import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case system = "Sistema"
    case light = "Chiaro"
    case dark = "Scuro"
}

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
