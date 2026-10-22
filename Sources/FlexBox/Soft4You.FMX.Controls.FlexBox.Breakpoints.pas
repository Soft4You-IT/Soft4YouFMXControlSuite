unit Soft4You.FMX.Controls.FlexBox.Breakpoints;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YFlexBox - CSS FlexBox layout container
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{
  Flexbox breakpoints (width thresholds)
  ======================================

  Each breakpoint has a Width, a set of container overrides
  (ContainerOverrides) with the related values, and a collection of item
  overrides (ItemOverrides). The mode (up to / from Width) is a single one for
  the whole list and lives on the flexbox (BreakpointMode).

  Cascade, as in CSS: ALL the breakpoints that match the current width are
  applied, from the least specific to the most specific, and the later one wins
  on the same properties. The order is computed here and does not depend on the
  position in the list (for equal Width the position decides):
  - bmMaxWidth: from the largest Width to the smallest
  - bmMinWidth: from the smallest Width to the largest
  Properties not touched by any active breakpoint keep their base values.

  Item overrides: each element of ItemOverrides designates an item (Item) and
  which of its properties the breakpoint overrides (Overrides). They apply with
  the same cascade as the container and do not modify the published properties
  of the item. If the item is deleted the element disappears (see RemoveItem).
}

interface

uses
  System.Classes,
  FMX.Controls,
  FMX.Types,
  Soft4You.FMX.Controls.FlexBox.Engine,
  Soft4You.FMX.Controls.FlexBox.ItemBase,
  Soft4You.FMX.Controls.FlexBox.SizeConstraints,
  Soft4You.FMX.Controls.FlexBox.Types;

