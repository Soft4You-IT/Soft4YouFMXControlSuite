unit Soft4You.FMX.Controls.FlexBox.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YFlexBox - CSS FlexBox layout container
  Original author: Carlo Marona (Soft4You) - 2026

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
  // How the width of a breakpoint is read (applies to the whole list):
  // bmMaxWidth = "up to Width" (like max-width in CSS), bmMinWidth = "from Width
  // up" (like min-width). The comparison is inclusive.
  TS4YBreakpointMode = (bmMaxWidth, bmMinWidth);

  // Flexbox (container) properties that a breakpoint can override
  TS4YContainerOverride = (
    coDirection,
    coWrap,
    coJustifyContent,
    coAlignItems,
    coAlignContent,
    coColumnGap,
    coRowGap
  );

  TS4YContainerOverrides = set of TS4YContainerOverride;

  // Item properties that a breakpoint can override
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

  TS4YItemOverrides = set of TS4YItemOverride;

  // Outcome of the visibility override for an item: voNone = the Visible
  // chosen by the user applies
  TS4YVisibilityOverride = (voNone, voShow, voHide);

  // Effective container properties for a layout (base + active breakpoints)
  TS4YFlexSettings = record
    Direction: TFlexDirection;
    Wrap: TFlexWrap;
    JustifyContent: TJustifyContent;
    AlignItems: TAlignItems;
    AlignContent: TAlignContent;
    ColumnGap: Single;
    RowGap: Single;
  end;

implementation

end.
