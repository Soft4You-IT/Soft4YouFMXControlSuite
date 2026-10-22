unit MainFrm;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Messaging,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Platform,
  FMX.VirtualKeyboard,
  Soft4You.FMX.Controls.HTMLEditor, FMX.Controls.Presentation;

type
  /// <summary>
  /// Test application for the HTML editor on mobile platforms: the editor fills the screen and a status line shows
  /// what the platform delivers to it (keys, virtual keyboard).
  /// </summary>
  TfrmMain = class(TForm)
    layButtons: TFlowLayout;
    btnBold: TButton;
    btnItalic: TButton;
    btnBullets: TButton;
    btnTable: TButton;
    btnShowKeyboard: TButton;
    btnHideKeyboard: TButton;
    lblStatus: TLabel;
    HTMLEditor: TS4YHTMLEditor;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FKeyboardVisible: Boolean;
    FKeyboardMessageId: Integer;
    FLastKey: string;
    HTMLEditorTapCount: Integer;

    procedure BoldButtonClick(Sender: TObject);
    procedure BulletsButtonClick(Sender: TObject);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EditorKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EditorTap(Sender: TObject);
    procedure HideKeyboardButtonClick(Sender: TObject);
    procedure ItalicButtonClick(Sender: TObject);
    procedure LoadTestDocument;
    procedure ShowKeyboardButtonClick(Sender: TObject);
    procedure TableButtonClick(Sender: TObject);
    procedure UpdateStatus;
    procedure VirtualKeyboardChanged(const Sender: TObject; const AMessage: TMessage);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}
{$R *.Moto360.fmx ANDROID}
{$R *.XLgXhdpiTb.fmx ANDROID}

const
  C_TEST_DOCUMENT =
    '<h2>Mobile test</h2>' +
    '<p>Tap here and type: <b>bold</b>, <i>italic</i>, <u>underline</u>.</p>' +
    '<ul><li>First item</li><li>Second item</li></ul>' +
    '<table border="1" cellpadding="6"><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>' +
    '<p>End of the document.</p>';

procedure TfrmMain.BoldButtonClick(Sender: TObject);
begin
  HTMLEditor.ToggleBold;
end;

procedure TfrmMain.BulletsButtonClick(Sender: TObject);
begin
  HTMLEditor.ToggleUnorderedList;
end;

procedure TfrmMain.EditorKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  FLastKey := Format('KeyDown Key=%d Char=%d', [Key, Ord(KeyChar)]);
  UpdateStatus;
end;

procedure TfrmMain.EditorKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  FLastKey := Format('KeyUp Key=%d Char=%d', [Key, Ord(KeyChar)]);
  UpdateStatus;
end;

procedure TfrmMain.EditorTap(Sender: TObject);
begin
  Inc(HTMLEditorTapCount);
  UpdateStatus;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  HTMLEditor.OnKeyDown := EditorKeyDown;
  HTMLEditor.OnKeyUp := EditorKeyUp;
  HTMLEditor.SetFocus;
  FKeyboardMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TVKStateChangeMessage, VirtualKeyboardChanged);
  LoadTestDocument;
  UpdateStatus;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  TMessageManager.DefaultManager.Unsubscribe(TVKStateChangeMessage, FKeyboardMessageId);
end;

procedure TfrmMain.HideKeyboardButtonClick(Sender: TObject);
var
  LService: IFMXVirtualKeyboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, LService) then
  begin
    LService.HideVirtualKeyboard;
  end;
end;

procedure TfrmMain.ItalicButtonClick(Sender: TObject);
begin
  HTMLEditor.ToggleItalic;
end;

procedure TfrmMain.LoadTestDocument;
begin
  HTMLEditor.HTML := C_TEST_DOCUMENT;
end;

// Explicit request to the platform, to tell apart "the editor does not ask for the keyboard" from "the keyboard
// does not work at all". The editor is the control the keyboard is attached to.
procedure TfrmMain.ShowKeyboardButtonClick(Sender: TObject);
var
  LService: IFMXVirtualKeyboardService;
begin
  HTMLEditor.SetFocus;
  if TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, LService) then
  begin
    LService.ShowVirtualKeyboard(HTMLEditor);
  end
  else
  begin
    FLastKey := 'No virtual keyboard service on this platform';
    UpdateStatus;
  end;
end;

procedure TfrmMain.TableButtonClick(Sender: TObject);
begin
  HTMLEditor.InsertTable;
end;

procedure TfrmMain.UpdateStatus;
const
  C_KEYBOARD_TEXT: array[Boolean] of string = ('hidden', 'visible');
begin
  lblStatus.Text := Format('Keyboard: %s | Taps: %d | %s',
    [C_KEYBOARD_TEXT[FKeyboardVisible], HTMLEditorTapCount, FLastKey]);
end;

procedure TfrmMain.VirtualKeyboardChanged(const Sender: TObject; const AMessage: TMessage);
begin
  FKeyboardVisible := TVKStateChangeMessage(AMessage).KeyboardVisible;
  UpdateStatus;
end;

end.
