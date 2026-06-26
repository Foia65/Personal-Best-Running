import XCTest
@testable import Personal_Best_Running

@MainActor
final class TrainingModelsTests: XCTestCase {

    // MARK: - GoalFeasibility

    func testGoalFeasibilityConservative() {
        XCTAssertEqual(GoalFeasibility.from(vdotGap: -10), .conservative)
        XCTAssertEqual(GoalFeasibility.from(vdotGap: -5.1), .conservative)
    }

    func testGoalFeasibilityPrudent() {
        XCTAssertEqual(GoalFeasibility.from(vdotGap: -5), .prudent)
        XCTAssertEqual(GoalFeasibility.from(vdotGap: -3), .prudent)
        XCTAssertEqual(GoalFeasibility.from(vdotGap: -2.1), .prudent)
    }

    func testGoalFeasibilityRealistic() {
        XCTAssertEqual(GoalFeasibility.from(vdotGap: -2), .realistic)
        XCTAssertEqual(GoalFeasibility.from(vdotGap: 0), .realistic)
        XCTAssertEqual(GoalFeasibility.from(vdotGap: 1.9), .realistic)
    }

    func testGoalFeasibilityAmbitious() {
        XCTAssertEqual(GoalFeasibility.from(vdotGap: 2), .ambitious)
        XCTAssertEqual(GoalFeasibility.from(vdotGap: 4.9), .ambitious)
    }

    func testGoalFeasibilityChallenging() {
        XCTAssertEqual(GoalFeasibility.from(vdotGap: 5), .challenging)
        XCTAssertEqual(GoalFeasibility.from(vdotGap: 9.9), .challenging)
    }

    func testGoalFeasibilityExtreme() {
        XCTAssertEqual(GoalFeasibility.from(vdotGap: 10), .extreme)
        XCTAssertEqual(GoalFeasibility.from(vdotGap: 20), .extreme)
    }

    func testGoalFeasibilityColorMapping() {
        XCTAssertEqual(GoalFeasibility.conservative.color, .green)
        XCTAssertEqual(GoalFeasibility.prudent.color, .green)
        XCTAssertEqual(GoalFeasibility.realistic.color, .green)
        XCTAssertEqual(GoalFeasibility.ambitious.color, .orange)
        XCTAssertEqual(GoalFeasibility.challenging.color, .orange)
        XCTAssertEqual(GoalFeasibility.extreme.color, .red)
    }

    func testGoalFeasibilitySfSymbol() {
        XCTAssertEqual(GoalFeasibility.conservative.sfSymbol, "checkmark.seal.fill")
        XCTAssertEqual(GoalFeasibility.extreme.sfSymbol, "exclamationmark.triangle.fill")
    }

    // MARK: - RunnerSex / RunnerLevel

    func testMaleRunnerLevelThresholds() {
        let male = RunnerSex.male
        XCTAssertEqual(male.runnerLevel(vdot: 30), .beginner)
        XCTAssertEqual(male.runnerLevel(vdot: 35), .recreational)
        XCTAssertEqual(male.runnerLevel(vdot: 45), .intermediate)
        XCTAssertEqual(male.runnerLevel(vdot: 55), .advanced)
        XCTAssertEqual(male.runnerLevel(vdot: 65), .elite)
    }

    func testFemaleRunnerLevelThresholds() {
        let female = RunnerSex.female
        XCTAssertEqual(female.runnerLevel(vdot: 25), .beginner)
        XCTAssertEqual(female.runnerLevel(vdot: 30), .recreational)
        XCTAssertEqual(female.runnerLevel(vdot: 40), .intermediate)
        XCTAssertEqual(female.runnerLevel(vdot: 50), .advanced)
        XCTAssertEqual(female.runnerLevel(vdot: 60), .elite)
    }

    func testRunnerSexLabels() {
        XCTAssertEqual(RunnerSex.male.label, "Uomo")
        XCTAssertEqual(RunnerSex.female.label, "Donna")
    }

    // MARK: - UnitSystem Conversions

    func testMetricDistanceConversion() {
        let metric = UnitSystem.metric
        XCTAssertEqual(metric.displayDistance(10), 10, accuracy: 0.001)
        XCTAssertEqual(metric.distanceUnit, "km")
    }

    func testImperialDistanceConversion() {
        let imperial = UnitSystem.imperial
        XCTAssertEqual(imperial.displayDistance(10), 6.21371, accuracy: 0.001)
        XCTAssertEqual(imperial.distanceUnit, "mi")
    }

