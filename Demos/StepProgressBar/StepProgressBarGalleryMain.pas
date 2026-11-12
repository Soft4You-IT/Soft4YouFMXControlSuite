unit StepProgressBarGalleryMain;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.ImageList,
  System.Math.Vectors,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.TabControl,
  FMX.Layouts,
  FMX.Objects,
  FMX.ImgList,
  Soft4You.FMX.Controls.StepProgressBar,
  Soft4You.FMX.Controls.StepProgressBar.Types;

type
  TStepProgressBarGalleryForm = class(TForm)
    AnimationBar: TS4YStepProgressBar;
    AnimationLabel: TLabel;
    AnimationTab: TTabItem;
    AnimationTimer: TTimer;
    CheckoutBar: TS4YStepProgressBar;
    CheckoutLabel: TLabel;
    CheckoutTab: TTabItem;
    CustomBar: TS4YStepProgressBar;
    CustomLabel: TLabel;
    CustomTab: TTabItem;
    DarkBackground: TRectangle;
    DarkBar: TS4YStepProgressBar;
    DarkLabel: TLabel;
    DarkTab: TTabItem;
    DotsBar: TS4YStepProgressBar;
    DotsLabel: TLabel;
    DotsLayout: TLayout;
    DotsTab: TTabItem;
    GalleryStyleBook: TStyleBook;
    GalleryTabControl: TTabControl;
    ImagesBar: TS4YStepProgressBar;
    ImagesLabel: TLabel;
    ImagesTab: TTabItem;
    InstallBar: TS4YStepProgressBar;
    InstallLabel: TLabel;
    InstallTab: TTabItem;
    OrderImages: TImageList;
    ShapesBar: TS4YStepProgressBar;
    ShapesLabel: TLabel;
    ShapesTab: TTabItem;
    SizesBar: TS4YStepProgressBar;
    SizesLabel: TLabel;
    SizesTab: TTabItem;
    SpecialBar: TS4YStepProgressBar;
    SpecialLabel: TLabel;
    SpecialTab: TTabItem;
    TrackingBar: TS4YStepProgressBar;
    TrackingLabel: TLabel;
    TrackingTab: TTabItem;
    procedure AnimationTimerTimer(Sender: TObject);
    procedure CustomBarDrawLine(Sender: TObject; const ACanvas: TCanvas; const ARect: TRectF;
      const AFromStep: Integer; const Completed: Boolean; var Handled: Boolean);
    procedure CustomBarDrawMarker(Sender: TObject; const ACanvas: TCanvas; const ARect: TRectF;
      const AStepIndex: Integer; const AState: TS4YStepState; var Handled: Boolean);
  end;

var
  StepProgressBarGalleryForm: TStepProgressBarGalleryForm;

implementation

{$R *.fmx}

const
  C_CUSTOM_DONE_COLOR: TAlphaColor = $FFFB8C00;
  C_CUSTOM_TODO_COLOR: TAlphaColor = $FFCFD8DC;
  C_CUSTOM_TODO_TEXT_COLOR: TAlphaColor = $FF607D8B;
  C_CUSTOM_CORNER_RADIUS = 6;

procedure TStepProgressBarGalleryForm.AnimationTimerTimer(Sender: TObject);
begin
  // After the last step the progress starts again from the first one.
  if not AnimationBar.NextStep then
    AnimationBar.CurrentStep := 0;
end;

procedure TStepProgressBarGalleryForm.CustomBarDrawLine(Sender: TObject; const ACanvas: TCanvas; const ARect: TRectF;
  const AFromStep: Integer; const Completed: Boolean; var Handled: Boolean);
begin
  // A rounded bar, orange where the progress has arrived.
  ACanvas.Fill.Kind := TBrushKind.Solid;

  if Completed then
    ACanvas.Fill.Color := C_CUSTOM_DONE_COLOR
  else
    ACanvas.Fill.Color := C_CUSTOM_TODO_COLOR;

  ACanvas.FillRect(ARect, ARect.Height / 2, ARect.Height / 2, AllCorners, 1);
  Handled := True;
end;

procedure TStepProgressBarGalleryForm.CustomBarDrawMarker(Sender: TObject; const ACanvas: TCanvas;
  const ARect: TRectF; const AStepIndex: Integer; const AState: TS4YStepState; var Handled: Boolean);
var
  LMarkerRect: TRectF;
  LCenter: TPointF;
  LCanvasState: TCanvasSaveState;
begin
  LMarkerRect := ARect;
  ACanvas.Fill.Kind := TBrushKind.Solid;

  if AState = sstPending then
    ACanvas.Fill.Color := C_CUSTOM_TODO_COLOR
  else
    ACanvas.Fill.Color := C_CUSTOM_DONE_COLOR;

  // The current step is a square turned by 45 degrees, the others are rounded squares.
  if AState = sstCurrent then
  begin
    LMarkerRect.Inflate(-ARect.Width * 0.15, -ARect.Height * 0.15);
    LCenter := ARect.CenterPoint;
    LCanvasState := ACanvas.SaveState;
    try
      ACanvas.SetMatrix(TMatrix.CreateTranslation(-LCenter.X, -LCenter.Y) * TMatrix.CreateRotation(Pi / 4) *
        TMatrix.CreateTranslation(LCenter.X, LCenter.Y) * ACanvas.Matrix);
      ACanvas.FillRect(LMarkerRect, C_CUSTOM_CORNER_RADIUS / 2, C_CUSTOM_CORNER_RADIUS / 2, AllCorners, 1);
    finally
      ACanvas.RestoreState(LCanvasState);
    end;
  end
  else
    ACanvas.FillRect(LMarkerRect, C_CUSTOM_CORNER_RADIUS, C_CUSTOM_CORNER_RADIUS, AllCorners, 1);

  if AState = sstPending then
    ACanvas.Fill.Color := C_CUSTOM_TODO_TEXT_COLOR
  else
    ACanvas.Fill.Color := TAlphaColors.White;

  ACanvas.Font.Size := 12;
  ACanvas.Font.Style := [TFontStyle.fsBold];
  ACanvas.FillText(ARect, IntToStr(AStepIndex + 1), False, 1, [], TTextAlign.Center, TTextAlign.Center);
  Handled := True;
end;

end.
