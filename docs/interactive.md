---
layout: default
title: Interactive Signal Explorer
---

<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
<script src="assets/js/detection-sim.js"></script>

<style>
  .sim-container {
    max-width: 960px;
    margin: 0 auto;
  }
  .chart-wrap {
    position: relative;
    height: 400px;
    margin-bottom: 24px;
    background: #fafafa;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 12px;
  }
  .controls {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px 32px;
    margin-bottom: 24px;
  }
  @media (max-width: 640px) {
    .controls { grid-template-columns: 1fr; }
  }
  .control-group label {
    display: block;
    font-weight: 600;
    font-size: 0.85em;
    margin-bottom: 4px;
    color: #334155;
  }
  .control-group .desc {
    font-size: 0.75em;
    color: #64748b;
    margin-bottom: 4px;
  }
  .control-group input[type="range"] {
    width: 100%;
    margin: 0;
  }
  .control-group .value {
    font-size: 0.8em;
    font-weight: 600;
    color: #3b82f6;
    float: right;
    margin-top: -20px;
  }
  .control-group select {
    width: 100%;
    padding: 4px 8px;
    border: 1px solid #cbd5e1;
    border-radius: 4px;
    font-size: 0.85em;
  }
  .stats {
    display: flex;
    gap: 24px;
    flex-wrap: wrap;
    margin-bottom: 24px;
  }
  .stat-card {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 12px 20px;
    text-align: center;
    min-width: 120px;
  }
  .stat-card .stat-value {
    font-size: 1.8em;
    font-weight: 700;
    color: #1e293b;
  }
  .stat-card .stat-label {
    font-size: 0.75em;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  .signal-controls {
    border-top: 1px solid #e2e8f0;
    padding-top: 16px;
    margin-top: 8px;
  }
  .btn-regen {
    background: #3b82f6;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    font-size: 0.85em;
    cursor: pointer;
    margin-bottom: 16px;
  }
  .btn-regen:hover {
    background: #2563eb;
  }
</style>

[Home](index)

# Interactive Signal Explorer

Adjust detection parameters and see how they affect rep detection in real time. The chart shows the same signal processing pipeline used by `RepDetectionService`.

<div class="sim-container">

<div class="stats" id="stats">
  <div class="stat-card">
    <div class="stat-value" id="stat-reps">0</div>
    <div class="stat-label">Reps Detected</div>
  </div>
  <div class="stat-card">
    <div class="stat-value" id="stat-confidence">--</div>
    <div class="stat-label">Avg Confidence</div>
  </div>
  <div class="stat-card">
    <div class="stat-value" id="stat-samples">0</div>
    <div class="stat-label">Samples</div>
  </div>
</div>

<div class="chart-wrap">
  <canvas id="signalChart"></canvas>
</div>

<h3>Detection Parameters</h3>

<div class="controls">
  <div class="control-group">
    <label>Alpha (smoothing) <span class="value" id="val-alpha">0.20</span></label>
    <div class="desc">Lower = smoother signal, higher = more responsive</div>
    <input type="range" id="ctrl-alpha" min="0.05" max="0.5" step="0.01" value="0.20">
  </div>

  <div class="control-group">
    <label>Threshold Multiplier <span class="value" id="val-threshold">1.50</span></label>
    <div class="desc">How many stddevs above mean to trigger detection</div>
    <input type="range" id="ctrl-threshold" min="0.3" max="3.0" step="0.05" value="1.50">
  </div>

  <div class="control-group">
    <label>Refractory Period (s) <span class="value" id="val-refractory">0.40</span></label>
    <div class="desc">Minimum time between consecutive reps</div>
    <input type="range" id="ctrl-refractory" min="0.1" max="1.5" step="0.05" value="0.40">
  </div>

  <div class="control-group">
    <label>Warmup Duration (s) <span class="value" id="val-warmup">5.0</span></label>
    <div class="desc">Ignore detections during this initial period</div>
    <input type="range" id="ctrl-warmup" min="0" max="10" step="0.5" value="5.0">
  </div>

  <div class="control-group">
    <label>Detection Axis</label>
    <select id="ctrl-axis">
      <option value="y" selected>Y (vertical)</option>
      <option value="x">X (lateral)</option>
      <option value="z">Z (forward/back)</option>
    </select>
  </div>

  <div class="control-group">
    <label>Peak Polarity</label>
    <select id="ctrl-polarity">
      <option value="positive" selected>Positive (+)</option>
      <option value="negative">Negative (-)</option>
    </select>
  </div>
</div>

<h3>Signal Generator</h3>

<button class="btn-regen" id="btn-regen">Regenerate Signal</button>

<div class="controls signal-controls">
  <div class="control-group">
    <label>Rep Frequency (Hz) <span class="value" id="val-freq">1.50</span></label>
    <div class="desc">How fast the simulated reps occur</div>
    <input type="range" id="ctrl-freq" min="0.5" max="4.0" step="0.1" value="1.50">
  </div>

  <div class="control-group">
    <label>Amplitude (g) <span class="value" id="val-amp">1.00</span></label>
    <div class="desc">Strength of the simulated acceleration</div>
    <input type="range" id="ctrl-amp" min="0.2" max="3.0" step="0.1" value="1.00">
  </div>

  <div class="control-group">
    <label>Noise Level <span class="value" id="val-noise">0.15</span></label>
    <div class="desc">Random noise added to the signal</div>
    <input type="range" id="ctrl-noise" min="0" max="0.8" step="0.05" value="0.15">
  </div>

  <div class="control-group">
    <label>Duration (s) <span class="value" id="val-duration">30</span></label>
    <div class="desc">Length of the simulated session</div>
    <input type="range" id="ctrl-duration" min="10" max="60" step="5" value="30">
  </div>
</div>

</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
  var chart = buildChart(document.getElementById("signalChart").getContext("2d"));
  var samples = null;

  function getSignalOpts() {
    return {
      repFrequency: parseFloat(document.getElementById("ctrl-freq").value),
      amplitude: parseFloat(document.getElementById("ctrl-amp").value),
      noise: parseFloat(document.getElementById("ctrl-noise").value),
      duration: parseFloat(document.getElementById("ctrl-duration").value),
      warmup: parseFloat(document.getElementById("ctrl-warmup").value),
    };
  }

  function getCalibration() {
    return {
      alpha: parseFloat(document.getElementById("ctrl-alpha").value),
      thresholdMultiplier: parseFloat(document.getElementById("ctrl-threshold").value),
      refractoryPeriod: parseFloat(document.getElementById("ctrl-refractory").value),
      warmupDuration: parseFloat(document.getElementById("ctrl-warmup").value),
      detectionAxis: document.getElementById("ctrl-axis").value,
      peakPolarity: document.getElementById("ctrl-polarity").value,
    };
  }

  function refresh() {
    if (!samples) samples = generateSyntheticSession(getSignalOpts());
    var cal = getCalibration();
    var result = runDetection(samples, cal);

    updateChart(chart, result.diagnostics, result.reps);

    document.getElementById("stat-reps").textContent = result.reps.length;
    document.getElementById("stat-samples").textContent = result.diagnostics.length;

    if (result.reps.length > 0) {
      var avg = result.reps.reduce(function (s, r) { return s + r.confidence; }, 0) / result.reps.length;
      document.getElementById("stat-confidence").textContent = avg.toFixed(2);
    } else {
      document.getElementById("stat-confidence").textContent = "--";
    }
  }

  function regenerate() {
    samples = generateSyntheticSession(getSignalOpts());
    refresh();
  }

  var sliders = [
    ["ctrl-alpha", "val-alpha"],
    ["ctrl-threshold", "val-threshold"],
    ["ctrl-refractory", "val-refractory"],
    ["ctrl-warmup", "val-warmup"],
  ];
  sliders.forEach(function (pair) {
    var input = document.getElementById(pair[0]);
    var display = document.getElementById(pair[1]);
    input.addEventListener("input", function () {
      display.textContent = parseFloat(input.value).toFixed(2);
      refresh();
    });
  });

  var signalSliders = [
    ["ctrl-freq", "val-freq"],
    ["ctrl-amp", "val-amp"],
    ["ctrl-noise", "val-noise"],
    ["ctrl-duration", "val-duration"],
  ];
  signalSliders.forEach(function (pair) {
    var input = document.getElementById(pair[0]);
    var display = document.getElementById(pair[1]);
    input.addEventListener("input", function () {
      display.textContent = parseFloat(input.value).toFixed(2);
      regenerate();
    });
  });

  document.getElementById("ctrl-axis").addEventListener("change", refresh);
  document.getElementById("ctrl-polarity").addEventListener("change", refresh);
  document.getElementById("btn-regen").addEventListener("click", regenerate);

  regenerate();
});
</script>
