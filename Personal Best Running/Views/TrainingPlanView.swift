import SwiftUI

// MARK: - Training Plan View
struct TrainingPlanView: View {
    let plan: TrainingPlan
    var onBack: () -> Void
    
    @State private var selectedTab = 0
    @State private var expandedWeek: Int?
    @State private var pdfItem: PDFDocumentItem?
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @StateObject private var calendarManager = CalendarManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con info piano
            planHeaderView
            
            Picker("Vista", selection: $selectedTab) {
                Text("Calendario").tag(0)
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
                    
                    Button(action: exportCalendar) {
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
                }
                
            } header: {
                Text("Gestione Piani")
            }
            
        }
        .listStyle(.insetGrouped)
        //   .navigationTitle("Programma Corse")
        .alert("Calendario Aggiornato", isPresented: $calendarManager.showConfirmation) {
            Button("Ottimo", role: .cancel) { }
        } message: {
            Text("Ho aggiunto correttamente \(calendarManager.lastEventCount) eventi al tuo calendario 'PB Running'.")
        }
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
    
    private func exportCalendar() {
        print("Exporting to Calendar...")
        
        // salvo tutti i workouts in allEvents
        var allEvents: [EventData] = []
        for week in plan.weeks {
            for workout in week.workouts {
                // Escludiamo il riposo
                guard workout.title != "Riposo" else { continue }
                
                // 1. Gestione Passo (Pace) usando UnitSystem
                var paceString = ""
                if let paceSecsPerKm = workout.paceTargetSecsPerKm {
                    paceString = "@ " + unitSystem.formatPace(paceSecsPerKm)
                }
                
                // 2. Gestione Distanza usando UnitSystem
                let distanceString: String
                if let kms = workout.distanceKm {
                    distanceString = unitSystem.formatDistance(kms)
                } else {
                    distanceString = "N/A"
                }
                
                // 3. Creazione delle note dell'evento
                let structuredDetails = (workout.structuredSets?.isEmpty == false) ? "📋 \(workout.structuredSets!)" : ""
                let notes = "\(workout.description)\n\n\(structuredDetails)\n\n❤️ RPE: \(workout.rpe)\n\(workout.type.intensityDescription)"
                
                // 4. Creazione dell'oggetto EventData
                let newEvent = EventData(
                    date: workout.date,
                    title: "W\(week.weekNumber) \(workout.title) - \(distanceString) \(paceString) ",
                    // notes: workout.description
                    notes: notes
                )
                allEvents.append(newEvent)
            }
        }
        
        // --- STAMPA NELLA CONSOLE ---
        
        print("\n--- ELENCO EVENTI DA SCRIVERE (\(allEvents.count)) ---")
        
        allEvents.forEach { event in
            let dateStr = event.date.formatted(date: .abbreviated, time: .omitted)
            print("📅 Data: \(dateStr) | 🏃 Titolo: \(event.title)")
            print("📝 Note: \(event.notes)")
            print("------------------------------------------\n")
        }
        
        // scrivo sul calendario
        calendarManager.addEventsBatch(allEvents)
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
                    WorkoutBadge(type: workout.type, size: 36) .font(.title3)
                    
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
                    
                    // DisclosureGroup("📚 Razionale scientifico") {
                    // Text(workout.scientificRationale)
                    // .font(.caption)
                    // .foregroundStyle(.secondary)
                    // }
                    // .font(.caption.bold())
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - WorkoutBadge
struct WorkoutBadge: View {
    // Badge riutilizzabile che incapsula SF Symbol + colore del WorkoutType.
    // Usato sia in PacesView (PaceRow) che in calendarView (WorkoutRowView),
    // garantendo coerenza visiva da un'unica definizione.
    //
    // Uso:
    //   WorkoutBadge(type: workout.type)           // dimensione standard (40pt)
    //   WorkoutBadge(type: workout.type, size: 32) // dimensione custom
    let type: WorkoutType
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .fill(type.color.opacity(0.15))
                .frame(width: size, height: size)
            Image(systemName: type.sfSymbol)
                .font(.system(size: size * 0.40, weight: .semibold))
                .foregroundStyle(type.color)
        }
    }
}

#Preview ("Piano"){
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
