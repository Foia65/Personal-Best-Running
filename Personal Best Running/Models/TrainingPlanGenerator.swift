import Foundation
// swiftlint:disable file_length

// MARK: - Training Plan Generator
// FONTI SCIENTIFICHE
///
/// [1] Daniels J. (2022). Daniels' Running Formula (4th ed.). Human Kinetics.
///     → VDOT system, pace zones (E/M/T/I/R), long run rules, phase structure,
///       weekly volume limits, taper, sex-neutrality of VDOT
///
/// [2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.
///     → Distribuzione volume settimanale, sessioni specifiche maratona/HM
///
/// [3] Billat V. (2001). Interval Training for Performance. Sports Medicine, 31(1), 13-31.
///     → Interval training a VO2max, durata ripetizioni, recupero
///
/// [4] Seiler S., Kjerland G.Ø. (2006). Quantifying training intensity distribution
///     in elite endurance athletes. Scand. J. Med. Sci. Sports, 16(1), 49-56.
///     → Distribuzione polarizzata: ~80% bassa intensità, ~20% alta intensità
///     NOTA: Seiler descrive un pattern empirico osservato negli élite, non un
///     modello prescrittivo che sostituisce la struttura per fasi di Daniels.
///     Nel codice è usato come guida per bilanciare i tipi di workout nella settimana.
///
/// [5] Laursen P.B., Jenkins D.G. (2002). The Scientific Basis for High-Intensity
///     Interval Training. Sports Medicine, 32(1), 53-73.
///     → Adattamenti fisiologici all'HIIT (VO2max, capillarizzazione)
///
/// [6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering
///     strategies. Medicine & Science in Sports & Exercise, 35(7), 1182-1187.
///     → Taper: riduzione 40-60% volume, mantenimento intensità
///
/// [7] Bompa T., Haff G. (2009). Periodization: Theory and Methodology of Training
///     (5th ed.). Human Kinetics.
///     → Periodizzazione in macrocicli (preparazione generale → speciale → competitiva)
///     NOTA: la nomenclatura Base/Build/Peak/Taper è compatibile con Bompa.
///     Il contenuto delle fasi (quale tipo di allenamento va in quale fase) segue però
///     Daniels [1] (Phase I→E+strides, Phase II→R, Phase III→T+I, Phase IV→picco).
///
/// [8] Galloway J. (2010). Running Until You're 100. Meyer & Meyer Sport.
///     → Progressione conservativa (regola del 10%)

class TrainingPlanGenerator {  // swiftlint:disable:this type_body_length
    // MARK: - Costanti basate su Daniels [1]

    /// Regola del 10%: non aumentare volume settimanale >10% rispetto alla settimana
    /// precedente. Fonte: [1] cap. 2, [8] Galloway.
    /// NOTA: Daniels suggerisce anche di restare allo stesso carico 3-4 settimane
    /// prima di aumentare. Qui applichiamo l'aumento massimo settimanale come
    /// limite superiore, con settimane di scarico ogni 3-4 settimane.
    static let maxWeeklyVolumeIncreasePercent: Double = 0.10

    /// Volume massimo di I-pace in una singola sessione: il minore tra 10K e 8%
    /// del volume settimanale. Fonte: [1] cap. 4.
    static let maxIntervalFractionOfWeekly: Double = 0.08
    static let maxIntervalKm: Double = 10.0

    /// Volume massimo di R-pace in una singola sessione: 5% del volume settimanale.
    /// Fonte: [1] cap. 4 (R è più intenso dell'I ma i work bout sono brevissimi,
    /// il limite è conservativo per non compromettere il recupero).
    static let maxRepetitionFractionOfWeekly: Double = 0.05

    /// Volume massimo T-pace in una singola sessione: 10% del volume settimanale.
    /// Fonte: [1] cap. 4: "not totaling more than 10 percent of your weekly mileage".
    static let maxThresholdFractionOfWeekly: Double = 0.10

    // MARK: - Generate Plan
     func generate(input: TrainingPlanInput) -> TrainingPlan {     // swiftlint:disable:this function_body_length
        let calendar = Calendar.current
        let today = Date()

        // Calcola VDOT corrente dalla performance attuale
        let currentVDOT = VDOTCalculator.calculate(
            timeInSeconds: input.currentPerformance.time,
            distanceMeters: input.currentPerformance.distance.meters
        )

        /// Il VDOT è già sex-neutral per definizione di Daniels [1] cap. 5.
        /// runner con VDOT 50 si allena agli stessi ritmi indipendentemente dal sesso.
        /// Il VDOT riflette già la performance individuale reale.
        /// Fonte: "The higher VDOT value is associated with the better runner,
        /// regardless of age or sex" — Daniels [1] cap. 5.
        let normalizedVDOT = currentVDOT

        // Calcola ritmi di allenamento dal VDOT corrente (senza correzione sesso)
        let paces = VDOTCalculator.trainingPaces(vdot: normalizedVDOT)

        // Tempo stimato con VDOT attuale sulla distanza target
        let estimatedCurrent = VDOTCalculator.predictRaceTime(
            vdot: normalizedVDOT,
            distance: input.raceDistance
        )
        let estimatedPaceSecsPerKm = estimatedCurrent / input.raceDistance.meters * 1000

        // VDOT richiesto per il tempo target
        let targetVDOT = VDOTCalculator.calculate(
            timeInSeconds: input.targetTime,
            distanceMeters: input.raceDistance.meters
        )
        let vdotGap = targetVDOT - normalizedVDOT
        let fitnessGap = buildFitnessGapString(
            estimatedCurrent: estimatedCurrent,
            target: input.targetTime,
            vdotCurrent: normalizedVDOT,
            vdotTarget: targetVDOT
        )

        // Numero di settimane disponibili
        let rawWeeks = calendar.dateComponents(
            [.weekOfYear], from: today, to: input.raceDate
        ).weekOfYear ?? 12
        let totalWeeks = min(input.raceDistance.maxPlanWeeks, max(12, rawWeeks))

        let planStartDate = calendar.date(
            byAdding: .weekOfYear, value: -totalWeeks, to: input.raceDate
        )! // swiftlint:disable:this force_unwrapping

        // Struttura delle fasi. Fonte: [1] cap. 10 (4 fasi), [7] Bompa periodizzazione.
        let phases = buildPhaseStructure(
            totalWeeks: totalWeeks,
            distance: input.raceDistance
        )

        let baseWeeklyKm = estimateBaseWeeklyKm(
            daysPerWeek: input.trainingDaysPerWeek,
            vdot: normalizedVDOT,
            distance: input.raceDistance
        )

        var weeks: [TrainingWeek] = []
        var prevWeekKm = baseWeeklyKm

        for week in 0..<totalWeeks {
            let weekPhase = phases[min(week, phases.count - 1)]
            let weekStartDate = calendar.date(
                byAdding: .weekOfYear, value: week, to: planStartDate
            )! // swiftlint:disable:this force_unwrapping

            let (weekKm, weekNote) = computeWeeklyVolume(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: weekPhase,
                baseKm: baseWeeklyKm,
                prevKm: prevWeekKm
            )

            let workouts = generateWeekWorkouts(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: weekPhase,
                weekStartDate: weekStartDate,
                daysPerWeek: input.trainingDaysPerWeek,
                weeklyKm: weekKm,
                paces: paces,
                distance: input.raceDistance,
                raceDate: input.raceDate,
                raceName: input.raceName,
                vdotGap: vdotGap,
                targetPaceSecsPerKm: estimatedPaceSecsPerKm
            )

            let trWk = TrainingWeek(
                weekNumber: week + 1,
                phase: weekPhase,
                workouts: workouts,
                weeklyNote: weekNote
            )
            weeks.append(trWk)
            prevWeekKm = weekKm
        }

        return TrainingPlan(
            input: input,
            paces: paces,
            weeks: weeks,
            scientificSources: scientificSources(),
            estimatedRaceTime: estimatedCurrent,
            fitnessGap: fitnessGap,
            feasibility: GoalFeasibility.from(vdotGap: vdotGap)
        )
    }

