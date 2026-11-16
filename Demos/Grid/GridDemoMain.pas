unit GridDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.Rtti,
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.ListBox,
  FMX.Layouts,
  FMX.TabControl,
  FMX.Grid,
  FMX.Grid.Style,
  FMX.ScrollBox,
  Data.DB,
  Data.Bind.EngExt,
  Fmx.Bind.DBEngExt,
  Fmx.Bind.Grid,
  System.Bindings.Outputs,
  Fmx.Bind.Editors,
  Data.Bind.Components,
  Data.Bind.Grid,
  Data.Bind.DBScope,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Soft4You.FMX.Controls.Grid.Types,
  Soft4You.FMX.Controls.Grid.Filters,
  Soft4You.FMX.Controls.Grid;

type
  // The status of a customer: an integer column shows a text for each value.
  TCustomerStatus = (
    csNew,
    csRegular,
    csLost
  );

  TCustomer = class
  public
    Active: Boolean;
    Amount: Currency;
    City: string;
    // The position in the data: the order of the rows that are the same for all the keys.
    Id: Integer;
    LastOrder: TDate;
    Name: string;
    Orders: Integer;
    Status: TCustomerStatus;
  end;

  TGridDemoForm = class(TForm)
    GridTabControl: TTabControl;
    ObjectsTab: TTabItem;
    ObjectsLayout: TLayout;
    ObjectsLabel: TLabel;
    ObjectsGrid: TS4YGrid;
    NameColumn: TStringColumn;
    CityColumn: TStringColumn;
    OrdersColumn: TIntegerColumn;
    AmountColumn: TCurrencyColumn;
    LastOrderColumn: TDateColumn;
    ActiveColumn: TCheckColumn;
    StatusColumn: TIntegerColumn;
    SettingsScrollBox: TVertScrollBox;
    FilterSettingsLabel: TLabel;
    FilterVisibleCheckBox: TCheckBox;
    AutoFilterCheckBox: TCheckBox;
    FilterDelayLabel: TLabel;
    FilterDelayTrackBar: TTrackBar;
    ClearOnHideCheckBox: TCheckBox;
    ShowButtonCheckBox: TCheckBox;
    ClearFiltersButton: TButton;
    FooterSettingsLabel: TLabel;
    FooterVisibleCheckBox: TCheckBox;
    AmountKindLabel: TLabel;
    AmountKindComboBox: TComboBox;
    AllDataCheckBox: TCheckBox;
    EventsSettingsLabel: TLabel;
    LastChangeLabel: TLabel;
    RowsLabel: TLabel;
    BindingsTab: TTabItem;
    BindingsLabel: TLabel;
    BindingsGrid: TS4YGrid;
    CustomersTable: TFDMemTable;
    CustomersTableName: TStringField;
    CustomersTableCity: TStringField;
    CustomersTableOrders: TIntegerField;
    CustomersTableAmount: TCurrencyField;
    CustomersTableLastOrder: TDateField;
    CustomersTableActive: TBooleanField;
    CustomersBindSource: TBindSourceDB;
    DemoBindingsList: TBindingsList;
    LinkGridToDataSourceCustomers: TLinkGridToDataSource;
    StyleBookTab: TTabItem;
    StyleBookLabel: TLabel;
    StyledGrid: TS4YGrid;
    StyledNameColumn: TStringColumn;
    StyledCityColumn: TStringColumn;
    StyledOrdersColumn: TIntegerColumn;
    StyledAmountColumn: TCurrencyColumn;
    GridStyleBook: TStyleBook;
    SortingSettingsLabel: TLabel;
    SortingEnabledCheckBox: TCheckBox;
    MultiColumnCheckBox: TCheckBox;
    ShowOrderCheckBox: TCheckBox;
    OrderBeforeCheckBox: TCheckBox;
    OrderSpacingLabel: TLabel;
    OrderSpacingTrackBar: TTrackBar;
    OrderLabel: TLabel;
    HeaderSettingsLabel: TLabel;
    HeaderHeightModeComboBox: TComboBox;
    HeaderHeightLabel: TLabel;
    HeaderHeightTrackBar: TTrackBar;
    RowHeightLabel: TLabel;
    RowHeightTrackBar: TTrackBar;
    procedure AllDataCheckBoxChange(Sender: TObject);
    procedure AmountKindComboBoxChange(Sender: TObject);
    procedure BindingsGridFilter(Sender: TObject);
    procedure BindingsGridSort(Sender: TObject);
    procedure ClearFiltersButtonClick(Sender: TObject);
    procedure CustomersTableFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure FilterSettingsChange(Sender: TObject);
    procedure FooterVisibleCheckBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure HeaderSettingsChange(Sender: TObject);
    procedure ObjectsGridFilter(Sender: TObject);
    procedure ObjectsGridFilterChanged(Sender: TObject; const AColumn: TColumn);
    procedure ObjectsGridFilterMenu(Sender: TObject; const AColumn: TColumn; const AItems: TS4YGridFilterMenuItems);
    procedure ObjectsGridFilterRowToggle(Sender: TObject);
    procedure ObjectsGridGetFooterText(Sender: TObject; const AColumn: TColumn; var AText: string);
    procedure ObjectsGridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
    procedure ObjectsGridSort(Sender: TObject);
    procedure SortingSettingsChange(Sender: TObject);
    procedure StyledGridFilter(Sender: TObject);
    procedure StyledGridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
  private
    FCustomers: TObjectList<TCustomer>;
    FStyledVisible: TList<TCustomer>;
    FVisible: TList<TCustomer>;
    function BindingsColumn(const AFieldName: string): TColumn;
    procedure BuildCustomers;
    function CompareCustomers(const ALeft, ARight: TCustomer; const AColumn: TColumn): Integer;
    procedure FillCustomersTable;
    function Matches(const AGrid: TS4YGrid; const ACustomer: TCustomer; const ANameColumn, ACityColumn, AOrdersColumn,
      AAmountColumn: TColumn): Boolean;
    function MatchesObjects(const ACustomer: TCustomer): Boolean;
    procedure AboveAverageClick(Sender: TObject);
    procedure SetUpBindingsGrid;
    procedure ShowObjects;
    function StatusText(const AStatus: TCustomerStatus): string;
    procedure UpdateRowsLabel;
  end;

