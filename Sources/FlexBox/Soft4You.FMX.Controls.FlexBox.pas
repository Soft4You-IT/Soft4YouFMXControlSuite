unit Soft4You.FMX.Controls.FlexBox;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YFlexBox - CSS FlexBox layout container
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

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

  AUTOMATIC MINIMUM
  -----------------
  As min-width: auto in CSS, an item whose content has Align = None (its own
  size) does not shrink below it on the main axis (ToEngineInput fills
  AutoMinWidth/AutoMinHeight; the
  engine uses them only while MinWidth/MinHeight is 0). The flexbox with AutoWidth
  therefore grows beyond its parent, and a scroll box shows the scroll bar, with the
  default FlexShrink.

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

  AUTOMATIC SIZE
  --------------
  As width: auto and height: auto in CSS, the size of the flexbox is automatic
  (AutoWidth, AutoHeight) until the user chooses it: a Width or Height set after
  the first layout makes that size explicit (see DoSetSize). AutoWidth needs
  Align = None: the width is that of the parent (or the smallest width that does
  not crop the items, if greater). AutoHeight works with Align = None, Top and
  Bottom: the height is that of the content at the width of the flexbox.
  The position is never changed: with AutoWidth the width is the space from
  Position.X to the right edge of the area of the parent (Padding.Right of the
  parent and Margins.Right of the flexbox taken away), like position: absolute
  with left set and right: 0. Moving the flexbox repeats the layout
  (DoMatrixChanged for Position, Move for SetBounds).
  With Align = None the parent is not asked to align the flexbox: it reacts to
  the bounds of its child, so a scroll box shows its scroll bars. The parent does
  not notify a child that is not aligned, so with AutoWidth the flexbox hooks the
  OnResized of the parent (OnResize of a form), chaining the handler that was
  already there.
  In the block flow (a parent that implements IS4YBlockFlowContainer, the
  content of TS4YBlockScrollBox) the flexbox implements IS4YBlockFlowChild: with
  AutoWidth or Align = Top it is width: auto, the flow gives it position and
  width (SetFlowBounds) and it does not grow beyond them; the items that do not
  fit overflow and the box shows the horizontal bar (GetFlowOverflowWidth).
  The items are placed after the size of the flexbox is applied: when their
  right edge differs from the one the flow read, the flexbox asks the flow to
  arrange its children again.
  There it does not hook the parent and does not follow its position.
  The breakpoints read the width that the parent gives, not the grown one.
  MinWidth is a floor for the width of the flexbox, for a layout that must not be
  narrower than that (for example with Wrap, where the smallest width without
  cropping is only that of the widest item).
  A scroll bar that appears or disappears changes the width of the parent: the
  layout is repeated, up to C_MAX_FIT_PASSES times.

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
  Soft4You.FMX.Controls.BlockScrollBox.Abstracts,
  Soft4You.FMX.Controls.FlexBox.Breakpoints,
  Soft4You.FMX.Controls.FlexBox.Engine,
  Soft4You.FMX.Controls.FlexBox.ItemBase,
  Soft4You.FMX.Controls.FlexBox.SizeConstraints,
  Soft4You.FMX.Controls.FlexBox.Types;

