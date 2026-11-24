program S4YTagDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  TagDemoMain in 'TagDemoMain.pas' {TagDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TTagDemoForm, TagDemoForm);
  Application.Run;
end.