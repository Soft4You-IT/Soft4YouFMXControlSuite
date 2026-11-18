program S4YMobileGallery;

uses
  System.StartUpCopy,
  FMX.Forms,
  MobileGalleryMain in 'MobileGalleryMain.pas' {MobileGalleryForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMobileGalleryForm, MobileGalleryForm);
  Application.Run;
end.
