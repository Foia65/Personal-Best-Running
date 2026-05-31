import Foundation

// MARK: - App-localized strings (rispetta il language picker via locale esplicita)

enum AppLocalizedString {
    static func resolve(_ resource: LocalizedStringResource, locale: Locale) -> String {
        var resource = resource
        resource.locale = locale
        return String(localized: resource)
    }

    static func formatted(
        _ resource: LocalizedStringResource,
        locale: Locale,
        arguments: [CVarArg]
    ) -> String {
        let format = resolve(resource, locale: locale)
        return withVaList(arguments) { pointer in
            NSString(format: format, locale: locale, arguments: pointer) as String
        }
    }
}

// MARK: - Weekly note (TrainingWeek header)

enum WeeklyNoteKind {
    case baseDeload
    case baseProgress
    case buildMicroDeload
    case buildProgress
    case peak
    case taper
    case raceWeek

    func localizedText(locale: Locale) -> String {
        switch self {
        case .baseDeload:
            return Self.text(
                LocalizedStringResource("weeklyNote.baseDeload", defaultValue: "Settimana di scarico (↓20%): supercompensazione e adattamento. Fonte: principio di scarico [7], mantenimento [1]."),
                locale: locale
            )
        case .baseProgress:
            return Self.text(
                LocalizedStringResource("weeklyNote.baseProgress", defaultValue: "Base aerobica: ↑max 10% volume. Nessun lavoro I in questa fase. Fonte: regola del 10% [1][8]."),
                locale: locale
            )
        case .buildMicroDeload:
            return Self.text(
                LocalizedStringResource("weeklyNote.buildMicroDeload", defaultValue: "Micro-scarico nel blocco Build: volume -15%, qualità R+T mantenuta. Fonte: [1] principio manutenzione."),
                locale: locale
            )
        case .buildProgress:
            return Self.text(
                LocalizedStringResource("weeklyNote.buildProgress", defaultValue: "Build: R (velocità/economia) + T (soglia). Distribuzione ~80% bassa intensità, ~20% alta. Fonte: [1][4]."),
                locale: locale
            )
        case .peak:
            return Self.text(
                LocalizedStringResource("weeklyNote.peak", defaultValue: "Picco: T + I + ritmo gara. Massimo stimolo fisiologico. Fonte: [1] Phase III (TQ), [2] Pfitzinger."),
                locale: locale
            )
        case .taper:
            return Self.text(
                LocalizedStringResource("weeklyNote.taper", defaultValue: "TAPER: volume ↓40-60%, intensità invariata. Supercompensazione attesa. Fonte: Mujika & Padilla [6]."),
                locale: locale
            )
        case .raceWeek:
            return Self.text(
                LocalizedStringResource("weeklyNote.raceWeek", defaultValue: "Settimana di gara: solo riscaldamenti leggeri."),
                locale: locale
            )
        }
    }

    private static func text(_ resource: LocalizedStringResource, locale: Locale) -> String {
        AppLocalizedString.resolve(resource, locale: locale)
    }
}

// MARK: - Workout title

enum WorkoutTitleKind {
    case workoutType(WorkoutType)
    case easyRecovery
    case postRaceRest
    case racePace
    case raceName(String)

    func localizedText(locale: Locale) -> String {
        switch self {
        case .workoutType(let type):
            return AppLocalizedString.resolve(type.localizedName, locale: locale)
        case .easyRecovery:
            return AppLocalizedString.resolve(
                LocalizedStringResource(
                    "workoutTitle.easyRecovery",
                    defaultValue: "Corsa Facile (Recupero)"
                ),
                locale: locale
            )
        case .postRaceRest:
            return AppLocalizedString.resolve(
                LocalizedStringResource(
                    "workoutTitle.postRaceRest",
                    defaultValue: "Riposo post-gara"
                ),
                locale: locale
            )
        case .racePace:
            return AppLocalizedString.resolve(
                LocalizedStringResource(
                    "workoutTitle.racePace",
                    defaultValue: "Ritmo Gara"
                ),
                locale: locale
            )
        case .raceName(let name):
            return name
        }
    }
}

// MARK: - Workout description

