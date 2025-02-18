//
//  ParticleSystem.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import Combine
import Foundation
import simd

struct RippleFrame {
    let ripples: [RippleProperties]
    let timestamp: TimeInterval
}

struct RippleProperties {
    let position: SIMD3<Float>
    let bandIndex: Int
    let energy: Float
    let frequency: Float
    
    var color: SIMD4<Float> {
        // 주파수 대역별 색상
        let colors: [SIMD4<Float>] = [
            SIMD4<Float>(1, 0, 0, 1),     // Sub Bass - Red
            SIMD4<Float>(1, 0.5, 0, 1),   // Bass - Orange
            SIMD4<Float>(1, 1, 0, 1),     // Low Mids - Yellow
            SIMD4<Float>(0, 1, 0, 1),     // Mids - Green
            SIMD4<Float>(0, 1, 1, 1),     // High Mids - Cyan
            SIMD4<Float>(0, 0, 1, 1)      // Highs - Blue
        ]
        return colors[bandIndex]
    }
    
    var radius: Float {
        // 주파수가 높을수록 작은 반경
        let baseRadius: Float = 0.5
        let frequencyFactor = 1.0 - (Float(bandIndex) / 5.0)
        return baseRadius * (1.0 + frequencyFactor)
    }
    
    var intensity: Float {
        // 에너지 기반 강도
        return min(max(energy * 2.0, 0.2), 1.0)
    }
}

// MARK: - Ripple System
class RippleSystem {
    private var ripples: [RippleProperties] = []
    private let rippleSubject = PassthroughSubject<RippleFrame, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    var ripplePublisher: AnyPublisher<RippleFrame, Error> {
        rippleSubject.eraseToAnyPublisher()
    }
    
    func start(frequencyStream: AnyPublisher<FrequencyData, Error>,
               arStream: AnyPublisher<ARData, Error>) {
        Publishers.CombineLatest(frequencyStream, arStream)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.rippleSubject.send(completion: .failure(error))
                }
            } receiveValue: { [weak self] frequency, ar in
                self?.updateRipples(frequency: frequency, ar: ar)
            }
            .store(in: &cancellables)
    }
    
    private func updateRipples(frequency: FrequencyData, ar: ARData) {
        let cameraTransform = ar.cameraTransform
        let cameraPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        var newRipples: [RippleProperties] = []
        
        // 각 주파수 대역에 대해 리플 생성
        for (index, energy) in frequency.bandEnergies.enumerated() {
            if energy > 0.1 { // 에너지가 임계값을 넘는 경우에만 리플 생성
                let ripple = RippleProperties(
                    position: cameraPos + SIMD3<Float>(0, -0.5, -2),
                    bandIndex: index,
                    energy: energy,
                    frequency: frequency.dominantFrequency
                )
                newRipples.append(ripple)
            }
        }
        
        let frame = RippleFrame(ripples: newRipples, timestamp: ar.timestamp)
        rippleSubject.send(frame)
    }
}
