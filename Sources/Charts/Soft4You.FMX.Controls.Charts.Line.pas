unit Soft4You.FMX.Controls.Charts.Line;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YLineChart - line chart
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
  /// A line chart: a line for each series, through its values in the categories, from left to right.
  /// </summary>
  /// <remarks>
  /// Each value is a point in the middle of the space of its category. The area under a line, down to the value 0, can be filled with the color of the series.
  /// The look comes from the style S4YLineChartStyle: besides the parts of TS4YCustomCategoryChart, its part point gives the border of the points (its Stroke), filled with the color of the series, and the Opacity of its part area the transparency of the filled areas.
  /// </remarks>
  TS4YLineChart = class(TS4YCustomCategoryChart)
  public const
    /// <summary>Default value of FillArea.</summary>
    C_DEFAULT_FILL_AREA = False;
    /// <summary>Default value of LineThickness, in pixels.</summary>
    C_DEFAULT_LINE_THICKNESS: Single = 2;
    /// <summary>Default value of PointSize, in pixels.</summary>
    C_DEFAULT_POINT_SIZE: Single = 8;
    /// <summary>Default value of ShowPoints.</summary>
    C_DEFAULT_SHOW_POINTS = True;
    /// <summary>Opacity of the filled areas when the style has no area part.</summary>
    C_DEFAULT_AREA_OPACITY: Single = 0.16;
  private
    FAreaOpacity: Single;
    FFillArea: Boolean;
    FLineThickness: Single;
    FPointSize: Single;
    FPointStroke: TStrokeBrush;
    FShowPoints: Boolean;
    function CategoryPoint(const ACategoryIndex, ASeriesIndex: Integer): TPointF;
    procedure DrawArea(const ASeriesIndex: Integer);
    procedure DrawLine(const ASeriesIndex: Integer);
    procedure DrawPoints(const ASeriesIndex: Integer);
    function LineThicknessStored: Boolean;
    function PointSizeStored: Boolean;
    procedure SetFillArea(const Value: Boolean);
    procedure SetLineThickness(const Value: Single);
    procedure SetPointSize(const Value: Single);
    procedure SetShowPoints(const Value: Boolean);
  protected
    /// <summary>Reads the border of the points and the opacity of the areas from the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Draws the areas, the lines and the points of the series.</summary>
    procedure DrawData(const ADataRect: TRectF); override;
    /// <summary>Returns the point nearest to APoint, when it is close enough: its series and its category.</summary>
    function FindItemAt(const APoint: TPointF; out ASeriesIndex, AItemIndex: Integer): Boolean; override;
    /// <summary>Returns the size of a new control: 300 x 200.</summary>
    function GetDefaultSize: TSizeF; override;
  public
    /// <summary>Creates a line chart without categories and without series.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property Anchors;
    property AnimationDuration;
    property Categories;
    property CategoryAxis;
    property Cursor;
    property Enabled;
    /// <summary>True fills the area under each line, down to the value 0, with the color of its series, partly transparent. The default is False.</summary>
    property FillArea: Boolean read FFillArea write SetFillArea default C_DEFAULT_FILL_AREA;
    property Height;
    property HitTest;
    property Legend;
    /// <summary>Thickness of the lines, in pixels. With 0 only the points are drawn. The default is 2.</summary>
    property LineThickness: Single read FLineThickness write SetLineThickness stored LineThicknessStored nodefault;
    property Margins;
    property Opacity;
    property Padding;
    property Palette;
    /// <summary>Diameter of the points, in pixels. The default is 8.</summary>
    property PointSize: Single read FPointSize write SetPointSize stored PointSizeStored nodefault;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Series;
    /// <summary>True draws a point on each value. The default is True.</summary>
    property ShowPoints: Boolean read FShowPoints write SetShowPoints default C_DEFAULT_SHOW_POINTS;
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
  C_STYLE_POINT = 'point';
  C_STYLE_AREA = 'area';

  // Size of a new chart.
  C_DEFAULT_WIDTH = 300;
  C_DEFAULT_HEIGHT = 200;
  // Border of the points when the style has no point part.
  C_DEFAULT_POINT_STROKE_COLOR: TAlphaColor = $FFFFFFFF;
  C_DEFAULT_POINT_STROKE_THICKNESS = 2;
  // Distance from a point, beyond its radius, at which a click still selects it, in pixels.
  C_POINT_HIT_MARGIN = 4;