enum WorkoutDescriptionKind {
    case rest
    case postRaceRest
    case easy
    case longRunMarathon
    case longRunOther(pace: String)
    case tempo
    case interval
    case repetition
    case easyRecovery
    case progression
    case hillRepeat
    case marPace
    case race(GoalFeasibility)

    func localizedText(locale: Locale) -> String {
        switch self {
        case .rest:
            return Self.text(
                LocalizedStringResource("workoutDescription.rest", defaultValue: "Riposo completo o camminata leggera. Parte integrante della supercompensazione."),
                locale: locale
            )
        case .postRaceRest:
            return Self.text(
                LocalizedStringResource("workoutDescription.postRaceRest", defaultValue: "Recupero dopo la gara. Riposo completo."),
                locale: locale
            )
        case .easy:
            return Self.text(
                LocalizedStringResource("workoutDescription.easy", defaultValue: "Ritmo confortevole, conversazione possibile. Obiettivo: aerobica di base e recupero attivo."),
                locale: locale
            )
        case .longRunMarathon:
            return Self.text(
                LocalizedStringResource("workoutDescription.longRunMarathon", defaultValue: "Corsa lunga a ritmo E. Ritmo uniforme, non accelerare negli ultimi km in allenamento."),
                locale: locale
            )
        case .longRunOther(let pace):
            return AppLocalizedString.formatted(
                LocalizedStringResource(
                    "workoutDescription.longRunOther",
                    defaultValue: "Corsa lunga a ritmo E. Non più veloce di %1$@. Priorità: completare la distanza."
                ),
                locale: locale,
                arguments: [pace]
            )
        case .tempo:
            return Self.text(
                LocalizedStringResource("workoutDescription.tempo", defaultValue: "Ritmo soglia: 'comfortably hard'. Sforzo sostenibile per ~20 min continuati."),
                locale: locale
            )
        case .interval:
            return Self.text(
                LocalizedStringResource("workoutDescription.interval", defaultValue: "Ripetute a VO2max (95-100%). Work bout 3-5 min, recupero attivo (jog) tra le ripetizioni."),
                locale: locale
            )
        case .repetition:
            return Self.text(
                LocalizedStringResource("workoutDescription.repetition", defaultValue: "Ripetute brevi a ritmo R (105-120% VDOT). Recupero completo tra le ripetizioni: non iniziare la prossima finché non sei pronto a correre con buona meccanica."),
                locale: locale
            )
        case .easyRecovery:
            return Self.text(
                LocalizedStringResource("workoutDescription.easyRecovery", defaultValue: "Corsa molto leggera nell'intervallo basso dell'E-pace. Obiettivo: promuovere il recupero, non costruire fitness."),
                locale: locale
            )
        case .progression:
            return Self.text(
                LocalizedStringResource("workoutDescription.progression", defaultValue: "Inizia a E-pace, aumenta gradualmente fino a T-pace."),
                locale: locale
            )
        case .hillRepeat:
            return Self.text(
                LocalizedStringResource("workoutDescription.hillRepeat", defaultValue: "Collinare ad alta intensità. Recupero in discesa lenta. Usate nella fase Base come stimolo di forza-velocità a basso impatto articolare."),
                locale: locale
            )
        case .marPace:
            return Self.text(
                LocalizedStringResource("workoutDescription.marPace", defaultValue: "Sezione centrale al ritmo gara target. Adattamento fisico e mentale al passo specifico."),
                locale: locale
            )
        case .race(let feasibility):
            return AppLocalizedString.resolve(feasibility.localizedRaceDescription, locale: locale)
        }
    }

    private static func text(_ resource: LocalizedStringResource, locale: Locale) -> String {
        AppLocalizedString.resolve(resource, locale: locale)
    }
}

// MARK: - Structured sets (workout detail con ritmi dinamici)

enum StructuredSetsKind {
    case tempo(mainKm: Int, pace: String)
    case interval(raceDistance: RaceDistance, pace: String)
    case repetition(raceDistance: RaceDistance, pace: String)
    case progression(easyEndKm: Int, marathonEndKm: Int, easyPace: String, mpPace: String, thresholdPace: String)
    case hillRepeat(reps: String, hillLength: String)
    case marPace(mainKm: Int)

