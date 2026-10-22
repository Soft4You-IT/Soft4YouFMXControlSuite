unit Soft4You.FMX.Controls.FlexBox.Register;

interface

// ---------------------------------------------------------------------------
// Component registration (called by the IDE when the design-time package
// is installed)
// ---------------------------------------------------------------------------
procedure Register;

implementation

{$R '..\..\Graphics\FlexBox\FlexBoxDesign.res'}

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
