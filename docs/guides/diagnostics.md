---
layout: default
title: Diagnostics
---

[Home](../index) / Guides

# Diagnostics

`RepDetectionService` emits a `DetectionDiagnostic` for every processed sample. Use diagnostics to understand why the detector is or isn't firing, and to visualize the signal processing pipeline in real time.

## Subscribing to Diagnostics

```swift
detector.diagnosticPublisher
    .sink { diag in
        print("[\(diag.sampleIndex)] raw=\(diag.rawValue) filtered=\(diag.filteredValue) threshold=\(diag.threshold)")
    }
    .store(in: &cancellables)
```

## DetectionDiagnostic

| Property | Type | Description |
|----------|------|-------------|
| `sampleIndex` | `Int` | Sequential index of this sample since last reset |
| `rawValue` | `Double` | Axis value after polarity flip, before filtering |
| `filteredValue` | `Double` | Value after exponential smoothing |
| `threshold` | `Double` | Current dynamic threshold (mean + k * stddev) |
| `mean` | `Double` | Rolling mean of last 100 samples |
| `stddev` | `Double` | Rolling standard deviation of last 100 samples |

## What to Look For

### Reps not detected

- **filteredValue never exceeds threshold**: Lower `thresholdMultiplier` or try a different `detectionAxis`
- **Peaks on wrong axis**: Check the `rawValue` stream for each axis to find where the signal is strongest
- **Signal too smooth**: Increase `alpha` to let more of the raw signal through
- **Still in warmup**: Check that enough time has passed (`warmupDuration`)

### Too many reps detected

- **Threshold too low**: Increase `thresholdMultiplier`
- **Double-counting**: Increase `refractoryPeriod`
- **Wrong polarity**: The detector might be catching both the positive and negative peaks of each rep. Set `peakPolarity` explicitly.

### Signal appears flat

- **stddev near zero**: The motion is too uniform or too small to detect. This is expected for a stationary device.
- **Mean drifting**: Normal -- the dynamic threshold adapts to the signal level.

## Visualization

Collect diagnostics into an array and chart them to see the detection pipeline:

```swift
struct DiagnosticChart: View {
    let diagnostics: [DetectionDiagnostic]

    var body: some View {
        Chart {
            ForEach(diagnostics, id: \.sampleIndex) { d in
                LineMark(
                    x: .value("Sample", d.sampleIndex),
                    y: .value("Value", d.filteredValue)
                )
                .foregroundStyle(.blue)

                LineMark(
                    x: .value("Sample", d.sampleIndex),
                    y: .value("Threshold", d.threshold)
                )
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(dash: [5, 3]))
            }
        }
    }
}
```

The chart shows:
- **Blue line**: filtered signal (what the detector sees)
- **Red dashed line**: dynamic threshold (reps fire when blue crosses above red)
- Peaks above the red line that are separated by at least `refractoryPeriod` become `RepEvent`s

## Buffering for Performance

The diagnostic publisher fires for every sample (50+ times per second at default rates). For UI display, throttle or sample the stream:

```swift
detector.diagnosticPublisher
    .collect(.byTime(DispatchQueue.main, .milliseconds(100)))
    .sink { batch in
        diagnosticBuffer.append(contentsOf: batch)
        if diagnosticBuffer.count > 500 {
            diagnosticBuffer.removeFirst(diagnosticBuffer.count - 500)
        }
    }
    .store(in: &cancellables)
```
