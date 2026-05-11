import Foundation
import Testing
@testable import RepMotionCore

@Suite("RepEvent")
struct RepEventTests {

    @Test func initProperties() {
        let date = Date()
        let event = RepEvent(timestamp: date, confidence: 0.85, peakAcceleration: 1.7)
        #expect(event.timestamp == date)
        #expect(event.confidence == 0.85)
        #expect(event.peakAcceleration == 1.7)
    }
}
