//
//  ARVisualizationViewModel.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import ARKit
import Combine
import Foundation

@MainActor
final class ARVisualizationViewModel: ObservableObject {
    @Published private(set) var error: Error?
    @Published var showErrorAlert: Bool = false
    
    private let audioSystem = AudioSystem()
    let arSystem = ARSystem()
    private let rippleSystem = RippleSystem()
    private var renderingEngine: SoundWaveRenderingEngine?
    private var soundSourceController: SoundSourceController?
    
    private var cancellables = Set<AnyCancellable>()
    
    func setARView(_ arView: ARSCNView) {
        self.renderingEngine = SoundWaveRenderingEngine(sceneView: arView)
        
        // 사운드 소스 컨트롤러 설정
        self.soundSourceController = arView.addSoundSourceController { [weak self] position in
            self?.rippleSystem.updateSoundSourcePosition(position)
        }
        
        // 오디오 데이터 구독 설정
        audioSystem.frequencyDataStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                    self?.showErrorAlert = true
                }
            } receiveValue: { [weak self] frequencyData in
                // 사운드 소스 컨트롤러 업데이트
                self?.soundSourceController?.updateWithFrequencyData(frequencyData)
            }
            .store(in: &cancellables)
        
        // Ripple System 설정
        rippleSystem.start(
            frequencyStream: audioSystem.frequencyDataStream,
            arStream: arSystem.arStream.eraseToAnyPublisher()
        )
        
        // 리플 스트림 처리
        let handledRippleStream = rippleSystem.ripplePublisher
            .catch { [weak self] error -> AnyPublisher<RippleFrame, Never> in
                DispatchQueue.main.async {
                    self?.error = error
                    self?.showErrorAlert = true
                }
                return Empty().eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // RenderingEngine 시작
        renderingEngine?.startRendering(rippleStream: handledRippleStream)
    }
    
    func startCapture() {
        do {
            try audioSystem.start()
            try arSystem.start()
        } catch {
            self.error = error
            self.showErrorAlert = true
        }
    }
    
    func stopCapture() {
        audioSystem.stop()
        arSystem.stop()
    }
    
    func dismissError() {
        showErrorAlert = false
        error = nil
    }
}
