import SwiftUI

struct ContentView: View {
    @StateObject private var telemetryProvider = MockTelemetryProvider()

    var body: some View {
        HUDView(
            snapshot: telemetryProvider.currentSnapshot,
            advanceAction: telemetryProvider.advance
        )
        .frame(minWidth: 360, idealWidth: 420, maxWidth: 480)
        .frame(minHeight: 500, idealHeight: 540, maxHeight: 620)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
