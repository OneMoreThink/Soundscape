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
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session = session
        arView.automaticallyUpdatesLighting = true
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
