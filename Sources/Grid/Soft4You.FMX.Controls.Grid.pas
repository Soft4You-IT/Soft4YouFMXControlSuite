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
  FMX.Types,
  FMX.Controls,
  FMX.Controls.Model,
  FMX.Grid,
  FMX.Menus,
  Soft4You.FMX.Controls.Grid.Types,
  Soft4You.FMX.Controls.Grid.Filters;

const
  /// <summary>Message of the model to the presentation: the settings of the filter row or of the columns changed.</summary>
  MM_S4Y_GRID_FILTER_ROW_CHANGED = MM_GRID_USER + 1;
  /// <summary>Message of the model to the presentation: the filter value of a column changed.</summary>
  MM_S4Y_GRID_FILTER_VALUE_CHANGED = MM_GRID_USER + 2;
  /// <summary>Message of the model to the presentation: the settings of the columns changed.</summary>
  MM_S4Y_GRID_COLUMN_SETTINGS_CHANGED = MM_GRID_USER + 3;
  /// <summary>Message of the model to the presentation: the footer must be calculated and drawn again.</summary>
  MM_S4Y_GRID_FOOTER_CHANGED = MM_GRID_USER + 4;
  /// <summary>Message of the model to the presentation: the order of the rows or its settings changed.</summary>
  MM_S4Y_GRID_SORT_CHANGED = MM_GRID_USER + 5;

