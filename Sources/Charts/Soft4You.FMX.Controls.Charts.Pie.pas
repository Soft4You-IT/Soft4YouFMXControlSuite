unit Soft4You.FMX.Controls.Charts.Pie;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YPieChart - pie and ring chart
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
  /// A slice of a TS4YPieChart.
  /// </summary>
  /// <remarks>
  /// The slices of the Slices list are stored in the form; the slices filled by the LiveBindings are created by the chart, are not stored, and are passed to OnSliceBound.
  /// </remarks>
  TS4YPieSlice = class(TCollectionItem)
  public const
    /// <summary>Default value of Color: the color of the palette of the chart for the position of the slice.</summary>
    C_DEFAULT_COLOR = TAlphaColorRec.Null;
  private
    FCaption: string;
    FColor: TAlphaColor;
    FTag: NativeInt;
    FValue: Single;
    procedure SetCaption(const Value: string);
    procedure SetColor(const Value: TAlphaColor);
    procedure SetValue(const Value: Single);
    function ValueStored: Boolean;
  protected
    /// <summary>Returns the caption of the slice, shown by the editor of the collection in the IDE.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates a slice without caption, with value 0 and the color of the palette.</summary>
    constructor Create(Collection: TCollection); override;

    /// <summary>Copies all the properties from another TS4YPieSlice.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>Text of the slice, shown in the legend and, with LabelContent = plcCaption, on the slice.</summary>
    property Caption: string read FCaption write SetCaption;
    /// <summary>Color of the slice. With claNull, the default, the slice takes the color of the palette for its position.</summary>
    property Color: TAlphaColor read FColor write SetColor default C_DEFAULT_COLOR;
    /// <summary>A value free for the application. The chart does not use it.</summary>
    property Tag: NativeInt read FTag write FTag default 0;
    /// <summary>Value of the slice: the slice is as large as its part of the total. A negative value counts as 0.</summary>
    property Value: Single read FValue write SetValue stored ValueStored nodefault;
  end;

  /// <summary>
  /// The slices of a TS4YPieChart stored in the form.
  /// </summary>
  TS4YPieSlices = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TS4YPieSlice;
    procedure SetItem(Index: Integer; const Value: TS4YPieSlice);
  protected
    /// <summary>Redraws the chart when the slices change.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the slices of AOwner, empty.</summary>
    constructor Create(AOwner: TPersistent);

    /// <summary>Adds a slice at the end and returns it.</summary>
    function Add: TS4YPieSlice; overload;
    /// <summary>Adds a slice with ACaption and AValue at the end and returns it.</summary>
    function Add(const ACaption: string; const AValue: Single): TS4YPieSlice; overload;

    /// <summary>The slices, in their order around the chart, clockwise from StartAngle.</summary>
    property Items[Index: Integer]: TS4YPieSlice read GetItem write SetItem; default;
  end;

  /// <summary>
  /// Event fired for each slice filled by the LiveBindings, after every update of the data.
  /// </summary>
  /// <remarks>
  /// ASlice has the caption and the value of its record, and Color = claNull, the color of the palette for its position: the event can change its color, its caption and its tag.
  /// </remarks>
  TS4YPieSliceBoundEvent = procedure(Sender: TObject; const ASlice: TS4YPieSlice) of object;

  /// <summary>
  /// A pie chart, or a ring chart with InnerRadius greater than 0: each slice is as large as its part of the total.
  /// </summary>
  /// <remarks>
  /// The slices come from Slices or, while a TLinkGridToDataSource fills the chart, from its records: the first column of the link gives the captions, the second the values.
  /// The look comes from the style S4YPieChartStyle: its parts color1 to color8 give the palette, the Stroke of its part slice the border between the slices, and its texts labeltext, outerlabeltext, legendtext, centertext and centercaptiontext the fonts and the colors.
  /// </remarks>
  TS4YPieChart = class(TS4YCustomChart)
  public const
    /// <summary>Default value of InnerRadius: a pie.</summary>
    C_DEFAULT_INNER_RADIUS: Single = 0;
    /// <summary>Largest value of InnerRadius, in percent of the radius.</summary>
    C_MAX_INNER_RADIUS: Single = 90;
    /// <summary>Default value of LabelContent.</summary>
    C_DEFAULT_LABEL_CONTENT = plcPercent;
    /// <summary>Default value of LabelPosition.</summary>
    C_DEFAULT_LABEL_POSITION = plpInside;
    /// <summary>Default value of ShowTotal.</summary>
    C_DEFAULT_SHOW_TOTAL = False;
    /// <summary>Default value of StartAngle, in degrees: the top of the circle.</summary>
    C_DEFAULT_START_ANGLE: Single = 0;
    /// <summary>Default color of the border between the slices, when the style has no slice part.</summary>
    C_DEFAULT_SLICE_STROKE_COLOR: TAlphaColor = $FFFFFFFF;
    /// <summary>Default thickness of the border between the slices, when the style has no slice part.</summary>
    C_DEFAULT_SLICE_STROKE_THICKNESS: Single = 2;
  private
    FBindingColumnCount: Integer;
    FBindingUpdateDepth: Integer;
    FBoundSlices: TObjectList<TS4YPieSlice>;
    FCenter: TPointF;
    FCenterCaption: string;
    FDrawnInnerRadius: Single;
    FDrawnOuterRadius: Single;
    FInnerRadius: Single;
    FLabelContent: TS4YPieLabelContent;
    FLabelPosition: TS4YPieLabelPosition;
    FShowTotal: Boolean;
    FSlices: TS4YPieSlices;
    FSliceStroke: TStrokeBrush;
    FStartAngle: Single;
    FStyleCenterCaptionText: TText;
    FStyleCenterText: TText;
    FStyleLabelText: TText;
    FStyleOuterLabelText: TText;
    FOnSliceBound: TS4YPieSliceBoundEvent;
    procedure BoundSliceChanged(const ARow: Integer);
    procedure DrawCenter(const ATotal: Single);
    procedure DrawLabels(const ATotal: Single);
    procedure DrawSliceLabel(const AIndex: Integer; const AMiddleAngle, ASweepAngle: Single; const AText: string);
    procedure DrawSlice(const AIndex: Integer; const AStartAngle, ASweepAngle: Single);
    function GetDisplayedTotal: Single;
    function GetDrawnSlice(Index: Integer): TS4YPieSlice;
    function GetDrawnSliceCount: Integer;
    function GetLabelText(const AIndex: Integer; const ATotal: Single): string;
    function GetSliceColor(const AIndex: Integer): TAlphaColor;
    function InnerRadiusStored: Boolean;
    function IsBound: Boolean;
    procedure SetCenterCaption(const Value: string);
    procedure SetInnerRadius(const Value: Single);
    procedure SetLabelContent(const Value: TS4YPieLabelContent);
    procedure SetLabelPosition(const Value: TS4YPieLabelPosition);
    procedure SetShowTotal(const Value: Boolean);
    procedure SetSlices(const Value: TS4YPieSlices);
    procedure SetStartAngle(const Value: Single);
    procedure SlicesChanged;
    function StartAngleStored: Boolean;
  protected
    /// <summary>Adds four slices, Item 1 to Item 4.</summary>
    procedure AddSampleData; override;
    /// <summary>Reads the border of the slices and the texts of the style.</summary>
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
    /// <summary>Fires OnSliceBound.</summary>
    procedure DoSliceBound(const ASlice: TS4YPieSlice); virtual;
    /// <summary>Draws the slices, their labels and the center of the ring.</summary>
    procedure DrawChart(const APlotRect: TRectF); override;
    /// <summary>Returns the slice at APoint; ASeriesIndex is always 0.</summary>
    function FindItemAt(const APoint: TPointF; out ASeriesIndex, AItemIndex: Integer): Boolean; override;
    /// <summary>Releases the texts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control: 300 x 200.</summary>
    function GetDefaultSize: TSizeF; override;
    function GetLegendEntryCaption(const AIndex: Integer): string; override;
    function GetLegendEntryColor(const AIndex: Integer): TAlphaColor; override;
    function GetLegendEntryCount: Integer; override;
    /// <summary>Returns the values of the slices drawn, negative values as 0.</summary>
    function GetTargetValues: TArray<Single>; override;
  public
    /// <summary>Creates a pie chart without slices.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>The number of the slices drawn: the ones filled by the LiveBindings while a link fills the chart, else the ones of Slices.</summary>
    property DrawnSliceCount: Integer read GetDrawnSliceCount;
    /// <summary>The slices drawn, the ones that ItemIndex and OnItemClick refer to.</summary>
    property DrawnSlices[Index: Integer]: TS4YPieSlice read GetDrawnSlice;
  published
    property Align;
    property Anchors;
    property AnimationDuration;
    /// <summary>Text written in the middle of a ring chart, under the total when ShowTotal is True. Not shown on a pie.</summary>
    property CenterCaption: string read FCenterCaption write SetCenterCaption;
    property Cursor;
    property Enabled;
    property Height;
    property HitTest;
    /// <summary>
    /// Radius of the hole in the middle, in percent of the radius of the chart, from 0 to 90. With 0, the default, the chart is a pie; with a larger value a ring.
    /// </summary>
    property InnerRadius: Single read FInnerRadius write SetInnerRadius stored InnerRadiusStored nodefault;
    /// <summary>What is written on each slice: nothing, the value, the percent of the total (the default) or the caption.</summary>
    property LabelContent: TS4YPieLabelContent read FLabelContent write SetLabelContent default C_DEFAULT_LABEL_CONTENT;
    /// <summary>
    /// Where the labels are written: inside the slices (plpInside, the default) or beside them (plpOutside).
    /// </summary>
    /// <remarks>
    /// A label inside a slice too small for it is not written. Labels outside make the chart smaller, to leave room for them.
    /// </remarks>
    property LabelPosition: TS4YPieLabelPosition read FLabelPosition write SetLabelPosition default C_DEFAULT_LABEL_POSITION;
    property Legend;
    property Margins;
    property Opacity;
    property Padding;
    property Palette;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    /// <summary>True writes the total of the values in the middle of a ring chart, formatted with ValueFormat. The default is False.</summary>
    property ShowTotal: Boolean read FShowTotal write SetShowTotal default C_DEFAULT_SHOW_TOTAL;
    property Size;
    /// <summary>The slices stored in the form. While a TLinkGridToDataSource fills the chart, the slices of its records are drawn instead.</summary>
    property Slices: TS4YPieSlices read FSlices write SetSlices;
    /// <summary>Angle where the first slice starts, in degrees: 0, the default, is the top of the circle, 90 its right side. The slices follow clockwise.</summary>
    property StartAngle: Single read FStartAngle write SetStartAngle stored StartAngleStored nodefault;
    property StyleLookup;
    property ValueFormat;
    property Visible;
    property Width;

    property OnClick;
    property OnDblClick;
    property OnGetValueText;
    property OnItemClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    /// <summary>Fires for each slice filled by the LiveBindings after every update of the data, to change its color or its caption.</summary>
    property OnSliceBound: TS4YPieSliceBoundEvent read FOnSliceBound write FOnSliceBound;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  Soft4You.FMX.Controls.Charts.Bindings,
  Soft4You.FMX.Controls.Charts.Strings;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_SLICE = 'slice';
  C_STYLE_LABEL_TEXT = 'labeltext';
  C_STYLE_OUTER_LABEL_TEXT = 'outerlabeltext';
  C_STYLE_CENTER_TEXT = 'centertext';
  C_STYLE_CENTER_CAPTION_TEXT = 'centercaptiontext';

  // Colors used when the style has no text part of that name.
  C_DEFAULT_LABEL_TEXT_COLOR: TAlphaColor = $FFFFFFFF;
  C_DEFAULT_OUTER_LABEL_TEXT_COLOR: TAlphaColor = $FF424242;
  C_DEFAULT_CENTER_TEXT_COLOR: TAlphaColor = $FF212121;
  C_DEFAULT_CENTER_CAPTION_TEXT_COLOR: TAlphaColor = $FF757575;

  // Size of a new chart.
  C_DEFAULT_WIDTH = 300;
  C_DEFAULT_HEIGHT = 200;
  // Values of the slices of a chart placed in the form designer.
  C_SAMPLE_SLICE_VALUES: array[0..3] of Single = (40, 30, 20, 10);
  // Angle of FMX for the top of the circle: FMX measures the angles from the right side.
  C_FMX_TOP_ANGLE = -90;
  // Distance of a label inside a pie from the center, as a fraction of the radius.
  C_PIE_LABEL_RADIUS = 0.62;
  // Part of the room of a slice a label inside it may take.
  C_LABEL_FIT = 0.9;
  // Length of the line from a slice to its label outside, of its horizontal end, and space before the text.
  C_OUTER_LINE_LENGTH = 10;
  C_OUTER_LINE_END = 6;
  C_OUTER_TEXT_SPACING = 3;
  C_OUTER_LINE_THICKNESS = 1;
  // Smallest radius drawn, in pixels.
  C_MIN_RADIUS = 4;
  // Format of the labels with LabelContent = plcPercent.
  C_PERCENT_FORMAT = '%.0f %%';
  C_PERCENT = 100;
  C_FULL_CIRCLE = 360;
  C_HALF_CIRCLE = 180;
  // Index of the column of values of the link used by the pie: the first after the captions.
  C_VALUE_COLUMN = 0;

