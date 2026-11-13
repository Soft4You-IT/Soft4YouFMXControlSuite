unit Soft4You.FMX.Controls.Charts.Bar;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YBarChart - bar chart
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
  Soft4You.FMX.Controls.Charts,
  Soft4You.FMX.Controls.Charts.Categories;

type
  /// <summary>
  /// A bar chart: a bar for each category and each series, the series of a category side by side.
  /// </summary>
  /// <remarks>
  /// The bars start from the value 0, or from the edge of the range when it does not include 0, so negative values go the other way.
  /// The look comes from the style S4YBarChartStyle: besides the parts of TS4YCustomCategoryChart, its part bar gives the shape of the bars (the corners of a TRectangle and its Stroke), filled with the color of the series, and its text labeltext the font of the values.
  /// </remarks>
  TS4YBarChart = class(TS4YCustomCategoryChart)
  public const
    /// <summary>Default value of BarWidth, in percent.</summary>
    C_DEFAULT_BAR_WIDTH: Single = 70;
    /// <summary>Default value of Orientation: vertical bars.</summary>
    C_DEFAULT_ORIENTATION = TOrientation.Vertical;
    /// <summary>Default value of ShowValues.</summary>
    C_DEFAULT_SHOW_VALUES = False;
    /// <summary>Largest value of BarWidth, in percent.</summary>
    C_MAX_BAR_WIDTH: Single = 100;
    /// <summary>Color of the values when the style has no labeltext.</summary>
    C_DEFAULT_LABEL_TEXT_COLOR: TAlphaColor = $FF424242;
  private type
    /// <summary>A bar of the last paint, for the clicks.</summary>
    TBarArea = record
      Rect: TRectF;
      SeriesIndex: Integer;
      CategoryIndex: Integer;
    end;
  private
    FBarCornerRadius: Single;
    FBars: TArray<TBarArea>;
    FBarStroke: TStrokeBrush;
    FBarWidth: Single;
    FOrientation: TOrientation;
    FShowValues: Boolean;
    FStyleLabelText: TText;
    function BarWidthStored: Boolean;
    procedure DrawBar(const ARect: TRectF; const AColor: TAlphaColor);
    procedure DrawValue(const ABar: TRectF; const AValue: Single; const ASeriesIndex, ACategoryIndex: Integer);
    procedure SetBarWidth(const Value: Single);
    procedure SetOrientation(const Value: TOrientation);
    procedure SetShowValues(const Value: Boolean);
  protected
    /// <summary>Reads the shape of the bars and the text of the values from the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Returns True for horizontal bars, whose categories go from top to bottom.</summary>
    function CategoriesVertical: Boolean; override;
    /// <summary>Draws the bars and their values.</summary>
    procedure DrawData(const ADataRect: TRectF); override;
    /// <summary>Returns the bar at APoint: its series and its category.</summary>
    function FindItemAt(const APoint: TPointF; out ASeriesIndex, AItemIndex: Integer): Boolean; override;
    /// <summary>Releases the texts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control: 300 x 200.</summary>
    function GetDefaultSize: TSizeF; override;
  public
    /// <summary>Creates a bar chart without categories and without series.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property Anchors;
    property AnimationDuration;
    /// <summary>Space of a category taken by its bars, in percent, from 1 to 100: the rest is left between the categories. The default is 70.</summary>
    property BarWidth: Single read FBarWidth write SetBarWidth stored BarWidthStored nodefault;
    property Categories;
    property CategoryAxis;
    property Cursor;
    property Enabled;
    property Height;
    property HitTest;
    property Legend;
    property Margins;
    property Opacity;
    /// <summary>Direction of the bars: vertical (the default), with the categories from left to right, or horizontal, with the categories from top to bottom.</summary>
    property Orientation: TOrientation read FOrientation write SetOrientation default C_DEFAULT_ORIENTATION;
    property Padding;
    property Palette;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Series;
    /// <summary>True writes the value of each bar at its end, formatted with ValueFormat. The default is False.</summary>
    property ShowValues: Boolean read FShowValues write SetShowValues default C_DEFAULT_SHOW_VALUES;
    property Size;
    property StyleLookup;
    property ValueAxis;
    property ValueFormat;
    property Visible;
    property Width;

    property OnCategoryBound;
    property OnClick;
    property OnDblClick;
    property OnGetValueText;
    property OnItemClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnSeriesBound;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  Soft4You.FMX.Controls.Charts.Bindings;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_BAR = 'bar';
  C_STYLE_LABEL_TEXT = 'labeltext';

  // Size of a new chart.
  C_DEFAULT_WIDTH = 300;
  C_DEFAULT_HEIGHT = 200;
  C_PERCENT = 100;
  C_MIN_BAR_WIDTH = 1;
  // Space between the end of a bar and its value, in pixels.
  C_VALUE_SPACING = 3;