    // MARK: - Phase Structure

    /// La struttura delle fasi ora rispecchia la logica di Daniels [1] cap. 10:
    ///
    ///  Phase I  (Base)  → E running + strides + hillRepeat leggere + progressioni.
    ///                     "Mostly E running" – nessun lavoro I pesante.
    ///  Phase II (Build) → Introduzione R (Repetition): si aggiunge solo lo stimolo
    ///                     velocità. Daniels porta R prima di T+I perché è uno stress
    ///                     aggiuntivo minore rispetto all'I. Si introduce anche T (Tempo).
    ///  Phase III (Peak) → Massima qualità: T + I + M. Il più impegnativo. Fonte: [1].
    ///  Taper            → Volume -40-60%, intensità mantenuta. Fonte: [6] Mujika.
    ///  Race             → Settimana di gara.
    ///
    /// I nomi Base/Build/Peak/Taper sono compatibili con la periodizzazione di Bompa [7].
    private func buildPhaseStructure(
        totalWeeks: Int,
        distance: RaceDistance
    ) -> [TrainingPhase] {

        /// Proporzioni fasi per distanza gara.
        /// Maratona: base più lunga (più volume aerobico necessario, meno velocità pura).
        /// 5K: base più corta, più picco (velocità e VO2max centrali).
        /// Fonte: [1] cap. 10 (distribuzione fasi), [2] Pfitzinger (maratona).
        let phaseRatios: (base: Double, build: Double, peak: Double, taper: Double) // swiftlint:disable:this large_tuple
        switch distance {
        case .fiveK:
            phaseRatios = (0.25, 0.38, 0.27, 0.10)
        case .tenK:
            phaseRatios = (0.28, 0.38, 0.24, 0.10)
        case .halfMarathon:
            phaseRatios = (0.33, 0.37, 0.20, 0.10)
        case .marathon:
            phaseRatios = (0.38, 0.35, 0.17, 0.10)
        }

        let baseWeeks  = max(2, Int(Double(totalWeeks) * phaseRatios.base))
        let buildWeeks = max(2, Int(Double(totalWeeks) * phaseRatios.build))
        let peakWeeks  = max(1, Int(Double(totalWeeks) * phaseRatios.peak))
        let taperWeeks = max(2, totalWeeks - baseWeeks - buildWeeks - peakWeeks - 1)

        var phases: [TrainingPhase] = []
        phases += Array(repeating: .base, count: baseWeeks)
        phases += Array(repeating: .build, count: buildWeeks)
        phases += Array(repeating: .peak, count: peakWeeks)
        phases += Array(repeating: .taper, count: taperWeeks)
        phases.append(.race)

        return phases
    }

    // MARK: - Weekly Volume Computation

    private func estimateBaseWeeklyKm(
        daysPerWeek: Int,
        vdot: Double,
        distance: RaceDistance
    ) -> Double {

        // Km per sessione base, per fascia VDOT.
        // Fonte: Daniels [1] cap. 2 (livelli di partenza raccomandati).
        let kmPerSession: Double
        switch vdot {
        case ..<35: kmPerSession = 5.0   // beginner: sessioni brevi, adattamento graduale
        case 35..<45: kmPerSession = 8.0
        case 45..<55: kmPerSession = 11.0
        default: kmPerSession = 14.0
        }

        let distanceFactor: Double
        switch distance {
        case .fiveK: distanceFactor = 0.75
        case .tenK: distanceFactor = 0.88
        case .halfMarathon: distanceFactor = 1.0
        case .marathon: distanceFactor = 1.15
        }

        let computed = Double(daysPerWeek) * kmPerSession * distanceFactor

        /// Cap assoluto per combinazione distanza/livello VDOT.
        /// Impedisce volumi sproporzionati per runner alle prime armi.
        /// Un beginner 5K non ha bisogno (né può reggere) 20+ km/settimana
        /// nelle prime settimane. Fonte: Daniels [1] cap. 2 — progressione
        /// conservativa per livelli bassi; Pfitzinger [2] — volume iniziale.
        ///
        /// Soglie basate su: distribuzione di popolazione (RunRepeat 2023),
        /// letteratura su prevenzione infortuni nei runner ricreativi.
        let absoluteCap: Double
        switch (distance, vdot) {
        // 5K
        case (.fiveK, ..<35):    absoluteCap = 18    // beginner 5K: max ~18 km/sett
        case (.fiveK, 35..<45):  absoluteCap = 32
        case (.fiveK, 45..<55):  absoluteCap = 50
        case (.fiveK, _):        absoluteCap = 65
        // 10K
        case (.tenK, ..<35):     absoluteCap = 25
        case (.tenK, 35..<45):   absoluteCap = 42
        case (.tenK, 45..<55):   absoluteCap = 60
        case (.tenK, _):         absoluteCap = 75
        // HM
        case (.halfMarathon, ..<35):   absoluteCap = 35
        case (.halfMarathon, 35..<45): absoluteCap = 55
        case (.halfMarathon, 45..<55): absoluteCap = 70
        case (.halfMarathon, _):       absoluteCap = 90
        // Maratona
        case (.marathon, ..<35):   absoluteCap = 45
        case (.marathon, 35..<45): absoluteCap = 65
        case (.marathon, 45..<55): absoluteCap = 85
        case (.marathon, _):       absoluteCap = 110
        default:                   absoluteCap = 100
        }

        return min(computed, absoluteCap)
    }
    
//    private func estimateBaseWeeklyKm(
//        daysPerWeek: Int,
//        vdot: Double,
//        distance: RaceDistance
//    ) -> Double {
//        let kmPerSession: Double
//        switch vdot {
//        case ..<35: kmPerSession = 7.0
//        case 35..<45: kmPerSession = 10.0
//        case 45..<55: kmPerSession = 13.0
//        default: kmPerSession = 16.0
//        }
//
//        let distanceFactor: Double
//        switch distance {
//        case .fiveK: distanceFactor = 0.8
//        case .tenK: distanceFactor = 0.9
//        case .halfMarathon: distanceFactor = 1.0
//        case .marathon: distanceFactor = 1.15
//        }
//
//        return Double(daysPerWeek) * kmPerSession * distanceFactor
//    }

