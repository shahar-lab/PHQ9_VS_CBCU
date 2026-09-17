function(el, x, data) {
  const yMinimum = document.getElementById("cbcu-y-min");
  const yMaximum = document.getElementById("cbcu-y-max");
  const yMinimumSlider = document.getElementById("cbcu-y-min-slider");
  const yMaximumSlider = document.getElementById("cbcu-y-max-slider");
  const countLower = document.getElementById("cbcu-count-lower");
  const countUpper = document.getElementById("cbcu-count-upper");
  const countLowerSlider = document.getElementById("cbcu-count-lower-slider");
  const countUpperSlider = document.getElementById("cbcu-count-upper-slider");
  const timeFilter = document.getElementById("cbcu-time");
  const participantFilter = document.getElementById("cbcu-participant");
  const tableBody = document.getElementById("cbcu-count-table-body");
  const participantIds = data.participant.map(function(value) {
    return value === null ? "" : String(value);
  });
  const times = data.time.map(function(value) {
    return value === null ? "" : String(value);
  });
  const trials = data.trial;
  const rts = data.rt;
  const orderedIds = Array.from(new Set(participantIds));

  function formatTick(value) {
    return String(Math.round(value));
  }

  function yTickValues(minimum, maximum) {
    if (minimum === maximum) {
      return [minimum];
    }

    const ticks = [
      minimum,
      minimum + (maximum - minimum) / 3,
      minimum + 2 * (maximum - minimum) / 3,
      maximum
    ];
    ticks[0] = minimum;
    ticks[3] = maximum;
    return ticks;
  }

  function selectedTime() {
    return timeFilter.value;
  }

  function rowMatchesTime(index) {
    const timeValue = selectedTime();
    return timeValue === "" || times[index] === timeValue;
  }

  function rowMatchesPlot(index) {
    const selectedParticipant = participantFilter.value;
    const participantOk = selectedParticipant === "" ||
      participantIds[index] === selectedParticipant;
    return rowMatchesTime(index) && participantOk;
  }

  function linearFit(x, y) {
    const n = x.length;
    if (n < 2) {
      return null;
    }

    let sumX = 0;
    let sumY = 0;
    let sumXX = 0;
    let sumYY = 0;
    let sumXY = 0;
    let xMin = x[0];
    let xMax = x[0];

    for (let i = 0; i < n; i++) {
      const xi = x[i];
      const yi = y[i];
      sumX += xi;
      sumY += yi;
      sumXX += xi * xi;
      sumYY += yi * yi;
      sumXY += xi * yi;
      if (xi < xMin) xMin = xi;
      if (xi > xMax) xMax = xi;
    }

    const slopeDenom = n * sumXX - sumX * sumX;
    const corrDenom = Math.sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY));
    if (slopeDenom === 0 || corrDenom === 0) {
      return null;
    }

    const slope = (n * sumXY - sumX * sumY) / slopeDenom;
    const intercept = (sumY - slope * sumX) / n;
    const r = (n * sumXY - sumX * sumY) / corrDenom;

    return {
      x: [xMin, xMax],
      y: [intercept + slope * xMin, intercept + slope * xMax],
      r: r
    };
  }

  function updateYAxis() {
    const minimum = yMinimum.valueAsNumber;
    const maximum = yMaximum.valueAsNumber;

    if (!Number.isFinite(minimum) || !Number.isFinite(maximum)) {
      return;
    }

    const ticks = yTickValues(minimum, maximum);
    Plotly.relayout(el, {
      "yaxis.range": [minimum, maximum],
      "yaxis.autorange": false,
      "yaxis.tickmode": "array",
      "yaxis.tickvals": ticks,
      "yaxis.ticktext": ticks.map(formatTick),
      "yaxis.showticklabels": true,
      "yaxis.ticks": "outside"
    });
  }

  function updatePlot() {
    const pointsById = new Map(orderedIds.map(function(id) {
      return [id, {x: [], y: []}];
    }));
    const visibleX = [];
    const visibleY = [];

    for (let i = 0; i < participantIds.length; i++) {
      if (!rowMatchesPlot(i)) {
        continue;
      }
      pointsById.get(participantIds[i]).x.push(trials[i]);
      pointsById.get(participantIds[i]).y.push(rts[i]);
      visibleX.push(trials[i]);
      visibleY.push(rts[i]);
    }

    const participantTraceIndex = [];
    const participantX = [];
    const participantY = [];
    const participantVisible = [];
    let fittedIndex = null;
    let annotationIndex = null;

    el.data.forEach(function(trace, index) {
      const traceName = trace.name === null || trace.name === undefined
        ? ""
        : String(trace.name);

      if (orderedIds.indexOf(traceName) !== -1) {
        const points = pointsById.get(traceName);
        participantTraceIndex.push(index);
        participantX.push(points.x);
        participantY.push(points.y);
        participantVisible.push(points.x.length > 0);
        return;
      }

      if (traceName === "fitted values") {
        fittedIndex = index;
        return;
      }

      if (trace.mode && String(trace.mode).indexOf("text") !== -1) {
        annotationIndex = index;
      }
    });

    if (participantTraceIndex.length > 0) {
      Plotly.restyle(el, {
        x: participantX,
        y: participantY,
        visible: participantVisible
      }, participantTraceIndex);
    }

    const fit = linearFit(visibleX, visibleY);
    if (fittedIndex !== null) {
      if (fit === null) {
        Plotly.restyle(el, {visible: false}, [fittedIndex]);
      } else {
        Plotly.restyle(el, {
          x: [fit.x],
          y: [fit.y],
          visible: true
        }, [fittedIndex]);
      }
    }

    if (annotationIndex !== null) {
      const label = fit === null
        ? "[Pearson r = NA]"
        : "[Pearson r = " + fit.r.toFixed(2) + "]";
      Plotly.restyle(el, {text: [[label]]}, [annotationIndex]);
    }
  }

  function formatCountPercent(count, total) {
    if (total === 0) {
      return "0 (—)";
    }
    return count + " (" + (100 * count / total).toFixed(1) + "%)";
  }

  function appendCell(row, value) {
    const cell = document.createElement("td");
    cell.textContent = value;
    row.appendChild(cell);
  }

  function updateCountTable() {
    const lower = countLower.valueAsNumber;
    const upper = countUpper.valueAsNumber;

    if (!Number.isFinite(lower) || !Number.isFinite(upper)) {
      return;
    }

    const counts = new Map(orderedIds.map(function(id) {
      return [id, {below: 0, above: 0, total: 0}];
    }));

    for (let i = 0; i < rts.length; i++) {
      if (!rowMatchesTime(i)) {
        continue;
      }
      const participantCounts = counts.get(participantIds[i]);
      participantCounts.total += 1;
      if (rts[i] < lower) participantCounts.below += 1;
      if (rts[i] > upper) participantCounts.above += 1;
    }

    tableBody.replaceChildren();
    orderedIds.forEach(function(id) {
      const row = document.createElement("tr");
      const participantCounts = counts.get(id);
      appendCell(row, id);
      appendCell(
        row,
        formatCountPercent(participantCounts.below, participantCounts.total)
      );
      appendCell(
        row,
        formatCountPercent(participantCounts.above, participantCounts.total)
      );
      tableBody.appendChild(row);
    });
  }

  function updateTimeAndParticipant() {
    updatePlot();
    updateCountTable();
  }

  function bindNumberAndSlider(numberInput, slider, onChange) {
    numberInput.addEventListener("input", function() {
      const value = numberInput.valueAsNumber;
      if (Number.isFinite(value)) {
        slider.value = String(value);
      }
      onChange();
    });
    slider.addEventListener("input", function() {
      numberInput.value = slider.value;
      onChange();
    });
  }

  if (el.dataset.cbcuControlsBound !== "true") {
    bindNumberAndSlider(yMinimum, yMinimumSlider, updateYAxis);
    bindNumberAndSlider(yMaximum, yMaximumSlider, updateYAxis);
    bindNumberAndSlider(countLower, countLowerSlider, updateCountTable);
    bindNumberAndSlider(countUpper, countUpperSlider, updateCountTable);
    timeFilter.addEventListener("change", updateTimeAndParticipant);
    participantFilter.addEventListener("change", updatePlot);
    el.dataset.cbcuControlsBound = "true";
  }

  updateYAxis();
  updateTimeAndParticipant();
}
