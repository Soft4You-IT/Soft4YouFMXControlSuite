unit Soft4You.FMX.Controls.ChipEdit;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YChipEdit - text field where each entry becomes a chip, as the recipients of an email
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Edit,
  Soft4You.FMX.Controls.Tag.Types,
  Soft4You.FMX.Controls.Chip,
  Soft4You.FMX.Controls.ChipHost;

type
  /// <summary>
  /// Text field where the user types entries that become chips, as the recipients of an email: the chips and the text field share the lines, which wrap at the width of the control.
  /// </summary>
  /// <remarks>
  /// Enter, a character of Separators (a comma and a semicolon at first), the loss of the focus and a paste with separators in it turn the text into chips; a text that is only spaces gives no chip.
  /// Tab goes through the text field only, not through the chips. Backspace with the field empty removes the last chip; the left arrow with the cursor at the start of the field, and the arrow keys among the chips, move the focus to the chips, where Backspace and Delete remove the chip and the close button of each chip does the same.
  /// Items holds the texts of the chips in order. Changing it from the code changes the chips but fires no event: OnAdd and OnRemove tell what the user does and what AddItem and RemoveItem do.
  /// OnValidate is called before a text becomes a chip: it can refuse the text, which stays in the field, or accept it with a Kind, for example tgkDanger for an email address that is not valid; the Kind is kept with the chip.
  /// AllowDuplicates False, the default, drops a text that is already an item, without case; MaxItems limits the chips.
  /// With AutoSize True, the default, the height follows the lines up to MaxHeight and a longer content scrolls, with the wheel and with the finger.
  /// The look comes from the style S4YChipEditStyle: the frame (the part background and the colors bordercolor and focusbordercolor), the space inside it (the margins of the part content) and the chips, which take the look of the part chip, a TS4YChip of the style: change it to change the size, the font, the padding, the shape and the variant of the chips. The text field takes its font from the part edit, a TEdit of the style that is hidden: its TextSettings and StyledSettings and its StyleLookup. Without that part the text field uses the style transparentedit of the active style, with the font size of the chips.
  /// </remarks>
  TS4YChipEdit = class(TS4YCustomChipHost)
  public const
    /// <summary>Default value of Separators.</summary>
    C_DEFAULT_SEPARATORS = ',;';
  private
    FAllowDuplicates: Boolean;
    FBorderColor: TAlphaColor;
    FEdit: TEdit;
    FEditFocused: Boolean;
    FFocusBorderColor: TAlphaColor;
    FFocusedChips: Integer;
    FHasEditModel: Boolean;
    FMaxItems: Integer;
    FSeparators: string;
    FSplitting: Boolean;
    FOnAdd: TS4YChipItemEvent;
    FOnRemove: TS4YChipItemEvent;
    FOnValidate: TS4YChipValidateEvent;
    procedure ChipClose(Sender: TObject; var CanClose: Boolean);
    procedure EditChangeTracking(Sender: TObject);
    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure EditStyleApplied(Sender: TObject);
    function GetEditText: string;
    function GetTextPrompt: string;
    function IsSeparator(const AChar: Char): Boolean;
    function IsSeparatorsStored: Boolean;
    procedure SetEditText(const Value: string);
    procedure SetTextPrompt(const Value: string);
    procedure UpdateBorder;
    procedure UpdateEditMetrics;
  protected
    /// <summary>Called when a click reaches the free space of the box: the text field takes the focus.</summary>
    procedure BoxClicked; override;
    /// <summary>Counts the chips that have the focus, to draw the border of the focus.</summary>
    procedure ChipFocusChanged(const ADelta: Integer); override;
    /// <summary>Gives the new chip the event that removes it.</summary>
    procedure ChipCreated(const AChip: TS4YChip); override;
    /// <summary>The text field is as high as the chips and has their font.</summary>
    procedure ChipsSynced; override;
    /// <summary>Gives the chip the close button, no tab stop and the kind that OnValidate gave to its text.</summary>
    procedure ConfigureChip(const AChip: TS4YChip; AIndex: Integer); override;
    /// <summary>Takes the colors of the border from the style.</summary>
    procedure StyleApplied; override;
  public
    /// <summary>Creates the control with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Turns a text into a chip, as the user does with Enter: the spaces around it are dropped, OnValidate is called and OnAdd fires. Returns False when the text is refused, True when it becomes a chip or is dropped (empty, or a duplicate).</summary>
    function AddItem(const AText: string): Boolean;
    /// <summary>Turns the text of the field into a chip. Returns True when the field has no text left.</summary>
    function CommitText: Boolean;
    /// <summary>Removes the chip at the position Index and fires OnRemove.</summary>
    procedure RemoveItem(Index: Integer);
    /// <summary>Gives the focus to the text field.</summary>
    procedure FocusEdit;

    /// <summary>The text that the user is typing, not yet a chip. Setting it works as typing or pasting the text: the separators in it make chips.</summary>
    property EditText: string read GetEditText write SetEditText;
  published
    /// <summary>When False a text that is already an item is dropped, without case. The default is False.</summary>
    property AllowDuplicates: Boolean read FAllowDuplicates write FAllowDuplicates default False;
    property Align;
    property Anchors;
    property AutoSize;
    property Enabled;
    property Height;
    property HorizontalGap;
    property Items;
    property Kind;
    property Margins;
    property MaxHeight;
    /// <summary>The most chips the control holds; a text that would be one more stays in the field. The default, 0, means no limit.</summary>
    property MaxItems: Integer read FMaxItems write FMaxItems default 0;
    property Opacity;
    property Padding;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    /// <summary>The characters that turn the text into a chip, besides Enter. The default is a comma and a semicolon.</summary>
    property Separators: string read FSeparators write FSeparators stored IsSeparatorsStored;
    property Size;
    property StyleLookup;
    /// <summary>The text shown in the text field while it is empty.</summary>
    property TextPrompt: string read GetTextPrompt write SetTextPrompt;
    property VerticalGap;
    property Visible;
    property Width;

    /// <summary>Fires after a chip is added by the user, by AddItem or by CommitText.</summary>
    property OnAdd: TS4YChipItemEvent read FOnAdd write FOnAdd;
    /// <summary>Fires after a chip is removed by the user or by RemoveItem.</summary>
    property OnRemove: TS4YChipItemEvent read FOnRemove write FOnRemove;
    /// <summary>Fires before a text becomes a chip, to refuse it or to give it a Kind.</summary>
    property OnValidate: TS4YChipValidateEvent read FOnValidate write FOnValidate;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  FMX.Graphics;

