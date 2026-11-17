unit Soft4You.FMX.Controls.Charts.Categories;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YCustomCategoryChart - base class of the bar and line charts
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
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.Objects,
  Soft4You.FMX.Controls.Charts.Types,
  Soft4You.FMX.Controls.Charts;

type
  /// <summary>
  /// A category of a bar or line chart, for example a month, with a value for each series.
  /// </summary>
  /// <remarks>
  /// The categories of the Categories list are stored in the form; the categories filled by the LiveBindings are created by the chart, are not stored, and are passed to OnCategoryBound.
  /// </remarks>
  TS4YChartCategory = class(TCollectionItem)
  private
    FCaption: string;
    FTag: NativeInt;
    FValues: TArray<Single>;
    function GetValue(ASeriesIndex: Integer): Single;
    function GetValueCount: Integer;
    function GetValuesText: string;
    procedure SetCaption(const Value: string);
    procedure SetValue(ASeriesIndex: Integer; const Value: Single);
    procedure SetValuesText(const Value: string);
  protected
    /// <summary>Returns the caption of the category, shown by the editor of the collection in the IDE.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Copies all the properties from another TS4YChartCategory.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>The value of the category for the series at ASeriesIndex. A series without a value of its own reads 0; writing beyond the last value adds the values in between, at 0.</summary>
    property Value[ASeriesIndex: Integer]: Single read GetValue write SetValue;
    /// <summary>The number of the values of the category.</summary>
    property ValueCount: Integer read GetValueCount;
  published
    /// <summary>Text of the category, written along the category axis.</summary>
    property Caption: string read FCaption write SetCaption;
    /// <summary>A value free for the application. The chart does not use it.</summary>
    property Tag: NativeInt read FTag write FTag default 0;
    /// <summary>
    /// The values of the category, one for each series in their order, separated by semicolons, with the point as decimal separator: for example 42;30.5.
    /// </summary>
    /// <remarks>
    /// Meant for the Object Inspector; in code Value[Index] is simpler. A text that is not a number counts as 0.
    /// </remarks>
    property Values: string read GetValuesText write SetValuesText;
  end;

  /// <summary>
  /// The categories of a bar or line chart stored in the form.
  /// </summary>
  TS4YChartCategories = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TS4YChartCategory;
    procedure SetItem(Index: Integer; const Value: TS4YChartCategory);
  protected
    /// <summary>Redraws the chart when the categories change.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the categories of AOwner, empty.</summary>
    constructor Create(AOwner: TPersistent);

    /// <summary>Adds a category at the end and returns it.</summary>
    function Add: TS4YChartCategory; overload;
    /// <summary>Adds a category with ACaption and the values AValues, one for each series, and returns it.</summary>
    function Add(const ACaption: string; const AValues: array of Single): TS4YChartCategory; overload;

    /// <summary>The categories, in their order along the category axis.</summary>
    property Items[Index: Integer]: TS4YChartCategory read GetItem write SetItem; default;
  end;

  /// <summary>
  /// A series of a bar or line chart: the name and the color of a set of values, one for each category.
  /// </summary>
  /// <remarks>
  /// The values are kept by the categories. The series of the Series list are stored in the form; the series filled by the LiveBindings are created by the chart, one for each column of values of the link, and are passed to OnSeriesBound.
  /// </remarks>
  TS4YChartSeries = class(TCollectionItem)
  public const
    /// <summary>Default value of Color: the color of the palette of the chart for the position of the series.</summary>
    C_DEFAULT_COLOR = TAlphaColorRec.Null;
  private
    FCaption: string;
    FColor: TAlphaColor;
    FTag: NativeInt;
    procedure SetCaption(const Value: string);
    procedure SetColor(const Value: TAlphaColor);
  protected
    /// <summary>Returns the caption of the series, shown by the editor of the collection in the IDE.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates a series without caption and with the color of the palette.</summary>
    constructor Create(Collection: TCollection); override;

    /// <summary>Copies all the properties from another TS4YChartSeries.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>Name of the series, shown in the legend.</summary>
    property Caption: string read FCaption write SetCaption;
    /// <summary>Color of the series. With claNull, the default, the series takes the color of the palette for its position.</summary>
    property Color: TAlphaColor read FColor write SetColor default C_DEFAULT_COLOR;
    /// <summary>A value free for the application. The chart does not use it.</summary>
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  /// <summary>
  /// The series of a bar or line chart stored in the form.
  /// </summary>
  TS4YChartSeriesList = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TS4YChartSeries;
    procedure SetItem(Index: Integer; const Value: TS4YChartSeries);
  protected
    /// <summary>Redraws the chart when the series change.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the series of AOwner, empty.</summary>
    constructor Create(AOwner: TPersistent);

    /// <summary>Adds a series at the end and returns it.</summary>
    function Add: TS4YChartSeries; overload;
    /// <summary>Adds a series with ACaption at the end and returns it.</summary>
    function Add(const ACaption: string): TS4YChartSeries; overload;

    /// <summary>The series, in the order of the values of the categories.</summary>
    property Items[Index: Integer]: TS4YChartSeries read GetItem write SetItem; default;
  end;

  /// <summary>
  /// An axis of a bar or line chart.
  /// </summary>
  TS4YChartAxis = class(TPersistent)
  public const
    /// <summary>Default value of Visible.</summary>
    C_DEFAULT_VISIBLE = True;
  private
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetVisible(const Value: Boolean);
  protected
    /// <summary>Fires OnChange.</summary>
    procedure DoChange;
  public
    /// <summary>Creates a visible axis.</summary>
    constructor Create; virtual;

    /// <summary>Copies the settings from another axis.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>True draws the line of the axis and its labels. The default is True.</summary>
    property Visible: Boolean read FVisible write SetVisible default C_DEFAULT_VISIBLE;
  end;

  /// <summary>
  /// The axis of the categories of a bar or line chart, with its grid lines.
  /// </summary>
  TS4YChartCategoryAxis = class(TS4YChartAxis)
  public const
    /// <summary>Default value of GridLines.</summary>
    C_DEFAULT_GRID_LINES = False;
  private
    FGridLines: Boolean;
    procedure SetGridLines(const Value: Boolean);
  public
    /// <summary>Creates a visible axis without grid lines.</summary>
    constructor Create; override;

    /// <summary>Copies the settings from another axis.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>
    /// True draws a line across the chart for the categories. The default is False.
    /// </summary>
    /// <remarks>
    /// In a bar chart the lines separate the categories; in a line chart they go through the points of each category.
    /// </remarks>
    property GridLines: Boolean read FGridLines write SetGridLines default C_DEFAULT_GRID_LINES;
  end;

  /// <summary>
  /// The axis of the values of a bar or line chart: its range and its grid lines.
  /// </summary>
  TS4YChartValueAxis = class(TS4YChartAxis)
  public const
    /// <summary>Default value of AutoRange.</summary>
    C_DEFAULT_AUTO_RANGE = True;
    /// <summary>Default value of GridLines.</summary>
    C_DEFAULT_GRID_LINES = True;
    /// <summary>Default value of Max.</summary>
    C_DEFAULT_MAX: Single = 100;
    /// <summary>Default value of Min.</summary>
    C_DEFAULT_MIN: Single = 0;
  private
    FAutoRange: Boolean;
    FGridLines: Boolean;
    FMax: Single;
    FMin: Single;
    function MaxStored: Boolean;
    function MinStored: Boolean;
    procedure SetAutoRange(const Value: Boolean);
    procedure SetGridLines(const Value: Boolean);
    procedure SetMax(const Value: Single);
    procedure SetMin(const Value: Single);
  public
    /// <summary>Creates a visible axis with the automatic range and the grid lines.</summary>
    constructor Create; override;

    /// <summary>Copies the settings from another axis.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>
    /// True, the default, takes the range from the values: from 0, or from the lowest value when it is negative, to the highest value, rounded to a step of the scale.
    /// </summary>
    /// <remarks>
    /// False uses Min and Max; values out of that range are drawn up to its edge.
    /// </remarks>
    property AutoRange: Boolean read FAutoRange write SetAutoRange default C_DEFAULT_AUTO_RANGE;
    /// <summary>True draws a line across the chart at each step of the scale. The default is True.</summary>
    property GridLines: Boolean read FGridLines write SetGridLines default C_DEFAULT_GRID_LINES;
    /// <summary>The end of the range when AutoRange is False. The default is 100.</summary>
    property Max: Single read FMax write SetMax stored MaxStored nodefault;
    /// <summary>The start of the range when AutoRange is False. The default is 0.</summary>
    property Min: Single read FMin write SetMin stored MinStored nodefault;
  end;

  /// <summary>
  /// Event fired for each category filled by the LiveBindings, after every update of the data.
  /// </summary>
  /// <remarks>
  /// ACategory has the caption and the values of its record: the event can change its caption and its tag.
  /// </remarks>
  TS4YChartCategoryBoundEvent = procedure(Sender: TObject; const ACategory: TS4YChartCategory) of object;

  /// <summary>
  /// Event fired for each series created by the LiveBindings from a column of the link.
  /// </summary>
  /// <remarks>
  /// ASeries has the header of the column as caption, or the name of the field, and Color = claNull, the color of the palette for its position: the event can change its color and its caption.
  /// </remarks>
  TS4YChartSeriesBoundEvent = procedure(Sender: TObject; const ASeries: TS4YChartSeries) of object;

  /// <summary>
  /// Base class of the bar and line charts: categories along one axis, values along the other, one set of values for each series.
  /// </summary>
  /// <remarks>
  /// The data come from Categories and Series or, while a TLinkGridToDataSource fills the chart, from its records: the first column of the link gives the captions of the categories, each next column a series.
  /// The look comes from a style: besides the parts of TS4YCustomChart, the Stroke of its parts axis and gridline gives the lines of the axes and of the grid, and its text axistext the labels of the axes. The class is not registered in the Tool Palette.
  /// </remarks>
  TS4YCustomCategoryChart = class(TS4YCustomChart)
  public const
    /// <summary>Color of the lines of the axes when the style has no axis part.</summary>
    C_DEFAULT_AXIS_COLOR: TAlphaColor = $FF9E9E9E;
    /// <summary>Color of the labels of the axes when the style has no axistext.</summary>
    C_DEFAULT_AXIS_TEXT_COLOR: TAlphaColor = $FF616161;
    /// <summary>Color of the grid lines when the style has no gridline part.</summary>
    C_DEFAULT_GRID_COLOR: TAlphaColor = $FFE0E0E0;
  private
    FAxisStroke: TStrokeBrush;
    FBindingColumnCount: Integer;
    FBindingUpdateDepth: Integer;
    FBoundCategories: TObjectList<TS4YChartCategory>;
    FBoundSeries: TObjectList<TS4YChartSeries>;
    FCategories: TS4YChartCategories;
    FCategoryAxis: TS4YChartCategoryAxis;
    FDataRect: TRectF;
    FGridStroke: TStrokeBrush;
    FScaleMax: Single;
    FScaleMin: Single;
    FScaleStep: Single;
    FSeries: TS4YChartSeriesList;
    FStyleAxisText: TText;
    FValueAxis: TS4YChartValueAxis;
    FOnCategoryBound: TS4YChartCategoryBoundEvent;
    FOnSeriesBound: TS4YChartSeriesBoundEvent;
    procedure AxisChanged(Sender: TObject);
    procedure BoundCategoryChanged(const ARow: Integer);
    procedure CalculateScale;
    procedure DrawAxes(const APlotRect: TRectF);
    function GetDrawnCategory(Index: Integer): TS4YChartCategory;
    function GetDrawnCategoryCount: Integer;
    function GetDrawnSeries(Index: Integer): TS4YChartSeries;
    function GetDrawnSeriesCount: Integer;
    function IsBound: Boolean;
    procedure SetCategories(const Value: TS4YChartCategories);
    procedure SetCategoryAxis(const Value: TS4YChartCategoryAxis);
    procedure SetSeries(const Value: TS4YChartSeriesList);
    procedure SetValueAxis(const Value: TS4YChartValueAxis);
  protected
    /// <summary>Adds two series, Series 1 and Series 2, and four categories, Q1 to Q4.</summary>
    procedure AddSampleData; override;
    /// <summary>Reads the lines and the texts of the style.</summary>
    procedure ApplyStyle; override;
    function BindingAddLinkColumn(const ACaption: string): Integer; override;
    function BindingAddRow: Integer; override;
    procedure BindingBeginUpdate; override;
    procedure BindingClearLinkColumns; override;
    procedure BindingClearRows; override;
    procedure BindingDeleteRowsFrom(const AIndex: Integer); override;
    procedure BindingEndUpdate; override;
    function BindingGetCaption(const ARow: Integer): string; override;
    function BindingGetRowCount: Integer; override;
    function BindingGetValue(const ARow, AColumn: Integer): Single; override;
    procedure BindingSetCaption(const ARow: Integer; const ACaption: string); override;
    procedure BindingSetValue(const ARow, AColumn: Integer; const AValue: Single); override;
    procedure BindingUpdateLinkColumn(const ALinkColumn: Integer; const ACaption: string); override;
    /// <summary>Returns the area of the category at AIndex along the category axis, inside the area of the data: a column for vertical categories, a row for horizontal ones.</summary>
    function CategoryRect(const AIndex: Integer): TRectF;
    /// <summary>Returns True when the categories follow one another from top to bottom, as in a chart of horizontal bars; False when they go from left to right.</summary>
    function CategoriesVertical: Boolean; virtual;
    /// <summary>Returns True when the grid lines of the categories go between the categories, as in a bar chart; False when they go through the middle of each category, as in a line chart.</summary>
    function CategoryGridLinesBetween: Boolean; virtual;
    /// <summary>To be called when the categories or the series change.</summary>
    procedure DataSetChanged;
    /// <summary>Fires OnCategoryBound.</summary>
    procedure DoCategoryBound(const ACategory: TS4YChartCategory); virtual;
    /// <summary>Fires OnSeriesBound.</summary>
    procedure DoSeriesBound(const ASeries: TS4YChartSeries); virtual;
    /// <summary>Draws the axes, the grid and then the data, through DrawData.</summary>
    procedure DrawChart(const APlotRect: TRectF); override;
    /// <summary>Draws the values in ADataRect, the area inside the axes.</summary>
    procedure DrawData(const ADataRect: TRectF); virtual; abstract;
    /// <summary>Releases the texts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the value drawn of the category ACategoryIndex in the series ASeriesIndex: it follows the animation.</summary>
    function GetDisplayedCategoryValue(const ACategoryIndex, ASeriesIndex: Integer): Single;
    function GetLegendEntryCaption(const AIndex: Integer): string; override;
    function GetLegendEntryColor(const AIndex: Integer): TAlphaColor; override;
    function GetLegendEntryCount: Integer; override;
    /// <summary>Returns the color of the series at AIndex: its own, or the one of the palette.</summary>
    function GetSeriesColor(const AIndex: Integer): TAlphaColor;
    /// <summary>Returns the values of the categories, category by category and series by series inside each.</summary>
    function GetTargetValues: TArray<Single>; override;
    /// <summary>Returns the position of AValue along the value axis, in the coordinates of the control: a Y for vertical categories, an X for horizontal ones.</summary>
    function ValueToPosition(const AValue: Single): Single;

    /// <summary>The area inside the axes of the last paint.</summary>
    property DataRect: TRectF read FDataRect;
  public
    /// <summary>Creates a chart without categories and without series.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>The categories stored in the form. While a TLinkGridToDataSource fills the chart, the categories of its records are drawn instead.</summary>
    property Categories: TS4YChartCategories read FCategories write SetCategories;
    /// <summary>The axis of the categories.</summary>
    property CategoryAxis: TS4YChartCategoryAxis read FCategoryAxis write SetCategoryAxis;
    /// <summary>The number of the categories drawn: the ones filled by the LiveBindings while a link fills the chart, else the ones of Categories.</summary>
    property DrawnCategoryCount: Integer read GetDrawnCategoryCount;
    /// <summary>The categories drawn, the ones that ItemIndex and OnItemClick refer to.</summary>
    property DrawnCategories[Index: Integer]: TS4YChartCategory read GetDrawnCategory;
    /// <summary>The number of the series drawn: the ones created by the LiveBindings while a link fills the chart, else the ones of Series.</summary>
    property DrawnSeriesCount: Integer read GetDrawnSeriesCount;
    /// <summary>The series drawn.</summary>
    property DrawnSeries[Index: Integer]: TS4YChartSeries read GetDrawnSeries;
    /// <summary>The series stored in the form. While a TLinkGridToDataSource fills the chart, the series of its columns are drawn instead.</summary>
    property Series: TS4YChartSeriesList read FSeries write SetSeries;
    /// <summary>The axis of the values: range and grid lines.</summary>
    property ValueAxis: TS4YChartValueAxis read FValueAxis write SetValueAxis;

    /// <summary>Fires for each category filled by the LiveBindings after every update of the data.</summary>
    property OnCategoryBound: TS4YChartCategoryBoundEvent read FOnCategoryBound write FOnCategoryBound;
    /// <summary>Fires for each series created by the LiveBindings from a column of the link, to change its color or its caption.</summary>
    property OnSeriesBound: TS4YChartSeriesBoundEvent read FOnSeriesBound write FOnSeriesBound;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  Soft4You.FMX.Controls.Charts.Strings;

