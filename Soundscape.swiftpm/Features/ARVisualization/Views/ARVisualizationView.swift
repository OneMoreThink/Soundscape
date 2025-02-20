//
//  ARVisualizationView.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//
import ARKit
import SwiftUI

struct ARVisualizationView: View {
    @ObservedObject private var viewModel: ARVisualizationViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    
    init(viewModel: ARVisualizationViewModel) {
        self.viewModel = viewModel
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
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
                .onDisappear {
                    hasSeenOnboarding = true
                }
        }
    }
}

