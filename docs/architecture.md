---
layout: default
title: Architecture
---

[Home](index)

# Architecture

RepMotion processes raw sensor data through a pipeline that transforms noisy accelerometer readings into discrete rep events and workout metrics.

## Pipeline Overview

```
                        RepMotionCapture                    RepMotionDetection
                   ┌──────────────────────┐    ┌──────────────────────────────────────┐
                   │                      │    │                                      │
 Apple Watch       │  MotionCaptureService │    │  RepDetectionService                 │
 Sensors     ───►  │  (CMMotionManager)    │───►│                                      │
                   │                      │    │  ┌─────────┐  ┌───────────┐          │
                   │  ── or ──            │    │  │ Exp.    │  │ Dynamic   │          │
                   │                      │    │  │ Filter  ├─►│ Threshold ├─► Peak   │
                   │  FixtureMotionProvider│    │  │ (alpha) │  │ (mean +   │  Detect  │
                   │  (test replay)       │    │  └─────────┘  │  k*stddev)│          │
                   │                      │    │               └───────────┘          │
                   └──────────────────────┘    │                    │                  │
                                               │                    ▼                  │
                                               │    ┌──────────────────────────┐       │
                                               │    │ Refractory + Warmup Gate │       │
                                               │    └───────────┬──────────────┘       │
                                               │                │                      │
                                               │                ▼                      │
                                               │         ┌────────────┐                │
                                               │         │  RepEvent  │                │
                                               │         └─────┬──────┘                │
                                               │               │                       │
                                               │    ┌──────────┼──────────┐            │
                                               │    ▼          ▼          ▼            │
                                               │  RPM      Power     Distance          │
                                               │  Calc   Estimation  Estimation        │
                                               │                                      │
                                               └──────────────────────────────────────┘
```

## Stage by Stage

### 1. Capture

`MotionCaptureService` wraps Apple's `CMMotionManager` and streams `MotionSample` values at a configurable rate (default 50 Hz). Each sample contains:

- **Accelerometer**: `ax`, `ay`, `az` -- user acceleration in g-force (gravity removed)
- **Gyroscope**: `gx`, `gy`, `gz` -- rotation rate in radians/sec

For testing, `FixtureMotionProvider` replays pre-recorded samples with configurable speed and batch size. Both conform to the `MotionProvider` protocol.

### 2. Exponential Smoothing Filter

Raw accelerometer data is noisy. The detector applies an exponential moving average (EMA) on the configured detection axis:

```
filtered = alpha * raw + (1 - alpha) * previous_filtered
```

- **alpha = 0.2** (default): moderate smoothing, good balance of responsiveness and noise rejection
- Lower alpha = smoother signal, slower to react
- Higher alpha = noisier signal, faster to react

### 3. Dynamic Threshold

Instead of a fixed threshold, RepMotion computes a rolling threshold from the last 100 samples:

```
threshold = mean + thresholdMultiplier * stddev
```

This adapts to different exercise intensities and sensor placements automatically. A floor of 0.05g prevents false positives on stationary devices.

### 4. Peak Detection

A peak is detected when the filtered value at sample N-1 is greater than both its neighbors (N-2 and N):

```
isPeak = filtered[N-1] > filtered[N-2]  AND  filtered[N-1] > filtered[N]
```

The peak must also exceed the dynamic threshold.

### 5. Gating

Two gates prevent spurious detections:

- **Warmup gate**: Ignores all peaks during an initial warmup period (default 5 seconds). This lets the filter and statistics stabilize before detecting reps.
- **Refractory period**: Enforces a minimum time between reps (default 0.4 seconds). This prevents double-counting from a single motion.

### 6. Outputs

When a peak passes all gates, the detector emits a `RepEvent` and updates derived metrics:

| Publisher | Type | Description |
|-----------|------|-------------|
| `repPublisher` | `RepEvent` | Fires once per detected rep |
| `rpmPublisher` | `Double` | Reps per minute over a 30-second window |
| `diagnosticPublisher` | `DetectionDiagnostic` | Raw/filtered values and threshold for every sample |
| `warmupPublisher` | `TimeInterval` | Seconds remaining in warmup countdown |

### 7. Power Estimation

`PowerEstimationService` tracks peak acceleration magnitude across reps and computes:

- **Relative power**: current rep peak / session peak (0.0 to 1.0)
- **Rolling average**: current rep peak / rolling 5-rep average
- **Rolling max**: current rep peak / rolling 5-rep max

### 8. Distance Estimation

`DistanceEstimationService` accumulates an estimated distance using a base of 8 meters per rep, scaled by power output.

## Module Dependency Graph

```
RepMotionCapture ──► RepMotionCore ◄── RepMotionDetection
```

`RepMotionCore` has no dependencies. The other two modules depend only on Core, so you can use detection without capture (bring your own sensor data) or capture without detection (record raw data).

## Threading

- `MotionCaptureService` receives CoreMotion callbacks on an `OperationQueue` and dispatches samples on a serial `.userInteractive` queue
- `RepDetectionService` processes samples synchronously on whatever queue calls `processBatch(_:)` -- the caller controls threading
- All publishers are Combine `PassthroughSubject` / `CurrentValueSubject` publishers and emit on the calling thread
