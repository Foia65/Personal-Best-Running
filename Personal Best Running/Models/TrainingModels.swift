import SwiftUI

// MARK: - GoalFeasibility
//
// Single source of truth for race goal assessment.
// Based on vdotGap because:
//   - It is independent of race distance
//   - It directly measures how much fitness must improve
//   - It is the same unit used throughout the Daniels system [1]
//   - diffSecs depends by distance (22' on marathon ≠ 22' on 5K)
// Source: Daniels [1] ch. 5 — VDOT as a universal measure of fitness.

enum GoalFeasibility {
    case conservative    // vdotGap < -5  (target slower than current fitness)
    case prudent         // vdotGap -5..<-2
    case realistic       // vdotGap -2..<2  (aligned with current fitness)
    case ambitious       // vdotGap  2..<5
    case challenging     // vdotGap  5..<10
    case extreme         // vdotGap >= 10

    // Calculation from VDOT difference. Single entry point used by the generator.
    static func from(vdotGap: Double) -> GoalFeasibility {
        switch vdotGap {
        case ..<(-5):   return .conservative
        case -5..<(-2): return .prudent
        case -2..<2:    return .realistic
        case  2..<5:    return .ambitious
        case  5..<10:   return .challenging
        default:        return .extreme
        }
    }

    // MARK: Short label (used in PlanHeaderView / fitnessGap)

    // Short text without emoji — visual indication is handled by
    // sfSymbol and color, more consistent with iOS SF Symbols aesthetics.
    var localizedLabel: LocalizedStringResource {
        switch self {
        case .conservative:
            return LocalizedStringResource("goalFeasibility.label.conservative", defaultValue: "Obiettivo conservativo")
        case .prudent:
            return LocalizedStringResource("goalFeasibility.label.prudent", defaultValue: "Obiettivo prudente")
        case .realistic:
            return LocalizedStringResource("goalFeasibility.label.realistic", defaultValue: "Obiettivo realistico")
        case .ambitious:
            return LocalizedStringResource("goalFeasibility.label.ambitious", defaultValue: "Obiettivo ambizioso")
        case .challenging:
            return LocalizedStringResource("goalFeasibility.label.challenging", defaultValue: "Obiettivo sfidante")
        case .extreme:
            return LocalizedStringResource("goalFeasibility.label.extreme", defaultValue: "Obiettivo estremo")
        }
    }

    var localizedRaceDescription: LocalizedStringResource {
        switch self {
        case .conservative:
            return LocalizedStringResource(
                "goalFeasibility.raceDescription.conservative",
                defaultValue: """
                Giorno di gara! Il tuo obiettivo è molto conservativo rispetto alla forma attuale: \
                potresti fare molto meglio. Parti controllato e valuta in corsa se aumentare il ritmo.
                """
            )
        case .prudent:
            return LocalizedStringResource(
                "goalFeasibility.raceDescription.prudent",
                defaultValue: """
                Giorno di gara! Obiettivo prudente rispetto alla forma attuale. \
                Ottima base per un risultato solido senza rischi. Corri con fiducia.
                """
            )
        case .realistic:
            return LocalizedStringResource(
                "goalFeasibility.raceDescription.realistic",
                defaultValue: """
                Giorno di gara! Obiettivo allineato alla tua forma attuale. \
                Esegui il piano di gara: il lavoro fatto lo supporta. Parti cauto nei primi km.
                """
            )
        case .ambitious:
            return LocalizedStringResource(
                "goalFeasibility.raceDescription.ambitious",
                defaultValue: """
                Giorno di gara! Obiettivo ambizioso rispetto alla forma di partenza. \
                Se il piano è andato bene, puoi farcela. Fondamentale partire cauto nei primi km.
                """
            )
        case .challenging:
            return LocalizedStringResource(
                "goalFeasibility.raceDescription.challenging",
                defaultValue: """
                Giorno di gara! Obiettivo molto sfidante rispetto alla forma di partenza. \
                Corri al meglio della tua condizione attuale e usa questa gara come tappa di avvicinamento.
                """
            )
        case .extreme:
            return LocalizedStringResource(
                "goalFeasibility.raceDescription.extreme",
                defaultValue: """
                Giorno di gara! L'obiettivo dichiarato era molto oltre la forma di partenza. \
                Corri al tuo ritmo stimato: usa questa gara come esperienza e rivaluta l'obiettivo \
                per il prossimo ciclo.
                """
            )
        }
    }

    // SF Symbols paired with feasibility level.
    var sfSymbol: String {
        switch self {
        case .conservative: return "checkmark.seal.fill"
        case .prudent:      return "checkmark.circle.fill"
        case .realistic:    return "checkmark.circle"
        case .ambitious:    return "arrow.up.circle"
        case .challenging:  return "exclamationmark.triangle"
        case .extreme:      return "exclamationmark.triangle.fill"
        }
    }

