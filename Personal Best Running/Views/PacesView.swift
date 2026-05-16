import SwiftUI

// MARK: - PacesView
struct PacesView: View {
    let plan: TrainingPlan
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    // swiftlint:disable:next large_tuple
    private var paceRows: [(type: WorkoutType, pace: String, rpe: String, detail: String)] {
        let passo = plan.paces
        return [
            (.easy, passo.easyFormatted(unitSystem: unitSystem),
             "4-5", "59-74% VO2max · 65-79% FCmax"),

            (.longRun, passo.easyFormatted(unitSystem: unitSystem),
             "5-6", "E-pace prolungato · max 25% vol. sett. · max 150 min"),

            (.marPace, passo.mpFormatted(unitSystem: unitSystem),
             "6-7", "75-84% VO2max · 80-89% FCmax"),

            (.tempo, passo.thresholdFormatted(unitSystem: unitSystem),
             "7-8", "85-88% VO2max · 88-92% FCmax · max 10% vol. sett."),

            (.interval, passo.intervalFormatted(unitSystem: unitSystem),
             "8-9", "95-100% VO2max · rec. attivo (jog) · max 8% vol. sett."),

            // [FIX-2] R-pace: velocità pura, work bout MAX 2 min, rec. COMPLETO.
            (.repetition, passo.repetitionFormatted(unitSystem: unitSystem),
             "9+", "105-120% VDOT · max 2 min/rep · rec. completo · max 5% vol. sett.")
        ]
    }

    var body: some View {
        List {
            // MARK: Profilo Atleta
//            Section {
//                VStack(spacing: 14) {
//
//                    // Riga VDOT / Stima / Target
//                    HStack {
//                        vdotBadge
//                        Spacer()
//                        Divider().frame(height: 44)
//                        Spacer()
//                        timeColumn(
//                            label: "Stima Attuale",
//                            value: formatTime(plan.estimatedRaceTime),
//                            subtitle: plan.input.raceDistance.rawValue,
//                            valueColor: .primary
//                        )
//                        Spacer()
//                        Divider().frame(height: 44)
//                        Spacer()
//                        timeColumn(
//                            label: "Target",
//                            value: formatTime(plan.input.targetTime),
//                            subtitle: plan.input.raceDistance.rawValue,
//                            valueColor: targetColor
//                        )
//                    }
//                    .padding(.vertical, 4)
//
//                    Divider()
//
//                    // Barra livello runner.
//                    // Il livello è calcolato dal VDOT attuale e dal sesso,
//                    // usando le soglie differenziate per distribuzione di popolazione.
//                    // Fonte: RunRepeat Global Report 2023, WMA age-grading tables.
//                    RunnerLevelBar(
//                        level: plan.input.sex.runnerLevel(vdot: plan.paces.vdot),
//                        sex: plan.input.sex
//                    )
//
//                    Divider()
//
//                    // Gap fitness
//                    Text(plan.fitnessGap)
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                }
//                .padding(.vertical, 4)
//            } header: {
//                Text("Profilo Atleta")
//            }
//            .padding(.top, 20)

            // MARK: Andature di Allenamento
            // Le andature si basano sul VDOT attuale, non sul target.
            // Fonte: Daniels [1] cap. 4 – "Train at the level you are."
            Section {
                ForEach(paceRows, id: \.type) { row in
                    PaceRow(type: row.type, pace: row.pace, rpe: row.rpe, detail: row.detail)
                }
            } header: {
                Text("Andature di Allenamento")
            }
            .padding(.top, 20)

            // MARK: Note
            Section {
                NoteRow(
                    symbol: "info.circle",
                    title: "Come sono calcolate",
                    text: "Le andature si basano sul tuo VDOT attuale (\(String(format: "%.1f", plan.paces.vdot))), non sull'obiettivo. Ci si allena alla forma che si ha oggi: i ritmi migliorano man mano che il VDOT cresce."
                )
                NoteRow(
                    symbol: "chart.pie",
                    title: "Distribuzione 80/20",
                    text: "~80% del volume a E-pace (Z2), ~20% a T/I/R (Z4-Z5+). Fonte: Seiler & Kjerland (2006)."
                )
                NoteRow(
                    symbol: "ruler",
                    title: "Lungo: max 25% del volume settimanale",
                    text: "Il lungo non supera il 25% del volume settimanale né 150 minuti. Fonte: Daniels (2022) cap. 4."
                )
                NoteRow(
                    symbol: "questionmark.circle",
                    title: "Zona 1 (Z1) - perché non è in tabella",
                    text: """
                        Daniels non assegna un ritmo specifico alla Z1: \
                        l'E-pace (Z2, 59-74% VO2max) copre già tutto il range di bassa intensità, \
                        recupero attivo incluso. \
                        Nei giorni di recupero corri al limite inferiore dell'E-pace \
                        senza un target preciso — l'obiettivo è muoversi, non allenare.
                        """
                )
            } header: {
                Text("Note")
            }
        }
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

