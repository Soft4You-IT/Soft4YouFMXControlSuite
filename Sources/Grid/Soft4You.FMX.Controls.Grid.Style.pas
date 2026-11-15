unit Soft4You.FMX.Controls.Grid.Style;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YGrid - styled presentation with the filter row
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
  FMX.Controls.Model,
  FMX.Graphics,
  FMX.Objects,
  FMX.Presentation.Messages,
  FMX.Header,
  FMX.Grid,
  FMX.Grid.Style,
  Soft4You.FMX.Controls.Grid;

type
  /// <summary>
  /// A row of the grid aligned with its columns, such as the filter row: the presentation places its controls on the
  /// columns, and the row draws a line on its bottom side with the brush of the lines of the grid.
  /// </summary>
  TS4YGridBand = class(TControl)
  private
    FLineBrush: TBrush;
    FLineOnTop: Boolean;
    procedure SetLineBrush(const Value: TBrush);
  protected
    /// <summary>Draws the line on the bottom side, or on the top side, over the background of the style.</summary>
    procedure AfterPaint; override;
  public
    /// <summary>Creates an empty row.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>The brush of the line, from the style of the grid; nil draws no line. The row does not own it.</summary>
    property LineBrush: TBrush read FLineBrush write SetLineBrush;
    /// <summary>True draws the line on the top side, as for the footer; False on the bottom side.</summary>
    property LineOnTop: Boolean read FLineOnTop write FLineOnTop;
  end;

  /// <summary>
  /// A text of the footer, in the cell of a column.
  /// </summary>
  TS4YGridFooterCell = record
    /// <summary>The space of the text, in the coordinates of the footer: the cell less the Padding of the
    /// column.</summary>
    Bounds: TRectF;
    /// <summary>The alignment of the text in the cell.</summary>
    Alignment: TTextAlign;
    /// <summary>The text.</summary>
    Text: string;
  end;

  /// <summary>
  /// The footer of the grid: a row aligned with the columns that draws a text in the cell of each column.
  /// </summary>
  TS4YGridFooterBand = class(TS4YGridBand)
  private
    FCells: TArray<TS4YGridFooterCell>;
    FFont: TFont;
    FFontColor: TAlphaColor;
    FTextPadding: TRectF;
    FOnUpdateCells: TNotifyEvent;
  protected
    /// <summary>Asks for the cells with OnUpdateCells and draws their texts, then the line, over the background of the
    /// style.</summary>
    procedure AfterPaint; override;
  public
    /// <summary>Creates an empty footer.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Destroys the footer.</summary>
    destructor Destroy; override;

    /// <summary>The texts of the footer, set by the presentation of the grid.</summary>
    property Cells: TArray<TS4YGridFooterCell> read FCells write FCells;
    /// <summary>The font of the texts.</summary>
    property Font: TFont read FFont;
    /// <summary>The color of the texts.</summary>
    property FontColor: TAlphaColor read FFontColor write FFontColor;
    /// <summary>The space added around the texts in all the cells, in pixels, besides the Padding of the
    /// columns.</summary>
    property TextPadding: TRectF read FTextPadding write FTextPadding;

    /// <summary>Fires before the footer is drawn, so that the presentation sets its cells.</summary>
    property OnUpdateCells: TNotifyEvent read FOnUpdateCells write FOnUpdateCells;
  end;

  /// <summary>
  /// The styled presentation of TS4YGrid: the presentation of TGrid, with the filter row inserted under the header of
  /// the style of the grid.
  /// </summary>
  /// <remarks>
  /// The filter row is added to the part background of the style, aligned to the top after the header, so the cells
  /// of the grid start under it; its cells follow the width, the order, the visibility and the horizontal scroll of
  /// the columns. A part filterrowbackground in the style of the grid becomes the background of the row, and its
  /// Padding the space between the editors and the sides of their cells.
  /// The footer is added in the same way, aligned to the bottom, over the horizontal scroll bar. A part
  /// footerbackground becomes its background, and its Padding a space around the texts besides the Padding of the
  /// columns, which places them as the texts of the cells; a part footertext, a TText, gives the font and the color of
  /// the texts; without it, they are the ones of the grid.
  /// The Padding of a part is used also when it is 0; without the part, the editors are 2 pixels from the sides of
  /// their cells and the texts have only the Padding of the columns.
  /// The header of a column the rows are sorted by shows an arrow, and its position in the order when there are more
  /// keys; a part sortindicator, a TText, gives their color and font, otherwise the ones of the text of the header.
  /// A part filterinvalidtext, a TText, gives the color of the text of a filter that cannot be read; without it, red.
  /// </remarks>
  TS4YStyledGrid = class(TStyledGrid)
  private
    FAutoFilterTimer: TTimer;
    FBackground: TControl;
    FContentPart: TControl;
    FEditorPadding: TRectF;
    FEditors: TDictionary<TColumn, TControl>;
    FFilterRow: TS4YGridBand;
    FFooter: TS4YGridFooterBand;
    FFooterTexts: TDictionary<TColumn, string>;
    FFooterTextsValid: Boolean;
    FHeader: THeader;
    FHeaderClickShift: TShiftState;
    FHorizontalScrollBar: TControl;
    FInvalidFontColor: TAlphaColor;
    FLineFill: TBrushObject;
    FPreviousHeaderDrawItem: TDrawHeaderItemEvent;
    FSortFont: TFont;
    FSortFontColor: TAlphaColor;
    FSortStyled: Boolean;
    FUpdatingFromEditor: Boolean;
    procedure AutoFilterTimer(Sender: TObject);
    function CreateFilterEditor(const AColumn: TColumn): TControl;
    function DrawSortIndicator(const ACanvas: TCanvas; const AItem: THeaderItem; const ABounds: TRectF;
      const AIndex: Integer): Single;
    procedure HeaderDrawItem(Sender: TObject; const Canvas: TCanvas; const Item: THeaderItem; const Bounds: TRectF);
    procedure HeaderItemClick(Item: THeaderItem);
    procedure HeaderItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure MMSortChanged(var Message: TDispatchMessage); message MM_S4Y_GRID_SORT_CHANGED;
    procedure RepaintHeader;
    procedure FooterUpdateCells(Sender: TObject);
    procedure FreeEditors;
    function GetCellLeft(const AColumnIndex: Integer; const ABand: TControl): Single;
    function FindEditorColumn(const AEditor: TObject): TColumn;
    procedure EditorFilterSubmit(Sender: TObject);
    procedure EditorFilterValueChange(Sender: TObject);
    function GetFilterRowHeight: Single;
    function GetModel: TS4YGridModel; overload;
    procedure MMColumnChanged(var Message: TDispatchMessageWithValue<Integer>); message MM_COLUMN_CHANGED;
    procedure MMColumnMoved(var Message: TDispatchMessageWithValue<TGridModel.TColumnIndexes>); message MM_COLUMN_MOVED;
    procedure MMColumnSettingsChanged(var Message: TDispatchMessage); message MM_S4Y_GRID_COLUMN_SETTINGS_CHANGED;
    procedure MMContentChanged(var Message: TDispatchMessage); message MM_CONTENT_CHANGED;
    procedure MMFilterRowChanged(var Message: TDispatchMessage); message MM_S4Y_GRID_FILTER_ROW_CHANGED;
    procedure MMFilterValueChanged(var Message: TDispatchMessageWithValue<TColumn>);
      message MM_S4Y_GRID_FILTER_VALUE_CHANGED;
    procedure MMFooterChanged(var Message: TDispatchMessage); message MM_S4Y_GRID_FOOTER_CHANGED;
    procedure InvalidateFooter;
    procedure RemoveOldEditors;
    procedure ShowEditorFilter(const AColumn: TColumn; const AEditor: TControl);
    procedure UpdateFilterRow;
    procedure UpdateFilterRowCells;
    procedure UpdateFooter;
  protected
    /// <summary>Inserts the filter row in the style of the grid.</summary>
    procedure ApplyStyle; override;
    /// <summary>Returns the class of the model of the grid, TS4YGridModel.</summary>
    function DefineModelClass: TDataModelClass; override;
    /// <summary>Keeps the footer over the horizontal scroll bar when the bar appears.</summary>
    procedure DoRealign; override;
    /// <summary>Moves the cells of the filter row with the horizontal scroll.</summary>
    procedure DoViewportPositionChange(const OldViewportPosition, NewViewportPosition: TPointF;
      const ContentSizeChanged: Boolean); override;
    /// <summary>Forgets the filter row and its editors, freed with the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Places the cells of the filter row again after a change of size.</summary>
    procedure Resize; override;
  public
    /// <summary>Creates the presentation.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Destroys the presentation.</summary>
    destructor Destroy; override;

    /// <summary>The model of the grid.</summary>
    property Model: TS4YGridModel read GetModel;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.Math.Vectors,
  System.Rtti,
  FMX.Presentation.Factory,
  FMX.Presentation.Style,
  Soft4You.FMX.Controls.Grid.Types,
  Soft4You.FMX.Controls.Grid.FilterEditors;

