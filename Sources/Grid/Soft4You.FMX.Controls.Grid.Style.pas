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
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Controls.Model,
  FMX.Graphics,
  FMX.Objects,
  FMX.Presentation.Messages,
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
    procedure SetLineBrush(const Value: TBrush);
  protected
    /// <summary>Draws the line on the bottom side.</summary>
    procedure Paint; override;
  public
    /// <summary>Creates an empty row.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>The brush of the line, from the style of the grid; nil draws no line. The row does not own it.</summary>
    property LineBrush: TBrush read FLineBrush write SetLineBrush;
  end;

  /// <summary>
  /// The styled presentation of TS4YGrid: the presentation of TGrid, with the filter row inserted under the header of
  /// the style of the grid.
  /// </summary>
  /// <remarks>
  /// The filter row is added to the part background of the style, aligned to the top after the header, so the cells
  /// of the grid start under it; its cells follow the width, the order, the visibility and the horizontal scroll of
  /// the columns. A part filterrowbackground in the style of the grid becomes the background of the row.
  /// </remarks>
  TS4YStyledGrid = class(TStyledGrid)
  private
    FAutoFilterTimer: TTimer;
    FBackground: TControl;
    FContentPart: TControl;
    FEditors: TDictionary<TColumn, TControl>;
    FFilterRow: TS4YGridBand;
    FLineFill: TBrushObject;
    FUpdatingFromEditor: Boolean;
    procedure AutoFilterTimer(Sender: TObject);
    function CreateFilterEditor(const AColumn: TColumn): TControl;
    procedure FreeEditors;
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
    procedure RemoveOldEditors;
    procedure UpdateFilterRow;
    procedure UpdateFilterRowCells;
  protected
    /// <summary>Inserts the filter row in the style of the grid.</summary>
    procedure ApplyStyle; override;
    /// <summary>Returns the class of the model of the grid, TS4YGridModel.</summary>
    function DefineModelClass: TDataModelClass; override;
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
  System.Rtti,
  System.UITypes,
  FMX.Presentation.Factory,
  FMX.Presentation.Style,
  Soft4You.FMX.Controls.Grid.Types,
  Soft4You.FMX.Controls.Grid.FilterEditors;

resourcestring
  S_FILTER_EDITOR_INTERFACE = 'The filter editor of the column %s does not implement IS4YGridFilterEditor';

const
  C_STYLE_BACKGROUND = 'background';
  C_STYLE_CONTENT = 'content';
  C_STYLE_FILTER_ROW_BACKGROUND = 'filterrowbackground';
  C_STYLE_LINE_FILL = 'linefill';

  // Space between the editors and the sides of their cell, in pixels.
  C_EDITOR_MARGIN = 2;
  // Height of an editor in the automatic height of the filter row: the height of a TEdit.
  C_EDITOR_HEIGHT = 22;

{ TS4YGridBand }

constructor TS4YGridBand.Create(AOwner: TComponent);
begin
  inherited;

  HitTest := False;
  ClipChildren := True;
end;

procedure TS4YGridBand.Paint;
var
  LY: Single;
begin
  if not Assigned(FLineBrush) then
    Exit;

  // The line in the middle of the last pixel, as the lines of the rows of the grid.
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

{ TS4YStyledGrid }

constructor TS4YStyledGrid.Create(AOwner: TComponent);
begin
  inherited;

  FEditors := TDictionary<TColumn, TControl>.Create;
  FAutoFilterTimer := TTimer.Create(nil);
  FAutoFilterTimer.Enabled := False;
  FAutoFilterTimer.OnTimer := AutoFilterTimer;
end;

destructor TS4YStyledGrid.Destroy;
begin
  FAutoFilterTimer.Free;
  FEditors.Free;

  inherited;
end;

procedure TS4YStyledGrid.ApplyStyle;
var
  LRowBackground: TControl;
begin
  inherited;

  FBackground := nil;
  FContentPart := nil;
  FLineFill := nil;

  // Without the part background the style has no place for the filter row.
  if not FindStyleResource<TControl>(C_STYLE_BACKGROUND, FBackground) then
    Exit;

  FindStyleResource<TControl>(C_STYLE_CONTENT, FContentPart);
  FindStyleResource<TBrushObject>(C_STYLE_LINE_FILL, FLineFill);

  // Added after the header, both aligned to the top: the row goes under it.
  FFilterRow := TS4YGridBand.Create(nil);
  FFilterRow.Stored := False;
  FFilterRow.Locked := True;
  FFilterRow.Align := TAlignLayout.Top;
  FFilterRow.Parent := FBackground;

  if Assigned(FLineFill) then
    FFilterRow.LineBrush := FLineFill.Brush;

  if FindStyleResource<TControl>(C_STYLE_FILTER_ROW_BACKGROUND, LRowBackground) then
  begin
    LRowBackground.Parent := FFilterRow;
    LRowBackground.Align := TAlignLayout.Contents;
    LRowBackground.HitTest := False;
    LRowBackground.Visible := True;
  end;

  UpdateFilterRow;
end;

procedure TS4YStyledGrid.AutoFilterTimer(Sender: TObject);
begin
  FAutoFilterTimer.Enabled := False;
  Model.Filter;
end;

function TS4YStyledGrid.CreateFilterEditor(const AColumn: TColumn): TControl;
var
  LEditor: IS4YGridFilterEditor;
  LItems: TStrings;
