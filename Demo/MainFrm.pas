unit MainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, Soft4You.FMX.Controls.HTMLEditor, FMX.Memo.Types, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.TabControl, FMX.ListBox, System.ImageList, FMX.ImgList,
  System.Actions, FMX.ActnList, FMX.Objects, FMX.Menus, FMX.Layouts, FMX.Ani,
  FMX.Colors;

type
  TfrmMain = class(TForm)
    HTMLEditor: THTMLEditor;
    TabControl1: TTabControl;
    tabEditor: TTabItem;
    tabPlainText: TTabItem;
    edPlainText: TMemo;
    ImageList1: TImageList;
    tbEditor: TToolBar;
    btnToggleBold: TSpeedButton;
    btnInsertPlaceholder: TSpeedButton;
    cbParagraphStyle: TComboBox;
    btnToggleItalic: TSpeedButton;
    btnToggleUnderline: TSpeedButton;
    btnLoadFromHTMLFile: TSpeedButton;
    ActionList1: TActionList;
    StyleBook1: TStyleBook;
    actLoadFromHTMLFile: TAction;
    actSaveToHTMLFile: TAction;
    btnSaveToHTMLFile: TSpeedButton;
    sep2: TLine;
    sep1: TLine;
    btnToggleUnorderedList: TSpeedButton;
    btnToggleOrderedList: TSpeedButton;
    actToggleUnorderedList: TAction;
    actToggleOrderedList: TAction;
    Line1: TLine;
    Line2: TLine;
    btnClearFormatting: TSpeedButton;
    Line3: TLine;
    actClearFormatting: TAction;
    btnOutdent: TSpeedButton;
    actIncreaseIndent: TAction;
    actDecreaseIndent: TAction;
    btnIndent: TSpeedButton;
    btnToggleStrikeOut: TSpeedButton;
    btnAlignLeft: TSpeedButton;
    btnAlignJustify: TSpeedButton;
    btnAlignRight: TSpeedButton;
    btnAlignCenter: TSpeedButton;
    sbStatusBar: TStatusBar;
    lblStatusbarText: TLabel;
    Line4: TLine;
    btnFontColor: TSpeedButton;
    shapeFontColor: TRectangle;
    btnBackgroundColor: TSpeedButton;
    shapeBackgroundColor: TRectangle;
    pnlStatusBarPosition: TPanel;
    pnlStatusBarText: TPanel;
    pnlStatusBarCount: TPanel;
    lblStatusBarPosition: TLabel;
    lblStatusBarCount: TLabel;
    Line5: TLine;
    btnFind: TSpeedButton;
    Line6: TLine;
    btnTable: TSpeedButton;
    pupTable: TPopupMenu;
    miInsertTableRow: TMenuItem;
    miDeleteTableRow: TMenuItem;
    miInsertTableColumn: TMenuItem;
    miDeleteTableColumn: TMenuItem;
    MenuItem1: TMenuItem;
    miInsertTable: TMenuItem;
    MenuItem3: TMenuItem;
    Line7: TLine;
    btnImage: TSpeedButton;
    pupImage: TPopupMenu;
    miInsertImage: TMenuItem;
    miInsertInlineImage: TMenuItem;
    Line8: TLine;
    btnInsertEmoji: TSpeedButton;
    pupEmojis: TPopupMenu;
    Line9: TLine;
    btnDecreaseFontSize: TSpeedButton;
    btnIncreaseFontSize: TSpeedButton;
    actFindText: TAction;
    MenuItem2: TMenuItem;
    miLoadRemoteImages: TMenuItem;
    actLoadRemoteImages: TAction;
    actInsertImage: TAction;
    actInsertInlineImage: TAction;
    Line10: TLine;
    Line11: TLine;
    btnSuperScript: TSpeedButton;
    btnSubscript: TSpeedButton;
    procedure HTMLEditorLinkClick(Sender: TObject; const URL, LinkText: string);
    procedure TabControl1Change(Sender: TObject);
    procedure actToggleOrderedListExecute(Sender: TObject);
    procedure actClearFormattingExecute(Sender: TObject);
    procedure actIncreaseIndentExecute(Sender: TObject);
    procedure actDecreaseIndentExecute(Sender: TObject);
    procedure cbParagraphStyleChange(Sender: TObject);
    procedure actLoadFromHTMLFileExecute(Sender: TObject);
    procedure HTMLEditorStateChange(Sender: TObject; const State: TEditorState);
    procedure btnAlignLeftClick(Sender: TObject);
    procedure btnAlignCenterClick(Sender: TObject);
    procedure btnAlignRightClick(Sender: TObject);
    procedure btnAlignJustifyClick(Sender: TObject);
    procedure btnToggleStrikeOutClick(Sender: TObject);
    procedure btnFontColorClick(Sender: TObject);
    procedure btnBackgroundColorClick(Sender: TObject);
    procedure miInsertTableRowClick(Sender: TObject);
    procedure miInsertTableColumnClick(Sender: TObject);
    procedure miDeleteTableRowClick(Sender: TObject);
    procedure miDeleteTableColumnClick(Sender: TObject);
    procedure miInsertTableClick(Sender: TObject);
    procedure btnTableClick(Sender: TObject);
    procedure btnInsertEmojiClick(Sender: TObject);
    procedure btnDecreaseFontSizeClick(Sender: TObject);
    procedure btnIncreaseFontSizeClick(Sender: TObject);
    procedure btnInsertPlaceholderClick(Sender: TObject);
    procedure btnToggleUnorderedListClick(Sender: TObject);
    procedure btnToggleUnderlineClick(Sender: TObject);
    procedure btnToggleItalicClick(Sender: TObject);
    procedure btnToggleBoldClick(Sender: TObject);
    procedure actFindTextExecute(Sender: TObject);
    procedure actSaveToHTMLFileExecute(Sender: TObject);
    procedure actInsertImageExecute(Sender: TObject);
    procedure actInsertInlineImageExecute(Sender: TObject);
    procedure actLoadRemoteImagesExecute(Sender: TObject);
    procedure btnSuperScriptClick(Sender: TObject);
    procedure btnSubscriptClick(Sender: TObject);
  private
    FUpdatingUI: Boolean;
    procedure ApplyColorButtonTextStyle(const AButton: TSpeedButton);
    procedure BuildEmojisList;
    procedure EmojiClick(Sender: TObject);
    procedure ShowControlPopup(const AControl: TControl);
    procedure SetParagraphFormat(const AIndex: integer);
    function ShowPlaceholderDlg(var ADisplayedName, APlaceholderName: string): boolean;
    procedure UpdateEditorControls(const AState: TEditorState);
    procedure UpdateStatusBar;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.IOUtils,

  FMX.DialogService,

  Soft4You.HTML.Document,
  Soft4You.HTML.Types,
  Soft4You.Unicode.EmojiData,

  PlaceholderFrm,
  ColorSelectionFrm

  ;

