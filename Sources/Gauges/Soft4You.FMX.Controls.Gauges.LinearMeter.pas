unit Soft4You.FMX.Controls.Gauges.LinearMeter;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YLinearMeter - linear gauge with a graduation, like a ruler or a thermometer
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
  FMX.Objects,
  Soft4You.FMX.Controls.Gauges.Types,
  Soft4You.FMX.Controls.Gauges.Scales,
  Soft4You.FMX.Controls.Gauges.Linear;

type
  /// <summary>
  /// A linear gauge with a graduation along the bar, like a ruler or a thermometer, with a pointer, colored ranges and a target value.
  /// </summary>
  /// <remarks>
  /// Graduation gives the ticks and their numbers, on one side of the bar; the bar, the graduation and the texts are kept together in the middle of the control.
  /// Pointer adds a small triangle beside the bar that points at the value; ShowFill can hide the fill, to show the value with the pointer only.
  /// Ranges color parts of the scale, on the bar or in thin bands beside it (RangePlacement); FillFromRange gives the fill the color of the range of the value. ShowTarget marks the value of Target across the bar.
  /// The style is S4YLinearMeterStyle: besides the parts of S4YLinearGaugeStyle, the shapes majortick, minortick and target give the stroke of the ticks and of the mark of the target, the shape pointer the brushes and the size of the pointer, and the text scaletext the font and the color of the numbers.
  /// </remarks>
  TS4YLinearMeter = class(TS4YLinearGauge)
  public const
    /// <summary>Color of the major ticks when the style has no majortick.</summary>
    C_DEFAULT_MAJOR_TICK_COLOR: TAlphaColor = $FF757575;
    /// <summary>Color of the minor ticks when the style has no minortick.</summary>
    C_DEFAULT_MINOR_TICK_COLOR: TAlphaColor = $FFBDBDBD;
    /// <summary>Color of the pointer when the style has no pointer.</summary>
    C_DEFAULT_POINTER_COLOR: TAlphaColor = $FF424242;
    /// <summary>Default value of RangeBandThickness, in pixels.</summary>
    C_DEFAULT_RANGE_BAND_THICKNESS: Single = 4;
    /// <summary>Default value of RangePlacement: the ranges are drawn on the bar.</summary>
    C_DEFAULT_RANGE_PLACEMENT: TS4YGaugeBarRangePlacement = [gbrTrack];
    /// <summary>Color of the numbers of the graduation when the style has no scaletext.</summary>
    C_DEFAULT_SCALE_TEXT_COLOR: TAlphaColor = $FF616161;
    /// <summary>Default value of ShowFill.</summary>
    C_DEFAULT_SHOW_FILL = True;
    /// <summary>Color of the mark of the target when the style has no target.</summary>
    C_DEFAULT_TARGET_COLOR: TAlphaColor = $FF212121;
  private
    FFillFromRange: Boolean;
    FGraduation: TS4YLinearMeterGraduation;
    FPointer: TS4YLinearMeterPointer;
    FRangeBandThickness: Single;
    FRangePlacement: TS4YGaugeBarRangePlacement;
    FRanges: TS4YMeterRanges;
    FShowFill: Boolean;
    FShowTarget: Boolean;
    FStyleMajorTick: TShape;
    FStyleMinorTick: TShape;
    FStylePointer: TShape;
    FStyleScaleText: TText;
    FStyleTarget: TShape;
    FTarget: Single;
    function BandRoom(const APlace: TS4YGaugeBarRangePlace): Single;
    procedure DrawBand(const ABarRect: TRectF; const APlace: TS4YGaugeBarRangePlace);
    procedure DrawGraduation(const ABarRect: TRectF);
    procedure DrawPointer(const ABarRect: TRectF);
    procedure DrawTarget(const ABarRect: TRectF);
    procedure DrawTicks(const ABarRect: TRectF; const AValues: TArray<Single>; const AStyleTick: TShape;
      const ADefaultColor: TAlphaColor; const ALength: Single);
    procedure FillSegment(const ARect: TRectF; const AColor: TAlphaColor; const ARadius: Single;
      const ACorners: TCorners);
    function GetEndCorners: TCorners;
    function GetGraduationExtent: Single;
    function GetPartCorners(const APart: TObject): TCorners;
    function GetPartRadius(const APart: TObject): Single;
    function GetStartCorners: TCorners;
    procedure GraduationChanged(Sender: TObject);
    function MaxLabelSize: TSizeF;
    procedure PointerChanged(Sender: TObject);
    function PointerRoom(const ASide: TS4YGaugeBarSide): Single;
    function PointerSize: TSizeF;
    procedure PrepareStroke(const AStyleShape: TShape; const ADefaultColor: TAlphaColor; const ADefaultThickness: Single);
    function RangeBandThicknessStored: Boolean;
    function RangePlacementStored: Boolean;
    procedure RangesChanged(Sender: TObject);
    function RangesStored: Boolean;
    procedure SetFillFromRange(const Value: Boolean);
    procedure SetGraduation(const Value: TS4YLinearMeterGraduation);
    procedure SetPointer(const Value: TS4YLinearMeterPointer);
    procedure SetRangeBandThickness(const Value: Single);
    procedure SetRangePlacement(const Value: TS4YGaugeBarRangePlacement);
    procedure SetRanges(const Value: TS4YMeterRanges);
    procedure SetShowFill(const Value: Boolean);
    procedure SetShowTarget(const Value: Boolean);
    procedure SetTarget(const Value: Single);
    function TargetStored: Boolean;
    function TickStart(const ABarRect: TRectF): Single;
  protected
    /// <summary>Finds the ticks, the mark of the target, the pointer and the text of the graduation in the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Draws the bands of the ranges, the graduation, the mark of the target and the pointer.</summary>
    procedure DrawDecorations(const ABarRect: TRectF); override;
    /// <summary>Draws the filled part of the bar when ShowFill is True, with the color of the range of the value when FillFromRange is True.</summary>
    procedure DrawFill(const ABarRect: TRectF); override;
    /// <summary>Draws the whole track and the ranges on it.</summary>
    procedure DrawTrack(const ABarRect: TRectF); override;
    /// <summary>Releases the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the room of what is drawn beside the bar: the graduation, the bands of the ranges, the pointer and the mark of the target.</summary>
    procedure GetBarMargins(out ABefore, AAfter: Single); override;
    /// <summary>Returns the size of a new control: 240 x 64.</summary>
    function GetDefaultSize: TSizeF; override;
  public
    /// <summary>Creates a horizontal meter with a graduation under the bar.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    /// <summary>True gives the fill the color of the range that contains the value; out of the ranges, the fill keeps its brush. The default is False.</summary>
    property FillFromRange: Boolean read FFillFromRange write SetFillFromRange default False;
    /// <summary>The ticks and the numbers drawn along the bar, on one of its sides.</summary>
    property Graduation: TS4YLinearMeterGraduation read FGraduation write SetGraduation;
    /// <summary>The small triangle beside the bar that points at the value; hidden by default.</summary>
    property Pointer: TS4YLinearMeterPointer read FPointer write SetPointer;
    /// <summary>Thickness of the bands of the ranges beside the bar, in pixels. The default is 4.</summary>
    property RangeBandThickness: Single read FRangeBandThickness write SetRangeBandThickness stored RangeBandThicknessStored nodefault;
    /// <summary>
    /// Where the ranges are drawn: on the bar (gbrTrack, the default), in a thin band before it (gbrBefore: above a horizontal bar, on the left of a vertical one), in a thin band after it (gbrAfter), or in more than one of these places.
    /// </summary>
    /// <remarks>
    /// On the bar the ranges are under the fill: they are seen where the fill does not cover them.
    /// </remarks>
    property RangePlacement: TS4YGaugeBarRangePlacement read FRangePlacement write SetRangePlacement stored RangePlacementStored nodefault;
    /// <summary>The ranges of values with a color of their own, for example a green, a yellow and a red zone.</summary>
    property Ranges: TS4YMeterRanges read FRanges write SetRanges stored RangesStored;
    /// <summary>True draws the filled part of the bar. The default is True; with False the pointer shows the value.</summary>
    property ShowFill: Boolean read FShowFill write SetShowFill default C_DEFAULT_SHOW_FILL;
    /// <summary>True marks the value of Target across the bar. The default is False.</summary>
    property ShowTarget: Boolean read FShowTarget write SetShowTarget default False;
    /// <summary>The value to reach, marked across the bar when ShowTarget is True. A value out of the range is marked at its nearest end.</summary>
    property Target: Single read FTarget write SetTarget stored TargetStored nodefault;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.Math.Vectors,
  FMX.Controls,
  FMX.Graphics;

