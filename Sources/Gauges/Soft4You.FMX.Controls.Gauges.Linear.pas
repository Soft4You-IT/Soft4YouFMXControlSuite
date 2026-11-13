unit Soft4You.FMX.Controls.Gauges.Linear;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YLinearGauge - gauge drawn as a bar that fills with a value
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Types,
  FMX.Types,
  FMX.Controls,
  Soft4You.FMX.Controls.Gauges.Types,
  Soft4You.FMX.Controls.Gauges;

type
  /// <summary>
  /// A gauge drawn as a horizontal or vertical bar that fills with the value, with the caption and the value beside it.
  /// </summary>
  /// <remarks>
  /// A horizontal bar fills from the left, a vertical one from the bottom. TextPosition puts the caption and the value on one side of the bar: the caption at the start of the bar, where the fill begins, and the value at its end.
  /// The style is S4YLinearGaugeStyle: the parts track and fill are resized to the bar and to the filled part of it.
  /// </remarks>
  TS4YLinearGauge = class(TS4YCustomGauge)
  public const
    /// <summary>Default value of Orientation.</summary>
    C_DEFAULT_ORIENTATION = TOrientation.Horizontal;
    /// <summary>Default value of TextPosition.</summary>
    C_DEFAULT_TEXT_POSITION = gtpBefore;
    /// <summary>Default value of Thickness, in pixels.</summary>
    C_DEFAULT_THICKNESS: Single = 8;
  private
    FOrientation: TOrientation;
    FTextPosition: TS4YGaugeTextPosition;
    procedure DrawHorizontal(const AContentRect: TRectF; const ACaption, AValueText: string);
    procedure DrawVertical(const AContentRect: TRectF; const ACaption, AValueText: string);
    function HasText(const ACaption, AValueText: string): Boolean;
    procedure SetOrientation(const Value: TOrientation);
    procedure SetTextPosition(const Value: TS4YGaugeTextPosition);
  protected
    /// <summary>Draws the bar, its fill, the caption and the value.</summary>
    procedure DrawGauge; override;
    /// <summary>Returns the size of a new control: 200 x 40.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns 8, the default thickness of the bar.</summary>
    function GetDefaultThickness: Single; override;
  public
    /// <summary>Creates a horizontal gauge with the default settings.</summary>
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
    /// <summary>Direction of the bar: horizontal, filled from the left, or vertical, filled from the bottom. The default is horizontal.</summary>
    property Orientation: TOrientation read FOrientation write SetOrientation default C_DEFAULT_ORIENTATION;
    property Padding;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property ShowValue;
    property Size;
    property StyleLookup;
    /// <summary>
    /// Side of the bar where the caption and the value are written, or gtpNone to hide them. The default is gtpBefore: above a horizontal bar, on the left of a vertical one.
    /// </summary>
    /// <remarks>
    /// The caption is at the start of the bar and the value at its end: on the left and on the right of a horizontal bar, at the bottom and at the top of a vertical one.
    /// </remarks>
    property TextPosition: TS4YGaugeTextPosition read FTextPosition write SetTextPosition default C_DEFAULT_TEXT_POSITION;
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
  System.Math;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

const
  // Space between the bar and its texts, in pixels.
  C_TEXT_SPACING = 4;
  // Size of a new gauge.
  C_DEFAULT_WIDTH = 200;
  C_DEFAULT_HEIGHT = 40;

{ TS4YLinearGauge }

constructor TS4YLinearGauge.Create(AOwner: TComponent);
begin
  inherited;

  FOrientation := C_DEFAULT_ORIENTATION;
  FTextPosition := C_DEFAULT_TEXT_POSITION;
end;

procedure TS4YLinearGauge.DrawGauge;
var
  LCaption: string;
  LValueText: string;
begin
  LCaption := Caption;
  LValueText := GetValueText;

  if FOrientation = TOrientation.Horizontal then
    DrawHorizontal(GetContentRect, LCaption, LValueText)
  else
    DrawVertical(GetContentRect, LCaption, LValueText);
end;

procedure TS4YLinearGauge.DrawHorizontal(const AContentRect: TRectF; const ACaption, AValueText: string);
var
  LBarRect: TRectF;
  LBlockHeight: Single;
  LTextHeight: Single;
  LTextRect: TRectF;
  LTextVerticalAlign: TTextAlign;
  LTop: Single;
