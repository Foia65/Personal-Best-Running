import SwiftUI

// MARK: - PersonalBestRunningApp
//
// Main app entry point. Configures theme, language, and launches with a splash screen.
@main
struct Personal_Best_RunningApp: App {

    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()

    init() {
        #if DEBUG
        // Clear launch screen snapshot cache to reset visual bugs
        if let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let snapshotsPath = cachePath.appendingPathComponent("Snapshots")
            try? FileManager.default.removeItem(at: snapshotsPath)
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.currentLocale)
                .background(Color(.systemBackground))
        }
    }
}
