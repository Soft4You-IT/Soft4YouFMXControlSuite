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
  FMX.Graphics,
  FMX.Objects,
  Soft4You.FMX.Controls.Gauges.Types,
  Soft4You.FMX.Controls.Gauges.Scales,
  Soft4You.FMX.Controls.Gauges.Circular;

type
  /// <summary>
  /// A circular gauge with a graduation along the arc, like the dial of an instrument, with a needle, colored ranges and a target value.
  /// </summary>
  /// <remarks>
  /// The arc is open at the bottom by default (StartAngle -135, SweepAngle 270). Graduation gives the ticks and their numbers, inside or outside the arc; outside, the arc becomes smaller to leave room for them.
  /// Needle points at the value from the center of the arc, and the value and the caption are written beside the center, on the side opposite to the middle of the arc; the fill of the arc is hidden by default (ShowFill).
  /// Ranges color parts of the scale, on the track or in thin bands beside it (RangePlacement); FillFromRange gives the fill the color of the range of the value. ShowTarget marks the value of Target across the track.
  /// The style is S4YCircularMeterStyle: besides the parts of S4YCircularGaugeStyle, the shapes majortick, minortick, target and needle give the stroke of the ticks, of the mark of the target and of the needle, the shape needlecap the brushes and the size of the circle at the center, and the text scaletext the font and the color of the numbers.
  /// </remarks>
  TS4YCircularMeter = class(TS4YCircularGauge)
  public const
    /// <summary>Color of the major ticks when the style has no majortick.</summary>
    C_DEFAULT_MAJOR_TICK_COLOR: TAlphaColor = $FF757575;
    /// <summary>Color of the minor ticks when the style has no minortick.</summary>
    C_DEFAULT_MINOR_TICK_COLOR: TAlphaColor = $FFBDBDBD;
    /// <summary>Color of the circle at the center of the needle when the style has no needlecap.</summary>
    C_DEFAULT_NEEDLE_CAP_COLOR: TAlphaColor = $FF424242;
    /// <summary>Color of the needle when the style has no needle.</summary>
    C_DEFAULT_NEEDLE_COLOR: TAlphaColor = $FFC62828;
    /// <summary>Default value of RangeBandThickness, in pixels.</summary>
    C_DEFAULT_RANGE_BAND_THICKNESS: Single = 4;
    /// <summary>Default value of RangePlacement: the ranges are drawn on the track.</summary>
    C_DEFAULT_RANGE_PLACEMENT: TS4YGaugeArcRangePlacement = [garTrack];
    /// <summary>Color of the numbers of the graduation when the style has no scaletext.</summary>
    C_DEFAULT_SCALE_TEXT_COLOR: TAlphaColor = $FF616161;
    /// <summary>Default value of ShowFill: the needle shows the value, not the fill.</summary>
    C_DEFAULT_SHOW_FILL = False;
    /// <summary>Default value of StartAngle, in degrees.</summary>
    C_DEFAULT_START_ANGLE: Single = -135;
    /// <summary>Default value of SweepAngle, in degrees: an arc open at the bottom.</summary>
    C_DEFAULT_SWEEP_ANGLE: Single = 270;
    /// <summary>Color of the mark of the target when the style has no target.</summary>
    C_DEFAULT_TARGET_COLOR: TAlphaColor = $FF212121;
  private
    FFillFromRange: Boolean;
    FGraduation: TS4YCircularMeterGraduation;
    FNeedle: TS4YCircularMeterNeedle;
    FRangeBandThickness: Single;
    FRangePlacement: TS4YGaugeArcRangePlacement;
    FRanges: TS4YMeterRanges;
    FShowFill: Boolean;
    FShowTarget: Boolean;
    FStyleMajorTick: TShape;
    FStyleMinorTick: TShape;
    FStyleNeedle: TShape;
    FStyleNeedleCap: TShape;
    FStyleScaleText: TText;
    FStyleTarget: TShape;
    FTarget: Single;
    function BandRoom(const APlace: TS4YGaugeArcRangePlace): Single;
    procedure DrawColoredArc(const ACenter: TPointF; const ARadius, AThickness, AStartFraction, AEndFraction: Single;
      const AColor: TAlphaColor; const ACap: TStrokeCap);
    procedure DrawGraduation(const ACenter: TPointF; const ARadius: Single);
    procedure DrawNeedle(const ACenter: TPointF; const ARadius: Single);
    procedure DrawRanges(const ACenter: TPointF; const ARadius, AThickness: Single; const ACap: TStrokeCap);
    procedure DrawTarget(const ACenter: TPointF; const ARadius: Single);
    procedure DrawTicks(const ACenter: TPointF; const AFromRadius: Single; const AValues: TArray<Single>;
      const AStyleTick: TShape; const ADefaultColor: TAlphaColor; const ALength: Single; Outside: Boolean);
    function GetPartCap(const APart: TObject): TStrokeCap;
    procedure GraduationChanged(Sender: TObject);
    function IsValueDrawn(const AValue: Single): Boolean;
    function IsWholeCircle: Boolean;
    function MaxLabelExtent: Single;
    function NeedleCapSize: Single;
    procedure NeedleChanged(Sender: TObject);
    procedure PrepareStroke(const AStyleShape: TShape; const ADefaultColor: TAlphaColor; const ADefaultThickness: Single);
    function RangeBandThicknessStored: Boolean;
    function RangePlacementStored: Boolean;
    procedure RangesChanged(Sender: TObject);
    function RangesStored: Boolean;
    procedure SetFillFromRange(const Value: Boolean);
    procedure SetGraduation(const Value: TS4YCircularMeterGraduation);
    procedure SetNeedle(const Value: TS4YCircularMeterNeedle);
    procedure SetRangeBandThickness(const Value: Single);
    procedure SetRangePlacement(const Value: TS4YGaugeArcRangePlacement);
    procedure SetRanges(const Value: TS4YMeterRanges);
    procedure SetShowFill(const Value: Boolean);
    procedure SetShowTarget(const Value: Boolean);
    procedure SetTarget(const Value: Single);
    function TargetStored: Boolean;
  protected
    /// <summary>Finds the ticks, the mark of the target, the needle and the text of the graduation in the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Draws the bands of the ranges, the graduation and the mark of the target.</summary>
    procedure DrawDecorations(const ACenter: TPointF; const ARadius: Single); override;
    /// <summary>Draws the filled part of the arc when ShowFill is True, with the color of the range of the value when FillFromRange is True.</summary>
    procedure DrawFill(const ACenter: TPointF; const ARadius: Single); override;
    /// <summary>Draws the needle over the texts.</summary>
    procedure DrawOverlay(const ACenter: TPointF; const ARadius: Single); override;
    /// <summary>Draws the whole track and the ranges on it.</summary>
    procedure DrawTrack(const ACenter: TPointF; const ARadius: Single); override;
    /// <summary>Releases the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control: 160 x 160.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns -135, the default value of StartAngle.</summary>
    function GetDefaultStartAngle: Single; override;
    /// <summary>Returns 270, the default value of SweepAngle.</summary>
    function GetDefaultSweepAngle: Single; override;
    /// <summary>Returns the room of what is drawn outside the arc: the graduation, the band of the ranges and the mark of the target.</summary>
    function GetOuterMargin: Single; override;
    /// <summary>Returns the distance from the center where the texts start when the needle is visible, beyond the circle at the center of the needle; 0 without the needle.</summary>
    function GetTextGapFromCenter: Single; override;
  public
    /// <summary>Creates a meter with an arc open at the bottom, a graduation inside it and a needle.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    /// <summary>True gives the fill the color of the range that contains the value; out of the ranges, the fill keeps its brush. The default is False.</summary>
    property FillFromRange: Boolean read FFillFromRange write SetFillFromRange default False;
    /// <summary>The ticks and the numbers drawn along the arc, inside or outside it.</summary>
    property Graduation: TS4YCircularMeterGraduation read FGraduation write SetGraduation;
    /// <summary>The needle that points at the value from the center of the arc, over the texts.</summary>
    property Needle: TS4YCircularMeterNeedle read FNeedle write SetNeedle;
    /// <summary>Thickness of the bands of the ranges inside and outside the arc, in pixels. The default is 4.</summary>
    property RangeBandThickness: Single read FRangeBandThickness write SetRangeBandThickness stored RangeBandThicknessStored nodefault;
    /// <summary>
    /// Where the ranges are drawn: on the track (garTrack, the default), in a thin band inside the arc (garInside), in a thin band outside it (garOutside), or in more than one of these places.
    /// </summary>
    /// <remarks>
    /// On the track the ranges are under the fill: they are seen where the fill does not cover them.
    /// </remarks>
    property RangePlacement: TS4YGaugeArcRangePlacement read FRangePlacement write SetRangePlacement stored RangePlacementStored nodefault;
    /// <summary>The ranges of values with a color of their own, for example a green, a yellow and a red zone.</summary>
    property Ranges: TS4YMeterRanges read FRanges write SetRanges stored RangesStored;
    /// <summary>True draws the filled part of the arc, as in TS4YCircularGauge. The default is False: the needle shows the value.</summary>
    property ShowFill: Boolean read FShowFill write SetShowFill default C_DEFAULT_SHOW_FILL;
    /// <summary>True marks the value of Target across the track. The default is False.</summary>
    property ShowTarget: Boolean read FShowTarget write SetShowTarget default False;
    /// <summary>The value to reach, marked across the track when ShowTarget is True. A value out of the range is marked at its nearest end.</summary>
    property Target: Single read FTarget write SetTarget stored TargetStored nodefault;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  FMX.Types,
  FMX.Controls;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_MAJOR_TICK = 'majortick';
  C_STYLE_MINOR_TICK = 'minortick';
  C_STYLE_NEEDLE = 'needle';
  C_STYLE_NEEDLE_CAP = 'needlecap';
  C_STYLE_SCALE_TEXT = 'scaletext';
  C_STYLE_TARGET = 'target';

  // Space between the track and the bands of the ranges, in pixels.
  C_BAND_SPACING = 3;
  // Diameter of the circle at the center of the needle when the style has no shape for it, in pixels.
  C_DEFAULT_NEEDLE_CAP_SIZE = 12;
  // Thickness of the needle when the style has no shape for it, in pixels.
  C_DEFAULT_NEEDLE_THICKNESS = 3;
  // Size of a new meter.
  C_DEFAULT_SIZE = 160;
  // Thickness of the mark of the target when the style has no shape for it, in pixels.
  C_DEFAULT_TARGET_THICKNESS = 3;
  // Thickness of a tick when the style has no shape for it, in pixels.
  C_DEFAULT_TICK_THICKNESS = 1.5;
  // Tolerance on the ends of the range, as a fraction of the range.
  C_FRACTION_EPSILON = 1E-4;
  // Smallest arc drawn, in degrees.
  C_MIN_DRAWN_SWEEP_ANGLE = 0.01;
  // Arc drawn with round ends to put a round end on a range, in degrees: a dot.
  C_ROUND_END_SWEEP_ANGLE = 0.1;
  // Space between the circle at the center of the needle and the texts below it, in pixels.
  C_NEEDLE_TEXT_SPACING = 4;
  // Space between the arc, the ticks and the numbers, in pixels.
  C_SCALE_SPACING = 3;
  // Length of the mark of the target beyond each side of the track, in pixels.
  C_TARGET_OVERHANG = 4;