const
  // Values of the categories of a chart placed in the form designer, one column for each series.
  C_SAMPLE_VALUES: array[0..3, 0..1] of Single = ((12, 8), (18, 11), (15, 16), (22, 14));

  C_STYLE_AXIS = 'axis';
  C_STYLE_GRIDLINE = 'gridline';
  C_STYLE_AXIS_TEXT = 'axistext';

  // Separator of the values in TS4YChartCategory.Values.
  C_VALUES_SEPARATOR = ';';
  // Number of steps the automatic range aims at, and the steps of the scale, as fractions of a power of 10.
  C_TARGET_STEPS = 5;
  C_NICE_STEPS: array[0..4] of Single = (1, 2, 2.5, 5, 10);
  // Space between the labels and the axes, in pixels.
  C_AXIS_LABEL_SPACING = 6;
  C_DEFAULT_LINE_THICKNESS = 1;
  // Index of the series in the values of the axes passed to OnGetValueText.
  C_AXIS_SERIES = -1;
  C_AXIS_ITEM = -1;
  // Tolerance on the steps of the scale, against the rounding of floating point numbers.
  C_SCALE_EPSILON = 1E-4;

var
  GInvariantFormat: TFormatSettings;

{ TS4YChartCategory }

procedure TS4YChartCategory.Assign(Source: TPersistent);
var
  LSource: TS4YChartCategory;
