unit TagDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.Math.Vectors,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.ImgList,
  FMX.MultiResBitmap,
  FMX.Forms,
  FMX.Layouts,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.ListBox,
  Soft4You.FMX.Controls.Tag,
  Soft4You.FMX.Controls.Chip;

type
  TTagDemoForm = class(TForm)
    DemoLayout: TLayout;
    KindsLabel: TLabel;
    KindsLayout: TFlowLayout;
    NeutralTag: TS4YTag;
    PrimaryTag: TS4YTag;
    SuccessTag: TS4YTag;
    WarningTag: TS4YTag;
    DangerTag: TS4YTag;
    InfoTag: TS4YTag;
    VariantsLabel: TLabel;
    VariantsLayout: TFlowLayout;
    FilledTag: TS4YTag;
    TonalTag: TS4YTag;
    OutlinedTag: TS4YTag;
    ClosableTag: TS4YTag;
    FilterLabel: TLabel;
    FilterLayout: TFlowLayout;
    OpenChip: TS4YChip;
    InProgressChip: TS4YChip;
    DoneChip: TS4YChip;
    ArchivedChip: TS4YChip;
    FilterResultLabel: TLabel;
    SizeLabel: TLabel;
    SizeLayout: TFlowLayout;
    SmallSizeChip: TS4YChip;
    MediumSizeChip: TS4YChip;
    LargeSizeChip: TS4YChip;
    SizeResultLabel: TLabel;
    RecipientsLabel: TLabel;
    RecipientsLayout: TFlowLayout;
    AnnaChip: TS4YChip;
    LucaChip: TS4YChip;
    NewRecipientEdit: TEdit;
    AddRecipientButton: TButton;
    MessageLabel: TLabel;
    SettingsPanel: TPanel;
    SampleLayout: TLayout;
    SampleTag: TS4YTag;
    TextLabel: TLabel;
    TextEdit: TEdit;
    KindSettingLabel: TLabel;
    KindComboBox: TComboBox;
    VariantSettingLabel: TLabel;
    VariantComboBox: TComboBox;
    ShapeSettingLabel: TLabel;
    ShapeComboBox: TComboBox;
    SizeSettingLabel: TLabel;
    SizeComboBox: TComboBox;
    ClosableCheckBox: TCheckBox;
    AutoSizeCheckBox: TCheckBox;
    MaxWidthCheckBox: TCheckBox;
    PicturesLabel: TLabel;
    PicturesLayout: TFlowLayout;
    DoneIconTag: TS4YTag;
    UrgentIconTag: TS4YTag;
    FavoriteChip: TS4YChip;
    PhotoTag: TS4YTag;
    SquarePhotoChip: TS4YChip;
    IconImageList: TImageList;
    procedure AddRecipientButtonClick(Sender: TObject);
    procedure AutoSizeCheckBoxChange(Sender: TObject);
    procedure ClosableCheckBoxChange(Sender: TObject);
    procedure FilterChipCheckedChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure KindComboBoxChange(Sender: TObject);
    procedure MaxWidthCheckBoxChange(Sender: TObject);
    procedure RecipientChipClose(Sender: TObject; var CanClose: Boolean);
    procedure ShapeComboBoxChange(Sender: TObject);
    procedure SizeChipCheckedChange(Sender: TObject);
    procedure SizeComboBoxChange(Sender: TObject);
    procedure TextEditChangeTracking(Sender: TObject);
    procedure VariantComboBoxChange(Sender: TObject);
  private
    function AddIcon(const ABitmap: TBitmap): Integer;
    function MakeIcon(const AKind: Integer): TBitmap;
    procedure DrawPhoto(const ATarget: TBitmap; const AName: string; const AColor: TAlphaColor);
  end;

var
  TagDemoForm: TTagDemoForm;

implementation

uses
  Soft4You.FMX.Controls.Tag.Types;

{$R *.fmx}

const
  // Colors of the pictures made for the recipients, one after the other
  C_PHOTO_COLORS: array[0..3] of TAlphaColor = ($FF1E88E5, $FF43A047, $FF8E24AA, $FFF4511E);

function TTagDemoForm.AddIcon(const ABitmap: TBitmap): Integer;
var
  LBitmapItem: TCustomBitmapItem;
  LDestination: TCustomDestinationItem;
  LLayer: TLayer;
  LSource: TCustomSourceItem;