{ TS4YCircularMeter }

constructor TS4YCircularMeter.Create(AOwner: TComponent);
begin
  inherited;

  FRangeBandThickness := C_DEFAULT_RANGE_BAND_THICKNESS;
  FRangePlacement := C_DEFAULT_RANGE_PLACEMENT;
  FShowFill := C_DEFAULT_SHOW_FILL;
  FGraduation := TS4YCircularMeterGraduation.Create;
  FGraduation.OnChange := GraduationChanged;
  FNeedle := TS4YCircularMeterNeedle.Create;
  FNeedle.OnChange := NeedleChanged;
  FRanges := TS4YMeterRanges.Create(Self);
  FRanges.OnChange := RangesChanged;
end;

destructor TS4YCircularMeter.Destroy;
begin
  FreeAndNil(FRanges);
  FreeAndNil(FNeedle);
  FreeAndNil(FGraduation);

  inherited;
end;

procedure TS4YCircularMeter.ApplyStyle;
begin
  inherited;

  FindStyleResource<TShape>(C_STYLE_MAJOR_TICK, FStyleMajorTick);
  FindStyleResource<TShape>(C_STYLE_MINOR_TICK, FStyleMinorTick);
  FindStyleResource<TShape>(C_STYLE_TARGET, FStyleTarget);
  FindStyleResource<TShape>(C_STYLE_NEEDLE, FStyleNeedle);
  FindStyleResource<TShape>(C_STYLE_NEEDLE_CAP, FStyleNeedleCap);
  FindStyleResource<TText>(C_STYLE_SCALE_TEXT, FStyleScaleText);
