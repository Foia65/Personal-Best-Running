import Foundation

// MARK: - Training Plan Generator
//
// Fonti scientifiche principali utilizzate nell'algoritmo:
//
// [1] Daniels J. (2014). Daniels' Running Formula (3rd ed.). Human Kinetics.
//     → VDOT system, pace zones, training types
//
// [2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.
//     → Piano a settimane, distribuzione volume, taper
//
// [3] Billat V. (2001). Interval Training for Performance. Sports Medicine, 31(1), 13-31.
//     → Interval training a VO2max, durata ripetizioni
//
// [4] Seiler S., Kjerland G.Ø. (2006). Quantifying training intensity distribution in elite
//     endurance athletes. Scandinavian Journal of Medicine & Science in Sports, 16(1), 49-56.
//     → Distribuzione polarizzata 80/20 (80% bassa intensità, 20% alta)
//
// [5] Laursen P.B., Jenkins D.G. (2002). The Scientific Basis for High-Intensity Interval
//     Training. Sports Medicine, 32(1), 53-73.
//     → HIT per miglioramento VO2max
//
// [6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering strategies.
//     Medicine & Science in Sports & Exercise, 35(7), 1182-1187.
//     → Taper: riduzione 40-60% volume, mantenimento intensità
//
// [7] Bompa T., Haff G. (2009). Periodization: Theory and Methodology of Training (5th ed.).
//     → Periodizzazione, fasi di allenamento
//
// [8] Galloway J. (2010). Running Until You're 100. Meyer & Meyer Sport.
//     → Progressione conservativa per prevenzione infortuni (regola del 10%)

class TrainingPlanGenerator {
    
    // MARK: - Regola del 10%
    // Fonte: [8] – non aumentare volume settimanale >10% rispetto alla settimana precedente
    static let maxWeeklyVolumeIncreasePercent: Double = 0.10
    
    // MARK: - Distribuzione polarizzata 80/20
    // Fonte: [4] Seiler & Kjerland (2006)
    // 80% allenamenti a bassa intensità, 20% ad alta intensità
    static let lowIntensityPercent: Double = 0.80
    static let highIntensityPercent: Double = 0.20
    