{$IF DEFINED(IOS)}
{$R *.ios.res}
{$ELSEIF DEFINED(MACOS)}
{$R *.mac.res}
{$ELSEIF DEFINED(ANDROID)}
{$R *.android.res}
{$ELSEIF DEFINED(MSWINDOWS)}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_MAJOR_TICK = 'majortick';
  C_STYLE_MINOR_TICK = 'minortick';
  C_STYLE_POINTER = 'pointer';
  C_STYLE_SCALE_TEXT = 'scaletext';
  C_STYLE_TARGET = 'target';

  // Space between the bar and the bands of the ranges, in pixels.
  C_BAND_SPACING = 3;
  // Size of the pointer when the style has no shape for it, in pixels: along the bar and away from it.
  C_DEFAULT_POINTER_WIDTH = 10;
  C_DEFAULT_POINTER_HEIGHT = 8;
  // Size of a new meter.
  C_DEFAULT_WIDTH = 240;
  C_DEFAULT_HEIGHT = 64;
  // Thickness of the mark of the target when the style has no shape for it, in pixels.
  C_DEFAULT_TARGET_THICKNESS = 3;
  // Thickness of a tick when the style has no shape for it, in pixels.
  C_DEFAULT_TICK_THICKNESS = 1.5;
  // Tolerance on the ends of the range, as a fraction of the range.
  C_FRACTION_EPSILON = 1E-4;
  // Space between the bar, the ticks and the numbers, in pixels.
  C_SCALE_SPACING = 3;
  // Length of the mark of the target beyond each side of the bar, in pixels.
  C_TARGET_OVERHANG = 4;

