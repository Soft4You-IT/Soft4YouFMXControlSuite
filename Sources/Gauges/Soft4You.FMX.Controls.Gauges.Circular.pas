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
  /// StartAngle and SweepAngle give the shape: a ring (0 and 360, the default), an open arc (-135 and 270) or a half circle (-90 and 180). The angles are in degrees, with 0 at the top and the positive values clockwise; the fill grows clockwise from StartAngle.
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
    FStartAngle: Single;
    FSweepAngle: Single;
    function CalculateUnitArcBounds: TRectF;
    procedure DrawArc(const APart: TControl; const ABrush: TBrush; const ACenter: TPointF; const ARadius,
      ASweepAngle: Single);
    procedure DrawTexts(const ATextArea: TRectF; const AContentWidth: Single);
    procedure SetStartAngle(const Value: Single);
    procedure SetSweepAngle(const Value: Single);
    function StartAngleStored: Boolean;
    function SweepAngleStored: Boolean;
  protected
    /// <summary>Gives ABrush to the border of an arc, which draws the track and the fill.</summary>
    procedure ApplyPartBrush(const APart: TControl; const ABrush: TBrush); override;
    /// <summary>Creates the part drawn when the style has no track or no fill: an arc with round ends.</summary>
    function CreateDefaultPart: TControl; override;
    /// <summary>Draws the track, the fill, the value and the caption.</summary>
    procedure DrawGauge; override;
    /// <summary>Returns the size of a new control: 120 x 120.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns 12, the default thickness of the arc.</summary>
    function GetDefaultThickness: Single; override;
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
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property ShowValue;
    property Size;
    /// <summary>Angle where the arc starts and the fill begins, in degrees: 0, the default, is the top of the circle, 90 its right side.</summary>
    property StartAngle: Single read FStartAngle write SetStartAngle stored StartAngleStored nodefault;
    property StyleLookup;
    /// <summary>
    /// Length of the arc, in degrees clockwise from StartAngle, from 0 to 360. The default is 360, a whole ring.
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

{ TS4YCircularGauge }

constructor TS4YCircularGauge.Create(AOwner: TComponent);
begin
  inherited;

  FStartAngle := C_DEFAULT_START_ANGLE;
  FSweepAngle := C_DEFAULT_SWEEP_ANGLE;
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
  // The area covered by the arc in a circle of radius 1 centered in 0, 0, with the angles of FMX.
  LStartAngle := FStartAngle + C_FMX_TOP_ANGLE;
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
  const ARadius, ASweepAngle: Single);
begin
  if ASweepAngle < C_MIN_DRAWN_SWEEP_ANGLE then
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
  Canvas.DrawArc(ACenter, TPointF.Create(ARadius, ARadius), FStartAngle + C_FMX_TOP_ANGLE, ASweepAngle,
    AbsoluteOpacity);
end;

procedure TS4YCircularGauge.DrawGauge;
var
  LCenter: TPointF;
  LContentRect: TRectF;
  LLeft: Single;
  LRadius: Single;
  LThickness: Single;
  LTop: Single;
  LUnitBounds: TRectF;
begin
  LContentRect := GetContentRect;
  LThickness := Thickness;
  LUnitBounds := CalculateUnitArcBounds;

  // The arc, with its thickness, is as large as the content allows, and the circle stays round.
  LRadius := System.Math.Min(
    (LContentRect.Width - LThickness) / System.Math.Max(LUnitBounds.Width, C_MIN_UNIT_ARC_EXTENT),
    (LContentRect.Height - LThickness) / System.Math.Max(LUnitBounds.Height, C_MIN_UNIT_ARC_EXTENT));

  if (LRadius <= 0) or (FSweepAngle < C_MIN_DRAWN_SWEEP_ANGLE) then
  begin
    DrawTexts(LContentRect, LContentRect.Width);
    Exit;
  end;

  LLeft := LContentRect.Left + (LContentRect.Width - LRadius * LUnitBounds.Width - LThickness) / 2;
  LTop := LContentRect.Top + (LContentRect.Height - LRadius * LUnitBounds.Height - LThickness) / 2;
  LCenter := TPointF.Create(LLeft + LThickness / 2 - LRadius * LUnitBounds.Left,
    LTop + LThickness / 2 - LRadius * LUnitBounds.Top);

  DrawArc(TrackPart, TrackBrush, LCenter, LRadius, FSweepAngle);
  DrawArc(FillPart, FillBrush, LCenter, LRadius, FSweepAngle * GetDisplayedFraction);

  // The texts are centered in the area enclosed by the arc.
  DrawTexts(TRectF.Create(LCenter.X + LRadius * LUnitBounds.Left, LCenter.Y + LRadius * LUnitBounds.Top,
    LCenter.X + LRadius * LUnitBounds.Right, LCenter.Y + LRadius * LUnitBounds.Bottom), LContentRect.Width);
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

function TS4YCircularGauge.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_SIZE, C_DEFAULT_SIZE);
end;

function TS4YCircularGauge.GetDefaultThickness: Single;
begin
  Result := C_DEFAULT_THICKNESS;
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
  Result := not SameValue(FStartAngle, C_DEFAULT_START_ANGLE);
end;

function TS4YCircularGauge.SweepAngleStored: Boolean;
begin
  Result := not SameValue(FSweepAngle, C_DEFAULT_SWEEP_ANGLE);
end;

end.
