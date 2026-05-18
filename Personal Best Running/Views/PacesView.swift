import SwiftUI

// MARK: - PacesView
struct PacesView: View {
    let plan: TrainingPlan
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    // Righe in ordine crescente di intensità.
    // I tipi senza ritmo proprio (rest, recovery, progression, hillRepeat, race)
    // non appaiono qui — non hanno un pace target definito da Daniels.
    private var paceRows: [(type: WorkoutType, pace: String, rpe: String, detail: String)] { // swiftlint:disable:this large_tuple

        let piano = plan.paces
        return [
            (.easy, piano.easyFormatted(unitSystem: unitSystem),
             "4-5", "59-74% VO2max · 65-79% FCmax"),

            (.longRun, piano.easyFormatted(unitSystem: unitSystem),
             "5-6", "E-pace prolungato · max 25% vol. sett. · max 150 min"),

            (.marPace, piano.mpFormatted(unitSystem: unitSystem),
             "6-7", "75-84% VO2max · 80-89% FCmax"),

            (.tempo, piano.thresholdFormatted(unitSystem: unitSystem),
             "7-8", "85-88% VO2max · 88-92% FCmax · max 10% vol. sett."),

            (.interval, piano.intervalFormatted(unitSystem: unitSystem),
             "8-9", "95-100% VO2max · rec. attivo (jog) · max 8% vol. sett."),

            (.repetition, piano.repetitionFormatted(unitSystem: unitSystem),
             "9+", "105-120% VDOT · max 2 min/rep · rec. completo · max 5% vol. sett.")
        ]
    }

    var body: some View {
        List {
            Section {
                ForEach(paceRows, id: \.type) { row in
                    PaceRow(
                        type: row.type,
                        pace: row.pace,
                        rpe: row.rpe,
                        detail: row.detail
                    )
                }
            } header: {
                Text("Andature di Allenamento")
                    .padding(.top, 20)

            } footer: {
                Text("Basate sul VDOT attuale \(String(format: "%.1f", plan.paces.vdot)). Ci si allena alla forma che si ha oggi, non a quella obiettivo.")
                    .font(.caption)
            }

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
                    title: "Zona 1 (Z1) — perché non è in tabella",
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
}

// MARK: - PaceRow
struct PaceRow: View {
    let type: WorkoutType
    let pace: String
    let rpe: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: type.sfSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(type.rawValue)
                        .font(.subheadline.weight(.medium))
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
    let symbol: String
    let title: String
    let text: String

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
