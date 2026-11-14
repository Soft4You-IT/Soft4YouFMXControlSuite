unit Soft4You.FMX.Controls.Grid;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YGrid - grid with a filter row under the header
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  FMX.Controls,
  FMX.Controls.Model,
  FMX.Grid,
  Soft4You.FMX.Controls.Grid.Types;

const
  /// <summary>Message of the model to the presentation: the settings of the filter row or of the columns changed.</summary>
  MM_S4Y_GRID_FILTER_ROW_CHANGED = MM_GRID_USER + 1;
  /// <summary>Message of the model to the presentation: the filter value of a column changed.</summary>
  MM_S4Y_GRID_FILTER_VALUE_CHANGED = MM_GRID_USER + 2;
  /// <summary>Message of the model to the presentation: the settings of the columns changed.</summary>
  MM_S4Y_GRID_COLUMN_SETTINGS_CHANGED = MM_GRID_USER + 3;

type
  TS4YGridModel = class;

  /// <summary>
  /// The settings of the filter row of TS4YGrid, the row of editors under the header.
  /// </summary>
  TS4YGridFilterRow = class(TPersistent)
  public const
    /// <summary>Default value of FilterDelay, in milliseconds.</summary>
    C_DEFAULT_FILTER_DELAY = 400;
    /// <summary>Default value of Height: automatic.</summary>
    C_DEFAULT_HEIGHT = 0;
  private
    FAutoFilter: Boolean;
    FClearOnHide: Boolean;
    FFilterDelay: Integer;
    FHeight: Integer;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    procedure Changed;
    procedure SetAutoFilter(const Value: Boolean);
    procedure SetClearOnHide(const Value: Boolean);
    procedure SetFilterDelay(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
  public
    /// <summary>Creates the settings with the default values.</summary>
    constructor Create;

    /// <summary>Copies the settings from another filter row.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>
    /// True fires OnFilter by itself when the user stops typing in an editor of text, number or date for FilterDelay
    /// milliseconds. The default is False: the user filters with Enter.
    /// </summary>
    /// <remarks>
    /// Each key starts the wait again, so the data are not filtered at each key. Enter, Esc, a choice in a drop-down
    /// list and a click on a check box filter at once, also when AutoFilter is False.
    /// </remarks>
    property AutoFilter: Boolean read FAutoFilter write SetAutoFilter default False;
    /// <summary>
    /// True clears the filters when the filter row is hidden, and asks the application to filter again with OnFilter.
    /// The default is False: the filters stay, and are shown again with the row.
    /// </summary>
    property ClearOnHide: Boolean read FClearOnHide write SetClearOnHide default False;
    /// <summary>
    /// Milliseconds without typing after which AutoFilter fires OnFilter. The default is 400; 0 fires it at each
    /// change.
    /// </summary>
    property FilterDelay: Integer read FFilterDelay write SetFilterDelay default C_DEFAULT_FILTER_DELAY;
    /// <summary>
    /// Height of the filter row, in pixels; 0, the default, is automatic: the height of the editors, at least the
    /// height of the rows of the grid.
    /// </summary>
    property Height: Integer read FHeight write SetHeight default C_DEFAULT_HEIGHT;
    /// <summary>True shows the filter row under the header. The default is False.</summary>
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

  /// <summary>
  /// The settings of TS4YGrid for one of its columns.
  /// </summary>
  TS4YGridColumnSetting = class(TCollectionItem)
  public const
    /// <summary>Default value of Filterable.</summary>
    C_DEFAULT_FILTERABLE = True;
  private
    FColumn: TColumn;
    FFilterable: Boolean;
    FFilterItems: TStrings;
    procedure FilterItemsChange(Sender: TObject);
    function FilterItemsStored: Boolean;
    procedure SetColumn(const Value: TColumn);
    procedure SetFilterable(const Value: Boolean);
    procedure SetFilterItems(const Value: TStrings);
  protected
    /// <summary>Returns the name of the column, for the editor of the collection.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates the settings of no column, with the default values.</summary>
    constructor Create(Collection: TCollection); override;
    /// <summary>Destroys the settings.</summary>
    destructor Destroy; override;

    /// <summary>Copies the settings from another item.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>The column of the grid these settings are for.</summary>
    property Column: TColumn read FColumn write SetColumn;
    /// <summary>True shows the editor of the filter of the column in the filter row. The default is True.</summary>
    property Filterable: Boolean read FFilterable write SetFilterable default C_DEFAULT_FILTERABLE;
    /// <summary>
    /// The values the user can choose as filter of the column: when there are some, the editor of the column is a
    /// drop-down list with them, whatever the type of the column. Empty by default.
    /// </summary>
    property FilterItems: TStrings read FFilterItems write SetFilterItems stored FilterItemsStored;
  end;

  /// <summary>
  /// The settings of TS4YGrid for its columns: a column without an item has the default settings.
  /// </summary>
  TS4YGridColumnSettings = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    function GetItem(const AIndex: Integer): TS4YGridColumnSetting;
    procedure SetItem(const AIndex: Integer; const Value: TS4YGridColumnSetting);
  protected
    /// <summary>Fires OnChange.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the collection of the settings of the columns of AOwner.</summary>
    constructor Create(const AOwner: TPersistent);

    /// <summary>Adds the settings of AColumn, with the default values.</summary>
    function Add(const AColumn: TColumn): TS4YGridColumnSetting; overload;
    /// <summary>Returns the settings of AColumn, or nil when the column has none.</summary>
    function FindColumn(const AColumn: TColumn): TS4YGridColumnSetting;
    /// <summary>Returns the FilterItems of AColumn, or nil when it has none.</summary>
    function GetFilterItems(const AColumn: TColumn): TStrings;
    /// <summary>Returns True when the filter of AColumn is shown in the filter row.</summary>
    function IsFilterable(const AColumn: TColumn): Boolean;

    /// <summary>The settings, by position.</summary>
    property Items[const AIndex: Integer]: TS4YGridColumnSetting read GetItem write SetItem; default;

    /// <summary>Fires when an item is added, removed or changed.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  /// <summary>
  /// The model of TS4YGrid: the settings of the filter row and of the columns, and the filter values.
  /// </summary>
  TS4YGridModel = class(TGridModel)
  private
    FColumnSettings: TS4YGridColumnSettings;
    FFilterRow: TS4YGridFilterRow;
    FFilterValues: TDictionary<TColumn, TValue>;
    FOnCreateFilterEditor: TS4YGridCreateFilterEditorEvent;
    FOnFilter: TNotifyEvent;
    FOnFilterChanged: TS4YGridColumnEvent;
    procedure ColumnSettingsChange(Sender: TObject);
    procedure FilterRowChange(Sender: TObject);
    procedure SetColumnSettings(const Value: TS4YGridColumnSettings);
    procedure SetFilterRow(const Value: TS4YGridFilterRow);
  protected
    /// <summary>Forgets the filter of a column removed from the grid.</summary>
    procedure DoColumnRemoved(const Column: TColumn); override;
    /// <summary>Fires OnFilterChanged.</summary>
    procedure DoFilterChanged(const AColumn: TColumn); virtual;
  public
    /// <summary>Creates the model of the grid AOwner.</summary>
    constructor Create(const AOwner: TComponent); override;
    /// <summary>Destroys the model.</summary>
    destructor Destroy; override;

    /// <summary>Clears the filters of all the columns, firing OnFilterChanged for each one that had a filter.</summary>
    procedure ClearFilters;
    /// <summary>Fires OnFilter: the application filters its data with the filter values.</summary>
    procedure Filter;
    /// <summary>Returns the filter value of AColumn: an empty value when the column has no filter.</summary>
    function GetFilterValue(const AColumn: TColumn): TValue;
    /// <summary>Returns True when at least one column has a filter.</summary>
    function IsFiltered: Boolean;
    /// <summary>Sets the filter value of AColumn and shows it in its editor; an empty value removes the filter.</summary>
    procedure SetFilterValue(const AColumn: TColumn; const AValue: TValue);

    /// <summary>The settings of the columns.</summary>
    property ColumnSettings: TS4YGridColumnSettings read FColumnSettings write SetColumnSettings;
    /// <summary>The settings of the filter row.</summary>
    property FilterRow: TS4YGridFilterRow read FFilterRow write SetFilterRow;

    /// <summary>Lets the application give the editor of the filter of a column.</summary>
    property OnCreateFilterEditor: TS4YGridCreateFilterEditorEvent read FOnCreateFilterEditor write FOnCreateFilterEditor;
    /// <summary>Fires when the application must filter its data: Enter in an editor, or a call to Filter.</summary>
    property OnFilter: TNotifyEvent read FOnFilter write FOnFilter;
    /// <summary>Fires when the filter value of a column changes, in its editor or by code.</summary>
    property OnFilterChanged: TS4YGridColumnEvent read FOnFilterChanged write FOnFilterChanged;
  end;

  /// <summary>
  /// A grid with a filter row under the header: an editor for each column, where the user writes the value to look
  /// for in that column.
  /// </summary>
  /// <remarks>
  /// TS4YGrid is a TGrid: the cells get their values from OnGetValue or from the LiveBindings. The grid does not
  /// filter the data itself: it keeps the filter values and fires OnFilter, and the application filters its data and
  /// sets RowCount again. The filter row takes the look of the style of the grid, from the platform or from a
  /// TStyleBook.
  /// </remarks>
  TS4YGrid = class(TGrid)
  private
    function GetColumnSettings: TS4YGridColumnSettings;
    function GetFilterRow: TS4YGridFilterRow;
    function GetFilterValue(const AColumn: TColumn): TValue;
    function GetModel: TS4YGridModel; overload;
    function GetOnCreateFilterEditor: TS4YGridCreateFilterEditorEvent;
    function GetOnFilter: TNotifyEvent;
    function GetOnFilterChanged: TS4YGridColumnEvent;
    procedure SetColumnSettings(const Value: TS4YGridColumnSettings);
    procedure SetFilterRow(const Value: TS4YGridFilterRow);
    procedure SetFilterValue(const AColumn: TColumn; const Value: TValue);
    procedure SetOnCreateFilterEditor(const Value: TS4YGridCreateFilterEditorEvent);
    procedure SetOnFilter(const Value: TNotifyEvent);
    procedure SetOnFilterChanged(const Value: TS4YGridColumnEvent);
  protected
    /// <summary>Returns the class of the model of the grid, TS4YGridModel.</summary>
    function DefineModelClass: TDataModelClass; override;
    /// <summary>Forgets the settings of a column that is freed.</summary>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    /// <summary>Clears the filters of all the columns, firing OnFilterChanged for each one that had a filter.</summary>
    procedure ClearFilters;
    /// <summary>Fires OnFilter: the application filters its data with the filter values.</summary>
    procedure Filter;
    /// <summary>Returns True when at least one column has a filter.</summary>
    function IsFiltered: Boolean;

    /// <summary>
    /// The filter value of AColumn: an empty value when the column has no filter.
    /// </summary>
    /// <remarks>
    /// The value has the type of the column: a string for a text column, an Int64 for an integer column, a Double for
    /// a decimal or currency column, a TDate for a date column, a Boolean for a check column. Setting it shows the
    /// value in the editor and fires OnFilterChanged, not OnFilter.
    /// </remarks>
    property FilterValue[const AColumn: TColumn]: TValue read GetFilterValue write SetFilterValue;
    /// <summary>The model of the grid.</summary>
    property Model: TS4YGridModel read GetModel;
  published
    /// <summary>The settings of the columns, such as Filterable; a column without an item has the default settings.</summary>
    property ColumnSettings: TS4YGridColumnSettings read GetColumnSettings write SetColumnSettings;
    /// <summary>The settings of the filter row, the row of editors under the header.</summary>
    property FilterRow: TS4YGridFilterRow read GetFilterRow write SetFilterRow;

    /// <summary>
    /// Lets the application give the editor of the filter of a column, instead of the one the grid creates from the
    /// type of the column.
    /// </summary>
    property OnCreateFilterEditor: TS4YGridCreateFilterEditorEvent read GetOnCreateFilterEditor
      write SetOnCreateFilterEditor;
    /// <summary>
    /// Fires when the application must filter its data with the filter values: Enter in an editor of the filter row,
    /// a click on a check box of the filter row, or a call to Filter.
    /// </summary>
    property OnFilter: TNotifyEvent read GetOnFilter write SetOnFilter;
    /// <summary>Fires when the filter value of a column changes, in its editor or by code.</summary>
    property OnFilterChanged: TS4YGridColumnEvent read GetOnFilterChanged write SetOnFilterChanged;
  end;

implementation

uses
  System.SysUtils,
  Soft4You.FMX.Controls.Grid.Style;

{ TS4YGridFilterRow }

constructor TS4YGridFilterRow.Create;
begin
  inherited;

  FFilterDelay := C_DEFAULT_FILTER_DELAY;
end;

procedure TS4YGridFilterRow.Assign(Source: TPersistent);
var
  LSource: TS4YGridFilterRow;
begin
  if Source is TS4YGridFilterRow then
  begin
    LSource := TS4YGridFilterRow(Source);
    FAutoFilter := LSource.AutoFilter;
    FClearOnHide := LSource.ClearOnHide;
    FFilterDelay := LSource.FilterDelay;
    FHeight := LSource.Height;
    FVisible := LSource.Visible;
    Changed;
  end
  else
    inherited;
end;

procedure TS4YGridFilterRow.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YGridFilterRow.SetAutoFilter(const Value: Boolean);
begin
  if FAutoFilter = Value then
    Exit;

  FAutoFilter := Value;
  Changed;
end;

procedure TS4YGridFilterRow.SetClearOnHide(const Value: Boolean);
begin
  if FClearOnHide = Value then
    Exit;

  FClearOnHide := Value;
  Changed;
end;

procedure TS4YGridFilterRow.SetFilterDelay(const Value: Integer);
begin
  if FFilterDelay = Value then
    Exit;

  if Value < 0 then
    FFilterDelay := 0
  else
    FFilterDelay := Value;

  Changed;
end;

procedure TS4YGridFilterRow.SetHeight(const Value: Integer);
begin
  if FHeight = Value then
    Exit;

  if Value < 0 then
    FHeight := 0
  else
    FHeight := Value;

  Changed;
end;

procedure TS4YGridFilterRow.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;
  Changed;
end;

{ TS4YGridColumnSetting }

constructor TS4YGridColumnSetting.Create(Collection: TCollection);
begin
  inherited;

  FFilterable := C_DEFAULT_FILTERABLE;
  FFilterItems := TStringList.Create;
  TStringList(FFilterItems).OnChange := FilterItemsChange;
end;

destructor TS4YGridColumnSetting.Destroy;
begin
  FFilterItems.Free;

  inherited;
end;

procedure TS4YGridColumnSetting.Assign(Source: TPersistent);
var
  LSource: TS4YGridColumnSetting;
begin
  if Source is TS4YGridColumnSetting then
  begin
    LSource := TS4YGridColumnSetting(Source);
    Column := LSource.Column;
    FFilterable := LSource.Filterable;
    FFilterItems.Assign(LSource.FilterItems);
    Changed(False);
  end
  else
    inherited;
end;

procedure TS4YGridColumnSetting.FilterItemsChange(Sender: TObject);
begin
  Changed(False);
end;

function TS4YGridColumnSetting.FilterItemsStored: Boolean;
begin
  Result := FFilterItems.Count > 0;
end;

function TS4YGridColumnSetting.GetDisplayName: string;
begin
  if Assigned(FColumn) then
    Result := FColumn.Name
  else
    Result := inherited;
end;

procedure TS4YGridColumnSetting.SetColumn(const Value: TColumn);
var
  LOwner: TPersistent;
begin
  if FColumn = Value then
    Exit;

  FColumn := Value;

  // The grid is told when the column is freed, to forget it.
  LOwner := TS4YGridColumnSettings(Collection).Owner;

  if Assigned(FColumn) and (LOwner is TComponent) then
    FColumn.FreeNotification(TComponent(LOwner));

  Changed(False);
end;

procedure TS4YGridColumnSetting.SetFilterItems(const Value: TStrings);
begin
  FFilterItems.Assign(Value);
end;

procedure TS4YGridColumnSetting.SetFilterable(const Value: Boolean);
begin
  if FFilterable = Value then
    Exit;

  FFilterable := Value;
  Changed(False);
end;

{ TS4YGridColumnSettings }

constructor TS4YGridColumnSettings.Create(const AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YGridColumnSetting);
end;

function TS4YGridColumnSettings.Add(const AColumn: TColumn): TS4YGridColumnSetting;
begin
  Result := TS4YGridColumnSetting(inherited Add);
  Result.Column := AColumn;
end;

function TS4YGridColumnSettings.FindColumn(const AColumn: TColumn): TS4YGridColumnSetting;
var
  LIndex: Integer;
begin
  Result := nil;
  LIndex := 0;

  while not Assigned(Result) and (LIndex < Count) do
  begin
    if Assigned(AColumn) and (Items[LIndex].Column = AColumn) then
      Result := Items[LIndex];

    Inc(LIndex);
  end;
end;

function TS4YGridColumnSettings.GetFilterItems(const AColumn: TColumn): TStrings;
var
  LSetting: TS4YGridColumnSetting;
begin
  LSetting := FindColumn(AColumn);

  if Assigned(LSetting) and (LSetting.FilterItems.Count > 0) then
    Result := LSetting.FilterItems
  else
    Result := nil;
end;

function TS4YGridColumnSettings.GetItem(const AIndex: Integer): TS4YGridColumnSetting;
begin
  Result := TS4YGridColumnSetting(inherited Items[AIndex]);
end;

function TS4YGridColumnSettings.IsFilterable(const AColumn: TColumn): Boolean;
var
  LSetting: TS4YGridColumnSetting;
begin
  LSetting := FindColumn(AColumn);

  if Assigned(LSetting) then
    Result := LSetting.Filterable
  else
    Result := TS4YGridColumnSetting.C_DEFAULT_FILTERABLE;
end;

procedure TS4YGridColumnSettings.SetItem(const AIndex: Integer; const Value: TS4YGridColumnSetting);
begin
  inherited Items[AIndex] := Value;
end;

procedure TS4YGridColumnSettings.Update(Item: TCollectionItem);
begin
  inherited;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TS4YGridModel }

