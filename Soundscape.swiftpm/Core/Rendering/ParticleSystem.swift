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
        var rotation: Float  // 회전 추가
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
        
        // 눈이 내리는 영역 설정 (범위 확대)
        let spawnRadius: Float = 4.0  // 더 넓은 영역에서 생성
        let spawnHeight: Float = 3.0  // 더 높은 위치에서 시작
        
        // 랜덤 위치 계산
        let randomX = Float.random(in: -spawnRadius...spawnRadius)
        let randomZ = Float.random(in: -spawnRadius...spawnRadius)
        
        let position = SIMD3<Float>(
            cameraPos.x + randomX,
            cameraPos.y + spawnHeight,
            cameraPos.z + randomZ
        )
        
        // 눈송이 초기 속도 설정 (속도 감소)
        let fallSpeed: Float = -0.1  // 하강 속도 감소
        let driftSpeed: Float = 0.05
        let velocity = SIMD3<Float>(
            Float.random(in: -driftSpeed...driftSpeed),
            fallSpeed,
            Float.random(in: -driftSpeed...driftSpeed)
        )
        
        return ParticleFrame.Particle(
            position: position,
            size: Float.random(in: 0.2...0.3),  // 크기 증가
            color: SIMD4<Float>(1, 1, 1, Float.random(in: 0.8...1.0)),
            velocity: velocity,
            lifetime: Float.random(in: 5.0...8.0),  // 수명 증가
            rotation: Float.random(in: 0...Float.pi * 2)
        )
    }
    
    private func updateParticles(audio: AudioData, ar: ARData) {
        let maxParticles = 100
        
        // 진폭에 따라 파티클 생성 (임계값 낮춤)
        if particles.count < maxParticles {
            // 진폭 임계값을 더 낮게 설정
            let threshold: Float = 0.001  // 기존 0.01에서 낮춤
            
            if audio.amplitude > threshold {
                // 진폭 효과 증폭
                let amplifiedAmplitude = audio.amplitude * 100  // 진폭 증폭
                let particlesToCreate = Int(min(amplifiedAmplitude, 3))  // 한번에 최대 3개
                
                for _ in 0..<particlesToCreate {
                    let newParticle = createParticle(ar: ar)
                    particles.append(newParticle)
                }
            }
        }
        
        // 진폭에 따른 파티클 움직임 조정
        let deltaTime: Float = 0.016
        particles = particles.compactMap { particle in
            var updatedParticle = particle
            
            // 진폭 효과 조정 (더 섬세하게)
            let amplitudeEffect = audio.amplitude * 1.0  // 진폭 효과 감소
            updatedParticle.velocity = particle.velocity * (1.0 + amplitudeEffect)
            
            // 위치 업데이트
            updatedParticle.position += updatedParticle.velocity * deltaTime
            
            // 회전 업데이트 (진폭 효과 감소)
            updatedParticle.rotation += deltaTime * (0.3 + audio.amplitude)
            
            // 수명 감소
            updatedParticle.lifetime -= deltaTime
            
            return updatedParticle.lifetime > 0 ? updatedParticle : nil
        }
        
        let frame = ParticleFrame(particles: particles, timestamp: ar.timestamp)
        particleSubject.send(frame)
    }
}