{ TS4YLinearMeter }

constructor TS4YLinearMeter.Create(AOwner: TComponent);
begin
  inherited;

  FRangeBandThickness := C_DEFAULT_RANGE_BAND_THICKNESS;
  FRangePlacement := C_DEFAULT_RANGE_PLACEMENT;
  FShowFill := C_DEFAULT_SHOW_FILL;
  FGraduation := TS4YLinearMeterGraduation.Create;
  FGraduation.OnChange := GraduationChanged;
  FPointer := TS4YLinearMeterPointer.Create;
  FPointer.OnChange := PointerChanged;
  FRanges := TS4YMeterRanges.Create(Self);
  FRanges.OnChange := RangesChanged;
end;

destructor TS4YLinearMeter.Destroy;
begin
  FreeAndNil(FRanges);
  FreeAndNil(FPointer);
  FreeAndNil(FGraduation);

  inherited;
end;

procedure TS4YLinearMeter.ApplyStyle;
begin
  inherited;

  FindStyleResource<TShape>(C_STYLE_MAJOR_TICK, FStyleMajorTick);
  FindStyleResource<TShape>(C_STYLE_MINOR_TICK, FStyleMinorTick);
  FindStyleResource<TShape>(C_STYLE_TARGET, FStyleTarget);
  FindStyleResource<TShape>(C_STYLE_POINTER, FStylePointer);
  FindStyleResource<TText>(C_STYLE_SCALE_TEXT, FStyleScaleText);
end;

function TS4YLinearMeter.BandRoom(const APlace: TS4YGaugeBarRangePlace): Single;
begin
  // A band takes room only when there are ranges to draw in it.
  if (FRanges.Count > 0) and (APlace in FRangePlacement) then
    Result := C_BAND_SPACING + FRangeBandThickness
  else
    Result := 0;
