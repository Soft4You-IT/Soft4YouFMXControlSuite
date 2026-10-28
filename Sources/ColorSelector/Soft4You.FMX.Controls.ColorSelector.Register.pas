unit Soft4You.FMX.Controls.ColorSelector.Register;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YColorSelector - foreground and background color swatches
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

{$R ColorSelectorDesign.res}

uses
  System.Classes,
  Soft4You.FMX.Controls.ColorSelector;

procedure Register;
begin
  // The icon is read automatically from the bitmap resource whose name
  // matches the class name in upper case ('TS4YCOLORSELECTOR'), compiled into
  // the .res from ColorSelectorDesign.rc.
  RegisterComponents('Soft4You FMX Controls Suite', [TS4YColorSelector]);
end;

end.
