unit Soft4You.FMX.Controls.Charts;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YCustomChart - base class of the charts
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
  FMX.Ani,
  FMX.TextLayout,
  Soft4You.FMX.Controls.Charts.Types;

type
  /// <summary>
  /// What a chart offers to the LiveBindings: rows of data, each with a caption, and columns of values.
  /// </summary>
  /// <remarks>
  /// Used by the grid editor of Soft4You.FMX.Controls.Charts.Bindings, which fills a chart from a TLinkGridToDataSource: the first column of the link gives the captions of the rows, each other column a column of values.
  /// The applications do not call it.
  /// </remarks>
  IS4YChartBinding = interface
    ['{7C2D1E2A-5B9F-4E3C-9A61-3F0B8D4C2E71}']
    procedure BindingBeginUpdate;
    procedure BindingEndUpdate;
    function BindingAddRow: Integer;
    procedure BindingClearRows;
    procedure BindingDeleteRowsFrom(const AIndex: Integer);
    function BindingGetRowCount: Integer;
    function BindingGetCaption(const ARow: Integer): string;
    procedure BindingSetCaption(const ARow: Integer; const ACaption: string);
    function BindingGetValue(const ARow, AColumn: Integer): Single;
    procedure BindingSetValue(const ARow, AColumn: Integer; const AValue: Single);
    function BindingAddLinkColumn(const ACaption: string): Integer;
    procedure BindingClearLinkColumns;
    procedure BindingUpdateLinkColumn(const ALinkColumn: Integer; const ACaption: string);
  end;

  /// <summary>
  /// A color of the palette of a chart.
  /// </summary>
  TS4YChartPaletteItem = class(TCollectionItem)
  private
    FColor: TAlphaColor;
    procedure SetColor(const Value: TAlphaColor);
  public
    /// <summary>Copies the color from another TS4YChartPaletteItem.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>The color.</summary>
    property Color: TAlphaColor read FColor write SetColor;
  end;

  /// <summary>
  /// The colors given in turn to the slices or the series of a chart that have no color of their own.
  /// </summary>
  TS4YChartPalette = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TS4YChartPaletteItem;
    procedure SetItem(Index: Integer; const Value: TS4YChartPaletteItem);
  protected
    /// <summary>Repaints the chart when a color changes.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the palette of AOwner, empty.</summary>
    constructor Create(AOwner: TPersistent);

    /// <summary>Adds a color at the end of the palette and returns it.</summary>
    function Add: TS4YChartPaletteItem;
    /// <summary>Adds AColor at the end of the palette.</summary>
    procedure AddColor(const AColor: TAlphaColor);

    /// <summary>The colors, in the order they are given.</summary>
    property Items[Index: Integer]: TS4YChartPaletteItem read GetItem write SetItem; default;
  end;

  /// <summary>
  /// Where a chart shows its legend.
  /// </summary>
  TS4YChartLegend = class(TPersistent)
  public const
    /// <summary>Default value of Position.</summary>
    C_DEFAULT_POSITION = clpRight;
  private
    FPosition: TS4YChartLegendPosition;
    FOnChange: TNotifyEvent;
    procedure SetPosition(const Value: TS4YChartLegendPosition);
  public
    /// <summary>Creates the settings with the legend on the right.</summary>
    constructor Create;

    /// <summary>Copies the settings from another TS4YChartLegend.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Side of the chart where the legend is shown, or clpNone to hide it. The default is clpRight.</summary>
    property Position: TS4YChartLegendPosition read FPosition write SetPosition default C_DEFAULT_POSITION;
  end;

  /// <summary>
  /// Base class of the charts: palette, legend, values written, animation of the data, click on an element and the current element of the LiveBindings.
  /// </summary>
  /// <remarks>
  /// The look comes from a style: its parts color1 to color8 give the palette, when the Palette property is empty, and its text legendtext gives font and color to the legend. The descendants add the parts and the texts of their own.
  /// A chart is filled from a dataset or a list of objects through a TLinkGridToDataSource: see Soft4You.FMX.Controls.Charts.Bindings. While the link has columns the chart draws its data, kept apart from the data stored in the form.
  /// The class is not registered in the Tool Palette.
  /// </remarks>
  TS4YCustomChart = class(TStyledControl, IS4YChartBinding)
  public const
    /// <summary>Default value of AnimationDuration, in seconds.</summary>
    C_DEFAULT_ANIMATION_DURATION: Single = 0.3;
    /// <summary>Default value of ValueFormat: the value without decimals.</summary>
    C_DEFAULT_VALUE_FORMAT = '%.0f';
    /// <summary>Color of the legend when the style has no legendtext.</summary>
    C_DEFAULT_LEGEND_TEXT_COLOR: TAlphaColor = $FF424242;
    /// <summary>Number of the colors of the palette of the style: the parts color1 to color8.</summary>
    C_STYLE_PALETTE_SIZE = 8;
  private
    FAnimation: TAnimation;
    FAnimationDuration: Single;
    FDefaultFont: TFont;
    FDisplayedValues: TArray<Single>;
    FEntryAnimated: Boolean;
    FItemIndex: Integer;
    FLegend: TS4YChartLegend;
    FPalette: TS4YChartPalette;
    FPlotRect: TRectF;
    FStartValues: TArray<Single>;
    FStyleLegendText: TText;
    FStylePalette: TArray<TAlphaColor>;
    FTargetValues: TArray<Single>;
    FTextLayout: TTextLayout;
    FValueFormat: string;
    FOnGetValueText: TS4YChartGetValueTextEvent;
    FOnItemClick: TS4YChartItemClickEvent;
    function AnimationDurationStored: Boolean;
    function ArrangeLegend(const AContentRect: TRectF; out AEntries: TArray<TRectF>): TRectF;
    function CanAnimate: Boolean;
    procedure DrawLegend(const AEntries: TArray<TRectF>);
    function FormatValue(const AValue: Single): string;
    procedure LegendChanged(Sender: TObject);
    procedure PrepareTextLayout(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string;
      const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign);
    procedure SetAnimationDuration(const Value: Single);
    procedure SetAnimationProgress(const AProgress: Single);
    procedure SetItemIndex(const Value: Integer);
    procedure SetLegend(const Value: TS4YChartLegend);
    procedure SetPalette(const Value: TS4YChartPalette);
    procedure SetValueFormat(const Value: string);
    procedure StartAnimation(const AStartValues: TArray<Single>);
    function ValueFormatStored: Boolean;
  protected
    /// <summary>Adds the sample data of a chart just placed in the form designer.</summary>
    procedure AddSampleData; virtual; abstract;
    /// <summary>Reads the palette and the texts of the style.</summary>
    procedure ApplyStyle; override;
    { IS4YChartBinding }
    function BindingAddLinkColumn(const ACaption: string): Integer; virtual; abstract;
    function BindingAddRow: Integer; virtual; abstract;
    procedure BindingBeginUpdate; virtual; abstract;
    procedure BindingClearLinkColumns; virtual; abstract;
    procedure BindingClearRows; virtual; abstract;
    procedure BindingDeleteRowsFrom(const AIndex: Integer); virtual; abstract;
    procedure BindingEndUpdate; virtual; abstract;
    function BindingGetCaption(const ARow: Integer): string; virtual; abstract;
    function BindingGetRowCount: Integer; virtual; abstract;
    function BindingGetValue(const ARow, AColumn: Integer): Single; virtual; abstract;
    procedure BindingSetCaption(const ARow: Integer; const ACaption: string); virtual; abstract;
    procedure BindingSetValue(const ARow, AColumn: Integer; const AValue: Single); virtual; abstract;
    procedure BindingUpdateLinkColumn(const ALinkColumn: Integer; const ACaption: string); virtual; abstract;
    /// <summary>Allows the LiveBindings to keep the current element in step with the current record.</summary>
    function CanObserve(const ID: Integer): Boolean; override;
    /// <summary>To be called by the descendants when their data change: the values drawn move to the new ones, with the animation once the chart has been shown.</summary>
    procedure DataChanged;
    /// <summary>Fires OnGetValueText.</summary>
    procedure DoGetValueText(const ASeriesIndex, AItemIndex: Integer; const AValue: Single; var AText: string); virtual;
    /// <summary>Fires OnItemClick.</summary>
    procedure DoItemClick(const ASeriesIndex, AItemIndex: Integer); virtual;
    /// <summary>Draws the chart in APlotRect, the area left by the legend.</summary>
    procedure DrawChart(const APlotRect: TRectF); virtual; abstract;
    /// <summary>Returns the series and the element at APoint, in the coordinates of the control; False when there is none.</summary>
    function FindItemAt(const APoint: TPointF; out ASeriesIndex, AItemIndex: Integer): Boolean; virtual; abstract;
    /// <summary>Releases the texts and the palette of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the area of the control inside Padding.</summary>
    function GetContentRect: TRectF;
    /// <summary>Returns the value drawn at AIndex, in the order of GetTargetValues: it follows the animation.</summary>
    function GetDisplayedValue(const AIndex: Integer): Single;
    /// <summary>Returns the number of the entries of the legend.</summary>
    function GetLegendEntryCount: Integer; virtual; abstract;
    /// <summary>Returns the text of the entry of the legend at AIndex.</summary>
    function GetLegendEntryCaption(const AIndex: Integer): string; virtual; abstract;
    /// <summary>Returns the color of the entry of the legend at AIndex.</summary>
    function GetLegendEntryColor(const AIndex: Integer): TAlphaColor; virtual; abstract;
    /// <summary>Returns the color of the palette for the element at AIndex: from Palette, else from the style, else a default color, in turn.</summary>
    function GetPaletteColor(const AIndex: Integer): TAlphaColor;
    /// <summary>Returns the style of the control: the one named by StyleLookup or, when it is empty or not found, the one named after the class in the style book or in the active style; else the default style linked into the package.</summary>
    function GetStyleObject: TFmxObject; override;
    /// <summary>Returns the values to draw, in an order of the descendant; the animation moves the values drawn towards them.</summary>
    function GetTargetValues: TArray<Single>; virtual; abstract;
    /// <summary>Returns the text of a value: ValueFormat applied to it, then OnGetValueText.</summary>
    function GetValueText(const ASeriesIndex, AItemIndex: Integer; const AValue: Single): string;
    /// <summary>Takes the data loaded from the form as the values drawn.</summary>
    procedure Loaded; override;
    /// <summary>Returns the width and the height of AText written with the font of ATemplate, or with the default font and ADefaultColor when ATemplate is nil.</summary>
    function MeasureText(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string): TSizeF;
    /// <summary>Makes the clicked element the current one and fires OnItemClick.</summary>
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    /// <summary>Draws the legend and the chart; the first time at run time, starts the animation of the data from 0.</summary>
    procedure Paint; override;
    /// <summary>Repaints the chart after a change of the palette.</summary>
    procedure PaletteChanged; virtual;
    /// <summary>Returns the color AColor or, when it is claNull, the color of the palette for the element at AIndex.</summary>
    function ResolveColor(const AColor: TAlphaColor; const AIndex: Integer): TAlphaColor;
    /// <summary>Writes AText in ARect on one line, with the font of ATemplate, or with the default font and ADefaultColor when ATemplate is nil.</summary>
    procedure RenderText(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string;
      const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign);

    /// <summary>The area of the last paint left by the legend to the chart.</summary>
    property PlotRect: TRectF read FPlotRect;
  public
    /// <summary>Creates the chart with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>Adds sample data to a chart placed in the form designer, so that it is not empty: they are stored with the form as the data added by the user, who can change them or delete them. A chart read from the form file or created in code has no sample data.</summary>
    procedure AfterConstruction; override;

    /// <summary>
    /// Duration in seconds of the movement of the data when the chart is shown for the first time and when its data change. With 0 the changes are immediate. The default is 0.3.
    /// </summary>
    /// <remarks>
    /// A change while the data are moving starts from where they are. In the designer the changes are always immediate.
    /// </remarks>
    property AnimationDuration: Single read FAnimationDuration write SetAnimationDuration stored AnimationDurationStored nodefault;
    /// <summary>
    /// Index of the current element: the slice of a pie chart, the category of a bar or line chart. -1 when there is none.
    /// </summary>
    /// <remarks>
    /// A click on an element makes it the current one. When the chart is filled by the LiveBindings, the current element follows the current record, and a click moves the current record.
    /// </remarks>
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    /// <summary>Where the legend is shown.</summary>
    property Legend: TS4YChartLegend read FLegend write SetLegend;
    /// <summary>
    /// The colors given in turn to the elements that have no color of their own: the slices of a pie chart, the series of a bar or line chart. Empty by default: the colors come from the style.
    /// </summary>
    /// <remarks>
    /// The elements filled by the LiveBindings take their colors from here too, by position: OnSliceBound and OnSeriesBound can change them.
    /// </remarks>
    property Palette: TS4YChartPalette read FPalette write SetPalette;
    /// <summary>
    /// Format of the values written, as for the Format function of Delphi with the value as its only argument. The default is %.0f, the value without decimals.
    /// </summary>
    /// <remarks>
    /// A format that does not fit a floating point value is replaced by the default.
    /// </remarks>
    property ValueFormat: string read FValueFormat write SetValueFormat stored ValueFormatStored;

    /// <summary>Fires when a value is written, with the text formatted with ValueFormat, which the event can replace.</summary>
    property OnGetValueText: TS4YChartGetValueTextEvent read FOnGetValueText write FOnGetValueText;
    /// <summary>Fires when the user clicks an element of the chart, after it has become the current one.</summary>
    property OnItemClick: TS4YChartItemClickEvent read FOnItemClick write FOnItemClick;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  FMX.Styles;