end;

procedure TS4YLinearMeter.DrawBand(const ABarRect: TRectF; const APlace: TS4YGaugeBarRangePlace);
var
  LBandRect: TRectF;
  LRange: TS4YMeterRange;
begin
  if BandRoom(APlace) <= 0 then
    Exit;

  // The band runs along the bar, a little away from it.
  LBandRect := ABarRect;

  if (Orientation = TOrientation.Horizontal) and (APlace = gbrBefore) then
  begin
    LBandRect.Bottom := ABarRect.Top - C_BAND_SPACING;
    LBandRect.Top := LBandRect.Bottom - FRangeBandThickness;
  end
  else if Orientation = TOrientation.Horizontal then
  begin
    LBandRect.Top := ABarRect.Bottom + C_BAND_SPACING;
    LBandRect.Bottom := LBandRect.Top + FRangeBandThickness;
  end
  else if APlace = gbrBefore then
  begin
    LBandRect.Right := ABarRect.Left - C_BAND_SPACING;
    LBandRect.Left := LBandRect.Right - FRangeBandThickness;
  end
  else
  begin
    LBandRect.Left := ABarRect.Right + C_BAND_SPACING;
    LBandRect.Right := LBandRect.Left + FRangeBandThickness;
  end;

  for var I := 0 to FRanges.Count - 1 do
  begin
    LRange := FRanges[I];
    FillSegment(BarSegment(LBandRect, GetValueFraction(LRange.LowValue), GetValueFraction(LRange.HighValue)),
      LRange.Color, 0, []);
  end;
end;

procedure TS4YLinearMeter.DrawDecorations(const ABarRect: TRectF);
begin
  DrawBand(ABarRect, gbrBefore);
  DrawBand(ABarRect, gbrAfter);
  DrawGraduation(ABarRect);

  if FShowTarget then
    DrawTarget(ABarRect);

  if FPointer.Visible then
    DrawPointer(ABarRect);
end;

procedure TS4YLinearMeter.DrawFill(const ABarRect: TRectF);
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

  // The fill keeps the corners of its rectangle of the style, with the color of the range.
  if Assigned(LRange) then
    FillSegment(BarSegment(ABarRect, 0, LFraction), LRange.Color, GetPartRadius(FillPart), GetPartCorners(FillPart))
  else
    inherited;
end;

procedure TS4YLinearMeter.DrawGraduation(const ABarRect: TRectF);
var
  LContentRect: TRectF;
  LLabelStart: Single;
  LMajorValues: TArray<Single>;
  LPosition: Single;
  LText: string;
  LTextRect: TRectF;
  LTextSize: TSizeF;
