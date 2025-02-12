// swift-tools-version: 6.0

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Soundscape",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "Soundscape",
            targets: ["AppModule"],
            bundleIdentifier: "com.onemorethink.Soundscape",
            teamIdentifier: "ZWTS2P7AH7",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .beachball),
            accentColor: .presetColor(.yellow),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .microphone(purposeString: "The app uses the camera to create an augmented reality experience, allowing visual elements to interact with your surroundings"),
                .camera(purposeString: "The app uses the microphone to capture audio for real-time visualization in augmented reality space")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ],
    swiftLanguageVersions: [.version("6")]
)