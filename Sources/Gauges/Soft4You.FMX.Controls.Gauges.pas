unit Soft4You.FMX.Controls.Gauges;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YCustomGauge - base class of the gauges
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Types,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.Objects,
  FMX.Ani,
  FMX.TextLayout,
  Soft4You.FMX.Controls.Gauges.Types;

type
  /// <summary>
  /// Base class of the gauges: a value in a range, drawn as a fill that grows along a track, with the value written and a caption.
  /// </summary>
  /// <remarks>
  /// The look comes from a style: its graphic parts track and fill can be any graphic object and are drawn as they are, resized to the area they cover; its texts valuetext and captiontext give fonts and colors.
  /// The descendants, TS4YLinearGauge and TS4YCircularGauge, decide the shape of the track and where the texts go. The class is not registered in the Tool Palette.
  /// The properties shared by the gauges are public, so that code can work on any gauge through this class.
  /// </remarks>
  TS4YCustomGauge = class(TStyledControl)
  public const
    /// <summary>Default value of AnimationDuration, in seconds.</summary>
    C_DEFAULT_ANIMATION_DURATION: Single = 0.3;
    /// <summary>Color of the caption when the style has no captiontext.</summary>
    C_DEFAULT_CAPTION_TEXT_COLOR: TAlphaColor = $FF616161;
    /// <summary>Default color of FillBrush.</summary>
    C_DEFAULT_FILL_COLOR: TAlphaColor = $FF1E88E5;
    /// <summary>Default value of Max.</summary>
    C_DEFAULT_MAX: Single = 100;
    /// <summary>Default value of Min.</summary>
    C_DEFAULT_MIN: Single = 0;
    /// <summary>Default value of ShowValue.</summary>
    C_DEFAULT_SHOW_VALUE = True;
    /// <summary>Default value of StyledBrushes: both brushes come from the style.</summary>
    C_DEFAULT_STYLED_BRUSHES: TS4YGaugeStyledBrushes = [gsbFill, gsbTrack];
    /// <summary>Default color of TrackBrush.</summary>
    C_DEFAULT_TRACK_COLOR: TAlphaColor = $FFE0E0E0;
    /// <summary>Default value of Value.</summary>
    C_DEFAULT_VALUE: Single = 0;
    /// <summary>Default value of ValueFormat: the value without decimals.</summary>
    C_DEFAULT_VALUE_FORMAT = '%.0f';
    /// <summary>Color of the value when the style has no valuetext.</summary>
    C_DEFAULT_VALUE_TEXT_COLOR: TAlphaColor = $FF212121;
  private
    FAnimation: TAnimation;
    FAnimationDuration: Single;
    FCaption: string;
    FDefaultFont: TFont;
    FDisplayedValue: Single;
    FFillBrush: TBrush;
    FFillPart: TControl;
    FMax: Single;
    FMin: Single;
    FPartsContainer: TControl;
    FShowValue: Boolean;
    FStyleCaptionText: TText;
    FStyleValueText: TText;
    FStyledBrushes: TS4YGaugeStyledBrushes;
    FTextLayout: TTextLayout;
    FThickness: Single;
    FTrackBrush: TBrush;
    FTrackPart: TControl;
    FValue: Single;
    FValueFormat: string;
    FOnGetValueText: TS4YGaugeGetValueTextEvent;
    procedure AnimateValue;
    function AnimationDurationStored: Boolean;
    procedure BrushesChanged;
    function CreateGaugePart(const AStyleName: string; const AStyledBrush: TS4YGaugeStyledBrush;
      const ABrush: TBrush): TControl;
    function CreatePart(const AStyleName: string; out FromStyle: Boolean): TControl;
    procedure EnsureParts;
    procedure FillBrushChanged(Sender: TObject);
    function FormatValue(const AValue: Single): string;
    procedure FreeParts;
    function IsAnimating: Boolean;
    function MaxStored: Boolean;
    function MinStored: Boolean;
    procedure PrepareTextLayout(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string;
      const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign);
    procedure RangeChanged;
    procedure SetAnimationDuration(const Value: Single);
    procedure SetCaption(const Value: string);
    procedure SetDisplayedValue(const Value: Single);
    procedure SetFillBrush(const Value: TBrush);
    procedure SetMax(const Value: Single);
    procedure SetMin(const Value: Single);
    procedure SetShowValue(const Value: Boolean);
    procedure SetStyledBrushes(const Value: TS4YGaugeStyledBrushes);
    procedure SetThickness(const Value: Single);
    procedure SetTrackBrush(const Value: TBrush);
    procedure SetValue(const Value: Single);
    procedure SetValueFormat(const Value: string);
    procedure StopAnimation;
    function StyledBrushesStored: Boolean;
    function ThicknessStored: Boolean;
    procedure TrackBrushChanged(Sender: TObject);
    function ValueFormatStored: Boolean;
    function ValueStored: Boolean;
  protected
    /// <summary>Gives ABrush to a part that is not taken as it is from the style: the fill of a shape.</summary>
    procedure ApplyPartBrush(const APart: TControl; const ABrush: TBrush); virtual;
    /// <summary>Finds the texts of the style and prepares the graphic parts again.</summary>
    procedure ApplyStyle; override;
    /// <summary>Creates the part drawn when the style has no track or no fill: a rectangle without border.</summary>
    function CreateDefaultPart: TControl; virtual;
    /// <summary>Fires OnGetValueText.</summary>
    procedure DoGetValueText(const AValue: Single; var AText: string); virtual;
    /// <summary>Draws the track, the fill and the texts in the area of the content.</summary>
    procedure DrawGauge; virtual; abstract;
    /// <summary>Draws a copy of a part of the style resized to ARect, in the coordinates of the control.</summary>
    procedure DrawPart(const APart: TControl; const ARect: TRectF);
    /// <summary>Releases the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the area of the control inside Padding.</summary>
    function GetContentRect: TRectF;
    /// <summary>Returns the default value of Thickness.</summary>
    function GetDefaultThickness: Single; virtual; abstract;
    /// <summary>Returns the part of the range covered by the value drawn, from 0 to 1.</summary>
    function GetDisplayedFraction: Single;
    /// <summary>Returns the style of the control: the one named by StyleLookup or, when it is empty, the one named after the class in the style book or in the active style; else the default style linked into the package.</summary>
    function GetStyleObject: TFmxObject; override;
    /// <summary>Returns the text of the value drawn: ValueFormat applied to it, then OnGetValueText. Empty when ShowValue is False.</summary>
    function GetValueText: string;
    /// <summary>Brings Min, Max and Value back into a coherent range after loading.</summary>
    procedure Loaded; override;
    /// <summary>Returns the width and the height of AText written with the font of ATemplate, or with the default font and ADefaultColor when ATemplate is nil.</summary>
    function MeasureText(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string): TSizeF;
    /// <summary>Draws the gauge.</summary>
    procedure Paint; override;
    /// <summary>Writes AText in ARect on one line, with the font of ATemplate, or with the default font and ADefaultColor when ATemplate is nil.</summary>
    procedure RenderText(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string;
      const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign);

    /// <summary>The copy of the fill part of the style that the control draws.</summary>
    property FillPart: TControl read FFillPart;
    /// <summary>The text of the style that gives font and color to the caption, or nil.</summary>
    property StyleCaptionText: TText read FStyleCaptionText;
    /// <summary>The text of the style that gives font and color to the value, or nil.</summary>
    property StyleValueText: TText read FStyleValueText;
    /// <summary>The copy of the track part of the style that the control draws.</summary>
    property TrackPart: TControl read FTrackPart;
  public
    /// <summary>Creates the gauge with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// Duration in seconds of the movement of the fill when Value changes by more than 5% of the range. With 0 the change is immediate. The default is 0.3.
    /// </summary>
    /// <remarks>
    /// A smaller change is drawn at once, so that the fill follows a value that changes often; a change while the fill is moving starts from where it is.
    /// </remarks>
    property AnimationDuration: Single read FAnimationDuration write SetAnimationDuration stored AnimationDurationStored nodefault;
    /// <summary>Text that describes the value, for example Download or CPU.</summary>
    property Caption: string read FCaption write SetCaption;
    /// <summary>Brush of the fill. Changing it makes the fill use it instead of the one of the style (see StyledBrushes).</summary>
    property FillBrush: TBrush read FFillBrush write SetFillBrush;
    /// <summary>
    /// The end of the range, where the fill is full. The default is 100.
    /// </summary>
    /// <remarks>
    /// A value lower than Min moves Min to it.
    /// </remarks>
    property Max: Single read FMax write SetMax stored MaxStored nodefault;
    /// <summary>
    /// The start of the range, where the fill is empty. The default is 0.
    /// </summary>
    /// <remarks>
    /// A value greater than Max moves Max to it.
    /// </remarks>
    property Min: Single read FMin write SetMin stored MinStored nodefault;
    /// <summary>True writes the value, formatted with ValueFormat. The default is True.</summary>
    property ShowValue: Boolean read FShowValue write SetShowValue default C_DEFAULT_SHOW_VALUE;
    /// <summary>
    /// Which brushes come from the style: the fill (gsbFill) and the track (gsbTrack). A brush that is not in the set is taken from FillBrush or TrackBrush.
    /// </summary>
    /// <remarks>
    /// Changing FillBrush or TrackBrush removes the matching brush from the set. Putting a brush back in the set makes the gauge read it from the style again.
    /// </remarks>
    property StyledBrushes: TS4YGaugeStyledBrushes read FStyledBrushes write SetStyledBrushes stored StyledBrushesStored nodefault;
    /// <summary>Thickness of the track and of the fill, in pixels.</summary>
    property Thickness: Single read FThickness write SetThickness stored ThicknessStored nodefault;
    /// <summary>Brush of the track. Changing it makes the track use it instead of the one of the style (see StyledBrushes).</summary>
    property TrackBrush: TBrush read FTrackBrush write SetTrackBrush;
    /// <summary>
    /// The value shown, from Min to Max. The default is 0.
    /// </summary>
    /// <remarks>
    /// A value out of the range is brought to Min or Max. A change of more than 5% of the range is animated in AnimationDuration.
    /// </remarks>
    property Value: Single read FValue write SetValue stored ValueStored nodefault;
    /// <summary>
    /// Format of the value, as for the Format function of Delphi with the value as its only argument. The default is %.0f, the value without decimals.
    /// </summary>
    /// <remarks>
    /// For example %.1f %% writes 42.5 %. A format that does not fit a floating point value is replaced by the default; an empty format writes nothing.
    /// </remarks>
    property ValueFormat: string read FValueFormat write SetValueFormat stored ValueFormatStored;

    /// <summary>Fires when the value is written, with the text formatted with ValueFormat, which the event can replace.</summary>
    property OnGetValueText: TS4YGaugeGetValueTextEvent read FOnGetValueText write FOnGetValueText;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  FMX.Styles;