begin
  if Source is TS4YChartCategory then
  begin
    LSource := TS4YChartCategory(Source);
    FCaption := LSource.Caption;
    FTag := LSource.Tag;
    FValues := Copy(LSource.FValues);
    Changed(False);
  end
  else
    inherited;
end;

function TS4YChartCategory.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

function TS4YChartCategory.GetValue(ASeriesIndex: Integer): Single;
begin
  if (ASeriesIndex >= 0) and (ASeriesIndex < Length(FValues)) then
    Result := FValues[ASeriesIndex]
  else
    Result := 0;
end;

function TS4YChartCategory.GetValueCount: Integer;
begin
  Result := Length(FValues);
end;

function TS4YChartCategory.GetValuesText: string;
begin
  Result := '';

  for var LIndex := 0 to Length(FValues) - 1 do
  begin
    if LIndex > 0 then
      Result := Result + C_VALUES_SEPARATOR;

    Result := Result + FloatToStr(FValues[LIndex], GInvariantFormat);
  end;
end;

procedure TS4YChartCategory.SetCaption(const Value: string);
begin
  if FCaption = Value then
    Exit;

  FCaption := Value;
  Changed(False);
end;

procedure TS4YChartCategory.SetValue(ASeriesIndex: Integer; const Value: Single);
begin
  if ASeriesIndex < 0 then
    Exit;

  if ASeriesIndex >= Length(FValues) then
    SetLength(FValues, ASeriesIndex + 1);

  FValues[ASeriesIndex] := Value;
  Changed(False);