begin
  // An item of the image list is a source with the bitmap and a destination with a layer that
  // points to the source by its name.
  LSource := IconImageList.Source.Add;
  LSource.Name := 'Icon' + IntToStr(IconImageList.Source.Count);
  LBitmapItem := LSource.MultiResBitmap.Add;
  LBitmapItem.Scale := 1;
  LBitmapItem.Bitmap.Assign(ABitmap);
  LDestination := IconImageList.Destination.Add;
  LLayer := LDestination.Layers.Add;
  LLayer.Name := LSource.Name;
  LLayer.SourceRect.Rect := TRectF.Create(0, 0, ABitmap.Width, ABitmap.Height);
  Result := LDestination.Index;
end;

procedure TTagDemoForm.AddRecipientButtonClick(Sender: TObject);
var
  LChip: TS4YChip;
begin
  if Trim(NewRecipientEdit.Text) = '' then
    Exit;

  // A chip made in code: the form owns it, and the flow layout places it after the others.
  LChip := TS4YChip.Create(Self);
  LChip.Parent := RecipientsLayout;
  LChip.Text := Trim(NewRecipientEdit.Text);
  LChip.Kind := tgkPrimary;
  LChip.Variant := tgvTonal;
  LChip.Closable := True;
  LChip.ImageRound := True;
  DrawPhoto(LChip.Bitmap, LChip.Text, C_PHOTO_COLORS[RecipientsLayout.ControlsCount mod Length(C_PHOTO_COLORS)]);
  LChip.OnClose := RecipientChipClose;
  NewRecipientEdit.Text := '';
  MessageLabel.Text := 'Added ' + LChip.Text;
end;

procedure TTagDemoForm.AutoSizeCheckBoxChange(Sender: TObject);
begin
  SampleTag.AutoSize := AutoSizeCheckBox.IsChecked;

  // Without AutoSize the width is the one set: a text that does not fit is cut.
  if not SampleTag.AutoSize then
    SampleTag.Width := 64;
end;

procedure TTagDemoForm.ClosableCheckBoxChange(Sender: TObject);
begin
  SampleTag.Closable := ClosableCheckBox.IsChecked;
end;

procedure TTagDemoForm.FilterChipCheckedChange(Sender: TObject);
var
  LChip: TS4YChip;
  LSelected: string;
begin
  LSelected := '';

  for LChip in [OpenChip, InProgressChip, DoneChip, ArchivedChip] do
  begin
    if LChip.Checked then
    begin
      if LSelected <> '' then
        LSelected := LSelected + ', ';

      LSelected := LSelected + LChip.Text;
    end;
  end;

  if LSelected = '' then
    LSelected := 'none';

  FilterResultLabel.Text := 'Selected: ' + LSelected;
end;

procedure TTagDemoForm.FormCreate(Sender: TObject);
var
  LIcon: TBitmap;
  LIndex: Integer;
begin
  // The icons of the image list and the pictures are drawn here, so that the demo needs no image file.
  for LIndex := 0 to 2 do
  begin
    LIcon := MakeIcon(LIndex);
    try
      AddIcon(LIcon);
    finally
      LIcon.Free;
    end;
  end;

  DrawPhoto(AnnaChip.Bitmap, 'Anna Verdi', C_PHOTO_COLORS[0]);
  DrawPhoto(LucaChip.Bitmap, 'Luca Bianchi', C_PHOTO_COLORS[1]);
  DrawPhoto(PhotoTag.Bitmap, 'Round', C_PHOTO_COLORS[2]);
  DrawPhoto(SquarePhotoChip.Bitmap, 'Picture', C_PHOTO_COLORS[3]);
end;

procedure TTagDemoForm.KindComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YTagKind
  SampleTag.Kind := TS4YTagKind(KindComboBox.ItemIndex);
end;

function TTagDemoForm.MakeIcon(const AKind: Integer): TBitmap;
const
  C_SIZE = 32;
  C_STAR_POINTS = 5;
var
  LAngle: Single;
  LIndex: Integer;
  LPolygon: TPolygon;
  LRadius: Single;
