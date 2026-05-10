import SwiftUI

// MARK: - Training Plan View

struct TrainingPlanView: View {
    let plan: TrainingPlan
    var onBack: () -> Void
    
    @State private var selectedTab = 0
    @State private var expandedWeek: Int?
    @State private var pdfItem: PDFDocumentItem?
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con info piano
            planHeaderView
            
            Picker("Vista", selection: $selectedTab) {
                Text("Calendario").tag(0)
                // Text("Ritmi").tag(1)
                Text("Riferimenti").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            TabView(selection: $selectedTab) {
                calendarView.tag(0)
                sourcesView.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Piano: \(plan.input.raceName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("← Modifica") { onBack() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    exportPDF()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        
        .sheet(item: $pdfItem) { item in
            ShareSheet(url: item.url)
        }
    }
    
    // MARK: Header
    
    var planHeaderView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading) {
                    Text(plan.input.raceName)
                        .font(.headline)
                    Text(plan.input.raceDistance.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(plan.input.raceDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                    Text("\(plan.weeks.count) settimane")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            Text(plan.fitnessGap)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .padding(.top, 20)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: Calendar
    
    var calendarView: some View {
        List {
            ForEach(plan.weeks) { week in
                Section {
                    // Header settimana
                    WeekHeaderView(week: week)
                    
                    // Workout della settimana
                    if expandedWeek == week.weekNumber {
                        ForEach(week.workouts) { workout in
                            WorkoutRowView(workout: workout)
                        }
                    }
                } header: {
                    Button {
                        withAnimation {
                            expandedWeek = expandedWeek == week.weekNumber ? nil : week.weekNumber
                        }
                    } label: {
                        HStack {
                            Text("Settimana \(week.weekNumber) – \(week.phase.rawValue)")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                            Spacer()
                            Image(systemName: expandedWeek == week.weekNumber ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.primary)
                    .buttonStyle(.plain)
                }
            }
            
            Section {
                VStack(spacing: 8) {
                    Button(action: exportPDF) {
                        HStack {
                            Spacer()
                            Label("Esporta Piano in PDF", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.0, green: 0.0, blue: 0.3))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            Label("Esporta nel Calendario", systemImage: "calendar")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .disabled(true)
                }
                
            } header: {
                Text("Gestione Piani")
            }
            
        }
        .listStyle(.insetGrouped)
        
    }
    
    // MARK: Sources
    
    var sourcesView: some View {
        List {
            Section("Fonti Scientifiche") {
                ForEach(plan.scientificSources, id: \.self) { source in
                    Text(source)
                        .font(.caption)
                        .padding(.vertical, 2)
                }
            }
            Section("Note") {
                Text("I ritmi di allenamento sono calcolati tramite il sistema VDOT di Jack Daniels. La distribuzione settimanale segue il principio di polarizzazione 80/20 (Seiler). La progressione del volume rispetta la regola del 10% per prevenire infortuni.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let hour = Int(seconds) / 3600
        let minute = (Int(seconds) % 3600) / 60
        let second = Int(seconds) % 60
        if hour > 0 { return String(format: "%d:%02d:%02d", hour, minute, second) }
        return String(format: "%d:%02d", minute, second)
    }
    
    private func exportPDF() {
        print("Exporting PDF...")
        
        // 1. Generate the data
        let data = TrainingPlanPDFGenerator().generatePDF(plan: plan, unitSystem: unitSystem)
        
        // 2. Setup the temporary file path
        let fileName = "\(plan.input.raceName.replacingOccurrences(of: " ", with: "_"))_piano.pdf"
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            // 3. Write data to disk
            try data.write(to: tmpURL)
            
            print("PDF size: \(data.count) bytes")
            print("PDF written to: \(tmpURL.path)")
            
            // 4. Update the state item (this triggers the sheet)
            self.pdfItem = PDFDocumentItem(url: tmpURL)
            
        } catch {
            print("PDF Export Failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Week Header View

struct WeekHeaderView: View {
    let week: TrainingWeek
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
//                Text(week.phase.rawValue)
//                    .font(.subheadline.bold())
//                    .foregroundStyle(.primary)
                Text(week.weeklyNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(unitSystem.formatDistance(week.totalKm))
                    .font(.title3.bold())
                Text("volume")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
//    var phaseColor: Color {
//        switch week.phase {
//        case .base: return .blue
//        case .build: return .orange
//        case .peak: return .red
//        case .taper: return .green
//        case .race: return .purple
//        }
//    }
}

// MARK: - Workout Row View

struct WorkoutRowView: View {
    let workout: Workout
    @State private var expanded = false
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                HStack {
                    if workout.type != .race {
                        Text(workout.type.emoji)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.date.formatted(.dateTime.weekday().day().month()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(workout.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        if let kms = workout.distanceKm {
                            Text(unitSystem.formatDistance(kms))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let secsPerKm = workout.paceTargetSecsPerKm, workout.type != .rest {
                        Text(unitSystem.formatPace(secsPerKm))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text(workout.description)
                        .font(.footnote)
                    
                    if let sets = workout.structuredSets {
                        Label(sets, systemImage: "list.bullet.clipboard")
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        Label("RPE: \(workout.rpe)", systemImage: "heart.fill")
                        Spacer()
                        Text(workout.type.intensityDescription)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    //                    DisclosureGroup("📚 Razionale scientifico") {
                    //                        Text(workout.scientificRationale)
                    //                            .font(.caption)
                    //                            .foregroundStyle(.secondary)
                    //                    }
                    //                    .font(.caption.bold())
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pace Row

struct PaceRow: View {
    let label: String
    let pace: String
    let rpe: String
    let zone: String
    let color: Color // New: pass the color directly
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. Intensity Indicator Bar
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 35)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())
                Text("RPE \(rpe)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(pace)
                    .font(.system(.title3, design: .rounded).bold()) // Rounded design feels more modern
                    .foregroundColor(.primary)
                
                Text(zone)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct PacesView: View {
    let plan: TrainingPlan
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Il Tuo VDOT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f", plan.paces.vdot))
                            .font(.title2.bold())
                    }
                    Spacer()
                    Divider()
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Stima Gara")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatTime(plan.estimatedRaceTime))
                            .font(.title2.bold())
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Profilo Atleta")
            }
            
            Section {
                PaceRow(
                    label: "Recupero",
                    pace: plan.paces.recoveryFormatted(unitSystem: unitSystem),
                    rpe: "3",
                    zone: "Z1",
                    color: .blue
                )
                
                PaceRow(
                    label: "Corsa Facile",
                    pace: plan.paces.easyFormatted(unitSystem: unitSystem),
                    rpe: "4-5",
                    zone: "Z2",
                    color: .green
                )
                
                PaceRow(
                    label: "Ritmo Maratona",
                    pace: plan.paces.mpFormatted(unitSystem: unitSystem),
                    rpe: "6-7",
                    zone: "Z3",
                    color: .yellow
                )
                
                PaceRow(
                    label: "Soglia / Tempo",
                    pace: plan.paces.thresholdFormatted(unitSystem: unitSystem),
                    rpe: "7-8",
                    zone: "Z4",
                    color: .red
                )
                
                PaceRow(
                    label: "Intervalli / VO2max",
                    pace: plan.paces.intervalFormatted(unitSystem: unitSystem),
                    rpe: "9+",
                    zone: "Z5",
                    color: .purple
                )
            } header: {
                Text("Andature di Allenamento")
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Regola 80/20")
                        .font(.headline)
                        .padding(.top, 10)
                    Text("L'80% degli allenamenti dovrebbe essere a bassa intensità (Z1-Z2) per costruire la base aerobica, mentre il 20% dovrebbe essere ad alta intensità (Z4-Z5).")
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hour = Int(seconds) / 3600
        let minute = (Int(seconds) % 3600) / 60
        let second = Int(seconds) % 60
        if hour > 0 { return String(format: "%d:%02d:%02d", hour, minute, second) }
        return String(format: "%d:%02d", minute, second)
    }
}

#Preview {
    let sampleInput = TrainingPlanInput(
        raceDistance: .halfMarathon,
        raceDate: Calendar.current.date(byAdding: .weekOfYear, value: 16, to: Date()) ?? Date(),
        raceName: "Monza Half Marathon",
        trainingDaysPerWeek: 4,
        targetTime: 1 * 3600 + 45 * 60,
        currentPerformance: CurrentPerformance(
            distance: .tenK,
            time: 55 * 60
        ),
        sex: .male
    )
    
    let samplePlan = TrainingPlanGenerator().generate(input: sampleInput)
    
    NavigationStack {
        PacesView(plan: samplePlan)
    }
}

#Preview {
    let sampleInput = TrainingPlanInput(
        raceDistance: .halfMarathon,
        raceDate: Calendar.current.date(byAdding: .weekOfYear, value: 16, to: Date()) ?? Date(),
        raceName: "Monza Half Marathon",
        trainingDaysPerWeek: 4,
        targetTime: 1 * 3600 + 45 * 60,
        currentPerformance: CurrentPerformance(
            distance: .tenK,
            time: 55 * 60
        ),
        sex: .male
    )
    
    let samplePlan = TrainingPlanGenerator().generate(input: sampleInput)
    
    NavigationStack {
        TrainingPlanView(plan: samplePlan) {
            print("Reset tapped")
        }
    }
}
