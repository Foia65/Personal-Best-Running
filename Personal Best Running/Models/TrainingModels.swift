import Foundation

// MARK: - Runner Sex

enum RunnerSex: String, CaseIterable, Identifiable, Codable {
    case male
    case female

    var id: String { rawValue }

    var label: String {
        switch self {
        case .male:   return "Uomo"
        case .female: return "Donna"
        }
    }

    var icon: String {
        switch self {
        case .male:   return "person"
        case .female: return "person.fill"
        }
    }

    /// Fattore correttivo VDOT per sesso biologico.
    /// Le donne mostrano una VO2max assoluta mediamente inferiore del ~10-12%,
    /// ma il VDOT di Daniels è già normalizzato per la performance (non per la
    /// fisiologia assoluta). Applichiamo un fattore conservativo di 0.96 per
    /// produrre ritmi di allenamento leggermente più accessibili per le donne,
    /// coerente con le tabelle sesso-specifiche di McMillan / Daniels.
    /// Fonte: Daniels J. (2014), McMillan G. (2021).
    var vdotCorrectionFactor: Double {
        switch self {
        case .male:   return 1.00
        case .female: return 0.96
        }
    }
}

// MARK: - Unit System

enum UnitSystem: String, CaseIterable, Identifiable, Codable {
    case metric
    case imperial

    var id: String { rawValue }

    var label: String {
        switch self {
        case .metric:   return "Metrico (km)"
        case .imperial: return "Imperiale (mi)"
        }
    }

    // MARK: Conversions

    /// Converte km → unità visualizzata
    func displayDistance(_ kms: Double) -> Double {
        switch self {
        case .metric:   return kms
        case .imperial: return kms * 0.621371
        }
    }

    /// Suffisso distanza
    var distanceUnit: String {
        switch self {
        case .metric:   return "km"
        case .imperial: return "mi"
        }
    }

    /// Converte secondi/km → secondi/unità visualizzata
    func displayPace(_ secsPerKm: Double) -> Double {
        switch self {
        case .metric:   return secsPerKm
        case .imperial: return secsPerKm / 0.621371   // sec/mi
        }
    }

    /// Suffisso passo
    var paceUnit: String {
        switch self {
        case .metric:   return "/km"
        case .imperial: return "/mi"
        }
    }

    /// Formatta secondi/km → stringa passo localizzata
    func formatPace(_ secsPerKm: Double) -> String {
        let converted = displayPace(secsPerKm)
        let mins = Int(converted) / 60
        let secs = Int(converted) % 60
        return String(format: "%d:%02d %@", mins, secs, paceUnit)
    }

    /// Formatta km → stringa distanza localizzata
    func formatDistance(_ kms: Double) -> String {
        let value = displayDistance(kms)
        return String(format: "%.1f %@", value, distanceUnit)
    }
}

enum RaceDistance: String, CaseIterable, Identifiable {
    case fiveK = "5 km"
    case tenK = "10 km"
    case halfMarathon = "Mezza Maratona"
    case marathon = "Maratona"

    var id: String { rawValue }

    var meters: Double {
        switch self {
        case .fiveK: return 5000
        case .tenK: return 10000
        case .halfMarathon: return 21097.5
        case .marathon: return 42195
        }
    }

    // lunghezza max in settimane per i piani di allenamento
    var maxPlanWeeks: Int {
        switch self {
        case .fiveK:        return 16
        case .tenK:         return 20
        case .halfMarathon: return 20
        case .marathon:     return 24
        }
    }
    /// Fattore di conversione VDOT per stimare performance su distanze diverse
    /// Fonte: Daniels' Running Formula (Jack Daniels, 3rd Ed.)
    var vdotConversionFactor: Double {
        switch self {
        case .fiveK: return 1.0
        case .tenK: return 0.9832
        case .halfMarathon: return 0.9512
        case .marathon: return 0.9090
        }
    }
}

