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
  FMX.Objects,
  Soft4You.FMX.Controls.Gauges.Scales,
  Soft4You.FMX.Controls.Gauges.Linear;

type
  /// <summary>
  /// A linear gauge with a graduation along the bar, like a ruler or a thermometer.
  /// </summary>
  /// <remarks>
  /// Graduation gives the ticks and their numbers, on one side of the bar; the bar, the graduation and the texts are kept together in the middle of the control.
  /// The style is S4YLinearMeterStyle: besides the parts of S4YLinearGaugeStyle, the shapes majortick and minortick give the stroke of the ticks and the text scaletext the font and the color of the numbers.
  /// </remarks>
  TS4YLinearMeter = class(TS4YLinearGauge)
  public const
    /// <summary>Color of the major ticks when the style has no majortick.</summary>
    C_DEFAULT_MAJOR_TICK_COLOR: TAlphaColor = $FF757575;
    /// <summary>Color of the minor ticks when the style has no minortick.</summary>
    C_DEFAULT_MINOR_TICK_COLOR: TAlphaColor = $FFBDBDBD;
    /// <summary>Color of the numbers of the graduation when the style has no scaletext.</summary>
    C_DEFAULT_SCALE_TEXT_COLOR: TAlphaColor = $FF616161;
  private
    FGraduation: TS4YLinearMeterGraduation;
    FStyleMajorTick: TShape;
    FStyleMinorTick: TShape;
    FStyleScaleText: TText;
    procedure DrawTicks(const ABarRect: TRectF; const AValues: TArray<Single>; const AStyleTick: TShape;
      const ADefaultColor: TAlphaColor; const ALength: Single);
    function GetGraduationExtent: Single;
    procedure GraduationChanged(Sender: TObject);
    function MaxLabelSize: TSizeF;
    procedure PrepareTickStroke(const AStyleTick: TShape; const ADefaultColor: TAlphaColor);
    procedure SetGraduation(const Value: TS4YLinearMeterGraduation);
    function TickStart(const ABarRect: TRectF): Single;
  protected
    /// <summary>Finds the ticks and the text of the graduation in the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Draws the graduation.</summary>
    procedure DrawDecorations(const ABarRect: TRectF); override;
    /// <summary>Releases the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the room of the graduation on its side of the bar.</summary>
    procedure GetBarMargins(out ABefore, AAfter: Single); override;
    /// <summary>Returns the size of a new control: 240 x 64.</summary>
    function GetDefaultSize: TSizeF; override;
  public
    /// <summary>Creates a horizontal meter with a graduation under the bar.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    /// <summary>The ticks and the numbers drawn along the bar, on one of its sides.</summary>
    property Graduation: TS4YLinearMeterGraduation read FGraduation write SetGraduation;
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
  C_DEFAULT_WIDTH = 240;
  C_DEFAULT_HEIGHT = 64;
  // Thickness of a tick when the style has no shape for it, in pixels.
  C_DEFAULT_TICK_THICKNESS = 1.5;
  // Space between the bar, the ticks and the numbers, in pixels.
  C_SCALE_SPACING = 3;

{ TS4YLinearMeter }

constructor TS4YLinearMeter.Create(AOwner: TComponent);
begin
  inherited;

  FGraduation := TS4YLinearMeterGraduation.Create;
  FGraduation.OnChange := GraduationChanged;
end;

destructor TS4YLinearMeter.Destroy;
begin
  FreeAndNil(FGraduation);

  inherited;
end;

procedure TS4YLinearMeter.ApplyStyle;
begin
  inherited;

  FindStyleResource<TShape>(C_STYLE_MAJOR_TICK, FStyleMajorTick);
  FindStyleResource<TShape>(C_STYLE_MINOR_TICK, FStyleMinorTick);
  FindStyleResource<TText>(C_STYLE_SCALE_TEXT, FStyleScaleText);
end;

procedure TS4YLinearMeter.DrawDecorations(const ABarRect: TRectF);
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

  PrepareTickStroke(AStyleTick, ADefaultColor);

  for var I := 0 to High(AValues) do
  begin
    LPosition := BarPosition(ABarRect, GetValueFraction(AValues[I]));

    if Orientation = TOrientation.Horizontal then
      Canvas.DrawLine(TPointF.Create(LPosition, LStart), TPointF.Create(LPosition, LEnd), AbsoluteOpacity)
    else
      Canvas.DrawLine(TPointF.Create(LStart, LPosition), TPointF.Create(LEnd, LPosition), AbsoluteOpacity);
  end;
end;

procedure TS4YLinearMeter.FreeStyle;
begin
  FStyleMajorTick := nil;
  FStyleMinorTick := nil;
  FStyleScaleText := nil;

  inherited;
end;

procedure TS4YLinearMeter.GetBarMargins(out ABefore, AAfter: Single);
begin
  ABefore := 0;
  AAfter := 0;

  if FGraduation.Position = gbsAfter then
    AAfter := GetGraduationExtent
  else
    ABefore := GetGraduationExtent;
end;

function TS4YLinearMeter.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_WIDTH, C_DEFAULT_HEIGHT);
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

procedure TS4YLinearMeter.PrepareTickStroke(const AStyleTick: TShape; const ADefaultColor: TAlphaColor);
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

procedure TS4YLinearMeter.SetGraduation(const Value: TS4YLinearMeterGraduation);
begin
  FGraduation.Assign(Value);
end;

function TS4YLinearMeter.TickStart(const ABarRect: TRectF): Single;
begin
  // The ticks start a little away from the bar, on the side of the graduation.
  if Orientation = TOrientation.Horizontal then
  begin
    if FGraduation.Position = gbsAfter then
      Result := ABarRect.Bottom + C_SCALE_SPACING
    else
      Result := ABarRect.Top - C_SCALE_SPACING;
  end
  else
  begin
    if FGraduation.Position = gbsAfter then
      Result := ABarRect.Right + C_SCALE_SPACING
    else
      Result := ABarRect.Left - C_SCALE_SPACING;
  end;
end;

end.
