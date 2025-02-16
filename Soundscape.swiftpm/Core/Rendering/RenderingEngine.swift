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
        // 매우 단순한 큐브 사용
        let geometry = SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0)
        let material = SCNMaterial()
        
        // 밝은 빨간색
        material.diffuse.contents = UIColor.red
        material.emission.contents = UIColor.red
        material.lightingModel = .constant
        
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        node.constraints = [SCNBillboardConstraint()]
        
        return node
    }

    func setupScene() {
        let scene = SCNScene()
        
        // 최소한의 조명만 사용
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        scene.rootNode.addChildNode(ambientLight)
        
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        
        // 디버깅 옵션 활성화
        sceneView.debugOptions = [.showFeaturePoints]
    }

    private func renderParticles(_ particles: [ParticleFrame.Particle]) {
        // 기존 노드 제거
        particleNodes.forEach { $0.removeFromParentNode() }
        particleNodes.removeAll()
        
        // 새 노드 추가
        for particle in particles {
            let node = createParticleNode()
            node.position = SCNVector3(
                particle.position.x,
                particle.position.y,
                particle.position.z
            )
            particleNodes.append(node)
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    private func updateParticleNode(_ node: SCNNode, with particle: ParticleFrame.Particle) {
        // 위치 업데이트
        node.position = SCNVector3(
            particle.position.x,
            particle.position.y,
            particle.position.z
        )
        
        // 크기 업데이트 (생명 주기에 따라 크기 변화)
        let scale = particle.size * (particle.lifetime / 2.0)  // 수명이 줄어들수록 작아짐
        node.scale = SCNVector3(scale, scale, scale)
        
        // 투명도 업데이트 (생명 주기에 따라 투명해짐)
        if let material = node.geometry?.materials.first {
            let alpha = CGFloat(particle.lifetime / 2.0)
            material.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: alpha)
            material.emission.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: alpha)
        }
    }
}
