import Combine
import Testing
@testable import RepMotionCore
@testable import RepMotionDetection

@Suite("RepDetectionService")
struct RepDetectionServiceTests {

    @Test func detectsRepsInSyntheticSession() {
        let service = RepDetectionService()
        service.calibration = RepCalibration(warmupDuration: 5.0)

        var repCount = 0
        let cancellable = service.repPublisher.sink { _ in repCount += 1 }

        let samples = SyntheticSamples.session(repCount: 5)
        service.processBatch(samples)

        cancellable.cancel()
        #expect(repCount >= 3 && repCount <= 7)
    }

    @Test func noRepsOnFlatSignal() {
        let service = RepDetectionService()
        service.calibration = RepCalibration(warmupDuration: 0)

        var repCount = 0
        let cancellable = service.repPublisher.sink { _ in repCount += 1 }

        let samples = SyntheticSamples.flat(count: 500)
        service.processBatch(samples)

        cancellable.cancel()
        #expect(repCount == 0)
    }

    @Test func warmupSuppressesEarlyReps() {
        let service = RepDetectionService()
        service.calibration = RepCalibration(warmupDuration: 10.0)

        var repCount = 0
        let cancellable = service.repPublisher.sink { _ in repCount += 1 }

        // Session is only ~5s of warmup + reps, so warmup hasn't elapsed
        var samples = SyntheticSamples.flat(count: 50)
        let pulseStart = samples.last!.timestamp + 0.02
        samples += SyntheticSamples.repPulse(startTime: pulseStart)
        service.processBatch(samples)

        cancellable.cancel()
        #expect(repCount == 0)
    }

    @Test func emitsRpm() {
        let service = RepDetectionService()
        service.calibration = RepCalibration(warmupDuration: 5.0)

        var lastRpm: Double?
        let cancellable = service.rpmPublisher.sink { lastRpm = $0 }

        let samples = SyntheticSamples.session(repCount: 3)
        service.processBatch(samples)

        cancellable.cancel()
        if let rpm = lastRpm {
            #expect(rpm > 0)
        }
    }

    @Test func emitsDiagnostics() {
        let service = RepDetectionService()
        service.calibration = RepCalibration(warmupDuration: 0)

        var diagnosticCount = 0
        let cancellable = service.diagnosticPublisher.sink { _ in diagnosticCount += 1 }

        let samples = SyntheticSamples.flat(count: 10)
        service.processBatch(samples)

        cancellable.cancel()
        #expect(diagnosticCount == 10)
    }

    @Test func resetClearsState() {
        let service = RepDetectionService()
        service.calibration = RepCalibration(warmupDuration: 5.0)

        let samples = SyntheticSamples.session(repCount: 3)
        service.processBatch(samples)
        service.reset()

        var repCount = 0
        let cancellable = service.repPublisher.sink { _ in repCount += 1 }

        let flatSamples = SyntheticSamples.flat(count: 100)
        service.processBatch(flatSamples)

        cancellable.cancel()
        #expect(repCount == 0)
    }
}
