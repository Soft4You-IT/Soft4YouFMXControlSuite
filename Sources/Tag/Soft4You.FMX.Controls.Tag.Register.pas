unit Soft4You.FMX.Controls.Tag.Register;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YTag, TS4YChip, TS4YChipGroup and TS4YChipEdit - registration in the Tool Palette
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

// ---------------------------------------------------------------------------
// Component registration (called by the IDE when the design-time package
// is installed)
// ---------------------------------------------------------------------------
procedure Register;

implementation

{$R TagDesign.res}

uses
  System.Classes,
  Soft4You.FMX.Controls.Tag,
  Soft4You.FMX.Controls.Chip,
  Soft4You.FMX.Controls.ChipGroup,
  Soft4You.FMX.Controls.ChipEdit;

procedure Register;
begin
  // The icons are read automatically from the bitmap resources whose names
  // match the class names in upper case ('TS4YTAG', 'TS4YCHIP', 'TS4YCHIPGROUP', 'TS4YCHIPEDIT'), compiled
  // into the .res from TagDesign.rc.
  RegisterComponents('Soft4You FMX Controls Suite', [TS4YTag, TS4YChip, TS4YChipGroup, TS4YChipEdit]);
end;

end.