var
  GridDemoForm: TGridDemoForm;

implementation

{$R *.fmx}

uses
  System.DateUtils,
  System.Math,
  System.TypInfo,
  System.Generics.Defaults;

resourcestring
  S_ABOVE_AVERAGE = 'Above the average';
  S_ALL_DATA = 'All: %s';
  S_FILTER_CHANGED = 'OnFilterChanged: %s "%s", %s';
  S_FILTER_EMPTY = 'no filter';
  S_FILTER_INCOMPLETE = 'incomplete, no filter yet';
  S_FILTER_INVALID = 'cannot be read, no filter';
  S_FILTER_VALID = 'operator %s, value %s';
  S_FILTER_DELAY = 'FilterDelay: %d ms';
  S_HEADER_HEIGHT = 'HeaderHeight: %d px';
  S_NO_ORDER = '(order of the data)';
  S_ORDER = 'OnSort: %s';
  S_ORDER_DESCENDING = '%s (descending)';
  S_ORDER_SPACING = 'OrderSpacing: %d px';
  S_ROW_HEIGHT = 'RowHeight: %d px';
  S_ROWS = 'Rows shown: %d of %d';
  S_STATUS_LOST = 'Lost';
  S_STATUS_NEW = 'New';
  S_STATUS_REGULAR = 'Regular';
  S_TOTAL = 'Total';

const
  C_CUSTOMER_COUNT = 200;
  C_FIRST_NAMES: array[0..9] of string = ('Anna', 'Bruno', 'Carla', 'Dario', 'Elena', 'Franco', 'Giulia', 'Luca',
    'Marta', 'Paolo');
  C_LAST_NAMES: array[0..9] of string = ('Rossi', 'Bianchi', 'Ferrari', 'Esposito', 'Romano', 'Colombo', 'Ricci',
    'Marino', 'Greco', 'Bruno');
  C_CITIES: array[0..5] of string = ('Milan', 'Rome', 'Turin', 'Naples', 'Florence', 'Bologna');
  // The kinds of the items of AmountKindComboBox, in the same order.
  C_AMOUNT_KINDS: array[0..4] of TS4YGridFooterKind = (gfkSum, gfkAverage, gfkCount, gfkMin, gfkMax);

