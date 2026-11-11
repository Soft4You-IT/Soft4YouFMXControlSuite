unit StepProgressBarDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.ListBox,
  FMX.Layouts,
  Soft4You.FMX.Controls.StepProgressBar,
  Soft4You.FMX.Controls.StepProgressBar.Types;

type
  TStepProgressBarDemoForm = class(TForm)
    DemoLayout: TLayout;
    InstallTitleLabel: TLabel;
    InstallBar: TS4YStepProgressBar;
    WizardTitleLabel: TLabel;
    WizardBar: TS4YStepProgressBar;
    WizardStatusLabel: TLabel;
    SettingsPanel: TPanel;
    InstallSettingsLabel: TLabel;
    NextButton: TButton;
    PreviousButton: TButton;
    FailedCheckBox: TCheckBox;
    WizardSettingsLabel: TLabel;
    ClickMarkerCheckBox: TCheckBox;
    ClickLabelCheckBox: TCheckBox;
    HandCursorCheckBox: TCheckBox;
    KeyboardCheckBox: TCheckBox;
    AllBarsSettingsLabel: TLabel;
    HighlightProgressCheckBox: TCheckBox;
    AnimatedCheckBox: TCheckBox;
    NumbersCheckBox: TCheckBox;
    LabelPositionLabel: TLabel;
    LabelPositionComboBox: TComboBox;
    InstallStatusLabel: TLabel;
    procedure AnimatedCheckBoxChange(Sender: TObject);
    procedure FailedCheckBoxChange(Sender: TObject);
    procedure HighlightProgressCheckBoxChange(Sender: TObject);
    procedure InstallBarStepChanged(Sender: TObject);
    procedure InteractionCheckBoxChange(Sender: TObject);
    procedure LabelPositionComboBoxChange(Sender: TObject);
    procedure NextButtonClick(Sender: TObject);
    procedure NumbersCheckBoxChange(Sender: TObject);
    procedure PreviousButtonClick(Sender: TObject);
    procedure WizardBarStepChanged(Sender: TObject);
    procedure WizardBarStepChanging(Sender: TObject; const ANewStep: Integer; var Allow: Boolean);
  private
    procedure SetMarkersContent(const AProgressBar: TS4YStepProgressBar; const AContent: TS4YStepMarkerContent);
  end;

var
  StepProgressBarDemoForm: TStepProgressBarDemoForm;

implementation

{$R *.fmx}

resourcestring
  S_INSTALL_STATUS = 'Step %d of %d: %s';
  S_WIZARD_STATUS = 'Current step: %s. OnStepChanging does not allow skipping a step forward: click the next step, ' +
    'or any step before.';

const
  C_ANIMATION_DURATION = 0.3;

procedure TStepProgressBarDemoForm.AnimatedCheckBoxChange(Sender: TObject);
var
  LDuration: Single;
begin
  LDuration := 0;

  if AnimatedCheckBox.IsChecked then
    LDuration := C_ANIMATION_DURATION;

  InstallBar.AnimationDuration := LDuration;
  WizardBar.AnimationDuration := LDuration;
end;

procedure TStepProgressBarDemoForm.FailedCheckBoxChange(Sender: TObject);
begin
  InstallBar.Steps[InstallBar.CurrentStep].Failed := FailedCheckBox.IsChecked;
end;

procedure TStepProgressBarDemoForm.HighlightProgressCheckBoxChange(Sender: TObject);
begin
  InstallBar.HighlightProgress := HighlightProgressCheckBox.IsChecked;
  WizardBar.HighlightProgress := HighlightProgressCheckBox.IsChecked;
end;

procedure TStepProgressBarDemoForm.InstallBarStepChanged(Sender: TObject);
var
  LStep: TS4YStepItem;
begin
  LStep := InstallBar.Steps[InstallBar.CurrentStep];
  FailedCheckBox.IsChecked := LStep.Failed;
  InstallStatusLabel.Text := Format(S_INSTALL_STATUS, [InstallBar.CurrentStep + 1, InstallBar.Steps.Count, LStep.Caption]);
end;

procedure TStepProgressBarDemoForm.InteractionCheckBoxChange(Sender: TObject);
var
  LInteractions: TS4YStepInteractions;
begin
  LInteractions := [];

  if ClickMarkerCheckBox.IsChecked then
    Include(LInteractions, stiClickMarker);

  if ClickLabelCheckBox.IsChecked then
    Include(LInteractions, stiClickLabel);

  if HandCursorCheckBox.IsChecked then
    Include(LInteractions, stiHandCursor);

  if KeyboardCheckBox.IsChecked then
    Include(LInteractions, stiKeyboard);

  WizardBar.Interactions := LInteractions;
end;

procedure TStepProgressBarDemoForm.LabelPositionComboBoxChange(Sender: TObject);
begin
  // The items follow the order of TS4YStepLabelPosition: none, before, after
  InstallBar.LabelPosition := TS4YStepLabelPosition(LabelPositionComboBox.ItemIndex);
  WizardBar.LabelPosition := TS4YStepLabelPosition(LabelPositionComboBox.ItemIndex);
end;

procedure TStepProgressBarDemoForm.NextButtonClick(Sender: TObject);
begin
  InstallBar.NextStep;
end;

procedure TStepProgressBarDemoForm.NumbersCheckBoxChange(Sender: TObject);
var
  LContent: TS4YStepMarkerContent;
begin
  LContent := smcNone;

  if NumbersCheckBox.IsChecked then
    LContent := smcNumber;

  SetMarkersContent(InstallBar, LContent);
  SetMarkersContent(WizardBar, LContent);
end;

procedure TStepProgressBarDemoForm.PreviousButtonClick(Sender: TObject);
begin
  InstallBar.PreviousStep;
end;

procedure TStepProgressBarDemoForm.SetMarkersContent(const AProgressBar: TS4YStepProgressBar;
  const AContent: TS4YStepMarkerContent);
begin
  AProgressBar.CompletedMarker.Content := AContent;
  AProgressBar.CurrentMarker.Content := AContent;
  AProgressBar.PendingMarker.Content := AContent;
  AProgressBar.FailedMarker.Content := AContent;
end;

procedure TStepProgressBarDemoForm.WizardBarStepChanged(Sender: TObject);
begin
  WizardStatusLabel.Text := Format(S_WIZARD_STATUS, [WizardBar.Steps[WizardBar.CurrentStep].Caption]);
end;

procedure TStepProgressBarDemoForm.WizardBarStepChanging(Sender: TObject; const ANewStep: Integer; var Allow: Boolean);
begin
  // A wizard lets the user go back to any step, but not skip a step forward
  Allow := ANewStep <= WizardBar.CurrentStep + 1;
end;

end.
