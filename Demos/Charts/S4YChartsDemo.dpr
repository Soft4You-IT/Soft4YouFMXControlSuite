program S4YChartsDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  ChartsDemoMain in 'ChartsDemoMain.pas' {ChartsDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TChartsDemoForm, ChartsDemoForm);
  Application.Run;
end.