type
  /// <summary>Animation that moves the value drawn by a gauge towards its Value.</summary>
  TS4YGaugeAnimation = class(TAnimation)
  private
    [Weak] FGauge: TS4YCustomGauge;
    FStartValue: Single;
    FTargetValue: Single;
  protected
    procedure ProcessAnimation; override;
  public
    constructor Create(const AGauge: TS4YCustomGauge); reintroduce;

    property StartValue: Single read FStartValue write FStartValue;
    property TargetValue: Single read FTargetValue write FTargetValue;
  end;

const
  C_STYLE_CAPTION_TEXT = 'captiontext';
  C_STYLE_FILL = 'fill';
  C_STYLE_TRACK = 'track';
  C_STYLE_VALUE_TEXT = 'valuetext';

  // Largest change of Value drawn at once, as a fraction of the range: a larger one is animated.
  C_ANIMATION_THRESHOLD = 0.05;
  // Width and height given to a text while it is measured: large enough for any value or caption.
  C_MEASURE_SIZE = 10000;

{ TS4YGaugeAnimation }

constructor TS4YGaugeAnimation.Create(const AGauge: TS4YCustomGauge);
begin
  inherited Create(AGauge);

  FGauge := AGauge;
end;

procedure TS4YGaugeAnimation.ProcessAnimation;
begin
  if Assigned(FGauge) then
    FGauge.SetDisplayedValue(FStartValue + (FTargetValue - FStartValue) * NormalizedTime);