type
  TS4YFlexBreakpoint = class;

  TS4YFlexItemOverride = class(TCollectionItem)
  strict private
    FAlignSelf: TAlignSelf;
    FAutoHeight: Boolean;
    FAutoWidth: Boolean;
    FFlexBasis: Single;
    FFlexBasisUnit: TFlexBasisUnit;
    FFlexGrow: Single;
    FFlexShrink: Single;
    FHeight: Single;
    FItem: TS4YFlexItemBase;
    FMargins: TBounds;
    FOrder: Integer;
    FOverrides: TS4YItemOverrides;
    FSizeConstraints: TS4YFlexSizeConstraints;
    FVisible: Boolean;
    FWidth: Single;

    function FindOwnerComponent: TComponent;
    function IsFlexShrinkStored: Boolean;
    function IsLoadingOwner: Boolean;
    procedure MarginsChanged(Sender: TObject);
    procedure SetAlignSelf(Value: TAlignSelf);
    procedure SetAutoHeight(Value: Boolean);
    procedure SetAutoWidth(Value: Boolean);
    procedure SetFlexBasis(Value: Single);
    procedure SetFlexBasisUnit(Value: TFlexBasisUnit);
    procedure SetFlexGrow(Value: Single);
    procedure SetFlexShrink(Value: Single);
    procedure SetHeight(Value: Single);
    procedure SetItem(Value: TS4YFlexItemBase);
    procedure SetMargins(Value: TBounds);
    procedure SetOrder(Value: Integer);
    procedure SetOverrides(Value: TS4YItemOverrides);
    procedure SetSizeConstraints(Value: TS4YFlexSizeConstraints);
    procedure SizeConstraintsChanged(Sender: TObject);
    procedure SetVisible(Value: Boolean);
    procedure SetWidth(Value: Single);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    // Overrides the engine input values listed in Overrides
    procedure ApplyTo(var AInput: TFlexItemInput;
      var AVisibility: TS4YVisibilityOverride);
    procedure Assign(Source: TPersistent); override;
  published
    property AlignSelf: TAlignSelf read FAlignSelf write SetAlignSelf default asAuto;
    property AutoHeight: Boolean read FAutoHeight write SetAutoHeight default True;
    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default True;
    property FlexBasis: Single read FFlexBasis write SetFlexBasis;
    property FlexBasisUnit: TFlexBasisUnit read FFlexBasisUnit write SetFlexBasisUnit default fbuAuto;
    property FlexGrow: Single read FFlexGrow write SetFlexGrow;
    property FlexShrink: Single read FFlexShrink write SetFlexShrink stored IsFlexShrinkStored;
    property Height: Single read FHeight write SetHeight;
    // The item the override applies to
    property Item: TS4YFlexItemBase read FItem write SetItem;
    property Margins: TBounds read FMargins write SetMargins;
    property Order: Integer read FOrder write SetOrder default 0;
    // Which item properties the element overrides; the others keep their base values
    property Overrides: TS4YItemOverrides read FOverrides write SetOverrides default [];
    // Values used by the ioMinWidth, ioMaxWidth, ioMinHeight and ioMaxHeight flags; 0 = no limit
    property SizeConstraints: TS4YFlexSizeConstraints read FSizeConstraints write SetSizeConstraints;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Width: Single read FWidth write SetWidth;
  end;

  TS4YFlexItemOverrides = class(TOwnedCollection)
  strict private
    FBreakpoint: TS4YFlexBreakpoint;

    function GetItem(Index: Integer): TS4YFlexItemOverride;
    procedure SetItem(Index: Integer; const Value: TS4YFlexItemOverride);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(ABreakpoint: TS4YFlexBreakpoint);

    function Add: TS4YFlexItemOverride;

    // The breakpoint is about to be destroyed: it must not be notified any more
    procedure Detach;

    // Removes the overrides that reference the given item
    procedure RemoveItem(AItem: TComponent);

    property Breakpoint: TS4YFlexBreakpoint read FBreakpoint;
    property Items[Index: Integer]: TS4YFlexItemOverride read GetItem write SetItem; default;
  end;

  TS4YFlexBreakpoint = class(TCollectionItem)
  strict private
    FAlignContent: TAlignContent;
    FAlignItems: TAlignItems;
    FColumnGap: Single;
    FContainerOverrides: TS4YContainerOverrides;
    FDirection: TFlexDirection;
    FItemOverrides: TS4YFlexItemOverrides;
    FJustifyContent: TJustifyContent;
    FRowGap: Single;
    FWidth: Single;
    FWrap: TFlexWrap;

    procedure SetAlignContent(Value: TAlignContent);
    procedure SetAlignItems(Value: TAlignItems);
    procedure SetColumnGap(Value: Single);
    procedure SetContainerOverrides(Value: TS4YContainerOverrides);
    procedure SetDirection(Value: TFlexDirection);
    procedure SetItemOverrides(Value: TS4YFlexItemOverrides);
    procedure SetJustifyContent(Value: TJustifyContent);
    procedure SetRowGap(Value: Single);
    procedure SetWidth(Value: Single);
    procedure SetWrap(Value: TFlexWrap);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    // Overrides the container settings listed in ContainerOverrides
    procedure ApplyTo(var ASettings: TS4YFlexSettings);

    // Overrides the item values listed in its overrides (if there are any)
    procedure ApplyToItem(const AItem: TControl; var AInput: TFlexItemInput;
      var AVisibility: TS4YVisibilityOverride);
    procedure Assign(Source: TPersistent); override;
    function IsMatch(AWidth: Single; AMode: TS4YBreakpointMode): Boolean;
  published
    property AlignContent: TAlignContent read FAlignContent write SetAlignContent default acFlexStart;
    property AlignItems: TAlignItems read FAlignItems write SetAlignItems default aiStretch;
    property ColumnGap: Single read FColumnGap write SetColumnGap;
    // Which container properties the breakpoint overrides; the others keep their base values
    property ContainerOverrides: TS4YContainerOverrides read FContainerOverrides write SetContainerOverrides default [];
    property Direction: TFlexDirection read FDirection write SetDirection default fdRow;
    // Overrides of the properties of the individual items
    property ItemOverrides: TS4YFlexItemOverrides read FItemOverrides write SetItemOverrides;
    property JustifyContent: TJustifyContent read FJustifyContent write SetJustifyContent default jcFlexStart;
    property RowGap: Single read FRowGap write SetRowGap;
    property Width: Single read FWidth write SetWidth;
    property Wrap: TFlexWrap read FWrap write SetWrap default fwNoWrap;
  end;

  TS4YFlexBreakpoints = class(TOwnedCollection)
  strict private
    FOnChanged: TNotifyEvent;
    FOwnerComponent: TComponent;

    function GetItem(Index: Integer): TS4YFlexBreakpoint;
    procedure SetItem(Index: Integer; const Value: TS4YFlexBreakpoint);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);

    function Add: TS4YFlexBreakpoint;

    // Removes from all breakpoints the overrides that reference the given item
    procedure RemoveItem(AItem: TComponent);

    // Applies the cascade to the base values. AActive receives the breakpoints
    // that match AWidth, in the order in which they were applied.
    function Resolve(AWidth: Single; AMode: TS4YBreakpointMode;
      const ABase: TS4YFlexSettings;
      out AActive: TArray<TS4YFlexBreakpoint>): TS4YFlexSettings;

    property Items[Index: Integer]: TS4YFlexBreakpoint read GetItem write SetItem; default;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;

    // The owner component (the flexbox): it receives the
    // destruction notifications of the items referenced by the overrides
    property OwnerComponent: TComponent read FOwnerComponent;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.Types,
  System.Generics.Collections,
  System.Generics.Defaults,
  Soft4You.FMX.Controls.FlexBox.Strings;

