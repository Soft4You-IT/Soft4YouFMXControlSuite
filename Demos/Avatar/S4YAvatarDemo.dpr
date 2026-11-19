program S4YAvatarDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  AvatarDemoMain in 'AvatarDemoMain.pas' {AvatarDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TAvatarDemoForm, AvatarDemoForm);
  Application.Run;
end.