    private var targetColor: Color {
        let targetVDOT = VDOTCalculator.calculate(
            timeInSeconds: plan.input.targetTime,
            distanceMeters: plan.input.raceDistance.meters
        )
        let gap = targetVDOT - plan.paces.vdot
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

// MARK: - PaceRow
struct PaceRow: View {
    //
    // Legge colore, SF Symbol, zoneLabel e danielsCode direttamente da WorkoutType.
    // Non contiene valori hardcoded: qualsiasi modifica all'enum si propaga
    // automaticamente sia qui che in calendarView.

    let type: WorkoutType
    let pace: String
    let rpe: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {

            // Badge: cerchio colorato con SF Symbol
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: type.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(type.color)
            }

            // Label tipo + dettaglio intensità
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(type.rawValue)
                        .font(.subheadline.weight(.medium))
                    // Codice Daniels (E/M/T/I/R) come badge compatto
                    if !type.danielsCode.isEmpty {
                        Text(type.danielsCode)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(type.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(type.color.opacity(0.12), in: Capsule())
                    }
                }
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
                    Text(type.zoneLabel)
                        .font(.caption2.bold())
                        .foregroundStyle(type.color)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - NoteRow
struct NoteRow: View {
    // Riga uniforme per la sezione Note: SF Symbol + titolo + corpo testo.
    // Evita la ripetizione di Label + Text + Divider in tutto il footer.

    let symbol: String
    let title: String
    let text: String   // rinominato da 'body' per evitare conflitto con View.body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - RunnerLevelBar
struct RunnerLevelBar: View {
    // Barra orizzontale che visualizza il livello del runner sulla scala a 5 step.
    // Il livello è calcolato da RunnerSex.runnerLevel(vdot:) usando soglie
    // differenziate per sesso (RunRepeat 2023, WMA age-grading).
    //
    // Struttura visiva:
    //   Label "Livello atleta"   [badge capsule con nome livello]
    //   ●────────────●─ ─ ─ ─ ─●  ← barra con fill fino al livello attivo
    //   Principiante  Amatore  Intermedio  Avanzato  Elite
    //
    // Il fill della barra usa .green per coerenza con il WorkoutType.easy color:
    // il livello non è un'intensità di allenamento ma una misura di fitness.

    let level: RunnerLevel
    let sex: RunnerSex

    // Tutti i livelli in ordine crescente — usati per posizione e label.
    private let levels: [RunnerLevel] = [
        .beginner, .recreational, .intermediate, .advanced, .elite
    ]

    // Indice (0-based) del livello corrente
    private var levelIndex: Int {
        levels.firstIndex(of: level) ?? 0
    }

    // Frazione di riempimento della barra (0.0 – 1.0)
    // Centro di ogni step: 0/4, 1/4, 2/4, 3/4, 4/4
    private var fillFraction: Double {
        Double(levelIndex) / Double(levels.count - 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Header: label + badge nome livello
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

            // Barra con dots agli step
            GeometryReader { geo in
                let dotCount = levels.count          // 5
                let spacing = geo.size.width / CGFloat(dotCount - 1)

                ZStack(alignment: .leading) {

                    // Traccia sfondo
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)

                    // Fill fino al livello corrente
                    Capsule()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: geo.size.width * fillFraction, height: 4)
                        .animation(.easeInOut(duration: 0.4), value: levelIndex)

                    // Dots agli step
                    ForEach(0..<dotCount, id: \.self) { i in
                        let isReached = i <= levelIndex
                        Circle()
                            .fill(isReached ? Color.blue : Color.secondary.opacity(0.25))
                            .frame(width: 8, height: 8)
                            .offset(x: CGFloat(i) * spacing - 4)
                            .animation(.easeInOut(duration: 0.4), value: levelIndex)
                    }
                }
                .frame(height: 8)   // altezza = diametro dot
            }
            .frame(height: 8)

            // Label step
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
        PacesView(plan: samplePlan)
    }
}
