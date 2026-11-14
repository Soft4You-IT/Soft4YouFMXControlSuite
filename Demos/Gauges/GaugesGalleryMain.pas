unit GaugesGalleryMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.Math,
  System.DateUtils,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.TabControl,
  FMX.Layouts,
  FMX.Objects,
  Soft4You.FMX.Controls.Gauges,
  Soft4You.FMX.Controls.Gauges.Linear,
  Soft4You.FMX.Controls.Gauges.Circular,
  Soft4You.FMX.Controls.Gauges.LinearMeter,
  Soft4You.FMX.Controls.Gauges.CircularMeter,
  Soft4You.FMX.Controls.Gauges.SkinCircular,
  Soft4You.FMX.Controls.Gauges.SkinLinear;

type
  TGaugesGalleryForm = class(TForm)
    GalleryTabControl: TTabControl;
    DefaultTab: TTabItem;
    DefaultLabel: TLabel;
    StorageGauge: TS4YLinearGauge;
    MemoryGauge: TS4YLinearGauge;
    BatteryGauge: TS4YLinearGauge;
    LowRingGauge: TS4YCircularGauge;
    MiddleRingGauge: TS4YCircularGauge;
    HighRingGauge: TS4YCircularGauge;
    ShapesTab: TTabItem;
    ShapesLabel: TLabel;
    RingGauge: TS4YCircularGauge;
    SpeedometerGauge: TS4YCircularGauge;
    HalfCircleGauge: TS4YCircularGauge;
    QuarterGauge: TS4YCircularGauge;
    LeftRingGauge: TS4YCircularGauge;
    MetersTab: TTabItem;
    MetersLabel: TLabel;
    SpeedometerMeter: TS4YCircularMeter;
    ManometerMeter: TS4YCircularMeter;
    ThermometerMeter: TS4YLinearMeter;
    TunerMeter: TS4YLinearMeter;
    MetersTimer: TTimer;
    DirectionsTab: TTabItem;
    DirectionsLabel: TLabel;
    UpsideDownGauge: TS4YCircularGauge;
    LeftHalfGauge: TS4YCircularGauge;
    RightHalfGauge: TS4YCircularGauge;
    QuarterReversedGauge: TS4YCircularGauge;
    TemperatureMeter: TS4YCircularMeter;
    FuelMeter: TS4YCircularMeter;
    MirroredMeter: TS4YCircularMeter;
    SkinsTab: TTabItem;
    SkinsLabel: TLabel;
    ClockSkinGauge: TS4YSkinCircularGauge;
    CarSkinGauge: TS4YSkinCircularGauge;
    ThermometerSkinGauge: TS4YSkinLinearGauge;
    DefaultSkinCircularGauge: TS4YSkinCircularGauge;
    DefaultSkinLinearGauge: TS4YSkinLinearGauge;
    SkinsTimer: TTimer;
    ClockTimer: TTimer;
    DashboardTab: TTabItem;
    DashboardLabel: TLabel;
    CpuGauge: TS4YCircularGauge;
    RamGauge: TS4YCircularGauge;
    DiskGauge: TS4YCircularGauge;
    UploadGauge: TS4YLinearGauge;
    DownloadSpeedGauge: TS4YLinearGauge;
    DashboardTimer: TTimer;
    ThresholdsTab: TTabItem;
    ThresholdsLabel: TLabel;
    LoadGauge: TS4YCircularGauge;
    LoadBarGauge: TS4YLinearGauge;
    LoadTrackBar: TTrackBar;
    DownloadTab: TTabItem;
    DownloadLabel: TLabel;
    DownloadGauge: TS4YLinearGauge;
    DownloadRingGauge: TS4YCircularGauge;
    DownloadTimer: TTimer;
    EqualizerTab: TTabItem;
    EqualizerLabel: TLabel;
    EqualizerLayout: TLayout;
    EqualizerTimer: TTimer;
    StyleBookTab: TTabItem;
    StyleBookLabel: TLabel;
    GradientLinearGauge: TS4YLinearGauge;
    GlossyLinearGauge: TS4YLinearGauge;
    SquareLinearGauge: TS4YLinearGauge;
    FlatCircularGauge: TS4YCircularGauge;
    DashedCircularGauge: TS4YCircularGauge;
    GradientCircularGauge: TS4YCircularGauge;
    DarkTab: TTabItem;
    DarkBackground: TRectangle;
    DarkLabel: TLabel;
    DarkLinearGauge: TS4YLinearGauge;
    DarkSecondLinearGauge: TS4YLinearGauge;
    DarkCircularGauge: TS4YCircularGauge;
    DarkSpeedometerGauge: TS4YCircularGauge;
    GalleryStyleBook: TStyleBook;
    procedure ClockTimerTimer(Sender: TObject);
    procedure DashboardTimerTimer(Sender: TObject);
    procedure DownloadTimerTimer(Sender: TObject);
    procedure EqualizerTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadGaugeGetValueText(Sender: TObject; const AValue: Single; var AText: string);
    procedure LoadTrackBarChange(Sender: TObject);
    procedure MetersTimerTimer(Sender: TObject);
    procedure SkinsTimerTimer(Sender: TObject);
  private
    FDownloadPause: Integer;
  end;

