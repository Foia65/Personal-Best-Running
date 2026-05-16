import SwiftUI

struct SettingsView: View {
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @EnvironmentObject private var themeManager: ThemeManager

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
    
    @AppStorage("selectedLanguage") private var selectedLanguageID: String = "system"
    var onChange: ((String) -> Void)? 
    
    var body: some View {
        List {
            // Sezione Runner
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Sesso", selection: $runnerSex) {
                        ForEach(RunnerSex.allCases) { sex in
                            Label(sex.label, systemImage: sex.icon).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    DisclosureGroup("Come influisce il sesso?") {
                        Text("""
                            Il sesso NON ha alcun ruolo nel calcolo del VDOT, \
                            ma viene considerato per contestualizzare la valutazione del livello \
                            ("principiante", "intermedio" o "avanzato") in base al genere del runner.
                            """)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 15)
                }
                .padding(.top, 10)
            } header: {
                Text("Runner")
                    .padding(.top, 20)
            }
            
            // Sezione Sistema di misura
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Unità", selection: $unitSystem) {
                        ForEach(UnitSystem.allCases) { system in
                            Text(system.label).tag(system)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    DisclosureGroup("Cosa cambia?") {
                        Text("Distanze in miglia (mi) anziché chilometri (km), passi in /mi anziché /km.")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 15)
                    
                }
                .padding(.top, 10)
            } header: {
                Text("Sistema di misura")
            }
            
            // Sezione App Theme
            Section {
                Picker("tema", selection: $themeManager.selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .padding(10)
            } header: {
                Text("Aspetto")
            }

            Section {
                VStack {
                    Picker("Lingua", selection: $selectedLanguageID) {
                        ForEach(options) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .font(.subheadline)
                    .bold()
                    .pickerStyle(.menu)
                    .onChange(of: selectedLanguageID) {
                        onChange?(selectedLanguageID)
                    }
                Text("\n 🔨 🪛 🔧 🪚  work in progress... ")
                        .foregroundStyle(.red)
                }
            //    .font(.system(.subheadline, design: .default, weight: .semibold))
            }
            
        }
//        .navigationTitle("Impostazioni")
//        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
