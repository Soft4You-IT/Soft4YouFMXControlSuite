unit Soft4You.FMX.Controls.ColorSelector.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YColorSelector - foreground and background color swatches
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.UITypes;

type
  /// <summary>
  /// The color of a TS4YColorSelector that the user clicked.
  /// </summary>
  /// <remarks>
  /// ctForeground: the foreground color, the swatch at the top left.
  /// ctBackground: the background color, the swatch at the bottom right.
  /// </remarks>
  TS4YColorTarget = (ctForeground, ctBackground);

  /// <summary>
  /// Event of TS4YColorSelector fired when the user clicks one of the two colors.
  /// </summary>
  /// <remarks>
  /// ATarget is the color clicked, ACurrentColor its value. The selector does not choose a color by itself: the handler
  /// shows a color picker and sets ForegroundColor or BackgroundColor with the new color.
  /// </remarks>
  TS4YColorSelectEvent = procedure(Sender: TObject; ATarget: TS4YColorTarget; ACurrentColor: TAlphaColor) of object;

implementation

end.
