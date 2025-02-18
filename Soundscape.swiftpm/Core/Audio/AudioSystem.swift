//
//  AudioEngine.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import AVFAudio
import Accelerate
import Combine

struct FrequencyBand {
    let range: ClosedRange<Float>
    let name: String
}

/// FFT 결과로 각 Frequency 별 magnitude 값
struct FrequencyData {
    static let bands: [FrequencyBand] = [
        FrequencyBand(range: 20...100, name: "Sub Bass"),
        FrequencyBand(range: 100...250, name: "Bass"),
        FrequencyBand(range: 250...500, name: "Low Mids"),
        FrequencyBand(range: 500...2000, name: "Mids"),
        FrequencyBand(range: 2000...4000, name: "High Mids"),
        FrequencyBand(range: 4000...20000, name: "Highs")
    ]
    
    let rawMagnitudes: [Float]      // FFT 결과의 원본 magnitude 값들
    let normalizedMagnitudes: [Float] // 0-1 사이로 정규화된 magnitude 값들
    let frequencies: [Float]         // 각 magnitude에 해당하는 주파수 값
    let bandEnergies: [Float]       // 주파수 대역별 에너지 값
    let dominantFrequency: Float    // 가장 강한 주파수
    let timestamp: TimeInterval
    
    init(magnitudes: [Float], frequencies: [Float], timestamp: TimeInterval) {
        self.rawMagnitudes = magnitudes
        self.frequencies = frequencies
        self.timestamp = timestamp
        
        // Magnitude 정규화
        if let maxMagnitude = magnitudes.max(), maxMagnitude > 0 {
            self.normalizedMagnitudes = magnitudes.map { $0 / maxMagnitude }
        } else {
            self.normalizedMagnitudes = magnitudes
        }
        
        // 주파수 대역별 에너지 계산
        self.bandEnergies = FrequencyData.calculateBandEnergies(
            magnitudes: normalizedMagnitudes,
            frequencies: frequencies
        )
        
        // 지배적 주파수 찾기
        if let maxIndex = normalizedMagnitudes.enumerated()
            .max(by: { $0.element < $1.element })?.offset {
            self.dominantFrequency = frequencies[maxIndex]
        } else {
            self.dominantFrequency = 0
        }
    }
    
    private static func calculateBandEnergies(magnitudes: [Float], frequencies: [Float]) -> [Float] {
        return bands.map { band in
            var energy: Float = 0
            var count: Float = 0
            for (i, freq) in frequencies.enumerated() where freq >= band.range.lowerBound && freq <= band.range.upperBound {
                energy += max(0, magnitudes[i]) // 음수 에너지 방지
                count += 1
            }
            // 평균 에너지를 반환하고, 0과 1 사이로 정규화
            return count > 0 ? min(max(energy / count, 0), 1) : 0
        }
    }
}

final class AudioSystem {
    private let engine = AVAudioEngine()
    private let fftSize = 2048
    private var fftSetup: vDSP_DFT_Setup?
    
    private var isRunning = false
    
    // 오디오 데이터를 발행하는 subject
    private let frequencyDataSubject = PassthroughSubject<FrequencyData, Error>()
 
    var frequencyDataStream: AnyPublisher<FrequencyData, Error> {
        return frequencyDataSubject.eraseToAnyPublisher()
    }
    
    init(){
        setupFFT()
    }
    
    deinit {
        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }
    
    private func setupFFT(){
        fftSetup =  vDSP_create_fftsetup(
            vDSP_Length(log2(Float(fftSize))),
            FFTRadix(kFFTRadix2)
        )
    }
    
    /// AudioEngine 시작
    func start() throws {
        // 이미 실행 중인 경우 처리
        if isRunning {
            stop()
        }
        
        // 현재 오디오 세션 상태 확인 및 정리
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.isOtherAudioPlaying {
            // 다른 오디오가 재생 중인 경우 처리
            try audioSession.setActive(false)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }
        // 오디오 세션 설정
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let sampleRate = Float(inputFormat.sampleRate)
        
        let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: inputFormat.sampleRate,
            channels: 1,
            interleaved: false
        )
        
        // Hann window 생성
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(
            &window,
            vDSP_Length(fftSize),
            Int32(vDSP_HANN_NORM))
        
        // 오디오 입력 처리
        inputNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(fftSize),
            format: audioFormat)
        { [weak self] buffer, time in
            guard let self = self,
            let channelData = buffer.floatChannelData?[0]
            else { return }
            
            // 입력 데이터 준비
            var inputData = [Float](repeating: 0, count: self.fftSize)
            let frameCount = min(Int(buffer.frameLength), self.fftSize)  // 안전한 범위 설정
            for i in 0..<frameCount {
                inputData[i] = channelData[i] * window[i]
            }

            // FFT 계산을 위한 배열들 준비
            var realPart = [Float](repeating: 0, count: self.fftSize)
            var imagPart = [Float](repeating: 0, count: self.fftSize)
            var magnitudes = [Float](repeating: 0, count: self.fftSize/2)

            // 안전한 메모리 접근을 위해 withUnsafeMutableBufferPointer 사용
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(
                        realp: realPtr.baseAddress!,
                        imagp: imagPtr.baseAddress!
                    )
                    
                    // 1단계: 입력 데이터를 복소수 형태로 변환
                    inputData.withUnsafeMutableBufferPointer { inputPtr in
                        vDSP_ctoz(inputPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: self.fftSize/2) { $0 },
                                  2,
                                  &splitComplex,
                                  1,
                                  vDSP_Length(self.fftSize/2))
                    }
                    
                    // 2단계: FFT 실행 (이 부분이 빠져있었습니다)
                    if let fftSetup = self.fftSetup {
                        // FFT 수행 전에 스케일링 설정
                        var scalingFactor = Float(1.0/2.0)
                        vDSP_vsmul(splitComplex.realp, 1, &scalingFactor, splitComplex.realp, 1, vDSP_Length(self.fftSize/2))
                        vDSP_vsmul(splitComplex.imagp, 1, &scalingFactor, splitComplex.imagp, 1, vDSP_Length(self.fftSize/2))
                        
                        // FFT 실행
                        vDSP_fft_zrip(fftSetup,
                                      &splitComplex,
                                      1,
                                      vDSP_Length(log2(Float(self.fftSize))),
                                      FFTDirection(kFFTDirection_Forward))
                    }
                    
                    // 3단계: Magnitude 계산
                    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(self.fftSize/2))
                }
            }

            // 로그 스케일 변환
            var logMagnitudes = magnitudes
            vDSP_vdbcon(magnitudes,
                        1,
                        [20.0],
                        &logMagnitudes,
                        1,
                        vDSP_Length(self.fftSize/2),
                        1)
            // 주파수 배열 생성
            let frequencies = (0..<self.fftSize/2).map {
                sampleRate * Float($0) / Float(self.fftSize)
            }
            
            // FrequencyData 생성 및 전송
            let frequencyData = FrequencyData(
                magnitudes: logMagnitudes,
                frequencies: frequencies,
                timestamp: Date().timeIntervalSinceReferenceDate
            )
            
            self.frequencyDataSubject.send(frequencyData)
        }
        
        // 엔진 시작
        try engine.start()
        isRunning = true
    }
    
    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        isRunning = false
        
        // 오디오 세션 비활성화
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
}
