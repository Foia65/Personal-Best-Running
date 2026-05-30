import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    // Salva l'identificatore della lingua (es. "it", "en") in UserDefaults
    @AppStorage("selected_language") var selectedLanguage: String = "it" {
        didSet {
            // Notifica i cambiamenti alle viste
            objectWillChange.send()
        }
    }
    
    // Converte la stringa in un oggetto Locale utilizzabile da SwiftUI
    var currentLocale: Locale {
        Locale(identifier: selectedLanguage)
    }
}

struct SettingsView: View {
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showSexInfo = false
    @EnvironmentObject var languageManager: LanguageManager
    
    // Lingue supportate
    let languages = [
        ("Italiano", "it"),
        ("English", "en")
    ]
    
    var body: some View {
        List {
            Section(header: HStack { Text("Informazioni e supporto").font(.title3) }.padding(.top, 20)) {
                
                // 1 - Le basi del metodo
                NavigationLink(destination: MethodologyView()) {
                    Label {
                        Text("Le basi del metodo")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                // 2 - Aiuto
                NavigationLink(destination: HelpView()) {
                    Label {
                        Text("Aiuto")
                            .foregroundColor(.primary)
                        
                    } icon: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                // 3 - supporto
                Button {
                    if let url = URL(string: "mailto:info.foiasoft@gmail.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label {
                        Text("Contatta il supporto")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                // 4 - versione app
                HStack {
                    Label {
                        Text("Versione: ")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "shippingbox")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    Spacer()
                    Text("\(Bundle.main.appVersionDisplay) (\(Bundle.main.appBuild))")
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundColor(.secondary)
                    
                }
            }
            
            Section(header: Text("Preferenze").font(.title3)) {
                
                // 1 - Sesso runner
                HStack {
                    Label {
                        Text("Genere")
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .layoutPriority(1)
                    } icon: {
                        Image(systemName: "person")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        showSexInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Picker("", selection: $runnerSex) {
                        ForEach(RunnerSex.allCases) { sex in
                            Text(sex.localizedGender).tag(sex)
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .labelsHidden()
                    .pickerStyle(.navigationLink)
                    .frame(minWidth: 90, maxWidth: 130, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .sheet(isPresented: $showSexInfo) {
                    NavigationStack {
                        ScrollView {
                            Text("""
                            Il sesso biologico NON influisce sul calcolo del VDOT.
                            
                            Viene utilizzato esclusivamente per contestualizzare \
                            la valutazione del livello del runner \
                            (principiante, intermedio o avanzato).
                            """)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .navigationTitle("Informazioni")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .presentationDetents([.medium])
                }
                
                // 2 - Sistema di misura
                HStack {
                    Label {
                        Text("Sistema di misura")
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .layoutPriority(1)
                    } icon: {
                        Image(systemName: "ruler")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $unitSystem) {
                        ForEach(UnitSystem.allCases, id: \.self) { system in
                            Text(system.localizedUnitSystem).tag(system)
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .labelsHidden()
                    .pickerStyle(.navigationLink)
                    .frame(minWidth: 80, maxWidth: 130, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                }
                
                // 3 - App Theme
                HStack {
                    Label {
                        Text("Aspetto dell'App")
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .layoutPriority(1)
                    } icon: {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .labelsHidden()
                    .pickerStyle(.navigationLink)
                    .frame(minWidth: 80, maxWidth: 150, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                }
                
                // 4 - Lingua
                HStack {
                    Label {
                        Text("Lingua")
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .layoutPriority(1)
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    Spacer()
                    Picker("", selection: $languageManager.selectedLanguage) {
                        ForEach(languages, id: \.1) { name, code in
                            Text(name).tag(code)
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .pickerStyle(.navigationLink) 
                }
            }
            
            Section(header: Text("Privacy e Sicurezza").font(.title3)) {
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label {
                        Text("Informativa Privacy")
                    } icon: {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    Label {
                        Text("Termini di utilizzo")
                    } icon: {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
            }
        }
        .font(.system(.subheadline, design: .default, weight: .semibold))
        .environment(\.defaultMinListRowHeight, 28)
        
    }
}

// Convenience accessors for app version and build information.
extension Bundle {
    var appVersionDisplay: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    
    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(ThemeManager())
            .environmentObject(LanguageManager())
    }
}