const
  C_HTML_FILE_NAME = '..\..\Test\Test.html';


{$R *.fmx}

procedure TfrmMain.actToggleOrderedListExecute(Sender: TObject);
begin
  HTMLEditor.ToggleOrderedList;
end;

procedure TfrmMain.btnAlignCenterClick(Sender: TObject);
begin
  HTMLEditor.AlignCenter;
end;

procedure TfrmMain.btnAlignJustifyClick(Sender: TObject);
begin
  HTMLEditor.AlignJustify;
end;

procedure TfrmMain.btnAlignLeftClick(Sender: TObject);
begin
  HTMLEditor.AlignLeft;
end;

procedure TfrmMain.btnAlignRightClick(Sender: TObject);
begin
  HTMLEditor.AlignRight;
end;

procedure TfrmMain.btnInsertEmojiClick(Sender: TObject);
begin
  ShowControlPopup(TSpeedButton(Sender));
end;

procedure TfrmMain.btnInsertPlaceholderClick(Sender: TObject);
var
  LPlaceholderName,
  LDisplayName: string;
begin
  if ShowPlaceholderDlg(LDisplayName, LPlaceholderName) then
    HTMLEditor.InsertPlaceholder(LPlaceholderName, LDisplayName);
end;

procedure TfrmMain.btnSubscriptClick(Sender: TObject);
begin
  HTMLEditor.ToggleSubscript;
