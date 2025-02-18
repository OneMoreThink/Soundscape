//
//  MetalEngine.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import ARKit
import SceneKit
import Combine

// MARK: - RenderingEngine
@MainActor
class RippleRenderingEngine {
    private let sceneView: ARSCNView
    private var rippleNodes: [Int: RippleNode] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        setupScene()
    }
    
    private func setupScene() {
        let scene = SCNScene()
        
        // 물리 시뮬레이션 설정
        scene.physicsWorld.gravity = SCNVector3(0, 0, 0)
        
        // 조명 설정
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        scene.rootNode.addChildNode(ambientLight)
        
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func startRendering(rippleStream: AnyPublisher<RippleFrame, Never>) {
        rippleStream
            .receive(on: DispatchQueue.main)
            .sink { _ in
            } receiveValue: { [weak self] frame in
                self?.updateRipples(frame.ripples)
            }
            .store(in: &cancellables)
    }
    
    private func updateRipples(_ properties: [RippleProperties]) {
        // 활성 리플 인덱스 추적
        var activeIndices = Set<Int>()
        
        // 리플 업데이트 또는 생성
        for property in properties {
            activeIndices.insert(property.bandIndex)
            
            if let existingNode = rippleNodes[property.bandIndex] {
                // 기존 리플 업데이트
                existingNode.update(with: property)
            } else {
                // 새 리플 생성
                let newNode = RippleNode(properties: property)
                rippleNodes[property.bandIndex] = newNode
                sceneView.scene.rootNode.addChildNode(newNode)
            }
        }
        
        // 비활성 리플 제거
        for (index, node) in rippleNodes {
            if !activeIndices.contains(index) {
                node.removeFromParentNode()
                rippleNodes.removeValue(forKey: index)
            }
        }
    }
}

class RippleNode: SCNNode {
    private var currentRadius: Float = 0
    private var targetRadius: Float = 0
    private var intensity: Float = 0
    private let maxRings = 5
    private var rings: [SCNNode] = []
    
    init(properties: RippleProperties) {
        super.init()
        
        self.position = SCNVector3(properties.position)
        setupRings(properties)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupRings(_ properties: RippleProperties) {
        // 여러 개의 동심원 생성
        for i in 0..<maxRings {
            let ring = createRing(properties: properties, index: i)
            rings.append(ring)
            addChildNode(ring)
        }
    }
    
    private func createRing(properties: RippleProperties, index: Int) -> SCNNode {
        let baseRadius = properties.radius
        let ringNode = SCNNode()
        
        // 동심원 지오메트리 생성
        let torus = SCNTorus(
            ringRadius: CGFloat(baseRadius),
            pipeRadius: 0.003  // 얇은 선
        )
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(
            red: CGFloat(properties.color.x),
            green: CGFloat(properties.color.y),
            blue: CGFloat(properties.color.z),
            alpha: CGFloat(properties.color.w)
        )
        material.emission.contents = material.diffuse.contents
        material.lightingModel = .constant
        material.transparency = 0.8
        
        torus.materials = [material]
        ringNode.geometry = torus
        
        // 초기 스케일 설정
        let scale = 1.0 + Float(index) * 0.2
        ringNode.scale = SCNVector3(scale, scale, scale)
        
        return ringNode
    }
    
    func update(with properties: RippleProperties) {
        // 타겟 반경 업데이트
        targetRadius = properties.radius
        intensity = properties.intensity
        
        // 각 링 업데이트
        for (i, ring) in rings.enumerated() {
            let scale = 1.0 + Float(i) * 0.2
            
            // 크기 애니메이션
            let scaleAction = SCNAction.scale(
                to: CGFloat(scale * (1.0 + intensity * 0.3)),
                duration: 0.2
            )
            ring.runAction(scaleAction)
            
            // 투명도 애니메이션
            if let material = ring.geometry?.materials.first {
                let fadeAction = SCNAction.customAction(duration: 0.2) { node, elapsedTime in
                    let progress = elapsedTime / 0.2
                    let alpha = 0.8 * (1.0 - (CGFloat(i) / CGFloat(self.maxRings)))
                               * (1.0 - progress)
                    material.transparency = alpha
                }
                ring.runAction(fadeAction)
            }
            
            // 회전 애니메이션
            let rotationSpeed = Float.pi * 2 * intensity
            let rotationAction = SCNAction.rotateBy(
                x: 0,
                y: CGFloat(rotationSpeed),
                z: 0,
                duration: 1.0
            )
            ring.runAction(SCNAction.repeatForever(rotationAction))
        }
        
        // 색상 업데이트
        updateColor(properties.color)
    }
    
    private func updateColor(_ color: SIMD4<Float>) {
        for ring in rings {
            if let material = ring.geometry?.materials.first {
                material.diffuse.contents = UIColor(
                    red: CGFloat(color.x),
                    green: CGFloat(color.y),
                    blue: CGFloat(color.z),
                    alpha: CGFloat(color.w)
                )
                material.emission.contents = material.diffuse.contents
            }
        }
    }
}
