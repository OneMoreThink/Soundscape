//
//  SwiftUIView.swift
//  Soundscape
//
//  Created by 이종선 on 2/19/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    Text("Sound Waves in AR")
                        .font(.system(size: isIPad ? 46 : 34, weight: .bold))
                        .padding(.top, 32)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    Text("See and feel your music in augmented reality")
                        .font(.system(size: isIPad ? 20 : 17))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        FeatureRow(
                            symbolName: "speaker.wave.3.fill",
                            title: "3D Sound Visualization",
                            description: "Watch as your music comes to life with colorful waves and particles in your space",
                            color: .purple
                        )
                        
                        FeatureRow(
                            symbolName: "cube.transparent.fill",
                            title: "Place Sound Anywhere",
                            description: "Drag and position the sound source freely in your environment",
                            color: .blue
                        )
                        
                        FeatureRow(
                            symbolName: "waveform.circle.fill",
                            title: "Frequency-Based Effects",
                            description: "Different colors and patterns react to bass, mid, and high frequencies",
                            color: .orange
                        )
                    }
                    .frame(maxWidth: isIPad ? 600 : .infinity)
                    .padding(.bottom)
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Start Experience")
                                .font(.headline)
                                .frame(maxWidth: isIPad ? 400 : .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                    }
                    .padding(.bottom, 32)
                }
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct FeatureRow: View {
    let symbolName: String
    let title: String
    let description: String
    let color: Color
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: isIPad ? 32 : 28))
                .foregroundColor(color)
                .frame(width: isIPad ? 50 : 44)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: isIPad ? 20 : 17, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(description)
                    .font(.system(size: isIPad ? 16 : 15))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    OnboardingView()
}