end;

{ TS4YCustomGauge }

constructor TS4YCustomGauge.Create(AOwner: TComponent);
begin
  inherited;

  FAnimationDuration := C_DEFAULT_ANIMATION_DURATION;
  FMax := C_DEFAULT_MAX;
  FMin := C_DEFAULT_MIN;
  FShowValue := C_DEFAULT_SHOW_VALUE;
  FStyledBrushes := C_DEFAULT_STYLED_BRUSHES;
  FThickness := GetDefaultThickness;
  FValue := C_DEFAULT_VALUE;
  FDisplayedValue := C_DEFAULT_VALUE;
  FValueFormat := C_DEFAULT_VALUE_FORMAT;

  FFillBrush := TBrush.Create(TBrushKind.Solid, C_DEFAULT_FILL_COLOR);
  FTrackBrush := TBrush.Create(TBrushKind.Solid, C_DEFAULT_TRACK_COLOR);
  // Assigned only now: the initial values above are not a customization of the brushes.
  FFillBrush.OnChanged := FillBrushChanged;
  FTrackBrush.OnChanged := TrackBrushChanged;

  FDefaultFont := TFont.Create;
  FTextLayout := TTextLayoutManager.DefaultTextLayout.Create;

  // Holds the copies of the graphic parts of the style. It is a child of the control, so that the
  // parts belong to its scene and their own children are painted; it is invisible, so that resizing
  // a part does not ask for a repaint. Without owner and not stored, it is not part of the form.
  FPartsContainer := TControl.Create(nil);
  FPartsContainer.Stored := False;
  FPartsContainer.Visible := False;
  FPartsContainer.HitTest := False;
  FPartsContainer.Locked := True;
  FPartsContainer.Parent := Self;
