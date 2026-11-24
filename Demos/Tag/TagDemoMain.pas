unit TagDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
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
    procedure AddRecipientButtonClick(Sender: TObject);
    procedure AutoSizeCheckBoxChange(Sender: TObject);
    procedure ClosableCheckBoxChange(Sender: TObject);
    procedure FilterChipCheckedChange(Sender: TObject);
    procedure KindComboBoxChange(Sender: TObject);
    procedure RecipientChipClose(Sender: TObject; var CanClose: Boolean);
    procedure ShapeComboBoxChange(Sender: TObject);
    procedure SizeChipCheckedChange(Sender: TObject);
    procedure SizeComboBoxChange(Sender: TObject);
    procedure TextEditChangeTracking(Sender: TObject);
    procedure VariantComboBoxChange(Sender: TObject);
  end;

var
  TagDemoForm: TTagDemoForm;

implementation

uses
  Soft4You.FMX.Controls.Tag.Types;

{$R *.fmx}

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

procedure TTagDemoForm.KindComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YTagKind
  SampleTag.Kind := TS4YTagKind(KindComboBox.ItemIndex);
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
