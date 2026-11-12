program S4YStepProgressBarGallery;

uses
  System.StartUpCopy,
  FMX.Forms,
  StepProgressBarGalleryMain in 'StepProgressBarGalleryMain.pas' {StepProgressBarGalleryForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStepProgressBarGalleryForm, StepProgressBarGalleryForm);
  Application.Run;
end.