begin
  Result := nil;
  LItems := Model.ColumnSettings.GetFilterItems(AColumn);

  if not Assigned(LItems) and (AColumn is TPopupColumn) then
    LItems := TPopupColumn(AColumn).Items;

  if Assigned(Model.OnCreateFilterEditor) then
    Model.OnCreateFilterEditor(Model.Owner, AColumn, Result);

  // The list of values comes before the type of the column.
  if Assigned(Result) then
  begin
    if not Supports(Result, IS4YGridFilterEditor) then
      raise EArgumentException.CreateFmt(S_FILTER_EDITOR_INTERFACE, [AColumn.Name]);
  end
  else if Assigned(LItems) then
  begin
    Result := TS4YGridListFilterEditor.Create(nil);
    TS4YGridListFilterEditor(Result).SetFilterItems(LItems);
  end
  else if AColumn is TIntegerColumn then
    Result := TS4YGridNumberFilterEditor.Create(nil)
  else if (AColumn is TFloatColumn) or (AColumn is TCurrencyColumn) then
  begin
    Result := TS4YGridNumberFilterEditor.Create(nil);
    TS4YGridNumberFilterEditor(Result).NumberKind := gnkFloat;
  end
  else if AColumn is TDateColumn then
    Result := TS4YGridDateFilterEditor.Create(nil)
  else if AColumn is TCheckColumn then
    Result := TS4YGridCheckFilterEditor.Create(nil)
  else
    Result := TS4YGridTextFilterEditor.Create(nil);

  Result.Stored := False;
  Result.Parent := FFilterRow;
  Supports(Result, IS4YGridFilterEditor, LEditor);
  LEditor.SetFilterValue(Model.GetFilterValue(AColumn));
  LEditor.SetOnFilterValueChange(EditorFilterValueChange);
  LEditor.SetOnFilterSubmit(EditorFilterSubmit);
end;

function TS4YStyledGrid.DefineModelClass: TDataModelClass;
begin
  Result := TS4YGridModel;
end;

procedure TS4YStyledGrid.DoViewportPositionChange(const OldViewportPosition, NewViewportPosition: TPointF;
  const ContentSizeChanged: Boolean);
begin
  inherited;

  UpdateFilterRowCells;
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

  // The editor already shows the value: the model does not send it back.
  FUpdatingFromEditor := True;
  try
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
  FBackground := nil;
  FContentPart := nil;
  FLineFill := nil;

  inherited;
end;

function TS4YStyledGrid.GetFilterRowHeight: Single;
begin
  if Model.FilterRow.Height > 0 then
    Result := Model.FilterRow.Height
  else
    Result := Max(RowHeight, C_EDITOR_HEIGHT + 2 * C_EDITOR_MARGIN + 1);
end;

function TS4YStyledGrid.GetModel: TS4YGridModel;
begin
  Result := TS4YGridModel(inherited Model);
end;

procedure TS4YStyledGrid.MMColumnChanged(var Message: TDispatchMessageWithValue<Integer>);
begin
  inherited;

  UpdateFilterRowCells;
end;

procedure TS4YStyledGrid.MMColumnMoved(var Message: TDispatchMessageWithValue<TGridModel.TColumnIndexes>);
begin
  inherited;

  UpdateFilterRowCells;
end;

procedure TS4YStyledGrid.MMColumnSettingsChanged(var Message: TDispatchMessage);
begin
  // The editors are created again, with the new lists of values; the filter values stay in the model.
  FreeEditors;
  UpdateFilterRow;
end;

procedure TS4YStyledGrid.MMContentChanged(var Message: TDispatchMessage);
begin
  inherited;

  UpdateFilterRow;
end;

procedure TS4YStyledGrid.MMFilterRowChanged(var Message: TDispatchMessage);
begin
  UpdateFilterRow;
end;

procedure TS4YStyledGrid.MMFilterValueChanged(var Message: TDispatchMessageWithValue<TColumn>);
var
  LEditor: TControl;
  LFilterEditor: IS4YGridFilterEditor;
begin
  if FUpdatingFromEditor then
    Exit;

  if FEditors.TryGetValue(Message.Value, LEditor) and Supports(LEditor, IS4YGridFilterEditor, LFilterEditor) then
    LFilterEditor.SetFilterValue(Model.GetFilterValue(Message.Value));
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
  LOffset: Single;
  LShown: Boolean;
begin
  if not Assigned(FFilterRow) or not FFilterRow.Visible then
    Exit;

  // The cells of the grid start at the part content; the row may start elsewhere in the same parent.
  if Assigned(FContentPart) then
    LOffset := FContentPart.Position.X - FFilterRow.Position.X
  else
    LOffset := 0;

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
        LEditor.SetBounds(LRect.Left - ViewportPosition.X + LOffset + C_EDITOR_MARGIN, C_EDITOR_MARGIN,
          LRect.Width - 2 * C_EDITOR_MARGIN, FFilterRow.Height - 2 * C_EDITOR_MARGIN - 1);
      end;
    end;
  end;
end;

initialization
  TPresentationProxyFactory.Current.Register(TS4YGrid, TControlType.Styled, TStyledPresentationProxy<TS4YStyledGrid>);

finalization
  TPresentationProxyFactory.Current.Unregister(TS4YGrid, TControlType.Styled,
    TStyledPresentationProxy<TS4YStyledGrid>);

end.
