//
//  ParticleSystem.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import Combine
import Foundation
import simd

// MARK: - ParticleSystem
struct ParticleFrame {
    struct Particle {
        var position: SIMD3<Float>
        var size: Float
        var color: SIMD4<Float>
        var velocity: SIMD3<Float>
        var lifetime: Float
    }
    let particles: [Particle]
    let timestamp: TimeInterval
}

class ParticleSystem {
    private var particles: [ParticleFrame.Particle] = []
    private let particleSubject = PassthroughSubject<ParticleFrame, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    var particlePublisher: AnyPublisher<ParticleFrame, Error> {
        particleSubject.eraseToAnyPublisher()
    }
    
    func start(audioStream: AnyPublisher<AudioData, Error>,
               arStream: AnyPublisher<ARData, Error>) {
        // 오디오와 AR 데이터 스트림 결합
        Publishers.CombineLatest(audioStream, arStream)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.particleSubject.send(completion: .failure(error))
                }
            } receiveValue: { [weak self] audio, ar in
                self?.updateParticles(audio: audio, ar: ar)
            }
            .store(in: &cancellables)
    }
    
    private func createParticle(ar: ARData) -> ParticleFrame.Particle {
        let cameraTransform = ar.cameraTransform
        
        // 카메라 위치
        let cameraPos = SIMD3<Float>(cameraTransform.columns.3.x,
                                    cameraTransform.columns.3.y,
                                    cameraTransform.columns.3.z)
        
        // 카메라가 보는 방향
        let cameraForward = normalize(SIMD3<Float>(cameraTransform.columns.2.x,
                                                  cameraTransform.columns.2.y,
                                                  cameraTransform.columns.2.z))
        
        // 카메라 바로 앞에 생성 (훨씬 가깝게)
        let distance = Float.random(in: 0.2...0.3)  // 더 가까운 거리
        
        // 파티클 위치 계산 (카메라 높이에 맞춤)
        let position = cameraPos + (cameraForward * distance)
        
        return ParticleFrame.Particle(
            position: position,
            size: 0.3,  // 크기 대폭 증가
            color: SIMD4<Float>(1, 0, 0, 1),  // 빨간색
            velocity: SIMD3<Float>(0, 0, 0),  // 속도 제거
            lifetime: 0.5  // 수명 감소
        )
    }

    private func updateParticles(audio: AudioData, ar: ARData) {
        // 성능을 위해 파티클 수 제한
        if audio.amplitude > 0.0001 && particles.count < 10 {
            // 한 번에 하나의 파티클만 생성
            let particle = createParticle(ar: ar)
            particles.append(particle)
        }
        
        // 간단한 업데이트
        particles = particles.compactMap { particle in
            var updatedParticle = particle
            updatedParticle.lifetime -= 0.016
            return updatedParticle.lifetime > 0 ? updatedParticle : nil
        }
        
        let frame = ParticleFrame(particles: particles, timestamp: ar.timestamp)
        particleSubject.send(frame)
    }
}
