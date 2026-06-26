import XCTest
@testable import Personal_Best_Running

@MainActor
final class TrainingPlanGeneratorTests: XCTestCase {

    private var generator: TrainingPlanGenerator!

    override func setUp() {
        super.setUp()
        generator = TrainingPlanGenerator()
    }

    // MARK: - Helpers

    private func makeInput(
        distance: RaceDistance = .marathon,
        currentVDOT: Double = 40,
        raceDate: Date = Date().addingTimeInterval(16 * 7 * 24 * 3600),
        daysPerWeek: Int = 5,
        targetTime: TimeInterval = 4 * 3600,
        currentDistance: RaceDistance = .halfMarathon
    ) -> TrainingPlanInput {
        let currentPerformance = CurrentPerformance(
            distance: currentDistance,
            time: VDOTCalculator.predictRaceTime(vdot: currentVDOT, distance: currentDistance)
        )
        return TrainingPlanInput(
            raceDistance: distance,
            raceDate: raceDate,
            raceName: "Test Race",
            trainingDaysPerWeek: daysPerWeek,
            targetTime: targetTime,
            currentPerformance: currentPerformance,
            sex: .male
        )
    }

    // MARK: - Plan Structure

    func testGeneratesCorrectNumberOfWeeks() {
        let plan = generator.generate(input: makeInput(raceDate: Date().addingTimeInterval(16 * 7 * 24 * 3600)))
        XCTAssertGreaterThanOrEqual(plan.weeks.count, 12)
        XCTAssertLessThanOrEqual(plan.weeks.count, 24)
    }

    func testPlanNeverExceedsMaxWeeksForDistance() {
        let plan = generator.generate(input: makeInput(distance: .tenK, raceDate: Date().addingTimeInterval(30 * 7 * 24 * 3600)))
        XCTAssertLessThanOrEqual(plan.weeks.count, RaceDistance.tenK.maxPlanWeeks)
    }

    func testPlanHasMinimum12Weeks() {
        let plan = generator.generate(input: makeInput(raceDate: Date().addingTimeInterval(8 * 7 * 24 * 3600)))
        XCTAssertGreaterThanOrEqual(plan.weeks.count, 12)
    }

    func testWeekNumbersAreSequential() {
        let plan = generator.generate(input: makeInput())
        for (index, week) in plan.weeks.enumerated() {
            XCTAssertEqual(week.weekNumber, index + 1)
        }
    }

    // MARK: - Phase Structure

    func testPhasesAppearInCorrectOrder() {
        let plan = generator.generate(input: makeInput())
        let phases = plan.weeks.map { $0.phase }

        guard let firstBuild = phases.firstIndex(of: .build),
              let firstPeak = phases.firstIndex(of: .peak),
              let firstTaper = phases.firstIndex(of: .taper),
              let firstRace = phases.firstIndex(of: .race) else {
            return XCTFail("Missing expected phases")
        }

        XCTAssertLessThan(firstBuild, firstPeak)
        XCTAssertLessThan(firstPeak, firstTaper)
        XCTAssertLessThan(firstTaper, firstRace)
    }

    func testLastWeekIsRace() {
        let plan = generator.generate(input: makeInput())
        XCTAssertEqual(plan.weeks.last?.phase, .race)
    }

    func testBasePhaseHasNoIntervalWorkouts() {
        let plan = generator.generate(input: makeInput())
        let baseWeeks = plan.weeks.filter { $0.phase == .base }
        XCTAssertFalse(baseWeeks.isEmpty)
        for week in baseWeeks {
            let types = week.workouts.map { $0.type }
            XCTAssertFalse(types.contains(.interval), "Base phase should not contain interval workouts")
        }
    }

