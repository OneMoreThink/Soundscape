//
//  File.swift
//  Soundscape
//
//  Created by 이종선 on 2/19/25.
//

import UIKit
import SceneKit
import ARKit

class SoundSourceController: SCNNode {
    private let sphere: SCNNode
    private var lastPanPosition: CGPoint?
    private var onPositionChanged: ((SCNVector3) -> Void)?
    private var audioReactiveSystem: AudioReactiveSystem?
    
    init(onPositionChanged: @escaping (SCNVector3) -> Void) {
        // 드래그 가능한 구체 생성
        let geometry = SCNSphere(radius: 0.1)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        material.emission.contents = UIColor.orange
        material.metalness.contents = 1.0  // 금속성 추가
        material.roughness.contents = 0.2  // 광택 추가
        geometry.materials = [material]
        
        sphere = SCNNode(geometry: geometry)
        self.onPositionChanged = onPositionChanged
        
        super.init()
        addChildNode(sphere)
        
        // 초기 위치 설정
        position = SCNVector3(0, -0.5, -2)
        
        // 오디오 반응 시스템 초기화
        audioReactiveSystem = AudioReactiveSystem(sphereNode: sphere)
    }
    
    func updateWithFrequencyData(_ frequencyData: FrequencyData) {
        audioReactiveSystem?.update(with: frequencyData)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 팬 제스처 처리
    @MainActor
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, in view: ARSCNView) {
        switch gesture.state {
        case .began:
            lastPanPosition = gesture.location(in: view)
            
        case .changed:
            guard let lastPosition = lastPanPosition else { return }
            let currentPosition = gesture.location(in: view)
            
            // 화면 상의 이동 거리 계산 - 방향 수정
            let deltaX = Float(currentPosition.x - lastPosition.x) * 0.01
            let deltaY = Float(lastPosition.y - currentPosition.y) * 0.01  // y축 방향 다시 반전
            
            // 현재 카메라의 방향을 기준으로 이동 벡터 계산
            guard let camera = view.pointOfView else { return }
            
            // 카메라의 right 벡터와 up 벡터 가져오기
            let rightVector = camera.rightVector
            let upVector = camera.upVector
            
            // 이동 벡터 계산
            let moveVector = SCNVector3(
                rightVector.x * deltaX + upVector.x * deltaY,
                rightVector.y * deltaX + upVector.y * deltaY,
                rightVector.z * deltaX + upVector.z * deltaY
            )
            
            // 새로운 위치 계산
            let newPosition = SCNVector3(
                position.x + moveVector.x,
                position.y + moveVector.y,
                position.z + moveVector.z
            )
            
            // 위치 업데이트
            position = newPosition
            onPositionChanged?(position)
            
            // 구체 펄스 애니메이션
            pulseSphere()
            
            // 현재 위치 저장
            lastPanPosition = currentPosition
            
        case .ended, .cancelled:
            lastPanPosition = nil
            
        default:
            break
        }
    }
    
    private func pulseSphere() {
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.2, duration: 0.1),
            SCNAction.scale(to: 1.0, duration: 0.1)
        ])
        sphere.runAction(pulseAction)
    }
}

// SCNNode extension for vector calculations
extension SCNNode {
    var rightVector: SCNVector3 {
        return SCNVector3(
            simdTransform.columns.0[0],  // 마이너스 제거
            simdTransform.columns.0[1],  // 마이너스 제거
            simdTransform.columns.0[2]   // 마이너스 제거
        )
    }
    
    var upVector: SCNVector3 {
        return SCNVector3(
            simdTransform.columns.1[0],
            simdTransform.columns.1[1],
            simdTransform.columns.1[2]
        )
    }
}

private class AudioReactiveSystem {
    private let sphereNode: SCNNode
    private var baseScale: CGFloat = 1.0
    private var rotationSpeed: CGFloat = 0.0
    
    init(sphereNode: SCNNode) {
        self.sphereNode = sphereNode
        setupInitialEffects()
    }
    
    private func setupInitialEffects() {
        // 지속적인 회전 애니메이션
        let rotateAction = SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
        )
        sphereNode.runAction(rotateAction)
        
