unit Soft4You.FMX.Controls.FlexBox.ItemBase;

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
