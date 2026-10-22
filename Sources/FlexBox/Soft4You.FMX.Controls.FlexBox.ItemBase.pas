unit Soft4You.FMX.Controls.FlexBox.ItemBase;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YFlexBox - CSS FlexBox layout container
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{
  Base class of TS4YFlexItem. It exists only to break the circular dependency:
  the breakpoints (Breakpoints.pas) must reference an item with a published
  property whose type restricts the Object Inspector drop-down to items,
  but TS4YFlexItem lives in FlexBox.pas, which in turn uses the breakpoints.
}

interface

uses
  FMX.Controls;

type
  TS4YFlexItemBase = class(TControl);

implementation

end.
