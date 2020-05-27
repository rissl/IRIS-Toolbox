'use strict';

// utility methods
var $ru = {
  createChart: createChartForChartJs,
  createSeries: createSeriesForChartJs,
  freqToUnit: freqToMomentJsUnit,
  createTable: createTable,
  createGrid: createGrid,
  addReportElement: addReportElement,
  getColorList: getColorList,
  addPageBreak: addPageBreak,
  getEntryFromDataBank: getEntryFromDataBank
};

// fetch an object stored in the global $data_bank variable under the given name
function getEntryFromDataBank(name) {
  if ($data_bank && typeof $data_bank === "object" && $data_bank.hasOwnProperty(name)) {
    return $data_bank[name];
  }
  return null;
}

// add div that would force page break when printing
function addPageBreak(parent, breakObj) {
  var pageBreakDiv = document.createElement("div");
  $(pageBreakDiv).addClass("page-break");
  pageBreakDiv.innerHTML = "&nbsp;";
  parent.appendChild(pageBreakDiv);
}

// create chart elements using Chart.js library
function createChartForChartJs(parent, chartObj) {
  var canvasParent = document.createElement("div");
  $(canvasParent).addClass("rephrase-chart");
  // apply custom css class to .rephrase-chart div
  if (chartObj.Settings.Class && (typeof chartObj.Settings.Class === "string"
    || chartObj.Settings.Class instanceof Array)) {
    $(canvasParent).addClass(chartObj.Settings.Class);
  }
  parent.appendChild(canvasParent);
  // whether to include title in canvas or make it a separate div
  const titleOutOfCanvas = (chartObj.Settings.hasOwnProperty("IsTitlePartOfChart") && !chartObj.Settings.IsTitlePartOfChart);
  // create chart title
  const chartTitle = chartObj.Title || "";
  if (chartTitle && titleOutOfCanvas) {
    var chartTitleDiv = document.createElement("div");
    $(chartTitleDiv).addClass(["rephrase-chart-title", "h4"]);
    chartTitleDiv.innerText = chartTitle;
    canvasParent.appendChild(chartTitleDiv);
  }
  var canvas = document.createElement("canvas");
  $(canvas).addClass("rephrase-chart-canvas");
  canvasParent.appendChild(canvas);
  var data = [];
  if (chartObj.hasOwnProperty("Content") && chartObj.Content instanceof Array) {
    const colorList = $ru.getColorList(chartObj.Content.length);
    for (var i = 0; i < chartObj.Content.length; i++) {
      const seriesObj = chartObj.Content[i];
      data.push($ru.createSeries(seriesObj, colorList[i]));
    }
  }

  Chart.defaults.global.defaultFontFamily = 'Lato';
  var chartJsObj = new Chart(canvas, {
    type: 'line',
    data: {
      datasets: data
    },
    options: {
      title: {
        display: chartTitle !== "" && !titleOutOfCanvas,
        text: chartTitle,
        fontFamily: 'Lato',
        fontSize: 20,
        fontStyle: '300',
        fontColor: '#0a0a0a'
      },
      tooltips: {
        intersect: false,
        mode: 'x',
        callbacks: {
          label: function (tooltipItem, data) {
            var label = data.datasets[tooltipItem.datasetIndex].label || '';

            if (label) {
              label += ': ';
            }
            label += Math.round(tooltipItem.yLabel * 1000) / 1000;
            return label;
          }
        }
      },
      maintainAspectRatio: true,
      scales: {
        xAxes: [{
          type: 'time',
          distribution: 'series',
          time: {
            min: new Date(chartObj.Settings.StartDate),
            max: new Date(chartObj.Settings.EndDate),
            minUnit: 'day',
            tooltipFormat: chartObj.Settings.DateFormat,
            parser: chartObj.Settings.DateFormat
          }
        }]
      }
    }
  });
  return chartJsObj;
}