{$IF DEFINED(IOS)}
{$R *.ios.res}
{$ELSEIF DEFINED(MACOS)}
{$R *.mac.res}
{$ELSEIF DEFINED(ANDROID)}
{$R *.android.res}
{$ELSEIF DEFINED(MSWINDOWS)}
{$R *.win.res}
{$ENDIF}

type
  // Gives access to the protected search of the parts of the style
  TEditAccess = class(TEdit);

const
  C_STYLE_BACKGROUND = 'background';
  C_STYLE_BORDER_COLOR = 'bordercolor';
  C_STYLE_EDIT = 'edit';
  C_STYLE_FOCUS_BORDER_COLOR = 'focusbordercolor';
  // Colors used when the style does not give them
  C_FALLBACK_BORDER_COLOR = $FF8A8886;
  C_FALLBACK_FOCUS_BORDER_COLOR = $FF0078D4;
  // The style of the text field when the style of the control has no part edit that gives another
  C_EDIT_STYLE_LOOKUP = 'transparentedit';
  // The text field takes the rest of the line, never less than this
  C_EDIT_MIN_WIDTH = 100;
  C_BORDER_THICKNESS = 1;
  C_FOCUS_BORDER_THICKNESS = 2;

{ TS4YChipEdit }

constructor TS4YChipEdit.Create(AOwner: TComponent);
begin
  inherited;

  FSeparators := C_DEFAULT_SEPARATORS;
  FBorderColor := C_FALLBACK_BORDER_COLOR;
  FFocusBorderColor := C_FALLBACK_FOCUS_BORDER_COLOR;
  // Until the style gives the chip that is the model of the chips
  Box.Variant := tgvTonal;
  Box.FillMinWidth := C_EDIT_MIN_WIDTH;

  FEdit := TEdit.Create(Self);
  FEdit.Stored := False;
  FEdit.Locked := True;
  // The style that has no frame and no background, so that the text field looks part of the control
  FEdit.StyleLookup := C_EDIT_STYLE_LOOKUP;
  FEdit.OnChangeTracking := EditChangeTracking;
  FEdit.OnEnter := EditEnter;
  FEdit.OnExit := EditExit;
  FEdit.OnKeyDown := EditKeyDown;
  FEdit.OnApplyStyleLookup := EditStyleApplied;
  FEdit.Parent := Box;
  Box.FillControl := FEdit;
  UpdateEditMetrics;
  UpdateHeight;
end;

function TS4YChipEdit.AddItem(const AText: string): Boolean;
var
  LAccept: Boolean;
  LIndex: Integer;
  LKind: TS4YTagKind;
  LText: string;
