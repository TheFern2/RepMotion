---
layout: default
title: RepMotion
---

# RepMotion

A Swift library for detecting repetitive motion patterns using Apple Watch accelerometer and gyroscope data. Count exercise reps, measure workout intensity, and auto-calibrate detection parameters -- all in real time.

## Features

- **Real-time rep detection** with adaptive thresholding and peak analysis
- **Auto-calibration** that optimizes detection parameters from labeled recordings
- **Power estimation** with rolling average, rolling max, and absolute modes
- **Distance estimation** based on rep power output
- **Diagnostic stream** for debugging and visualizing the detection pipeline
- **Fixture replay** for testing without hardware

## Quick Start

Add RepMotion to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/thefern/RepMotion.git", from: "0.1.0")
]
```

Add the libraries you need:

```swift
.target(
    name: "YourApp",
    dependencies: [
        "RepMotionCore",
        "RepMotionDetection",
        "RepMotionCapture"
    ]
)
```

## Minimal Example

```swift
import Combine
import RepMotionCore
import RepMotionDetection
import RepMotionCapture

let capture = MotionCaptureService(sampleRate: 50)
let detector = RepDetectionService()
var cancellables = Set<AnyCancellable>()
var repCount = 0

capture.samplePublisher
    .sink { detector.processBatch($0) }
    .store(in: &cancellables)

detector.repPublisher
    .sink { event in
        repCount += 1
        print("Rep \(repCount) — confidence: \(event.confidence)")
    }
    .store(in: &cancellables)

capture.start()
```

That's it. Ten lines to count reps from live sensor data.

## Platform Support

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 17.0           |
| watchOS  | 10.0           |
| macOS    | 14.0           |

## Modules

RepMotion ships as three independent libraries so you can import only what you need.

| Module | Purpose | Dependencies |
|--------|---------|--------------|
| `RepMotionCore` | Data types: `MotionSample`, `RepEvent`, `RepCalibration`, etc. | None |
| `RepMotionDetection` | Detection engine, calibration, power and distance estimation | `RepMotionCore` |
| `RepMotionCapture` | Live sensor capture via CoreMotion and fixture replay | `RepMotionCore` |

## Interactive Demo

**[Try the Signal Explorer](interactive)** -- adjust detection parameters with sliders and watch the pipeline process a simulated exercise session in real time. See how alpha, threshold, refractory period, axis, and polarity affect rep detection.

## Documentation

- [Getting Started](getting-started) -- installation, setup, first integration
- [Architecture](architecture) -- how the detection pipeline works
- [Interactive Signal Explorer](interactive) -- live parameter tuning visualization
- [Basic Detection](guides/basic-detection) -- using `RepDetectionService`
- [Calibration](guides/calibration) -- auto-tuning with `CalibrationEngine`
- [Power and Distance](guides/power-distance) -- workout intensity metrics
- [Testing](guides/testing) -- using `FixtureMotionProvider` for tests
- [Diagnostics](guides/diagnostics) -- debugging detection with the diagnostic stream
- [API Reference](api-reference) -- all public types and methods

## License

MIT. See [LICENSE](https://github.com/thefern/RepMotion/blob/main/LICENSE).
