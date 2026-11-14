unit Soft4You.FMX.Controls.Gauges.Circular;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YCircularGauge - gauge drawn as a ring or an arc that fills with a value
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Types,
  FMX.Controls,
  FMX.Graphics,
  Soft4You.FMX.Controls.Gauges;

type
  /// <summary>
  /// A gauge drawn as a ring or an arc that fills with the value, with the value and the caption in the middle.
  /// </summary>
  /// <remarks>
  /// StartAngle and SweepAngle give the shape: a ring (0 and 360, the default), an open arc (-135 and 270) or a half circle (-90 and 180). The angles are in degrees, with 0 at the top and the positive values clockwise; the fill grows clockwise from StartAngle, or counterclockwise when Reversed is True.
  /// The arc is as large as the control allows, and the value and the caption are centered in the area enclosed by it.
  /// The style is S4YCircularGaugeStyle: its parts track and fill are TArc objects, which give the brush and the ends of the arc; the gauge draws the arc itself with its angles and Thickness.
  /// </remarks>
  TS4YCircularGauge = class(TS4YCustomGauge)
  public const
    /// <summary>Default value of StartAngle, in degrees: the top of the circle.</summary>
    C_DEFAULT_START_ANGLE: Single = 0;
    /// <summary>Default value of SweepAngle, in degrees: a whole ring.</summary>
    C_DEFAULT_SWEEP_ANGLE: Single = 360;
    /// <summary>Default value of Thickness, in pixels.</summary>
    C_DEFAULT_THICKNESS: Single = 12;
    /// <summary>Largest value of SweepAngle, in degrees.</summary>
    C_MAX_SWEEP_ANGLE: Single = 360;
  private
    FReversed: Boolean;
    FStartAngle: Single;
    FSweepAngle: Single;
    function CalculateUnitArcBounds: TRectF;
    procedure DrawTexts(const ATextArea: TRectF; const AContentWidth: Single);
    procedure LayOutBesideCenter(const AContentRect, AUnitBounds: TRectF; const AOuterSize, ATextGap: Single;
      out ACenter: TPointF; out ARadius: Single; out ATextArea: TRectF);
    procedure LayOutInsideArc(const AContentRect, AUnitBounds: TRectF; const AOuterSize: Single;
      out ACenter: TPointF; out ARadius: Single; out ATextArea: TRectF);
    function MeasureTextsSize: TSizeF;
    procedure SetReversed(const Value: Boolean);
    procedure SetStartAngle(const Value: Single);
    procedure SetSweepAngle(const Value: Single);
    function StartAngleStored: Boolean;
    function SweepAngleStored: Boolean;
  protected
    /// <summary>Returns the angle of FMX, from the right side and clockwise, of the point of the arc at AFraction of the range, from 0 to 1.</summary>
    function AngleOfFraction(const AFraction: Single): Single;
    /// <summary>Gives ABrush to the border of an arc, which draws the track and the fill.</summary>
    procedure ApplyPartBrush(const APart: TControl; const ABrush: TBrush); override;
    /// <summary>Creates the part drawn when the style has no track or no fill: an arc with round ends.</summary>
    function CreateDefaultPart: TControl; override;
    /// <summary>Draws an arc with the look of APart, or with ABrush when APart is not a TArc, from AStartFraction to AEndFraction of the range.</summary>
    procedure DrawArc(const APart: TControl; const ABrush: TBrush; const ACenter: TPointF; const ARadius,
      AStartFraction, AEndFraction: Single);
    /// <summary>Draws what a descendant adds before the texts, such as a graduation; ACenter and ARadius are the ones of the middle of the track. Nothing here.</summary>
    procedure DrawDecorations(const ACenter: TPointF; const ARadius: Single); virtual;
    /// <summary>Draws the filled part of the arc.</summary>
    procedure DrawFill(const ACenter: TPointF; const ARadius: Single); virtual;
    /// <summary>Draws the track, the fill, the value and the caption.</summary>
    procedure DrawGauge; override;
    /// <summary>Draws what a descendant adds over the texts, such as a needle. Nothing here.</summary>
    procedure DrawOverlay(const ACenter: TPointF; const ARadius: Single); virtual;
    /// <summary>Draws the whole track.</summary>
    procedure DrawTrack(const ACenter: TPointF; const ARadius: Single); virtual;
    /// <summary>Returns the size of a new control: 120 x 120.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns 12, the default thickness of the arc.</summary>
    function GetDefaultThickness: Single; override;
    /// <summary>Returns the default value of StartAngle: 0.</summary>
    function GetDefaultStartAngle: Single; virtual;
    /// <summary>Returns the default value of SweepAngle: 360.</summary>
    function GetDefaultSweepAngle: Single; virtual;
    /// <summary>Returns SweepAngle with the sign of the direction of the arc: negative when Reversed is True.</summary>
    function GetDirectedSweepAngle: Single;
    /// <summary>Returns the room a descendant needs outside the track, all around the arc, in pixels. 0 here.</summary>
    function GetOuterMargin: Single; virtual;
    /// <summary>Returns the distance from the center of the arc, in pixels, where a descendant wants the texts to start, to leave the center to a needle; 0 here: the texts are in the middle of the area enclosed by the arc.</summary>
    /// <remarks>The texts are then on the side of the center opposite to the middle of the arc: below it for an arc at the top, above it for an arc at the bottom, beside it for an arc on a side. When there is not enough room on that side, the arc becomes smaller to make it.</remarks>
    function GetTextGapFromCenter: Single; virtual;
  public
    /// <summary>Creates a ring gauge with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property AnimationDuration;
    property Caption;
    property Cursor;
    property Enabled;
    property FillBrush;
    property Height;
    property HitTest;
    property Margins;
    property Max;
    property Min;
    property Opacity;
    property Padding;
    property PopupMenu;
    property Position;
    /// <summary>
    /// True makes the value grow counterclockwise from StartAngle. The default is False: clockwise.
    /// </summary>
    /// <remarks>
    /// With the same angles, the arc is the mirror image of the one drawn clockwise: for example StartAngle -90 and SweepAngle 180 draw a half circle that starts on the left and goes over the top, or with Reversed under the bottom.
    /// </remarks>
    property Reversed: Boolean read FReversed write SetReversed default False;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property ShowValue;
    property Size;
    /// <summary>Angle where the arc starts and the fill begins, in degrees: 0, the default, is the top of the circle, 90 its right side.</summary>
    property StartAngle: Single read FStartAngle write SetStartAngle stored StartAngleStored nodefault;
    property StyleLookup;
    /// <summary>
    /// Length of the arc, in degrees from StartAngle, from 0 to 360: clockwise, or counterclockwise when Reversed is True. The default is 360, a whole ring.
    /// </summary>
    /// <remarks>
    /// For example 270 with StartAngle = -135 draws an arc open at the bottom, 180 with StartAngle = -90 a half circle.
    /// </remarks>
    property SweepAngle: Single read FSweepAngle write SetSweepAngle stored SweepAngleStored nodefault;
    property Thickness;
    property TrackBrush;
    // Must stay after FillBrush and TrackBrush: while streaming, modifying them switches the matching
    // brush off, so an explicit StyledBrushes stored in the form has to be read last to win.
    property StyledBrushes;
    property Value;
    property ValueFormat;
    property Visible;
    property Width;

    property OnClick;
    property OnDblClick;
    property OnGetValueText;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  System.Math,
  FMX.Types,
  FMX.Objects;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

