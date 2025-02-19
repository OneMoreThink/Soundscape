//
//  ParticleSystem.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import Combine
import Foundation
import simd
import SceneKit

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
        // 확장된 주파수 대역별 색상 (12개 대역)
        let colors: [SIMD4<Float>] = [
            // Sub Bass Low (20-40Hz) - 매우 진한 자주색
            SIMD4<Float>(0.4, 0, 0.4, 1),
            
            // Sub Bass High (40-60Hz) - 깊은 보라색
            SIMD4<Float>(0.5, 0, 0.7, 1),
            
            // Bass Low (60-120Hz) - 진한 크림슨
            SIMD4<Float>(0.7, 0, 0.3, 1),
            
            // Bass High (120-250Hz) - 강렬한 빨강
            SIMD4<Float>(0.9, 0, 0.1, 1),
            
            // Low Mids (250-500Hz) - 짙은 주황
            SIMD4<Float>(0.95, 0.3, 0, 1),
            
            // Mid Low (500-1000Hz) - 진한 황금색
            SIMD4<Float>(0.9, 0.5, 0, 1),
            
            // Mid High (1000-2000Hz) - 진한 초록
            SIMD4<Float>(0.4, 0.8, 0, 1),
            
            // High Mids (2000-4000Hz) - 깊은 청록색
            SIMD4<Float>(0, 0.8, 0.5, 1),
            
            // Presence (4000-6000Hz) - 진한 하늘색
            SIMD4<Float>(0, 0.6, 0.8, 1),
            
            // Brilliance Low (6000-10000Hz) - 진한 파랑
            SIMD4<Float>(0, 0.3, 0.9, 1),
            
            // Brilliance High (10000-16000Hz) - 매우 진한 파랑
            SIMD4<Float>(0, 0.1, 0.8, 1),
            
            // Air (16000-20000Hz) - 진한 코발트 블루
            SIMD4<Float>(0.1, 0.3, 0.9, 1)
        ]
        
        return colors[bandIndex]
    }
    
    var radius: Float {
        // 주파수 대역에 따른 반경 조정
        // 저주파는 큰 반경, 고주파는 작은 반경으로 표현
        let baseRadius: Float = 0.5
        let frequencyFactor = 1.0 - (Float(bandIndex) / 11.0)  // 12개 대역을 고려하여 11로 변경
        
        // 주파수 대역별 특성을 반영한 반경 계수
        let bandFactors: [Float] = [
            1.2,    // Sub Bass Low - 매우 큰 반경
            1.15,   // Sub Bass High
            1.1,    // Bass Low
            1.05,   // Bass High
            1.0,    // Low Mids
            0.95,   // Mid Low
            0.9,    // Mid High
            0.85,   // High Mids
            0.8,    // Presence
            0.75,   // Brilliance Low
            0.7,    // Brilliance High
            0.65    // Air - 가장 작은 반경
        ]
        
        return baseRadius * (1.0 + frequencyFactor) * bandFactors[bandIndex]
    }
    
    var intensity: Float {
        // 에너지 기반 강도 계산 개선
        // 주파수 대역별 가중치 적용
        let bandWeights: [Float] = [
            1.2,    // Sub Bass Low - 강조
            1.15,   // Sub Bass High
            1.1,    // Bass Low
            1.05,   // Bass High
            1.0,    // Low Mids
            1.0,    // Mid Low
            1.0,    // Mid High
            1.05,   // High Mids
            1.1,    // Presence
            1.15,   // Brilliance Low
            1.2,    // Brilliance High
            1.25    // Air - 더 강조
        ]
        
        let weightedEnergy = energy * bandWeights[bandIndex]
        return min(max(weightedEnergy * 2.0, 0.2), 1.0)
    }
    
    // 파동의 복잡도를 주파수 대역에 따라 결정
    var complexity: Float {
        // 고주파일수록 더 복잡한 파형 생성
        let baseComplexity: Float = 1.0
        let frequencyFactor = Float(bandIndex) / 11.0  // 12개 대역을 고려
        return baseComplexity + (frequencyFactor * 2.0)
    }
    
    // 파동의 지속 시간을 주파수 대역에 따라 결정
    var duration: TimeInterval {
        // 저주파는 더 오래 지속
        let baseDuration: TimeInterval = 2.0
        let frequencyFactor = 1.0 - (Double(bandIndex) / 11.0)  // 12개 대역을 고려
        return baseDuration * (0.5 + frequencyFactor)
    }
    
    // 파동의 감쇠율을 주파수 대역에 따라 결정
    var decayRate: Float {
        // 고주파는 빠르게 감쇠
        let baseDecay: Float = 1.0
        let frequencyFactor = Float(bandIndex) / 11.0  // 12개 대역을 고려
        return baseDecay * (1.0 + frequencyFactor)
    }
}

// MARK: - Ripple System
class RippleSystem {
    private var ripples: [RippleProperties] = []
    private let rippleSubject = PassthroughSubject<RippleFrame, Error>()
    private var cancellables = Set<AnyCancellable>()
    private var soundSourcePosition: SCNVector3 = SCNVector3(0, -0.5, -2)
    
    var ripplePublisher: AnyPublisher<RippleFrame, Error> {
        rippleSubject.eraseToAnyPublisher()
    }
    
    func updateSoundSourcePosition(_ position: SCNVector3) {
        soundSourcePosition = position
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
        var newRipples: [RippleProperties] = []
        
        // 각 주파수 대역에 대해 리플 생성
        for (index, energy) in frequency.bandEnergies.enumerated() {
            if energy > 0.1 { // 에너지가 임계값을 넘는 경우에만 리플 생성
                let ripple = RippleProperties(
                    position: SIMD3<Float>(
                        soundSourcePosition.x,
                        soundSourcePosition.y,
                        soundSourcePosition.z
                    ),
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
