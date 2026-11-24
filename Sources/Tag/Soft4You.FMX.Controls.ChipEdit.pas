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
  System.Types,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Edit,
  FMX.Objects,
  Soft4You.FMX.Controls.Tag.Types,
  Soft4You.FMX.Controls.Chip,
  Soft4You.FMX.Controls.ChipBox;

type
  TS4YChipEdit = class;

  /// <summary>The box of chips inside TS4YChipEdit: its chips can be closed and the text field follows them.</summary>
  TS4YChipEditBox = class(TS4YCustomChipBox)
  private
    FEditor: TS4YChipEdit;
  protected
    procedure ChipEntered(const AChip: TS4YChip); override;
    procedure ChipExited(const AChip: TS4YChip); override;
    procedure ConfigureChip(const AChip: TS4YChip; AIndex: Integer); override;
    function CreateChip: TS4YChip; override;
  public
    /// <summary>A click on the free space of the box takes the focus to the text field.</summary>
    procedure Click; override;
    /// <summary>Scrolls the text field into view.</summary>
    procedure ScrollToEdit;

    property AutoSize;
    property FillControl;
    property FillMinWidth;
    property HorizontalGap;
    property Items;
    property Kind;
    property MaxHeight;
    property OnResized;
    property Shape;
    property SizePreset;
    property Variant;
    property VerticalGap;
  end;

  /// <summary>
  /// Text field where the user types entries that become chips, as the recipients of an email: the chips and the text field share the lines, which wrap at the width of the control.
  /// </summary>
  /// <remarks>
  /// Enter, a character of Separators (a comma and a semicolon at first), the loss of the focus and a paste with separators in it turn the text into chips; a text that is only spaces gives no chip.
  /// Backspace with the field empty removes the last chip; the left arrow with the cursor at the start of the field, and the arrow keys among the chips, move the focus to the chips, where Backspace and Delete remove the chip and the close button of each chip does the same.
  /// Items holds the texts of the chips in order. Changing it from the code changes the chips but fires no event: OnAdd and OnRemove tell what the user does and what AddItem and RemoveItem do.
  /// OnValidate is called before a text becomes a chip: it can refuse the text, which stays in the field, or accept it with a Kind, for example tgkDanger for an email address that is not valid; the Kind is kept with the chip.
  /// AllowDuplicates False, the default, drops a text that is already an item, without case; MaxItems limits the chips.
  /// With AutoSize True, the default, the height follows the lines up to MaxHeight and a longer content scrolls, with the wheel and with the finger.
  /// The look of the frame comes from the style S4YChipEditStyle (the parts background, and the colors bordercolor and focusbordercolor); the chips are the ones of TS4YChip.
  /// </remarks>
  TS4YChipEdit = class(TStyledControl)
  public const
    /// <summary>Default value of Separators.</summary>
    C_DEFAULT_SEPARATORS = ',;';
  private
    FAllowDuplicates: Boolean;
    FAutoSize: Boolean;
    FBorderColor: TAlphaColor;
    FBox: TS4YChipEditBox;
    FEdit: TEdit;
    FEditFocused: Boolean;
    FFocusBorderColor: TAlphaColor;
    FFocusedChips: Integer;
    FMaxItems: Integer;
    FResizing: Boolean;
    FSeparators: string;
    FSplitting: Boolean;
    FStyleBackground: TRectangle;
    FOnAdd: TS4YChipItemEvent;
    FOnRemove: TS4YChipItemEvent;
    FOnValidate: TS4YChipValidateEvent;
    procedure BoxResized(Sender: TObject);
    procedure ChipClose(Sender: TObject; var CanClose: Boolean);
    procedure EditChangeTracking(Sender: TObject);
    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    function GetEditText: string;
    function GetHorizontalGap: Single;
    function GetItems: TStrings;
    function GetKind: TS4YTagKind;
    function GetMaxHeight: Single;
    function GetShape: TS4YTagShape;
    function GetSizePreset: TS4YTagSizePreset;
    function GetTextPrompt: string;
    function GetVariant: TS4YTagVariant;
    function GetVerticalGap: Single;
    function IsGapStored(const AGap: Single): Boolean;
    function IsHorizontalGapStored: Boolean;
    function IsMaxHeightStored: Boolean;
    function IsSeparator(const AChar: Char): Boolean;
    function IsSeparatorsStored: Boolean;
    function IsVerticalGapStored: Boolean;
    procedure SetAutoSize(const Value: Boolean);
    procedure SetEditText(const Value: string);
    procedure SetHorizontalGap(const Value: Single);
    procedure SetItems(const Value: TStrings);
    procedure SetKind(const Value: TS4YTagKind);
    procedure SetMaxHeight(const Value: Single);
    procedure SetShape(const Value: TS4YTagShape);
    procedure SetSizePreset(const Value: TS4YTagSizePreset);
    procedure SetTextPrompt(const Value: string);
    procedure SetVariant(const Value: TS4YTagVariant);
    procedure SetVerticalGap(const Value: Single);
    procedure UpdateBorder;
    procedure UpdateEditMetrics;
    procedure UpdateHeight;
  protected
    /// <summary>Takes the parts of the style: the background and the colors of the border.</summary>
    procedure ApplyStyle; override;
    /// <summary>Lets go of the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>The control starts as wide as 320 pixels and as high as a line of chips with its frame.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns the style S4YChipEditStyle of the style book or of the active style or, when it is not found, the one linked into the package.</summary>
    function GetStyleObject: TFmxObject; override;
    /// <summary>Called by the box when the focus enters or leaves a chip or the text field: draws the border of the focus.</summary>
    procedure FocusChanged(const ADelta: Integer; AEditChanged: Boolean; AEditFocused: Boolean);
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
    /// <summary>When True, the default, the height follows the lines of chips up to MaxHeight.</summary>
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;
    property Enabled;
    property Height;
    /// <summary>Space between two chips on a line, in pixels. The default is 8.</summary>
    property HorizontalGap: Single read GetHorizontalGap write SetHorizontalGap stored IsHorizontalGapStored nodefault;
    /// <summary>The texts of the chips, in order.</summary>
    property Items: TStrings read GetItems write SetItems;
    /// <summary>Meaning of the chips, which gives them their color; OnValidate can give another to a chip. The default is tgkNeutral.</summary>
    property Kind: TS4YTagKind read GetKind write SetKind default tgkNeutral;
    property Margins;
    /// <summary>Largest height of the control in pixels when AutoSize is True: a longer content scrolls. The default, 0, means no limit.</summary>
    property MaxHeight: Single read GetMaxHeight write SetMaxHeight stored IsMaxHeightStored nodefault;
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
    /// <summary>Shape of the chips. The default is tgsPill.</summary>
    property Shape: TS4YTagShape read GetShape write SetShape default tgsPill;
    property Size;
    /// <summary>Size of the chips. The default is tgzMedium, tgzLarge on Android and iOS.</summary>
    property SizePreset: TS4YTagSizePreset read GetSizePreset write SetSizePreset default TS4YCustomChipBox.C_DEFAULT_SIZE_PRESET;
    property StyleLookup;
    /// <summary>The text shown in the text field while it is empty.</summary>
    property TextPrompt: string read GetTextPrompt write SetTextPrompt;
    /// <summary>How the color fills the chips: filled, tonal or outlined. The default is tgvTonal.</summary>
    property Variant: TS4YTagVariant read GetVariant write SetVariant default tgvTonal;
    /// <summary>Space between two lines of chips, in pixels. The default is 8.</summary>
    property VerticalGap: Single read GetVerticalGap write SetVerticalGap stored IsVerticalGapStored nodefault;
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
  FMX.Graphics,
  FMX.Styles;