type
  /// <summary>Animation that moves the values drawn by a chart towards its data.</summary>
  TS4YChartAnimation = class(TAnimation)
  private
    [Weak] FChart: TS4YCustomChart;
  protected
    procedure ProcessAnimation; override;
  public
    constructor Create(const AChart: TS4YCustomChart); reintroduce;
  end;

const
  C_STYLE_LEGEND_TEXT = 'legendtext';
  C_STYLE_PALETTE_PREFIX = 'color';

  // Colors used when neither Palette nor the style give any.
  C_DEFAULT_PALETTE: array[0..7] of TAlphaColor = ($FF1E88E5, $FFFB8C00, $FF43A047, $FF8E24AA, $FFE53935, $FF00897B,
    $FFFDD835, $FF6D4C41);

  // Width and height given to a text while it is measured: large enough for any caption.
  C_MEASURE_SIZE = 10000;
  // Size of the colored square of an entry of the legend, and space between it and its text, in pixels.
  C_LEGEND_MARKER_SIZE = 10;
  C_LEGEND_MARKER_SPACING = 6;
  C_LEGEND_MARKER_RADIUS = 2;
  // Space between the entries of the legend in a row, between its rows, and between the legend and the chart.
  C_LEGEND_ENTRY_SPACING = 16;
  C_LEGEND_ROW_SPACING = 4;
  C_LEGEND_SPACING = 12;
  C_NO_ITEM = -1;