end;

procedure TfrmMain.btnSuperScriptClick(Sender: TObject);
begin
  HTMLEditor.ToggleSuperscript;
end;

procedure TfrmMain.btnTableClick(Sender: TObject);
begin
  ShowControlPopup(TSpeedButton(Sender));
end;

procedure TfrmMain.btnToggleBoldClick(Sender: TObject);
begin
  HTMLEditor.ToggleBold;
end;

procedure TfrmMain.btnToggleItalicClick(Sender: TObject);
begin
  HTMLEditor.ToggleItalic;
end;

procedure TfrmMain.btnToggleStrikeOutClick(Sender: TObject);
begin
  HTMLEditor.ToggleStrikeOut;
end;

procedure TfrmMain.btnToggleUnderlineClick(Sender: TObject);
begin
  HTMLEditor.ToggleUnderline;
end;

procedure TfrmMain.btnToggleUnorderedListClick(Sender: TObject);
begin
  HTMLEditor.ToggleUnorderedList;
end;

procedure TfrmMain.ApplyColorButtonTextStyle(const AButton: TSpeedButton);
begin
  AButton.StyledSettings := AButton.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style];
  AButton.TextSettings.Font.Size := 14;
  AButton.TextSettings.Font.Style := [TFontStyle.fsBold];
end;

procedure TfrmMain.BuildEmojisList;
var
  LEmojis: TArray<TEmoji>;
  LEmoji: TEmoji;
  LMenuItem: TMenuItem;
begin
  pupEmojis.Clear;

  LEmojis := TEmojiData.Emojis(TEmojiCategoryKind.eckSmileys);

  for LEmoji in LEmojis do
  begin
    LMenuItem := TMenuITem.Create(pupEmojis);
    LMenuItem.OnClick := EmojiClick;
    LMenuItem.Text := LEmoji.Glyph;
    pupEmojis.AddObject(LMenuItem);
  end;
end;

procedure TfrmMain.cbParagraphStyleChange(Sender: TObject);
begin
  if FUpdatingUI then
    exit;

  SetParagraphFormat(TComboBox(Sender).ItemIndex);
end;

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited;

  FUpdatingUI := False;
  lblStatusbarText.Text := EmptyStr;
  lblStatusBarCount.Text := EmptyStr;
  lblStatusBarPosition.Text := EmptyStr;
  TabControl1.ActiveTab := tabEditor;

  ApplyColorButtonTextStyle(btnFontColor);
  ApplyColorButtonTextStyle(btnBackgroundColor);
  shapeBackgroundColor.Fill.Color := HTMLEditor.BackgroundColor;
  shapeFontColor.Fill.Color := HTMLEditor.FontColor;

  BuildEmojisList;

  UpdateEditorControls(HTMLEditor.State);
  UpdateStatusBar;
end;

procedure TfrmMain.EmojiClick(Sender: TObject);
begin
  if not Assigned(Sender) then
    exit;

  HTMLEditor.InsertText(TMenuItem(Sender).Text);
end;

procedure TfrmMain.HTMLEditorLinkClick(Sender: TObject; const URL, LinkText: string);
begin
  ShowMessage(Format('Clicked link "%s", url=%s', [LinkText, URL]));
end;

procedure TfrmMain.HTMLEditorStateChange(Sender: TObject; const State: TEditorState);
begin
  UpdateEditorControls(State);
  UpdateStatusBar;
end;

procedure TfrmMain.miDeleteTableColumnClick(Sender: TObject);
begin
  HTMLEditor.DeleteTableColumn;
end;

procedure TfrmMain.miDeleteTableRowClick(Sender: TObject);
begin
  HTMLEditor.DeleteTableRow;
end;

procedure TfrmMain.miInsertTableClick(Sender: TObject);
begin
  HTMLEditor.InsertTable();
end;

procedure TfrmMain.miInsertTableColumnClick(Sender: TObject);
begin
  HTMLEditor.InsertTableColumn;
