import Combine
import Testing
@testable import RepMotionDetection

@Suite("DistanceEstimationService")
struct DistanceEstimationServiceTests {

    @Test func singleRepAtFullPower() {
        let service = DistanceEstimationService()
        service.addRep(power: 1.0)
        #expect(service.totalDistance == 12.0) // 8 * (0.5 + 1.0)
    }

    @Test func singleRepAtZeroPower() {
        let service = DistanceEstimationService()
        service.addRep(power: 0.0)
        #expect(service.totalDistance == 4.0) // 8 * (0.5 + 0.0)
    }

    @Test func negativePowerClamps() {
        let service = DistanceEstimationService()
        service.addRep(power: -1.0)
        #expect(service.totalDistance == 0.0) // 8 * max(0, 0.5 + -1.0) = 0
    }

    @Test func accumulates() {
        let service = DistanceEstimationService()
        service.addRep(power: 1.0) // +12
        service.addRep(power: 0.5) // +8
        #expect(service.totalDistance == 20.0)
    }

    @Test func publishesDistance() {
        let service = DistanceEstimationService()

        var distances: [Double] = []
        let cancellable = service.distancePublisher.sink { distances.append($0) }

        service.addRep(power: 1.0)
        service.addRep(power: 0.5)

        cancellable.cancel()
        #expect(distances.contains(12.0))
        #expect(distances.contains(20.0))
    }

    @Test func resetClearsState() {
        let service = DistanceEstimationService()
        service.addRep(power: 1.0)
        service.reset()
        #expect(service.totalDistance == 0.0)
    }
}