end;

procedure TS4YChartCategory.SetValuesText(const Value: string);
var
  LParts: TArray<string>;
begin
  LParts := Value.Split([C_VALUES_SEPARATOR]);
  SetLength(FValues, Length(LParts));

  for var LIndex := 0 to Length(LParts) - 1 do
    FValues[LIndex] := StrToFloatDef(LParts[LIndex].Trim, 0, GInvariantFormat);

  Changed(False);
end;

{ TS4YChartCategories }

constructor TS4YChartCategories.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YChartCategory);
end;

function TS4YChartCategories.Add: TS4YChartCategory;
begin
  Result := TS4YChartCategory(inherited Add);
end;

function TS4YChartCategories.Add(const ACaption: string; const AValues: array of Single): TS4YChartCategory;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.Caption := ACaption;

    for var LIndex := 0 to Length(AValues) - 1 do
      Result.Value[LIndex] := AValues[LIndex];
  finally
    EndUpdate;
  end;
end;

function TS4YChartCategories.GetItem(Index: Integer): TS4YChartCategory;
begin
  Result := TS4YChartCategory(inherited GetItem(Index));
end;

procedure TS4YChartCategories.SetItem(Index: Integer; const Value: TS4YChartCategory);
begin
  inherited SetItem(Index, Value);
end;

procedure TS4YChartCategories.Update(Item: TCollectionItem);
begin
  inherited;

  if Owner is TS4YCustomCategoryChart then
    TS4YCustomCategoryChart(Owner).DataSetChanged;
end;

{ TS4YChartSeries }

constructor TS4YChartSeries.Create(Collection: TCollection);
begin
  inherited;

  FColor := C_DEFAULT_COLOR;
end;

procedure TS4YChartSeries.Assign(Source: TPersistent);
var
  LSource: TS4YChartSeries;
begin
  if Source is TS4YChartSeries then
  begin
    LSource := TS4YChartSeries(Source);
    FCaption := LSource.Caption;
    FColor := LSource.Color;
    FTag := LSource.Tag;
    Changed(False);
  end
  else
    inherited;
end;

function TS4YChartSeries.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TS4YChartSeries.SetCaption(const Value: string);
begin
  if FCaption = Value then
    Exit;

  FCaption := Value;
  Changed(False);
end;

procedure TS4YChartSeries.SetColor(const Value: TAlphaColor);
begin
  if FColor = Value then
    Exit;

  FColor := Value;
  Changed(False);
end;

{ TS4YChartSeriesList }

constructor TS4YChartSeriesList.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YChartSeries);
end;

function TS4YChartSeriesList.Add: TS4YChartSeries;
begin
  Result := TS4YChartSeries(inherited Add);
end;

function TS4YChartSeriesList.Add(const ACaption: string): TS4YChartSeries;
begin
  Result := Add;
  Result.Caption := ACaption;
end;

function TS4YChartSeriesList.GetItem(Index: Integer): TS4YChartSeries;
begin
  Result := TS4YChartSeries(inherited GetItem(Index));
end;

procedure TS4YChartSeriesList.SetItem(Index: Integer; const Value: TS4YChartSeries);
begin
  inherited SetItem(Index, Value);
end;

procedure TS4YChartSeriesList.Update(Item: TCollectionItem);
begin
  inherited;

  if Owner is TS4YCustomCategoryChart then
    TS4YCustomCategoryChart(Owner).DataSetChanged;
end;

{ TS4YChartAxis }

constructor TS4YChartAxis.Create;
begin
  inherited Create;

  FVisible := C_DEFAULT_VISIBLE;
end;

procedure TS4YChartAxis.Assign(Source: TPersistent);
begin
  if Source is TS4YChartAxis then
  begin
    FVisible := TS4YChartAxis(Source).Visible;
    DoChange;
  end
  else
    inherited;
end;

procedure TS4YChartAxis.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YChartAxis.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;
  DoChange;
end;

{ TS4YChartCategoryAxis }

constructor TS4YChartCategoryAxis.Create;
begin
  inherited;

  FGridLines := C_DEFAULT_GRID_LINES;
end;

