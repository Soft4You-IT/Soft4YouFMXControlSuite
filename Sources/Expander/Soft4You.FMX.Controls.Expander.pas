unit Soft4You.FMX.Controls.Expander;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YExpander - expander with an icon, a badge and an animated height
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

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

  /// <summary>
  /// Settings of the badge shown on the header of a TS4YExpander.
  /// </summary>
  /// <remarks>
  /// They are the settings an application needs to drive at run time: what the badge shows, whether it is visible, whether it reacts to the mouse and whether it blinks.
  /// Its look (colors, position) comes from the style of the expander. The settings can be changed at any time: they are applied to the badge as soon as the style provides it.
  /// </remarks>
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
    /// <summary>Fires OnChange.</summary>
    procedure DoChange;
  public
    /// <summary>Creates the settings for the badge of the given expander, with the default values.</summary>
    constructor Create(const AExpander: TS4YExpander);
    destructor Destroy; override;

    /// <summary>Copies the settings to the badge of the style. It does nothing if the style has no badge yet; the expander calls it again when the style is applied.</summary>
    procedure ApplyToBadge;
    /// <summary>Copies all the settings from another TS4YExpanderBadgeSettings and fires OnChange.</summary>
    procedure Assign(Source: TPersistent); override;
    /// <summary>Restores the default values of all the settings and fires OnChange.</summary>
    procedure SetDefaultValues;
  published
    /// <summary>Blinking of the badge at run time. See TS4YBadgeBlinkSettings.</summary>
    property BlinkSettings: TS4YBadgeBlinkSettings read FBlinkSettings write SetBlinkSettings;
    /// <summary>The number shown when Style is bdgsNumeric. At run time the badge is hidden while it is 0 or less; above MaxValue it shows MaxValue+.</summary>
    property CurrentValue: Integer read FCurrentValue write SetCurrentValue default 0;
    /// <summary>True makes the badge react to the mouse, which OnClick and PopupMenu need. With False a click on the badge reaches the header of the expander. The default is False.</summary>
    property HitTest: Boolean read FHitTest write SetHitTest default False;
    /// <summary>Highest value shown as a plain number; a greater CurrentValue is shown as MaxValue+, for example 99+. The default is 99.</summary>
    property MaxValue: Integer read FMaxValue write SetMaxValue default TS4YBadge.C_DEFAULT_MAX_VALUE;
    /// <summary>Popup menu of the badge. It needs HitTest to be True.</summary>
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
    /// <summary>What the badge shows: the number CurrentValue or the Text. The default is bdgsNumeric.</summary>
    property Style: TS4YBadgeStyle read FStyle write SetStyle default TS4YBadge.C_DEFAULT_BADGE_STYLE;
    /// <summary>The text shown when Style is bdgsText. At run time the badge is hidden while it is empty.</summary>
    property Text: string read FText write SetText;
    /// <summary>True shows the badge. At run time it stays hidden anyway while it has nothing to show (see Style). The default is False.</summary>
    property Visible: Boolean read FVisible write SetVisible default False;

    /// <summary>Fires when the user clicks the badge. It needs HitTest to be True.</summary>
    property OnClick: TNotifyEvent read FOnClick write SetOnClick;
    /// <summary>Fires when one of the settings changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  /// <summary>
  /// An expander (a collapsible panel with a header) that extends the standard FMX TExpander with an icon in the header, an optional height animation, a click on the whole header and a badge counter on the header.
  /// </summary>
  /// <remarks>
  /// The icon comes from an image list (Images and ImageIndex) and is shown only if ShowIcon is True and the index points to a real image.
  /// With Animated = True the height of the control changes smoothly when it expands or collapses.
  /// With ClickOnHeader = True a click anywhere on the header expands or collapses the control, not only on the arrow button.
  /// The badge is configured with BadgeSettings; its look comes from the style.
  /// A custom style can provide the parts named header (the area that reacts to the click), icon and badge.
  /// </remarks>
  TS4YExpander = class(TExpander, IGlyph)
  private
    FBadge: TS4YBadge;
    FBadgeSettings: TS4YExpanderBadgeSettings;
    FClickOnHeader: Boolean;
    FExpandedHeight: Single;
    FHeightBeforeChange: Single;
    FIsAnimatingHeight: Boolean;
    FSavedClipChildren: Boolean;
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
    procedure AnimateToHeight(const AStartHeight, ATargetHeight: Single);
    procedure BadgeSettingsChangedHandler(Sender: TObject);
    procedure HeightAnimationFinished(Sender: TObject);
    procedure UpdateIcon;
    { IGlyph }
    function IGlyph.GetImages = GetImageList;
    procedure IGlyph.SetImages = SetImageList;
  protected
    /// <summary>Applies the settings of the expander (icon, click on the header, badge) to the parts of the style named icon, header and badge.</summary>
    procedure ApplyStyle; override;
    /// <summary>Called when a badge setting changes: it applies the settings to the badge. A descendant can override it.</summary>
    procedure BadgeChanged; virtual;
    /// <summary>Sets the height of the control after it expanded or collapsed, with the animation if Animated is True.</summary>
    procedure DoExpandedChanged; override;
    /// <summary>Remembers the height before the change, from which the animation starts.</summary>
    procedure DoExpandedChanging; override;
    /// <summary>Realigns the content and gives it the Padding of the expander.</summary>
    procedure DoRealign; override;
    /// <summary>Sets the size of the control. While it is expanded the height is kept as ExpandedHeight; while it is collapsed the height can still be set, as the base class would ignore it.</summary>
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean;
      ANewWidth, ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean; override;
    /// <summary>Releases the parts of the style found by ApplyStyle.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the style of the expander: the default style of the control when StyleLookup is empty.</summary>
    function GetStyleObject: TFmxObject; override;
    /// <summary>Called when the image list or the image index change: it refreshes the icon. A descendant can override it.</summary>
    procedure ImagesChanged; virtual;
  public
    /// <summary>Creates the expander with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    /// <summary>True animates the height when the control expands or collapses. The default is False.</summary>
    property Animated: Boolean read FAnimated write FAnimated default False;
    /// <summary>Duration of the height animation, in seconds. The default is 0.25.</summary>
    property AnimationDuration: Single read FAnimationDuration write FAnimationDuration;
    /// <summary>Settings of the badge shown on the header.</summary>
    property BadgeSettings: TS4YExpanderBadgeSettings read FBadgeSettings write SetBadgeSettings;
    /// <summary>True makes a click anywhere on the header expand or collapse the control. The default is True.</summary>
    property ClickOnHeader: Boolean read FClickOnHeader write SetClickOnHeader default True;
    /// <summary>
    /// Height of the control when it is expanded.
    /// </summary>
    /// <remarks>
    /// It is saved in the form only while the control is collapsed, because a collapsed control is saved with the height of its header: without it the height to restore on expansion would be lost.
    /// When the control is expanded, Height already holds it. Changing it on an expanded control resizes the control.
    /// </remarks>
    property ExpandedHeight: Single read FExpandedHeight write SetExpandedHeight stored IsExpandedHeightStored;
    /// <summary>Index in Images of the image shown as the icon of the header. The default is -1, no icon.</summary>
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    /// <summary>Image list that holds the icon of the header.</summary>
    property Images: TCustomImageList read GetImages write SetImages;
    /// <summary>True shows the icon of the header, when Images and ImageIndex point to an image. The default is True.</summary>
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

  // TExpander.UpdateControlSize has already set Height from the 'button' element
  // of the style and the content height, which is not the height wanted here.
  // Manage it here instead: on collapse go to the header height; on expand restore
  // FExpandedHeight (saved by DoSetSize whenever Height is changed while expanded).
  if IsExpanded then
    LTargetHeight := FExpandedHeight
  else
    LTargetHeight := EffectiveHeaderHeight;

  // The animation starts from the height before the change, which DoExpandedChanging
  // saved: Height itself was already changed by the base class.
  if FAnimated and (FExpandedHeight > EffectiveHeaderHeight) then
    AnimateToHeight(FHeightBeforeChange, LTargetHeight)
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

