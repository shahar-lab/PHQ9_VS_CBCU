function(el, x, data) {
  const yMinimum = document.getElementById("cbcu-y-min");
  const yMaximum = document.getElementById("cbcu-y-max");
  const countLower = document.getElementById("cbcu-count-lower");
  const countUpper = document.getElementById("cbcu-count-upper");
  const tableBody = document.getElementById("cbcu-count-table-body");
  const participantIds = data.participant.map(function(value) {
    return value === null ? "" : String(value);
  });
  const orderedIds = Array.from(new Set(participantIds));

  function updateYAxis() {
    const minimum = yMinimum.valueAsNumber;
    const maximum = yMaximum.valueAsNumber;

    if (Number.isFinite(minimum) && Number.isFinite(maximum)) {
      Plotly.relayout(el, {
        "yaxis.range": [minimum, maximum],
        "yaxis.autorange": false
      });
    }
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
      return [id, { below: 0, above: 0 }];
    }));

    data.rt.forEach(function(rt, index) {
      const participantCounts = counts.get(participantIds[index]);
      if (rt < lower) participantCounts.below += 1;
      if (rt > upper) participantCounts.above += 1;
    });

    tableBody.replaceChildren();
    orderedIds.forEach(function(id) {
      const row = document.createElement("tr");
      appendCell(row, id);
      appendCell(row, counts.get(id).below);
      appendCell(row, counts.get(id).above);
      tableBody.appendChild(row);
    });
  }

  if (el.dataset.cbcuControlsBound !== "true") {
    yMinimum.addEventListener("input", updateYAxis);
    yMaximum.addEventListener("input", updateYAxis);
    countLower.addEventListener("input", updateCountTable);
    countUpper.addEventListener("input", updateCountTable);
    el.dataset.cbcuControlsBound = "true";
  }

  updateYAxis();
  updateCountTable();
}