end;

function TS4YCircularMeter.BandRoom(const APlace: TS4YGaugeArcRangePlace): Single;
begin
  // A band takes room only when there are ranges to draw in it.
  if (FRanges.Count > 0) and (APlace in FRangePlacement) then
    Result := C_BAND_SPACING + FRangeBandThickness
  else
    Result := 0;
end;

procedure TS4YCircularMeter.DrawColoredArc(const ACenter: TPointF; const ARadius, AThickness, AStartFraction,
  AEndFraction: Single; const AColor: TAlphaColor; const ACap: TStrokeCap);
var
  LSweepAngle: Single;
begin
  LSweepAngle := SweepAngle * (AEndFraction - AStartFraction);

  if (LSweepAngle < C_MIN_DRAWN_SWEEP_ANGLE) or (AThickness <= 0) then
    Exit;

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := AColor;
  Canvas.Stroke.Thickness := AThickness;
  Canvas.Stroke.Cap := ACap;
  Canvas.Stroke.Dash := TStrokeDash.Solid;
  Canvas.DrawArc(ACenter, TPointF.Create(ARadius, ARadius), AngleOfFraction(AStartFraction),
    GetDirectedSweepAngle * (AEndFraction - AStartFraction), AbsoluteOpacity);
end;

procedure TS4YCircularMeter.DrawDecorations(const ACenter: TPointF; const ARadius: Single);
begin
  if BandRoom(garInside) > 0 then
    DrawRanges(ACenter, ARadius - Thickness / 2 - C_BAND_SPACING - FRangeBandThickness / 2, FRangeBandThickness,
      TStrokeCap.Flat);

  if BandRoom(garOutside) > 0 then
    DrawRanges(ACenter, ARadius + Thickness / 2 + C_BAND_SPACING + FRangeBandThickness / 2, FRangeBandThickness,
      TStrokeCap.Flat);

  DrawGraduation(ACenter, ARadius);

  if FShowTarget then
    DrawTarget(ACenter, ARadius);