const
  C_DEFAULT_WIDTH = 600;
  C_DEFAULT_ITEM_SIZE = 100;

// ===========================================================================
// TS4YFlexItemOverride
// ===========================================================================

constructor TS4YFlexItemOverride.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FAlignSelf := asAuto;
  FAutoHeight := True;
  FAutoWidth := True;
  FFlexBasisUnit := fbuAuto;
  FFlexShrink := 1;
  FHeight := C_DEFAULT_ITEM_SIZE;
  FMargins := TBounds.Create(TRectF.Empty);
  FMargins.OnChange := MarginsChanged;
  FSizeConstraints := TS4YFlexSizeConstraints.Create;
  FSizeConstraints.OnChange := SizeConstraintsChanged;
  FVisible := True;
  FWidth := C_DEFAULT_ITEM_SIZE;
end;

destructor TS4YFlexItemOverride.Destroy;
begin
  FMargins.OnChange := nil;
  FMargins.Free;
  FSizeConstraints.Free;
  inherited;
end;

procedure TS4YFlexItemOverride.ApplyTo(var AInput: TFlexItemInput;
  var AVisibility: TS4YVisibilityOverride);
begin
  if ioFlexGrow in FOverrides then
  begin
    AInput.FlexGrow := FFlexGrow;
  end;

  if ioFlexShrink in FOverrides then
  begin
    AInput.FlexShrink := FFlexShrink;
  end;

  if ioFlexBasis in FOverrides then
  begin
    AInput.FlexBasis := FFlexBasis;
    AInput.FlexBasisUnit := FFlexBasisUnit;
  end;

  if ioAlignSelf in FOverrides then
  begin
    AInput.AlignSelf := FAlignSelf;
  end;

  if ioOrder in FOverrides then
  begin
    AInput.Order := FOrder;
  end;

  if ioVisible in FOverrides then
  begin
    if FVisible then
    begin
      AVisibility := voShow;
    end
    else
    begin
      AVisibility := voHide;
    end;
  end;

  if ioWidth in FOverrides then
  begin
    AInput.WidthAuto := FAutoWidth;

    if not FAutoWidth then
    begin
      AInput.NaturalWidth := FWidth;
    end;
  end;

  if ioHeight in FOverrides then
  begin
    AInput.HeightAuto := FAutoHeight;

    if not FAutoHeight then
    begin
      AInput.NaturalHeight := FHeight;
    end;
  end;

  if ioMargins in FOverrides then
  begin
    AInput.MarginLeft := FMargins.Left;
    AInput.MarginTop := FMargins.Top;
    AInput.MarginRight := FMargins.Right;
    AInput.MarginBottom := FMargins.Bottom;
  end;

  if ioMinWidth in FOverrides then
  begin
    AInput.MinWidth := FSizeConstraints.MinWidth;
  end;

  if ioMaxWidth in FOverrides then
  begin
    AInput.MaxWidth := FSizeConstraints.MaxWidth;
  end;

  if ioMinHeight in FOverrides then
  begin
    AInput.MinHeight := FSizeConstraints.MinHeight;
  end;

  if ioMaxHeight in FOverrides then
  begin
    AInput.MaxHeight := FSizeConstraints.MaxHeight;
  end;