begin
  LText := Trim(AText);

  // Nothing to add, or a duplicate: dropped, the field has nothing to keep
  if LText = '' then
    Exit(True);

  if (FMaxItems > 0) and (Box.Items.Count >= FMaxItems) then
    Exit(False);

  if not FAllowDuplicates and (Box.Items.IndexOf(LText) >= 0) then
    Exit(True);

  LAccept := True;
  LKind := Box.Kind;

  if Assigned(FOnValidate) then
    FOnValidate(Self, LText, LAccept, LKind);

  if not LAccept then
    Exit(False);

  // The kind goes with the text, as the kind plus one (nil means the kind of the control)
  LIndex := Box.Items.AddObject(LText, TObject(NativeInt(Ord(LKind) + 1)));

  if Assigned(FOnAdd) then
    FOnAdd(Self, LText, LIndex);

  Result := True;
end;

procedure TS4YChipEdit.BoxClicked;
begin
  FocusEdit;
end;

procedure TS4YChipEdit.ChipClose(Sender: TObject; var CanClose: Boolean);
var
  LIndex: Integer;
begin
  // The chip is not hidden by itself: it is removed from Items, which frees it
  CanClose := False;
  LIndex := Box.Chips.IndexOf(TS4YChip(Sender));

  if LIndex >= 0 then
  begin
    RemoveItem(LIndex);
    FocusEdit;
  end;
end;

procedure TS4YChipEdit.ChipCreated(const AChip: TS4YChip);
begin
  AChip.OnClose := ChipClose;
end;

procedure TS4YChipEdit.ChipFocusChanged(const ADelta: Integer);
begin
  FFocusedChips := Max(0, FFocusedChips + ADelta);
  UpdateBorder;
end;

procedure TS4YChipEdit.ChipsSynced;
begin
  UpdateEditMetrics;
end;

function TS4YChipEdit.CommitText: Boolean;
begin
  // A text that is refused stays in the field
  Result := AddItem(FEdit.Text);

  if Result then
    FEdit.Text := '';
end;

procedure TS4YChipEdit.ConfigureChip(const AChip: TS4YChip; AIndex: Integer);
begin
  AChip.Closable := True;
  // Tab goes from the text field to the next control, not through every chip: the arrow keys reach the chips
  AChip.TabStop := False;

  // The kind that OnValidate gave to the text is kept with it in Items.Objects, as the kind plus one
  if Assigned(Box.Items.Objects[AIndex]) then
    AChip.Kind := TS4YTagKind(NativeInt(Box.Items.Objects[AIndex]) - 1);
end;

procedure TS4YChipEdit.EditChangeTracking(Sender: TObject);
var
  LIndex: Integer;
  LPart: string;
  LRest: string;
  LText: string;