function TGridDemoForm.BindingsColumn(const AFieldName: string): TColumn;
begin
  // The columns of the LiveBindings are created by the link, with the name of the field as header.
  Result := nil;

  for var I := 0 to BindingsGrid.ColumnCount - 1 do
    if SameText(BindingsGrid.Columns[I].Header, AFieldName) then
      Result := BindingsGrid.Columns[I];
end;

procedure TGridDemoForm.AboveAverageClick(Sender: TObject);
var
  LSum: Currency;
begin
  // An item of the application in the menu of the filter: it writes the filter, and filters at once.
  LSum := 0;

  for var LCustomer in FCustomers do
    LSum := LSum + LCustomer.Amount;

  ObjectsGrid.SetFilter(AmountColumn, gfoGreater, TValue.From<Currency>(RoundTo(LSum / FCustomers.Count, -2)));
  ObjectsGrid.Filter;
end;

procedure TGridDemoForm.AllDataCheckBoxChange(Sender: TObject);
begin
  ObjectsGrid.UpdateFooter;
end;

procedure TGridDemoForm.AmountKindComboBoxChange(Sender: TObject);
begin
  if AmountKindComboBox.ItemIndex >= 0 then
    ObjectsGrid.ColumnSettings.FindColumn(AmountColumn).FooterKind := C_AMOUNT_KINDS[AmountKindComboBox.ItemIndex];
end;

procedure TGridDemoForm.BindingsGridFilter(Sender: TObject);
begin
  // The data set filters itself with OnFilterRecord: the link shows the records that pass.
  CustomersTable.Filtered := False;
  CustomersTable.Filtered := BindingsGrid.IsFiltered;
  BindingsGrid.UpdateFooter;
end;

procedure TGridDemoForm.BindingsGridSort(Sender: TObject);
var
  LFields: string;
begin
  // The data set sorts itself: the headers of the columns of the link are the names of the fields.
  LFields := '';

  for var I := 0 to BindingsGrid.SortCount - 1 do
  begin
    if LFields <> '' then
      LFields := LFields + ';';

    LFields := LFields + BindingsGrid.SortColumn[I].Header;

    if BindingsGrid.SortDescending[I] then
      LFields := LFields + ':D';
  end;

  CustomersTable.IndexFieldNames := LFields;
end;

procedure TGridDemoForm.BuildCustomers;
var
  LCustomer: TCustomer;
begin
  // The same customers at each start.
  RandSeed := 2026;

  for var I := 1 to C_CUSTOMER_COUNT do
  begin
    LCustomer := TCustomer.Create;
    LCustomer.Id := I;
    LCustomer.Name := C_FIRST_NAMES[Random(Length(C_FIRST_NAMES))] + ' ' + C_LAST_NAMES[Random(Length(C_LAST_NAMES))];
    LCustomer.City := C_CITIES[Random(Length(C_CITIES))];
    LCustomer.Orders := 1 + Random(40);
    LCustomer.Amount := RoundTo(LCustomer.Orders * (20 + Random * 180), -2);
    LCustomer.LastOrder := EncodeDate(2026, 1, 1) + Random(300);
    LCustomer.Active := Random(4) > 0;
    LCustomer.Status := TCustomerStatus(I mod (Ord(High(TCustomerStatus)) + 1));
    FCustomers.Add(LCustomer);
  end;
end;

procedure TGridDemoForm.ClearFiltersButtonClick(Sender: TObject);
begin
  ObjectsGrid.ClearFilters;
  ObjectsGrid.Filter;
end;

