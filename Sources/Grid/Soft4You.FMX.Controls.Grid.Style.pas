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
  FMX.ListBox,
  FMX.Calendar,
  FMX.StdCtrls,
  FMX.Grid,
  FMX.Grid.Style,
  Soft4You.FMX.Controls.Grid,
  Soft4You.FMX.Controls.Grid.Filters;

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
  /// The button on the right side of the header that shows or hides the filter row: a funnel on the style of the
  /// items of the header, pressed while the row is shown.
  /// </summary>
  TS4YGridFilterButton = class(TCustomButton)
  private
    FIcon: TControl;
    procedure SetIcon(const Value: TControl);
  protected
    /// <summary>Draws the funnel over the background of the style, when there is no Icon.</summary>
    procedure AfterPaint; override;
    /// <summary>Returns headeritemstyle, the style of the items of the header.</summary>
    function GetDefaultStyleLookupName: string; override;
  public
    /// <summary>Creates the button.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>
    /// A control shown in the middle of the button in place of the funnel, such as the part filterbutton of the style
    /// of the grid; the button becomes its owner and frees it.
    /// </summary>
    property Icon: TControl read FIcon write SetIcon;
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
  /// The text fields take the style FilterRow.EditStyleLookup, editstyle by default; the check boxes the style
  /// FilterRow.CheckBoxStyleLookup, by default checkcellstyle, the style of the check boxes of the cells.
  /// A part filterinvalidtext, a TText, gives the color of the text of a filter that cannot be read; without it, red.
  /// The button of a text field opens the menu of the filter in a TPopup, with the style book of the form of the grid
  /// and the style FilterRow.MenuStyleLookup; with FilterRow.ShowButton, a button on the right side of the header shows
  /// or hides the row, with a part filterbutton of the style as its icon; when the popup finds no style, its list keeps the background of its own
  /// style. A part filtermenubutton is shown in the button in place of its three
  /// dots.
  /// </remarks>
  TS4YStyledGrid = class(TStyledGrid)
  private
    FAutoFilterTimer: TTimer;
    FBackground: TControl;
    FContentPart: TControl;
    FEditorPadding: TRectF;
    FEditors: TDictionary<TColumn, TControl>;
    FFilterButton: TS4YGridFilterButton;
    FFilterButtonIcon: TControl;
    FFilterRow: TS4YGridBand;
    FFooter: TS4YGridFooterBand;
    FFooterTexts: TDictionary<TColumn, string>;
    FFooterTextsValid: Boolean;
    FHeader: THeader;
    FHeaderClickShift: TShiftState;
    FHorizontalScrollBar: TControl;
    FInvalidFontColor: TAlphaColor;
    FLineFill: TBrushObject;
    FMenuButtonIcon: TControl;
    FMenuCalendar: TCalendar;
    FMenuColumn: TColumn;
    FMenuItems: TS4YGridFilterMenuItems;
    FMenuList: TListBox;
    FMenuPopup: TPopup;
    FPreviousHeaderDrawItem: TDrawHeaderItemEvent;
    FSortFont: TFont;
    FSortFontColor: TAlphaColor;
    FSortStyled: Boolean;
    FUpdatingFromEditor: Boolean;
    procedure ApplyEditorStyle(const AEditor: TControl);
    procedure ApplyMenuStyle;
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
    procedure CloseMenu;
    procedure CreateMenuPopup;
    procedure EditorFilterSubmit(Sender: TObject);
    procedure EditorFilterValueChange(Sender: TObject);
    procedure EditorMenuButtonClick(Sender: TObject);
    procedure FilterButtonClick(Sender: TObject);
    procedure FocusFilterRow;
    procedure FilterMenuDone(const AColumn: TColumn; const AOldText: string);
    procedure MenuCalendarDateSelected(Sender: TObject);
    procedure MenuListItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
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
    procedure MMFilterRowToggled(var Message: TDispatchMessage); message MM_S4Y_GRID_FILTER_ROW_TOGGLED;
    procedure InvalidateFooter;
    procedure RemoveOldEditors;
    procedure ShowEditorFilter(const AColumn: TColumn; const AEditor: TControl);
    procedure ShowFilterCalendar;
    procedure ShowFilterMenu(const AColumn: TColumn; const AEditor: TControl);
    procedure UpdateCheckAlignment;
    procedure UpdateFilterButton;
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
    /// <summary>Places the boxes of the check boxes of the filter row as the boxes of their cells.</summary>
    procedure Paint; override;
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
  FMX.Menus,
  FMX.Presentation.Factory,
  FMX.Presentation.Style,
  Soft4You.FMX.Controls.Grid.Types,
  Soft4You.FMX.Controls.Grid.FilterEditors;