{ TS4YPieSlice }

constructor TS4YPieSlice.Create(Collection: TCollection);
begin
  inherited;

  FColor := C_DEFAULT_COLOR;
end;

procedure TS4YPieSlice.Assign(Source: TPersistent);
var
  LSource: TS4YPieSlice;
begin
  if Source is TS4YPieSlice then
  begin
    LSource := TS4YPieSlice(Source);
    FCaption := LSource.Caption;
    FColor := LSource.Color;
    FTag := LSource.Tag;
    FValue := LSource.Value;
    Changed(False);
  end
  else
    inherited;
end;

function TS4YPieSlice.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TS4YPieSlice.SetCaption(const Value: string);
begin
  if FCaption = Value then
    Exit;

  FCaption := Value;
  Changed(False);
end;

procedure TS4YPieSlice.SetColor(const Value: TAlphaColor);
begin
  if FColor = Value then
    Exit;

  FColor := Value;
  Changed(False);
end;

procedure TS4YPieSlice.SetValue(const Value: Single);
begin
  if SameValue(FValue, Value) then
    Exit;

  FValue := Value;
  Changed(False);
end;

function TS4YPieSlice.ValueStored: Boolean;
begin
  Result := not IsZero(FValue);
end;

{ TS4YPieSlices }

constructor TS4YPieSlices.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YPieSlice);
end;

