//
//  AudioEngine.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import AVFAudio
import Combine

struct AudioData {
    let amplitude: Float
    let timeStamp: TimeInterval
}

final class AudioSystem {
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let bufferSize: AVAudioFrameCount = 1024
    private var isRunning = false
    
    // 오디오 데이터를 발행하는 subject
    private let audioSubject = PassthroughSubject<AudioData, Error>()
 
    var audioStream: AnyPublisher<AudioData, Error> {
        return audioSubject.eraseToAnyPublisher()
    }
    
    init(){
        self.inputNode = engine.inputNode
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
        
        // 입력 포멧 설정
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // 오디오 입력 처리
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            let amplitude = self.calculateAmplitude(buffer)
            let timeStamp = Date().timeIntervalSinceReferenceDate
            let audioData = AudioData(amplitude: amplitude, timeStamp: timeStamp)
            
            self.audioSubject.send(audioData)
        }
        
        // 엔진 시작
        try engine.start()
        isRunning = true
    }
    
    func stop() {
        engine.stop()
        inputNode.removeTap(onBus: 0)
        isRunning = false
        
        // 오디오 세션 비활성화
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    private func calculateAmplitude(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameCount = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameCount {
            sum += abs(channelData[i])
        }
        
        return sum / Float(frameCount)
    }
}