constructor TS4YGridModel.Create(const AOwner: TComponent);
begin
  inherited;

  FFilterValues := TDictionary<TColumn, TValue>.Create;
  FFilterRow := TS4YGridFilterRow.Create;
  FFilterRow.OnChange := FilterRowChange;
  // The collection is owned by the grid, so that the Object Inspector and the form find it.
  FColumnSettings := TS4YGridColumnSettings.Create(AOwner);
  FColumnSettings.OnChange := ColumnSettingsChange;
end;

destructor TS4YGridModel.Destroy;
begin
  FColumnSettings.OnChange := nil;
  FFilterRow.OnChange := nil;
  FColumnSettings.Free;
  FFilterRow.Free;
  FFilterValues.Free;

  inherited;
end;

procedure TS4YGridModel.ClearFilters;
var
  LColumns: TArray<TColumn>;
begin
  // The keys are copied: the dictionary changes while the filters are cleared.
  LColumns := FFilterValues.Keys.ToArray;

  for var I := 0 to High(LColumns) do
    SetFilterValue(LColumns[I], TValue.Empty);
end;

procedure TS4YGridModel.ColumnSettingsChange(Sender: TObject);
begin
  SendMessage(MM_S4Y_GRID_COLUMN_SETTINGS_CHANGED);