procedure TS4YChartCategoryAxis.Assign(Source: TPersistent);
begin
  if Source is TS4YChartCategoryAxis then
    FGridLines := TS4YChartCategoryAxis(Source).GridLines;

  inherited;
end;

procedure TS4YChartCategoryAxis.SetGridLines(const Value: Boolean);
begin
  if FGridLines = Value then
    Exit;

  FGridLines := Value;
  DoChange;
end;

{ TS4YChartValueAxis }

constructor TS4YChartValueAxis.Create;
begin
  inherited;

  FAutoRange := C_DEFAULT_AUTO_RANGE;
  FGridLines := C_DEFAULT_GRID_LINES;
  FMax := C_DEFAULT_MAX;
  FMin := C_DEFAULT_MIN;
end;

procedure TS4YChartValueAxis.Assign(Source: TPersistent);
var
  LSource: TS4YChartValueAxis;
begin
  if Source is TS4YChartValueAxis then
  begin
    LSource := TS4YChartValueAxis(Source);
    FAutoRange := LSource.AutoRange;
    FGridLines := LSource.GridLines;
    FMax := LSource.Max;
    FMin := LSource.Min;
  end;

  inherited;
end;

function TS4YChartValueAxis.MaxStored: Boolean;
begin
  Result := not SameValue(FMax, C_DEFAULT_MAX);
end;

function TS4YChartValueAxis.MinStored: Boolean;
begin
  Result := not SameValue(FMin, C_DEFAULT_MIN);
end;

procedure TS4YChartValueAxis.SetAutoRange(const Value: Boolean);
begin
  if FAutoRange = Value then
    Exit;

  FAutoRange := Value;
  DoChange;
end;

procedure TS4YChartValueAxis.SetGridLines(const Value: Boolean);
begin
  if FGridLines = Value then
    Exit;

  FGridLines := Value;
  DoChange;
end;

procedure TS4YChartValueAxis.SetMax(const Value: Single);
begin
  if SameValue(FMax, Value) then
    Exit;

  FMax := Value;
  DoChange;
end;

procedure TS4YChartValueAxis.SetMin(const Value: Single);
begin
  if SameValue(FMin, Value) then
    Exit;

  FMin := Value;
  DoChange;
end;

{ TS4YCustomCategoryChart }

constructor TS4YCustomCategoryChart.Create(AOwner: TComponent);
begin
  inherited;

  FCategories := TS4YChartCategories.Create(Self);
  FSeries := TS4YChartSeriesList.Create(Self);
  FBoundCategories := TObjectList<TS4YChartCategory>.Create(True);
  FBoundSeries := TObjectList<TS4YChartSeries>.Create(True);
  FCategoryAxis := TS4YChartCategoryAxis.Create;
  FCategoryAxis.OnChange := AxisChanged;
  FValueAxis := TS4YChartValueAxis.Create;
  FValueAxis.OnChange := AxisChanged;
  FAxisStroke := TStrokeBrush.Create(TBrushKind.Solid, C_DEFAULT_AXIS_COLOR);
  FAxisStroke.Thickness := C_DEFAULT_LINE_THICKNESS;
  FGridStroke := TStrokeBrush.Create(TBrushKind.Solid, C_DEFAULT_GRID_COLOR);
  FGridStroke.Thickness := C_DEFAULT_LINE_THICKNESS;
end;

destructor TS4YCustomCategoryChart.Destroy;
begin
  inherited;

  // After the inherited destructor, which stops the animation that reads the categories.
  FreeAndNil(FGridStroke);
  FreeAndNil(FAxisStroke);
  FreeAndNil(FValueAxis);
  FreeAndNil(FCategoryAxis);
  FreeAndNil(FBoundSeries);
  FreeAndNil(FBoundCategories);
  FreeAndNil(FSeries);
  FreeAndNil(FCategories);
end;

procedure TS4YCustomCategoryChart.AddSampleData;
begin
  for var I := Low(C_SAMPLE_VALUES[0]) to High(C_SAMPLE_VALUES[0]) do
    FSeries.Add(Format(S_CHART_SAMPLE_SERIES_CAPTION, [I + 1]));

  for var I := Low(C_SAMPLE_VALUES) to High(C_SAMPLE_VALUES) do
    FCategories.Add(Format(S_CHART_SAMPLE_CATEGORY_CAPTION, [I + 1]), C_SAMPLE_VALUES[I]);
end;

procedure TS4YCustomCategoryChart.ApplyStyle;
var
  LPart: TShape;
begin
  inherited;

  FindStyleResource<TText>(C_STYLE_AXIS_TEXT, FStyleAxisText);

  if FindStyleResource<TShape>(C_STYLE_AXIS, LPart) then
    FAxisStroke.Assign(LPart.Stroke);

  if FindStyleResource<TShape>(C_STYLE_GRIDLINE, LPart) then
    FGridStroke.Assign(LPart.Stroke);
end;

procedure TS4YCustomCategoryChart.AxisChanged(Sender: TObject);
begin
  Repaint;
end;

function TS4YCustomCategoryChart.BindingAddLinkColumn(const ACaption: string): Integer;
var
  LSeries: TS4YChartSeries;
begin
  // The first column of the link gives the captions; each next column is a series.
  Result := FBindingColumnCount;
  Inc(FBindingColumnCount);

  if Result > 0 then
  begin
    LSeries := TS4YChartSeries.Create(nil);
    LSeries.Caption := ACaption;
    FBoundSeries.Add(LSeries);
    DoSeriesBound(LSeries);
  end;

  DataSetChanged;
end;

function TS4YCustomCategoryChart.BindingAddRow: Integer;
begin
  Result := FBoundCategories.Add(TS4YChartCategory.Create(nil));
end;

procedure TS4YCustomCategoryChart.BindingBeginUpdate;
begin
  Inc(FBindingUpdateDepth);
end;

procedure TS4YCustomCategoryChart.BindingClearLinkColumns;
begin
  FBindingColumnCount := 0;
  FBoundSeries.Clear;
  FBoundCategories.Clear;
  DataSetChanged;
end;

procedure TS4YCustomCategoryChart.BindingClearRows;
begin
  FBoundCategories.Clear;

  if FBindingUpdateDepth = 0 then
    DataSetChanged;
