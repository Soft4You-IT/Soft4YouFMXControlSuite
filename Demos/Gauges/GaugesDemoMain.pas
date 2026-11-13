unit GaugesDemoMain;

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
  FMX.EditBox,
  FMX.SpinBox,
  FMX.Edit,
  FMX.Colors,
  Soft4You.FMX.Controls.Gauges,
  Soft4You.FMX.Controls.Gauges.Types,
  Soft4You.FMX.Controls.Gauges.Linear,
  Soft4You.FMX.Controls.Gauges.Circular;

type
  TGaugesDemoForm = class(TForm)
    DemoLayout: TLayout;
    LinearTitleLabel: TLabel;
    FirstLinearGauge: TS4YLinearGauge;
    VerticalTitleLabel: TLabel;
    VerticalGauge: TS4YLinearGauge;
    CircularTitleLabel: TLabel;
    CircularGauge: TS4YCircularGauge;
    NoteLabel: TLabel;
    SettingsScrollBox: TVertScrollBox;
    ValueSettingsLabel: TLabel;
    ValueLabel: TLabel;
    ValueTrackBar: TTrackBar;
    RangeLabel: TLabel;
    RangeLayout: TLayout;
    MinSpinBox: TSpinBox;
    MaxSpinBox: TSpinBox;
    AnimatedCheckBox: TCheckBox;
    RandomButton: TButton;
    TextSettingsLabel: TLabel;
    CaptionEdit: TEdit;
    ShowValueCheckBox: TCheckBox;
    ValueFormatLabel: TLabel;
    ValueFormatComboBox: TComboBox;
    CustomTextCheckBox: TCheckBox;
    LookSettingsLabel: TLabel;
    StyleFillCheckBox: TCheckBox;
    FillColorComboBox: TColorComboBox;
    LinearSettingsLabel: TLabel;
    OrientationLabel: TLabel;
    OrientationComboBox: TComboBox;
    TextPositionLabel: TLabel;
    TextPositionComboBox: TComboBox;
    LinearThicknessLabel: TLabel;
    LinearThicknessTrackBar: TTrackBar;
    CircularSettingsLabel: TLabel;
    ShapeLabel: TLabel;
    ShapeComboBox: TComboBox;
    StartAngleLabel: TLabel;
    StartAngleTrackBar: TTrackBar;
    SweepAngleLabel: TLabel;
    SweepAngleTrackBar: TTrackBar;
    CircularThicknessLabel: TLabel;
    CircularThicknessTrackBar: TTrackBar;
    procedure AnimatedCheckBoxChange(Sender: TObject);
    procedure AngleTrackBarChange(Sender: TObject);
    procedure CaptionEditChangeTracking(Sender: TObject);
    procedure CircularThicknessTrackBarChange(Sender: TObject);
    procedure CustomTextCheckBoxChange(Sender: TObject);
    procedure FillColorComboBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LinearThicknessTrackBarChange(Sender: TObject);
    procedure OrientationComboBoxChange(Sender: TObject);
    procedure RandomButtonClick(Sender: TObject);
    procedure RangeSpinBoxChange(Sender: TObject);
    procedure ShapeComboBoxChange(Sender: TObject);
    procedure ShowValueCheckBoxChange(Sender: TObject);
    procedure StyleFillCheckBoxChange(Sender: TObject);
    procedure TextPositionComboBoxChange(Sender: TObject);
    procedure ValueFormatComboBoxChange(Sender: TObject);
    procedure ValueTrackBarChange(Sender: TObject);
  private
    function GetGauges: TArray<TS4YCustomGauge>;
    procedure GaugeGetValueText(Sender: TObject; const AValue: Single; var AText: string);
    procedure UpdateAngleLabels;
  end;

var
  GaugesDemoForm: TGaugesDemoForm;

implementation

{$R *.fmx}

resourcestring
  S_CUSTOM_VALUE_TEXT = '%.0f of %.0f';
  S_START_ANGLE = 'StartAngle: %.0f';
  S_SWEEP_ANGLE = 'SweepAngle: %.0f';
  S_THICKNESS = 'Thickness: %.0f';
  S_VALUE = 'Value: %.1f';

const
  C_ANIMATION_DURATION = 0.3;
  // Formats of the items of ValueFormatComboBox, in the same order.
  C_VALUE_FORMATS: array[0..3] of string = ('%.0f', '%.1f %%', '%.0f GB', '');
  // Angles of the items of ShapeComboBox, in the same order: ring, open arc, half circle.
  C_SHAPE_START_ANGLES: array[0..2] of Single = (0, -135, -90);
  C_SHAPE_SWEEP_ANGLES: array[0..2] of Single = (360, 270, 180);

procedure TGaugesDemoForm.AnimatedCheckBoxChange(Sender: TObject);
var
  LDuration: Single;
begin
  LDuration := 0;

  if AnimatedCheckBox.IsChecked then
    LDuration := C_ANIMATION_DURATION;

  for var LGauge in GetGauges do
    LGauge.AnimationDuration := LDuration;
end;

procedure TGaugesDemoForm.AngleTrackBarChange(Sender: TObject);
begin
  CircularGauge.StartAngle := StartAngleTrackBar.Value;
  CircularGauge.SweepAngle := SweepAngleTrackBar.Value;
  UpdateAngleLabels;
end;

procedure TGaugesDemoForm.CaptionEditChangeTracking(Sender: TObject);
begin
  for var LGauge in GetGauges do
    LGauge.Caption := CaptionEdit.Text;
end;