begin
  // 0: a check on a green disc, 1: a yellow star, 2: an exclamation mark on a red disc
  Result := TBitmap.Create(C_SIZE, C_SIZE);
  Result.Canvas.BeginScene;
  try
    Result.Canvas.Clear(TAlphaColors.Null);
    Result.Canvas.Stroke.Kind := TBrushKind.Solid;
    Result.Canvas.Stroke.Thickness := 3;
    Result.Canvas.Stroke.Cap := TStrokeCap.Round;
    Result.Canvas.Stroke.Join := TStrokeJoin.Round;

    case AKind of
      0:
        begin
          Result.Canvas.Fill.Color := $FF43A047;
          Result.Canvas.FillEllipse(TRectF.Create(1, 1, C_SIZE - 1, C_SIZE - 1), 1);
          Result.Canvas.Stroke.Color := TAlphaColors.White;
          Result.Canvas.DrawLine(PointF(9, 17), PointF(14, 22), 1);
          Result.Canvas.DrawLine(PointF(14, 22), PointF(23, 10), 1);
        end;
      1:
        begin
          SetLength(LPolygon, C_STAR_POINTS * 2);

          for LIndex := 0 to C_STAR_POINTS * 2 - 1 do
          begin
            if Odd(LIndex) then
              LRadius := 6.5
            else
              LRadius := 15;

            LAngle := -Pi / 2 + LIndex * Pi / C_STAR_POINTS;
            LPolygon[LIndex] := PointF(C_SIZE / 2 + LRadius * Cos(LAngle), C_SIZE / 2 + 1 + LRadius * Sin(LAngle));
          end;

          Result.Canvas.Fill.Color := $FFFFB300;
          Result.Canvas.FillPolygon(LPolygon, 1);
        end;
    else
      begin
        Result.Canvas.Fill.Color := $FFE53935;
        Result.Canvas.FillEllipse(TRectF.Create(1, 1, C_SIZE - 1, C_SIZE - 1), 1);
        Result.Canvas.Stroke.Color := TAlphaColors.White;
        Result.Canvas.DrawLine(PointF(C_SIZE / 2, 8), PointF(C_SIZE / 2, 18), 1);
        Result.Canvas.Fill.Color := TAlphaColors.White;
        Result.Canvas.FillEllipse(TRectF.Create(C_SIZE / 2 - 2, 22, C_SIZE / 2 + 2, 26), 1);
      end;
    end;
  finally
    Result.Canvas.EndScene;
  end;
end;

procedure TTagDemoForm.DrawPhoto(const ATarget: TBitmap; const AName: string; const AColor: TAlphaColor);
const
  C_SIZE = 96;
begin
  // A square picture with the first letter of the name; the control shows it with the corners
  // rounded or, with ImageRound, as a circle.
  ATarget.SetSize(C_SIZE, C_SIZE);
  ATarget.Canvas.BeginScene;
  try
    ATarget.Canvas.Clear(AColor);
    ATarget.Canvas.Fill.Color := TAlphaColors.White;
    ATarget.Canvas.Font.Size := 56;
    ATarget.Canvas.FillText(TRectF.Create(0, 0, C_SIZE, C_SIZE), UpperCase(Copy(Trim(AName), 1, 1)), False, 1, [],
      TTextAlign.Center, TTextAlign.Center);
  finally
    ATarget.Canvas.EndScene;
  end;
end;

procedure TTagDemoForm.MaxWidthCheckBoxChange(Sender: TObject);
begin
  // With AutoSize the width follows the text up to MaxWidth; a longer text is cut, with an ellipsis. 0 is no limit.
  if MaxWidthCheckBox.IsChecked then
    SampleTag.MaxWidth := 100
  else
    SampleTag.MaxWidth := 0;
end;

procedure TTagDemoForm.RecipientChipClose(Sender: TObject; var CanClose: Boolean);
begin
  // CanClose is True: the chip is hidden, and the flow layout closes the gap. Set it to False to keep the chip.
  MessageLabel.Text := 'Removed ' + TS4YChip(Sender).Text;
end;

procedure TTagDemoForm.ShapeComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YTagShape: pill, rounded, square
  SampleTag.Shape := TS4YTagShape(ShapeComboBox.ItemIndex);
end;

procedure TTagDemoForm.SizeChipCheckedChange(Sender: TObject);
begin
  // The chips of the group tell it when they are chosen and when another one is chosen: only the chosen one is shown.
  if TS4YChip(Sender).Checked then
    SizeResultLabel.Text := 'Size: ' + TS4YChip(Sender).Text;
end;

procedure TTagDemoForm.SizeComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YTagSizePreset: small, medium, large
  SampleTag.SizePreset := TS4YTagSizePreset(SizeComboBox.ItemIndex);
end;

procedure TTagDemoForm.TextEditChangeTracking(Sender: TObject);
begin
  SampleTag.Text := TextEdit.Text;
end;

procedure TTagDemoForm.VariantComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YTagVariant: filled, tonal, outlined
  SampleTag.Variant := TS4YTagVariant(VariantComboBox.ItemIndex);
end;

end.
