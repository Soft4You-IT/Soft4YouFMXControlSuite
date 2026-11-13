program S4YChartsGallery;

uses
  System.StartUpCopy,
  FMX.Forms,
  ChartsGalleryMain in 'ChartsGalleryMain.pas' {ChartsGalleryForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TChartsGalleryForm, ChartsGalleryForm);
  Application.Run;
end.
