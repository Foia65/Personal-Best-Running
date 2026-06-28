import SwiftUI
import UIKit

// MARK: - ContentView

// MARK: - Color Extension

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

struct PerformanceBounds {
    let minSeconds: Double
    let maxSeconds: Double
}

struct ContentView: View {
    @State private var plan: TrainingPlan?
    @State private var showingPlan = false
    @State private var selectedTab = 0
    @State private var previousTab = 0 // Stores the last valid tab index to restore after premium alert dismissal
    @State private var showingPremiumSheet = false
    @State private var showingPremiumAlert = false
    @EnvironmentObject private var languageManager: LanguageManager
    @AppStorage("isPremiumUser") private var isPremiumUser = false
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    AppColors.themeNavy
                        .ignoresSafeArea(edges: .top)
                    HStack {
                        Image(systemName: "figure.run")
                        Text("Personal Best Running")
                    }
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                
                TabView(selection: $selectedTab) {
                    PlanInputView(
                        onGenerate: { newPlan in
                            self.plan = newPlan
                            self.showingPlan = true
                            self.selectedTab = 1
                        },
                        onReset: {
                            self.plan = nil
                            self.selectedTab = 0
                        }
                    )
                    .tabItem {
                        Image(systemName: "target")
                        Text("Obiettivo")
                    }
                    .tag(0)
                    
                    Group {
                        if let plan = plan {
                            TrainingPlanView(plan: plan) {
                                self.plan = nil
                                self.selectedTab = 0
                            }
                        } else {
                            EmptyStateView(icon: "calendar.badge.plus")
                        }
                    }
                    .environmentObject(languageManager)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Piano")
                    }
                    .tag(1)
                    
                    Group {
                        if let plan = plan {
                            PacesView(plan: plan)
                        } else {
                            EmptyStateView(icon: "figure.run")
                        }
                    }
                    .environmentObject(languageManager)
                    .tabItem {
                        Image(systemName: "figure.run")
                        Text("Ritmi")
                    }
                    .tag(2)
                    
                    Group {
                        if let plan = plan, isPremiumUser {
                            AthleteProfileView(plan: plan)
                        } else {
                            EmptyStateView(icon: "person")
                        }
                    }
                    .environmentObject(languageManager)
                    .tabItem {
                            Image(systemName: isPremiumUser ? "person" : "person.fill")
                            Text("Profilo")
                        }
                        .tag(3)
                        .onChange(of: selectedTab) { _, newValue in
                            if newValue == 3 && !isPremiumUser && plan != nil {
                                showingPremiumAlert = true
                                selectedTab = previousTab
                            } else {
                                previousTab = newValue
                            }
                        }

                    SettingsView()
                        .environmentObject(languageManager)
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("Impostazioni")
                        }
                        .tag(4)
                }
            }
        }
        .environment(\.locale, languageManager.currentLocale)
        .sheet(isPresented: $showingPremiumSheet) {
            NavigationStack {
                PremiumInfoView()
                    .environmentObject(StoreKitManager.shared)
            }
        }
        .overlay {
            if showingPremiumAlert {
                PremiumAlertOverlay(
                    title: AppLocalizedString.resolve(
                        LocalizedStringResource("premiumAlert.title", defaultValue: "Funzione Premium"),
                        locale: locale
                    ),
                    message: AppLocalizedString.resolve(
                        LocalizedStringResource(
                            "premiumAlert.profile",
                            defaultValue: "Il Profilo Atleta è riservato agli utenti Premium.\nEsegui l'upgrade per visualizzare il tuo stato attuale e le previsioni dei tempi stimati per ogni distanza."
                        ),
                        locale: locale
                    ),
                    onUpgrade: {
                        showingPremiumAlert = false
                        showingPremiumSheet = true
                    },
                    onDismiss: {
                        showingPremiumAlert = false
                    }
                )
            }
        }
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .imageScale(.large)
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text("Nessun piano attivo")
                .font(.headline)
            Text("Crea un piano nella scheda Obiettivo")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(LanguageManager())
        .environment(\.locale, .init(identifier: "en"))
}
