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
  FMX.TabControl,
  Soft4You.FMX.Controls.Gauges,
  Soft4You.FMX.Controls.Gauges.Types,
  Soft4You.FMX.Controls.Gauges.Scales,
  Soft4You.FMX.Controls.Gauges.Linear,
  Soft4You.FMX.Controls.Gauges.Circular,
  Soft4You.FMX.Controls.Gauges.LinearMeter,
  Soft4You.FMX.Controls.Gauges.CircularMeter,
  Soft4You.FMX.Controls.Gauges.SkinCircular,
  Soft4You.FMX.Controls.Gauges.SkinLinear;

type
  TGaugesDemoForm = class(TForm)
    DemoTabControl: TTabControl;
    GaugesTab: TTabItem;
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
    ReversedCheckBox: TCheckBox;
    CircularThicknessLabel: TLabel;
    CircularThicknessTrackBar: TTrackBar;
    MetersTab: TTabItem;
    MetersLayout: TLayout;
    CircularMeterTitleLabel: TLabel;
    CircularMeter: TS4YCircularMeter;
    VerticalMeterTitleLabel: TLabel;
    VerticalMeter: TS4YLinearMeter;
    LinearMeterTitleLabel: TLabel;
    LinearMeter: TS4YLinearMeter;
    MetersNoteLabel: TLabel;
    MeterSettingsScrollBox: TVertScrollBox;
    MeterValueSettingsLabel: TLabel;
    MeterValueLabel: TLabel;
    MeterValueTrackBar: TTrackBar;
    MeterRandomButton: TButton;
    MeterShapeSettingsLabel: TLabel;
    MeterShapeComboBox: TComboBox;
    MeterReversedCheckBox: TCheckBox;
    GraduationSettingsLabel: TLabel;
    GraduationVisibleCheckBox: TCheckBox;
    ShowLabelsCheckBox: TCheckBox;
    MajorStepLabel: TLabel;
    MajorStepComboBox: TComboBox;
    CircularGraduationLabel: TLabel;
    CircularGraduationComboBox: TComboBox;
    LinearGraduationLabel: TLabel;
    LinearGraduationComboBox: TComboBox;
    RangesSettingsLabel: TLabel;
    RangesCheckBox: TCheckBox;
    RangeTrackCheckBox: TCheckBox;
    RangeInsideCheckBox: TCheckBox;
    RangeOutsideCheckBox: TCheckBox;
    FillFromRangeCheckBox: TCheckBox;
    TargetSettingsLabel: TLabel;
    ShowTargetCheckBox: TCheckBox;
    TargetLabel: TLabel;
    TargetTrackBar: TTrackBar;
    NeedleSettingsLabel: TLabel;
    NeedleVisibleCheckBox: TCheckBox;
    NeedleLengthLabel: TLabel;
    NeedleLengthTrackBar: TTrackBar;
    CircularShowFillCheckBox: TCheckBox;
    PointerVisibleCheckBox: TCheckBox;
    PointerPositionLabel: TLabel;
    PointerPositionComboBox: TComboBox;
    LinearShowFillCheckBox: TCheckBox;
    SkinsTab: TTabItem;
    SkinsLayout: TLayout;
    SkinCircularTitleLabel: TLabel;
    SkinCircularGauge: TS4YSkinCircularGauge;
    SkinLinearTitleLabel: TLabel;
    SkinLinearGauge: TS4YSkinLinearGauge;
    SkinsNoteLabel: TLabel;
    SkinSettingsScrollBox: TVertScrollBox;
    SkinValueSettingsLabel: TLabel;
    SkinValueLabel: TLabel;
    SkinValueTrackBar: TTrackBar;
    SkinAnimatedCheckBox: TCheckBox;
    SkinRandomButton: TButton;
    SkinTextSettingsLabel: TLabel;
    SkinCaptionEdit: TEdit;
    SkinShowValueCheckBox: TCheckBox;
    SkinLinearSettingsLabel: TLabel;
    SkinReversedCheckBox: TCheckBox;
    procedure AnimatedCheckBoxChange(Sender: TObject);
    procedure AngleTrackBarChange(Sender: TObject);
    procedure CaptionEditChangeTracking(Sender: TObject);
    procedure CircularThicknessTrackBarChange(Sender: TObject);
    procedure CustomTextCheckBoxChange(Sender: TObject);
    procedure FillColorComboBoxChange(Sender: TObject);
    procedure FillFromRangeCheckBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GraduationCheckBoxChange(Sender: TObject);
    procedure GraduationPositionComboBoxChange(Sender: TObject);
    procedure LinearThicknessTrackBarChange(Sender: TObject);
    procedure MajorStepComboBoxChange(Sender: TObject);
    procedure MeterRandomButtonClick(Sender: TObject);
    procedure MeterReversedCheckBoxChange(Sender: TObject);
    procedure MeterShapeComboBoxChange(Sender: TObject);
    procedure MeterValueTrackBarChange(Sender: TObject);
    procedure NeedleChange(Sender: TObject);
    procedure OrientationComboBoxChange(Sender: TObject);
    procedure PointerChange(Sender: TObject);
    procedure RandomButtonClick(Sender: TObject);
    procedure RangePlacementCheckBoxChange(Sender: TObject);
    procedure RangesCheckBoxChange(Sender: TObject);
    procedure RangeSpinBoxChange(Sender: TObject);
    procedure ReversedCheckBoxChange(Sender: TObject);
    procedure ShapeComboBoxChange(Sender: TObject);
    procedure ShowFillCheckBoxChange(Sender: TObject);
    procedure ShowValueCheckBoxChange(Sender: TObject);
    procedure SkinAnimatedCheckBoxChange(Sender: TObject);
    procedure SkinCaptionEditChangeTracking(Sender: TObject);
    procedure SkinRandomButtonClick(Sender: TObject);
    procedure SkinReversedCheckBoxChange(Sender: TObject);
    procedure SkinShowValueCheckBoxChange(Sender: TObject);
    procedure SkinValueTrackBarChange(Sender: TObject);
    procedure StyleFillCheckBoxChange(Sender: TObject);
    procedure TargetChange(Sender: TObject);
    procedure TextPositionComboBoxChange(Sender: TObject);
    procedure ValueFormatComboBoxChange(Sender: TObject);
    procedure ValueTrackBarChange(Sender: TObject);
  private
    procedure AddRanges(const ARanges: TS4YMeterRanges);
    function GetGauges: TArray<TS4YCustomGauge>;
    function GetLinearMeters: TArray<TS4YLinearMeter>;
    function GetSkinGauges: TArray<TS4YCustomGauge>;
    procedure GaugeGetValueText(Sender: TObject; const AValue: Single; var AText: string);
    procedure UpdateAngleLabels;
  end;

