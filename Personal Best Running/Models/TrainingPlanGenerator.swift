import Foundation
// swiftlint:disable file_length

// MARK: - Training Plan Generator
//
// Scientific sources:
//
// [1] Daniels J. (2022). Daniels' Running Formula (4th ed.). Human Kinetics.
//     → VDOT system, pace zones (E/M/T/I/R), long run rules, phase structure,
//       weekly volume limits, taper, sex-neutrality of VDOT
//
// [2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.
//     → Weekly volume distribution, marathon/HM specific sessions
//
// [3] Billat V. (2001). Interval Training for Performance. Sports Medicine, 31(1), 13-31.
//     → Interval training at VO2max, repetition duration, recovery
//
// [4] Seiler S., Kjerland G.Ø. (2006). Quantifying training intensity distribution
//     in elite endurance athletes. Scand. J. Med. Sci. Sports, 16(1), 49-56.
//     → Polarized distribution: ~80% low intensity, ~20% high intensity
//     NOTE: Seiler describes an empirical pattern observed in elite athletes, not a
//     prescriptive model that replaces Daniels' phase structure.
//     In the code it is used as a guide to balance workout types within the week.
//
// [5] Laursen P.B., Jenkins D.G. (2002). The Scientific Basis for High-Intensity
//     Interval Training. Sports Medicine, 32(1), 53-73.
//     → Physiological adaptations to HIIT (VO2max, capillarization)
//
// [6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering
//     strategies. Medicine & Science in Sports & Exercise, 35(7), 1182-1187.
//     → Taper: 40-60% volume reduction, intensity maintained
//
// [7] Bompa T., Haff G. (2009). Periodization: Theory and Methodology of Training
//     (5th ed.). Human Kinetics.
//     → Periodization in macrocycles (general preparation → specific → competitive)
//     NOTE: The Base/Build/Peak/Taper naming is compatible with Bompa.
//     Phase content (which workout type goes in which phase) however follows
//     Daniels [1] (Phase I→E+strides, Phase II→R, Phase III→T+I, Phase IV→peak).
//
// [8] Galloway J. (2010). Running Until You're 100. Meyer & Meyer Sport.
//     → Conservative progression (10% rule)

class TrainingPlanGenerator {  // swiftlint:disable:this type_body_length
    // MARK: - Constants based on Daniels [1]

    /// 10% rule: do not increase weekly volume more than 10% compared to the
    /// previous week. Source: [1] ch. 2, [8] Galloway.
    /// NOTE: Daniels also suggests staying at the same load for 3-4 weeks
    /// before increasing. Here we apply the maximum weekly increase as
    /// the upper limit, with deload weeks every 3-4 weeks.
    static let maxWeeklyVolumeIncreasePercent: Double = 0.10

    /// Maximum I-pace volume in a single session: the lesser of 10K and 8%
    /// of weekly volume. Source: [1] ch. 4.
    static let maxIntervalFractionOfWeekly: Double = 0.08
    static let maxIntervalKm: Double = 10.0

    /// Maximum R-pace volume in a single session: 5% of weekly volume.
    /// Source: [1] ch. 4 (R is more intense than I but work bouts are very short,
    /// the limit is conservative to avoid compromising recovery).
    static let maxRepetitionFractionOfWeekly: Double = 0.05

    /// Maximum T-pace volume in a single session: 10% of weekly volume.
    /// Source: [1] ch. 4: "not totaling more than 10 percent of your weekly mileage".
    static let maxThresholdFractionOfWeekly: Double = 0.10

