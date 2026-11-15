program S4YGridDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  GridDemoMain in 'GridDemoMain.pas' {GridDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGridDemoForm, GridDemoForm);
  Application.Run;
end.
