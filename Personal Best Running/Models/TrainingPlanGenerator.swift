import Foundation

// MARK: - Training Plan Generator
//
// ============================================================
// FONTI SCIENTIFICHE
// ============================================================
//
// [1] Daniels J. (2022). Daniels' Running Formula (4th ed.). Human Kinetics.
//     → VDOT system, pace zones (E/M/T/I/R), long run rules, phase structure,
//       weekly volume limits, taper, sex-neutrality of VDOT
//
// [2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.
//     → Distribuzione volume settimanale, sessioni specifiche maratona/HM
//
// [3] Billat V. (2001). Interval Training for Performance. Sports Medicine, 31(1), 13-31.
//     → Interval training a VO2max, durata ripetizioni, recupero
//
// [4] Seiler S., Kjerland G.Ø. (2006). Quantifying training intensity distribution
//     in elite endurance athletes. Scand. J. Med. Sci. Sports, 16(1), 49-56.
//     → Distribuzione polarizzata: ~80% bassa intensità, ~20% alta intensità
//     NOTA: Seiler descrive un pattern empirico osservato negli élite, non un
//     modello prescrittivo che sostituisce la struttura per fasi di Daniels.
//     Nel codice è usato come guida per bilanciare i tipi di workout nella settimana.
//
// [5] Laursen P.B., Jenkins D.G. (2002). The Scientific Basis for High-Intensity
//     Interval Training. Sports Medicine, 32(1), 53-73.
//     → Adattamenti fisiologici all'HIIT (VO2max, capillarizzazione)
//
// [6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering
//     strategies. Medicine & Science in Sports & Exercise, 35(7), 1182-1187.
//     → Taper: riduzione 40-60% volume, mantenimento intensità
//
// [7] Bompa T., Haff G. (2009). Periodization: Theory and Methodology of Training
//     (5th ed.). Human Kinetics.
//     → Periodizzazione in macrocicli (preparazione generale → speciale → competitiva)
//     NOTA: la nomenclatura Base/Build/Peak/Taper è compatibile con Bompa.
//     Il contenuto delle fasi (quale tipo di allenamento va in quale fase) segue però
//     Daniels [1] (Phase I→E+strides, Phase II→R, Phase III→T+I, Phase IV→picco).
//
// [8] Galloway J. (2010). Running Until You're 100. Meyer & Meyer Sport.
//     → Progressione conservativa (regola del 10%)
//
// ============================================================
// CORREZIONI RISPETTO ALLA VERSIONE PRECEDENTE
// ============================================================
//
// [FIX-1] LONG RUN CAP: 25% (non 33%)
//   Daniels [1] cap. 4: "I like to limit any single L run to no more than
//   25 percent of weekly mileage". In più, limite assoluto di 150 minuti
//   (2h30') per il lungo anche in maratona. Il precedente 33% non era
//   supportato da nessuna delle fonti citate.
//
// [FIX-2] TIPO R (REPETITION) AGGIUNTO
//   Daniels [1] cap. 4 dedica un'intera sezione alle R (Repetition) pace runs:
//   - Scopo primario: velocità, economia di corsa, potenza anaerobica
//   - Work bout: MAX 2 minuti per singola ripetizione
//   - Recupero: COMPLETO, uguale o maggiore del lavoro (non attivo come nelle I)
//   - Volume sessione: max 5% del volume settimanale (vs 8% per le I)
//   - Fase: Daniels le introduce in Phase II (prima delle I), perché
//     aggiungono solo lo stimolo velocità senza stress aerobico aggiuntivo.
//   Il tipo era completamente assente nella versione precedente.
//
// [FIX-3] SEQUENZA DELLE FASI CORRETTA
//   Daniels [1] cap. 10: Phase I (E + strides) → Phase II (R) → Phase III (T+I)
//   → Phase IV (picco con tutto).
//   La versione precedente introduceva I (interval) nella fase Build, saltando
//   il gradino R. Ora:
//   - Base  → E puro, hillRepeat leggere, progressione (corrispondente a Phase I)
//   - Build → R + T (corrispondente a Phase II/III di Daniels)
//   - Peak  → T + I + M (Phase III/IV di Daniels)
//   - Taper → volume ridotto, mantenimento qualità [6]
//
// [FIX-4] FATTORE CORRETTIVO SESSO RIMOSSO DAL VDOT
//   Daniels [1] cap. 5: "The higher VDOT value is associated with the better
//   runner, regardless of age or sex, simply because VDOT represents
//   performance in the first place."
//   Il VDOT è già normalizzato sulla performance individuale: una donna con
//   VDOT 55 e un uomo con VDOT 55 si allenano agli stessi ritmi. Il fattore
//   0.96 applicato al VDOT nella versione precedente era contraddetto
//   esplicitamente dal testo. Daniels usa tabelle VDOT unificate per sesso.
//   NOTA: il fattore di correzione rimane nel modello RunnerSex (per compatibilità
//   con il resto del codice), ma non viene più applicato nel generatore.
//
// [FIX-5] INTENSITÀ FCMAX TEMPO RUN CORRETTA
//   Daniels [1] cap. 4: T pace = 85-88% VO2max / 88-92% FCmax (atleti allenati).
//   La versione precedente usava "80-90% FCmax" — il limite inferiore era troppo
//   basso (coincide con M-pace). Corretto a "88-92% FCmax".
//
// [FIX-6] RECOVERY COME CATEGORIA SEPARATA RIMOSSA
//   Daniels non definisce una zona "recovery" con ritmo proprio distinto dall'Easy.
//   Usa semplicemente E-pace per tutto il continuum bassa intensità.
//   I giorni di recupero attivo sono ora gestiti come E runs con distanza ridotta,
//   non come una zona di ritmo artificialmente più lenta.
//   Bompa [7] descrive il recupero attivo come principio (microciclo leggero),
//   non come zona di ritmo autonoma.