// MARK: - WorkoutType
//
// Enum dei tipi di allenamento basato sulle categorie ufficiali di Daniels [1].
//
// FONTI
// [1] Daniels J. (2022). Daniels' Running Formula (4th ed.). Human Kinetics.
//     Cap. 4: E, M, T, I, R — le cinque intensità core del sistema Daniels.
// [2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.
// [6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering strategies.
//     Medicine & Science in Sports & Exercise, 35(7), 1182-1187.
//
// MODIFICHE RISPETTO ALLA VERSIONE PRECEDENTE
//
// [FIX-2] Aggiunto caso .repetition (R-pace di Daniels).
//   Era completamente assente. Daniels [1] cap. 4 dedica una sezione autonoma
//   alle Repetition: scopo primario è velocità ed economia di corsa.
//   Work bout MAX 2 min, recupero COMPLETO (jog = distanza del lavoro).
//   Introdotte in Phase II (Build), prima delle Interval.
//
// [FIX-5] Intensità FCmax di .tempo corretta: da "80-90%" a "88-92%".
//   Daniels [1] cap. 4: T-pace = 85-88% VO2max / 88-92% FCmax (atleti allenati).
//   Il precedente 80% coincideva con M-pace, non con la soglia anaerobica.
//
// [FIX-6] Intensità di .recovery allineata all'E-pace di Daniels.
//   Daniels non definisce una zona "recovery" separata: usa E-pace (59-74% VO2max)
//   per tutto il continuum di bassa intensità. L'intensityDescription ora
//   rispecchia questo, usando il limite inferiore dell'E-pace.

enum WorkoutType: String, CaseIterable {

    // ── Daniels core training types ─────────────────────────────────────────
    case easy        = "Corsa Facile"
    case longRun     = "Lungo"
    case marPace     = "Ritmo Maratona"
    case tempo       = "Tempo Run"
    case interval    = "Interval Training"

    // [FIX-2] Nuovo caso: R (Repetition) pace di Daniels [1] cap. 4.
    // Scopo: velocità, economia di corsa, potenza anaerobica.
    // Distinto dall'Interval per: work bout più breve (max 2 min),
    // recupero completo (non attivo), intensità più alta (~105-120% VDOT).
    case repetition  = "Ripetute"

    // ── Tipi supplementari ───────────────────────────────────────────────────
    case progression = "Corsa Progressiva"
    case hillRepeat  = "Ripetute in Salita"

    // ── Speciali ─────────────────────────────────────────────────────────────
    case recovery    = "Recupero Attivo"
    case race        = "GARA"
    case rest        = "Riposo"

    // MARK: - Emoji / colore zona

    // Le zone di colore seguono approssimativamente le zone cardiache
    // come descritte da Daniels [1] e dalla letteratura sull'endurance.
    var emoji: String {
        switch self {
        case .rest:                    return "⚪️"  // nessuno sforzo
        case .recovery:                return "🔵"  // Z1 – molto leggero
        case .easy, .longRun:          return "🟢"  // Z2 – aerobico base
        case .marPace:                 return "🟡"  // Z3 – aerobico moderato
        case .tempo:                   return "🔴"  // Z4 – soglia anaerobica
        case .interval, .repetition:   return "🟣"  // Z5 – VO2max / velocità
        case .progression:             return "📈"  // Z2→Z4 progressivo
        case .hillRepeat:              return "⛰️"  // Z4-5 forza-velocità
        case .race:                    return "🏆"  // sforzo massimo pianificato
        }
    }

    // MARK: - Descrizione intensità fisiologica