        // 기본 호흡 애니메이션
        let breatheAction = SCNAction.repeatForever(
            SCNAction.sequence([
                SCNAction.scale(to: 1.1, duration: 1.0),
                SCNAction.scale(to: 0.9, duration: 1.0)
            ])
        )
        sphereNode.runAction(breatheAction)
    }
    
    func update(with frequencyData: FrequencyData) {
        // 전체 에너지 계산
        let totalEnergy = frequencyData.bandEnergies.reduce(0, +)
        
        // 베이스 주파수 반응
        let bassEnergy = frequencyData.bandEnergies[0] + frequencyData.bandEnergies[1]
        updateScale(bassEnergy)
        
        // 중간 주파수 반응
        let midEnergy = frequencyData.bandEnergies[2] + frequencyData.bandEnergies[3]
        updateEmission(midEnergy)
        
        // 높은 주파수 반응
        let highEnergy = frequencyData.bandEnergies[4] + frequencyData.bandEnergies[5]
        updateRotation(highEnergy)
        
        // 구체 변형 효과
        updateDeformation(totalEnergy)
    }
    
    private func updateScale(_ energy: Float) {
        // 베이스에 따른 크기 변화
        let scaleMultiplier = 1.0 + Double(energy * 1.5)
        let newScale = baseScale * scaleMultiplier
        
        // 급격한 변화 방지를 위한 보간
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        sphereNode.scale = SCNVector3(newScale, newScale, newScale)
        SCNTransaction.commit()
    }
    
    private func updateEmission(_ energy: Float) {
        // 중간 주파수에 따른 발광 효과
        guard let material = sphereNode.geometry?.materials.first else { return }
        
        let baseColor = UIColor.orange
        let energyColor = UIColor(
            red: CGFloat(1.0),
            green: CGFloat(0.3 + Double(energy) * 0.7),
            blue: CGFloat(energy * 0.5),
            alpha: 1.0
        )
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        material.emission.contents = energyColor
        material.diffuse.contents = baseColor.withAlphaComponent(0.8)
        SCNTransaction.commit()
    }
    
    private func updateRotation(_ energy: Float) {
        // 높은 주파수에 따른 회전 속도 변화
        rotationSpeed = CGFloat(energy * 10.0)
        
        // 현재 회전 애니메이션 제거
        sphereNode.removeAllActions()
        
        // 새로운 회전 속도로 애니메이션 적용
        let rotateAction = SCNAction.repeatForever(
            SCNAction.rotateBy(
                x: rotationSpeed,
                y: rotationSpeed * 2,
                z: rotationSpeed * 0.5,
                duration: 1.0
            )
        )
        sphereNode.runAction(rotateAction)
    }
    
    private func updateDeformation(_ energy: Float) {
        // 전체 에너지에 따른 구체 변형
        guard let geometry = sphereNode.geometry as? SCNSphere else { return }
        
        // 세그먼트 수를 에너지에 따라 동적으로 조정
        let baseSegments = 24
        let additionalSegments = Int(energy * 24)
        geometry.segmentCount = baseSegments + additionalSegments
        
        // 표면 요동 효과
        let shader = """
        #pragma body
        
        float turbulence = sin(_surface.position.x * 4.0 + u_time) * 
                          cos(_surface.position.y * 4.0 + u_time) * 
                          sin(_surface.position.z * 4.0 + u_time);
        
        _surface.position += _surface.normal * turbulence * 0.02;
        """
        
        if let material = geometry.materials.first {
            material.shaderModifiers = [.surface: shader]
        }
    }
}

// ARSCNView extension update
extension ARSCNView {
    func addSoundSourceController(onPositionChanged: @escaping (SCNVector3) -> Void) -> SoundSourceController {
        let controller = SoundSourceController(onPositionChanged: onPositionChanged)
        scene.rootNode.addChildNode(controller)
        
        // 팬 제스처 인식기 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        return controller
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let controller = scene.rootNode.childNodes.first(where: { $0 is SoundSourceController }) as? SoundSourceController else { return }
        controller.handlePanGesture(gesture, in: self)
    }
}
