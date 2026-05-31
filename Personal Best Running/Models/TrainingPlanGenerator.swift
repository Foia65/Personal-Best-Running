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
       // let calendar = Calendar.current
         var calendar = Calendar.current
         calendar.firstWeekday = 2  // 2 = lunedì — iOS usa domenica come default
         let today = Date()

        // Calcola VDOT corrente dalla performance attuale
        let currentVDOT = VDOTCalculator.calculate(
            timeInSeconds: input.currentPerformance.time,
            distanceMeters: input.currentPerformance.distance.meters
        )

        // VDOT è sex-neutral per definizione [1] cap. 5: nessuna correzione necessaria.
        let normalizedVDOT = currentVDOT

        // Calcola ritmi di allenamento dal VDOT corrente (senza correzione sesso)
        let paces = VDOTCalculator.trainingPaces(vdot: normalizedVDOT)

        // Tempo stimato con VDOT attuale sulla distanza target
        let estimatedCurrent = VDOTCalculator.predictRaceTime(
            vdot: normalizedVDOT,
            distance: input.raceDistance
        )
        // Usa il tempo TARGET dichiarato, non la stima dalla forma attuale:
        // il passo gara mostrato deve riflettere l'obiettivo del runner.
        let targetPaceSecsPerKm = input.targetTime / input.raceDistance.meters * 1000

        // VDOT richiesto per il tempo target
        let targetVDOT = VDOTCalculator.calculate(
            timeInSeconds: input.targetTime,
            distanceMeters: input.raceDistance.meters
        )
        let vdotGap = targetVDOT - normalizedVDOT
        // Numero di settimane disponibili
        let rawWeeks = calendar.dateComponents(
            [.weekOfYear], from: today, to: input.raceDate
        ).weekOfYear ?? 12
        let totalWeeks = min(input.raceDistance.maxPlanWeeks, max(12, rawWeeks))

        // Aggancia planStartDate al lunedì della sua settimana.
        // Senza questo, l'indice 0 non corrisponde sempre a lunedì
        // (es. se rawStartDate cade a mercoledì, dayOfWeek 0 sarebbe mercoledì).
        let rawStartDate = calendar.date(
            byAdding: .weekOfYear, value: -totalWeeks, to: input.raceDate
        )! // swiftlint:disable:this force_unwrapping

        // Con firstWeekday=2 (lunedì), .weekday restituisce 1=lun…7=dom.
        // daysFromMonday è lo shift da sottrarre per tornare al lunedì.
        let weekdayComponent = calendar.component(.weekday, from: rawStartDate)
        let daysFromMonday = (weekdayComponent - calendar.firstWeekday + 7) % 7
        let planStartDate = calendar.date(
            byAdding: .day, value: -daysFromMonday, to: rawStartDate
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

            let (weekKm, weekNoteKind) = computeWeeklyVolume(
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
                weeklyNote: weekNoteKind.localizedText(locale: Locale(identifier: "it")),
                weeklyNoteKind: weekNoteKind
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
            vdotCurrent: normalizedVDOT,
            vdotTarget: targetVDOT,
            feasibility: GoalFeasibility.from(vdotGap: vdotGap)
        )
    }

    // MARK: - Phase Structure

    /// La struttura delle fasi  rispecchia la logica di Daniels [1] cap. 10:
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
        case .tenK:
            phaseRatios = (0.28, 0.38, 0.24, 0.10)
        case .halfMarathon:
            phaseRatios = (0.33, 0.37, 0.20, 0.10)
        case .marathon:
            phaseRatios = (0.38, 0.35, 0.17, 0.10)
        case .fiveK:  // non distanza target, ma richiesto per exhaustiveness
            phaseRatios = (0.25, 0.38, 0.27, 0.10)
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

    private func estimateBaseWeeklyKm( // swiftlint:disable:this cyclomatic_complexity
        daysPerWeek: Int,
        vdot: Double,
        distance: RaceDistance
    ) -> Double {

        // Km per sessione base per fascia VDOT — valori calibrati sui piani
        // Daniels [1] cap. 15-16 e Pfitzinger [2] cap. 2-3.
        // Il volume di picco sarà base × 1.42 (v. computeWeeklyVolume).
        let kmPerSession: Double
        switch vdot {
        case ..<35: kmPerSession = 6.0    // beginner: sessioni brevi, adattamento graduale
        case 35..<45: kmPerSession = 10.0 // recreational: ~10 km/sessione base
        case 45..<55: kmPerSession = 14.0 // intermediate
        default: kmPerSession = 18.0      // advanced
        }

        // Il fattore distanza amplifica il volume per distanze più lunghe.
        // La maratona richiede un volume base significativamente maggiore della 5K.
        let distanceFactor: Double
        switch distance {
        case .tenK: distanceFactor = 0.85
        case .halfMarathon: distanceFactor = 1.0
        case .marathon: distanceFactor = 1.25  // [FIX] era 1.15, troppo basso
        case .fiveK: distanceFactor = 0.70     // non target, ma richiesto per exhaustiveness
        }

        let computed = Double(daysPerWeek) * kmPerSession * distanceFactor

        // Cap assoluto per combinazione distanza/livello: limita il volume di partenza
        // per i runner meno allenati e garantisce un picco realistico (base × 1.42).
        let absoluteCap: Double
        switch (distance, vdot) {
        // 5K
        // 10K
        case (.tenK, ..<35):     absoluteCap = 28
        case (.tenK, 35..<45):   absoluteCap = 45
        case (.tenK, 45..<55):   absoluteCap = 62
        case (.tenK, _):         absoluteCap = 80
        // HM
        case (.halfMarathon, ..<35):   absoluteCap = 38
        case (.halfMarathon, 35..<45): absoluteCap = 55   // base ~55 → picco ~78 km
        case (.halfMarathon, 45..<55): absoluteCap = 72
        case (.halfMarathon, _):       absoluteCap = 95
        // Maratona — [FIX] cap alzati: base più alta → picco realistico
        case (.marathon, ..<35):   absoluteCap = 48   // base ~48 → picco ~68 km
        case (.marathon, 35..<45): absoluteCap = 75   // base ~75 → picco ~106 km ← target Pfitzinger
        case (.marathon, 45..<55): absoluteCap = 95   // base ~95 → picco ~135 km
        case (.marathon, _):       absoluteCap = 120
        default:                   absoluteCap = 100
        }

        return min(computed, absoluteCap)
    }
    
    // Versione precedente di estimateBaseWeeklyKm rimossa (volumi troppo bassi).

    private func computeWeeklyVolume(
        weekIndex: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        baseKm: Double,
        prevKm: Double
    ) -> (Double, WeeklyNoteKind) {

        let weekNum = weekIndex + 1
        var noteKind: WeeklyNoteKind
        var kms: Double

        switch phase {
        case .base:
            /// Ogni 4ª settimana: scarico (-20%) per supercompensazione.
            /// Nelle altre: aumento max 10% (regola del 10% [1][8]).
            if weekNum % 4 == 0 {
                kms = prevKm * 0.80
                noteKind = .baseDeload
            } else {
                kms = min(prevKm * 1.10, prevKm + baseKm * 0.10)
                noteKind = .baseProgress
            }

        case .build:
            // Build: ogni 3ª settimana micro-scarico (-15%).
            // R aggiunge solo stimolo velocità senza stress aerobico aggiuntivo [1].
            if weekNum % 3 == 0 {
                kms = prevKm * 0.85
                noteKind = .buildMicroDeload
            } else {
                kms = min(prevKm * 1.08, baseKm * 1.38)
                noteKind = .buildProgress
            }

        case .peak:
            // Picco: massima qualità T + I + M. Il più impegnativo [1].
            kms = baseKm * 1.42
            noteKind = .peak

        case .taper:
            /// Taper: -40-60% volume, intensità invariata [6].
            /// taperProgress decresce verso 0 man mano che ci si avvicina alla gara,
            /// portando taperFactor verso 0.40 (massima riduzione nell'ultima settimana).
            let taperProgress = Double(totalWeeks - weekIndex) / Double(totalWeeks)
            let taperFactor = 0.60 - (0.20 * taperProgress)
            kms = baseKm * max(0.40, taperFactor)
            noteKind = .taper

        case .race:
            kms = baseKm * 0.30
            noteKind = .raceWeek
        }

        // Floor minimo per evitare settimane vuote, ma proporzionale al base.
        // Il precedente floor fisso di 20 km era troppo alto per 5K beginner.
        let minKms = max(baseKm * 0.60, 8.0)
        return (max(minKms, kms), noteKind)
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
            vdot: paces.vdot   // adatta la struttura al livello del runner (es. includeHills)
        )

        // Il lungo è phase-driven: la progressione segue la curva attesa per distanza,
        // poi viene cappato dal limite temporale di Daniels (150 min a E-pace) [1] cap. 4.
        let longRunKm = computeLongRunKm(
            weeklyKm: weeklyKm,
            distance: distance,
            phase: phase,
            weekIndex: weekIndex,
            totalWeeks: totalWeeks,
            vdot: paces.vdot,
            easyPaceSecsPerKm: paces.easyPaceSecsPerKm
        )
        let remainingKm = weeklyKm - longRunKm
        let otherSessionsCount = max(1, daysPerWeek - 1)
        // Se il cap temporale (150 min) tiene basso il lungo, il budget residuo
        // potrebbe produrre sessioni più lunghe del lungo stesso.
        // L'85% mantiene le altre sessioni sempre inferiori al lungo.
        let rawAvgOtherKm = remainingKm / Double(otherSessionsCount)
        let avgOtherKm = min(rawAvgOtherKm, longRunKm * 0.85)

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

        // Giorni di riposo standard (giorni non di allenamento nella settimana)
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
                titleKind: .workoutType(.rest),
                descriptionKind: .rest,
                distanceKm: nil,
                durationMinutes: nil,
                paceTarget: nil,
                paceTargetSecsPerKm: nil,
                structuredSets: nil,
                structuredSetsKind: nil,
                scientificRationale: "Il riposo è componente fondamentale della supercompensazione. " +
                                     "Fonte: Bompa & Haff [7].",
                rpe: "1",
                tss: 0
            )
            workouts.append(rest)
        }

        // Nell'ultima settimana, i giorni successivi alla gara diventano riposo.
        // Se la gara cade sabato (offset 5), domenica diventa riposo post-gara.
        // Il controllo su raceDayOffset < 6 evita un range invalido 7..<7.
        if weekIndex == totalWeeks - 1 {
            let raceDayOffset = calendar.dateComponents(
                [.day], from: weekStartDate, to: raceDate
            ).day ?? 6

            // Aggiungi riposo per ogni giorno dopo la gara fino a fine settimana
            // Se la gara è domenica (offset 6) non ci sono giorni successivi.
            // Il controllo su raceDayOffset < 6 evita un range invalido 7..<7.
            if raceDayOffset < 6 {
            for dayOffset in (raceDayOffset + 1)..<7 {
                // Salta se il giorno è già presente nei workout (non dovrebbe succedere)
                guard !workouts.contains(where: { $0.dayOfWeek == dayOffset }) else { continue }
                let postRaceDate = calendar.date(
                    byAdding: .day, value: dayOffset, to: weekStartDate
                )! // swiftlint:disable:this force_unwrapping
                let postRaceRest = Workout(
                    date: postRaceDate,
                    type: .rest,
                    week: weekIndex + 1,
                    dayOfWeek: dayOffset,
                    title: "Riposo post-gara",
                    description: "Recupero dopo la gara. Riposo completo.",
                    titleKind: .postRaceRest,
                    descriptionKind: .postRaceRest,
                    distanceKm: nil,
                    durationMinutes: nil,
                    paceTarget: nil,
                    paceTargetSecsPerKm: nil,
                    structuredSets: nil,
                    structuredSetsKind: nil,
                    scientificRationale: "Recupero post-gara: riposo completo per almeno 48-72h. " +
                                         "Fonte: principio di recupero [7].",
                    rpe: "1",
                    tss: 0
                )
                workouts.append(postRaceRest)
            }
            } // if raceDayOffset < 6
        }

        return workouts.sorted { $0.date < $1.date }
    }

    // MARK: - Day Selection

    private func selectTrainingDays(daysPerWeek: Int) -> [Int] {
        /// Distribuzione ottimale: evita back-to-back sessioni intense,
        /// garantisce recupero tra le sessioni di qualità.
        /// Fonte: [2] Pfitzinger – distribuzione settimanale.
        // Indici 0-6: 0=lunedì, 6=domenica (con calendar.firstWeekday=2).
        // Il lungo è SEMPRE domenica (indice 6) — convenzione universale del runner.
        // Si evitano sessioni di qualità sabato+domenica back-to-back:
        // il sabato è sempre facile o riposo quando c'è il lungo domenica.
        switch daysPerWeek {
        case 3: return [1, 3, 6]           // mar, gio, dom(lungo)
        case 4: return [1, 3, 5, 6]        // mar, gio, sab(easy), dom(lungo)
        case 5: return [1, 2, 4, 5, 6]     // mar, mer, ven, sab(easy), dom(lungo)
        case 6: return [0, 1, 3, 4, 5, 6]  // lun, mar, gio, ven, sab(easy), dom(lungo)
        default: return [1, 3, 6]
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

        // VDOT < 35 (beginner): hillRepeat sostituito con .easy o .progression.
        // Daniels [1] Phase I: "mostly E running" — le colline sono stimolo
        // supplementare adatto solo dopo una base aerobica consolidata.
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
            // R (velocità) arriva prima di T+I: aggiunge solo stress velocità,
            // senza appesantire il sistema aerobico/lattato [1] cap. 10.
            // T introdotto come secondo stimolo. Nessun I ancora.
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
            // Se il gap VDOT è ampio (>3 punti), si privilegia un secondo stimolo I
            // per massimizzare l'adattamento VO2max; altrimenti T è sufficiente.
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

    // Il lungo è calcolato in base alla fase (non al volume settimanale), seguendo
    // la progressione attesa per distanza:
    //   Maratona: 16 km (base) → 32 km (peak)
    //   HM:       10 km (base) → 22 km (peak)
    //   10K:       8 km (base) → 18 km (peak)
    //
    // Daniels [1] cap. 4: il lungo si misura in TEMPO, non in km.
    // Cap: 150 min a E-pace reale — produce naturalmente km minori per runner lenti:
    //   VDOT 60 (E ~4:24/km) → ~34 km (cappato a 32)
    //   VDOT 35 (E ~6:47/km) → ~22 km
    //
    // Per HM/maratona il volume settimanale non vincola il lungo (sarebbe troppo basso).
    // Per 5K/10K si applica anche il cap al 25% settimanale (il lungo non deve dominare).
    // Fonte: [1] cap. 4, [2] cap. 3.
    private func computeLongRunKm(
        weeklyKm: Double,
        distance: RaceDistance,
        phase: TrainingPhase,
        weekIndex: Int,
        totalWeeks: Int,
        vdot: Double,
        easyPaceSecsPerKm: Double   // E-pace reale del runner per il cap temporale
    ) -> Double {

        _ = vdot   // rimosso vdotFactor: il cap temporale (150 min) gestisce già le differenze tra runner
        
        let phaseFraction = phaseProgressionFraction(
            phase: phase, weekIndex: weekIndex, totalWeeks: totalWeeks
        )

        let (low, high) = longRunPhaseRange(phase: phase, distance: distance)
        var target = low + (high - low) * phaseFraction

        // [FIX] Rimosso vdotFactor: non è Daniels.
        // Il cap temporale (150 min a E-pace) gestisce già la differenza
        // tra runner veloci e lenti in modo fisiologicamente corretto.

        // Cap temporale di Daniels: max 150 minuti a E-pace reale del runner.
        let maxKmByTime = (150.0 * 60.0) / easyPaceSecsPerKm

        // Cap assoluto per distanza
        let absoluteMax: Double
        switch distance {
        case .tenK:         absoluteMax = 18
        case .halfMarathon: absoluteMax = 22
        case .marathon:     absoluteMax = 32
        default:            absoluteMax = 18
        }

        // Applica i cap in base a fase e distanza
        if phase == .taper || phase == .race {
            // Taper: cap al 40% del settimanale (già ridotto) per evitare
            // che il lungo assorba quasi tutto il volume disponibile.
            target = min(target, weeklyKm * 0.40, maxKmByTime, absoluteMax)
        } else {
            switch distance {
            case .tenK:
                // Distanze brevi: il lungo non deve dominare il volume.
                target = min(target, weeklyKm * 0.25, maxKmByTime, absoluteMax)
            case .halfMarathon, .marathon:
                // Distanze lunghe: cap temporale + cap assoluto.
                // Il volume settimanale non è usato come vincolo per HM/maratona.
                target = min(target, maxKmByTime, absoluteMax)
            default:
                target = min(target, weeklyKm * 0.25, maxKmByTime, absoluteMax)
            }
        }

        // Floor: non scendere sotto l'80% del minimo della fase.
        // Il cap temporale prevale sempre, anche sul floor.
        let floor = low * 0.80
        return roundKm(min(max(target, floor), maxKmByTime))
    }

    /// Fraction [0,1] di avanzamento all'interno della fase corrente,
    /// normalizzata sulle soglie medie tra le distanze supportate.
    /// Il clamp finale evita valori negativi o >1 nei boundary di fase.
    private func phaseProgressionFraction(
        phase: TrainingPhase,
        weekIndex: Int,
        totalWeeks: Int
    ) -> Double {
        let totalActive = max(1, totalWeeks - 1)
        let normalized = Double(weekIndex) / Double(totalActive)

        // Le soglie riflettono le proporzioni medie dei piani per tutte le distanze.
        // Usando i valori mediani tra le distanze (marathon 0.38, fiveK 0.25 → ~0.31 per base).
        // Il clamp finale garantisce sempre un valore in [0,1].
        let raw: Double
        switch phase {
        case .base:
            // Base: primi ~30% del piano (media tra 0.25 fiveK e 0.38 marathon)
            raw = normalized / 0.30
        case .build:
            // Build: ~30-68% del piano
            raw = (normalized - 0.30) / 0.38
        case .peak:
            // Peak: ~68-88% del piano
            raw = (normalized - 0.68) / 0.20
        case .taper, .race:
            return 0.5
        }
        // [FIX] Clamp essenziale: senza questo, le prime settimane di una fase
        // producevano frazioni negative (target = lo + negativo × range < lo).
        return max(0.0, min(1.0, raw))
    }
    
    /// Range (min, max) km del lungo per fase e distanza gara.
    /// Fonte: Daniels [1] tavole piani cap. 15-16, Pfitzinger [2] cap. 3.
    private func longRunPhaseRange( // swiftlint:disable:this cyclomatic_complexity
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
        case (.tenK, .base):   return (8, 13)
        case (.tenK, .build):  return (12, 16)
        case (.tenK, .peak):   return (15, 18)
        case (.tenK, .taper):  return (8, 12)
        // 5K
        // Race week / fallback
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
                titleKind: .workoutType(.easy),
                descriptionKind: .easy,
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: paces.easyFormatted,
                paceTargetSecsPerKm: paces.easyPaceSecsPerKm,
                structuredSets: nil,
                structuredSetsKind: nil,
                // E-pace copre tutto il range bassa intensità in Daniels (59-74% VO2max);
                // non esiste una recovery zone separata. Fonte: [1] cap. 4, [4] Seiler.
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
            let longRunDescriptionKind: WorkoutDescriptionKind = distance == .marathon
                ? .longRunMarathon
                : .longRunOther(pace: paces.easyFormatted)
            return Workout(
                date: date, type: .longRun, week: week, dayOfWeek: day,
                title: "Lungo",
                description: "Corsa lunga a ritmo E. \(note)",
                titleKind: .workoutType(.longRun),
                descriptionKind: longRunDescriptionKind,
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: paces.easyFormatted,
                paceTargetSecsPerKm: paces.easyPaceSecsPerKm,
                structuredSets: nil,
                structuredSetsKind: nil,
                // Cap 25% settimanale e max 150 min a E-pace (Daniels [1] cap. 4).
                scientificRationale: "Il lungo stimola adattamenti aerobici e riserve " +
                    "di glicogeno. Limitato al 25% del volume settimanale (non 30-33%) " +
                    "e max 150 min per sessione. Fonte: [1] cap. 4.",
                rpe: "5-6",
                tss: kms * 55
            )

        case .tempo:
            // T-pace: 85-88% VO2max. Max 10% del volume settimanale per sessione [1].
            let maxTempoKm = min(
                kms * 0.55,
                weeklyKm * TrainingPlanGenerator.maxThresholdFractionOfWeekly,
                distance == .marathon ? 14.0 : 10.0
            )
            let warmupKm = 2.0
            let cooldownKm = 2.0
            let mainKm = max(3.0, maxTempoKm - warmupKm - cooldownKm)
            let tempoKm = warmupKm + mainKm + cooldownKm
            let tempoSetsKind = StructuredSetsKind.tempo(mainKm: Int(mainKm), pace: paces.thresholdFormatted)
            return Workout(
                date: date, type: .tempo, week: week, dayOfWeek: day,
                title: "Tempo Run",
                description: "Ritmo soglia: 'comfortably hard'. " +
                             "Sforzo sostenibile per ~20 min continuati.",
                titleKind: .workoutType(.tempo),
                descriptionKind: .tempo,
                distanceKm: roundKm(tempoKm),
                durationMinutes: nil,
                paceTarget: paces.thresholdFormatted,
                paceTargetSecsPerKm: paces.thresholdPaceSecsPerKm,
                structuredSets: italianSetsText(tempoSetsKind),
                structuredSetsKind: tempoSetsKind,
                // Intensità corretta: 85-88% VO2max / 88-92% FCmax. Fonte: [1] cap. 4.
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
            let intervalSetsKind = buildIntervalSetsKind(distance: distance, paces: paces)
            return Workout(
                date: date, type: .interval, week: week, dayOfWeek: day,
                title: "Interval Training",
                description: "Ripetute a VO2max (95-100%). Work bout 3-5 min, " +
                             "recupero attivo (jog) tra le ripetizioni.",
                titleKind: .workoutType(.interval),
                descriptionKind: .interval,
                distanceKm: roundKm(sessionKm),
                durationMinutes: nil,
                paceTarget: paces.intervalFormatted,
                paceTargetSecsPerKm: paces.intervalPaceSecsPerKm,
                structuredSets: italianSetsText(intervalSetsKind),
                structuredSetsKind: intervalSetsKind,
                scientificRationale: "I-pace massimizza il tempo a VO2max, " +
                    "stimola gittata cardiaca e densità mitocondriale. " +
                    "Max il minore tra 10K e 8% volume settimanale per sessione. " +
                    "Fonte: [1] cap. 4, [3] Billat, [5] Laursen & Jenkins.",
                rpe: "8-9",
                tss: sessionKm * 100
            )

        case .repetition:
            // R-pace: velocità pura, basso stress aerobico.
            // Work bout max 2 min, recupero COMPLETO (jog uguale al lavoro).
            // Introdotto in Build prima delle I: aggiunge solo stimolo velocità [1] cap. 4.
            let maxRKm = weeklyKm * TrainingPlanGenerator.maxRepetitionFractionOfWeekly
            let sessionKm = min(kms * 0.70, maxRKm)
            let repetitionSetsKind = buildRepetitionSetsKind(distance: distance, paces: paces)
            return Workout(
                date: date, type: .repetition, week: week, dayOfWeek: day,
                title: "Ripetute",
                description: "Ripetute brevi a ritmo R (105-120% VDOT). " +
                             "Recupero completo tra le ripetizioni: non iniziare " +
                             "la prossima finché non sei pronto a correre con buona meccanica.",
                titleKind: .workoutType(.repetition),
                descriptionKind: .repetition,
                distanceKm: roundKm(sessionKm),
                durationMinutes: nil,
                paceTarget: paces.repetitionFormatted,
                paceTargetSecsPerKm: paces.repetitionPaceSecsPerKm,
                structuredSets: italianSetsText(repetitionSetsKind),
                structuredSetsKind: repetitionSetsKind,
                // Il recupero completo è fondamentale: la prossima ripetuta
                // si inizia solo quando la meccanica di corsa è di nuovo buona [1].
                scientificRationale: "R-pace (105-120% VDOT) migliora velocità, " +
                    "economia di corsa e potenza anaerobica. Work bout max 2 min, " +
                    "recupero completo (jog uguale al lavoro). Max 5% volume settimanale. " +
                    "Introdotto prima delle I (aggiunge solo stimolo velocità). " +
                    "Fonte: [1] cap. 4 – Repetition training.",
                rpe: "8-9",
                tss: sessionKm * 90
            )

        case .recovery:
            // Daniels non definisce una recovery zone separata: E-pace copre
            // tutto il range bassa intensità. Questo tipo usa il limite inferiore
            // dell'E-pace per segnalare un'uscita di recupero senza creare una zona fittizia.
            return Workout(
                date: date, type: .recovery, week: week, dayOfWeek: day,
                title: "Corsa Facile (Recupero)",
                description: "Corsa molto leggera nell'intervallo basso dell'E-pace. " +
                             "Obiettivo: promuovere il recupero, non costruire fitness.",
                titleKind: .easyRecovery,
                descriptionKind: .easyRecovery,
                distanceKm: roundKm(max(4, kms * 0.65)),
                durationMinutes: nil,
                // Usa il limite inferiore dell'E-pace (non un ritmo fittizio più lento).
                paceTarget: paces.easyFormatted + " (limite inf.)",
                paceTargetSecsPerKm: paces.easyPaceSecsPerKm,
                structuredSets: nil,
                structuredSetsKind: nil,
                scientificRationale: "Recupero attivo nella zona E (59-74% VO2max). " +
                    "Daniels non definisce una recovery zone separata: E-pace copre " +
                    "tutto il range bassa intensità. Fonte: [1] cap. 4.",
                rpe: "3-4",
                tss: kms * 28
            )

        case .progression:
            let progressionSetsKind = buildProgressionSetsKind(kms: kms, paces: paces)
            return Workout(
                date: date, type: .progression, week: week, dayOfWeek: day,
                title: "Corsa Progressiva",
                description: "Inizia a E-pace, aumenta gradualmente fino a T-pace.",
                titleKind: .workoutType(.progression),
                descriptionKind: .progression,
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: "Da \(paces.easyFormatted) a \(paces.thresholdFormatted)",
                paceTargetSecsPerKm: paces.thresholdPaceSecsPerKm,
                structuredSets: italianSetsText(progressionSetsKind),
                structuredSetsKind: progressionSetsKind,
                scientificRationale: "La progressiva abitua a correre a ritmi crescenti, " +
                    "allenando sia la base aerobica che la soglia. " +
                    "Compatibile con Phase I di Daniels (stimolo leggero). Fonte: [2].",
                rpe: "5-7",
                tss: kms * 65
            )

        case .hillRepeat:
            let reps = (distance == .marathon || distance == .halfMarathon) ? "8-10" : "6-8"
            let hillLen = distance == .marathon ? "200m" : "150m"
            // Minimo 4 km: garantisce spazio per 2 km riscaldamento + ripetute + defaticamento.
            let hillSessionKm = roundKm(max(4, kms * 0.9))
            let hillSetsKind = StructuredSetsKind.hillRepeat(reps: reps, hillLength: hillLen)
            return Workout(
                date: date, type: .hillRepeat, week: week, dayOfWeek: day,
                title: "Ripetute in Salita",
                description: "Collinare ad alta intensità. Recupero in discesa lenta. " +
                             "Usate nella fase Base come stimolo di forza-velocità " +
                             "a basso impatto articolare.",
                titleKind: .workoutType(.hillRepeat),
                descriptionKind: .hillRepeat,
                distanceKm: hillSessionKm,
                durationMinutes: nil,
                paceTarget: "Sforzo 95% in salita",
                paceTargetSecsPerKm: nil,
                structuredSets: italianSetsText(hillSetsKind),
                structuredSetsKind: hillSetsKind,
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
            let marPaceSetsKind = StructuredSetsKind.marPace(mainKm: Int(mpSection))
            return Workout(
                date: date, type: .marPace, week: week, dayOfWeek: day,
                title: "Ritmo Gara",
                description: "Sezione centrale al ritmo gara target. " +
                             "Adattamento fisico e mentale al passo specifico.",
                titleKind: .racePace,
                descriptionKind: .marPace,
                distanceKm: roundKm(mpKm),
                durationMinutes: nil,
                paceTarget: distance == .marathon
                    ? paces.mpFormatted
                    : paces.thresholdFormatted,
                paceTargetSecsPerKm: distance == .marathon
                    ? paces.marathonPaceSecsPerKm
                    : paces.thresholdPaceSecsPerKm,
                structuredSets: italianSetsText(marPaceSetsKind),
                structuredSetsKind: marPaceSetsKind,
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
                distance: .tenK,  // .fiveK rimossa come distanza target
                targetPaceSecsPerKm: paces.thresholdPaceSecsPerKm,
                vdotGap: 0,
                week: week, day: day
            )
        }
    }

    private func buildIntervalSetsKind(
        distance: RaceDistance,
        paces: TrainingPaces
    ) -> StructuredSetsKind {
        .interval(raceDistance: distance, pace: paces.intervalFormatted)
    }

    // MARK: - Repetition Structure Builder

    /// Struttura R (Repetition) secondo Daniels [1] cap. 4:
    /// - Work bout max 2 minuti (200m, 300m, 400m, max 600-800m per VDOT alti)
    /// - Recupero COMPLETO: jog uguale alla distanza della ripetuta (es. 400R → 400 jog)
    /// - Scopo: velocità e economia, NON stress aerobico
    private func buildRepetitionSetsKind(
        distance: RaceDistance,
        paces: TrainingPaces
    ) -> StructuredSetsKind {
        .repetition(raceDistance: distance, pace: paces.repetitionFormatted)
    }

    // MARK: - Progression Description

    private func buildProgressionSetsKind(
        kms: Double,
        paces: TrainingPaces
    ) -> StructuredSetsKind {
        let third = max(1, Int(kms / 3))
        return .progression(
            easyEndKm: third,
            marathonEndKm: third * 2,
            easyPace: paces.easyFormatted,
            mpPace: paces.mpFormatted,
            thresholdPace: paces.thresholdFormatted
        )
    }

    private func italianSetsText(_ kind: StructuredSetsKind) -> String {
        kind.localizedText(locale: Locale(identifier: "it"))
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

        let feasibility = GoalFeasibility.from(vdotGap: vdotGap)

        return Workout(
            date: date, type: .race, week: week, dayOfWeek: day,
            title: raceName,  // sfSymbol "trophy" già mostrato da WorkoutBadge
            description: feasibility.raceDescription,
            titleKind: .raceName(raceName),
            descriptionKind: .race(feasibility),
            distanceKm: distance.meters / 1000,
            durationMinutes: nil,
            paceTarget: racePaceFormatted,
            paceTargetSecsPerKm: targetPaceSecsPerKm,
            structuredSets: nil,
            structuredSetsKind: nil,
            scientificRationale: "Gara: culmine del ciclo di allenamento.",
            rpe: "9-10",
            tss: 150
        )
    }

    // MARK: - Helpers

    private func roundKm(_ kms: Double) -> Double {
        (kms * 2).rounded() / 2
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