end;

procedure TfrmMain.miInsertTableRowClick(Sender: TObject);
begin
  HTMLEditor.InsertTableRow;
end;

procedure TfrmMain.btnFontColorClick(Sender: TObject);
var
  LColor: TAlphaColor;
begin
  LColor := shapeFontColor.Fill.Color;
  if not TColorSelection.Execute(LColor) then
    Exit;

  shapeFontColor.Fill.Color := LColor;
  HTMLEditor.SetCurrentFontColor(LColor);
end;

procedure TfrmMain.btnBackgroundColorClick(Sender: TObject);
var
  LColor: TAlphaColor;
begin
  LColor := shapeBackgroundColor.Fill.Color;
  if not TColorSelection.Execute(LColor) then
    Exit;

  shapeBackgroundColor.Fill.Color := LColor;
  HTMLEditor.SetCurrentBackgroundColor(LColor);
end;

procedure TfrmMain.actClearFormattingExecute(Sender: TObject);
begin
  HTMLEditor.ClearFormatting;
end;

procedure TfrmMain.actDecreaseIndentExecute(Sender: TObject);
begin
  HTMLEditor.Outdent;
end;

procedure TfrmMain.actFindTextExecute(Sender: TObject);
var
  LTextToSearch: string;
begin
  TDialogService.InputQuery('Find', ['Text to find'], [EmptyStr],
    procedure (const AResult: TModalResult; const AValues: array of string)
    begin
      if AResult = mrOk then
        LTextToSearch := AValues[0];
    end
  );

  if LTextToSearch.IsEmpty then
    exit;

  HTMLEditor.FindNext(LTextToSearch);
end;

procedure TfrmMain.actIncreaseIndentExecute(Sender: TObject);
begin
  HTMLEditor.Indent;
end;

procedure TfrmMain.actInsertImageExecute(Sender: TObject);
var
  LDlg: TOpenDialog;
begin
  LDlg := TOpenDialog.Create(nil);

  try
    LDlg.Title := 'Select image';
    LDlg.Filter := 'Portable Network Graphic (*.png)|*.png';

    if LDlg.Execute then
      HTMLEditor.InsertImage(LDlg.FileName);
  finally
    LDlg.Free;
  end;
end;

procedure TfrmMain.actInsertInlineImageExecute(Sender: TObject);
var
  LDlg: TOpenDialog;
begin
  LDlg := TOpenDialog.Create(nil);

  try
    LDlg.Title := 'Select image';
    LDlg.Filter := 'Portable Network Graphic (*.png)|*.png';

    if LDlg.Execute then
      HTMLEditor.InsertInlineImage(LDlg.FileName);
  finally
    LDlg.Free;
  end;
end;

procedure TfrmMain.actLoadFromHTMLFileExecute(Sender: TObject);
var
  LDlg: TOpenDialog;
begin
  LDlg := TOpenDialog.Create(nil);

  try
    LDlg.Title := 'Select HTML document';
    LDlg.Filter := 'HTML document (*.html)|*.html';

    if LDlg.Execute then
      HTMLEditor.HTML := TFile.ReadAllText(LDlg.FileName, TEncoding.UTF8);
  finally
    LDlg.Free;
  end;
end;

procedure TfrmMain.actLoadRemoteImagesExecute(Sender: TObject);
begin
  HTMLEditor.LoadRemoteImages;
end;

procedure TfrmMain.actSaveToHTMLFileExecute(Sender: TObject);
var
  LDlg: TSaveDialog;
begin
  LDlg := TSaveDialog.Create(nil);

  try
    LDlg.Title := 'Save document';
    LDLG.Filter := 'HTML document (*.html)|*.html';
    LDlg.FileName := 'No name.html';

    if LDlg.Execute then
      TFile.WriteAllText(LDlg.FileName, HTMLEditor.FullHTML, TEncoding.UTF8);
  finally
    LDlg.Free;
  end;
end;