resourcestring
  S_FILTER_EDITOR_INTERFACE = 'The filter editor of the column %s does not implement IS4YGridFilterEditor';

const
  C_STYLE_BACKGROUND = 'background';
  C_STYLE_CONTENT = 'content';
  C_STYLE_FILTER_INVALID_TEXT = 'filterinvalidtext';
  C_STYLE_FILTER_ROW_BACKGROUND = 'filterrowbackground';
  C_STYLE_FOOTER_BACKGROUND = 'footerbackground';
  C_STYLE_FOOTER_TEXT = 'footertext';
  C_STYLE_HEADER = 'header';
  C_STYLE_HORIZONTAL_SCROLL_BAR = 'hscrollbar';
  C_STYLE_LINE_FILL = 'linefill';
  C_STYLE_SORT_INDICATOR = 'sortindicator';
  C_STYLE_TEXT = 'text';

  // The arrow of the order in the header, and the space around it, in pixels.
  C_SORT_ARROW_WIDTH = 8;
  C_SORT_ARROW_HEIGHT = 4;
  C_SORT_MARGIN = 4;
  // Size of the position in the order compared to the text of the header.
  C_SORT_ORDER_FONT_SCALE = 0.75;

  // Default space between the editors and the sides of their cell, in pixels.
  C_DEFAULT_EDITOR_PADDING = 2;
  // Height of an editor in the automatic height of the filter row: the height of a TEdit.
  C_EDITOR_HEIGHT = 22;