    private func computeWeeklyVolume(
        weekIndex: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        baseKm: Double,
        prevKm: Double
    ) -> (Double, String) {

        let weekNum = weekIndex + 1
        var note = ""
        var kms: Double

        switch phase {
        case .base:
            /// Progressione con regola del 10% [1][8].
            /// Daniels suggerisce di restare allo stesso carico 3-4 settimane
            /// prima di aumentare; qui ogni 4a settimana è di scarico (-20%)
            /// come compromesso tra la regola del 10% e questo principio.
            if weekNum % 4 == 0 {
                kms = prevKm * 0.80
                note = "Settimana di scarico (↓20%): supercompensazione e adattamento. " +
                       "Fonte: principio di scarico [7], mantenimento [1]."
            } else {
                kms = min(prevKm * 1.10, prevKm + baseKm * 0.10)
                note = "Base aerobica: ↑max 10% volume. Nessun lavoro I in questa fase. " +
                       "Fonte: regola del 10% [1][8]."
            }

        case .build:
            /// In questa fase si introduce prima R (velocità pura, basso stress
            /// aerobico), poi T (soglia). L'I arriverà nella fase Peak.
            /// Daniels [1] cap. 10: "going from E running to R workouts is adding
            /// only a speed stress, with little being asked of the aerobic or
            /// lactate-clearance systems."
            if weekNum % 3 == 0 {
                kms = prevKm * 0.85
                note = "Micro-scarico nel blocco Build: volume -15%, qualità R+T mantenuta. " +
                       "Fonte: [1] principio manutenzione."
            } else {
                kms = min(prevKm * 1.08, baseKm * 1.38)
                note = "Build: R (velocità/economia) + T (soglia). " +
                       "Distribuzione ~80% bassa intensità, ~20% alta. Fonte: [1][4]."
            }

        case .peak:
            // Picco: massima qualità T + I + M. Il più impegnativo [1].
            kms = baseKm * 1.42
            note = "Picco: T + I + ritmo gara. Massimo stimolo fisiologico. " +
                   "Fonte: [1] Phase III (TQ), [2] Pfitzinger."

        case .taper:
            /// Taper: -40-60% volume, intensità invariata. Fonte: [6] Mujika.
            /// "Supercompensation is expected to peak during taper."
            let taperProgress = Double(totalWeeks - weekIndex) / Double(totalWeeks)
            let taperFactor = 0.60 - (0.20 * taperProgress)
            kms = baseKm * max(0.40, taperFactor)
            note = "TAPER: volume ↓40-60%, intensità invariata. Supercompensazione attesa. " +
                   "Fonte: Mujika & Padilla [6]."

        case .race:
            kms = baseKm * 0.30
            note = "Settimana di gara: solo riscaldamenti leggeri."
        }

        return (max(20, kms), note)
    }

    // MARK: - Generate Week Workouts

    private func generateWeekWorkouts( // swiftlint:disable:this function_body_length
        weekIndex: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        weekStartDate: Date,
        daysPerWeek: Int,
        weeklyKm: Double,
        paces: TrainingPaces,
        distance: RaceDistance,
        raceDate: Date,
        raceName: String,
        vdotGap: Double,
        targetPaceSecsPerKm: Double
    ) -> [Workout] {

        var workouts: [Workout] = []
        let calendar = Calendar.current

        let trainingDayIndices = selectTrainingDays(daysPerWeek: daysPerWeek)

        let weekStructure = buildWeekStructure(
            phase: phase,
            daysPerWeek: daysPerWeek,
            distance: distance,
            vdotGap: vdotGap,
            vdot: paces.vdot   // [FIX-C] passa il VDOT per adattare la struttura al livello
        )

        // [FIX] computeLongRunKm ora è phase-aware: calcola il target
        // del lungo in base alla fase e alla progressione interna, non solo
        // dal volume settimanale. Questo garantisce una curva di progressione
        // reale verso le distanze tipiche di gara.
        let longRunKm = computeLongRunKm(
            weeklyKm: weeklyKm,
            distance: distance,
            phase: phase,
            weekIndex: weekIndex,
            totalWeeks: totalWeeks,
            vdot: paces.vdot
        )
        let remainingKm = weeklyKm - longRunKm
        let otherSessionsCount = max(1, daysPerWeek - 1)
        let avgOtherKm = remainingKm / Double(otherSessionsCount)

        for (slotIndex, workoutType) in weekStructure.enumerated() {
            guard slotIndex < trainingDayIndices.count else { break }
            let dayOffset = trainingDayIndices[slotIndex]
            let workoutDate = calendar.date(
                byAdding: .day, value: dayOffset, to: weekStartDate
            )! // swiftlint:disable:this force_unwrapping

            let isRaceDay = calendar.isDate(workoutDate, inSameDayAs: raceDate)

            let workout: Workout
            if isRaceDay || (weekIndex == totalWeeks - 1 && slotIndex == weekStructure.count - 1) {
                workout = buildRaceWorkout(
                    date: raceDate,
                    raceName: raceName,
                    distance: distance,
                    targetPaceSecsPerKm: targetPaceSecsPerKm,
                    vdotGap: vdotGap,
                    week: weekIndex + 1,
                    day: dayOffset
                )
            } else {
                let kms = workoutType == .longRun ? longRunKm : avgOtherKm
                workout = buildWorkout(
                    type: workoutType,
                    date: workoutDate,
                    week: weekIndex + 1,
                    day: dayOffset,
                    kms: kms,
                    weeklyKm: weeklyKm,
                    paces: paces,
                    distance: distance
                )
            }
            workouts.append(workout)
        }

        // Giorni di riposo
        let allDays = Set(0..<7)
        let restDays = allDays.subtracting(Set(trainingDayIndices))
        for dayOffset in restDays.sorted() {
            let restDate = calendar.date(
                byAdding: .day, value: dayOffset, to: weekStartDate
            )! // swiftlint:disable:this force_unwrapping
            let rest = Workout(
                date: restDate,
                type: .rest,
                week: weekIndex + 1,
                dayOfWeek: dayOffset,
                title: "Riposo",
                description: "Riposo completo o camminata leggera. " +
                             "Parte integrante della supercompensazione.",
                distanceKm: nil,
                durationMinutes: nil,
                paceTarget: nil,
                paceTargetSecsPerKm: nil,
                structuredSets: nil,
                scientificRationale: "Il riposo è componente fondamentale della supercompensazione. " +
                                     "Fonte: Bompa & Haff [7].",
                rpe: "1",
                tss: 0
            )
            workouts.append(rest)
        }

        return workouts.sorted { $0.date < $1.date }
    }

