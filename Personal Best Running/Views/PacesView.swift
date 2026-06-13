import SwiftUI

// MARK: - PacesView
struct PacesView: View {
    let plan: TrainingPlan
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @Environment(\.locale) private var locale

    // Rows in ascending order of intensity.
    // Types without their own pace (rest, recovery, progression, hillRepeat, race)
    // don't appear here — they have no pace target defined by Daniels.
    private var paceRows: [(type: WorkoutType, pace: String, rpe: String, detail: String, rpeText: String, name: String)] { // swiftlint:disable:this large_tuple

        let rpeResource = LocalizedStringResource("paces.rpe", defaultValue: "RPE %@")
        let piano = plan.paces
        return [
            (.easy, piano.easyFormatted(unitSystem: unitSystem),
             "4-5",
             AppLocalizedString.resolve(LocalizedStringResource("paces.detail.easy", defaultValue: "59-74% VO2max · 65-79% FCmax"), locale: locale),
             String(format: AppLocalizedString.resolve(rpeResource, locale: locale), "4-5"),
             AppLocalizedString.resolve(WorkoutType.easy.localizedName, locale: locale)),

            (.longRun, piano.easyFormatted(unitSystem: unitSystem),
             "5-6",
             AppLocalizedString.resolve(LocalizedStringResource("paces.detail.longRun", defaultValue: "E-pace prolungato · max 25% vol. sett. · max 150 min"), locale: locale),
             String(format: AppLocalizedString.resolve(rpeResource, locale: locale), "5-6"),
             AppLocalizedString.resolve(WorkoutType.longRun.localizedName, locale: locale)),

            (.marPace, piano.mpFormatted(unitSystem: unitSystem),
             "7",
             AppLocalizedString.resolve(LocalizedStringResource("paces.detail.marPace", defaultValue: "75-84% VO2max · 80-89% FCmax"), locale: locale),
             String(format: AppLocalizedString.resolve(rpeResource, locale: locale), "7"),
             AppLocalizedString.resolve(WorkoutType.marPace.localizedName, locale: locale)),

            (.tempo, piano.thresholdFormatted(unitSystem: unitSystem),
             "7-8",
             AppLocalizedString.resolve(LocalizedStringResource("paces.detail.tempo", defaultValue: "85-88% VO2max · 88-92% FCmax · max 10% vol. sett."), locale: locale),
             String(format: AppLocalizedString.resolve(rpeResource, locale: locale), "7-8"),
             AppLocalizedString.resolve(WorkoutType.tempo.localizedName, locale: locale)),

            (.interval, piano.intervalFormatted(unitSystem: unitSystem),
             "8-9",
             AppLocalizedString.resolve(LocalizedStringResource("paces.detail.interval", defaultValue: "95-100% VO2max · rec. attivo (jog) · max 8% vol. sett."), locale: locale),
             String(format: AppLocalizedString.resolve(rpeResource, locale: locale), "8-9"),
             AppLocalizedString.resolve(WorkoutType.interval.localizedName, locale: locale)),

            (.repetition, piano.repetitionFormatted(unitSystem: unitSystem),
             "8-9",
             AppLocalizedString.resolve(LocalizedStringResource("paces.detail.repetition", defaultValue: "105-120% VDOT · max 2 min/rep · rec. completo · max 5% vol. sett."), locale: locale),
             String(format: AppLocalizedString.resolve(rpeResource, locale: locale), "8-9"),
             AppLocalizedString.resolve(WorkoutType.repetition.localizedName, locale: locale))
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
                        detail: row.detail,
                        rpeText: row.rpeText,
                        name: row.name
                    )
                }
            } header: {
                Text("Ritmi di Allenamento")
                    .padding(.top, 20)

            } footer: {
                Text(AppLocalizedString.formatted(
                        LocalizedStringResource("paces.footer", defaultValue: "Basate sul VDOT attuale %@. Ci si allena alla forma che si ha oggi, non a quella obiettivo."),
                        locale: locale,
                        arguments: [String(format: "%.1f", plan.paces.vdot)]
                    ))
                    .font(.caption)
            }

            Section {
                let noteLocale = locale
                NoteRow(
                    symbol: "function",
                    title: AppLocalizedString.resolve(
                        LocalizedStringResource("paces.note.howCalculated", defaultValue: "Come sono calcolate"),
                        locale: locale
                    ),
                    text: AppLocalizedString.formatted(
                        LocalizedStringResource("paces.note.howCalculated.body", defaultValue: "Le andature si basano sul tuo VDOT attuale (%@), non sull'obiettivo. Ci si allena alla forma che si ha oggi: i ritmi migliorano man mano che il VDOT cresce."),
                        locale: noteLocale,
                        arguments: [String(format: "%.1f", plan.paces.vdot)]
                    ),
                    methodologySection: .vdot

                )
                NoteRow(
                    symbol: "chart.pie",
                    title: AppLocalizedString.resolve(
                        LocalizedStringResource("paces.note.volume8020", defaultValue: "Distribuzione 80/20"),
                        locale: locale
                    ),
                    text: AppLocalizedString.resolve(
                        LocalizedStringResource("paces.note.volume8020.body", defaultValue: "~80% del volume a E-pace (Z2), ~20% a T/I/R (Z4-Z5+). Fonte: Seiler & Kjerland (2006)."),
                        locale: locale
                    ),
                    methodologySection: .volume8020
                )
                NoteRow(
                    symbol: "ruler",
                    title: AppLocalizedString.resolve(
                        LocalizedStringResource("paces.note.longRun", defaultValue: "Lungo: max 25% del volume settimanale"),
                        locale: locale
                    ),
                    text: AppLocalizedString.resolve(
                        LocalizedStringResource("paces.note.longRun.body", defaultValue: "Il lungo non supera il 25% del volume settimanale né 150 minuti. Fonte: Daniels (2022) cap. 4."),
                        locale: locale
                    ),
                    methodologySection: .volumeLong

                )
                NoteRow(
                    symbol: "questionmark.circle",
                    title: AppLocalizedString.resolve(
                        LocalizedStringResource("paces.note.zone1", defaultValue: "Zona 1 (Z1) — perché non è in tabella"),
                        locale: locale
                    ),
                    text: AppLocalizedString.resolve(
                        LocalizedStringResource(
                            "paces.note.zone1.body",
                            defaultValue: """
                            Daniels non assegna un ritmo specifico alla Z1: \
                            l'E-pace (Z2, 59-74% VO2max) copre già tutto il range \
                            di bassa intensità, recupero attivo incluso. \
                            Nei giorni di recupero corri al limite inferiore dell'E-pace \
                            senza un target preciso — l'obiettivo è muoversi, non allenare.
                            """
                        ),
                        locale: locale
                    )
                )
            } header: {
                Text(AppLocalizedString.resolve(
                    LocalizedStringResource("paces.section.notes", defaultValue: "Note"),
                    locale: locale
                ))
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
    var rpeText: String?
    var name: String?

    private var resolvedRpeText: String {
        rpeText ?? "RPE \(rpe)"
    }

    private var resolvedName: String {
        name ?? type.rawValue
    }

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
                    Text(resolvedName)
                        .font(.subheadline.weight(.medium))
                    if !type.danielsCode.isEmpty {
                        Text(type.danielsCode)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(type.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(type.color.opacity(0.12), in: Capsule())
                    }
                    // Contextual link → corresponding zone section in MethodologyView
                    if let section = type.methodologySection {
                        MethodologyButton(section: section)
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
                    Text(resolvedRpeText)
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
    // Optional: if specified, shows a MethodologyButton next to the title.
    var methodologySection: MethodologySection?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Label(title, systemImage: symbol)
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
                if let section = methodologySection {
                    MethodologyButton(section: section)
                }
            }
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