    // Le percentuali di FCmax e VO2max seguono Daniels [1] cap. 4 (figura 4.1).
    // [FIX-5] .tempo: corretto da "80-90% FCmax" a "88-92% FCmax".
    // [FIX-6] .recovery: rimosso il riferimento a una zona separata inesistente;
    //         ora indica il limite inferiore dell'E-pace di Daniels.
    // [FIX-2] .repetition: descrizione basata su Daniels [1] cap. 4 R-pace section.
    var intensityDescription: String {
        switch self {
        case .rest:
            return "Riposo completo o attività leggera"

        case .recovery:
            // [FIX-6] Daniels non definisce una zona recovery distinta dall'Easy.
            // Usa il limite inferiore del range E-pace (59% VO2max / 65% FCmax).
            // Fonte: [1] cap. 4 – E pace range 59-74% VO2max.
            return "59-65% VO2max / 65-70% FCmax – limite inferiore E-pace (Daniels)"

        case .easy:
            // Fonte: [1] cap. 4: "E is typically about 59 to 74 percent of O2max
            // or about 65 to 79 percent of maximum heart rate."
            return "59-74% VO2max / 65-79% FCmax – Easy pace (Daniels E)"

        case .longRun:
            // Il lungo è sempre a E-pace. Fonte: [1] cap. 4.
            return "59-74% VO2max / 65-79% FCmax – E-pace (L run = E run prolungato)"

        case .marPace:
            // Fonte: [1] cap. 4 figura 4.1: M = 75-84% VO2max / 80-89% FCmax.
            return "75-84% VO2max / 80-89% FCmax – Marathon pace (Daniels M)"

        case .tempo:
            // [FIX-5] Corretto: Daniels [1] cap. 4: "T-pace at about 85 to 88 percent
            // of O2max (88 to 92 percent of maximum heart rate) for well-trained athletes."
            // La versione precedente indicava 80-90% FCmax — il limite inferiore era
            // troppo basso, coincideva con M-pace anziché con la soglia lattato.
            return "85-88% VO2max / 88-92% FCmax – Threshold/Tempo pace (Daniels T)"

        case .interval:
            // Fonte: [1] cap. 4: I-pace = ~95-100% VO2max (vVO2max).
            // Work bout 3-5 min. Recupero attivo (jog) uguale o leggermente inferiore
            // al tempo di lavoro.
            return "95-100% VO2max / ~98% FCmax – Interval pace (Daniels I)"

        case .repetition:
            // [FIX-2] Nuovo. Fonte: [1] cap. 4 – Repetition training section.
            // "The primary purpose of R training is to improve anaerobic power,
            //  speed, and economy of running."
            // R-pace ≈ 105-120% intensità VDOT (più veloce di I-pace).
            // "Daniels' 6-second rule": R pace è ~6 sec/400m più veloce di I pace.
            // Work bout MAX 2 minuti. Recupero COMPLETO (jog = distanza corsa).
            return "105-120% VDOT (>100% VO2max) – Repetition pace (Daniels R) – max 2 min/rep"

        case .progression:
            // Da E-pace a T-pace progressivamente. Fonte: [2] Pfitzinger.
            return "Da 59% a 88% VO2max – E→M→T progressivo (Z2→Z4)"

        case .hillRepeat:
            // Colline: stimolo forza-velocità a impatto articolare ridotto.
            // Compatibile con Phase I/II di Daniels. Fonte: [2] Pfitzinger.
            return "~90-95% sforzo in salita – forza specifica (Z4-5, impatto ridotto)"

        case .race:
            return "Sforzo massimo pianificato – ritmo gara specifico"
        }
    }

    // MARK: - Fase consigliata (Daniels [1] cap. 10)

