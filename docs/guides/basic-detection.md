---
layout: default
title: Basic Detection
---

[Home](../index) / Guides

# Basic Detection

This guide covers how to configure `RepDetectionService` for different exercises and motion patterns.

## Default Configuration

`RepDetectionService` ships with defaults that work for many rowing and pulling exercises:

```swift
let detector = RepDetectionService()
// detector.calibration is already RepCalibration.default
```

The default calibration:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `alpha` | 0.2 | EMA smoothing factor |
| `thresholdMultiplier` | 1.5 | Multiplied by stddev for dynamic threshold |
| `refractoryPeriod` | 0.4s | Minimum time between reps |
| `detectionAxis` | `.y` | Which accelerometer axis to analyze |
| `peakPolarity` | `.positive` | Detect positive or negative peaks |
| `warmupDuration` | 5.0s | Warmup period before detection begins |
| `cooldownDuration` | 3.0s | Cooldown after exercise stops |

## Tuning Parameters

### Detection Axis

Different exercises produce their strongest signal on different axes. The axis depends on watch orientation and exercise movement:

```swift
detector.calibration.detectionAxis = .x  // lateral movements
detector.calibration.detectionAxis = .y  // vertical movements (default)
detector.calibration.detectionAxis = .z  // forward/backward movements
```

### Peak Polarity

Some exercises produce a strong positive peak per rep, others a strong negative peak:

```swift
detector.calibration.peakPolarity = .positive   // detect upward spikes
detector.calibration.peakPolarity = .negative    // detect downward spikes
```

### Sensitivity

Lower `thresholdMultiplier` = more sensitive (more detections, more false positives):

```swift
detector.calibration.thresholdMultiplier = 1.0  // sensitive
detector.calibration.thresholdMultiplier = 2.0  // conservative
```

### Refractory Period

Minimum time between reps. Set this based on the fastest expected rep speed:

```swift
detector.calibration.refractoryPeriod = 0.3  // fast exercises (jump rope)
detector.calibration.refractoryPeriod = 0.8  // slow exercises (deadlift)
```

### Smoothing

Controls how aggressively the filter smooths the raw signal:

```swift
detector.calibration.alpha = 0.1  // heavy smoothing, slower response
detector.calibration.alpha = 0.3  // light smoothing, faster response
```

### Warmup Duration

Time to wait before detecting reps. Allows the filter and statistics to stabilize:

```swift
detector.calibration.warmupDuration = 3.0   // shorter warmup
detector.calibration.warmupDuration = 0     // no warmup (immediate detection)
```

## Subscribing to Events

### Rep Events

```swift
detector.repPublisher
    .receive(on: DispatchQueue.main)
    .sink { event in
        repCount += 1
        lastConfidence = event.confidence
    }
    .store(in: &cancellables)
```

### RPM (Reps Per Minute)

Calculated over a rolling 30-second window:

```swift
detector.rpmPublisher
    .receive(on: DispatchQueue.main)
    .sink { rpm in
        currentRPM = rpm
    }
    .store(in: &cancellables)
```

### Warmup Countdown

Emits seconds remaining during the warmup period:

```swift
detector.warmupPublisher
    .receive(on: DispatchQueue.main)
    .sink { remaining in
        if remaining > 0 {
            statusLabel = "Warmup: \(Int(remaining))s"
        } else {
            statusLabel = "Detecting..."
        }
    }
    .store(in: &cancellables)
```

## Resetting

Call `reset()` between exercise sets or sessions to clear all internal state:

```swift
detector.reset()
```

This clears the sample buffer, filter state, rep timestamps, and warmup timer.

## SwiftUI Integration

```swift
class WorkoutViewModel: ObservableObject {
    @Published var repCount = 0
    @Published var rpm: Double = 0
    @Published var warmupRemaining: TimeInterval = 0

    private let capture = MotionCaptureService()
    private let detector = RepDetectionService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        capture.samplePublisher
            .sink { [weak self] in self?.detector.processBatch($0) }
            .store(in: &cancellables)

        detector.repPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.repCount += 1 }
            .store(in: &cancellables)

        detector.rpmPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.rpm = $0 }
            .store(in: &cancellables)

        detector.warmupPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.warmupRemaining = $0 }
            .store(in: &cancellables)
    }

    func startWorkout() {
        detector.reset()
        repCount = 0
        capture.start()
    }

    func stopWorkout() {
        capture.stop()
    }
}
```
