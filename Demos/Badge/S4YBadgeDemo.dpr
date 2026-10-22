program S4YBadgeDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  BadgeDemoMain in 'BadgeDemoMain.pas' {BadgeDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TBadgeDemoForm, BadgeDemoForm);
  Application.Run;
end.