{ TS4YGridBand }

constructor TS4YGridBand.Create(AOwner: TComponent);
begin
  inherited;

  HitTest := False;
  ClipChildren := True;
end;

procedure TS4YGridBand.AfterPaint;
var
  LY: Single;
begin
  if not Assigned(FLineBrush) then
    Exit;

  // The line in the middle of the first or of the last pixel, as the lines of the rows of the grid.
  if FLineOnTop then
    LY := 0.5
  else
    LY := Height - 0.5;

  Canvas.Stroke.Assign(FLineBrush);
  Canvas.Stroke.Thickness := 1;
  Canvas.DrawLine(TPointF.Create(0, LY), TPointF.Create(Width, LY), AbsoluteOpacity);
end;

procedure TS4YGridBand.SetLineBrush(const Value: TBrush);
begin
  FLineBrush := Value;
  Repaint;
end;

{ TS4YGridFooterBand }

constructor TS4YGridFooterBand.Create(AOwner: TComponent);
begin
  inherited;

  FFont := TFont.Create;
  FFontColor := TAlphaColors.Black;
  LineOnTop := True;
end;

destructor TS4YGridFooterBand.Destroy;
begin
  FFont.Free;

  inherited;
end;

procedure TS4YGridFooterBand.AfterPaint;
var
  LRect: TRectF;
begin
  if Assigned(FOnUpdateCells) then
    FOnUpdateCells(Self);

  Canvas.Font.Assign(FFont);
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FFontColor;

  for var I := 0 to High(FCells) do
  begin
    LRect := FCells[I].Bounds;
    LRect := TRectF.Create(LRect.Left + FTextPadding.Left, LRect.Top + FTextPadding.Top,
      LRect.Right - FTextPadding.Right, LRect.Bottom - FTextPadding.Bottom);
    Canvas.FillText(LRect, FCells[I].Text, False, AbsoluteOpacity, [], FCells[I].Alignment, TTextAlign.Center);
  end;

  inherited;
end;

{ TS4YStyledGrid }

constructor TS4YStyledGrid.Create(AOwner: TComponent);
begin
  inherited;

  FEditors := TDictionary<TColumn, TControl>.Create;
  FFooterTexts := TDictionary<TColumn, string>.Create;
  FSortFont := TFont.Create;
  FAutoFilterTimer := TTimer.Create(nil);
  FAutoFilterTimer.Enabled := False;
  FAutoFilterTimer.OnTimer := AutoFilterTimer;
  FEditorPadding := TRectF.Create(C_DEFAULT_EDITOR_PADDING, C_DEFAULT_EDITOR_PADDING, C_DEFAULT_EDITOR_PADDING,
    C_DEFAULT_EDITOR_PADDING);
  FInvalidFontColor := TS4YGridTextFilterEditor.C_DEFAULT_INVALID_FONT_COLOR;
end;

destructor TS4YStyledGrid.Destroy;
begin
  FAutoFilterTimer.Free;
  FSortFont.Free;
  FFooterTexts.Free;
  FEditors.Free;

  inherited;
end;

procedure TS4YStyledGrid.ApplyStyle;
var
  LRowBackground: TControl;
  LFooterText: TText;
  LInvalidText: TText;
  LSortIndicator: TText;
  LTextSettings: ITextSettings;
  LHeader: TControl;
