---
layout: default
title: Getting Started
---

[Home](index)

# Getting Started

## Installation

RepMotion is distributed as a Swift Package. Add it to your project in Xcode via File > Add Package Dependencies, or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/thefern/RepMotion.git", from: "1.0.0")
]
```

Then add the libraries you need to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        "RepMotionCore",       // Data types only
        "RepMotionDetection",  // Detection + calibration + power
        "RepMotionCapture"     // Live sensor capture + fixtures
    ]
)
```

You don't need all three. If you're building your own capture layer, skip `RepMotionCapture`. If you only need the data types for a shared model layer, use `RepMotionCore` alone.

## Requirements

- Swift 5.9+
- iOS 17.0+ / watchOS 10.0+ / macOS 14.0+
- Combine framework

## First Integration

### 1. Capture motion data

Use `MotionCaptureService` to stream accelerometer and gyroscope samples from the device at a configurable sample rate (default 50 Hz):

```swift
import RepMotionCapture

let capture = MotionCaptureService(sampleRate: 50)
capture.start()
```

On watchOS, motion data comes from the Apple Watch accelerometer and gyroscope. On iOS, it comes from the iPhone's CoreMotion stack.

### 2. Detect reps

Pipe captured samples into `RepDetectionService`:

```swift
import Combine
import RepMotionDetection

let detector = RepDetectionService()
var cancellables = Set<AnyCancellable>()

capture.samplePublisher
    .sink { samples in
        detector.processBatch(samples)
    }
    .store(in: &cancellables)
```

### 3. React to rep events

Subscribe to the rep publisher to get notified each time a rep is detected:

```swift
detector.repPublisher
    .sink { event in
        print("Rep detected!")
        print("  Confidence: \(event.confidence)")
        print("  Peak acceleration: \(event.peakAcceleration)")
    }
    .store(in: &cancellables)
```

Each `RepEvent` includes:

| Property | Type | Description |
|----------|------|-------------|
| `timestamp` | `Date` | When the rep was detected |
| `confidence` | `Double` | 0.0 to 1.0 -- how far the peak exceeded the threshold |
| `peakAcceleration` | `Double` | Filtered peak value that triggered detection |

### 4. Clean up

```swift
capture.stop()
detector.reset()
```

## Next Steps

- [Architecture](architecture) -- understand the detection pipeline
- [Basic Detection](guides/basic-detection) -- tune detection parameters
- [Calibration](guides/calibration) -- auto-optimize for specific exercises