end;

destructor TS4YCustomGauge.Destroy;
begin
  // Freed first, so that a running animation cannot touch the settings released below.
  FreeAndNil(FAnimation);
  FreeParts;
  FreeAndNil(FPartsContainer);
  FreeAndNil(FTextLayout);
  FreeAndNil(FDefaultFont);
  FreeAndNil(FFillBrush);
  FreeAndNil(FTrackBrush);

  inherited;
end;

procedure TS4YCustomGauge.AnimateValue;
var
  LAnimation: TS4YGaugeAnimation;
begin
  if not Assigned(FAnimation) then
  begin
    LAnimation := TS4YGaugeAnimation.Create(Self);
    LAnimation.Stored := False;
    LAnimation.Interpolation := TInterpolationType.Sinusoidal;
    LAnimation.AnimationType := TAnimationType.InOut;
    LAnimation.Parent := Self;
    FAnimation := LAnimation;
  end
  else
    LAnimation := TS4YGaugeAnimation(FAnimation);

  // A change during an animation starts from where the fill is now.
  LAnimation.StopAtCurrent;
  LAnimation.StartValue := FDisplayedValue;
  LAnimation.TargetValue := FValue;
  LAnimation.Duration := FAnimationDuration;
  LAnimation.Start;
end;

function TS4YCustomGauge.AnimationDurationStored: Boolean;
begin
  Result := not SameValue(FAnimationDuration, C_DEFAULT_ANIMATION_DURATION);
end;

procedure TS4YCustomGauge.ApplyPartBrush(const APart: TControl; const ABrush: TBrush);
begin
  if APart is TShape then
    TShape(APart).Fill.Assign(ABrush);
end;

procedure TS4YCustomGauge.ApplyStyle;
begin
  inherited;

  FindStyleResource<TText>(C_STYLE_VALUE_TEXT, FStyleValueText);
  FindStyleResource<TText>(C_STYLE_CAPTION_TEXT, FStyleCaptionText);

  // The graphic parts are copied from the new style the next time the control paints.
  FreeParts;
  Repaint;
end;

procedure TS4YCustomGauge.BrushesChanged;
begin
  // The brushes of the properties are applied to the parts when they are prepared again.
  FreeParts;
  Repaint;
end;

function TS4YCustomGauge.CreateDefaultPart: TControl;
var
  LRectangle: TRectangle;