    // MARK: - Day Selection

    private func selectTrainingDays(daysPerWeek: Int) -> [Int] {
        /// Distribuzione ottimale: evita back-to-back sessioni intense,
        /// garantisce recupero tra le sessioni di qualità.
        /// Fonte: [2] Pfitzinger – distribuzione settimanale.
        switch daysPerWeek {
        case 3: return [0, 2, 5]
        case 4: return [0, 2, 4, 6]
        case 5: return [0, 1, 3, 4, 6]
        case 6: return [0, 1, 2, 4, 5, 6]
        default: return [0, 2, 5]
        }
    }

    // MARK: - Week Structure

    /// La struttura settimanale rispecchia la progressione di Daniels [1]:
    ///
    ///  BASE  → E + hillRepeat + progression + L run.
    ///          Nessuna sessione I. Le ripetute in salita e le corse progressive
    ///          sono stimoli lievi compatibili con la Phase I di Daniels.
    ///
    ///  BUILD → R (Repetition) + T (Tempo) + L run.
    ///          Daniels introduce R prima di I perché aggiunge solo velocità.
    ///          T (soglia) si aggiunge in questa fase come secondo stimolo.
    ///          Nessuna I ancora.
    ///
    ///  PEAK  → T + I + M/R (ritmo specifico di gara) + L run.
    ///          Il più impegnativo. Daniels Phase III (TQ) e IV (FQ).
    ///
    ///  TAPER → T leggero + E + L run ridotto. Volume giù, qualità mantenuta [6].
    private func buildWeekStructure( // swiftlint:disable:this cyclomatic_complexity
        phase: TrainingPhase,
        daysPerWeek: Int,
        distance: RaceDistance,
        vdotGap: Double,
        vdot: Double        // [FIX-C] aggiunto per adattare la struttura al livello
    ) -> [WorkoutType] {

        // [FIX-C] I runner con VDOT < 35 (beginner) nella fase Base non fanno
        // hillRepeat: sostituiti con .easy o .progression per ridurre il rischio
        // infortuni e rispettare il principio di progressione graduale.
        // Daniels [1] cap. 10 Phase I: "mostly E running" — le colline sono
        // stimoli supplementari appropriati solo quando c'è già una base solida.
        // Soglia 35: corrisponde a ~30 min su 5K, livello recreational.
        let includeHills = vdot >= 35

        switch phase {
        case .base:
            // Fase Base: E puro + strides/colline + progressione + lungo.
            // Fonte: [1] cap. 10 Phase I – "mostly E running",
            // strides e supplemental. Nessun lavoro I.
            // Per beginner (VDOT < 35): solo E + progression, nessuna hillRepeat.
            switch daysPerWeek {
            case 3: return includeHills ? [.easy, .hillRepeat, .longRun]
                                        : [.easy, .progression, .longRun]
            case 4: return includeHills ? [.easy, .hillRepeat, .progression, .longRun]
                                        : [.easy, .easy, .progression, .longRun]
            case 5: return includeHills ? [.easy, .hillRepeat, .easy, .progression, .longRun]
                                        : [.easy, .easy, .easy, .progression, .longRun]
            case 6: return includeHills ? [.easy, .easy, .hillRepeat, .easy, .progression, .longRun]
                                        : [.easy, .easy, .easy, .easy, .progression, .longRun]
            default: return [.easy, .progression, .longRun]
            }

        case .build:
            // [FIX-3] Fase Build: R (velocità) + T (soglia) + lungo.
            // Daniels [1] cap. 10: "going from E running to R workouts is adding
            // only a speed stress" → R arriva PRIMA di T+I, non dopo.
            // T viene introdotto come secondo stimolo qualitativo.
            // Nessuna sessione I ancora: quella arriverà in Peak.
            switch daysPerWeek {
            case 3: return [.repetition, .tempo, .longRun]
            case 4: return [.easy, .repetition, .tempo, .longRun]
            case 5: return [.easy, .repetition, .easy, .tempo, .longRun]
            case 6: return [.easy, .repetition, .easy, .tempo, .easy, .longRun]
            default: return [.easy, .repetition, .tempo, .longRun]
            }

        case .peak:
            // Fase Peak: T + I + ritmo specifico + lungo. Il più impegnativo.
            // Fonte: [1] Phase III (TQ) e IV (FQ).
            // Per maratona/HM: M-pace run è più rilevante degli interval puri [2].
            // Per 5K/10K: interval a VO2max centrali [3][5].
            let specificWork: WorkoutType = (distance == .marathon || distance == .halfMarathon)
                ? .marPace
                : .interval
            // Se il gap VDOT è grande (>3), aggiungiamo più stimolo qualitativo.
            let secondQuality: WorkoutType = vdotGap > 3 ? .interval : .tempo
            switch daysPerWeek {
            case 3: return [.tempo, specificWork, .longRun]
            case 4: return [.tempo, specificWork, secondQuality, .longRun]
            case 5: return [.easy, .tempo, specificWork, secondQuality, .longRun]
            case 6: return [.easy, .tempo, .easy, specificWork, secondQuality, .longRun]
            default: return [.tempo, specificWork, .longRun]
            }

        case .taper:
            // Taper: volume giù, almeno una sessione T per mantenere lo stimolo
            // alla soglia. Fonte: [6] Mujika – "maintain training intensity".
            // Daniels [1] cap. 10 Phase IV: sessione T leggera nell'ultima settimana.
            switch daysPerWeek {
            case 3: return [.tempo, .easy, .longRun]
            case 4: return [.easy, .tempo, .easy, .longRun]
            case 5: return [.easy, .tempo, .easy, .easy, .longRun]
            case 6: return [.easy, .easy, .tempo, .easy, .easy, .longRun]
            default: return [.easy, .tempo, .easy]
            }

        case .race:
            return [.easy, .easy, .race]
        }
    }
    