const
  // Size of a new gauge.
  C_DEFAULT_SIZE = 120;
  // Angle of FMX for the top of the circle: FMX measures the angles from the right side.
  C_FMX_TOP_ANGLE = -90;
  // Angles smaller than this, in degrees, are not drawn: a round end would draw a dot.
  C_MIN_DRAWN_SWEEP_ANGLE = 0.01;
  // Smallest width and height of the arc in a circle of radius 1, so that a very short arc does not
  // divide by zero.
  C_MIN_UNIT_ARC_EXTENT = 0.01;

function CenterCoordinate(const AStart, AAvailable, ALowExtent, AHighExtent: Single): Single;
begin
  // A block that goes ALowExtent before the center and AHighExtent after it, in the middle of the
  // available room.
  Result := AStart + (AAvailable - ALowExtent - AHighExtent) / 2 + ALowExtent;
end;

function FitRadius(const AAvailable, AArcLow, AArcHigh, ATextLow, ATextHigh, AMargin: Single): Single;
begin
  // The largest radius for which the larger of the arc and the texts fits on both sides of the center,
  // along one axis: the arc reaches AArcLow and AArcHigh times the radius, plus AMargin, the texts
  // ATextLow and ATextHigh. Every pair of the two sides must fit in AAvailable.
  Result := (AAvailable - 2 * AMargin) / System.Math.Max(AArcLow + AArcHigh, C_MIN_UNIT_ARC_EXTENT);

  if AArcLow > C_MIN_UNIT_ARC_EXTENT then
    Result := System.Math.Min(Result, (AAvailable - AMargin - ATextHigh) / AArcLow);

  if AArcHigh > C_MIN_UNIT_ARC_EXTENT then
    Result := System.Math.Min(Result, (AAvailable - AMargin - ATextLow) / AArcHigh);
