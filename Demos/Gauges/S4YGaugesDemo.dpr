program S4YGaugesDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  GaugesDemoMain in 'GaugesDemoMain.pas' {GaugesDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGaugesDemoForm, GaugesDemoForm);
  Application.Run;
end.