end;

procedure TS4YGridModel.DoColumnRemoved(const Column: TColumn);
begin
  FFilterValues.Remove(Column);

  inherited;

  SendMessage(MM_S4Y_GRID_FILTER_ROW_CHANGED);
end;

procedure TS4YGridModel.DoFilterChanged(const AColumn: TColumn);
begin
  if Assigned(FOnFilterChanged) then
    FOnFilterChanged(Owner, AColumn);
end;

procedure TS4YGridModel.Filter;
begin
  if Assigned(FOnFilter) then
    FOnFilter(Owner);
end;

procedure TS4YGridModel.FilterRowChange(Sender: TObject);
begin
  // A hidden row with ClearOnHide does not filter anymore: the application shows all the data again.
  if not FFilterRow.Visible and FFilterRow.ClearOnHide and IsFiltered then
  begin
    ClearFilters;
    Filter;
  end;

  SendMessage(MM_S4Y_GRID_FILTER_ROW_CHANGED);
end;

function TS4YGridModel.GetFilterValue(const AColumn: TColumn): TValue;
begin
  if not FFilterValues.TryGetValue(AColumn, Result) then
    Result := TValue.Empty;
end;

function TS4YGridModel.IsFiltered: Boolean;
begin
  Result := FFilterValues.Count > 0;