type
  TS4YFlexBox = class;
  TS4YFlexItem = class;

  /// <summary>
  /// Procedure that wraps in a flex item a control dropped on a flexbox at design time. The design-time package sets it.
  /// </summary>
  /// <param name="AFlexBox">The flexbox that received the control.</param>
  /// <param name="AControl">The control to wrap.</param>
  TS4YFlexDesignWrapHandler = reference to procedure(const AFlexBox: TS4YFlexBox;
    const AControl: TControl);

  /// <summary>
  /// The state of an item with respect to its flex-basis changed: it became shrunk, at the basis or grown.
  /// </summary>
  /// <param name="Sender">The item.</param>
  /// <param name="AState">The new state.</param>
  /// <param name="APreviousState">The previous state. At the first layout it equals AState.</param>
  TS4YFlexItemStateEvent = procedure(Sender: TObject; AState,
    APreviousState: TFlexItemState) of object;

  /// <summary>
  /// The line that holds an item changed.
  /// </summary>
  /// <param name="Sender">The item.</param>
  /// <param name="ALineIndex">The new line, counted from 0.</param>
  /// <param name="APreviousLineIndex">The previous line. At the first layout it is -1.</param>
  TS4YFlexItemLineEvent = procedure(Sender: TObject; ALineIndex,
    APreviousLineIndex: Integer) of object;

  /// <summary>
  /// The number of lines of a flexbox changed.
  /// </summary>
  /// <param name="Sender">The flexbox.</param>
  /// <param name="ALineCount">The new number of lines.</param>
  /// <param name="APreviousLineCount">The previous number of lines. At the first layout it is -1.</param>
  TS4YFlexLineCountEvent = procedure(Sender: TObject; ALineCount,
    APreviousLineCount: Integer) of object;

  /// <summary>
  /// Weak reference to an item, used by deferred drop requests.
  /// </summary>
  IS4YFlexItemHandle = interface
    ['{7B1E3C52-5A0F-4D6B-9E34-2F1C8A6D0B71}']
    /// <summary>Returns the item, or nil if it no longer exists.</summary>
    function GetItem: TS4YFlexItem;
    /// <summary>Breaks the reference: Item becomes nil.</summary>
    procedure Detach;
    /// <summary>The item, or nil if it no longer exists.</summary>
    property Item: TS4YFlexItem read GetItem;
  end;

  /// <summary>
  /// An element of a TS4YFlexBox. It hosts one control and exposes the CSS properties of a flexbox item (flex-grow, flex-shrink, flex-basis, align-self, order).
  /// </summary>
  /// <remarks>
  /// Every control that takes part in the layout lives inside an item. The flexbox creates the item by itself when a control is dropped on it; for several controls, use a container (a layout, a panel) as the content of the item.
  /// An item lives only inside a TS4YFlexBox: at run time any other parent raises EInvalidOperation. An item left without controls is deleted.
  /// Width and Height are automatic (AutoWidth and AutoHeight are True) until the user sets them. An automatic size on the cross axis stretches according to AlignItems and AlignSelf; an explicit size does not stretch.
  /// The Align of the content decides where the automatic size comes from. With Align = None the content keeps its own size, at the top left of the item, and the item takes it (like width: auto in CSS), without shrinking below it. With Align = Top the content follows the width of the item, and the item takes its height.
  /// The properties of the item can be changed by the active breakpoints of the flexbox without altering the values set here, including Visible.
  /// </remarks>
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
    FContentSelfSized: Boolean;
    FHookedContent: TControl;
    FPreviousContentResized: TNotifyEvent;

    procedure ContentResized(Sender: TObject);
    procedure HookContent(const AContent: TControl);
    procedure PlaceContent;
    procedure UnhookContent;
    procedure UpdateContentSizing;
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
    /// <summary>Saves the size chosen by the user (DesignWidth and DesignHeight) apart from the size computed by the layout.</summary>
    procedure DefineProperties(Filer: TFiler); override;
    /// <summary>Keeps one control in the item: a second control goes back to the flexbox, which creates an item for it.</summary>
    procedure DoAddObject(const AObject: TFmxObject); override;
    /// <summary>Called when the state of the item with respect to its flex-basis changes. It fires OnFlexStateChanged.</summary>
    procedure DoFlexStateChanged(AState, APreviousState: TFlexItemState); virtual;
    /// <summary>Sets the visibility chosen by the user. While a breakpoint overrides the visibility, the override applies until the breakpoint ends.</summary>
    procedure SetVisible(const Value: Boolean); override;
    /// <summary>Tells whether Visible is saved: the value saved is the one chosen by the user, not the one of an active breakpoint.</summary>
    function VisibleStored: Boolean; override;
    /// <summary>Called when the position or the size of the item changed since the last notified layout. It fires OnLayoutChanged.</summary>
    procedure DoLayoutChanged; virtual;
    /// <summary>Called when the line that holds the item changes. It fires OnLineChanged.</summary>
    procedure DoLineChanged(ALineIndex, APreviousLineIndex: Integer); virtual;
    /// <summary>Realigns the content and, if the height is automatic, makes the item follow the height of the content.</summary>
    procedure DoRealign; override;
    /// <summary>Deletes the item when its last control is removed.</summary>
    procedure DoRemoveObject(const AObject: TFmxObject); override;
    /// <summary>Completes the loading of the item.</summary>
    procedure Loaded; override;
    /// <summary>Sets the size of the item. A size that the layout did not set is a choice of the user and becomes the natural size of the item.</summary>
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean;
      ANewWidth, ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean; override;
    /// <summary>Sets the parent of the item. At run time the parent must be a TS4YFlexBox, otherwise EInvalidOperation is raised.</summary>
    procedure SetParent(const Value: TFmxObject); override;
  public
    /// <summary>Creates the item with the default values.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Destroys the item.</summary>
    destructor Destroy; override;

    /// <summary>Applies the bounds computed by the layout without altering the size chosen by the user.</summary>
    procedure ApplyLayoutBounds(ALeft, ATop, AWidth, AHeight: Single);

    /// <summary>Shows or hides the item according to the active breakpoints, without losing the Visible chosen by the user. The flexbox calls it at every layout.</summary>
    procedure ApplyVisibilityOverride(AVisibility: TS4YVisibilityOverride);

    /// <summary>Fires the events of the item (OnFlexStateChanged, OnLineChanged, OnLayoutChanged) for what changed in the last layout. The flexbox calls it when the layout is done.</summary>
    procedure NotifyLayoutOutcome;
    /// <summary>Stores the outcome of the last layout: the final main size, the main size before the free space was distributed, and the line. The flexbox calls it at every layout.</summary>
    procedure StoreLayoutOutcome(AMainSize, ABaseMain: Single; ALineIndex: Integer);

    /// <summary>Makes the item follow the height of the content, like height: auto in CSS.</summary>
    procedure UseContentHeight;

    /// <summary>Returns the input data of the item for TFlexEngine.</summary>
    function ToEngineInput: TFlexItemInput;

    /// <summary>The flexbox that contains the item.</summary>
    property FlexBox: TS4YFlexBox read GetFlexBox;
  published
    /// <summary>Alignment of the item on the cross axis, in place of the AlignItems of the flexbox (CSS align-self). The default is asAuto: the item uses AlignItems.</summary>
    property AlignSelf: TAlignSelf read FAlignSelf write SetAlignSelf default asAuto;
    /// <summary>True: the height follows the content (like height: auto in CSS). False: explicit height, also set by changing Height or by resizing the item in the designer.</summary>
    property AutoHeight: Boolean read GetAutoHeight write SetAutoHeight stored IsAutoHeightStored;
    /// <summary>True: the width is not an explicit choice (like width: auto in CSS). On the cross axis the item stretches and, in a column, fits the width of the flexbox; the design width stays the starting one. False: explicit width, also set by changing Width or by resizing the item in the designer.</summary>
    property AutoWidth: Boolean read GetAutoWidth write SetAutoWidth stored IsAutoWidthStored;
    /// <summary>Initial main size of the item (CSS flex-basis). FlexBasisUnit says how the value is read.</summary>
    property FlexBasis: Single read FFlexBasis write SetFlexBasis;
    /// <summary>How FlexBasis is read: the size of the item (fbuAuto, the default), pixels or a percentage of the main size of the flexbox.</summary>
    property FlexBasisUnit: TFlexBasisUnit read FFlexBasisUnit write SetFlexBasisUnit default fbuAuto;
    /// <summary>How much of the free space the item takes, compared with the other items (CSS flex-grow). The default is 0: the item does not grow.</summary>
    property FlexGrow: Single read FFlexGrow write SetFlexGrow;
    /// <summary>How much the item shrinks, compared with the other items, when the space is not enough (CSS flex-shrink). The default is 1.</summary>
    [Default(1)]
    property FlexShrink: Single read FFlexShrink write SetFlexShrink stored IsFlexShrinkStored;
    property Height;
    /// <summary>Position of the item in the flexbox (source order). It is not saved, because the order is already that of the objects in the file.</summary>
    property Index stored False;
    property Margins;
    /// <summary>Position of the item in the layout, whatever its source order (CSS order). Items with a lower value come first. The default is 0.</summary>
    property Order: Integer read FOrder write SetOrder default 0;
    property Padding;
    property Size;
    /// <summary>Smallest and largest size of the item, like min-width, max-width, min-height and max-height in CSS (0 means no limit). They apply even to an explicit size, and to the layout of the item, not to its content.</summary>
    property SizeConstraints: TS4YFlexSizeConstraints read FSizeConstraints write SetSizeConstraints;
    property Visible;
    property Width;
    /// <summary>Fires when the item becomes shrunk, at its flex-basis or grown after a layout.</summary>
    property OnFlexStateChanged: TS4YFlexItemStateEvent read FOnFlexStateChanged write FOnFlexStateChanged;
    /// <summary>Fires when the position or the size of the item changed since the last notified layout, also at the first layout.</summary>
    property OnLayoutChanged: TNotifyEvent read FOnLayoutChanged write FOnLayoutChanged;
    /// <summary>Fires when the item moves to another line of the flexbox.</summary>
    property OnLineChanged: TS4YFlexItemLineEvent read FOnLineChanged write FOnLineChanged;
  end;

  /// <summary>
  /// A container that lays out its items with the CSS flexbox model (W3C Level 1).
  /// </summary>
  /// <remarks>
  /// The flexbox exposes the CSS properties of the container: Direction, Wrap, JustifyContent, AlignItems, AlignContent, ColumnGap and RowGap. Each control that takes part in the layout lives in a TS4YFlexItem.
  /// When a control that is not an item becomes a child of the flexbox, the flexbox creates an item with the same position and size and moves the control into it; the margins of the control go to the item. At design time the item is created by the designer, through DesignWrapHandler.
  /// Breakpoints change the properties of the container and of the items according to the width of the flexbox, also at design time, without altering the values set in the Object Inspector.
  /// The flexbox does not scroll, as in CSS. To see content that does not fit, put it in a scroll box with Align = None: the flexbox takes the width of its parent and the height of its content (AutoWidth and AutoHeight), and the scroll box shows its scroll bars.
  /// In a TS4YBlockScrollBox the box gives the position and the width to a flexbox with AutoWidth or Align = Top, like the width: auto of CSS: the items that do not fit overflow and the box shows the horizontal bar.
  /// </remarks>
  TS4YFlexBox = class(TControl, IS4YBlockFlowChild)
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
    FApplyingAutoSize: Boolean;
    FFlowOverflowWidth: Single;
    FFlowWidth: Single;
    FHasFlowWidth: Boolean;
    FHasLayoutSize: Boolean;
    FHeightExplicit: Boolean;
    FHookedParent: TFmxObject;
    FLayoutHeight: Single;
    FLayoutWidth: Single;
    FMinWidth: Single;
    FWidthExplicit: Boolean;
    FPreviousParentResized: TNotifyEvent;
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
    function GetAutoHeight: Boolean;
    function GetAutoWidth: Boolean;
    function IsAutoHeightActive: Boolean;
    function IsAutoHeightStored: Boolean;
    function IsAutoWidthActive(out AAvailableWidth: Single): Boolean;
    function IsAutoWidthStored: Boolean;
    function IsInBlockFlow: Boolean;
    function MeasureOverflowWidth: Single;
    function ResolveSettings(AWidth: Single): TS4YFlexSettings;
    function TryGetParentArea(out AArea: TRectF): Boolean;
    procedure ApplyAutoSize(var AContext: TFlexContext; UseAutoWidth, UseAutoHeight: Boolean;
      AAvailableWidth: Single);
    procedure FollowPosition;
    procedure HookParent;
    procedure ParentResized(Sender: TObject);
    procedure SetAutoHeight(Value: Boolean);
    procedure SetAutoWidth(Value: Boolean);
    procedure SetMinWidth(Value: Single);
    procedure UnhookParent;
    procedure UpdateParentHook;
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
    /// <summary>Wraps in an item a control that is not an item and becomes a child of the flexbox (at design time through DesignWrapHandler).</summary>
    procedure DoAddObject(const AObject: TFmxObject); override;
    /// <summary>Called when the set of active breakpoints changes. It fires OnBreakpointsChanged.</summary>
    procedure DoBreakpointsChanged; virtual;
    /// <summary>Called when a layout has been applied to the items. It fires OnLayoutApplied.</summary>
    procedure DoLayoutApplied; virtual;
    /// <summary>Called when the number of lines changes. It fires OnLineCountChanged.</summary>
    procedure DoLineCountChanged(ALineCount, APreviousLineCount: Integer); virtual;
    /// <summary>With AutoWidth the width depends on the position: when Position changes, the layout is repeated.</summary>
    procedure DoMatrixChanged(Sender: TObject); override;
    /// <summary>Computes the layout and applies it to the items.</summary>
    procedure DoRealign; override;
    /// <summary>Sets the size of the flexbox. A size that the layout did not set, and that the Align leaves to the user, is a choice of the user after the first layout: that size becomes explicit (AutoWidth or AutoHeight becomes False).</summary>
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean;
      ANewWidth, ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean; override;
    /// <summary>True if the width is automatic in the block flow: AutoWidth with Align = None, or Align = Top.</summary>
    function GetFlowAutoWidth: Boolean;
    /// <summary>The right edge of the items after the layout, from the left of the flexbox, Padding.Right and margins included: more than the width when the items overflow. With ClipChildren nothing overflows and it is the width.</summary>
    function GetFlowOverflowWidth: Single;
    /// <summary>Computes the layout again once the control is loaded, which sizes a flexbox with an automatic size.</summary>
    procedure Loaded; override;
    /// <summary>With AutoWidth the width depends on the position: when SetBounds moves the flexbox without resizing it (as the designer does), the layout is repeated.</summary>
    procedure Move; override;
    /// <summary>When an item is deleted, removes the breakpoint overrides that refer to it.</summary>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// <summary>Follows the size of the new parent when AutoWidth is True.</summary>
    procedure ParentChanged; override;
    /// <summary>Takes the position and the width given by the block flow, then computes the layout and the height.</summary>
    procedure SetFlowBounds(ALeft, ATop, AWidth: Single);
  public
    /// <summary>True if the control takes part in the layout: it is a visible item that is not loading or being destroyed.</summary>
    class function IsFlexChild(AChild: TControl): Boolean; static;

    /// <summary>Creates the flexbox with the default settings and no breakpoints.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Destroys the flexbox.</summary>
    destructor Destroy; override;

    /// <summary>Forces the layout to be computed again, for example after changes made by code.</summary>
    procedure InvalidateLayout;

    /// <summary>Returns the size that the flexbox needs to show all its items, Padding included: the smallest width at which no item is cropped, and the height of the content at the current width. It is the size that AutoWidth and AutoHeight give to the flexbox, whatever their value.</summary>
    function MeasureContent: TSizeF;

    /// <summary>Creates an item in the flexbox and moves the control into it. Position, size and margins of the control go to the item.</summary>
    function WrapControl(const AControl: TControl): TS4YFlexItem;

    /// <summary>Moves the control into an item that the caller already created, for example the designer, copying position, size and margins.</summary>
    procedure WrapInItem(const AControl: TControl; const AItem: TS4YFlexItem);

    /// <summary>The breakpoints that matched the width in the last layout, in the order in which they were applied.</summary>
    property ActiveBreakpoints: TArray<TS4YFlexBreakpoint> read FActiveBreakpoints;

    /// <summary>True while the layout is being computed.</summary>
    property UpdatingLayout: Boolean read GetUpdatingLayout;

    /// <summary>Procedure that the design-time package sets to wrap in an item the controls dropped on a flexbox in the designer.</summary>
    class property DesignWrapHandler: TS4YFlexDesignWrapHandler
      read FDesignWrapHandler write FDesignWrapHandler;

  published
    property Align;
    /// <summary>Distribution of the lines on the cross axis when the items wrap onto more lines (CSS align-content). The default is acFlexStart.</summary>
    property AlignContent: TAlignContent read FAlignContent write SetAlignContent default acFlexStart;
    /// <summary>Alignment of the items on the cross axis (CSS align-items). The default is aiStretch.</summary>
    property AlignItems: TAlignItems read FAlignItems write SetAlignItems default aiStretch;
    property Anchors;
    /// <summary>True: the height is that of the content at the width of the flexbox (like height: auto in CSS). It works with Align = None, Top and Bottom. Without items the height stays as it is. It becomes False when the user sets the height, after the first layout. While it is True, the height is decided by the flexbox. The default is True.</summary>
    property AutoHeight: Boolean read GetAutoHeight write SetAutoHeight stored IsAutoHeightStored;
    /// <summary>True: the width is the space from the left of the flexbox (Position.X) to the right edge of the parent, minus the Padding.Right of the parent and the Margins.Right of the flexbox, or the smallest width at which no item is cropped if that is greater. The position is not changed: at X = 0 the flexbox is as wide as the parent (like the width: auto of a block in CSS). A parent that scrolls shows its scroll bars; any other parent crops what does not fit. In a TS4YBlockScrollBox the width is the one that the box gives (or MinWidth, if greater), never more: the items that do not fit overflow and the box shows the horizontal bar. It needs Align = None and a parent. While it is True the width is decided by the flexbox. It becomes False when the user sets the width, after the first layout: assign Width after the Parent. To follow its parent the flexbox hooks the OnResized event of the parent (OnResize of a form): assign your own handler before. The default is True.</summary>
    property AutoWidth: Boolean read GetAutoWidth write SetAutoWidth stored IsAutoWidthStored;
    /// <summary>How the Width of the breakpoints is read: up to the width (bmMaxWidth, the default) or from the width up (bmMinWidth). It applies to the whole list; changing it keeps the breakpoints but they read the opposite way.</summary>
    property BreakpointMode: TS4YBreakpointMode read FBreakpointMode write SetBreakpointMode default bmMaxWidth;
    /// <summary>Width thresholds that change the properties of the flexbox and of its items. They also apply at design time.</summary>
    property Breakpoints: TS4YFlexBreakpoints read FBreakpoints write SetBreakpoints;
    property ClipChildren;
    /// <summary>Space between the items of a line, in pixels (CSS column-gap).</summary>
    property ColumnGap: Single read FColumnGap write SetColumnGap;
    /// <summary>Direction of the main axis (CSS flex-direction). The default is fdRow.</summary>
    property Direction: TFlexDirection read FDirection write SetDirection default fdRow;
    property Height;
    property HitTest;
    /// <summary>Distribution of the items along the main axis (CSS justify-content). The default is jcFlexStart.</summary>
    property JustifyContent: TJustifyContent read FJustifyContent write SetJustifyContent default jcFlexStart;
    property Margins;
    /// <summary>Smallest width of the flexbox when AutoWidth is True, in pixels: the width is the greater of the width of the parent, MinWidth and the smallest width at which no item is cropped, and the items wrap at that width. If the parent is narrower, the parent crops the flexbox or, if it scrolls, shows the horizontal bar. 0 means no minimum. It has no effect without AutoWidth. The default is 0.</summary>
    property MinWidth: Single read FMinWidth write SetMinWidth;
    property Opacity;
    property Padding;
    property Position;
    /// <summary>Space between the lines, in pixels (CSS row-gap).</summary>
    property RowGap: Single read FRowGap write SetRowGap;
    property Size;
    property Visible;
    property Width;
    /// <summary>Whether the items wrap onto more lines (CSS flex-wrap). The default is fwNoWrap.</summary>
    property Wrap: TFlexWrap read FWrap write SetWrap default fwNoWrap;
    /// <summary>Fires when the set of active breakpoints changes, also at the first layout if there are any.</summary>
    property OnBreakpointsChanged: TNotifyEvent read FOnBreakpointsChanged write FOnBreakpointsChanged;
    property OnClick;
    /// <summary>Fires after a layout has been applied to the items and their events have been fired.</summary>
    property OnLayoutApplied: TNotifyEvent read FOnLayoutApplied write FOnLayoutApplied;
    /// <summary>Fires when the number of lines changes.</summary>
    property OnLineCountChanged: TS4YFlexLineCountEvent read FOnLineCountChanged write FOnLineCountChanged;
    property OnResize;
  end;