end;

{ TS4YCircularGauge }

constructor TS4YCircularGauge.Create(AOwner: TComponent);
begin
  inherited;

  FStartAngle := GetDefaultStartAngle;
  FSweepAngle := GetDefaultSweepAngle;
end;

function TS4YCircularGauge.AngleOfFraction(const AFraction: Single): Single;
begin
  Result := FStartAngle + C_FMX_TOP_ANGLE + GetDirectedSweepAngle * AFraction;
end;

procedure TS4YCircularGauge.ApplyPartBrush(const APart: TControl; const ABrush: TBrush);
begin
  if APart is TArc then
    TArc(APart).Stroke.Assign(ABrush)
  else
    inherited;
end;

function TS4YCircularGauge.CalculateUnitArcBounds: TRectF;
var
  LStartAngle: Single;
  LEndAngle: Single;
  LAngle: Single;
  LBounds: TRectF;

  procedure IncludeAngle(const AAngle: Single);
  var
    LPoint: TPointF;
  begin
    LPoint := TPointF.Create(Cos(DegToRad(AAngle)), Sin(DegToRad(AAngle)));
    LBounds.Left := System.Math.Min(LBounds.Left, LPoint.X);
    LBounds.Top := System.Math.Min(LBounds.Top, LPoint.Y);
    LBounds.Right := System.Math.Max(LBounds.Right, LPoint.X);
    LBounds.Bottom := System.Math.Max(LBounds.Bottom, LPoint.Y);
  end;

begin
  // The area covered by the arc in a circle of radius 1 centered in 0, 0, with the angles of FMX; a
  // reversed arc covers the same area as the clockwise arc from its end to its start.
  if FReversed then
    LStartAngle := AngleOfFraction(1)
  else
    LStartAngle := AngleOfFraction(0);

  LEndAngle := LStartAngle + FSweepAngle;
  LBounds := TRectF.Create(Cos(DegToRad(LStartAngle)), Sin(DegToRad(LStartAngle)), Cos(DegToRad(LStartAngle)),
    Sin(DegToRad(LStartAngle)));
  IncludeAngle(LEndAngle);

  // The top, bottom, left and right points of the circle that the arc crosses.
  LAngle := Ceil(LStartAngle / 90) * 90;

  while LAngle < LEndAngle do
  begin
    IncludeAngle(LAngle);
    LAngle := LAngle + 90;
  end;

  Result := LBounds;
end;

function TS4YCircularGauge.CreateDefaultPart: TControl;
var
  LArc: TArc;
begin
  LArc := TArc.Create(nil);
  LArc.Fill.Kind := TBrushKind.None;
  LArc.Stroke.Cap := TStrokeCap.Round;
  Result := LArc;
end;

