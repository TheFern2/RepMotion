---
layout: default
title: Calibration
---

[Home](../index) / Guides

# Calibration

`CalibrationEngine` automatically finds optimal detection parameters for a specific exercise by replaying a recorded motion session against a known rep count.

## How It Works

The engine runs a two-pass optimization:

```
Pass 1: Coarse Search
  - Tests all combinations of:
    - 9 threshold multipliers (0.5 to 2.5)
    - 5 refractory periods (0.2s to 0.8s)
    - 3 axes (X, Y, Z)
    - 2 polarities (positive, negative)
  - Total: 270 combinations
  - Ranks by scoring function

Pass 2: Fine Tuning
  - Takes the top 3 candidates from Pass 1
  - Tests fine-grained variations:
    - 5 alpha values (0.1 to 0.3)
    - Threshold +/- 0.2 in 0.05 steps
    - Refractory +/- 0.05 in 0.01 steps
  - Typically 1000+ additional combinations
```

### Scoring

Each combination is scored by:

```
score = |detected - target| + 0.3 * max(0, detected - target) + 0.01 * paramDistance
```

- Primary: minimize error between detected and target rep count
- Secondary: penalize overcounting more than undercounting (30% penalty for each extra rep)
- Tertiary: prefer parameters close to the current calibration (stability)

## Basic Usage

```swift
import RepMotionDetection

let engine = CalibrationEngine()

// 'samples' is an array of MotionSample from a recorded session
// 'target' is the known number of reps in that recording
let result = engine.calibrate(
    samples: recordedSamples,
    target: 12,
    current: .default
)

if let result {
    print("Detected: \(result.detectedReps) / \(result.targetReps)")
    print("Previous: \(result.previousReps)")
    print("Improvement: \(result.improvement)")
    print("Combinations tested: \(result.combinationsTested)")
    print("Perfect matches: \(result.perfectMatches)")

    // Apply the optimized calibration
    detector.calibration = result.calibration
}
```

## CalibrationResult

| Property | Type | Description |
|----------|------|-------------|
| `calibration` | `RepCalibration` | The optimized parameters |
| `detectedReps` | `Int` | Reps detected with optimized parameters |
| `previousReps` | `Int` | Reps detected with the original parameters |
| `targetReps` | `Int` | The target rep count you provided |
| `combinationsTested` | `Int` | Total parameter combinations evaluated |
| `perfectMatches` | `Int` | How many combinations hit the target exactly |
| `improvement` | `Int` | How many reps closer to target vs previous |
| `isAlreadyOptimal` | `Bool` | True if the original calibration was already perfect |

## Requirements

- At least 50 samples in the recording (returns `nil` otherwise)
- Target rep count must be > 0

## Recording a Calibration Session

A typical calibration workflow:

1. Record a session with `MotionCaptureService`, collecting all `MotionSample` values
2. The user counts reps manually during the recording
3. After the recording, pass the samples and manual count to `CalibrationEngine`
4. Store the resulting `RepCalibration` for that exercise type

```swift
var recordedSamples: [MotionSample] = []

capture.samplePublisher
    .sink { samples in
        recordedSamples.append(contentsOf: samples)
        detector.processBatch(samples)
    }
    .store(in: &cancellables)

// After recording completes:
let result = engine.calibrate(
    samples: recordedSamples,
    target: userReportedCount,
    current: detector.calibration
)
```

## Tips

- Record at least 10 reps for reliable calibration. More data = better results.
- Calibrate per exercise type. A calibration for bicep curls won't work well for squats.
- The engine preserves warmup and cooldown durations from the input calibration -- it only optimizes alpha, threshold, refractory, axis, and polarity.
- If `perfectMatches` is high, the detection is robust for this exercise. If it's low or zero, the motion pattern may be difficult to detect reliably.