var
  GaugesGalleryForm: TGaugesGalleryForm;

implementation

{$R *.fmx}

resourcestring
  S_LOAD_CRITICAL = 'critical';
  S_LOAD_HIGH = 'high';
  S_LOAD_NORMAL = 'normal';
  S_LOAD_TEXT = '%.0f %% %s';

const
  // Limits of the levels of the load, in percent.
  C_HIGH_LOAD = 60;
  C_CRITICAL_LOAD = 85;
  C_NORMAL_LOAD_COLOR: TAlphaColor = $FF43A047;
  C_HIGH_LOAD_COLOR: TAlphaColor = $FFFB8C00;
  C_CRITICAL_LOAD_COLOR: TAlphaColor = $FFE53935;
  // Percent added at each tick of DownloadTimer: small enough to be drawn at once.
  C_DOWNLOAD_INCREMENT = 0.5;
  // Ticks of DownloadTimer to wait at the end of a download, before the next one.
  C_DOWNLOAD_END_PAUSE = 30;
  // Percent of fuel used at each tick of SkinsTimer.
  C_FUEL_DECREMENT = 2;

procedure TGaugesGalleryForm.ClockTimerTimer(Sender: TObject);
var
  LNow: TDateTime;
begin
  // The hands of the hours and the minutes move a little with the minutes and the seconds, the one of the
  // seconds is needle and jumps from second to second.
  LNow := Now;
  ClockSkinGauge.Needles[0].Value := HourOf(LNow) + MinuteOf(LNow) / 60;
  ClockSkinGauge.Needles[1].Value := MinuteOf(LNow) + SecondOf(LNow) / 60;
  ClockSkinGauge.Value := SecondOf(LNow);
end;

procedure TGaugesGalleryForm.DashboardTimerTimer(Sender: TObject);
begin
  // Random values: the large changes are animated, the small ones drawn at once.
  CpuGauge.Value := Random(100);
  RamGauge.Value := 40 + Random(30);
  DiskGauge.Value := DiskGauge.Value + Random * 2 - 1;
  UploadGauge.Value := Random * UploadGauge.Max;
  DownloadSpeedGauge.Value := Random * DownloadSpeedGauge.Max;
end;

procedure TGaugesGalleryForm.DownloadTimerTimer(Sender: TObject);
begin
  if FDownloadPause > 0 then
  begin
    Dec(FDownloadPause);

    // A new download starts from 0: the fill goes back with the animation.
    if FDownloadPause = 0 then
    begin
      DownloadGauge.Value := 0;
      DownloadRingGauge.Value := 0;
    end;

    Exit;
  end;

  DownloadGauge.Value := DownloadGauge.Value + C_DOWNLOAD_INCREMENT;
  DownloadRingGauge.Value := DownloadGauge.Value;

  if DownloadGauge.Value >= DownloadGauge.Max then
    FDownloadPause := C_DOWNLOAD_END_PAUSE;
end;