function TS4YPieSlices.Add: TS4YPieSlice;
begin
  Result := TS4YPieSlice(inherited Add);
end;

function TS4YPieSlices.Add(const ACaption: string; const AValue: Single): TS4YPieSlice;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.Caption := ACaption;
    Result.Value := AValue;
  finally
    EndUpdate;
  end;
end;

function TS4YPieSlices.GetItem(Index: Integer): TS4YPieSlice;
begin
  Result := TS4YPieSlice(inherited GetItem(Index));
end;

procedure TS4YPieSlices.SetItem(Index: Integer; const Value: TS4YPieSlice);
begin
  inherited SetItem(Index, Value);
end;

procedure TS4YPieSlices.Update(Item: TCollectionItem);
begin
  inherited;

  if Owner is TS4YPieChart then
    TS4YPieChart(Owner).SlicesChanged;
end;

{ TS4YPieChart }

constructor TS4YPieChart.Create(AOwner: TComponent);
begin
  inherited;

  FInnerRadius := C_DEFAULT_INNER_RADIUS;
  FLabelContent := C_DEFAULT_LABEL_CONTENT;
  FLabelPosition := C_DEFAULT_LABEL_POSITION;
  FShowTotal := C_DEFAULT_SHOW_TOTAL;
  FStartAngle := C_DEFAULT_START_ANGLE;
  FSlices := TS4YPieSlices.Create(Self);
  FBoundSlices := TObjectList<TS4YPieSlice>.Create(True);
  FSliceStroke := TStrokeBrush.Create(TBrushKind.Solid, C_DEFAULT_SLICE_STROKE_COLOR);
  FSliceStroke.Thickness := C_DEFAULT_SLICE_STROKE_THICKNESS;