class TrainingPlanGenerator { // swiftlint:disable:this type_body_length

    // MARK: - Costanti basate su Daniels [1]

    // Regola del 10%: non aumentare volume settimanale >10% rispetto alla settimana
    // precedente. Fonte: [1] cap. 2, [8] Galloway.
    // NOTA: Daniels suggerisce anche di restare allo stesso carico 3-4 settimane
    // prima di aumentare. Qui applichiamo l'aumento massimo settimanale come
    // limite superiore, con settimane di scarico ogni 3-4 settimane.
    static let maxWeeklyVolumeIncreasePercent: Double = 0.10

    // Volume massimo di I-pace in una singola sessione: il minore tra 10K e 8%
    // del volume settimanale. Fonte: [1] cap. 4.
    static let maxIntervalFractionOfWeekly: Double = 0.08
    static let maxIntervalKm: Double = 10.0

    // Volume massimo di R-pace in una singola sessione: 5% del volume settimanale.
    // Fonte: [1] cap. 4 (R è più intenso dell'I ma i work bout sono brevissimi,
    // il limite è conservativo per non compromettere il recupero).
    static let maxRepetitionFractionOfWeekly: Double = 0.05

    // Volume massimo T-pace in una singola sessione: 10% del volume settimanale.
    // Fonte: [1] cap. 4: "not totaling more than 10 percent of your weekly mileage".
    static let maxThresholdFractionOfWeekly: Double = 0.10

    // MARK: - Generate Plan