begin
  LRectangle := TRectangle.Create(nil);
  LRectangle.Stroke.Kind := TBrushKind.None;
  Result := LRectangle;
end;

function TS4YCustomGauge.CreateGaugePart(const AStyleName: string; const AStyledBrush: TS4YGaugeStyledBrush;
  const ABrush: TBrush): TControl;
var
  LFromStyle: Boolean;
begin
  Result := CreatePart(AStyleName, LFromStyle);

  if not LFromStyle then
  begin
    Result := CreateDefaultPart;
    Result.Parent := FPartsContainer;
  end;

  if not LFromStyle or not (AStyledBrush in FStyledBrushes) then
    ApplyPartBrush(Result, ABrush);
end;

function TS4YCustomGauge.CreatePart(const AStyleName: string; out FromStyle: Boolean): TControl;
var
  LStylePart: TControl;
  LStylePartStored: Boolean;
begin
  Result := nil;
  FromStyle := FindStyleResource<TControl>(AStyleName, LStylePart);

  if not FromStyle then
    Exit;

  // A copy, so that it can be resized and recolored without touching the style. FMX marks the
  // objects of an applied style as not stored, and Clone copies through streaming: the part has to
  // be stored while it is copied, or the copy would lose its children.
  LStylePartStored := LStylePart.Stored;
  LStylePart.Stored := True;
  try
    Result := TControl(LStylePart.Clone(nil));
  finally
    LStylePart.Stored := LStylePartStored;
  end;

  // Clone reads the copy as stored, so the copy and its children with a StyleName are added to the
  // global list of the styles of FMX: setting Stored to False removes them from it, like the parts
  // copied by FMX itself.
  Result.Stored := False;
  Result.Visible := True;
  Result.Parent := FPartsContainer;
end;

procedure TS4YCustomGauge.DoGetValueText(const AValue: Single; var AText: string);
begin
  if Assigned(FOnGetValueText) then
    FOnGetValueText(Self, AValue, AText);
end;

procedure TS4YCustomGauge.DrawPart(const APart: TControl; const ARect: TRectF);
begin
  if not Assigned(APart) or (ARect.Width < 1) or (ARect.Height < 1) then
    Exit;

  // The part gets the size of the area, so that its borders keep their thickness instead of
  // being scaled; PaintTo with the control as parent draws it in the coordinates of the control.
  APart.SetBounds(0, 0, ARect.Width, ARect.Height);
  APart.PaintTo(Canvas, ARect, Self);
  Canvas.SetMatrix(AbsoluteMatrix);
end;

procedure TS4YCustomGauge.EnsureParts;
begin
  if Assigned(FTrackPart) then
    Exit;

  FTrackPart := CreateGaugePart(C_STYLE_TRACK, gsbTrack, FTrackBrush);
  FFillPart := CreateGaugePart(C_STYLE_FILL, gsbFill, FFillBrush);
end;

procedure TS4YCustomGauge.FillBrushChanged(Sender: TObject);
begin
  Exclude(FStyledBrushes, gsbFill);
  BrushesChanged;
end;

function TS4YCustomGauge.FormatValue(const AValue: Single): string;
begin
  try
    Result := Format(FValueFormat, [AValue]);
  except
    on EConvertError do
      Result := Format(C_DEFAULT_VALUE_FORMAT, [AValue]);
  end;
end;

procedure TS4YCustomGauge.FreeParts;
begin
  FreeAndNil(FTrackPart);
  FreeAndNil(FFillPart);
end;

procedure TS4YCustomGauge.FreeStyle;
begin
  FreeParts;
  FStyleValueText := nil;
  FStyleCaptionText := nil;

  inherited;
end;

function TS4YCustomGauge.GetContentRect: TRectF;
begin
  Result := Padding.PaddingRect(LocalRect);
end;

function TS4YCustomGauge.GetDisplayedFraction: Single;
begin
  if FMax - FMin <= 0 then
    Exit(0);

  Result := EnsureRange((FDisplayedValue - FMin) / (FMax - FMin), 0, 1);
end;

