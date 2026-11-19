unit Soft4You.FMX.Controls.Avatar.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YAvatar - simple types of the avatar
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

type
  /// <summary>
  /// Shape of a TS4YAvatar.
  /// </summary>
  /// <remarks>
  /// avsCircle: a circle, the default.
  /// avsRounded: a square with rounded corners, with the radius of CornerRadius.
  /// avsSquare: a square with sharp corners.
  /// </remarks>
  TS4YAvatarShape = (
    avsCircle,
    avsRounded,
    avsSquare
  );

  /// <summary>
  /// Size of a TS4YAvatar chosen among the ready ones.
  /// </summary>
  /// <remarks>
  /// avzCustom: the size is the one given by Width and Height, the default.
  /// avzSmall: 32 x 32 pixels.
  /// avzMedium: 40 x 40 pixels.
  /// avzLarge: 56 x 56 pixels.
  /// avzExtraLarge: 80 x 80 pixels.
  /// </remarks>
  TS4YAvatarSizePreset = (
    avzCustom,
    avzSmall,
    avzMedium,
    avzLarge,
    avzExtraLarge
  );

  /// <summary>
  /// State of the person shown by the dot of a TS4YAvatar.
  /// </summary>
  /// <remarks>
  /// avtNone: no dot, the default.
  /// avtOnline, avtAway, avtBusy, avtOffline: a dot with the color of the state, taken from the style (green, yellow, red and gray in the default styles) or from StatusColor.
  /// </remarks>
  TS4YAvatarStatus = (
    avtNone,
    avtOnline,
    avtAway,
    avtBusy,
    avtOffline
  );

  /// <summary>
  /// Corner of a TS4YAvatar where the status dot or the edit button is placed.
  /// </summary>
  /// <remarks>
  /// On a round avatar the corner is the point of the circle in that direction, at 45 degrees.
  /// </remarks>
  TS4YAvatarCorner = (
    avcTopLeft,
    avcTopRight,
    avcBottomLeft,
    avcBottomRight
  );

  /// <summary>
  /// When the edit button of a TS4YAvatar is shown.
  /// </summary>
  /// <remarks>
  /// ebvNever: never, the default.
  /// ebvAlways: always.
  /// ebvOnHover: while the mouse is over the avatar; on Android and iOS, which have no mouse, always.
  /// </remarks>
  TS4YAvatarEditButtonVisibility = (
    ebvNever,
    ebvAlways,
    ebvOnHover
  );

implementation

end.