    // MARK: - Long Run Computation

    // Il lungo è ora calcolato in base alla fase e alla progressione interna,
    // non solo dal volume settimanale. Questo garantisce una curva realistica:
    //   Maratona:  16 km (base inizio) → 28-32 km (peak fine)
    //   HM:        10 km (base inizio) → 19-22 km (peak fine)
    //   10K:        8 km (base inizio) → 15-18 km (peak fine)
    //   5K:         6 km (base inizio) → 11-14 km (peak fine)
    //
    // Per HM e maratona il target è phase-driven (non cappato dal volume
    // settimanale, che è troppo basso per vincolare il lungo in modo sensato).
    // Per 5K e 10K si applica anche il cap 25% del volume settimanale
    // perché il lungo non deve dominare il volume su distanze brevi.
    //
    // Il fattore VDOT scala il target: runner più lenti fanno lunghi
    // proporzionalmente più brevi (stessa intensità relativa, meno km assoluti).
    //
    // Fonte: Daniels [1] cap. 4 (25% weekly, 150 min cap),
    //        Pfitzinger [2] cap. 3 (progressione lungo in piani maratona).
    private func computeLongRunKm(
        weeklyKm: Double,
        distance: RaceDistance,
        phase: TrainingPhase,
        weekIndex: Int,
        totalWeeks: Int,
        vdot: Double
    ) -> Double {

        // Progressione interna alla fase (0.0 = prima settimana, 1.0 = ultima)
        // Calcolata approssimativamente dal weekIndex globale e dalla distribuzione fasi.
        let phaseFraction = phaseProgressionFraction(
            phase: phase, weekIndex: weekIndex, totalWeeks: totalWeeks
        )

        // Target per fase e distanza (km ideali indipendenti dal volume settimanale)
        let (lo, hi) = longRunPhaseRange(phase: phase, distance: distance)
        var target = lo + (hi - lo) * phaseFraction

        // Fattore VDOT: runner più lenti fanno lunghi proporzionalmente più brevi.
        // La stessa sessione richiede più tempo → il vincolo temporale di Daniels
        // (max 150 min) produce km assoluti minori per runner con VDOT basso.
        let vdotFactor: Double
        switch vdot {
        case ..<35:  vdotFactor = 0.75
        case 35..<45: vdotFactor = 0.87
        case 45..<55: vdotFactor = 1.00
        default:     vdotFactor = 1.08
        }
        target *= vdotFactor

        // Cap assoluto: limite temporale di Daniels [1] (~150 min).
        // 32 km ≈ 150 min a ~4:40/km (VDOT 50); scalato dal fattore VDOT sopra.
        let absoluteMax: Double
        switch distance {
        case .fiveK:        absoluteMax = 14
        case .tenK:         absoluteMax = 18
        case .halfMarathon: absoluteMax = 22
        case .marathon:     absoluteMax = 32
        }

        // Per 5K e 10K: il lungo non deve dominare il volume → cap 25% weekly.
        // Per HM e maratona: il target è phase-driven, il volume settimanale
        // è troppo basso per essere un vincolo sensato sul lungo.
        switch distance {
        case .fiveK, .tenK:
            target = min(target, weeklyKm * 0.25, absoluteMax)
        case .halfMarathon, .marathon:
            target = min(target, absoluteMax)
        }

        // Minimo: non scendere sotto l'80% del target minimo della fase.
        // Evita lunghi ridicolmente corti nelle prime settimane.
        let floor = lo * vdotFactor * 0.80
        return roundKm(max(target, floor))
    }

    /// Restituisce la fraction di avanzamento [0,1] all'interno della fase corrente,
    /// stimata dalla posizione globale nel piano e dalla distribuzione delle fasi.
    private func phaseProgressionFraction(
        phase: TrainingPhase,
        weekIndex: Int,
        totalWeeks: Int
    ) -> Double {
        // Stima la durata della fase dal piano corrente usando le stesse proporzioni
        // di buildPhaseStructure — senza ricostruire l'intero array.
        // Per semplicità usiamo il weekIndex normalizzato sul range della fase.
        // Questo è un'approssimazione: la precisione millimetrica non è necessaria
        // per la curva del lungo.
        let totalActive = max(1, totalWeeks - 1)  // escludi settimana gara
        let normalized = Double(weekIndex) / Double(totalActive)

        switch phase {
        case .base:
            // Base occupa i primi ~25-38% del piano
            return normalized / 0.35
        case .build:
            // Build occupa ~35-72% del piano
            return (normalized - 0.35) / 0.37
        case .peak:
            // Peak occupa ~72-90% del piano
            return (normalized - 0.72) / 0.18
        case .taper, .race:
            return 0.5   // taper: usa valore medio del range
        }
    }
    
    /// Range (min, max) km del lungo per fase e distanza gara.
    /// Fonte: Daniels [1] tavole piani cap. 15-16, Pfitzinger [2] cap. 3.
    private func longRunPhaseRange(
        phase: TrainingPhase,
        distance: RaceDistance
    ) -> (Double, Double) {
        switch (distance, phase) {
        // Maratona
        case (.marathon, .base):   return (16, 24)
        case (.marathon, .build):  return (22, 29)
        case (.marathon, .peak):   return (27, 32)
        case (.marathon, .taper):  return (16, 20)
        // Mezza maratona
        case (.halfMarathon, .base):   return (10, 16)
        case (.halfMarathon, .build):  return (14, 19)
        case (.halfMarathon, .peak):   return (18, 22)
        case (.halfMarathon, .taper):  return (10, 14)
        // 10K
        case (.tenK, .base):   return (8,  13)
        case (.tenK, .build):  return (12, 16)
        case (.tenK, .peak):   return (15, 18)
        case (.tenK, .taper):  return (8,  12)
        // 5K
        case (.fiveK, .base):   return (6,  10)
        case (.fiveK, .build):  return (8,  12)
        case (.fiveK, .peak):   return (11, 14)
        case (.fiveK, .taper):  return (6,  9)
        // Race week
        default: return (6, 8)
        }
    }
    