// create series object for Chart.js chart
function createSeriesForChartJs(seriesObj, color) {
  // return empty object if smth. is wrong
  if (!seriesObj || !(typeof seriesObj === "object") || !seriesObj.hasOwnProperty("Type")
    || seriesObj.Type.toLowerCase() !== "series" || !seriesObj.hasOwnProperty("Content")
    || !((typeof seriesObj.Content === "string")
      || (typeof seriesObj.Content === "object"
        && seriesObj.Content.hasOwnProperty("Dates")
        && seriesObj.Content.hasOwnProperty("Values")))) {
    return {};
  }
  const inDataBank = (typeof seriesObj.Content === "string");
  var values, dates = [];
  if (inDataBank) {
    const dataObj = getEntryFromDataBank(seriesObj.Content);
    if (dataObj && typeof dataObj === "object" && dataObj.hasOwnProperty("Values")
      && (dataObj.Values instanceof Array)) {
      values = dataObj.Values;
      if (dataObj.Dates instanceof Array) {
        dates = dataObj.Dates.map(function (d) {
          return new Date(d);
        });
      } else {
        const freqUnit = freqToMomentJsUnit(dataObj.Frequency);
        const startDate = moment(dataObj.Dates);
        for (var i = 0; i < values.length; i++) {
          dates.push(startDate.add(1, freqUnit).toDate());
        }
      }
    }
  } else {
    values = seriesObj.Content.Values;
    dates = seriesObj.Content.Dates.map(function (d) {
      return new Date(d);
    });
  }
  var tsData = [];
  for (var i = 0; i < values.length; i++) {
    tsData.push({
      x: dates[i],
      y: values[i]
    });
  }
  var overrideColor = null;
  if (seriesObj.hasOwnProperty("Settings") && (typeof seriesObj.Settings === "object")
    && seriesObj.Settings.hasOwnProperty("Color")) {
    overrideColor = seriesObj.Settings.Color;
  }
  return {
    data: tsData,
    lineTension: 0,
    label: seriesObj.Title || "",
    backgroundColor: "rgba(0,0,0,0)",
    borderColor: overrideColor || color,
    type: seriesObj.Settings.Type || "line"
  };
}

// convert frequency letter to Chart.js time unit
function freqToMomentJsUnit(freq) {
  var unit = "";
  switch (freq) {
    case 365:
      unit = "day";
      break;
    case 52:
      unit = "week";
      break;
    case 12:
      unit = "month";
      break;
    case 4:
      unit = "quarter";
      break;
    case 1:
      unit = "year";
      break;
    default:
      unit = "";
  }
  return unit;
}

function getColorList(nColors) {
  const defaultColorList = [
    "#0072bd",
    "#d95319",
    "#edb120",
    "#7e2f8e",
    "#77ac30",
    "#4dbeee",
    "#a2142f"
  ];
  const nDefaults = defaultColorList.length;
  var colorList = [];
  for (var i = 0; i < nColors; i++) {
    colorList.push(defaultColorList[i % nDefaults]);

  }
  return colorList;
}

