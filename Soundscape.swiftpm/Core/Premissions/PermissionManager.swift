//
//  PermissionManager.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import AVFoundation

@MainActor
class PermissionManager: ObservableObject {
    @Published private(set) var microphonePermission: PermissionStatus = .notDetermined
    @Published private(set) var cameraPermission: PermissionStatus = .notDetermined
    
    enum PermissionStatus {
        case notDetermined
        case denied
        case authorized
    }
    
    // Check current permission states
    func checkPermissionStatus() {
        // Check microphone
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphonePermission = .authorized
        case .denied:
            microphonePermission = .denied
        case .undetermined:
            microphonePermission = .notDetermined
        @unknown default:
            microphonePermission = .notDetermined
        }
        
        // Check camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermission = .authorized
        case .denied:
            cameraPermission = .denied
        case .notDetermined:
            cameraPermission = .notDetermined
        case .restricted:
            cameraPermission = .denied
        @unknown default:
            cameraPermission = .notDetermined
        }
    }
    
    // Convenience method to check if all required permissions are granted
    var hasRequiredPermissions: Bool {
        return microphonePermission == .authorized && cameraPermission == .authorized
    }
    
    func requestPermissions() async {
        // 마이크 권한 요청
        await requestMicrophonePermission()
        
        // 카메라 권한 요청
        await requestCameraPermission()
    }
    
    func requestMicrophonePermission() async {
        let microphoneGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        microphonePermission = microphoneGranted ? .authorized : .denied
    }
    
    func requestCameraPermission() async {
        let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        cameraPermission = cameraGranted ? .authorized : .denied
    }

}
