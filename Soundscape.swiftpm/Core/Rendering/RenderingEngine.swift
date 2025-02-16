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
class RenderingEngine {
    private let sceneView: ARSCNView
    private var particleNodes: [SCNNode] = []
    private var cancellables = Set<AnyCancellable>()
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        setupScene()
    }
    
    func startRendering(particleStream: AnyPublisher<ParticleFrame, Never>) {
        particleStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.renderParticles(frame.particles)
            }
            .store(in: &cancellables)
    }
    
    private func createParticleNode() -> SCNNode {
        // 눈송이용 평면 크기 증가
        let size: CGFloat = 0.3  // 크기 증가
        let geometry = SCNPlane(width: size, height: size)
        let material = SCNMaterial()
        
        // 더 밝은 색상으로 설정
        let snowColor = UIColor(white: 1.0, alpha: 0.9)
        material.diffuse.contents = snowColor
        material.emission.contents = snowColor
        material.transparent.contents = snowColor
        material.lightingModel = .constant
        material.transparencyMode = .rgbZero
        
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        node.constraints = [SCNBillboardConstraint()]
        
        return node
    }
    
    func setupScene() {
        let scene = SCNScene()
        
        // 은은한 환경광 설정
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 700
        scene.rootNode.addChildNode(ambientLight)
        
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
    }
    
    private func renderParticles(_ particles: [ParticleFrame.Particle]) {
        // 노드 수 관리
        while particleNodes.count < particles.count {
            let node = createParticleNode()
            particleNodes.append(node)
            sceneView.scene.rootNode.addChildNode(node)
        }
        
        while particleNodes.count > particles.count {
            if let node = particleNodes.popLast() {
                node.removeFromParentNode()
            }
        }
        
        // 파티클 업데이트
        for (index, particle) in particles.enumerated() {
            let node = particleNodes[index]
            
            // 위치 업데이트
            node.position = SCNVector3(
                particle.position.x,
                particle.position.y,
                particle.position.z
            )
            
            // 크기 업데이트
            let scale = particle.size
            node.scale = SCNVector3(scale, scale, scale)
            
            // 회전 업데이트
            node.eulerAngles.z = particle.rotation
            
            // 투명도 업데이트
            if let material = node.geometry?.materials.first {
                let alpha = CGFloat(min(1.0, particle.lifetime))
                material.transparency = 1 - alpha
            }
        }
    }
}
