program S4YBlockScrollBoxDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  BlockScrollBoxDemoMain in 'BlockScrollBoxDemoMain.pas' {BlockScrollBoxDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TBlockScrollBoxDemoForm, BlockScrollBoxDemoForm);
  Application.Run;
end.