procedure TS4YCircularGauge.DrawArc(const APart: TControl; const ABrush: TBrush; const ACenter: TPointF;
  const ARadius, AStartFraction, AEndFraction: Single);
var
  LSweepAngle: Single;
begin
  LSweepAngle := FSweepAngle * (AEndFraction - AStartFraction);

  if LSweepAngle < C_MIN_DRAWN_SWEEP_ANGLE then
    Exit;

  // An arc of the style gives the brush and the ends; another object leaves the brush of the property,
  // with flat ends.
  if APart is TArc then
    Canvas.Stroke.Assign(TArc(APart).Stroke)
  else
  begin
    Canvas.Stroke.Assign(ABrush);
    Canvas.Stroke.Cap := TStrokeCap.Flat;
    Canvas.Stroke.Dash := TStrokeDash.Solid;
  end;

  Canvas.Stroke.Thickness := Thickness;
  Canvas.DrawArc(ACenter, TPointF.Create(ARadius, ARadius), AngleOfFraction(AStartFraction),
    GetDirectedSweepAngle * (AEndFraction - AStartFraction), AbsoluteOpacity);
end;

procedure TS4YCircularGauge.DrawDecorations(const ACenter: TPointF; const ARadius: Single);
begin
  // Nothing: the descendants draw a graduation or other marks here.
end;

procedure TS4YCircularGauge.DrawFill(const ACenter: TPointF; const ARadius: Single);
begin
  DrawArc(FillPart, FillBrush, ACenter, ARadius, 0, GetDisplayedFraction);
end;

procedure TS4YCircularGauge.DrawGauge;
var
  LCenter: TPointF;
  LContentRect: TRectF;
  LOuterSize: Single;
  LRadius: Single;
  LTextArea: TRectF;
  LTextGap: Single;
  LUnitBounds: TRectF;
begin
  LContentRect := GetContentRect;
  LUnitBounds := CalculateUnitArcBounds;
  LOuterSize := Thickness + 2 * GetOuterMargin;
  LTextGap := GetTextGapFromCenter;

  if LTextGap > 0 then
    LayOutBesideCenter(LContentRect, LUnitBounds, LOuterSize, LTextGap, LCenter, LRadius, LTextArea)
  else
    LayOutInsideArc(LContentRect, LUnitBounds, LOuterSize, LCenter, LRadius, LTextArea);

  if (LRadius <= 0) or (FSweepAngle < C_MIN_DRAWN_SWEEP_ANGLE) then
  begin
    DrawTexts(LContentRect, LContentRect.Width);
    Exit;
  end;

  DrawTrack(LCenter, LRadius);
  DrawFill(LCenter, LRadius);
  DrawDecorations(LCenter, LRadius);
  DrawTexts(LTextArea, LContentRect.Width);
  DrawOverlay(LCenter, LRadius);
end;

procedure TS4YCircularGauge.DrawOverlay(const ACenter: TPointF; const ARadius: Single);
begin
  // Nothing: the descendants draw a needle or other marks over the texts here.
end;

procedure TS4YCircularGauge.DrawTexts(const ATextArea: TRectF; const AContentWidth: Single);
var
  LCaption: string;
  LCaptionHeight: Single;
  LCenterX: Single;
  LTop: Single;
  LValueHeight: Single;
  LValueText: string;
begin
  LValueText := GetValueText;
  LCaption := Caption;
  LValueHeight := MeasureText(StyleValueText, C_DEFAULT_VALUE_TEXT_COLOR, LValueText).Height;
  LCaptionHeight := MeasureText(StyleCaptionText, C_DEFAULT_CAPTION_TEXT_COLOR, LCaption).Height;

  if LValueHeight + LCaptionHeight <= 0 then
    Exit;

  // The value, with the caption under it, in the middle of the area; a text wider than the area can
  // go beyond it, as far as the width of the content.
  LCenterX := ATextArea.CenterPoint.X;
  LTop := ATextArea.CenterPoint.Y - (LValueHeight + LCaptionHeight) / 2;
  RenderText(StyleValueText, C_DEFAULT_VALUE_TEXT_COLOR, LValueText, TRectF.Create(LCenterX - AContentWidth / 2,
    LTop, LCenterX + AContentWidth / 2, LTop + LValueHeight), TTextAlign.Center, TTextAlign.Leading);
  LTop := LTop + LValueHeight;
  RenderText(StyleCaptionText, C_DEFAULT_CAPTION_TEXT_COLOR, LCaption, TRectF.Create(LCenterX - AContentWidth / 2,
    LTop, LCenterX + AContentWidth / 2, LTop + LCaptionHeight), TTextAlign.Center, TTextAlign.Leading);
