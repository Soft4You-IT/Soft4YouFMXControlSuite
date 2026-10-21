unit Soft4You.FMX.Controls.HTMLEditor.Design;

{ *****************************************************************************
  S4YFMXHTMLEditor - WYSIWYG HTML editor for Delphi FireMonkey (FMX)
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  DesignIntf,
  DesignEditors;

type

  // ===========================================================================
  // TS4YHTMLPropertyEditor
  // ===========================================================================

  TS4YHTMLPropertyEditor = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

procedure Register;

implementation

uses
  System.Classes,
  Data.Bind.Components,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Soft4You.FMX.Controls.HTMLEditor;

// -----------------------------------------------------------------------------
// TS4YHTMLPropertyEditor
// -----------------------------------------------------------------------------

function TS4YHTMLPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

procedure TS4YHTMLPropertyEditor.Edit;
const
  C_DLG_W   = 700;
  C_DLG_H   = 500;
  C_BTN_W   = 80;
  C_BTN_H   = 25;
  C_PANEL_H = 40;
  C_MARGIN  = 8;
var
  LForm: TForm;
  LMemo: TMemo;
  LPanel: TPanel;
  LButtonOk: TButton;
  LButtonCancel: TButton;
begin
  LForm := TForm.CreateNew(nil);
  try
    LForm.Caption  := 'HTML';
    LForm.Width    := C_DLG_W;
    LForm.Height   := C_DLG_H;
    LForm.Position := poScreenCenter;

    LPanel            := TPanel.Create(LForm);
    LPanel.Parent     := LForm;
    LPanel.Align      := alBottom;
    LPanel.Height     := C_PANEL_H;
    LPanel.BevelOuter := bvNone;

    LButtonCancel             := TButton.Create(LPanel);
    LButtonCancel.Parent      := LPanel;
    LButtonCancel.Caption     := 'Annulla';
    LButtonCancel.ModalResult := mrCancel;
    LButtonCancel.Cancel      := True;
    LButtonCancel.Width       := C_BTN_W;
    LButtonCancel.Height      := C_BTN_H;
    LButtonCancel.Anchors     := [akRight, akTop];
    LButtonCancel.Left        := C_DLG_W - C_BTN_W - C_MARGIN;
    LButtonCancel.Top         := (C_PANEL_H - C_BTN_H) div 2;

    LButtonOk             := TButton.Create(LPanel);
    LButtonOk.Parent      := LPanel;
    LButtonOk.Caption     := 'OK';
    LButtonOk.ModalResult := mrOk;
    LButtonOk.Default     := True;
    LButtonOk.Width       := C_BTN_W;
    LButtonOk.Height      := C_BTN_H;
    LButtonOk.Anchors     := [akRight, akTop];
    LButtonOk.Left        := C_DLG_W - (C_BTN_W + C_MARGIN) * 2;
    LButtonOk.Top         := LButtonCancel.Top;

    LMemo            := TMemo.Create(LForm);
    LMemo.Parent     := LForm;
    LMemo.Align      := alClient;
    LMemo.ScrollBars := ssBoth;
    LMemo.WordWrap   := False;
    LMemo.Font.Name  := 'Courier New';
    LMemo.Font.Size  := 10;
    LMemo.Text       := GetValue;

    if LForm.ShowModal = mrOk then
      SetValue(LMemo.Text);
  finally
    LForm.Free;
  end;
end;

// -----------------------------------------------------------------------------

procedure Register;
begin
  RegisterComponents('Soft4You Ctrls', [TS4YHTMLEditor]);
  RegisterObservableMember([TS4YHTMLEditor], 'HTML', 'OnChange');
  RegisterPropertyEditor(TypeInfo(string), TS4YHTMLEditor, 'HTML', TS4YHTMLPropertyEditor);
end;

end.