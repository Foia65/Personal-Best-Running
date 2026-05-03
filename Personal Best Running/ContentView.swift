import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @State private var plan: TrainingPlan?
    @State private var showingPlan = false

    var body: some View {
        NavigationStack {
            if showingPlan, let plan = plan {
                TrainingPlanView(plan: plan) {
                    self.showingPlan = false
                    self.plan = nil
                }
            } else {
                PlanInputView { newPlan in
                    self.plan = newPlan
                    self.showingPlan = true
                }
            }
        }
    }
}

// MARK: - Input View

struct PlanInputView: View {
    var onGenerate: (TrainingPlan) -> Void

    @AppStorage("raceDistance") private var raceDistance: RaceDistance = .tenK
    @AppStorage("raceDate") private var raceDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    @AppStorage("raceName") private var raceName: String = ""
    @AppStorage("trainingDays") private var trainingDays: Int = 4
    @AppStorage("targetHours") private var targetHours: Int = 0
    @AppStorage("targetMinutes") private var targetMinutes: Int = 50
    @AppStorage("targetSeconds") private var targetSeconds: Int = 0
    @AppStorage("currentDistance") private var currentDistance: RaceDistance = .tenK
    @AppStorage("currentHours") private var currentHours: Int = 0
    @AppStorage("currentMinutes") private var currentMinutes: Int = 55
    @AppStorage("currentSeconds") private var currentSeconds: Int = 0

    private var targetTime: TimeInterval {
        TimeInterval(targetHours * 3600 + targetMinutes * 60 + targetSeconds)
    }

    private var currentTime: TimeInterval {
        TimeInterval(currentHours * 3600 + currentMinutes * 60 + currentSeconds)
    }

    var body: some View {
        Form {
            Section("Gara Target") {
                Picker("Distanza", selection: $raceDistance) {
                    ForEach(RaceDistance.allCases) { dist in
                        Text(dist.rawValue).tag(dist)
                    }
                }
                TextField("Nome evento", text: $raceName)
                    .autocorrectionDisabled(true)

                DatePicker("Data gara", selection: $raceDate, in: Date()..., displayedComponents: .date)
            }

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
                .frame(height: 120)
                
                if targetTime > 0 {
                    let paceSecsPerKm = targetTime / raceDistance.meters * 1000
                    let paceMin = Int(paceSecsPerKm) / 60
                    let paceSec = Int(paceSecsPerKm) % 60
                    let paceFormatted = String(format: "%d:%02d", paceMin, paceSec)
                    
                    Text("Passo Target: \(paceFormatted) /km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Performance Attuale") {
                Picker("Distanza di riferimento", selection: $currentDistance) {
                    ForEach(RaceDistance.allCases) { d in
                        Text(d.rawValue).tag(d)
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
                .frame(height: 120)
            }

            Section("Giorni di Allenamento") {
                Stepper("Giorni/settimana: \(trainingDays)", value: $trainingDays, in: 3...6)
            }

            Section {
                Button(action: generate) {
                    Label("Genera Piano", systemImage: "figure.run")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .listRowBackground(Color.clear)
            }
            
            Section {
                Button(role: .destructive, action: resetParameters) {
                    Label("Reset", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("🏃 PB Running")
        .navigationBarTitleDisplayMode(.large)
    }

    private func generate() {
        let input = TrainingPlanInput(
            raceDistance: raceDistance,
            raceDate: raceDate,
            raceName: raceName.isEmpty ? raceDistance.rawValue : raceName,
            trainingDaysPerWeek: trainingDays,
            targetTime: targetTime,
            currentPerformance: CurrentPerformance(distance: currentDistance, time: currentTime)
        )
        let plan = TrainingPlanGenerator().generate(input: input)
        onGenerate(plan)
    }
    
    private func resetParameters() {
        raceDistance = .tenK
        raceDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
        raceName = ""
        trainingDays = 4
        targetHours = 0
        targetMinutes = 50
        targetSeconds = 0
        currentDistance = .tenK
        currentHours = 0
        currentMinutes = 50
        currentSeconds = 0
    }
}

#Preview {
    ContentView()
}
