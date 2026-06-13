import SwiftUI

// MARK: - DocumentItem
struct DocumentItem: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - TrainingPlanView
struct TrainingPlanView: View {
    let plan: TrainingPlan
    var onBack: () -> Void

    @State private var selectedTab = 0
    @State private var expandedWeek: Int?
    @State private var pdfItem: PDFDocumentItem?
    @State private var csvItem: DocumentItem? // State for CSV share sheet
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @Environment(\.locale) private var locale
    @StateObject private var calendarManager = CalendarManager()
    private var goalFeasibility: GoalFeasibility { plan.feasibility }

    var body: some View {
        VStack(spacing: 0) {
            // Header with plan info
            planHeaderView
            calendarView
        }
        .sheet(item: $pdfItem) { item in
            ShareSheet(url: item.url)
        }
        .sheet(item: $csvItem) { item in
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
                    Text(plan.input.raceDistance.localizedName)
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

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: plan.feasibility.sfSymbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(plan.feasibility.color)
                    .padding(.top, 1)

                Text(plan.localizedFitnessGap(locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Image(systemName: "calendar")
                Text("Calendario Allenamenti")
                    .font(.title3.bold())
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 30)

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
                    // Week header
                    WeekHeaderView(week: week, locale: locale)

                    // Week workouts
                    if expandedWeek == week.weekNumber {
                        ForEach(week.workouts) { workout in
                            WorkoutRowView(workout: workout, locale: locale)
                        }
                    }
                } header: {
                    Button {
                        withAnimation {
                            expandedWeek = expandedWeek == week.weekNumber ? nil : week.weekNumber
                        }
                    } label: {
                        HStack {
                            Text(week.localizedHeader(locale: locale))
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                            // Contextual link → corresponding phase section in MethodologyView
                            MethodologyButton(section: week.phase.methodologySection)
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
                    .padding(.vertical, 8)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.0, green: 0.0, blue: 0.3))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

#if DEBUG  // CSV export button for testing
                    Button(action: exportCSV) {
                        HStack {
                            Spacer()
                            Label("Esporta Piano in CSV", systemImage: "tablecells.badge.ellipsis")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.vertical, 8)
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
#endif
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
                    .padding(.vertical, 8)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

            } header: {
                Text("Condivisione")
            }

            Section("Note") {
                Text("I ritmi di allenamento sono calcolati tramite il sistema VDOT di Jack Daniels. La distribuzione settimanale segue il principio di polarizzazione 80/20 (Seiler). La progressione del volume rispetta la regola del 10% per prevenire infortuni.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .alert("Calendario Aggiornato", isPresented: $calendarManager.showConfirmation) {
            Button("Ottimo", role: .cancel) { }
        } message: {
            Text(
                AppLocalizedString.formatted(
                    LocalizedStringResource(
                        "Ho aggiunto correttamente %lld eventi al tuo calendario 'PB Running'.",
                        defaultValue: "Ho aggiunto correttamente %1$lld eventi al tuo calendario 'PB Running'."
                    ),
                    locale: locale,
                    arguments: [calendarManager.lastEventCount]
                )
            )
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

        // Save all workouts into allEvents
        var allEvents: [EventData] = []
        for week in plan.weeks {
            for workout in week.workouts {
                // Exclude rest days
                guard workout.type != .rest else { continue }

                // 1. Pace handling using UnitSystem
                var paceString = ""
                if let paceSecsPerKm = workout.paceTargetSecsPerKm {
                    paceString = "@ " + unitSystem.formatPace(paceSecsPerKm)
                }

                // 2. Distance handling using UnitSystem
                let distanceString: String
                if let kms = workout.distanceKm {
                    distanceString = unitSystem.formatDistance(kms)
                } else {
                    distanceString = AppLocalizedString.resolve(
                        LocalizedStringResource("export.notAvailable", defaultValue: "N/A"),
                        locale: locale
                    )
                }

                // 3. Create event notes
                let structuredDetails = workout.localizedStructuredSets(locale: locale).map { "📋 \($0)" } ?? ""
                let notes = """
                \(workout.localizedDescription(locale: locale))

                \(structuredDetails)

                ❤️ RPE: \(workout.rpe)
                \(workout.localizedIntensityDescription(locale: locale))
                """

                // 4. Create EventData object
                let newEvent = EventData(
                    date: workout.date,
                    title: "W\(week.weekNumber) \(workout.localizedTitle(locale: locale)) - \(distanceString) \(paceString) ",
                    notes: notes
                )
                allEvents.append(newEvent)
            }
        }

#if DEBUG
        // --- PRINT TO CONSOLE ---

        print("\n--- EVENTS TO WRITE (\(allEvents.count)) ---")

        allEvents.forEach { event in
            let dateStr = event.date.formatted(date: .abbreviated, time: .omitted)
            print("📅 Date: \(dateStr) | 🏃 Title: \(event.title)")
            print("📝 Notes: \(event.notes)")
            print("------------------------------------------\n")
        }
#endif

        // Write to calendar
        calendarManager.addEventsBatch(allEvents)
    }

    private func exportPDF() {
        print("Exporting PDF...")

        // 1. Generate the data
        let data = TrainingPlanPDFGenerator().generatePDF(plan: plan, unitSystem: unitSystem, locale: locale)

        // 2. Setup the temporary file path
        let localizedSuffix = String(
            localized: LocalizedStringResource(
                "export.pdf.filenameSuffix",
                defaultValue: "_piano"
            )
        )
        let fileName = "\(plan.input.raceName.replacingOccurrences(of: " ", with: "_"))\(localizedSuffix).pdf"
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

    func formatTimeForFilename(_ seconds: Double) -> String {
        guard seconds > 0 else { return "" }
        let hour = Int(seconds) / 3600
        let minute = (Int(seconds) % 3600) / 60
        let second = Int(seconds) % 60

        if hour > 0 {
            return String(format: "%dh%02dm%02ds", hour, minute, second)
        }
        return String(format: "%dm%02ds", minute, second)
    }

    // MARK: - Export CSV Logic
    private func exportCSV() {
        print("Exporting CSV...")

        // 1. Add UTF-8 BOM prefix and use ";" as separator
        let header = AppLocalizedString.resolve(
            LocalizedStringResource(
                "export.csvHeader",
                defaultValue: "Settimana;Data;Nome Workout;Distanza;Passo"
            ),
            locale: locale
        )
        var csvString = "\u{FEFF}" + header + "\n"

        // Date formatter including day of week
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEEddMMMM")

        // 2. Iterate weeks and workouts
        for week in plan.weeks {
            for workout in week.workouts {
                let weekNum = "\(week.weekNumber)"
                let dateStr = dateFormatter.string(from: workout.date)

                // Sanitize title if it contains the separator ";"
                let localizedTitle = workout.localizedTitle(locale: locale)
                let title = localizedTitle.contains(";") ? "\"\(localizedTitle)\"" : localizedTitle

                // Clean distance formatting without units, using comma for decimals
                let distanceStr: String
                if let kms = workout.distanceKm {
                    let rawDistance = unitSystem.formatDistance(kms)
                    // Remove everything that is not a number, dot, or comma
                    var cleanedNumber = rawDistance.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression, range: nil)
                    // Replace Anglo-Saxon decimal point with comma
                    cleanedNumber = cleanedNumber.replacingOccurrences(of: ".", with: ",")

                    distanceStr = cleanedNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    distanceStr = "" // Leave cell empty if no distance (e.g. Rest)
                }

                // Pace formatting based on unitSystem
                let paceStr: String
                if let secsPerKm = workout.paceTargetSecsPerKm, workout.type != .rest {
                    paceStr = unitSystem.formatPace(secsPerKm)
                } else {
                    paceStr = "-"
                }

                // Compose row using ";"
                let row = "\(weekNum);\(dateStr);\(title);\(distanceStr);\(paceStr)\n"
                csvString.append(row)
            }
        }

        // 3. Prepare and write temporary .csv file

        // --- DYNAMIC FILENAME GENERATION ---
        // Sanitize race name
        let baseRaceName = plan.input.raceName.replacingOccurrences(of: " ", with: "_")

        // Format times into readable strings for filenames (e.g. 1h45m00s or 55m00s)
        let targetTimeStr = formatTimeForFilename(Double(plan.input.targetTime))
        let currentTimeStr = formatTimeForFilename(Double(plan.input.currentPerformance.time))

        // Build suffix based on presence of required data
        let metricsSuffix: String
        if !targetTimeStr.isEmpty && !currentTimeStr.isEmpty {
            metricsSuffix = "_Target_\(targetTimeStr)_Current_\(currentTimeStr)"
        } else {
            // Fallback if times are empty or zero
            metricsSuffix = ""
        }

        let fileName = "\(baseRaceName)\(metricsSuffix).csv"

        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            // If file already exists in 'tmp', remove it
            if FileManager.default.fileExists(atPath: tmpURL.path) {
                try FileManager.default.removeItem(at: tmpURL)
                print("Old CSV file removed successfully.")
            }
            // UTF-8 writing
            try csvString.write(to: tmpURL, atomically: true, encoding: .utf8)
            print("CSV saved to: \(tmpURL.path)")

            // 4. Activate native share sheet
            self.csvItem = DocumentItem(url: tmpURL)
        } catch {
            print("Failed to export CSV file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Week Header View
struct WeekHeaderView: View {
    let week: TrainingWeek
    let locale: Locale
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(week.localizedWeeklyNote(locale: locale))
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
    let locale: Locale
    @State private var expanded = false
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                HStack {
                    WorkoutBadge(type: workout.type, size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.date.formatted(.dateTime.weekday().day().month()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(workout.localizedTitle(locale: locale))
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

                    Text(workout.localizedDescription(locale: locale))
                        .font(.footnote)

                    if let sets = workout.localizedStructuredSets(locale: locale) {
                        Label(sets, systemImage: "list.bullet.clipboard")
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }

                    HStack {
                        Label {
                            Text("RPE: \(workout.rpe)")
                        } icon: {
                            Image(systemName: "heart.fill")
                        }
                        Spacer()
                        Text(workout.localizedIntensityDescription(locale: locale))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - WorkoutBadge
struct WorkoutBadge: View {
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
        .environment(\.locale, .init(identifier: "en"))
    }
}
