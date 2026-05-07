import SwiftUI

// Shared color used across views in this file
private let navyBlue = Color(red: 0.0, green: 0.0, blue: 0.3)

// MARK: - Content View

struct ContentView: View {
    @State private var plan: TrainingPlan?
    @State private var showingPlan = false
    @State private var selectedTab = 0
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    
    private var headerTitle: String {
        runnerSex == .male ? "🏃‍♂️ Personal Best Running" : "🏃‍♀️ Personal Best Running"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    navyBlue
                        .ignoresSafeArea(edges: .top)
                    Text(headerTitle)
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
                            self.selectedTab = 1 // Sposta l'utente sul calendario dopo la generazione
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
                    
                    // Tab 2: Calendar / Training Plan
                    Group {
                        if let plan = plan {
                            TrainingPlanView(plan: plan) {
                                self.plan = nil
                                self.selectedTab = 0
                            }
                        } else {
                            EmptyStateView(icon: "calendar.badge.plus", title: "Nessun piano attivo")
                        }
                    }
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Calendario")
                    }
                    .tag(1)
                    
                    // Tab 3: ritmi di allenamento
                    Group {
                        if let plan = plan {
                            PacesView(plan: plan)
                        } else {
                            EmptyStateView(icon: "figure.run", title: "Nessun piano attivo")
                        }
                    }
                    .tabItem {
                        Image(systemName: "figure.run")
                        Text("Ritmi")
                    }
                    .tag(2)
                    
                    // Tab 4: preferenze
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gear")
                            Text("Impostazioni")
                        }
                        .tag(3)
                    
                    // debugging view
//                    Group {
//                        if let plan = plan {
//                            PDFDebugView(plan: plan)
//                        } else {
//                            EmptyStateView(icon: "ant.circle", title: "Crea un piano per testare il PDF")
//                        }
//                    }
//                    .tabItem {
//                        Image(systemName: "ant")
//                        Text("Debug")
//                    }
//                    .tag(4)
                    
                }
                .tint(navyBlue)
            }
        }
    }
}

//  componente di supporto per evitare ripetizioni nel codice
struct EmptyStateView: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .imageScale(.large)
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text(title)
                .font(.headline)
            Text("Crea un piano nella scheda Obiettivo")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
// MARK: - Input View
struct PlanInputView: View {
    var onGenerate: (TrainingPlan) -> Void
    var onReset: () -> Void
    
    // Parametri gara
    @AppStorage("raceDistance") private var raceDistance: RaceDistance = .tenK
    @AppStorage("raceDate") private var raceDate: Date = PlanInputView.defaultRaceDate()
    @AppStorage("raceName") private var raceName: String = ""
    @AppStorage("trainingDays") private var trainingDays: Int = 4
    @AppStorage("targetHours") private var targetHours: Int = 0
    @AppStorage("targetMinutes") private var targetMinutes: Int = 50
    @AppStorage("targetSeconds") private var targetSeconds: Int = 0
    @AppStorage("currentDistance") private var currentDistance: RaceDistance = .tenK
    @AppStorage("currentHours") private var currentHours: Int = 0
    @AppStorage("currentMinutes") private var currentMinutes: Int = 55
    @AppStorage("currentSeconds") private var currentSeconds: Int = 0
    @State private var showResetConfirmation = false
    
    // Nuovi parametri (Punti 2 e 3)
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    @State private var showSettings = false
    
    private var targetTime: TimeInterval {
        TimeInterval(targetHours * 3600 + targetMinutes * 60 + targetSeconds)
    }
    private var currentTime: TimeInterval {
        TimeInterval(currentHours * 3600 + currentMinutes * 60 + currentSeconds)
    }
    
    private static func defaultRaceDate() -> Date {
        let calendar = Calendar.current
        
        // 12 weeks from now
        let twelveWeeksAhead = calendar.date(byAdding: .weekOfYear, value: 12, to: Date()) ?? Date()
        
        // Find next Sunday (including same day if already Sunday)
        let weekday = calendar.component(.weekday, from: twelveWeeksAhead)
        
        // In Gregorian calendar: Sunday = 1
        let daysUntilSunday = (8 - weekday) % 7
        
        return calendar.date(byAdding: .day, value: daysUntilSunday, to: twelveWeeksAhead) ?? twelveWeeksAhead
    }
    
    private var isRaceOnSunday: Bool {
        Calendar.current.component(.weekday, from: raceDate) == 1
    }

