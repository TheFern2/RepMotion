import Testing
@testable import RepMotionCore

@Suite("RepCalibration")
struct RepCalibrationTests {

    @Test func defaultValues() {
        let cal = RepCalibration()
        #expect(cal.alpha == 0.2)
        #expect(cal.thresholdMultiplier == 1.5)
        #expect(cal.refractoryPeriod == 0.4)
        #expect(cal.detectionAxis == .y)
        #expect(cal.peakPolarity == .positive)
        #expect(cal.warmupDuration == 5.0)
        #expect(cal.cooldownDuration == 3.0)
    }

    @Test func staticDefault() {
        let cal = RepCalibration.default
        #expect(cal.alpha == 0.2)
        #expect(cal.detectionAxis == .y)
    }

    @Test func customInit() {
        let cal = RepCalibration(
            alpha: 0.1,
            thresholdMultiplier: 2.0,
            refractoryPeriod: 0.6,
            detectionAxis: .z,
            peakPolarity: .negative,
            warmupDuration: 3.0,
            cooldownDuration: 1.0
        )
        #expect(cal.alpha == 0.1)
        #expect(cal.thresholdMultiplier == 2.0)
        #expect(cal.refractoryPeriod == 0.6)
        #expect(cal.detectionAxis == .z)
        #expect(cal.peakPolarity == .negative)
        #expect(cal.warmupDuration == 3.0)
        #expect(cal.cooldownDuration == 1.0)
    }

    @Test func detectionAxisAllCases() {
        let axes = DetectionAxis.allCases
        #expect(axes.count == 3)
        #expect(axes.contains(.x))
        #expect(axes.contains(.y))
        #expect(axes.contains(.z))
    }

    @Test func peakPolarityMultiplier() {
        #expect(PeakPolarity.positive.multiplier == 1.0)
        #expect(PeakPolarity.negative.multiplier == -1.0)
    }
}