function TGridDemoForm.CompareCustomers(const ALeft, ARight: TCustomer; const AColumn: TColumn): Integer;
begin
  if AColumn = NameColumn then
    Result := CompareText(ALeft.Name, ARight.Name)
  else if AColumn = CityColumn then
    Result := CompareText(ALeft.City, ARight.City)
  else if AColumn = OrdersColumn then
    Result := CompareValue(ALeft.Orders, ARight.Orders)
  else if AColumn = AmountColumn then
    Result := CompareValue(ALeft.Amount, ARight.Amount)
  else if AColumn = LastOrderColumn then
    Result := CompareDate(ALeft.LastOrder, ARight.LastOrder)
  else if AColumn = ActiveColumn then
    Result := CompareValue(Ord(ALeft.Active), Ord(ARight.Active))
  else if AColumn = StatusColumn then
    Result := CompareValue(Ord(ALeft.Status), Ord(ARight.Status))
  else
    Result := 0;
end;

procedure TGridDemoForm.CustomersTableFilterRecord(DataSet: TDataSet; var Accept: Boolean);
var
  LColumn: TColumn;
  LField: TField;
  LValue: TValue;
begin
  // The header of each column of the link is the name of its field: the grid compares the field with the filter.
  Accept := True;

  for var I := 0 to BindingsGrid.ColumnCount - 1 do
  begin
    LColumn := BindingsGrid.Columns[I];
    LField := DataSet.FindField(LColumn.Header);

    if Accept and Assigned(LField) then
    begin
      if LField.IsNull then
        LValue := TValue.Empty
      else
        LValue := TValue.FromVariant(LField.Value);

      Accept := BindingsGrid.FilterMatches(LColumn, LValue);
    end;
  end;
end;

procedure TGridDemoForm.FillCustomersTable;
begin
  CustomersTable.CreateDataSet;
  CustomersTable.DisableControls;
  try
    for var LCustomer in FCustomers do
      CustomersTable.AppendRecord([LCustomer.Name, LCustomer.City, LCustomer.Orders, LCustomer.Amount,
        LCustomer.LastOrder, LCustomer.Active]);

    CustomersTable.First;
  finally
    CustomersTable.EnableControls;
  end;
end;

procedure TGridDemoForm.FilterSettingsChange(Sender: TObject);
begin
  // The row is also shown and hidden by the button of the header and by Ctrl+Shift+F, which update its box.
  if (Sender = nil) or (Sender = FilterVisibleCheckBox) then
    ObjectsGrid.FilterRow.Visible := FilterVisibleCheckBox.IsChecked;

  ObjectsGrid.FilterRow.AutoFilter := AutoFilterCheckBox.IsChecked;
  ObjectsGrid.FilterRow.FilterDelay := Round(FilterDelayTrackBar.Value);
  ObjectsGrid.FilterRow.ClearOnHide := ClearOnHideCheckBox.IsChecked;
  ObjectsGrid.FilterRow.ShowButton := ShowButtonCheckBox.IsChecked;
  FilterDelayLabel.Text := Format(S_FILTER_DELAY, [ObjectsGrid.FilterRow.FilterDelay]);
end;

procedure TGridDemoForm.FooterVisibleCheckBoxChange(Sender: TObject);
begin
  ObjectsGrid.FooterRow.Visible := FooterVisibleCheckBox.IsChecked;
end;

procedure TGridDemoForm.FormCreate(Sender: TObject);
var
  LCities: TStringList;