begin
  inherited;

  FBackground := nil;
  FContentPart := nil;
  FLineFill := nil;
  FHeader := nil;
  FPreviousHeaderDrawItem := nil;
  FEditorPadding := TRectF.Create(C_DEFAULT_EDITOR_PADDING, C_DEFAULT_EDITOR_PADDING, C_DEFAULT_EDITOR_PADDING,
    C_DEFAULT_EDITOR_PADDING);

  // The header draws the arrows of the order after the drawing of TStyledGrid, which fires OnDrawColumnHeader.
  if FindStyleResource<THeader>(C_STYLE_HEADER, FHeader) then
  begin
    FPreviousHeaderDrawItem := FHeader.OnDrawItem;
    FHeader.OnDrawItem := HeaderDrawItem;
    FHeader.OnItemClick := HeaderItemClick;
  end;

  FSortStyled := FindStyleResource<TText>(C_STYLE_SORT_INDICATOR, LSortIndicator);

  if FSortStyled then
  begin
    FSortFont.Assign(LSortIndicator.TextSettings.Font);
    FSortFontColor := LSortIndicator.TextSettings.FontColor;
    LSortIndicator.Visible := False;
  end;

  FInvalidFontColor := TS4YGridTextFilterEditor.C_DEFAULT_INVALID_FONT_COLOR;

  if FindStyleResource<TText>(C_STYLE_FILTER_INVALID_TEXT, LInvalidText) then
  begin
    FInvalidFontColor := LInvalidText.TextSettings.FontColor;
    LInvalidText.Visible := False;
  end;

  // Without the part background the style has no place for the filter row.
  if not FindStyleResource<TControl>(C_STYLE_BACKGROUND, FBackground) then
    Exit;

  FindStyleResource<TControl>(C_STYLE_CONTENT, FContentPart);
  FindStyleResource<TBrushObject>(C_STYLE_LINE_FILL, FLineFill);

  // Aligned to the top as the header: the controls with the same alignment are placed in the order of their
  // position, so the row starts under the header to stay under it.
  FFilterRow := TS4YGridBand.Create(nil);
  FFilterRow.Stored := False;
  FFilterRow.Locked := True;

  if FindStyleResource<TControl>(C_STYLE_HEADER, LHeader) then
    FFilterRow.Position.Y := LHeader.Position.Y + LHeader.Height;

  FFilterRow.Align := TAlignLayout.Top;
  FFilterRow.Parent := FBackground;

  if Assigned(FLineFill) then
    FFilterRow.LineBrush := FLineFill.Brush;

  if FindStyleResource<TControl>(C_STYLE_FILTER_ROW_BACKGROUND, LRowBackground) then
  begin
    // The part decides the space, also 0; without it the default stays.
    FEditorPadding := LRowBackground.Padding.Rect;
    LRowBackground.Parent := FFilterRow;
    LRowBackground.Align := TAlignLayout.Contents;
    LRowBackground.HitTest := False;
    LRowBackground.Visible := True;
  end;

  // Aligned to the bottom as the horizontal scroll bar, and placed over it in the same way.
  FFooter := TS4YGridFooterBand.Create(nil);
  FFooter.Stored := False;
  FFooter.Locked := True;

  if FindStyleResource<TControl>(C_STYLE_HORIZONTAL_SCROLL_BAR, FHorizontalScrollBar) then
    FFooter.Position.Y := FHorizontalScrollBar.Position.Y - FFooter.Height;

  FFooter.Align := TAlignLayout.Bottom;
  FFooter.Parent := FBackground;
  FFooter.OnUpdateCells := FooterUpdateCells;

  if Assigned(FLineFill) then
    FFooter.LineBrush := FLineFill.Brush;

  if FindStyleResource<TControl>(C_STYLE_FOOTER_BACKGROUND, LRowBackground) then
  begin
    FFooter.TextPadding := LRowBackground.Padding.Rect;
    LRowBackground.Parent := FFooter;
    LRowBackground.Align := TAlignLayout.Contents;
    LRowBackground.HitTest := False;
    LRowBackground.Visible := True;
  end;

  // The font of the texts: the part footertext, or the text of the grid.
  if FindStyleResource<TText>(C_STYLE_FOOTER_TEXT, LFooterText) then
  begin
    FFooter.Font.Assign(LFooterText.TextSettings.Font);
    FFooter.FontColor := LFooterText.TextSettings.FontColor;
    LFooterText.Visible := False;
  end
  else if Supports(PresentedControl, ITextSettings, LTextSettings) then
  begin
    FFooter.Font.Assign(LTextSettings.ResultingTextSettings.Font);
    FFooter.FontColor := LTextSettings.ResultingTextSettings.FontColor;
  end;

  UpdateFilterRow;
  UpdateFooter;
end;

procedure TS4YStyledGrid.AutoFilterTimer(Sender: TObject);
begin
  FAutoFilterTimer.Enabled := False;
  Model.Filter;
end;

function TS4YStyledGrid.CreateFilterEditor(const AColumn: TColumn): TControl;
var
  LEditor: IS4YGridFilterEditor;
  LKind: TS4YGridFilterValueKind;
