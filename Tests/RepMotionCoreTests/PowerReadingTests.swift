import Testing
@testable import RepMotionCore

@Suite("PowerReading")
struct PowerReadingTests {

    @Test func valueForMode() {
        let reading = PowerReading(
            relativePower: 0.8,
            rollingAvgPower: 1.1,
            rollingMaxPower: 0.95,
            peakAcceleration: 2.3,
            repAvgAcceleration: 1.9
        )
        #expect(reading.value(for: .rollingAvg) == 1.1)
        #expect(reading.value(for: .rollingMax) == 0.95)
        #expect(reading.value(for: .absolute) == 2.3)
    }
}
