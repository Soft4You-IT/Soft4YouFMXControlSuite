program S4YStepProgressBarDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  StepProgressBarDemoMain in 'StepProgressBarDemoMain.pas' {StepProgressBarDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStepProgressBarDemoForm, StepProgressBarDemoForm);
  Application.Run;
end.