end;

destructor TS4YPieChart.Destroy;
begin
  inherited;

  // After the inherited destructor, which stops the animation that reads the slices.
  FreeAndNil(FSliceStroke);
  FreeAndNil(FBoundSlices);
  FreeAndNil(FSlices);
end;

procedure TS4YPieChart.AddSampleData;
begin
  for var I := Low(C_SAMPLE_SLICE_VALUES) to High(C_SAMPLE_SLICE_VALUES) do
    FSlices.Add(Format(S_CHART_SAMPLE_SLICE_CAPTION, [I + 1]), C_SAMPLE_SLICE_VALUES[I]);
end;

procedure TS4YPieChart.ApplyStyle;
var
  LSlicePart: TShape;
begin
  inherited;

  FindStyleResource<TText>(C_STYLE_LABEL_TEXT, FStyleLabelText);
  FindStyleResource<TText>(C_STYLE_OUTER_LABEL_TEXT, FStyleOuterLabelText);
  FindStyleResource<TText>(C_STYLE_CENTER_TEXT, FStyleCenterText);
  FindStyleResource<TText>(C_STYLE_CENTER_CAPTION_TEXT, FStyleCenterCaptionText);

  if FindStyleResource<TShape>(C_STYLE_SLICE, LSlicePart) then
    FSliceStroke.Assign(LSlicePart.Stroke);
end;

function TS4YPieChart.BindingAddLinkColumn(const ACaption: string): Integer;
begin
  // The first column of the link gives the captions, the next ones the values: the pie uses the first of them.
  Result := FBindingColumnCount;
  Inc(FBindingColumnCount);

  if FBindingColumnCount = 1 then
    DataChanged;
end;

function TS4YPieChart.BindingAddRow: Integer;
begin
  Result := FBoundSlices.Add(TS4YPieSlice.Create(nil));
end;

procedure TS4YPieChart.BindingBeginUpdate;
begin
  Inc(FBindingUpdateDepth);
end;