{ TS4YBarChart }

constructor TS4YBarChart.Create(AOwner: TComponent);
begin
  inherited;

  FBarWidth := C_DEFAULT_BAR_WIDTH;
  FOrientation := C_DEFAULT_ORIENTATION;
  FShowValues := C_DEFAULT_SHOW_VALUES;
  FBarStroke := TStrokeBrush.Create(TBrushKind.None, TAlphaColors.Null);
end;

destructor TS4YBarChart.Destroy;
begin
  inherited;

  FreeAndNil(FBarStroke);
end;

procedure TS4YBarChart.ApplyStyle;
var
  LPart: TShape;
begin
  inherited;

  FindStyleResource<TText>(C_STYLE_LABEL_TEXT, FStyleLabelText);
  FBarCornerRadius := 0;
  FBarStroke.Kind := TBrushKind.None;

  if FindStyleResource<TShape>(C_STYLE_BAR, LPart) then
  begin
    FBarStroke.Assign(LPart.Stroke);

    if LPart is TRectangle then
      FBarCornerRadius := TRectangle(LPart).XRadius;
  end;
end;

function TS4YBarChart.BarWidthStored: Boolean;
begin
  Result := not SameValue(FBarWidth, C_DEFAULT_BAR_WIDTH);
end;

function TS4YBarChart.CategoriesVertical: Boolean;
begin
  Result := FOrientation = TOrientation.Horizontal;
end;

procedure TS4YBarChart.DrawBar(const ARect: TRectF; const AColor: TAlphaColor);
var
  LRadius: Single;
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  // The corners never take more than half of the thinner side of the bar.
  LRadius := Min(FBarCornerRadius, Min(ARect.Width, ARect.Height) / 2);
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := AColor;
  Canvas.FillRect(ARect, LRadius, LRadius, AllCorners, AbsoluteOpacity);

  if FBarStroke.Kind <> TBrushKind.None then
  begin
    Canvas.Stroke.Assign(FBarStroke);
    Canvas.DrawRect(ARect, LRadius, LRadius, AllCorners, AbsoluteOpacity);
  end;
end;

procedure TS4YBarChart.DrawData(const ADataRect: TRectF);
var
  LBar: TRectF;
  LBarSize: Single;
  LBaseline: Single;
  LCount: Integer;
  LGroupStart: Single;
  LGroupSize: Single;
  LSeriesCount: Integer;
  LSlot: TRectF;
  LValue: Single;
  LValuePosition: Single;
begin
  FBars := nil;
  LSeriesCount := DrawnSeriesCount;

  if LSeriesCount = 0 then
    Exit;

  LCount := 0;
  SetLength(FBars, DrawnCategoryCount * LSeriesCount);
  LBaseline := ValueToPosition(0);

  for var LCategory := 0 to DrawnCategoryCount - 1 do
  begin
    LSlot := CategoryRect(LCategory);

    // The bars of the series side by side, in the middle of the slot of the category.
    if CategoriesVertical then
    begin
      LGroupSize := LSlot.Height * FBarWidth / C_PERCENT;
      LGroupStart := LSlot.CenterPoint.Y - LGroupSize / 2;
    end
    else
    begin
      LGroupSize := LSlot.Width * FBarWidth / C_PERCENT;
      LGroupStart := LSlot.CenterPoint.X - LGroupSize / 2;
    end;

    LBarSize := LGroupSize / LSeriesCount;

    for var LSeries := 0 to LSeriesCount - 1 do
    begin
      LValue := GetDisplayedCategoryValue(LCategory, LSeries);
      LValuePosition := ValueToPosition(LValue);

      if CategoriesVertical then
        LBar := TRectF.Create(Min(LBaseline, LValuePosition), LGroupStart + LSeries * LBarSize,
          Max(LBaseline, LValuePosition), LGroupStart + (LSeries + 1) * LBarSize)
      else
        LBar := TRectF.Create(LGroupStart + LSeries * LBarSize, Min(LBaseline, LValuePosition),
          LGroupStart + (LSeries + 1) * LBarSize, Max(LBaseline, LValuePosition));

      DrawBar(LBar, GetSeriesColor(LSeries));
      FBars[LCount].Rect := LBar;
      FBars[LCount].SeriesIndex := LSeries;
      FBars[LCount].CategoryIndex := LCategory;
      Inc(LCount);

      if FShowValues then
        DrawValue(LBar, LValue, LSeries, LCategory);
    end;
  end;
