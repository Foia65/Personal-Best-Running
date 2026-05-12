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
//        .navigationTitle("Piano: \(plan.input.raceName)")
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
                let notes = "\(workout.description)\n\n\(structuredDetails)\n\n❤️ RPE: \(workout.rpe)"
                
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
            print("------------------------------------------")
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
                    
                    //                                        DisclosureGroup("📚 Razionale scientifico") {
                    //                                            Text(workout.scientificRationale)
                    //                                                .font(.caption)
                    //                                                .foregroundStyle(.secondary)
                    //                                        }
                    //                                        .font(.caption.bold())
                }
                .padding(.top, 8)
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
            
            // MARK: - Profilo Atleta
            Section {
                // Mostriamo sia la stima attuale che il target dichiarato.
                // Sono due valori distinti e confonderli era il bug originale:
                // - Stima attuale: predictRaceTime dal VDOT di partenza
                // - Target: input.targetTime dichiarato dall'utente
                // Fonte: Daniels [1] cap. 5 – VDOT come misura della forma attuale.
                VStack(spacing: 12) {
                    HStack {
                        vdotBadge
                        Spacer()
                        Divider().frame(height: 44)
                        Spacer()
                        timeColumn(
                            label: "Stima Attuale",
                            value: formatTime(plan.estimatedRaceTime),
                            subtitle: plan.input.raceDistance.rawValue,
                            valueColor: .primary
                        )
                        Spacer()
                        Divider().frame(height: 44)
                        Spacer()
                        timeColumn(
                            label: "Target",
                            value: formatTime(plan.input.targetTime),
                            subtitle: plan.input.raceDistance.rawValue,
                            valueColor: targetColor
                        )
                    }
                    .padding(.vertical, 8)
                    
                    // Gap fitness già formattato nel piano (VDOT attuale → target)
                    Text(plan.fitnessGap)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } header: {
                Text("Profilo Atleta")
            }
            
            // MARK: - Andature di Allenamento
            // Le andature sono calcolate dal VDOT ATTUALE, non dal target.
            // È corretto: ci si allena alla forma che si ha oggi.
            // Fonte: Daniels [1] cap. 4 – "Train at the level you are."
            Section {
                
                // [FIX-6] Rimossa la riga "Recupero" come zona separata.
                // Daniels [1] cap. 4 non definisce una recovery zone distinta dall'Easy:
                // usa E-pace (59-74% VO2max) per tutto il continuum di bassa intensità.
                // Il recupero attivo usa il limite inferiore dell'E-pace.
                
                PaceRow(
                    label: "Corsa Facile",
                    pace: plan.paces.easyFormatted(unitSystem: unitSystem),
                    rpe: "4-5",
                    zone: "Z2",
                    color: .green,
                    danielsCode: "E",
                    detail: "59-74% VO2max · 65-79% FCmax"
                )
                
                PaceRow(
                    label: "Ritmo Maratona",
                    pace: plan.paces.mpFormatted(unitSystem: unitSystem),
                    rpe: "6-7",
                    zone: "Z3",
                    color: .yellow,
                    danielsCode: "M",
                    detail: "75-84% VO2max · 80-89% FCmax"
                )
                
                PaceRow(
                    label: "Soglia / Tempo",
                    pace: plan.paces.thresholdFormatted(unitSystem: unitSystem),
                    rpe: "7-8",
                    zone: "Z4",
                    color: .red,
                    danielsCode: "T",
                    // [FIX-5] Corretto da "80-90% FCmax" a "88-92% FCmax".
                    // Fonte: Daniels [1] cap. 4.
                    detail: "85-88% VO2max · 88-92% FCmax"
                )
                
                PaceRow(
                    label: "Intervalli",
                    pace: plan.paces.intervalFormatted(unitSystem: unitSystem),
                    rpe: "8-9",
                    zone: "Z5",
                    color: .purple,
                    danielsCode: "I",
                    detail: "95-100% VO2max · rec. attivo (jog)"
                )
                
                // [FIX-2] Nuova riga: R (Repetition) pace.
                // Daniels [1] cap. 4: scopo primario è velocità ed economia.
                // Work bout MAX 2 min, recupero COMPLETO (jog = distanza corsa).
                // ~6 sec/400m più veloce dell'I-pace ("regola dei 6 secondi").
                PaceRow(
                    label: "Ripetute",
                    pace: plan.paces.repetitionFormatted(unitSystem: unitSystem),
                    rpe: "9+",
                    zone: "Z5+",
                    color: .orange,
                    danielsCode: "R",
                    detail: "105-120% VDOT · max 2 min/rep · rec. completo"
                )
                
            } header: {
                Text("Andature di Allenamento")
                
            }
            
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    
                    Label("Come sono calcolate", systemImage: "info.circle")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                    
                    Text(
                        "Le andature si basano sul tuo **VDOT attuale** (\(String(format: "%.1f", plan.paces.vdot))), " +
                        "non sull'obiettivo. Ci si allena alla forma che si ha oggi: " +
                        "i ritmi migliorano man mano che il VDOT cresce."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    Label("Distribuzione 80/20", systemImage: "chart.pie")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                    
                    Text("~80% del volume a E-pace (Z2), ~20% a T/I/R (Z4-Z5+). " +
                         "Fonte: Seiler & Kjerland (2006).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    Label("Lungo: max 25% del volume settimanale", systemImage: "ruler")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                    
                    Text("Il lungo non supera il 25% del volume settimanale né 150 minuti. " +
                         "Fonte: Daniels (2022) cap. 4.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    Label("Zona 1 (Z1) - perché non è in tabella", systemImage: "questionmark.circle")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                    // usato *** perchè con i + la preview andava in crash (!)
                    Text("""
                            Daniels non assegna un ritmo specifico alla Z1: \
                            l'E-pace (Z2, 59-74% VO2max) copre già tutto il range di bassa intensità, \
                            recupero attivo incluso. \
                            Nei giorni di recupero corri semplicemente al limite inferiore dell'E-pace, \
                            senza un target preciso — l'obiettivo è muoversi, non allenare
                            """)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Note")
            }
        }
        .navigationTitle("Andature")
    }
    
    // MARK: - Subviews
    
    private var vdotBadge: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("VDOT")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", plan.paces.vdot))
                .font(.title2.bold())
                .foregroundStyle(.indigo)
            Text("forma attuale")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    private func timeColumn(
        label: String,
        value: String,
        subtitle: String,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(valueColor)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    // Colore del target in base all'ambizione del gap VDOT
    private var targetColor: Color {
        let targetVDOT = VDOTCalculator.calculate(
            timeInSeconds: plan.input.targetTime,
            distanceMeters: plan.input.raceDistance.meters
        )
        let gap = targetVDOT - plan.paces.vdot
        switch gap {
        case ..<2:  return .green    // conservativo / realistico
        case 2..<5: return .orange   // ambizioso
        default:    return .red      // molto sfidante
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: Double) -> String {
        let ore = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        let sec = Int(seconds) % 60
        if ore > 0 { return String(format: "%d:%02d:%02d", ore, min, sec) }
        return String(format: "%d:%02d", min, sec)
    }
}

// MARK: - PaceRow

// Rispetto alla versione precedente:
// - aggiunto danielsCode (lettera ufficiale E/M/T/I/R) nel badge
// - aggiunto detail (intensità fisiologica sintetica sotto il label)
// - zona e RPE spostati in trailing come seconda riga
struct PaceRow: View {
    let label: String
    let pace: String
    let rpe: String
    let zone: String
    let color: Color
    var danielsCode: String = ""
    var detail: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Badge: cerchio colorato con lettera Daniels
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(danielsCode.isEmpty ? zone : danielsCode)
                    .font(
                        .system(
                            size: danielsCode.isEmpty ? 10 : 18,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(color)
            }
            
            // Label + dettaglio intensità
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Passo + RPE + zona
            VStack(alignment: .trailing, spacing: 2) {
                Text(pace)
                    .font(.subheadline.monospacedDigit().bold())
                HStack(spacing: 4) {
                    Text("RPE \(rpe)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(zone)
                        .font(.caption2.bold())
                        .foregroundStyle(color)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview ("Andature") {
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

