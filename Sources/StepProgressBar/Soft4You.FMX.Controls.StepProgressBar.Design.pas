unit Soft4You.FMX.Controls.StepProgressBar.Design;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YStepProgressBar - progress indicator made of steps along a line
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  DesignIntf,
  DesignEditors;

type
  /// <summary>
  /// Property editor of Steps of a TS4YStepProgressBar: opens the editor of the steps.
  /// </summary>
  /// <remarks>
  /// The editor lists the steps; the selected step is shown in the Object Inspector. The buttons add, insert, remove and move the steps between the first and the last one.
  /// </remarks>
  TS4YStepListProperty = class(TClassProperty)
  public
    /// <summary>Opens the editor of the steps.</summary>
    procedure Edit; override;
    /// <summary>Returns paDialog and paReadOnly: the steps are changed only in the editor.</summary>
    function GetAttributes: TPropertyAttributes; override;
  end;

  /// <summary>
  /// Component editor of TS4YStepProgressBar: a double click on the control opens the editor of the steps.
  /// </summary>
  /// <remarks>
  /// The context menu of the control has the same command, Edit Steps.
  /// </remarks>
  TS4YStepProgressBarEditor = class(TComponentEditor)
  public
    /// <summary>Opens the editor of the steps.</summary>
    procedure ExecuteVerb(Index: Integer); override;
    /// <summary>Returns the text of the command in the context menu.</summary>
    function GetVerb(Index: Integer): string; override;
    /// <summary>Returns 1: the command Edit Steps.</summary>
    function GetVerbCount: Integer; override;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  DesignWindows,
  Soft4You.FMX.Controls.StepProgressBar,
  Soft4You.FMX.Controls.StepProgressBar.Strings;

type
  /// <summary>Window of the IDE that lists the steps of a TS4YStepProgressBar.</summary>
  TS4YStepListEditor = class(TDesignWindow)
  private
    FAddButton: TButton;
    FDeleteButton: TButton;
    FInsertButton: TButton;
    FMoveDownButton: TButton;
    FMoveUpButton: TButton;
    FProgressBar: TS4YStepProgressBar;
    FStepListBox: TListBox;
    procedure AddButtonClick(Sender: TObject);
    function CreateButton(const AParent: TWinControl; const ACaption: string; const AOnClick: TNotifyEvent): TButton;
    procedure DeleteButtonClick(Sender: TObject);
    class function FindEditor(const AProgressBar: TS4YStepProgressBar): TS4YStepListEditor;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure InsertButtonClick(Sender: TObject);
    procedure MoveDownButtonClick(Sender: TObject);
    procedure MoveUpButtonClick(Sender: TObject);
    procedure SelectStep(const AIndex: Integer);
    procedure StepListBoxClick(Sender: TObject);
    procedure StepsModified(const ASelectedIndex: Integer);
    procedure UpdateButtons;
    procedure UpdateList;
  public
    /// <summary>Shows the editor of the steps of AProgressBar, the one already open if there is one.</summary>
    class procedure ShowEditor(const ADesigner: IDesigner; const AProgressBar: TS4YStepProgressBar);

    /// <summary>Creates the editor of the steps of AProgressBar.</summary>
    constructor CreateEditor(const ADesigner: IDesigner; const AProgressBar: TS4YStepProgressBar);

    /// <summary>Closes the editor when the form of the control is closed.</summary>
    procedure DesignerClosed(const Designer: IDesigner; AGoingDormant: Boolean); override;
    /// <summary>Closes the editor when the control is deleted.</summary>
    procedure ItemDeleted(const ADesigner: IDesigner; Item: TPersistent); override;
    /// <summary>Shows again the captions of the steps, which may have changed in the Object Inspector.</summary>
    procedure ItemsModified(const Designer: IDesigner); override;
    /// <summary>Selects in the list the step selected in the IDE.</summary>
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections); override;
  end;

const
  // Text of a step in the list: index and caption.
  C_STEP_LINE_FORMAT = '%d - %s';
  C_EDITOR_WIDTH = 380;
  C_EDITOR_HEIGHT = 320;
  C_BUTTON_PANEL_WIDTH = 110;
  C_MARGIN = 6;
  // Commands of the component editor; the first one also runs on a double click.
  C_EDIT_STEPS_VERB = 0;
  C_VERB_COUNT = 1;

{ TS4YStepListEditor }

class procedure TS4YStepListEditor.ShowEditor(const ADesigner: IDesigner; const AProgressBar: TS4YStepProgressBar);
var
  LEditor: TS4YStepListEditor;