{$IF DEFINED(IOS)}
{$R *.ios.res}
{$ELSEIF DEFINED(MACOS)}
{$R *.mac.res}
{$ELSEIF DEFINED(ANDROID)}
{$R *.android.res}
{$ELSEIF DEFINED(MSWINDOWS)}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_BACKGROUND = 'background';
  C_STYLE_BORDER_COLOR = 'bordercolor';
  C_STYLE_FOCUS_BORDER_COLOR = 'focusbordercolor';
  // Colors used when the style does not give them
  C_FALLBACK_BORDER_COLOR = $FF8A8886;
  C_FALLBACK_FOCUS_BORDER_COLOR = $FF0078D4;
  // Space between the frame and the chips
  C_INNER_MARGIN_HORIZONTAL = 8;
  C_INNER_MARGIN_VERTICAL = 4;
  // The text field takes the rest of the line, never less than this
  C_EDIT_MIN_WIDTH = 100;
  C_BORDER_THICKNESS = 1;
  C_FOCUS_BORDER_THICKNESS = 2;

{ TS4YChipEditBox }

procedure TS4YChipEditBox.ChipEntered(const AChip: TS4YChip);
begin
  inherited;

  FEditor.FocusChanged(1, False, False);
end;

procedure TS4YChipEditBox.ChipExited(const AChip: TS4YChip);
begin
  inherited;

  FEditor.FocusChanged(-1, False, False);