end;

procedure TS4YGridModel.SetColumnSettings(const Value: TS4YGridColumnSettings);
begin
  FColumnSettings.Assign(Value);
end;

procedure TS4YGridModel.SetFilterRow(const Value: TS4YGridFilterRow);
begin
  FFilterRow.Assign(Value);
end;

procedure TS4YGridModel.SetFilterValue(const AColumn: TColumn; const AValue: TValue);
begin
  if not Assigned(AColumn) then
    Exit;

  // An empty value removes the filter; a column without filter that stays without filter changes nothing.
  if AValue.IsEmpty then
  begin
    if not FFilterValues.ContainsKey(AColumn) then
      Exit;

    FFilterValues.Remove(AColumn);
  end
  else
    FFilterValues.AddOrSetValue(AColumn, AValue);

  SendMessage<TColumn>(MM_S4Y_GRID_FILTER_VALUE_CHANGED, AColumn);
  DoFilterChanged(AColumn);
end;

{ TS4YGrid }

procedure TS4YGrid.ClearFilters;
begin
  Model.ClearFilters;
end;

function TS4YGrid.DefineModelClass: TDataModelClass;
begin
  Result := TS4YGridModel;
end;

procedure TS4YGrid.Filter;
begin
  Model.Filter;
end;

function TS4YGrid.GetColumnSettings: TS4YGridColumnSettings;
begin
  Result := Model.ColumnSettings;
