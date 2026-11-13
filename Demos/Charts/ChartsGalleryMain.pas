unit ChartsGalleryMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.Rtti,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.TabControl,
  FMX.Layouts,
  FMX.Objects,
  FMX.Grid.Style,
  FMX.Grid,
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
  Data.Bind.Controls,
  Fmx.Bind.Navigator,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Soft4You.FMX.Controls.Charts,
  Soft4You.FMX.Controls.Charts.Categories,
  Soft4You.FMX.Controls.Charts.Pie,
  Soft4You.FMX.Controls.Charts.Bar,
  Soft4You.FMX.Controls.Charts.Line,
  Soft4You.FMX.Controls.Charts.Bindings;

type
  TChartsGalleryForm = class(TForm)
    GalleryTabControl: TTabControl;
    PieTab: TTabItem;
    PieLabel: TLabel;
    PercentPie: TS4YPieChart;
    RingPie: TS4YPieChart;
    OutsidePie: TS4YPieChart;
    BarTab: TTabItem;
    BarLabel: TLabel;
    ValuesBar: TS4YBarChart;
    HorizontalBar: TS4YBarChart;
    ProfitBar: TS4YBarChart;
    LineTab: TTabItem;
    LineLabel: TLabel;
    TwoSeriesLine: TS4YLineChart;
    AreaLine: TS4YLineChart;
    StyleBookTab: TTabItem;
    StyleBookLabel: TLabel;
    PastelPie: TS4YPieChart;
    RoundBar: TS4YBarChart;
    SoftLine: TS4YLineChart;
    DarkTab: TTabItem;
    DarkBackground: TRectangle;
    DarkLabel: TLabel;
    DarkPie: TS4YPieChart;
    DarkBar: TS4YBarChart;
    DarkLine: TS4YLineChart;
    BindingsTab: TTabItem;
    BindingsLabel: TLabel;
    SalesNavigator: TBindNavigator;
    SalesGrid: TStringGrid;
    SalesPie: TS4YPieChart;
    SalesBar: TS4YBarChart;
    SalesStatusLabel: TLabel;
    SalesTable: TFDMemTable;
    SalesTableRegion: TStringField;
    SalesTableSales: TCurrencyField;
    SalesTableTarget: TCurrencyField;
    SalesBindSource: TBindSourceDB;
    GalleryBindingsList: TBindingsList;
    LinkGridToDataSourceGrid: TLinkGridToDataSource;
    LinkGridToDataSourcePie: TLinkGridToDataSource;
    LinkGridToDataSourceBar: TLinkGridToDataSource;
    GalleryStyleBook: TStyleBook;
    procedure FormCreate(Sender: TObject);
    procedure SalesBarSeriesBound(Sender: TObject; const ASeries: TS4YChartSeries);
    procedure SalesChartItemClick(Sender: TObject; const ASeriesIndex, AItemIndex: Integer);
    procedure SalesPieSliceBound(Sender: TObject; const ASlice: TS4YPieSlice);
  end;

var
  ChartsGalleryForm: TChartsGalleryForm;

implementation

{$R *.fmx}

resourcestring
  S_SALES_STATUS = 'Clicked: %s. The current record of the grid has moved to it.';

const
  // Sales under this amount are drawn in red by OnSliceBound.
  C_LOW_SALES = 20000;
  C_LOW_SALES_COLOR: TAlphaColor = $FFE53935;
  C_TARGET_COLOR: TAlphaColor = $FFB0BEC5;
  C_TARGET_FIELD = 'Target';

procedure TChartsGalleryForm.FormCreate(Sender: TObject);
begin
  // The gallery always opens on the first tab, whichever tab was selected when the form was saved.
  GalleryTabControl.TabIndex := 0;

  // The data of the LiveBindings tab: the links fill the grid and the charts when the table opens.
  SalesTable.CreateDataSet;
  SalesTable.AppendRecord(['North', 48500, 45000]);
  SalesTable.AppendRecord(['South', 31200, 35000]);
  SalesTable.AppendRecord(['East', 27800, 25000]);
  SalesTable.AppendRecord(['West', 18400, 22000]);
  SalesTable.AppendRecord(['Center', 12900, 15000]);
  SalesTable.First;
end;

procedure TChartsGalleryForm.SalesBarSeriesBound(Sender: TObject; const ASeries: TS4YChartSeries);
begin
  // The series of the targets in gray, the sales keep the palette.
  if SameText(ASeries.Caption, C_TARGET_FIELD) then
    ASeries.Color := C_TARGET_COLOR;
end;

procedure TChartsGalleryForm.SalesChartItemClick(Sender: TObject; const ASeriesIndex, AItemIndex: Integer);
begin
  SalesStatusLabel.Text := Format(S_SALES_STATUS, [SalesTableRegion.AsString]);
end;

procedure TChartsGalleryForm.SalesPieSliceBound(Sender: TObject; const ASlice: TS4YPieSlice);
begin
  // OnSliceBound fires after every change of the data: a slice is red only while its sales are low.
  if ASlice.Value < C_LOW_SALES then
    ASlice.Color := C_LOW_SALES_COLOR;
end;

end.