    // MARK: - Generate Plan
    // swiftlint:disable:next function_body_length
    func generate(input: TrainingPlanInput) -> TrainingPlan {
        let calendar = Calendar.current
        let today = Date()
        
        // Calcola VDOT corrente
        let currentVDOT = VDOTCalculator.calculate(
            timeInSeconds: input.currentPerformance.time,
            distanceMeters: input.currentPerformance.distance.meters
        )
        
        // Il VDOT è già una misura universale — lo stesso VDOT predice correttamente qualsiasi distanza tramite predictRaceTime. I vdotConversionFactor erano un'approssimazione errata che gonfiava il valore.
        let normalizedVDOT = currentVDOT

        // Calcola i ritmi di allenamento dal VDOT corrente
        let paces = VDOTCalculator.trainingPaces(vdot: normalizedVDOT, sex: input.sex)
        
        // Tempo stimato con VDOT attuale sulla distanza target
        let estimatedCurrent = VDOTCalculator.predictRaceTime(vdot: normalizedVDOT, distance: input.raceDistance)
        
        let estimatedPaceSecsPerKm = estimatedCurrent / input.raceDistance.meters * 1000
        
        // VDOT richiesto per il target
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
        let rawWeeks = calendar.dateComponents([.weekOfYear], from: today, to: input.raceDate).weekOfYear ?? 12
        let totalWeeks = min(input.raceDistance.maxPlanWeeks, max(12, rawWeeks))

        // Calcola la data di inizio piano contando a ritroso dalla gara
        let planStartDate = calendar.date(byAdding: .weekOfYear, value: -totalWeeks, to: input.raceDate)!
        
        // Struttura delle fasi (fonte: [7] Bompa periodizzazione)
        let phases = buildPhaseStructure(totalWeeks: totalWeeks, distance: input.raceDistance)
        
        // Volume base settimanale (stimato in km) dal numero giorni e livello
        let baseWeeklyKm = estimateBaseWeeklyKm(
            daysPerWeek: input.trainingDaysPerWeek,
            vdot: normalizedVDOT,
            distance: input.raceDistance
        )
        
        // Genera le settimane
        var weeks: [TrainingWeek] = []
        var prevWeekKm = baseWeeklyKm
        
        for week in 0..<totalWeeks {
            let weekPhase = phases[min(week, phases.count - 1)]
            let weekStartDate = calendar.date(byAdding: .weekOfYear, value: week, to: planStartDate)!
            let (weekKm, weekNote) = computeWeeklyVolume(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: weekPhase,
                baseKm: baseWeeklyKm,
                prevKm: prevWeekKm,
                distance: input.raceDistance
            )
            
            let targetPaceSecsPerKm = input.targetTime / input.raceDistance.meters * 1000
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
                targetPaceSecsPerKm: estimatedPaceSecsPerKm,
                estimatedPaceSecsPerKm: estimatedPaceSecsPerKm
            )
            
            let trWk = TrainingWeek(
                weekNumber: week + 1,
                phase: weekPhase,
                workouts: workouts,
                totalKm: weekKm,
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
    // Fonte: [7] Bompa – periodizzazione in macro-cicli
    private func buildPhaseStructure(totalWeeks: Int, distance: RaceDistance) -> [TrainingPhase] {
        
        // Proporzioni fasi per distanza
        // Maratona: base più lunga (Pfitzinger [2])
        // 5/10k: più velocità, meno volume base
        
        // swiftlint:disable:next large_tuple
        let phaseRatios: (base: Double, build: Double, peak: Double, taper: Double)
        switch distance {
        case .fiveK:
            phaseRatios = (0.30, 0.40, 0.20, 0.10)
        case .tenK:
            phaseRatios = (0.30, 0.38, 0.22, 0.10)
        case .halfMarathon:
            phaseRatios = (0.35, 0.38, 0.17, 0.10)
        case .marathon:
            phaseRatios = (0.40, 0.35, 0.15, 0.10)
        }
        
        let baseWeeks  = max(1, Int(Double(totalWeeks) * phaseRatios.base))
        let buildWeeks = max(1, Int(Double(totalWeeks) * phaseRatios.build))
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
    
    private func estimateBaseWeeklyKm(daysPerWeek: Int, vdot: Double, distance: RaceDistance) -> Double {
        // Stima volume base da livello fitness e giorni disponibili
        // Circa 8-12 km per sessione per principianti, 12-18 per intermedi, 18-25 per avanzati
        let kmPerSession: Double
        switch vdot {
        case ..<35: kmPerSession = 7.0
        case 35..<45: kmPerSession = 10.0
        case 45..<55: kmPerSession = 13.0
        default: kmPerSession = 16.0
        }
        
        // Aggiustamento per distanza gara
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
        prevKm: Double,
        distance: RaceDistance
    ) -> (Double, String) {
        
        let weekNum = weekIndex + 1
        var note = ""
        var kms: Double
        
        switch phase {
        case .base:
            // Progressione lineare con regola del 10% [8]
            // Ogni 4a settimana: settimana di scarico (-20%)
            if weekNum % 4 == 0 {
                kms = prevKm * 0.80
                note = "Settimana di scarico (↓20%). Fonte: principio di supercompensazione [7], recupero attivo."
            } else {
                kms = min(prevKm * 1.10, prevKm + baseKm * 0.10)
                note = "Costruzione aerobica: +10% max volume. Fonte: regola del 10% Galloway [8]."
            }
            
        case .build:
            // Mantieni volume alto, introduci qualità [2]
            if weekNum % 3 == 0 {
                kms = prevKm * 0.85
                note = "Micro-ciclo di scarico nel blocco sviluppo. Qualità mantenuta, volume -15%."
            } else {
                kms = min(prevKm * 1.08, baseKm * 1.40)
                note = "Sviluppo: intensità aumenta (Tempo + Interval). 80/20 distribuzione intensità [4]."
            }
            
        case .peak:
            // Picco: volume massimo o leggermente ridotto, qualità massima [2]
            kms = baseKm * 1.45
            note = "Picco di forma: massimo carico complessivo. Simulazione ritmo gara. Fonte: Pfitzinger [2]."
            
        case .taper:
            // Taper: -40% a -60% volume, mantenere intensità [6]
            // Fonte: Mujika & Padilla (2003)
            let taperProgress = Double(totalWeeks - weekIndex) / Double(totalWeeks)
            let taperFactor = 0.60 - (0.20 * taperProgress)
            kms = baseKm * max(0.40, taperFactor)
            note = "TAPER: volume ridotto (-40/60%), intensità invariata. Supercompensazione attesa. Fonte: Mujika & Padilla [6]."
            
        case .race:
            kms = baseKm * 0.30
            note = "Settimana di GARA: solo riscaldamenti leggeri fino alla gara."
        }
        
        return (max(20, kms), note)
    }
    
    // MARK: - Generate Week Workouts
    // swiftlint:disable:next function_body_length
    private func generateWeekWorkouts(
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
        targetPaceSecsPerKm: Double,
        estimatedPaceSecsPerKm: Double
    ) -> [Workout] {
        
        var workouts: [Workout] = []
        let calendar = Calendar.current
        
        // Assegna i giorni di allenamento nella settimana
        let trainingDayIndices = selectTrainingDays(daysPerWeek: daysPerWeek)
        
        // Definisci la struttura della settimana secondo fase e distanza
        let weekStructure = buildWeekStructure(
            phase: phase,
            daysPerWeek: daysPerWeek,
            distance: distance,
            weekIndex: weekIndex,
            totalWeeks: totalWeeks,
            vdotGap: vdotGap
        )
        
        // Calcola km per sessione
        let longRunKm = computeLongRunKm(weeklyKm: weeklyKm, distance: distance, phase: phase)
        let remainingKm = weeklyKm - longRunKm
        let otherSessionsCount = max(1, daysPerWeek - 1)
        let avgOtherKm = remainingKm / Double(otherSessionsCount)
        
        for (slotIndex, workoutType) in weekStructure.enumerated() {
            guard slotIndex < trainingDayIndices.count else { break }
            let dayOffset = trainingDayIndices[slotIndex]
            let workoutDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate)! // swiftlint:disable:this force_unwrapping
            
            // Check se è il giorno della gara
            let isRaceDay = calendar.isDate(workoutDate, inSameDayAs: raceDate)
            
            let workout: Workout
            if isRaceDay || (weekIndex == totalWeeks - 1 && slotIndex == weekStructure.count - 1) {
                workout = buildRaceWorkout(
                    date: raceDate,
                    raceName: raceName,
                    distance: distance,
                    paces: paces,
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
                    paces: paces,
                    distance: distance,
                    phase: phase,
                    weekIndex: weekIndex,
                    totalWeeks: totalWeeks
                )
            }
            workouts.append(workout)
        }
        
        // Aggiungi giorni di riposo
        let allDays = Set(0..<7)
        let restDays = allDays.subtracting(Set(trainingDayIndices))
        for dayOffset in restDays.sorted() {
            let restDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate)! // swiftlint:disable:this force_unwrapping
            let rest = Workout(
                date: restDate,
                type: .rest,
                week: weekIndex + 1,
                dayOfWeek: dayOffset,
                title: "Riposo",
                description: "Giorno di riposo completo o camminata leggera.",
                distanceKm: nil,
                durationMinutes: nil,
                paceTarget: nil,
                paceTargetSecsPerKm: nil,
                structuredSets: nil,
                scientificRationale: "Il riposo è componente fondamentale della supercompensazione. Fonte: Bompa & Haff [7].",
                rpe: "1",
                tss: 0
            )
            workouts.append(rest)
        }
        
        return workouts.sorted { $0.date < $1.date }
    }
    
    // MARK: - Day Selection
    
    private func selectTrainingDays(daysPerWeek: Int) -> [Int] {
        // Distribuisce i giorni in modo ottimale:
        // Evita back-to-back sessioni intense, assicura recupero
        // Fonte: [2] Pfitzinger – distribuzione settimanale ottimale
        switch daysPerWeek {
        case 3: return [0, 2, 5]          // Lun, Mer, Sab
        case 4: return [0, 2, 4, 6]       // Lun, Mer, Ven, Dom
        case 5: return [0, 1, 3, 4, 6]    // Lun, Mar, Gio, Ven, Dom
        case 6: return [0, 1, 2, 4, 5, 6] // Lun-Mer, Gio-Sab-Dom
        default: return [0, 2, 5]
        }
    }
    
    // MARK: - Week Structure (types per session)
    
    private func buildWeekStructure(
        phase: TrainingPhase,
        daysPerWeek: Int,
        distance: RaceDistance,
        weekIndex: Int,
        totalWeeks: Int,
        vdotGap: Double
    ) -> [WorkoutType] {
        
        switch phase {
        case .base:
            // Base: 80% easy, 20% progressione/colline – no interval pesanti [4]
            switch daysPerWeek {
            case 3: return [.easy, .progression, .longRun]
            case 4: return [.easy, .progression, .easy, .longRun]
            case 5: return [.easy, .hillRepeat, .easy, .progression, .longRun]
            case 6: return [.recovery, .easy, .hillRepeat, .easy, .progression, .longRun]
            default: return [.easy, .progression, .longRun]
            }
            
        case .build:
            // Build: introduzione tempo e interval [1][3]
            let hasInterval = vdotGap > 2 // Se gap grande, più lavoro qualità
            switch daysPerWeek {
            case 3: return [.tempo, hasInterval ? .interval : .easy, .longRun]
            case 4: return [.easy, .tempo, hasInterval ? .interval : .progression, .longRun]
            case 5: return [.easy, .tempo, .easy, .interval, .longRun]
            case 6: return [.recovery, .tempo, .easy, .interval, .easy, .longRun]
            default: return [.easy, .tempo, .longRun]
            }
            
        case .peak:
            // Peak: massima qualità + lungo specifico [2]
            let mpWork: WorkoutType = (distance == .marathon || distance == .halfMarathon) ? .marPace : .interval
            switch daysPerWeek {
            case 3: return [.tempo, mpWork, .longRun]
            case 4: return [.interval, .tempo, mpWork, .longRun]
            case 5: return [.easy, .interval, .tempo, mpWork, .longRun]
            case 6: return [.recovery, .interval, .tempo, .easy, mpWork, .longRun]
            default: return [.tempo, .interval, .longRun]
            }
            
        case .taper:
            // Taper: volume giù, mantenere alcune stimolazioni intense [6]
            switch daysPerWeek {
            case 3: return [.tempo, .easy, .longRun]
            case 4: return [.easy, .tempo, .easy, .longRun]
            case 5: return [.easy, .tempo, .easy, .interval, .easy]
            case 6: return [.recovery, .easy, .tempo, .easy, .easy, .easy]
            default: return [.easy, .tempo, .easy]
            }
            
        case .race:
            return [.easy, .easy, .race]
        }
    }
    
    // MARK: - Long Run KM
    
    private func computeLongRunKm(weeklyKm: Double, distance: RaceDistance, phase: TrainingPhase) -> Double {
        // Il lungo non supera il 30-33% del volume settimanale (Daniels [1])
        // O distanza massima raccomandata per distanza gara
        let maxFraction: Double = 0.33
        let absoluteMax: Double
        switch distance {
        case .fiveK:       absoluteMax = 14
        case .tenK:        absoluteMax = 18
        case .halfMarathon: absoluteMax = 22
        case .marathon:    absoluteMax = 35
        }
        return min(weeklyKm * maxFraction, absoluteMax)
    }
    
    // MARK: - Build Single Workout
    // swiftlint:disable:next function_body_length
    private func buildWorkout(
        type: WorkoutType,
        date: Date,
        week: Int,
        day: Int,
        kms: Double,
        paces: TrainingPaces,
        distance: RaceDistance,
        phase: TrainingPhase,
        weekIndex: Int,
        totalWeeks: Int
    ) -> Workout {
        
        switch type {
        case .easy:
            return Workout(
                date: date, type: .easy, week: week, dayOfWeek: day,
                title: "Corsa Facile",
                description: "Corsa a ritmo confortevole, respirazione controllata. Puoi parlare facilmente.",
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: paces.easyFormatted,
                paceTargetSecsPerKm: paces.easyPaceSecsPerKm,
                structuredSets: nil,
                scientificRationale: "L'80% del volume ad intensità facile sviluppa la base aerobica e mitocondri senza stress eccessivo. Fonte: Seiler & Kjerland [4].",
                rpe: "4-5",
                tss: kms * 40
            )
            
        case .longRun:
            let note = distance == .marathon ?
            "Negli ultimi \(Int(kms * 0.25)) km mantieni ritmo costante (non accelerare)." :
            "Ritmo uniforme, non più veloce di \(paces.easyFormatted)."
            return Workout(
                date: date, type: .longRun, week: week, dayOfWeek: day,
                title: "Lungo",
                description: "Corsa lunga a ritmo easy. \(note)",
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: paces.easyFormatted,
                paceTargetSecsPerKm: paces.easyPaceSecsPerKm,
                structuredSets: nil,
                scientificRationale: "Il lungo stimola adattamenti aerobici, aumenta glicogeno muscolare, migliora efficienza lipidica. Fondamentale per resistenza. Fonte: Daniels [1], Pfitzinger [2].",
                rpe: "5-6",
                tss: kms * 55
            )
            
        case .tempo:
            // Tempo run: 20-40 min a soglia lattato [1]
            // Fonte: Daniels – T-pace (Threshold pace)
            let tempoKm = min(kms * 0.55, distance == .marathon ? 14.0 : 10.0)
            let warmupKm = 2.0
            let cooldownKm = 2.0
            let mainKm = max(3, tempoKm - warmupKm - cooldownKm)
            return Workout(
                date: date, type: .tempo, week: week, dayOfWeek: day,
                title: "Tempo Run",
                description: "Corsa a ritmo soglia lattato: sforzo 'comfortably hard'. Riscaldamento 2 km, sezione principale, defaticamento 2 km.",
                distanceKm: roundKm(tempoKm),
                durationMinutes: nil,
                paceTarget: paces.thresholdFormatted,
                paceTargetSecsPerKm: paces.thresholdPaceSecsPerKm,
                structuredSets: "2 km riscaldamento + \(Int(mainKm)) km a \(paces.thresholdFormatted) + 2 km defaticamento",
                scientificRationale: "Il tempo run alla soglia anaerobica (circa 60 min di gara pace) migliora la capacità di eliminazione lattato. Fonte: Daniels [1] – T-pace zone.",
                rpe: "7-8",
                tss: tempoKm * 80
            )
            
        case .interval:
            // Interval training a VO2max [3][5]
            // Fonte: Billat – 30/30, 1km rip, 400m rip
            let (structure, _) = buildIntervalStructure(distance: distance, paces: paces, phase: phase)
            return Workout(
                date: date, type: .interval, week: week, dayOfWeek: day,
                title: "Interval Training",
                description: "Ripetute ad alta intensità (95-100% VO2max). Recupero attivo tra le ripetizioni.",
                distanceKm: roundKm(kms * 0.80),
                durationMinutes: nil,
                paceTarget: paces.intervalFormatted,
                paceTargetSecsPerKm: paces.intervalPaceSecsPerKm,
                structuredSets: structure,
                scientificRationale: "Interval training al VO2max aumenta gittata cardiaca, capillarizzazione e densità mitocondriale. Fonte: Billat [3], Laursen & Jenkins [5].",
                rpe: "8-9",
                tss: kms * 100
            )
            
        case .recovery:
            return Workout(
                date: date, type: .recovery, week: week, dayOfWeek: day,
                title: "Recupero Attivo",
                description: "Corsa molto leggera. L'obiettivo è promuovere il recupero attraverso circolazione attiva, non costruire fitness.",
                distanceKm: roundKm(max(4, kms * 0.6)),
                durationMinutes: nil,
                paceTarget: paces.recoveryFormatted,
                paceTargetSecsPerKm: paces.recoveryPaceSecsPerKm,
                structuredSets: nil,
                scientificRationale: "Il recupero attivo accelera la clearance del lattato e mantiene il flusso sanguigno nei muscoli. Fonte: principio di recupero attivo [7].",
                rpe: "3",
                tss: kms * 25
            )
            
        case .progression:
            // Corsa progressiva: inizia easy, finisce a ritmo MP o T-pace [2]
            let prog = buildProgressionDescription(kms: kms, paces: paces, distance: distance)
            return Workout(
                date: date, type: .progression, week: week, dayOfWeek: day,
                title: "Corsa Progressiva",
                description: "Inizia facile, aumenta gradualmente il ritmo ogni 2-3 km.",
                distanceKm: roundKm(kms),
                durationMinutes: nil,
                paceTarget: "Da \(paces.easyFormatted) a \(paces.thresholdFormatted)",
                paceTargetSecsPerKm: paces.thresholdPaceSecsPerKm,
                structuredSets: prog,
                scientificRationale: "La corsa progressiva abitua il corpo a correre a ritmi crescenti e allena sia il sistema aerobico che la soglia. Fonte: Pfitzinger [2].",
                rpe: "5-7",
                tss: kms * 65
            )
            
        case .hillRepeat:
            // Ripetute in salita: forza-velocità, ridotto impatto [2]
            let reps = distance == .marathon || distance == .halfMarathon ? "8-10" : "6-8"
            let hillLen = distance == .marathon ? "200m" : "150m"
            return Workout(
                date: date, type: .hillRepeat, week: week, dayOfWeek: day,
                title: "Ripetute in Salita",
                description: "Corsa in salita ad alta intensità. Recupero in discesa lenta.",
                distanceKm: roundKm(max(6, kms * 0.9)),
                durationMinutes: nil,
                paceTarget: "Sforzo 95% su salita",
                paceTargetSecsPerKm: nil,
                structuredSets: "2 km riscaldamento + \(reps) × \(hillLen) salita (pendenza 5-8%) + recupero discesa + 2 km defaticamento",
                scientificRationale: "Le ripetute in salita sviluppano forza-specifica corsa, migliorano la potenza e riducono il rischio di infortuni rispetto all'interval in piano. Fonte: Pfitzinger [2].",
                rpe: "8",
                tss: kms * 85
            )
            
        case .marPace:
            // Ritmo Maratona / Mezza
            let mpKm = distance == .marathon ? min(kms * 0.80, 28.0) : min(kms * 0.80, 16.0)
            let mpSection = max(5, mpKm - 4)
            return Workout(
                date: date, type: .marPace, week: week, dayOfWeek: day,
                title: "Ritmo Gara",
                description: "Sezione centrale al ritmo gara target. Ottimo per abituare fisicamente e mentalmente al passo.",
                distanceKm: roundKm(mpKm),
                durationMinutes: nil,
                paceTarget: distance == .marathon ? paces.mpFormatted : paces.thresholdFormatted,
                paceTargetSecsPerKm: distance == .marathon ? paces.marathonPaceSecsPerKm : paces.thresholdPaceSecsPerKm,
                structuredSets: "2 km riscaldamento + \(Int(mpSection)) km a ritmo gara + 2 km defaticamento",
                scientificRationale: "Le uscite al ritmo specifico di gara ottimizzano l'economia di corsa e la gestione del ritmo. Fonte: Pfitzinger [2], Daniels [1].",
                rpe: "7",
                tss: mpKm * 75
            )
            
        case .rest, .race: // fallback
            return buildRaceWorkout(
                date: date,
                raceName: "Gara",
                distance: .fiveK,
                paces: paces,
                targetPaceSecsPerKm: paces.thresholdPaceSecsPerKm,
                vdotGap: 0,    // ← NUOVO
                week: week, day: day
            )
        }
    }
    
    // MARK: - Interval Structure Builder
    
    private func buildIntervalStructure(distance: RaceDistance, paces: TrainingPaces, phase: TrainingPhase) -> (String, String) {
        // Fonte: Daniels [1] – I-pace (Interval pace)
        // Fonte: Billat [3] – vVO2max intervals
        switch distance {
        case .fiveK:
            // 5k: 400m o 800m rip – alta velocità, breve durata
            return ("2 km risc. + 6×600m a \(paces.intervalFormatted) (rec. 2' cammino) + 1 km def.",
                    "6×600m")
        case .tenK:
            // 10k: 1000m rip
            return ("2 km risc. + 5×1000m a \(paces.intervalFormatted) (rec. 2'30\" cammino) + 1 km def.",
                    "5×1000m")
        case .halfMarathon:
            // HM: misto 1200m + MP finale
            return ("2 km risc. + 4×1200m a \(paces.intervalFormatted) (rec. 3' cammino) + 1 km def.",
                    "4×1200m")
        case .marathon:
            // Maratona: meno interval puri, più 1600m
            return ("2 km risc. + 4×1600m a \(paces.intervalFormatted) (rec. 3' cammino) + 2 km def.",
                    "4×1600m")
        }
    }
    
    // MARK: - Progression Description
    
    private func buildProgressionDescription(kms: Double, paces: TrainingPaces, distance: RaceDistance) -> String {
        let third = max(1, Int(kms / 3))
        return "Km 1-\(third): \(paces.easyFormatted) | Km \(third+1)-\(third*2): \(paces.mpFormatted) | Km \(third*2+1)+: \(paces.thresholdFormatted)"
    }
    
    // MARK: - Race Workout
  
    private func buildRaceWorkout(
        date: Date,
        raceName: String,
        distance: RaceDistance,
        paces: TrainingPaces,
        targetPaceSecsPerKm: Double,
        vdotGap: Double,              // ← NUOVO
        week: Int,
        day: Int
    ) -> Workout {
        let mins = Int(targetPaceSecsPerKm) / 60
        let secs = Int(targetPaceSecsPerKm) % 60
        let racePaceFormatted = String(format: "%d:%02d /km", mins, secs)

        // Description dinamica basata sul gap VDOT
        let description: String
        switch vdotGap {
        case ..<(-5):
            // Target molto più lento della forma attuale
            description = "Giorno di gara! Il tuo obiettivo è molto conservativo rispetto alla tua forma attuale: potresti fare molto meglio. Parti controllato e valuta in corsa."
        case -5..<(-2):
            // Target leggermente più lento
            description = "Giorno di gara! Il tuo obiettivo è prudente rispetto alla forma attuale. Buona base per un risultato solido senza rischi."
        case -2..<2:
            // Target sostanzialmente allineato alla forma attuale
            description = "Giorno di gara! Il tuo obiettivo è allineato alla tua forma attuale. Esegui il piano di gara con fiducia: il lavoro fatto lo supporta."
        case 2..<5:
            // Target ambizioso ma raggiungibile
            description = "Giorno di gara! Il tuo obiettivo è ambizioso rispetto alla forma di partenza. Se il piano è andato bene, potresti farcela. Parti cauto nei primi km."
        case 5..<10:
            // Target molto ambizioso
            description = "Giorno di gara! Obiettivo sfidante rispetto alla forma di partenza. Considera questo una tappa di avvicinamento: corri al meglio della tua condizione attuale."
        default:
            // Gap enorme
            description = "Giorno di gara! L'obiettivo dichiarato era molto al di là della forma di partenza. Corri al tuo ritmo stimato e usa questa gara come esperienza."
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
            scientificRationale: "Gara come test performance e culmine del ciclo di allenamento.",
            rpe: "9-10",
            tss: 150
        )
    }
    
    // MARK: - Helpers
    
    private func roundKm(_ kms: Double) -> Double {
        (kms * 2).rounded() / 2  // arrotonda a 0.5 km
    }
    
    private func buildFitnessGapString(estimatedCurrent: Double, target: Double, vdotCurrent: Double, vdotTarget: Double) -> String {
        let diffSecs = target - estimatedCurrent
        let absDiff = abs(Int(diffSecs))
        let mins = absDiff / 60
        let secs = absDiff % 60
        let direction = diffSecs > 0 ? "più lento" : "più veloce"

        let feasibility: String
        if diffSecs >= 60 { // target più lento di almeno 1 minuto: obiettivo facile/conservativo
            feasibility = "Obiettivo conservativo ✅"
        } else if diffSecs > 0 { // target più lento ma meno di 1 minuto
            feasibility = "Obiettivo alla portata ✅"
        } else if abs(vdotTarget - vdotCurrent) < 5 {
            feasibility = "Obiettivo realistico ✅"
        } else if abs(vdotTarget - vdotCurrent) < 10 {
            feasibility = "Obiettivo ambizioso ⚠️"
        } else {
            feasibility = "Obiettivo molto sfidante ❗"
        }

        return "Il tuo VDOT attuale (sulla distanza target): \(String(format: "%.1f", vdotCurrent)) → VDOT richiesto per target: \(String(format: "%.1f", vdotTarget)). Tempo stimato attuale: \(formatTime(estimatedCurrent)). Il target è \(String(format: "%d:%02d", mins, secs)) \(direction). \(feasibility)"
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
            "[1] Daniels J. (2014). Daniels' Running Formula (3rd ed.). Human Kinetics.",
            "[2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.",
            "[3] Billat V. (2001). Interval Training for Performance. Sports Medicine, 31(1), 13-31.",
            "[4] Seiler S., Kjerland G.Ø. (2006). Quantifying training intensity distribution in elite endurance athletes. Scand. J. Med. Sci. Sports, 16(1), 49-56.",
            "[5] Laursen P.B., Jenkins D.G. (2002). The Scientific Basis for High-Intensity Interval Training. Sports Medicine, 32(1), 53-73.",
            "[6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering strategies. Medicine & Science in Sports & Exercise, 35(7), 1182-1187.",
            "[7] Bompa T., Haff G. (2009). Periodization: Theory and Methodology of Training (5th ed.). Human Kinetics.",
            "[8] Galloway J. (2010). Running Until You're 100. Meyer & Meyer Sport."
        ]
    }
}