    func testBuildPhaseHasRepetitionWorkouts() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        let buildWeeks = plan.weeks.filter { $0.phase == .build }
        XCTAssertFalse(buildWeeks.isEmpty)
        let hasRepetition = buildWeeks.contains { week in
            week.workouts.contains { $0.type == .repetition }
        }
        XCTAssertTrue(hasRepetition, "Build phase should contain repetition workouts")
    }

    func testPeakPhaseHasQualityWorkouts() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        let peakWeeks = plan.weeks.filter { $0.phase == .peak }
        XCTAssertFalse(peakWeeks.isEmpty)
        for week in peakWeeks {
            let types = week.workouts.map { $0.type }
            let hasQuality = types.contains(.tempo) || types.contains(.interval) || types.contains(.marPace)
            XCTAssertTrue(hasQuality, "Peak phase should contain at least one quality workout type")
        }
    }

    func testTaperPhaseHasTempoMaintenance() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        let taperWeeks = plan.weeks.filter { $0.phase == .taper }
        XCTAssertFalse(taperWeeks.isEmpty)
        let hasTempo = taperWeeks.contains { week in
            week.workouts.contains { $0.type == .tempo }
        }
        XCTAssertTrue(hasTempo, "Taper should maintain at least one tempo session")
    }

    // MARK: - Weekly Volume

    func testBaseDeloadEveryFourthWeek() {
        let plan = generator.generate(input: makeInput())
        let baseWeeks = plan.weeks.enumerated().filter { $0.element.phase == .base }
        guard baseWeeks.count >= 4 else { return }

        let fourthWeek = baseWeeks[3]
        let thirdWeek = baseWeeks[2]
        XCTAssertLessThan(fourthWeek.element.totalKm, thirdWeek.element.totalKm,
                          "4th base week should be a deload (lower than 3rd week)")
    }

    func testTaperVolumeLowerThanPeak() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        let peakWeeks = plan.weeks.filter { $0.phase == .peak }
        let taperWeeks = plan.weeks.filter { $0.phase == .taper }
        guard !peakWeeks.isEmpty, !taperWeeks.isEmpty else { return }

        let avgPeak = peakWeeks.map { $0.totalKm }.reduce(0, +) / Double(peakWeeks.count)
        let avgTaper = taperWeeks.map { $0.totalKm }.reduce(0, +) / Double(taperWeeks.count)
        XCTAssertLessThan(avgTaper, avgPeak, "Taper volume should be lower than peak")
    }

    func testTaperVolumeReductionWithinDanielsRange() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        let peakWeeks = plan.weeks.filter { $0.phase == .peak }
        let taperWeeks = plan.weeks.filter { $0.phase == .taper }
        guard !peakWeeks.isEmpty, !taperWeeks.isEmpty else { return }

        let avgPeak = peakWeeks.map { $0.totalKm }.reduce(0, +) / Double(peakWeeks.count)
        let avgTaper = taperWeeks.map { $0.totalKm }.reduce(0, +) / Double(taperWeeks.count)
        let reduction = 1.0 - (avgTaper / avgPeak)
        XCTAssertGreaterThanOrEqual(reduction, 0.40)
        XCTAssertLessThanOrEqual(reduction, 0.60)
    }

    func testRaceWeekVolumeIsLowest() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        guard let raceWeek = plan.weeks.last else { return }
        let avgVolume = plan.weeks.dropLast().map { $0.totalKm }.reduce(0, +) / Double(plan.weeks.count - 1)
        XCTAssertLessThan(raceWeek.totalKm, avgVolume)
    }

    // MARK: - Long Run

    func testLongRunNeverExceedsMarathonCap() {
        let plan = generator.generate(input: makeInput(distance: .marathon, daysPerWeek: 6))
        for week in plan.weeks {
            for workout in week.workouts where workout.type == .longRun {
                XCTAssertLessThanOrEqual(workout.distanceKm ?? 0, 32.0,
                                         "Long run should not exceed 32 km for marathon")
            }
        }
    }

    func testLongRunNeverExceedsHMCap() {
        let plan = generator.generate(input: makeInput(distance: .halfMarathon, daysPerWeek: 5))
        for week in plan.weeks {
            for workout in week.workouts where workout.type == .longRun {
                XCTAssertLessThanOrEqual(workout.distanceKm ?? 0, 22.0,
                                         "Long run should not exceed 22 km for HM")
            }
        }
    }

    func testLongRunNeverExceeds10KCap() {
        let plan = generator.generate(input: makeInput(distance: .tenK, daysPerWeek: 4))
        for week in plan.weeks {
            for workout in week.workouts where workout.type == .longRun {
                XCTAssertLessThanOrEqual(workout.distanceKm ?? 0, 18.0,
                                         "Long run should not exceed 18 km for 10K")
            }
        }
    }

    func testLongRunPresentInEveryNonRaceWeek() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        for week in plan.weeks where week.phase != .race {
            let hasLongRun = week.workouts.contains { $0.type == .longRun }
            XCTAssertTrue(hasLongRun, "Week \(week.weekNumber) should have a long run")
        }
    }

    // MARK: - Workout Distribution

    func testEveryWeekHasRestDays() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        for week in plan.weeks {
            let hasRest = week.workouts.contains { $0.type == .rest }
            XCTAssertTrue(hasRest, "Week \(week.weekNumber) should have at least one rest day")
        }
    }

    func testTrainingDaysMatchRequestedCount() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 4))
        for week in plan.weeks.filter({ $0.phase != .race }) {
            let trainingDays = week.workouts.filter { $0.type != .rest }.count
            XCTAssertEqual(trainingDays, 4,
                           "Week \(week.weekNumber) should have 4 training days, got \(trainingDays)")
        }
    }

    func testWorkoutsAreSortedByDate() {
        let plan = generator.generate(input: makeInput())
        for week in plan.weeks {
            let dates = week.workouts.map { $0.date }
            XCTAssertEqual(dates, dates.sorted(), "Workouts should be sorted by date")
        }
    }

    // MARK: - VDOT Integration

    func testVdotCurrentMatchesPerformance() {
        let input = makeInput(currentVDOT: 45)
        let plan = generator.generate(input: input)
        XCTAssertEqual(plan.vdotCurrent, 45, accuracy: 1.0)
    }

    func testFeasibilityReflectsVdotGap() {
        let currentVDOT: Double = 45
        let predictedTime = VDOTCalculator.predictRaceTime(vdot: currentVDOT, distance: .marathon)
        let easyInput = makeInput(currentVDOT: currentVDOT, targetTime: predictedTime)
        let easyPlan = generator.generate(input: easyInput)
        XCTAssertEqual(easyPlan.feasibility, .realistic)

        let hardInput = makeInput(currentVDOT: 30, targetTime: 2 * 3600)
        let hardPlan = generator.generate(input: hardInput)
        XCTAssertEqual(hardPlan.feasibility, .extreme)
    }

    func testEstimatedRaceTimeIsReasonable() {
        let plan = generator.generate(input: makeInput(distance: .marathon, currentVDOT: 40))
        XCTAssertGreaterThan(plan.estimatedRaceTime, 3 * 3600)
        XCTAssertLessThan(plan.estimatedRaceTime, 6 * 3600)
    }

    // MARK: - TSS and RPE

    func testRestWorkoutsHaveZeroTSS() {
        let plan = generator.generate(input: makeInput())
        for week in plan.weeks {
            for workout in week.workouts where workout.type == .rest {
                XCTAssertEqual(workout.tss, 0, "Rest workout should have TSS = 0")
            }
        }
    }

    func testQualityWorkoutsHaveHigherTSSThanEasy() {
        let plan = generator.generate(input: makeInput(daysPerWeek: 5))
        var easyTSS: Double = 0
        var intervalTSS: Double = 0
        var easyCount = 0
        var intervalCount = 0

        for week in plan.weeks {
            for workout in week.workouts {
                switch workout.type {
                case .easy:
                    easyTSS += workout.tss
                    easyCount += 1
                case .interval:
                    intervalTSS += workout.tss
                    intervalCount += 1
                default:
                    break
                }
            }
        }

        if easyCount > 0 && intervalCount > 0 {
            let avgEasy = easyTSS / Double(easyCount)
            let avgInterval = intervalTSS / Double(intervalCount)
            XCTAssertGreaterThan(avgInterval, avgEasy,
                                 "Interval TSS should be higher than easy TSS")
        }
    }

    // MARK: - Scientific Sources

    func testScientificSourcesNotEmpty() {
        let plan = generator.generate(input: makeInput())
        XCTAssertFalse(plan.scientificSources.isEmpty)
        XCTAssertTrue(plan.scientificSources.contains { $0.contains("Daniels") })
    }

    // MARK: - Edge Cases

    func testBeginnerWithLowVDOTGeneratesPlan() {
        let input = makeInput(currentVDOT: 25, daysPerWeek: 3, targetTime: 5 * 3600)
        let plan = generator.generate(input: input)
        XCTAssertGreaterThan(plan.weeks.count, 0)
        XCTAssertNotEqual(plan.feasibility, .realistic)
    }

    func testEliteRunnerGeneratesPlan() {
        let input = makeInput(currentVDOT: 70, daysPerWeek: 6, targetTime: 2 * 3600 + 30 * 60)
        let plan = generator.generate(input: input)
        XCTAssertGreaterThan(plan.weeks.count, 0)
    }

    func testHalfMarathonPlanStructure() {
        let plan = generator.generate(input: makeInput(distance: .halfMarathon, daysPerWeek: 5))
        XCTAssertLessThanOrEqual(plan.weeks.count, 20)
        XCTAssertEqual(plan.weeks.last?.phase, .race)
    }

    func testTenKPlanStructure() {
        let plan = generator.generate(input: makeInput(distance: .tenK, daysPerWeek: 4))
        XCTAssertLessThanOrEqual(plan.weeks.count, 20)
        XCTAssertEqual(plan.weeks.last?.phase, .race)
    }
}