resourcestring
  S_FILTER_EDITOR_INTERFACE = 'The filter editor of the column %s does not implement IS4YGridFilterEditor';

const
  C_STYLE_BACKGROUND = 'background';
  C_STYLE_CONTENT = 'content';
  C_STYLE_CHECK_CELL = 'checkcellstyle';
  C_STYLE_FILTER_BUTTON = 'filterbutton';
  C_STYLE_FILTER_INVALID_TEXT = 'filterinvalidtext';
  C_STYLE_FILTER_MENU_BUTTON = 'filtermenubutton';
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

  // The menu of the filter: least and greatest width, space of an item besides its text, greatest height, height of a
  // separator, size of the calendar, in pixels.
  C_MENU_WIDTH = 180;
  C_MENU_MAX_WIDTH = 480;
  C_MENU_TEXT_SPACE = 40;
  C_MENU_MAX_HEIGHT = 360;
  C_MENU_SEPARATOR_HEIGHT = 7;
  C_MENU_BORDER = 4;
  C_CALENDAR_WIDTH = 240;
  C_CALENDAR_HEIGHT = 220;
  C_SEPARATOR_OPACITY = 0.3;

  // The funnel of the button of the header: its size compared to the button, and the width of its stem.
  C_FUNNEL_SCALE = 0.5;
  C_FUNNEL_STEM = 0.25;
  // The list of the menu without background of its own, over a popup with a style.
  C_STYLE_MENU_LIST_TRANSPARENT = 'transparentlistboxstyle';

type
  // The popup of the menu of a filter: it tells whether it found its style.
  TS4YGridMenuPopup = class(TPopup)
  public
    function HasStyle: Boolean;
  end;

{ TS4YGridMenuPopup }

function TS4YGridMenuPopup.HasStyle: Boolean;
begin
  Result := Assigned(ResourceControl);
end;

{ TS4YGridFilterButton }

constructor TS4YGridFilterButton.Create(AOwner: TComponent);
begin
  inherited;

  StaysPressed := True;
  CanFocus := False;
end;

procedure TS4YGridFilterButton.AfterPaint;
var
  LTextSettings: ITextSettings;
  LColor: TAlphaColor;
  LSize: Single;
  LLeft: Single;
  LTop: Single;
  LFunnel: TPolygon;
begin
  inherited;

  if Assigned(FIcon) then
    Exit;

  // The color of the text of the header.
  LColor := TAlphaColors.Black;

  if Supports(Self, ITextSettings, LTextSettings) then
    LColor := LTextSettings.ResultingTextSettings.FontColor;

  LSize := Min(Width, Height) * C_FUNNEL_SCALE;
  LLeft := (Width - LSize) / 2;
  LTop := (Height - LSize) / 2;
  SetLength(LFunnel, 6);
  LFunnel[0] := TPointF.Create(LLeft, LTop);
  LFunnel[1] := TPointF.Create(LLeft + LSize, LTop);
  LFunnel[2] := TPointF.Create(LLeft + LSize * (0.5 + C_FUNNEL_STEM / 2), LTop + LSize * 0.5);
  LFunnel[3] := TPointF.Create(LLeft + LSize * (0.5 + C_FUNNEL_STEM / 2), LTop + LSize);
  LFunnel[4] := TPointF.Create(LLeft + LSize * (0.5 - C_FUNNEL_STEM / 2), LTop + LSize * 0.85);
  LFunnel[5] := TPointF.Create(LLeft + LSize * (0.5 - C_FUNNEL_STEM / 2), LTop + LSize * 0.5);
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := LColor;
  Canvas.FillPolygon(LFunnel, AbsoluteOpacity);
end;

function TS4YGridFilterButton.GetDefaultStyleLookupName: string;
begin
  Result := 'headeritemstyle';