begin
  LEditor := FindEditor(AProgressBar);

  if not Assigned(LEditor) then
    LEditor := TS4YStepListEditor.CreateEditor(ADesigner, AProgressBar);

  LEditor.Show;
  LEditor.BringToFront;
end;

constructor TS4YStepListEditor.CreateEditor(const ADesigner: IDesigner; const AProgressBar: TS4YStepProgressBar);
var
  LButtonPanel: TPanel;
begin
  // The window has no form file: CreateNew in place of Create, which would also register it for the
  // notifications of the designer.
  inherited CreateNew(nil);
  RegisterDesignNotification(Self);

  Designer := ADesigner;
  FProgressBar := AProgressBar;

  Caption := Format(S_STEP_EDITOR_CAPTION, [AProgressBar.Name]);
  BorderStyle := bsSizeToolWin;
  Position := poScreenCenter;
  ClientWidth := ScaleValue(C_EDITOR_WIDTH);
  ClientHeight := ScaleValue(C_EDITOR_HEIGHT);
  OnClose := FormClose;

  LButtonPanel := TPanel.Create(Self);
  LButtonPanel.Parent := Self;
  LButtonPanel.Align := alRight;
  LButtonPanel.Width := ScaleValue(C_BUTTON_PANEL_WIDTH);
  LButtonPanel.BevelOuter := bvNone;

  // Created in the opposite order: each button is aligned to the top, above the ones created before it.
  FMoveDownButton := CreateButton(LButtonPanel, S_STEP_EDITOR_MOVE_DOWN, MoveDownButtonClick);
  FMoveUpButton := CreateButton(LButtonPanel, S_STEP_EDITOR_MOVE_UP, MoveUpButtonClick);
  FDeleteButton := CreateButton(LButtonPanel, S_STEP_EDITOR_DELETE, DeleteButtonClick);
  FInsertButton := CreateButton(LButtonPanel, S_STEP_EDITOR_INSERT, InsertButtonClick);
  FAddButton := CreateButton(LButtonPanel, S_STEP_EDITOR_ADD, AddButtonClick);

  FStepListBox := TListBox.Create(Self);
  FStepListBox.Parent := Self;
  FStepListBox.Align := alClient;
  FStepListBox.AlignWithMargins := True;
  FStepListBox.Margins.SetBounds(ScaleValue(C_MARGIN), ScaleValue(C_MARGIN), 0, ScaleValue(C_MARGIN));
  FStepListBox.OnClick := StepListBoxClick;

  UpdateList;
end;

procedure TS4YStepListEditor.AddButtonClick(Sender: TObject);
begin
  StepsModified(FProgressBar.Steps.Add.Index);
end;