implementation

uses
  FMX.Forms,
  Soft4You.FMX.Controls.FlexBox.Strings;

const
  // Layouts of a flexbox that fits its content when the parent changes size in the meantime
  C_MAX_FIT_PASSES = 3;

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
  if (ComponentState * [csLoading, csDestroying] <> []) or
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

  // A change of the Align of the content changes where its size comes from
  UpdateContentSizing;
  PlaceContent;
end;

procedure TS4YFlexItem.UpdateContentSizing;
var
  LContent: TControl;
  LSelfSized: Boolean;
begin
  if IsLoadingOrDestroying then
  begin
    Exit;
  end;

  LContent := GetContent;
  LSelfSized := (LContent <> nil) and (LContent.Align = TAlignLayout.None);

  if LSelfSized then
  begin
    HookContent(LContent);
  end
  else
  begin
    UnhookContent;
  end;

  // The size of a content with its own size is read at every layout
  if LSelfSized <> FContentSelfSized then
  begin
    FContentSelfSized := LSelfSized;
    InvalidateFlexBox;
  end;
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
  if not IsLoadingOrDestroying then
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

  if (LContent <> nil) and (LContent.Align = TAlignLayout.None) and
    not IsLoadingOrDestroying then
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

  // With Align = None the own height of the content is read in ToEngineInput
  if FHeightExplicit or (LContent = nil) or (LContent.Align = TAlignLayout.None) or
    IsLoadingOrDestroying then
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
begin
  FHeightExplicit := False;
  UpdateContentSizing;
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

  if (LContent <> nil) and (LContent.Align = TAlignLayout.Client) then
  begin
    LContent.Align := TAlignLayout.Top;
  end;

  UpdateContentSizing;

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
  else if (AObject is TControl) and (ControlsCount = 1) and
    not IsLoadingOrDestroying and IsContentControl(TControl(AObject)) then
  begin
    UpdateContentSizing;
    PlaceContent;
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
  LContentHeight: Single;
  LContentWidth: Single;
