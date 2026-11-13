unit ChartsDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.ListBox,
  FMX.Layouts,
  Soft4You.FMX.Controls.Charts.Types,
  Soft4You.FMX.Controls.Charts,
  Soft4You.FMX.Controls.Charts.Categories,
  Soft4You.FMX.Controls.Charts.Pie,
  Soft4You.FMX.Controls.Charts.Bar,
  Soft4You.FMX.Controls.Charts.Line;

type
  TChartsDemoForm = class(TForm)
    DemoLayout: TLayout;
    OrdersPie: TS4YPieChart;
    SalesBar: TS4YBarChart;
    SalesLine: TS4YLineChart;
    StatusLabel: TLabel;
    SettingsScrollBox: TVertScrollBox;
    GeneralSettingsLabel: TLabel;
    LegendLabel: TLabel;
    LegendComboBox: TComboBox;
    AnimatedCheckBox: TCheckBox;
    ValueFormatLabel: TLabel;
    ValueFormatComboBox: TComboBox;
    PaletteCheckBox: TCheckBox;
    RandomButton: TButton;
    PieSettingsLabel: TLabel;
    InnerRadiusLabel: TLabel;
    InnerRadiusTrackBar: TTrackBar;
    StartAngleLabel: TLabel;
    StartAngleTrackBar: TTrackBar;
    LabelContentLabel: TLabel;
    LabelContentComboBox: TComboBox;
    LabelPositionLabel: TLabel;
    LabelPositionComboBox: TComboBox;
    ShowTotalCheckBox: TCheckBox;
    BarSettingsLabel: TLabel;
    OrientationLabel: TLabel;
    OrientationComboBox: TComboBox;
    BarWidthLabel: TLabel;
    BarWidthTrackBar: TTrackBar;
    ShowValuesCheckBox: TCheckBox;
    AxesSettingsLabel: TLabel;
    GridLinesCheckBox: TCheckBox;
    AutoRangeCheckBox: TCheckBox;
    ValueAxisCheckBox: TCheckBox;
    CategoryAxisCheckBox: TCheckBox;
    LineSettingsLabel: TLabel;
    LineThicknessLabel: TLabel;
    LineThicknessTrackBar: TTrackBar;
    ShowPointsCheckBox: TCheckBox;
    PointSizeLabel: TLabel;
    PointSizeTrackBar: TTrackBar;
    FillAreaCheckBox: TCheckBox;
    procedure AnimatedCheckBoxChange(Sender: TObject);
    procedure AxesCheckBoxChange(Sender: TObject);
    procedure BarWidthTrackBarChange(Sender: TObject);
    procedure ChartItemClick(Sender: TObject; const ASeriesIndex, AItemIndex: Integer);
    procedure FillAreaCheckBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure InnerRadiusTrackBarChange(Sender: TObject);
    procedure LabelContentComboBoxChange(Sender: TObject);
    procedure LabelPositionComboBoxChange(Sender: TObject);
    procedure LegendComboBoxChange(Sender: TObject);
    procedure LineThicknessTrackBarChange(Sender: TObject);
    procedure OrientationComboBoxChange(Sender: TObject);
    procedure PaletteCheckBoxChange(Sender: TObject);
    procedure PointSizeTrackBarChange(Sender: TObject);
    procedure RandomButtonClick(Sender: TObject);
    procedure ShowPointsCheckBoxChange(Sender: TObject);
    procedure ShowTotalCheckBoxChange(Sender: TObject);
    procedure ShowValuesCheckBoxChange(Sender: TObject);
    procedure StartAngleTrackBarChange(Sender: TObject);
    procedure ValueFormatComboBoxChange(Sender: TObject);
  private
    function GetCharts: TArray<TS4YCustomChart>;
    function GetCategoryCharts: TArray<TS4YCustomCategoryChart>;
  end;

var
  ChartsDemoForm: TChartsDemoForm;

implementation

{$R *.fmx}

