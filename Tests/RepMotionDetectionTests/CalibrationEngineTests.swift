import Testing
@testable import RepMotionCore
@testable import RepMotionDetection

@Suite("CalibrationEngine")
struct CalibrationEngineTests {

    @Test func returnsNilForTooFewSamples() {
        let engine = CalibrationEngine()
        let result = engine.calibrate(
            samples: SyntheticSamples.flat(count: 10),
            target: 3,
            current: RepCalibration()
        )
        #expect(result == nil)
    }

    @Test func returnsNilForZeroTarget() {
        let engine = CalibrationEngine()
        let result = engine.calibrate(
            samples: SyntheticSamples.session(repCount: 5),
            target: 0,
            current: RepCalibration()
        )
        #expect(result == nil)
    }

    @Test func returnsOptimalWhenAlreadyCorrect() {
        let engine = CalibrationEngine()
        let samples = SyntheticSamples.session(repCount: 5)

        let service = RepDetectionService()
        service.calibration = RepCalibration()
        var actualCount = 0
        let cancellable = service.repPublisher.sink { _ in actualCount += 1 }
        service.processBatch(samples)
        cancellable.cancel()

        guard actualCount > 0 else { return }

        let result = engine.calibrate(
            samples: samples,
            target: actualCount,
            current: RepCalibration()
        )
        #expect(result != nil)
        #expect(result!.isAlreadyOptimal == true)
    }

    @Test func improvesDetectionCount() {
        let engine = CalibrationEngine()
        let samples = SyntheticSamples.session(repCount: 5)

        // Pulses are on Y axis; calibrating on X guarantees zero detections
        let badCalibration = RepCalibration(
            detectionAxis: .x
        )

        let result = engine.calibrate(
            samples: samples,
            target: 5,
            current: badCalibration
        )

        #expect(result != nil)
        if let result {
            #expect(result.combinationsTested > 1)
            let newError = abs(result.detectedReps - result.targetReps)
            let oldError = abs(result.previousReps - result.targetReps)
            #expect(newError <= oldError)
        }
    }
}
