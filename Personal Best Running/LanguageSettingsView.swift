// LanguageSettingsView
// Presents a list of language options. Stores the user's selection and
// requests a relaunch so the system can load the proper localization on next launch.
// Also resolves certain strings (like the relaunch alert and the "System Default" label)
// in the target language so the user immediately sees their choice reflected.

import SwiftUI

// View for selecting the app's language preference.
struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    // Persist the chosen language code. Nil (or "system") means follow the device's language.
    @AppStorage("appLanguageCode") private var appLanguageCode: String? // nil or "system" means System Default
    @State private var showRelaunchAlert = false
    @State private var pendingAlertTitle: String = ""
    @State private var pendingAlertMessage: String = ""

    // Simple model for the list rows: `id` is the language code (or "system"), `title` is the display name.
    private struct LanguageOption: Identifiable, Hashable {
        let id: String // code or "system"
        let title: String
    }

    // Supported language choices shown to the user. Endonyms are used for language names.
    private let options: [LanguageOption] = [
        LanguageOption(id: "system", title: "System Default"),
        LanguageOption(id: "de", title: "Deutsch"),
        LanguageOption(id: "en", title: "English"),
        LanguageOption(id: "es", title: "Español"),
        LanguageOption(id: "fr", title: "Français"),
        LanguageOption(id: "it", title: "Italiano"),
        LanguageOption(id: "ja", title: "日本語"),
        LanguageOption(id: "zh-Hans", title: "简体中文")
    ]

    // Currently active selection derived from persisted storage. Falls back to "system".
    private var currentSelection: String {
        if let code = appLanguageCode, code != "" { return code }
        return "system"
    }

    // The "System Default" label rendered in the currently selected target language.
    // If the user selected a specific language, use that code; otherwise use the app's current language.
    private var localizedSystemDefaultTitle: String {
        // Use the currently selected language code for the label; nil means follow system
        let code = (currentSelection == "system") ? nil : currentSelection
        return localized("System Default", for: code)
    }

    // Resolve a localized string for a specific language code by loading its .lproj bundle.
    // Special-case: if English ("en") is selected but no en.lproj exists (common when English is the
    // development language), fall back to Base.lproj. Otherwise fall back to the main bundle (system language).
    private func localized(_ key: String, for code: String?) -> String {
        // If explicit language code is provided and not "system", try to resolve its .lproj bundle
        if let code, !code.isEmpty, code != "system" {
            // 1) Try the language-specific lproj
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle.localizedString(forKey: key, value: nil, table: nil)
            }
            // 2) If English is selected but no en.lproj exists, fall back to Base.lproj (common when English is the development language)
            if code == "en",
               let basePath = Bundle.main.path(forResource: "Base", ofType: "lproj"),
               let baseBundle = Bundle(path: basePath) {
                return baseBundle.localizedString(forKey: key, value: nil, table: nil)
            }
        }
        // 3) Fallback: use main bundle resolution (system/app language)
        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }

    var body: some View {
        List {
            // Show the list of options with a checkmark for the current selection. Footer reminds about relaunch.
            Section(footer: Text("Changes take effect after you relaunch the app.")) {
                ForEach(options) { option in
                    HStack {
                        if option.id == "system" {
                            Text(localizedSystemDefaultTitle)
                        } else {
                            Text(option.title)
                        }
                        Spacer()
                        if option.id == currentSelection {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Update persisted preference (nil means follow system)
                        if option.id == "system" {
                            appLanguageCode = nil
                        } else {
                            appLanguageCode = option.id
                        }
                        // Apply AppleLanguages override so the next cold launch uses the chosen language
                        LanguageManager.applyPreferredLanguageOverride(code: appLanguageCode ?? "system")
                        // Pre-resolve alert strings in the target language so the prompt appears localized immediately
                        let selectedCode = (option.id == "system") ? nil : option.id
                        pendingAlertTitle = localized("Relaunch Required", for: selectedCode)
                        pendingAlertMessage = localized("Please relaunch the app for the language change to take effect.", for: selectedCode)
                        showRelaunchAlert = true
                    }
                }
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        // Alert prompting the user to relaunch. Title and message are already localized to the selected language.
        .alert(pendingAlertTitle, isPresented: $showRelaunchAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(pendingAlertMessage)
        }
    }
}

// Minimal helper to write/remove the AppleLanguages override and to re-apply it at app startup.
struct LanguageManager {
    static func applyPreferredLanguageOverride(code: String?) {
        let defaults = UserDefaults.standard
        if let code, !code.isEmpty, code != "system" {
            defaults.set([code], forKey: "AppleLanguages")
        } else {
            defaults.removeObject(forKey: "AppleLanguages")
        }
        defaults.synchronize()
    }

    static func applyOnLaunchFromStoredPreference() {
        let code = UserDefaults.standard.string(forKey: "appLanguageCode")
        applyPreferredLanguageOverride(code: code)
    }
}

#Preview {
    NavigationStack { LanguageSettingsView() }
}
