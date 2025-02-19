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
    
    private var cancellables = Set<AnyCancellable>()
    
    func setARView(_ arView: ARSCNView) {
        self.renderingEngine = SoundWaveRenderingEngine(sceneView: arView)
        
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