end;

procedure TS4YChipEditBox.Click;
begin
  inherited;

  FEditor.FocusEdit;
end;

procedure TS4YChipEditBox.ScrollToEdit;
begin
  if Assigned(FillControl) then
    ScrollInView(FillControl);
end;

procedure TS4YChipEditBox.ConfigureChip(const AChip: TS4YChip; AIndex: Integer);
begin
  inherited;

  AChip.Closable := True;

  // The kind that OnValidate gave to the text is kept with it in Items.Objects, as the kind plus one
  if Assigned(Items.Objects[AIndex]) then
    AChip.Kind := TS4YTagKind(NativeInt(Items.Objects[AIndex]) - 1);
end;

function TS4YChipEditBox.CreateChip: TS4YChip;
begin
  Result := inherited;
  Result.OnClose := FEditor.ChipClose;
end;

{ TS4YChipEdit }

constructor TS4YChipEdit.Create(AOwner: TComponent);
begin
  inherited;

  FAutoSize := True;
  FSeparators := C_DEFAULT_SEPARATORS;
  CanFocus := False;

  FBox := TS4YChipEditBox.Create(Self);
  FBox.FEditor := Self;
  FBox.Stored := False;
  FBox.Locked := True;
  FBox.Variant := tgvTonal;
  FBox.Margins.Rect := TRectF.Create(C_INNER_MARGIN_HORIZONTAL, C_INNER_MARGIN_VERTICAL, C_INNER_MARGIN_HORIZONTAL,
    C_INNER_MARGIN_VERTICAL);
  FBox.Align := TAlignLayout.Top;
  FBox.OnResized := BoxResized;
  FBox.FillMinWidth := C_EDIT_MIN_WIDTH;
  FBox.Parent := Self;

  FEdit := TEdit.Create(Self);
  FEdit.Stored := False;
  FEdit.Locked := True;
  // The style that has no frame and no background, so that the text field looks part of the control
  FEdit.StyleLookup := 'transparentedit';
  FEdit.OnChangeTracking := EditChangeTracking;
  FEdit.OnEnter := EditEnter;
  FEdit.OnExit := EditExit;
  FEdit.OnKeyDown := EditKeyDown;
  FEdit.Parent := FBox;
  FBox.FillControl := FEdit;
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

  if (FMaxItems > 0) and (FBox.Items.Count >= FMaxItems) then
    Exit(False);

  if not FAllowDuplicates and (FBox.Items.IndexOf(LText) >= 0) then
    Exit(True);

  LAccept := True;
  LKind := FBox.Kind;

  if Assigned(FOnValidate) then
    FOnValidate(Self, LText, LAccept, LKind);

  if not LAccept then
    Exit(False);

  // The kind goes with the text, as the kind plus one (nil means the kind of the control)
  LIndex := FBox.Items.AddObject(LText, TObject(NativeInt(Ord(LKind) + 1)));

  if Assigned(FOnAdd) then
    FOnAdd(Self, LText, LIndex);

  Result := True;
end;

procedure TS4YChipEdit.ApplyStyle;
var
  LColorObject: TColorObject;
begin
  inherited;

  FindStyleResource<TRectangle>(C_STYLE_BACKGROUND, FStyleBackground);

  if FindStyleResource<TColorObject>(C_STYLE_BORDER_COLOR, LColorObject) then
    FBorderColor := LColorObject.Color
  else
    FBorderColor := C_FALLBACK_BORDER_COLOR;

  if FindStyleResource<TColorObject>(C_STYLE_FOCUS_BORDER_COLOR, LColorObject) then
    FFocusBorderColor := LColorObject.Color
  else
    FFocusBorderColor := C_FALLBACK_FOCUS_BORDER_COLOR;

  UpdateBorder;
end;

procedure TS4YChipEdit.BoxResized(Sender: TObject);
begin
  UpdateHeight;
