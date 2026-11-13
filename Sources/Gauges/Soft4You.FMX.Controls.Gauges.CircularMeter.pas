unit Soft4You.FMX.Controls.Gauges.CircularMeter;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YCircularMeter - circular gauge with a graduation, like a dial
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
  FMX.Objects,
  Soft4You.FMX.Controls.Gauges.Scales,
  Soft4You.FMX.Controls.Gauges.Circular;

type
  /// <summary>
  /// A circular gauge with a graduation along the arc, like the dial of an instrument.
  /// </summary>
  /// <remarks>
  /// The arc is open at the bottom by default (StartAngle -135, SweepAngle 270). Graduation gives the ticks and their numbers, inside or outside the arc; outside, the arc becomes smaller to leave room for them.
  /// The style is S4YCircularMeterStyle: besides the parts of S4YCircularGaugeStyle, the shapes majortick and minortick give the stroke of the ticks and the text scaletext the font and the color of the numbers.
  /// </remarks>
  TS4YCircularMeter = class(TS4YCircularGauge)
  public const
    /// <summary>Color of the major ticks when the style has no majortick.</summary>
    C_DEFAULT_MAJOR_TICK_COLOR: TAlphaColor = $FF757575;
    /// <summary>Color of the minor ticks when the style has no minortick.</summary>
    C_DEFAULT_MINOR_TICK_COLOR: TAlphaColor = $FFBDBDBD;
    /// <summary>Color of the numbers of the graduation when the style has no scaletext.</summary>
    C_DEFAULT_SCALE_TEXT_COLOR: TAlphaColor = $FF616161;
    /// <summary>Default value of StartAngle, in degrees.</summary>
    C_DEFAULT_START_ANGLE: Single = -135;
    /// <summary>Default value of SweepAngle, in degrees: an arc open at the bottom.</summary>
    C_DEFAULT_SWEEP_ANGLE: Single = 270;
  private
    FGraduation: TS4YCircularMeterGraduation;
    FStyleMajorTick: TShape;
    FStyleMinorTick: TShape;
    FStyleScaleText: TText;
    procedure DrawTicks(const ACenter: TPointF; const AFromRadius: Single; const AValues: TArray<Single>;
      const AStyleTick: TShape; const ADefaultColor: TAlphaColor; const ALength: Single; Outside: Boolean);
    procedure GraduationChanged(Sender: TObject);
    function IsWholeCircle: Boolean;
    function IsValueDrawn(const AValue: Single): Boolean;
    function MaxLabelExtent: Single;
    procedure PrepareTickStroke(const AStyleTick: TShape; const ADefaultColor: TAlphaColor);
    procedure SetGraduation(const Value: TS4YCircularMeterGraduation);
  protected
    /// <summary>Finds the ticks and the text of the graduation in the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Draws the graduation.</summary>
    procedure DrawDecorations(const ACenter: TPointF; const ARadius: Single); override;
    /// <summary>Releases the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control: 160 x 160.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns -135, the default value of StartAngle.</summary>
    function GetDefaultStartAngle: Single; override;
    /// <summary>Returns 270, the default value of SweepAngle.</summary>
    function GetDefaultSweepAngle: Single; override;
    /// <summary>Returns the room of the graduation outside the arc, or 0 when it is inside.</summary>
    function GetOuterMargin: Single; override;
  public
    /// <summary>Creates a meter with an arc open at the bottom and a graduation inside it.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    /// <summary>The ticks and the numbers drawn along the arc, inside or outside it.</summary>
    property Graduation: TS4YCircularMeterGraduation read FGraduation write SetGraduation;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  Soft4You.FMX.Controls.Gauges.Types;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_MAJOR_TICK = 'majortick';
  C_STYLE_MINOR_TICK = 'minortick';
  C_STYLE_SCALE_TEXT = 'scaletext';

  // Size of a new meter.
  C_DEFAULT_SIZE = 160;
  // Thickness of a tick when the style has no shape for it, in pixels.
  C_DEFAULT_TICK_THICKNESS = 1.5;
  // Space between the arc, the ticks and the numbers, in pixels.
  C_SCALE_SPACING = 3;
  // Tolerance on the end of a whole circle, as a fraction of the range.
  C_WHOLE_CIRCLE_EPSILON = 1E-4;