end;

procedure TS4YBarChart.DrawValue(const ABar: TRectF; const AValue: Single; const ASeriesIndex,
  ACategoryIndex: Integer);
var
  LSize: TSizeF;
  LText: string;
begin
  LText := GetValueText(ASeriesIndex, ACategoryIndex, AValue);
  LSize := MeasureText(FStyleLabelText, C_DEFAULT_LABEL_TEXT_COLOR, LText);

  // The value beyond the end of the bar: above or on the right, below or on the left for a negative value.
  if CategoriesVertical then
  begin
    if AValue >= 0 then
      RenderText(FStyleLabelText, C_DEFAULT_LABEL_TEXT_COLOR, LText, TRectF.Create(ABar.Right + C_VALUE_SPACING,
        ABar.Top, ABar.Right + C_VALUE_SPACING + LSize.Width + 1, ABar.Bottom), TTextAlign.Leading, TTextAlign.Center)
    else
      RenderText(FStyleLabelText, C_DEFAULT_LABEL_TEXT_COLOR, LText, TRectF.Create(ABar.Left - C_VALUE_SPACING -
        LSize.Width - 1, ABar.Top, ABar.Left - C_VALUE_SPACING, ABar.Bottom), TTextAlign.Trailing, TTextAlign.Center);
  end
  else
  begin
    if AValue >= 0 then
      RenderText(FStyleLabelText, C_DEFAULT_LABEL_TEXT_COLOR, LText, TRectF.Create(ABar.CenterPoint.X - LSize.Width,
        ABar.Top - C_VALUE_SPACING - LSize.Height, ABar.CenterPoint.X + LSize.Width, ABar.Top - C_VALUE_SPACING),
        TTextAlign.Center, TTextAlign.Trailing)
    else
      RenderText(FStyleLabelText, C_DEFAULT_LABEL_TEXT_COLOR, LText, TRectF.Create(ABar.CenterPoint.X - LSize.Width,
        ABar.Bottom + C_VALUE_SPACING, ABar.CenterPoint.X + LSize.Width, ABar.Bottom + C_VALUE_SPACING + LSize.Height),
        TTextAlign.Center, TTextAlign.Leading);
  end;
end;

function TS4YBarChart.FindItemAt(const APoint: TPointF; out ASeriesIndex, AItemIndex: Integer): Boolean;
begin
  Result := False;
  ASeriesIndex := -1;
  AItemIndex := -1;

  for var LIndex := 0 to Length(FBars) - 1 do
  begin
    if FBars[LIndex].Rect.Contains(APoint) then
    begin
      ASeriesIndex := FBars[LIndex].SeriesIndex;
      AItemIndex := FBars[LIndex].CategoryIndex;
      Exit(True);
    end;
  end;
end;

procedure TS4YBarChart.FreeStyle;
begin
  FStyleLabelText := nil;

  inherited;
end;

function TS4YBarChart.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_WIDTH, C_DEFAULT_HEIGHT);
end;

procedure TS4YBarChart.SetBarWidth(const Value: Single);
begin
  if SameValue(FBarWidth, Value) then
    Exit;

  FBarWidth := EnsureRange(Value, C_MIN_BAR_WIDTH, C_MAX_BAR_WIDTH);
  Repaint;
end;

procedure TS4YBarChart.SetOrientation(const Value: TOrientation);
begin
  if FOrientation = Value then
    Exit;

  FOrientation := Value;
  Repaint;
end;

procedure TS4YBarChart.SetShowValues(const Value: Boolean);
begin
  if FShowValues = Value then
    Exit;

  FShowValues := Value;
  Repaint;
end;

initialization
  RegisterChartBindingClass(TS4YBarChart);

end.
