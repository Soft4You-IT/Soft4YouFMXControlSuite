unit BadgeDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.EditBox,
  FMX.SpinBox,
  FMX.ListBox,
  FMX.Layouts,
  Soft4You.FMX.Controls.Badge;

type
  TBadgeDemoForm = class(TForm)
    DemoLayout: TLayout;
    MessagesButton: TButton;
    MessagesBadge: TS4YBadge;
    ReleaseNotesLabel: TLabel;
    ReleaseNotesBadge: TS4YBadge;
    SettingsPanel: TPanel;
    CurrentValueLabel: TLabel;
    CurrentValueSpinBox: TSpinBox;
    MaxValueLabel: TLabel;
    MaxValueSpinBox: TSpinBox;
    BadgeStyleLabel: TLabel;
    BadgeStyleComboBox: TComboBox;
    TextLabel: TLabel;
    TextEdit: TEdit;
    PositionLabel: TLabel;
    PositionComboBox: TComboBox;
    OffsetLabel: TLabel;
    OffsetComboBox: TComboBox;
    BlinkCheckBox: TCheckBox;
    AutoRadiusCheckBox: TCheckBox;
    HintLabel: TLabel;
    procedure AutoRadiusCheckBoxChange(Sender: TObject);
    procedure BadgeStyleComboBoxChange(Sender: TObject);
    procedure BlinkCheckBoxChange(Sender: TObject);
    procedure CurrentValueSpinBoxChange(Sender: TObject);
    procedure MaxValueSpinBoxChange(Sender: TObject);
    procedure OffsetComboBoxChange(Sender: TObject);
    procedure PositionComboBoxChange(Sender: TObject);
    procedure TextEditChangeTracking(Sender: TObject);
  end;

var
  BadgeDemoForm: TBadgeDemoForm;

implementation

{$R *.fmx}

procedure TBadgeDemoForm.AutoRadiusCheckBoxChange(Sender: TObject);
begin
  MessagesBadge.AutoRadius := AutoRadiusCheckBox.IsChecked;
end;

procedure TBadgeDemoForm.BadgeStyleComboBoxChange(Sender: TObject);
begin
  // Item 0 = numeric (shows CurrentValue), item 1 = text (shows Text)
  MessagesBadge.BadgeStyle := TS4YBadgeStyle(BadgeStyleComboBox.ItemIndex);
end;

procedure TBadgeDemoForm.BlinkCheckBoxChange(Sender: TObject);
begin
  MessagesBadge.BlinkSettings.Enabled := BlinkCheckBox.IsChecked;
end;

procedure TBadgeDemoForm.CurrentValueSpinBoxChange(Sender: TObject);
begin
  MessagesBadge.CurrentValue := Round(CurrentValueSpinBox.Value);
end;

procedure TBadgeDemoForm.MaxValueSpinBoxChange(Sender: TObject);
begin
  MessagesBadge.MaxValue := Round(MaxValueSpinBox.Value);
end;

procedure TBadgeDemoForm.OffsetComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YBadgePositionOffset: inner, edge, outer
  MessagesBadge.AutoPosition.OffsetX := TS4YBadgePositionOffset(OffsetComboBox.ItemIndex);
  MessagesBadge.AutoPosition.OffsetY := TS4YBadgePositionOffset(OffsetComboBox.ItemIndex);
end;

procedure TBadgeDemoForm.PositionComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YBadgeAutoPosition
  MessagesBadge.AutoPosition.AutoPosition := TS4YBadgeAutoPosition(PositionComboBox.ItemIndex);
end;

procedure TBadgeDemoForm.TextEditChangeTracking(Sender: TObject);
begin
  MessagesBadge.Text := TextEdit.Text;
end;

end.