end;

function TS4YGrid.GetFilterRow: TS4YGridFilterRow;
begin
  Result := Model.FilterRow;
end;

function TS4YGrid.GetFilterValue(const AColumn: TColumn): TValue;
begin
  Result := Model.GetFilterValue(AColumn);
end;

function TS4YGrid.GetModel: TS4YGridModel;
begin
  Result := GetModel<TS4YGridModel>;
end;

function TS4YGrid.GetOnCreateFilterEditor: TS4YGridCreateFilterEditorEvent;
begin
  Result := Model.OnCreateFilterEditor;
end;

function TS4YGrid.GetOnFilter: TNotifyEvent;
begin
  Result := Model.OnFilter;
end;

function TS4YGrid.GetOnFilterChanged: TS4YGridColumnEvent;
begin
  Result := Model.OnFilterChanged;
end;

function TS4YGrid.IsFiltered: Boolean;
begin
  Result := Model.IsFiltered;
end;

procedure TS4YGrid.Notification(AComponent: TComponent; Operation: TOperation);
var
  LSetting: TS4YGridColumnSetting;
begin
  inherited;

  if (Operation = opRemove) and (AComponent is TColumn) and Assigned(Model) then
  begin
    LSetting := Model.ColumnSettings.FindColumn(TColumn(AComponent));

    if Assigned(LSetting) then
      LSetting.Column := nil;
  end;
end;

procedure TS4YGrid.SetColumnSettings(const Value: TS4YGridColumnSettings);
begin
  Model.ColumnSettings := Value;
end;

procedure TS4YGrid.SetFilterRow(const Value: TS4YGridFilterRow);
begin
  Model.FilterRow := Value;
end;

procedure TS4YGrid.SetFilterValue(const AColumn: TColumn; const Value: TValue);
begin
  Model.SetFilterValue(AColumn, Value);
end;

procedure TS4YGrid.SetOnCreateFilterEditor(const Value: TS4YGridCreateFilterEditorEvent);
begin
  Model.OnCreateFilterEditor := Value;
end;

procedure TS4YGrid.SetOnFilter(const Value: TNotifyEvent);
begin
  Model.OnFilter := Value;
end;

procedure TS4YGrid.SetOnFilterChanged(const Value: TS4YGridColumnEvent);
begin
  Model.OnFilterChanged := Value;
end;

end.
