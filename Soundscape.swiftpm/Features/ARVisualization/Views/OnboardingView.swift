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
                    Text("Experience Sound Visualization")
                        .font(.system(size: isIPad ? 46 : 34, weight: .bold))
                        .padding(.top, 32)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity) // 텍스트 중앙 정렬을 위해 추가
                    
                    VStack(alignment: .leading, spacing: 24) {
                        FeatureRow(
                            symbolName: "ear.and.waveform",
                            title: "Audio Visualization",
                            description: "Experience sound in a whole new visual dimension",
                            color: .purple
                        )
                        
                        FeatureRow(
                            symbolName: "arrow.up.and.down.and.arrow.left.and.right",
                            title: "Free Positioning",
                            description: "Place the sound source anywhere in your space",
                            color: .blue
                        )
                        
                        FeatureRow(
                            symbolName: "paintpalette.fill",
                            title: "Rich Visual Effects",
                            description: "Watch as different frequencies create unique patterns",
                            color: .orange
                        )
                    }
                    .frame(maxWidth: isIPad ? 600 : .infinity)
                    .padding(.bottom)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: isIPad ? 400 : .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom, 32)
                }
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity) // VStack을 전체 너비로 확장
                .padding(.horizontal, 24) // 패딩을 VStack 전체에 적용
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

#Preview{
    OnboardingView()
}