{ TS4YChartAnimation }

constructor TS4YChartAnimation.Create(const AChart: TS4YCustomChart);
begin
  inherited Create(AChart);

  FChart := AChart;
end;

procedure TS4YChartAnimation.ProcessAnimation;
begin
  if Assigned(FChart) then
    FChart.SetAnimationProgress(NormalizedTime);
end;

{ TS4YChartPaletteItem }

procedure TS4YChartPaletteItem.Assign(Source: TPersistent);
begin
  if Source is TS4YChartPaletteItem then
    SetColor(TS4YChartPaletteItem(Source).Color)
  else
    inherited;
end;

procedure TS4YChartPaletteItem.SetColor(const Value: TAlphaColor);
begin
  if FColor = Value then
    Exit;

  FColor := Value;
  Changed(False);
end;

{ TS4YChartPalette }

constructor TS4YChartPalette.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YChartPaletteItem);
end;

function TS4YChartPalette.Add: TS4YChartPaletteItem;
begin
  Result := TS4YChartPaletteItem(inherited Add);
end;

procedure TS4YChartPalette.AddColor(const AColor: TAlphaColor);
begin
  Add.Color := AColor;
end;

function TS4YChartPalette.GetItem(Index: Integer): TS4YChartPaletteItem;
begin
  Result := TS4YChartPaletteItem(inherited GetItem(Index));
