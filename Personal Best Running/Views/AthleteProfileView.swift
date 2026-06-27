import SwiftUI

// MARK: - AthleteProfileView
//
// Independent athlete profile view.
// Contains:
//   1. VDOT row / Current estimate / Target
//   2. Runner level bar (RunnerLevelBar)
//   3. Multi-distance predictions from current VDOT
//   4. Current level description + gap to next level

struct AthleteProfileView: View {
    let plan: TrainingPlan

    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male

    private var vdot: Double {plan.paces.vdot}
    private var sex: RunnerSex {runnerSex}
    private var level: RunnerLevel {sex.runnerLevel(vdot: vdot)}

    var body: some View {
        List {

            // MARK: VDOT + Times + Level
            Section {
                VStack(spacing: 14) {

                    // VDOT row / Current estimate / Target
                    HStack {
                        vdotBadge
                        Spacer()
                        Divider().frame(height: 44)
                        Spacer()
                        timeColumn(
                            label: "Stima Attuale",
                            value: formatTime(plan.estimatedRaceTime),
                            subtitle: plan.input.raceDistance.localizedName,
                            valueColor: .primary
                        )
                        Spacer()
                        Divider().frame(height: 44)
                        Spacer()
                        timeColumn(
                            label: "Target",
                            value: formatTime(plan.input.targetTime),
                            subtitle: plan.input.raceDistance.localizedName,
                            valueColor: targetColor
                        )
                    }
                    .padding(.vertical, 4)

                    Divider()

                    // Runner level bar. Uses sex-differentiated thresholds (RunRepeat 2023, WMA).
                    RunnerLevelBar(level: level, sex: sex)

                    Divider()
                }
                .padding(.vertical, 4)
            } header: {
                Text("Profilo Atleta")
                    .padding(.top, 20)
            }

            // MARK: Multi-Distance Predictions
            // Estimated times on all standard distances from current VDOT.
            // Helps understand fitness on distances other than the target.
            // Source: VDOTCalculator.predictRaceTime — same algorithm as paces.
            Section {
                ForEach(RaceDistance.allCases) { distance in
                    MultiDistancePredictionRow(
                        distance: distance,
                        vdot: vdot,
                        isTarget: distance == plan.input.raceDistance
                    )
                }
            } header: {
                Text("Previsioni dal VDOT Attuale")
            } footer: {
                Text("Stime basate sul VDOT \(String(format: "%.1f", vdot)), indipendentemente dalla distanza obiettivo del piano.")
                    .font(.caption)
            }

            // MARK: Level and Progression
            Section {
                RunnerLevelDescriptionView(level: level, vdot: vdot, sex: sex)
            } header: {
                Text("Il Tuo Livello")
            }
        }
    }

    // MARK: - Subviews

    private var vdotBadge: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text("VDOT")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                // Contextual link → VDOT section in MethodologyView
                MethodologyButton(section: .vdot)
            }
            Text(String(format: "%.1f", vdot))
                .font(.title2.bold())
                .foregroundStyle(.indigo)
            Text("forma attuale")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func timeColumn(
        label: LocalizedStringKey,
        value: String,
        subtitle: LocalizedStringResource,
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

    private var targetColor: Color { plan.feasibility.color }
}

// MARK: - MultiDistancePredictionRow
//
// Single prediction row: distance + estimated time + average pace.
// Highlights the plan's target distance with a "target" badge.

struct MultiDistancePredictionRow: View {
    let distance: RaceDistance
    let vdot: Double
    let isTarget: Bool
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    private var predictedSeconds: Double {
        VDOTCalculator.predictRaceTime(vdot: vdot, distance: distance)
    }

