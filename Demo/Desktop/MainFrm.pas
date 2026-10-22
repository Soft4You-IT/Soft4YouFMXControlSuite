unit MainFrm;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  Soft4You.FMX.Controls.HTMLEditor,
  FMX.Memo.Types,
  FMX.StdCtrls,
  FMX.Controls.Presentation,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.TabControl,
  FMX.ListBox,
  System.ImageList,
  FMX.ImgList,
  System.Actions,
  FMX.ActnList,
  FMX.Objects,
  FMX.Menus,
  FMX.Layouts,
  FMX.Ani,
  FMX.Colors;

type
  TfrmMain = class(TForm)
    HTMLEditor: TS4YHTMLEditor;
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
    btnFindNext: TSpeedButton;
    btnFindPrevious: TSpeedButton;
    Line6: TLine;
    btnTable: TSpeedButton;
    pupTable: TPopupMenu;
    miInsertTableRow: TMenuItem;
    miDeleteTableRow: TMenuItem;
    miInsertTableColumn: TMenuItem;
    miDeleteTableColumn: TMenuItem;
    miTableStyleSeparator: TMenuItem;
    miTableCellBackground: TMenuItem;
    miTableCellBackgroundColor: TMenuItem;
    miTableCellBackgroundNone: TMenuItem;
    miTableCellBorder: TMenuItem;
    miTableCellBorderAll: TMenuItem;
    miTableCellBorderNone: TMenuItem;
    miTableCellBorderSeparatorSides: TMenuItem;
    miTableCellBorderTop: TMenuItem;
    miTableCellBorderRight: TMenuItem;
    miTableCellBorderBottom: TMenuItem;
    miTableCellBorderLeft: TMenuItem;
    miTableCellBorderSeparatorStyle: TMenuItem;
    miTableCellBorderColor: TMenuItem;
    miTableCellBorderWidth1: TMenuItem;
    miTableCellBorderWidth2: TMenuItem;
    miTableCellBorderWidth3: TMenuItem;
    miTableCellPadding: TMenuItem;
    miTableCellPaddingDefault: TMenuItem;
    miTableCellPadding4: TMenuItem;
    miTableCellPadding8: TMenuItem;
    miTableCellPadding16: TMenuItem;
    miTableCellVerticalAlignment: TMenuItem;
    miTableCellVerticalAlignmentTop: TMenuItem;
    miTableCellVerticalAlignmentMiddle: TMenuItem;
    miTableCellVerticalAlignmentBottom: TMenuItem;
    miTableAlignment: TMenuItem;
    miTableAlignmentLeft: TMenuItem;
    miTableAlignmentCenter: TMenuItem;
    miTableAlignmentRight: TMenuItem;
    miTableSpacing: TMenuItem;
    miTableSpacing0: TMenuItem;
    miTableSpacing2: TMenuItem;
    miTableSpacing4: TMenuItem;
    miTableSpacing8: TMenuItem;
    miTableBorder: TMenuItem;
    miTableBorderShow: TMenuItem;
    miTableBorderHide: TMenuItem;
    miTableWidth: TMenuItem;
    miTableWidthAuto: TMenuItem;
    miTableWidth50Percent: TMenuItem;
    miTableWidth100Percent: TMenuItem;
    miTableWidth400Pixels: TMenuItem;
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
    actFindNext: TAction;
    actFindPrevious: TAction;
    MenuItem2: TMenuItem;
    miLoadRemoteImages: TMenuItem;
    actLoadRemoteImages: TAction;
    actInsertImage: TAction;
    actInsertInlineImage: TAction;
    Line10: TLine;
    Line11: TLine;
    btnSuperScript: TSpeedButton;
    btnSubscript: TSpeedButton;
    pnlStatusBarReadOnly: TPanel;
    swReadOnly: TSwitch;
    lblReadOnly: TLabel;
    procedure HTMLEditorLinkClick(Sender: TObject; const URL, LinkText: string);
    procedure TabControl1Change(Sender: TObject);
    procedure actToggleOrderedListExecute(Sender: TObject);
    procedure actClearFormattingExecute(Sender: TObject);
    procedure actIncreaseIndentExecute(Sender: TObject);
    procedure actDecreaseIndentExecute(Sender: TObject);
    procedure cbParagraphStyleChange(Sender: TObject);
    procedure actLoadFromHTMLFileExecute(Sender: TObject);
    procedure HTMLEditorStateChange(Sender: TObject; const State: TS4YEditorState);
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
    procedure miTableCellBackgroundColorClick(Sender: TObject);
    procedure miTableCellBackgroundNoneClick(Sender: TObject);
    procedure miTableCellBorderAllClick(Sender: TObject);
    procedure miTableCellBorderNoneClick(Sender: TObject);
    procedure miTableCellBorderSideClick(Sender: TObject);
    procedure miTableCellBorderColorClick(Sender: TObject);
    procedure miTableCellBorderWidthClick(Sender: TObject);
    procedure miTableCellPaddingClick(Sender: TObject);
    procedure miTableCellVerticalAlignmentClick(Sender: TObject);
    procedure miTableAlignmentClick(Sender: TObject);
    procedure miTableSpacingClick(Sender: TObject);
    procedure miTableBorderClick(Sender: TObject);
    procedure miTableWidthAutoClick(Sender: TObject);
    procedure miTableWidthPercentClick(Sender: TObject);
    procedure miTableWidthPixelsClick(Sender: TObject);
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
    procedure actFindNextExecute(Sender: TObject);
    procedure actFindPreviousExecute(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
    procedure actSaveToHTMLFileExecute(Sender: TObject);
    procedure actInsertImageExecute(Sender: TObject);
    procedure actInsertInlineImageExecute(Sender: TObject);
    procedure actLoadRemoteImagesExecute(Sender: TObject);
    procedure btnSuperScriptClick(Sender: TObject);
    procedure btnSubscriptClick(Sender: TObject);
    procedure swReadOnlySwitch(Sender: TObject);
  private
    FLastSearchText: string;
    FUpdatingUI: Boolean;
    procedure ApplyColorButtonTextStyle(const AButton: TSpeedButton);
    procedure RestyleVisibleBorders(AWidth: Single; AColor: TAlphaColor);
    procedure BuildEmojisList;
    procedure EmojiClick(Sender: TObject);
    procedure ShowControlPopup(const AControl: TControl);
    procedure SetParagraphFormat(const AIndex: integer);
    function ShowPlaceholderDlg(var ADisplayedName, APlaceholderName: string): boolean;
    procedure UpdateEditorControls(const AState: TS4YEditorState);
    procedure UpdateReadOnlyControls;
    procedure UpdateStatusBar;
    procedure UpdateTableMenuItems(const AState: TS4YEditorState);
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
  ColorSelectionFrm;

const
  C_HTML_FILE_NAME = '..\..\..\Test\Test.html';

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
  LEmojis: TArray<TS4YEmoji>;
  LEmoji: TS4YEmoji;
  LMenuItem: TMenuItem;
begin
  pupEmojis.Clear;

  LEmojis := TS4YEmojiData.Emojis(TS4YEmojiCategoryKind.eckSmileys);

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
  swReadOnly.IsChecked := HTMLEditor.ReadOnly;
  UpdateReadOnlyControls;

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

procedure TfrmMain.HTMLEditorStateChange(Sender: TObject; const State: TS4YEditorState);
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

function BorderSideOf(const ABorders: TS4YTableBorders; ASide: TS4YTableSide): TS4YTableBorderSide;
begin
  case ASide of
    tsTop: Result := ABorders.Top;
    tsRight: Result := ABorders.Right;
    tsBottom: Result := ABorders.Bottom;
  else
    Result := ABorders.Left;
  end;
end;

// Changes the width and the color of the sides that have a border; a width of 0 or TAlphaColors.Null keeps the current one.
// The sides that end up with the same border are changed together, so that one change is one undo step.
procedure TfrmMain.RestyleVisibleBorders(AWidth: Single; AColor: TAlphaColor);
var
  LBorders: TS4YTableBorders;
  LDone: TS4YTableSides;
  LGroup: TS4YTableSides;
  LSide: TS4YTableSide;
  LOtherSide: TS4YTableSide;
  LCurrent: TS4YTableBorderSide;
  LNew: TS4YTableBorderSide;
  LOtherNew: TS4YTableBorderSide;

  function Restyled(const ASide: TS4YTableBorderSide): TS4YTableBorderSide;
  begin
    Result := ASide;

    if AWidth > 0 then
      Result.Width := AWidth;

    if AColor <> TAlphaColors.Null then
      Result.Color := AColor;
  end;

begin
  LBorders := HTMLEditor.State.TableCellBorders;
  LDone := [];

  for LSide := Low(TS4YTableSide) to High(TS4YTableSide) do
  begin
    LCurrent := BorderSideOf(LBorders, LSide);

    if LCurrent.IsVisible and not (LSide in LDone) then
    begin
      LNew := Restyled(LCurrent);
      LGroup := [LSide];

      for LOtherSide := Low(TS4YTableSide) to High(TS4YTableSide) do
      begin
        LOtherNew := Restyled(BorderSideOf(LBorders, LOtherSide));

        if (LOtherSide > LSide) and BorderSideOf(LBorders, LOtherSide).IsVisible and LOtherNew.Equals(LNew) then
          Include(LGroup, LOtherSide);
      end;

      HTMLEditor.SetTableCellBorder(LGroup, LNew);
      LDone := LDone + LGroup;
    end;
  end;
end;

procedure TfrmMain.miTableCellBorderAllClick(Sender: TObject);
begin
  HTMLEditor.SetTableCellBorder([tsTop, tsRight, tsBottom, tsLeft], TS4YTableBorderSide.Default);
end;

procedure TfrmMain.miTableCellBorderColorClick(Sender: TObject);
var
  LBorders: TS4YTableBorders;
  LColor: TAlphaColor;
  LSide: TS4YTableSide;
begin
  LBorders := HTMLEditor.State.TableCellBorders;
  LColor := C_DEFAULT_TABLE_BORDER_COLOR;

  for LSide := High(TS4YTableSide) downto Low(TS4YTableSide) do
  begin
    if BorderSideOf(LBorders, LSide).IsVisible then
      LColor := BorderSideOf(LBorders, LSide).Color;
  end;

  if not TColorSelection.Execute(LColor) then
    Exit;

  RestyleVisibleBorders(0, LColor);
end;

procedure TfrmMain.miTableCellBorderNoneClick(Sender: TObject);
begin
  HTMLEditor.SetTableCellBorder([tsTop, tsRight, tsBottom, tsLeft], TS4YTableBorderSide.None);
end;

// Each side switches: a side with a border loses it, a side without one gets the default border
procedure TfrmMain.miTableCellBorderSideClick(Sender: TObject);
var
  LSide: TS4YTableSide;
begin
  LSide := TS4YTableSide(TMenuItem(Sender).Tag);

  if BorderSideOf(HTMLEditor.State.TableCellBorders, LSide).IsVisible then
  begin
    HTMLEditor.SetTableCellBorder([LSide], TS4YTableBorderSide.None);
  end
  else
  begin
    HTMLEditor.SetTableCellBorder([LSide], TS4YTableBorderSide.Default);
  end;
end;

procedure TfrmMain.miTableCellBorderWidthClick(Sender: TObject);
begin
  RestyleVisibleBorders(TMenuItem(Sender).Tag, TAlphaColors.Null);
end;

procedure TfrmMain.miTableAlignmentClick(Sender: TObject);
begin
  HTMLEditor.SetTableAlignment(TS4YHTMLAlignment(TMenuItem(Sender).Tag));
end;

procedure TfrmMain.miTableSpacingClick(Sender: TObject);
begin
  HTMLEditor.SetTableCellSpacing(TMenuItem(Sender).Tag);
end;

procedure TfrmMain.miTableBorderClick(Sender: TObject);
begin
  HTMLEditor.SetTableBorder(TMenuItem(Sender).Tag <> 0);
end;

procedure TfrmMain.miTableCellBackgroundColorClick(Sender: TObject);
var
  LColor: TAlphaColor;
begin
  LColor := TAlphaColors.White;

  if not TColorSelection.Execute(LColor) then
    Exit;

  HTMLEditor.SetTableCellBackgroundColor(LColor);
end;

procedure TfrmMain.miTableCellBackgroundNoneClick(Sender: TObject);
begin
  HTMLEditor.SetTableCellBackgroundColor(TAlphaColors.Null);
end;

procedure TfrmMain.miTableCellPaddingClick(Sender: TObject);
var
  LPixels: Integer;
begin
  LPixels := TMenuItem(Sender).Tag;

  if LPixels < 0 then
  begin
    HTMLEditor.SetTableCellPadding(TS4YTablePadding.Default);
  end
  else
  begin
    HTMLEditor.SetTableCellPadding(TS4YTablePadding.Uniform(LPixels));
  end;
end;

procedure TfrmMain.miTableCellVerticalAlignmentClick(Sender: TObject);
begin
  HTMLEditor.SetTableCellVerticalAlignment(TS4YTableVerticalAlignment(TMenuItem(Sender).Tag));
end;

procedure TfrmMain.miTableWidthAutoClick(Sender: TObject);
begin
  HTMLEditor.SetTableWidth(TS4YTableLength.Auto);
end;

procedure TfrmMain.miTableWidthPercentClick(Sender: TObject);
begin
  HTMLEditor.SetTableWidth(TS4YTableLength.Percent(TMenuItem(Sender).Tag));
end;

procedure TfrmMain.miTableWidthPixelsClick(Sender: TObject);
begin
  HTMLEditor.SetTableWidth(TS4YTableLength.Pixels(TMenuItem(Sender).Tag));
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

procedure TfrmMain.actFindNextExecute(Sender: TObject);
begin
  if FLastSearchText.IsEmpty then
  begin
    actFindTextExecute(Sender);
    Exit;
  end;

  HTMLEditor.FindNext(FLastSearchText);
end;

procedure TfrmMain.actFindPreviousExecute(Sender: TObject);
begin
  if FLastSearchText.IsEmpty then
  begin
    actFindTextExecute(Sender);
    Exit;
  end;

  HTMLEditor.FindPrevious(FLastSearchText);
end;

// F3 and Shift+F3 are handled here, and not with the ShortCut property of actFindNext and
// actFindPrevious, because in Delphi 11 FMX does not match the ShortCut of an action for the
// function keys F1-F11: TCustomAction.IsDialogKey changes the key to upper case, so the code of
// F3 becomes the one of 'R' and never equals the ShortCut. Delphi 10.4, 12 and 13 compare the
// keys correctly, but handling the keys here works in every version.
// The form receives the key because the editor leaves to the form the keys it does not use.
procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
begin
  if (Key <> vkF3) or ((Shift <> []) and (Shift <> [ssShift])) then
    Exit;

  if ssShift in Shift then
    actFindPrevious.Execute
  else
    actFindNext.Execute;

  Key := 0;
end;

// The dialog can be asynchronous (mobile platforms), so the search runs inside its callback
procedure TfrmMain.actFindTextExecute(Sender: TObject);
begin
  TDialogService.InputQuery('Find', ['Text to find'], [FLastSearchText],
    procedure(const AResult: TModalResult; const AValues: array of string)
    begin
      if (AResult <> mrOk) or AValues[0].IsEmpty then
        Exit;

      FLastSearchText := AValues[0];
      HTMLEditor.FindNext(FLastSearchText);
    end
  );
end;

procedure TfrmMain.actIncreaseIndentExecute(Sender: TObject);
begin
  HTMLEditor.Indent;
end;

procedure TfrmMain.actInsertImageExecute(Sender: TObject);
var
  LDialog: TOpenDialog;
begin
  LDialog := TOpenDialog.Create(nil);

  try
    LDialog.Title := 'Select image';
    LDialog.Filter := 'Portable Network Graphic (*.png)|*.png';

    if LDialog.Execute then
      HTMLEditor.InsertImage(LDialog.FileName);
  finally
    LDialog.Free;
  end;
end;

procedure TfrmMain.actInsertInlineImageExecute(Sender: TObject);
var
  LDialog: TOpenDialog;
begin
  LDialog := TOpenDialog.Create(nil);

  try
    LDialog.Title := 'Select image';
    LDialog.Filter := 'Portable Network Graphic (*.png)|*.png';

    if LDialog.Execute then
      HTMLEditor.InsertInlineImage(LDialog.FileName);
  finally
    LDialog.Free;
  end;
end;

procedure TfrmMain.actLoadFromHTMLFileExecute(Sender: TObject);
var
  LDialog: TOpenDialog;
begin
  LDialog := TOpenDialog.Create(nil);

  try
    LDialog.Title := 'Select HTML document';
    LDialog.Filter := 'HTML document (*.html)|*.html';

    if LDialog.Execute then
      HTMLEditor.LoadFromFile(LDialog.FileName);
  finally
    LDialog.Free;
  end;
end;

procedure TfrmMain.actLoadRemoteImagesExecute(Sender: TObject);
begin
  HTMLEditor.LoadRemoteImages;
end;

procedure TfrmMain.actSaveToHTMLFileExecute(Sender: TObject);
var
  LDialog: TSaveDialog;
begin
  LDialog := TSaveDialog.Create(nil);

  try
    LDialog.Title := 'Save document';
    LDialog.Filter := 'HTML document (*.html)|*.html';
    LDialog.FileName := 'No name.html';

    if LDialog.Execute then
      HTMLEditor.SaveToFile(LDialog.FileName);
  finally
    LDialog.Free;
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

procedure TfrmMain.UpdateEditorControls(const AState: TS4YEditorState);
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
    btnOutdent.Enabled := AState.CanOutdent and not HTMLEditor.ReadOnly;
    shapeFontColor.Fill.Color := AState.FontColor;
    shapeBackgroundColor.Fill.Color := AState.BackgroundColor;
    UpdateTableMenuItems(AState);
  finally
    FUpdatingUI := False;
  end;
end;

function IsUniformPadding(const APadding: TS4YTablePadding; const APixels: Integer): Boolean;
begin
  Result := APadding.IsSet and
    (APadding.Left = APixels) and
    (APadding.Top = APixels) and
    (APadding.Right = APixels) and
    (APadding.Bottom = APixels);
end;

// True when at least one side has a border and every side that has one is APixels wide
function HasVisibleBorderWidth(const ABorders: TS4YTableBorders; APixels: Single): Boolean;
var
  LSide: TS4YTableSide;
begin
  Result := False;

  for LSide := Low(TS4YTableSide) to High(TS4YTableSide) do
  begin
    if BorderSideOf(ABorders, LSide).IsVisible then
    begin
      if BorderSideOf(ABorders, LSide).Width <> APixels then
      begin
        Result := False;
        Exit;
      end;

      Result := True;
    end;
  end;
end;

procedure TfrmMain.UpdateTableMenuItems(const AState: TS4YEditorState);
var
  LInTable: Boolean;
begin
  LInTable := AState.TableRow >= 0;

  miTableCellBorderTop.IsChecked := LInTable and AState.TableCellBorders.Top.IsVisible;
  miTableCellBorderRight.IsChecked := LInTable and AState.TableCellBorders.Right.IsVisible;
  miTableCellBorderBottom.IsChecked := LInTable and AState.TableCellBorders.Bottom.IsVisible;
  miTableCellBorderLeft.IsChecked := LInTable and AState.TableCellBorders.Left.IsVisible;
  miTableCellBorderWidth1.IsChecked := LInTable and HasVisibleBorderWidth(AState.TableCellBorders, 1);
  miTableCellBorderWidth2.IsChecked := LInTable and HasVisibleBorderWidth(AState.TableCellBorders, 2);
  miTableCellBorderWidth3.IsChecked := LInTable and HasVisibleBorderWidth(AState.TableCellBorders, 3);

  miTableCellPaddingDefault.IsChecked := LInTable and not AState.TableCellPadding.IsSet;
  miTableCellPadding4.IsChecked := LInTable and IsUniformPadding(AState.TableCellPadding, 4);
  miTableCellPadding8.IsChecked := LInTable and IsUniformPadding(AState.TableCellPadding, 8);
  miTableCellPadding16.IsChecked := LInTable and IsUniformPadding(AState.TableCellPadding, 16);

  miTableCellVerticalAlignmentTop.IsChecked := LInTable and (AState.TableCellVerticalAlignment = tvaTop);
  miTableCellVerticalAlignmentMiddle.IsChecked := LInTable and (AState.TableCellVerticalAlignment = tvaMiddle);
  miTableCellVerticalAlignmentBottom.IsChecked := LInTable and (AState.TableCellVerticalAlignment = tvaBottom);

  miTableAlignmentLeft.IsChecked := LInTable and (AState.TableAlignment = haLeft);
  miTableAlignmentCenter.IsChecked := LInTable and (AState.TableAlignment = haCenter);
  miTableAlignmentRight.IsChecked := LInTable and (AState.TableAlignment = haRight);

  miTableSpacing0.IsChecked := LInTable and (AState.TableCellSpacing = 0);
  miTableSpacing2.IsChecked := LInTable and (AState.TableCellSpacing = 2);
  miTableSpacing4.IsChecked := LInTable and (AState.TableCellSpacing = 4);
  miTableSpacing8.IsChecked := LInTable and (AState.TableCellSpacing = 8);

  miTableBorderShow.IsChecked := LInTable and AState.TableHasBorder;
  miTableBorderHide.IsChecked := LInTable and not AState.TableHasBorder;

  miTableWidthAuto.IsChecked := LInTable and AState.TableWidth.IsAuto;
  miTableWidth50Percent.IsChecked := LInTable and (AState.TableWidth.Kind = tlkPercent) and (AState.TableWidth.Value = 50);
  miTableWidth100Percent.IsChecked := LInTable and (AState.TableWidth.Kind = tlkPercent) and (AState.TableWidth.Value = 100);
  miTableWidth400Pixels.IsChecked := LInTable and (AState.TableWidth.Kind = tlkPixels) and (AState.TableWidth.Value = 400);
end;

procedure TfrmMain.swReadOnlySwitch(Sender: TObject);
begin
  HTMLEditor.ReadOnly := swReadOnly.IsChecked;
  UpdateReadOnlyControls;
  HTMLEditor.SetFocus;
end;

procedure TfrmMain.UpdateReadOnlyControls;
var
  LEditable: Boolean;
begin
  // Find, load and save stay available: they do not edit the open document by hand
  LEditable := not HTMLEditor.ReadOnly;
  cbParagraphStyle.Enabled := LEditable;
  btnToggleBold.Enabled := LEditable;
  btnToggleItalic.Enabled := LEditable;
  btnToggleUnderline.Enabled := LEditable;
  btnToggleStrikeOut.Enabled := LEditable;
  btnSuperscript.Enabled := LEditable;
  btnSubscript.Enabled := LEditable;
  btnToggleUnorderedList.Enabled := LEditable;
  btnToggleOrderedList.Enabled := LEditable;
  btnClearFormatting.Enabled := LEditable;
  btnIndent.Enabled := LEditable;
  btnOutdent.Enabled := LEditable and HTMLEditor.State.CanOutdent;
  btnAlignLeft.Enabled := LEditable;
  btnAlignCenter.Enabled := LEditable;
  btnAlignRight.Enabled := LEditable;
  btnAlignJustify.Enabled := LEditable;
  btnFontColor.Enabled := LEditable;
  btnBackgroundColor.Enabled := LEditable;
  btnDecreaseFontSize.Enabled := LEditable;
  btnIncreaseFontSize.Enabled := LEditable;
  btnTable.Enabled := LEditable;
  btnImage.Enabled := LEditable;
  btnInsertEmoji.Enabled := LEditable;
  btnInsertPlaceholder.Enabled := LEditable;
end;

procedure TfrmMain.UpdateStatusBar;
var
  LRun: TS4YHTMLRun;
  LText: string;
begin
  LRun := HTMLEditor.CurrentRun;
  LText := EmptyStr;

  if Assigned(LRun) then
  begin
    if LRun.IsImage then
      LText := LRun.ImageSource
    else if LRun.IsPlaceholder then
      LText := LRun.DisplayText
  end;

  lblStatusbarText.Text := LText;
  lblStatusBarCount.Text := Format('Words: %d, Chars: %d', [HTMLEditor.WordCount, HTMLEditor.CharCount]);
  lblStatusBarPosition.Text := Format('Line: %d, Col: %d', [HTMLEditor.State.LineNumber, HTMLEDitor.State.ColumnNumber]);
end;

end.