end;

procedure TS4YCustomCategoryChart.BindingDeleteRowsFrom(const AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FBoundCategories.Count) then
    FBoundCategories.DeleteRange(AIndex, FBoundCategories.Count - AIndex);

  if FBindingUpdateDepth = 0 then
    DataSetChanged;
end;

procedure TS4YCustomCategoryChart.BindingEndUpdate;
begin
  Dec(FBindingUpdateDepth);

  if FBindingUpdateDepth > 0 then
    Exit;

  for var LIndex := 0 to FBoundCategories.Count - 1 do
    DoCategoryBound(FBoundCategories[LIndex]);

  DataSetChanged;
end;

function TS4YCustomCategoryChart.BindingGetCaption(const ARow: Integer): string;
begin
  Result := FBoundCategories[ARow].Caption;
end;

function TS4YCustomCategoryChart.BindingGetRowCount: Integer;
begin
  Result := FBoundCategories.Count;
end;

function TS4YCustomCategoryChart.BindingGetValue(const ARow, AColumn: Integer): Single;
begin
  Result := FBoundCategories[ARow].Value[AColumn];
end;

procedure TS4YCustomCategoryChart.BindingSetCaption(const ARow: Integer; const ACaption: string);
begin
  FBoundCategories[ARow].Caption := ACaption;
  BoundCategoryChanged(ARow);
end;

procedure TS4YCustomCategoryChart.BindingSetValue(const ARow, AColumn: Integer; const AValue: Single);
begin
  FBoundCategories[ARow].Value[AColumn] := AValue;
  BoundCategoryChanged(ARow);
end;

procedure TS4YCustomCategoryChart.BindingUpdateLinkColumn(const ALinkColumn: Integer; const ACaption: string);
begin
  if (ALinkColumn > 0) and (ALinkColumn - 1 < FBoundSeries.Count) then
  begin
    FBoundSeries[ALinkColumn - 1].Caption := ACaption;
    Repaint;
  end;
end;

procedure TS4YCustomCategoryChart.BoundCategoryChanged(const ARow: Integer);
begin
  // A single record changed outside an update of the list, for example after a post.
  if FBindingUpdateDepth > 0 then
    Exit;

  DoCategoryBound(FBoundCategories[ARow]);
  DataSetChanged;
end;

procedure TS4YCustomCategoryChart.CalculateScale;
var
  LHigh: Single;
  LLow: Single;
  LMagnitude: Single;
  LRawStep: Single;
  LValue: Single;
  LNiceIndex: Integer;
begin
  if not FValueAxis.AutoRange then
  begin
    LLow := FValueAxis.Min;
    LHigh := FValueAxis.Max;
  end
  else
  begin
    // The range of the data, not of the values drawn: the scale stays still during the animation.
    LLow := 0;
    LHigh := 0;

    for var LCategory := 0 to GetDrawnCategoryCount - 1 do
    begin
      for var LSeries := 0 to GetDrawnSeriesCount - 1 do
      begin
        LValue := GetDrawnCategory(LCategory).Value[LSeries];
        LLow := System.Math.Min(LLow, LValue);
        LHigh := System.Math.Max(LHigh, LValue);
      end;
    end;
  end;

  if LHigh <= LLow then
    LHigh := LLow + 1;

  // A step of 1, 2, 2.5 or 5 times a power of 10, for about C_TARGET_STEPS steps.
  LRawStep := (LHigh - LLow) / C_TARGET_STEPS;
  LMagnitude := Power(10, Floor(Log10(LRawStep)));
  LNiceIndex := 0;

  while (LNiceIndex < High(C_NICE_STEPS)) and (C_NICE_STEPS[LNiceIndex] * LMagnitude < LRawStep - C_SCALE_EPSILON) do
    Inc(LNiceIndex);

  FScaleStep := C_NICE_STEPS[LNiceIndex] * LMagnitude;

  if FValueAxis.AutoRange then
  begin
    FScaleMin := Floor(LLow / FScaleStep + C_SCALE_EPSILON) * FScaleStep;
    FScaleMax := Ceil(LHigh / FScaleStep - C_SCALE_EPSILON) * FScaleStep;

    // A value on the edge of the scale gets a step more, so that the value written beyond its bar
    // stays inside the chart.
    if (LHigh > 0) and SameValue(FScaleMax, LHigh, FScaleStep * C_SCALE_EPSILON) then
      FScaleMax := FScaleMax + FScaleStep;

    if (LLow < 0) and SameValue(FScaleMin, LLow, FScaleStep * C_SCALE_EPSILON) then
      FScaleMin := FScaleMin - FScaleStep;
  end
  else
  begin
    FScaleMin := LLow;
    FScaleMax := LHigh;
  end;
end;

function TS4YCustomCategoryChart.CategoriesVertical: Boolean;
begin
  Result := False;
end;

function TS4YCustomCategoryChart.CategoryGridLinesBetween: Boolean;
begin
  Result := True;
end;

function TS4YCustomCategoryChart.CategoryRect(const AIndex: Integer): TRectF;
var
  LCount: Integer;
  LSlot: Single;
begin
  LCount := System.Math.Max(1, GetDrawnCategoryCount);

  if CategoriesVertical then
  begin
    LSlot := FDataRect.Height / LCount;
    Result := TRectF.Create(FDataRect.Left, FDataRect.Top + AIndex * LSlot, FDataRect.Right,
      FDataRect.Top + (AIndex + 1) * LSlot);
  end
  else
  begin
    LSlot := FDataRect.Width / LCount;
    Result := TRectF.Create(FDataRect.Left + AIndex * LSlot, FDataRect.Top, FDataRect.Left + (AIndex + 1) * LSlot,
      FDataRect.Bottom);
  end;
end;

procedure TS4YCustomCategoryChart.DataSetChanged;
begin
  // The data drawn depend on the link, while it has columns, else on the stored lists.
  DataChanged;
end;

procedure TS4YCustomCategoryChart.DoCategoryBound(const ACategory: TS4YChartCategory);
begin
  if Assigned(FOnCategoryBound) then
    FOnCategoryBound(Self, ACategory);
end;