end;

procedure TS4YChartPalette.SetItem(Index: Integer; const Value: TS4YChartPaletteItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TS4YChartPalette.Update(Item: TCollectionItem);
begin
  inherited;

  if Owner is TS4YCustomChart then
    TS4YCustomChart(Owner).PaletteChanged;
end;

{ TS4YChartLegend }

constructor TS4YChartLegend.Create;
begin
  inherited Create;

  FPosition := C_DEFAULT_POSITION;
end;

procedure TS4YChartLegend.Assign(Source: TPersistent);
begin
  if Source is TS4YChartLegend then
    SetPosition(TS4YChartLegend(Source).Position)
  else
    inherited;
end;

procedure TS4YChartLegend.SetPosition(const Value: TS4YChartLegendPosition);
begin
  if FPosition = Value then
    Exit;

  FPosition := Value;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TS4YCustomChart }

constructor TS4YCustomChart.Create(AOwner: TComponent);
begin
  inherited;

  FAnimationDuration := C_DEFAULT_ANIMATION_DURATION;
  FValueFormat := C_DEFAULT_VALUE_FORMAT;
  FItemIndex := C_NO_ITEM;
  FPalette := TS4YChartPalette.Create(Self);
  FLegend := TS4YChartLegend.Create;
  FLegend.OnChange := LegendChanged;
  FDefaultFont := TFont.Create;
  FTextLayout := TTextLayoutManager.DefaultTextLayout.Create;