resourcestring
  S_BAR_WIDTH = 'BarWidth: %.0f %%';
  S_CLICKED_CATEGORY = 'Clicked: %s, series %s, category %s';
  S_CLICKED_SLICE = 'Clicked: %s, slice %s';
  S_INNER_RADIUS = 'InnerRadius: %.0f %%';
  S_LINE_THICKNESS = 'LineThickness: %.0f';
  S_POINT_SIZE = 'PointSize: %.0f';
  S_START_ANGLE = 'StartAngle: %.0f';

const
  C_ANIMATION_DURATION = 0.3;
  // Formats of the items of ValueFormatComboBox, in the same order.
  C_VALUE_FORMATS: array[0..2] of string = ('%.0f', '%.1f', '%.0f k');
  // Palette set by PaletteCheckBox, in place of the one of the style.
  C_OWN_PALETTE: array[0..3] of TAlphaColor = ($FF26A69A, $FFFFA726, $FF7E57C2, $FFEC407A);
  // Range of the value axis when AutoRangeCheckBox is not checked.
  C_FIXED_MAX = 200;
  // Range of the random values.
  C_RANDOM_MIN = 10;
  C_RANDOM_RANGE = 90;

procedure TChartsDemoForm.AnimatedCheckBoxChange(Sender: TObject);
var
  LDuration: Single;
begin
  LDuration := 0;

  if AnimatedCheckBox.IsChecked then
    LDuration := C_ANIMATION_DURATION;

  for var LChart in GetCharts do
    LChart.AnimationDuration := LDuration;
end;

procedure TChartsDemoForm.AxesCheckBoxChange(Sender: TObject);
begin
  for var LChart in GetCategoryCharts do
  begin
    LChart.ValueAxis.GridLines := GridLinesCheckBox.IsChecked;
    LChart.ValueAxis.AutoRange := AutoRangeCheckBox.IsChecked;
    LChart.ValueAxis.Max := C_FIXED_MAX;
    LChart.ValueAxis.Visible := ValueAxisCheckBox.IsChecked;
    LChart.CategoryAxis.Visible := CategoryAxisCheckBox.IsChecked;
  end;
end;

procedure TChartsDemoForm.BarWidthTrackBarChange(Sender: TObject);
begin
  SalesBar.BarWidth := BarWidthTrackBar.Value;
  BarWidthLabel.Text := Format(S_BAR_WIDTH, [BarWidthTrackBar.Value]);
end;

procedure TChartsDemoForm.ChartItemClick(Sender: TObject; const ASeriesIndex, AItemIndex: Integer);
var
  LCategoryChart: TS4YCustomCategoryChart;
begin
  if Sender is TS4YPieChart then
  begin
    StatusLabel.Text := Format(S_CLICKED_SLICE, [TComponent(Sender).Name,
      TS4YPieChart(Sender).DrawnSlices[AItemIndex].Caption]);
    Exit;
  end;

  LCategoryChart := Sender as TS4YCustomCategoryChart;
  StatusLabel.Text := Format(S_CLICKED_CATEGORY, [LCategoryChart.Name, LCategoryChart.DrawnSeries[ASeriesIndex].Caption,
    LCategoryChart.DrawnCategories[AItemIndex].Caption]);
end;

procedure TChartsDemoForm.FillAreaCheckBoxChange(Sender: TObject);
begin
  SalesLine.FillArea := FillAreaCheckBox.IsChecked;
end;

procedure TChartsDemoForm.FormCreate(Sender: TObject);
begin
  InnerRadiusTrackBarChange(InnerRadiusTrackBar);
  StartAngleTrackBarChange(StartAngleTrackBar);
  BarWidthTrackBarChange(BarWidthTrackBar);
  LineThicknessTrackBarChange(LineThicknessTrackBar);
  PointSizeTrackBarChange(PointSizeTrackBar);
end;

function TChartsDemoForm.GetCategoryCharts: TArray<TS4YCustomCategoryChart>;
begin
  Result := [SalesBar, SalesLine];
end;

function TChartsDemoForm.GetCharts: TArray<TS4YCustomChart>;
begin
  Result := [OrdersPie, SalesBar, SalesLine];
end;

procedure TChartsDemoForm.InnerRadiusTrackBarChange(Sender: TObject);
begin
  OrdersPie.InnerRadius := InnerRadiusTrackBar.Value;
  InnerRadiusLabel.Text := Format(S_INNER_RADIUS, [InnerRadiusTrackBar.Value]);