procedure TGaugesDemoForm.CircularThicknessTrackBarChange(Sender: TObject);
begin
  CircularGauge.Thickness := CircularThicknessTrackBar.Value;
  CircularThicknessLabel.Text := Format(S_THICKNESS, [CircularThicknessTrackBar.Value]);
end;

procedure TGaugesDemoForm.CustomTextCheckBoxChange(Sender: TObject);
begin
  for var LGauge in GetGauges do
  begin
    if CustomTextCheckBox.IsChecked then
      LGauge.OnGetValueText := GaugeGetValueText
    else
      LGauge.OnGetValueText := nil;

    LGauge.Repaint;
  end;
end;

procedure TGaugesDemoForm.FillColorComboBoxChange(Sender: TObject);
begin
  // Choosing a color takes the fill from FillBrush instead of the style.
  if StyleFillCheckBox.IsChecked then
    StyleFillCheckBox.IsChecked := False
  else
    StyleFillCheckBoxChange(StyleFillCheckBox);
end;

procedure TGaugesDemoForm.FormCreate(Sender: TObject);
begin
  UpdateAngleLabels;
  ValueTrackBarChange(ValueTrackBar);
  LinearThicknessTrackBarChange(LinearThicknessTrackBar);
  CircularThicknessTrackBarChange(CircularThicknessTrackBar);
end;

procedure TGaugesDemoForm.GaugeGetValueText(Sender: TObject; const AValue: Single; var AText: string);
begin
  AText := Format(S_CUSTOM_VALUE_TEXT, [AValue, (Sender as TS4YCustomGauge).Max]);
end;

function TGaugesDemoForm.GetGauges: TArray<TS4YCustomGauge>;
begin
  Result := [FirstLinearGauge, VerticalGauge, CircularGauge];
end;

procedure TGaugesDemoForm.LinearThicknessTrackBarChange(Sender: TObject);
begin
  FirstLinearGauge.Thickness := LinearThicknessTrackBar.Value;
  VerticalGauge.Thickness := LinearThicknessTrackBar.Value;
  LinearThicknessLabel.Text := Format(S_THICKNESS, [LinearThicknessTrackBar.Value]);
end;

procedure TGaugesDemoForm.OrientationComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TOrientation: horizontal, vertical
  FirstLinearGauge.Orientation := TOrientation(OrientationComboBox.ItemIndex);
end;

procedure TGaugesDemoForm.RandomButtonClick(Sender: TObject);
begin
  ValueTrackBar.Value := ValueTrackBar.Min + Random * (ValueTrackBar.Max - ValueTrackBar.Min);
end;

procedure TGaugesDemoForm.RangeSpinBoxChange(Sender: TObject);
begin
  // A Min greater than Max moves Max, and the other way round: the spin boxes follow the gauges.
  for var LGauge in GetGauges do
  begin
    if Sender = MinSpinBox then
      LGauge.Min := MinSpinBox.Value
    else
      LGauge.Max := MaxSpinBox.Value;
  end;

  MinSpinBox.Value := CircularGauge.Min;
  MaxSpinBox.Value := CircularGauge.Max;
  ValueTrackBar.Min := CircularGauge.Min;
  ValueTrackBar.Max := CircularGauge.Max;
  ValueTrackBar.Value := CircularGauge.Value;
  ValueLabel.Text := Format(S_VALUE, [CircularGauge.Value]);
end;

procedure TGaugesDemoForm.ShapeComboBoxChange(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := ShapeComboBox.ItemIndex;

  if LIndex < 0 then
    Exit;

  // The track bars apply the angles to the gauge.
  StartAngleTrackBar.Value := C_SHAPE_START_ANGLES[LIndex];
  SweepAngleTrackBar.Value := C_SHAPE_SWEEP_ANGLES[LIndex];
end;

procedure TGaugesDemoForm.ShowValueCheckBoxChange(Sender: TObject);
begin
  for var LGauge in GetGauges do
    LGauge.ShowValue := ShowValueCheckBox.IsChecked;
end;

procedure TGaugesDemoForm.StyleFillCheckBoxChange(Sender: TObject);
begin
  for var LGauge in GetGauges do
  begin
    // Changing FillBrush removes gsbFill from StyledBrushes; putting it back reads the fill from the style.
    if StyleFillCheckBox.IsChecked then
      LGauge.StyledBrushes := LGauge.StyledBrushes + [gsbFill]
    else
      LGauge.FillBrush.Color := FillColorComboBox.Color;
  end;
end;

procedure TGaugesDemoForm.TextPositionComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YGaugeTextPosition: none, before, after
  FirstLinearGauge.TextPosition := TS4YGaugeTextPosition(TextPositionComboBox.ItemIndex);
  VerticalGauge.TextPosition := TS4YGaugeTextPosition(TextPositionComboBox.ItemIndex);
end;

procedure TGaugesDemoForm.UpdateAngleLabels;
begin
  StartAngleLabel.Text := Format(S_START_ANGLE, [StartAngleTrackBar.Value]);
  SweepAngleLabel.Text := Format(S_SWEEP_ANGLE, [SweepAngleTrackBar.Value]);
end;

procedure TGaugesDemoForm.ValueFormatComboBoxChange(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := ValueFormatComboBox.ItemIndex;

  if LIndex < 0 then
    Exit;

  for var LGauge in GetGauges do
    LGauge.ValueFormat := C_VALUE_FORMATS[LIndex];
end;

procedure TGaugesDemoForm.ValueTrackBarChange(Sender: TObject);
begin
  for var LGauge in GetGauges do
    LGauge.Value := ValueTrackBar.Value;

  ValueLabel.Text := Format(S_VALUE, [ValueTrackBar.Value]);
end;

end.