    func testMetricPaceConversion() {
        let metric = UnitSystem.metric
        XCTAssertEqual(metric.displayPace(300), 300, accuracy: 0.001)
        XCTAssertEqual(metric.paceUnit, "/km")
    }

    func testImperialPaceConversion() {
        let imperial = UnitSystem.imperial
        XCTAssertEqual(imperial.displayPace(300), 482.803, accuracy: 0.001)
        XCTAssertEqual(imperial.paceUnit, "/mi")
    }

    func testFormatPaceMetric() {
        let metric = UnitSystem.metric
        XCTAssertEqual(metric.formatPace(300), "5:00 /km")
        XCTAssertEqual(metric.formatPace(299), "4:59 /km")
    }

    func testFormatDistance() {
        XCTAssertEqual(UnitSystem.metric.formatDistance(5.0), "5.0 km")
        XCTAssertEqual(UnitSystem.imperial.formatDistance(10.0), "6.2 mi")
    }

    // MARK: - RaceDistance

    func testRaceDistanceMeters() {
        XCTAssertEqual(RaceDistance.fiveK.meters, 5000)
        XCTAssertEqual(RaceDistance.tenK.meters, 10000)
        XCTAssertEqual(RaceDistance.halfMarathon.meters, 21097.5)
        XCTAssertEqual(RaceDistance.marathon.meters, 42195)
    }

    func testRaceDistanceMaxPlanWeeks() {
        XCTAssertEqual(RaceDistance.fiveK.maxPlanWeeks, 16)
        XCTAssertEqual(RaceDistance.tenK.maxPlanWeeks, 20)
        XCTAssertEqual(RaceDistance.halfMarathon.maxPlanWeeks, 20)
        XCTAssertEqual(RaceDistance.marathon.maxPlanWeeks, 24)
    }

    func testTargetDistancesExcludesFiveK() {
        let targets = RaceDistance.targetDistances
        XCTAssertFalse(targets.contains(.fiveK))
        XCTAssertTrue(targets.contains(.tenK))
        XCTAssertTrue(targets.contains(.halfMarathon))
        XCTAssertTrue(targets.contains(.marathon))
    }

    func testVdotConversionFactors() {
        XCTAssertEqual(RaceDistance.fiveK.vdotConversionFactor, 1.0)
        XCTAssertEqual(RaceDistance.tenK.vdotConversionFactor, 0.9832, accuracy: 0.0001)
        XCTAssertEqual(RaceDistance.halfMarathon.vdotConversionFactor, 0.9512, accuracy: 0.0001)
        XCTAssertEqual(RaceDistance.marathon.vdotConversionFactor, 0.9090, accuracy: 0.0001)
    }

    // MARK: - WorkoutType

    func testWorkoutTypeDanielsCode() {
        XCTAssertEqual(WorkoutType.easy.danielsCode, "E")
        XCTAssertEqual(WorkoutType.longRun.danielsCode, "E")
        XCTAssertEqual(WorkoutType.marPace.danielsCode, "M")
        XCTAssertEqual(WorkoutType.tempo.danielsCode, "T")
        XCTAssertEqual(WorkoutType.interval.danielsCode, "I")
        XCTAssertEqual(WorkoutType.repetition.danielsCode, "R")
        XCTAssertEqual(WorkoutType.rest.danielsCode, "")
        XCTAssertEqual(WorkoutType.race.danielsCode, "")
    }

    func testWorkoutTypeZoneLabel() {
        XCTAssertEqual(WorkoutType.easy.zoneLabel, "Z2")
        XCTAssertEqual(WorkoutType.marPace.zoneLabel, "Z3")
        XCTAssertEqual(WorkoutType.tempo.zoneLabel, "Z4")
        XCTAssertEqual(WorkoutType.interval.zoneLabel, "Z5")
        XCTAssertEqual(WorkoutType.repetition.zoneLabel, "Z5+")
        XCTAssertEqual(WorkoutType.rest.zoneLabel, "—")
    }

    func testWorkoutTypeMaxSessionFraction() {
        XCTAssertEqual(WorkoutType.longRun.maxSessionFractionOfWeeklyVolume, 0.25)
        XCTAssertEqual(WorkoutType.tempo.maxSessionFractionOfWeeklyVolume, 0.10)
        XCTAssertEqual(WorkoutType.interval.maxSessionFractionOfWeeklyVolume, 0.08)
        XCTAssertEqual(WorkoutType.repetition.maxSessionFractionOfWeeklyVolume, 0.05)
        XCTAssertNil(WorkoutType.easy.maxSessionFractionOfWeeklyVolume)
        XCTAssertNil(WorkoutType.rest.maxSessionFractionOfWeeklyVolume)
    }

