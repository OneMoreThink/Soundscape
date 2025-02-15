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
        VStack {
            // 진폭을 시각화하는 간단한 막대
            Rectangle()
                .fill(Color.blue)
                .frame(width: CGFloat(viewModel.currentAmplitude) * 5000, height: 500)
                .animation(.linear(duration: 0.1), value: viewModel.currentAmplitude)
            
            // 시작/정지 버튼
            Button(action: {
                viewModel.startAudioCapture()
            }) {
                Text("Start Capture")
            }
            .padding()
            
            // 에러 표시
            if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

#Preview {
    ARVisualizationView()
}