var
  GaugesDemoForm: TGaugesDemoForm;

implementation

{$R *.fmx}

resourcestring
  S_CUSTOM_VALUE_TEXT = '%.0f of %.0f';
  S_NEEDLE_LENGTH = 'Needle.Length: %.0f';
  S_START_ANGLE = 'StartAngle: %.0f';
  S_SWEEP_ANGLE = 'SweepAngle: %.0f';
  S_TARGET = 'Target: %.0f';
  S_THICKNESS = 'Thickness: %.0f';
  S_VALUE = 'Value: %.1f';

const
  C_ANIMATION_DURATION = 0.3;
  // Steps of the items of MajorStepComboBox, in the same order: 0 is automatic.
  C_MAJOR_STEPS: array[0..3] of Single = (0, 10, 20, 25);
  // Ranges of the meters: green, yellow and red zones.
  C_GREEN_RANGE_END = 60;
  C_YELLOW_RANGE_END = 80;
  C_GREEN_RANGE_COLOR: TAlphaColor = $FF43A047;
  C_YELLOW_RANGE_COLOR: TAlphaColor = $FFFDD835;
  C_RED_RANGE_COLOR: TAlphaColor = $FFE53935;
  // Formats of the items of ValueFormatComboBox, in the same order.
  C_VALUE_FORMATS: array[0..3] of string = ('%.0f', '%.1f %%', '%.0f GB', '');
  // Angles and directions of the items of ShapeComboBox, in the same order: ring, open arc, half circle,
  // upside-down half circle, half circle on the right.
  C_SHAPE_START_ANGLES: array[0..4] of Single = (0, -135, -90, -90, 180);
  C_SHAPE_SWEEP_ANGLES: array[0..4] of Single = (360, 270, 180, 180, 180);
  C_SHAPE_REVERSED: array[0..4] of Boolean = (False, False, False, True, True);
  // The same for the items of MeterShapeComboBox: open arc, half circle, upside-down half circle, half
  // circle on the right, ring.
  C_METER_SHAPE_START_ANGLES: array[0..4] of Single = (-135, -90, -90, 180, 0);
  C_METER_SHAPE_SWEEP_ANGLES: array[0..4] of Single = (270, 180, 180, 180, 360);
  C_METER_SHAPE_REVERSED: array[0..4] of Boolean = (False, False, True, True, False);