{ TS4YCircularMeter }

constructor TS4YCircularMeter.Create(AOwner: TComponent);
begin
  inherited;

  FGraduation := TS4YCircularMeterGraduation.Create;
  FGraduation.OnChange := GraduationChanged;
end;

destructor TS4YCircularMeter.Destroy;
begin
  FreeAndNil(FGraduation);

  inherited;
end;

procedure TS4YCircularMeter.ApplyStyle;
begin
  inherited;

  FindStyleResource<TShape>(C_STYLE_MAJOR_TICK, FStyleMajorTick);
  FindStyleResource<TShape>(C_STYLE_MINOR_TICK, FStyleMinorTick);
  FindStyleResource<TText>(C_STYLE_SCALE_TEXT, FStyleScaleText);
end;

procedure TS4YCircularMeter.DrawDecorations(const ACenter: TPointF; const ARadius: Single);
var
  LAngle: Single;
  LCos: Single;
  LFromRadius: Single;
  LHalfExtent: Single;
  LLabelCenter: TPointF;
  LLabelRadius: Single;
  LMajorValues: TArray<Single>;
  LOutside: Boolean;
  LSin: Single;
  LText: string;
  LTextSize: TSizeF;
begin
  if not FGraduation.Visible then
    Exit;

  // The ticks start a little away from the edge of the track, on the side of the graduation.
  LOutside := FGraduation.Position = gasOutside;

  if LOutside then
    LFromRadius := ARadius + Thickness / 2 + C_SCALE_SPACING
  else
    LFromRadius := ARadius - Thickness / 2 - C_SCALE_SPACING;

  LMajorValues := FGraduation.GetMajorValues(Min, Max);
  DrawTicks(ACenter, LFromRadius, FGraduation.GetMinorValues(Min, Max), FStyleMinorTick, C_DEFAULT_MINOR_TICK_COLOR,
    FGraduation.MinorTickLength, LOutside);
  DrawTicks(ACenter, LFromRadius, LMajorValues, FStyleMajorTick, C_DEFAULT_MAJOR_TICK_COLOR,
    FGraduation.MajorTickLength, LOutside);

  if not FGraduation.ShowLabels then
    Exit;

  for var I := 0 to High(LMajorValues) do
  begin
    if IsValueDrawn(LMajorValues[I]) then
    begin
      LText := FGraduation.FormatLabel(LMajorValues[I]);
      LTextSize := MeasureText(FStyleScaleText, C_DEFAULT_SCALE_TEXT_COLOR, LText);
      LAngle := DegToRad(AngleOfFraction(GetValueFraction(LMajorValues[I])));
      LCos := Cos(LAngle);
      LSin := Sin(LAngle);

      // The number is beyond the major tick, at the distance that keeps its whole rectangle clear of
      // it: half of its width along the X axis and half of its height along the Y axis.
      LHalfExtent := Abs(LTextSize.Width / 2 * LCos) + Abs(LTextSize.Height / 2 * LSin);

      if LOutside then
        LLabelRadius := LFromRadius + FGraduation.MajorTickLength + C_SCALE_SPACING + LHalfExtent
      else
        LLabelRadius := LFromRadius - FGraduation.MajorTickLength - C_SCALE_SPACING - LHalfExtent;

      LLabelCenter := TPointF.Create(ACenter.X + LLabelRadius * LCos, ACenter.Y + LLabelRadius * LSin);
      RenderText(FStyleScaleText, C_DEFAULT_SCALE_TEXT_COLOR, LText, TRectF.Create(LLabelCenter.X - LTextSize.Width,
        LLabelCenter.Y - LTextSize.Height, LLabelCenter.X + LTextSize.Width, LLabelCenter.Y + LTextSize.Height),
        TTextAlign.Center, TTextAlign.Center);
    end;
  end;
end;

procedure TS4YCircularMeter.DrawTicks(const ACenter: TPointF; const AFromRadius: Single;
  const AValues: TArray<Single>; const AStyleTick: TShape; const ADefaultColor: TAlphaColor; const ALength: Single;
  Outside: Boolean);
