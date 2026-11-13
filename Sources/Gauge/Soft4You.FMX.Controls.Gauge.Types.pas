unit Soft4You.FMX.Controls.Gauge.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YLinearGauge, TS4YCircularGauge - types of the gauges
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

type
  /// <summary>
  /// A brush of a gauge that can come from the style.
  /// </summary>
  /// <remarks>
  /// gsbFill: the part that grows with the value.
  /// gsbTrack: the whole path the fill runs along, drawn under it.
  /// </remarks>
  TS4YGaugeStyledBrush = (
    gsbFill,
    gsbTrack
  );

  /// <summary>
  /// The brushes of a gauge that come from the style instead of the FillBrush and TrackBrush properties.
  /// </summary>
  TS4YGaugeStyledBrushes = set of TS4YGaugeStyledBrush;

  /// <summary>
  /// Side of the bar of a TS4YLinearGauge where the caption and the value are shown.
  /// </summary>
  /// <remarks>
  /// gtpNone: no caption and no value.
  /// gtpBefore: above the bar when it is horizontal, on its left when it is vertical.
  /// gtpAfter: below the bar when it is horizontal, on its right when it is vertical.
  /// </remarks>
  TS4YGaugeTextPosition = (
    gtpNone,
    gtpBefore,
    gtpAfter
  );

  /// <summary>
  /// Event fired when a gauge writes its value.
  /// </summary>
  /// <remarks>
  /// AValue is the value drawn, which follows the animation; AText comes formatted with ValueFormat and can be replaced.
  /// </remarks>
  TS4YGaugeGetValueTextEvent = procedure(Sender: TObject; const AValue: Single; var AText: string) of object;

implementation

end.
