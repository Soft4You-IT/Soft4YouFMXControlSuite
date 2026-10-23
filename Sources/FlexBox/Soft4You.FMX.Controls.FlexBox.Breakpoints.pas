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

  /// <summary>
  /// Override of the properties of one item, for the width range of a breakpoint.
  /// </summary>
  /// <remarks>
  /// Item says which item the element refers to, and Overrides which of its properties the breakpoint changes: only those use the values of this element, the others keep the values of the item.
  /// The overrides apply while the breakpoint is active and do not change the published properties of the item.
  /// </remarks>
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
    /// <summary>Returns the caption of the element in the collection editor.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates the element with the default values and no overridden property.</summary>
    constructor Create(Collection: TCollection); override;
    /// <summary>Destroys the element.</summary>
    destructor Destroy; override;

    /// <summary>Overrides the input values of the item that are listed in Overrides, and reports the visibility override.</summary>
    procedure ApplyTo(var AInput: TFlexItemInput;
      var AVisibility: TS4YVisibilityOverride);
    /// <summary>Copies the item, the list of overridden properties and their values from another TS4YFlexItemOverride.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>AlignSelf of the item while the breakpoint is active. It applies when Overrides contains ioAlignSelf.</summary>
    property AlignSelf: TAlignSelf read FAlignSelf write SetAlignSelf default asAuto;
    /// <summary>AutoHeight of the item while the breakpoint is active. It applies when Overrides contains ioHeight.</summary>
    property AutoHeight: Boolean read FAutoHeight write SetAutoHeight default True;
    /// <summary>AutoWidth of the item while the breakpoint is active. It applies when Overrides contains ioWidth.</summary>
    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default True;
    /// <summary>FlexBasis of the item while the breakpoint is active. It applies when Overrides contains ioFlexBasis.</summary>
    property FlexBasis: Single read FFlexBasis write SetFlexBasis;
    /// <summary>FlexBasisUnit of the item while the breakpoint is active. It applies when Overrides contains ioFlexBasis.</summary>
    property FlexBasisUnit: TFlexBasisUnit read FFlexBasisUnit write SetFlexBasisUnit default fbuAuto;
    /// <summary>FlexGrow of the item while the breakpoint is active. It applies when Overrides contains ioFlexGrow.</summary>
    property FlexGrow: Single read FFlexGrow write SetFlexGrow;
    /// <summary>FlexShrink of the item while the breakpoint is active. It applies when Overrides contains ioFlexShrink.</summary>
    property FlexShrink: Single read FFlexShrink write SetFlexShrink stored IsFlexShrinkStored;
    /// <summary>Height of the item while the breakpoint is active. It applies when Overrides contains ioHeight.</summary>
    property Height: Single read FHeight write SetHeight;
    /// <summary>The item the override applies to.</summary>
    property Item: TS4YFlexItemBase read FItem write SetItem;
    /// <summary>Margins of the item while the breakpoint is active. They apply when Overrides contains ioMargins.</summary>
    property Margins: TBounds read FMargins write SetMargins;
    /// <summary>Order of the item while the breakpoint is active. It applies when Overrides contains ioOrder.</summary>
    property Order: Integer read FOrder write SetOrder default 0;
    /// <summary>Which properties of the item the element overrides; the others keep their own values.</summary>
    property Overrides: TS4YItemOverrides read FOverrides write SetOverrides default [];
    /// <summary>Limits of the size of the item while the breakpoint is active. Each one applies when Overrides contains the matching flag (ioMinWidth, ioMaxWidth, ioMinHeight, ioMaxHeight); 0 means no limit.</summary>
    property SizeConstraints: TS4YFlexSizeConstraints read FSizeConstraints write SetSizeConstraints;
    /// <summary>Visibility of the item while the breakpoint is active. It applies when Overrides contains ioVisible.</summary>
    property Visible: Boolean read FVisible write SetVisible default True;
    /// <summary>Width of the item while the breakpoint is active. It applies when Overrides contains ioWidth.</summary>
    property Width: Single read FWidth write SetWidth;
  end;

  /// <summary>
  /// The collection of the item overrides of a breakpoint.
  /// </summary>
  TS4YFlexItemOverrides = class(TOwnedCollection)
  strict private
    FBreakpoint: TS4YFlexBreakpoint;

    function GetItem(Index: Integer): TS4YFlexItemOverride;
    procedure SetItem(Index: Integer; const Value: TS4YFlexItemOverride);
  protected
    /// <summary>Notifies the breakpoint that an override changed.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the collection for the given breakpoint.</summary>
    constructor Create(ABreakpoint: TS4YFlexBreakpoint);

    /// <summary>Adds a new override.</summary>
    function Add: TS4YFlexItemOverride;

    /// <summary>Tells the collection that its breakpoint is about to be destroyed, so that it does not notify it any more.</summary>
    procedure Detach;

    /// <summary>Removes the overrides that refer to the given item.</summary>
    procedure RemoveItem(AItem: TComponent);

    /// <summary>The breakpoint that owns the collection.</summary>
    property Breakpoint: TS4YFlexBreakpoint read FBreakpoint;
    /// <summary>The overrides of the collection.</summary>
    property Items[Index: Integer]: TS4YFlexItemOverride read GetItem write SetItem; default;
  end;

  /// <summary>
  /// A width threshold of a TS4YFlexBox, with the container properties and the item properties that change while it is active.
  /// </summary>
  /// <remarks>
  /// ContainerOverrides says which container properties the breakpoint changes: only those use the values of the breakpoint. ItemOverrides does the same for individual items.
  /// Whether the breakpoint is active depends on Width and on the BreakpointMode of the flexbox. All the active breakpoints apply, as in CSS: the less specific ones first and the more specific ones later, so the later one wins on the same property.
  /// </remarks>
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
    /// <summary>Returns the caption of the breakpoint in the collection editor.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates the breakpoint with the default values and no overridden property.</summary>
    constructor Create(Collection: TCollection); override;
    /// <summary>Destroys the breakpoint and its item overrides.</summary>
    destructor Destroy; override;

    /// <summary>Overrides the container settings that are listed in ContainerOverrides.</summary>
    procedure ApplyTo(var ASettings: TS4YFlexSettings);

    /// <summary>Overrides the input values of an item with the item overrides of the breakpoint that refer to it, if there are any, and reports the visibility override.</summary>
    procedure ApplyToItem(const AItem: TControl; var AInput: TFlexItemInput;
      var AVisibility: TS4YVisibilityOverride);
    /// <summary>Copies the width, the overridden container properties and the item overrides from another TS4YFlexBreakpoint.</summary>
    procedure Assign(Source: TPersistent); override;
    /// <summary>True when the breakpoint is active for the given width, read as AMode says.</summary>
    function IsMatch(AWidth: Single; AMode: TS4YBreakpointMode): Boolean;
  published
    /// <summary>AlignContent of the container while the breakpoint is active. It applies when ContainerOverrides contains coAlignContent.</summary>
    property AlignContent: TAlignContent read FAlignContent write SetAlignContent default acFlexStart;
    /// <summary>AlignItems of the container while the breakpoint is active. It applies when ContainerOverrides contains coAlignItems.</summary>
    property AlignItems: TAlignItems read FAlignItems write SetAlignItems default aiStretch;
    /// <summary>ColumnGap of the container while the breakpoint is active. It applies when ContainerOverrides contains coColumnGap.</summary>
    property ColumnGap: Single read FColumnGap write SetColumnGap;
    /// <summary>Which properties of the container the breakpoint overrides; the others keep their own values.</summary>
    property ContainerOverrides: TS4YContainerOverrides read FContainerOverrides write SetContainerOverrides default [];
    /// <summary>Direction of the container while the breakpoint is active. It applies when ContainerOverrides contains coDirection.</summary>
    property Direction: TFlexDirection read FDirection write SetDirection default fdRow;
    /// <summary>Overrides of the properties of the individual items while the breakpoint is active.</summary>
    property ItemOverrides: TS4YFlexItemOverrides read FItemOverrides write SetItemOverrides;
    /// <summary>JustifyContent of the container while the breakpoint is active. It applies when ContainerOverrides contains coJustifyContent.</summary>
    property JustifyContent: TJustifyContent read FJustifyContent write SetJustifyContent default jcFlexStart;
    /// <summary>RowGap of the container while the breakpoint is active. It applies when ContainerOverrides contains coRowGap.</summary>
    property RowGap: Single read FRowGap write SetRowGap;
    /// <summary>Width of the threshold, in pixels. The breakpoint is active up to this width or from it up, according to the BreakpointMode of the flexbox.</summary>
    property Width: Single read FWidth write SetWidth;
    /// <summary>Wrap of the container while the breakpoint is active. It applies when ContainerOverrides contains coWrap.</summary>
    property Wrap: TFlexWrap read FWrap write SetWrap default fwNoWrap;
  end;

  /// <summary>
  /// The collection of the breakpoints of a TS4YFlexBox.
  /// </summary>
  TS4YFlexBreakpoints = class(TOwnedCollection)
  strict private
    FOnChanged: TNotifyEvent;
    FOwnerComponent: TComponent;

    function GetItem(Index: Integer): TS4YFlexBreakpoint;
    procedure SetItem(Index: Integer; const Value: TS4YFlexBreakpoint);
  protected
    /// <summary>Fires OnChanged when a breakpoint changes.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the collection for the given owner, which is normally the flexbox.</summary>
    constructor Create(AOwner: TPersistent);

    /// <summary>Adds a new breakpoint.</summary>
    function Add: TS4YFlexBreakpoint;

    /// <summary>Removes from all the breakpoints the overrides that refer to the given item.</summary>
    procedure RemoveItem(AItem: TComponent);

    /// <summary>
    /// Applies the breakpoints that match AWidth to the base settings and returns the settings in effect.
    /// </summary>
    /// <remarks>
    /// AActive receives the breakpoints that match AWidth, in the order in which they were applied: the less specific first, so that the later ones win on the same property.
    /// </remarks>
    function Resolve(AWidth: Single; AMode: TS4YBreakpointMode;
      const ABase: TS4YFlexSettings;
      out AActive: TArray<TS4YFlexBreakpoint>): TS4YFlexSettings;

    /// <summary>The breakpoints of the collection.</summary>
    property Items[Index: Integer]: TS4YFlexBreakpoint read GetItem write SetItem; default;
    /// <summary>Fires when a breakpoint changes.</summary>
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;

    /// <summary>The owner component, which is the flexbox. It receives the destruction notifications of the items that the overrides refer to.</summary>
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