begin
  LTextHeight := 0;
  LTextRect := TRectF.Empty;

  if HasText(ACaption, AValueText) then
    LTextHeight := System.Math.Max(MeasureText(StyleCaptionText, C_DEFAULT_CAPTION_TEXT_COLOR, ACaption).Height,
      MeasureText(StyleValueText, C_DEFAULT_VALUE_TEXT_COLOR, AValueText).Height);

  // The bar and the line of text are one block, in the middle of the content.
  LBlockHeight := Thickness;

  if LTextHeight > 0 then
    LBlockHeight := LBlockHeight + C_TEXT_SPACING + LTextHeight;

  LTop := AContentRect.Top + (AContentRect.Height - LBlockHeight) / 2;

  if (LTextHeight > 0) and (FTextPosition = gtpBefore) then
  begin
    LTextRect := TRectF.Create(AContentRect.Left, LTop, AContentRect.Right, LTop + LTextHeight);
    LTop := LTextRect.Bottom + C_TEXT_SPACING;
  end;

  LBarRect := TRectF.Create(AContentRect.Left, LTop, AContentRect.Right, LTop + Thickness);

  if (LTextHeight > 0) and (FTextPosition = gtpAfter) then
    LTextRect := TRectF.Create(AContentRect.Left, LBarRect.Bottom + C_TEXT_SPACING, AContentRect.Right,
      LBarRect.Bottom + C_TEXT_SPACING + LTextHeight);

  DrawPart(TrackPart, LBarRect);
  DrawPart(FillPart, TRectF.Create(LBarRect.Left, LBarRect.Top, LBarRect.Left + LBarRect.Width * GetDisplayedFraction,
    LBarRect.Bottom));

  if LTextHeight > 0 then
  begin
    // Texts of different heights are aligned towards the bar.
    if FTextPosition = gtpBefore then
      LTextVerticalAlign := TTextAlign.Trailing
    else
      LTextVerticalAlign := TTextAlign.Leading;

    RenderText(StyleCaptionText, C_DEFAULT_CAPTION_TEXT_COLOR, ACaption, LTextRect, TTextAlign.Leading,
      LTextVerticalAlign);
    RenderText(StyleValueText, C_DEFAULT_VALUE_TEXT_COLOR, AValueText, LTextRect, TTextAlign.Trailing,
      LTextVerticalAlign);
  end;
end;

procedure TS4YLinearGauge.DrawVertical(const AContentRect: TRectF; const ACaption, AValueText: string);
var
  LBarRect: TRectF;
  LBlockWidth: Single;
  LLeft: Single;
  LTextHorizontalAlign: TTextAlign;
  LTextRect: TRectF;
  LTextWidth: Single;
begin
  LTextWidth := 0;
  LTextRect := TRectF.Empty;

  if HasText(ACaption, AValueText) then
    LTextWidth := System.Math.Max(MeasureText(StyleCaptionText, C_DEFAULT_CAPTION_TEXT_COLOR, ACaption).Width,
      MeasureText(StyleValueText, C_DEFAULT_VALUE_TEXT_COLOR, AValueText).Width);

  // The bar and the column of text are one block, in the middle of the content.
  LBlockWidth := Thickness;

  if LTextWidth > 0 then
    LBlockWidth := LBlockWidth + C_TEXT_SPACING + LTextWidth;

  LLeft := AContentRect.Left + (AContentRect.Width - LBlockWidth) / 2;

  if (LTextWidth > 0) and (FTextPosition = gtpBefore) then
  begin
    LTextRect := TRectF.Create(LLeft, AContentRect.Top, LLeft + LTextWidth, AContentRect.Bottom);
    LLeft := LTextRect.Right + C_TEXT_SPACING;
  end;

  LBarRect := TRectF.Create(LLeft, AContentRect.Top, LLeft + Thickness, AContentRect.Bottom);

  if (LTextWidth > 0) and (FTextPosition = gtpAfter) then
    LTextRect := TRectF.Create(LBarRect.Right + C_TEXT_SPACING, AContentRect.Top,
      LBarRect.Right + C_TEXT_SPACING + LTextWidth, AContentRect.Bottom);

  DrawPart(TrackPart, LBarRect);
  DrawPart(FillPart, TRectF.Create(LBarRect.Left, LBarRect.Bottom - LBarRect.Height * GetDisplayedFraction,
    LBarRect.Right, LBarRect.Bottom));

  if LTextWidth > 0 then
  begin
    // Texts of different widths are aligned towards the bar.
    if FTextPosition = gtpBefore then
      LTextHorizontalAlign := TTextAlign.Trailing
    else
      LTextHorizontalAlign := TTextAlign.Leading;

    // The fill starts from the bottom: the caption is there, the value at the top.
    RenderText(StyleCaptionText, C_DEFAULT_CAPTION_TEXT_COLOR, ACaption, LTextRect, LTextHorizontalAlign,
      TTextAlign.Trailing);
    RenderText(StyleValueText, C_DEFAULT_VALUE_TEXT_COLOR, AValueText, LTextRect, LTextHorizontalAlign,
      TTextAlign.Leading);
  end;
end;

function TS4YLinearGauge.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_WIDTH, C_DEFAULT_HEIGHT);
end;

function TS4YLinearGauge.GetDefaultThickness: Single;
begin
  Result := C_DEFAULT_THICKNESS;
end;

function TS4YLinearGauge.HasText(const ACaption, AValueText: string): Boolean;
begin
  Result := (FTextPosition <> gtpNone) and ((ACaption <> '') or (AValueText <> ''));
end;

procedure TS4YLinearGauge.SetOrientation(const Value: TOrientation);
begin
  if FOrientation = Value then
    Exit;

  FOrientation := Value;
  Repaint;
end;

procedure TS4YLinearGauge.SetTextPosition(const Value: TS4YGaugeTextPosition);
begin
  if FTextPosition = Value then
    Exit;

  FTextPosition := Value;
  Repaint;
end;

end.