end;

procedure TS4YCircularMeter.DrawFill(const ACenter: TPointF; const ARadius: Single);
var
  LFraction: Single;
  LRange: TS4YMeterRange;
begin
  if not FShowFill then
    Exit;

  LRange := nil;
  LFraction := GetDisplayedFraction;

  if FFillFromRange then
    LRange := FRanges.FindRange(Min + LFraction * (Max - Min));

  // The fill keeps the ends of its part of the style, with the color of the range.
  if Assigned(LRange) then
    DrawColoredArc(ACenter, ARadius, Thickness, 0, LFraction, LRange.Color, GetPartCap(FillPart))
  else
    inherited;
end;

procedure TS4YCircularMeter.DrawGraduation(const ACenter: TPointF; const ARadius: Single);
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

  // The ticks start a little away from the edge of the track, beyond the band of the ranges on the
  // same side.
  LOutside := FGraduation.Position = gasOutside;

  if LOutside then
    LFromRadius := ARadius + Thickness / 2 + BandRoom(garOutside) + C_SCALE_SPACING
  else
    LFromRadius := ARadius - Thickness / 2 - BandRoom(garInside) - C_SCALE_SPACING;

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

procedure TS4YCircularMeter.DrawNeedle(const ACenter: TPointF; const ARadius: Single);
var
  LAngle: Single;
  LCapRect: TRectF;
  LCapSize: Single;
  LLength: Single;
begin
  // A line from the center towards the value, as long as a part of the distance from the center to
  // the inner edge of the track; it follows the animation of the value.
  LAngle := DegToRad(AngleOfFraction(GetDisplayedFraction));
  LLength := System.Math.Max(0, ARadius - Thickness / 2) * FNeedle.Length / 100;

  if LLength > 0 then
  begin
    PrepareStroke(FStyleNeedle, C_DEFAULT_NEEDLE_COLOR, C_DEFAULT_NEEDLE_THICKNESS);
    Canvas.DrawLine(ACenter, TPointF.Create(ACenter.X + LLength * Cos(LAngle), ACenter.Y + LLength * Sin(LAngle)),
      AbsoluteOpacity);
  end;

  // A circle over the center, with the brushes and the width of the part of the style.
  LCapSize := NeedleCapSize;

  if Assigned(FStyleNeedleCap) then
  begin
    Canvas.Fill.Assign(FStyleNeedleCap.Fill);
    Canvas.Stroke.Assign(FStyleNeedleCap.Stroke);
  end
  else
  begin
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := C_DEFAULT_NEEDLE_CAP_COLOR;
    Canvas.Stroke.Kind := TBrushKind.None;
  end;

  if LCapSize <= 0 then
    Exit;

  LCapRect := TRectF.Create(ACenter.X - LCapSize / 2, ACenter.Y - LCapSize / 2, ACenter.X + LCapSize / 2,
    ACenter.Y + LCapSize / 2);
  Canvas.FillEllipse(LCapRect, AbsoluteOpacity);

  if Canvas.Stroke.Kind <> TBrushKind.None then
    Canvas.DrawEllipse(LCapRect, AbsoluteOpacity);