    // Indica in quale fase del piano Daniels introduce preferibilmente questo tipo.
    // Utile per validazione e UI.
    // [FIX-3] La sequenza corretta è: E (Base) → R (Build) → T+I (Peak).
    //         Non: E (Base) → T+I (Build). L'I non va introdotto prima di R.
    var recommendedPhases: [TrainingPhase] {
        switch self {
        case .rest:
            return [.base, .build, .peak, .taper, .race]
        case .recovery:
            return [.base, .build, .peak, .taper, .race]
        case .easy, .longRun:
            // E-pace è presente in tutte le fasi come volume di base.
            return [.base, .build, .peak, .taper, .race]
        case .progression, .hillRepeat:
            // Stimoli leggeri compatibili con Phase I (Base) di Daniels.
            return [.base, .build]
        case .repetition:
            // [FIX-2][FIX-3] R introdotto in Phase II (Build), prima di I.
            // Fonte: [1] cap. 10 – Phase II: "going from E running to R workouts
            // is adding only a speed stress."
            return [.build, .peak]
        case .tempo:
            // T introdotto da Phase II (Build) in poi.
            return [.build, .peak, .taper]
        case .marPace:
            // M-pace rilevante in Peak, soprattutto per maratona/HM. Fonte: [2].
            return [.peak, .taper]
        case .interval:
            // [FIX-3] I introdotto solo in Peak (Phase III/IV di Daniels), mai in Base.
            // Nella versione precedente era inserito già nella fase Build.
            return [.peak]
        case .race:
            return [.race]
        }
    }

    // MARK: - Massimo volume per sessione (% del volume settimanale)

    // Limiti definiti da Daniels [1] cap. 4.
    // Utile per validazione dei workout generati.
    var maxSessionFractionOfWeeklyVolume: Double? {
        switch self {
        case .longRun:
            // [FIX-1] 25% — Daniels [1] cap. 4: "no more than 25 percent
            // of weekly mileage." Precedentemente era 33%, non supportato.
            return 0.25
        case .tempo:
            // Daniels [1] cap. 4: "not totaling more than 10 percent of
            // your weekly mileage in a single workout."
            return 0.10
        case .marPace:
            // Daniels [1] cap. 4: "not add up to more than the lesser of
            // 20 percent of your weekly mileage or 18 miles."
            return 0.20
        case .interval:
            // Daniels [1] cap. 4: "maximum the lesser of 10K or 8 percent
            // of your weekly mileage."
            return 0.08
        case .repetition:
            // [FIX-2] Daniels [1] cap. 4: R sessioni più brevi e intense.
            // Limite conservativo: 5% del volume settimanale.
            return 0.05
        case .easy, .recovery, .progression,
             .hillRepeat, .rest, .race:
            return nil  // nessun limite percentuale rigido per questi tipi
        }
    }
}

// MARK: - VDOT / Paces

/// Calcolo VDOT e ritmi di allenamento
/// Fonti principali:
/// - Daniels J. (2014). Daniels' Running Formula, 3rd Ed. Human Kinetics.
/// - Pfitzinger P., Douglas S. (2009). Advanced Marathoning. Human Kinetics.
/// - Billat V. (2001). Interval Training for Performance. Sports Medicine.
struct VDOTCalculator {

    /// Calcola il VDOT da tempo e distanza
    /// Formula di Daniels (approssimazione polinomiale)
    static func calculate(timeInSeconds: Double, distanceMeters: Double) -> Double {
        let time = timeInSeconds / 60.0  // minuti
        let dist = distanceMeters / 1000.0 // km

        // Velocità in m/min
        let velocity = (distanceMeters / timeInSeconds) * 60.0

        // VO2 richiesto a quella velocità
        let vo2 = -4.60 + 0.182258 * velocity + 0.000104 * velocity * velocity

        // Frazione VO2max utilizzata a quella durata (Daniels)
        let pctVO2max = 0.8 + 0.1894393 * exp(-0.012778 * time) + 0.2989558 * exp(-0.1932605 * time)

        let vdot = vo2 / pctVO2max
        return max(20, min(85, vdot))
    }