function TS4YCustomGauge.GetStyleObject: TFmxObject;
begin
  // Without StyleLookup only the style named after the class is searched, in the style book and
  // in the active style: the search of FMX would also take the style of the parent class.
  if StyleLookup <> '' then
    Result := inherited GetStyleObject
  else
    Result := LookupStyleObject(Self, GetStyleContext, Scene, '', GetDefaultStyleLookupName, '', True);

  // The style linked into the package is used when no other style is found.
  if not Assigned(Result) then
    Result := TStyleStreaming.LoadFromResource(HInstance, GetDefaultStyleLookupName, RT_RCDATA);
end;

function TS4YCustomGauge.GetValueText: string;
begin
  if not FShowValue then
    Exit('');

  Result := FormatValue(FDisplayedValue);
  DoGetValueText(FDisplayedValue, Result);
end;

function TS4YCustomGauge.IsAnimating: Boolean;
begin
  Result := Assigned(FAnimation) and FAnimation.Running;
end;

procedure TS4YCustomGauge.Loaded;
begin
  inherited;

  // Min, Max and Value are read one at a time: they can be checked only now.
  if FMax < FMin then
    FMax := FMin;

  FValue := EnsureRange(FValue, FMin, FMax);
  FDisplayedValue := FValue;
end;

function TS4YCustomGauge.MaxStored: Boolean;
begin
  Result := not SameValue(FMax, C_DEFAULT_MAX);
end;

function TS4YCustomGauge.MeasureText(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string): TSizeF;
begin
  if AText = '' then
    Exit(TSizeF.Create(0, 0));

  PrepareTextLayout(ATemplate, ADefaultColor, AText, TRectF.Create(0, 0, C_MEASURE_SIZE, C_MEASURE_SIZE),
    TTextAlign.Leading, TTextAlign.Leading);
  Result := TSizeF.Create(FTextLayout.TextWidth, FTextLayout.TextHeight);
end;

function TS4YCustomGauge.MinStored: Boolean;
begin
  Result := not SameValue(FMin, C_DEFAULT_MIN);
end;

procedure TS4YCustomGauge.Paint;
begin
  inherited;

  EnsureParts;
  DrawGauge;
end;

procedure TS4YCustomGauge.PrepareTextLayout(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string; const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign);
begin
  FTextLayout.BeginUpdate;
  try
    if Assigned(ATemplate) then
    begin
      FTextLayout.Font.Assign(ATemplate.TextSettings.Font);
      FTextLayout.Color := ATemplate.TextSettings.FontColor;
    end
    else
    begin
      FTextLayout.Font.Assign(FDefaultFont);
      FTextLayout.Color := ADefaultColor;
    end;

    FTextLayout.Text := AText;
    FTextLayout.TopLeft := ARect.TopLeft;
    FTextLayout.MaxSize := TPointF.Create(ARect.Width, ARect.Height);
    FTextLayout.HorizontalAlign := AHorizontalAlign;
    FTextLayout.VerticalAlign := AVerticalAlign;
    FTextLayout.WordWrap := False;
    FTextLayout.Trimming := TTextTrimming.None;
    FTextLayout.Opacity := AbsoluteOpacity;
  finally
    FTextLayout.EndUpdate;
  end;
end;

procedure TS4YCustomGauge.RangeChanged;
begin
  StopAnimation;
  FValue := EnsureRange(FValue, FMin, FMax);
  SetDisplayedValue(FValue);
end;

procedure TS4YCustomGauge.RenderText(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string; const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign);
begin
  if AText = '' then
    Exit;

  PrepareTextLayout(ATemplate, ADefaultColor, AText, ARect, AHorizontalAlign, AVerticalAlign);
  FTextLayout.RenderLayout(Canvas);
end;

procedure TS4YCustomGauge.SetAnimationDuration(const Value: Single);
begin
  FAnimationDuration := System.Math.Max(0, Value);
end;

procedure TS4YCustomGauge.SetCaption(const Value: string);
begin
  if FCaption = Value then
    Exit;

  FCaption := Value;
  Repaint;
end;

procedure TS4YCustomGauge.SetDisplayedValue(const Value: Single);
begin
  if csDestroying in ComponentState then
    Exit;

  FDisplayedValue := Value;
  Repaint;
end;

procedure TS4YCustomGauge.SetFillBrush(const Value: TBrush);
begin
  FFillBrush.Assign(Value);