procedure TS4YCustomCategoryChart.DoSeriesBound(const ASeries: TS4YChartSeries);
begin
  if Assigned(FOnSeriesBound) then
    FOnSeriesBound(Self, ASeries);
end;

procedure TS4YCustomCategoryChart.DrawAxes(const APlotRect: TRectF);

  procedure DrawCategoryGridLine(const APoint: TPointF);
  begin
    // A line across the chart, at the position of APoint along the category axis.
    if CategoriesVertical then
      Canvas.DrawLine(TPointF.Create(FDataRect.Left, APoint.Y), TPointF.Create(FDataRect.Right, APoint.Y),
        AbsoluteOpacity)
    else
      Canvas.DrawLine(TPointF.Create(APoint.X, FDataRect.Top), TPointF.Create(APoint.X, FDataRect.Bottom),
        AbsoluteOpacity);
  end;

var
  LCaption: string;
  LCategoryLabelSize: Single;
  LPosition: Single;
  LSize: TSizeF;
  LSlot: TRectF;
  LStepCount: Integer;
  LValue: Single;
  LValueLabelSize: Single;
begin
  LStepCount := Round((FScaleMax - FScaleMin) / FScaleStep);
  LValueLabelSize := 0;
  LCategoryLabelSize := 0;

  // The labels of the axes take room on the left and at the bottom of the plot.
  if FValueAxis.Visible then
  begin
    for var LStep := 0 to LStepCount do
    begin
      LSize := MeasureText(FStyleAxisText, C_DEFAULT_AXIS_TEXT_COLOR,
        GetValueText(C_AXIS_SERIES, C_AXIS_ITEM, FScaleMin + LStep * FScaleStep));

      if CategoriesVertical then
        LValueLabelSize := System.Math.Max(LValueLabelSize, LSize.Height)
      else
        LValueLabelSize := System.Math.Max(LValueLabelSize, LSize.Width);
    end;
  end;

  if FCategoryAxis.Visible then
  begin
    for var LIndex := 0 to GetDrawnCategoryCount - 1 do
    begin
      LSize := MeasureText(FStyleAxisText, C_DEFAULT_AXIS_TEXT_COLOR, GetDrawnCategory(LIndex).Caption);

      if CategoriesVertical then
        LCategoryLabelSize := System.Math.Max(LCategoryLabelSize, LSize.Width)
      else
        LCategoryLabelSize := System.Math.Max(LCategoryLabelSize, LSize.Height);
    end;
  end;

  FDataRect := APlotRect;

  if CategoriesVertical then
  begin
    if LCategoryLabelSize > 0 then
      FDataRect.Left := FDataRect.Left + LCategoryLabelSize + C_AXIS_LABEL_SPACING;

    if LValueLabelSize > 0 then
      FDataRect.Bottom := FDataRect.Bottom - LValueLabelSize - C_AXIS_LABEL_SPACING;
  end
  else
  begin
    if LValueLabelSize > 0 then
      FDataRect.Left := FDataRect.Left + LValueLabelSize + C_AXIS_LABEL_SPACING;

    if LCategoryLabelSize > 0 then
      FDataRect.Bottom := FDataRect.Bottom - LCategoryLabelSize - C_AXIS_LABEL_SPACING;
  end;

  if (FDataRect.Width <= 0) or (FDataRect.Height <= 0) then
    Exit;

  // Grid lines and labels of the values, at each step of the scale.
  for var LStep := 0 to LStepCount do
  begin
    LValue := FScaleMin + LStep * FScaleStep;
    LPosition := ValueToPosition(LValue);

    if FValueAxis.GridLines and (FGridStroke.Kind <> TBrushKind.None) then
    begin
      Canvas.Stroke.Assign(FGridStroke);

      if CategoriesVertical then
        Canvas.DrawLine(TPointF.Create(LPosition, FDataRect.Top), TPointF.Create(LPosition, FDataRect.Bottom),
          AbsoluteOpacity)
      else
        Canvas.DrawLine(TPointF.Create(FDataRect.Left, LPosition), TPointF.Create(FDataRect.Right, LPosition),
          AbsoluteOpacity);
    end;

    if FValueAxis.Visible then
    begin
      if CategoriesVertical then
        RenderText(FStyleAxisText, C_DEFAULT_AXIS_TEXT_COLOR, GetValueText(C_AXIS_SERIES, C_AXIS_ITEM, LValue),
          TRectF.Create(LPosition - FDataRect.Width, FDataRect.Bottom + C_AXIS_LABEL_SPACING,
          LPosition + FDataRect.Width, FDataRect.Bottom + C_AXIS_LABEL_SPACING + LValueLabelSize),
          TTextAlign.Center, TTextAlign.Leading)
      else
        RenderText(FStyleAxisText, C_DEFAULT_AXIS_TEXT_COLOR, GetValueText(C_AXIS_SERIES, C_AXIS_ITEM, LValue),
          TRectF.Create(APlotRect.Left, LPosition - FDataRect.Height, FDataRect.Left - C_AXIS_LABEL_SPACING,
          LPosition + FDataRect.Height), TTextAlign.Trailing, TTextAlign.Center);
    end;
  end;

  // Grid lines of the categories: between them, or through their middle.
  if FCategoryAxis.GridLines and (FGridStroke.Kind <> TBrushKind.None) then
  begin
    Canvas.Stroke.Assign(FGridStroke);

    for var LIndex := 0 to GetDrawnCategoryCount - 1 do
    begin
      LSlot := CategoryRect(LIndex);

      // Between the categories there is no line before the first one: it would be the edge of the chart.
      if not CategoryGridLinesBetween then
        DrawCategoryGridLine(LSlot.CenterPoint)
      else if LIndex > 0 then
        DrawCategoryGridLine(LSlot.TopLeft);
    end;
  end;

  // Labels of the categories, in the middle of their slot.
  if FCategoryAxis.Visible then
  begin
    for var LIndex := 0 to GetDrawnCategoryCount - 1 do
    begin
      LSlot := CategoryRect(LIndex);
      LCaption := GetDrawnCategory(LIndex).Caption;

      if CategoriesVertical then
        RenderText(FStyleAxisText, C_DEFAULT_AXIS_TEXT_COLOR, LCaption, TRectF.Create(APlotRect.Left, LSlot.Top,
          FDataRect.Left - C_AXIS_LABEL_SPACING, LSlot.Bottom), TTextAlign.Trailing, TTextAlign.Center)
      else
        RenderText(FStyleAxisText, C_DEFAULT_AXIS_TEXT_COLOR, LCaption, TRectF.Create(LSlot.Left,
          FDataRect.Bottom + C_AXIS_LABEL_SPACING, LSlot.Right, FDataRect.Bottom + C_AXIS_LABEL_SPACING +
          LCategoryLabelSize), TTextAlign.Center, TTextAlign.Leading);
    end;
  end;
