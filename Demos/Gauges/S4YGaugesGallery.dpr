program S4YGaugesGallery;

uses
  System.StartUpCopy,
  FMX.Forms,
  GaugesGalleryMain in 'GaugesGalleryMain.pas' {GaugesGalleryForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGaugesGalleryForm, GaugesGalleryForm);
  Application.Run;
end.
