//
//  ARVisualizationView.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//
import ARKit
import SwiftUI

struct ARVisualizationView: View {
    @StateObject private var viewModel: ARVisualizationViewModel
    
    init() {
        // ARSCNView 생성을 위한 클로저 준비
        let viewModelInit = ARVisualizationViewModel()
        _viewModel = StateObject(wrappedValue: viewModelInit)
    }
    
    var body: some View {
        ZStack {
            // ARViewContainer에 콜백 전달
            ARViewContainer(session: viewModel.arSystem.session) { arView in
                viewModel.setARView(arView)  // ViewModel에 ARSCNView 전달
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            viewModel.startCapture()
        }
        .onDisappear {
            viewModel.stopCapture()
        }
    }
}

#Preview {
    ARVisualizationView()
}
