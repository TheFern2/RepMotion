import Combine
import Testing
@testable import RepMotionCapture
@testable import RepMotionCore

@Suite("FixtureMotionProvider")
struct FixtureMotionProviderTests {

    @Test func replayAllEmitsAllSamples() {
        let samples = (0..<10).map { i in
            MotionSample(timestamp: Double(i) * 0.02, ax: Double(i), ay: 0, az: 0)
        }
        let provider = FixtureMotionProvider(samples: samples, batchSize: 1)

        var received: [MotionSample] = []
        let cancellable = provider.samplePublisher.sink { batch in
            received.append(contentsOf: batch)
        }

        provider.replayAll()
        cancellable.cancel()

        #expect(received.count == 10)
        #expect(received.first?.ax == 0)
        #expect(received.last?.ax == 9)
    }

    @Test func replayAllRespectsBatchSize() {
        let samples = (0..<10).map { i in
            MotionSample(timestamp: Double(i) * 0.02, ax: 0, ay: 0, az: 0)
        }
        let provider = FixtureMotionProvider(samples: samples, batchSize: 3)

        var batchCount = 0
        var totalSamples = 0
        let cancellable = provider.samplePublisher.sink { batch in
            batchCount += 1
            totalSamples += batch.count
        }

        provider.replayAll()
        cancellable.cancel()

        #expect(batchCount == 4) // 3+3+3+1
        #expect(totalSamples == 10)
    }

    @Test func emptyFixtureDoesNothing() {
        let provider = FixtureMotionProvider(samples: [])

        var received = 0
        let cancellable = provider.samplePublisher.sink { _ in received += 1 }

        provider.replayAll()
        provider.start()
        provider.stop()
        cancellable.cancel()

        #expect(received == 0)
    }

    @Test func preservesSampleOrder() {
        let samples = (0..<5).map { i in
            MotionSample(timestamp: Double(i) * 0.5, ax: 0, ay: 0, az: 0)
        }
        let provider = FixtureMotionProvider(samples: samples, batchSize: 2)

        var timestamps: [Double] = []
        let cancellable = provider.samplePublisher.sink { batch in
            timestamps.append(contentsOf: batch.map(\.timestamp))
        }

        provider.replayAll()
        cancellable.cancel()

        #expect(timestamps == [0.0, 0.5, 1.0, 1.5, 2.0])
    }
}