end;

procedure TChartsDemoForm.LabelContentComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YPieLabelContent: none, value, percent, caption
  OrdersPie.LabelContent := TS4YPieLabelContent(LabelContentComboBox.ItemIndex);
end;

procedure TChartsDemoForm.LabelPositionComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YPieLabelPosition: inside, outside
  OrdersPie.LabelPosition := TS4YPieLabelPosition(LabelPositionComboBox.ItemIndex);
end;

procedure TChartsDemoForm.LegendComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YChartLegendPosition: none, top, bottom, left, right
  for var LChart in GetCharts do
    LChart.Legend.Position := TS4YChartLegendPosition(LegendComboBox.ItemIndex);
end;

procedure TChartsDemoForm.LineThicknessTrackBarChange(Sender: TObject);
begin
  SalesLine.LineThickness := LineThicknessTrackBar.Value;
  LineThicknessLabel.Text := Format(S_LINE_THICKNESS, [LineThicknessTrackBar.Value]);
end;

procedure TChartsDemoForm.OrientationComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TOrientation: horizontal, vertical
  SalesBar.Orientation := TOrientation(OrientationComboBox.ItemIndex);
end;

procedure TChartsDemoForm.PaletteCheckBoxChange(Sender: TObject);
begin
  for var LChart in GetCharts do
  begin
    LChart.Palette.BeginUpdate;
    try
      LChart.Palette.Clear;

      // Without colors of its own, the palette comes from the style.
      if PaletteCheckBox.IsChecked then
      begin
        for var LColor in C_OWN_PALETTE do
          LChart.Palette.AddColor(LColor);
      end;
    finally
      LChart.Palette.EndUpdate;
    end;
  end;
end;

procedure TChartsDemoForm.PointSizeTrackBarChange(Sender: TObject);
begin
  SalesLine.PointSize := PointSizeTrackBar.Value;
  PointSizeLabel.Text := Format(S_POINT_SIZE, [PointSizeTrackBar.Value]);
end;

procedure TChartsDemoForm.RandomButtonClick(Sender: TObject);
begin
  // New values: the charts move to them with the animation.
  OrdersPie.Slices.BeginUpdate;
  try
    for var LIndex := 0 to OrdersPie.Slices.Count - 1 do
      OrdersPie.Slices[LIndex].Value := C_RANDOM_MIN + Random(C_RANDOM_RANGE);
  finally
    OrdersPie.Slices.EndUpdate;
  end;

  for var LChart in GetCategoryCharts do
  begin
    LChart.Categories.BeginUpdate;
    try
      for var LCategory := 0 to LChart.Categories.Count - 1 do
      begin
        for var LSeries := 0 to LChart.Series.Count - 1 do
          LChart.Categories[LCategory].Value[LSeries] := C_RANDOM_MIN + Random(C_RANDOM_RANGE);
      end;
    finally
      LChart.Categories.EndUpdate;
    end;
  end;
end;

procedure TChartsDemoForm.ShowPointsCheckBoxChange(Sender: TObject);
begin
  SalesLine.ShowPoints := ShowPointsCheckBox.IsChecked;
end;

procedure TChartsDemoForm.ShowTotalCheckBoxChange(Sender: TObject);
begin
  OrdersPie.ShowTotal := ShowTotalCheckBox.IsChecked;
end;

procedure TChartsDemoForm.ShowValuesCheckBoxChange(Sender: TObject);
begin
  SalesBar.ShowValues := ShowValuesCheckBox.IsChecked;
end;

procedure TChartsDemoForm.StartAngleTrackBarChange(Sender: TObject);
begin
  OrdersPie.StartAngle := StartAngleTrackBar.Value;
  StartAngleLabel.Text := Format(S_START_ANGLE, [StartAngleTrackBar.Value]);
end;

procedure TChartsDemoForm.ValueFormatComboBoxChange(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := ValueFormatComboBox.ItemIndex;

  if LIndex < 0 then
    Exit;

  for var LChart in GetCharts do
    LChart.ValueFormat := C_VALUE_FORMATS[LIndex];
end;

end.
