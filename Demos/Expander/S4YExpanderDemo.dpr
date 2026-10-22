program S4YExpanderDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  ExpanderDemoMain in 'ExpanderDemoMain.pas' {ExpanderDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TExpanderDemoForm, ExpanderDemoForm);
  Application.Run;
end.