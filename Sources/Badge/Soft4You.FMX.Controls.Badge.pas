unit Soft4You.FMX.Controls.Badge;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YBadge - notification badge counter
  Original author: Carlo Marona (Soft4You) - 2023-2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{ * S4YBadge control *

  Implement a badge similar to smartphone notification badge counter.
  If the counter value is 0 the badge will hide.
  If the counter value is > 0 the badge displays a circle containig the counter value number.
  Color of the badge and font can be customized.
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  FMX.StdCtrls,
  FMX.Types,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Objects,
  FMX.Controls.Model,
  FMX.Graphics;


type
  TS4YBadgeStyle = (
    bdgsNumeric,        // Only current value is displayed if it's > 0. Max value property, controls the max value displayed
    bdgsText            // Only text value is displayed if <> EmptyStr
  );

  // Used for autopositioning of the badge control relative to ParentControl
  TS4YBadgeAutoPosition = (
    bdgpNone,                                          // No automatic positioning
    bdgpUpLeft, bdgpUpCenter, bdgpUpRight,
    bdgpCenterLeft, bdgpCenter, bdgpCenterRight,
    bdgpBottomLeft, bdgpBottomCenter, bdgpBottomRight
  );

  // Used for the offset of position relative to ParentControl edges
  TS4YBadgePositionOffset = (
    bdpoInner,          // Positioning is made inner bounding edges
    bdpoEdge,           // Positioning is made over bounding edges
    bdpoOuter           // Positioning is made outer bounding edges
  );

  // Brushes of the badge background that come from the style instead of the Fill/Stroke properties
  TS4YBadgeStyledBrush = (
    bdgbFill,           // The background fill is the one defined by the style
    bdgbStroke          // The background border is the one defined by the style
  );
  TS4YBadgeStyledBrushes = set of TS4YBadgeStyledBrush;

  // Used internally to trace blink state
  TS4YBadgeBlinkState = (
    bbsVisible,         // The badge control is visible
    bbsHidden           // The badge control is hidden
  );


  TS4YBadge = class;


  // Manage blink settings
  TS4YBadgeBlinkSettings = class(TPersistent)
  public const
    C_DEFAULT_ENABLED = False;
    C_DEFAULT_INTERVAL = 1000;
  private
    FEnabled: Boolean;
    FInterval: Integer;
    FOnChange: TNotifyEvent;
    procedure DoChange;
    procedure SetEnabled(const Value: Boolean);
    procedure SetInterval(const Value: Integer);
  public
    constructor Create;

    procedure Assign(Source: TPersistent); override;
    procedure SetDefaultValues;
  published
    property Interval: Integer read FInterval write SetInterval default C_DEFAULT_INTERVAL;
    property Enabled: Boolean read FEnabled write SetEnabled default C_DEFAULT_ENABLED;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  // Manage positioning settings included auto positioning
  TS4YBadgePosition = class(TPersistent)
  public const
    C_DEFAULT_POSITION = bdgpNone;
    C_DEFAULT_OFFSET_X = bdpoEdge;
    C_DEFAULT_OFFSET_Y = bdpoEdge;
  private
    FOffsetX: TS4YBadgePositionOffset;
    FAutoPosition: TS4YBadgeAutoPosition;
    FOnChange: TNotifyEvent;
    FOffsetY: TS4YBadgePositionOffset;
    procedure SetOffsetX(const Value: TS4YBadgePositionOffset);
    procedure SetAutoPosition(const Value: TS4YBadgeAutoPosition);
    procedure SetOffsetY(const Value: TS4YBadgePositionOffset);
  protected
    procedure DoChange;
  public
    constructor Create;

    procedure Assign(Source: TPersistent); override;
    procedure SetDefaultValues;
  published
    property AutoPosition: TS4YBadgeAutoPosition read FAutoPosition write SetAutoPosition default C_DEFAULT_POSITION;
    property OffsetX: TS4YBadgePositionOffset read FOffsetX write SetOffsetX default C_DEFAULT_OFFSET_X;
    property OffsetY: TS4YBadgePositionOffset read FOffsetY write SetOffsetY default C_DEFAULT_OFFSET_Y;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;


  TS4YBadge = class(TStyledControl, ITextSettings)
  public const
    C_DEFAULT_BORDER_COLOR: TAlphaColor = $FFFFFFFF;
    C_DEFAULT_BORDER_KIND: TBrushKind = TBrushKind.Solid;
    C_DEFAULT_BORDER_THICKNESS: Single = 1;
    C_DEFAULT_BACKGROUND_COLOR: TAlphaColor = $FFFF0000;
    C_DEFAULT_BACKGROUND_KIND: TBrushKind = TBrushKind.Solid;
    C_DEFAULT_TEXT_COLOR: TAlphacolor = $FFFFFFFF;
    C_DEFAULT_SIZE: Single = 20;
    C_DEFAULT_MAX_VALUE = 99;
    C_DEFAULT_BADGE_STYLE = bdgsNumeric;
    C_DEFAULT_AUTO_RADIUS = True;
    C_DEFAULT_STYLED_BRUSHES: TS4YBadgeStyledBrushes = [bdgbFill, bdgbStroke];
  private
    FBackgroundStyleControl: TRectangle;
    FBackgroundFill: TBrush;
    FBackgroundStroke: TStrokeBrush;
    FBadgeStyle: TS4YBadgeStyle;
    FBlinkSettings: TS4YBadgeBlinkSettings;
    FBlinkState: TS4YBadgeBlinkState;
    FBlinkTimer: TTimer;
    FCurrentValue: integer;
    FMaxValue: integer;
    FText: String;
    FTextStyleControl: TText;
    FTextSettingsInfo: TTextSettingsInfo;
    FAutoPosition: TS4YBadgePosition;
    FAutoRadius: Boolean;
    FStyledBrushes: TS4YBadgeStyledBrushes;
    FUpdatingBrushes: Boolean;
    procedure BackgroundFillChanged(Sender: TObject);
    procedure BackgroundStrokeChanged(Sender: TObject);
    procedure InternalAdjustSize;
    procedure InternalAdjustPositioning;
    procedure DoBlink;
    procedure BlinkTimerEvent(Sender: TObject);
    function CalcPositionPoint: TPointF;
    procedure SetCurrentValue(const Value: integer);
    procedure SetText(const Value: String);
    function GetBadgeVisible: Boolean;
    procedure SetBadgeStyle(const Value: TS4YBadgeStyle);
    procedure SetMaxValue(const Value: integer);
    function GetTextSettings: TTextSettings;
    procedure SetTextSettings(const Value: TTextSettings);
    function GetDefaultTextSettings: TTextSettings;
    function GetStyledSettings: TStyledSettings;
    function GetResultingTextSettings: TTextSettings;
    function GetCurrentValueAsString: string;
    function GetCurrentText: string;
    procedure SetStyledSettings(const Value: TStyledSettings);
    function StyledSettingsStored: Boolean;
    procedure ReapplyStyle;
    procedure SetAutoRadius(const Value: Boolean);
    procedure SetStyledBrushes(const Value: TS4YBadgeStyledBrushes);
    function StyledBrushesStored: Boolean;
    procedure UpdateBackground;
    procedure UpdateCornerRadius;
    procedure UpdateVisibleState;
    procedure UpdateText;
    procedure SetBackgroundFill(const Value: TBrush);
    procedure SetBackgroundStroke(const Value: TStrokeBrush);
    procedure SetDefaultFill;
    procedure SetDefaultStroke;
    procedure SetBlinkSettings(const Value: TS4YBadgeBlinkSettings);
    procedure SetAutoPosition(const Value: TS4YBadgePosition);
    procedure PositionChanged(Sender: TObject);
    procedure BlinkSettingsChangedHandler(Sender: TObject);
  protected
    procedure ApplyStyle; override;
    procedure DoResized; override;
    procedure FreeStyle; override;
    function GetDefaultSize: TSizeF; override;
    function GetStyleObject: TFmxObject; override;
    function GetTextSettingsClass: TTextSettingsInfo.TCustomTextSettingsClass; virtual;
    procedure Loaded; override;

    property BadgeVisible: Boolean read GetBadgeVisible;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure BlinkSettingsChanged; virtual;
    procedure ResultTextSettingsChanged; virtual;

    property DefaultTextSettings: TTextSettings read GetDefaultTextSettings;
    property ResultingTextSettings: TTextSettings read GetResultingTextSettings;
  published
    property Anchors;
    property Align;
    property AutoPosition: TS4YBadgePosition read FAutoPosition write SetAutoPosition;
    property AutoRadius: Boolean read FAutoRadius write SetAutoRadius default C_DEFAULT_AUTO_RADIUS;
    property Fill: TBrush read FBackgroundFill write SetBackgroundFill;
    property BadgeStyle: TS4YBadgeStyle read FBadgeStyle write SetBadgeStyle default C_DEFAULT_BADGE_STYLE;
    property BlinkSettings: TS4YBadgeBlinkSettings read FBlinkSettings write SetBlinkSettings;
    property CurrentValue: integer read FCurrentValue write SetCurrentValue default 0;
    property Height;
    property HitTest;
    property Margins;
    property MaxValue: integer read FMaxValue write SetMaxValue default C_DEFAULT_MAX_VALUE;
    property Opacity;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Size;
    property StyledSettings: TStyledSettings read GetStyledSettings write SetStyledSettings stored StyledSettingsStored nodefault;
    property StyleLookup;
    property Stroke: TStrokeBrush read FBackgroundStroke write SetBackgroundStroke;
    // Must stay after Fill and Stroke: while streaming, modifying them switches the matching brush
    // off, so an explicit StyledBrushes stored in the form has to be read last to win.
    property StyledBrushes: TS4YBadgeStyledBrushes read FStyledBrushes write SetStyledBrushes stored StyledBrushesStored nodefault;
    property Text: String read FText write SetText;
    property TextSettings: TTextSettings read GetTextSettings write SetTextSettings;
    property Visible;
    property Width;
  end;



implementation

uses
  FMX.Styles;


{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}






type
  TS4YBadgeTextSettingsInfo = class(TTextSettingsInfo)
  private
    [Weak] FBadge: TS4YBadge;
  protected
    procedure DoCalculatedTextSettings; override;
  public
    constructor Create(AOwner: TPersistent; ATextSettingsClass: TTextSettingsInfo.TCustomTextSettingsClass); override;
    property Badge: TS4YBadge read FBadge;
  end;

  TS4YBadgeTextSettings = class (TTextSettingsInfo.TCustomTextSettings)
  public
    constructor Create(const AOwner: TPersistent); override;
  published
    property Font;
    property FontColor;
    property HorzAlign default TTextAlign.Leading;
  end;



const
  C_STYLE_BACKGROUND = 'background'; // Not localize
  C_STYLE_TEXT= 'text';              // Not localize



{ TS4YBadge }

procedure TS4YBadge.InternalAdjustSize;
var
  LTextWidth: single;
  LCurrentText: string;
begin
  if not Assigned(FTextStyleControl) then
    Exit;

  LCurrentText := GetCurrentText;
  LTextWidth := FTextStyleControl.Canvas.TextWidth(LCurrentText) +
   FBackgroundStyleControl.Padding.Left + FBackgroundStyleControl.Padding.Right;

  // Never narrower than tall, so a short text still gives a circle; a longer text widens the badge.
  if LTextWidth < Size.Height then
    Size.Width := Size.Height
  else
    Size.Width := LTextWidth;
end;

procedure TS4YBadge.InternalAdjustPositioning;
var
  LPositionPoint: TPointF;
begin
  LPositionPoint := CalcPositionPoint;
  Position.Point := LPositionPoint;
end;

procedure TS4YBadge.ApplyStyle;
begin
  inherited;

  FindStyleResource<TRectangle>(C_STYLE_BACKGROUND, FBackgroundStyleControl);
  FindStyleResource<TText>(C_STYLE_TEXT, FTextStyleControl);

  UpdateBackground;
  UpdateText;
  UpdateVisibleState;
end;

procedure TS4YBadge.DoResized;
begin
  inherited;

  UpdateCornerRadius;
end;

procedure TS4YBadge.PositionChanged(Sender: TObject);
begin
  InternalAdjustPositioning;
end;

procedure TS4YBadge.BackgroundFillChanged(Sender: TObject);
begin
  if FUpdatingBrushes then
    Exit;

  // Any change of Fill means a color of its own is wanted instead of the style's one.
  Exclude(FStyledBrushes, bdgbFill);
  UpdateBackground;
end;

procedure TS4YBadge.BackgroundStrokeChanged(Sender: TObject);
begin
  if FUpdatingBrushes then
    Exit;

  Exclude(FStyledBrushes, bdgbStroke);
  UpdateBackground;
end;

procedure TS4YBadge.BlinkSettingsChangedHandler(Sender: TObject);
begin
  BlinkSettingsChanged;
end;

procedure TS4YBadge.BlinkSettingsChanged;
begin
  FBlinkTimer.Enabled := False;
  FBlinkTimer.Interval := BlinkSettings.Interval;
  FBlinkTimer.Enabled := BlinkSettings.Enabled;
  FBlinkState := bbsVisible;
  UpdateVisibleState;
end;

procedure TS4YBadge.BlinkTimerEvent(Sender: TObject);
begin
  FBlinkTimer.Enabled := False;

  DoBlink;

  FBlinkTimer.Enabled := BlinkSettings.Enabled;
end;

function TS4YBadge.CalcPositionPoint: TPointF;
begin
  if not Assigned(ParentControl) then
    Exit;

  Result := inherited Position.Point;

  if AutoPosition.AutoPosition = bdgpNone then
    Exit;

  // Calc X coordinate
  case AutoPosition.AutoPosition of
    bdgpUpLeft, bdgpCenterLeft, bdgpBottomLeft:
    begin
      case AutoPosition.OffsetX of
        bdpoInner: Result.X := 0;
        bdpoEdge: Result.X := -(Size.Width / 2);
        bdpoOuter: Result.X := -Size.Width;
      end;
    end;
    bdgpUpCenter, bdgpCenter, bdgpBottomCenter: Result.X := (ParentControl.Width / 2) - (Size.Width / 2);
    bdgpUpRight, bdgpCenterRight, bdgpBottomRight:
    begin
      case AutoPosition.OffsetX of
        bdpoInner: Result.X := ParentControl.Width - Size.Width;
        bdpoEdge: Result.X := ParentControl.Width - (Size.Width / 2);
        bdpoOuter: Result.X := ParentControl.Width + 1;
      end;
    end;
  end;

  // Calc Y coordinate
  case AutoPosition.AutoPosition of
    bdgpUpLeft, bdgpUpCenter, bdgpUpRight:
    begin
      case AutoPosition.OffsetY of
        bdpoInner: Result.Y := 0;
        bdpoEdge: Result.Y := -(Size.Height / 2);
        bdpoOuter: Result.Y := -Size.Height;
      end;
    end;
    bdgpCenterLeft, bdgpCenter, bdgpCenterRight: Result.Y := (ParentControl.Height / 2) - (Size.Height / 2);
    bdgpBottomLeft, bdgpBottomCenter, bdgpBottomRight:
    begin
      case AutoPosition.OffsetY of
        bdpoInner: Result.Y := ParentControl.Height - Size.Height;
        bdpoEdge: Result.Y := ParentControl.Height - (Size.Height / 2);
        bdpoOuter: Result.Y := ParentControl.Height + 1;
      end;
    end;
  end;
end;

constructor TS4YBadge.Create(AOwner: TComponent);
begin
  inherited;

  FBackgroundStyleControl := nil;
  FTextStyleControl := nil;

  FBlinkTimer := TTimer.Create(nil);
  FBlinkTimer.OnTimer := BlinkTimerEvent;

  FTextSettingsInfo := TS4YBadgeTextSettingsInfo.Create(Self, GetTextSettingsClass);
  FTextSettingsInfo.DefaultTextSettings.FontColor := C_DEFAULT_TEXT_COLOR;

  FBackgroundFill := TBrush.Create(C_DEFAULT_BACKGROUND_KIND, C_DEFAULT_BACKGROUND_COLOR);
  FBackgroundStroke := TStrokeBrush.Create(C_DEFAULT_BORDER_KIND, C_DEFAULT_BORDER_COLOR);
  FStyledBrushes := C_DEFAULT_STYLED_BRUSHES;
  FAutoRadius := C_DEFAULT_AUTO_RADIUS;

  // Assigned only now: the initial values above are not a customization of the brushes.
  FBackgroundFill.OnChanged := BackgroundFillChanged;
  FBackgroundStroke.OnChanged := BackgroundStrokeChanged;

  FBlinkSettings := TS4YBadgeBlinkSettings.Create;
  FBlinkSettings.OnChange := BlinkSettingsChangedHandler;
  FBlinkState := bbsVisible;

  FAutoPosition := TS4YBadgePosition.Create;
  FAutoPosition.OnChange := PositionChanged;

  FBadgeStyle := C_DEFAULT_BADGE_STYLE;
  FText := EmptyStr;
  FMaxValue := C_DEFAULT_MAX_VALUE;
  FCurrentValue := 0;
end;

destructor TS4YBadge.Destroy;
begin
  FBlinkTimer.Enabled := False;
  FBackgroundFill.Free;
  FBackgroundStroke.Free;
  FBlinkSettings.Free;

  FreeAndNil(FTextSettingsInfo);
  FreeAndNil(FBlinkTimer);

  FreeAndNil(FAutoPosition);

  inherited;
end;

procedure TS4YBadge.DoBlink;
begin
  // Blink only if value > 0 and Badgestyle = bdgsNumeric
  // or if BadgeStyle = bdgsText

  if not (((BadgeStyle = bdgsNumeric) and (CurrentValue > 0)) or (BadgeStyle = bdgsText)) then
    Exit;

  case FBlinkState of
    bbsVisible:
    begin
      FBlinkState := bbsHidden;
    end;
    bbsHidden:
    begin
      FBlinkState := bbsVisible;
    end;
  end;

  UpdateVisibleState;
end;

procedure TS4YBadge.FreeStyle;
begin
  FBlinkTimer.Enabled := False;

  FBackgroundStyleControl := nil;
  FTextStyleControl := nil;
  inherited;
end;

function TS4YBadge.GetBadgeVisible: Boolean;
begin
  Result := (FBlinkState = bbsVisible) and (((BadgeStyle = bdgsNumeric) and (CurrentValue > 0)) or
    ((BadgeStyle = bdgsText) and (Text <> String.Empty)));
end;

function TS4YBadge.GetCurrentText: string;
begin
  case BadgeStyle of
    bdgsNumeric: Result := GetCurrentValueAsString;
    bdgsText: Result := Text;
  end;
end;

function TS4YBadge.GetCurrentValueAsString: string;
begin
  if FCurrentValue > FMaxValue then
    Result := Format('%d+', [FMaxValue])
  else
    Result := IntToStr(FCurrentValue);
end;

function TS4YBadge.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(16, 16);
end;

function TS4YBadge.GetDefaultTextSettings: TTextSettings;
begin
  Result := FTextSettingsInfo.DefaultTextSettings;
end;

function TS4YBadge.GetResultingTextSettings: TTextSettings;
begin
  Result := FTextSettingsInfo.ResultingTextSettings;
end;

function TS4YBadge.GetStyledSettings: TStyledSettings;
begin
  Result := FTextSettingsInfo.StyledSettings;
end;

function TS4YBadge.GetStyleObject: TFmxObject;
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

function TS4YBadge.GetTextSettings: TTextSettings;
begin
  Result := FTextSettingsInfo.TextSettings;
end;

function TS4YBadge.GetTextSettingsClass: TTextSettingsInfo.TCustomTextSettingsClass;
begin
  Result := TS4YBadgeTextSettings;
end;

procedure TS4YBadge.Loaded;
begin
  inherited;

  if not (csDesigning in ComponentState) then
    BlinkSettingsChanged;
end;

procedure TS4YBadge.ResultTextSettingsChanged;
begin

end;

procedure TS4YBadge.SetBackgroundFill(const Value: TBrush);
begin
  if Assigned(Value) then
    FBackgroundFill.Assign(Value)
  else
    SetDefaultFill;

  UpdateBackground;
end;

procedure TS4YBadge.SetBackgroundStroke(const Value: TStrokeBrush);
begin
  if Assigned(Value) then
    FBackgroundStroke.Assign(Value)
  else
    SetDefaultStroke;

  UpdateBackground;
end;

procedure TS4YBadge.SetBadgeStyle(const Value: TS4YBadgeStyle);
begin
  if FBadgeStyle = Value then
    Exit;

  FBadgeStyle := Value;
  UpdateText;
end;

procedure TS4YBadge.SetBlinkSettings(const Value: TS4YBadgeBlinkSettings);
begin
  if Assigned(Value) then
    FBlinkSettings.Assign(Value)
  else
    FBlinkSettings.SetDefaultValues;
end;

procedure TS4YBadge.SetCurrentValue(const Value: integer);
begin
  if FCurrentValue = Value then
    Exit;

  FCurrentValue := Value;
  UpdateText;
  UpdateVisibleState;
end;

procedure TS4YBadge.SetDefaultFill;
begin
  FUpdatingBrushes := True;
  try
    FBackgroundFill.Color := C_DEFAULT_BACKGROUND_COLOR;
  finally
    FUpdatingBrushes := False;
  end;

  // Back to the default means back to the style's own fill.
  if not (bdgbFill in FStyledBrushes) then
  begin
    Include(FStyledBrushes, bdgbFill);
    ReapplyStyle;
  end;
end;

procedure TS4YBadge.SetDefaultStroke;
begin
  FUpdatingBrushes := True;
  try
    FBackgroundStroke.Color := C_DEFAULT_BORDER_COLOR;
    FBackgroundStroke.Kind := C_DEFAULT_BORDER_KIND;
  finally
    FUpdatingBrushes := False;
  end;

  if not (bdgbStroke in FStyledBrushes) then
  begin
    Include(FStyledBrushes, bdgbStroke);
    ReapplyStyle;
  end;
end;

procedure TS4YBadge.SetMaxValue(const Value: integer);
begin
  if FMaxValue = Value then
    Exit;

  FMaxValue := Value;
  UpdateText;
end;

procedure TS4YBadge.SetAutoPosition(const Value: TS4YBadgePosition);
begin
  FAutoPosition.Assign(Value);
end;

procedure TS4YBadge.SetAutoRadius(const Value: Boolean);
begin
  if FAutoRadius = Value then
    Exit;

  FAutoRadius := Value;

  if FAutoRadius then
    UpdateCornerRadius
  else
    ReapplyStyle;
end;

procedure TS4YBadge.SetStyledBrushes(const Value: TS4YBadgeStyledBrushes);
var
  LGivenBackToStyle: TS4YBadgeStyledBrushes;
begin
  if FStyledBrushes = Value then
    Exit;

  LGivenBackToStyle := Value - FStyledBrushes;
  FStyledBrushes := Value;

  // A brush handed back to the style has to be read again from it: the background control
  // still holds the color previously copied from the properties.
  if LGivenBackToStyle <> [] then
    ReapplyStyle
  else
    UpdateBackground;
end;

procedure TS4YBadge.ReapplyStyle;
begin
  if Assigned(FBackgroundStyleControl) then
  begin
    NeedStyleLookup;
    ApplyStyleLookup;
  end;
end;

function TS4YBadge.StyledBrushesStored: Boolean;
var
  LImplied: TS4YBadgeStyledBrushes;
begin
  // Streaming Fill/Stroke already switches the matching brush off by itself, so StyledBrushes is
  // only worth storing when it says something different from what that alone would give.
  LImplied := C_DEFAULT_STYLED_BRUSHES;

  if (FBackgroundFill.Kind <> C_DEFAULT_BACKGROUND_KIND) or
    (FBackgroundFill.Color <> C_DEFAULT_BACKGROUND_COLOR) then
    Exclude(LImplied, bdgbFill);

  if (FBackgroundStroke.Kind <> C_DEFAULT_BORDER_KIND) or
    (FBackgroundStroke.Color <> C_DEFAULT_BORDER_COLOR) or
    (FBackgroundStroke.Thickness <> C_DEFAULT_BORDER_THICKNESS) or
    (FBackgroundStroke.Dash <> TStrokeDash.Solid) or
    (FBackgroundStroke.Cap <> TStrokeCap.Flat) or
    (FBackgroundStroke.Join <> TStrokeJoin.Miter) then
    Exclude(LImplied, bdgbStroke);

  Result := FStyledBrushes <> LImplied;
end;

procedure TS4YBadge.SetStyledSettings(const Value: TStyledSettings);
begin
  FTextSettingsInfo.StyledSettings := Value;
end;

procedure TS4YBadge.SetText(const Value: String);
begin
  if SameText(FText, Value) then
    Exit;

  FText := Value;
  UpdateText;
end;

procedure TS4YBadge.SetTextSettings(const Value: TTextSettings);
begin
  FTextSettingsInfo.TextSettings := Value;
end;

function TS4YBadge.StyledSettingsStored: Boolean;
begin
  Result := StyledSettings <> DefaultStyledSettings;
end;

procedure TS4YBadge.UpdateBackground;
begin
  inherited;

  if Assigned(FBackgroundStyleControl) then
  begin
    // Brushes flagged as styled keep whatever the style defines
    if not (bdgbFill in FStyledBrushes) then
      FBackgroundStyleControl.Fill.Assign(FBackgroundFill);

    if not (bdgbStroke in FStyledBrushes) then
      FBackgroundStyleControl.Stroke.Assign(FBackgroundStroke);

    UpdateCornerRadius;
  end;
end;

procedure TS4YBadge.UpdateCornerRadius;
begin
  if not FAutoRadius then
    Exit;

  if Assigned(FBackgroundStyleControl) then
  begin
    FBackgroundStyleControl.XRadius := Height / 2;
    FBackgroundStyleControl.YRadius := Height / 2;
  end;
end;

procedure TS4YBadge.UpdateText;
begin
  if Assigned(FTextStyleControl) then
  begin
    FTextStyleControl.Text := GetCurrentText;

    // Adapt width and position to text size
    InternalAdjustSize;
    InternalAdjustPositioning;
  end;
end;

procedure TS4YBadge.UpdateVisibleState;
begin
  if not (csDesigning in ComponentState) then
  begin
    if Assigned(FTextStyleControl) then
      FTextStyleControl.Visible := BadgeVisible;

    if Assigned(FBackgroundStyleControl) then
      FBackgroundStyleControl.Visible := BadgeVisible;
  end
  else
  begin
    if Assigned(FTextStyleControl) then
      FTextStyleControl.Visible := True;

    if Assigned(FBackgroundStyleControl) then
      FBackgroundStyleControl.Visible := True;
  end;
end;

{ TS4YBadgeTextSettings }

constructor TS4YBadgeTextSettings.Create(const AOwner: TPersistent);
begin
  inherited;

  WordWrap := False;
  HorzAlign := TTextAlign.Center;
  FontColor := TS4YBadge.C_DEFAULT_TEXT_COLOR;
end;

{ TS4YBadgeTextSettingsInfo }

constructor TS4YBadgeTextSettingsInfo.Create(AOwner: TPersistent;
  ATextSettingsClass: TTextSettingsInfo.TCustomTextSettingsClass);
begin
  inherited;

  if AOwner is TS4YBadge then
    FBadge := TS4YBadge(AOwner)
  else
    raise EArgumentException.CreateFMT('Error: %s', [TS4YBadge.ClassName]);
end;

procedure TS4YBadgeTextSettingsInfo.DoCalculatedTextSettings;
begin
  FBadge.ResultTextSettingsChanged;
  inherited;
end;


{ TS4YBadgeBlinkSettings }

constructor TS4YBadgeBlinkSettings.Create;
begin
  inherited Create;

  FInterval := C_DEFAULT_INTERVAL;
  FEnabled := C_DEFAULT_ENABLED;
end;

procedure TS4YBadgeBlinkSettings.Assign(Source: TPersistent);
var
  LSource: TS4YBadgeBlinkSettings;
begin
  if Source is TS4YBadgeBlinkSettings then
  begin
    LSource := TS4YBadgeBlinkSettings(Source);

    if (FEnabled <> LSource.Enabled) or (FInterval <> LSource.Interval) then
    begin
      FEnabled := LSource.Enabled;
      FInterval := LSource.Interval;
      DoChange;
    end;
  end
  else
    inherited Assign(Source);
end;

procedure TS4YBadgeBlinkSettings.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YBadgeBlinkSettings.SetDefaultValues;
begin
  FEnabled := C_DEFAULT_ENABLED;
  FInterval := C_DEFAULT_INTERVAL;
  DoChange;
end;

procedure TS4YBadgeBlinkSettings.SetEnabled(const Value: Boolean);
begin
  if FEnabled = Value then
    Exit;

  FEnabled := Value;
  DoChange;
end;

procedure TS4YBadgeBlinkSettings.SetInterval(const Value: Integer);
begin
  if FInterval = Value then
    Exit;

  FInterval := Value;
  DoChange;
end;

{ TS4YBadgePositionSettings }

constructor TS4YBadgePosition.Create;
begin
  inherited;

  FAutoPosition := C_DEFAULT_POSITION;
  FOffsetX := C_DEFAULT_OFFSET_X;
  FOffsetY := C_DEFAULT_OFFSET_Y;
end;

procedure TS4YBadgePosition.Assign(Source: TPersistent);
var
  LSource: TS4YBadgePosition;
begin
  if Source is TS4YBadgePosition then
  begin
    LSource := TS4YBadgePosition(Source);

    if (FAutoPosition <> LSource.AutoPosition) or
      (FOffsetX <> LSource.OffsetX) or
      (FOffsetY <> LSource.OffsetY) then
    begin
      FAutoPosition := LSource.AutoPosition;
      FOffsetX := LSource.OffsetX;
      FOffsetY := LSource.OffsetY;
      DoChange;
    end;
  end
  else
    inherited Assign(Source);
end;

procedure TS4YBadgePosition.SetDefaultValues;
begin
  FAutoPosition := C_DEFAULT_POSITION;
  FOffsetX := C_DEFAULT_OFFSET_X;
  FOffsetY := C_DEFAULT_OFFSET_Y;
  DoChange;
end;

procedure TS4YBadgePosition.SetOffsetX(
  const Value: TS4YBadgePositionOffset);
begin
  if FOffsetX = Value then
    Exit;

  FOffsetX := Value;
  DoChange;
end;

procedure TS4YBadgePosition.SetOffsetY(const Value: TS4YBadgePositionOffset);
begin
  if FOffsetY = Value then
    Exit;

  FOffsetY := Value;
  DoChange;
end;

procedure TS4YBadgePosition.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YBadgePosition.SetAutoPosition(const Value: TS4YBadgeAutoPosition);
begin
  if FAutoPosition = Value then
    Exit;

  FAutoPosition := Value;
  DoChange;
end;

initialization
  RegisterFmxClasses([TS4YBadge]);
//  RegisterFmxClasses([TS4YBadgeBlinkSettings]);

end.