end;

destructor TS4YCustomChart.Destroy;
begin
  // Freed first, so that a running animation cannot touch the data released below.
  FreeAndNil(FAnimation);
  FreeAndNil(FTextLayout);
  FreeAndNil(FDefaultFont);
  FreeAndNil(FLegend);
  FreeAndNil(FPalette);

  inherited;
end;

procedure TS4YCustomChart.AfterConstruction;
begin
  inherited;

  // Placed in the form designer: the owner of a chart read from the form file is loading, and the owner
  // of a chart created in code is not being designed.
  if (csDesigning in ComponentState) and Assigned(Owner) and not (csLoading in Owner.ComponentState) then
    AddSampleData;
end;

function TS4YCustomChart.AnimationDurationStored: Boolean;
begin
  Result := not SameValue(FAnimationDuration, C_DEFAULT_ANIMATION_DURATION);
end;

procedure TS4YCustomChart.ApplyStyle;
var
  LPart: TShape;
begin
  inherited;

  FindStyleResource<TText>(C_STYLE_LEGEND_TEXT, FStyleLegendText);
  FStylePalette := nil;

  // The palette of the style ends at the first color part that is missing.
  for var LIndex := 1 to C_STYLE_PALETTE_SIZE do
  begin
    if not FindStyleResource<TShape>(C_STYLE_PALETTE_PREFIX + IntToStr(LIndex), LPart) then
      Exit;

    FStylePalette := FStylePalette + [LPart.Fill.Color];
  end;
end;

function TS4YCustomChart.ArrangeLegend(const AContentRect: TRectF; out AEntries: TArray<TRectF>): TRectF;
var
  LCount: Integer;
  LEntryHeight: Single;
  LEntryWidths: TArray<Single>;
  LLegendSize: Single;
  LPosition: TPointF;
  LRowStart: Integer;
  LRowWidth: Single;
  LTextSize: TSizeF;
  LTotalHeight: Single;
  LTop: Single;

  procedure PlaceRow(const AFirst, ALast: Integer; const ATop: Single);
  var
    LLeft: Single;
  begin
    // Each row of entries is centered across the content.
    LLeft := AContentRect.Left + (AContentRect.Width - LRowWidth) / 2;

    for var LIndex := AFirst to ALast do
    begin
      AEntries[LIndex] := TRectF.Create(LLeft, ATop, LLeft + LEntryWidths[LIndex], ATop + LEntryHeight);
      LLeft := LLeft + LEntryWidths[LIndex] + C_LEGEND_ENTRY_SPACING;
    end;
  end;