procedure TGaugesDemoForm.AddRanges(const ARanges: TS4YMeterRanges);
begin
  ARanges.Add(0, C_GREEN_RANGE_END, C_GREEN_RANGE_COLOR);
  ARanges.Add(C_GREEN_RANGE_END, C_YELLOW_RANGE_END, C_YELLOW_RANGE_COLOR);
  ARanges.Add(C_YELLOW_RANGE_END, 100, C_RED_RANGE_COLOR);
end;

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

procedure TGaugesDemoForm.FillFromRangeCheckBoxChange(Sender: TObject);
begin
  CircularMeter.FillFromRange := FillFromRangeCheckBox.IsChecked;

  for var LMeter in GetLinearMeters do
    LMeter.FillFromRange := FillFromRangeCheckBox.IsChecked;
end;

procedure TGaugesDemoForm.FormCreate(Sender: TObject);
begin
  // The demo always opens on the first tab, whichever tab was selected when the form was saved.
  DemoTabControl.TabIndex := 0;
  UpdateAngleLabels;
  ValueTrackBarChange(ValueTrackBar);
  LinearThicknessTrackBarChange(LinearThicknessTrackBar);
  CircularThicknessTrackBarChange(CircularThicknessTrackBar);
  MeterValueTrackBarChange(MeterValueTrackBar);
  RangesCheckBoxChange(RangesCheckBox);
  TargetChange(TargetTrackBar);
  NeedleChange(NeedleLengthTrackBar);
  SkinValueTrackBarChange(SkinValueTrackBar);
end;

procedure TGaugesDemoForm.GaugeGetValueText(Sender: TObject; const AValue: Single; var AText: string);
begin
  AText := Format(S_CUSTOM_VALUE_TEXT, [AValue, (Sender as TS4YCustomGauge).Max]);
end;

function TGaugesDemoForm.GetGauges: TArray<TS4YCustomGauge>;
begin
  Result := [FirstLinearGauge, VerticalGauge, CircularGauge];
end;

function TGaugesDemoForm.GetLinearMeters: TArray<TS4YLinearMeter>;
begin
  Result := [LinearMeter, VerticalMeter];
end;

function TGaugesDemoForm.GetSkinGauges: TArray<TS4YCustomGauge>;
begin
  Result := [SkinCircularGauge, SkinLinearGauge];
end;

procedure TGaugesDemoForm.GraduationCheckBoxChange(Sender: TObject);
begin
  CircularMeter.Graduation.Visible := GraduationVisibleCheckBox.IsChecked;
  CircularMeter.Graduation.ShowLabels := ShowLabelsCheckBox.IsChecked;

  for var LMeter in GetLinearMeters do
  begin
    LMeter.Graduation.Visible := GraduationVisibleCheckBox.IsChecked;
    LMeter.Graduation.ShowLabels := ShowLabelsCheckBox.IsChecked;
  end;
end;

procedure TGaugesDemoForm.GraduationPositionComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YGaugeArcSide and TS4YGaugeBarSide.
  if CircularGraduationComboBox.ItemIndex >= 0 then
    CircularMeter.Graduation.Position := TS4YGaugeArcSide(CircularGraduationComboBox.ItemIndex);

  if LinearGraduationComboBox.ItemIndex < 0 then
    Exit;

  for var LMeter in GetLinearMeters do
    LMeter.Graduation.Position := TS4YGaugeBarSide(LinearGraduationComboBox.ItemIndex);
end;