    func localizedText(locale: Locale) -> String {
        switch self {
        case .tempo(let mainKm, let pace):
            return AppLocalizedString.formatted(
                LocalizedStringResource(
                    "structuredSets.tempo",
                    defaultValue: "2 km risc. E + %1$lld km a %2$@ + 2 km def. E"
                ),
                locale: locale,
                arguments: [mainKm, pace]
            )
        case .interval(let raceDistance, let pace):
            return Self.intervalText(for: raceDistance, pace: pace, locale: locale)
        case .repetition(let raceDistance, let pace):
            return Self.repetitionText(for: raceDistance, pace: pace, locale: locale)
        case .progression(let easyEnd, let marathonEnd, let easyPace, let mpPace, let thresholdPace):
            let thresholdStart = marathonEnd + 1
            return AppLocalizedString.formatted(
                LocalizedStringResource(
                    "structuredSets.progression",
                    defaultValue: "Km 1-%1$lld: %2$@ | Km %3$lld-%4$lld: %5$@ | Km %6$lld+: %7$@"
                ),
                locale: locale,
                arguments: [easyEnd, easyPace, easyEnd + 1, marathonEnd, mpPace, thresholdStart, thresholdPace]
            )
        case .hillRepeat(let reps, let hillLength):
            return AppLocalizedString.formatted(
                LocalizedStringResource(
                    "structuredSets.hillRepeat",
                    defaultValue: "2 km risc. E + %1$@×%2$@ salita (5-8%) + recupero discesa + 2 km def. E"
                ),
                locale: locale,
                arguments: [reps, hillLength]
            )
        case .marPace(let mainKm):
            return AppLocalizedString.formatted(
                LocalizedStringResource(
                    "structuredSets.marPace",
                    defaultValue: "2 km risc. E + %1$lld km a ritmo gara + 2 km def. E"
                ),
                locale: locale,
                arguments: [mainKm]
            )
        }
    }

    private static func intervalText(for distance: RaceDistance, pace: String, locale: Locale) -> String {
        let resource: LocalizedStringResource
        switch distance {
        case .tenK:
            resource = LocalizedStringResource(
                "structuredSets.interval.tenK",
                defaultValue: "2 km risc. + 5×1000m a %1$@ (rec. 2'30\" jog) + 1 km def."
            )
        case .halfMarathon:
            resource = LocalizedStringResource(
                "structuredSets.interval.halfMarathon",
                defaultValue: "2 km risc. + 4×1200m a %1$@ (rec. 3' jog) + 1 km def."
            )
        case .marathon:
            resource = LocalizedStringResource(
                "structuredSets.interval.marathon",
                defaultValue: "2 km risc. + 4×1600m a %1$@ (rec. 3' jog) + 2 km def."
            )
        case .fiveK:
            resource = LocalizedStringResource(
                "structuredSets.interval.fiveK",
                defaultValue: "2 km risc. + 6×600m a %1$@ (rec. 2' jog) + 1 km def."
            )
        }
        return AppLocalizedString.formatted(resource, locale: locale, arguments: [pace])
    }

    private static func repetitionText(for distance: RaceDistance, pace: String, locale: Locale) -> String {
        let resource: LocalizedStringResource
        switch distance {
        case .tenK:
            resource = LocalizedStringResource(
                "structuredSets.repetition.tenK",
                defaultValue: "2 km risc. E + 3×200m R a %1$@ (rec. 200m jog) + 5×400m R (rec. 400m jog) + 1 km def. E"
            )
        case .halfMarathon:
            resource = LocalizedStringResource(
                "structuredSets.repetition.halfMarathon",
                defaultValue: "2 km risc. E + 6×300m R a %1$@ (rec. 300m jog) + 2×200m R (rec. 200m jog) + 1 km def. E"
            )
        case .marathon:
            resource = LocalizedStringResource(
                "structuredSets.repetition.marathon",
                defaultValue: "2 km risc. E + 8×200m R a %1$@ (rec. 200m jog) + 2 km def. E"
            )
        case .fiveK:
            resource = LocalizedStringResource(
                "structuredSets.repetition.fiveK",
                defaultValue: "2 km risc. E + 4×200m R a %1$@ (rec. 200m jog) + 4×400m R (rec. 400m jog) + 1 km def. E"
            )
        }
        return AppLocalizedString.formatted(resource, locale: locale, arguments: [pace])
    }
}