type
  TS4YGridModel = class;

  /// <summary>
  /// The settings of the order of the rows of TS4YGrid, chosen with a click on the header of the columns.
  /// </summary>
  TS4YGridSorting = class(TPersistent)
  public const
    /// <summary>Default value of OrderPosition.</summary>
    C_DEFAULT_ORDER_POSITION = gopBefore;
    /// <summary>Default value of OrderSpacing, in pixels.</summary>
    C_DEFAULT_ORDER_SPACING = 3;
  private
    FEnabled: Boolean;
    FMultiColumn: Boolean;
    FOrderPosition: TS4YGridSortOrderPosition;
    FOrderSpacing: Single;
    FShowOrder: Boolean;
    FOnChange: TNotifyEvent;
    procedure Changed;
    function OrderSpacingStored: Boolean;
    procedure SetEnabled(const Value: Boolean);
    procedure SetMultiColumn(const Value: Boolean);
    procedure SetOrderPosition(const Value: TS4YGridSortOrderPosition);
    procedure SetOrderSpacing(const Value: Single);
    procedure SetShowOrder(const Value: Boolean);
  public
    /// <summary>Creates the settings with the default values.</summary>
    constructor Create;

    /// <summary>Copies the settings from another one.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>
    /// True lets the user choose the order of the rows with a click on the header of a column. The default is False.
    /// </summary>
    /// <remarks>
    /// A click sorts by the column, or inverts the direction when the rows are sorted only by it; Shift+click adds the
    /// column as the next key, or inverts its direction; Ctrl+click (Cmd+click on macOS) removes it; Alt+click goes
    /// back to the order of the data. The order set by code is shown also when Enabled is False.
    /// </remarks>
    property Enabled: Boolean read FEnabled write SetEnabled default False;
    /// <summary>True lets Shift+click sort by more than one column. The default is True.</summary>
    property MultiColumn: Boolean read FMultiColumn write SetMultiColumn default True;
    /// <summary>
    /// Where the position of a column in the order is shown, compared to its arrow. The default is gopBefore, on the
    /// left of the arrow.
    /// </summary>
    property OrderPosition: TS4YGridSortOrderPosition read FOrderPosition write SetOrderPosition
      default C_DEFAULT_ORDER_POSITION;
    /// <summary>Space between the position of a column in the order and its arrow, in pixels. The default is 3.</summary>
    property OrderSpacing: Single read FOrderSpacing write SetOrderSpacing stored OrderSpacingStored;
    /// <summary>
    /// True shows the position of each column in the order next to its arrow, when the rows are sorted by more than
    /// one column. The default is True.
    /// </summary>
    property ShowOrder: Boolean read FShowOrder write SetShowOrder default True;
  end;

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
    FCheckBoxStyleLookup: string;
    FClearOnHide: Boolean;
    FEditStyleLookup: string;
    FFilterDelay: Integer;
    FHeight: Integer;
    FMenuStyleLookup: string;
    FShowMenuButton: Boolean;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    procedure Changed;
    procedure SetAutoFilter(const Value: Boolean);
    procedure SetCheckBoxStyleLookup(const Value: string);
    procedure SetClearOnHide(const Value: Boolean);
    procedure SetEditStyleLookup(const Value: string);
    procedure SetFilterDelay(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure SetMenuStyleLookup(const Value: string);
    procedure SetShowMenuButton(const Value: Boolean);
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
    /// Each key starts the wait again, so the data are not filtered at each key. Enter, Esc, a choice in the menu of a
    /// filter and a click on a check box filter at once, also when AutoFilter is False.
    /// </remarks>
    property AutoFilter: Boolean read FAutoFilter write SetAutoFilter default False;
    /// <summary>
    /// The name of the style of the check boxes of the filter row, looked for in the style book of the form and in the
    /// style of the platform. Empty by default: checkcellstyle, the style of the check boxes of the cells of the grid,
    /// or checkboxstyle, the style of TCheckBox, when it is not found.
    /// </summary>
    property CheckBoxStyleLookup: string read FCheckBoxStyleLookup write SetCheckBoxStyleLookup;
    /// <summary>
    /// True clears the filters when the filter row is hidden, and asks the application to filter again with OnFilter.
    /// The default is False: the filters stay, and are shown again with the row.
    /// </summary>
    property ClearOnHide: Boolean read FClearOnHide write SetClearOnHide default False;
    /// <summary>
    /// The name of the style of the text fields of the filter row, looked for in the style book of the form and in the
    /// style of the platform. Empty by default: editstyle, the style of TEdit.
    /// </summary>
    property EditStyleLookup: string read FEditStyleLookup write SetEditStyleLookup;
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
    /// <summary>
    /// The name of the style of the popup of the menu of the filter, its background and border, looked for in the
    /// style book of the form and in the style of the platform. Empty by default: popupstyle, the style of TPopup.
    /// </summary>
    property MenuStyleLookup: string read FMenuStyleLookup write SetMenuStyleLookup;
    /// <summary>
    /// True shows a button in the text fields of the filter row, which opens the menu of the filter: the operators,
    /// the values and the functions of the column. The default is True.
    /// </summary>
    property ShowMenuButton: Boolean read FShowMenuButton write SetShowMenuButton default True;
    /// <summary>True shows the filter row under the header. The default is False.</summary>
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

  /// <summary>
  /// The settings of the footer of TS4YGrid, the row under the cells with a total, an average or a text for each
  /// column.
  /// </summary>
  TS4YGridFooterRow = class(TPersistent)
  public const
    /// <summary>Default value of Height: the height of the rows of the grid.</summary>
    C_DEFAULT_HEIGHT = 0;
  private
    FHeight: Integer;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    procedure Changed;
    procedure SetHeight(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
  public
    /// <summary>Copies the settings from another footer.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Height of the footer, in pixels; 0, the default, is the height of the rows of the grid.</summary>
    property Height: Integer read FHeight write SetHeight default C_DEFAULT_HEIGHT;
    /// <summary>True shows the footer under the cells. The default is False.</summary>
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

  /// <summary>
  /// The settings of TS4YGrid for one of its columns.
  /// </summary>
  TS4YGridColumnSetting = class(TCollectionItem)
  public const
    /// <summary>Default value of Filterable.</summary>
    C_DEFAULT_FILTERABLE = True;
    /// <summary>Default value of FooterAlignment.</summary>
    C_DEFAULT_FOOTER_ALIGNMENT = TTextAlign.Trailing;
    /// <summary>Default value of Sortable.</summary>
    C_DEFAULT_SORTABLE = True;
  private
    FColumn: TColumn;
    FFilterable: Boolean;
    FFilterItems: TStrings;
    FFilterMenu: TPopupMenu;
    FFooterAlignment: TTextAlign;
    FFooterFormat: string;
    FFooterKind: TS4YGridFooterKind;
    FFooterText: string;
    FSortable: Boolean;
    procedure FilterItemsChange(Sender: TObject);
    function FilterItemsStored: Boolean;
    procedure SetColumn(const Value: TColumn);
    procedure SetFilterable(const Value: Boolean);
    procedure SetFilterItems(const Value: TStrings);
    procedure SetFilterMenu(const Value: TPopupMenu);
    procedure SetFooterAlignment(const Value: TTextAlign);
    procedure SetFooterFormat(const Value: string);
    procedure SetFooterKind(const Value: TS4YGridFooterKind);
    procedure SetFooterText(const Value: string);
    procedure SetSortable(const Value: Boolean);
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
    /// <summary>
    /// A menu of the application for the button of the editor of the filter of the column, instead of the menu of the
    /// grid: the application does what its items do, with FilterText, SetFilter and Filter of the grid.
    /// </summary>
    property FilterMenu: TPopupMenu read FFilterMenu write SetFilterMenu;
    /// <summary>Alignment of the text of the footer in the cell of the column. The default is Trailing.</summary>
    property FooterAlignment: TTextAlign read FFooterAlignment write SetFooterAlignment
      default C_DEFAULT_FOOTER_ALIGNMENT;
    /// <summary>
    /// Format of the value of the footer, as for the Format function of Delphi with the value as its only argument,
    /// for example '%.2f'. Empty by default: the value is written as the column writes its cells.
    /// </summary>
    property FooterFormat: string read FFooterFormat write SetFooterFormat;
    /// <summary>What the footer shows under the column. The default is gfkNone, nothing.</summary>
    property FooterKind: TS4YGridFooterKind read FFooterKind write SetFooterKind default gfkNone;
    /// <summary>The text of the footer under the column when FooterKind is gfkText, for example Total.</summary>
    property FooterText: string read FFooterText write SetFooterText;
    /// <summary>
    /// True lets the user sort the rows by the column with a click on its header, when Sorting.Enabled is True. The
    /// default is True.
    /// </summary>
    property Sortable: Boolean read FSortable write SetSortable default C_DEFAULT_SORTABLE;
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
    /// <summary>Returns True when the user can sort the rows by AColumn.</summary>
    function IsSortable(const AColumn: TColumn): Boolean;

    /// <summary>The settings, by position.</summary>
    property Items[const AIndex: Integer]: TS4YGridColumnSetting read GetItem write SetItem; default;

    /// <summary>Fires when an item is added, removed or changed.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  /// <summary>
  /// The model of TS4YGrid: the settings of the filter row and of the columns, and the filters.
  /// </summary>
  TS4YGridModel = class(TGridModel)
  private
    FColumnSettings: TS4YGridColumnSettings;
    FFilterRow: TS4YGridFilterRow;
    FFilters: TDictionary<TColumn, TS4YGridFilter>;
    FFooterRow: TS4YGridFooterRow;
    FSorting: TS4YGridSorting;
    FSortKeys: TList<TS4YGridSortKey>;
    FOnCreateFilterEditor: TS4YGridCreateFilterEditorEvent;
    FOnFilter: TNotifyEvent;
    FOnFilterChanged: TS4YGridColumnEvent;
    FOnFilterMenu: TS4YGridFilterMenuEvent;
    FOnGetFooterText: TS4YGridFooterTextEvent;
    FOnSort: TNotifyEvent;
    procedure ColumnSettingsChange(Sender: TObject);
    function FormatFooterValue(const AColumn: TColumn; const ASetting: TS4YGridColumnSetting; const AValue: Double;
      const AIsAverage: Boolean): string;
    procedure FilterRowChange(Sender: TObject);
    procedure FooterRowChange(Sender: TObject);
    function GetSortCount: Integer;
    function GetSortKey(const AIndex: Integer): TS4YGridSortKey;
    procedure SetColumnSettings(const Value: TS4YGridColumnSettings);
    procedure SetFilterRow(const Value: TS4YGridFilterRow);
    procedure SetFooterRow(const Value: TS4YGridFooterRow);
    procedure SetSorting(const Value: TS4YGridSorting);
    procedure SortChanged;
    procedure SortingChange(Sender: TObject);
    procedure StoreFilter(const AColumn: TColumn; const AFilter: TS4YGridFilter);
  protected
    /// <summary>Forgets the filter and the key of the order of a column removed from the grid.</summary>
    procedure DoColumnRemoved(const Column: TColumn); override;
    /// <summary>Fires OnFilterChanged.</summary>
    procedure DoFilterChanged(const AColumn: TColumn); virtual;
    /// <summary>Calculates the footer again when the number of rows changes.</summary>
    procedure DoRowCountChanged(const OldValue, NewValue: Integer); override;
    /// <summary>Calculates the footer again when a cell is edited in the grid.</summary>
    procedure DoSetValue(Col, Row: Integer; const Value: TValue); override;
    /// <summary>Fires OnSort.</summary>
    procedure DoSort; virtual;
  public
    /// <summary>Creates the model of the grid AOwner.</summary>
    constructor Create(const AOwner: TComponent); override;
    /// <summary>Destroys the model.</summary>
    destructor Destroy; override;

    /// <summary>
    /// Does what the item AItem of the menu of a filter does: writes its operator or value, the date of today, the
    /// current time, clears the filter, or fires its OnClick. The items gmaCalendar and gmaSeparator do nothing: the
    /// calendar is shown by the menu.
    /// </summary>
    procedure ApplyFilterMenuItem(const AItem: TS4YGridFilterMenuItem);
    /// <summary>
    /// Writes AOperator in the text of the filter of AColumn, before the value already written, as the menu of the
    /// filter: the operator is written also when it is the default one.
    /// </summary>
    procedure ApplyFilterOperator(const AColumn: TColumn; const AOperator: TS4YGridFilterOperator);
    /// <summary>
    /// Writes AValue in the text of the filter of AColumn, after the operator already written, as the menu of the
    /// filter; an operator that cannot be used with a value becomes the default operator.
    /// </summary>
    procedure ApplyFilterValue(const AColumn: TColumn; const AValue: TValue);
    /// <summary>Clears the filters of all the columns, firing OnFilterChanged for each one that had a filter.</summary>
    procedure ClearFilters;
    /// <summary>Fires OnFilter: the application filters its data with the filters.</summary>
    procedure Filter;
    /// <summary>
    /// Returns True when AValue, the value of a row in AColumn, passes the filter of the column; True when the column
    /// has no filter.
    /// </summary>
    function FilterMatches(const AColumn: TColumn; const AValue: TValue): Boolean;
    /// <summary>Returns the filter of AColumn: its text, operator, value and state.</summary>
    function GetFilter(const AColumn: TColumn): TS4YGridFilter;
    /// <summary>Returns the kind of value of the filter of AColumn, from the type of the column.</summary>
    function GetFilterKind(const AColumn: TColumn): TS4YGridFilterValueKind;
    /// <summary>
    /// Fills AItems with the items of the menu of the filter of AColumn: the operators of the column, with the current
    /// one checked, the values of its list, the functions of its type and the item that clears the filter; then fires
    /// OnFilterMenu.
    /// </summary>
    procedure GetFilterMenu(const AColumn: TColumn; const AItems: TS4YGridFilterMenuItems);
    /// <summary>Returns the operator of the filter of AColumn; gfoNone when the column has no filter text.</summary>
    function GetFilterOperator(const AColumn: TColumn): TS4YGridFilterOperator;
    /// <summary>Returns the state of the text of the filter of AColumn.</summary>
    function GetFilterState(const AColumn: TColumn): TS4YGridFilterState;
    /// <summary>Returns the text of the filter of AColumn, as it is written.</summary>
    function GetFilterText(const AColumn: TColumn): string;
    /// <summary>Returns the filter value of AColumn: an empty value when the filter is not applied.</summary>
    function GetFilterValue(const AColumn: TColumn): TValue;
    /// <summary>Returns True when at least one column has a filter that is applied.</summary>
    function IsFiltered: Boolean;
    /// <summary>
    /// Sets the filter of AColumn to AOperator and AValue and shows its text in the editor; gfoNone removes the filter.
    /// </summary>
    procedure SetFilter(const AColumn: TColumn; const AOperator: TS4YGridFilterOperator; const AValue: TValue);
    /// <summary>Sets the text of the filter of AColumn, read with the syntax of the filters, and shows it in the editor.</summary>
    procedure SetFilterText(const AColumn: TColumn; const AText: string);
    /// <summary>
    /// Sets the filter of AColumn to AValue with the default operator of the column and shows it in its editor; an
    /// empty value removes the filter.
    /// </summary>
    procedure SetFilterValue(const AColumn: TColumn; const AValue: TValue);
    /// <summary>
    /// Returns the text of the footer under AColumn: the value calculated from the rows of the grid and the
    /// settings of the column, changed by OnGetFooterText.
    /// </summary>
    function GetFooterText(const AColumn: TColumn): string;
    /// <summary>Calculates and draws the footer again, after a change of the data of the application.</summary>
    procedure UpdateFooter;
    /// <summary>
    /// Adds AColumn as the last key of the order, or changes its direction when it is already a key; fires OnSort.
    /// </summary>
    procedure AddSort(const AColumn: TColumn; const Descending: Boolean);
    /// <summary>Removes all the keys of the order, back to the order of the data; fires OnSort.</summary>
    procedure ClearSort;
    /// <summary>Returns True when the rows are sorted by at least one column.</summary>
    function IsSorted: Boolean;
    /// <summary>Removes AColumn from the keys of the order; fires OnSort.</summary>
    procedure RemoveSort(const AColumn: TColumn);
    /// <summary>Sorts the rows only by AColumn; fires OnSort.</summary>
    procedure SetSort(const AColumn: TColumn; const Descending: Boolean);
    /// <summary>
    /// Changes the order as a click on the header of AColumn with the keys AShift, when Sorting.Enabled is True: see
    /// TS4YGridSorting.Enabled.
    /// </summary>
    procedure SortByHeaderClick(const AColumn: TColumn; const AShift: TShiftState);
    /// <summary>Returns the position of AColumn among the keys of the order, -1 when it is not a key.</summary>
    function SortIndexOf(const AColumn: TColumn): Integer;

    /// <summary>The settings of the columns.</summary>
    property ColumnSettings: TS4YGridColumnSettings read FColumnSettings write SetColumnSettings;
    /// <summary>The settings of the filter row.</summary>
    property FilterRow: TS4YGridFilterRow read FFilterRow write SetFilterRow;
    /// <summary>The settings of the footer.</summary>
    property FooterRow: TS4YGridFooterRow read FFooterRow write SetFooterRow;
    /// <summary>The number of keys of the order.</summary>
    property SortCount: Integer read GetSortCount;
    /// <summary>The keys of the order, the first one first.</summary>
    property SortKeys[const AIndex: Integer]: TS4YGridSortKey read GetSortKey;
    /// <summary>The settings of the order.</summary>
    property Sorting: TS4YGridSorting read FSorting write SetSorting;

    /// <summary>Lets the application give the editor of the filter of a column.</summary>
    property OnCreateFilterEditor: TS4YGridCreateFilterEditorEvent read FOnCreateFilterEditor write FOnCreateFilterEditor;
    /// <summary>Fires when the application must filter its data: Enter in an editor, or a call to Filter.</summary>
    property OnFilter: TNotifyEvent read FOnFilter write FOnFilter;
    /// <summary>Fires when the filter of a column changes, in its editor or by code.</summary>
    property OnFilterChanged: TS4YGridColumnEvent read FOnFilterChanged write FOnFilterChanged;
    /// <summary>Lets the application change the menu of the filter of a column before it is shown.</summary>
    property OnFilterMenu: TS4YGridFilterMenuEvent read FOnFilterMenu write FOnFilterMenu;
    /// <summary>Lets the application change the text of the footer under a column.</summary>
    property OnGetFooterText: TS4YGridFooterTextEvent read FOnGetFooterText write FOnGetFooterText;
    /// <summary>Fires when the order of the rows changes: the application sorts its data with the keys.</summary>
    property OnSort: TNotifyEvent read FOnSort write FOnSort;
  end;

  /// <summary>
  /// A grid with a filter row under the header: an editor for each column, where the user writes the value to look
  /// for in that column.
  /// </summary>
  /// <remarks>
  /// TS4YGrid is a TGrid: the cells get their values from OnGetValue or from the LiveBindings. The grid does not
  /// filter the data itself: it keeps the filter values and fires OnFilter, and the application filters its data and
  /// sets RowCount again. In the same way it keeps the order chosen with a click on the header and fires OnSort. The
  /// filter row takes the look of the style of the grid, from the platform or from a TStyleBook.
  /// </remarks>
  TS4YGrid = class(TGrid)
  private
    function GetColumnSettings: TS4YGridColumnSettings;
    function GetFilterOperator(const AColumn: TColumn): TS4YGridFilterOperator;
    function GetFilterRow: TS4YGridFilterRow;
    function GetFilterState(const AColumn: TColumn): TS4YGridFilterState;
    function GetFilterText(const AColumn: TColumn): string;
    function GetFilterValue(const AColumn: TColumn): TValue;
    function GetFooterRow: TS4YGridFooterRow;
    function GetModel: TS4YGridModel; overload;
    function GetOnCreateFilterEditor: TS4YGridCreateFilterEditorEvent;
    function GetOnFilter: TNotifyEvent;
    function GetOnFilterChanged: TS4YGridColumnEvent;
    function GetOnFilterMenu: TS4YGridFilterMenuEvent;
    function GetOnGetFooterText: TS4YGridFooterTextEvent;
    function GetOnSort: TNotifyEvent;
    function GetSortColumn(const AIndex: Integer): TColumn;
    function GetSortCount: Integer;
    function GetSortDescending(const AIndex: Integer): Boolean;
    function GetSorting: TS4YGridSorting;
    procedure SetColumnSettings(const Value: TS4YGridColumnSettings);
    procedure SetFilterRow(const Value: TS4YGridFilterRow);
    procedure SetFilterText(const AColumn: TColumn; const Value: string);
    procedure SetFilterValue(const AColumn: TColumn; const Value: TValue);
    procedure SetFooterRow(const Value: TS4YGridFooterRow);
    procedure SetOnCreateFilterEditor(const Value: TS4YGridCreateFilterEditorEvent);
    procedure SetOnFilter(const Value: TNotifyEvent);
    procedure SetOnFilterChanged(const Value: TS4YGridColumnEvent);
    procedure SetOnFilterMenu(const Value: TS4YGridFilterMenuEvent);
    procedure SetOnGetFooterText(const Value: TS4YGridFooterTextEvent);
    procedure SetOnSort(const Value: TNotifyEvent);
    procedure SetSorting(const Value: TS4YGridSorting);
  protected
    /// <summary>Returns the class of the model of the grid, TS4YGridModel.</summary>
    function DefineModelClass: TDataModelClass; override;
    /// <summary>Forgets the settings of a column that is freed.</summary>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    /// <summary>
    /// Adds AColumn as the last key of the order, or changes its direction when it is already a key; fires OnSort.
    /// </summary>
    procedure AddSort(const AColumn: TColumn; const Descending: Boolean = False);
    /// <summary>Clears the filters of all the columns, firing OnFilterChanged for each one that had a filter.</summary>
    procedure ClearFilters;
    /// <summary>Removes all the keys of the order, back to the order of the data; fires OnSort.</summary>
    procedure ClearSort;
    /// <summary>Fires OnFilter: the application filters its data with the filters.</summary>
    procedure Filter;
    /// <summary>
    /// Returns True when AValue, the value of a row in AColumn, passes the filter of the column, with its operator and
    /// value; True when the column has no filter. For the application that filters its data in memory, in OnFilter.
    /// </summary>
    /// <remarks>
    /// The texts are compared without difference between upper and lower case; the dates only by the day, the times
    /// to the millisecond. A row without value passes only the operators not equal, does not contain and is empty. A
    /// value that cannot be compared with the value of the filter, such as a text that is not a number in a number
    /// column, passes the filter.
    /// </remarks>
    function FilterMatches(const AColumn: TColumn; const AValue: TValue): Boolean;
    /// <summary>Returns True when at least one column has a filter that is applied.</summary>
    function IsFiltered: Boolean;
    /// <summary>Returns True when the rows are sorted by at least one column.</summary>
    function IsSorted: Boolean;
    /// <summary>Removes AColumn from the keys of the order; fires OnSort.</summary>
    procedure RemoveSort(const AColumn: TColumn);
    /// <summary>
    /// Sets the filter of AColumn to AOperator and AValue, writes its text in the editor and fires OnFilterChanged,
    /// not OnFilter; gfoNone removes the filter.
    /// </summary>
    /// <remarks>
    /// The text is written as the grid writes it: the operator, a space and the value, without the default operator of
    /// the column, with double quotes when the value needs them.
    /// </remarks>
    procedure SetFilter(const AColumn: TColumn; const AOperator: TS4YGridFilterOperator; const AValue: TValue);
    /// <summary>Sorts the rows only by AColumn; fires OnSort.</summary>
    procedure SetSort(const AColumn: TColumn; const Descending: Boolean = False);
    /// <summary>Returns the position of AColumn among the keys of the order, -1 when it is not a key.</summary>
    function SortIndexOf(const AColumn: TColumn): Integer;
    /// <summary>
    /// Calculates and draws the footer again. Call it after a change of the data of the application that the grid
    /// cannot see, such as a value changed in the list shown by OnGetValue.
    /// </summary>
    procedure UpdateFooter;

    /// <summary>
    /// The operator of the filter of AColumn, read in its text: how the values of the rows are compared with
    /// FilterValue. gfoNone when the column has no filter text.
    /// </summary>
    /// <remarks>
    /// A text without operator has the default operator of the column: gfoContains for a text column, gfoEqual for
    /// the others. The operator is given also when the filter is not applied yet, as for "&gt;" alone: check
    /// FilterState, or that FilterValue is not empty.
    /// </remarks>
    property FilterOperator[const AColumn: TColumn]: TS4YGridFilterOperator read GetFilterOperator;
    /// <summary>
    /// The state of the text of the filter of AColumn: empty, incomplete (an operator without value), valid (the
    /// filter is applied) or invalid.
    /// </summary>
    property FilterState[const AColumn: TColumn]: TS4YGridFilterState read GetFilterState;
    /// <summary>
    /// The text of the filter of AColumn, as it is written in its editor; setting it reads it with the syntax of the
    /// filters, shows it in the editor and fires OnFilterChanged, not OnFilter.
    /// </summary>
    property FilterText[const AColumn: TColumn]: string read GetFilterText write SetFilterText;
    /// <summary>
    /// The filter value of AColumn: an empty value when the filter is not applied, or when its operator is gfoEmpty or
    /// gfoNotEmpty.
    /// </summary>
    /// <remarks>
    /// The value has the type of the column: a string for a text column or a column with a list of values, an Int64
    /// for an integer column, a Double for a decimal or currency column, a TDate for a date column or a column of date
    /// and time, a TTime for a time column, a Boolean for a check column. Setting it sets the filter with the default
    /// operator of the column, shows it in the editor and fires OnFilterChanged, not OnFilter.
    /// </remarks>
    property FilterValue[const AColumn: TColumn]: TValue read GetFilterValue write SetFilterValue;
    /// <summary>The model of the grid.</summary>
    property Model: TS4YGridModel read GetModel;
    /// <summary>The columns of the keys of the order, the first key first.</summary>
    property SortColumn[const AIndex: Integer]: TColumn read GetSortColumn;
    /// <summary>The number of keys of the order: 0 when the rows have the order of the data.</summary>
    property SortCount: Integer read GetSortCount;
    /// <summary>The directions of the keys of the order: True from the highest value to the lowest.</summary>
    property SortDescending[const AIndex: Integer]: Boolean read GetSortDescending;
  published
    /// <summary>The settings of the columns, such as Filterable; a column without an item has the default settings.</summary>
    property ColumnSettings: TS4YGridColumnSettings read GetColumnSettings write SetColumnSettings;
    /// <summary>The settings of the filter row, the row of editors under the header.</summary>
    property FilterRow: TS4YGridFilterRow read GetFilterRow write SetFilterRow;
    /// <summary>
    /// The settings of the footer, the row under the cells; what each column shows is in ColumnSettings.
    /// </summary>
    /// <remarks>
    /// The values are calculated from the rows of the grid, the ones of RowCount: after a filter, the rows shown.
    /// </remarks>
    property FooterRow: TS4YGridFooterRow read GetFooterRow write SetFooterRow;
    /// <summary>
    /// The settings of the order of the rows, chosen with a click on the header of the columns.
    /// </summary>
    /// <remarks>
    /// The grid does not sort the data itself: it keeps the keys of the order, shows them in the header and fires
    /// OnSort, and the application sorts its data.
    /// </remarks>
    property Sorting: TS4YGridSorting read GetSorting write SetSorting;

    /// <summary>
    /// Lets the application give the editor of the filter of a column, instead of the one the grid creates from the
    /// type of the column.
    /// </summary>
    property OnCreateFilterEditor: TS4YGridCreateFilterEditorEvent read GetOnCreateFilterEditor
      write SetOnCreateFilterEditor;
    /// <summary>
    /// Fires when the application must filter its data with the filters of the columns: Enter in an editor of the
    /// filter row, a click on a check box of the filter row, or a call to Filter.
    /// </summary>
    /// <remarks>
    /// For each column, FilterOperator and FilterValue tell how to filter; FilterMatches compares a value with them.
    /// </remarks>
    property OnFilter: TNotifyEvent read GetOnFilter write SetOnFilter;
    /// <summary>Fires when the filter of a column changes, in its editor or by code.</summary>
    property OnFilterChanged: TS4YGridColumnEvent read GetOnFilterChanged write SetOnFilterChanged;
    /// <summary>
    /// Lets the application change the menu of the filter of a column before it is shown, for example to add an item
    /// such as "This month"; the items gmaCustom fire their OnClick.
    /// </summary>
    property OnFilterMenu: TS4YGridFilterMenuEvent read GetOnFilterMenu write SetOnFilterMenu;
    /// <summary>
    /// Lets the application change the text of the footer under a column, for example to show the total of all its
    /// data and not only of the rows shown.
    /// </summary>
    property OnGetFooterText: TS4YGridFooterTextEvent read GetOnGetFooterText write SetOnGetFooterText;
    /// <summary>
    /// Fires when the order of the rows changes, with a click on the header or by code: the application sorts its
    /// data with SortCount, SortColumn and SortDescending.
    /// </summary>
    property OnSort: TNotifyEvent read GetOnSort write SetOnSort;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.DateUtils,
  Soft4You.FMX.Controls.Grid.Style;

resourcestring
  S_FILTER_CONTAINS = 'Contains';
  S_FILTER_NOT_CONTAINS = 'Does not contain';
  S_FILTER_STARTS_WITH = 'Starts with';
  S_FILTER_ENDS_WITH = 'Ends with';
  S_FILTER_EQUAL = 'Equal to';
  S_FILTER_NOT_EQUAL = 'Not equal to';
  S_FILTER_LESS = 'Less than';
  S_FILTER_LESS_OR_EQUAL = 'Less than or equal to';
  S_FILTER_GREATER = 'Greater than';
  S_FILTER_GREATER_OR_EQUAL = 'Greater than or equal to';
  S_FILTER_EMPTY = 'Is empty';
  S_FILTER_NOT_EMPTY = 'Is not empty';
  S_FILTER_CALENDAR = 'Calendar...';
  S_FILTER_TODAY = 'Today';
  S_FILTER_CURRENT_TIME = 'Current time';
  S_FILTER_CLEAR = 'Clear filter';

// Returns the text of the item of the menu of AOperator.
function OperatorText(const AOperator: TS4YGridFilterOperator): string;
begin
  case AOperator of
    gfoContains:
      Result := S_FILTER_CONTAINS;
    gfoNotContains:
      Result := S_FILTER_NOT_CONTAINS;
    gfoStartsWith:
      Result := S_FILTER_STARTS_WITH;
    gfoEndsWith:
      Result := S_FILTER_ENDS_WITH;
    gfoEqual:
      Result := S_FILTER_EQUAL;
    gfoNotEqual:
      Result := S_FILTER_NOT_EQUAL;
    gfoLess:
      Result := S_FILTER_LESS;
    gfoLessOrEqual:
      Result := S_FILTER_LESS_OR_EQUAL;
    gfoGreater:
      Result := S_FILTER_GREATER;
    gfoGreaterOrEqual:
      Result := S_FILTER_GREATER_OR_EQUAL;
    gfoEmpty:
      Result := S_FILTER_EMPTY;
    gfoNotEmpty:
      Result := S_FILTER_NOT_EMPTY;
  else
    Result := '';
  end;
end;

{ TS4YGridSorting }

constructor TS4YGridSorting.Create;
begin
  inherited;

  FMultiColumn := True;
  FOrderPosition := C_DEFAULT_ORDER_POSITION;
  FOrderSpacing := C_DEFAULT_ORDER_SPACING;
  FShowOrder := True;
end;

procedure TS4YGridSorting.Assign(Source: TPersistent);
var
  LSource: TS4YGridSorting;
begin
  if Source is TS4YGridSorting then
  begin
    LSource := TS4YGridSorting(Source);
    FEnabled := LSource.Enabled;
    FMultiColumn := LSource.MultiColumn;
    FOrderPosition := LSource.OrderPosition;
    FOrderSpacing := LSource.OrderSpacing;
    FShowOrder := LSource.ShowOrder;
    Changed;
  end
  else
    inherited;
end;

procedure TS4YGridSorting.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TS4YGridSorting.OrderSpacingStored: Boolean;
begin
  Result := not SameValue(FOrderSpacing, C_DEFAULT_ORDER_SPACING);
end;

procedure TS4YGridSorting.SetOrderPosition(const Value: TS4YGridSortOrderPosition);
begin
  if FOrderPosition = Value then
    Exit;

  FOrderPosition := Value;
  Changed;
end;

procedure TS4YGridSorting.SetOrderSpacing(const Value: Single);
begin
  if SameValue(FOrderSpacing, Value) then
    Exit;

  FOrderSpacing := Max(0, Value);
  Changed;
end;

procedure TS4YGridSorting.SetEnabled(const Value: Boolean);
begin
  if FEnabled = Value then
    Exit;

  FEnabled := Value;
  Changed;
end;

procedure TS4YGridSorting.SetMultiColumn(const Value: Boolean);
begin
  if FMultiColumn = Value then
    Exit;

  FMultiColumn := Value;
  Changed;
end;

procedure TS4YGridSorting.SetShowOrder(const Value: Boolean);
begin
  if FShowOrder = Value then
    Exit;

  FShowOrder := Value;
  Changed;
end;

{ TS4YGridFooterRow }

procedure TS4YGridFooterRow.Assign(Source: TPersistent);
var
  LSource: TS4YGridFooterRow;
begin
  if Source is TS4YGridFooterRow then
  begin
    LSource := TS4YGridFooterRow(Source);
    FHeight := LSource.Height;
    FVisible := LSource.Visible;
    Changed;
  end
  else
    inherited;
end;

procedure TS4YGridFooterRow.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YGridFooterRow.SetHeight(const Value: Integer);
begin
  if FHeight = Value then
    Exit;

  if Value < 0 then
    FHeight := 0
  else
    FHeight := Value;

  Changed;
end;

procedure TS4YGridFooterRow.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;
  Changed;
end;

{ TS4YGridFilterRow }

constructor TS4YGridFilterRow.Create;
begin
  inherited;

  FFilterDelay := C_DEFAULT_FILTER_DELAY;
  FShowMenuButton := True;
end;

procedure TS4YGridFilterRow.Assign(Source: TPersistent);
var
  LSource: TS4YGridFilterRow;
begin
  if Source is TS4YGridFilterRow then
  begin
    LSource := TS4YGridFilterRow(Source);
    FAutoFilter := LSource.AutoFilter;
    FCheckBoxStyleLookup := LSource.CheckBoxStyleLookup;
    FClearOnHide := LSource.ClearOnHide;
    FEditStyleLookup := LSource.EditStyleLookup;
    FFilterDelay := LSource.FilterDelay;
    FHeight := LSource.Height;
    FMenuStyleLookup := LSource.MenuStyleLookup;
    FShowMenuButton := LSource.ShowMenuButton;
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

procedure TS4YGridFilterRow.SetCheckBoxStyleLookup(const Value: string);
begin
  if FCheckBoxStyleLookup = Value then
    Exit;

  FCheckBoxStyleLookup := Value;
  Changed;
end;

procedure TS4YGridFilterRow.SetClearOnHide(const Value: Boolean);
begin
  if FClearOnHide = Value then
    Exit;

  FClearOnHide := Value;
  Changed;
end;

procedure TS4YGridFilterRow.SetEditStyleLookup(const Value: string);
begin
  if FEditStyleLookup = Value then
    Exit;

  FEditStyleLookup := Value;
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

procedure TS4YGridFilterRow.SetMenuStyleLookup(const Value: string);
begin
  if FMenuStyleLookup = Value then
    Exit;

  FMenuStyleLookup := Value;
  Changed;
end;

procedure TS4YGridFilterRow.SetShowMenuButton(const Value: Boolean);
begin
  if FShowMenuButton = Value then
    Exit;

  FShowMenuButton := Value;
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
  FFooterAlignment := C_DEFAULT_FOOTER_ALIGNMENT;
  FSortable := C_DEFAULT_SORTABLE;
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
    FilterMenu := LSource.FilterMenu;
    FFooterAlignment := LSource.FooterAlignment;
    FFooterFormat := LSource.FooterFormat;
    FFooterKind := LSource.FooterKind;
    FFooterText := LSource.FooterText;
    FSortable := LSource.Sortable;
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

procedure TS4YGridColumnSetting.SetFilterMenu(const Value: TPopupMenu);
var
  LOwner: TPersistent;
begin
  if FFilterMenu = Value then
    Exit;

  FFilterMenu := Value;

  // The grid is told when the menu is freed, to forget it.
  LOwner := TS4YGridColumnSettings(Collection).Owner;

  if Assigned(FFilterMenu) and (LOwner is TComponent) then
    FFilterMenu.FreeNotification(TComponent(LOwner));

  Changed(False);
end;

procedure TS4YGridColumnSetting.SetFilterable(const Value: Boolean);
begin
  if FFilterable = Value then
    Exit;

  FFilterable := Value;
  Changed(False);
end;

procedure TS4YGridColumnSetting.SetFooterAlignment(const Value: TTextAlign);
begin
  if FFooterAlignment = Value then
    Exit;

  FFooterAlignment := Value;
  Changed(False);
end;

procedure TS4YGridColumnSetting.SetFooterFormat(const Value: string);
begin
  if FFooterFormat = Value then
    Exit;

  FFooterFormat := Value;
  Changed(False);
end;

procedure TS4YGridColumnSetting.SetFooterKind(const Value: TS4YGridFooterKind);
begin
  if FFooterKind = Value then
    Exit;

  FFooterKind := Value;
  Changed(False);
end;

procedure TS4YGridColumnSetting.SetFooterText(const Value: string);
begin
  if FFooterText = Value then
    Exit;

  FFooterText := Value;
  Changed(False);
end;

procedure TS4YGridColumnSetting.SetSortable(const Value: Boolean);
begin
  if FSortable = Value then
    Exit;

  FSortable := Value;
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

function TS4YGridColumnSettings.IsSortable(const AColumn: TColumn): Boolean;
var
  LSetting: TS4YGridColumnSetting;
begin
  LSetting := FindColumn(AColumn);

  if Assigned(LSetting) then
    Result := LSetting.Sortable
  else
    Result := TS4YGridColumnSetting.C_DEFAULT_SORTABLE;
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

  FFilters := TDictionary<TColumn, TS4YGridFilter>.Create;
  FFilterRow := TS4YGridFilterRow.Create;
  FFilterRow.OnChange := FilterRowChange;
  FFooterRow := TS4YGridFooterRow.Create;
  FFooterRow.OnChange := FooterRowChange;
  FSortKeys := TList<TS4YGridSortKey>.Create;
  FSorting := TS4YGridSorting.Create;
  FSorting.OnChange := SortingChange;
  // The collection is owned by the grid, so that the Object Inspector and the form find it.
  FColumnSettings := TS4YGridColumnSettings.Create(AOwner);
  FColumnSettings.OnChange := ColumnSettingsChange;
end;

destructor TS4YGridModel.Destroy;
begin
  FColumnSettings.OnChange := nil;
  FFilterRow.OnChange := nil;
  FFooterRow.OnChange := nil;
  FSorting.OnChange := nil;
  FColumnSettings.Free;
  FFilterRow.Free;
  FFooterRow.Free;
  FFilters.Free;
  FSorting.Free;
  FSortKeys.Free;

  inherited;
end;

procedure TS4YGridModel.AddSort(const AColumn: TColumn; const Descending: Boolean);
var
  LIndex: Integer;
  LKey: TS4YGridSortKey;
begin
  if not Assigned(AColumn) then
    Exit;

  LIndex := SortIndexOf(AColumn);

  if (LIndex >= 0) and (FSortKeys[LIndex].Descending = Descending) then
    Exit;

  LKey.Column := AColumn;
  LKey.Descending := Descending;

  if LIndex >= 0 then
    FSortKeys[LIndex] := LKey
  else
    FSortKeys.Add(LKey);

  SortChanged;
end;

procedure TS4YGridModel.ApplyFilterMenuItem(const AItem: TS4YGridFilterMenuItem);
var
  LNow: TDateTime;
begin
  case AItem.Action of
    gmaOperator:
      ApplyFilterOperator(AItem.Column, AItem.FilterOperator);
    gmaValue:
      ApplyFilterValue(AItem.Column, AItem.Value);
    gmaToday:
      ApplyFilterValue(AItem.Column, TValue.From<TDate>(Date));
    gmaCurrentTime:
      begin
        LNow := Now;
        ApplyFilterValue(AItem.Column, TValue.From<TTime>(EncodeTime(HourOf(LNow), MinuteOf(LNow), 0, 0)));
      end;
    gmaClear:
      SetFilterText(AItem.Column, '');
    gmaCustom:
      if Assigned(AItem.OnClick) then
        AItem.OnClick(AItem);
  end;
end;

procedure TS4YGridModel.ApplyFilterOperator(const AColumn: TColumn; const AOperator: TS4YGridFilterOperator);
var
  LFilter: TS4YGridFilter;
  LValue: TValue;
begin
  if not Assigned(AColumn) then
    Exit;

  // The value already written stays, also when it cannot be read yet; empty and not empty have no value.
  LFilter := GetFilter(AColumn);
  LValue := TValue.Empty;

  if not (LFilter.FilterOperator in [gfoEmpty, gfoNotEmpty]) and (LFilter.ValueText <> '') then
    LValue := LFilter.ValueText;

  SetFilterText(AColumn, TS4YGridFilter.FormatText(LFilter.Kind, AOperator, LValue, True));
end;

procedure TS4YGridModel.ApplyFilterValue(const AColumn: TColumn; const AValue: TValue);
var
  LFilter: TS4YGridFilter;
  LOperator: TS4YGridFilterOperator;
begin
  if not Assigned(AColumn) then
    Exit;

  // The operator already written stays, in the form the grid writes; the default one stays not written.
  LFilter := GetFilter(AColumn);
  LOperator := LFilter.FilterOperator;

  if (LOperator in [gfoNone, gfoEmpty, gfoNotEmpty]) or not TS4YGridFilter.IsOperatorAllowed(LFilter.Kind, LOperator) then
    LOperator := TS4YGridFilter.DefaultOperator(LFilter.Kind);

  SetFilterText(AColumn, TS4YGridFilter.FormatText(LFilter.Kind, LOperator, AValue,
    LFilter.ExplicitOperator and (LOperator = LFilter.FilterOperator)));
end;

procedure TS4YGridModel.ClearSort;
begin
  if FSortKeys.Count = 0 then
    Exit;

  FSortKeys.Clear;
  SortChanged;
end;

procedure TS4YGridModel.ClearFilters;
var
  LColumns: TArray<TColumn>;
begin
  // The keys are copied: the dictionary changes while the filters are cleared.
  LColumns := FFilters.Keys.ToArray;

  for var I := 0 to High(LColumns) do
    SetFilterText(LColumns[I], '');
end;

procedure TS4YGridModel.ColumnSettingsChange(Sender: TObject);
var
  LColumns: TArray<TColumn>;
  LFilter: TS4YGridFilter;
begin
  // A list of values added or removed changes the kind of value of a column: its text is read again.
  LColumns := FFilters.Keys.ToArray;

  for var I := 0 to High(LColumns) do
  begin
    LFilter := FFilters[LColumns[I]];

    if LFilter.Kind <> GetFilterKind(LColumns[I]) then
      FFilters[LColumns[I]] := TS4YGridFilter.Parse(LFilter.Text, GetFilterKind(LColumns[I]));
  end;

  SendMessage(MM_S4Y_GRID_COLUMN_SETTINGS_CHANGED);
end;

procedure TS4YGridModel.DoColumnRemoved(const Column: TColumn);
var
  LIndex: Integer;
begin
  FFilters.Remove(Column);
  // The key is forgotten without OnSort: the order of the data does not change.
  LIndex := SortIndexOf(Column);

  if LIndex >= 0 then
    FSortKeys.Delete(LIndex);

  inherited;

  SendMessage(MM_S4Y_GRID_FILTER_ROW_CHANGED);
  SendMessage(MM_S4Y_GRID_SORT_CHANGED);
end;

procedure TS4YGridModel.DoFilterChanged(const AColumn: TColumn);
begin
  if Assigned(FOnFilterChanged) then
    FOnFilterChanged(Owner, AColumn);
end;

procedure TS4YGridModel.DoRowCountChanged(const OldValue, NewValue: Integer);
begin
  inherited;

  SendMessage(MM_S4Y_GRID_FOOTER_CHANGED);
end;

procedure TS4YGridModel.DoSetValue(Col, Row: Integer; const Value: TValue);
begin
  inherited;

  SendMessage(MM_S4Y_GRID_FOOTER_CHANGED);
end;

procedure TS4YGridModel.DoSort;
begin
  if Assigned(FOnSort) then
    FOnSort(Owner);
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

procedure TS4YGridModel.FooterRowChange(Sender: TObject);
begin
  SendMessage(MM_S4Y_GRID_FOOTER_CHANGED);
end;

function TS4YGridModel.FormatFooterValue(const AColumn: TColumn; const ASetting: TS4YGridColumnSetting;
  const AValue: Double; const AIsAverage: Boolean): string;
begin
  if ASetting.FooterFormat <> '' then
  begin
    // A format that does not fit the value, such as '%d' for an average, writes the value as the column would.
    try
      Exit(Format(ASetting.FooterFormat, [AValue]));
    except
      on EConvertError do
        Result := '';
    end;
  end;

  // The value as the column writes its cells; an average of whole numbers keeps its decimals.
  if AColumn is TDateTimeColumnBase then
    Result := AColumn.ValueToString(TValue.From<TDateTime>(AValue))
  else if (AColumn is TCustomNumberColumn) and not (AIsAverage and (AColumn is TIntegerColumn)) then
    Result := AColumn.ValueToString(AValue)
  else
    Result := FormatFloat('0.##', AValue);
end;

function TS4YGridModel.FilterMatches(const AColumn: TColumn; const AValue: TValue): Boolean;
begin
  Result := GetFilter(AColumn).Matches(AValue);
end;

function TS4YGridModel.GetFilter(const AColumn: TColumn): TS4YGridFilter;
begin
  if not Assigned(AColumn) or not FFilters.TryGetValue(AColumn, Result) then
    Result := TS4YGridFilter.Parse('', GetFilterKind(AColumn));
end;

function TS4YGridModel.GetFilterKind(const AColumn: TColumn): TS4YGridFilterValueKind;
begin
  // The list of values comes before the type of the column.
  if Assigned(FColumnSettings.GetFilterItems(AColumn)) or (AColumn is TPopupColumn) then
    Result := gvkList
  else if AColumn is TIntegerColumn then
    Result := gvkInteger
  else if AColumn is TCustomNumberColumn then
    Result := gvkFloat
  else if (AColumn is TDateColumn) or (AColumn is TDateTimeColumn) then
    Result := gvkDate
  else if AColumn is TTimeColumn then
    Result := gvkTime
  else if AColumn is TCheckColumn then
    Result := gvkBoolean
  else
    Result := gvkText;
end;

procedure TS4YGridModel.GetFilterMenu(const AColumn: TColumn; const AItems: TS4YGridFilterMenuItems);
var
  LFilter: TS4YGridFilter;
  LOperators: TArray<TS4YGridFilterOperator>;
  LCurrent: TS4YGridFilterOperator;
  LItem: TS4YGridFilterMenuItem;
  LValues: TStrings;
begin
  AItems.Clear;
  AItems.Column := AColumn;
  LFilter := GetFilter(AColumn);

  case LFilter.Kind of
    gvkText:
      LOperators := [gfoContains, gfoNotContains, gfoStartsWith, gfoEndsWith, gfoEqual, gfoNotEqual];
    gvkList, gvkBoolean:
      LOperators := [gfoEqual, gfoNotEqual];
  else
    LOperators := [gfoEqual, gfoNotEqual, gfoLess, gfoLessOrEqual, gfoGreater, gfoGreaterOrEqual];
  end;

  LOperators := LOperators + [gfoEmpty, gfoNotEmpty];

  // Without text, the default operator is the one the text will have.
  LCurrent := LFilter.FilterOperator;

  if LCurrent = gfoNone then
    LCurrent := TS4YGridFilter.DefaultOperator(LFilter.Kind);

  for var I := 0 to High(LOperators) do
  begin
    LItem := AItems.AddAction(gmaOperator, OperatorText(LOperators[I]));
    LItem.FilterOperator := LOperators[I];
    LItem.Checked := LOperators[I] = LCurrent;
  end;

  // The values of the list, the one written checked.
  LValues := FColumnSettings.GetFilterItems(AColumn);

  if not Assigned(LValues) and (AColumn is TPopupColumn) then
    LValues := TPopupColumn(AColumn).Items;

  if (LFilter.Kind = gvkList) and Assigned(LValues) and (LValues.Count > 0) then
  begin
    AItems.AddSeparator;

    for var I := 0 to LValues.Count - 1 do
    begin
      LItem := AItems.AddAction(gmaValue, LValues[I]);
      LItem.Value := LValues[I];
      LItem.Checked := (LFilter.State = gfsValid) and AnsiSameText(LFilter.ValueText, LValues[I]);
    end;
  end;

  if LFilter.Kind = gvkDate then
  begin
    AItems.AddSeparator;
    AItems.AddAction(gmaCalendar, S_FILTER_CALENDAR);
    AItems.AddAction(gmaToday, S_FILTER_TODAY);
  end
  else if LFilter.Kind = gvkTime then
  begin
    AItems.AddSeparator;
    AItems.AddAction(gmaCurrentTime, S_FILTER_CURRENT_TIME);
  end;

  AItems.AddSeparator;
  AItems.AddAction(gmaClear, S_FILTER_CLEAR);

  if Assigned(FOnFilterMenu) then
    FOnFilterMenu(Owner, AColumn, AItems);
end;

function TS4YGridModel.GetFilterOperator(const AColumn: TColumn): TS4YGridFilterOperator;
begin
  Result := GetFilter(AColumn).FilterOperator;
end;

function TS4YGridModel.GetFilterState(const AColumn: TColumn): TS4YGridFilterState;
begin
  Result := GetFilter(AColumn).State;
end;

function TS4YGridModel.GetFilterText(const AColumn: TColumn): string;
begin
  Result := GetFilter(AColumn).Text;
end;

function TS4YGridModel.GetFilterValue(const AColumn: TColumn): TValue;
begin
  Result := GetFilter(AColumn).Value;
end;

function TS4YGridModel.GetFooterText(const AColumn: TColumn): string;
var
  LSetting: TS4YGridColumnSetting;
  LValue: TValue;
  LNumber: Double;
  LCount: Integer;
  LNumbers: Integer;
  LSum: Double;
  LMin: Double;
  LMax: Double;
begin
  Result := '';
  LSetting := FColumnSettings.FindColumn(AColumn);

  if Assigned(LSetting) and (LSetting.FooterKind = gfkText) then
    Result := LSetting.FooterText
  else if Assigned(LSetting) and (LSetting.FooterKind <> gfkNone) then
  begin
    LCount := 0;
    LNumbers := 0;
    LSum := 0;
    LMin := 0;
    LMax := 0;

    // The values of the rows of the grid, read again: the data may have changed since they were drawn.
    for var LRow := 0 to RowCount - 1 do
    begin
      LValue := GetValue(AColumn.Index, LRow, True);

      if not LValue.IsEmpty then
      begin
        Inc(LCount);

        if TS4YGridFilter.TryValueToNumber(LValue, LNumber) then
        begin
          if (LNumbers = 0) or (LNumber < LMin) then
            LMin := LNumber;

          if (LNumbers = 0) or (LNumber > LMax) then
            LMax := LNumber;

          LSum := LSum + LNumber;
          Inc(LNumbers);
        end;
      end;
    end;

    case LSetting.FooterKind of
      gfkCount:
        if LSetting.FooterFormat <> '' then
          Result := Format(LSetting.FooterFormat, [LCount])
        else
          Result := IntToStr(LCount);
      gfkSum:
        if LNumbers > 0 then
          Result := FormatFooterValue(AColumn, LSetting, LSum, False);
      gfkAverage:
        if LNumbers > 0 then
          Result := FormatFooterValue(AColumn, LSetting, LSum / LNumbers, True);
      gfkMin:
        if LNumbers > 0 then
          Result := FormatFooterValue(AColumn, LSetting, LMin, False);
      gfkMax:
        if LNumbers > 0 then
          Result := FormatFooterValue(AColumn, LSetting, LMax, False);
    end;
  end;

  if Assigned(FOnGetFooterText) then
    FOnGetFooterText(Owner, AColumn, Result);
end;

function TS4YGridModel.GetSortCount: Integer;
begin
  Result := FSortKeys.Count;
end;

function TS4YGridModel.GetSortKey(const AIndex: Integer): TS4YGridSortKey;
begin
  Result := FSortKeys[AIndex];
end;

function TS4YGridModel.IsFiltered: Boolean;
begin
  Result := False;

  for var LFilter in FFilters.Values do
    if LFilter.IsActive then
      Result := True;
end;

function TS4YGridModel.IsSorted: Boolean;
begin
  Result := FSortKeys.Count > 0;
end;

procedure TS4YGridModel.RemoveSort(const AColumn: TColumn);
var
  LIndex: Integer;
begin
  LIndex := SortIndexOf(AColumn);

  if LIndex < 0 then
    Exit;

  FSortKeys.Delete(LIndex);
  SortChanged;
end;

procedure TS4YGridModel.SetSort(const AColumn: TColumn; const Descending: Boolean);
var
  LKey: TS4YGridSortKey;
begin
  if not Assigned(AColumn) then
    Exit;

  if (FSortKeys.Count = 1) and (FSortKeys[0].Column = AColumn) and (FSortKeys[0].Descending = Descending) then
    Exit;

  LKey.Column := AColumn;
  LKey.Descending := Descending;
  FSortKeys.Clear;
  FSortKeys.Add(LKey);
  SortChanged;
end;

procedure TS4YGridModel.SetSorting(const Value: TS4YGridSorting);
begin
  FSorting.Assign(Value);
end;

procedure TS4YGridModel.SortByHeaderClick(const AColumn: TColumn; const AShift: TShiftState);
var
  LIndex: Integer;
begin
  if not FSorting.Enabled or not Assigned(AColumn) then
    Exit;

  LIndex := SortIndexOf(AColumn);

  // Alt goes back to the order of the data and Ctrl removes the column, also from a column that is not sortable.
  if ssAlt in AShift then
    ClearSort
  else if [ssCtrl, ssCommand] * AShift <> [] then
    RemoveSort(AColumn)
  else if not FColumnSettings.IsSortable(AColumn) then
    Exit
  else if (ssShift in AShift) and FSorting.MultiColumn then
  begin
    if LIndex >= 0 then
      AddSort(AColumn, not FSortKeys[LIndex].Descending)
    else
      AddSort(AColumn, False);
  end
  else if (FSortKeys.Count = 1) and (LIndex = 0) then
    SetSort(AColumn, not FSortKeys[0].Descending)
  else
    SetSort(AColumn, False);
end;

procedure TS4YGridModel.SortChanged;
begin
  SendMessage(MM_S4Y_GRID_SORT_CHANGED);
  DoSort;
end;

procedure TS4YGridModel.SortingChange(Sender: TObject);
begin
  SendMessage(MM_S4Y_GRID_SORT_CHANGED);
end;

function TS4YGridModel.SortIndexOf(const AColumn: TColumn): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  LIndex := 0;

  while (Result < 0) and (LIndex < FSortKeys.Count) do
  begin
    if Assigned(AColumn) and (FSortKeys[LIndex].Column = AColumn) then
      Result := LIndex;

    Inc(LIndex);
  end;
end;

procedure TS4YGridModel.SetColumnSettings(const Value: TS4YGridColumnSettings);
begin
  FColumnSettings.Assign(Value);
end;

procedure TS4YGridModel.SetFilterRow(const Value: TS4YGridFilterRow);
begin
  FFilterRow.Assign(Value);
end;

procedure TS4YGridModel.SetFooterRow(const Value: TS4YGridFooterRow);
begin
  FFooterRow.Assign(Value);
end;

procedure TS4YGridModel.UpdateFooter;
begin
  SendMessage(MM_S4Y_GRID_FOOTER_CHANGED);
end;

procedure TS4YGridModel.SetFilter(const AColumn: TColumn; const AOperator: TS4YGridFilterOperator;
  const AValue: TValue);
var
  LKind: TS4YGridFilterValueKind;
  LFilter: TS4YGridFilter;
begin
  if not Assigned(AColumn) then
    Exit;

  LKind := GetFilterKind(AColumn);
  LFilter := TS4YGridFilter.Parse(TS4YGridFilter.FormatText(LKind, AOperator, AValue, False), LKind);

  // A value the text cannot hold, such as the one of an editor of the application, is kept as it is.
  if (LFilter.State <> gfsValid) and not TS4YGridFilter.IsValueEmpty(AValue) and
    not (AOperator in [gfoNone, gfoEmpty, gfoNotEmpty]) and TS4YGridFilter.IsOperatorAllowed(LKind, AOperator) then
  begin
    LFilter.FilterOperator := AOperator;
    LFilter.State := gfsValid;
    LFilter.Value := AValue;
  end;

  StoreFilter(AColumn, LFilter);
end;

procedure TS4YGridModel.SetFilterText(const AColumn: TColumn; const AText: string);
begin
  if not Assigned(AColumn) or (GetFilterText(AColumn) = AText) then
    Exit;

  StoreFilter(AColumn, TS4YGridFilter.Parse(AText, GetFilterKind(AColumn)));
end;

procedure TS4YGridModel.SetFilterValue(const AColumn: TColumn; const AValue: TValue);
begin
  if TS4YGridFilter.IsValueEmpty(AValue) then
    SetFilter(AColumn, gfoNone, TValue.Empty)
  else
    SetFilter(AColumn, TS4YGridFilter.DefaultOperator(GetFilterKind(AColumn)), AValue);
end;

procedure TS4YGridModel.StoreFilter(const AColumn: TColumn; const AFilter: TS4YGridFilter);
begin
  // No text removes the filter; a column without filter that stays without filter changes nothing.
  if AFilter.State = gfsEmpty then
  begin
    if not FFilters.ContainsKey(AColumn) then
      Exit;

    FFilters.Remove(AColumn);
  end
  else
    FFilters.AddOrSetValue(AColumn, AFilter);

  SendMessage<TColumn>(MM_S4Y_GRID_FILTER_VALUE_CHANGED, AColumn);
  DoFilterChanged(AColumn);
end;

{ TS4YGrid }

procedure TS4YGrid.AddSort(const AColumn: TColumn; const Descending: Boolean);
begin
  Model.AddSort(AColumn, Descending);
end;

procedure TS4YGrid.ClearFilters;
begin
  Model.ClearFilters;
end;

procedure TS4YGrid.ClearSort;
begin
  Model.ClearSort;
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

function TS4YGrid.FilterMatches(const AColumn: TColumn; const AValue: TValue): Boolean;
begin
  Result := Model.FilterMatches(AColumn, AValue);
end;

function TS4YGrid.GetFilterOperator(const AColumn: TColumn): TS4YGridFilterOperator;
begin
  Result := Model.GetFilterOperator(AColumn);
end;

function TS4YGrid.GetFilterRow: TS4YGridFilterRow;
begin
  Result := Model.FilterRow;
end;

function TS4YGrid.GetFilterState(const AColumn: TColumn): TS4YGridFilterState;
begin
  Result := Model.GetFilterState(AColumn);
end;

function TS4YGrid.GetFilterText(const AColumn: TColumn): string;
begin
  Result := Model.GetFilterText(AColumn);
end;

function TS4YGrid.GetFilterValue(const AColumn: TColumn): TValue;
begin
  Result := Model.GetFilterValue(AColumn);
end;

function TS4YGrid.GetFooterRow: TS4YGridFooterRow;
begin
  Result := Model.FooterRow;
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

function TS4YGrid.GetOnFilterMenu: TS4YGridFilterMenuEvent;
begin
  Result := Model.OnFilterMenu;
end;

function TS4YGrid.GetOnGetFooterText: TS4YGridFooterTextEvent;
begin
  Result := Model.OnGetFooterText;
end;

function TS4YGrid.GetOnSort: TNotifyEvent;
begin
  Result := Model.OnSort;
end;

function TS4YGrid.GetSortColumn(const AIndex: Integer): TColumn;
begin
  Result := Model.SortKeys[AIndex].Column;
end;

function TS4YGrid.GetSortCount: Integer;
begin
  Result := Model.SortCount;
end;

function TS4YGrid.GetSortDescending(const AIndex: Integer): Boolean;
begin
  Result := Model.SortKeys[AIndex].Descending;
end;

function TS4YGrid.GetSorting: TS4YGridSorting;
begin
  Result := Model.Sorting;
end;

function TS4YGrid.IsFiltered: Boolean;
begin
  Result := Model.IsFiltered;
end;

function TS4YGrid.IsSorted: Boolean;
begin
  Result := Model.IsSorted;
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

  // A menu of the application that is freed.
  if (Operation = opRemove) and (AComponent is TPopupMenu) and Assigned(Model) then
  begin
    for var I := 0 to Model.ColumnSettings.Count - 1 do
      if Model.ColumnSettings[I].FilterMenu = AComponent then
        Model.ColumnSettings[I].FilterMenu := nil;
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

procedure TS4YGrid.SetFilter(const AColumn: TColumn; const AOperator: TS4YGridFilterOperator; const AValue: TValue);
begin
  Model.SetFilter(AColumn, AOperator, AValue);
end;

procedure TS4YGrid.SetFilterText(const AColumn: TColumn; const Value: string);
begin
  Model.SetFilterText(AColumn, Value);
end;

procedure TS4YGrid.SetFilterValue(const AColumn: TColumn; const Value: TValue);
begin
  Model.SetFilterValue(AColumn, Value);
end;

procedure TS4YGrid.RemoveSort(const AColumn: TColumn);
begin
  Model.RemoveSort(AColumn);
end;

procedure TS4YGrid.SetFooterRow(const Value: TS4YGridFooterRow);
begin
  Model.FooterRow := Value;
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

procedure TS4YGrid.SetOnFilterMenu(const Value: TS4YGridFilterMenuEvent);
begin
  Model.OnFilterMenu := Value;
end;

procedure TS4YGrid.SetOnGetFooterText(const Value: TS4YGridFooterTextEvent);
begin
  Model.OnGetFooterText := Value;
end;

procedure TS4YGrid.SetOnSort(const Value: TNotifyEvent);
begin
  Model.OnSort := Value;
end;

procedure TS4YGrid.SetSort(const AColumn: TColumn; const Descending: Boolean);
begin
  Model.SetSort(AColumn, Descending);
end;

procedure TS4YGrid.SetSorting(const Value: TS4YGridSorting);
begin
  Model.Sorting := Value;
end;

function TS4YGrid.SortIndexOf(const AColumn: TColumn): Integer;
begin
  Result := Model.SortIndexOf(AColumn);
end;

procedure TS4YGrid.UpdateFooter;
begin
  Model.UpdateFooter;
end;

initialization
  // Registered as TGrid: the LiveBindings look for the grids among the registered classes to create the columns of a
  // TLinkGridToDataSource.
  RegisterFmxClasses([TS4YGrid]);

end.
