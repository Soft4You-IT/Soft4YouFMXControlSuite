unit Soft4You.FMX.Controls.Expander;

interface

uses
  System.Classes,
  System.ImageList,
  System.UITypes,

  FMX.ActnList,
  FMX.Ani,
  FMX.ImgList,
  FMX.Menus,
  FMX.Types,
  FMX.StdCtrls,

  Soft4You.FMX.Controls.Badge;

type
  TS4YExpander = class;

  // Small facade exposing only the badge settings an application actually needs to
  // drive at runtime (value/visibility/interaction), instead of publishing the whole
  // TS4YBadge sub-component - which would let callers override anything the style
  // already defines (colors, position, ...) and would be nil at design-time, before
  // the style's own 'badge' element has ever been resolved via FindStyleResource.
  // Every property is buffered locally and pushed to the real TS4YBadge both
  // immediately (if already resolved) and again in ApplyToBadge (called once the
  // style provides one) - so callers can set them at any time regardless of timing.
  TS4YExpanderBadgeSettings = class(TPersistent)
  private
    FExpander: TS4YExpander;
    FStyle: TS4YBadgeStyle;
    FText: string;
    FCurrentValue: Integer;
    FMaxValue: Integer;
    FVisible: Boolean;
    FHitTest: Boolean;
    FPopupMenu: TPopupMenu;
    FOnClick: TNotifyEvent;
    FBlinkSettings: TS4YBadgeBlinkSettings;
    FOnChange: TNotifyEvent;
    function GetBadge: TS4YBadge;
    procedure SetStyle(const Value: TS4YBadgeStyle);
    procedure SetText(const Value: string);
    procedure SetCurrentValue(const Value: Integer);
    procedure SetMaxValue(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
    procedure SetHitTest(const Value: Boolean);
    procedure SetPopupMenu(const Value: TPopupMenu);
    procedure SetOnClick(const Value: TNotifyEvent);
    procedure SetBlinkSettings(const Value: TS4YBadgeBlinkSettings);
    procedure BlinkSettingsChangedHandler(Sender: TObject);
    property Badge: TS4YBadge read GetBadge;
  protected
    procedure DoChange;
  public
    constructor Create(const AExpander: TS4YExpander);
    destructor Destroy; override;

    procedure ApplyToBadge;
    procedure Assign(Source: TPersistent); override;
    procedure SetDefaultValues;
  published
    property BlinkSettings: TS4YBadgeBlinkSettings read FBlinkSettings write SetBlinkSettings;
    property CurrentValue: Integer read FCurrentValue write SetCurrentValue default 0;
    property HitTest: Boolean read FHitTest write SetHitTest default False;
    property MaxValue: Integer read FMaxValue write SetMaxValue default TS4YBadge.C_DEFAULT_MAX_VALUE;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
    property Style: TS4YBadgeStyle read FStyle write SetStyle default TS4YBadge.C_DEFAULT_BADGE_STYLE;
    property Text: string read FText write SetText;
    property Visible: Boolean read FVisible write SetVisible default False;

    property OnClick: TNotifyEvent read FOnClick write SetOnClick;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TS4YExpander = class(TExpander, IGlyph)
  private
    FBadge: TS4YBadge;
    FBadgeSettings: TS4YExpanderBadgeSettings;
    FClickOnHeader: Boolean;
    FExpandedHeight: Single;
    FAnimated: Boolean;
    FAnimationDuration: Single;
    FGlyph: TGlyph;
    FHeightAnimation: TFloatAnimation;
    FImageLink: TGlyphImageLink;
    FShowIcon: Boolean;
    function GetImageIndex: TImageIndex;
    function GetImageList: TBaseImageList;
    function GetImages: TCustomImageList;
    procedure HandleHeaderClick(Sender: TObject);
    function IsExpandedHeightStored: Boolean;
    procedure SetBadgeSettings(const Value: TS4YExpanderBadgeSettings);
    procedure SetClickOnHeader(const Value: Boolean);
    procedure SetExpandedHeight(const Value: Single);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageList(const Value: TBaseImageList);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetShowIcon(const Value: Boolean);
    procedure EnsureHeightAnimation;
    procedure AnimateToHeight(const ATargetHeight: Single);
    procedure BadgeSettingsChangedHandler(Sender: TObject);
    procedure UpdateIcon;
    { IGlyph }
    function IGlyph.GetImages = GetImageList;
    procedure IGlyph.SetImages = SetImageList;
  protected
    procedure ApplyStyle; override;
    procedure BadgeChanged; virtual;
    procedure DoExpandedChanged; override;
    procedure DoRealign; override;
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean;
      ANewWidth, ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean; override;
    procedure FreeStyle; override;
    function GetStyleObject: TFmxObject; override;
    procedure ImagesChanged; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Animated: Boolean read FAnimated write FAnimated default False;
    property AnimationDuration: Single read FAnimationDuration write FAnimationDuration;
    property BadgeSettings: TS4YExpanderBadgeSettings read FBadgeSettings write SetBadgeSettings;
    property ClickOnHeader: Boolean read FClickOnHeader write SetClickOnHeader default True;
    // Height the control takes when expanded. Saved (in the form file) only while collapsed, because a
    // collapsed control is streamed with the height of its header: without this the height to restore on
    // expansion is lost, so IsExpanded = True does not expand it, neither at design time nor at run time.
    property ExpandedHeight: Single read FExpandedHeight write SetExpandedHeight stored IsExpandedHeightStored;
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    property Images: TCustomImageList read GetImages write SetImages;
    property ShowIcon: Boolean read FShowIcon write SetShowIcon default True;
  end;

implementation

uses
  System.SysUtils,
  System.Types,

  FMX.Controls,
  FMX.Styles;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_BACKGROUND = 'background'; // Not localize
  C_STYLE_TEXT= 'text';              // Not localize

{ TS4YExpander }

procedure TS4YExpander.ApplyStyle;
var
  LExpectedHeight: Single;
  LHeader: TFmxObject;
begin
  LExpectedHeight := Height;

  inherited;

  if (FHeightAnimation <> nil) and FHeightAnimation.Running then
    FHeightAnimation.Stop;

  // Restore the height that was current before inherited (which may have altered
  // it via UpdateControlSize). When ApplyStyle is called deferred - i.e. after
  // SetIsExpanded was already called with Scene=nil (TFrame before being parented)
  // - FIsExpanded is already False here, so collapse to header height.
  if IsExpanded then
    Height := LExpectedHeight
  else
    Height := EffectiveHeaderHeight;

  // Optional icon declared by the style: UpdateIcon keeps it hidden unless
  // ShowIcon is set and the image list / image index point to a real image.
  if FindStyleResource<TGlyph>('icon', FGlyph) then
    UpdateIcon;

  LHeader := FindStyleResource('header');

  if not (LHeader is TControl) then
    Exit;

  if FClickOnHeader then
  begin
    TControl(LHeader).HitTest := True;
    TControl(LHeader).OnClick := HandleHeaderClick;
  end;

  // Deferred case only: inherited started an async collapse animation before
  // HitTest was set to True. Snap to the correct visual state synchronously.
  if not IsExpanded then
    TAnimator.StartTriggerAnimationWait(LHeader, Self, 'IsExpanded');

  if FindStyleResource<TS4YBadge>('badge', FBadge) then
  begin
    // Mirrors the base TExpander.ApplyStyle handling of FButton: a nested custom
    // TStyledControl found this way does not reliably get its own ApplyStyleLookup
    // triggered by the generic paint-driven mechanism (Painting/PrepareForPaint/
    // RecalcSize) in this context - force it synchronously here instead.
    FBadgeSettings.ApplyToBadge;
    FBadge.ApplyStyleLookup;
  end;
end;

procedure TS4YExpander.BadgeChanged;
begin
  if Assigned(FBadge) then
  begin
    FBadgeSettings.ApplyToBadge;
    FBadge.Repaint;
  end;
end;

procedure TS4YExpander.BadgeSettingsChangedHandler(Sender: TObject);
begin
  BadgeChanged;
end;

constructor TS4YExpander.Create(AOwner: TComponent);
begin
  inherited;
  FClickOnHeader := True;
  FAnimated := False;
  FAnimationDuration := 0.25;
  FShowIcon := True;
  FImageLink := TGlyphImageLink.Create(Self);
  FBadgeSettings := TS4YExpanderBadgeSettings.Create(Self);
  FBadgeSettings.OnChange := BadgeSettingsChangedHandler;
end;

destructor TS4YExpander.Destroy;
begin
  FreeAndNil(FBadgeSettings);
  FreeAndNil(FImageLink);

  inherited;
end;

procedure TS4YExpander.DoExpandedChanged;
var
  LHeader: TFmxObject;
  LTargetHeight: Single;
begin
  inherited;

  // StartTriggerAnimation(Self,'IsExpanded') traversal is blocked because
  // ApplyStyle set HitTest=True on the header. Drive the animation directly
  // from the header so the arrow reaches the correct state before next paint.
  LHeader := FindStyleResource('header');

  if LHeader <> nil then
    TAnimator.StartTriggerAnimationWait(LHeader, Self, 'IsExpanded');

  // The custom style has no 'button' element, so FButton=nil and
  // TExpander.UpdateControlSize never sets Height. Manage it here instead:
  // on collapse snap to header height; on expand restore FExpandedHeight
  // (saved by DoSetSize whenever Height is changed while expanded).
  if IsExpanded then
    LTargetHeight := FExpandedHeight
  else
    LTargetHeight := EffectiveHeaderHeight;

  if FAnimated and (FExpandedHeight > EffectiveHeaderHeight) then
    AnimateToHeight(LTargetHeight)
  else
  begin
    if IsExpanded then
    begin
      if FExpandedHeight > EffectiveHeaderHeight then
        Height := FExpandedHeight;
    end
    else
      Height := EffectiveHeaderHeight;
  end;
end;

procedure TS4YExpander.DoRealign;
var
  LIndex: Integer;
begin
  inherited;
  LIndex := 0;

  while (LIndex < ChildrenCount) and not (Children[LIndex] is TContent) do
  begin
    Inc(LIndex);
  end;

  if LIndex < ChildrenCount then
  begin
    TContent(Children[LIndex]).Padding.Assign(Padding);
  end;
end;

function TS4YExpander.DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean;
  ANewWidth, ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean;
begin
  if not FIsExpanded then
  begin
    // TExpander.DoSetSize substitutes the current Height for ANewHeight when
    // collapsed, blocking the explicit assignments in ApplyStyle and
    // DoExpandedChanged. Bypass by temporarily flagging as expanded.
    // Side effect: TExpander resets FContentHeight to 0; corrected on next
    // expansion via DoExpandedChanged -> Height := FExpandedHeight.
    FIsExpanded := True;
    try
      Result := inherited;
    finally
      FIsExpanded := False;
    end;
  end
  else
  begin
    // Track the latest valid expanded height so DoExpandedChanged can restore
    // it after a collapse/expand cycle. Captured here rather than in ApplyStyle
    // so it stays current even when the user resizes the control at runtime.
    if ANewHeight > EffectiveHeaderHeight then
      FExpandedHeight := ANewHeight;

    Result := inherited;
  end;
end;

procedure TS4YExpander.FreeStyle;
begin
  if FGlyph <> nil then
  begin
    FGlyph.ImageIndex := -1;
    FGlyph.Images := nil;
    FGlyph := nil;
  end;

  FBadge := nil;

  inherited;
end;

function TS4YExpander.GetStyleObject: TFmxObject;
var
  LStyle: String;
begin
  if (StyleLookup = '') then
  begin
    LStyle := GetDefaultStyleLookupName;
    Result := TStyleStreaming.LoadFromResource(HInstance, LStyle, RT_RCDATA)
  end
  else
    Result := inherited GetStyleObject;
end;

function TS4YExpander.GetImageIndex: TImageIndex;
begin
  Result := FImageLink.ImageIndex;
end;

function TS4YExpander.GetImageList: TBaseImageList;
begin
  Result := FImageLink.Images;
end;

function TS4YExpander.GetImages: TCustomImageList;
begin
  Result := TCustomImageList(FImageLink.Images);
end;

procedure TS4YExpander.ImagesChanged;
begin
  UpdateIcon;
end;

procedure TS4YExpander.SetImageIndex(const Value: TImageIndex);
begin
  FImageLink.ImageIndex := Value;
end;

procedure TS4YExpander.SetImageList(const Value: TBaseImageList);
begin
  FImageLink.Images := Value;
end;

procedure TS4YExpander.SetImages(const Value: TCustomImageList);
begin
  FImageLink.Images := Value;
end;

procedure TS4YExpander.SetShowIcon(const Value: Boolean);
begin
  if FShowIcon = Value then
    Exit;

  FShowIcon := Value;
  UpdateIcon;
end;

procedure TS4YExpander.UpdateIcon;
var
  LImages: TCustomImageList;
begin
  if FGlyph = nil then
    Exit;

  LImages := GetImages;

  FGlyph.BeginUpdate;
  try
    // The glyph's own AutoHide would fight with ShowIcon: visibility is decided here.
    FGlyph.AutoHide := False;
    FGlyph.Images := LImages;
    FGlyph.ImageIndex := FImageLink.ImageIndex;
    FGlyph.Visible := FShowIcon and (LImages <> nil) and LImages.BitmapExists(FImageLink.ImageIndex);
  finally
    FGlyph.EndUpdate;
  end;
end;

procedure TS4YExpander.EnsureHeightAnimation;
begin
  if FHeightAnimation <> nil then
    Exit;

  FHeightAnimation := TFloatAnimation.Create(Self);
  FHeightAnimation.Parent := Self;
  FHeightAnimation.PropertyName := 'Height';
  FHeightAnimation.Interpolation := TInterpolationType.Sinusoidal;
  FHeightAnimation.AnimationType := TAnimationType.InOut;
end;

procedure TS4YExpander.AnimateToHeight(const ATargetHeight: Single);
begin
  EnsureHeightAnimation;
  FHeightAnimation.StopAtCurrent;
  FHeightAnimation.Duration := FAnimationDuration;
  FHeightAnimation.StartValue := Height;
  FHeightAnimation.StopValue := ATargetHeight;
  FHeightAnimation.Start;
end;

procedure TS4YExpander.HandleHeaderClick(Sender: TObject);
begin
  IsExpanded := not IsExpanded;
end;

procedure TS4YExpander.SetBadgeSettings(const Value: TS4YExpanderBadgeSettings);
begin
  if Assigned(Value) then
    FBadgeSettings.Assign(Value)
  else
    FBadgeSettings.SetDefaultValues;
end;

procedure TS4YExpander.SetClickOnHeader(const Value: Boolean);
var
  LHeader: TFmxObject;
begin
  if FClickOnHeader = Value then
    Exit;

  FClickOnHeader := Value;
  LHeader := FindStyleResource('header');

  if not (LHeader is TControl) then
    Exit;

  if FClickOnHeader then
  begin
    TControl(LHeader).HitTest := True;
    TControl(LHeader).OnClick := HandleHeaderClick;
  end
  else
  begin
    TControl(LHeader).OnClick := nil;
  end;
end;

function TS4YExpander.IsExpandedHeightStored: Boolean;
begin
  // Only while collapsed: then Size.Height is the header height and this is the only place that keeps
  // the height to restore on expansion. When expanded, Size.Height already carries it.
  Result := (not IsExpanded) and (FExpandedHeight > EffectiveHeaderHeight);
end;

procedure TS4YExpander.SetExpandedHeight(const Value: Single);
begin
  if FExpandedHeight = Value then
    Exit;

  FExpandedHeight := Value;

  // While loading, the regular sequence (Size.Height, ApplyStyle) applies the height. Afterwards an
  // expanded control follows the new value, so changing it in the Object Inspector is visible.
  if IsExpanded and not (csLoading in ComponentState) and (FExpandedHeight > EffectiveHeaderHeight) then
    Height := FExpandedHeight;
end;

{ TS4YExpanderBadgeSettings }

procedure TS4YExpanderBadgeSettings.ApplyToBadge;
begin
  if not Assigned(Badge) then
    Exit;

  Badge.BadgeStyle := FStyle;
  Badge.Text := FText;
  Badge.CurrentValue := FCurrentValue;
  Badge.MaxValue := FMaxValue;
  Badge.Visible := FVisible;
  Badge.HitTest := FHitTest;
  Badge.PopupMenu := FPopupMenu;
  Badge.OnClick := FOnClick;
  Badge.BlinkSettings.Enabled := FBlinkSettings.Enabled;
  Badge.BlinkSettings.Interval := FBlinkSettings.Interval;
end;

procedure TS4YExpanderBadgeSettings.Assign(Source: TPersistent);
var
  LSource: TS4YExpanderBadgeSettings;
begin
  if Source is TS4YExpanderBadgeSettings then
  begin
    LSource := TS4YExpanderBadgeSettings(Source);

    Style := LSource.Style;
    Text := LSource.Text;
    CurrentValue := LSource.CurrentValue;
    MaxValue := LSource.MaxValue;
    Visible := LSource.Visible;
    HitTest := LSource.HitTest;
    PopupMenu := LSource.PopupMenu;
    OnClick := LSource.OnClick;
    BlinkSettings := LSource.BlinkSettings;

    DoChange;
  end
  else
    inherited Assign(Source);
end;

procedure TS4YExpanderBadgeSettings.BlinkSettingsChangedHandler(Sender: TObject);
begin
  if Assigned(Badge) then
  begin
    Badge.BlinkSettings.Enabled := FBlinkSettings.Enabled;
    Badge.BlinkSettings.Interval := FBlinkSettings.Interval;
  end;
end;

constructor TS4YExpanderBadgeSettings.Create(const AExpander: TS4YExpander);
begin
  inherited Create;

  FExpander := AExpander;
  FStyle := TS4YBadge.C_DEFAULT_BADGE_STYLE;
  FMaxValue := TS4YBadge.C_DEFAULT_MAX_VALUE;
  FVisible := False;
  FHitTest := False;

  FBlinkSettings := TS4YBadgeBlinkSettings.Create;
  FBlinkSettings.OnChange := BlinkSettingsChangedHandler;
end;

destructor TS4YExpanderBadgeSettings.Destroy;
begin
  FreeAndNil(FBlinkSettings);

  inherited;
end;

procedure TS4YExpanderBadgeSettings.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TS4YExpanderBadgeSettings.GetBadge: TS4YBadge;
begin
  Result := FExpander.FBadge;
end;

procedure TS4YExpanderBadgeSettings.SetBlinkSettings(const Value: TS4YBadgeBlinkSettings);
begin
  FBlinkSettings.Enabled := Value.Enabled;
  FBlinkSettings.Interval := Value.Interval;
  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetCurrentValue(const Value: Integer);
begin
  if FCurrentValue = Value then
    exit;

  FCurrentValue := Value;
  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetDefaultValues;
begin
  FBlinkSettings.SetDefaultValues;
  FCurrentValue := 0;
  FHitTest := False;
  FMaxValue := TS4YBadge.C_DEFAULT_MAX_VALUE;
  FPopupMenu := nil;
  FStyle := TS4YBadge.C_DEFAULT_BADGE_STYLE;
  FText := EmptyStr;
  FVisible := False;
  FOnClick := nil;

  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetHitTest(const Value: Boolean);
begin
  if FHitTest = Value then
    exit;

  FHitTest := Value;
  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetMaxValue(const Value: Integer);
begin
  if FMaxValue = Value then
    exit;

  FMaxValue := Value;
  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetOnClick(const Value: TNotifyEvent);
begin
  FOnClick := Value;
  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetPopupMenu(const Value: TPopupMenu);
begin
  if FPopUpMenu = Value then
    exit;

  FPopupMenu := Value;
  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetStyle(const Value: TS4YBadgeStyle);
begin
  if FStyle = Value then
    exit;

  FStyle := Value;
  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetText(const Value: string);
begin
  if FText = Value then
    exit;

  FText := Value;
  DoChange;
end;

procedure TS4YExpanderBadgeSettings.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    exit;

  FVisible := Value;
  DoChange;
end;

end.