begin
  Result := TFlexItemInput.Default;
  Result.NaturalWidth := FDesignWidth;
  Result.NaturalHeight := FDesignHeight;

  LContent := GetContent;

  // A content with Align = None has its own size, which the item reads
  if not IsLoadingOrDestroying then
  begin
    if (LContent <> nil) and (LContent.Align = TAlignLayout.None) then
    begin
      LContentWidth := LContent.Width + LContent.Margins.Left + LContent.Margins.Right +
        Padding.Left + Padding.Right;
      LContentHeight := LContent.Height + LContent.Margins.Top + LContent.Margins.Bottom +
        Padding.Top + Padding.Bottom;

      // Own size of the content, only for automatic sizes
      if not FWidthExplicit then
      begin
        Result.NaturalWidth := LContentWidth;
      end;

      if not FHeightExplicit then
      begin
        Result.NaturalHeight := LContentHeight;
      end;

      // The item does not shrink below its content (CSS min-width: auto), nor
      // below its explicit size if that is smaller
      Result.AutoMinWidth := Min(Result.NaturalWidth, LContentWidth);
      Result.AutoMinHeight := Min(Result.NaturalHeight, LContentHeight);
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
  UnhookParent;
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

function TS4YFlexBox.ResolveSettings(AWidth: Single): TS4YFlexSettings;
begin
  Result.Direction := FDirection;
  Result.Wrap := FWrap;
  Result.JustifyContent := FJustifyContent;
  Result.AlignItems := FAlignItems;
  Result.AlignContent := FAlignContent;
  Result.ColumnGap := FColumnGap;
  Result.RowGap := FRowGap;

  Result := FBreakpoints.Resolve(AWidth, FBreakpointMode, Result, FActiveBreakpoints);
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
  LAlignRoot: IAlignRoot;
  LContext: TFlexContext;
  LResults: TArray<TFlexItemResult>;
  LFlexChildren: TArray<TControl>;
  LLineCount: Integer;
  LApplied: Boolean;
  LSettings: TS4YFlexSettings;
  LAvailableWidth: Single;
  LCurrentWidth: Single;
  LAutoHeight: Boolean;
  LAutoWidth: Boolean;
  LPass: Integer;
  LRepeat: Boolean;
