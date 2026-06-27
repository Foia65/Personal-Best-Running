import SwiftUI
import Combine

struct AppColors {
 static let themeNavy = Color(red: 0.0, green: 0.0, blue: 0.3)
}  

func formatTime(_ seconds: Double) -> String {
    let ore = Int(seconds) / 3600
    let min = (Int(seconds) % 3600) / 60
    let sec = Int(seconds) % 60
    if ore > 0 { return String(format: "%d:%02d:%02d", ore, min, sec) }
    return String(format: "%d:%02d", min, sec)
}

// MARK: - LanguageManager
class LanguageManager: ObservableObject {

    static let supportedLanguageCodes = ["it", "en"]

    // Saves the language identifier (e.g. "it", "en") to UserDefaults
    @AppStorage("selected_language") var selectedLanguage: String = "en" {
        didSet {
            objectWillChange.send()
        }
    }

    // Converts the string to a Locale object usable by SwiftUI
    var currentLocale: Locale {
        Locale(identifier: selectedLanguage)
    }

    init() {
        #if DEBUG
        print("[LanguageManager] Init. UserDefaults selected_language exists: \(UserDefaults.standard.object(forKey: "selected_language") != nil)")
        print("[LanguageManager] Bundle.preferredLocalizations: \(Bundle.main.preferredLocalizations)")
        print("[LanguageManager] Locale.current.identifier: \(Locale.current.identifier)")
        print("[LanguageManager] Locale.current.language.languageCode: \(Locale.current.language.languageCode?.identifier ?? "nil")")
        print("[LanguageManager] Bundle.main.developmentLocalization: \(Bundle.main.developmentLocalization ?? "nil")")
        print("[LanguageManager] Locale.preferredLanguages: \(Locale.preferredLanguages)")
        #endif

        if UserDefaults.standard.object(forKey: "selected_language") == nil {
            let resolved = Self.systemLanguageCode()
            #if DEBUG
            print("[LanguageManager] First launch — resolved system language: \(resolved)")
            #endif
            selectedLanguage = resolved
        }

        #if DEBUG
        print("[LanguageManager] Final selectedLanguage: \(selectedLanguage)")
        #endif
    }

    private static func systemLanguageCode() -> String {
        let deviceCode = Locale.preferredLanguages
            .compactMap { Locale(identifier: $0).language.languageCode?.identifier }
            .first { Self.supportedLanguageCodes.contains($0) }
        return deviceCode ?? "en"
    }
}
