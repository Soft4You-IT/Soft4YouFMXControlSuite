unit Soft4You.FMX.Controls.Gauges.Register;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YLinearGauge, TS4YCircularGauge - indicators of a value in a range
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

{$R GaugesDesign.res}

uses
  System.Classes,
  Soft4You.FMX.Controls.Gauges.Linear;

procedure Register;
begin
  // The icons are read automatically from the bitmap resources whose names
  // match the class names in upper case ('TS4YLINEARGAUGE'), compiled into
  // the .res from GaugesDesign.rc.
  RegisterComponents('Soft4You FMX Controls Suite', [TS4YLinearGauge]);
end;

end.