procedure TS4YPieChart.BindingClearLinkColumns;
begin
  FBindingColumnCount := 0;
  FBoundSlices.Clear;
  DataChanged;
end;

procedure TS4YPieChart.BindingClearRows;
begin
  FBoundSlices.Clear;

  if FBindingUpdateDepth = 0 then
    DataChanged;
end;

procedure TS4YPieChart.BindingDeleteRowsFrom(const AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FBoundSlices.Count) then
    FBoundSlices.DeleteRange(AIndex, FBoundSlices.Count - AIndex);

  if FBindingUpdateDepth = 0 then
    DataChanged;
end;

procedure TS4YPieChart.BindingEndUpdate;
begin
  Dec(FBindingUpdateDepth);

  if FBindingUpdateDepth > 0 then
    Exit;

  // The event sets the look of every slice again, from the palette, after every update.
  for var LIndex := 0 to FBoundSlices.Count - 1 do
  begin
    FBoundSlices[LIndex].Color := TS4YPieSlice.C_DEFAULT_COLOR;
    DoSliceBound(FBoundSlices[LIndex]);
  end;

  DataChanged;
end;

function TS4YPieChart.BindingGetCaption(const ARow: Integer): string;
begin
  Result := FBoundSlices[ARow].Caption;
end;

function TS4YPieChart.BindingGetRowCount: Integer;
begin
  Result := FBoundSlices.Count;
end;

function TS4YPieChart.BindingGetValue(const ARow, AColumn: Integer): Single;
begin
  if AColumn = C_VALUE_COLUMN then
    Result := FBoundSlices[ARow].Value
  else
    Result := 0;
end;

procedure TS4YPieChart.BindingSetCaption(const ARow: Integer; const ACaption: string);
begin
  FBoundSlices[ARow].Caption := ACaption;
  BoundSliceChanged(ARow);
end;

procedure TS4YPieChart.BindingSetValue(const ARow, AColumn: Integer; const AValue: Single);
begin
  if AColumn <> C_VALUE_COLUMN then
    Exit;

  FBoundSlices[ARow].Value := AValue;
  BoundSliceChanged(ARow);
end;

procedure TS4YPieChart.BindingUpdateLinkColumn(const ALinkColumn: Integer; const ACaption: string);
begin
  // The headers of the columns are not shown by a pie.
end;

procedure TS4YPieChart.BoundSliceChanged(const ARow: Integer);
begin
  // A single record changed outside an update of the list, for example after a post.
  if FBindingUpdateDepth > 0 then
    Exit;

  FBoundSlices[ARow].Color := TS4YPieSlice.C_DEFAULT_COLOR;
  DoSliceBound(FBoundSlices[ARow]);
  DataChanged;
end;

procedure TS4YPieChart.DoSliceBound(const ASlice: TS4YPieSlice);
begin
  if Assigned(FOnSliceBound) then
    FOnSliceBound(Self, ASlice);
end;

procedure TS4YPieChart.DrawCenter(const ATotal: Single);
var
  LCaptionHeight: Single;
  LTop: Single;
  LTotalHeight: Single;
  LTotalText: string;
begin
  if FDrawnInnerRadius <= 0 then
    Exit;

  LTotalText := '';

  if FShowTotal then
    LTotalText := GetValueText(0, -1, ATotal);

  LTotalHeight := MeasureText(FStyleCenterText, C_DEFAULT_CENTER_TEXT_COLOR, LTotalText).Height;
  LCaptionHeight := MeasureText(FStyleCenterCaptionText, C_DEFAULT_CENTER_CAPTION_TEXT_COLOR, FCenterCaption).Height;
  LTop := FCenter.Y - (LTotalHeight + LCaptionHeight) / 2;
  RenderText(FStyleCenterText, C_DEFAULT_CENTER_TEXT_COLOR, LTotalText, TRectF.Create(FCenter.X - FDrawnInnerRadius,
    LTop, FCenter.X + FDrawnInnerRadius, LTop + LTotalHeight), TTextAlign.Center, TTextAlign.Leading);
  LTop := LTop + LTotalHeight;
  RenderText(FStyleCenterCaptionText, C_DEFAULT_CENTER_CAPTION_TEXT_COLOR, FCenterCaption,
    TRectF.Create(FCenter.X - FDrawnInnerRadius, LTop, FCenter.X + FDrawnInnerRadius, LTop + LCaptionHeight),
    TTextAlign.Center, TTextAlign.Leading);
end;

procedure TS4YPieChart.DrawChart(const APlotRect: TRectF);
var
  LAngle: Single;
  LMarginX: Single;
  LMarginY: Single;
  LSize: TSizeF;
  LSweep: Single;
  LTotal: Single;
