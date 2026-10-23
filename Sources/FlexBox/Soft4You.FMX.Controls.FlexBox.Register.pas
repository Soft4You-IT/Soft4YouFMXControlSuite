unit Soft4You.FMX.Controls.FlexBox.Register;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YFlexBox - CSS FlexBox layout container
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

{$R FlexBoxDesign.res}

uses
  System.Classes,
  DesignIntf,
  FMX.Types,
  Soft4You.FMX.Controls.FlexBox,
  Soft4You.FMX.Controls.FlexBox.Design;

procedure Register;
begin
  // 'Soft4You FMX Controls Suite' = palette tab where the components appear.
  // The icon is read automatically from the bitmap resource whose name
  // matches the class name in upper case ('TS4YFLEXBOX'),
  // compiled into the .res from FlexBoxDesign.rc.
  RegisterComponents('Soft4You FMX Controls Suite', [TS4YFlexBox]);

  // The item is not in the palette: the flexbox creates it (wrapping). Registered for
  // streaming of the .fmx and for the IDE, but without a palette entry.
  RegisterFmxClasses([TS4YFlexItem]);
  RegisterNoIcon([TS4YFlexItem]);

  // Automatic wrapping of controls dropped into the flexbox
  RegisterFlexDesignSupport;
end;

end.
