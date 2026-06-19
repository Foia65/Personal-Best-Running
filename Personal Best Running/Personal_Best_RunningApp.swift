import SwiftUI

@main
struct Personal_Best_RunningApp: App {

    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var storeKitManager = StoreKitManager.shared

    init() {
        #if DEBUG
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
                .environmentObject(storeKitManager)
                .background(Color(.systemBackground))
        }
    }
}