end;

procedure TS4YCircularGauge.DrawTrack(const ACenter: TPointF; const ARadius: Single);
begin
  DrawArc(TrackPart, TrackBrush, ACenter, ARadius, 0, 1);
end;

function TS4YCircularGauge.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_SIZE, C_DEFAULT_SIZE);
end;

function TS4YCircularGauge.GetDefaultStartAngle: Single;
begin
  Result := C_DEFAULT_START_ANGLE;
end;

function TS4YCircularGauge.GetDefaultSweepAngle: Single;
begin
  Result := C_DEFAULT_SWEEP_ANGLE;
end;

function TS4YCircularGauge.GetDefaultThickness: Single;
begin
  Result := C_DEFAULT_THICKNESS;
end;

function TS4YCircularGauge.GetDirectedSweepAngle: Single;
begin
  if FReversed then
    Result := -FSweepAngle
  else
    Result := FSweepAngle;
end;

function TS4YCircularGauge.GetOuterMargin: Single;
begin
  Result := 0;
end;

function TS4YCircularGauge.GetTextGapFromCenter: Single;
begin
  Result := 0;
end;

procedure TS4YCircularGauge.LayOutBesideCenter(const AContentRect, AUnitBounds: TRectF; const AOuterSize,
  ATextGap: Single; out ACenter: TPointF; out ARadius: Single; out ATextArea: TRectF);
var
  LArcBottom: Single;
  LArcLeft: Single;
  LArcRight: Single;
  LArcTop: Single;
  LDirection: TPointF;
  LMargin: Single;
  LMiddleAngle: Single;
  LOffset: TPointF;
  LTextBottom: Single;
  LTextLeft: Single;
  LTextRight: Single;
  LTextSize: TSizeF;
  LTextTop: Single;
begin
  // The texts are on the side of the center opposite to the middle of the arc, along the line from
  // the middle of the arc through the center, with their nearest side ATextGap away from the center.
  LTextSize := MeasureTextsSize;
  LMiddleAngle := DegToRad(AngleOfFraction(0.5));
  LDirection := TPointF.Create(-Cos(LMiddleAngle), -Sin(LMiddleAngle));
  LOffset := LDirection * (ATextGap + Abs(LTextSize.Width / 2 * LDirection.X) +
    Abs(LTextSize.Height / 2 * LDirection.Y));

  // How far the texts and the arc go from the center on each side; the arc includes the center,
  // where the needle is.
  LTextLeft := LTextSize.Width / 2 - LOffset.X;
  LTextRight := LTextSize.Width / 2 + LOffset.X;
  LTextTop := LTextSize.Height / 2 - LOffset.Y;
  LTextBottom := LTextSize.Height / 2 + LOffset.Y;
  LArcLeft := System.Math.Max(0, -AUnitBounds.Left);
  LArcRight := System.Math.Max(0, AUnitBounds.Right);
  LArcTop := System.Math.Max(0, -AUnitBounds.Top);
  LArcBottom := System.Math.Max(0, AUnitBounds.Bottom);
  LMargin := AOuterSize / 2;

  // The arc is as large as the content allows with the texts beside it: when there is not enough room
  // for them, it becomes smaller.
  ARadius := System.Math.Min(
    FitRadius(AContentRect.Width, LArcLeft, LArcRight, LTextLeft, LTextRight, LMargin),
    FitRadius(AContentRect.Height, LArcTop, LArcBottom, LTextTop, LTextBottom, LMargin));
  // The block of the arc and of the texts is in the middle of the content.
  ACenter.X := CenterCoordinate(AContentRect.Left, AContentRect.Width,
    System.Math.Max(LArcLeft * ARadius + LMargin, LTextLeft),
    System.Math.Max(LArcRight * ARadius + LMargin, LTextRight));
  ACenter.Y := CenterCoordinate(AContentRect.Top, AContentRect.Height,
    System.Math.Max(LArcTop * ARadius + LMargin, LTextTop),
    System.Math.Max(LArcBottom * ARadius + LMargin, LTextBottom));
  ATextArea := TRectF.Create(ACenter + LOffset, ACenter + LOffset);
  ATextArea.Inflate(LTextSize.Width / 2, LTextSize.Height / 2);
