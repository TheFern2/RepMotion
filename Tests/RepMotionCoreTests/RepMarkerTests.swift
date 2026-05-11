import Foundation
import Testing
@testable import RepMotionCore

@Suite("RepMarker")
struct RepMarkerTests {

    @Test func initProperties() {
        let marker = RepMarker(bufferIndex: 42, confidence: 0.9)
        #expect(marker.bufferIndex == 42)
        #expect(marker.confidence == 0.9)
        #expect(marker.id != UUID())
    }

    @Test func customId() {
        let id = UUID()
        let marker = RepMarker(bufferIndex: 0, confidence: 0.5, id: id)
        #expect(marker.id == id)
    }
}