end;

procedure TS4YCircularMeter.DrawOverlay(const ACenter: TPointF; const ARadius: Single);
begin
  if FNeedle.Visible then
    DrawNeedle(ACenter, ARadius);
end;

procedure TS4YCircularMeter.DrawRanges(const ACenter: TPointF; const ARadius, AThickness: Single;
  const ACap: TStrokeCap);
var
  LEndFraction: Single;
  LRange: TS4YMeterRange;
  LStartFraction: Single;
begin
  for var I := 0 to FRanges.Count - 1 do
  begin
    LRange := FRanges[I];
    LStartFraction := GetValueFraction(LRange.LowValue);
    LEndFraction := GetValueFraction(LRange.HighValue);
    DrawColoredArc(ACenter, ARadius, AThickness, LStartFraction, LEndFraction, LRange.Color, TStrokeCap.Flat);

    // A range at an end of an arc with round ends gets a round end too, drawn as a very short arc
    // with round ends: a dot as large as the thickness, centered on the end.
    if (ACap = TStrokeCap.Round) and not IsWholeCircle and (LEndFraction > LStartFraction) then
    begin
      if LStartFraction < C_FRACTION_EPSILON then
        DrawColoredArc(ACenter, ARadius, AThickness, 0, C_ROUND_END_SWEEP_ANGLE / SweepAngle, LRange.Color,
          TStrokeCap.Round);

      if LEndFraction > 1 - C_FRACTION_EPSILON then
        DrawColoredArc(ACenter, ARadius, AThickness, 1 - C_ROUND_END_SWEEP_ANGLE / SweepAngle, 1, LRange.Color,
          TStrokeCap.Round);
    end;
  end;
end;

procedure TS4YCircularMeter.DrawTarget(const ACenter: TPointF; const ARadius: Single);
var
  LAngle: Single;
  LInnerRadius: Single;
  LOuterRadius: Single;
begin
  // A line across the track, a little longer than its thickness.
  LAngle := DegToRad(AngleOfFraction(GetValueFraction(FTarget)));
  LInnerRadius := ARadius - Thickness / 2 - C_TARGET_OVERHANG;
  LOuterRadius := ARadius + Thickness / 2 + C_TARGET_OVERHANG;
  PrepareStroke(FStyleTarget, C_DEFAULT_TARGET_COLOR, C_DEFAULT_TARGET_THICKNESS);
  Canvas.DrawLine(TPointF.Create(ACenter.X + LInnerRadius * Cos(LAngle), ACenter.Y + LInnerRadius * Sin(LAngle)),
    TPointF.Create(ACenter.X + LOuterRadius * Cos(LAngle), ACenter.Y + LOuterRadius * Sin(LAngle)), AbsoluteOpacity);
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

  PrepareStroke(AStyleTick, ADefaultColor, C_DEFAULT_TICK_THICKNESS);

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

procedure TS4YCircularMeter.DrawTrack(const ACenter: TPointF; const ARadius: Single);
begin
  inherited;

  if garTrack in FRangePlacement then
    DrawRanges(ACenter, ARadius, Thickness, GetPartCap(TrackPart));
end;

procedure TS4YCircularMeter.FreeStyle;
begin
  FStyleMajorTick := nil;
  FStyleMinorTick := nil;
  FStyleNeedle := nil;
  FStyleNeedleCap := nil;
  FStyleScaleText := nil;
  FStyleTarget := nil;

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
  Result := BandRoom(garOutside);

  if FGraduation.Visible and (FGraduation.Position = gasOutside) then
  begin
    LTickLength := FGraduation.MajorTickLength;

    if FGraduation.MinorCount > 0 then
      LTickLength := System.Math.Max(LTickLength, FGraduation.MinorTickLength);

    Result := Result + C_SCALE_SPACING + LTickLength;

    if FGraduation.ShowLabels then
      Result := Result + C_SCALE_SPACING + MaxLabelExtent;
  end;

  if FShowTarget then
    Result := System.Math.Max(Result, C_TARGET_OVERHANG);
end;