begin
  // Reentrancy guard; no layout during loading or destruction
  if not UpdatingLayout and not IsLoadingOrDestroying then
  begin
    UpdateParentHook;
    LLineCount := 0;
    LPass := 0;
    BeginLayout;
    try
      repeat
        Inc(LPass);
        LAutoWidth := IsAutoWidthActive(LAvailableWidth);
        LAutoHeight := IsAutoHeightActive;

        if LAutoWidth then
        begin
          LSettings := ResolveSettings(LAvailableWidth);
        end
        else
        begin
          LSettings := ResolveSettings(Width);
        end;

        LContext := BuildContext(LSettings, LFlexChildren);

        if LAutoWidth or LAutoHeight then
        begin
          ApplyAutoSize(LContext, LAutoWidth, LAutoHeight, LAvailableWidth);
        end;

        LApplied := False;

        if Length(LContext.Items) > 0 then
        begin
          LResults := TFlexEngine.Calculate(LContext);
          LLineCount := ApplyResults(LResults, LFlexChildren, LSettings.Direction);
          LApplied := True;
        end;

        // The size of the flexbox can make a scroll bar appear or disappear, which
        // changes the width that the parent gives: the layout is repeated for that
        LRepeat := LAutoWidth and (LPass < C_MAX_FIT_PASSES) and
          IsAutoWidthActive(LCurrentWidth) and
          not SameValue(LCurrentWidth, LAvailableWidth, 0.5);
      until not LRepeat;

      // From now on a size different from this one is a choice of the user
      FLayoutWidth := Width;
      FLayoutHeight := Height;
      FHasLayoutSize := True;
    finally
      EndLayout;
    end;

    // The flow read the right edge of the items before they were placed
    if IsInBlockFlow and Supports(Parent, IAlignRoot, LAlignRoot) and
      not SameValue(MeasureOverflowWidth, FFlowOverflowWidth, 0.001) then
    begin
      LAlignRoot.Realign;
    end;

    // Events fire after the layout is done: a handler that changes the
    // content starts a new layout instead of reentering this one
    if LApplied then
    begin
      NotifyLayoutApplied(LFlexChildren, LLineCount);
    end;
  end;