begin
  if not FGraduation.Visible then
    Exit;

  LMajorValues := FGraduation.GetMajorValues(Min, Max);
  DrawTicks(ABarRect, FGraduation.GetMinorValues(Min, Max), FStyleMinorTick, C_DEFAULT_MINOR_TICK_COLOR,
    FGraduation.MinorTickLength);
  DrawTicks(ABarRect, LMajorValues, FStyleMajorTick, C_DEFAULT_MAJOR_TICK_COLOR, FGraduation.MajorTickLength);

  if not FGraduation.ShowLabels then
    Exit;

  // The numbers are beyond the major ticks, centered on them; the ones at the ends of the bar are
  // moved inside the control instead of being cut.
  LContentRect := GetContentRect;

  if FGraduation.Position = gbsAfter then
    LLabelStart := TickStart(ABarRect) + FGraduation.MajorTickLength + C_SCALE_SPACING
  else
    LLabelStart := TickStart(ABarRect) - FGraduation.MajorTickLength - C_SCALE_SPACING;

  for var I := 0 to High(LMajorValues) do
  begin
    LText := FGraduation.FormatLabel(LMajorValues[I]);
    LTextSize := MeasureText(FStyleScaleText, C_DEFAULT_SCALE_TEXT_COLOR, LText);
    LPosition := BarPosition(ABarRect, GetValueFraction(LMajorValues[I]));

    if Orientation = TOrientation.Horizontal then
    begin
      LTextRect.Left := EnsureRange(LPosition - LTextSize.Width / 2, LContentRect.Left,
        System.Math.Max(LContentRect.Left, LContentRect.Right - LTextSize.Width));
      LTextRect.Right := LTextRect.Left + LTextSize.Width;

      if FGraduation.Position = gbsAfter then
        LTextRect.Top := LLabelStart
      else
        LTextRect.Top := LLabelStart - LTextSize.Height;

      LTextRect.Bottom := LTextRect.Top + LTextSize.Height;
    end
    else
    begin
      LTextRect.Top := EnsureRange(LPosition - LTextSize.Height / 2, LContentRect.Top,
        System.Math.Max(LContentRect.Top, LContentRect.Bottom - LTextSize.Height));
      LTextRect.Bottom := LTextRect.Top + LTextSize.Height;

      // The numbers are aligned towards the bar: on the left of it, on their right side.
      if FGraduation.Position = gbsAfter then
        LTextRect.Left := LLabelStart
      else
        LTextRect.Left := LLabelStart - LTextSize.Width;

      LTextRect.Right := LTextRect.Left + LTextSize.Width;
    end;

    RenderText(FStyleScaleText, C_DEFAULT_SCALE_TEXT_COLOR, LText, LTextRect, TTextAlign.Center, TTextAlign.Center);
  end;
end;

procedure TS4YLinearMeter.DrawPointer(const ABarRect: TRectF);
var
  LBase: Single;
  LEdge: Single;
  LPolygon: TPolygon;
  LPosition: Single;
  LSize: TSizeF;
begin
  // A triangle with its tip on the edge of the bar, or of the band of the ranges on the same side,
  // that follows the animation of the value.
  LSize := PointerSize;
  LPosition := BarPosition(ABarRect, GetDisplayedFraction);

  if (Orientation = TOrientation.Horizontal) and (FPointer.Position = gbsBefore) then
  begin
    LEdge := ABarRect.Top - BandRoom(gbrBefore);
    LBase := LEdge - LSize.Height;
  end
  else if Orientation = TOrientation.Horizontal then
  begin
    LEdge := ABarRect.Bottom + BandRoom(gbrAfter);
    LBase := LEdge + LSize.Height;
  end
  else if FPointer.Position = gbsBefore then
  begin
    LEdge := ABarRect.Left - BandRoom(gbrBefore);
    LBase := LEdge - LSize.Height;
  end
  else
  begin
    LEdge := ABarRect.Right + BandRoom(gbrAfter);
    LBase := LEdge + LSize.Height;
  end;

  System.SetLength(LPolygon, 4);

  if Orientation = TOrientation.Horizontal then
  begin
    LPolygon[0] := TPointF.Create(LPosition, LEdge);
    LPolygon[1] := TPointF.Create(LPosition - LSize.Width / 2, LBase);
    LPolygon[2] := TPointF.Create(LPosition + LSize.Width / 2, LBase);
  end
  else
  begin
    LPolygon[0] := TPointF.Create(LEdge, LPosition);
    LPolygon[1] := TPointF.Create(LBase, LPosition - LSize.Width / 2);
    LPolygon[2] := TPointF.Create(LBase, LPosition + LSize.Width / 2);
  end;

  LPolygon[3] := LPolygon[0];

  if Assigned(FStylePointer) then
  begin
    Canvas.Fill.Assign(FStylePointer.Fill);
    Canvas.Stroke.Assign(FStylePointer.Stroke);
  end
  else
  begin
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := C_DEFAULT_POINTER_COLOR;
    Canvas.Stroke.Kind := TBrushKind.None;
  end;

  Canvas.FillPolygon(LPolygon, AbsoluteOpacity);

  if Canvas.Stroke.Kind <> TBrushKind.None then
    Canvas.DrawPolygon(LPolygon, AbsoluteOpacity);
end;

