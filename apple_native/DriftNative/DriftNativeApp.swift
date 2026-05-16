import SwiftUI

@main
struct DriftNativeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(
            width: DesignTokens.Layout.hudIdealWidth,
            height: DesignTokens.Layout.hudIdealHeight
        )
        .windowResizability(.contentSize)
    }
}