    // MARK: Extended description (used in WorkoutRowView / RACE card)
    // Contextualized for race day: motivational tone and practical advice.

    var raceDescription: String {
        switch self {
        case .conservative:
            return "Giorno di gara! Il tuo obiettivo è molto conservativo rispetto alla forma attuale: potresti fare molto meglio. Parti controllato e valuta in corsa se aumentare il ritmo."
        case .prudent:
            return "Giorno di gara! Obiettivo prudente rispetto alla forma attuale. Ottima base per un risultato solido senza rischi. Corri con fiducia."
        case .realistic:
            return "Giorno di gara! Obiettivo allineato alla tua forma attuale. Esegui il piano di gara: il lavoro fatto lo supporta. Parti cauto nei primi km."
        case .ambitious:
            return "Giorno di gara! Obiettivo ambizioso rispetto alla forma di partenza. Se il piano è andato bene, puoi farcela. Fondamentale partire cauto nei primi km."
        case .challenging:
            return "Giorno di gara! Obiettivo molto sfidante rispetto alla forma di partenza. Corri al meglio della tua condizione attuale e usa questa gara come tappa di avvicinamento."
        case .extreme:
            return "Giorno di gara! L'obiettivo dichiarato era molto oltre la forma di partenza. Corri al tuo ritmo stimato: usa questa gara come esperienza e rivaluta l'obiettivo per il prossimo ciclo."
        }
    }

    // MARK: SwiftUI Color (consistent between PlanHeaderView and WorkoutRowView)
    var color: Color {
        switch self {
        case .conservative, .prudent, .realistic: return .green
        case .ambitious, .challenging:            return .orange
        case .extreme:                            return .red
        }
    }
}

// MARK: Runner Level
enum RunnerLevel: String, Equatable, CaseIterable {
    case beginner = "Principiante"
    case recreational = "Amatore"
    case intermediate = "Intermedio"
    case advanced = "Avanzato"
    case elite = "Elite"

