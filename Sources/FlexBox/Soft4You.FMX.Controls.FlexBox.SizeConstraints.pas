unit Soft4You.FMX.Controls.FlexBox.SizeConstraints;

{
  Size limits of an item (CSS min-width, max-width, min-height, max-height),
  grouped in a persistent property like Margins and Padding.
  0 = no limit.
}

interface

uses
  System.Classes,
  System.Math;

type
  TS4YFlexSizeConstraints = class(TPersistent)
  strict private
    FMaxHeight: Single;
    FMaxWidth: Single;
    FMinHeight: Single;
    FMinWidth: Single;
    FOnChange: TNotifyEvent;

    function IsMaxHeightStored: Boolean;
    function IsMaxWidthStored: Boolean;
    function IsMinHeightStored: Boolean;
    function IsMinWidthStored: Boolean;
    procedure DoChange;
    procedure SetMaxHeight(Value: Single);
    procedure SetMaxWidth(Value: Single);
    procedure SetMinHeight(Value: Single);
    procedure SetMinWidth(Value: Single);
  public
    procedure Assign(Source: TPersistent); override;

    // True if no limit is set
    function IsEmpty: Boolean;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property MaxHeight: Single read FMaxHeight write SetMaxHeight stored IsMaxHeightStored;
    property MaxWidth: Single read FMaxWidth write SetMaxWidth stored IsMaxWidthStored;
    property MinHeight: Single read FMinHeight write SetMinHeight stored IsMinHeightStored;
    property MinWidth: Single read FMinWidth write SetMinWidth stored IsMinWidthStored;
  end;

implementation

{ TS4YFlexSizeConstraints }

procedure TS4YFlexSizeConstraints.Assign(Source: TPersistent);
var
  LSource: TS4YFlexSizeConstraints;
begin
  if Source is TS4YFlexSizeConstraints then
  begin
    LSource := TS4YFlexSizeConstraints(Source);
    if (FMaxHeight <> LSource.FMaxHeight) or (FMaxWidth <> LSource.FMaxWidth) or
      (FMinHeight <> LSource.FMinHeight) or (FMinWidth <> LSource.FMinWidth) then
    begin
      FMaxHeight := LSource.FMaxHeight;
      FMaxWidth := LSource.FMaxWidth;
      FMinHeight := LSource.FMinHeight;
      FMinWidth := LSource.FMinWidth;
      DoChange;
    end;
  end
  else
  begin
    inherited Assign(Source);
  end;
end;

procedure TS4YFlexSizeConstraints.DoChange;
begin
  if Assigned(FOnChange) then
  begin
    FOnChange(Self);
  end;
end;

function TS4YFlexSizeConstraints.IsEmpty: Boolean;
begin
  Result := (FMaxHeight = 0) and (FMaxWidth = 0) and (FMinHeight = 0) and (FMinWidth = 0);
end;

function TS4YFlexSizeConstraints.IsMaxHeightStored: Boolean;
begin
  Result := FMaxHeight <> 0;
end;

function TS4YFlexSizeConstraints.IsMaxWidthStored: Boolean;
begin
  Result := FMaxWidth <> 0;
end;

function TS4YFlexSizeConstraints.IsMinHeightStored: Boolean;
begin
  Result := FMinHeight <> 0;
end;

function TS4YFlexSizeConstraints.IsMinWidthStored: Boolean;
begin
  Result := FMinWidth <> 0;
end;

procedure TS4YFlexSizeConstraints.SetMaxHeight(Value: Single);
begin
  Value := Max(0, Value);
  if FMaxHeight <> Value then
  begin
    FMaxHeight := Value;
    DoChange;
  end;
end;

procedure TS4YFlexSizeConstraints.SetMaxWidth(Value: Single);
begin
  Value := Max(0, Value);
  if FMaxWidth <> Value then
  begin
    FMaxWidth := Value;
    DoChange;
  end;
end;

procedure TS4YFlexSizeConstraints.SetMinHeight(Value: Single);
begin
  Value := Max(0, Value);
  if FMinHeight <> Value then
  begin
    FMinHeight := Value;
    DoChange;
  end;
end;

procedure TS4YFlexSizeConstraints.SetMinWidth(Value: Single);
begin
  Value := Max(0, Value);
  if FMinWidth <> Value then
  begin
    FMinWidth := Value;
    DoChange;
  end;
end;

end.