begin
  // A separator in the text, typed on a keyboard that sends no key or pasted with other text, ends one or more chips
  if FSplitting or (FEdit.Text = '') then
    Exit;

  LText := FEdit.Text;
  LPart := '';
  FSplitting := True;
  try
    for LIndex := 1 to Length(LText) do
    begin
      if IsSeparator(LText[LIndex]) or CharInSet(LText[LIndex], [#13, #10, #9]) then
      begin
        if not AddItem(LPart) then
        begin
          // A refused text stays, with what follows it, in the field
          LRest := Copy(LText, LIndex - Length(LPart), MaxInt);
          FEdit.Text := LRest;
          Exit;
        end;

        LPart := '';
      end
      else
        LPart := LPart + LText[LIndex];
    end;

    if LPart <> LText then
      FEdit.Text := LPart;
  finally
    FSplitting := False;
  end;
end;

procedure TS4YChipEdit.EditEnter(Sender: TObject);
begin
  FEditFocused := True;
  UpdateBorder;
  Box.ScrollToControl(FEdit);
end;

procedure TS4YChipEdit.EditExit(Sender: TObject);
begin
  FEditFocused := False;
  UpdateBorder;
  CommitText;
end;

procedure TS4YChipEdit.EditKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if (Key = vkReturn) and (FEdit.Text <> '') then
  begin
    CommitText;
    Key := 0;
    KeyChar := #0;
  end
  else if (Key = vkBack) and (FEdit.Text = '') and (Box.Chips.Count > 0) then
  begin
    RemoveItem(Box.Chips.Count - 1);
    Key := 0;
    KeyChar := #0;
  end
  else if (Key = vkLeft) and (FEdit.CaretPosition = 0) and (FEdit.SelLength = 0) and (Box.Chips.Count > 0) then
  begin
    Box.Chips[Box.Chips.Count - 1].SetFocus;
    Key := 0;
    KeyChar := #0;
  end
  else if (KeyChar <> #0) and IsSeparator(KeyChar) then
  begin
    CommitText;
    Key := 0;
    KeyChar := #0;
  end;
end;

procedure TS4YChipEdit.EditStyleApplied(Sender: TObject);
var
  LBackground: TControl;
begin
  // The frame is the one of the control, which also shows the focus: the text field has neither a frame nor a focus
  // rectangle of its own, that would be drawn where the field was when it takes or loses the focus
  if TEditAccess(FEdit).FindStyleResource<TControl>(C_STYLE_BACKGROUND, LBackground) then
    LBackground.Visible := False;
end;

procedure TS4YChipEdit.FocusEdit;
begin
  if Assigned(FEdit) and FEdit.Visible and FEdit.Enabled and not (csDesigning in ComponentState) then
    FEdit.SetFocus;
end;

function TS4YChipEdit.GetEditText: string;
begin
  Result := FEdit.Text;
end;

function TS4YChipEdit.GetTextPrompt: string;
begin
  Result := FEdit.TextPrompt;
end;

function TS4YChipEdit.IsSeparator(const AChar: Char): Boolean;
begin
  Result := Pos(AChar, FSeparators) > 0;
end;

function TS4YChipEdit.IsSeparatorsStored: Boolean;
begin
  Result := FSeparators <> C_DEFAULT_SEPARATORS;
end;

procedure TS4YChipEdit.RemoveItem(Index: Integer);
var
  LText: string;
begin
  if (Index < 0) or (Index >= Box.Items.Count) then
    Exit;

  LText := Box.Items[Index];
  Box.Items.Delete(Index);

  if Assigned(FOnRemove) then
    FOnRemove(Self, LText, Index);
end;

procedure TS4YChipEdit.SetEditText(const Value: string);
begin
  FEdit.Text := Value;
end;

procedure TS4YChipEdit.SetTextPrompt(const Value: string);
begin
  FEdit.TextPrompt := Value;
end;

procedure TS4YChipEdit.StyleApplied;
var
  LColorObject: TColorObject;
  LEditModel: TEdit;
begin
  // The edit of the style is the model of the text field: it takes its font and its style
  if Assigned(FEdit) then
  begin
    FHasEditModel := FindStyleResource<TEdit>(C_STYLE_EDIT, LEditModel);

    if FHasEditModel then
    begin
      FEdit.TextSettings.Assign(LEditModel.TextSettings);
      FEdit.StyledSettings := LEditModel.StyledSettings;

      if LEditModel.StyleLookup <> '' then
        FEdit.StyleLookup := LEditModel.StyleLookup
      else
        FEdit.StyleLookup := C_EDIT_STYLE_LOOKUP;
    end
    else
      FEdit.StyleLookup := C_EDIT_STYLE_LOOKUP;
  end;

  if FindStyleResource<TColorObject>(C_STYLE_BORDER_COLOR, LColorObject) then
    FBorderColor := LColorObject.Color
  else
    FBorderColor := C_FALLBACK_BORDER_COLOR;

  if FindStyleResource<TColorObject>(C_STYLE_FOCUS_BORDER_COLOR, LColorObject) then
    FFocusBorderColor := LColorObject.Color
  else
    FFocusBorderColor := C_FALLBACK_FOCUS_BORDER_COLOR;

  UpdateBorder;
  UpdateEditMetrics;
end;

procedure TS4YChipEdit.UpdateBorder;
begin
  if not Assigned(StyleBackground) then
    Exit;

  StyleBackground.Stroke.Kind := TBrushKind.Solid;

  if FEditFocused or (FFocusedChips > 0) then
  begin
    StyleBackground.Stroke.Color := FFocusBorderColor;
    StyleBackground.Stroke.Thickness := C_FOCUS_BORDER_THICKNESS;
  end
  else
  begin
    StyleBackground.Stroke.Color := FBorderColor;
    StyleBackground.Stroke.Thickness := C_BORDER_THICKNESS;
  end;
end;

procedure TS4YChipEdit.UpdateEditMetrics;
begin
  // The box tells that its chips are made while the control is being created, before the text field exists
  if not Assigned(FEdit) then
    Exit;

  // The text field is as high as a chip
  FEdit.Height := Box.CurrentChipHeight;

  // Its font is the one of the model of the style, when there is one; without it, it has the font size of the chips
  if FHasEditModel then
    Exit;

  FEdit.StyledSettings := FEdit.StyledSettings - [TStyledSetting.Size];
  FEdit.TextSettings.Font.Size := Box.CurrentChipFontSize;
end;

end.
