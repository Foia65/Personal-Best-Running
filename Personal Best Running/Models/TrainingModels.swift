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

enum WorkoutType: String, CaseIterable {
    case easy = "Corsa Facile"
    case longRun = "Lungo"
    case tempo = "Tempo Run"
    case interval = "Interval Training"
    case recovery = "Recupero Attivo"
    case race = "GARA"
    case rest = "Riposo"
    case progression = "Corsa Progressiva"
    case hillRepeat = "Ripetute in Salita"
    case marPace = "Ritmo Maratona"

    var emoji: String {
        switch self {
        case .easy: return "🟢"
        case .longRun: return "🔵"
        case .tempo: return "🟠"
        case .interval: return "🔴"
        case .recovery: return "🟡"
        case .race: return "🏆"
        case .rest: return "⚪️"
        case .progression: return "🟣"
        case .hillRepeat: return "⛰️"
        case .marPace: return "🎯"
        }
    }

    var intensityDescription: String {
        switch self {
        case .easy: return "60-70% FCmax / Easy pace (Zona 1-2)"
        case .longRun: return "65-75% FCmax / Easy-Moderate (Zona 2)"
        case .tempo: return "80-90% FCmax / Soglia Latt. (Zona 4)"
        case .interval: return "95-100% VO2max pace (Zona 5)"
        case .recovery: return "55-60% FCmax / Very Easy (Zona 1)"
        case .race: return "Gara – sforzo massimo pianificato"
        case .rest: return "Riposo completo o attività leggera"
        case .progression: return "Da Zona 2 a Zona 3-4 progressivamente"
        case .hillRepeat: return "95-100% sforzo / forza-velocità (Zona 4-5)"
        case .marPace: return "Ritmo gara maratona (Zona 3-4)"
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
    let totalKm: Double
    let weeklyNote: String
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
