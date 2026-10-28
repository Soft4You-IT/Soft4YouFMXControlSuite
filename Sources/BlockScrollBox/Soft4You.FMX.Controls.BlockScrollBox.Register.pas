unit Soft4You.FMX.Controls.BlockScrollBox.Register;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YBlockScrollBox - scroll box with the CSS block flow
  Original author: Carlo Marona (Soft4You) - 2026

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

{$R BlockScrollBoxDesign.res}

uses
  System.Classes,
  Soft4You.FMX.Controls.BlockScrollBox;

procedure Register;
begin
  RegisterComponents('Soft4You FMX Controls Suite', [TS4YBlockScrollBox]);
end;

end.
