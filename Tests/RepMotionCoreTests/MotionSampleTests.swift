import Testing
@testable import RepMotionCore

@Suite("MotionSample")
struct MotionSampleTests {

    @Test func initWithDefaults() {
        let sample = MotionSample(timestamp: 1.0, ax: 0.1, ay: 0.2, az: 0.3)
        #expect(sample.timestamp == 1.0)
        #expect(sample.ax == 0.1)
        #expect(sample.ay == 0.2)
        #expect(sample.az == 0.3)
        #expect(sample.gx == 0)
        #expect(sample.gy == 0)
        #expect(sample.gz == 0)
    }

    @Test func initWithAllAxes() {
        let sample = MotionSample(timestamp: 2.0, ax: 0.1, ay: 0.2, az: 0.3, gx: 0.4, gy: 0.5, gz: 0.6)
        #expect(sample.gx == 0.4)
        #expect(sample.gy == 0.5)
        #expect(sample.gz == 0.6)
    }

    @Test func dictionaryRoundTrip() {
        let original = MotionSample(timestamp: 3.5, ax: 1.0, ay: -0.5, az: 0.8, gx: 0.1, gy: 0.2, gz: 0.3)
        let dict = original.toDictionary()
        let restored = MotionSample.from(dictionary: dict)

        #expect(restored != nil)
        #expect(restored?.timestamp == original.timestamp)
        #expect(restored?.ax == original.ax)
        #expect(restored?.ay == original.ay)
        #expect(restored?.az == original.az)
        #expect(restored?.gx == original.gx)
        #expect(restored?.gy == original.gy)
        #expect(restored?.gz == original.gz)
    }

    @Test func fromDictionaryMissingRequiredKeys() {
        let incomplete: [String: Any] = ["ts": 1.0, "ax": 0.1]
        #expect(MotionSample.from(dictionary: incomplete) == nil)
    }

    @Test func fromDictionaryMissingGyro() {
        let dict: [String: Any] = ["ts": 1.0, "ax": 0.1, "ay": 0.2, "az": 0.3]
        let sample = MotionSample.from(dictionary: dict)
        #expect(sample != nil)
        #expect(sample?.gx == 0)
        #expect(sample?.gy == 0)
        #expect(sample?.gz == 0)
    }
}
