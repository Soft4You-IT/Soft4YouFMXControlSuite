unit Soft4You.FMX.Controls.Expander.Register;

interface

// ---------------------------------------------------------------------------
// Component registration (called by the IDE when the design-time package
// is installed)
// ---------------------------------------------------------------------------
procedure Register;

implementation

{$R ExpanderDesign.res}

uses
  System.Classes,
  Soft4You.FMX.Controls.Expander;

procedure Register;
begin
  // The icon is read automatically from the bitmap resource whose name
  // matches the class name in upper case ('TS4YEXPANDER'), compiled into the
  // .res from ExpanderDesign.rc.
  RegisterComponents('Soft4You FMX Controls Suite', [TS4YExpander]);
end;

end.