    // MARK: - Build Single Workout

    private func buildWorkout( // swiftlint:disable:this function_body_length
        type: WorkoutType,
        date: Date,
        week: Int,
        day: Int,
        kms: Double,
        weeklyKm: Double,
        paces: TrainingPaces,
        distance: RaceDistance
    ) -> Workout {

        switch type {
        case .easy:
            return Workout(
                date: date, type: .easy, week: week, dayOfWeek: day,
                title: "Corsa Facile",
                description: "Ritmo confortevole, conversazione possibile. " +
                             "Obiettivo: aerobica di base e recupero attivo.",
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: paces.easyFormatted,
                paceTargetSecsPerKm: paces.easyPaceSecsPerKm,
                structuredSets: nil,
                // [FIX-6] Non esistono zone di "recovery pace" separate in Daniels.
                // L'E-pace copre tutto il range di bassa intensità (59-74% VO2max).
                // Fonte: [1] cap. 4: "E is typically an intensity about 59 to 74
                // percent of O2max or about 65 to 79 percent of maximum heart rate."
                scientificRationale: "L'E running sviluppa la base aerobica, " +
                    "vascolarizzazione e resistenza all'infortunio. ~80% del volume " +
                    "settimanale a questa intensità. Fonte: [1] cap. 4, [4] Seiler.",
                rpe: "4-5",
                tss: kms * 40
            )

        case .longRun:
            let note = distance == .marathon
                ? "Ritmo uniforme, non accelerare negli ultimi km in allenamento."
                : "Non più veloce di \(paces.easyFormatted). Priorità: completare la distanza."
            return Workout(
                date: date, type: .longRun, week: week, dayOfWeek: day,
                title: "Lungo",
                description: "Corsa lunga a ritmo E. \(note)",
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: paces.easyFormatted,
                paceTargetSecsPerKm: paces.easyPaceSecsPerKm,
                structuredSets: nil,
                // [FIX-1] Cap al 25% del volume settimanale, max 150 min (cap Daniels).
                scientificRationale: "Il lungo stimola adattamenti aerobici e riserve " +
                    "di glicogeno. Limitato al 25% del volume settimanale (non 30-33%) " +
                    "e max 150 min per sessione. Fonte: [1] cap. 4.",
                rpe: "5-6",
                tss: kms * 55
            )

        case .tempo:
            // T-pace: 20 min continuati (Tempo Run) o cruise intervals.
            // Limite: max 10% del volume settimanale in una sessione [1].
            // [FIX-5] Intensità corretta: 85-88% VO2max / 88-92% FCmax (non 80-90%).
            let maxTempoKm = min(
                kms * 0.55,
                weeklyKm * TrainingPlanGenerator.maxThresholdFractionOfWeekly,
                distance == .marathon ? 14.0 : 10.0
            )
            let warmupKm = 2.0
            let cooldownKm = 2.0
            let mainKm = max(3.0, maxTempoKm - warmupKm - cooldownKm)
            let tempoKm = warmupKm + mainKm + cooldownKm
            return Workout(
                date: date, type: .tempo, week: week, dayOfWeek: day,
                title: "Tempo Run",
                description: "Ritmo soglia: 'comfortably hard'. " +
                             "Sforzo sostenibile per ~20 min continuati.",
                distanceKm: roundKm(tempoKm),
                durationMinutes: nil,
                paceTarget: paces.thresholdFormatted,
                paceTargetSecsPerKm: paces.thresholdPaceSecsPerKm,
                structuredSets: "2 km risc. E + \(Int(mainKm)) km a \(paces.thresholdFormatted) " +
                                "+ 2 km def. E",
                // [FIX-5] Intensità corretta: 85-88% VO2max / 88-92% FCmax.
                // La versione precedente indicava 80-90% FCmax (troppo basso).
                scientificRationale: "T-pace (85-88% VO2max / 88-92% FCmax) migliora " +
                    "la clearance del lattato e la soglia anaerobica. " +
                    "Max 10% volume settimanale per sessione. " +
                    "Fonte: [1] cap. 4 – T pace.",
                rpe: "7-8",
                tss: tempoKm * 80
            )

        case .interval:
            // I-pace: 95-100% VO2max. Work bout 3-5 min. Recupero attivo (jog).
            // Volume max: il minore tra 10K e 8% del volume settimanale [1].
            let maxIntervalKm = min(
                weeklyKm * TrainingPlanGenerator.maxIntervalFractionOfWeekly,
                TrainingPlanGenerator.maxIntervalKm
            )
            let sessionKm = min(kms * 0.80, maxIntervalKm)
            let structure = buildIntervalStructure(distance: distance, paces: paces)
            return Workout(
                date: date, type: .interval, week: week, dayOfWeek: day,
                title: "Interval Training",
                description: "Ripetute a VO2max (95-100%). Work bout 3-5 min, " +
                             "recupero attivo (jog) tra le ripetizioni.",
                distanceKm: roundKm(sessionKm),
                durationMinutes: nil,
                paceTarget: paces.intervalFormatted,
                paceTargetSecsPerKm: paces.intervalPaceSecsPerKm,
                structuredSets: structure,
                scientificRationale: "I-pace massimizza il tempo a VO2max, " +
                    "stimola gittata cardiaca e densità mitocondriale. " +
                    "Max il minore tra 10K e 8% volume settimanale per sessione. " +
                    "Fonte: [1] cap. 4, [3] Billat, [5] Laursen & Jenkins.",
                rpe: "8-9",
                tss: sessionKm * 100
            )

        case .repetition:
            // [FIX-2] NUOVO TIPO: R (Repetition) pace.
            // Daniels [1] cap. 4: "The primary purpose of R training is to improve
            // anaerobic power, speed, and economy of running."
            // Caratteristiche chiave:
            //   - Work bout MAX 2 minuti per singola ripetizione
            //   - Recupero COMPLETO (uguale o maggiore del lavoro, non attivo)
            //   - Volume sessione: max 5% del volume settimanale
            //   - Fase di introduzione: Build (prima delle I, aggiunge solo velocità)
            let maxRKm = weeklyKm * TrainingPlanGenerator.maxRepetitionFractionOfWeekly
            let sessionKm = min(kms * 0.70, maxRKm)
            let rStructure = buildRepetitionStructure(distance: distance, paces: paces)
            return Workout(
                date: date, type: .repetition, week: week, dayOfWeek: day,
                title: "Repetition Training",
                description: "Ripetute brevi a ritmo R (105-120% VDOT). " +
                             "Recupero completo tra le ripetizioni: non iniziare " +
                             "la prossima finché non sei pronto a correre con buona meccanica.",
                distanceKm: roundKm(sessionKm),
                durationMinutes: nil,
                paceTarget: paces.repetitionFormatted,
                paceTargetSecsPerKm: paces.repetitionPaceSecsPerKm,
                structuredSets: rStructure,
                // [FIX-2] Il recupero COMPLETO è fondamentale per le R:
                // Daniels: "In order to run fast, you have to be recovered enough
                // to run fast and with good technique."
                scientificRationale: "R-pace (105-120% VDOT) migliora velocità, " +
                    "economia di corsa e potenza anaerobica. Work bout max 2 min, " +
                    "recupero completo (jog uguale al lavoro). Max 5% volume settimanale. " +
                    "Introdotto prima delle I (aggiunge solo stimolo velocità). " +
                    "Fonte: [1] cap. 4 – Repetition training.",
                rpe: "8-9",
                tss: sessionKm * 90
            )

        case .recovery:
            // [FIX-6] Il tipo .recovery viene mantenuto per compatibilità con il
            // resto del codebase, ma è ora mappato su E-pace (non su una zona
            // di ritmo fittizia più lenta). Daniels non definisce una "recovery zone"
            // separata: usa semplicemente E-pace per tutto il range bassa intensità.
            return Workout(
                date: date, type: .recovery, week: week, dayOfWeek: day,
                title: "Corsa Facile (Recupero)",
                description: "Corsa molto leggera nell'intervallo basso dell'E-pace. " +
                             "Obiettivo: promuovere il recupero, non costruire fitness.",
                distanceKm: roundKm(max(4, kms * 0.65)),
                durationMinutes: nil,
                // [FIX-6] Usa easyPace (limite inferiore del range) invece di
                // un fantomatico recoveryPace non presente in Daniels.
                paceTarget: paces.easyFormatted + " (limite inf.)",
                paceTargetSecsPerKm: paces.easyPaceSecsPerKm,
                structuredSets: nil,
                scientificRationale: "Recupero attivo nella zona E (59-74% VO2max). " +
                    "Daniels non definisce una recovery zone separata: E-pace copre " +
                    "tutto il range bassa intensità. Fonte: [1] cap. 4.",
                rpe: "3-4",
                tss: kms * 28
            )

        case .progression:
            let prog = buildProgressionDescription(kms: kms, paces: paces)
            return Workout(
                date: date, type: .progression, week: week, dayOfWeek: day,
                title: "Corsa Progressiva",
                description: "Inizia a E-pace, aumenta gradualmente fino a T-pace.",
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: "Da \(paces.easyFormatted) a \(paces.thresholdFormatted)",
                paceTargetSecsPerKm: paces.thresholdPaceSecsPerKm,
                structuredSets: prog,
                scientificRationale: "La progressiva abitua a correre a ritmi crescenti, " +
                    "allenando sia la base aerobica che la soglia. " +
                    "Compatibile con Phase I di Daniels (stimolo leggero). Fonte: [2].",
                rpe: "5-7",
                tss: kms * 65
            )

        case .hillRepeat:
            let reps = (distance == .marathon || distance == .halfMarathon) ? "8-10" : "6-8"
            let hillLen = distance == .marathon ? "200m" : "150m"
            // [FIX-B] Rimosso max(6, ...) hardcoded che forzava 6 km indipendentemente
            // dal livello del runner. Il minimo di 4 km garantisce solo lo spazio
            // minimo per riscaldamento (2 km) + almeno 1-2 ripetute + defaticamento.
            // Fonte: struttura sessione colline in Pfitzinger [2].
            let hillSessionKm = roundKm(max(4, kms * 0.9))
            return Workout(
                date: date, type: .hillRepeat, week: week, dayOfWeek: day,
                title: "Ripetute in Salita",
                description: "Collinare ad alta intensità. Recupero in discesa lenta. " +
                             "Usate nella fase Base come stimolo di forza-velocità " +
                             "a basso impatto articolare.",
                distanceKm: hillSessionKm,
                durationMinutes: nil,
                paceTarget: "Sforzo 95% in salita",
                paceTargetSecsPerKm: nil,
                structuredSets: "2 km risc. E + \(reps)×\(hillLen) salita (5-8%) + " +
                                "recupero discesa + 2 km def. E",
                scientificRationale: "Le ripetute in salita sviluppano forza specifica " +
                    "e riducono il rischio infortuni rispetto agli interval in piano. " +
                    "Compatibili con Phase I di Daniels. Fonte: [2] Pfitzinger.",
                rpe: "8",
                tss: kms * 85
            )

        case .marPace:
            let mpKm = distance == .marathon
                ? min(kms * 0.80, 28.0)
                : min(kms * 0.80, 16.0)
            let mpSection = max(5, mpKm - 4)
            return Workout(
                date: date, type: .marPace, week: week, dayOfWeek: day,
                title: "Ritmo Gara",
                description: "Sezione centrale al ritmo gara target. " +
                             "Adattamento fisico e mentale al passo specifico.",
                distanceKm: roundKm(mpKm),
                durationMinutes: nil,
                paceTarget: distance == .marathon
                    ? paces.mpFormatted
                    : paces.thresholdFormatted,
                paceTargetSecsPerKm: distance == .marathon
                    ? paces.marathonPaceSecsPerKm
                    : paces.thresholdPaceSecsPerKm,
                structuredSets: "2 km risc. E + \(Int(mpSection)) km a ritmo gara + 2 km def. E",
                scientificRationale: "Il lavoro al ritmo gara ottimizza l'economia di corsa " +
                    "e la gestione del passo. Centrale in Phase III/IV per maratona e HM. " +
                    "Fonte: [1] cap. 4 M-pace, [2] Pfitzinger.",
                rpe: "7",
                tss: mpKm * 75
            )

        case .rest, .race:
            return buildRaceWorkout(
                date: date,
                raceName: "Gara",
                distance: .fiveK,
                targetPaceSecsPerKm: paces.thresholdPaceSecsPerKm,
                vdotGap: 0,
                week: week, day: day
            )
        }
    }

