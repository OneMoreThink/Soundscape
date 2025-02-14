//
//  PremissionStatusView.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import SwiftUI

struct PermissionStatusView: View {
    @ObservedObject var permissionManager: PermissionManager
    
    var body: some View {
        VStack(spacing: 24) {
            // 상단 헤더
            Text("Permissions Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This app needs camera and microphone access to create AR audio visualizations")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // 권한 상태 카드들
            VStack(spacing: 16) {
                // 마이크 권한 상태 카드
                PermissionCard(
                    title: "Microphone",
                    description: "Used for audio visualization",
                    status: permissionManager.microphonePermission,
                    systemImage: "mic.fill"
                )
                // 카메라 권한 상태 카드
                PermissionCard(
                    title: "Camera",
                    description: "Used for AR experience",
                    status: permissionManager.cameraPermission,
                    systemImage: "camera.fill"
                )
            }
            .padding(.horizontal)
        }
    }
}

// 각 권한을 표시하는 카드 뷰
private struct PermissionCard: View {
    let title: String
    let description: String
    let status: PermissionManager.PermissionStatus
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 32)
            
            // 텍스트 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            // 권한이 거부된 경우에만 설정으로 이동하는 버튼 표시
            if status == .denied {
                Button {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
                .frame(width: 44)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // 권한 상태에 따른 색상
    private var statusColor: Color {
        switch status {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        }
    }
    
    // 권한 상태에 따른 텍스트
    private var statusText: String {
        switch status {
        case .authorized:
            return "Access granted"
        case .denied:
            return "Access denied - Please enable in Settings"
        case .notDetermined:
            return "Permission needed"
        }
    }
}


struct PermissionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        let permissionManager = PermissionManager()
        PermissionStatusView(permissionManager: permissionManager)
            .padding()
    }
}