begin
  Result := AContentRect;
  AEntries := nil;
  LCount := GetLegendEntryCount;

  if (FLegend.Position = clpNone) or (LCount = 0) then
    Exit;

  SetLength(AEntries, LCount);
  SetLength(LEntryWidths, LCount);
  LEntryHeight := C_LEGEND_MARKER_SIZE;

  for var LIndex := 0 to LCount - 1 do
  begin
    LTextSize := MeasureText(FStyleLegendText, C_DEFAULT_LEGEND_TEXT_COLOR, GetLegendEntryCaption(LIndex));
    LEntryWidths[LIndex] := C_LEGEND_MARKER_SIZE + C_LEGEND_MARKER_SPACING + LTextSize.Width;
    LEntryHeight := Max(LEntryHeight, LTextSize.Height);
  end;

  if FLegend.Position in [clpLeft, clpRight] then
  begin
    // A column of entries, in the middle of the height.
    LLegendSize := MaxValue(LEntryWidths);
    LTotalHeight := LCount * LEntryHeight + (LCount - 1) * C_LEGEND_ROW_SPACING;
    LTop := Max(AContentRect.Top, AContentRect.Top + (AContentRect.Height - LTotalHeight) / 2);

    if FLegend.Position = clpRight then
      LPosition := TPointF.Create(AContentRect.Right - LLegendSize, LTop)
    else
      LPosition := TPointF.Create(AContentRect.Left, LTop);

    for var LIndex := 0 to LCount - 1 do
    begin
      AEntries[LIndex] := TRectF.Create(LPosition.X, LPosition.Y, LPosition.X + LEntryWidths[LIndex],
        LPosition.Y + LEntryHeight);
      LPosition.Y := LPosition.Y + LEntryHeight + C_LEGEND_ROW_SPACING;
    end;

    if FLegend.Position = clpRight then
      Result.Right := Result.Right - LLegendSize - C_LEGEND_SPACING
    else
      Result.Left := Result.Left + LLegendSize + C_LEGEND_SPACING;

    Exit;
  end;

  // Rows of entries, as many as needed to fit the width; first counted, then placed.
  LTotalHeight := LEntryHeight;
  LRowWidth := 0;

  for var LIndex := 0 to LCount - 1 do
  begin
    if (LRowWidth > 0) and (LRowWidth + C_LEGEND_ENTRY_SPACING + LEntryWidths[LIndex] > AContentRect.Width) then
    begin
      LTotalHeight := LTotalHeight + C_LEGEND_ROW_SPACING + LEntryHeight;
      LRowWidth := LEntryWidths[LIndex];
    end
    else if LRowWidth > 0 then
      LRowWidth := LRowWidth + C_LEGEND_ENTRY_SPACING + LEntryWidths[LIndex]
    else
      LRowWidth := LEntryWidths[LIndex];
  end;

  if FLegend.Position = clpTop then
    LTop := AContentRect.Top
  else
    LTop := AContentRect.Bottom - LTotalHeight;

  LRowStart := 0;
  LRowWidth := 0;

  for var LIndex := 0 to LCount - 1 do
  begin
    if (LRowWidth > 0) and (LRowWidth + C_LEGEND_ENTRY_SPACING + LEntryWidths[LIndex] > AContentRect.Width) then
    begin
      PlaceRow(LRowStart, LIndex - 1, LTop);
      LTop := LTop + LEntryHeight + C_LEGEND_ROW_SPACING;
      LRowStart := LIndex;
      LRowWidth := LEntryWidths[LIndex];
    end
    else if LRowWidth > 0 then
      LRowWidth := LRowWidth + C_LEGEND_ENTRY_SPACING + LEntryWidths[LIndex]
    else
      LRowWidth := LEntryWidths[LIndex];
  end;

  PlaceRow(LRowStart, LCount - 1, LTop);

  if FLegend.Position = clpTop then
    Result.Top := Result.Top + LTotalHeight + C_LEGEND_SPACING
  else
    Result.Bottom := Result.Bottom - LTotalHeight - C_LEGEND_SPACING;
end;

function TS4YCustomChart.CanAnimate: Boolean;
begin
  // Before the first paint the chart is not seen yet: its entry animation starts from 0 when it is.
  Result := FEntryAnimated and (FAnimationDuration > 0) and
    ([csDesigning, csLoading, csDestroying] * ComponentState = []);
end;

function TS4YCustomChart.CanObserve(const ID: Integer): Boolean;
begin
  // The position link of the LiveBindings keeps ItemIndex in step with the current record.
  Result := (ID = TObserverMapping.PositionLinkID) or inherited CanObserve(ID);
end;

procedure TS4YCustomChart.DataChanged;
var
  LStartValues: TArray<Single>;
begin
  if [csLoading, csDestroying] * ComponentState <> [] then
    Exit;

  FTargetValues := GetTargetValues;

  if not CanAnimate then
  begin
    if Assigned(FAnimation) then
      FAnimation.StopAtCurrent;

    FDisplayedValues := Copy(FTargetValues);
    Repaint;
    Exit;
  end;

  // A change while the data move starts from where they are; a new element starts from 0.
  SetLength(LStartValues, Length(FTargetValues));

  for var LIndex := 0 to Length(LStartValues) - 1 do
    LStartValues[LIndex] := GetDisplayedValue(LIndex);

  StartAnimation(LStartValues);
end;

procedure TS4YCustomChart.DoGetValueText(const ASeriesIndex, AItemIndex: Integer; const AValue: Single;
  var AText: string);
begin
  if Assigned(FOnGetValueText) then
    FOnGetValueText(Self, ASeriesIndex, AItemIndex, AValue, AText);
end;

procedure TS4YCustomChart.DoItemClick(const ASeriesIndex, AItemIndex: Integer);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, ASeriesIndex, AItemIndex);
end;

procedure TS4YCustomChart.DrawLegend(const AEntries: TArray<TRectF>);
var
  LEntry: TRectF;
  LMarker: TRectF;