    // MARK: - Interval Structure Builder

    private func buildIntervalStructure(
        distance: RaceDistance,
        paces: TrainingPaces
    ) -> String {
        // Work bout: 3-5 minuti ideali per garantire tempo a VO2max.
        // Recupero attivo (jog): circa uguale al lavoro.
        // Fonte: [1] cap. 4, [3] Billat.
        switch distance {
        case .fiveK:
            return "2 km risc. + 6×600m a \(paces.intervalFormatted) (rec. 2' jog) + 1 km def."
        case .tenK:
            return "2 km risc. + 5×1000m a \(paces.intervalFormatted) (rec. 2'30\" jog) + 1 km def."
        case .halfMarathon:
            return "2 km risc. + 4×1200m a \(paces.intervalFormatted) (rec. 3' jog) + 1 km def."
        case .marathon:
            return "2 km risc. + 4×1600m a \(paces.intervalFormatted) (rec. 3' jog) + 2 km def."
        }
    }

    // MARK: - Repetition Structure Builder

    /// Struttura R (Repetition) secondo Daniels [1] cap. 4:
    /// - Work bout max 2 minuti (200m, 300m, 400m, max 600-800m per VDOT alti)
    /// - Recupero COMPLETO: jog uguale alla distanza della ripetuta (es. 400R → 400 jog)
    /// - Scopo: velocità e economia, NON stress aerobico
    private func buildRepetitionStructure(
        distance: RaceDistance,
        paces: TrainingPaces
    ) -> String {
        switch distance {
        case .fiveK:
            // 5K: 200m e 400m R con recupero completo.
            return "2 km risc. E + 4×200m R a \(paces.repetitionFormatted) " +
                   "(rec. 200m jog) + 4×400m R (rec. 400m jog) + 1 km def. E"
        case .tenK:
            return "2 km risc. E + 3×200m R a \(paces.repetitionFormatted) " +
                   "(rec. 200m jog) + 5×400m R (rec. 400m jog) + 1 km def. E"
        case .halfMarathon:
            // Per HM e maratona le R sono meno centrali ma utili per economia.
            return "2 km risc. E + 6×300m R a \(paces.repetitionFormatted) " +
                   "(rec. 300m jog) + 2×200m R (rec. 200m jog) + 1 km def. E"
        case .marathon:
            return "2 km risc. E + 8×200m R a \(paces.repetitionFormatted) " +
                   "(rec. 200m jog) + 2 km def. E"
        }
    }

