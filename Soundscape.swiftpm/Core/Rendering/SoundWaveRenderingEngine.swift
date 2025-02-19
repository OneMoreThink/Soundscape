//
//  File.swift
//  Soundscape
//
//  Created by 이종선 on 2/19/25.
//

import ARKit
import SceneKit
import Combine

@MainActor
class SoundWaveRenderingEngine {
    private let sceneView: ARSCNView
    private var waveEmitters: [Int: SphericalWaveEmitter] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        setupScene()
    }
    
    private func setupScene() {
        let scene = SCNScene()
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        scene.rootNode.addChildNode(ambientLight)
        
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = false
    }
    
    func startRendering(rippleStream: AnyPublisher<RippleFrame, Never>) {
        rippleStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.updateWaves(frame.ripples)
            }
            .store(in: &cancellables)
    }
    
    private func updateWaves(_ properties: [RippleProperties]) {
        var activeIndices = Set<Int>()
        
        for property in properties {
            activeIndices.insert(property.bandIndex)
            
            if let existingEmitter = waveEmitters[property.bandIndex] {
                existingEmitter.updateEnergy(property)
            } else {
                let newEmitter = SphericalWaveEmitter(properties: property)
                waveEmitters[property.bandIndex] = newEmitter
                sceneView.scene.rootNode.addChildNode(newEmitter)
            }
        }
        
        for (index, emitter) in waveEmitters {
            if !activeIndices.contains(index) {
                emitter.removeFromParentNode()
                waveEmitters.removeValue(forKey: index)
            }
        }
    }
}

class SphericalWaveEmitter: SCNNode {
    private var waveFronts: [SCNNode] = []
    private var waveParticleSystems: [SCNNode] = []
    private let maxWaves = 15
    private var currentProperties: RippleProperties
    private var lastEmissionTime: TimeInterval = 0
    private let emissionInterval: TimeInterval = 0.1
    
    init(properties: RippleProperties) {
        self.currentProperties = properties
        super.init()
        
        setupEmitter()
        setupParticleSystems()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEmitter() {
        // 공간상의 위치 설정
        self.position = SCNVector3(
            x: 0,
            y: Float(currentProperties.bandIndex) * 0.4 - 1.0, // 약간 아래에서 시작
            z: -3.0
        )
    }
    
    private func setupParticleSystems() {
        // 주파수 대역별로 다른 특성을 가진 파티클 시스템 생성
        let mainSystem = createParticleSystem(
            size: 0.05,
            speedFactor: 1.0,
            spread: 180.0,
            lifetime: 2.0
        )
        
        let trailSystem = createParticleSystem(
            size: 0.02,
            speedFactor: 0.5,
            spread: 360.0,
            lifetime: 1.5
        )
        
        // 파티클 시스템 노드 생성 및 추가
        let mainNode = SCNNode()
        mainNode.addParticleSystem(mainSystem)
        
        let trailNode = SCNNode()
        trailNode.addParticleSystem(trailSystem)
        
        waveParticleSystems = [mainNode, trailNode]
        
        // 노드 추가
        for node in waveParticleSystems {
            addChildNode(node)
        }
    }
    
    private func createParticleSystem(
        size: CGFloat,
        speedFactor: CGFloat,
        spread: CGFloat,
        lifetime: CGFloat
    ) -> SCNParticleSystem {
        let system = SCNParticleSystem()
        
        // 기본 설정
        system.particleSize = size
        system.particleLifeSpan = lifetime
        
        // 3D 구형 방출을 위한 설정
        system.emitterShape = SCNSphere(radius: 0.05)  // 더 작은 방출 영역
        system.birthRate = 1000
        system.spreadingAngle = 180  // 완전한 구형 분포
        system.emittingDirection = SCNVector3(0, 0, 1)  // 전방향
        system.speedFactor = speedFactor
        system.particleVelocity = 1.5  // 속도 감소
        system.particleVelocityVariation = 1.0  // 더 다양한 속도
        system.stretchFactor = 0.0  // 스트레치 효과 제거
        
        // 랜덤한 방향성을 위한 추가 설정
        system.particleAngleVariation = CGFloat.pi  // 회전 변화
        system.particleAngularVelocity = 0.5  // 회전 속도
        
        // 부드러운 파티클을 위한 설정
        system.particleImage = generateSmoothParticle()
        system.blendMode = .additive  // 부드러운 블렌딩
        system.sortingMode = .distance  // 깊이에 따른 정렬
        system.isLightingEnabled = false  // 조명 효과 비활성화
        
        // 색상 설정
        system.particleColor = UIColor(
            red: CGFloat(currentProperties.color.x),
            green: CGFloat(currentProperties.color.y),
            blue: CGFloat(currentProperties.color.z),
            alpha: CGFloat(currentProperties.color.w)
        )
        
        // 가속도 설정
        system.acceleration = SCNVector3(0, 0.2, 0)
        
        // 크기 변화
        system.particleSizeVariation = size * 0.5
        
        // 파티클 페이드아웃을 위한 알파 변화
        let alphaSequence = SCNParticlePropertyController()
        let animation = CAKeyframeAnimation()
        animation.values = [0.0, 0.8, 0.0] as [NSNumber]  // NSNumber 배열로 명시적 타입 변환
        animation.duration = lifetime
        alphaSequence.animation = animation
        system.propertyControllers = [SCNParticleSystem.ParticleProperty.opacity: alphaSequence]
        
        return system
    }

    // 부드러운 원형 파티클 이미지 생성
    private func generateSmoothParticle() -> UIImage {
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2.0
            
            // 그라데이션 생성
            let colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors as CFArray,
                                    locations: [0.0, 1.0])!
            
            // 원형 그라데이션 그리기
            context.cgContext.drawRadialGradient(gradient,
                                               startCenter: center,
                                               startRadius: 0,
                                               endCenter: center,
                                               endRadius: radius,
                                               options: .drawsBeforeStartLocation)
        }
        
