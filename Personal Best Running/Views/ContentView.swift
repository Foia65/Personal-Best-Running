import SwiftUI

// Shared color used across views in this file
private let navyBlue = Color(red: 0.0, green: 0.0, blue: 0.3)

struct PerformanceBounds {
    let minSeconds: Double  // tempo minimo realistico (élite)
    let maxSeconds: Double  // tempo massimo accettabile (runner lento ma reale)
}

extension RaceDistance {
    var performanceBounds: PerformanceBounds {
        switch self {
        case .fiveK:
            return PerformanceBounds(
                minSeconds: 13 * 60,          // 13:00 (élite mondiale ~12:35)
                maxSeconds: 60 * 60           // 1:00:00 (12:00 /km)
            )
        case .tenK:
            return PerformanceBounds(
                minSeconds: 27 * 60,          // 27:00 (élite mondiale ~26:17)
                maxSeconds: 2 * 3600          // 2:00:00 (12:00 /km)
            )
        case .halfMarathon:
            return PerformanceBounds(
                minSeconds: 58 * 60,          // 58:00 (élite mondiale ~57:31)
                maxSeconds: 4 * 3600          // 4:00:00 (~11:22 /km)
            )
        case .marathon:
            return PerformanceBounds(
                minSeconds: 2 * 3600,         // 2:00:00 (élite mondiale)
                maxSeconds: 8 * 3600          // 8:00:00 (~11:22 /km)
            )
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var plan: TrainingPlan?
    @State private var showingPlan = false
    @State private var selectedTab = 0
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
                    // Tab 1: input parametri per il plan
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
                        Text("Piano")
                    }
                    .tag(1)
                    
                    // Tab 3: profilo runner e ritmi di allenamento
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
                    
                    // Tab 4: info
                    Group {
                        if let plan = plan {
                            AthleteProfileView(plan: plan)
                        } else {
                            EmptyStateView(icon: "calendar.badge.plus", title: "Nessun piano attivo")
                        }
                    }                        .tabItem {
                            Image(systemName: "person")
                            Text("Profilo")
                        }
                        .tag(3)

                    // Tab 5: preferenze
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("Impostazioni")
                        }
                        .tag(4)
                }
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
    
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    @State private var showSettings = false
    
    private var targetTime: TimeInterval {
        TimeInterval(targetHours * 3600 + targetMinutes * 60 + targetSeconds)
    }
    private var currentTime: TimeInterval {
        TimeInterval(currentHours * 3600 + currentMinutes * 60 + currentSeconds)
    }
    
    private var isTargetTimeOutOfBounds: Bool {
        guard targetTime > 0 else { return false }
        let bounds = raceDistance.performanceBounds
        return targetTime < bounds.minSeconds || targetTime > bounds.maxSeconds
    }

    private var isCurrentTimeOutOfBounds: Bool {
        guard currentTime > 0 else { return false }
        let bounds = currentDistance.performanceBounds
        return currentTime < bounds.minSeconds || currentTime > bounds.maxSeconds
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
        // Confronta solo i componenti della data
        return Calendar.current.startOfDay(for: raceDate) < Calendar.current.startOfDay(for: minimumDate)
    }
        
    private var isPreparationTooLong: Bool {
        guard let weeksAhead = Calendar.current.dateComponents(
            [.weekOfYear],
            from: Date(),
            to: raceDate
        ).weekOfYear
        else { return false }
        return weeksAhead > raceDistance.maxPlanWeeks
    }
  
    private var isGenerateDisabled: Bool {
        isPreparationTooShort
            || targetTime <= 0
            || currentTime <= 0
            || isTargetTimeOutOfBounds
            || isCurrentTimeOutOfBounds
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
                    .tint(.primary) // senza questo non è visibile in dark mode

                    HStack {
                        Text("Evento:")
                        Spacer()
                        TextField("Nome evento", text: $raceName)
                            .autocorrectionDisabled(true)
                            .multilineTextAlignment(.trailing)
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

                    if isPreparationTooLong {
                        Label {
                            Text("Il piano verrà limitato a \(raceDistance.maxPlanWeeks) settimane (il massimo efficace per \(raceDistance.rawValue))")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
                header: {
                    Text("Gara Target")
                        .padding(.top, 20)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))

                .listRowBackground(Color.orange.opacity(0.05)) // Only this row is yellow
                .id("top")

                Section("Tempo Target") {
                    HStack {
                        Spacer()
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
                        Spacer()
                    }
                    .frame(height: 70)
                    
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
                    
                    if isTargetTimeOutOfBounds && targetTime > 0 {
                        let bounds = raceDistance.performanceBounds
                        Label {
                            Text("Tempo non realistico per \(raceDistance.rawValue). Range accettato: \(formatSeconds(bounds.minSeconds)) – \(formatSeconds(bounds.maxSeconds))")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
                .listRowBackground(Color.blue.opacity(0.05))
                .listRowInsets(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                
                Section("Performance Attuale") {
                    Picker("Distanza di riferimento", selection: $currentDistance) {
                        ForEach(RaceDistance.allCases) { dist in
                            Text(dist.rawValue).tag(dist)
                        }
                    }
                    .tint(.primary) // senza questo non è visibile in dark mode

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
                    .frame(height: 70)
                    
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
                    
                    if isCurrentTimeOutOfBounds && currentTime > 0 {
                        let bounds = currentDistance.performanceBounds
                        Label {
                            Text("Tempo non realistico per \(currentDistance.rawValue). Range accettato: \(formatSeconds(bounds.minSeconds)) – \(formatSeconds(bounds.maxSeconds))")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
                .listRowBackground(Color.green.opacity(0.05))
                .listRowInsets(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))

                
                Section("Giorni di Allenamento") {
                    Stepper("Giorni/settimana: \(trainingDays)", value: $trainingDays, in: 3...6)
                }
                .listRowBackground(Color.indigo.opacity(0.05))
                .listRowInsets(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))

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
                    .disabled(isGenerateDisabled)
                    .listRowInsets(EdgeInsets())
                    
                    if isPreparationTooShort {
                        Text("La preparazione richiede almeno 12 settimane. Seleziona una data successiva al \(Calendar.current.date(byAdding: .weekOfYear, value: 12, to: Date())?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    
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
        guard !isPreparationTooShort, targetTime > 0, currentTime > 0 else {
                // Mostra un alert o semplicemente ritorna
                return
            }
        let input = TrainingPlanInput(
            raceDistance: raceDistance,
            raceDate: raceDate,
            raceName: raceName.isEmpty ? raceDistance.rawValue : raceName,
            trainingDaysPerWeek: trainingDays,
            targetTime: targetTime,
            currentPerformance: CurrentPerformance(distance: currentDistance, time: currentTime),
            sex: runnerSex
        )
        let plan = TrainingPlanGenerator().generate(input: input)
        onGenerate(plan)
    }
    
    private func formatSeconds(_ seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        let sec = Int(seconds) % 60
        if hrs > 0 {
            return sec > 0
                ? String(format: "%d:%02d:%02d", hrs, min, sec)
                : String(format: "%dh%02d", hrs, min)
        }
        return String(format: "%d:%02d", min, sec)
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
        .environmentObject(ThemeManager())
}