begin
  // The demo always opens on the first tab, whichever tab was selected when the form was saved.
  GridTabControl.TabIndex := 0;
  FCustomers := TObjectList<TCustomer>.Create;
  FVisible := TList<TCustomer>.Create;
  FStyledVisible := TList<TCustomer>.Create;
  BuildCustomers;
  FVisible.AddRange(FCustomers);
  FStyledVisible.AddRange(FCustomers);

  // The grids show the data: they are not edited.
  ObjectsGrid.Options := ObjectsGrid.Options - [TGridOption.Editing];
  BindingsGrid.Options := BindingsGrid.Options - [TGridOption.Editing];
  StyledGrid.Options := StyledGrid.Options - [TGridOption.Editing];
  ObjectsGrid.RowCount := FVisible.Count;
  StyledGrid.RowCount := FStyledVisible.Count;

  // The cities of the drop-down list of the filter.
  LCities := TStringList.Create;
  try
    LCities.AddStrings(C_CITIES);
    LCities.Sort;
    ObjectsGrid.ColumnSettings.FindColumn(CityColumn).FilterItems := LCities;
    StyledGrid.ColumnSettings.Add(StyledCityColumn).FilterItems := LCities;
  finally
    LCities.Free;
  end;

  // The integer column of the status shows texts: its filter shows and accepts the texts, and gives the values.
  ObjectsGrid.ColumnSettings.Add(StatusColumn).SetFilterEnum(TypeInfo(TCustomerStatus),
    [S_STATUS_NEW, S_STATUS_REGULAR, S_STATUS_LOST]);
  FillCustomersTable;
  SetUpBindingsGrid;
  FilterSettingsChange(nil);
  HeaderSettingsChange(nil);
  UpdateRowsLabel;
end;

procedure TGridDemoForm.FormDestroy(Sender: TObject);
begin
  FStyledVisible.Free;
  FVisible.Free;
  FCustomers.Free;
end;

function TGridDemoForm.Matches(const AGrid: TS4YGrid; const ACustomer: TCustomer; const ANameColumn, ACityColumn,
  AOrdersColumn, AAmountColumn: TColumn): Boolean;
begin
  // The grid compares each value with the operator and the value written in the filter of its column.
  Result := AGrid.FilterMatches(ANameColumn, ACustomer.Name) and AGrid.FilterMatches(ACityColumn, ACustomer.City) and
    AGrid.FilterMatches(AOrdersColumn, ACustomer.Orders) and
    AGrid.FilterMatches(AAmountColumn, TValue.From<Currency>(ACustomer.Amount));
end;

function TGridDemoForm.MatchesObjects(const ACustomer: TCustomer): Boolean;
begin
  Result := Matches(ObjectsGrid, ACustomer, NameColumn, CityColumn, OrdersColumn, AmountColumn) and
    ObjectsGrid.FilterMatches(LastOrderColumn, TValue.From<TDate>(ACustomer.LastOrder)) and
    ObjectsGrid.FilterMatches(ActiveColumn, ACustomer.Active) and
    ObjectsGrid.FilterMatches(StatusColumn, Ord(ACustomer.Status));
end;

procedure TGridDemoForm.HeaderSettingsChange(Sender: TObject);
begin
  // With ghmRowHeight the header follows RowHeight; HeaderHeight is used only with ghmExplicit.
  ObjectsGrid.HeaderHeightMode := TS4YGridHeaderHeightMode(Max(0, HeaderHeightModeComboBox.ItemIndex));
  ObjectsGrid.HeaderHeight := Round(HeaderHeightTrackBar.Value);
  ObjectsGrid.RowHeight := Round(RowHeightTrackBar.Value);
  HeaderHeightLabel.Text := Format(S_HEADER_HEIGHT, [Round(HeaderHeightTrackBar.Value)]);
  RowHeightLabel.Text := Format(S_ROW_HEIGHT, [Round(RowHeightTrackBar.Value)]);
end;

procedure TGridDemoForm.ObjectsGridFilter(Sender: TObject);
begin
  ShowObjects;
end;

procedure TGridDemoForm.ObjectsGridFilterChanged(Sender: TObject; const AColumn: TColumn);
var
  LState: string;
begin
  // What the grid read in the text of the filter.
  case ObjectsGrid.FilterState[AColumn] of
    gfsIncomplete:
      LState := S_FILTER_INCOMPLETE;
    gfsValid:
      LState := Format(S_FILTER_VALID, [GetEnumName(TypeInfo(TS4YGridFilterOperator),
        Ord(ObjectsGrid.FilterOperator[AColumn])), ObjectsGrid.FilterValue[AColumn].ToString]);
    gfsInvalid:
      LState := S_FILTER_INVALID;
  else
    LState := S_FILTER_EMPTY;
  end;

  LastChangeLabel.Text := Format(S_FILTER_CHANGED, [AColumn.Header, ObjectsGrid.FilterText[AColumn], LState]);