    // MARK: - Generate Plan
     func generate(input: TrainingPlanInput) -> TrainingPlan {     // swiftlint:disable:this function_body_length
          var calendar = Calendar.current
          calendar.firstWeekday = 2  // 2 = Monday — iOS uses Sunday as default
          let today = Date()

         // Calculate current VDOT from current performance
         let currentVDOT = VDOTCalculator.calculate(
             timeInSeconds: input.currentPerformance.time,
             distanceMeters: input.currentPerformance.distance.meters
         )

         // VDOT is sex-neutral by definition [1] ch. 5: no correction needed.
         let normalizedVDOT = currentVDOT

         // Calculate training paces from current VDOT (no sex correction)
         let paces = VDOTCalculator.trainingPaces(vdot: normalizedVDOT)

         // Estimated time with current VDOT on target distance
         let estimatedCurrent = VDOTCalculator.predictRaceTime(
             vdot: normalizedVDOT,
             distance: input.raceDistance
         )
         // Use the declared TARGET time, not the estimate from current fitness:
         // the displayed race pace must reflect the runner's goal.
         let targetPaceSecsPerKm = input.targetTime / input.raceDistance.meters * 1000

         // VDOT required for the target time
         let targetVDOT = VDOTCalculator.calculate(
             timeInSeconds: input.targetTime,
             distanceMeters: input.raceDistance.meters
         )
         let vdotGap = targetVDOT - normalizedVDOT
         // Number of weeks available
         let rawWeeks = calendar.dateComponents(
             [.weekOfYear], from: today, to: input.raceDate
         ).weekOfYear ?? 12
         let totalWeeks = min(input.raceDistance.maxPlanWeeks, max(12, rawWeeks))

         // Anchor planStartDate to the Monday of its week.
         // Without this, index 0 doesn't always correspond to Monday
         // (e.g. if rawStartDate falls on Wednesday, dayOfWeek 0 would be Wednesday).
         let rawStartDate = calendar.date(
             byAdding: .weekOfYear, value: -totalWeeks, to: input.raceDate
         )! // swiftlint:disable:this force_unwrapping

         // With firstWeekday=2 (Monday), .weekday returns 1=Mon…7=Sun.
         // daysFromMonday is the shift to subtract to get back to Monday.
         let weekdayComponent = calendar.component(.weekday, from: rawStartDate)
         let daysFromMonday = (weekdayComponent - calendar.firstWeekday + 7) % 7
         let planStartDate = calendar.date(
             byAdding: .day, value: -daysFromMonday, to: rawStartDate
         )! // swiftlint:disable:this force_unwrapping

         // Phase structure. Source: [1] ch. 10 (4 phases), [7] Bompa periodization.
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

    // Phase structure reflects the logic of Daniels [1] ch. 10:
    //
    //  Phase I  (Base)  → E running + strides + light hillRepeat + progressions.
    //                      "Mostly E running" — no heavy I work.
    //  Phase II (Build) → Introduction of R (Repetition): only speed stress
    //                      is added. Daniels puts R before T+I because it is a
    //                      lesser additional stress compared to I. T (Tempo) is also introduced.
    //  Phase III (Peak) → Maximum quality: T + I + M. The most demanding. Source: [1].
    //  Taper            → Volume -40-60%, intensity maintained. Source: [6] Mujika.
    //  Race             → Race week.
    //
    // The Base/Build/Peak/Taper names are compatible with Bompa periodization [7].
    private func buildPhaseStructure(
        totalWeeks: Int,
        distance: RaceDistance
    ) -> [TrainingPhase] {

        // Phase proportions by race distance.
        // Marathon: longer base (more aerobic volume needed, less pure speed).
        // 5K: shorter base, more peak (speed and VO2max are central).
        // Source: [1] ch. 10 (phase distribution), [2] Pfitzinger (marathon).
        let phaseRatios: (base: Double, build: Double, peak: Double, taper: Double) // swiftlint:disable:this large_tuple
        switch distance {
        case .tenK:
            phaseRatios = (0.28, 0.38, 0.24, 0.10)
        case .halfMarathon:
            phaseRatios = (0.33, 0.37, 0.20, 0.10)
        case .marathon:
            phaseRatios = (0.38, 0.35, 0.17, 0.10)
        case .fiveK:          // not a target distance, but required for exhaustiveness
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

        // Km per base session by VDOT band — values calibrated on Daniels [1] ch. 15-16
        // and Pfitzinger [2] ch. 2-3 plans.
        // Peak volume will be base × 1.42 (see computeWeeklyVolume).
        let kmPerSession: Double
        switch vdot {
        case ..<35: kmPerSession = 6.0    // beginner: short sessions, gradual adaptation
        case 35..<45: kmPerSession = 10.0 // recreational: ~10 km/base session
        case 45..<55: kmPerSession = 14.0 // intermediate
        default: kmPerSession = 18.0      // advanced
        }

        // Distance factor amplifies volume for longer distances.
        // Marathon requires a significantly greater base volume than 5K.
        let distanceFactor: Double
        switch distance {
        case .tenK: distanceFactor = 0.85
        case .halfMarathon: distanceFactor = 1.0
        case .marathon: distanceFactor = 1.25
        case .fiveK: distanceFactor = 0.70     // not a target distance, but required for exhaustiveness
        }

        let computed = Double(daysPerWeek) * kmPerSession * distanceFactor

        // Absolute cap for distance/level combination: limits starting volume
        // for less trained runners and ensures a realistic peak (base × 1.42).
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
        case (.halfMarathon, 35..<45): absoluteCap = 55   // base ~55 → peak ~78 km
        case (.halfMarathon, 45..<55): absoluteCap = 72
        case (.halfMarathon, _):       absoluteCap = 95
        // Marathon
        case (.marathon, ..<35):   absoluteCap = 48   // base ~48 → peak ~68 km
        case (.marathon, 35..<45): absoluteCap = 75   // base ~75 → peak ~106 km ← Pfitzinger target
        case (.marathon, 45..<55): absoluteCap = 95   // base ~95 → peak ~135 km
        case (.marathon, _):       absoluteCap = 120
        default:                   absoluteCap = 100
        }

        return min(computed, absoluteCap)
    }

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
            // Every 4th week: deload (-20%) for supercompensation.
            // Others: max 10% increase (10% rule [1][8]).
            if weekNum % 4 == 0 {
                kms = prevKm * 0.80
                noteKind = .baseDeload
            } else {
                kms = min(prevKm * 1.10, prevKm + baseKm * 0.10)
                noteKind = .baseProgress
            }

        case .build:
            // Build: every 3rd week micro-deload (-15%).
            // R adds only speed stress without additional aerobic stress [1].
            if weekNum % 3 == 0 {
                kms = prevKm * 0.85
                noteKind = .buildMicroDeload
            } else {
                kms = min(prevKm * 1.08, baseKm * 1.38)
                noteKind = .buildProgress
            }

        case .peak:
            // Peak: maximum quality T + I + M. The most demanding [1].
            kms = baseKm * 1.42
            noteKind = .peak

        case .taper:
            // Taper: -40-60% volume, unchanged intensity [6].
            // taperProgress decreases toward 0 as we approach race day,
            // bringing taperFactor toward 0.40 (maximum reduction in the last week).
            let taperProgress = Double(totalWeeks - weekIndex) / Double(totalWeeks)
            let taperFactor = 0.60 - (0.20 * taperProgress)
            kms = baseKm * max(0.40, taperFactor)
            noteKind = .taper

        case .race:
            kms = baseKm * 0.30
            noteKind = .raceWeek
        }

