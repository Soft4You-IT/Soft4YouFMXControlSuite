unit Soft4You.FMX.Controls.FlexBox.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YFlexBox - CSS FlexBox layout container
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{
  Simple flexbox types: breakpoint modes and overrides, effective settings
  of the container.
}

interface

uses
  Soft4You.FMX.Controls.FlexBox.Engine;

type
  /// <summary>
  /// How the width of a breakpoint is read. It applies to the whole list of breakpoints.
  /// </summary>
  /// <remarks>
  /// bmMaxWidth: the breakpoint is active up to its Width, like max-width in CSS.
  /// bmMinWidth: the breakpoint is active from its Width up, like min-width in CSS.
  /// The comparison is inclusive.
  /// </remarks>
  TS4YBreakpointMode = (bmMaxWidth, bmMinWidth);

  /// <summary>
  /// A property of the flexbox container that a breakpoint can override.
  /// </summary>
  /// <remarks>
  /// Each value stands for the property of TS4YFlexBox with the same name.
  /// </remarks>
  TS4YContainerOverride = (
    coDirection,
    coWrap,
    coJustifyContent,
    coAlignItems,
    coAlignContent,
    coColumnGap,
    coRowGap
  );

  /// <summary>
  /// The properties of the container that a breakpoint overrides.
  /// </summary>
  TS4YContainerOverrides = set of TS4YContainerOverride;

  /// <summary>
  /// A property of a flexbox item that a breakpoint can override.
  /// </summary>
  /// <remarks>
  /// Each value stands for the property of TS4YFlexItem with the same name. ioFlexBasis covers FlexBasis and FlexBasisUnit together; ioWidth covers AutoWidth and Width; ioHeight covers AutoHeight and Height.
  /// </remarks>
  TS4YItemOverride = (
    ioFlexGrow,
    ioFlexShrink,
    ioFlexBasis,    // FlexBasis and FlexBasisUnit together
    ioAlignSelf,
    ioOrder,
    ioVisible,
    ioWidth,        // AutoWidth and Width together
    ioHeight,       // AutoHeight and Height together
    ioMargins,
    ioMinWidth,
    ioMaxWidth,
    ioMinHeight,
    ioMaxHeight
  );

  /// <summary>
  /// The properties of an item that a breakpoint overrides.
  /// </summary>
  TS4YItemOverrides = set of TS4YItemOverride;

  /// <summary>
  /// Outcome of the visibility override of an item at the current width.
  /// </summary>
  /// <remarks>
  /// voNone: no override, the Visible chosen by the user applies.
  /// voShow: the item is shown.
  /// voHide: the item is hidden.
  /// </remarks>
  TS4YVisibilityOverride = (voNone, voShow, voHide);

  /// <summary>
  /// The properties of the container in effect for a layout: the ones of the container, changed by the active breakpoints.
  /// </summary>
  TS4YFlexSettings = record
    /// <summary>Direction of the main axis.</summary>
    Direction: TFlexDirection;
    /// <summary>Whether the items wrap onto more lines.</summary>
    Wrap: TFlexWrap;
    /// <summary>Distribution of the items along the main axis.</summary>
    JustifyContent: TJustifyContent;
    /// <summary>Alignment of the items on the cross axis.</summary>
    AlignItems: TAlignItems;
    /// <summary>Distribution of the lines on the cross axis.</summary>
    AlignContent: TAlignContent;
    /// <summary>Space between the columns, in pixels.</summary>
    ColumnGap: Single;
    /// <summary>Space between the rows, in pixels.</summary>
    RowGap: Single;
  end;

implementation

end.