end;

procedure TGridDemoForm.ObjectsGridFilterMenu(Sender: TObject; const AColumn: TColumn;
  const AItems: TS4YGridFilterMenuItems);
begin
  // The menu of the amount has an item of the application, before the item that clears the filter.
  if AColumn = AmountColumn then
    AItems.Insert(AItems.IndexOfAction(gmaClear), S_ABOVE_AVERAGE, AboveAverageClick);
end;

procedure TGridDemoForm.ObjectsGridFilterRowToggle(Sender: TObject);
begin
  // The row shown or hidden by the button of the header or by Ctrl+Shift+F: its box shows it.
  FilterVisibleCheckBox.IsChecked := ObjectsGrid.FilterRow.Visible;
end;

procedure TGridDemoForm.ObjectsGridGetFooterText(Sender: TObject; const AColumn: TColumn; var AText: string);
var
  LSum: Currency;
begin
  // The sum of all the customers, also of the ones the filter hides.
  if AllDataCheckBox.IsChecked and (AColumn = AmountColumn) then
  begin
    LSum := 0;

    for var LCustomer in FCustomers do
      LSum := LSum + LCustomer.Amount;

    AText := Format(S_ALL_DATA, [AmountColumn.ValueToString(LSum)]);
  end;
end;

procedure TGridDemoForm.ObjectsGridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
var
  LColumn: TColumn;
  LCustomer: TCustomer;
begin
  // The columns can be moved: the column is found from its index.
  LColumn := ObjectsGrid.Columns[ACol];
  LCustomer := FVisible[ARow];

  if LColumn = NameColumn then
    Value := LCustomer.Name
  else if LColumn = CityColumn then
    Value := LCustomer.City
  else if LColumn = OrdersColumn then
    Value := LCustomer.Orders
  else if LColumn = AmountColumn then
    Value := TValue.From<Currency>(LCustomer.Amount)
  else if LColumn = LastOrderColumn then
    Value := TValue.From<TDate>(LCustomer.LastOrder)
  else if LColumn = ActiveColumn then
    Value := LCustomer.Active
  else if LColumn = StatusColumn then
    Value := StatusText(LCustomer.Status);
end;

procedure TGridDemoForm.SetUpBindingsGrid;
var
  LColumn: TColumn;
  LCities: TStringList;
begin
  // The settings of the columns created by the link: a list for the city, the footer for the numbers.
  LColumn := BindingsColumn('City');

  if Assigned(LColumn) then
  begin
    LCities := TStringList.Create;
    try
      LCities.AddStrings(C_CITIES);
      LCities.Sort;
      BindingsGrid.ColumnSettings.Add(LColumn).FilterItems := LCities;
    finally
      LCities.Free;
    end;
  end;

  LColumn := BindingsColumn('Name');

  if Assigned(LColumn) then
  begin
    BindingsGrid.ColumnSettings.Add(LColumn).FooterKind := gfkText;
    BindingsGrid.ColumnSettings.FindColumn(LColumn).FooterText := S_TOTAL;
    BindingsGrid.ColumnSettings.FindColumn(LColumn).FooterAlignment := TTextAlign.Leading;
  end;

  LColumn := BindingsColumn('Orders');

  if Assigned(LColumn) then
    BindingsGrid.ColumnSettings.Add(LColumn).FooterKind := gfkSum;

  LColumn := BindingsColumn('Amount');

  if Assigned(LColumn) then
    BindingsGrid.ColumnSettings.Add(LColumn).FooterKind := gfkSum;
end;

procedure TGridDemoForm.ObjectsGridSort(Sender: TObject);
var
  LOrder: string;
  LText: string;
begin
  ShowObjects;
  LOrder := '';

  for var I := 0 to ObjectsGrid.SortCount - 1 do
  begin
    LText := ObjectsGrid.SortColumn[I].Header;

    if ObjectsGrid.SortDescending[I] then
      LText := Format(S_ORDER_DESCENDING, [LText]);

    if LOrder <> '' then
      LOrder := LOrder + ', ';

    LOrder := LOrder + LText;
  end;

  if LOrder = '' then
    LOrder := S_NO_ORDER;

  OrderLabel.Text := Format(S_ORDER, [LOrder]);
