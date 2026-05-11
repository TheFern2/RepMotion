---
layout: default
title: Power and Distance
---

[Home](../index) / Guides

# Power and Distance Estimation

RepMotion provides two services for workout intensity metrics: `PowerEstimationService` and `DistanceEstimationService`.

## Power Estimation

`PowerEstimationService` tracks acceleration magnitude across reps and produces relative power readings.

### Setup

```swift
let detector = RepDetectionService()
let power = PowerEstimationService()
var cancellables = Set<AnyCancellable>()

// Feed motion samples to both detector and power service
capture.samplePublisher
    .sink { samples in
        detector.processBatch(samples)
        power.processBatch(samples)
    }
    .store(in: &cancellables)

// Connect rep events to power service
detector.repPublisher
    .sink { event in
        power.consumeRepEvent(event)
    }
    .store(in: &cancellables)

// Subscribe to power readings
power.powerPublisher
    .receive(on: DispatchQueue.main)
    .sink { reading in
        updatePowerUI(reading)
    }
    .store(in: &cancellables)
```

### How It Works

1. `processBatch(_:)` tracks the peak acceleration magnitude (sqrt of ax^2 + ay^2 + az^2) between reps
2. When `consumeRepEvent(_:)` is called, the service:
   - Records the peak since the last rep
   - Updates the session-wide peak
   - Maintains a rolling window of the last 5 rep peaks
   - Emits a `PowerReading`

### PowerReading

| Property | Type | Description |
|----------|------|-------------|
| `relativePower` | `Double` | Current rep peak / session peak (0.0 to 1.0) |
| `rollingAvgPower` | `Double` | Current rep peak / rolling 5-rep average |
| `rollingMaxPower` | `Double` | Current rep peak / rolling 5-rep max |
| `peakAcceleration` | `Double` | Raw peak acceleration this rep (in g) |
| `repAvgAcceleration` | `Double` | Rolling 5-rep average acceleration |

### Power Modes

Use `PowerMode` to select which metric to display:

```swift
let mode: PowerMode = .rollingAvg

power.powerPublisher
    .sink { reading in
        let displayValue = reading.value(for: mode)
    }
    .store(in: &cancellables)
```

| Mode | Description | Use Case |
|------|-------------|----------|
| `.rollingAvg` | Ratio vs rolling average | Smooth, shows fatigue over time |
| `.rollingMax` | Ratio vs rolling max | Shows drop-off from recent peak |
| `.absolute` | Raw peak acceleration in g | Direct physical measurement |

## Distance Estimation

`DistanceEstimationService` accumulates an estimated distance based on rep power.

### Setup

```swift
let distance = DistanceEstimationService()

power.powerPublisher
    .sink { reading in
        distance.addRep(power: reading.relativePower)
    }
    .store(in: &cancellables)

distance.distancePublisher
    .receive(on: DispatchQueue.main)
    .sink { meters in
        distanceLabel = String(format: "%.0f m", meters)
    }
    .store(in: &cancellables)
```

### Formula

Each rep adds distance based on a base of 8 meters scaled by power:

```
distance += 8.0 * max(0, 0.5 + power)
```

At minimum power (0.0), each rep adds 4 meters. At full power (1.0), each rep adds 12 meters.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `totalDistance` | `Double` | Cumulative distance in meters |
| `distancePublisher` | `AnyPublisher<Double, Never>` | Emits updated total after each rep |

## Resetting

Both services support `reset()` to clear state between sessions:

```swift
power.reset()
distance.reset()
```

## Full Pipeline Example

```swift
let capture = MotionCaptureService()
let detector = RepDetectionService()
let power = PowerEstimationService()
let distance = DistanceEstimationService()
var cancellables = Set<AnyCancellable>()

// Wire the pipeline
capture.samplePublisher
    .sink { samples in
        detector.processBatch(samples)
        power.processBatch(samples)
    }
    .store(in: &cancellables)

detector.repPublisher
    .sink { event in
        power.consumeRepEvent(event)
    }
    .store(in: &cancellables)

power.powerPublisher
    .sink { reading in
        distance.addRep(power: reading.relativePower)
    }
    .store(in: &cancellables)

capture.start()
```