{ TS4YLineChart }

constructor TS4YLineChart.Create(AOwner: TComponent);
begin
  inherited;

  FFillArea := C_DEFAULT_FILL_AREA;
  FLineThickness := C_DEFAULT_LINE_THICKNESS;
  FPointSize := C_DEFAULT_POINT_SIZE;
  FShowPoints := C_DEFAULT_SHOW_POINTS;
  FAreaOpacity := C_DEFAULT_AREA_OPACITY;
  FPointStroke := TStrokeBrush.Create(TBrushKind.Solid, C_DEFAULT_POINT_STROKE_COLOR);
  FPointStroke.Thickness := C_DEFAULT_POINT_STROKE_THICKNESS;
end;

destructor TS4YLineChart.Destroy;
begin
  inherited;

  FreeAndNil(FPointStroke);
end;

procedure TS4YLineChart.ApplyStyle;
var
  LPart: TShape;
  LArea: TControl;
begin
  inherited;

  if FindStyleResource<TShape>(C_STYLE_POINT, LPart) then
    FPointStroke.Assign(LPart.Stroke);

  if FindStyleResource<TControl>(C_STYLE_AREA, LArea) then
    FAreaOpacity := LArea.Opacity
  else
    FAreaOpacity := C_DEFAULT_AREA_OPACITY;
end;

function TS4YLineChart.CategoryPoint(const ACategoryIndex, ASeriesIndex: Integer): TPointF;
begin
  Result := TPointF.Create(CategoryRect(ACategoryIndex).CenterPoint.X,
    ValueToPosition(GetDisplayedCategoryValue(ACategoryIndex, ASeriesIndex)));
end;

procedure TS4YLineChart.DrawArea(const ASeriesIndex: Integer);
var
  LBaseline: Single;
  LPath: TPathData;
  LFirst: TPointF;
  LLast: TPointF;
begin
  if DrawnCategoryCount < 2 then
    Exit;

  LBaseline := ValueToPosition(0);
  LFirst := CategoryPoint(0, ASeriesIndex);
  LLast := CategoryPoint(DrawnCategoryCount - 1, ASeriesIndex);
  LPath := TPathData.Create;
  try
    LPath.MoveTo(TPointF.Create(LFirst.X, LBaseline));

    for var LCategory := 0 to DrawnCategoryCount - 1 do
      LPath.LineTo(CategoryPoint(LCategory, ASeriesIndex));

    LPath.LineTo(TPointF.Create(LLast.X, LBaseline));
    LPath.ClosePath;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := GetSeriesColor(ASeriesIndex);
    Canvas.FillPath(LPath, AbsoluteOpacity * FAreaOpacity);
  finally
    LPath.Free;
  end;
end;

procedure TS4YLineChart.DrawData(const ADataRect: TRectF);
begin
  // The areas first, so that no area covers the line of another series.
  if FFillArea then
  begin
    for var LSeries := 0 to DrawnSeriesCount - 1 do
      DrawArea(LSeries);
  end;

  for var LSeries := 0 to DrawnSeriesCount - 1 do
    DrawLine(LSeries);

  if FShowPoints then
  begin
    for var LSeries := 0 to DrawnSeriesCount - 1 do
      DrawPoints(LSeries);
  end;
end;

procedure TS4YLineChart.DrawLine(const ASeriesIndex: Integer);
var
  LPath: TPathData;
