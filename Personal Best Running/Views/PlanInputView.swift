import SwiftUI

struct TimePickerHintPopover: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("drag helper")
                .resizable()
                .scaledToFit()
                .frame(height: 120) // or whatever looks good
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Text("Trascina per modificare i tempi")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("OK") {
                onDismiss()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .presentationDetents([.medium])
    }
}

struct PlanInputView: View {
    var onGenerate: (TrainingPlan) -> Void
    var onReset: () -> Void
    
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
    @State private var showRaceNameError = false
    @State private var scrollProxy: ScrollViewProxy?
    
    private var raceNameIsEmpty: Bool {
        raceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    @State private var showTimePickerHint = false
    
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
        let twelveWeeksAhead = calendar.date(byAdding: .weekOfYear, value: 12, to: Date()) ?? Date()
        let weekday = calendar.component(.weekday, from: twelveWeeksAhead)
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
                        ForEach(RaceDistance.targetDistances) { dist in
                            Text(dist.localizedName).tag(dist)
                        }
                    }
                    .tint(.primary)

                    HStack {
                        Text("Evento:")
                        Spacer()
                        TextField("Nome evento", text: $raceName)
                            .autocorrectionDisabled(true)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: raceName) {
                                showRaceNameError = false
                            }
                    }
                    if showRaceNameError && raceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Label {
                            Text("Nome evento obbligatorio")
                        } icon: {
                            Image(systemName: "exclamationmark.circle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
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
                            Text("Una preparazione adeguata richiede almeno 12 settimane.\nSeleziona una data successiva al \(Calendar.current.date(byAdding: .weekOfYear, value: 12, to: Date())?.formatted(date: .numeric, time: .omitted) ?? "")")
                        } icon: {
                            Image(systemName: "calendar.badge.exclamationmark")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }

                    if isPreparationTooLong {
                        Label {
                            Text("Il piano verrà limitato a \(raceDistance.maxPlanWeeks) settimane (il massimo efficace per \(raceDistance.localizedName))")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
                header: {
                    Label("GARA TARGET", systemImage: "flag.checkered")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .listRowBackground(Color(.systemGroupedBackground))
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .id("top")
                
                Section {
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
                            Image(systemName: "stopwatch")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if isTargetTimeOutOfBounds && targetTime > 0 {
                        let bounds = raceDistance.performanceBounds
                        Label {
                            Text("Tempo non realistico per \(raceDistance.localizedName). Range accettato: \(formatSeconds(bounds.minSeconds)) – \(formatSeconds(bounds.maxSeconds))")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
                header: {
                    HStack {
                        Label("TEMPO TARGET", systemImage: "stopwatch")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showTimePickerHint = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color(.systemGroupedBackground))
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                Section {
                    Picker("Distanza di riferimento", selection: $currentDistance) {
                        ForEach(RaceDistance.allCases) { dist in
                            Text(dist.localizedName).tag(dist)
                        }
                    }
                    .tint(.primary)

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
                            Image(systemName: "chart.line.uptrend.xyaxis")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if isCurrentTimeOutOfBounds && currentTime > 0 {
                        let bounds = currentDistance.performanceBounds
                        Label {
                            Text("Tempo non realistico per \(currentDistance.localizedName). Range accettato: \(formatSeconds(bounds.minSeconds)) – \(formatSeconds(bounds.maxSeconds))")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
                header: {
                    HStack {
                        Label("PERFORMANCE ATTUALE", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showTimePickerHint = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color(.systemGroupedBackground))
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                Section {
                    Stepper("Giorni alla settimana: \(trainingDays)", value: $trainingDays, in: 3...6)
                }
                header: {
                    Label("FREQUENZA DI ALLENAMENTO", systemImage: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowBackground(Color(.systemGroupedBackground))
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

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
                    .tint(AppColors.themeNavy)
                    .controlSize(.large)
                    .disabled(isGenerateDisabled)
                    .listRowInsets(EdgeInsets())
                    
                    Button(role: .destructive) {
                        resetParameters()
                        
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        
                        withAnimation(.smooth) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Azzera e ricomincia")
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 8)
                }
                .listRowBackground(Color.clear)
            }
            .listSectionSpacing(16)
            .background(
                EmptyView()
                    .onAppear { scrollProxy = proxy }
            )
        }
        .onChange(of: showRaceNameError) { _, showError in
            if showError {
                withAnimation(.smooth) {
                    scrollProxy?.scrollTo("top", anchor: .top)
                }
            }
        }
        .sheet(isPresented: $showTimePickerHint) {
            TimePickerHintPopover {
                showTimePickerHint = false
            }
        }
    }
    
    private func generate() {
        guard !isPreparationTooShort,
              targetTime > 0,
              currentTime > 0
        else {
            return
        }
        if raceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showRaceNameError = true
            return
        }
        let input = TrainingPlanInput(
            raceDistance: raceDistance,
            raceDate: raceDate,
            raceName: raceName,
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
        showRaceNameError = false
        onReset()
    }
}

#Preview {
    PlanInputView(
        onGenerate: { _ in },
        onReset: { }
    )
    .environmentObject(ThemeManager())
    .environmentObject(LanguageManager())
    .environment(\.locale, .init(identifier: "it"))
}
