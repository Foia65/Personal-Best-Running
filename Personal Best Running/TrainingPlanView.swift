import SwiftUI

// MARK: - Training Plan View

struct TrainingPlanView: View {
    let plan: TrainingPlan
    var onBack: () -> Void

    @State private var selectedTab = 0
    @State private var expandedWeek: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header con info piano
            planHeaderView

            Picker("Vista", selection: $selectedTab) {
                Text("Calendario").tag(0)
                Text("Ritmi").tag(1)
                Text("Fonti").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            TabView(selection: $selectedTab) {
                calendarView.tag(0)
                pacesView.tag(1)
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
                            Spacer()
                            Image(systemName: expandedWeek == week.weekNumber ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.primary)
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: Paces

    var pacesView: some View {
        List {
            Section("Il Tuo Profilo") {
                LabeledContent("VDOT", value: String(format: "%.1f", plan.paces.vdot))
                LabeledContent("Tempo stimato attuale", value: formatTime(plan.estimatedRaceTime))
            }

            Section("Ritmi di Allenamento") {
                PaceRow(label: "Recupero 🟡", pace: plan.paces.recoveryFormatted, rpe: "3", zone: "Z1")
                PaceRow(label: "Facile 🟢", pace: plan.paces.easyFormatted, rpe: "4-5", zone: "Z2")
                PaceRow(label: "Ritmo Maratona 🎯", pace: plan.paces.mpFormatted, rpe: "6-7", zone: "Z3")
                PaceRow(label: "Soglia / Tempo 🟠", pace: plan.paces.thresholdFormatted, rpe: "7-8", zone: "Z4")
                PaceRow(label: "Interval / VO2max 🔴", pace: plan.paces.intervalFormatted, rpe: "8-9", zone: "Z5")
            }

            Section("Distribuzione Intensità Raccomandata") {
                Text("80% bassa intensità (Z1-Z2) + 20% alta intensità (Z4-Z5)")
                    .font(.callout)
                Text("Fonte: Seiler & Kjerland (2006) – distribuzione polarizzata")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
}

// MARK: - Week Header View

struct WeekHeaderView: View {
    let week: TrainingWeek

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(week.phase.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(phaseColor)
                Text(week.weeklyNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.0f km", week.totalKm))
                    .font(.title3.bold())
                Text("volume")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    var phaseColor: Color {
        switch week.phase {
        case .base: return .blue
        case .build: return .orange
        case .peak: return .red
        case .taper: return .green
        case .race: return .purple
        }
    }
}

// MARK: - Workout Row View

struct WorkoutRowView: View {
    let workout: Workout
    @State private var expanded = false

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
                        if let km = workout.distanceKm {
                            Text(String(format: "%.1f km", km))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let pace = workout.paceTarget, workout.type != .rest {
                        Text(pace)
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
                        .font(.callout)

                    if let sets = workout.structuredSets {
                        Label(sets, systemImage: "list.bullet.clipboard")
                            .font(.callout)
                            .foregroundStyle(.blue)
                    }

                    HStack {
                        Label("RPE: \(workout.rpe)", systemImage: "heart.fill")
                        Spacer()
                        Text(workout.type.intensityDescription)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    DisclosureGroup("📚 Razionale scientifico") {
                        Text(workout.scientificRationale)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption.bold())
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

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(zone)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 30)
            Text(pace)
                .font(.subheadline.monospaced().bold())
            Text("RPE \(rpe)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 55)
        }
    }
}
