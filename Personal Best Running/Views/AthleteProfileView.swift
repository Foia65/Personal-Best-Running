import SwiftUI

// Vista indipendente del profilo atleta.
// Contiene:
//   1. Riga VDOT / Stima attuale / Target
//   2. Barra livello runner (RunnerLevelBar)
//   3. Previsioni multi-distanza dal VDOT attuale
//   4. Descrizione livello corrente + gap verso il livello successivo

struct AthleteProfileView: View {
    let plan: TrainingPlan

    private var vdot: Double { plan.paces.vdot }
    private var sex: RunnerSex { plan.input.sex }
    private var level: RunnerLevel { sex.runnerLevel(vdot: vdot) }

    var body: some View {
        List {

            // MARK: VDOT + Tempi + Livello
            Section {
                VStack(spacing: 14) {

                    // Riga VDOT / Stima attuale / Target
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
                    .padding(.vertical, 4)

                    Divider()

                    // Barra livello runner.
                    // Usa soglie differenziate per sesso (RunRepeat 2023, WMA).
                    RunnerLevelBar(level: level, sex: sex)

                    Divider()

                    // Gap fitness VDOT attuale → target
                    Text(plan.fitnessGap)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }

            // MARK: Previsioni Multi-Distanza
            // Tempi stimati su tutte le distanze standard dal VDOT attuale.
            // Permette di capire la propria forma su distanze diverse da quella obiettivo.
            // Fonte: VDOTCalculator.predictRaceTime — stesso algoritmo dei ritmi.
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

            // MARK: Livello e Progressione
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
            Text("VDOT")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", vdot))
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

    private var targetColor: Color {
        let targetVDOT = VDOTCalculator.calculate(
            timeInSeconds: plan.input.targetTime,
            distanceMeters: plan.input.raceDistance.meters
        )
        let gap = targetVDOT - vdot
        switch gap {
        case ..<2:  return .green
        case 2..<5: return .orange
        default:    return .red
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let ore = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        let sec = Int(seconds) % 60
        if ore > 0 { return String(format: "%d:%02d:%02d", ore, min, sec) }
        return String(format: "%d:%02d", min, sec)
    }
}

// MARK: - RunnerLevelDescriptionView
//
// Descrive il livello corrente e mostra quanto VDOT manca per salire
// al livello successivo, con una barra di progressione nel range corrente.

struct RunnerLevelDescriptionView: View {
    let level: RunnerLevel
    let vdot: Double
    let sex: RunnerSex

    private var levelDescription: String {
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
        let sogliaLiv = sex.levelThresholds
        switch level {
        case .beginner:     return sogliaLiv.recreational
        case .recreational: return sogliaLiv.intermediate
        case .intermediate: return sogliaLiv.advanced
        case .advanced:     return sogliaLiv.elite
        case .elite:        return nil
        }
    }

    private var nextLevelName: String? {
        switch level {
        case .beginner:     return RunnerLevel.recreational.rawValue
        case .recreational: return RunnerLevel.intermediate.rawValue
        case .intermediate: return RunnerLevel.advanced.rawValue
        case .advanced:     return RunnerLevel.elite.rawValue
        case .elite:        return nil
        }
    }

    // Inizio del range VDOT del livello corrente (per la barra di progressione)
    private var vdotRangeStart: Double {
        let sogliaLiv = sex.levelThresholds
        switch level {
        case .beginner:     return 0
        case .recreational: return sogliaLiv.recreational
        case .intermediate: return sogliaLiv.intermediate
        case .advanced:     return sogliaLiv.advanced
        case .elite:        return sogliaLiv.elite
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Descrizione narrativa
            Text(levelDescription)
                .font(.footnote)
                .foregroundStyle(.primary)

            // Gap verso il livello successivo
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
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("mancano \(String(format: "%.1f", gap)) pt VDOT")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                    }

                    // Barra di progressione nel range corrente
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

//                    Text("Con un piano di 16-20 settimane è realistico guadagnare 3-5 punti VDOT.")
//                        .font(.caption2)
//                        .foregroundStyle(.secondary)
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

// MARK: - MultiDistancePredictionRow
//
// Singola riga della tabella previsioni: distanza + tempo stimato + passo medio.
// Evidenzia la distanza obiettivo del piano con un badge "obiettivo".

struct MultiDistancePredictionRow: View {
    let distance: RaceDistance
    let vdot: Double
    let isTarget: Bool

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
                    Text(distance.rawValue)
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
                Text(formatPace(predictedPaceSecsPerKm) + " /km medio")
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

    private func formatTime(_ seconds: Double) -> String {
        let ore = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        let sec = Int(seconds) % 60
        if ore > 0 { return String(format: "%d:%02d:%02d", ore, min, sec) }
        return String(format: "%d:%02d", min, sec)
    }

    private func formatPace(_ secsPerKm: Double) -> String {
        let min = Int(secsPerKm) / 60
        let sec = Int(secsPerKm) % 60
        return String(format: "%d:%02d", min, sec)
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
        sex: .male
    )
    
    let samplePlan = TrainingPlanGenerator().generate(input: sampleInput)
    
    NavigationStack {
        AthleteProfileView(plan: samplePlan)
    }
}
