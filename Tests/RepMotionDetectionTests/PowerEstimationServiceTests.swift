import Combine
import Foundation
import Testing
@testable import RepMotionCore
@testable import RepMotionDetection

@Suite("PowerEstimationService")
struct PowerEstimationServiceTests {

    @Test func firstRepIsFullRelativePower() {
        let service = PowerEstimationService()

        var reading: PowerReading?
        let cancellable = service.powerPublisher.sink { reading = $0 }

        service.processBatch(SyntheticSamples.magnitudeSamples(ax: 2.0))
        service.consumeRepEvent(RepEvent(timestamp: Date(), confidence: 1.0, peakAcceleration: 2.0))

        cancellable.cancel()
        #expect(reading != nil)
        #expect(reading!.relativePower == 1.0)
        #expect(reading!.peakAcceleration == 2.0)
    }

    @Test func relativePowerScalesWithSessionPeak() {
        let service = PowerEstimationService()

        var readings: [PowerReading] = []
        let cancellable = service.powerPublisher.sink { readings.append($0) }

        service.processBatch(SyntheticSamples.magnitudeSamples(ax: 2.0))
        service.consumeRepEvent(RepEvent(timestamp: Date(), confidence: 1.0, peakAcceleration: 2.0))

        service.processBatch(SyntheticSamples.magnitudeSamples(ax: 1.0))
        service.consumeRepEvent(RepEvent(timestamp: Date(), confidence: 0.8, peakAcceleration: 1.0))

        cancellable.cancel()
        #expect(readings.count == 2)
        #expect(readings[0].relativePower == 1.0)
        #expect(readings[1].relativePower == 0.5)
    }

    @Test func rollingAvgAccumulates() {
        let service = PowerEstimationService()

        var readings: [PowerReading] = []
        let cancellable = service.powerPublisher.sink { readings.append($0) }

        for peak in [1.0, 2.0, 3.0] {
            service.processBatch(SyntheticSamples.magnitudeSamples(ax: peak))
            service.consumeRepEvent(RepEvent(timestamp: Date(), confidence: 1.0, peakAcceleration: peak))
        }

        cancellable.cancel()
        #expect(readings.count == 3)
        #expect(readings[2].repAvgAcceleration == 2.0)
    }

    @Test func resetClearsState() {
        let service = PowerEstimationService()

        service.processBatch(SyntheticSamples.magnitudeSamples(ax: 5.0))
        service.consumeRepEvent(RepEvent(timestamp: Date(), confidence: 1.0, peakAcceleration: 5.0))
        service.reset()

        var reading: PowerReading?
        let cancellable = service.powerPublisher.sink { reading = $0 }

        service.processBatch(SyntheticSamples.magnitudeSamples(ax: 1.0))
        service.consumeRepEvent(RepEvent(timestamp: Date(), confidence: 1.0, peakAcceleration: 1.0))

        cancellable.cancel()
        #expect(reading != nil)
        #expect(reading!.relativePower == 1.0)
    }
}