    // This tells Xcode to put these strings in the .xcstrings file!
    var localizedRunnerLevel: LocalizedStringResource {
        switch self {
        case .beginner: return "Principiante"
        case .recreational: return "Amatore"
        case .intermediate: return "Intermedio"
        case .advanced: return "Avanzato"
        case .elite: return "Elite"
        }
    }
}

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

    var localizedGender: LocalizedStringResource {
        switch self {
        case .male:
            return LocalizedStringResource("gender.label.male", defaultValue: "Uomo")
        case .female:
            return LocalizedStringResource("gender.label.female", defaultValue: "Donna")
        }
    }

    var icon: String {
        switch self {
        case .male:   return "figure.stand"
        case .female: return "figure.stand.dress"
        }
    }

    // MARK: - Athlete level thresholds
    //
    // VDOT thresholds per level, differentiated by sex.
    // Based on percentile distribution of finishing times in mass marathons (RunRepeat Global Report 2023)
    // and on WMA (World Masters Athletics) age-grading tables.
    //
    // Male:   median marathon ~4:30 → VDOT ~37
    // Female: median marathon ~4:55 → VDOT ~33
    // The "average runner" has different VDOT by sex → thresholds shift.

    // swiftlint:disable:next large_tuple
    var levelThresholds: (recreational: Double, intermediate: Double, advanced: Double, elite: Double) {
        switch self {
        case .male:
            // Male distribution: median ~VDOT 37
            return (recreational: 32, intermediate: 42, advanced: 52, elite: 62)
        case .female:
            // Female distribution: median ~VDOT 33, shift ~8-10 points
            return (recreational: 28, intermediate: 37, advanced: 47, elite: 57)
        }
    }

    func runnerLevel(vdot: Double) -> RunnerLevel {
        let thresholds = levelThresholds
        switch vdot {
        case ..<thresholds.recreational:  return .beginner
        case thresholds.recreational..<thresholds.intermediate: return .recreational
        case thresholds.intermediate..<thresholds.advanced: return .intermediate
        case thresholds.advanced..<thresholds.elite: return .advanced
        default: return .elite
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
    var localizedUnitSystem: LocalizedStringResource {
        switch self {
        case .metric:
            return LocalizedStringResource("UnitSystem.label.metric", defaultValue: "Metrico")
        case .imperial:
            return LocalizedStringResource("UnitSystem.label.imperial", defaultValue: "Imperiale")
        }
    }

    // MARK: - Conversions

    // Converts km → display unit
    func displayDistance(_ kms: Double) -> Double {
        switch self {
        case .metric:   return kms
        case .imperial: return kms * 0.621371
        }
    }

    // Distance suffix
    var distanceUnit: String {
        switch self {
        case .metric:   return "km"
        case .imperial: return "mi"
        }
    }

    // Converts sec/km → sec/display unit
    func displayPace(_ secsPerKm: Double) -> Double {
        switch self {
        case .metric:   return secsPerKm
        case .imperial: return secsPerKm / 0.621371   // sec/mi
        }
    }

    // Pace suffix
    var paceUnit: String {
        switch self {
        case .metric:   return "/km"
        case .imperial: return "/mi"
        }
    }

    // Formats sec/km → localized pace string
    func formatPace(_ secsPerKm: Double) -> String {
        let converted = displayPace(secsPerKm)
        let mins = Int(converted) / 60
        let secs = Int(converted) % 60
        return String(format: "%d:%02d %@", mins, secs, paceUnit)
    }

    // Formats km → localized distance string
    func formatDistance(_ kms: Double) -> String {
        let value = displayDistance(kms)
        return String(format: "%.1f %@", value, distanceUnit)
    }
}

// MARK: - Race Distances
enum RaceDistance: String, CaseIterable, Identifiable {
    case fiveK = "5 km"
    case tenK = "10 km"
    case halfMarathon = "Mezza Maratona"
    case marathon = "Maratona"

    // This tells Xcode to put these strings in the .xcstrings file!
    var localizedName: LocalizedStringResource {
        switch self {
        case .fiveK: return "5 km"
        case .tenK: return "10 km"
        case .halfMarathon: return "Mezza Maratona"
        case .marathon: return "Maratona"
        }
    }

    // 5K is excluded from target distances because:
    // - It requires a different plan structure (more R and I, less volume)
    // - The generator is optimized for prolonged endurance distances
    // - It remains available as a reference distance for VDOT
    static var targetDistances: [RaceDistance] {
        [.tenK, .halfMarathon, .marathon]
    }

    var id: String { rawValue }

    var meters: Double {
        switch self {
        case .fiveK: return 5000
        case .tenK: return 10000
        case .halfMarathon: return 21097.5
        case .marathon: return 42195
        }
    }

    // Max plan length in weeks
    var maxPlanWeeks: Int {
        switch self {
        case .fiveK:        return 16
        case .tenK:         return 20
        case .halfMarathon: return 20
        case .marathon:     return 24
        }
    }
    // VDOT conversion factor for estimating performance on different distances
    // Source: Daniels' Running Formula (Jack Daniels, 3rd Ed.)
    var vdotConversionFactor: Double {
        switch self {
        case .fiveK: return 1.0
        case .tenK: return 0.9832
        case .halfMarathon: return 0.9512
        case .marathon: return 0.9090
        }
    }

    var performanceBounds: PerformanceBounds {
        switch self {
        case .fiveK:
            return PerformanceBounds(
                minSeconds: 13 * 60,          // 13:00 (world elite ~12:35)
                maxSeconds: 60 * 60           // 1:00:00 (12:00 /km)
            )
        case .tenK:
            return PerformanceBounds(
                minSeconds: 27 * 60,          // 27:00 (world elite ~26:17)
                maxSeconds: 2 * 3600          // 2:00:00 (12:00 /km)
            )
        case .halfMarathon:
            return PerformanceBounds(
                minSeconds: 58 * 60,          // 58:00 (world elite ~57:31)
                maxSeconds: 4 * 3600          // 4:00:00 (~11:22 /km)
            )
        case .marathon:
            return PerformanceBounds(
                minSeconds: 2 * 3600,         // 2:00:00 (world elite)
                maxSeconds: 8 * 3600          // 8:00:00 (~11:22 /km)
            )
        }
    }
}

// MARK: - WorkoutType
//
// Enum of workout types based on the official Daniels categories [1].
//
// Sources:
// [1] Daniels J. (2022). Daniels' Running Formula (4th ed.). Human Kinetics.
//     Ch. 4: E, M, T, I, R — the five core intensities of the Daniels system.
// [2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.
// [6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering strategies.
//     Medicine & Science in Sports & Exercise, 35(7), 1182-1187.

enum WorkoutType: String, CaseIterable {

    // ── Daniels core training types ─────────────────────────────────────────
    case easy        = "Corsa Facile"
    case longRun     = "Lungo"
    case marPace     = "Ritmo Maratona"
    case tempo       = "Tempo Run"
    case interval    = "Interval Training"

    // R (Repetition) pace from Daniels [1] ch. 4.
    // Purpose: speed, running economy, anaerobic power.
    // Distinct from Interval by: shorter work bout (max 2 min),
    // full recovery (not active), higher intensity (~105-120% VDOT).
    case repetition  = "Ripetute"

    // ── Supplemental types ───────────────────────────────────────────────────
    case progression = "Corsa Progressiva"
    case hillRepeat  = "Ripetute in Salita"

    // ── Special ─────────────────────────────────────────────────────────────
    case recovery    = "Recupero Attivo"
    case race        = "GARA"
    case rest        = "Riposo"

    // MARK: - Color palette / zone / emoji
    //
    // Single source of truth for color, zone label, Daniels code, and emoji.
    // Both calendarView and PacesView draw from these properties,
    // ensuring visual consistency without duplication.
    //
    // Palette based on increasing intensity per Daniels [1] ch. 4:
    //   gray   → no intensity (rest/recovery)
    //   green  → E  (Z2, aerobic base)
    //   teal   → progression/hills (Z2→Z4, supplemental)
    //   yellow → M  (Z3, marathon pace)
    //   orange → T  (Z4, threshold)
    //   red    → I  (Z5, VO2max)
    //   purple → R  (Z5+, pure speed)
    //   indigo → race
    //
    // Corrections from previous version:
    // - interval and repetition had the same purple color → now distinct (red/purple)
    // - recovery was blue suggesting a separate zone → now green (lower bound E-pace)
    // - tempo was red like interval → now orange (one step below in intensity)

    var color: Color {
        switch self {
        case .rest:
            // No effort — neutral.
            return .gray

        case .recovery:
            // Lower bound of E-pace (59% VO2max). Daniels does not define
            // a separate zone: it's simply very light E-pace.
            // Same color as .easy for conceptual consistency.
            return .green

        case .easy, .longRun:
            // E-pace / L run: Z2, aerobic base. Source: Daniels [1] ch. 4.
            return .green

        case .progression:
            // Progression starts at E-pace (Z2) and rises toward T-pace (Z4),
            // but most of the volume is in the lower half of the range.
            // .yellow (Z3/M-pace) reflects the honest average intensity of the session.
            // Previously .teal: didn't communicate intensity, just "different type".
            return .yellow

        case .marPace:
            // M-pace: Z3, 75-84% VO2max. Source: Daniels [1] ch. 4.
            return .yellow

        case .hillRepeat:
            // Average Z4 intensity: effort ~90-95% uphill, passive recovery
            // downhill. Session as demanding as Tempo Run → same color.
            // Previously .teal: underestimated the required effort.
            return .orange

        case .tempo:
            // T-pace: Z4, anaerobic threshold, 85-88% VO2max. Source: Daniels [1] ch. 4.
            return .orange

        case .interval:
            // I-pace: Z5, 95-100% VO2max. Source: Daniels [1] ch. 4.
            return .red

        case .repetition:
            // R-pace: Z5+, >100% VO2max, pure speed. Distinct from .interval
            // by shorter work bout and full recovery. Source: Daniels [1] ch. 4.
            return .purple

        case .race:
            // Race: maximum planned effort. Color distinct from all workout types
            // to signal the uniqueness of the event in the calendar.
            return .indigo
        }
    }

    // Numeric zone label (e.g. "Z2", "Z4", "Z5+").
    var zoneLabel: String {
        switch self {
        case .rest:        return "—"
        case .recovery:    return "Z1"
        case .easy:        return "Z2"
        case .longRun:     return "Z2"
        case .progression: return "Z2-4"
        case .hillRepeat:  return "Z4-5"
        case .marPace:     return "Z3"
        case .tempo:       return "Z4"
        case .interval:    return "Z5"
        case .repetition:  return "Z5+"
        case .race:        return "—"
        }
    }

    // Official Daniels letter (E/M/T/I/R). Empty for non-Daniels types.
    var danielsCode: String {
        switch self {
        case .easy, .longRun, .recovery: return "E"
        case .marPace:                   return "M"
        case .tempo:                     return "T"
        case .interval:                  return "I"
        case .repetition:                return "R"
        case .progression, .hillRepeat,
                .rest, .race:               return ""
        }
    }

    // SF Symbol consistent with `color` and `zoneLabel`.
    // Replaces emoji: more consistent with iOS/SwiftUI aesthetics,
    // support automatic tinting, dark mode, and Dynamic Type.
    //
    // Selection criteria:
    // - rest/recovery: minimal or no activity
    // - easy/longRun:  running figure (low intensity)
    // - progression:   ascending chart
    // - hillRepeat:    arrow up (hill)
    // - marPace:       gauge at 1/3 (controlled and sustained pace)
    // - tempo:         flame (high but sustainable effort)
    // - interval:      lightning (maximum aerobic effort, intermittent)
    // - repetition:    hare (pure speed, sprint)
    // - race:          trophy
    var sfSymbol: String {
        switch self {
        case .rest:        return "moon.zzz"
        case .recovery:    return "figure.walk"
        case .easy:        return "figure.run"
        case .longRun:     return "figure.run.circle"
        case .progression: return "chart.line.uptrend.xyaxis"
        case .hillRepeat:  return "arrow.up.forward"
        case .marPace:     return "gauge.with.dots.needle.33percent"
        case .tempo:       return "flame"
        case .interval:    return "bolt"
        case .repetition:  return "hare"
        case .race:        return "trophy"
        }
    }

    var localizedName: LocalizedStringResource {
        switch self {
        case .easy:
            return LocalizedStringResource("workoutType.easy", defaultValue: "Corsa Facile")
        case .longRun:
            return LocalizedStringResource("workoutType.longRun", defaultValue: "Lungo")
        case .marPace:
            return LocalizedStringResource("workoutType.marPace", defaultValue: "Ritmo Maratona")
        case .tempo:
            return LocalizedStringResource("workoutType.tempo", defaultValue: "Tempo Run")
        case .interval:
            return LocalizedStringResource("workoutType.interval", defaultValue: "Interval Training")
        case .repetition:
            return LocalizedStringResource("workoutType.repetition", defaultValue: "Ripetute")
        case .progression:
            return LocalizedStringResource("workoutType.progression", defaultValue: "Corsa Progressiva")
        case .hillRepeat:
            return LocalizedStringResource("workoutType.hillRepeat", defaultValue: "Ripetute in Salita")
        case .recovery:
            return LocalizedStringResource("workoutType.recovery", defaultValue: "Recupero Attivo")
        case .race:
            return LocalizedStringResource("workoutType.race", defaultValue: "GARA")
        case .rest:
            return LocalizedStringResource("workoutType.rest", defaultValue: "Riposo")
        }
    }

    var localizedIntensityDescription: LocalizedStringResource {
        switch self {
        case .rest:
            return LocalizedStringResource(
                "workoutType.intensity.rest",
                defaultValue: "Riposo completo o attività leggera"
            )
        case .recovery:
            return LocalizedStringResource(
                "workoutType.intensity.recovery",
                defaultValue: "59-65% VO2max / 65-70% FCmax – limite inferiore E-pace (Daniels)"
            )
        case .easy:
            return LocalizedStringResource(
                "workoutType.intensity.easy",
                defaultValue: "59-74% VO2max / 65-79% FCmax – Easy pace (Daniels E)"
            )
        case .longRun:
            return LocalizedStringResource(
                "workoutType.intensity.longRun",
                defaultValue: "59-74% VO2max / 65-79% FCmax – E-pace (L run = E run prolungato)"
            )
        case .marPace:
            return LocalizedStringResource(
                "workoutType.intensity.marPace",
                defaultValue: "75-84% VO2max / 80-89% FCmax – Marathon pace (Daniels M)"
            )
        case .tempo:
            return LocalizedStringResource(
                "workoutType.intensity.tempo",
                defaultValue: "85-88% VO2max / 88-92% FCmax – Threshold/Tempo pace (Daniels T)"
            )
        case .interval:
            return LocalizedStringResource(
                "workoutType.intensity.interval",
                defaultValue: "95-100% VO2max / ~98% FCmax – Interval pace (Daniels I)"
            )
        case .repetition:
            return LocalizedStringResource(
                "workoutType.intensity.repetition",
                defaultValue: "105-120% VDOT (>100% VO2max) – Repetition pace (Daniels R) – max 2 min/rep"
            )
        case .progression:
            return LocalizedStringResource(
                "workoutType.intensity.progression",
                defaultValue: "Da 59% a 88% VO2max – E→M→T progressivo (Z2→Z4)"
            )
        case .hillRepeat:
            return LocalizedStringResource(
                "workoutType.intensity.hillRepeat",
                defaultValue: "~90-95% sforzo in salita – forza specifica (Z4-5, impatto ridotto)"
            )
        case .race:
            return LocalizedStringResource(
                "workoutType.intensity.race",
                defaultValue: "Sforzo massimo pianificato – ritmo gara specifico"
            )
        }
    }

    // MARK: - Physiological intensity description

    // FCmax and VO2max percentages follow Daniels [1] ch. 4 (figure 4.1).
    var intensityDescription: String {
        switch self {
        case .rest:
            return "Riposo completo o attività leggera"

        case .recovery:
            // [FIX-6] Daniels does not define a separate recovery zone from Easy.
            // Uses the lower bound of the E-pace range (59% VO2max / 65% FCmax).
            // Source: [1] ch. 4 – E pace range 59-74% VO2max.
            return "59-65% VO2max / 65-70% FCmax – limite inferiore E-pace (Daniels)"

        case .easy:
            // Source: [1] ch. 4: "E is typically about 59 to 74 percent of O2max
            // or about 65 to 79 percent of maximum heart rate."
            return "59-74% VO2max / 65-79% FCmax – Easy pace (Daniels E)"

        case .longRun:
            // The long run is always at E-pace. Source: [1] ch. 4.
            return "59-74% VO2max / 65-79% FCmax – E-pace (L run = E run prolungato)"

        case .marPace:
            // Source: [1] ch. 4 figure 4.1: M = 75-84% VO2max / 80-89% FCmax.
            return "75-84% VO2max / 80-89% FCmax – Marathon pace (Daniels M)"

        case .tempo:
            // Source: [1] ch. 4: T-pace = 85-88% VO2max / 88-92% FCmax (trained athletes).
            return "85-88% VO2max / 88-92% FCmax – Threshold/Tempo pace (Daniels T)"

        case .interval:
            // Source: [1] ch. 4: I-pace = ~95-100% VO2max (vVO2max).
            // Work bout 3-5 min. Active recovery (jog) equal to or slightly less than
            // work time.
            return "95-100% VO2max / ~98% FCmax – Interval pace (Daniels I)"

        case .repetition:
            // Source: [1] ch. 4 – Repetition training. R-pace ≈ 105-120% VDOT (faster than I-pace).
            // "Daniels' 6-second rule": R pace is ~6 sec/400m faster than I pace.
            // Work bout MAX 2 minutes. FULL recovery (jog = run distance).
            return "105-120% VDOT (>100% VO2max) – Repetition pace (Daniels R) – max 2 min/rep"

        case .progression:
            // From E-pace to T-pace progressively. Source: [2] Pfitzinger.
            return "Da 59% a 88% VO2max – E→M→T progressivo (Z2→Z4)"

        case .hillRepeat:
            // Hills: strength-speed stimulus with reduced joint impact.
            // Compatible with Phase I/II of Daniels. Source: [2] Pfitzinger.
            return "~90-95% sforzo in salita – forza specifica (Z4-5, impatto ridotto)"

        case .race:
            return "Sforzo massimo pianificato – ritmo gara specifico"
        }
    }

    // MARK: - Recommended phase (Daniels [1] ch. 10)

    // Indicates in which phase Daniels preferably introduces this type.
    // Useful for validation and UI.
    // [FIX-3] The correct sequence is: E (Base) → R (Build) → T+I (Peak).
    //         Not: E (Base) → T+I (Build). I should not be introduced before R.
    var recommendedPhases: [TrainingPhase] {
        switch self {
        case .rest:
            return [.base, .build, .peak, .taper, .race]
        case .recovery:
            return [.base, .build, .peak, .taper, .race]
        case .easy, .longRun:
            // E-pace is present in all phases as base volume.
            return [.base, .build, .peak, .taper, .race]
        case .progression, .hillRepeat:
            // Light stimuli compatible with Phase I (Base) of Daniels.
            return [.base, .build]
        case .repetition:
            // R introduced in Phase II (Build), before I.
            // Source: [1] ch. 10 – Phase II: "going from E running to R workouts
            // is adding only a speed stress."
            return [.build, .peak]
        case .tempo:
            // T introduced from Phase II (Build) onward.
            return [.build, .peak, .taper]
        case .marPace:
            // M-pace relevant in Peak, especially for marathon/HM. Source: [2].
            return [.peak, .taper]
        case .interval:
            // I introduced only in Peak (Phase III/IV of Daniels), never in Base.
            return [.peak]
        case .race:
            return [.race]
        }
    }

    // MARK: - Max volume per session (% of weekly volume)

    // Limits defined by Daniels [1] ch. 4.
    // Useful for validation of generated workouts.
    var maxSessionFractionOfWeeklyVolume: Double? {
        switch self {
        case .longRun:
            // Daniels [1] ch. 4: "no more than 25 percent of weekly mileage."
            return 0.25
        case .tempo:
            // Daniels [1] ch. 4: "not totaling more than 10 percent of
            // your weekly mileage in a single workout."
            return 0.10
        case .marPace:
            // Daniels [1] ch. 4: "not add up to more than the lesser of
            // 20 percent of your weekly mileage or 18 miles."
            return 0.20
        case .interval:
            // Daniels [1] ch. 4: "maximum the lesser of 10K or 8 percent
            // of your weekly mileage."
            return 0.08
        case .repetition:
            // Daniels [1] ch. 4: R sessions shorter and more intense.
            // Conservative limit: 5% of weekly volume.
            return 0.05
        case .easy, .recovery, .progression,
                .hillRepeat, .rest, .race:
            return nil  // no strict percentage limit for these types
        }
    }

    // Corresponding section in MethodologyView.
    // nil for types without a dedicated Daniels zone (rest, race, etc.).
    var methodologySection: MethodologySection? {
        switch self {
        case .easy, .longRun, .recovery: return .zoneE
        case .marPace:                   return .zoneM
        case .tempo:                     return .zoneT
        case .interval:                  return .zoneI
        case .repetition:                return .zoneR
        case .progression, .hillRepeat:  return .phaseBase
        case .rest, .race:               return nil
        }
    }
}

// MARK: - VDOT / Paces calculator
//
// VDOT and training paces calculation.
// Main sources:
// - Daniels J. (2014). Daniels' Running Formula, 3rd Ed. Human Kinetics.
// - Pfitzinger P., Douglas S. (2009). Advanced Marathoning. Human Kinetics.
// - Billat V. (2001). Interval Training for Performance. Sports Medicine.

struct VDOTCalculator {
    static func calculate(timeInSeconds: Double, distanceMeters: Double) -> Double {
        let time = timeInSeconds / 60.0  // minutes

        // Velocity in m/min
        let velocity = (distanceMeters / timeInSeconds) * 60.0

        // VO2 required at that velocity
        let vo2 = -4.60 + 0.182258 * velocity + 0.000104 * velocity * velocity

        // Fraction of VO2max used at that duration (Daniels)
        let pctVO2max = 0.8 + 0.1894393 * exp(-0.012778 * time) + 0.2989558 * exp(-0.1932605 * time)

        let vdot = vo2 / pctVO2max
        return max(20, min(85, vdot))
    }

    // Training paces in sec/km based on VDOT
    // Source: Daniels' Running Formula, Tables (adapted)
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

    // Velocity (m/min) from VDOT (approximate inversion)
    private static func velocityFromVDOT(_ vdot: Double) -> Double {
        // Simplified numerical inversion of the Daniels formula
        // at 100% VO2max (pctVO2max ≈ 1.0 for durations ~10-15 min)
        // v ≈ solution of: -4.60 + 0.182258*v + 0.000104*v^2 = vdot
        let a = 0.000104
        let b = 0.182258
        let c = -4.60 - vdot
        let discriminant = b * b - 4 * a * c
        return (-b + sqrt(discriminant)) / (2 * a)
    }

    // Estimates target time on race distance from VDOT
    static func predictRaceTime(vdot: Double, distance: RaceDistance) -> Double {
        // Find the time (in sec) such that calculated VDOT ≈ given vdot
        // Bisection method
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

// MARK: - Training paces
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

    // R-pace: ~105-120% of VDOT intensity (faster than I-pace).
    // Daniels [1]: R pace ≈ race pace on mile / 1500m.
    // "6-second rule": R pace is ~6 sec/400m faster than I pace.
    // Implementation: invert the formula with VDOT * 1.05 (approximate
    // conservative, equivalent to about 5% faster than race pace at VO2max).
    var repetitionPaceSecsPerKm: Double {
        // Approximation: R pace ≈ I pace - 6 sec/400m ≈ I pace * 0.965
        // (6 sec on 400m = 15 sec/km, and at I-pace ~3:30-4:00/km, -15 sec ≈ 4%)
        return intervalPaceSecsPerKm * 0.965
    }

    var repetitionFormatted: String {
        formatted(repetitionPaceSecsPerKm)
    }

    func repetitionFormatted(unitSystem: UnitSystem) -> String {
        formattedPace(repetitionPaceSecsPerKm, unitSystem: unitSystem)
    }
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
    let titleKind: WorkoutTitleKind
    let descriptionKind: WorkoutDescriptionKind
    let distanceKm: Double?
    let durationMinutes: Int?
    let paceTarget: String?
    let paceTargetSecsPerKm: Double?   // raw value, formatted at display time
    let structuredSets: String?
    let structuredSetsKind: StructuredSetsKind?
    let scientificRationale: String
    let rpe: String  // Rate of Perceived Exertion 1-10
    let tss: Double  // Training Stress Score (approximate)

    func localizedTitle(locale: Locale) -> String {
        titleKind.localizedText(locale: locale)
    }

    func localizedDescription(locale: Locale) -> String {
        descriptionKind.localizedText(locale: locale)
    }

    func localizedIntensityDescription(locale: Locale) -> String {
        AppLocalizedString.resolve(type.localizedIntensityDescription, locale: locale)
    }

    func localizedStructuredSets(locale: Locale) -> String? {
        structuredSetsKind?.localizedText(locale: locale)
    }
}

// MARK: - Training Plan Input
struct TrainingPlanInput {
    let raceDistance: RaceDistance
    let raceDate: Date
    let raceName: String
    let trainingDaysPerWeek: Int
    let targetTime: TimeInterval        // seconds
    let currentPerformance: CurrentPerformance
    let sex: RunnerSex
}

// MARK: - Current Performance
struct CurrentPerformance {
    let distance: RaceDistance
    let time: TimeInterval  // seconds
}

// MARK: - Training Plan Output
struct TrainingPlan: Identifiable {
    let id = UUID()
    let input: TrainingPlanInput
    let paces: TrainingPaces
    let weeks: [TrainingWeek]
    let scientificSources: [String]
    let estimatedRaceTime: Double
    let vdotCurrent: Double
    let vdotTarget: Double
    let feasibility: GoalFeasibility   // used for sfSymbol and color

    // Localized text at presentation time.
    // `String(localized:)` alone uses the system language; passing `locale` from `@Environment(\.locale)`
    // aligns with the in-app language picker (as static `Text` already do).
    func localizedFitnessGap(locale: Locale) -> String {
        let diffSeconds = input.targetTime - estimatedRaceTime
        let direction = diffSeconds > 0
            ? LocalizedStringResource(
                "trainingPlan.fitnessGap.direction.slower",
                defaultValue: "più lento",
                locale: locale
            )
            : LocalizedStringResource(
                "trainingPlan.fitnessGap.direction.faster",
                defaultValue: "più veloce",
                locale: locale
            )

        let absDiff = abs(Int(diffSeconds))
        let diffText = String(format: "%d:%02d", absDiff / 60, absDiff % 60)
        let format = String(
            localized: LocalizedStringResource(
                "trainingPlan.fitnessGap",
                defaultValue: """
                VDOT attuale: %1$@ → VDOT richiesto: %2$@. Tempo stimato attuale: %3$@. \
                Il target è %4$@ %5$@.
                %6$@
                """,
                locale: locale
            )
        )

        return String(
            format: format,
            locale: locale,
            String(format: "%.1f", vdotCurrent),
            String(format: "%.1f", vdotTarget),
            Self.formatRaceTime(estimatedRaceTime),
            diffText,
            String(localized: direction),
            String(localized: Self.localizedLabel(for: feasibility, locale: locale))
        )
    }

    private static func localizedLabel(for feasibility: GoalFeasibility, locale: Locale) -> LocalizedStringResource {
        var resource = feasibility.localizedLabel
        resource.locale = locale
        return resource
    }

    private static func formatRaceTime(_ seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        let sec = Int(seconds) % 60
        if hrs > 0 { return String(format: "%d:%02d:%02d", hrs, min, sec) }
        return String(format: "%d:%02d", min, sec)
    }
}

// MARK: Training Week
struct TrainingWeek: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let phase: TrainingPhase
    let workouts: [Workout]
    let weeklyNote: String
    let weeklyNoteKind: WeeklyNoteKind

    var totalKm: Double {
        workouts.compactMap(\.distanceKm).reduce(0, +)
    }

    func localizedWeeklyNote(locale: Locale) -> String {
        weeklyNoteKind.localizedText(locale: locale)
    }

    func localizedHeader(locale: Locale) -> String {
        AppLocalizedString.formatted(
            LocalizedStringResource(
                "Settimana %lld – %@",
                defaultValue: "Settimana %1$lld – %2$@"
            ),
            locale: locale,
            arguments: [weekNumber, AppLocalizedString.resolve(phase.localizedName, locale: locale)]
        )
    }
}

// MARK: Event data (for calendar)
struct EventData: Identifiable {
    let id = UUID()
    var date: Date
    var title: String
    var notes: String
}

// MARK: Training Phases
enum TrainingPhase: String {
    case base = "Fase Base"
    case build = "Fase di Sviluppo"
    case peak = "Fase di Picco"
    case taper = "Scarico"
    case race = "Gara"

    var localizedName: LocalizedStringResource {
        switch self {
        case .base:
            return LocalizedStringResource("trainingPhase.base", defaultValue: "Fase Base")
        case .build:
            return LocalizedStringResource("trainingPhase.build", defaultValue: "Fase di Sviluppo")
        case .peak:
            return LocalizedStringResource("trainingPhase.peak", defaultValue: "Fase di Picco")
        case .taper:
            return LocalizedStringResource("trainingPhase.taper", defaultValue: "Scarico")
        case .race:
            return LocalizedStringResource("trainingPhase.race", defaultValue: "Gara")
        }
    }

    var description: String {
        switch self {
        case .base: return "Costruzione aerobica, adattamento muscolo-scheletrico, volume progressivo"
        case .build: return "Introduzione lavori di qualità, aumento intensità, sviluppo soglia"
        case .peak: return "Massimo volume/qualità, simulazioni gara, affinamento della forma"
        case .taper: return "Riduzione volume (40-60%), mantenimento intensità, recupero e supercompensazione"
        case .race: return "Settimana di gara"
        }
    }

    var methodologySection: MethodologySection {
        switch self {
        case .base:  return .phaseBase
        case .build: return .phaseBuild
        case .peak:  return .phasePeak
        case .taper: return .taper
        case .race:  return .sources
        }
    }
}     // swiftlint:disable:this file_length
