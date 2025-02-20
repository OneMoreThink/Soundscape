import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ARVisualizationViewModel()
    @StateObject private var permissionManager = PermissionManager()
    @State private var isChecking = true
    
    var body: some View {
        
        Group{
            if isChecking {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                if permissionManager.hasRequiredPermissions {
                    ARVisualizationView(viewModel: vm)
                } else {
                    PermissionStatusView(permissionManager: permissionManager)
                }
            }
        }
        .onAppear {
            permissionManager.checkPermissionStatus()
            isChecking = false
            
            vm.startCapture()
        }
        .onDisappear{
            vm.stopCapture()
        }
    }
}