end;

procedure TS4YFlexItemOverride.Assign(Source: TPersistent);
var
  LSource: TS4YFlexItemOverride;
begin
  if Source is TS4YFlexItemOverride then
  begin
    LSource := TS4YFlexItemOverride(Source);
    FAlignSelf := LSource.FAlignSelf;
    FAutoHeight := LSource.FAutoHeight;
    FAutoWidth := LSource.FAutoWidth;
    FFlexBasis := LSource.FFlexBasis;
    FFlexBasisUnit := LSource.FFlexBasisUnit;
    FFlexGrow := LSource.FFlexGrow;
    FFlexShrink := LSource.FFlexShrink;
    FHeight := LSource.FHeight;
    FMargins.OnChange := nil;
    try
      FMargins.Assign(LSource.FMargins);
    finally
      FMargins.OnChange := MarginsChanged;
    end;

    FOrder := LSource.FOrder;
    FOverrides := LSource.FOverrides;
    FSizeConstraints.OnChange := nil;
    try
      FSizeConstraints.Assign(LSource.FSizeConstraints);
    finally
      FSizeConstraints.OnChange := SizeConstraintsChanged;
    end;

    FVisible := LSource.FVisible;
    FWidth := LSource.FWidth;
    SetItem(LSource.FItem);
    Changed(False);
  end
  else
  begin
    inherited Assign(Source);
  end;
end;

function TS4YFlexItemOverride.GetDisplayName: string;
begin
  if FItem <> nil then
  begin
    Result := FItem.Name;
  end
  else
  begin
    Result := SFlexItemOverrideNoItem;
  end;
end;

function TS4YFlexItemOverride.FindOwnerComponent: TComponent;
var
  LBreakpoint: TS4YFlexBreakpoint;
begin
  Result := nil;

  if Collection is TS4YFlexItemOverrides then
  begin
    LBreakpoint := TS4YFlexItemOverrides(Collection).Breakpoint;

    if (LBreakpoint <> nil) and (LBreakpoint.Collection is TS4YFlexBreakpoints) then
    begin
      Result := TS4YFlexBreakpoints(LBreakpoint.Collection).OwnerComponent;
    end;
  end;
end;

function TS4YFlexItemOverride.IsFlexShrinkStored: Boolean;
begin
  Result := FFlexShrink <> 1;
end;

function TS4YFlexItemOverride.IsLoadingOwner: Boolean;
var
  LOwnerComponent: TComponent;
begin
  LOwnerComponent := FindOwnerComponent;
  Result := (LOwnerComponent <> nil) and
    (LOwnerComponent.ComponentState * [csLoading, csReading] <> []);
end;

procedure TS4YFlexItemOverride.MarginsChanged(Sender: TObject);
begin
  Changed(False);
end;

procedure TS4YFlexItemOverride.SetAlignSelf(Value: TAlignSelf);
begin
  if FAlignSelf <> Value then
  begin
    FAlignSelf := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetAutoHeight(Value: Boolean);