function TS4YStepListEditor.CreateButton(const AParent: TWinControl; const ACaption: string;
  const AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Align := alTop;
  Result.AlignWithMargins := True;
  Result.Margins.SetBounds(ScaleValue(C_MARGIN), ScaleValue(C_MARGIN), ScaleValue(C_MARGIN), 0);
  Result.Caption := ACaption;
  Result.OnClick := AOnClick;
end;

procedure TS4YStepListEditor.DeleteButtonClick(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := FStepListBox.ItemIndex;

  // The Object Inspector must not keep showing the step that is removed.
  Designer.SelectComponent(FProgressBar);
  FProgressBar.Steps.Delete(LIndex);
  StepsModified(Min(LIndex, FProgressBar.Steps.Count - 2));
end;

procedure TS4YStepListEditor.DesignerClosed(const Designer: IDesigner; AGoingDormant: Boolean);
begin
  inherited;

  if Designer = Self.Designer then
  begin
    FProgressBar := nil;
    Close;
  end;
end;

class function TS4YStepListEditor.FindEditor(const AProgressBar: TS4YStepProgressBar): TS4YStepListEditor;
var
  LIndex: Integer;
begin
  Result := nil;
  LIndex := 0;

  while not Assigned(Result) and (LIndex < Screen.FormCount) do
  begin
    if (Screen.Forms[LIndex] is TS4YStepListEditor) and
      (TS4YStepListEditor(Screen.Forms[LIndex]).FProgressBar = AProgressBar) then
    begin
      Result := TS4YStepListEditor(Screen.Forms[LIndex]);
    end;

    Inc(LIndex);
  end;
end;

procedure TS4YStepListEditor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TS4YStepListEditor.InsertButtonClick(Sender: TObject);
var
  LIndex: Integer;
begin
  // The new step takes the place of the selected one, which moves down.
  LIndex := FStepListBox.ItemIndex;
  FProgressBar.Steps.Insert(LIndex);
  StepsModified(LIndex);
end;

procedure TS4YStepListEditor.ItemDeleted(const ADesigner: IDesigner; Item: TPersistent);
begin
  inherited;

  if Assigned(FProgressBar) and (Item = FProgressBar) then
  begin
    FProgressBar := nil;
    Close;
  end;
end;

procedure TS4YStepListEditor.ItemsModified(const Designer: IDesigner);
begin
  inherited;

  if Assigned(FProgressBar) then
    UpdateList;
end;

procedure TS4YStepListEditor.MoveDownButtonClick(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := FStepListBox.ItemIndex;
  FProgressBar.Steps.Move(LIndex, LIndex + 1);
  StepsModified(LIndex + 1);
end;

procedure TS4YStepListEditor.MoveUpButtonClick(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := FStepListBox.ItemIndex;
  FProgressBar.Steps.Move(LIndex, LIndex - 1);
  StepsModified(LIndex - 1);
end;

procedure TS4YStepListEditor.SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections);
var
  LSelectedIndex: Integer;
begin
  inherited;

  if not Assigned(FProgressBar) or (ADesigner <> Designer) then
    Exit;

  LSelectedIndex := -1;

  if (ASelection.Count = 1) and (ASelection[0] is TS4YStepItem) and
    (TS4YStepItem(ASelection[0]).Collection.Owner = FProgressBar.Steps) then
  begin
    LSelectedIndex := TS4YStepItem(ASelection[0]).Index;
  end;

  FStepListBox.ItemIndex := LSelectedIndex;
  UpdateButtons;
end;

procedure TS4YStepListEditor.SelectStep(const AIndex: Integer);
begin
  FStepListBox.ItemIndex := AIndex;

  if AIndex >= 0 then
    Designer.SelectComponent(FProgressBar.Steps[AIndex]);

  UpdateButtons;
end;

procedure TS4YStepListEditor.StepListBoxClick(Sender: TObject);
begin
  SelectStep(FStepListBox.ItemIndex);
end;

procedure TS4YStepListEditor.StepsModified(const ASelectedIndex: Integer);
begin
  UpdateList;
  SelectStep(ASelectedIndex);
  Designer.Modified;
end;

procedure TS4YStepListEditor.UpdateButtons;
var
  LIndex: Integer;
  LCount: Integer;
begin
  LIndex := FStepListBox.ItemIndex;
  LCount := FProgressBar.Steps.Count;

  // The first and the last steps cannot be removed or moved, and no step can take their place.
  FInsertButton.Enabled := LIndex >= 1;
  FDeleteButton.Enabled := (LIndex >= 1) and (LIndex <= LCount - 2);
  FMoveUpButton.Enabled := (LIndex >= 2) and (LIndex <= LCount - 2);
  FMoveDownButton.Enabled := (LIndex >= 1) and (LIndex <= LCount - 3);
end;

procedure TS4YStepListEditor.UpdateList;
var
  LSelectedIndex: Integer;
begin
  LSelectedIndex := FStepListBox.ItemIndex;
  FStepListBox.Items.BeginUpdate;
  try
    FStepListBox.Items.Clear;

    for var LIndex := 0 to FProgressBar.Steps.Count - 1 do
      FStepListBox.Items.Add(Format(C_STEP_LINE_FORMAT, [LIndex, FProgressBar.Steps[LIndex].DisplayName]));
  finally
    FStepListBox.Items.EndUpdate;
  end;

  FStepListBox.ItemIndex := Min(LSelectedIndex, FStepListBox.Items.Count - 1);
  UpdateButtons;
end;

{ TS4YStepListProperty }

procedure TS4YStepListProperty.Edit;
begin
  TS4YStepListEditor.ShowEditor(Designer, GetComponent(0) as TS4YStepProgressBar);
end;

function TS4YStepListProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

{ TS4YStepProgressBarEditor }

procedure TS4YStepProgressBarEditor.ExecuteVerb(Index: Integer);
begin
  if Index = C_EDIT_STEPS_VERB then
    TS4YStepListEditor.ShowEditor(Designer, Component as TS4YStepProgressBar);
end;

function TS4YStepProgressBarEditor.GetVerb(Index: Integer): string;
begin
  if Index = C_EDIT_STEPS_VERB then
    Result := S_STEP_EDITOR_VERB
  else
    Result := '';
end;

function TS4YStepProgressBarEditor.GetVerbCount: Integer;
begin
  Result := C_VERB_COUNT;
end;

end.