end;

procedure TS4YGridFilterButton.SetIcon(const Value: TControl);
begin
  if FIcon = Value then
    Exit;

  FIcon.Free;
  FIcon := Value;

  if Assigned(FIcon) then
  begin
    FIcon.Stored := False;
    FIcon.Align := TAlignLayout.Center;
    FIcon.HitTest := False;
    FIcon.Visible := True;
    FIcon.Parent := Self;
  end;

  Repaint;
end;

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
  FMenuItems.Free;
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

  // The icon of the button of the header: the button shows a copy of it.
  if FindStyleResource<TControl>(C_STYLE_FILTER_BUTTON, FFilterButtonIcon) then
    FFilterButtonIcon.Visible := False;

  // The icon of the button of the menu: each button shows a copy of it.
  if FindStyleResource<TControl>(C_STYLE_FILTER_MENU_BUTTON, FMenuButtonIcon) then
    FMenuButtonIcon.Visible := False;

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

  // The button over the right side of the header, which leaves the space for it.
  FFilterButton := TS4YGridFilterButton.Create(nil);
  FFilterButton.Stored := False;
  FFilterButton.Locked := True;
  FFilterButton.OnClick := FilterButtonClick;
  FFilterButton.Parent := FBackground;

  if Assigned(FFilterButtonIcon) then
    FFilterButton.Icon := TControl(FFilterButtonIcon.Clone(nil));

  UpdateFilterRow;
  UpdateFooter;
end;

procedure TS4YStyledGrid.ApplyEditorStyle(const AEditor: TControl);
begin
  // A style that is not found gives the default style of the editor: editstyle, checkboxstyle.
  if AEditor is TS4YGridTextFilterEditor then
    TS4YGridTextFilterEditor(AEditor).StyleLookup := Model.FilterRow.EditStyleLookup
  else if (AEditor is TS4YGridCheckFilterEditor) and (Model.FilterRow.CheckBoxStyleLookup <> '') then
    TS4YGridCheckFilterEditor(AEditor).StyleLookup := Model.FilterRow.CheckBoxStyleLookup
  else if AEditor is TS4YGridCheckFilterEditor then
    TS4YGridCheckFilterEditor(AEditor).StyleLookup := C_STYLE_CHECK_CELL;
end;

procedure TS4YStyledGrid.ApplyMenuStyle;
begin
  FMenuPopup.StyleLookup := Model.FilterRow.MenuStyleLookup;
  FMenuPopup.ApplyStyleLookup;

  // A popup without a style draws no background, as with the styles of the platform that have no popupstyle: the list
  // keeps the background of its own style. A popup with a style draws its background, and the list does not cover it.
  if TS4YGridMenuPopup(FMenuPopup).HasStyle then
    FMenuList.StyleLookup := C_STYLE_MENU_LIST_TRANSPARENT
  else
    FMenuList.StyleLookup := '';
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
    TS4YGridTextFilterEditor(Result).ShowMenuButton := Model.FilterRow.ShowMenuButton;
    TS4YGridTextFilterEditor(Result).OnMenuButtonClick := EditorMenuButtonClick;

    if Assigned(FMenuButtonIcon) then
      TS4YGridTextFilterEditor(Result).MenuButton.Icon := TControl(FMenuButtonIcon.Clone(nil));

    if LKind in [gvkInteger, gvkFloat, gvkDate, gvkTime] then
      TS4YGridTextFilterEditor(Result).KeyboardType := TVirtualKeyboardType.NumbersAndPunctuation;
  end;

  // Part of the grid: the designer does not select it.
  Result.Stored := False;
  Result.Locked := True;
  ApplyEditorStyle(Result);
  Result.Parent := FFilterRow;
  ShowEditorFilter(AColumn, Result);
  Supports(Result, IS4YGridFilterEditor, LEditor);
  LEditor.SetOnFilterValueChange(EditorFilterValueChange);
  LEditor.SetOnFilterSubmit(EditorFilterSubmit);
end;

procedure TS4YStyledGrid.CloseMenu;
begin
  // Before its editor is freed: the popup, also while it closes, no longer refers to it.
  if not Assigned(FMenuPopup) then
    Exit;

  FMenuPopup.IsOpen := False;
  FMenuPopup.PlacementTarget := nil;
