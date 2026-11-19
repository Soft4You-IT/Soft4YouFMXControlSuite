unit AvatarDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.EditBox,
  FMX.SpinBox,
  FMX.ListBox,
  FMX.Layouts,
  Soft4You.FMX.Controls.Badge,
  Soft4You.FMX.Controls.Avatar;

type
  TAvatarDemoForm = class(TForm)
    DemoLayout: TLayout;
    ProfileAvatar: TS4YAvatar;
    ProfileBadge: TS4YBadge;
    ProfileNameLabel: TLabel;
    ProfileHintLabel: TLabel;
    ContactsLabel: TLabel;
    ContactsLayout: TFlowLayout;
    AnnaAvatar: TS4YAvatar;
    LucaAvatar: TS4YAvatar;
    GiuliaAvatar: TS4YAvatar;
    PaoloAvatar: TS4YAvatar;
    SaraAvatar: TS4YAvatar;
    UnknownAvatar: TS4YAvatar;
    SizesLabel: TLabel;
    SizesLayout: TFlowLayout;
    SmallAvatar: TS4YAvatar;
    MediumAvatar: TS4YAvatar;
    LargeAvatar: TS4YAvatar;
    ExtraLargeAvatar: TS4YAvatar;
    HintLabel: TLabel;
    SettingsPanel: TPanel;
    TextLabel: TLabel;
    TextEdit: TEdit;
    InitialsLabel: TLabel;
    InitialsEdit: TEdit;
    ShapeLabel: TLabel;
    ShapeComboBox: TComboBox;
    StatusLabel: TLabel;
    StatusComboBox: TComboBox;
    StatusPositionLabel: TLabel;
    StatusPositionComboBox: TComboBox;
    EditButtonLabel: TLabel;
    EditButtonComboBox: TComboBox;
    EditPositionLabel: TLabel;
    EditPositionComboBox: TComboBox;
    RingCheckBox: TCheckBox;
    NotificationsLabel: TLabel;
    NotificationsSpinBox: TSpinBox;
    RemovePhotoButton: TButton;
    PhotoOpenDialog: TOpenDialog;
    procedure EditButtonComboBoxChange(Sender: TObject);
    procedure EditPositionComboBoxChange(Sender: TObject);
    procedure InitialsEditChangeTracking(Sender: TObject);
    procedure NotificationsSpinBoxChange(Sender: TObject);
    procedure ProfileAvatarEditClick(Sender: TObject);
    procedure RemovePhotoButtonClick(Sender: TObject);
    procedure RingCheckBoxChange(Sender: TObject);
    procedure ShapeComboBoxChange(Sender: TObject);
    procedure StatusComboBoxChange(Sender: TObject);
    procedure StatusPositionComboBoxChange(Sender: TObject);
    procedure TextEditChangeTracking(Sender: TObject);
  end;

var
  AvatarDemoForm: TAvatarDemoForm;

implementation

uses
  Soft4You.FMX.Controls.Avatar.Types;

{$R *.fmx}

procedure TAvatarDemoForm.EditButtonComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YAvatarEditButtonVisibility: never, always, on hover
  ProfileAvatar.EditButton.Visibility := TS4YAvatarEditButtonVisibility(EditButtonComboBox.ItemIndex);
end;

procedure TAvatarDemoForm.EditPositionComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YAvatarCorner
  ProfileAvatar.EditButton.Position := TS4YAvatarCorner(EditPositionComboBox.ItemIndex);
end;

procedure TAvatarDemoForm.InitialsEditChangeTracking(Sender: TObject);
begin
  ProfileAvatar.Initials := InitialsEdit.Text;
end;

procedure TAvatarDemoForm.NotificationsSpinBoxChange(Sender: TObject);
begin
  // 0 hides the badge
  ProfileBadge.CurrentValue := Round(NotificationsSpinBox.Value);
end;

procedure TAvatarDemoForm.ProfileAvatarEditClick(Sender: TObject);
begin
  // On the computer the photo comes from a file; on a phone a TTakePhotoFromLibraryAction in
  // EditAction would set it by itself.
  if PhotoOpenDialog.Execute then
    ProfileAvatar.Bitmap.LoadFromFile(PhotoOpenDialog.FileName);
end;

procedure TAvatarDemoForm.RemovePhotoButtonClick(Sender: TObject);
begin
  // Without the photo the avatar shows the initials again
  ProfileAvatar.Bitmap.SetSize(0, 0);
end;

procedure TAvatarDemoForm.RingCheckBoxChange(Sender: TObject);
begin
  ProfileAvatar.Ring.Visible := RingCheckBox.IsChecked;
end;

procedure TAvatarDemoForm.ShapeComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YAvatarShape: circle, rounded, square
  ProfileAvatar.Shape := TS4YAvatarShape(ShapeComboBox.ItemIndex);
end;

procedure TAvatarDemoForm.StatusComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YAvatarStatus
  ProfileAvatar.Status := TS4YAvatarStatus(StatusComboBox.ItemIndex);
end;

procedure TAvatarDemoForm.StatusPositionComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YAvatarCorner
  ProfileAvatar.StatusPosition := TS4YAvatarCorner(StatusPositionComboBox.ItemIndex);
end;

procedure TAvatarDemoForm.TextEditChangeTracking(Sender: TObject);
begin
  ProfileAvatar.Text := TextEdit.Text;
  ProfileNameLabel.Text := TextEdit.Text;
end;

end.