begin
  if FAutoHeight <> Value then
  begin
    FAutoHeight := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetAutoWidth(Value: Boolean);
begin
  if FAutoWidth <> Value then
  begin
    FAutoWidth := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetFlexBasis(Value: Single);
begin
  Value := Max(0, Value);

  if FFlexBasis <> Value then
  begin
    FFlexBasis := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetFlexBasisUnit(Value: TFlexBasisUnit);
begin
  if FFlexBasisUnit <> Value then
  begin
    FFlexBasisUnit := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetFlexGrow(Value: Single);
begin
  Value := Max(0, Value);

  if FFlexGrow <> Value then
  begin
    FFlexGrow := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetFlexShrink(Value: Single);
begin
  Value := Max(0, Value);

  if FFlexShrink <> Value then
  begin
    FFlexShrink := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetSizeConstraints(Value: TS4YFlexSizeConstraints);
begin
  FSizeConstraints.Assign(Value);
end;

procedure TS4YFlexItemOverride.SizeConstraintsChanged(Sender: TObject);
begin
  Changed(False);
end;

procedure TS4YFlexItemOverride.SetHeight(Value: Single);
begin
  Value := Max(0, Value);

  if FHeight <> Value then
  begin
    FHeight := Value;

    // As in the item, setting the height makes it explicit (not while
    // loading, where AutoHeight comes from the file)
    if not IsLoadingOwner then
    begin
      FAutoHeight := False;
    end;

    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetItem(Value: TS4YFlexItemBase);
var
  LOwnerComponent: TComponent;
begin
  if FItem <> Value then
  begin
    FItem := Value;

    // If the item is deleted the flexbox deletes the override (RemoveItem)
    if FItem <> nil then
    begin
      LOwnerComponent := FindOwnerComponent;

      if LOwnerComponent <> nil then
      begin
        FItem.FreeNotification(LOwnerComponent);
      end;
    end;

    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetMargins(Value: TBounds);
begin
  FMargins.Assign(Value);
end;

procedure TS4YFlexItemOverride.SetOrder(Value: Integer);
begin
  if FOrder <> Value then
  begin
    FOrder := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetOverrides(Value: TS4YItemOverrides);