procedure TGaugesGalleryForm.EqualizerTimerTimer(Sender: TObject);
begin
  for var LIndex := 0 to EqualizerLayout.ControlsCount - 1 do
  begin
    if EqualizerLayout.Controls[LIndex] is TS4YLinearGauge then
      TS4YLinearGauge(EqualizerLayout.Controls[LIndex]).Value := Random(100);
  end;
end;

procedure TGaugesGalleryForm.FormCreate(Sender: TObject);
begin
  // The gallery always opens on the first tab, whichever tab was selected when the form was saved.
  GalleryTabControl.TabIndex := 0;
  Randomize;
  LoadTrackBarChange(LoadTrackBar);
  ClockTimerTimer(ClockTimer);
end;

procedure TGaugesGalleryForm.LoadGaugeGetValueText(Sender: TObject; const AValue: Single; var AText: string);
var
  LLevel: string;
begin
  // The text follows the value drawn, also during the animation.
  if AValue >= C_CRITICAL_LOAD then
    LLevel := S_LOAD_CRITICAL
  else if AValue >= C_HIGH_LOAD then
    LLevel := S_LOAD_HIGH
  else
    LLevel := S_LOAD_NORMAL;

  AText := Format(S_LOAD_TEXT, [AValue, LLevel]);
end;

procedure TGaugesGalleryForm.LoadTrackBarChange(Sender: TObject);
var
  LColor: TAlphaColor;
begin
  if LoadTrackBar.Value >= C_CRITICAL_LOAD then
    LColor := C_CRITICAL_LOAD_COLOR
  else if LoadTrackBar.Value >= C_HIGH_LOAD then
    LColor := C_HIGH_LOAD_COLOR
  else
    LColor := C_NORMAL_LOAD_COLOR;

  // The color of FillBrush replaces the one of the style.
  LoadGauge.FillBrush.Color := LColor;
  LoadBarGauge.FillBrush.Color := LColor;
  LoadGauge.Value := LoadTrackBar.Value;
  LoadBarGauge.Value := LoadTrackBar.Value;
end;

procedure TGaugesGalleryForm.MetersTimerTimer(Sender: TObject);
begin
  // The speed and the temperature drift from their values, the pressure and the pitch jump: the needle
  // and the pointer follow the animation.
  SpeedometerMeter.Value := EnsureRange(SpeedometerMeter.Value + Random(81) - 40, SpeedometerMeter.Min,
    SpeedometerMeter.Max);
  ManometerMeter.Value := 3 + Random * 6;
  ThermometerMeter.Value := EnsureRange(ThermometerMeter.Value + Random * 16 - 8, ThermometerMeter.Min,
    ThermometerMeter.Max);
  TunerMeter.Value := Random(61) - 30;
end;

procedure TGaugesGalleryForm.SkinsTimerTimer(Sender: TObject);
var
  LFuel: TS4YSkinGaugeNeedle;
begin
  CarSkinGauge.Value := EnsureRange(CarSkinGauge.Value + Random(81) - 40, CarSkinGauge.Min, CarSkinGauge.Max);

  // The fuel goes down at each tick, and the tank is filled again when it is empty.
  LFuel := CarSkinGauge.Needles[0];

  if LFuel.Value <= LFuel.Min then
    LFuel.Value := LFuel.Max
  else
    LFuel.Value := LFuel.Value - C_FUEL_DECREMENT;

  // The marks of the thermometer follow the lowest and the highest temperature reached.
  ThermometerSkinGauge.Value := EnsureRange(ThermometerSkinGauge.Value + Random * 6 - 3, ThermometerSkinGauge.Min,
    ThermometerSkinGauge.Max);
  ThermometerSkinGauge.Pointers[0].Value := System.Math.Min(ThermometerSkinGauge.Pointers[0].Value,
    ThermometerSkinGauge.Value);
  ThermometerSkinGauge.Pointers[1].Value := System.Math.Max(ThermometerSkinGauge.Pointers[1].Value,
    ThermometerSkinGauge.Value);
  DefaultSkinCircularGauge.Value := Random(101);
  DefaultSkinLinearGauge.Value := Random(101);
end;

end.