procedure TS4YLinearMeter.DrawTarget(const ABarRect: TRectF);
var
  LPosition: Single;
begin
  // A line across the bar, a little longer than its thickness.
  LPosition := BarPosition(ABarRect, GetValueFraction(FTarget));
  PrepareStroke(FStyleTarget, C_DEFAULT_TARGET_COLOR, C_DEFAULT_TARGET_THICKNESS);

  if Orientation = TOrientation.Horizontal then
    Canvas.DrawLine(TPointF.Create(LPosition, ABarRect.Top - C_TARGET_OVERHANG),
      TPointF.Create(LPosition, ABarRect.Bottom + C_TARGET_OVERHANG), AbsoluteOpacity)
  else
    Canvas.DrawLine(TPointF.Create(ABarRect.Left - C_TARGET_OVERHANG, LPosition),
      TPointF.Create(ABarRect.Right + C_TARGET_OVERHANG, LPosition), AbsoluteOpacity);
end;

procedure TS4YLinearMeter.DrawTicks(const ABarRect: TRectF; const AValues: TArray<Single>; const AStyleTick: TShape;
  const ADefaultColor: TAlphaColor; const ALength: Single);
var
  LEnd: Single;
  LPosition: Single;
  LStart: Single;
begin
  if (ALength <= 0) or (Length(AValues) = 0) then
    Exit;

  LStart := TickStart(ABarRect);

  if FGraduation.Position = gbsAfter then
    LEnd := LStart + ALength
  else
    LEnd := LStart - ALength;

  PrepareStroke(AStyleTick, ADefaultColor, C_DEFAULT_TICK_THICKNESS);

  for var I := 0 to High(AValues) do
  begin
    LPosition := BarPosition(ABarRect, GetValueFraction(AValues[I]));

    if Orientation = TOrientation.Horizontal then
      Canvas.DrawLine(TPointF.Create(LPosition, LStart), TPointF.Create(LPosition, LEnd), AbsoluteOpacity)
    else
      Canvas.DrawLine(TPointF.Create(LStart, LPosition), TPointF.Create(LEnd, LPosition), AbsoluteOpacity);
  end;
end;

procedure TS4YLinearMeter.DrawTrack(const ABarRect: TRectF);
var
  LCorners: TCorners;
  LEndFraction: Single;
  LRadius: Single;
  LRange: TS4YMeterRange;
  LStartFraction: Single;
  LTrackCorners: TCorners;
begin
  inherited;

  if not (gbrTrack in FRangePlacement) then
    Exit;

  // A range at an end of the bar takes the rounded corners of the track at that end.
  LRadius := GetPartRadius(TrackPart);
  LTrackCorners := GetPartCorners(TrackPart);

  for var I := 0 to FRanges.Count - 1 do
  begin
    LRange := FRanges[I];
    LStartFraction := GetValueFraction(LRange.LowValue);
    LEndFraction := GetValueFraction(LRange.HighValue);
    LCorners := [];

    if LStartFraction < C_FRACTION_EPSILON then
      LCorners := LCorners + GetStartCorners;

    if LEndFraction > 1 - C_FRACTION_EPSILON then
      LCorners := LCorners + GetEndCorners;

    FillSegment(BarSegment(ABarRect, LStartFraction, LEndFraction), LRange.Color, LRadius, LCorners * LTrackCorners);
  end;
end;

procedure TS4YLinearMeter.FillSegment(const ARect: TRectF; const AColor: TAlphaColor; const ARadius: Single;
  const ACorners: TCorners);
var
  LRadius: Single;
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  // The corners cannot be rounder than half of the rectangle.
  LRadius := System.Math.Min(ARadius, System.Math.Min(ARect.Width, ARect.Height) / 2);
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := AColor;
  Canvas.FillRect(ARect, LRadius, LRadius, ACorners, AbsoluteOpacity);
end;

procedure TS4YLinearMeter.FreeStyle;
begin
  FStyleMajorTick := nil;
  FStyleMinorTick := nil;
  FStylePointer := nil;
  FStyleScaleText := nil;
  FStyleTarget := nil;

  inherited;