begin
  LTotal := GetDisplayedTotal;
  LMarginX := 0;
  LMarginY := 0;

  // Labels outside the slices need room around the chart.
  if (FLabelPosition = plpOutside) and (FLabelContent <> plcNone) then
  begin
    for var LIndex := 0 to GetDrawnSliceCount - 1 do
    begin
      LSize := MeasureText(FStyleOuterLabelText, C_DEFAULT_OUTER_LABEL_TEXT_COLOR, GetLabelText(LIndex, LTotal));
      LMarginX := Max(LMarginX, LSize.Width + C_OUTER_LINE_LENGTH + C_OUTER_LINE_END + C_OUTER_TEXT_SPACING);
      LMarginY := Max(LMarginY, LSize.Height / 2 + C_OUTER_LINE_LENGTH);
    end;
  end;

  FCenter := APlotRect.CenterPoint;
  FDrawnOuterRadius := Min(APlotRect.Width / 2 - LMarginX, APlotRect.Height / 2 - LMarginY);

  if FDrawnOuterRadius < C_MIN_RADIUS then
  begin
    FDrawnOuterRadius := 0;
    FDrawnInnerRadius := 0;
    Exit;
  end;

  FDrawnInnerRadius := FDrawnOuterRadius * FInnerRadius / C_PERCENT;

  if LTotal > 0 then
  begin
    LAngle := FStartAngle;

    for var LIndex := 0 to GetDrawnSliceCount - 1 do
    begin
      LSweep := GetDisplayedValue(LIndex) / LTotal * C_FULL_CIRCLE;

      if LSweep > 0 then
        DrawSlice(LIndex, LAngle, LSweep);

      LAngle := LAngle + LSweep;
    end;

    DrawLabels(LTotal);
  end;

  DrawCenter(LTotal);
end;

procedure TS4YPieChart.DrawLabels(const ATotal: Single);
var
  LAngle: Single;
  LSweep: Single;
  LText: string;
begin
  if FLabelContent = plcNone then
    Exit;

  LAngle := FStartAngle;

  for var LIndex := 0 to GetDrawnSliceCount - 1 do
  begin
    LSweep := GetDisplayedValue(LIndex) / ATotal * C_FULL_CIRCLE;
    LText := GetLabelText(LIndex, ATotal);

    if (LSweep > 0) and (LText <> '') then
      DrawSliceLabel(LIndex, LAngle + LSweep / 2, LSweep, LText);

    LAngle := LAngle + LSweep;
  end;
end;

procedure TS4YPieChart.DrawSliceLabel(const AIndex: Integer; const AMiddleAngle, ASweepAngle: Single;
  const AText: string);
var
  LAnchor: TPointF;
  LEdge: TPointF;
  LEnd: TPointF;
  LLabelRadius: Single;
  LOnRight: Boolean;
  LRadians: Single;
  LRoom: Single;
  LSize: TSizeF;