procedure TGaugesDemoForm.LinearThicknessTrackBarChange(Sender: TObject);
begin
  FirstLinearGauge.Thickness := LinearThicknessTrackBar.Value;
  VerticalGauge.Thickness := LinearThicknessTrackBar.Value;
  LinearThicknessLabel.Text := Format(S_THICKNESS, [LinearThicknessTrackBar.Value]);
end;

procedure TGaugesDemoForm.MajorStepComboBoxChange(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := MajorStepComboBox.ItemIndex;

  if LIndex < 0 then
    Exit;

  CircularMeter.Graduation.MajorStep := C_MAJOR_STEPS[LIndex];

  for var LMeter in GetLinearMeters do
    LMeter.Graduation.MajorStep := C_MAJOR_STEPS[LIndex];
end;

procedure TGaugesDemoForm.MeterRandomButtonClick(Sender: TObject);
begin
  MeterValueTrackBar.Value := MeterValueTrackBar.Min + Random * (MeterValueTrackBar.Max - MeterValueTrackBar.Min);
end;

procedure TGaugesDemoForm.MeterReversedCheckBoxChange(Sender: TObject);
begin
  CircularMeter.Reversed := MeterReversedCheckBox.IsChecked;
end;

procedure TGaugesDemoForm.MeterShapeComboBoxChange(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := MeterShapeComboBox.ItemIndex;

  if LIndex < 0 then
    Exit;

  CircularMeter.StartAngle := C_METER_SHAPE_START_ANGLES[LIndex];
  CircularMeter.SweepAngle := C_METER_SHAPE_SWEEP_ANGLES[LIndex];
  // The check box applies the direction to the meter.
  MeterReversedCheckBox.IsChecked := C_METER_SHAPE_REVERSED[LIndex];
end;

procedure TGaugesDemoForm.MeterValueTrackBarChange(Sender: TObject);
begin
  CircularMeter.Value := MeterValueTrackBar.Value;

  for var LMeter in GetLinearMeters do
    LMeter.Value := MeterValueTrackBar.Value;

  MeterValueLabel.Text := Format(S_VALUE, [MeterValueTrackBar.Value]);
end;

procedure TGaugesDemoForm.NeedleChange(Sender: TObject);
begin
  CircularMeter.Needle.Visible := NeedleVisibleCheckBox.IsChecked;
  CircularMeter.Needle.Length := NeedleLengthTrackBar.Value;
  NeedleLengthLabel.Text := Format(S_NEEDLE_LENGTH, [NeedleLengthTrackBar.Value]);
end;

procedure TGaugesDemoForm.OrientationComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TOrientation: horizontal, vertical
  FirstLinearGauge.Orientation := TOrientation(OrientationComboBox.ItemIndex);
end;

procedure TGaugesDemoForm.PointerChange(Sender: TObject);
begin
  for var LMeter in GetLinearMeters do
  begin
    LMeter.Pointer.Visible := PointerVisibleCheckBox.IsChecked;

    // The items follow the order of TS4YGaugeBarSide: before, after
    if PointerPositionComboBox.ItemIndex >= 0 then
      LMeter.Pointer.Position := TS4YGaugeBarSide(PointerPositionComboBox.ItemIndex);
  end;
end;

procedure TGaugesDemoForm.RandomButtonClick(Sender: TObject);
begin
  ValueTrackBar.Value := ValueTrackBar.Min + Random * (ValueTrackBar.Max - ValueTrackBar.Min);
end;

procedure TGaugesDemoForm.RangePlacementCheckBoxChange(Sender: TObject);
var
  LArcPlacement: TS4YGaugeArcRangePlacement;
  LBarPlacement: TS4YGaugeBarRangePlacement;
begin
  // The same three check boxes give the places on the arc and on the bar.
  LArcPlacement := [];
  LBarPlacement := [];

  if RangeTrackCheckBox.IsChecked then
  begin
    LArcPlacement := LArcPlacement + [garTrack];
    LBarPlacement := LBarPlacement + [gbrTrack];
  end;

  if RangeInsideCheckBox.IsChecked then
  begin
    LArcPlacement := LArcPlacement + [garInside];
    LBarPlacement := LBarPlacement + [gbrBefore];
  end;

  if RangeOutsideCheckBox.IsChecked then
  begin
    LArcPlacement := LArcPlacement + [garOutside];
    LBarPlacement := LBarPlacement + [gbrAfter];
  end;

  CircularMeter.RangePlacement := LArcPlacement;

  for var LMeter in GetLinearMeters do
    LMeter.RangePlacement := LBarPlacement;
end;

procedure TGaugesDemoForm.RangesCheckBoxChange(Sender: TObject);
begin
  CircularMeter.Ranges.Clear;

  if RangesCheckBox.IsChecked then
    AddRanges(CircularMeter.Ranges);

  for var LMeter in GetLinearMeters do
  begin
    LMeter.Ranges.Clear;

    if RangesCheckBox.IsChecked then
      AddRanges(LMeter.Ranges);
  end;
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

procedure TGaugesDemoForm.ReversedCheckBoxChange(Sender: TObject);
begin
  CircularGauge.Reversed := ReversedCheckBox.IsChecked;
end;

procedure TGaugesDemoForm.ShapeComboBoxChange(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := ShapeComboBox.ItemIndex;

  if LIndex < 0 then
    Exit;

  // The track bars and the check box apply the angles and the direction to the gauge.
  StartAngleTrackBar.Value := C_SHAPE_START_ANGLES[LIndex];
  SweepAngleTrackBar.Value := C_SHAPE_SWEEP_ANGLES[LIndex];
  ReversedCheckBox.IsChecked := C_SHAPE_REVERSED[LIndex];
end;

procedure TGaugesDemoForm.ShowFillCheckBoxChange(Sender: TObject);
begin
  CircularMeter.ShowFill := CircularShowFillCheckBox.IsChecked;

  for var LMeter in GetLinearMeters do
    LMeter.ShowFill := LinearShowFillCheckBox.IsChecked;
end;

procedure TGaugesDemoForm.ShowValueCheckBoxChange(Sender: TObject);
begin
  for var LGauge in GetGauges do
    LGauge.ShowValue := ShowValueCheckBox.IsChecked;
end;

procedure TGaugesDemoForm.SkinAnimatedCheckBoxChange(Sender: TObject);
var
  LDuration: Single;
begin
  LDuration := 0;

  if SkinAnimatedCheckBox.IsChecked then
    LDuration := C_ANIMATION_DURATION;

  for var LGauge in GetSkinGauges do
    LGauge.AnimationDuration := LDuration;
end;

procedure TGaugesDemoForm.SkinCaptionEditChangeTracking(Sender: TObject);
begin
  for var LGauge in GetSkinGauges do
    LGauge.Caption := SkinCaptionEdit.Text;
end;

procedure TGaugesDemoForm.SkinRandomButtonClick(Sender: TObject);
begin
  SkinValueTrackBar.Value := SkinValueTrackBar.Min + Random * (SkinValueTrackBar.Max - SkinValueTrackBar.Min);
end;

procedure TGaugesDemoForm.SkinReversedCheckBoxChange(Sender: TObject);
begin
  SkinLinearGauge.Reversed := SkinReversedCheckBox.IsChecked;
end;

procedure TGaugesDemoForm.SkinShowValueCheckBoxChange(Sender: TObject);
begin
  for var LGauge in GetSkinGauges do
    LGauge.ShowValue := SkinShowValueCheckBox.IsChecked;
end;

procedure TGaugesDemoForm.SkinValueTrackBarChange(Sender: TObject);
begin
  for var LGauge in GetSkinGauges do
    LGauge.Value := SkinValueTrackBar.Value;

  SkinValueLabel.Text := Format(S_VALUE, [SkinValueTrackBar.Value]);
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

procedure TGaugesDemoForm.TargetChange(Sender: TObject);
begin
  CircularMeter.ShowTarget := ShowTargetCheckBox.IsChecked;
  CircularMeter.Target := TargetTrackBar.Value;

  for var LMeter in GetLinearMeters do
  begin
    LMeter.ShowTarget := ShowTargetCheckBox.IsChecked;
    LMeter.Target := TargetTrackBar.Value;
  end;

  TargetLabel.Text := Format(S_TARGET, [TargetTrackBar.Value]);
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