end;

procedure TS4YStyledGrid.CreateMenuPopup;
begin
  if Assigned(FMenuPopup) then
    Exit;

  // A list for the items, and a calendar in its place for the item gmaCalendar.
  FMenuPopup := TS4YGridMenuPopup.Create(Self);
  FMenuPopup.Stored := False;
  FMenuPopup.Placement := TPlacement.Bottom;
  FMenuPopup.Parent := Self;
  FMenuList := TListBox.Create(FMenuPopup);
  FMenuList.Stored := False;
  FMenuList.Align := TAlignLayout.Client;
  FMenuList.MultiSelectStyle := TMultiSelectStyle.Extended;
  FMenuList.OnItemClick := MenuListItemClick;
  FMenuList.Parent := FMenuPopup;
  FMenuCalendar := TCalendar.Create(FMenuPopup);
  FMenuCalendar.Stored := False;
  FMenuCalendar.Align := TAlignLayout.Client;
  FMenuCalendar.Visible := False;
  FMenuCalendar.OnDateSelected := MenuCalendarDateSelected;
  FMenuCalendar.Parent := FMenuPopup;
end;

function TS4YStyledGrid.DefineModelClass: TDataModelClass;
begin
  Result := TS4YGridModel;
end;

procedure TS4YStyledGrid.DoRealign;
begin
  inherited;

  UpdateFilterButton;

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

procedure TS4YStyledGrid.EditorMenuButtonClick(Sender: TObject);
var
  LColumn: TColumn;
begin
  LColumn := FindEditorColumn(Sender);

  if Assigned(LColumn) and (Sender is TControl) then
    ShowFilterMenu(LColumn, TControl(Sender));
end;

procedure TS4YStyledGrid.FilterButtonClick(Sender: TObject);
begin
  Model.ToggleFilterRow;
end;

procedure TS4YStyledGrid.FilterMenuDone(const AColumn: TColumn; const AOldText: string);
var
  LEditor: TControl;
begin
  // Back to the editor, to write the value after the operator.
  if FEditors.TryGetValue(AColumn, LEditor) and LEditor.CanFocus then
  begin
    LEditor.SetFocus;

    if LEditor is TS4YGridTextFilterEditor then
      TS4YGridTextFilterEditor(LEditor).GoToTextEnd;
  end;

  // A filter changed and complete is applied at once; an operator without value waits for it.
  if (Model.GetFilterText(AColumn) <> AOldText) and (Model.GetFilterState(AColumn) in [gfsEmpty, gfsValid]) then
    EditorFilterSubmit(nil);
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
  CloseMenu;

  for var LEditor in FEditors.Values do
    LEditor.Free;

  FEditors.Clear;
end;

procedure TS4YStyledGrid.FreeStyle;
begin
  // The row and its editors are children of the style, and are freed with it; the menu of an editor is closed.
  FAutoFilterTimer.Enabled := False;

  CloseMenu;
  FEditors.Clear;
  FFilterRow := nil;
  FFooter := nil;
  FHeader := nil;
  FPreviousHeaderDrawItem := nil;
  FHorizontalScrollBar := nil;
  FFilterButton := nil;
  FFilterButtonIcon := nil;
  FMenuButtonIcon := nil;
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

procedure TS4YStyledGrid.MenuCalendarDateSelected(Sender: TObject);
var
  LOldText: string;
begin
  if not Assigned(FMenuColumn) then
    Exit;

  FMenuPopup.IsOpen := False;
  LOldText := Model.GetFilterText(FMenuColumn);
  Model.ApplyFilterValue(FMenuColumn, TValue.From<TDate>(FMenuCalendar.Date));
  FilterMenuDone(FMenuColumn, LOldText);
end;

procedure TS4YStyledGrid.MenuListItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
var
  LMenuItem: TS4YGridFilterMenuItem;
  LColumn: TColumn;
  LOldText: string;
