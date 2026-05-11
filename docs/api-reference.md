---
layout: default
title: API Reference
---

[Home](index)

# API Reference

Complete reference of all public types, methods, and properties in RepMotion.

## RepMotionCore

### MotionSample

A single sensor reading from the device.

```swift
public struct MotionSample: Sendable {
    public let timestamp: TimeInterval
    public let ax: Double, ay: Double, az: Double   // accelerometer (g-force)
    public let gx: Double, gy: Double, gz: Double   // gyroscope (rad/s)

    public init(
        timestamp: TimeInterval,
        ax: Double, ay: Double, az: Double,
        gx: Double = 0, gy: Double = 0, gz: Double = 0
    )

    public func toDictionary() -> [String: Any]
    public static func from(dictionary: [String: Any]) -> MotionSample?
}
```

### RepEvent

Emitted when a rep is detected.

```swift
public struct RepEvent: Sendable {
    public let timestamp: Date
    public let confidence: Double        // 0.0 to 1.0
    public let peakAcceleration: Double  // filtered peak value
}
```

### RepCalibration

Configuration for the detection algorithm.

```swift
public struct RepCalibration: Sendable {
    public var alpha: Double                // EMA smoothing (default: 0.2)
    public var thresholdMultiplier: Double   // stddev multiplier (default: 1.5)
    public var refractoryPeriod: Double      // min seconds between reps (default: 0.4)
    public var detectionAxis: DetectionAxis  // .x, .y, or .z (default: .y)
    public var peakPolarity: PeakPolarity    // .positive or .negative (default: .positive)
    public var warmupDuration: TimeInterval  // seconds before detection starts (default: 5.0)
    public var cooldownDuration: TimeInterval // seconds after exercise ends (default: 3.0)

    public static let `default` = RepCalibration()
}
```

### DetectionAxis

```swift
public enum DetectionAxis: String, CaseIterable, Identifiable, Sendable {
    case x = "X"
    case y = "Y"
    case z = "Z"
}
```

### PeakPolarity

```swift
public enum PeakPolarity: String, CaseIterable, Identifiable, Sendable {
    case positive = "Positive (+)"
    case negative = "Negative (-)"

    public var multiplier: Double  // 1.0 or -1.0
}
```

### RepMarker

Marks a rep position in a sample buffer. Identifiable for SwiftUI list rendering.

```swift
public struct RepMarker: Identifiable, Sendable {
    public let id: UUID
    public var bufferIndex: Int
    public let confidence: Double
}
```

### DetectionDiagnostic

Per-sample diagnostic data from the detection pipeline.

```swift
public struct DetectionDiagnostic: Sendable {
    public let sampleIndex: Int
    public let rawValue: Double       // axis value * polarity, before filtering
    public let filteredValue: Double  // after EMA smoothing
    public let threshold: Double      // dynamic threshold
    public let mean: Double           // rolling 100-sample mean
    public let stddev: Double         // rolling 100-sample stddev
}
```

### PowerReading

Power metrics for a single rep.

```swift
public struct PowerReading: Sendable {
    public let relativePower: Double       // rep peak / session peak (0.0-1.0)
    public let rollingAvgPower: Double     // rep peak / rolling 5-rep avg
    public let rollingMaxPower: Double     // rep peak / rolling 5-rep max
    public let peakAcceleration: Double    // raw peak this rep (g)
    public let repAvgAcceleration: Double  // rolling 5-rep avg (g)

    public func value(for mode: PowerMode) -> Double
}
```

### PowerMode

```swift
public enum PowerMode: String, CaseIterable, Identifiable, Sendable {
    case rollingAvg   // "Rolling Avg"
    case rollingMax   // "Rolling Max"
    case absolute     // "Absolute (g)"

    public var displayName: String
}
```

## RepMotionDetection

### RepDetectionService

The main detection engine. Processes motion samples and emits rep events.

```swift
public final class RepDetectionService {
    public var calibration: RepCalibration

    // Publishers
    public var repPublisher: AnyPublisher<RepEvent, Never>
    public var rpmPublisher: AnyPublisher<Double, Never>
    public var diagnosticPublisher: AnyPublisher<DetectionDiagnostic, Never>
    public var warmupPublisher: AnyPublisher<TimeInterval, Never>

    public init()
    public func processBatch(_ samples: [MotionSample])
    public func reset()
}
```

### CalibrationEngine

Optimizes detection parameters by replaying recorded sessions.

```swift
public struct CalibrationEngine: Sendable {
    public init()

    public func calibrate(
        samples: [MotionSample],
        target: Int,
        current: RepCalibration
    ) -> CalibrationResult?
}
```

### CalibrationResult

```swift
public struct CalibrationResult: Sendable {
    public let calibration: RepCalibration
    public let detectedReps: Int
    public let previousReps: Int
    public let targetReps: Int
    public let combinationsTested: Int
    public let perfectMatches: Int

    public var improvement: Int
    public var isAlreadyOptimal: Bool
}
```

### PowerEstimationService

Tracks acceleration magnitude across reps for power metrics.

```swift
public final class PowerEstimationService {
    public var powerPublisher: AnyPublisher<PowerReading, Never>

    public init()
    public func processBatch(_ samples: [MotionSample])
    public func consumeRepEvent(_ event: RepEvent)
    public func reset()
}
```

### DistanceEstimationService

Accumulates estimated distance from rep power.

```swift
public final class DistanceEstimationService {
    public static let defaultBaseMeters: Double  // 8.0

    public var distancePublisher: AnyPublisher<Double, Never>
    public private(set) var totalDistance: Double

    public init()
    public func addRep(power: Double)
    public func reset()
}
```

## RepMotionCapture

### MotionProvider

Protocol for motion data sources.

```swift
public protocol MotionProvider {
    var samplePublisher: AnyPublisher<[MotionSample], Never> { get }
    func start()
    func stop()
}
```

### MotionCaptureService

Live sensor capture via CoreMotion.

```swift
public final class MotionCaptureService: MotionProvider {
    public let sampleRate: Double

    public init(sampleRate: Double = 50.0)
    public var samplePublisher: AnyPublisher<[MotionSample], Never>
    public func start()
    public func stop()
}
```

### FixtureMotionProvider

Replays pre-recorded samples for testing.

```swift
public final class FixtureMotionProvider: MotionProvider {
    public init(
        samples: [MotionSample],
        batchSize: Int = 1,
        speedMultiplier: Double = 1.0
    )

    public var samplePublisher: AnyPublisher<[MotionSample], Never>
    public func start()       // async replay on timer
    public func stop()
    public func replayAll()   // synchronous, for unit tests
}
```