    /// Ritmi di allenamento in sec/km basati su VDOT
    /// Fonte: Daniels' Running Formula, Tables (adattate)
    static func trainingPaces(vdot: Double) -> TrainingPaces {

        // Easy pace: ~70% VDOT velocity
        let easyVelocity = velocityFromVDOT(vdot * 0.70)
        let easyPace = 1000.0 / easyVelocity * 60.0

        // Marathon pace: ~80% VDOT velocity
        let mpVelocity = velocityFromVDOT(vdot * 0.80)
        let mpPace = 1000.0 / mpVelocity * 60.0

        // Threshold (Tempo) pace: ~83-88% VDOT
        let thresholdVelocity = velocityFromVDOT(vdot * 0.86)
        let thresholdPace = 1000.0 / thresholdVelocity * 60.0

        // Interval pace: ~95-100% VDOT (VO2max pace)
        let intervalVelocity = velocityFromVDOT(vdot * 0.98)
        let intervalPace = 1000.0 / intervalVelocity * 60.0

        // Recovery pace: ~60% VDOT
        let recoveryVelocity = velocityFromVDOT(vdot * 0.60)
        let recoveryPace = 1000.0 / recoveryVelocity * 60.0

        return TrainingPaces(
            vdot: vdot,
            easyPaceSecsPerKm: easyPace,
            marathonPaceSecsPerKm: mpPace,
            thresholdPaceSecsPerKm: thresholdPace,
            intervalPaceSecsPerKm: intervalPace,
            recoveryPaceSecsPerKm: recoveryPace
        )
    }

    static func trainingPaces(vdot: Double, sex: RunnerSex) -> TrainingPaces {
        let correctedVDOT = vdot * sex.vdotCorrectionFactor
        return trainingPaces(vdot: correctedVDOT)
    }
    
    /// Velocità (m/min) da VDOT (inversione approssimativa)
    private static func velocityFromVDOT(_ vdot: Double) -> Double {
        // Inversione numerica semplificata della formula Daniels
        // a 100% VO2max (pctVO2max ≈ 1.0 per durate ~10-15 min)
        // v ≈ soluzione di: -4.60 + 0.182258*v + 0.000104*v^2 = vdot
        let a = 0.000104
        let b = 0.182258
        let c = -4.60 - vdot
        let discriminant = b * b - 4 * a * c
        return (-b + sqrt(discriminant)) / (2 * a)
    }

    /// Stima il tempo target su distanza gara dal VDOT
    static func predictRaceTime(vdot: Double, distance: RaceDistance) -> Double {
        // Trova il tempo (in sec) tale che VDOT calcolato ≈ vdot dato
        // Metodo bisezione
        var low: Double = 60
        var hig: Double = 36000
        for _ in 0..<50 {
            let mid = (low + hig) / 2
            let computed = calculate(timeInSeconds: mid, distanceMeters: distance.meters)
            if computed > vdot { low = mid } else { hig = mid }
        }
        return (low + hig) / 2
    }
}

struct TrainingPaces {
    let vdot: Double
    let easyPaceSecsPerKm: Double
    let marathonPaceSecsPerKm: Double
    let thresholdPaceSecsPerKm: Double
    let intervalPaceSecsPerKm: Double
    let recoveryPaceSecsPerKm: Double

    func formatted(_ secsPerKm: Double) -> String {
        let mins = Int(secsPerKm) / 60
        let secs = Int(secsPerKm) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }

    var easyFormatted: String { formatted(easyPaceSecsPerKm) }
    var mpFormatted: String { formatted(marathonPaceSecsPerKm) }
    var thresholdFormatted: String { formatted(thresholdPaceSecsPerKm) }
    var intervalFormatted: String { formatted(intervalPaceSecsPerKm) }
    var recoveryFormatted: String { formatted(recoveryPaceSecsPerKm) }
    
    func formattedPace(_ secsPerKm: Double, unitSystem: UnitSystem) -> String {
        unitSystem.formatPace(secsPerKm)
    }

