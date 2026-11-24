unit Soft4You.FMX.Controls.Chip;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YChip - label that the user clicks, chooses or closes
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
  Soft4You.FMX.Controls.Tag.Types,
  Soft4You.FMX.Controls.Tag;

type
  /// <summary>
  /// An interactive label: the user clicks it, chooses it (alone or in a group) or closes it, as in a filter bar or a list of recipients.
  /// </summary>
  /// <remarks>
  /// It has everything a TS4YTag has, and reacts to the mouse (hover and press), to the finger and to the keyboard: it takes the focus, Space clicks it and Delete or Backspace close it when Closable is True.
  /// With Checkable True a click chooses and un-chooses it; chips with the same GroupName in the same parent are a group of which only one is chosen, as with radio buttons, and clicking the chosen one keeps it chosen.
  /// A chosen chip is drawn with a stronger variant (outlined becomes tonal, tonal becomes filled) and with a check mark in place of its icon, unless ShowCheckMark is False.
  /// The default Variant is tgvOutlined.
  /// The style is S4YChipStyle, with the same parts as S4YTagStyle.
  /// </remarks>
  TS4YChip = class(TS4YCustomTag)
  private
    FCheckable: Boolean;
    FChecked: Boolean;
    FGroupName: string;
    FShowCheckMark: Boolean;
    FOnCheckedChange: TNotifyEvent;
    procedure SetCheckable(const Value: Boolean);
    procedure SetChecked(const Value: Boolean);
    procedure SetGroupName(const Value: string);
    procedure SetShowCheckMark(const Value: Boolean);
    procedure UncheckOthers;
  protected
    /// <summary>Fires OnCheckedChange.</summary>
    procedure DoCheckedChange; virtual;
    /// <summary>Draws the focus border.</summary>
    procedure DoEnter; override;
    /// <summary>Takes the focus border away.</summary>
    procedure DoExit; override;
    /// <summary>Draws the state hover.</summary>
    procedure DoMouseEnter; override;
    /// <summary>Returns the variant that is drawn: the next stronger one when the chip is checked.</summary>
    function GetEffectiveVariant: TS4YTagVariant; override;
    /// <summary>Returns tgtPressed while the mouse button is down on the chip, tgtHover while the mouse is over it, else tgtNormal; on Android and iOS, which have no mouse, never tgtHover.</summary>
    function GetState: TS4YTagState; override;
    /// <summary>Returns True when the chip is checked and ShowCheckMark is True.</summary>
    function IsCheckMarkShown: Boolean; override;
    /// <summary>Returns True when the chip has the focus, on the desktop.</summary>
    function IsFocusBorderShown: Boolean; override;
  public
    /// <summary>Creates the chip with the default settings: it takes the focus and has the hand cursor.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Chooses or un-chooses the chip when it is Checkable, then fires OnClick.</summary>
    procedure Click; override;
    /// <summary>Space clicks the chip; Delete and Backspace close it when Closable is True.</summary>
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    /// <summary>Draws the state pressed.</summary>
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    /// <summary>Takes the state pressed away.</summary>
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
  published
    property Align;
    property Anchors;
    property AutoSize;
    property BackgroundColor;
    property Bitmap;
    property BorderColor;
    /// <summary>When True a click chooses and un-chooses the chip. The default is False.</summary>
    property Checkable: Boolean read FCheckable write SetCheckable default False;
    /// <summary>True when the chip is chosen. Choosing a chip that has a GroupName un-chooses the other chips of its group. The default is False.</summary>
    property Checked: Boolean read FChecked write SetChecked default False;
    property Closable;
    property CornerRadius;
    property Cursor default crHandPoint;
    property Enabled;
    /// <summary>Name of the group of the chip: the chips with the same name in the same parent are a group of which only one is checked. The default, empty, means no group.</summary>
    property GroupName: string read FGroupName write SetGroupName;
    property Height;
    property HitTest;
    property ImageIndex;
    property ImageRound;
    property Images;
    property Kind;
    property Margins;
    property MaxWidth;
    property Opacity;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Shape;
    /// <summary>When True, the default, a chosen chip shows a check mark in place of its icon or picture.</summary>
    property ShowCheckMark: Boolean read FShowCheckMark write SetShowCheckMark default True;
    property Size;
    property SizePreset;
    property StyleLookup;
    property TabOrder;
    property TabStop;
    property Text;
    property TextColor;
    property Variant default tgvOutlined;
    property Visible;
    property Width;

    /// <summary>Fires after Checked changes, whether by a click, by the keyboard, by the code or because another chip of the group was chosen.</summary>
    property OnCheckedChange: TNotifyEvent read FOnCheckedChange write FOnCheckedChange;
    property OnClick;
    property OnClose;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  System.SysUtils;

