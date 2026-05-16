import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HUDViewModel()

    var body: some View {
        HUDView(viewModel: viewModel)
            .frame(
                minWidth: DesignTokens.Layout.hudMinWidth,
                idealWidth: DesignTokens.Layout.hudIdealWidth,
                maxWidth: DesignTokens.Layout.hudMaxWidth
            )
            .frame(
                minHeight: DesignTokens.Layout.hudMinHeight,
                idealHeight: DesignTokens.Layout.hudIdealHeight,
                maxHeight: DesignTokens.Layout.hudMaxHeight
            )
            .onAppear {
                viewModel.startMockCycle()
            }
            .onDisappear {
                viewModel.stopAllTimers()
            }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