begin
  for var LIndex := 0 to Length(AEntries) - 1 do
  begin
    LEntry := AEntries[LIndex];
    LMarker := TRectF.Create(LEntry.Left, LEntry.CenterPoint.Y - C_LEGEND_MARKER_SIZE / 2,
      LEntry.Left + C_LEGEND_MARKER_SIZE, LEntry.CenterPoint.Y + C_LEGEND_MARKER_SIZE / 2);
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := GetLegendEntryColor(LIndex);
    Canvas.FillRect(LMarker, C_LEGEND_MARKER_RADIUS, C_LEGEND_MARKER_RADIUS, AllCorners, AbsoluteOpacity);
    RenderText(FStyleLegendText, C_DEFAULT_LEGEND_TEXT_COLOR, GetLegendEntryCaption(LIndex),
      TRectF.Create(LMarker.Right + C_LEGEND_MARKER_SPACING, LEntry.Top, LEntry.Right + 1, LEntry.Bottom),
      TTextAlign.Leading, TTextAlign.Center);
  end;
end;

function TS4YCustomChart.FormatValue(const AValue: Single): string;
begin
  try
    Result := Format(FValueFormat, [AValue]);
  except
    on EConvertError do
      Result := Format(C_DEFAULT_VALUE_FORMAT, [AValue]);
  end;
end;

procedure TS4YCustomChart.FreeStyle;
begin
  FStyleLegendText := nil;
  FStylePalette := nil;

  inherited;
end;

function TS4YCustomChart.GetContentRect: TRectF;
begin
  Result := Padding.PaddingRect(LocalRect);
end;

function TS4YCustomChart.GetDisplayedValue(const AIndex: Integer): Single;
begin
  if (AIndex >= 0) and (AIndex < Length(FDisplayedValues)) then
    Result := FDisplayedValues[AIndex]
  else
    Result := 0;
end;

function TS4YCustomChart.GetPaletteColor(const AIndex: Integer): TAlphaColor;
var
  LIndex: Integer;
begin
  LIndex := Max(0, AIndex);

  if FPalette.Count > 0 then
    Result := FPalette[LIndex mod FPalette.Count].Color
  else if Length(FStylePalette) > 0 then
    Result := FStylePalette[LIndex mod Length(FStylePalette)]
  else
    Result := C_DEFAULT_PALETTE[LIndex mod Length(C_DEFAULT_PALETTE)];
end;

function TS4YCustomChart.GetStyleObject: TFmxObject;
begin
  // The style named by StyleLookup or, when it is empty, the one named after the class, in the
  // style book or in the active style; never the style of the parent class.
  Result := LookupStyleObject(Self, GetStyleContext, Scene, StyleLookup, GetDefaultStyleLookupName, '', True);

  // The style linked into the package is used when no other style is found.
  if not Assigned(Result) then
    Result := TStyleStreaming.LoadFromResource(HInstance, GetDefaultStyleLookupName, RT_RCDATA);
end;

function TS4YCustomChart.GetValueText(const ASeriesIndex, AItemIndex: Integer; const AValue: Single): string;
begin
  Result := FormatValue(AValue);
  DoGetValueText(ASeriesIndex, AItemIndex, AValue, Result);
end;

procedure TS4YCustomChart.LegendChanged(Sender: TObject);
begin
  Repaint;
end;

procedure TS4YCustomChart.Loaded;
begin
  inherited;

  DataChanged;
end;

function TS4YCustomChart.MeasureText(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string): TSizeF;
begin
  if AText = '' then
    Exit(TSizeF.Create(0, 0));

  PrepareTextLayout(ATemplate, ADefaultColor, AText, TRectF.Create(0, 0, C_MEASURE_SIZE, C_MEASURE_SIZE),
    TTextAlign.Leading, TTextAlign.Leading);
  Result := TSizeF.Create(FTextLayout.TextWidth, FTextLayout.TextHeight);
end;

procedure TS4YCustomChart.MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LSeriesIndex: Integer;
  LItemIndex: Integer;
begin
  inherited;

  if (Button <> TMouseButton.mbLeft) or not FindItemAt(TPointF.Create(X, Y), LSeriesIndex, LItemIndex) then
    Exit;

  SetItemIndex(LItemIndex);

  // The LiveBindings move the current record to the clicked element.
  if Observers.IsObserving(TObserverMapping.PositionLinkID) then
    TLinkObservers.PositionLinkPosChanged(Observers);

  DoItemClick(LSeriesIndex, LItemIndex);
end;

procedure TS4YCustomChart.Paint;
var
  LEntries: TArray<TRectF>;
  LStartValues: TArray<Single>;