begin
  Result := nil;
  LKind := Model.GetFilterKind(AColumn);

  if Assigned(Model.OnCreateFilterEditor) then
    Model.OnCreateFilterEditor(Model.Owner, AColumn, Result);

  // A text field for every column but the check columns.
  if Assigned(Result) then
  begin
    if not Supports(Result, IS4YGridFilterEditor) then
      raise EArgumentException.CreateFmt(S_FILTER_EDITOR_INTERFACE, [AColumn.Name]);
  end
  else if LKind = gvkBoolean then
    Result := TS4YGridCheckFilterEditor.Create(nil)
  else
  begin
    Result := TS4YGridTextFilterEditor.Create(nil);
    TS4YGridTextFilterEditor(Result).InvalidFontColor := FInvalidFontColor;

    if LKind in [gvkInteger, gvkFloat, gvkDate, gvkTime] then
      TS4YGridTextFilterEditor(Result).KeyboardType := TVirtualKeyboardType.NumbersAndPunctuation;
  end;

  Result.Stored := False;
  Result.Parent := FFilterRow;
  ShowEditorFilter(AColumn, Result);
  Supports(Result, IS4YGridFilterEditor, LEditor);
  LEditor.SetOnFilterValueChange(EditorFilterValueChange);
  LEditor.SetOnFilterSubmit(EditorFilterSubmit);
end;

function TS4YStyledGrid.DefineModelClass: TDataModelClass;
begin
  Result := TS4YGridModel;
end;

procedure TS4YStyledGrid.DoRealign;
begin
  inherited;

  // The controls aligned to the bottom are placed in the order of their position: a scroll bar that appears may
  // keep a position over the footer. Moved over the bar, the footer stays there; the cells are placed again.
  if Assigned(FFooter) and FFooter.Visible and Assigned(FHorizontalScrollBar) and FHorizontalScrollBar.Visible and
    (FFooter.Position.Y > FHorizontalScrollBar.Position.Y) then
  begin
    FFooter.Position.Y := FHorizontalScrollBar.Position.Y - FFooter.Height;
    RealignContent;
  end;
end;

procedure TS4YStyledGrid.DoViewportPositionChange(const OldViewportPosition, NewViewportPosition: TPointF;
  const ContentSizeChanged: Boolean);
begin
  inherited;

  UpdateFilterRowCells;

  if Assigned(FFooter) then
    FFooter.Repaint;
end;

function TS4YStyledGrid.DrawSortIndicator(const ACanvas: TCanvas; const AItem: THeaderItem; const ABounds: TRectF;
  const AIndex: Integer): Single;
var
  LTextSettings: ITextSettings;
  LColor: TAlphaColor;
  LOrder: string;
  LOrderWidth: Single;
  LLeft: Single;
  LRight: Single;
  LTop: Single;
  LArrow: TPolygon;
  LState: TCanvasSaveState;
begin
  // Returns the space taken on the right side of the header, kept free of the text of the header.
  LOrderWidth := 0;
  LState := ACanvas.SaveState;
  try
    LColor := TAlphaColors.Black;

    if FSortStyled then
    begin
      ACanvas.Font.Assign(FSortFont);
      LColor := FSortFontColor;
    end
    else if Supports(AItem, ITextSettings, LTextSettings) then
    begin
      ACanvas.Font.Assign(LTextSettings.ResultingTextSettings.Font);
      ACanvas.Font.Size := ACanvas.Font.Size * C_SORT_ORDER_FONT_SCALE;
      LColor := LTextSettings.ResultingTextSettings.FontColor;
    end;

    LOrder := '';

    if Model.Sorting.ShowOrder and (Model.SortCount > 1) then
      LOrder := IntToStr(AIndex + 1);

    ACanvas.Fill.Kind := TBrushKind.Solid;
    ACanvas.Fill.Color := LColor;

    // The arrow and the position in the order, as a group on the right side of the header.
    if LOrder <> '' then
      LOrderWidth := ACanvas.TextWidth(LOrder) + Model.Sorting.OrderSpacing;

    LLeft := ABounds.Right - C_SORT_MARGIN - C_SORT_ARROW_WIDTH - LOrderWidth;

    if (LOrder <> '') and (Model.Sorting.OrderPosition = gopBefore) then
    begin
      ACanvas.FillText(TRectF.Create(LLeft, ABounds.Top, LLeft + LOrderWidth - Model.Sorting.OrderSpacing,
        ABounds.Bottom), LOrder, False, AItem.AbsoluteOpacity, [], TTextAlign.Leading, TTextAlign.Center);
      LRight := ABounds.Right - C_SORT_MARGIN;
    end
    else
    begin
      if LOrder <> '' then
        ACanvas.FillText(TRectF.Create(LLeft + C_SORT_ARROW_WIDTH + Model.Sorting.OrderSpacing, ABounds.Top,
          ABounds.Right - C_SORT_MARGIN, ABounds.Bottom), LOrder, False, AItem.AbsoluteOpacity, [], TTextAlign.Leading,
          TTextAlign.Center);

      LRight := LLeft + C_SORT_ARROW_WIDTH;
    end;

    // Pointing up from the lowest value, down from the highest.
    LTop := ABounds.Top + (ABounds.Height - C_SORT_ARROW_HEIGHT) / 2;
    SetLength(LArrow, 3);

    if Model.SortKeys[AIndex].Descending then
    begin
      LArrow[0] := TPointF.Create(LRight - C_SORT_ARROW_WIDTH, LTop);
      LArrow[1] := TPointF.Create(LRight, LTop);
      LArrow[2] := TPointF.Create(LRight - C_SORT_ARROW_WIDTH / 2, LTop + C_SORT_ARROW_HEIGHT);
    end
    else
    begin
      LArrow[0] := TPointF.Create(LRight - C_SORT_ARROW_WIDTH, LTop + C_SORT_ARROW_HEIGHT);
      LArrow[1] := TPointF.Create(LRight, LTop + C_SORT_ARROW_HEIGHT);
      LArrow[2] := TPointF.Create(LRight - C_SORT_ARROW_WIDTH / 2, LTop);
    end;

    ACanvas.FillPolygon(LArrow, AItem.AbsoluteOpacity);
  finally
    ACanvas.RestoreState(LState);
  end;

  Result := 2 * C_SORT_MARGIN + C_SORT_ARROW_WIDTH + LOrderWidth;