end;

procedure TS4YCustomCategoryChart.DrawChart(const APlotRect: TRectF);
var
  LBaseline: Single;
begin
  CalculateScale;
  DrawAxes(APlotRect);

  if (FDataRect.Width <= 0) or (FDataRect.Height <= 0) then
    Exit;

  DrawData(FDataRect);

  // The lines of the axes over the data: the category axis at the value 0, or at the edge of the range.
  if FAxisStroke.Kind = TBrushKind.None then
    Exit;

  Canvas.Stroke.Assign(FAxisStroke);
  LBaseline := ValueToPosition(EnsureRange(0, FScaleMin, FScaleMax));

  if CategoriesVertical then
  begin
    if FCategoryAxis.Visible then
      Canvas.DrawLine(TPointF.Create(LBaseline, FDataRect.Top), TPointF.Create(LBaseline, FDataRect.Bottom),
        AbsoluteOpacity);

    if FValueAxis.Visible then
      Canvas.DrawLine(TPointF.Create(FDataRect.Left, FDataRect.Bottom),
        TPointF.Create(FDataRect.Right, FDataRect.Bottom), AbsoluteOpacity);
  end
  else
  begin
    if FCategoryAxis.Visible then
      Canvas.DrawLine(TPointF.Create(FDataRect.Left, LBaseline), TPointF.Create(FDataRect.Right, LBaseline),
        AbsoluteOpacity);

    if FValueAxis.Visible then
      Canvas.DrawLine(TPointF.Create(FDataRect.Left, FDataRect.Top), TPointF.Create(FDataRect.Left, FDataRect.Bottom),
        AbsoluteOpacity);
  end;
end;

procedure TS4YCustomCategoryChart.FreeStyle;
begin
  FStyleAxisText := nil;

  inherited;
end;

function TS4YCustomCategoryChart.GetDisplayedCategoryValue(const ACategoryIndex, ASeriesIndex: Integer): Single;
begin
  Result := GetDisplayedValue(ACategoryIndex * GetDrawnSeriesCount + ASeriesIndex);
end;

function TS4YCustomCategoryChart.GetDrawnCategory(Index: Integer): TS4YChartCategory;
begin
  if IsBound then
    Result := FBoundCategories[Index]
  else
    Result := FCategories[Index];
end;

function TS4YCustomCategoryChart.GetDrawnCategoryCount: Integer;
begin
  if IsBound then
    Result := FBoundCategories.Count
  else
    Result := FCategories.Count;
end;

function TS4YCustomCategoryChart.GetDrawnSeries(Index: Integer): TS4YChartSeries;
begin
  if IsBound then
    Result := FBoundSeries[Index]
  else
    Result := FSeries[Index];
end;

function TS4YCustomCategoryChart.GetDrawnSeriesCount: Integer;
begin
  if IsBound then
    Result := FBoundSeries.Count
  else
    Result := FSeries.Count;
end;

function TS4YCustomCategoryChart.GetLegendEntryCaption(const AIndex: Integer): string;
begin
  Result := GetDrawnSeries(AIndex).Caption;
end;

function TS4YCustomCategoryChart.GetLegendEntryColor(const AIndex: Integer): TAlphaColor;
begin
  Result := GetSeriesColor(AIndex);
end;

function TS4YCustomCategoryChart.GetLegendEntryCount: Integer;
begin
  Result := GetDrawnSeriesCount;
end;

function TS4YCustomCategoryChart.GetSeriesColor(const AIndex: Integer): TAlphaColor;
begin
  Result := ResolveColor(GetDrawnSeries(AIndex).Color, AIndex);
end;

function TS4YCustomCategoryChart.GetTargetValues: TArray<Single>;
var
  LSeriesCount: Integer;
begin
  LSeriesCount := GetDrawnSeriesCount;
  SetLength(Result, GetDrawnCategoryCount * LSeriesCount);

  for var LCategory := 0 to GetDrawnCategoryCount - 1 do
  begin
    for var LSeries := 0 to LSeriesCount - 1 do
      Result[LCategory * LSeriesCount + LSeries] := GetDrawnCategory(LCategory).Value[LSeries];
  end;
end;

function TS4YCustomCategoryChart.IsBound: Boolean;
begin
  // While the link has columns, the chart draws the records of the link.
  Result := FBindingColumnCount > 0;
end;

procedure TS4YCustomCategoryChart.SetCategories(const Value: TS4YChartCategories);
begin
  FCategories.Assign(Value);
end;

procedure TS4YCustomCategoryChart.SetCategoryAxis(const Value: TS4YChartCategoryAxis);
begin
  FCategoryAxis.Assign(Value);
end;

procedure TS4YCustomCategoryChart.SetSeries(const Value: TS4YChartSeriesList);
begin
  FSeries.Assign(Value);
end;

procedure TS4YCustomCategoryChart.SetValueAxis(const Value: TS4YChartValueAxis);
begin
  FValueAxis.Assign(Value);
end;

function TS4YCustomCategoryChart.ValueToPosition(const AValue: Single): Single;
var
  LFraction: Single;
begin
  if FScaleMax - FScaleMin <= 0 then
    LFraction := 0
  else
    LFraction := (EnsureRange(AValue, FScaleMin, FScaleMax) - FScaleMin) / (FScaleMax - FScaleMin);

  if CategoriesVertical then
    Result := FDataRect.Left + LFraction * FDataRect.Width
  else
    Result := FDataRect.Bottom - LFraction * FDataRect.Height;
end;

initialization
  GInvariantFormat := TFormatSettings.Invariant;

end.