procedure TS4YExpander.DoExpandedChanging;
begin
  inherited;

  // Called before the base class changes Height, so this is the height from
  // which an animation has to start
  FHeightBeforeChange := Height;
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
    // The intermediate heights of an animation are not the expanded height
    if (ANewHeight > EffectiveHeaderHeight) and not FIsAnimatingHeight then
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
var
  LContent: TContent;
begin
  if FHeightAnimation <> nil then
    Exit;

  FHeightAnimation := TFloatAnimation.Create(Self);

  // TExpander.DoAddObject moves every object that is added to the control into
  // its content layout. The animation would become a child of the content and
  // would change the height of the content, not the one of the control, so the
  // redirection is switched off while the animation is added.
  LContent := FContent;
  FContent := nil;
  try
    FHeightAnimation.Parent := Self;
  finally
    FContent := LContent;
  end;

  FHeightAnimation.PropertyName := 'Height';
  FHeightAnimation.Interpolation := TInterpolationType.Sinusoidal;
  FHeightAnimation.AnimationType := TAnimationType.InOut;
  FHeightAnimation.OnFinish := HeightAnimationFinished;
end;

procedure TS4YExpander.AnimateToHeight(const AStartHeight, ATargetHeight: Single);
begin
  EnsureHeightAnimation;

  // An animation still running is stopped where it is (its end restores the state
  // that is set up again below)
  FHeightAnimation.StopAtCurrent;

  // While the height changes the content has to stay visible and must not draw
  // outside the control: the base class hides or shows it at once
  FIsAnimatingHeight := True;
  FSavedClipChildren := ClipChildren;
  ClipChildren := True;

  if FContent <> nil then
    FContent.Visible := True;

  // The base class has already set Height to the final value: go back to the start
  Height := AStartHeight;
  FHeightAnimation.Duration := FAnimationDuration;
  FHeightAnimation.StartValue := AStartHeight;
  FHeightAnimation.StopValue := ATargetHeight;
  FHeightAnimation.Start;
end;

procedure TS4YExpander.HeightAnimationFinished(Sender: TObject);
begin
  FIsAnimatingHeight := False;
  ClipChildren := FSavedClipChildren;

  if FContent <> nil then
    FContent.Visible := IsExpanded;
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