    private var isPreparationTooShort: Bool {
        guard let minimumDate = Calendar.current.date(byAdding: .weekOfYear, value: 12, to: Date()) else {
            return false
        }
        
        return raceDate < minimumDate
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            Form {
                Section {
                    Picker("Distanza", selection: $raceDistance) {
                        ForEach(RaceDistance.allCases) { dist in
                            Text(dist.rawValue).tag(dist)
                        }
                    }
                    HStack {
                        Text("Evento:")
                        TextField("Nome evento", text: $raceName)
                            .autocorrectionDisabled(true)
                    }
                    DatePicker("Data gara", selection: $raceDate, in: Date()..., displayedComponents: .date)
                    if !isRaceOnSunday {
                        Label {
                            Text("Le gare si disputano normalmente di domenica")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                    
                    if isPreparationTooShort {
                        Label {
                            Text("Una preparazione adeguata richiede almeno 12 settimane")
                        } icon: {
                            Image(systemName: "calendar.badge.exclamationmark")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
                header: {
                    Text("Gara Target")
                        .padding(.top, 20)
                }
                .listRowBackground(Color.orange.opacity(0.05)) // Only this row is yellow
                .id("top")

                Section("Tempo Target (h:mm:ss)") {
                    HStack {
                        Picker("Ore", selection: $targetHours) {
                            ForEach(0..<6, id: \.self) { Text("\($0)h").tag($0) }
                        }.pickerStyle(.wheel).frame(width: 80)
                        Text(":")
                        Picker("Min", selection: $targetMinutes) {
                            ForEach(0..<60, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                        }.pickerStyle(.wheel).frame(width: 80)
                        Text(":")
                        Picker("Sec", selection: $targetSeconds) {
                            ForEach(0..<60, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                        }.pickerStyle(.wheel).frame(width: 80)
                    }
                    .frame(height: 100)
                    
                    if targetTime > 0 {
                        let paceSecsPerKm = targetTime / raceDistance.meters * 1000
                        Label {
                            Text("Passo Target: **\(unitSystem.formatPace(paceSecsPerKm))**")
                        } icon: {
                            Image(systemName: "timer")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.blue.opacity(0.05))
                
                Section("Performance Attuale") {
                    Picker("Distanza di riferimento", selection: $currentDistance) {
                        ForEach(RaceDistance.allCases) { dist in
                            Text(dist.rawValue).tag(dist)
                        }
                    }
                    HStack {
                        Picker("Ore", selection: $currentHours) {
                            ForEach(0..<6, id: \.self) { Text("\($0)h").tag($0) }
                        }.pickerStyle(.wheel).frame(width: 80)
                        Text(":")
                        Picker("Min", selection: $currentMinutes) {
                            ForEach(0..<60, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                        }.pickerStyle(.wheel).frame(width: 80)
                        Text(":")
                        Picker("Sec", selection: $currentSeconds) {
                            ForEach(0..<60, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                        }.pickerStyle(.wheel).frame(width: 80)
                    }
                    .frame(height: 100)
                    
                    if currentTime > 0 {
                        let currentPaceSecsPerKm = currentTime / currentDistance.meters * 1000
                        Label {
                            Text("Passo Attuale: **\(unitSystem.formatPace(currentPaceSecsPerKm))**")
                        } icon: {
                            Image(systemName: "timer")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.green.opacity(0.05))
                
                Section("Giorni di Allenamento") {
                    Stepper("Giorni/settimana: \(trainingDays)", value: $trainingDays, in: 3...6)
                }
                .listRowBackground(Color.indigo.opacity(0.05))
                
                Section {
                    Button(action: generate) {
                        HStack {
                            Image(systemName: "figure.run")
                            Text("Genera Piano")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(navyBlue)
                    .controlSize(.large)
                    .listRowInsets(EdgeInsets())
                    
                    Button(role: .destructive) {
                        resetParameters()
                        
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        
                        withAnimation(.smooth) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    } label: {
                        Text("🗑️ Azzera e ricomincia")
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 8)
                }
                .listRowBackground(Color.clear)
            }
        }
    }
    
    private func generate() {
        let input = TrainingPlanInput(
            raceDistance: raceDistance,
            raceDate: raceDate,
            raceName: raceName.isEmpty ? raceDistance.rawValue : raceName,
            trainingDaysPerWeek: trainingDays,
            targetTime: targetTime,
            currentPerformance: CurrentPerformance(distance: currentDistance, time: currentTime),
            sex: runnerSex           // ← NUOVO campo
        )
        let plan = TrainingPlanGenerator().generate(input: input)
        onGenerate(plan)
    }
    
    private func resetParameters() {
        raceDistance    = .tenK
        raceDate = Self.defaultRaceDate()
        raceName        = ""
        trainingDays    = 4
        targetHours     = 0
        targetMinutes   = 50
        targetSeconds   = 0
        currentDistance = .tenK
        currentHours    = 0
        currentMinutes  = 55
        currentSeconds  = 0
        onReset()
        // Non resettiamo sex e unitSystem: sono preferenze globali
    }
}

#Preview {
    ContentView()
}
