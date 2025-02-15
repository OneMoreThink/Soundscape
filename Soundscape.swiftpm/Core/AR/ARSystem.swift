//
//  ARSystem.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import ARKit
import Combine

struct ARData {
    // 카메라의 현재 위치와 방향
    let cameraTransform: simd_float4x4
    // 감지된 평면들의 위치와 크기
    let detectedPlanes: [ARPlaneAnchor]
    // 주변 조명 정보
    let lightEstimate: ARLightEstimate?
    // AR 프레임이 캡처된 시간
    let timestamp: TimeInterval
}

final class ARSystem: NSObject {
    let session = ARSession()
    private let subject = PassthroughSubject<ARData, Error>()
    
    var arStream: AnyPublisher<ARData, Error> {
        subject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        session.delegate = self
    }
    
    func start() throws {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        session.run(configuration)
    }
    
    func stop() {
        session.pause()
    }
}

extension ARSystem: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let arData = ARData(
            cameraTransform: frame.camera.transform,
            detectedPlanes: session.currentFrame?
                .anchors.compactMap { $0 as? ARPlaneAnchor } ?? [],
            lightEstimate: frame.lightEstimate,
            timestamp: frame.timestamp
        )
        
        subject.send(arData)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        subject.send(completion: .failure(error))
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        let error = NSError(domain: "ARSystem", code: 100, userInfo: [NSLocalizedDescriptionKey: "AR Session was interrupted"])
        subject.send(completion: .failure(error))
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        do {
            try start()
        } catch {
            subject.send(completion: .failure(error))
        }
    }
}

