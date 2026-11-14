import SwiftUI

@main
struct FluxApp: App {
    @StateObject private var store = StudioStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(store.settings.accent.color)
        }
    }
}