end;

procedure TS4YStyledGrid.EditorFilterSubmit(Sender: TObject);
begin
  // The filter is applied now: the wait of AutoFilter is no longer needed.
  FAutoFilterTimer.Enabled := False;
  Model.Filter;
end;

procedure TS4YStyledGrid.EditorFilterValueChange(Sender: TObject);
var
  LColumn: TColumn;
  LEditor: IS4YGridFilterEditor;
begin
  LColumn := FindEditorColumn(Sender);

  if not Assigned(LColumn) or not Supports(Sender, IS4YGridFilterEditor, LEditor) then
    Exit;

  // The editor already shows the value: the model does not send it back. The text fields give their text, read by
  // the model with the syntax of the filters.
  FUpdatingFromEditor := True;
  try
    if Sender is TS4YGridTextFilterEditor then
    begin
      Model.SetFilterText(LColumn, TS4YGridTextFilterEditor(Sender).Text);
      TS4YGridTextFilterEditor(Sender).Invalid := Model.GetFilterState(LColumn) = gfsInvalid;
    end
    else
      Model.SetFilterValue(LColumn, LEditor.GetFilterValue);
  finally
    FUpdatingFromEditor := False;
  end;

  // Each change starts the wait again; a change followed at once by a request to filter, as a click on a check
  // box, stops it.
  if Model.FilterRow.AutoFilter then
  begin
    FAutoFilterTimer.Enabled := False;
    FAutoFilterTimer.Interval := Max(1, Model.FilterRow.FilterDelay);
    FAutoFilterTimer.Enabled := True;
  end;
end;

function TS4YStyledGrid.FindEditorColumn(const AEditor: TObject): TColumn;
var
  LPair: TPair<TColumn, TControl>;
begin
  Result := nil;

  for LPair in FEditors do
    if TObject(LPair.Value) = AEditor then
      Result := LPair.Key;
end;

procedure TS4YStyledGrid.FooterUpdateCells(Sender: TObject);
var
  LColumn: TColumn;
  LCells: TArray<TS4YGridFooterCell>;
  LRect: TRect;
  LLeft: Single;
  LText: string;
  LSetting: TS4YGridColumnSetting;
begin
  // The texts are calculated when the footer is drawn: while the grid is updated its values are not available.
  if not FFooterTextsValid then
  begin
    FFooterTexts.Clear;

    for var I := 0 to ColumnCount - 1 do
      if Columns[I].EffectiveVisible then
        FFooterTexts.Add(Columns[I], Model.GetFooterText(Columns[I]));

    FFooterTextsValid := True;
  end;

  // The places follow the columns and the horizontal scroll at each drawing.
  LCells := nil;

  for var I := 0 to ColumnCount - 1 do
  begin
    LColumn := Columns[I];

    if LColumn.EffectiveVisible and (LColumn.Width > 0) and FFooterTexts.TryGetValue(LColumn, LText) and
      (LText <> '') then
    begin
      LRect := CellRect(I, 0);
      LLeft := GetCellLeft(I, FFooter);
      SetLength(LCells, Length(LCells) + 1);

      // The texts of the footer start where the texts of the cells start.
      LCells[High(LCells)].Bounds := LColumn.Padding.PaddingRect(TRectF.Create(LLeft, 0, LLeft + LRect.Width,
        FFooter.Height));
      LCells[High(LCells)].Text := LText;
      LSetting := Model.ColumnSettings.FindColumn(LColumn);

      if Assigned(LSetting) then
        LCells[High(LCells)].Alignment := LSetting.FooterAlignment
      else
        LCells[High(LCells)].Alignment := TS4YGridColumnSetting.C_DEFAULT_FOOTER_ALIGNMENT;
    end;
  end;

  FFooter.Cells := LCells;
end;