begin
  LRadians := DegToRad(AMiddleAngle + C_FMX_TOP_ANGLE);

  if FLabelPosition = plpInside then
  begin
    if FDrawnInnerRadius > 0 then
      LLabelRadius := (FDrawnInnerRadius + FDrawnOuterRadius) / 2
    else
      LLabelRadius := FDrawnOuterRadius * C_PIE_LABEL_RADIUS;

    // The label is written only when it fits the slice, along it and across it.
    LSize := MeasureText(FStyleLabelText, C_DEFAULT_LABEL_TEXT_COLOR, AText);
    LRoom := Min(LLabelRadius * DegToRad(ASweepAngle), FDrawnOuterRadius - FDrawnInnerRadius) * C_LABEL_FIT;

    if (ASweepAngle < C_HALF_CIRCLE) and (Max(LSize.Width, LSize.Height) > LRoom) then
      Exit;

    LAnchor := TPointF.Create(FCenter.X + LLabelRadius * Cos(LRadians), FCenter.Y + LLabelRadius * Sin(LRadians));
    RenderText(FStyleLabelText, C_DEFAULT_LABEL_TEXT_COLOR, AText, TRectF.Create(LAnchor.X - LSize.Width,
      LAnchor.Y - LSize.Height, LAnchor.X + LSize.Width, LAnchor.Y + LSize.Height), TTextAlign.Center,
      TTextAlign.Center);
    Exit;
  end;

  // A line from the edge of the slice outwards, then a short horizontal end, then the text.
  LEdge := TPointF.Create(FCenter.X + FDrawnOuterRadius * Cos(LRadians), FCenter.Y + FDrawnOuterRadius * Sin(LRadians));
  LAnchor := TPointF.Create(FCenter.X + (FDrawnOuterRadius + C_OUTER_LINE_LENGTH) * Cos(LRadians),
    FCenter.Y + (FDrawnOuterRadius + C_OUTER_LINE_LENGTH) * Sin(LRadians));
  LOnRight := LAnchor.X >= FCenter.X;

  if LOnRight then
    LEnd := TPointF.Create(LAnchor.X + C_OUTER_LINE_END, LAnchor.Y)
  else
    LEnd := TPointF.Create(LAnchor.X - C_OUTER_LINE_END, LAnchor.Y);

  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := GetSliceColor(AIndex);
  Canvas.Stroke.Thickness := C_OUTER_LINE_THICKNESS;
  Canvas.Stroke.Dash := TStrokeDash.Solid;
  Canvas.DrawLine(LEdge, LAnchor, AbsoluteOpacity);
  Canvas.DrawLine(LAnchor, LEnd, AbsoluteOpacity);
  LSize := MeasureText(FStyleOuterLabelText, C_DEFAULT_OUTER_LABEL_TEXT_COLOR, AText);

  if LOnRight then
    RenderText(FStyleOuterLabelText, C_DEFAULT_OUTER_LABEL_TEXT_COLOR, AText,
      TRectF.Create(LEnd.X + C_OUTER_TEXT_SPACING, LEnd.Y - LSize.Height,
      LEnd.X + C_OUTER_TEXT_SPACING + LSize.Width + 1, LEnd.Y + LSize.Height), TTextAlign.Leading, TTextAlign.Center)
  else
    RenderText(FStyleOuterLabelText, C_DEFAULT_OUTER_LABEL_TEXT_COLOR, AText,
      TRectF.Create(LEnd.X - C_OUTER_TEXT_SPACING - LSize.Width - 1, LEnd.Y - LSize.Height,
      LEnd.X - C_OUTER_TEXT_SPACING, LEnd.Y + LSize.Height), TTextAlign.Trailing, TTextAlign.Center);
end;

procedure TS4YPieChart.DrawSlice(const AIndex: Integer; const AStartAngle, ASweepAngle: Single);
var
  LPath: TPathData;
  LStart: Single;
begin
  LStart := AStartAngle + C_FMX_TOP_ANGLE;
  LPath := TPathData.Create;
  try
    // A pie slice starts from the center; a ring slice goes back along the hole.
    if FDrawnInnerRadius > 0 then
    begin
      LPath.AddArc(FCenter, TPointF.Create(FDrawnOuterRadius, FDrawnOuterRadius), LStart, ASweepAngle);
      LPath.AddArc(FCenter, TPointF.Create(FDrawnInnerRadius, FDrawnInnerRadius), LStart + ASweepAngle,
        -ASweepAngle);
    end
    else
    begin
      LPath.MoveTo(FCenter);
      LPath.AddArc(FCenter, TPointF.Create(FDrawnOuterRadius, FDrawnOuterRadius), LStart, ASweepAngle);
    end;

    LPath.ClosePath;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := GetSliceColor(AIndex);
    Canvas.FillPath(LPath, AbsoluteOpacity);

    if FSliceStroke.Kind <> TBrushKind.None then
    begin
      Canvas.Stroke.Assign(FSliceStroke);
      Canvas.DrawPath(LPath, AbsoluteOpacity);
    end;
  finally
    LPath.Free;
  end;
end;

function TS4YPieChart.FindItemAt(const APoint: TPointF; out ASeriesIndex, AItemIndex: Integer): Boolean;
var
  LAngle: Single;
  LDistance: Single;
  LEnd: Single;
  LSweep: Single;
  LTotal: Single;
begin
  Result := False;
  ASeriesIndex := 0;
  AItemIndex := -1;
  LTotal := GetDisplayedTotal;
  LDistance := APoint.Distance(FCenter);

  if (LTotal <= 0) or (LDistance > FDrawnOuterRadius) or (LDistance < FDrawnInnerRadius) then
    Exit;

  // The angle of the point from StartAngle, clockwise, from 0 to 360.
  LAngle := RadToDeg(ArcTan2(APoint.Y - FCenter.Y, APoint.X - FCenter.X)) - C_FMX_TOP_ANGLE - FStartAngle;
  LAngle := LAngle - Floor(LAngle / C_FULL_CIRCLE) * C_FULL_CIRCLE;
  LEnd := 0;

  for var LIndex := 0 to GetDrawnSliceCount - 1 do
  begin
    LSweep := GetDisplayedValue(LIndex) / LTotal * C_FULL_CIRCLE;
    LEnd := LEnd + LSweep;

    if (LSweep > 0) and (LAngle < LEnd) then
    begin
      AItemIndex := LIndex;
      Exit(True);
    end;
  end;
