import SwiftUI
import Combine

/// App-wide theme options.
enum AppTheme: String, CaseIterable {
    case system = "Sistema"
    case light = "Chiaro"
    case dark = "Scuro"
 
    var localizedAppTheme: LocalizedStringResource {
        switch self {
        case .system:
            return LocalizedStringResource("AppTheme.label.system", defaultValue: "Sistema")
        case .light:
            return LocalizedStringResource("AppTheme.label.light", defaultValue: "Chiaro")
        case .dark:
            return LocalizedStringResource("AppTheme.label.dark", defaultValue: "Scuro")
        }
    }
    
}

/// Manages the app's color scheme preference and applies it globally.
class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme = .system {
        didSet {
            saveToStorage()
            updateColorScheme()
        }
    }

    @Published var colorScheme: ColorScheme?

    private let storageKey = "selectedTheme"

    init() {
        if let storedValue = UserDefaults.standard.string(forKey: storageKey),
           let theme = AppTheme(rawValue: storedValue) {
            selectedTheme = theme
        } else {
            selectedTheme = .system
        }
        updateColorScheme()
    }

    private func saveToStorage() {
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: storageKey)
    }

    private func updateColorScheme() {
        switch selectedTheme {
        case .system:
            colorScheme = nil
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }
}