var
  LAngle: Single;
  LToRadius: Single;
begin
  if (ALength <= 0) or (Length(AValues) = 0) then
    Exit;

  if Outside then
    LToRadius := AFromRadius + ALength
  else
    LToRadius := AFromRadius - ALength;

  PrepareTickStroke(AStyleTick, ADefaultColor);

  for var I := 0 to High(AValues) do
  begin
    if IsValueDrawn(AValues[I]) then
    begin
      LAngle := DegToRad(AngleOfFraction(GetValueFraction(AValues[I])));
      Canvas.DrawLine(TPointF.Create(ACenter.X + AFromRadius * Cos(LAngle), ACenter.Y + AFromRadius * Sin(LAngle)),
        TPointF.Create(ACenter.X + LToRadius * Cos(LAngle), ACenter.Y + LToRadius * Sin(LAngle)), AbsoluteOpacity);
    end;
  end;
end;

procedure TS4YCircularMeter.FreeStyle;
begin
  FStyleMajorTick := nil;
  FStyleMinorTick := nil;
  FStyleScaleText := nil;

  inherited;
end;

function TS4YCircularMeter.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_SIZE, C_DEFAULT_SIZE);
end;

function TS4YCircularMeter.GetDefaultStartAngle: Single;
begin
  Result := C_DEFAULT_START_ANGLE;
end;

function TS4YCircularMeter.GetDefaultSweepAngle: Single;
begin
  Result := C_DEFAULT_SWEEP_ANGLE;
end;

function TS4YCircularMeter.GetOuterMargin: Single;
var
  LTickLength: Single;
begin
  if not FGraduation.Visible or (FGraduation.Position <> gasOutside) then
    Exit(0);

  LTickLength := FGraduation.MajorTickLength;

  if FGraduation.MinorCount > 0 then
    LTickLength := System.Math.Max(LTickLength, FGraduation.MinorTickLength);

  Result := C_SCALE_SPACING + LTickLength;

  if FGraduation.ShowLabels then
    Result := Result + C_SCALE_SPACING + MaxLabelExtent;
end;

procedure TS4YCircularMeter.GraduationChanged(Sender: TObject);
begin
  Repaint;
end;

function TS4YCircularMeter.IsValueDrawn(const AValue: Single): Boolean;
begin
  // On a whole circle the end of the range is at the same place as its start, which is drawn instead.
  Result := not IsWholeCircle or (GetValueFraction(AValue) < 1 - C_WHOLE_CIRCLE_EPSILON);
end;

function TS4YCircularMeter.IsWholeCircle: Boolean;
begin
  Result := SweepAngle >= C_MAX_SWEEP_ANGLE - C_WHOLE_CIRCLE_EPSILON;
end;

function TS4YCircularMeter.MaxLabelExtent: Single;
var
  LMajorValues: TArray<Single>;
  LTextSize: TSizeF;
begin
  // The largest width or height of the numbers: the room they need in any direction.
  Result := 0;
  LMajorValues := FGraduation.GetMajorValues(Min, Max);

  for var I := 0 to High(LMajorValues) do
  begin
    LTextSize := MeasureText(FStyleScaleText, C_DEFAULT_SCALE_TEXT_COLOR, FGraduation.FormatLabel(LMajorValues[I]));
    Result := System.Math.Max(Result, System.Math.Max(LTextSize.Width, LTextSize.Height));
  end;
end;

procedure TS4YCircularMeter.PrepareTickStroke(const AStyleTick: TShape; const ADefaultColor: TAlphaColor);
begin
  if Assigned(AStyleTick) then
    Canvas.Stroke.Assign(AStyleTick.Stroke)
  else
  begin
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := ADefaultColor;
    Canvas.Stroke.Thickness := C_DEFAULT_TICK_THICKNESS;
    Canvas.Stroke.Cap := TStrokeCap.Flat;
    Canvas.Stroke.Dash := TStrokeDash.Solid;
  end;
end;

procedure TS4YCircularMeter.SetGraduation(const Value: TS4YCircularMeterGraduation);
begin
  FGraduation.Assign(Value);
end;

end.