end;

procedure TS4YLinearMeter.GetBarMargins(out ABefore, AAfter: Single);
begin
  ABefore := BandRoom(gbrBefore) + PointerRoom(gbsBefore);
  AAfter := BandRoom(gbrAfter) + PointerRoom(gbsAfter);

  if FGraduation.Position = gbsAfter then
    AAfter := AAfter + GetGraduationExtent
  else
    ABefore := ABefore + GetGraduationExtent;

  if FShowTarget then
  begin
    ABefore := System.Math.Max(ABefore, C_TARGET_OVERHANG);
    AAfter := System.Math.Max(AAfter, C_TARGET_OVERHANG);
  end;
end;

function TS4YLinearMeter.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_WIDTH, C_DEFAULT_HEIGHT);
end;

function TS4YLinearMeter.GetEndCorners: TCorners;
begin
  // The end of the scale: the right side of a horizontal bar, the top of a vertical one.
  if Orientation = TOrientation.Horizontal then
    Result := [TCorner.TopRight, TCorner.BottomRight]
  else
    Result := [TCorner.TopLeft, TCorner.TopRight];
end;

function TS4YLinearMeter.GetGraduationExtent: Single;
var
  LTickLength: Single;
begin
  if not FGraduation.Visible then
    Exit(0);

  LTickLength := FGraduation.MajorTickLength;

  if FGraduation.MinorCount > 0 then
    LTickLength := System.Math.Max(LTickLength, FGraduation.MinorTickLength);

  Result := C_SCALE_SPACING + LTickLength;

  if not FGraduation.ShowLabels then
    Exit;

  // Beside a horizontal bar the numbers take their height, beside a vertical one their width.
  if Orientation = TOrientation.Horizontal then
    Result := Result + C_SCALE_SPACING + MaxLabelSize.Height
  else
    Result := Result + C_SCALE_SPACING + MaxLabelSize.Width;
end;

function TS4YLinearMeter.GetPartCorners(const APart: TObject): TCorners;
begin
  if APart is TRectangle then
    Result := TRectangle(APart).Corners
  else
    Result := [];
end;

function TS4YLinearMeter.GetPartRadius(const APart: TObject): Single;
begin
  // The rectangles of the style give their rounded corners; another part gives square ones.
  if APart is TRectangle then
    Result := System.Math.Min(TRectangle(APart).XRadius, TRectangle(APart).YRadius)
  else
    Result := 0;
end;

function TS4YLinearMeter.GetStartCorners: TCorners;
begin
  // The start of the scale: the left side of a horizontal bar, the bottom of a vertical one.
  if Orientation = TOrientation.Horizontal then
    Result := [TCorner.TopLeft, TCorner.BottomLeft]
  else
    Result := [TCorner.BottomLeft, TCorner.BottomRight];
end;

procedure TS4YLinearMeter.GraduationChanged(Sender: TObject);
begin
  Repaint;
end;

function TS4YLinearMeter.MaxLabelSize: TSizeF;
var
  LMajorValues: TArray<Single>;
  LTextSize: TSizeF;
begin
  Result := TSizeF.Create(0, 0);
  LMajorValues := FGraduation.GetMajorValues(Min, Max);

  for var I := 0 to High(LMajorValues) do
  begin
    LTextSize := MeasureText(FStyleScaleText, C_DEFAULT_SCALE_TEXT_COLOR, FGraduation.FormatLabel(LMajorValues[I]));
    Result.Width := System.Math.Max(Result.Width, LTextSize.Width);
    Result.Height := System.Math.Max(Result.Height, LTextSize.Height);
  end;
end;

procedure TS4YLinearMeter.PointerChanged(Sender: TObject);
begin
  Repaint;
end;

function TS4YLinearMeter.PointerRoom(const ASide: TS4YGaugeBarSide): Single;
begin
  if FPointer.Visible and (FPointer.Position = ASide) then
    Result := PointerSize.Height
  else
    Result := 0;
end;