end;

function TS4YFlexBox.DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean;
  ANewWidth, ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean;
begin
  // A size not set by the layout is a choice of the user, but only after the
  // first layout (the size given when the flexbox is created is not) and only
  // for the sizes that the Align leaves to the user. A size equal to that of the
  // last layout is an echo (for example the designer reapplying the values).
  if not FApplyingAutoSize and FHasLayoutSize and
    (ComponentState * [csLoading, csReading] = []) and
    not (SameValue(ANewWidth, FLayoutWidth, 0.001) and SameValue(ANewHeight, FLayoutHeight, 0.001)) then
  begin
    if (Align = TAlignLayout.None) and not SameValue(ANewWidth, Width, 0.001) then
    begin
      FWidthExplicit := True;
    end;

    if (Align in [TAlignLayout.None, TAlignLayout.Top, TAlignLayout.Bottom]) and
      not SameValue(ANewHeight, Height, 0.001) then
    begin
      FHeightExplicit := True;
    end;
  end;

  Result := inherited DoSetSize(ASize, NewPlatformDefault, ANewWidth, ANewHeight,
    ALastWidth, ALastHeight);
end;

function TS4YFlexBox.TryGetParentArea(out AArea: TRectF): Boolean;
var
  LParent: TControl;
begin
  Result := True;

  if Parent is TControl then
  begin
    LParent := TControl(Parent);
    AArea := TRectF.Create(LParent.Padding.Left, LParent.Padding.Top,
      LParent.Width - LParent.Padding.Right, LParent.Height - LParent.Padding.Bottom);
  end
  else if Parent is TCommonCustomForm then
  begin
    AArea := TRectF.Create(0, 0, TCommonCustomForm(Parent).ClientWidth,
      TCommonCustomForm(Parent).ClientHeight);
  end
  else
  begin
    AArea := TRectF.Empty;
    Result := False;
  end;