begin
  inherited;

  // The first time the chart is seen at run time its data grow from 0.
  if not FEntryAnimated then
  begin
    FEntryAnimated := True;

    if CanAnimate then
    begin
      FTargetValues := GetTargetValues;
      SetLength(LStartValues, Length(FTargetValues));
      StartAnimation(LStartValues);
    end;
  end;

  FPlotRect := ArrangeLegend(GetContentRect, LEntries);
  DrawChart(FPlotRect);
  DrawLegend(LEntries);
end;

procedure TS4YCustomChart.PaletteChanged;
begin
  Repaint;
end;

procedure TS4YCustomChart.PrepareTextLayout(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string; const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign);
begin
  FTextLayout.BeginUpdate;
  try
    if Assigned(ATemplate) then
    begin
      FTextLayout.Font.Assign(ATemplate.TextSettings.Font);
      FTextLayout.Color := ATemplate.TextSettings.FontColor;
    end
    else
    begin
      FTextLayout.Font.Assign(FDefaultFont);
      FTextLayout.Color := ADefaultColor;
    end;

    FTextLayout.Text := AText;
    FTextLayout.TopLeft := ARect.TopLeft;
    FTextLayout.MaxSize := TPointF.Create(ARect.Width, ARect.Height);
    FTextLayout.HorizontalAlign := AHorizontalAlign;
    FTextLayout.VerticalAlign := AVerticalAlign;
    FTextLayout.WordWrap := False;
    FTextLayout.Trimming := TTextTrimming.None;
    FTextLayout.Opacity := AbsoluteOpacity;
  finally
    FTextLayout.EndUpdate;
  end;
end;

procedure TS4YCustomChart.RenderText(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string; const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign);
begin
  if AText = '' then
    Exit;

  PrepareTextLayout(ATemplate, ADefaultColor, AText, ARect, AHorizontalAlign, AVerticalAlign);
  FTextLayout.RenderLayout(Canvas);
end;

function TS4YCustomChart.ResolveColor(const AColor: TAlphaColor; const AIndex: Integer): TAlphaColor;
begin
  if AColor = TAlphaColors.Null then
    Result := GetPaletteColor(AIndex)
  else
    Result := AColor;
end;

procedure TS4YCustomChart.SetAnimationDuration(const Value: Single);
begin
  FAnimationDuration := Max(0, Value);
end;

procedure TS4YCustomChart.SetAnimationProgress(const AProgress: Single);
begin
  if csDestroying in ComponentState then
    Exit;

  SetLength(FDisplayedValues, Length(FTargetValues));

  for var LIndex := 0 to Length(FTargetValues) - 1 do
  begin
    if LIndex < Length(FStartValues) then
      FDisplayedValues[LIndex] := FStartValues[LIndex] + (FTargetValues[LIndex] - FStartValues[LIndex]) * AProgress
    else
      FDisplayedValues[LIndex] := FTargetValues[LIndex] * AProgress;
  end;

  Repaint;
end;

procedure TS4YCustomChart.SetItemIndex(const Value: Integer);
begin
  if FItemIndex = Value then
    Exit;

  FItemIndex := Max(C_NO_ITEM, Value);
  Repaint;
end;

procedure TS4YCustomChart.SetLegend(const Value: TS4YChartLegend);
begin
  FLegend.Assign(Value);
end;

procedure TS4YCustomChart.SetPalette(const Value: TS4YChartPalette);
begin
  FPalette.Assign(Value);
end;

procedure TS4YCustomChart.SetValueFormat(const Value: string);
begin
  if FValueFormat = Value then
    Exit;

  FValueFormat := Value;
  Repaint;
end;

procedure TS4YCustomChart.StartAnimation(const AStartValues: TArray<Single>);
var
  LAnimation: TS4YChartAnimation;
begin
  if not Assigned(FAnimation) then
  begin
    LAnimation := TS4YChartAnimation.Create(Self);
    LAnimation.Stored := False;
    LAnimation.Interpolation := TInterpolationType.Sinusoidal;
    LAnimation.AnimationType := TAnimationType.InOut;
    LAnimation.Parent := Self;
    FAnimation := LAnimation;
  end;

  FAnimation.StopAtCurrent;
  FStartValues := AStartValues;
  FAnimation.Duration := FAnimationDuration;
  SetAnimationProgress(0);
  FAnimation.Start;
end;

function TS4YCustomChart.ValueFormatStored: Boolean;
begin
  Result := FValueFormat <> C_DEFAULT_VALUE_FORMAT;
end;

end.