    // MARK: - Progression Description

    private func buildProgressionDescription(
        kms: Double,
        paces: TrainingPaces
    ) -> String {
        let third = max(1, Int(kms / 3))
        return "Km 1-\(third): \(paces.easyFormatted) | " +
               "Km \(third+1)-\(third*2): \(paces.mpFormatted) | " +
               "Km \(third*2+1)+: \(paces.thresholdFormatted)"
    }

    // MARK: - Race Workout

    private func buildRaceWorkout(
        date: Date,
        raceName: String,
        distance: RaceDistance,
        targetPaceSecsPerKm: Double,
        vdotGap: Double,
        week: Int,
        day: Int
    ) -> Workout {
        let mins = Int(targetPaceSecsPerKm) / 60
        let secs = Int(targetPaceSecsPerKm) % 60
        let racePaceFormatted = String(format: "%d:%02d /km", mins, secs)

        let description = GoalFeasibility.from(vdotGap: vdotGap).raceDescription

        return Workout(
            date: date, type: .race, week: week, dayOfWeek: day,
            title: raceName,  // sfSymbol "trophy" già mostrato da WorkoutBadge
            description: description,
            distanceKm: distance.meters / 1000,
            durationMinutes: nil,
            paceTarget: racePaceFormatted,
            paceTargetSecsPerKm: targetPaceSecsPerKm,
            structuredSets: nil,
            scientificRationale: "Gara: culmine del ciclo di allenamento.",
            rpe: "9-10",
            tss: 150
        )
    }

    // MARK: - Helpers

    private func roundKm(_ kms: Double) -> Double {
        (kms * 2).rounded() / 2
    }

    private func buildFitnessGapString(
        estimatedCurrent: Double,
        target: Double,
        vdotCurrent: Double,
        vdotTarget: Double
    ) -> String {
        let vdotGap = vdotTarget - vdotCurrent
        let feasibility = GoalFeasibility.from(vdotGap: vdotGap)

        let diffSecs = target - estimatedCurrent
        let absDiff = abs(Int(diffSecs))
        let mins = absDiff / 60
        let secs = absDiff % 60
        let direction = diffSecs > 0 ? "più lento" : "più veloce"

        return "VDOT attuale: \(String(format: "%.1f", vdotCurrent)) → " +
               "VDOT richiesto: \(String(format: "%.1f", vdotTarget)). " +
               "Tempo stimato attuale: \(formatTime(estimatedCurrent)). " +
               "Il target è \(String(format: "%d:%02d", mins, secs)) \(direction). " +
               "\n\(feasibility.label)"
    }

    private func formatTime(_ seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        let sec = Int(seconds) % 60
        if hrs > 0 { return String(format: "%d:%02d:%02d", hrs, min, sec) }
        return String(format: "%d:%02d", min, sec)
    }

    // MARK: - Scientific Sources

    private func scientificSources() -> [String] {
        [
            "[1] Daniels J. (2022). Daniels' Running Formula (4th ed.). Human Kinetics.",
            "[2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.",
            "[3] Billat V. (2001). Interval Training for Performance. Sports Medicine, 31(1), 13-31.",
            "[4] Seiler S., Kjerland G.Ø. (2006). Quantifying training intensity distribution " +
                "in elite endurance athletes. Scand. J. Med. Sci. Sports, 16(1), 49-56.",
            "[5] Laursen P.B., Jenkins D.G. (2002). The Scientific Basis for High-Intensity " +
                "Interval Training. Sports Medicine, 32(1), 53-73.",
            "[6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering " +
                "strategies. Medicine & Science in Sports & Exercise, 35(7), 1182-1187.",
            "[7] Bompa T., Haff G. (2009). Periodization: Theory and Methodology of Training " +
                "(5th ed.). Human Kinetics.",
            "[8] Galloway J. (2010). Running Until You're 100. Meyer & Meyer Sport."
        ]
    }
}
