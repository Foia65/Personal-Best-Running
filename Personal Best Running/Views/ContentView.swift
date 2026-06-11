import SwiftUI
import UIKit

private let navyBlue = Color(red: 0.0, green: 0.0, blue: 0.3)

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
    @StateObject private var languageManager = LanguageManager()
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    @StateObject private var calendarManager = CalendarManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    navyBlue
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
                        if let plan = plan {
                            AthleteProfileView(plan: plan)
                        } else {
                            EmptyStateView(icon: "person")
                        }
                    }
                    .environmentObject(languageManager)
                    .tabItem {
                            Image(systemName: "person")
                            Text("Profilo")
                        }
                        .tag(3)

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
    }
}

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
