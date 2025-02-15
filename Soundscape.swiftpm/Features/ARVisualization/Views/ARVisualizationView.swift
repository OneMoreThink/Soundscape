//
//  ARVisualizationView.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import SwiftUI

struct ARVisualizationView: View {
    @StateObject private var viewModel = ARVisualizationViewModel()
    
    var body: some View {
        ZStack{
            // ARView
            ARViewContainer(session: viewModel.arSystem.session)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                debugPanel
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
            }
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unknown error occurred")
        }
        .onAppear {
            viewModel.startCapture()
        }
        .onDisappear {
            viewModel.stopCapture()
        }
      
    }
    
    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Visualization Debug")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Audio Amplitude: \(viewModel.currentAmplitude, specifier: "%.2f")")
                .foregroundColor(.green)
            
            if let arData = viewModel.currentARData {
                Group {
                    Text("Camera Position:")
                        .foregroundColor(.white)
                    Text("X: \(arData.cameraTransform.columns.3.x)")
                    Text("Y: \(arData.cameraTransform.columns.3.y)")
                    Text("Z: \(arData.cameraTransform.columns.3.z)")
                }
                .foregroundColor(.green)
                .font(.system(.body, design: .monospaced))
                
                Text("Detected Planes: \(arData.detectedPlanes.count)")
                    .foregroundColor(.white)
                
                if let lightEstimate = arData.lightEstimate {
                    Text("Light Intensity: \(lightEstimate.ambientIntensity)")
                        .foregroundColor(.white)
                }
            } else {
                Text("Waiting for AR data...")
                    .foregroundColor(.yellow)
            }
        }
    }
}

#Preview {
    ARVisualizationView()
}
