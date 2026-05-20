import SwiftUI

// MARK: - AthleteProfileView
//
// Vista indipendente del profilo atleta.
// Contiene:
//   1. Riga VDOT / Stima attuale / Target
//   2. Barra livello runner (RunnerLevelBar)
//   3. Previsioni multi-distanza dal VDOT attuale
//   4. Descrizione livello corrente + gap verso il livello successivo

struct AthleteProfileView: View {
    let plan: TrainingPlan

    private var vdot: Double {plan.paces.vdot}
    private var sex: RunnerSex {plan.input.sex}
    private var level: RunnerLevel {sex.runnerLevel(vdot: vdot)}

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

                    // Barra livello runner. Usa soglie differenziate per sesso (RunRepeat 2023, WMA).
                    RunnerLevelBar(level: level, sex: sex)

                    Divider()
                }
                .padding(.vertical, 4)
            } header: {
                Text("Profilo Atleta")
                    .padding(.top , 20)
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
            HStack(spacing: 4) {
                Text("VDOT")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                // Link contestuale → sezione VDOT in MethodologyView
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
//    private var vdotBadge: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            Text("VDOT")
//                .font(.caption)
//                .foregroundStyle(.secondary)
//            Text(String(format: "%.1f", vdot))
//                .font(.title2.bold())
//                .foregroundStyle(.indigo)
//            Text("forma attuale")
//                .font(.caption2)
//                .foregroundStyle(.tertiary)
//        }
//    }

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

    private var targetColor: Color { plan.feasibility.color }

    private func formatTime(_ seconds: Double) -> String {
        let ore = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        let sec = Int(seconds) % 60
        if ore > 0 { return String(format: "%d:%02d:%02d", ore, min, sec) }
        return String(format: "%d:%02d", min, sec)
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
                /// Usa unitSystem.formatPace per rispettare la preferenza metrico/imperiale.
                /// Il suffisso (/km o /mi) è già incluso in unitSystem.formatPace.
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
        let sogliaLivello = sex.levelThresholds
        switch level {
        case .beginner:     return sogliaLivello.recreational
        case .recreational: return sogliaLivello.intermediate
        case .intermediate: return sogliaLivello.advanced
        case .advanced:     return sogliaLivello.elite
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

                    Text("Con un piano di 16-20 settimane è realistico guadagnare 3-5 punti VDOT.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true) // per vedere tutto il text (problema con GeometryReader)

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
        sex: .male
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

    private let levels: [RunnerLevel] = [
        .beginner, .recreational, .intermediate, .advanced, .elite
    ]

    private var levelIndex: Int {
        levels.firstIndex(of: level) ?? 0
    }

    private var fillFraction: Double {
        Double(levelIndex) / Double(levels.count - 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Livello atleta")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(level.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12), in: Capsule())
            }

            GeometryReader { geo in
                let dotCount = levels.count
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

            HStack(spacing: 0) {
                ForEach(0..<levels.count, id: \.self) { i in
                    let isActive = i == levelIndex
                    Text(levels[i].rawValue)
                        .font(.system(size: 10))
                        .fontWeight(isActive ? .bold : .regular)
                        .foregroundStyle(isActive ? Color.blue : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}
