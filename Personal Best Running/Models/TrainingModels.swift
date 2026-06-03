import SwiftUI

// MARK: - GoalFeasibility
enum GoalFeasibility {
    /// Unica fonte di verità per la valutazione dell'obiettivo gara.
    /// basata su vdotGap perché:
    ///   - È indipendente dalla distanza di gara
    ///   - Misura direttamente quanta fitness deve crescere
    ///   - È la stessa unità usata in tutto il sistema Daniels [1]
    ///   - diffSecs dipende dalla distanza (22' su maratona ≠ 22' su 5K
    /// Fonte: Daniels [1] cap. 5 — VDOT come misura universale della fitness.
    
    case conservative    // vdotGap < -5  (target più lento della forma attuale)
    case prudent        // vdotGap -5..<-2
    case realistic      // vdotGap -2..<2  (allineato alla forma attuale)
    case ambitious      // vdotGap  2..<5
    case challenging    // vdotGap  5..<10
    case extreme        // vdotGap >= 10
    
    // Calcolo dalla differenza VDOT. Entry point unico usato dal generatore.
    static func from(vdotGap: Double) -> GoalFeasibility {
        switch vdotGap {
        case ..<(-5):  return .conservative
        case -5..<(-2): return .prudent
        case -2..<2:   return .realistic
        case  2..<5:   return .ambitious
        case  5..<10:  return .challenging
        default:       return .extreme
        }
    }
    
    // MARK: Label breve (usata in PlanHeaderView / fitnessGap)

    // Testo breve senza emoji — la segnalazione visiva è affidata a
    // sfSymbol e color, più coerenti con l'estetica iOS di SF Symbols.
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
    
    // SF Symbol abbinati al livello di fattibilità.
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
    
    // MARK: Descrizione estesa (usata in WorkoutRowView / scheda GARA)
    // Contestualizzata per il giorno di gara: tono motivazionale e consigli pratici.
    
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
    
    // MARK: Colore SwiftUI (coerente tra PlanHeaderView e WorkoutRowView)
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
    
    // Questo dice a Xcode di mettere queste stringhe e mettile nel file .xcstrings!"
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
    
    // MARK: Soglie livelli atleta
    /// Soglie VDOT per livello, differenziate per sesso.
    /// Basate sulla distribuzione percentile dei finishing time    // nelle maratone di massa (RunRepeat Global Report 2023)
    /// e sulle tabelle age-grading di WMA (World Masters Athletics).
    ///
    /// Uomo:   mediana maratona ~4:30 → VDOT ~37
    /// Donna:  mediana maratona ~4:55 → VDOT ~33
    /// Il "corridore medio" ha VDOT diverso per sesso → le soglie si spostano.
    
    // swiftlint:disable:next large_tuple
    var levelThresholds: (recreational: Double, intermediate: Double, advanced: Double, elite: Double) {
        switch self {
        case .male:
            // Distribuzione maschile: mediana ~VDOT 37
            return (recreational: 32, intermediate: 42, advanced: 52, elite: 62)
        case .female:
            // Distribuzione femminile: mediana ~VDOT 33, shift ~8-10 punti
            return (recreational: 28, intermediate: 37, advanced: 47, elite: 57)
        }
    }
    