begin
  if not Assigned(Item) or not Assigned(FMenuItems) or (Item.Tag < 0) or (Item.Tag >= FMenuItems.Count) then
    Exit;

  LMenuItem := FMenuItems[Item.Tag];

  if LMenuItem.Action = gmaSeparator then
    Exit;

  if LMenuItem.Action = gmaCalendar then
  begin
    ShowFilterCalendar;
    Exit;
  end;

  FMenuPopup.IsOpen := False;
  LColumn := FMenuColumn;
  LOldText := Model.GetFilterText(LColumn);
  Model.ApplyFilterMenuItem(LMenuItem);

  // An item of the application does what its OnClick does, also about OnFilter.
  if LMenuItem.Action <> gmaCustom then
    FilterMenuDone(LColumn, LOldText);
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
  UpdateFilterButton;
end;

procedure TS4YStyledGrid.FocusFilterRow;
var
  LEditor: TControl;
  LColumnIndex: Integer;
begin
  // The editor of the current column, or the first editor shown.
  LEditor := nil;
  LColumnIndex := TCustomGrid(PresentedControl).ColumnIndex;

  if (LColumnIndex >= 0) and (LColumnIndex < ColumnCount) and FEditors.TryGetValue(Columns[LColumnIndex], LEditor) and
    not LEditor.Visible then
    LEditor := nil;

  for var I := 0 to ColumnCount - 1 do
    if not Assigned(LEditor) and FEditors.ContainsKey(Columns[I]) and FEditors[Columns[I]].Visible then
      LEditor := FEditors[Columns[I]];

  if Assigned(LEditor) and LEditor.CanFocus then
    LEditor.SetFocus;
end;

procedure TS4YStyledGrid.MMFilterRowToggled(var Message: TDispatchMessage);
begin
  // Shown: the focus in the row, to write a filter; hidden: the focus back to the cells.
  if Model.FilterRow.Visible then
    FocusFilterRow
  else if PresentedControl.CanFocus then
    PresentedControl.SetFocus;
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

procedure TS4YStyledGrid.Paint;
begin
  inherited;

  // A column does not tell a change of its HorzAlign: its cells use it when they are drawn, and so does the row.
  UpdateCheckAlignment;
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
        CloseMenu;
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

procedure TS4YStyledGrid.ShowFilterCalendar;
var
  LFilter: TS4YGridFilter;
begin
  // The calendar opens on the date of the filter, or on today.
  FMenuPopup.IsOpen := False;
  LFilter := Model.GetFilter(FMenuColumn);

  if LFilter.IsActive and not LFilter.Value.IsEmpty then
    FMenuCalendar.Date := LFilter.Value.AsExtended
  else
    FMenuCalendar.Date := Date;

  FMenuList.Visible := False;
  FMenuCalendar.Visible := True;
  FMenuPopup.Width := C_CALENDAR_WIDTH;
  FMenuPopup.Height := C_CALENDAR_HEIGHT;
  ApplyMenuStyle;
  FMenuPopup.Popup;
end;

procedure TS4YStyledGrid.ShowFilterMenu(const AColumn: TColumn; const AEditor: TControl);
var
  LSetting: TS4YGridColumnSetting;
  LPoint: TPointF;
  LItem: TListBoxItem;
  LLine: TLine;
  LHeight: Single;
  LWidth: Single;
