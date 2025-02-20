import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ARVisualizationViewModel()
    
    var body: some View {
        ARVisualizationView(viewModel: vm)
            .onAppear {
                vm.startCapture()
            }
            .onDisappear{
                vm.stopCapture()
            }
    }
}