begin
  if (FLineThickness <= 0) or (DrawnCategoryCount < 2) then
    Exit;

  LPath := TPathData.Create;
  try
    LPath.MoveTo(CategoryPoint(0, ASeriesIndex));

    for var LCategory := 1 to DrawnCategoryCount - 1 do
      LPath.LineTo(CategoryPoint(LCategory, ASeriesIndex));

    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := GetSeriesColor(ASeriesIndex);
    Canvas.Stroke.Thickness := FLineThickness;
    Canvas.Stroke.Dash := TStrokeDash.Solid;
    Canvas.Stroke.Join := TStrokeJoin.Round;
    Canvas.Stroke.Cap := TStrokeCap.Round;
    Canvas.DrawPath(LPath, AbsoluteOpacity);
  finally
    LPath.Free;
  end;
end;

procedure TS4YLineChart.DrawPoints(const ASeriesIndex: Integer);
var
  LCenter: TPointF;
  LRect: TRectF;
begin
  if FPointSize <= 0 then
    Exit;

  for var LCategory := 0 to DrawnCategoryCount - 1 do
  begin
    LCenter := CategoryPoint(LCategory, ASeriesIndex);
    LRect := TRectF.Create(LCenter.X - FPointSize / 2, LCenter.Y - FPointSize / 2, LCenter.X + FPointSize / 2,
      LCenter.Y + FPointSize / 2);
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := GetSeriesColor(ASeriesIndex);
    Canvas.FillEllipse(LRect, AbsoluteOpacity);

    if FPointStroke.Kind <> TBrushKind.None then
    begin
      Canvas.Stroke.Assign(FPointStroke);
      Canvas.DrawEllipse(LRect, AbsoluteOpacity);
    end;
  end;
end;

function TS4YLineChart.FindItemAt(const APoint: TPointF; out ASeriesIndex, AItemIndex: Integer): Boolean;
var
  LBestDistance: Single;
  LDistance: Single;
begin
  ASeriesIndex := -1;
  AItemIndex := -1;
  LBestDistance := Max(FPointSize / 2, 0) + C_POINT_HIT_MARGIN;

  // The nearest point within reach; the one of the last series wins a tie, as it is drawn over the others.
  for var LSeries := 0 to DrawnSeriesCount - 1 do
  begin
    for var LCategory := 0 to DrawnCategoryCount - 1 do
    begin
      LDistance := APoint.Distance(CategoryPoint(LCategory, LSeries));

      if LDistance <= LBestDistance then
      begin
        LBestDistance := LDistance;
        ASeriesIndex := LSeries;
        AItemIndex := LCategory;
      end;
    end;
  end;

  Result := AItemIndex >= 0;
end;

function TS4YLineChart.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_WIDTH, C_DEFAULT_HEIGHT);
end;

function TS4YLineChart.LineThicknessStored: Boolean;
begin
  Result := not SameValue(FLineThickness, C_DEFAULT_LINE_THICKNESS);
end;

function TS4YLineChart.PointSizeStored: Boolean;
begin
  Result := not SameValue(FPointSize, C_DEFAULT_POINT_SIZE);
end;

procedure TS4YLineChart.SetFillArea(const Value: Boolean);
begin
  if FFillArea = Value then
    Exit;

  FFillArea := Value;
  Repaint;
end;

procedure TS4YLineChart.SetLineThickness(const Value: Single);
begin
  if SameValue(FLineThickness, Value) then
    Exit;

  FLineThickness := Max(0, Value);
  Repaint;
end;

procedure TS4YLineChart.SetPointSize(const Value: Single);
begin
  if SameValue(FPointSize, Value) then
    Exit;

  FPointSize := Max(0, Value);
  Repaint;
end;

procedure TS4YLineChart.SetShowPoints(const Value: Boolean);
begin
  if FShowPoints = Value then
    Exit;

  FShowPoints := Value;
  Repaint;
end;

initialization
  RegisterChartBindingClass(TS4YLineChart);

end.
