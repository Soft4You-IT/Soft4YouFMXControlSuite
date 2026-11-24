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

  /// <summary>
  /// How the user chooses the chips of a TS4YChipGroup.
  /// </summary>
  /// <remarks>
  /// cgmNone: the chips cannot be chosen.
  /// cgmSingle: one chip is chosen at a time, as with radio buttons; the default.
  /// cgmMultiple: any number of chips is chosen.
  /// </remarks>
  TS4YChipSelectionMode = (
    cgmNone,
    cgmSingle,
    cgmMultiple
  );

  /// <summary>
  /// Event fired by TS4YChipEdit after an item is added or removed by the user or by AddItem and RemoveItem.
  /// </summary>
  /// <param name="Sender">The control.</param>
  /// <param name="Text">The text of the item.</param>
  /// <param name="Index">The position of the item in Items, where it was added or removed.</param>
  TS4YChipItemEvent = procedure(Sender: TObject; const Text: string; Index: Integer) of object;

  /// <summary>
  /// Event fired by TS4YChipEdit before a text becomes an item.
  /// </summary>
  /// <param name="Sender">The control.</param>
  /// <param name="Text">The text, without the spaces around it.</param>
  /// <param name="Accept">True; set it to False to refuse the text, which stays in the field.</param>
  /// <param name="Kind">The kind of the chip, the one of ChipKind at first; set it to tgkDanger, for example, to mark a text that is accepted but not valid.</param>
  TS4YChipValidateEvent = procedure(Sender: TObject; const Text: string; var Accept: Boolean; var Kind: TS4YTagKind) of object;

const
  /// <summary>Height in pixels of a tag or a chip for each size preset.</summary>
  C_TAG_PRESET_HEIGHTS: array[TS4YTagSizePreset] of Single = (24, 32, 40);
  /// <summary>Size in points of the font of a tag or a chip for each size preset.</summary>
  C_TAG_PRESET_FONT_SIZES: array[TS4YTagSizePreset] of Single = (11, 13, 15);

implementation

end.
