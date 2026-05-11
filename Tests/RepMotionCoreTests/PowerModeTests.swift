import Testing
@testable import RepMotionCore

@Suite("PowerMode")
struct PowerModeTests {

    @Test func allCases() {
        #expect(PowerMode.allCases.count == 3)
    }

    @Test func displayNames() {
        #expect(PowerMode.rollingAvg.displayName == "Rolling Avg")
        #expect(PowerMode.rollingMax.displayName == "Rolling Max")
        #expect(PowerMode.absolute.displayName == "Absolute (g)")
    }

    @Test func identifiable() {
        #expect(PowerMode.rollingAvg.id == "rollingAvg")
        #expect(PowerMode.rollingMax.id == "rollingMax")
        #expect(PowerMode.absolute.id == "absolute")
    }
}