    func runnerLevel(vdot: Double) -> RunnerLevel {
        let soglie = levelThresholds
        switch vdot {
        case ..<soglie.recreational:  return .beginner
        case soglie.recreational..<soglie.intermediate: return .recreational
        case soglie.intermediate..<soglie.advanced: return .intermediate
        case soglie.advanced..<soglie.elite: return .advanced
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
    
    // MARK: Conversions
    /// Converte km → unità visualizzata
    func displayDistance(_ kms: Double) -> Double {
        switch self {
        case .metric:   return kms
        case .imperial: return kms * 0.621371
        }
    }
    
    // Suffisso distanza
    var distanceUnit: String {
        switch self {
        case .metric:   return "km"
        case .imperial: return "mi"
        }
    }
    
    // Converte secondi/km → secondi/unità visualizzata
    func displayPace(_ secsPerKm: Double) -> Double {
        switch self {
        case .metric:   return secsPerKm
        case .imperial: return secsPerKm / 0.621371   // sec/mi
        }
    }
    
    // Suffisso passo
    var paceUnit: String {
        switch self {
        case .metric:   return "/km"
        case .imperial: return "/mi"
        }
    }
    
    // Formatta secondi/km → stringa passo localizzata
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

// MARK: - Race Distances
enum RaceDistance: String, CaseIterable, Identifiable {
    case fiveK = "5 km"
    case tenK = "10 km"
    case halfMarathon = "Mezza Maratona"
    case marathon = "Maratona"
    
    // Questo dice a Xcode di mettere queste stringhe e mettile nel file .xcstrings!"
    var localizedName: LocalizedStringResource {
        switch self {
        case .fiveK: return "5 km"
        case .tenK: return "10 km"
        case .halfMarathon: return "Mezza Maratona"
        case .marathon: return "Maratona"
        }
    }
    
    // La 5K è esclusa dalle distanze target perché:
    // - Richiede una struttura di piano diversa (più R e I, meno volume)
    // - Il generatore è ottimizzato per distanze da resistenza prolungata
    // - Rimane disponibile come distanza di riferimento per il VDOT
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
    
    var performanceBounds: PerformanceBounds {
        switch self {
        case .fiveK:
            return PerformanceBounds(
                minSeconds: 13 * 60,          // 13:00 (élite mondiale ~12:35)
                maxSeconds: 60 * 60           // 1:00:00 (12:00 /km)
            )
        case .tenK:
            return PerformanceBounds(
                minSeconds: 27 * 60,          // 27:00 (élite mondiale ~26:17)
                maxSeconds: 2 * 3600          // 2:00:00 (12:00 /km)
            )
        case .halfMarathon:
            return PerformanceBounds(
                minSeconds: 58 * 60,          // 58:00 (élite mondiale ~57:31)
                maxSeconds: 4 * 3600          // 4:00:00 (~11:22 /km)
            )
        case .marathon:
            return PerformanceBounds(
                minSeconds: 2 * 3600,         // 2:00:00 (élite mondiale)
                maxSeconds: 8 * 3600          // 8:00:00 (~11:22 /km)
            )
        }
    }
}

// MARK: - WorkoutType
enum WorkoutType: String, CaseIterable {
    /// Enum dei tipi di allenamento basato sulle categorie ufficiali di Daniels [1].
    ///
    /// FONTI
    /// [1] Daniels J. (2022). Daniels' Running Formula (4th ed.). Human Kinetics.
    ///     Cap. 4: E, M, T, I, R — le cinque intensità core del sistema Daniels.
    /// [2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.
    /// [6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering strategies.
    ///     Medicine & Science in Sports & Exercise, 35(7), 1182-1187.
    ///
    /// MODIFICHE RISPETTO ALLA VERSIONE PRECEDENTE
    ///
    /// [FIX-2] Aggiunto caso .repetition (R-pace di Daniels).
    ///   Era completamente assente. Daniels [1] cap. 4 dedica una sezione autonoma
    ///   alle Repetition: scopo primario è velocità ed economia di corsa.
    ///   Work bout MAX 2 min, recupero COMPLETO (jog = distanza del lavoro).
    ///   Introdotte in Phase II (Build), prima delle Interval.
    ///
    /// [FIX-5] Intensità FCmax di .tempo corretta: da "80-90%" a "88-92%".
    ///   Daniels [1] cap. 4: T-pace = 85-88% VO2max / 88-92% FCmax (atleti allenati).
    ///   Il precedente 80% coincideva con M-pace, non con la soglia anaerobica.
    ///
    /// [FIX-6] Intensità di .recovery allineata all'E-pace di Daniels.
    ///   Daniels non definisce una zona "recovery" separata: usa E-pace (59-74% VO2max)
    ///   per tutto il continuum di bassa intensità. L'intensityDescription ora
    ///   rispecchia questo, usando il limite inferiore dell'E-pace.
    
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
    
    // MARK: - Palette colori / zona / emoji
    //
    /// Fonte unica di verità per colore, etichetta zona, codice Daniels ed emoji.
    /// Sia calendarView che PacesView attingono a queste proprietà,
    /// garantendo coerenza visiva senza duplicazioni.
    ///
    /// Palette basata sull'intensità crescente secondo Daniels [1] cap. 4:
    ///   gray   → nessuna intensità (rest/recovery)
    ///   green  → E  (Z2, aerobico base)
    ///   teal   → progressione/colline (Z2→Z4, supplemental)
    ///   yellow → M  (Z3, marathon pace)
    ///   orange → T  (Z4, soglia)
    ///   red    → I  (Z5, VO2max)
    ///   purple → R  (Z5+, velocità pura)
    ///   indigo → gara
    ///
    /// Correzioni rispetto alla versione precedente:
    /// - interval e repetition avevano lo stesso colore purple → ora distinti (red/purple)
    /// - recovery era blue suggerendo una zona separata → ora green (limite inf. E-pace)
    /// - tempo era red come interval → ora orange (un gradino sotto in intensità)
    
    var color: Color {
        switch self {
        case .rest:
            // Nessuno sforzo — neutro.
            return .gray
            
        case .recovery:
            // Limite inferiore dell'E-pace (59% VO2max). Daniels non definisce
            // una zona separata: è semplicemente E-pace molto leggero.
            // Stesso colore di .easy per coerenza concettuale.
            return .green
            
        case .easy, .longRun:
            // E-pace / L run: Z2, aerobico base. Fonte: Daniels [1] cap. 4.
            return .green
            
        case .progression:
            // La progressiva inizia a E-pace (Z2) e sale verso T-pace (Z4),
            // ma la maggior parte del volume è nella metà inferiore del range.
            // .yellow (Z3/M-pace) riflette l'intensità media onesta della sessione.
            // Precedentemente .teal: non comunicava intensità, solo "tipo diverso".
            return .yellow
            
        case .marPace:
            // M-pace: Z3, 75-84% VO2max. Fonte: Daniels [1] cap. 4.
            return .yellow
            
        case .hillRepeat:
            // Intensità media Z4: sforzo ~90-95% in salita, recupero passivo
            // in discesa. Sessione impegnativa quanto il Tempo Run → stesso colore.
            // Precedentemente .teal: sottostimava lo sforzo richiesto.
            return .orange
            
        case .tempo:
            // T-pace: Z4, soglia anaerobica, 85-88% VO2max. Fonte: Daniels [1] cap. 4.
            return .orange
            
        case .interval:
            // I-pace: Z5, 95-100% VO2max. Fonte: Daniels [1] cap. 4.
            return .red
            
        case .repetition:
            // R-pace: Z5+, >100% VO2max, velocità pura. Distinto da .interval
            // per work bout più breve e recupero completo. Fonte: Daniels [1] cap. 4.
            return .purple
            
        case .race:
            // Gara: sforzo massimo pianificato. Colore distinto da tutti i tipi
            // di allenamento per segnalare l'unicità dell'evento nel calendario.
            return .indigo
        }
    }
    
    /// Etichetta zona numerica (es. "Z2", "Z4", "Z5+").
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
    
    /// Lettera ufficiale Daniels (E/M/T/I/R). Vuota per i tipi non-Daniels.
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
    
    /// SF Symbol coerente con `color` e `zoneLabel`.
    /// Sostituisce le emoji: più coerenti con l'estetica iOS/SwiftUI,
    /// supportano tinting automatico, dark mode e Dynamic Type.
    ///
    /// Criteri di scelta:
    /// - rest/recovery: attività minima o assente
    /// - easy/longRun:  figura che corre (intensità bassa)
    /// - progression:   grafico ascendente
    /// - hillRepeat:    freccia su (salita)
    /// - marPace:       gauge a 1/3 (ritmo controllato e sostenuto)
    /// - tempo:         fiamma (sforzo alto ma sostenibile)
    /// - interval:      fulmine (sforzo massimo aerobico, intermittente)
    /// - repetition:    coniglio (velocità pura, sprint)
    /// - race:          trofeo
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
    
    // MARK: - Descrizione intensità fisiologica
    
    // Le percentuali di FCmax e VO2max seguono Daniels [1] cap. 4 (figura 4.1).
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
            // Collinare: stimolo forza-velocità a impatto articolare ridotto.
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
    
    // Sezione corrispondente in MethodologyView.
    // nil per tipi senza zona Daniels dedicata (rest, race, ecc.).
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
struct VDOTCalculator {
    /// Calcolo VDOT e ritmi di allenamento
    /// Fonti principali:
    /// - Daniels J. (2014). Daniels' Running Formula, 3rd Ed. Human Kinetics.
    /// - Pfitzinger P., Douglas S. (2009). Advanced Marathoning. Human Kinetics.
    /// - Billat V. (2001). Interval Training for Performance. Sports Medicine.
    static func calculate(timeInSeconds: Double, distanceMeters: Double) -> Double {
        let time = timeInSeconds / 60.0  // minuti
        //   let dist = distanceMeters / 1000.0 // km
        
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
    
    // Velocità (m/min) da VDOT (inversione approssimativa)
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
    let tss: Double  // Training Stress Score (approssimativo)

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
    let targetTime: TimeInterval        // secondi
    let currentPerformance: CurrentPerformance
    let sex: RunnerSex
}

// MARK: - Current Performance
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
    let vdotCurrent: Double
    let vdotTarget: Double
    let feasibility: GoalFeasibility   // seve per sfSymbol e color

    /// Testo localizzato al momento della presentazione.
    /// `String(localized:)` da solo usa la lingua di sistema; passando `locale` da `@Environment(\.locale)`
    /// si allinea al language picker in-app (come fanno già le `Text` statiche).
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

    // Somma le distanze reali dei workout
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

// MARK: Event data (per il calendario)
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