begin
  // A menu of the application is shown in place of the menu of the grid.
  LSetting := Model.ColumnSettings.FindColumn(AColumn);

  if Assigned(LSetting) and Assigned(LSetting.FilterMenu) then
  begin
    LPoint := AEditor.LocalToScreen(TPointF.Create(0, AEditor.Height));
    LSetting.FilterMenu.PopupComponent := AEditor;
    LSetting.FilterMenu.Popup(LPoint.X, LPoint.Y);
    Exit;
  end;

  CreateMenuPopup;
  FMenuPopup.IsOpen := False;
  FMenuColumn := AColumn;
  FMenuItems.Free;
  FMenuItems := TS4YGridFilterMenuItems.Create(AColumn);
  Model.GetFilterMenu(AColumn, FMenuItems);
  LHeight := 0;
  FMenuList.BeginUpdate;
  try
    FMenuList.Clear;

    // The items chosen, as the operator of the filter, are shown selected.
    for var I := 0 to FMenuItems.Count - 1 do
    begin
      LItem := TListBoxItem.Create(FMenuList);
      LItem.Stored := False;
      LItem.Tag := I;

      if FMenuItems[I].Action = gmaSeparator then
      begin
        LItem.Height := C_MENU_SEPARATOR_HEIGHT;
        LItem.Selectable := False;
        LItem.HitTest := False;
        LLine := TLine.Create(LItem);
        LLine.Stored := False;
        LLine.LineType := TLineType.Top;
        LLine.Align := TAlignLayout.VertCenter;
        LLine.Height := 1;
        LLine.Opacity := C_SEPARATOR_OPACITY;
        LLine.HitTest := False;
        LLine.Parent := LItem;
      end
      else
        LItem.Text := FMenuItems[I].Text;

      LItem.Parent := FMenuList;
      LItem.IsSelected := FMenuItems[I].Checked;
      LHeight := LHeight + LItem.Height;
    end;
  finally
    FMenuList.EndUpdate;
  end;

  // As wide as the column, or as the longest text when it is wider, within a limit.
  LWidth := Max(AEditor.Width, C_MENU_WIDTH);

  for var I := 0 to FMenuList.Count - 1 do
  begin
    LItem := FMenuList.ListItems[I];

    if LItem.Text <> '' then
    begin
      LItem.ApplyStyleLookup;
      TCanvasManager.MeasureCanvas.Font.Assign(LItem.ResultingTextSettings.Font);
      LWidth := Max(LWidth, TCanvasManager.MeasureCanvas.TextWidth(LItem.Text) + C_MENU_TEXT_SPACE);
    end;
  end;

  FMenuCalendar.Visible := False;
  FMenuList.Visible := True;
  FMenuPopup.PlacementTarget := AEditor;
  FMenuPopup.Width := Min(LWidth, Max(AEditor.Width, C_MENU_MAX_WIDTH));
  FMenuPopup.Height := Min(LHeight + C_MENU_BORDER, C_MENU_MAX_HEIGHT);
  ApplyMenuStyle;
  FMenuPopup.Popup;
end;

procedure TS4YStyledGrid.UpdateCheckAlignment;
var
  LPair: TPair<TColumn, TControl>;
begin
  // The box of a check column in the place of the boxes of its cells.
  for LPair in FEditors do
    if LPair.Value is TS4YGridCheckFilterEditor then
      TS4YGridCheckFilterEditor(LPair.Value).HorzAlign := LPair.Key.HorzAlign;
end;

procedure TS4YStyledGrid.UpdateFilterButton;
var
  LShown: Boolean;
  LSize: Single;
begin
  if not Assigned(FFilterButton) or not Assigned(FHeader) then
    Exit;

  // Square, as high as the header, on its right side: the header leaves the space for it.
  LShown := Model.FilterRow.ShowButton and FHeader.Visible;
  LSize := FHeader.Height;
  FFilterButton.Visible := LShown;

  if LShown then
    FHeader.Margins.Right := LSize
  else
    FHeader.Margins.Right := 0;

  if not LShown then
    Exit;

  FFilterButton.SetBounds(FHeader.Position.X + FHeader.Width, FHeader.Position.Y, LSize, LSize);
  FFilterButton.IsPressed := Model.FilterRow.Visible;
  FFilterButton.BringToFront;
end;

procedure TS4YStyledGrid.UpdateFilterRow;
var
  LShowing: Boolean;
  LPair: TPair<TColumn, TControl>;
begin
  if not Assigned(FFilterRow) then
    Exit;

  LShowing := not FFilterRow.Visible and Model.FilterRow.Visible;
  FFilterRow.Visible := Model.FilterRow.Visible;
  FFilterRow.Height := GetFilterRowHeight;

  for var LEditor in FEditors.Values do
  begin
    ApplyEditorStyle(LEditor);

    if LEditor is TS4YGridTextFilterEditor then
      TS4YGridTextFilterEditor(LEditor).ShowMenuButton := Model.FilterRow.ShowMenuButton;
  end;

  // The part content is now smaller or larger: the cells of the grid are placed in it again.
  RealignContent;
  RemoveOldEditors;
  UpdateFilterRowCells;

  // Shown again: the editors show their filters, which did not apply while the row was hidden.
  if LShowing then
    for LPair in FEditors do
      ShowEditorFilter(LPair.Key, LPair.Value);
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
