//
//  ARViewRepresentable.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import ARKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    let session: ARSession
    let onARViewCreated: (ARSCNView) -> Void  // ARSCNView 생성 시 콜백 추가
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session = session
        arView.automaticallyUpdatesLighting = true
        
        // 뷰가 생성되면 콜백 호출
        onARViewCreated(arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