end;

procedure TS4YCustomGauge.SetMax(const Value: Single);
begin
  // While loading, Min may not be read yet: Loaded checks the value.
  if csLoading in ComponentState then
  begin
    FMax := Value;
    Exit;
  end;

  if SameValue(FMax, Value) then
    Exit;

  FMax := Value;

  if FMin > FMax then
    FMin := FMax;

  RangeChanged;
end;

procedure TS4YCustomGauge.SetMin(const Value: Single);
begin
  // While loading, Max may not be read yet: Loaded checks the value.
  if csLoading in ComponentState then
  begin
    FMin := Value;
    Exit;
  end;

  if SameValue(FMin, Value) then
    Exit;

  FMin := Value;

  if FMax < FMin then
    FMax := FMin;

  RangeChanged;
end;

procedure TS4YCustomGauge.SetShowValue(const Value: Boolean);
begin
  if FShowValue = Value then
    Exit;

  FShowValue := Value;
  Repaint;
end;

procedure TS4YCustomGauge.SetStyledBrushes(const Value: TS4YGaugeStyledBrushes);
begin
  if FStyledBrushes = Value then
    Exit;

  FStyledBrushes := Value;
  BrushesChanged;
end;

procedure TS4YCustomGauge.SetThickness(const Value: Single);
begin
  if SameValue(FThickness, Value) then
    Exit;

  FThickness := System.Math.Max(0, Value);
  Repaint;
end;

procedure TS4YCustomGauge.SetTrackBrush(const Value: TBrush);
begin
  FTrackBrush.Assign(Value);
end;

procedure TS4YCustomGauge.SetValue(const Value: Single);
var
  LValue: Single;
  LChange: Single;
begin
  // While loading, Min and Max may not be read yet: Loaded checks the value.
  if csLoading in ComponentState then
  begin
    FValue := Value;
    Exit;
  end;

  LValue := EnsureRange(Value, FMin, FMax);

  if SameValue(LValue, FValue) then
    Exit;

  LChange := Abs(LValue - FValue);
  FValue := LValue;

  // Small changes, such as the ones of a download, are drawn at once, so that the fill follows them;
  // a larger one is animated, and so is any change while the fill is already moving, so that it
  // never jumps.
  if (FAnimationDuration > 0) and not (csDesigning in ComponentState) and
    (IsAnimating or (LChange > (FMax - FMin) * C_ANIMATION_THRESHOLD)) then
    AnimateValue
  else
    SetDisplayedValue(FValue);
end;

procedure TS4YCustomGauge.SetValueFormat(const Value: string);
begin
  if FValueFormat = Value then
    Exit;

  FValueFormat := Value;
  Repaint;
end;

procedure TS4YCustomGauge.StopAnimation;
begin
  if IsAnimating then
    FAnimation.StopAtCurrent;
end;

function TS4YCustomGauge.StyledBrushesStored: Boolean;
var
  LImplied: TS4YGaugeStyledBrushes;
begin
  LImplied := C_DEFAULT_STYLED_BRUSHES;

  if (FFillBrush.Kind <> TBrushKind.Solid) or (FFillBrush.Color <> C_DEFAULT_FILL_COLOR) then
    Exclude(LImplied, gsbFill);

  if (FTrackBrush.Kind <> TBrushKind.Solid) or (FTrackBrush.Color <> C_DEFAULT_TRACK_COLOR) then
    Exclude(LImplied, gsbTrack);

  Result := FStyledBrushes <> LImplied;
end;

function TS4YCustomGauge.ThicknessStored: Boolean;
begin
  Result := not SameValue(FThickness, GetDefaultThickness);
end;

procedure TS4YCustomGauge.TrackBrushChanged(Sender: TObject);
begin
  Exclude(FStyledBrushes, gsbTrack);
  BrushesChanged;
end;

function TS4YCustomGauge.ValueFormatStored: Boolean;
begin
  Result := FValueFormat <> C_DEFAULT_VALUE_FORMAT;
end;

function TS4YCustomGauge.ValueStored: Boolean;
begin
  Result := not SameValue(FValue, C_DEFAULT_VALUE);
end;

end.