    func easyFormatted(unitSystem: UnitSystem) -> String { formattedPace(easyPaceSecsPerKm, unitSystem: unitSystem) }
    func mpFormatted(unitSystem: UnitSystem) -> String { formattedPace(marathonPaceSecsPerKm, unitSystem: unitSystem) }
    func thresholdFormatted(unitSystem: UnitSystem) -> String { formattedPace(thresholdPaceSecsPerKm, unitSystem: unitSystem) }
    func intervalFormatted(unitSystem: UnitSystem) -> String { formattedPace(intervalPaceSecsPerKm, unitSystem: unitSystem) }
    func recoveryFormatted(unitSystem: UnitSystem) -> String { formattedPace(recoveryPaceSecsPerKm, unitSystem: unitSystem) }
}

// MARK: - Workout

struct Workout: Identifiable {
    let id = UUID()
    let date: Date
    let type: WorkoutType
    let week: Int
    let dayOfWeek: Int
    let title: String
    let description: String
    let distanceKm: Double?
    let durationMinutes: Int?
    let paceTarget: String?
    let paceTargetSecsPerKm: Double?   // raw value, formatted at display time
    let structuredSets: String?
    let scientificRationale: String
    let rpe: String  // Rate of Perceived Exertion 1-10
    let tss: Double  // Training Stress Score (approssimativo)
}

// MARK: - Training Plan Input

struct TrainingPlanInput {
    let raceDistance: RaceDistance
    let raceDate: Date
    let raceName: String
    let trainingDaysPerWeek: Int
    let targetTime: TimeInterval        // secondi
    let currentPerformance: CurrentPerformance
    let sex: RunnerSex
}

struct CurrentPerformance {
    let distance: RaceDistance
    let time: TimeInterval  // secondi
}

// MARK: - Training Plan Output

struct TrainingPlan: Identifiable {
    let id = UUID()
    let input: TrainingPlanInput
    let paces: TrainingPaces
    let weeks: [TrainingWeek]
    let scientificSources: [String]
    let estimatedRaceTime: Double
    let fitnessGap: String  // differenza tra performance attuale e target
}

struct TrainingWeek: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let phase: TrainingPhase
    let workouts: [Workout]
    let weeklyNote: String
    
    // Somma le distanze reali dei workout
    var totalKm: Double {
            workouts.compactMap(\.distanceKm).reduce(0, +)
        }
}

// serve per scrivere sul calendario
struct EventData: Identifiable {
    let id = UUID()
    var date: Date
    var title: String
    var notes: String
}


enum TrainingPhase: String {
    case base = "Fase Base"
    case build = "Fase Sviluppo"
    case peak = "Fase Picco"
    case taper = "Taper"
    case race = "Gara"

    var description: String {
        switch self {
        case .base: return "Costruzione aerobica, adattamento muscolo-scheletrico, volume progressivo"
        case .build: return "Introduzione lavori di qualità, aumento intensità, sviluppo soglia"
        case .peak: return "Massimo volume/qualità, simulazioni gara, affinamento della forma"
        case .taper: return "Riduzione volume (40-60%), mantenimento intensità, recupero e supercompensazione"
        case .race: return "Settimana di gara"
        }
    }
}

extension TrainingPaces {
    // [FIX-2] R-pace: circa 105-120% dell'intensità VDOT (velocità > I-pace).
    // Daniels [1]: R pace ≈ ritmo gara sul miglio / 1500m.
    // "Regola dei 6 secondi": R pace è ~6 sec/400m più veloce di I pace.
    // Implementazione: invertiamo la formula con VDOT * 1.05 (approssimazione
    // conservativa, equivale a circa 5% più veloce del ritmo di gara a VO2max).
    var repetitionPaceSecsPerKm: Double {
        // Approssimazione: R pace ≈ I pace - 6 sec/400m ≈ I pace * 0.965
        // (6 sec su 400m = 15 sec/km, e a I-pace ~3:30-4:00/km, -15 sec ≈ 4%)
        return intervalPaceSecsPerKm * 0.965
    }

    var repetitionFormatted: String {
        formatted(repetitionPaceSecsPerKm)
    }

    func repetitionFormatted(unitSystem: UnitSystem) -> String {
        formattedPace(repetitionPaceSecsPerKm, unitSystem: unitSystem)
    }
}