begin
  if FOverrides <> Value then
  begin
    FOverrides := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetVisible(Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexItemOverride.SetWidth(Value: Single);
begin
  Value := Max(0, Value);

  if FWidth <> Value then
  begin
    FWidth := Value;

    // As in the item, setting the width makes it explicit (not while
    // loading, where AutoWidth comes from the file)
    if not IsLoadingOwner then
    begin
      FAutoWidth := False;
    end;

    Changed(False);
  end;
end;

// ===========================================================================
// TS4YFlexItemOverrides
// ===========================================================================

constructor TS4YFlexItemOverrides.Create(ABreakpoint: TS4YFlexBreakpoint);
begin
  inherited Create(ABreakpoint, TS4YFlexItemOverride);
  FBreakpoint := ABreakpoint;
end;

function TS4YFlexItemOverrides.Add: TS4YFlexItemOverride;
begin
  Result := TS4YFlexItemOverride(inherited Add);
end;

procedure TS4YFlexItemOverrides.Detach;
begin
  FBreakpoint := nil;
end;

function TS4YFlexItemOverrides.GetItem(Index: Integer): TS4YFlexItemOverride;
begin
  Result := TS4YFlexItemOverride(inherited GetItem(Index));
end;

procedure TS4YFlexItemOverrides.RemoveItem(AItem: TComponent);
var
  LIndex: Integer;
begin
  for LIndex := Count - 1 downto 0 do
  begin
    if Items[LIndex].Item = AItem then
    begin
      Delete(LIndex);
    end;
  end;
end;

procedure TS4YFlexItemOverrides.SetItem(Index: Integer; const Value: TS4YFlexItemOverride);
begin
  inherited SetItem(Index, Value);
end;

procedure TS4YFlexItemOverrides.Update(Item: TCollectionItem);
begin
  inherited;

  // The flexbox notices the change through the breakpoint that owns the list
  if FBreakpoint <> nil then
  begin
    FBreakpoint.Changed(False);
  end;
end;

// ===========================================================================
// TS4YFlexBreakpoint
// ===========================================================================

constructor TS4YFlexBreakpoint.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FAlignContent := acFlexStart;
  FAlignItems := aiStretch;
  FDirection := fdRow;
  FItemOverrides := TS4YFlexItemOverrides.Create(Self);
  FJustifyContent := jcFlexStart;
  FWidth := C_DEFAULT_WIDTH;
  FWrap := fwNoWrap;
end;

destructor TS4YFlexBreakpoint.Destroy;
begin
  FItemOverrides.Detach;
  FItemOverrides.Free;
  inherited;
end;

procedure TS4YFlexBreakpoint.ApplyTo(var ASettings: TS4YFlexSettings);
begin
  if coDirection in FContainerOverrides then
  begin
    ASettings.Direction := FDirection;
  end;

  if coWrap in FContainerOverrides then
  begin
    ASettings.Wrap := FWrap;
  end;

  if coJustifyContent in FContainerOverrides then
  begin
    ASettings.JustifyContent := FJustifyContent;
  end;

  if coAlignItems in FContainerOverrides then
  begin
    ASettings.AlignItems := FAlignItems;
  end;

  if coAlignContent in FContainerOverrides then
  begin
    ASettings.AlignContent := FAlignContent;
  end;

  if coColumnGap in FContainerOverrides then
  begin
    ASettings.ColumnGap := FColumnGap;
  end;

  if coRowGap in FContainerOverrides then
  begin
    ASettings.RowGap := FRowGap;
  end;
end;

procedure TS4YFlexBreakpoint.ApplyToItem(const AItem: TControl;
  var AInput: TFlexItemInput; var AVisibility: TS4YVisibilityOverride);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FItemOverrides.Count - 1 do
  begin
    if FItemOverrides[LIndex].Item = AItem then
    begin
      FItemOverrides[LIndex].ApplyTo(AInput, AVisibility);
    end;
  end;
end;

procedure TS4YFlexBreakpoint.Assign(Source: TPersistent);
var
  LSource: TS4YFlexBreakpoint;
begin
  if Source is TS4YFlexBreakpoint then
  begin
    LSource := TS4YFlexBreakpoint(Source);
    FAlignContent := LSource.FAlignContent;
    FAlignItems := LSource.FAlignItems;
    FColumnGap := LSource.FColumnGap;
    FContainerOverrides := LSource.FContainerOverrides;
    FDirection := LSource.FDirection;
    FItemOverrides.Assign(LSource.FItemOverrides);
    FJustifyContent := LSource.FJustifyContent;
    FRowGap := LSource.FRowGap;
    FWidth := LSource.FWidth;
    FWrap := LSource.FWrap;
    Changed(False);
  end
  else
  begin
    inherited Assign(Source);
  end;
end;

function TS4YFlexBreakpoint.GetDisplayName: string;
begin
  Result := Format('Width %g', [FWidth]);
end;

function TS4YFlexBreakpoint.IsMatch(AWidth: Single; AMode: TS4YBreakpointMode): Boolean;
begin
  if AMode = bmMaxWidth then
  begin
    Result := AWidth <= FWidth;
  end
  else
  begin
    Result := AWidth >= FWidth;
  end;
end;

procedure TS4YFlexBreakpoint.SetAlignContent(Value: TAlignContent);
begin
  if FAlignContent <> Value then
  begin
    FAlignContent := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexBreakpoint.SetAlignItems(Value: TAlignItems);
begin
  if FAlignItems <> Value then
  begin
    FAlignItems := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexBreakpoint.SetColumnGap(Value: Single);
begin
  Value := Max(0, Value);

  if FColumnGap <> Value then
  begin
    FColumnGap := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexBreakpoint.SetContainerOverrides(Value: TS4YContainerOverrides);
begin
  if FContainerOverrides <> Value then
  begin
    FContainerOverrides := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexBreakpoint.SetDirection(Value: TFlexDirection);
begin
  if FDirection <> Value then
  begin
    FDirection := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexBreakpoint.SetItemOverrides(Value: TS4YFlexItemOverrides);
begin
  FItemOverrides.Assign(Value);
end;

procedure TS4YFlexBreakpoint.SetJustifyContent(Value: TJustifyContent);
begin
  if FJustifyContent <> Value then
  begin
    FJustifyContent := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexBreakpoint.SetRowGap(Value: Single);
begin
  Value := Max(0, Value);

  if FRowGap <> Value then
  begin
    FRowGap := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexBreakpoint.SetWidth(Value: Single);
begin
  Value := Max(0, Value);

  if FWidth <> Value then
  begin
    FWidth := Value;
    Changed(False);
  end;
end;

procedure TS4YFlexBreakpoint.SetWrap(Value: TFlexWrap);
begin
  if FWrap <> Value then
  begin
    FWrap := Value;
    Changed(False);
  end;
end;

// ===========================================================================
// TS4YFlexBreakpoints
// ===========================================================================

constructor TS4YFlexBreakpoints.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YFlexBreakpoint);

  if AOwner is TComponent then
  begin
    FOwnerComponent := TComponent(AOwner);
  end;