{$IF DEFINED(IOS)}
{$R *.ios.res}
{$ELSEIF DEFINED(MACOS)}
{$R *.mac.res}
{$ELSEIF DEFINED(ANDROID)}
{$R *.android.res}
{$ELSEIF DEFINED(MSWINDOWS)}
{$R *.win.res}
{$ENDIF}

function IsMobilePlatform: Boolean;
begin
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

constructor TS4YChip.Create(AOwner: TComponent);
begin
  inherited;

  FShowCheckMark := True;
  CanFocus := True;
  Cursor := crHandPoint;
  Variant := tgvOutlined;
end;

procedure TS4YChip.Click;
begin
  if FCheckable and not (csDesigning in ComponentState) then
  begin
    // A chip of a group stays chosen when it is clicked again, as a radio button does.
    if FGroupName = '' then
      SetChecked(not FChecked)
    else
      SetChecked(True);
  end;

  inherited;
end;

procedure TS4YChip.DoCheckedChange;
begin
  if Assigned(FOnCheckedChange) then
    FOnCheckedChange(Self);
end;

procedure TS4YChip.DoEnter;
begin
  inherited;

  UpdateParts;
end;

procedure TS4YChip.DoExit;
begin
  inherited;

  UpdateParts;
end;

procedure TS4YChip.DoMouseEnter;
begin
  inherited;

  UpdateParts;
end;

function TS4YChip.GetEffectiveVariant: TS4YTagVariant;
begin
  Result := Variant;

  if not FChecked then
    Exit;

  case Variant of
    tgvOutlined:
      Result := tgvTonal;
    tgvTonal:
      Result := tgvFilled;
  end;
end;

function TS4YChip.GetState: TS4YTagState;
begin
  if Pressed and IsMouseOver then
    Result := tgtPressed
  else if IsMouseOver and not IsMobilePlatform then
    Result := tgtHover
  else
    Result := tgtNormal;
end;

function TS4YChip.IsCheckMarkShown: Boolean;
begin
  Result := FChecked and FShowCheckMark;
end;

function TS4YChip.IsFocusBorderShown: Boolean;
begin
  Result := IsFocused and not IsMobilePlatform;
end;

procedure TS4YChip.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if (Key = vkSpace) or (KeyChar = ' ') then
  begin
    Click;
    Key := 0;
    KeyChar := #0;
  end
  else if Closable and ((Key = vkDelete) or (Key = vkBack)) then
  begin
    DoClose;
    Key := 0;
  end
  else
    inherited;
end;

procedure TS4YChip.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;

  UpdateParts;
end;

procedure TS4YChip.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;

  UpdateParts;
end;

procedure TS4YChip.SetCheckable(const Value: Boolean);
begin
  FCheckable := Value;
end;

procedure TS4YChip.SetChecked(const Value: Boolean);
begin
  if FChecked = Value then
    Exit;

  FChecked := Value;

  // The group is not touched while the form is loading: the file already holds its state.
  if FChecked and (FGroupName <> '') and not (csLoading in ComponentState) then
    UncheckOthers;

  // The check mark takes the place of the icon, so the width can change.
  UpdateSize;
  UpdateParts;

  if not (csLoading in ComponentState) then
    DoCheckedChange;
end;

procedure TS4YChip.SetGroupName(const Value: string);
begin
  if FGroupName = Value then
    Exit;

  FGroupName := Value;

  if FChecked and (FGroupName <> '') and not (csLoading in ComponentState) then
    UncheckOthers;
end;

procedure TS4YChip.SetShowCheckMark(const Value: Boolean);
begin
  if FShowCheckMark = Value then
    Exit;

  FShowCheckMark := Value;
  UpdateSize;
  UpdateParts;
end;

procedure TS4YChip.UncheckOthers;
var
  LChip: TS4YChip;
  LIndex: Integer;
begin
  if not Assigned(Parent) then
    Exit;

  for LIndex := 0 to Parent.ChildrenCount - 1 do
  begin
    if (Parent.Children[LIndex] is TS4YChip) and (Parent.Children[LIndex] <> Self) then
    begin
      LChip := TS4YChip(Parent.Children[LIndex]);

      if LChip.Checked and SameText(LChip.GroupName, FGroupName) then
        LChip.Checked := False;
    end;
  end;
end;

end.
