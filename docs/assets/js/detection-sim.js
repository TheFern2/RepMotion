"use strict";

function generateSyntheticSession(opts) {
  const {
    duration = 30,
    sampleRate = 50,
    repFrequency = 1.5,
    amplitude = 1.0,
    noise = 0.15,
    warmup = 5,
    fadeIn = 2,
  } = opts || {};

  const samples = [];
  const total = Math.floor(duration * sampleRate);

  for (let i = 0; i < total; i++) {
    const t = i / sampleRate;
    let envelope = 1.0;
    if (t < warmup) {
      envelope = 0.0;
    } else if (t < warmup + fadeIn) {
      envelope = (t - warmup) / fadeIn;
    }

    const signal =
      envelope * amplitude * Math.sin(2 * Math.PI * repFrequency * t);
    const n = (Math.random() - 0.5) * 2 * noise;

    samples.push({ timestamp: t, ax: n * 0.3, ay: signal + n, az: n * 0.2 });
  }
  return samples;
}

function runDetection(samples, calibration) {
  const {
    alpha = 0.2,
    thresholdMultiplier = 1.5,
    refractoryPeriod = 0.4,
    detectionAxis = "y",
    peakPolarity = "positive",
    warmupDuration = 5.0,
  } = calibration;

  const polarityMul = peakPolarity === "positive" ? 1.0 : -1.0;
  const axisKey = { x: "ax", y: "ay", z: "az" }[detectionAxis];

  let filtered = 0;
  let prevFiltered = 0;
  let preprevFiltered = 0;
  let lastRepTimestamp = -Infinity;
  const startTimestamp = samples.length > 0 ? samples[0].timestamp : 0;

  const buffer = [];
  const bufferCap = 100;
  const minThreshold = 0.05;

  const diagnostics = [];
  const reps = [];

  for (let i = 0; i < samples.length; i++) {
    const s = samples[i];
    const rawValue = s[axisKey] * polarityMul;

    buffer.push(rawValue);
    if (buffer.length > bufferCap) buffer.shift();

    preprevFiltered = prevFiltered;
    prevFiltered = filtered;
    filtered = alpha * rawValue + (1 - alpha) * prevFiltered;

    let mean = 0;
    let stddev = 0;
    if (buffer.length > 1) {
      mean = buffer.reduce((a, b) => a + b, 0) / buffer.length;
      const sq = buffer.reduce((a, b) => a + (b - mean) * (b - mean), 0);
      stddev = Math.sqrt(sq / buffer.length);
    }

    const dynamicThreshold = mean + thresholdMultiplier * stddev;
    const threshold = Math.max(dynamicThreshold, minThreshold);

    diagnostics.push({
      sampleIndex: i,
      timestamp: s.timestamp,
      rawValue: rawValue,
      filteredValue: filtered,
      threshold: threshold,
      mean: mean,
      stddev: stddev,
    });

    if (i < 2) continue;

    const isPeak = prevFiltered > preprevFiltered && prevFiltered > filtered;
    if (!isPeak) continue;
    if (prevFiltered <= threshold) continue;

    const elapsed = s.timestamp - startTimestamp;
    if (elapsed < warmupDuration) continue;
    if (s.timestamp - lastRepTimestamp < refractoryPeriod) continue;

    lastRepTimestamp = s.timestamp;
    const confidence =
      stddev > 0 ? Math.min(1.0, (prevFiltered - mean) / (2 * stddev)) : 0;

    reps.push({
      sampleIndex: i - 1,
      timestamp: samples[i - 1].timestamp,
      peakValue: prevFiltered,
      confidence: confidence,
    });
  }

  return { diagnostics, reps };
}

function buildChart(ctx) {
  return new Chart(ctx, {
    type: "line",
    data: {
      labels: [],
      datasets: [
        {
          label: "Raw Signal",
          data: [],
          borderColor: "rgba(148, 163, 184, 0.4)",
          borderWidth: 1,
          pointRadius: 0,
          fill: false,
          order: 3,
        },
        {
          label: "Filtered Signal",
          data: [],
          borderColor: "#3b82f6",
          borderWidth: 2,
          pointRadius: 0,
          fill: false,
          order: 2,
        },
        {
          label: "Threshold",
          data: [],
          borderColor: "#ef4444",
          borderWidth: 1.5,
          borderDash: [6, 3],
          pointRadius: 0,
          fill: false,
          order: 1,
        },
        {
          label: "Detected Reps",
          data: [],
          borderColor: "transparent",
          backgroundColor: "#22c55e",
          pointRadius: 7,
          pointStyle: "triangle",
          showLine: false,
          order: 0,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 300 },
      interaction: {
        mode: "index",
        intersect: false,
      },
      plugins: {
        legend: {
          position: "top",
          labels: {
            usePointStyle: true,
            padding: 20,
          },
        },
        tooltip: {
          callbacks: {
            title: function (items) {
              if (items.length > 0) {
                return "t = " + Number(items[0].label).toFixed(2) + "s";
              }
              return "";
            },
          },
        },
      },
      scales: {
        x: {
          title: { display: true, text: "Time (s)" },
          ticks: {
            maxTicksLimit: 15,
            callback: function (val) {
              return Number(this.getLabelForValue(val)).toFixed(1);
            },
          },
        },
        y: {
          title: { display: true, text: "Acceleration (g)" },
        },
      },
    },
  });
}

function updateChart(chart, diagnostics, reps) {
  const step = Math.max(1, Math.floor(diagnostics.length / 800));

  const labels = [];
  const rawData = [];
  const filteredData = [];
  const thresholdData = [];

  for (let i = 0; i < diagnostics.length; i += step) {
    const d = diagnostics[i];
    labels.push(d.timestamp.toFixed(3));
    rawData.push(d.rawValue);
    filteredData.push(d.filteredValue);
    thresholdData.push(d.threshold);
  }

  const repPoints = reps.map((r) => ({
    x: r.timestamp.toFixed(3),
    y: r.peakValue,
  }));

  chart.data.labels = labels;
  chart.data.datasets[0].data = rawData;
  chart.data.datasets[1].data = filteredData;
  chart.data.datasets[2].data = thresholdData;
  chart.data.datasets[3].data = repPoints;
  chart.update();
}