end;

procedure TS4YCircularGauge.LayOutInsideArc(const AContentRect, AUnitBounds: TRectF; const AOuterSize: Single;
  out ACenter: TPointF; out ARadius: Single; out ATextArea: TRectF);
var
  LLeft: Single;
  LTop: Single;
begin
  // The arc, with its thickness and the room of a descendant outside it, is as large as the content
  // allows, and the circle stays round.
  ARadius := System.Math.Min(
    (AContentRect.Width - AOuterSize) / System.Math.Max(AUnitBounds.Width, C_MIN_UNIT_ARC_EXTENT),
    (AContentRect.Height - AOuterSize) / System.Math.Max(AUnitBounds.Height, C_MIN_UNIT_ARC_EXTENT));
  LLeft := AContentRect.Left + (AContentRect.Width - ARadius * AUnitBounds.Width - AOuterSize) / 2;
  LTop := AContentRect.Top + (AContentRect.Height - ARadius * AUnitBounds.Height - AOuterSize) / 2;
  ACenter := TPointF.Create(LLeft + AOuterSize / 2 - ARadius * AUnitBounds.Left,
    LTop + AOuterSize / 2 - ARadius * AUnitBounds.Top);

  // The texts are centered in the area enclosed by the arc.
  ATextArea := TRectF.Create(ACenter.X + ARadius * AUnitBounds.Left, ACenter.Y + ARadius * AUnitBounds.Top,
    ACenter.X + ARadius * AUnitBounds.Right, ACenter.Y + ARadius * AUnitBounds.Bottom);
end;

function TS4YCircularGauge.MeasureTextsSize: TSizeF;
var
  LCaptionSize: TSizeF;
  LValueSize: TSizeF;
begin
  // The value with the caption under it.
  LValueSize := MeasureText(StyleValueText, C_DEFAULT_VALUE_TEXT_COLOR, GetValueText);
  LCaptionSize := MeasureText(StyleCaptionText, C_DEFAULT_CAPTION_TEXT_COLOR, Caption);
  Result := TSizeF.Create(System.Math.Max(LValueSize.Width, LCaptionSize.Width),
    LValueSize.Height + LCaptionSize.Height);
end;

procedure TS4YCircularGauge.SetReversed(const Value: Boolean);
begin
  if FReversed = Value then
    Exit;

  FReversed := Value;
  Repaint;
end;

procedure TS4YCircularGauge.SetStartAngle(const Value: Single);
begin
  if SameValue(FStartAngle, Value) then
    Exit;

  FStartAngle := Value;
  Repaint;
end;

procedure TS4YCircularGauge.SetSweepAngle(const Value: Single);
var
  LSweepAngle: Single;
begin
  LSweepAngle := EnsureRange(Value, 0, C_MAX_SWEEP_ANGLE);

  if SameValue(FSweepAngle, LSweepAngle) then
    Exit;

  FSweepAngle := LSweepAngle;
  Repaint;
end;

function TS4YCircularGauge.StartAngleStored: Boolean;
begin
  Result := not SameValue(FStartAngle, GetDefaultStartAngle);
end;

function TS4YCircularGauge.SweepAngleStored: Boolean;
begin
  Result := not SameValue(FSweepAngle, GetDefaultSweepAngle);
end;

end.
