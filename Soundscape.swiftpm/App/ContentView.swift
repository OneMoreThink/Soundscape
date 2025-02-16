import SwiftUI

struct ContentView: View {
    @StateObject private var permissionManager = PermissionManager()
    
    var body: some View {
        Group {
            if permissionManager.hasRequiredPermissions {
                ARVisualizationView()
            } else {
                PermissionStatusView(permissionManager: permissionManager)
            }
        }
        .task {
            permissionManager.checkPermissionStatus()
            await permissionManager.requestPermissions()
        }
    }
}