end;

procedure TGridDemoForm.ShowObjects;
begin
  // The customers that pass the filters...
  FVisible.Clear;

  for var LCustomer in FCustomers do
    if MatchesObjects(LCustomer) then
      FVisible.Add(LCustomer);

  // ...in the order of the keys, then in the order of the data.
  FVisible.Sort(TComparer<TCustomer>.Construct(
    function(const ALeft, ARight: TCustomer): Integer
    var
      LIndex: Integer;
    begin
      Result := 0;
      LIndex := 0;

      while (Result = 0) and (LIndex < ObjectsGrid.SortCount) do
      begin
        Result := CompareCustomers(ALeft, ARight, ObjectsGrid.SortColumn[LIndex]);

        if ObjectsGrid.SortDescending[LIndex] then
          Result := -Result;

        Inc(LIndex);
      end;

      if Result = 0 then
        Result := CompareValue(ALeft.Id, ARight.Id);
    end));

  // The grid keeps the values it has shown: the rows are now other customers.
  ObjectsGrid.Model.ClearCache;
  ObjectsGrid.RowCount := FVisible.Count;
  ObjectsGrid.Repaint;
  // Also when the number of rows is the same, the totals are of other customers.
  ObjectsGrid.UpdateFooter;
  UpdateRowsLabel;
end;

procedure TGridDemoForm.SortingSettingsChange(Sender: TObject);
begin
  ObjectsGrid.Sorting.Enabled := SortingEnabledCheckBox.IsChecked;
  ObjectsGrid.Sorting.MultiColumn := MultiColumnCheckBox.IsChecked;
  ObjectsGrid.Sorting.ShowOrder := ShowOrderCheckBox.IsChecked;

  if OrderBeforeCheckBox.IsChecked then
    ObjectsGrid.Sorting.OrderPosition := gopBefore
  else
    ObjectsGrid.Sorting.OrderPosition := gopAfter;

  ObjectsGrid.Sorting.OrderSpacing := Round(OrderSpacingTrackBar.Value);
  OrderSpacingLabel.Text := Format(S_ORDER_SPACING, [Round(OrderSpacingTrackBar.Value)]);
end;

function TGridDemoForm.StatusText(const AStatus: TCustomerStatus): string;
begin
  case AStatus of
    csRegular:
      Result := S_STATUS_REGULAR;
    csLost:
      Result := S_STATUS_LOST;
  else
    Result := S_STATUS_NEW;
  end;
end;

procedure TGridDemoForm.StyledGridFilter(Sender: TObject);
begin
  FStyledVisible.Clear;

  for var LCustomer in FCustomers do
    if Matches(StyledGrid, LCustomer, StyledNameColumn, StyledCityColumn, StyledOrdersColumn, StyledAmountColumn) then
      FStyledVisible.Add(LCustomer);

  StyledGrid.Model.ClearCache;
  StyledGrid.RowCount := FStyledVisible.Count;
  StyledGrid.Repaint;
  StyledGrid.UpdateFooter;
end;

procedure TGridDemoForm.StyledGridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
var
  LColumn: TColumn;
  LCustomer: TCustomer;
begin
  LColumn := StyledGrid.Columns[ACol];
  LCustomer := FStyledVisible[ARow];

  if LColumn = StyledNameColumn then
    Value := LCustomer.Name
  else if LColumn = StyledCityColumn then
    Value := LCustomer.City
  else if LColumn = StyledOrdersColumn then
    Value := LCustomer.Orders
  else if LColumn = StyledAmountColumn then
    Value := TValue.From<Currency>(LCustomer.Amount);
end;

procedure TGridDemoForm.UpdateRowsLabel;
begin
  RowsLabel.Text := Format(S_ROWS, [FVisible.Count, FCustomers.Count]);
end;

end.