function TS4YLinearMeter.PointerSize: TSizeF;
begin
  // The part of the style gives the size of the triangle: its width along the bar, its height away
  // from it.
  if Assigned(FStylePointer) then
    Result := TSizeF.Create(System.Math.Max(0, FStylePointer.Width), System.Math.Max(0, FStylePointer.Height))
  else
    Result := TSizeF.Create(C_DEFAULT_POINTER_WIDTH, C_DEFAULT_POINTER_HEIGHT);
end;

procedure TS4YLinearMeter.PrepareStroke(const AStyleShape: TShape; const ADefaultColor: TAlphaColor;
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

function TS4YLinearMeter.RangeBandThicknessStored: Boolean;
begin
  Result := not SameValue(FRangeBandThickness, C_DEFAULT_RANGE_BAND_THICKNESS);
end;

function TS4YLinearMeter.RangePlacementStored: Boolean;
begin
  Result := FRangePlacement <> C_DEFAULT_RANGE_PLACEMENT;
end;

procedure TS4YLinearMeter.RangesChanged(Sender: TObject);
begin
  Repaint;
end;

function TS4YLinearMeter.RangesStored: Boolean;
begin
  // An empty collection is not written to the form.
  Result := FRanges.Count > 0;
end;

procedure TS4YLinearMeter.SetFillFromRange(const Value: Boolean);
begin
  if FFillFromRange = Value then
    Exit;

  FFillFromRange := Value;
  Repaint;
end;

procedure TS4YLinearMeter.SetGraduation(const Value: TS4YLinearMeterGraduation);
begin
  FGraduation.Assign(Value);
end;

procedure TS4YLinearMeter.SetPointer(const Value: TS4YLinearMeterPointer);
begin
  FPointer.Assign(Value);
end;

procedure TS4YLinearMeter.SetRangeBandThickness(const Value: Single);
begin
  if SameValue(FRangeBandThickness, Value) then
    Exit;

  FRangeBandThickness := System.Math.Max(0, Value);
  Repaint;
end;

procedure TS4YLinearMeter.SetRangePlacement(const Value: TS4YGaugeBarRangePlacement);
begin
  if FRangePlacement = Value then
    Exit;

  FRangePlacement := Value;
  Repaint;
end;

procedure TS4YLinearMeter.SetRanges(const Value: TS4YMeterRanges);
begin
  FRanges.Assign(Value);
end;

procedure TS4YLinearMeter.SetShowFill(const Value: Boolean);
begin
  if FShowFill = Value then
    Exit;

  FShowFill := Value;
  Repaint;
end;

procedure TS4YLinearMeter.SetShowTarget(const Value: Boolean);
begin
  if FShowTarget = Value then
    Exit;

  FShowTarget := Value;
  Repaint;
end;

procedure TS4YLinearMeter.SetTarget(const Value: Single);
begin
  // Compared exactly: SameValue would take a value very near 0 for 0.
  if FTarget = Value then
    Exit;

  FTarget := Value;
  Repaint;
end;

function TS4YLinearMeter.TargetStored: Boolean;
begin
  Result := FTarget <> 0;
end;

function TS4YLinearMeter.TickStart(const ABarRect: TRectF): Single;
begin
  // The ticks start a little away from the bar, beyond the band of the ranges and the pointer on the
  // same side.
  if Orientation = TOrientation.Horizontal then
  begin
    if FGraduation.Position = gbsAfter then
      Result := ABarRect.Bottom + BandRoom(gbrAfter) + PointerRoom(gbsAfter) + C_SCALE_SPACING
    else
      Result := ABarRect.Top - BandRoom(gbrBefore) - PointerRoom(gbsBefore) - C_SCALE_SPACING;
  end
  else
  begin
    if FGraduation.Position = gbsAfter then
      Result := ABarRect.Right + BandRoom(gbrAfter) + PointerRoom(gbsAfter) + C_SCALE_SPACING
    else
      Result := ABarRect.Left - BandRoom(gbrBefore) - PointerRoom(gbsBefore) - C_SCALE_SPACING;
  end;
end;

end.
