import SwiftUI

@main
struct Personal_Best_RunningApp: App {
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                 .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
