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
    private let particleSystem = ParticleSystem()
    private var renderingEngine: RenderingEngine?
    
    private var cancellables = Set<AnyCancellable>()
    
    func setARView(_ arView: ARSCNView) {
        print("Setting up RenderingEngine with ARSCNView")
        self.renderingEngine = RenderingEngine(sceneView: arView)
        
        // Particle System 설정
        particleSystem.start(
            audioStream: audioSystem.audioStream.mapError { $0 as Error }.eraseToAnyPublisher(),
            arStream: arSystem.arStream.eraseToAnyPublisher()
        )
        
        // 파티클 스트림 처리
        let handledParticleStream = particleSystem.particlePublisher
            .catch { [weak self] error -> AnyPublisher<ParticleFrame, Never> in
                DispatchQueue.main.async {
                    self?.error = error
                    self?.showErrorAlert = true
                }
                return Empty().eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // RenderingEngine 시작
        renderingEngine?.startRendering(particleStream: handledParticleStream)
        print("Rendering engine started")
    }
    
    func startCapture() {
        do {
            try audioSystem.start()
            try arSystem.start()
        } catch {
            self.error = error
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
