unit Soft4You.FMX.Controls.Expander.Register;

interface

// ---------------------------------------------------------------------------
// Component registration (called by the IDE when the design-time package
// is installed)
// ---------------------------------------------------------------------------
procedure Register;

implementation

uses
  System.Classes,
  Soft4You.FMX.Controls.Expander;

procedure Register;
begin
  RegisterComponents('Soft4You FMX Controls Suite', [TS4YExpander]);
end;

end.