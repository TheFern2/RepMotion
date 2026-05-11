---
layout: default
title: Testing
---

[Home](../index) / Guides

# Testing with FixtureMotionProvider

`FixtureMotionProvider` replays pre-recorded or synthetic motion data without requiring real hardware. Use it for unit tests, SwiftUI previews, and demos.

## Creating Synthetic Samples

Generate a sine wave to simulate repetitive motion:

```swift
func makeSamples(repCount: Int, frequency: Double = 1.5, sampleRate: Double = 50) -> [MotionSample] {
    let duration = Double(repCount) / frequency + 6.0  // add warmup time
    let totalSamples = Int(duration * sampleRate)

    return (0..<totalSamples).map { i in
        let t = Double(i) / sampleRate
        let y = sin(2 * .pi * frequency * t)
        return MotionSample(timestamp: t, ax: 0, ay: y, az: 0)
    }
}
```

## Using FixtureMotionProvider

### In Unit Tests

Use `replayAll()` for synchronous playback in tests:

```swift
func testDetectsReps() {
    let samples = makeSamples(repCount: 10)
    let fixture = FixtureMotionProvider(samples: samples, batchSize: 10)
    let detector = RepDetectionService()
    var repCount = 0

    let cancellable = fixture.samplePublisher
        .sink { batch in
            detector.processBatch(batch)
        }

    let repCancellable = detector.repPublisher
        .sink { _ in repCount += 1 }

    fixture.replayAll()

    XCTAssertEqual(repCount, 10, accuracy: 2)
}
```

### In SwiftUI Previews

Use real-time replay with a speed multiplier for previews and demos:

```swift
let fixture = FixtureMotionProvider(
    samples: preloadedSamples,
    batchSize: 1,
    speedMultiplier: 2.0  // 2x playback speed
)

fixture.start()  // begins async replay on a timer
// ...
fixture.stop()   // cancel when done
```

### Constructor Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `samples` | `[MotionSample]` | required | The samples to replay |
| `batchSize` | `Int` | 1 | Samples emitted per tick |
| `speedMultiplier` | `Double` | 1.0 | Playback speed (2.0 = twice as fast) |

## MotionProvider Protocol

Both `MotionCaptureService` and `FixtureMotionProvider` conform to `MotionProvider`:

```swift
public protocol MotionProvider {
    var samplePublisher: AnyPublisher<[MotionSample], Never> { get }
    func start()
    func stop()
}
```

Use this protocol to swap between real and fixture providers in your app:

```swift
class WorkoutViewModel: ObservableObject {
    private let provider: MotionProvider
    private let detector = RepDetectionService()

    init(provider: MotionProvider) {
        self.provider = provider
        provider.samplePublisher
            .sink { [weak self] in self?.detector.processBatch($0) }
            .store(in: &cancellables)
    }

    func start() { provider.start() }
    func stop() { provider.stop() }
}

// Production
let vm = WorkoutViewModel(provider: MotionCaptureService())

// Tests / Previews
let vm = WorkoutViewModel(provider: FixtureMotionProvider(samples: testData))
```

## Tips

- `replayAll()` is synchronous -- it emits all batches immediately without timers. Use it in tests where you need deterministic behavior.
- `start()` uses a `DispatchSourceTimer` and emits batches at the original sample interval scaled by `speedMultiplier`. Use it for real-time demos.
- The minimum `speedMultiplier` is clamped to 0.1 to prevent near-zero intervals.