function createTable(parent, tableObj) {
  // create a div to wrap the table
  var tableParent = document.createElement("div");
  $(tableParent).addClass(["rephrase-table-parent", "table-scroll"]);
  parent.appendChild(tableParent);
  // create table title
  if (tableObj.Title) {
    var tableTitle = document.createElement("h3");
    $(tableTitle).addClass("rephrase-table-title");
    tableTitle.innerText = tableObj.Title;
  }
  tableParent.appendChild(tableTitle);
  var table = document.createElement("table");
  $(table).addClass(["rephrase-table", "hover", "unstriped"]);
  // apply custom css class to .rephrase-chart div
  if (tableObj.Settings.Class && (typeof tableObj.Settings.Class === "string"
    || tableObj.Settings.Class instanceof Array)) {
    $(table).addClass(tableObj.Settings.Class);
  }
  tableParent.appendChild(table);
  // initiate table header and body
  var thead = document.createElement("thead");
  $(thead).addClass('rephrase-table-header');
  table.appendChild(thead);
  var theadRow = document.createElement("tr");
  $(theadRow).addClass('rephrase-table-header-row');
  thead.appendChild(theadRow);
  var tbody = document.createElement("tbody");
  $(tbody).addClass('rephrase-table-body');
  table.appendChild(tbody);
  // create title column in header
  var theadFirstCell = document.createElement("th");
  $(theadFirstCell).addClass('rephrase-table-header-cell');
  theadRow.appendChild(theadFirstCell);
  // re-format the date string and populate table header
  const dates = tableObj.Settings.Dates.map(function (d) {
    const t = moment(d).format(tableObj.Settings.DateFormat);
    var theadDateCell = document.createElement("th");
    $(theadDateCell).addClass('rephrase-table-header-cell');
    theadDateCell.innerText = t;
    theadRow.appendChild(theadDateCell);
    return t;
  });
  // number of decimals when showing numbers
  const nDecimals = tableObj.Settings.NumDecimals || 2;
  // populate table body
  for (var i = 0; i < tableObj.Content.length; i++) {
    const tableRowObj = tableObj.Content[i];
    // skip this entry if it's neither a SERIES nor HEADING or if smth. else is wrong
    if (!tableRowObj.hasOwnProperty("Type")
      || ["series", "heading"].indexOf(tableRowObj.Type.toLowerCase()) === -1
      || (tableRowObj.Type.toLowerCase() === "series"
        && (!tableRowObj.hasOwnProperty("Content")
          || !tableRowObj.Content.hasOwnProperty("Values")
          || !(tableRowObj.Content.Values instanceof Array)
          || !(dates instanceof Array)
          || tableRowObj.Content.Values.length !== dates.length))) {
      continue;
    }
    const isSeries = (tableRowObj.Type.toLowerCase() === "series");
    // create new table row
    var tbodyRow = document.createElement("tr");
    $(tbodyRow).addClass(['rephrase-table-row',
      isSeries ? 'rephrase-table-data-row' : 'rephrase-table-heading-row']);
    tbody.appendChild(tbodyRow);
    // create title cell
    var tbodyTitleCell = document.createElement("td");
    if (isSeries) {
      $(tbodyTitleCell).addClass('rephrase-table-data-row-title');
    } else {
      $(tbodyTitleCell).addClass('h5');
      tbodyTitleCell.setAttribute('colspan', dates.length + 1);
    }
    tbodyTitleCell.innerText = tableRowObj.Title || "";
    tbodyRow.appendChild(tbodyTitleCell);
    // create data cells
    if (isSeries) {
      for (var j = 0; j < tableRowObj.Content.Values.length; j++) {
        const v = tableRowObj.Content.Values[j];
        var tbodyDataCell = document.createElement("td");
        $(tbodyDataCell).addClass('rephrase-table-data-cell');
        tbodyDataCell.innerText = v.toFixed(nDecimals);
        tbodyRow.appendChild(tbodyDataCell);
      }
    }
  }
}

function createGrid(parent, gridObj) {
  // create a parent div elements for rows
  var gridRowParent = document.createElement("div");
  $(gridRowParent).addClass(["rephrase-grid", "grid-y", "grid-padding-y"]);
  parent.appendChild(gridRowParent);
  // create grid title
  if (gridObj.Title) {
    var gridTitle = document.createElement("h2");
    $(gridTitle).addClass("rephrase-grid-title");
    gridTitle.innerText = gridObj.Title;
    gridRowParent.appendChild(gridTitle);
  }
  const nRows = gridObj.Settings.NumRows;
  const nCols = gridObj.Settings.NumColumns;
  // populate rows
  for (var i = 0; i < nRows; i++) {
    // create row
    var gridRow = document.createElement("div");
    $(gridRow).addClass(["cell", "shrink"]);
    gridRowParent.appendChild(gridRow);
    // create parent div for this row's columns
    var gridColParent = document.createElement("div");
    $(gridColParent).addClass(["grid-x", "grid-padding-x"]);
    gridRow.appendChild(gridColParent);
    // populate this row's columns
    for (let j = 0; j < nCols; j++) {
      const contentIndex = nCols * i + j;
      var gridCol = document.createElement("div");
      $(gridCol).addClass(["cell", "auto"]);
      gridColParent.appendChild(gridCol);
      const gridElementObj = gridObj.Content[contentIndex];
      $ru.addReportElement(gridCol, gridElementObj);
    }
  }
}

function addReportElement(parent, elementObj) {
  // do nothing if smth. is wrong
  if (!elementObj || !(typeof elementObj === "object") || !elementObj.hasOwnProperty("Type")) {
    return {};
  }
  switch (elementObj.Type.toLowerCase()) {
    case "chart":
      $ru.createChart(parent, elementObj);
      break;
    case "table":
      $ru.createTable(parent, elementObj);
      break;
    case "grid":
      $ru.createGrid(parent, elementObj);
      break;
    case "pagebreak":
      $ru.addPageBreak(parent, elementObj);
      break;
    default:
      break;
  }
}
