import SwiftUI
import Combine
import StoreKit

// MARK: - SettingsView
//
// App settings view: language, theme, measurement system, runner profile, and legal links.
struct SettingsView: View {
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject var storeKitManager: StoreKitManager
    @State private var showSexInfo = false
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage("isPremiumUser") private var isPremiumUser = false

    // Supported languages
    let languages = [
        ("Italiano", "it"),
        ("English", "en"),
        ("Español", "es"),
        ("Français", "fr")
    ]
    
    var body: some View {
        List {
            Section(header: HStack { Text("Informazioni e supporto").font(.title3) }.padding(.top, 20)) {
                
                // 1 - Method basics
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
                
                // 2 - Help
                NavigationLink(destination: HelpView()) {
                    Label {
                        Text("Guida")
                            .foregroundColor(.primary)
                        
                    } icon: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                // 3 - Support
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
                
                // 4 - App version
                HStack {
                    Label {
                        Text("Versione")
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

             Section(header: Text("Account").font(.title3)) {
                
                // 1 - Product level
                HStack {
                    Label {
                        Text("Livello Prodotto:")
                    } icon: {
                        Image(systemName: "person.badge.shield.checkmark")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    
                    Spacer()
                    
                    if isPremiumUser {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.footnote)
                                .foregroundColor(.yellow)
                            Text("Premium")
                                .font(.system(.subheadline, design: .rounded, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Base (gratuito)")
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 2 - View premium offer-
                if !isPremiumUser {
                    NavigationLink(destination: PremiumInfoView()) {
                        Label {
                            Text("Visualizza l'offerta premium")
                        } icon: {
                            Image(systemName: "crown")
                            .font(.footnote)
                        .foregroundColor(.secondary)}
                    }
                }
                
                // 3 - restore purchase
                if !isPremiumUser {
                    Button {
                        Task {
                            await storeKitManager.restorePurchases()
                        }
                    } label: {
                        Label {
                            Text("Ripristina l'acquisto")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "icloud.and.arrow.down")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                  
                // 4 - Rate this App
                 Button {
                    requestAppReview()
                } label: {
                    Label {
                        Text("Valuta questa App")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "star")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }
            } 
            
            Section(header: Text("Preferenze").font(.title3)) {
                
                // 1 - Runner gender
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
                
                // 2 - Measurement system
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
                            Text(theme.localizedAppTheme).tag(theme)
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .labelsHidden()
                    .pickerStyle(.navigationLink)
                    .frame(minWidth: 80, maxWidth: 150, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                }
                
                // 4 - Language
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
            
#if DEBUG
            Section(header: Text("Debug").font(.title3)) {
                
                // to play with premium status
                Toggle(isOn: $isPremiumUser) {
                    Label("Premium User", systemImage: "crown")
                }
                .foregroundStyle(.blue)
                
            }
#endif
            
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

private func requestAppReview() {
    // Deep-link directly to the App Store review composer.
    // Reads the Apple App ID from Info.plist (AppStoreAppID key).
    // This works in both production and sandbox/test builds.
    let appID = Bundle.main.object(forInfoDictionaryKey: "AppStoreAppID") as? String ?? ""
    guard !appID.isEmpty, let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") else {
        print("[Review] App Store App ID not configured. Add 'AppStoreAppID' to Info.plist.")
        return
    }

    #if DEBUG
    print("[Review] Opening review URL: \(url.absoluteString)")
    #endif

    UIApplication.shared.open(url)
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(ThemeManager())
            .environmentObject(LanguageManager())
            .environment(\.locale, .init(identifier: "it"))
    }
}
