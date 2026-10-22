unit Soft4You.FMX.Controls.FlexBox;

{
  Soft4You.FMX.Controls.FlexBox - FireMonkey container with CSS FlexBox layout
  =============================================================================

  COMPONENTS
  ----------
  TS4YFlexBox : TControl
    Main container. It intercepts DoRealign and delegates the computation to
    TFlexEngine. It exposes the CSS properties of the container (direction, wrap,
    justify-content, align-items, align-content, gap).

  TS4YFlexItem : TControl
    Element of the flexbox. Every control that takes part in the layout lives
    inside a TS4YFlexItem, which exposes the CSS properties of the item
    (flex-grow, flex-shrink, flex-basis, align-self, order) in the Object
    Inspector. An item hosts a single control; for several controls use a
    container (layout, panel, ...) as the content of the item.

  AUTOMATIC WRAPPING
  ------------------
  When a control that is not a TS4YFlexItem becomes a child of a
  TS4YFlexBox, a TS4YFlexItem with the same position and size is created, and
  the control is moved inside it with Align = Top (the item follows the height
  of the content until the user sets an explicit height; with an explicit
  height the content stays Top and keeps its own height, never Align = Client:
  the item has the given height and the content, for example a TExpander, can
  change height on its own). The margins of the control go to the item.
  - At runtime the wrapping is done by the component itself.
  - At design time it is delegated to DesignWrapHandler, set by the
    design-time package (the IDE designer is needed to create the item
    correctly: name, Structure view, undo).
  - No wrapping happens while the DFM is loading.

  A TS4YFlexItem rejects a second control: the new control is moved back
  into the flexbox, which creates a dedicated item for it. An item left
  without controls is deleted and the flexbox recalculates the layout.

  A TS4YFlexItem lives only inside a TS4YFlexBox: at runtime SetParent with
  another Parent raises EInvalidOperation (not while loading and not at
  design time, where the designer creates the item in transit). The item is
  not registered in the palette (RegisterNoIcon): the flexbox creates it.

  BREAKPOINTS
  -----------
  Breakpoints (+ BreakpointMode) override the properties of the container
  (ContainerOverrides) and those of the individual items (ItemOverrides) based
  on the width of the flexbox, with a CSS cascade (see Breakpoints.pas). The
  effective values are computed at every layout (ResolveSettings, BuildContext)
  without modifying the published properties; they also apply at design time.
  OnBreakpointsChanged fires after the layout is done when the set of active
  breakpoints changes.

  Visible of an item: the override (ioVisible) hides or shows the item for the
  duration of the breakpoint, without losing the Visible chosen by the user
  (FUserVisible), which is the one saved in the file.

  AUTO WIDTH
  ----------
  Like AutoHeight, AutoWidth is True until the user sets Width. An auto size on
  the cross axis stretches (align-items/align-self); in a column the auto width
  fits the width of the flexbox (fit-content), while an explicit width does not
  stretch and is not reduced. With Wrap = fwNoWrap the line takes the whole
  cross size of the flexbox (as in CSS).

  PROBLEM 1 - Realign loop
  ------------------------
  FMX calls DoRealign in cascade when a child changes size.
  Solution: reentrant counter FLayoutDepth. SetBounds on the items is
  protected by BeginLayout/EndLayout.

  PROBLEM 2 - Filtering of the children
  -------------------------------------
  Only the visible TS4YFlexItem that are not loading/being destroyed take
  part in the layout (see IsFlexChild). BuildContext returns FlexChildren, a
  compact array parallel to Context.Items: OriginalIndex is the index in
  FlexChildren and not in Controls[].

  MINIMAL USE
  -----------
    LFlexBox := TS4YFlexBox.Create(Self);
    LFlexBox.Parent := Self;
    LFlexBox.SetBounds(0, 0, 400, 300);
    LFlexBox.JustifyContent := jcSpaceBetween;

    LButton := TButton.Create(Self);
    LButton.Parent := LFlexBox;  // automatically creates the TS4YFlexItem
    (LButton.Parent as TS4YFlexItem).FlexGrow := 1;
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  FMX.Types,
  FMX.Controls,
  Soft4You.FMX.Controls.FlexBox.Breakpoints,
  Soft4You.FMX.Controls.FlexBox.Engine,
  Soft4You.FMX.Controls.FlexBox.ItemBase,
  Soft4You.FMX.Controls.FlexBox.SizeConstraints,
  Soft4You.FMX.Controls.FlexBox.Types;

type
  TS4YFlexBox = class;
  TS4YFlexItem = class;

  // Design-time wrapping handler, set by the design-time package
  TS4YFlexDesignWrapHandler = reference to procedure(const AFlexBox: TS4YFlexBox;
    const AControl: TControl);

  // Change of the item state with respect to the flex-basis (at the first layout
  // APreviousState equals AState)
  TS4YFlexItemStateEvent = procedure(Sender: TObject; AState,
    APreviousState: TFlexItemState) of object;

  // Change of the item line (at the first layout APreviousLineIndex is -1)
  TS4YFlexItemLineEvent = procedure(Sender: TObject; ALineIndex,
    APreviousLineIndex: Integer) of object;

  // Change of the flexbox line count (at the first layout APreviousLineCount is -1)
  TS4YFlexLineCountEvent = procedure(Sender: TObject; ALineCount,
    APreviousLineCount: Integer) of object;

  // Weak reference to an item, used by deferred drop requests
  IS4YFlexItemHandle = interface
    ['{7B1E3C52-5A0F-4D6B-9E34-2F1C8A6D0B71}']
    function GetItem: TS4YFlexItem;
    procedure Detach;
    property Item: TS4YFlexItem read GetItem;
  end;

  TS4YFlexItem = class(TS4YFlexItemBase)
  strict private
    FFlexGrow: Single;
    FFlexShrink: Single;
    FFlexBasis: Single;
    FFlexBasisUnit: TFlexBasisUnit;
    FAlignSelf: TAlignSelf;
    FOrder: Integer;
    FSizeConstraints: TS4YFlexSizeConstraints;
    FHandle: IS4YFlexItemHandle;
    FApplyingLayout: Boolean;
    FApplyingVisibility: Boolean;
    FUserVisible: Boolean;
    FVisibilityOverride: TS4YVisibilityOverride;
    FDesignWidth: Single;
    FDesignHeight: Single;
    FDesignHeightLoaded: Boolean;
    FDesignWidthLoaded: Boolean;
    FHeightExplicit: Boolean;
    FWidthExplicit: Boolean;
    FLayoutWidth: Single;
    FLayoutHeight: Single;
    FHasLayoutSize: Boolean;
    FFlexState: TFlexItemState;
    FLineIndex: Integer;
    FOutcomeBaseMain: Single;
    FOutcomeLineIndex: Integer;
    FOutcomeMainSize: Single;
    FOnFlexStateChanged: TS4YFlexItemStateEvent;
    FOnLineChanged: TS4YFlexItemLineEvent;
    FOnLayoutChanged: TNotifyEvent;
    FNotifiedBounds: TRectF;
    FFitContent: Boolean;
    FHookedContent: TControl;
    FPreviousContentResized: TNotifyEvent;

    procedure ApplyFitContent(const AContent: TControl);
    procedure ContentResized(Sender: TObject);
    procedure HookContent(const AContent: TControl);
    procedure PlaceContent;
    procedure SetFitContent(Value: Boolean);
    procedure UnhookContent;
    function GetAutoHeight: Boolean;
    function GetAutoWidth: Boolean;
    function GetContent: TControl;
    function GetFlexBox: TS4YFlexBox;
    function IsContentControl(const AControl: TControl): Boolean;
    function IsAutoHeightStored: Boolean;
    function IsAutoWidthStored: Boolean;
    function IsFlexShrinkStored: Boolean;
    function IsLoadingOrDestroying: Boolean;
    procedure InvalidateFlexBox;
    procedure ReleaseWhenEmpty;
    procedure SetAlignSelf(Value: TAlignSelf);
    procedure SetAutoHeight(Value: Boolean);
    procedure SetAutoWidth(Value: Boolean);
    procedure ReadDesignHeight(Reader: TReader);
    procedure ReadDesignWidth(Reader: TReader);
    procedure ReadHeightExplicit(Reader: TReader);
    procedure UpdateContentHeight;
    procedure WriteDesignHeight(Writer: TWriter);
    procedure WriteDesignWidth(Writer: TWriter);
    procedure SetFlexBasis(Value: Single);
    procedure SetFlexBasisUnit(Value: TFlexBasisUnit);
    procedure SetFlexGrow(Value: Single);
    procedure SetFlexShrink(Value: Single);
    procedure SetOrder(Value: Integer);
    procedure SetSizeConstraints(Value: TS4YFlexSizeConstraints);
    procedure SizeConstraintsChanged(Sender: TObject);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoAddObject(const AObject: TFmxObject); override;
    procedure DoFlexStateChanged(AState, APreviousState: TFlexItemState); virtual;
    procedure SetVisible(const Value: Boolean); override;
    function VisibleStored: Boolean; override;
    procedure DoLayoutChanged; virtual;
    procedure DoLineChanged(ALineIndex, APreviousLineIndex: Integer); virtual;
    procedure DoRealign; override;
    procedure DoRemoveObject(const AObject: TFmxObject); override;
    procedure Loaded; override;
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean;
      ANewWidth, ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean; override;
    procedure SetParent(const Value: TFmxObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Applies the bounds computed by the layout without altering the design size
    procedure ApplyLayoutBounds(ALeft, ATop, AWidth, AHeight: Single);

    // Called by the flexbox at every layout: shows/hides the item according to the
    // active breakpoints, without losing the Visible chosen by the user
    procedure ApplyVisibilityOverride(AVisibility: TS4YVisibilityOverride);

    // Called by the flexbox: the second one stores the outcome of the last layout, the
    // first one (after the layout is done) fires the events if something changed
    procedure NotifyLayoutOutcome;
    procedure StoreLayoutOutcome(AMainSize, ABaseMain: Single; ALineIndex: Integer);

    // "Auto" height: the item follows the height of the content (like CSS height: auto)
    procedure UseContentHeight;

    // Converts to TFlexItemInput for TFlexEngine
    function ToEngineInput: TFlexItemInput;

    property FlexBox: TS4YFlexBox read GetFlexBox;
  published
    property AlignSelf: TAlignSelf read FAlignSelf write SetAlignSelf default asAuto;
    // True: the height follows the content (height: auto). False: explicit height,
    // also set by changing Height or by resizing the item in the designer.
    property AutoHeight: Boolean read GetAutoHeight write SetAutoHeight stored IsAutoHeightStored;
    // True: the width is not an explicit choice (width: auto). On the cross axis
    // the item stretches and, in a column, fits the width of the flexbox;
    // the design width stays the starting one. False: explicit width,
    // also set by changing Width or by resizing the item in the designer.
    property AutoWidth: Boolean read GetAutoWidth write SetAutoWidth stored IsAutoWidthStored;
    // True: the automatic size (width and height not explicit) is that
    // of the content itself, for example a TLabel with AutoSize. The content is
    // no longer Align = Top: it keeps its size, at the top left (after the
    // Padding), even if the item grows. False: the content follows the width
    // of the item.
    property FitContent: Boolean read FFitContent write SetFitContent default False;
    property FlexBasis: Single read FFlexBasis write SetFlexBasis;
    property FlexBasisUnit: TFlexBasisUnit read FFlexBasisUnit write SetFlexBasisUnit default fbuAuto;
    property FlexGrow: Single read FFlexGrow write SetFlexGrow;
    property FlexShrink: Single read FFlexShrink write SetFlexShrink stored IsFlexShrinkStored;
    property Height;
    // Position of the item in the flexbox (source order): not saved, the order
    // is already that of the objects in the file
    property Index stored False;
    property Margins;
    property Order: Integer read FOrder write SetOrder default 0;
    property Padding;
    property Size;
    // Size limits like min-/max-width and min-/max-height in CSS (0 = no
    // limit): they apply even with an explicit size and apply to the layout
    // of the item, not to the content
    property SizeConstraints: TS4YFlexSizeConstraints read FSizeConstraints write SetSizeConstraints;
    property Visible;
    property Width;
    property OnFlexStateChanged: TS4YFlexItemStateEvent read FOnFlexStateChanged write FOnFlexStateChanged;
    // Position or size of the item changed since the last notified layout
    // (also at the first layout)
    property OnLayoutChanged: TNotifyEvent read FOnLayoutChanged write FOnLayoutChanged;
    property OnLineChanged: TS4YFlexItemLineEvent read FOnLineChanged write FOnLineChanged;
  end;

  TS4YFlexBox = class(TControl)
  strict private
    class var FDesignWrapHandler: TS4YFlexDesignWrapHandler;
  strict private
    FLayoutDepth: Integer;
    FDirection: TFlexDirection;
    FWrap: TFlexWrap;
    FJustifyContent: TJustifyContent;
    FAlignItems: TAlignItems;
    FAlignContent: TAlignContent;
    FColumnGap: Single;
    FRowGap: Single;
    FLineCount: Integer;
    FActiveBreakpoints: TArray<TS4YFlexBreakpoint>;
    FBreakpointMode: TS4YBreakpointMode;
    FBreakpoints: TS4YFlexBreakpoints;
    FNotifiedBreakpointIndexes: TArray<Integer>;
    FOnBreakpointsChanged: TNotifyEvent;
    FOnLayoutApplied: TNotifyEvent;
    FOnLineCountChanged: TS4YFlexLineCountEvent;

    function BuildContext(const ASettings: TS4YFlexSettings;
      out AFlexChildren: TArray<TControl>): TFlexContext;
    function GetUpdatingLayout: Boolean;
    function IsContentControl(const AControl: TControl): Boolean;
    function IsLoadingOrDestroying: Boolean;
    function ApplyResults(const AResults: TArray<TFlexItemResult>;
      const AFlexChildren: TArray<TControl>; ADirection: TFlexDirection): Integer;
    function ResolveSettings: TS4YFlexSettings;
    procedure BreakpointsChanged(Sender: TObject);
    procedure NotifyBreakpointsChanged;
    procedure NotifyLayoutApplied(const AFlexChildren: TArray<TControl>;
      ALineCount: Integer);
    procedure BeginLayout;
    procedure EndLayout;
    procedure SetAlignContent(Value: TAlignContent);
    procedure SetAlignItems(Value: TAlignItems);
    procedure SetBreakpointMode(Value: TS4YBreakpointMode);
    procedure SetBreakpoints(Value: TS4YFlexBreakpoints);
    procedure SetColumnGap(Value: Single);
    procedure SetDirection(Value: TFlexDirection);
    procedure SetJustifyContent(Value: TJustifyContent);
    procedure SetRowGap(Value: Single);
    procedure SetWrap(Value: TFlexWrap);
  protected
    procedure DoAddObject(const AObject: TFmxObject); override;
    procedure DoBreakpointsChanged; virtual;
    procedure DoLayoutApplied; virtual;
    procedure DoLineCountChanged(ALineCount, APreviousLineCount: Integer); virtual;
    procedure DoRealign; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    // Layout inclusion predicate
    class function IsFlexChild(AChild: TControl): Boolean; static;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Forces a layout recalculation (useful after programmatic changes)
    procedure InvalidateLayout;

    // Creates a TS4YFlexItem child of the flexbox and moves the control into it
    function WrapControl(const AControl: TControl): TS4YFlexItem;

    // Moves the control into the given item (already created by the caller,
    // for example by the designer), copying position, size and margins
    procedure WrapInItem(const AControl: TControl; const AItem: TS4YFlexItem);

    // Breakpoints that match the width in the last layout (empty at
    // design time), in the order of application
    property ActiveBreakpoints: TArray<TS4YFlexBreakpoint> read FActiveBreakpoints;

    // True while DoRealign is computing the layout
    property UpdatingLayout: Boolean read GetUpdatingLayout;

    // Set by the design-time package to perform wrapping in the designer
    class property DesignWrapHandler: TS4YFlexDesignWrapHandler
      read FDesignWrapHandler write FDesignWrapHandler;

  published
    property Align;
    property AlignContent: TAlignContent read FAlignContent write SetAlignContent default acFlexStart;
    property AlignItems: TAlignItems read FAlignItems write SetAlignItems default aiStretch;
    property Anchors;
    // How the Width of the breakpoints is read: up to (default) or from. It applies to
    // the whole list; changing it keeps the rules but they read the opposite way.
    property BreakpointMode: TS4YBreakpointMode read FBreakpointMode write SetBreakpointMode default bmMaxWidth;
    // Thresholds on the flexbox width with overrides of its properties and of
    // those of the items. They also apply at design time.
    property Breakpoints: TS4YFlexBreakpoints read FBreakpoints write SetBreakpoints;
    property ClipChildren;
    property ColumnGap: Single read FColumnGap write SetColumnGap;
    property Direction: TFlexDirection read FDirection write SetDirection default fdRow;
    property Height;
    property HitTest;
    property JustifyContent: TJustifyContent read FJustifyContent write SetJustifyContent default jcFlexStart;
    property Margins;
    property Opacity;
    property Padding;
    property Position;
    property RowGap: Single read FRowGap write SetRowGap;
    property Size;
    property Visible;
    property Width;
    property Wrap: TFlexWrap read FWrap write SetWrap default fwNoWrap;
    // Changes the set of active breakpoints (also at the first layout, if there are any)
    property OnBreakpointsChanged: TNotifyEvent read FOnBreakpointsChanged write FOnBreakpointsChanged;
    property OnClick;
    property OnLayoutApplied: TNotifyEvent read FOnLayoutApplied write FOnLayoutApplied;
    property OnLineCountChanged: TS4YFlexLineCountEvent read FOnLineCountChanged write FOnLineCountChanged;
    property OnResize;
  end;

implementation

uses
  Soft4You.FMX.Controls.FlexBox.Strings;

type
  TS4YFlexItemHandle = class(TInterfacedObject, IS4YFlexItemHandle)
  strict private
    FItem: TS4YFlexItem;
    function GetItem: TS4YFlexItem;
  public
    constructor Create(const AItem: TS4YFlexItem);
    procedure Detach;
  end;

// ===========================================================================
// TS4YFlexItemHandle
// ===========================================================================

constructor TS4YFlexItemHandle.Create(const AItem: TS4YFlexItem);
begin
  inherited Create;
  FItem := AItem;
end;

function TS4YFlexItemHandle.GetItem: TS4YFlexItem;
begin
  Result := FItem;
end;

procedure TS4YFlexItemHandle.Detach;
begin
  FItem := nil;
end;

// ===========================================================================
// TS4YFlexItem
// ===========================================================================

constructor TS4YFlexItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHandle := TS4YFlexItemHandle.Create(Self);
  FSizeConstraints := TS4YFlexSizeConstraints.Create;
  FSizeConstraints.OnChange := SizeConstraintsChanged;
  FFlexGrow := 0;
  FFlexShrink := 1;
  FFlexBasis := 0;
  FFlexBasisUnit := fbuAuto;
  FAlignSelf := asAuto;
  FOrder := 0;
  FUserVisible := True;
  FVisibilityOverride := voNone;
  FDesignWidth := Width;
  FDesignHeight := Height;
  FHeightExplicit := False;
  FWidthExplicit := False;
  FLineIndex := -1;
  FOutcomeLineIndex := -1;
end;

procedure TS4YFlexItem.ApplyLayoutBounds(ALeft, ATop, AWidth, AHeight: Single);
begin
  FApplyingLayout := True;
  try
    FLayoutWidth := AWidth;
    FLayoutHeight := AHeight;
    FHasLayoutSize := True;
    SetBounds(ALeft, ATop, AWidth, AHeight);
  finally
    FApplyingLayout := False;
  end;

  PlaceContent;
end;

procedure TS4YFlexItem.ApplyVisibilityOverride(AVisibility: TS4YVisibilityOverride);
var
  LTarget: Boolean;
begin
  FVisibilityOverride := AVisibility;

  case AVisibility of
    voShow: LTarget := True;
    voHide: LTarget := False;
  else
    LTarget := FUserVisible;
  end;

  if Visible <> LTarget then
  begin
    FApplyingVisibility := True;
    try
      Visible := LTarget;
    finally
      FApplyingVisibility := False;
    end;
  end;
end;

procedure TS4YFlexItem.SetVisible(const Value: Boolean);
begin
  if FApplyingVisibility then
  begin
    inherited SetVisible(Value);
  end
  else
  begin
    // With an active override, that value applies for as long as the breakpoint lasts
    FUserVisible := Value;

    if FVisibilityOverride = voNone then
    begin
      inherited SetVisible(Value);
    end;
  end;
end;

function TS4YFlexItem.VisibleStored: Boolean;
begin
  // The user's choice is saved, not the outcome of a breakpoint
  Result := not FUserVisible;
end;

function TS4YFlexItem.DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean;
  ANewWidth, ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean;
var
  LBecameExplicit: Boolean;
  LWidthBecameExplicit: Boolean;
begin
  LBecameExplicit := False;
  LWidthBecameExplicit := False;

  // A size not set by the layout is a choice of the user (or of the
  // designer): it becomes the natural size used by the engine.
  // A size equal to that of the last layout is an echo (for example
  // the designer reapplying the values): it is not a choice of the user.
  if not FApplyingLayout and (ComponentState * [csLoading, csReading] = []) then
  begin
    if not (FHasLayoutSize and (Abs(ANewWidth - FLayoutWidth) < 0.001) and
      (Abs(ANewHeight - FLayoutHeight) < 0.001)) then
    begin
      LBecameExplicit := not FHeightExplicit and (Abs(ANewHeight - FDesignHeight) > 0.001);
      LWidthBecameExplicit := not FWidthExplicit and (Abs(ANewWidth - FDesignWidth) > 0.001);
      FDesignWidth := ANewWidth;
      FDesignHeight := ANewHeight;
    end;
  end;

  Result := inherited DoSetSize(ASize, NewPlatformDefault, ANewWidth, ANewHeight,
    ALastWidth, ALastHeight);

  if LWidthBecameExplicit then
  begin
    // Width chosen by the user: it no longer stretches on the cross axis
    FWidthExplicit := True;
  end;

  if LBecameExplicit then
  begin
    // Height chosen by the user: the item no longer follows the content
    FHeightExplicit := True;
  end;
end;

procedure TS4YFlexItem.DoFlexStateChanged(AState, APreviousState: TFlexItemState);
begin
  if Assigned(FOnFlexStateChanged) then
  begin
    FOnFlexStateChanged(Self, AState, APreviousState);
  end;
end;

procedure TS4YFlexItem.DoLayoutChanged;
begin
  if Assigned(FOnLayoutChanged) then
  begin
    FOnLayoutChanged(Self);
  end;
end;

procedure TS4YFlexItem.DoLineChanged(ALineIndex, APreviousLineIndex: Integer);
begin
  if Assigned(FOnLineChanged) then
  begin
    FOnLineChanged(Self, ALineIndex, APreviousLineIndex);
  end;
end;

procedure TS4YFlexItem.StoreLayoutOutcome(AMainSize, ABaseMain: Single; ALineIndex: Integer);
begin
  FOutcomeMainSize := AMainSize;
  FOutcomeBaseMain := ABaseMain;
  FOutcomeLineIndex := ALineIndex;
end;

procedure TS4YFlexItem.NotifyLayoutOutcome;
const
  C_BASIS_TOLERANCE = 0.5;
var
  LCurrentBounds: TRectF;
  LFirstLayout: Boolean;
  LNewState: TFlexItemState;
  LPreviousLineIndex: Integer;
  LPreviousState: TFlexItemState;
begin
  if (ComponentState * [csDesigning, csLoading, csDestroying] <> []) or
    (FOutcomeLineIndex < 0) then
  begin
    Exit;
  end;

  if FOutcomeMainSize < FOutcomeBaseMain - C_BASIS_TOLERANCE then
  begin
    LNewState := fisShrunk;
  end
  else if FOutcomeMainSize > FOutcomeBaseMain + C_BASIS_TOLERANCE then
  begin
    LNewState := fisGrown;
  end
  else
  begin
    LNewState := fisAtBasis;
  end;

  LFirstLayout := FLineIndex < 0;
  LPreviousState := FFlexState;
  LPreviousLineIndex := FLineIndex;

  if LFirstLayout then
  begin
    LPreviousState := LNewState;
  end;

  FFlexState := LNewState;
  FLineIndex := FOutcomeLineIndex;

  if LFirstLayout or (LNewState <> LPreviousState) then
  begin
    DoFlexStateChanged(LNewState, LPreviousState);
  end;

  if LFirstLayout or (FLineIndex <> LPreviousLineIndex) then
  begin
    DoLineChanged(FLineIndex, LPreviousLineIndex);
  end;

  LCurrentBounds := TRectF.Create(Position.X, Position.Y, Position.X + Width, Position.Y + Height);

  if LFirstLayout or
    (Abs(LCurrentBounds.Left - FNotifiedBounds.Left) > C_BASIS_TOLERANCE) or
    (Abs(LCurrentBounds.Top - FNotifiedBounds.Top) > C_BASIS_TOLERANCE) or
    (Abs(LCurrentBounds.Right - FNotifiedBounds.Right) > C_BASIS_TOLERANCE) or
    (Abs(LCurrentBounds.Bottom - FNotifiedBounds.Bottom) > C_BASIS_TOLERANCE) then
  begin
    FNotifiedBounds := LCurrentBounds;
    DoLayoutChanged;
  end;
end;

procedure TS4YFlexItem.DoRealign;
begin
  inherited;

  // The content (Align = Top) changed height: the item follows it (only with
  // automatic height)
  UpdateContentHeight;
  PlaceContent;
end;

procedure TS4YFlexItem.SetFitContent(Value: Boolean);
var
  LContent: TControl;
begin
  if FFitContent = Value then
  begin
    Exit;
  end;

  FFitContent := Value;

  // During loading Align and sizes come from the file (see Loaded)
  if IsLoadingOrDestroying then
  begin
    Exit;
  end;

  LContent := GetContent;

  if Value then
  begin
    if LContent <> nil then
    begin
      ApplyFitContent(LContent);
    end;
  end
  else
  begin
    UnhookContent;

    if LContent <> nil then
    begin
      LContent.Align := TAlignLayout.Top;
    end;

    UpdateContentHeight;
  end;

  InvalidateFlexBox;
end;

procedure TS4YFlexItem.ApplyFitContent(const AContent: TControl);
begin
  if AContent.Align <> TAlignLayout.None then
  begin
    AContent.Align := TAlignLayout.None;
  end;

  HookContent(AContent);
  PlaceContent;
end;

procedure TS4YFlexItem.HookContent(const AContent: TControl);
begin
  if FHookedContent = AContent then
  begin
    Exit;
  end;

  UnhookContent;
  FHookedContent := AContent;
  FPreviousContentResized := AContent.OnResized;
  AContent.OnResized := ContentResized;
end;

procedure TS4YFlexItem.UnhookContent;
var
  LHandler: TMethod;
begin
  if FHookedContent <> nil then
  begin
    // If the user assigned another handler after ours, theirs stays
    LHandler := TMethod(FHookedContent.OnResized);

    if (LHandler.Data = Pointer(Self)) and (LHandler.Code = @TS4YFlexItem.ContentResized) then
    begin
      FHookedContent.OnResized := FPreviousContentResized;
    end;

    FHookedContent := nil;
    FPreviousContentResized := nil;
  end;
end;

procedure TS4YFlexItem.ContentResized(Sender: TObject);
begin
  if Assigned(FPreviousContentResized) then
  begin
    FPreviousContentResized(Sender);
  end;

  // The own size of the content changed (for example the text of
  // a label with AutoSize): the item rereads it at every layout
  if FFitContent and not IsLoadingOrDestroying then
  begin
    InvalidateFlexBox;
  end;
end;

procedure TS4YFlexItem.PlaceContent;
var
  LContent: TControl;
  LLeft: Single;
  LTop: Single;
begin
  LContent := GetContent;

  if FFitContent and (LContent <> nil) and not IsLoadingOrDestroying then
  begin
    LLeft := Padding.Left + LContent.Margins.Left;
    LTop := Padding.Top + LContent.Margins.Top;

    if (Abs(LContent.Position.X - LLeft) > 0.001) or (Abs(LContent.Position.Y - LTop) > 0.001) then
    begin
      LContent.SetBounds(LLeft, LTop, LContent.Width, LContent.Height);
    end;
  end;
end;

function TS4YFlexItem.GetAutoHeight: Boolean;
begin
  Result := not FHeightExplicit;
end;

function TS4YFlexItem.GetAutoWidth: Boolean;
begin
  Result := not FWidthExplicit;
end;

function TS4YFlexItem.IsAutoWidthStored: Boolean;
begin
  Result := FWidthExplicit;
end;

procedure TS4YFlexItem.SetAutoWidth(Value: Boolean);
begin
  if Value = FWidthExplicit then
  begin
    FWidthExplicit := not Value;

    // During loading the rest comes from the file
    if not (csLoading in ComponentState) then
    begin
      if FWidthExplicit then
      begin
        FDesignWidth := Width;
      end;

      InvalidateFlexBox;
    end;
  end;
end;

function TS4YFlexItem.IsAutoHeightStored: Boolean;
begin
  Result := FHeightExplicit;
end;

procedure TS4YFlexItem.SetAutoHeight(Value: Boolean);
begin
  if Value = (not FHeightExplicit) then
  begin
    Exit;
  end;

  if csLoading in ComponentState then
  begin
    // The Align of the content comes from the file
    FHeightExplicit := not Value;
    Exit;
  end;

  if Value then
  begin
    UseContentHeight;
  end
  else
  begin
    FHeightExplicit := True;
    FDesignHeight := Height;
    InvalidateFlexBox;
  end;
end;

function TS4YFlexItem.GetContent: TControl;
var
  LIndex: Integer;
begin
  Result := nil;
  LIndex := 0;

  while (Result = nil) and (LIndex < ControlsCount) do
  begin
    if IsContentControl(Controls[LIndex]) then
    begin
      Result := Controls[LIndex];
    end;

    Inc(LIndex);
  end;
end;

procedure TS4YFlexItem.UpdateContentHeight;
var
  LContent: TControl;
  LHeight: Single;
begin
  LContent := GetContent;

  // With FitContent the own height of the content is read in ToEngineInput
  if FHeightExplicit or FFitContent or (LContent = nil) or IsLoadingOrDestroying then
  begin
    Exit;
  end;

  LHeight := LContent.Height + LContent.Margins.Top + LContent.Margins.Bottom +
    Padding.Top + Padding.Bottom;

  if Abs(LHeight - FDesignHeight) > 0.001 then
  begin
    FDesignHeight := LHeight;
    InvalidateFlexBox;
  end;
end;

procedure TS4YFlexItem.UseContentHeight;
var
  LContent: TControl;
begin
  FHeightExplicit := False;
  LContent := GetContent;

  if LContent <> nil then
  begin
    if FFitContent then
    begin
      ApplyFitContent(LContent);
    end
    else
    begin
      LContent.Align := TAlignLayout.Top;
    end;
  end;

  UpdateContentHeight;
end;

destructor TS4YFlexItem.Destroy;
begin
  UnhookContent;
  FHandle.Detach;
  FSizeConstraints.Free;
  inherited;
end;

function TS4YFlexItem.GetFlexBox: TS4YFlexBox;
begin
  if Parent is TS4YFlexBox then
  begin
    Result := TS4YFlexBox(Parent);
  end
  else
  begin
    Result := nil;
  end;
end;

function TS4YFlexItem.IsContentControl(const AControl: TControl): Boolean;
begin
  // At design time the designer service controls do not belong to the
  // form: they are not item content and must not be moved.
  Result := not (csDesigning in ComponentState) or (AControl.Owner = Owner);
end;

function TS4YFlexItem.IsFlexShrinkStored: Boolean;
begin
  Result := FFlexShrink <> 1;
end;

function TS4YFlexItem.IsLoadingOrDestroying: Boolean;
begin
  Result := ComponentState * [csLoading, csReading, csDestroying] <> [];
end;

procedure TS4YFlexItem.InvalidateFlexBox;
var
  LFlexBox: TS4YFlexBox;
begin
  LFlexBox := FlexBox;

  if LFlexBox <> nil then
  begin
    LFlexBox.InvalidateLayout;
  end;
end;

procedure TS4YFlexItem.SetAlignSelf(Value: TAlignSelf);
begin
  if FAlignSelf <> Value then
  begin
    FAlignSelf := Value;
    InvalidateFlexBox;
  end;
end;

procedure TS4YFlexItem.SetFlexBasis(Value: Single);
begin
  if FFlexBasis <> Value then
  begin
    FFlexBasis := Max(0, Value);
    InvalidateFlexBox;
  end;
end;

procedure TS4YFlexItem.SetFlexBasisUnit(Value: TFlexBasisUnit);
begin
  if FFlexBasisUnit <> Value then
  begin
    FFlexBasisUnit := Value;
    InvalidateFlexBox;
  end;
end;

procedure TS4YFlexItem.SetFlexGrow(Value: Single);
begin
  if FFlexGrow <> Value then
  begin
    FFlexGrow := Max(0, Value);
    InvalidateFlexBox;
  end;
end;

procedure TS4YFlexItem.SetFlexShrink(Value: Single);
begin
  if FFlexShrink <> Value then
  begin
    FFlexShrink := Max(0, Value);
    InvalidateFlexBox;
  end;
end;

procedure TS4YFlexItem.Loaded;
var
  LContent: TControl;
begin
  inherited;

  // Without DesignWidth/DesignHeight in the file, the saved size is the design one
  if not FDesignWidthLoaded then
  begin
    FDesignWidth := Width;
  end;

  if not FDesignHeightLoaded then
  begin
    FDesignHeight := Height;
  end;

  // Files saved with Client content: the content becomes Top (with explicit height
  // it keeps the height it had)
  LContent := GetContent;

  if FFitContent then
  begin
    if LContent <> nil then
    begin
      ApplyFitContent(LContent);
    end;
  end
  else if (LContent <> nil) and (LContent.Align = TAlignLayout.Client) then
  begin
    LContent.Align := TAlignLayout.Top;
  end;

  if not FHeightExplicit then
  begin
    UpdateContentHeight;
  end;
end;

procedure TS4YFlexItem.DefineProperties(Filer: TFiler);
begin
  inherited;

  // Size holds the size computed by the layout (for example stretched):
  // the size chosen by the user is saved separately, only if different.
  Filer.DefineProperty('DesignHeight', ReadDesignHeight, WriteDesignHeight,
    FDesignHeight <> Height);
  Filer.DefineProperty('DesignWidth', ReadDesignWidth, WriteDesignWidth,
    FDesignWidth <> Width);
  // Format prior to AutoHeight: read only
  Filer.DefineProperty('HeightExplicit', ReadHeightExplicit, nil, False);
end;

procedure TS4YFlexItem.ReadHeightExplicit(Reader: TReader);
begin
  FHeightExplicit := Reader.ReadBoolean;
end;

procedure TS4YFlexItem.ReadDesignHeight(Reader: TReader);
begin
  FDesignHeight := Reader.ReadFloat;
  FDesignHeightLoaded := True;
end;

procedure TS4YFlexItem.ReadDesignWidth(Reader: TReader);
begin
  FDesignWidth := Reader.ReadFloat;
  FDesignWidthLoaded := True;
end;

procedure TS4YFlexItem.WriteDesignHeight(Writer: TWriter);
begin
  Writer.WriteFloat(FDesignHeight);
end;

procedure TS4YFlexItem.WriteDesignWidth(Writer: TWriter);
begin
  Writer.WriteFloat(FDesignWidth);
end;

procedure TS4YFlexItem.SetOrder(Value: Integer);
begin
  if FOrder <> Value then
  begin
    FOrder := Value;
    InvalidateFlexBox;
  end;
end;

procedure TS4YFlexItem.SetSizeConstraints(Value: TS4YFlexSizeConstraints);
begin
  FSizeConstraints.Assign(Value);
end;

procedure TS4YFlexItem.SizeConstraintsChanged(Sender: TObject);
begin
  InvalidateFlexBox;
end;

procedure TS4YFlexItem.DoAddObject(const AObject: TFmxObject);
var
  LFlexBox: TS4YFlexBox;
  LTargetIndex: Integer;
begin
  inherited;

  // An item hosts a single control: a second control goes back to the
  // flexbox, which creates a dedicated item for it.
  if (AObject is TControl) and (ControlsCount > 1) and not IsLoadingOrDestroying and
    IsContentControl(TControl(AObject)) then
  begin
    LFlexBox := FlexBox;

    if LFlexBox <> nil then
    begin
      LTargetIndex := Index;
      TControl(AObject).Parent := LFlexBox;

      // An item dropped onto another item (Structure view) goes before it
      if AObject is TS4YFlexItem then
      begin
        TS4YFlexItem(AObject).Index := LTargetIndex;
      end;
    end;
  end
  else if FFitContent and (AObject is TControl) and (ControlsCount = 1) and
    not IsLoadingOrDestroying and IsContentControl(TControl(AObject)) then
  begin
    ApplyFitContent(TControl(AObject));
  end;
end;

procedure TS4YFlexItem.SetParent(const Value: TFmxObject);
begin
  // Rule: an item lives only inside a TS4YFlexBox. At design time the designer
  // may create it elsewhere in transit (see WrapInItem), and during loading
  // the Parent does not pass through here.
  if (Value <> nil) and not (Value is TS4YFlexBox) and
    not (csDesigning in ComponentState) and not IsLoadingOrDestroying then
  begin
    raise EInvalidOperation.Create(SFlexItemInvalidParent);
  end;

  inherited;
end;

procedure TS4YFlexItem.DoRemoveObject(const AObject: TFmxObject);
begin
  inherited;

  if AObject = FHookedContent then
  begin
    UnhookContent;
  end;

  if AObject is TControl then
  begin
    ReleaseWhenEmpty;
  end;
end;

procedure TS4YFlexItem.ReleaseWhenEmpty;
var
  LHandle: IS4YFlexItemHandle;
begin
  if not IsLoadingOrDestroying then
  begin
    // Deferred: the control may be only in transit to another
    // item, and the removal happens during a Parent change.
    LHandle := FHandle;
    TThread.ForceQueue(nil,
      procedure
      var
        LFlexBox: TS4YFlexBox;
        LItem: TS4YFlexItem;
      begin
        LItem := LHandle.Item;

        if (LItem <> nil) and (LItem.ControlsCount = 0) and
          not LItem.IsLoadingOrDestroying then
        begin
          LFlexBox := LItem.FlexBox;
          LItem.Free;

          // The other items must take the freed place
          if LFlexBox <> nil then
          begin
            LFlexBox.InvalidateLayout;
          end;
        end;
      end);
  end;
end;

function TS4YFlexItem.ToEngineInput: TFlexItemInput;
var
  LContent: TControl;
begin
  Result := TFlexItemInput.Default;
  Result.NaturalWidth := FDesignWidth;
  Result.NaturalHeight := FDesignHeight;

  if FFitContent and not IsLoadingOrDestroying then
  begin
    LContent := GetContent;

    if LContent <> nil then
    begin
      // Own size of the content, only for automatic sizes
      if not FWidthExplicit then
      begin
        Result.NaturalWidth := LContent.Width + LContent.Margins.Left + LContent.Margins.Right +
          Padding.Left + Padding.Right;
      end;

      if not FHeightExplicit then
      begin
        Result.NaturalHeight := LContent.Height + LContent.Margins.Top + LContent.Margins.Bottom +
          Padding.Top + Padding.Bottom;
      end;
    end;
  end;

  Result.WidthAuto := not FWidthExplicit;
  Result.HeightAuto := not FHeightExplicit;
  Result.MarginLeft := Margins.Left;
  Result.MarginTop := Margins.Top;
  Result.MarginRight := Margins.Right;
  Result.MarginBottom := Margins.Bottom;
  Result.FlexGrow := FFlexGrow;
  Result.FlexShrink := FFlexShrink;
  Result.FlexBasis := FFlexBasis;
  Result.FlexBasisUnit := FFlexBasisUnit;
  Result.AlignSelf := FAlignSelf;
  Result.Order := FOrder;
  Result.MinWidth := FSizeConstraints.MinWidth;
  Result.MaxWidth := FSizeConstraints.MaxWidth;
  Result.MinHeight := FSizeConstraints.MinHeight;
  Result.MaxHeight := FSizeConstraints.MaxHeight;
end;

// ===========================================================================
// TS4YFlexBox
// ===========================================================================

constructor TS4YFlexBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLayoutDepth := 0;
  FLineCount := -1;
  FDirection := fdRow;
  FWrap := fwNoWrap;
  FJustifyContent := jcFlexStart;
  FAlignItems := aiStretch;
  FAlignContent := acFlexStart;
  FColumnGap := 0;
  FRowGap := 0;
  FBreakpointMode := bmMaxWidth;
  FBreakpoints := TS4YFlexBreakpoints.Create(Self);
  FBreakpoints.OnChanged := BreakpointsChanged;
end;

destructor TS4YFlexBox.Destroy;
begin
  // Emptying the collection during destruction must no longer notify the flexbox
  FBreakpoints.OnChanged := nil;
  FreeAndNil(FBreakpoints);
  inherited;
end;

procedure TS4YFlexBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  // A deleted item takes its breakpoint overrides with it
  if (Operation = opRemove) and (FBreakpoints <> nil) and
    (AComponent is TS4YFlexItemBase) and not (csDestroying in ComponentState) then
  begin
    FBreakpoints.RemoveItem(AComponent);
  end;
end;

procedure TS4YFlexBox.BreakpointsChanged(Sender: TObject);
begin
  FActiveBreakpoints := nil;
  InvalidateLayout;
end;

function TS4YFlexBox.ResolveSettings: TS4YFlexSettings;
begin
  Result.Direction := FDirection;
  Result.Wrap := FWrap;
  Result.JustifyContent := FJustifyContent;
  Result.AlignItems := FAlignItems;
  Result.AlignContent := FAlignContent;
  Result.ColumnGap := FColumnGap;
  Result.RowGap := FRowGap;

  Result := FBreakpoints.Resolve(Width, FBreakpointMode, Result, FActiveBreakpoints);
end;

function TS4YFlexBox.IsLoadingOrDestroying: Boolean;
begin
  Result := ComponentState * [csLoading, csReading, csDestroying] <> [];
end;

function TS4YFlexBox.IsContentControl(const AControl: TControl): Boolean;
begin
  // At design time the designer service controls do not belong to the
  // form: they must not be wrapped in an item.
  Result := not (csDesigning in ComponentState) or (AControl.Owner = Owner);
end;

procedure TS4YFlexBox.DoAddObject(const AObject: TFmxObject);
var
  LControl: TControl;
begin
  inherited;

  if (AObject is TControl) and not (AObject is TS4YFlexItem) and
    not IsLoadingOrDestroying and
    (TControl(AObject).ComponentState * [csLoading, csReading, csDestroying] = []) and
    IsContentControl(TControl(AObject)) then
  begin
    LControl := TControl(AObject);

    if csDesigning in ComponentState then
    begin
      if Assigned(FDesignWrapHandler) then
      begin
        FDesignWrapHandler(Self, LControl);
      end;
    end
    else
    begin
      WrapControl(LControl);
    end;
  end;
end;

function TS4YFlexBox.WrapControl(const AControl: TControl): TS4YFlexItem;
begin
  Result := TS4YFlexItem.Create(Self);
  Result.Parent := Self;
  WrapInItem(AControl, Result);
end;

procedure TS4YFlexBox.WrapInItem(const AControl: TControl; const AItem: TS4YFlexItem);
var
  LBounds: TRectF;
  LMargins: TRectF;
begin
  LBounds := TRectF.Create(AControl.Position.X, AControl.Position.Y,
    AControl.Position.X + AControl.Width, AControl.Position.Y + AControl.Height);
  LMargins := AControl.Margins.Rect;

  // The designer may have created the item elsewhere (for example inside the
  // control just dropped): it brings it back into the flexbox, preventing
  // the item from being a descendant of the control to insert (circular dependency).
  if AItem.Parent <> Self then
  begin
    AItem.Parent := Self;
  end;

  // If SetParent fails, the control and margins stay unchanged
  AControl.Parent := AItem;
  AItem.SetBounds(LBounds.Left, LBounds.Top, LBounds.Width, LBounds.Height);
  AItem.Margins.Rect := LMargins;
  AControl.Margins.Rect := TRectF.Empty;

  // Item height = content height (auto), item width = content width
  // (SetBounds made the width explicit: it goes back to automatic)
  AItem.AutoWidth := True;
  AItem.UseContentHeight;
end;

procedure TS4YFlexBox.SetAlignContent(Value: TAlignContent);
begin
  if FAlignContent <> Value then
  begin
    FAlignContent := Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.SetAlignItems(Value: TAlignItems);
begin
  if FAlignItems <> Value then
  begin
    FAlignItems := Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.SetBreakpointMode(Value: TS4YBreakpointMode);
begin
  if FBreakpointMode <> Value then
  begin
    FBreakpointMode := Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.SetBreakpoints(Value: TS4YFlexBreakpoints);
begin
  FBreakpoints.Assign(Value);
end;

procedure TS4YFlexBox.SetColumnGap(Value: Single);
begin
  if FColumnGap <> Value then
  begin
    FColumnGap := Max(0, Value);
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.SetDirection(Value: TFlexDirection);
begin
  if FDirection <> Value then
  begin
    FDirection := Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.SetJustifyContent(Value: TJustifyContent);
begin
  if FJustifyContent <> Value then
  begin
    FJustifyContent := Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.SetRowGap(Value: Single);
begin
  if FRowGap <> Value then
  begin
    FRowGap := Max(0, Value);
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.SetWrap(Value: TFlexWrap);
begin
  if FWrap <> Value then
  begin
    FWrap := Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.InvalidateLayout;
begin
  // Do not schedule during a layout already in progress (avoids loops)
  if not UpdatingLayout then
  begin
    Realign;
  end;
end;

procedure TS4YFlexBox.BeginLayout;
begin
  Inc(FLayoutDepth);
end;

procedure TS4YFlexBox.EndLayout;
begin
  Dec(FLayoutDepth);
end;

function TS4YFlexBox.GetUpdatingLayout: Boolean;
begin
  Result := FLayoutDepth > 0;
end;

procedure TS4YFlexBox.DoRealign;
var
  LContext: TFlexContext;
  LResults: TArray<TFlexItemResult>;
  LFlexChildren: TArray<TControl>;
  LLineCount: Integer;
  LApplied: Boolean;
  LSettings: TS4YFlexSettings;
begin
  // Reentrancy guard; no layout during loading or destruction
  if not UpdatingLayout and not IsLoadingOrDestroying then
  begin
    LApplied := False;
    LLineCount := 0;
    BeginLayout;
    try
      LSettings := ResolveSettings;
      LContext := BuildContext(LSettings, LFlexChildren);

      if Length(LContext.Items) > 0 then
      begin
        LResults := TFlexEngine.Calculate(LContext);
        LLineCount := ApplyResults(LResults, LFlexChildren, LSettings.Direction);
        LApplied := True;
      end;
    finally
      EndLayout;
    end;

    // Events fire after the layout is done: a handler that changes the
    // content starts a new layout instead of reentering this one
    if LApplied then
    begin
      NotifyLayoutApplied(LFlexChildren, LLineCount);
    end;
  end;
end;

procedure TS4YFlexBox.NotifyLayoutApplied(const AFlexChildren: TArray<TControl>;
  ALineCount: Integer);
var
  LChild: TControl;
  LPreviousLineCount: Integer;
begin
  if ComponentState * [csDesigning, csLoading, csDestroying] <> [] then
  begin
    Exit;
  end;

  for LChild in AFlexChildren do
  begin
    if not (csDestroying in LChild.ComponentState) then
    begin
      TS4YFlexItem(LChild).NotifyLayoutOutcome;
    end;
  end;

  NotifyBreakpointsChanged;

  LPreviousLineCount := FLineCount;
  FLineCount := ALineCount;

  if ALineCount <> LPreviousLineCount then
  begin
    DoLineCountChanged(ALineCount, LPreviousLineCount);
  end;

  DoLayoutApplied;
end;

procedure TS4YFlexBox.NotifyBreakpointsChanged;
var
  LIndex: Integer;
  LChanged: Boolean;
  LCurrentIndexes: TArray<Integer>;
begin
  SetLength(LCurrentIndexes, Length(FActiveBreakpoints));

  for LIndex := 0 to High(FActiveBreakpoints) do
  begin
    LCurrentIndexes[LIndex] := FActiveBreakpoints[LIndex].Index;
  end;

  LChanged := Length(LCurrentIndexes) <> Length(FNotifiedBreakpointIndexes);

  for LIndex := 0 to High(LCurrentIndexes) do
  begin
    if not LChanged and (LCurrentIndexes[LIndex] <> FNotifiedBreakpointIndexes[LIndex]) then
    begin
      LChanged := True;
    end;
  end;

  if LChanged then
  begin
    FNotifiedBreakpointIndexes := LCurrentIndexes;
    DoBreakpointsChanged;
  end;
end;

procedure TS4YFlexBox.DoBreakpointsChanged;
begin
  if Assigned(FOnBreakpointsChanged) then
  begin
    FOnBreakpointsChanged(Self);
  end;
end;

procedure TS4YFlexBox.DoLayoutApplied;
begin
  if Assigned(FOnLayoutApplied) then
  begin
    FOnLayoutApplied(Self);
  end;
end;

procedure TS4YFlexBox.DoLineCountChanged(ALineCount, APreviousLineCount: Integer);
begin
  if Assigned(FOnLineCountChanged) then
  begin
    FOnLineCountChanged(Self, ALineCount, APreviousLineCount);
  end;
end;

class function TS4YFlexBox.IsFlexChild(AChild: TControl): Boolean;
begin
  Result := (AChild is TS4YFlexItem) and
    AChild.Visible and
    (AChild.ComponentState * [csLoading, csReading, csDestroying] = []);
end;

function TS4YFlexBox.BuildContext(const ASettings: TS4YFlexSettings;
  out AFlexChildren: TArray<TControl>): TFlexContext;
var
  LIndex: Integer;
  LCount: Integer;
  LChild: TControl;
  LBreakpoint: TS4YFlexBreakpoint;
  LInput: TFlexItemInput;
  LItems: TArray<TFlexItemInput>;
  LVisibility: TS4YVisibilityOverride;
begin
  Result := TFlexContext.Default;

  // Available size = container size minus the padding
  Result.AvailableWidth := Width - Padding.Left - Padding.Right;
  Result.AvailableHeight := Height - Padding.Top - Padding.Bottom;

  Result.Direction := ASettings.Direction;
  Result.Wrap := ASettings.Wrap;
  Result.JustifyContent := ASettings.JustifyContent;
  Result.AlignItems := ASettings.AlignItems;
  Result.AlignContent := ASettings.AlignContent;
  Result.ColumnGap := ASettings.ColumnGap;
  Result.RowGap := ASettings.RowGap;
  Result.SingleLineFillsContainer := True;

  // Snapshot of the children: compact array, only the items that participate.
  LCount := 0;
  SetLength(LItems, ControlsCount);
  SetLength(AFlexChildren, ControlsCount);

  for LIndex := 0 to ControlsCount - 1 do
  begin
    LChild := Controls[LIndex];

    if (LChild is TS4YFlexItem) and
      (LChild.ComponentState * [csLoading, csReading, csDestroying] = []) then
    begin
      // Base values + overrides of the active breakpoints (in cascade order);
      // visibility must be applied before deciding whether the item participates
      LInput := TS4YFlexItem(LChild).ToEngineInput;
      LVisibility := voNone;

      for LBreakpoint in FActiveBreakpoints do
      begin
        LBreakpoint.ApplyToItem(LChild, LInput, LVisibility);
      end;

      TS4YFlexItem(LChild).ApplyVisibilityOverride(LVisibility);
    end;

    if IsFlexChild(LChild) then
    begin
      // OriginalIndex = index in AFlexChildren (compact array), not in Controls[]
      LInput.OriginalIndex := LCount;
      LItems[LCount] := LInput;
      AFlexChildren[LCount] := LChild;
      Inc(LCount);
    end;
  end;

  SetLength(LItems, LCount);
  SetLength(AFlexChildren, LCount);
  Result.Items := LItems;
end;

function TS4YFlexBox.ApplyResults(const AResults: TArray<TFlexItemResult>;
  const AFlexChildren: TArray<TControl>; ADirection: TFlexDirection): Integer;
var
  LIndex: Integer;
  LChild: TControl;
  LMainSize: Single;
  LResult: TFlexItemResult;
  LPaddingLeft: Single;
  LPaddingTop: Single;
begin
  Result := 0;
  LPaddingLeft := Padding.Left;
  LPaddingTop := Padding.Top;

  for LIndex := 0 to High(AResults) do
  begin
    LResult := AResults[LIndex];

    if (LResult.OriginalIndex >= 0) and (LResult.OriginalIndex <= High(AFlexChildren)) then
    begin
      LChild := AFlexChildren[LResult.OriginalIndex];

      // Defensive check: the item may have disappeared in the meantime
      if (LChild <> nil) and LChild.Visible and
        not (csDestroying in LChild.ComponentState) then
      begin
        TS4YFlexItem(LChild).ApplyLayoutBounds(
          LPaddingLeft + LResult.Left,
          LPaddingTop + LResult.Top,
          LResult.Width,
          LResult.Height);

        if ADirection in [fdRow, fdRowReverse] then
        begin
          LMainSize := LResult.Width;
        end
        else
        begin
          LMainSize := LResult.Height;
        end;

        TS4YFlexItem(LChild).StoreLayoutOutcome(LMainSize, LResult.BaseMain,
          LResult.LineIndex);
        Result := Max(Result, LResult.LineIndex + 1);
      end;
    end;
  end;
end;

end.