end;

function TS4YFlexBreakpoints.Add: TS4YFlexBreakpoint;
begin
  Result := TS4YFlexBreakpoint(inherited Add);
end;

function TS4YFlexBreakpoints.GetItem(Index: Integer): TS4YFlexBreakpoint;
begin
  Result := TS4YFlexBreakpoint(inherited GetItem(Index));
end;

procedure TS4YFlexBreakpoints.RemoveItem(AItem: TComponent);
var
  LIndex: Integer;
begin
  for LIndex := 0 to Count - 1 do
  begin
    Items[LIndex].ItemOverrides.RemoveItem(AItem);
  end;
end;

procedure TS4YFlexBreakpoints.SetItem(Index: Integer; const Value: TS4YFlexBreakpoint);
begin
  inherited SetItem(Index, Value);
end;

procedure TS4YFlexBreakpoints.Update(Item: TCollectionItem);
begin
  inherited;

  if Assigned(FOnChanged) then
  begin
    FOnChanged(Self);
  end;
end;

function TS4YFlexBreakpoints.Resolve(AWidth: Single; AMode: TS4YBreakpointMode;
  const ABase: TS4YFlexSettings;
  out AActive: TArray<TS4YFlexBreakpoint>): TS4YFlexSettings;
var
  LIndex: Integer;
  LMatching: TList<TS4YFlexBreakpoint>;
  LBreakpoint: TS4YFlexBreakpoint;
begin
  Result := ABase;
  LMatching := TList<TS4YFlexBreakpoint>.Create;
  try
    for LIndex := 0 to Count - 1 do
    begin
      if Items[LIndex].IsMatch(AWidth, AMode) then
      begin
        LMatching.Add(Items[LIndex]);
      end;
    end;

    LMatching.Sort(TComparer<TS4YFlexBreakpoint>.Construct(
      function(const ALeft, ARight: TS4YFlexBreakpoint): Integer
      begin
        if AMode = bmMaxWidth then
        begin
          Result := CompareValue(ARight.Width, ALeft.Width);
        end
        else
        begin
          Result := CompareValue(ALeft.Width, ARight.Width);
        end;

        if Result = 0 then
        begin
          Result := CompareValue(ALeft.Index, ARight.Index);
        end;
      end));

    for LBreakpoint in LMatching do
    begin
      LBreakpoint.ApplyTo(Result);
    end;

    AActive := LMatching.ToArray;
  finally
    LMatching.Free;
  end;
end;

end.
