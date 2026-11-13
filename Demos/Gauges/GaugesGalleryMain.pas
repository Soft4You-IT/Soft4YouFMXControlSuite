unit GaugesGalleryMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
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
  Soft4You.FMX.Controls.Gauges.Circular;

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
    procedure DashboardTimerTimer(Sender: TObject);
    procedure DownloadTimerTimer(Sender: TObject);
    procedure EqualizerTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadGaugeGetValueText(Sender: TObject; const AValue: Single; var AText: string);
    procedure LoadTrackBarChange(Sender: TObject);
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
  Randomize;
  LoadTrackBarChange(LoadTrackBar);
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

end.
