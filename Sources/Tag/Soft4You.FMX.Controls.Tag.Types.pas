unit Soft4You.FMX.Controls.Tag.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YTag and TS4YChip - simple types of the tag and the chip
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

type
  /// <summary>
  /// Meaning of a tag or a chip, which gives it its color.
  /// </summary>
  /// <remarks>
  /// tgkNeutral: gray, the default.
  /// tgkPrimary, tgkSuccess, tgkWarning, tgkDanger, tgkInfo: blue, green, orange, red and light blue in the default styles.
  /// The colors come from the style, the parts named neutralcolor, primarycolor, successcolor, warningcolor, dangercolor and infocolor.
  /// </remarks>
  TS4YTagKind = (
    tgkNeutral,
    tgkPrimary,
    tgkSuccess,
    tgkWarning,
    tgkDanger,
    tgkInfo
  );

  /// <summary>
  /// How the color of a tag or a chip fills it.
  /// </summary>
  /// <remarks>
  /// tgvFilled: the whole background has the color, the text is white or dark.
  /// tgvTonal: a light background of the color with text of the color.
  /// tgvOutlined: no background, a border and text of the color.
  /// </remarks>
  TS4YTagVariant = (
    tgvFilled,
    tgvTonal,
    tgvOutlined
  );

  /// <summary>
  /// Shape of a tag or a chip.
  /// </summary>
  /// <remarks>
  /// tgsPill: the short sides are half circles.
  /// tgsRounded: rounded corners with the radius of CornerRadius.
  /// tgsSquare: sharp corners.
  /// </remarks>
  TS4YTagShape = (
    tgsPill,
    tgsRounded,
    tgsSquare
  );

  /// <summary>
  /// Size of a tag or a chip: the height, with the font and the space that follow it.
  /// </summary>
  /// <remarks>
  /// tgzSmall: 24 pixels high.
  /// tgzMedium: 32 pixels high, the default on the desktop.
  /// tgzLarge: 40 pixels high, the default on Android and iOS.
  /// </remarks>
  TS4YTagSizePreset = (
    tgzSmall,
    tgzMedium,
    tgzLarge
  );

  /// <summary>
  /// Visual state of a tag or a chip.
  /// </summary>
  TS4YTagState = (
    tgtNormal,
    tgtHover,
    tgtPressed
  );

  /// <summary>
  /// Event fired when the user closes a tag or a chip.
  /// </summary>
  /// <param name="Sender">The tag or the chip.</param>
  /// <param name="CanClose">True; set it to False to keep the control, which is hidden otherwise.</param>
  TS4YTagCloseEvent = procedure(Sender: TObject; var CanClose: Boolean) of object;

implementation

end.