end;

function TS4YFlexBox.IsAutoWidthActive(out AAvailableWidth: Single): Boolean;
var
  LParentArea: TRectF;
begin
  AAvailableWidth := 0;

  if IsInBlockFlow then
  begin
    // The width that the flow gives
    Result := not FWidthExplicit and (Align = TAlignLayout.None) and FHasFlowWidth;

    if Result then
    begin
      AAvailableWidth := FFlowWidth;
    end;
  end
  else
  begin
    Result := not FWidthExplicit and (Align = TAlignLayout.None) and
      TryGetParentArea(LParentArea);

    if Result then
    begin
      // From the position of the flexbox to the right edge of the area of the
      // parent, with the right margin of the flexbox taken away
      AAvailableWidth := Max(0, LParentArea.Right - Margins.Right - Position.X);
    end;
  end;
end;

function TS4YFlexBox.IsInBlockFlow: Boolean;
begin
  Result := Supports(Parent, IS4YBlockFlowContainer);
end;

function TS4YFlexBox.IsAutoHeightActive: Boolean;
begin
  Result := not FHeightExplicit and
    (Align in [TAlignLayout.None, TAlignLayout.Top, TAlignLayout.Bottom]);
end;

procedure TS4YFlexBox.ApplyAutoSize(var AContext: TFlexContext;
  UseAutoWidth, UseAutoHeight: Boolean; AAvailableWidth: Single);
var
  LMeasure: TFlexContentSize;
  LNewHeight: Single;
  LNewWidth: Single;
  LOuterWidth: Single;
  LPaddingHorizontal: Single;
  LPaddingVertical: Single;
begin
  LPaddingHorizontal := Padding.Left + Padding.Right;
  LPaddingVertical := Padding.Top + Padding.Bottom;

  if UseAutoWidth then
  begin
    LOuterWidth := Max(AAvailableWidth, FMinWidth);
  end
  else
  begin
    LOuterWidth := Width;
  end;

  AContext.AvailableWidth := Max(0, LOuterWidth - LPaddingHorizontal);

  LNewWidth := LOuterWidth;
  LNewHeight := Height;

  // Without items the height stays as it is: an empty flexbox must not disappear
  if Length(AContext.Items) > 0 then
  begin
    LMeasure := TFlexEngine.Measure(AContext);

    // In the block flow the width does not grow: the items overflow, as in CSS
    if UseAutoWidth and not IsInBlockFlow then
    begin
      LNewWidth := Max(LOuterWidth, LMeasure.Width + LPaddingHorizontal);
    end;

    if UseAutoHeight then
    begin
      LNewHeight := LMeasure.Height + LPaddingVertical;
    end;
  end;

  FApplyingAutoSize := True;
  try
    SetBounds(Position.X, Position.Y, LNewWidth, LNewHeight);
  finally
    FApplyingAutoSize := False;
  end;

  AContext.AvailableWidth := Width - LPaddingHorizontal;
  AContext.AvailableHeight := Height - LPaddingVertical;
end;

procedure TS4YFlexBox.DoMatrixChanged(Sender: TObject);
begin
  inherited;

  // Only an assignment of Position: inside SetBounds the layout cannot run (the
  // control is updating) and Move follows; scale and rotation do not change the width
  if Sender = Position then
  begin
    FollowPosition;
  end;
end;

procedure TS4YFlexBox.Move;
begin
  inherited;
  FollowPosition;
end;

procedure TS4YFlexBox.FollowPosition;
begin
  // With an automatic width the space up to the right edge of the parent depends
  // on the position; in the block flow the position is that of the flow
  if not FApplyingAutoSize and FHasLayoutSize and not FWidthExplicit and
    (Align = TAlignLayout.None) and not IsInBlockFlow and
    (ComponentState * [csLoading, csReading, csDestroying] = []) then
  begin
    InvalidateLayout;
  end;
end;

function TS4YFlexBox.MeasureContent: TSizeF;
var
  LContext: TFlexContext;
  LFlexChildren: TArray<TControl>;
  LMeasure: TFlexContentSize;
  LSettings: TS4YFlexSettings;
begin
  LSettings := ResolveSettings(Width);
  LContext := BuildContext(LSettings, LFlexChildren);
  LMeasure := TFlexEngine.Measure(LContext);
  Result := TSizeF.Create(LMeasure.Width + Padding.Left + Padding.Right,
    LMeasure.Height + Padding.Top + Padding.Bottom);
end;

procedure TS4YFlexBox.Loaded;
begin
  inherited;
  InvalidateLayout;
end;