    func testWorkoutTypeRecommendedPhases() {
        XCTAssertEqual(WorkoutType.easy.recommendedPhases, [.base, .build, .peak, .taper, .race])
        XCTAssertEqual(WorkoutType.repetition.recommendedPhases, [.build, .peak])
        XCTAssertEqual(WorkoutType.interval.recommendedPhases, [.peak])
        XCTAssertEqual(WorkoutType.race.recommendedPhases, [.race])
    }

    // MARK: - VDOTCalculator

    func testVdotCalculationMarathon() {
        let vdot = VDOTCalculator.calculate(timeInSeconds: 3 * 3600, distanceMeters: 42195)
        XCTAssertGreaterThan(vdot, 40)
        XCTAssertLessThan(vdot, 60)
    }

    func testVdotCalculationFiveK() {
        let vdot = VDOTCalculator.calculate(timeInSeconds: 20 * 60, distanceMeters: 5000)
        XCTAssertGreaterThan(vdot, 30)
        XCTAssertLessThan(vdot, 55)
    }

    func testVdotClampedToValidRange() {
        let veryFast = VDOTCalculator.calculate(timeInSeconds: 10 * 60, distanceMeters: 5000)
        XCTAssertLessThanOrEqual(veryFast, 85)
        let verySlow = VDOTCalculator.calculate(timeInSeconds: 60 * 60, distanceMeters: 5000)
        XCTAssertGreaterThanOrEqual(verySlow, 20)
    }

    func testTrainingPacesOrdering() {
        let paces = VDOTCalculator.trainingPaces(vdot: 40)
        XCTAssertGreaterThan(paces.easyPaceSecsPerKm, paces.marathonPaceSecsPerKm)
        XCTAssertGreaterThan(paces.marathonPaceSecsPerKm, paces.thresholdPaceSecsPerKm)
        XCTAssertGreaterThan(paces.thresholdPaceSecsPerKm, paces.intervalPaceSecsPerKm)
        XCTAssertGreaterThan(paces.intervalPaceSecsPerKm, paces.repetitionPaceSecsPerKm)
    }

    func testPredictRaceTimeRoundTrip() {
        let originalVdot: Double = 45
        let predicted = VDOTCalculator.predictRaceTime(vdot: originalVdot, distance: .marathon)
        let recalculated = VDOTCalculator.calculate(timeInSeconds: predicted, distanceMeters: RaceDistance.marathon.meters)
        XCTAssertEqual(originalVdot, recalculated, accuracy: 0.5)
    }

    func testTrainingPacesFormatting() {
        let paces = VDOTCalculator.trainingPaces(vdot: 40)
        XCTAssertTrue(paces.easyFormatted.contains("/km"))
        XCTAssertTrue(paces.mpFormatted.contains("/km"))
    }

    // MARK: - TrainingPhase

    func testTrainingPhaseRawValues() {
        XCTAssertEqual(TrainingPhase.base.rawValue, "Fase Base")
        XCTAssertEqual(TrainingPhase.build.rawValue, "Fase di Sviluppo")
        XCTAssertEqual(TrainingPhase.peak.rawValue, "Fase di Picco")
        XCTAssertEqual(TrainingPhase.taper.rawValue, "Scarico")
        XCTAssertEqual(TrainingPhase.race.rawValue, "Gara")
    }

    func testTrainingPhaseDescriptions() {
        XCTAssertTrue(TrainingPhase.base.description.contains("aerobica"))
        XCTAssertTrue(TrainingPhase.taper.description.contains("Riduzione"))
        XCTAssertTrue(TrainingPhase.race.description.contains("gara"))
    }

    func testTrainingPhaseMethodologySection() {
        XCTAssertEqual(TrainingPhase.base.methodologySection, .phaseBase)
        XCTAssertEqual(TrainingPhase.build.methodologySection, .phaseBuild)
        XCTAssertEqual(TrainingPhase.peak.methodologySection, .phasePeak)
        XCTAssertEqual(TrainingPhase.taper.methodologySection, .taper)
        XCTAssertEqual(TrainingPhase.race.methodologySection, .sources)
    }
}