        // Minimum floor to avoid empty weeks, but proportional to base.
        // The previous fixed floor of 20 km was too high for 5K beginner.
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
            vdot: paces.vdot   // adapts the structure to the runner's level (e.g. includeHills)
        )

         // The long run is phase-driven: progression follows the expected curve by distance,
         // then capped by the Daniels time limit (150 min at E-pace) [1] ch. 4.
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
        // If the time cap (150 min) keeps the long run low, the remaining budget
        // could produce sessions longer than the long run itself.
        // The 85% keeps the other sessions always shorter than the long run.
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

        // In the last week, the days after the race become rest days.
        // Post-race rest days
        if weekIndex == totalWeeks - 1 {
            let raceDayOffset = calendar.dateComponents(
                [.day], from: weekStartDate, to: raceDate
            ).day ?? 6

            if raceDayOffset < 6 {
            for dayOffset in (raceDayOffset + 1)..<7 {
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
            }
        }

        return workouts.sorted { $0.date < $1.date }
    }

    // MARK: - Day Selection

    // Optimal distribution: avoids back-to-back intense sessions,
    // ensures recovery between quality sessions.
    // Source: [2] Pfitzinger – weekly distribution.
    // Indices 0-6: 0=Monday, 6=Sunday (with calendar.firstWeekday=2).
    // The long run is ALWAYS Sunday (index 6) — universal runner convention.
    // Quality sessions are avoided Saturday+Sunday back-to-back:
    // Saturday is always easy or rest when there's a long run Sunday.
    private func selectTrainingDays(daysPerWeek: Int) -> [Int] {
        switch daysPerWeek {
        case 3: return [1, 3, 6]           // Wed, Fri, Sun(long)
        case 4: return [1, 3, 5, 6]        // Wed, Fri, Sat(easy), Sun(long)
        case 5: return [1, 2, 4, 5, 6]     // Wed, Thu, Mon, Sat(easy), Sun(long)
        case 6: return [0, 1, 3, 4, 5, 6]  // Mon, Wed, Fri, Thu, Sat(easy), Sun(long)
        default: return [1, 3, 6]
        }
    }

    // MARK: - Week Structure

    // The weekly structure reflects Daniels' progression [1]:
    //
    //  BASE  → E + hillRepeat + progression + L run.
    //          No I sessions. Hill repeats and progressive runs
    //          are light stimuli compatible with Daniels Phase I.
    //
    //  BUILD → R (Repetition) + T (Tempo) + L run.
    //          Daniels introduces R before I because it only adds speed.
    //          T (threshold) is added in this phase as a second stimulus.
    //          No I yet.
    //
    //  PEAK  → T + I + M/R (race-specific pace) + L run.
    //          The most demanding. Daniels Phase III (TQ) and IV (FQ).
    //
    //  TAPER → Light T + E + reduced L run. Volume down, quality maintained [6].
    private func buildWeekStructure( // swiftlint:disable:this cyclomatic_complexity
        phase: TrainingPhase,
        daysPerWeek: Int,
        distance: RaceDistance,
        vdotGap: Double,
        vdot: Double        // [FIX-C] added to adapt the structure to the runner's level
    ) -> [WorkoutType] {

        // VDOT < 35 (beginner): hillRepeat replaced with .easy or .progression.
        // Daniels [1] Phase I: "mostly E running" — hills are a
        // supplemental stimulus suitable only after a solid aerobic base.
        let includeHills = vdot >= 35

        switch phase {
        case .base:
            // Base phase: pure E + strides/hills + progression + long run.
            // Source: [1] ch. 10 Phase I – "mostly E running",
            // strides and supplemental. No I work.
            // For beginners (VDOT < 35): only E + progression, no hillRepeat.
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
            // R (speed) comes before T+I: only adds speed stress,
            // without burdening the aerobic/lactate system [1] ch. 10.
            // T introduced as a second stimulus. No I yet.
            switch daysPerWeek {
            case 3: return [.repetition, .tempo, .longRun]
            case 4: return [.easy, .repetition, .tempo, .longRun]
            case 5: return [.easy, .repetition, .easy, .tempo, .longRun]
            case 6: return [.easy, .repetition, .easy, .tempo, .easy, .longRun]
            default: return [.easy, .repetition, .tempo, .longRun]
            }

        case .peak:
            // Peak phase: T + I + specific pace + long run. The most demanding.
            // Source: [1] Phase III (TQ) and IV (FQ).
            // For marathon/HM: M-pace run is more relevant than pure intervals [2].
            // For 5K/10K: VO2max intervals are central [3][5].
            let specificWork: WorkoutType = (distance == .marathon || distance == .halfMarathon)
                ? .marPace
                : .interval
            // If the VDOT gap is large (>3 points), a second I stimulus is prioritized
            // to maximize VO2max adaptation; otherwise T is sufficient.
            let secondQuality: WorkoutType = vdotGap > 3 ? .interval : .tempo
            switch daysPerWeek {
            case 3: return [.tempo, specificWork, .longRun]
            case 4: return [.tempo, specificWork, secondQuality, .longRun]
            case 5: return [.easy, .tempo, specificWork, secondQuality, .longRun]
            case 6: return [.easy, .tempo, .easy, specificWork, secondQuality, .longRun]
            default: return [.tempo, specificWork, .longRun]
            }

        case .taper:
            // Taper: volume down, at least one T session to maintain the threshold
            // stimulus. Source: [6] Mujika – "maintain training intensity".
            // Daniels [1] ch. 10 Phase IV: light T session in the last week.
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

    // The long run is calculated based on phase (not weekly volume), following
    // the expected progression by distance:
    //   Marathon: 16 km (base) → 32 km (peak)
    //   HM:       10 km (base) → 22 km (peak)
    //   10K:       8 km (base) → 18 km (peak)
    //
    // Daniels [1] ch. 4: the long run is measured in TIME, not km.
    // Cap: 150 min at real E-pace — naturally produces fewer km for slower runners:
    //   VDOT 60 (E ~4:24/km) → ~34 km (capped at 32)
    //   VDOT 35 (E ~6:47/km) → ~22 km
    //
    // For HM/marathon the weekly volume does not constrain the long run (it would be too low).
    // For 5K/10K the cap at 25% of weekly volume also applies (the long run must not dominate).
    // Source: [1] ch. 4, [2] ch. 3.
    private func computeLongRunKm(
        weeklyKm: Double,
        distance: RaceDistance,
        phase: TrainingPhase,
        weekIndex: Int,
        totalWeeks: Int,
        vdot: Double,
        easyPaceSecsPerKm: Double   // runner's real E-pace for the time cap
    ) -> Double {

        _ = vdot   // removed vdotFactor: the time cap (150 min) already handles the difference between runners
        
        let phaseFraction = phaseProgressionFraction(
            phase: phase, weekIndex: weekIndex, totalWeeks: totalWeeks
        )

        let (low, high) = longRunPhaseRange(phase: phase, distance: distance)
        var target = low + (high - low) * phaseFraction

        // Daniels' time cap: max 150 minutes at the runner's real E-pace.
        let maxKmByTime = (150.0 * 60.0) / easyPaceSecsPerKm

        let absoluteMax: Double
        switch distance {
        case .tenK:         absoluteMax = 18
        case .halfMarathon: absoluteMax = 22
        case .marathon:     absoluteMax = 32
        default:            absoluteMax = 18
        }

        if phase == .taper || phase == .race {
            // Taper: cap at 40% of weekly (already reduced) to prevent
            // the long run from consuming nearly all available volume.
            target = min(target, weeklyKm * 0.40, maxKmByTime, absoluteMax)
        } else {
            switch distance {
            case .tenK:
                // Short distances: the long run must not dominate the volume.
                target = min(target, weeklyKm * 0.25, maxKmByTime, absoluteMax)
            case .halfMarathon, .marathon:
                // Long distances: time cap + absolute cap.
                // Weekly volume is not used as a constraint for HM/marathon.
                target = min(target, maxKmByTime, absoluteMax)
            default:
                target = min(target, weeklyKm * 0.25, maxKmByTime, absoluteMax)
            }
        }

        // Floor: do not go below 80% of the phase minimum.
        let floor = low * 0.80
        return roundKm(min(max(target, floor), maxKmByTime))
    }

    // Fraction [0,1] of progress within the current phase,
    // normalized on the average thresholds across supported distances.
    // The final clamp avoids negative values or >1 at phase boundaries.
    private func phaseProgressionFraction(
        phase: TrainingPhase,
        weekIndex: Int,
        totalWeeks: Int
    ) -> Double {
        let totalActive = max(1, totalWeeks - 1)
        let normalized = Double(weekIndex) / Double(totalActive)

        // The thresholds reflect the average proportions of plans for all distances.
        // Using median values across distances (marathon 0.38, fiveK 0.25 → ~0.31 for base).
        // The final clamp always guarantees a value in [0,1].
        let raw: Double
        switch phase {
        case .base:
            // Base: first ~30% of the plan (average of 0.25 fiveK and 0.38 marathon)
            raw = normalized / 0.30
        case .build:
            // Build: ~30-68% of the plan
            raw = (normalized - 0.30) / 0.38
        case .peak:
            // Peak: ~68-88% of the plan
            raw = (normalized - 0.68) / 0.20
        case .taper, .race:
            return 0.5
        }
        return max(0.0, min(1.0, raw))
    }
    
    // Range (min, max) km of the long run for each phase and race distance.
    // Source: Daniels [1] plan tables ch. 15-16, Pfitzinger [2] ch. 3.
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
        case (.halfMarathon, .base):   return (10, 16)
        case (.halfMarathon, .build):  return (14, 19)
        case (.halfMarathon, .peak):   return (18, 22)
        case (.halfMarathon, .taper):  return (10, 14)
        case (.tenK, .base):   return (8, 13)
        case (.tenK, .build):  return (12, 16)
        case (.tenK, .peak):   return (15, 18)
        case (.tenK, .taper):  return (8, 12)
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
                // E-pace covers the full low-intensity range in Daniels (59-74% VO2max);
                // there is no separate recovery zone. Source: [1] ch. 4, [4] Seiler.
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
                // Cap 25% of weekly volume and max 150 min at E-pace (Daniels [1] ch. 4).
                scientificRationale: "Il lungo stimola adattamenti aerobici e riserve " +
                    "di glicogeno. Limitato al 25% del volume settimanale (non 30-33%) " +
                    "e max 150 min per sessione. Fonte: [1] cap. 4.",
                rpe: "5-6",
                tss: kms * 55
            )

        case .tempo:
            // T-pace: 85-88% VO2max. Max 10% of weekly volume per session [1].
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
                // Correct intensity: 85-88% VO2max / 88-92% HRmax. Source: [1] ch. 4.
                scientificRationale: "T-pace (85-88% VO2max / 88-92% FCmax) migliora " +
                    "la clearance del lattato e la soglia anaerobica. " +
                    "Max 10% volume settimanale per sessione. " +
                    "Fonte: [1] cap. 4 – T pace.",
                rpe: "7-8",
                tss: tempoKm * 80
            )

        case .interval:
            // I-pace: 95-100% VO2max. Work bout 3-5 min. Active recovery (jog).
            // Max volume: the lesser of 10K and 8% of weekly volume [1].
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
            // R-pace: pure speed, low aerobic stress.
            // Work bout max 2 min, FULL recovery (jog equal to work distance).
            // Introduced in Build before I: only adds speed stimulus [1] ch. 4.
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
                // Full recovery is essential: the next repetition
                // starts only when running mechanics are good again [1].
                scientificRationale: "R-pace (105-120% VDOT) migliora velocità, " +
                    "economia di corsa e potenza anaerobica. Work bout max 2 min, " +
                    "recupero completo (jog uguale al lavoro). Max 5% volume settimanale. " +
                    "Introdotto prima delle I (aggiunge solo stimolo velocità). " +
                    "Fonte: [1] cap. 4 – Repetition training.",
                rpe: "8-9",
                tss: sessionKm * 90
            )

        case .recovery:
            // Daniels does not define a separate recovery zone: E-pace covers
            // the full low-intensity range. This type uses the lower limit
            // of E-pace to signal a recovery run without creating a fictitious zone.
            return Workout(
                date: date, type: .recovery, week: week, dayOfWeek: day,
                title: "Corsa Facile (Recupero)",
                description: "Corsa molto leggera nell'intervallo basso dell'E-pace. " +
                             "Obiettivo: promuovere il recupero, non costruire fitness.",
                titleKind: .easyRecovery,
                descriptionKind: .easyRecovery,
                distanceKm: roundKm(max(4, kms * 0.65)),
                durationMinutes: nil,
                // Uses the lower limit of E-pace (not a fictitious slower pace).
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
            // Minimum 4 km: ensures space for 2 km warm-up + repeats + cool-down.
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
                distance: .tenK,  // .fiveK removed as target distance
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

    // R (Repetition) structure according to Daniels [1] ch. 4:
    // - Work bout max 2 minutes (200m, 300m, 400m, max 600-800m for high VDOT)
    // - FULL recovery: jog equal to the repetition distance (e.g. 400R → 400 jog)
    // - Purpose: speed and economy, NOT aerobic stress
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
            title: raceName,  // sfSymbol "trophy" already shown by WorkoutBadge
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