        return image
    }
    
    private func emitWaveFront() {
        let waveFront = createSphericalWaveFront()
        waveFronts.append(waveFront)
        addChildNode(waveFront)
        
        animateWaveFront(waveFront)
        
        if waveFronts.count > maxWaves {
            waveFronts.first?.removeFromParentNode()
            waveFronts.removeFirst()
        }
    }
    
    private func createSphericalWaveFront() -> SCNNode {
        // 구형 메시 생성
        let sphere = SCNSphere(radius: 0.1)
        sphere.segmentCount = 48  // 높은 해상도
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.emission.contents = UIColor(
            red: CGFloat(currentProperties.color.x),
            green: CGFloat(currentProperties.color.y),
            blue: CGFloat(currentProperties.color.z),
            alpha: 0.3
        )
        material.transparent.contents = UIColor.white
        material.transparency = 0.8
        material.lightingModel = .constant
        
        sphere.materials = [material]
        
        return SCNNode(geometry: sphere)
    }
    
    private func animateWaveFront(_ node: SCNNode) {
        let duration = 2.0
        let finalScale = 20.0 + Double(currentProperties.energy * 10.0)
        
        // 비선형 확장 애니메이션
        let scaleAction = SCNAction.customAction(duration: duration) { node, elapsedTime in
            let progress = elapsedTime / CGFloat(duration)
            let scale = CGFloat(finalScale) * pow(progress, 0.7)  // 비선형 스케일링
            node.scale = SCNVector3(scale, scale, scale)
        }
        
        // 페이드아웃 애니메이션
        let fadeAction = SCNAction.customAction(duration: duration) { node, elapsedTime in
            let progress = elapsedTime / CGFloat(duration)
            if let material = node.geometry?.materials.first {
                let alpha = pow(1 - progress, 2.0) * 0.3  // 비선형 페이드아웃
                material.emission.contents = UIColor(
                    red: CGFloat(self.currentProperties.color.x),
                    green: CGFloat(self.currentProperties.color.y),
                    blue: CGFloat(self.currentProperties.color.z),
                    alpha: CGFloat(alpha)
                )
            }
        }
        
        // 왜곡 애니메이션 (주파수에 따른 변형)
        let deformAction = SCNAction.customAction(duration: duration) { node, elapsedTime in
            if let sphere = node.geometry as? SCNSphere {
                sphere.segmentCount = Int(48.0 * (1.0 - elapsedTime / CGFloat(duration)))
            }
        }
        
        let groupAction = SCNAction.group([scaleAction, fadeAction, deformAction])
        let removeAction = SCNAction.removeFromParentNode()
        let sequence = SCNAction.sequence([groupAction, removeAction])
        
        node.runAction(sequence)
    }
    
    func updateEnergy(_ properties: RippleProperties) {
        self.currentProperties = properties
        
        let currentTime = CACurrentMediaTime()
        if currentTime - lastEmissionTime >= emissionInterval && currentProperties.energy > 0.1 {
            emitWaveFront()
            lastEmissionTime = currentTime
            
            // 파티클 시스템 업데이트
            updateParticleSystems()
        }
    }
    
    private func updateParticleSystems() {
        for node in waveParticleSystems {
            if let system = node.particleSystems?.first {
                // 에너지에 따른 파티클 방출 속도 조정
                system.birthRate = CGFloat(Float(1000 * currentProperties.energy))
                system.particleVelocity = CGFloat(2.0 + currentProperties.energy * 3.0)
                
                // 색상 업데이트
                system.particleColor = UIColor(
                    red: CGFloat(currentProperties.color.x),
                    green: CGFloat(currentProperties.color.y),
                    blue: CGFloat(currentProperties.color.z),
                    alpha: CGFloat(currentProperties.color.w)
                )
            }
        }
    }
}
