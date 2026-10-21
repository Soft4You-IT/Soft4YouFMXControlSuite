program S4YHTMLEditorDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainFrm in 'MainFrm.pas' {frmMain},
  PlaceholderFrm in 'PlaceholderFrm.pas' {frmPlaceholder},
  ColorSelectionFrm in 'ColorSelectionFrm.pas' {ColorSelection};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmPlaceholder, frmPlaceholder);
  Application.CreateForm(TColorSelection, ColorSelection);
  Application.Run;
end.
