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
    
    init(onPositionChanged: @escaping (SCNVector3) -> Void) {
        // 드래그 가능한 구체 생성
        let geometry = SCNSphere(radius: 0.1)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        material.emission.contents = UIColor.orange
        geometry.materials = [material]
        
        sphere = SCNNode(geometry: geometry)
        self.onPositionChanged = onPositionChanged
        
        super.init()
        addChildNode(sphere)
        
        // 초기 위치 설정
        position = SCNVector3(0, -0.5, -2)
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
            
            // 화면 상의 이동 거리 계산
            let deltaX = Float(currentPosition.x - lastPosition.x) * 0.01
            let deltaY = Float(lastPosition.y - currentPosition.y) * 0.01
            
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
            -simdTransform.columns.0[0],
            -simdTransform.columns.0[1],
            -simdTransform.columns.0[2]
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

// ARSCNView extension for gesture handling
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
