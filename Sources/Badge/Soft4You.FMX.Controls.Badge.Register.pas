unit Soft4You.FMX.Controls.Badge.Register;

interface

// ---------------------------------------------------------------------------
// Component registration (called by the IDE when the design-time package
// is installed)
// ---------------------------------------------------------------------------
procedure Register;

implementation

{$R BadgeDesign.res}

uses
  System.Classes,
  Soft4You.FMX.Controls.Badge;

procedure Register;
begin
  // The icon is read automatically from the bitmap resource whose name
  // matches the class name in upper case ('TS4YBADGE'), compiled into the
  // .res from BadgeDesign.rc.
  RegisterComponents('Soft4You FMX Controls Suite', [TS4YBadge]);
end;

end.