    private var predictedPaceSecsPerKm: Double {
        predictedSeconds / distance.meters * 1000
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(distance.localizedName)
                        .font(.subheadline.weight(.medium))
                    if isTarget {
                        Text("obiettivo")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.indigo)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.1), in: Capsule())
                    }
                }
                // Uses unitSystem.formatPace to respect metric/imperial preference.
                // The suffix (/km or /mi) is already included in unitSystem.formatPace.
                Text(unitSystem.formatPace(predictedPaceSecsPerKm))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatTime(predictedSeconds))
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(isTarget ? .indigo : .primary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - RunnerLevelDescriptionView
//
// Describes the current level and shows how much VDOT is needed to reach
// the next level, with a progress bar in the current range.

struct RunnerLevelDescriptionView: View {
    let level: RunnerLevel
    let vdot: Double
    let sex: RunnerSex

    private var levelDescription: LocalizedStringKey {
        switch level {
        case .beginner:
            return "Stai costruendo le fondamenta. L'obiettivo principale è la continuità: completare le sessioni con regolarità è più importante del ritmo."
        case .recreational:
            return "Corri con una certa regolarità e hai sviluppato una base aerobica solida. Puoi iniziare a introdurre sessioni di qualità leggere."
        case .intermediate:
            return "Hai una base aerobica ben sviluppata e tolleri sessioni di qualità. Puoi lavorare su soglia e ritmo maratona con buoni risultati."
        case .advanced:
            return "Sei un runner allenato con capacità aerobica elevata. Sessioni I e R producono adattamenti significativi a questo livello."
        case .elite:
            return "Prestazioni di alto livello. L'ottimizzazione riguarda dettagli fisiologici fini: periodizzazione, recupero e picco di forma."
        }
    }

    private var vdotToNextLevel: Double? {
        let sogliaLivello = sex.levelThresholds
        switch level {
        case .beginner:     return sogliaLivello.recreational
        case .recreational: return sogliaLivello.intermediate
        case .intermediate:  return sogliaLivello.advanced
        case .advanced:     return sogliaLivello.elite
        case .elite:        return nil
        }
    }

    private var nextLevelName: LocalizedStringResource? {
        switch level {
        case .beginner:     return RunnerLevel.recreational.localizedRunnerLevel
        case .recreational: return RunnerLevel.intermediate.localizedRunnerLevel
        case .intermediate: return RunnerLevel.advanced.localizedRunnerLevel
        case .advanced:     return RunnerLevel.elite.localizedRunnerLevel
        case .elite:        return nil
        }
    }

    // Start of current level VDOT range (for progress bar)
    private var vdotRangeStart: Double {
        let sogliaLivello = sex.levelThresholds
        switch level {
        case .beginner:     return 0
        case .recreational: return sogliaLivello.recreational
        case .intermediate: return sogliaLivello.intermediate
        case .advanced:     return sogliaLivello.advanced
        case .elite:        return sogliaLivello.elite
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Narrative description
            Text(levelDescription)
                .font(.footnote)
                .foregroundStyle(.primary)

            // Gap to next level
            if let nextVDOT = vdotToNextLevel, let nextName = nextLevelName {
                let gap = nextVDOT - vdot
                let rangeWidth = nextVDOT - vdotRangeStart
                let progress = min(1.0, max(0.0, (vdot - vdotRangeStart) / rangeWidth))

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.up.circle")
                            .foregroundStyle(.blue)
                            .font(.footnote)
                        Text("Verso \(nextName)")
                            .font(.footnote.bold())
                        Spacer()
                        Text("mancano \(String(format: "%.1f", gap)) pt VDOT")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                    }

                    // Progress bar in current range
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 4)
                            Capsule()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: geo.size.width * progress, height: 4)
                                .animation(.easeInOut(duration: 0.4), value: progress)
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text("VDOT \(String(format: "%.1f", vdotRangeStart))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("VDOT \(String(format: "%.1f", nextVDOT))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text("Con un piano di 16-20 settimane è realistico guadagnare 3-5 punti VDOT.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true) // to see all text (GeometryReader issue)

                }
            } else {
                Label("Hai raggiunto il livello massimo della scala.", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview  {
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
        sex: .female
    )

    let samplePlan = TrainingPlanGenerator().generate(input: sampleInput)

    NavigationStack {
        AthleteProfileView(plan: samplePlan)
    }
}

// MARK: - RunnerLevelBar
struct RunnerLevelBar: View {
    let level: RunnerLevel
    let sex: RunnerSex

    private var levelIndex: Int {
        RunnerLevel.allCases.firstIndex(of: level) ?? 0
    }

    private var fillFraction: Double {
        Double(levelIndex) / Double(RunnerLevel.allCases.count - 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Livello atleta")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(level.localizedRunnerLevel)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12), in: Capsule())
            }

            GeometryReader { geo in
                let dotCount = RunnerLevel.allCases.count
                let spacing = geo.size.width / CGFloat(dotCount - 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                    Capsule()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: geo.size.width * fillFraction, height: 4)
                        .animation(.easeInOut(duration: 0.4), value: levelIndex)
                    ForEach(0..<dotCount, id: \.self) { i in
                        let isReached = i <= levelIndex
                        Circle()
                            .fill(isReached ? Color.blue : Color.secondary.opacity(0.25))
                            .frame(width: 8, height: 8)
                            .offset(x: CGFloat(i) * spacing - 4)
                            .animation(.easeInOut(duration: 0.4), value: levelIndex)
                    }
                }
                .frame(height: 8)
            }
            .frame(height: 8)

            // Used another GeometryReader inside a ZStack
            // to align text labels to dots
            GeometryReader { geo in
                let dotCount = RunnerLevel.allCases.count
                let spacing = geo.size.width / CGFloat(dotCount - 1)
                ZStack(alignment: .topLeading) {
                    ForEach(Array(RunnerLevel.allCases.enumerated()), id: \.offset) { i, lvl in
                        let isActive = lvl == level
                        let xPos = CGFloat(i) * spacing
                        Text(lvl.localizedRunnerLevel)
                            .font(.system(size: 10))
                            .fontWeight(isActive ? .bold : .regular)
                            .foregroundStyle(isActive ? Color.blue : Color.secondary)
                            .multilineTextAlignment(i == dotCount - 1 ? .trailing : .leading)
                            .frame(width: spacing, alignment: i == dotCount - 1 ? .trailing : .leading)
                            .offset(x: i == dotCount - 1 ? geo.size.width - spacing : xPos)
                    }
                }
            }
            .frame(height: 20)
        }
    }
}