    func generate(input: TrainingPlanInput) -> TrainingPlan { // swiftlint:disable:this function_body_length
        let calendar = Calendar.current
        let today = Date()

        // Calcola VDOT corrente dalla performance attuale
        let currentVDOT = VDOTCalculator.calculate(
            timeInSeconds: input.currentPerformance.time,
            distanceMeters: input.currentPerformance.distance.meters
        )

        // [FIX-4] Il VDOT è già sex-neutral per definizione di Daniels [1] cap. 5.
        // Non applichiamo più il fattore 0.96 per le donne: una runner con VDOT 50
        // si allena agli stessi ritmi di un runner con VDOT 50, indipendentemente
        // dal sesso. Il VDOT riflette già la performance individuale reale.
        // Fonte: "The higher VDOT value is associated with the better runner,
        // regardless of age or sex" — Daniels [1] cap. 5.
        let normalizedVDOT = currentVDOT

        // Calcola ritmi di allenamento dal VDOT corrente (senza correzione sesso)
        let paces = VDOTCalculator.trainingPaces(vdot: normalizedVDOT)

        // Tempo stimato con VDOT attuale sulla distanza target. serve per fitnessGap e estimatedRaceTime nel TrainingPlan
        let estimatedCurrent = VDOTCalculator.predictRaceTime(vdot: normalizedVDOT, distance: input.raceDistance)

        let targetPaceSecsPerKm = input.targetTime / input.raceDistance.meters * 1000
        
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
                targetPaceSecsPerKm: targetPaceSecsPerKm
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
            fitnessGap: fitnessGap
        )
    }

    // MARK: - Phase Structure

    // [FIX-3] La struttura delle fasi ora rispecchia la logica di Daniels [1] cap. 10:
    //
    //  Phase I  (Base)  → E running + strides + hillRepeat leggere + progressioni.
    //                     "Mostly E running" – nessun lavoro I pesante.
    //  Phase II (Build) → Introduzione R (Repetition): si aggiunge solo lo stimolo
    //                     velocità. Daniels porta R prima di T+I perché è uno stress
    //                     aggiuntivo minore rispetto all'I. Si introduce anche T (Tempo).
    //  Phase III (Peak) → Massima qualità: T + I + M. Il più impegnativo. Fonte: [1].
    //  Taper            → Volume -40-60%, intensità mantenuta. Fonte: [6] Mujika.
    //  Race             → Settimana di gara.
    //
    // I nomi Base/Build/Peak/Taper sono compatibili con la periodizzazione di Bompa [7].
    private func buildPhaseStructure(
        totalWeeks: Int,
        distance: RaceDistance
    ) -> [TrainingPhase] {

        // Proporzioni fasi per distanza gara.
        // Maratona: base più lunga (più volume aerobico necessario, meno velocità pura).
        // 5K: base più corta, più picco (velocità e VO2max centrali).
        // Fonte: [1] cap. 10 (distribuzione fasi), [2] Pfitzinger (maratona).
        
        // swiftlint:disable:next large_tuple
        let phaseRatios: (base: Double, build: Double, peak: Double, taper: Double)
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
        let kmPerSession: Double
        switch vdot {
        case ..<35: kmPerSession = 7.0
        case 35..<45: kmPerSession = 10.0
        case 45..<55: kmPerSession = 13.0
        default: kmPerSession = 16.0
        }

        let distanceFactor: Double
        switch distance {
        case .fiveK: distanceFactor = 0.8
        case .tenK: distanceFactor = 0.9
        case .halfMarathon: distanceFactor = 1.0
        case .marathon: distanceFactor = 1.15
        }

        return Double(daysPerWeek) * kmPerSession * distanceFactor
    }

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
            // Progressione con regola del 10% [1][8].
            // Daniels suggerisce di restare allo stesso carico 3-4 settimane
            // prima di aumentare; qui ogni 4a settimana è di scarico (-20%)
            // come compromesso tra la regola del 10% e questo principio.
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
            // [FIX-3] In questa fase si introduce prima R (velocità pura, basso stress
            // aerobico), poi T (soglia). L'I arriverà nella fase Peak.
            // Daniels [1] cap. 10: "going from E running to R workouts is adding
            // only a speed stress, with little being asked of the aerobic or
            // lactate-clearance systems."
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
            // Taper: -40-60% volume, intensità invariata. Fonte: [6] Mujika.
            // "Supercompensation is expected to peak during taper."
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
            vdotGap: vdotGap
        )

        let longRunKm = computeLongRunKm(weeklyKm: weeklyKm, distance: distance)
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
        // Distribuzione ottimale: evita back-to-back sessioni intense,
        // garantisce recupero tra le sessioni di qualità.
        // Fonte: [2] Pfitzinger – distribuzione settimanale.
        switch daysPerWeek {
        case 3: return [0, 2, 5]
        case 4: return [0, 2, 4, 6]
        case 5: return [0, 1, 3, 4, 6]
        case 6: return [0, 1, 2, 4, 5, 6]
        default: return [0, 2, 5]
        }
    }

    // MARK: - Week Structure

    // [FIX-3] La struttura settimanale ora rispecchia la progressione di Daniels [1]:
    //
    //  BASE  → E + hillRepeat + progression + L run.
    //          Nessuna sessione I. Le ripetute in salita e le corse progressive
    //          sono stimoli lievi compatibili con la Phase I di Daniels.
    //
    //  BUILD → R (Repetition) + T (Tempo) + L run.
    //          Daniels introduce R prima di I perché aggiunge solo velocità.
    //          T (soglia) si aggiunge in questa fase come secondo stimolo.
    //          Nessuna I ancora.
    //
    //  PEAK  → T + I + M/R (ritmo specifico di gara) + L run.
    //          Il più impegnativo. Daniels Phase III (TQ) e IV (FQ).
    //
    //  TAPER → T leggero + E + L run ridotto. Volume giù, qualità mantenuta [6].
    private func buildWeekStructure( // swiftlint:disable:this cyclomatic_complexity
        phase: TrainingPhase,
        daysPerWeek: Int,
        distance: RaceDistance,
        vdotGap: Double
    ) -> [WorkoutType] {

        switch phase {
        case .base:
            // Fase Base: E puro + strides/colline + progressione + lungo.
            // Fonte: [1] cap. 10 Phase I – "mostly E running",
            // strides e supplemental. Nessun lavoro I.
            switch daysPerWeek {
            case 3: return [.easy, .hillRepeat, .longRun]
            case 4: return [.easy, .hillRepeat, .progression, .longRun]
            case 5: return [.easy, .hillRepeat, .easy, .progression, .longRun]
            case 6: return [.easy, .easy, .hillRepeat, .easy, .progression, .longRun]
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

    // [FIX-1] Cap al 25% del volume settimanale (non 33%).
    // Fonte: [1] cap. 4: "I like to limit any single L run to no more than
    // 25 percent of weekly mileage."
    // Secondo vincolo: limite assoluto di tempo ~150 minuti (2h30') anche per
    // maratona. Daniels: "I also suggest that your longest steady run be
    // 150 minutes (2.5 hours), even if preparing for a marathon."
    // Qui il limite è espresso in km, assumendo ~5:30-6:00 min/km per runner
    // intermedi (150 min ≈ 25-27 km per un runner con VDOT 45-50).
    // Il limite assoluto in km rispecchia questa soglia temporale approssimativa.
    private func computeLongRunKm(weeklyKm: Double, distance: RaceDistance) -> Double {
        // [FIX-1] 25% invece del precedente 33%
        let maxFractionOfWeekly = weeklyKm * 0.25

        // Limite assoluto basato sul vincolo temporale di Daniels [1]:
        // ~150 minuti di corsa (≈25-30 km per runner di livello intermedio).
        // Per 5K e 10K il lungo non supera mai distanze sproporzionate rispetto
        // alla gara obiettivo.
        let absoluteMax: Double
        switch distance {
        case .fiveK:        absoluteMax = 14   // long run non fondamentale per 5K
        case .tenK:         absoluteMax = 18
        case .halfMarathon: absoluteMax = 22
        case .marathon:     absoluteMax = 30   // ≈150 min a ~5:00/km, cap Daniels [1]
        }

        return min(maxFractionOfWeekly, absoluteMax)
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
                title: "Ripetute",
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
            return Workout(
                date: date, type: .hillRepeat, week: week, dayOfWeek: day,
                title: "Ripetute in Salita",
                description: "Colline ad alta intensità. Recupero in discesa lenta. " +
                             "Usate nella fase Base come stimolo di forza-velocità " +
                             "a basso impatto articolare.",
                distanceKm: roundKm(max(6, kms * 0.9)),
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

    // [FIX-2] Struttura R (Repetition) secondo Daniels [1] cap. 4:
    // - Work bout max 2 minuti (200m, 300m, 400m, max 600-800m per VDOT alti)
    // - Recupero COMPLETO: jog uguale alla distanza della ripetuta (es. 400R → 400 jog)
    // - Scopo: velocità e economia, NON stress aerobico
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

        let description: String
        switch vdotGap {
        case ..<(-5):
            description = "Giorno di gara! Il tuo obiettivo è molto conservativo rispetto " +
                "alla forma attuale: potresti fare molto meglio. Parti controllato."
        case -5..<(-2):
            description = "Giorno di gara! Obiettivo prudente rispetto alla forma attuale. " +
                "Ottima base per un risultato solido senza rischi."
        case -2..<2:
            description = "Giorno di gara! Obiettivo allineato alla forma attuale. " +
                "Esegui il piano di gara: il lavoro fatto lo supporta."
        case 2..<5:
            description = "Giorno di gara! Obiettivo ambizioso rispetto alla forma di partenza. " +
                "Se il piano è andato bene, puoi farcela. Parti cauto nei primi km."
        case 5..<10:
            description = "Giorno di gara! Obiettivo molto sfidante. " +
                "Corri al meglio della tua condizione attuale."
        default:
            description = "Giorno di gara! L'obiettivo era molto oltre la forma di partenza. " +
                "Corri al tuo ritmo stimato e usa questa gara come esperienza."
        }

        return Workout(
            date: date, type: .race, week: week, dayOfWeek: day,
            title: "🏆 \(raceName)",
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
        let diffSecs = target - estimatedCurrent
        let absDiff = abs(Int(diffSecs))
        let mins = absDiff / 60
        let secs = absDiff % 60
        let direction = diffSecs > 0 ? "più lento" : "più veloce"

        let feasibility: String
        if diffSecs >= 60 {
            feasibility = "Obiettivo conservativo ✅"
        } else if diffSecs > 0 {
            feasibility = "Obiettivo alla portata ✅"
        } else if abs(vdotTarget - vdotCurrent) < 5 {
            feasibility = "Obiettivo realistico ✅"
        } else if abs(vdotTarget - vdotCurrent) < 10 {
            feasibility = "Obiettivo ambizioso ⚠️"
        } else {
            feasibility = "Obiettivo molto sfidante❗"
        }

        return "VDOT attuale: \(String(format: "%.1f", vdotCurrent)) → " +
               "VDOT richiesto: \(String(format: "%.1f", vdotTarget)). " +
               "Tempo stimato attuale: \(formatTime(estimatedCurrent)). " +
               "Il target è \(String(format: "%d:%02d", mins, secs)) \(direction). " +
               "\(feasibility)"
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