procedure TS4YStyledGrid.FreeEditors;
begin
  for var LEditor in FEditors.Values do
    LEditor.Free;

  FEditors.Clear;
end;

procedure TS4YStyledGrid.FreeStyle;
begin
  // The row and its editors are children of the style, and are freed with it.
  FAutoFilterTimer.Enabled := False;
  FEditors.Clear;
  FFilterRow := nil;
  FFooter := nil;
  FHeader := nil;
  FPreviousHeaderDrawItem := nil;
  FHorizontalScrollBar := nil;
  FBackground := nil;
  FContentPart := nil;
  FLineFill := nil;

  inherited;
end;

function TS4YStyledGrid.GetCellLeft(const AColumnIndex: Integer; const ABand: TControl): Single;
var
  LOffset: Single;
begin
  // The cells of the grid start at the part content; the band may start elsewhere in the same parent.
  if Assigned(FContentPart) then
    LOffset := FContentPart.Position.X - ABand.Position.X
  else
    LOffset := 0;

  Result := CellRect(AColumnIndex, 0).Left - ViewportPosition.X + LOffset;
end;

function TS4YStyledGrid.GetFilterRowHeight: Single;
begin
  if Model.FilterRow.Height > 0 then
    Result := Model.FilterRow.Height
  else
    Result := Max(RowHeight, C_EDITOR_HEIGHT + FEditorPadding.Top + FEditorPadding.Bottom + 1);
end;

function TS4YStyledGrid.GetModel: TS4YGridModel;
begin
  Result := TS4YGridModel(inherited Model);
end;

procedure TS4YStyledGrid.HeaderDrawItem(Sender: TObject; const Canvas: TCanvas; const Item: THeaderItem;
  const Bounds: TRectF);
var
  LIndex: Integer;
  LSpace: Single;
  LText: TFmxObject;
begin
  if Assigned(FPreviousHeaderDrawItem) then
    FPreviousHeaderDrawItem(Sender, Canvas, Item, Bounds);

  if not (Item is TGridHeaderItem) then
    Exit;

  // The click does not tell the keys: they come from the mouse down. The items are created again by the grid, and
  // they are drawn before they can be clicked.
  if not Assigned(Item.OnMouseDown) then
    Item.OnMouseDown := HeaderItemMouseDown;

  LIndex := Model.SortIndexOf(TGridHeaderItem(Item).Column);
  LSpace := 0;

  if LIndex >= 0 then
    LSpace := DrawSortIndicator(Canvas, Item, Bounds, LIndex);

  // The text of the header leaves the space of the arrow; TagFloat keeps the space added to its margin of the style.
  LText := Item.FindStyleResource(C_STYLE_TEXT);

  if (LText is TControl) and not SameValue(LText.TagFloat, LSpace) then
  begin
    TControl(LText).Margins.Right := TControl(LText).Margins.Right - LText.TagFloat + LSpace;
    LText.TagFloat := LSpace;
  end;
end;

procedure TS4YStyledGrid.HeaderItemClick(Item: THeaderItem);
begin
  if Item is TGridHeaderItem then
    Model.SortByHeaderClick(TGridHeaderItem(Item).Column, FHeaderClickShift);

  FHeaderClickShift := [];
end;

procedure TS4YStyledGrid.HeaderItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FHeaderClickShift := Shift;
end;

procedure TS4YStyledGrid.InvalidateFooter;
begin
  FFooterTextsValid := False;

  if Assigned(FFooter) then
    FFooter.Repaint;
end;

procedure TS4YStyledGrid.MMColumnChanged(var Message: TDispatchMessageWithValue<Integer>);
begin
  inherited;

  UpdateFilterRowCells;
  InvalidateFooter;
end;

procedure TS4YStyledGrid.MMColumnMoved(var Message: TDispatchMessageWithValue<TGridModel.TColumnIndexes>);
begin
  inherited;

  UpdateFilterRowCells;

  if Assigned(FFooter) then
    FFooter.Repaint;
end;

procedure TS4YStyledGrid.MMColumnSettingsChanged(var Message: TDispatchMessage);
begin
  // The editors are created again, with the new lists of values; the filter values stay in the model.
  FreeEditors;
  UpdateFilterRow;
  InvalidateFooter;
end;

procedure TS4YStyledGrid.MMContentChanged(var Message: TDispatchMessage);
begin
  inherited;

  UpdateFilterRow;
  UpdateFooter;
end;

procedure TS4YStyledGrid.MMFilterRowChanged(var Message: TDispatchMessage);
begin
  UpdateFilterRow;
end;

procedure TS4YStyledGrid.MMFooterChanged(var Message: TDispatchMessage);
begin
  UpdateFooter;
end;

procedure TS4YStyledGrid.MMFilterValueChanged(var Message: TDispatchMessageWithValue<TColumn>);
var
  LEditor: TControl;