end;

procedure TS4YPieChart.FreeStyle;
begin
  FStyleLabelText := nil;
  FStyleOuterLabelText := nil;
  FStyleCenterText := nil;
  FStyleCenterCaptionText := nil;

  inherited;
end;

function TS4YPieChart.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_WIDTH, C_DEFAULT_HEIGHT);
end;

function TS4YPieChart.GetDisplayedTotal: Single;
begin
  Result := 0;

  for var LIndex := 0 to GetDrawnSliceCount - 1 do
    Result := Result + Max(0, GetDisplayedValue(LIndex));
end;

function TS4YPieChart.GetDrawnSlice(Index: Integer): TS4YPieSlice;
begin
  if IsBound then
    Result := FBoundSlices[Index]
  else
    Result := FSlices[Index];
end;

function TS4YPieChart.GetDrawnSliceCount: Integer;
begin
  if IsBound then
    Result := FBoundSlices.Count
  else
    Result := FSlices.Count;
end;

function TS4YPieChart.GetLabelText(const AIndex: Integer; const ATotal: Single): string;
begin
  case FLabelContent of
    plcValue:
      Result := GetValueText(0, AIndex, GetDisplayedValue(AIndex));
    plcPercent:
      if ATotal > 0 then
        Result := Format(C_PERCENT_FORMAT, [GetDisplayedValue(AIndex) / ATotal * C_PERCENT])
      else
        Result := '';
    plcCaption:
      Result := GetDrawnSlice(AIndex).Caption;
  else
    Result := '';
  end;
end;

function TS4YPieChart.GetLegendEntryCaption(const AIndex: Integer): string;
begin
  Result := GetDrawnSlice(AIndex).Caption;
end;

function TS4YPieChart.GetLegendEntryColor(const AIndex: Integer): TAlphaColor;
begin
  Result := GetSliceColor(AIndex);
end;

function TS4YPieChart.GetLegendEntryCount: Integer;
begin
  Result := GetDrawnSliceCount;
end;

function TS4YPieChart.GetSliceColor(const AIndex: Integer): TAlphaColor;
begin
  Result := ResolveColor(GetDrawnSlice(AIndex).Color, AIndex);
end;

function TS4YPieChart.GetTargetValues: TArray<Single>;
begin
  SetLength(Result, GetDrawnSliceCount);

  for var LIndex := 0 to Length(Result) - 1 do
    Result[LIndex] := Max(0, GetDrawnSlice(LIndex).Value);
end;

function TS4YPieChart.InnerRadiusStored: Boolean;
begin
  Result := not SameValue(FInnerRadius, C_DEFAULT_INNER_RADIUS);
end;

function TS4YPieChart.IsBound: Boolean;
begin
  // While the link has columns, the chart draws the records of the link.
  Result := FBindingColumnCount > 0;
end;

procedure TS4YPieChart.SetCenterCaption(const Value: string);
begin
  if FCenterCaption = Value then
    Exit;

  FCenterCaption := Value;
  Repaint;
end;

procedure TS4YPieChart.SetInnerRadius(const Value: Single);
begin
  if SameValue(FInnerRadius, Value) then
    Exit;

  FInnerRadius := EnsureRange(Value, 0, C_MAX_INNER_RADIUS);
  Repaint;
end;

procedure TS4YPieChart.SetLabelContent(const Value: TS4YPieLabelContent);
begin
  if FLabelContent = Value then
    Exit;

  FLabelContent := Value;
  Repaint;
end;

procedure TS4YPieChart.SetLabelPosition(const Value: TS4YPieLabelPosition);
begin
  if FLabelPosition = Value then
    Exit;

  FLabelPosition := Value;
  Repaint;
end;

procedure TS4YPieChart.SetShowTotal(const Value: Boolean);
begin
  if FShowTotal = Value then
    Exit;

  FShowTotal := Value;
  Repaint;
end;

procedure TS4YPieChart.SetSlices(const Value: TS4YPieSlices);
begin
  FSlices.Assign(Value);
end;

procedure TS4YPieChart.SetStartAngle(const Value: Single);
begin
  if SameValue(FStartAngle, Value) then
    Exit;

  FStartAngle := Value;
  Repaint;
end;

procedure TS4YPieChart.SlicesChanged;
begin
  // The slices of the form are drawn only while no link fills the chart.
  if not IsBound then
    DataChanged
  else
    Repaint;
end;

function TS4YPieChart.StartAngleStored: Boolean;
begin
  Result := not SameValue(FStartAngle, C_DEFAULT_START_ANGLE);
end;

initialization
  RegisterChartBindingClass(TS4YPieChart);

end.