function TS4YCircularMeter.GetTextGapFromCenter: Single;
begin
  if FNeedle.Visible then
    Result := NeedleCapSize / 2 + C_NEEDLE_TEXT_SPACING
  else
    Result := 0;
end;

function TS4YCircularMeter.GetPartCap(const APart: TObject): TStrokeCap;
begin
  // The arcs of the style give their ends; another part is drawn with flat ends.
  if APart is TArc then
    Result := TArc(APart).Stroke.Cap
  else
    Result := TStrokeCap.Flat;
end;

procedure TS4YCircularMeter.GraduationChanged(Sender: TObject);
begin
  Repaint;
end;

function TS4YCircularMeter.IsValueDrawn(const AValue: Single): Boolean;
begin
  // On a whole circle the end of the range is at the same place as its start, which is drawn instead.
  Result := not IsWholeCircle or (GetValueFraction(AValue) < 1 - C_FRACTION_EPSILON);
end;

function TS4YCircularMeter.IsWholeCircle: Boolean;
begin
  Result := SweepAngle >= C_MAX_SWEEP_ANGLE - C_FRACTION_EPSILON;
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

function TS4YCircularMeter.NeedleCapSize: Single;
begin
  if Assigned(FStyleNeedleCap) then
    Result := System.Math.Max(0, FStyleNeedleCap.Width)
  else
    Result := C_DEFAULT_NEEDLE_CAP_SIZE;
end;

procedure TS4YCircularMeter.NeedleChanged(Sender: TObject);
begin
  Repaint;
end;

procedure TS4YCircularMeter.PrepareStroke(const AStyleShape: TShape; const ADefaultColor: TAlphaColor;
  const ADefaultThickness: Single);
begin
  if Assigned(AStyleShape) then
    Canvas.Stroke.Assign(AStyleShape.Stroke)
  else
  begin
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := ADefaultColor;
    Canvas.Stroke.Thickness := ADefaultThickness;
    Canvas.Stroke.Cap := TStrokeCap.Flat;
    Canvas.Stroke.Dash := TStrokeDash.Solid;
  end;
end;

function TS4YCircularMeter.RangeBandThicknessStored: Boolean;
begin
  Result := not SameValue(FRangeBandThickness, C_DEFAULT_RANGE_BAND_THICKNESS);
end;

function TS4YCircularMeter.RangePlacementStored: Boolean;
begin
  Result := FRangePlacement <> C_DEFAULT_RANGE_PLACEMENT;
end;

procedure TS4YCircularMeter.RangesChanged(Sender: TObject);
begin
  Repaint;
end;

function TS4YCircularMeter.RangesStored: Boolean;
begin
  // An empty collection is not written to the form.
  Result := FRanges.Count > 0;
end;

procedure TS4YCircularMeter.SetFillFromRange(const Value: Boolean);
begin
  if FFillFromRange = Value then
    Exit;

  FFillFromRange := Value;
  Repaint;
end;

procedure TS4YCircularMeter.SetGraduation(const Value: TS4YCircularMeterGraduation);
begin
  FGraduation.Assign(Value);
end;

procedure TS4YCircularMeter.SetNeedle(const Value: TS4YCircularMeterNeedle);
begin
  FNeedle.Assign(Value);
end;

procedure TS4YCircularMeter.SetRangeBandThickness(const Value: Single);
begin
  if SameValue(FRangeBandThickness, Value) then
    Exit;

  FRangeBandThickness := System.Math.Max(0, Value);
  Repaint;
end;

procedure TS4YCircularMeter.SetRangePlacement(const Value: TS4YGaugeArcRangePlacement);
begin
  if FRangePlacement = Value then
    Exit;

  FRangePlacement := Value;
  Repaint;
end;

procedure TS4YCircularMeter.SetRanges(const Value: TS4YMeterRanges);
begin
  FRanges.Assign(Value);
end;

procedure TS4YCircularMeter.SetShowFill(const Value: Boolean);
begin
  if FShowFill = Value then
    Exit;

  FShowFill := Value;
  Repaint;
end;

procedure TS4YCircularMeter.SetShowTarget(const Value: Boolean);
begin
  if FShowTarget = Value then
    Exit;

  FShowTarget := Value;
  Repaint;
end;

procedure TS4YCircularMeter.SetTarget(const Value: Single);
begin
  // Compared exactly: SameValue would take a value very near 0 for 0.
  if FTarget = Value then
    Exit;

  FTarget := Value;
  Repaint;
end;

function TS4YCircularMeter.TargetStored: Boolean;
begin
  Result := FTarget <> 0;
end;

end.
