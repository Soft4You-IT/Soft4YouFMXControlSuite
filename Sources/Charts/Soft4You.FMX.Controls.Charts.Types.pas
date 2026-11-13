unit Soft4You.FMX.Controls.Charts.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YPieChart, TS4YBarChart, TS4YLineChart - types of the charts
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

type
  /// <summary>
  /// Side of a chart where its legend is shown.
  /// </summary>
  /// <remarks>
  /// clpNone: no legend.
  /// clpTop, clpBottom: above or below the chart, with the entries in rows.
  /// clpLeft, clpRight: on the left or on the right of the chart, with the entries in a column.
  /// </remarks>
  TS4YChartLegendPosition = (
    clpNone,
    clpTop,
    clpBottom,
    clpLeft,
    clpRight
  );

  /// <summary>
  /// What a TS4YPieChart writes on each slice.
  /// </summary>
  /// <remarks>
  /// plcNone: nothing.
  /// plcValue: the value, formatted with ValueFormat.
  /// plcPercent: the part of the total, in percent.
  /// plcCaption: the caption of the slice.
  /// </remarks>
  TS4YPieLabelContent = (
    plcNone,
    plcValue,
    plcPercent,
    plcCaption
  );

  /// <summary>
  /// Where a TS4YPieChart writes the labels of the slices.
  /// </summary>
  /// <remarks>
  /// plpInside: in the middle of each slice, when the label fits in it.
  /// plpOutside: beside each slice, joined to it by a short line.
  /// </remarks>
  TS4YPieLabelPosition = (
    plpInside,
    plpOutside
  );

  /// <summary>
  /// Event fired when the user clicks an element of a chart.
  /// </summary>
  /// <remarks>
  /// AItemIndex is the slice of a pie chart or the category of a bar or line chart; ASeriesIndex is the series of the bar or the point, 0 for a pie chart.
  /// </remarks>
  TS4YChartItemClickEvent = procedure(Sender: TObject; const ASeriesIndex, AItemIndex: Integer) of object;

  /// <summary>
  /// Event fired when a chart writes a value.
  /// </summary>
  /// <remarks>
  /// ASeriesIndex and AItemIndex say which value it is, as in TS4YChartItemClickEvent; AItemIndex is -1 for a total.
  /// AValue is the value drawn, which follows the animation; AText comes formatted with ValueFormat and can be replaced.
  /// </remarks>
  TS4YChartGetValueTextEvent = procedure(Sender: TObject; const ASeriesIndex, AItemIndex: Integer;
    const AValue: Single; var AText: string) of object;

implementation

end.