end;

procedure TS4YChipEdit.ChipClose(Sender: TObject; var CanClose: Boolean);
var
  LIndex: Integer;
begin
  // The chip is not hidden by itself: it is removed from Items, which frees it
  CanClose := False;
  LIndex := FBox.Chips.IndexOf(TS4YChip(Sender));

  if LIndex >= 0 then
  begin
    RemoveItem(LIndex);
    FocusEdit;
  end;
end;

function TS4YChipEdit.CommitText: Boolean;
begin
  // A text that is refused stays in the field
  Result := AddItem(FEdit.Text);

  if Result then
    FEdit.Text := '';
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
  FocusChanged(0, True, True);
  FBox.ScrollToEdit;
end;

procedure TS4YChipEdit.EditExit(Sender: TObject);
begin
  FocusChanged(0, True, False);
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
  else if (Key = vkBack) and (FEdit.Text = '') and (FBox.Chips.Count > 0) then
  begin
    RemoveItem(FBox.Chips.Count - 1);
    Key := 0;
    KeyChar := #0;
  end
  else if (Key = vkLeft) and (FEdit.CaretPosition = 0) and (FEdit.SelLength = 0) and (FBox.Chips.Count > 0) then
  begin
    FBox.Chips[FBox.Chips.Count - 1].SetFocus;
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

procedure TS4YChipEdit.FocusChanged(const ADelta: Integer; AEditChanged: Boolean; AEditFocused: Boolean);
begin
  FFocusedChips := Max(0, FFocusedChips + ADelta);

  if AEditChanged then
    FEditFocused := AEditFocused;

  UpdateBorder;
end;

procedure TS4YChipEdit.FocusEdit;
begin
  if Assigned(FEdit) and FEdit.Visible and FEdit.Enabled and not (csDesigning in ComponentState) then
    FEdit.SetFocus;
end;

procedure TS4YChipEdit.FreeStyle;
begin
  FStyleBackground := nil;

  inherited;
end;

function TS4YChipEdit.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(320, C_TAG_PRESET_HEIGHTS[tgzMedium] + 2 * C_INNER_MARGIN_VERTICAL);
end;

function TS4YChipEdit.GetEditText: string;
begin
  Result := FEdit.Text;
end;

function TS4YChipEdit.GetHorizontalGap: Single;
begin
  Result := FBox.HorizontalGap;
end;

function TS4YChipEdit.GetItems: TStrings;
begin
  Result := FBox.Items;
end;

function TS4YChipEdit.GetKind: TS4YTagKind;
begin
  Result := FBox.Kind;
end;

function TS4YChipEdit.GetMaxHeight: Single;
begin
  // The box counts its own height, the space of the frame around it is added
  if FBox.MaxHeight > 0 then
    Result := FBox.MaxHeight + FBox.Margins.Top + FBox.Margins.Bottom
  else
    Result := 0;
end;

function TS4YChipEdit.GetShape: TS4YTagShape;
begin
  Result := FBox.Shape;
end;

function TS4YChipEdit.GetSizePreset: TS4YTagSizePreset;
begin
  Result := FBox.SizePreset;
end;

function TS4YChipEdit.GetStyleObject: TFmxObject;
begin
  Result := LookupStyleObject(Self, GetStyleContext, Scene, StyleLookup, GetDefaultStyleLookupName, '', True);

  // The style linked into the package is used when no other style is found.
  if not Assigned(Result) then
    Result := TStyleStreaming.LoadFromResource(HInstance, GetDefaultStyleLookupName, RT_RCDATA);
end;

function TS4YChipEdit.GetTextPrompt: string;
begin
  Result := FEdit.TextPrompt;
end;

function TS4YChipEdit.GetVariant: TS4YTagVariant;
begin
  Result := FBox.Variant;
end;

function TS4YChipEdit.GetVerticalGap: Single;
begin
  Result := FBox.VerticalGap;
end;

function TS4YChipEdit.IsGapStored(const AGap: Single): Boolean;
begin
  Result := not SameValue(AGap, TS4YCustomChipBox.C_DEFAULT_GAP);
end;

function TS4YChipEdit.IsHorizontalGapStored: Boolean;
begin
  Result := IsGapStored(FBox.HorizontalGap);
end;