procedure TS4YFlexBox.ParentChanged;
begin
  inherited;
  // A new parent in the block flow gives its own width
  FHasFlowWidth := False;
  UpdateParentHook;
  InvalidateLayout;
end;

function TS4YFlexBox.GetFlowAutoWidth: Boolean;
begin
  Result := (Align = TAlignLayout.Top) or ((Align = TAlignLayout.None) and not FWidthExplicit);
end;

function TS4YFlexBox.GetFlowOverflowWidth: Single;
begin
  // The value that the flow knows: a layout that changes it tells the flow
  Result := MeasureOverflowWidth;
  FFlowOverflowWidth := Result;
end;

function TS4YFlexBox.MeasureOverflowWidth: Single;
var
  LChild: TControl;
begin
  Result := Width;

  // A flexbox that crops its items has nothing that overflows (overflow: hidden)
  if not ClipChildren then
  begin
    for var I := 0 to ControlsCount - 1 do
    begin
      LChild := Controls[I];

      if IsFlexChild(LChild) then
      begin
        Result := Max(Result, LChild.Position.X + LChild.Width + LChild.Margins.Right + Padding.Right);
      end;
    end;
  end;
end;

procedure TS4YFlexBox.SetFlowBounds(ALeft, ATop, AWidth: Single);
var
  LWidth: Single;
  LWidthChanged: Boolean;
begin
  LWidthChanged := not FHasFlowWidth or not SameValue(FFlowWidth, AWidth, 0.001);
  FFlowWidth := AWidth;
  FHasFlowWidth := True;

  // With Align = None the layout applies the width (MinWidth included)
  LWidth := Width;
  if Align = TAlignLayout.Top then
  begin
    LWidth := AWidth;
  end;

  // Not a choice of the user: AutoWidth stays True
  FApplyingAutoSize := True;
  try
    SetBounds(ALeft, ATop, LWidth, Height);
  finally
    FApplyingAutoSize := False;
  end;

  if LWidthChanged then
  begin
    InvalidateLayout;
  end;
end;

function TS4YFlexBox.GetAutoHeight: Boolean;
begin
  Result := not FHeightExplicit;
end;

function TS4YFlexBox.GetAutoWidth: Boolean;
begin
  Result := not FWidthExplicit;
end;

function TS4YFlexBox.IsAutoHeightStored: Boolean;
begin
  Result := FHeightExplicit;
end;

function TS4YFlexBox.IsAutoWidthStored: Boolean;
begin
  Result := FWidthExplicit;
end;

procedure TS4YFlexBox.SetAutoHeight(Value: Boolean);
begin
  if Value = FHeightExplicit then
  begin
    FHeightExplicit := not Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.SetAutoWidth(Value: Boolean);
begin
  if Value = FWidthExplicit then
  begin
    FWidthExplicit := not Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.UpdateParentHook;
begin
  // The size of the parent matters only to an automatic width; the block flow
  // gives the width by itself
  if not FWidthExplicit and (Align = TAlignLayout.None) and (Parent <> nil) and
    not IsInBlockFlow then
  begin
    if FHookedParent <> Parent then
    begin
      UnhookParent;
      HookParent;
    end;
  end
  else
  begin
    UnhookParent;
  end;
end;

procedure TS4YFlexBox.SetMinWidth(Value: Single);
begin
  Value := Max(0, Value);

  if not SameValue(FMinWidth, Value) then
  begin
    FMinWidth := Value;
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.HookParent;
begin
  if Parent is TControl then
  begin
    FHookedParent := Parent;
    FPreviousParentResized := TControl(Parent).OnResized;
    TControl(Parent).OnResized := ParentResized;
  end
  else if Parent is TCommonCustomForm then
  begin
    FHookedParent := Parent;
    FPreviousParentResized := TCommonCustomForm(Parent).OnResize;
    TCommonCustomForm(Parent).OnResize := ParentResized;
  end;
end;

procedure TS4YFlexBox.UnhookParent;
var
  LHandler: TMethod;
begin
  if FHookedParent <> nil then
  begin
    // If the user assigned another handler after ours, theirs stays
    if FHookedParent is TControl then
    begin
      LHandler := TMethod(TControl(FHookedParent).OnResized);

      if (LHandler.Data = Pointer(Self)) and (LHandler.Code = @TS4YFlexBox.ParentResized) then
      begin
        TControl(FHookedParent).OnResized := FPreviousParentResized;
      end;
    end
    else if FHookedParent is TCommonCustomForm then
    begin
      LHandler := TMethod(TCommonCustomForm(FHookedParent).OnResize);

      if (LHandler.Data = Pointer(Self)) and (LHandler.Code = @TS4YFlexBox.ParentResized) then
      begin
        TCommonCustomForm(FHookedParent).OnResize := FPreviousParentResized;
      end;
    end;

    FHookedParent := nil;
    FPreviousParentResized := nil;
  end;
end;

procedure TS4YFlexBox.ParentResized(Sender: TObject);
begin
  if Assigned(FPreviousParentResized) then
  begin
    FPreviousParentResized(Sender);
  end;

  if not FWidthExplicit then
  begin
    InvalidateLayout;
  end;
end;

procedure TS4YFlexBox.NotifyLayoutApplied(const AFlexChildren: TArray<TControl>;
  ALineCount: Integer);
var
  LChild: TControl;
  LPreviousLineCount: Integer;
begin
  if ComponentState * [csLoading, csDestroying] <> [] then
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