begin
  if FUpdatingFromEditor then
    Exit;

  if FEditors.TryGetValue(Message.Value, LEditor) then
    ShowEditorFilter(Message.Value, LEditor);
end;

procedure TS4YStyledGrid.MMSortChanged(var Message: TDispatchMessage);
begin
  RepaintHeader;
end;

procedure TS4YStyledGrid.RepaintHeader;
begin
  if not Assigned(FHeader) then
    Exit;

  for var I := 0 to FHeader.Count - 1 do
    FHeader.Items[I].Repaint;
end;

procedure TS4YStyledGrid.RemoveOldEditors;
var
  LPresent: TList<TColumn>;
  LColumns: TArray<TColumn>;
begin
  // The editors of the columns no longer in the grid.
  LPresent := TList<TColumn>.Create;
  try
    for var I := 0 to ColumnCount - 1 do
      LPresent.Add(Columns[I]);

    LColumns := FEditors.Keys.ToArray;

    for var I := 0 to High(LColumns) do
      if not LPresent.Contains(LColumns[I]) then
      begin
        FEditors[LColumns[I]].Free;
        FEditors.Remove(LColumns[I]);
      end;
  finally
    LPresent.Free;
  end;
end;

procedure TS4YStyledGrid.Resize;
begin
  inherited;

  UpdateFilterRowCells;

  if Assigned(FFooter) then
    FFooter.Repaint;
end;

procedure TS4YStyledGrid.ShowEditorFilter(const AColumn: TColumn; const AEditor: TControl);
var
  LFilterEditor: IS4YGridFilterEditor;
begin
  // A text field shows the text of the filter; the other editors its value.
  if AEditor is TS4YGridTextFilterEditor then
  begin
    TS4YGridTextFilterEditor(AEditor).SetFilterText(Model.GetFilterText(AColumn));
    TS4YGridTextFilterEditor(AEditor).Invalid := Model.GetFilterState(AColumn) = gfsInvalid;
  end
  else if Supports(AEditor, IS4YGridFilterEditor, LFilterEditor) then
    LFilterEditor.SetFilterValue(Model.GetFilterValue(AColumn));
end;

procedure TS4YStyledGrid.UpdateFilterRow;
begin
  if not Assigned(FFilterRow) then
    Exit;

  FFilterRow.Visible := Model.FilterRow.Visible;
  FFilterRow.Height := GetFilterRowHeight;
  // The part content is now smaller or larger: the cells of the grid are placed in it again.
  RealignContent;
  RemoveOldEditors;
  UpdateFilterRowCells;
end;

procedure TS4YStyledGrid.UpdateFilterRowCells;
var
  LColumn: TColumn;
  LEditor: TControl;
  LRect: TRect;
  LShown: Boolean;
begin
  if not Assigned(FFilterRow) or not FFilterRow.Visible then
    Exit;

  for var I := 0 to ColumnCount - 1 do
  begin
    LColumn := Columns[I];
    LShown := LColumn.EffectiveVisible and (LColumn.Width > 0) and Model.ColumnSettings.IsFilterable(LColumn);

    if not FEditors.TryGetValue(LColumn, LEditor) then
    begin
      LEditor := nil;

      if LShown then
      begin
        LEditor := CreateFilterEditor(LColumn);
        FEditors.Add(LColumn, LEditor);
      end;
    end;

    if Assigned(LEditor) then
    begin
      LEditor.Visible := LShown;

      // The same place as the cells of the column, moved by the horizontal scroll.
      if LShown then
      begin
        LRect := CellRect(I, 0);
        LEditor.SetBounds(GetCellLeft(I, FFilterRow) + FEditorPadding.Left, FEditorPadding.Top,
          LRect.Width - FEditorPadding.Left - FEditorPadding.Right,
          FFilterRow.Height - FEditorPadding.Top - FEditorPadding.Bottom - 1);
      end;
    end;
  end;
end;

procedure TS4YStyledGrid.UpdateFooter;
var
  LHeight: Single;
begin
  if not Assigned(FFooter) then
    Exit;

  if Model.FooterRow.Height > 0 then
    LHeight := Model.FooterRow.Height
  else
    LHeight := RowHeight + FFooter.TextPadding.Top + FFooter.TextPadding.Bottom;

  // A change of the visibility or of the height makes the part content smaller or larger.
  if (FFooter.Visible <> Model.FooterRow.Visible) or not SameValue(FFooter.Height, LHeight) then
  begin
    FFooter.Visible := Model.FooterRow.Visible;
    FFooter.Height := LHeight;
    RealignContent;
  end;

  InvalidateFooter;
end;

initialization
  TPresentationProxyFactory.Current.Register(TS4YGrid, TControlType.Styled, TStyledPresentationProxy<TS4YStyledGrid>);

finalization
  TPresentationProxyFactory.Current.Unregister(TS4YGrid, TControlType.Styled,
    TStyledPresentationProxy<TS4YStyledGrid>);

end.