function TS4YChipEdit.IsMaxHeightStored: Boolean;
begin
  Result := FBox.MaxHeight <> 0;
end;

function TS4YChipEdit.IsSeparator(const AChar: Char): Boolean;
begin
  Result := Pos(AChar, FSeparators) > 0;
end;

function TS4YChipEdit.IsSeparatorsStored: Boolean;
begin
  Result := FSeparators <> C_DEFAULT_SEPARATORS;
end;

function TS4YChipEdit.IsVerticalGapStored: Boolean;
begin
  Result := IsGapStored(FBox.VerticalGap);
end;

procedure TS4YChipEdit.RemoveItem(Index: Integer);
var
  LText: string;
begin
  if (Index < 0) or (Index >= FBox.Items.Count) then
    Exit;

  LText := FBox.Items[Index];
  FBox.Items.Delete(Index);

  if Assigned(FOnRemove) then
    FOnRemove(Self, LText, Index);
end;

procedure TS4YChipEdit.SetAutoSize(const Value: Boolean);
begin
  if FAutoSize = Value then
    Exit;

  FAutoSize := Value;
  FBox.AutoSize := Value;

  if FAutoSize then
    FBox.Align := TAlignLayout.Top
  else
    FBox.Align := TAlignLayout.Client;

  UpdateHeight;
end;

procedure TS4YChipEdit.SetEditText(const Value: string);
begin
  FEdit.Text := Value;
end;

procedure TS4YChipEdit.SetHorizontalGap(const Value: Single);
begin
  FBox.HorizontalGap := Value;
end;

procedure TS4YChipEdit.SetItems(const Value: TStrings);
begin
  FBox.Items.Assign(Value);
end;

procedure TS4YChipEdit.SetKind(const Value: TS4YTagKind);
begin
  FBox.Kind := Value;
end;

procedure TS4YChipEdit.SetMaxHeight(const Value: Single);
begin
  if Value > 0 then
    FBox.MaxHeight := Max(1, Value - FBox.Margins.Top - FBox.Margins.Bottom)
  else
    FBox.MaxHeight := 0;
end;

procedure TS4YChipEdit.SetShape(const Value: TS4YTagShape);
begin
  FBox.Shape := Value;
end;

procedure TS4YChipEdit.SetSizePreset(const Value: TS4YTagSizePreset);
begin
  FBox.SizePreset := Value;
  UpdateEditMetrics;
  UpdateHeight;
end;

procedure TS4YChipEdit.SetTextPrompt(const Value: string);
begin
  FEdit.TextPrompt := Value;
end;

procedure TS4YChipEdit.SetVariant(const Value: TS4YTagVariant);
begin
  FBox.Variant := Value;
end;

procedure TS4YChipEdit.SetVerticalGap(const Value: Single);
begin
  FBox.VerticalGap := Value;
end;

procedure TS4YChipEdit.UpdateBorder;
begin
  if not Assigned(FStyleBackground) then
    Exit;

  FStyleBackground.Stroke.Kind := TBrushKind.Solid;

  if FEditFocused or (FFocusedChips > 0) then
  begin
    FStyleBackground.Stroke.Color := FFocusBorderColor;
    FStyleBackground.Stroke.Thickness := C_FOCUS_BORDER_THICKNESS;
  end
  else
  begin
    FStyleBackground.Stroke.Color := FBorderColor;
    FStyleBackground.Stroke.Thickness := C_BORDER_THICKNESS;
  end;
end;

procedure TS4YChipEdit.UpdateEditMetrics;
begin
  // The text field is as high as a chip and has its font size
  FEdit.Height := C_TAG_PRESET_HEIGHTS[FBox.SizePreset];
  FEdit.StyledSettings := FEdit.StyledSettings - [TStyledSetting.Size];
  FEdit.TextSettings.Font.Size := C_TAG_PRESET_FONT_SIZES[FBox.SizePreset];
end;

procedure TS4YChipEdit.UpdateHeight;
var
  LHeight: Single;
begin
  if FResizing or not FAutoSize or not Assigned(FBox) then
    Exit;

  FResizing := True;
  try
    LHeight := FBox.Height + FBox.Margins.Top + FBox.Margins.Bottom;

    if not SameValue(Height, LHeight, 0.01) then
      SetBounds(Position.X, Position.Y, Width, LHeight);
  finally
    FResizing := False;
  end;
end;

end.