procedure TfrmMain.SetParagraphFormat(const AIndex: integer);
begin
  case AIndex of
    0: HTMLEditor.SetCurrentParagraphFormat(pfBodyText);
    1: HTMLEditor.SetCurrentParagraphFormat(pfParagraph);
    2: HTMLEditor.SetCurrentParagraphFormat(pfH1);
    3: HTMLEditor.SetCurrentParagraphFormat(pfH2);
    4: HTMLEditor.SetCurrentParagraphFormat(pfH3);
    5: HTMLEditor.SetCurrentParagraphFormat(pfH4);
    6: HTMLEditor.SetCurrentParagraphFormat(pfH5);
    7: HTMLEditor.SetCurrentParagraphFormat(pfH6);
    8: HTMLEditor.SetCurrentParagraphFormat(pfPre);
  end;
end;

procedure TfrmMain.ShowControlPopup(const AControl: TControl);
var
  LPoint: TPointF;
begin
  LPoint := ClientToScreen(TPointF.Create(AControl.Position.X, AControl.Height));

  if Assigned(AControl.PopupMenu) then
    AControl.PopupMenu.Popup(LPoint.X, LPoint.Y);
end;

function TfrmMain.ShowPlaceholderDlg(var ADisplayedName, APlaceholderName: string): boolean;
begin
  Result := TfrmPlaceholder.Execute(ADisplayedName, APlaceholderName);
end;

procedure TfrmMain.btnDecreaseFontSizeClick(Sender: TObject);
begin
  HTMLEditor.DecreaseFontSize;
end;

procedure TfrmMain.btnIncreaseFontSizeClick(Sender: TObject);
begin
  HTMLEditor.IncreaseFontSize;
end;

procedure TfrmMain.TabControl1Change(Sender: TObject);
begin
  if TabControl1.ActiveTab = tabEditor then
    HTMLEditor.HTML := edPlainText.Lines.Text
  else if TabControl1.ActiveTab = tabPlainText then
    edPlainText.Lines.Text := HTMLEditor.HTML;
end;

procedure TfrmMain.UpdateEditorControls(const AState: TEditorState);
begin
  if FUpdatingUI then
    exit;

  FUpdatingUI := True;

  try
    cbParagraphStyle.ItemIndex := Ord(AState.ParagraphFormat);
    btnToggleBold.IsPressed := AState.IsBold;
    btnToggleItalic.IsPressed := AState.IsItalic;
    btnToggleUnderline.IsPressed := AState.IsUnderline;
    btnToggleStrikeOut.IsPressed := AState.IsStrikeOut;
    btnToggleUnorderedList.IsPressed := AState.IsUnorderedList;
    btnToggleOrderedList.IsPressed := AState.IsOrderedList;
    btnSuperscript.IsPressed := AState.IsSuperscript;
    btnSubscript.IsPressed := AState.IsSubscript;
    btnAlignLeft.IsPressed := AState.Alignment = haLeft;
    btnAlignCenter.IsPressed := AState.Alignment = haCenter;
    btnAlignRight.IsPressed := AState.Alignment = haRight;
    btnAlignJustify.IsPressed := AState.Alignment = haJustify;
    btnOutdent.Enabled := AState.CanOutdent;
    shapeFontColor.Fill.Color := AState.FontColor;
    shapeBackgroundColor.Fill.Color := AState.BackgroundColor;
  finally
    FUpdatingUI := False;
  end;
end;

procedure TfrmMain.UpdateStatusBar;
var
  LRun: THTMLRun;
  LText: string;
begin
  LRun := HTMLEditor.CurrentRun;
  LText := EmptyStr;

  if Assigned(LRun) then
  begin
    if LRun.IsImage then
      LText := LRun.ImageSrc
    else if LRun.IsPlaceholder then
      LText := LRun.DisplayText
  end;

  lblStatusbarText.Text := LText;
  lblStatusBarCount.Text := Format('Words: %d, Chars: %d', [HTMLEditor.WordCount, HTMLEditor.CharCount]);
  lblStatusBarPosition.Text := Format('Line: %d, Col: %d', [HTMLEditor.State.LineNumber, HTMLEDitor.State.ColumnNumber]);
end;

end.
