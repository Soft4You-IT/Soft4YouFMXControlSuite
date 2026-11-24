unit Soft4You.FMX.Controls.ChipGroup;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YChipGroup - chips made from a list of texts, of which the user chooses one, some or none
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
  Soft4You.FMX.Controls.Chip,
  Soft4You.FMX.Controls.ChipBox;

type
  /// <summary>
  /// Chips made from the texts of Items, one after the other and on a new line when the width ends, of which the user chooses one, some or none.
  /// </summary>
  /// <remarks>
  /// SelectionMode says how: cgmSingle, the default, chooses one at a time as radio buttons do and clicking the chosen chip keeps it chosen; cgmMultiple lets the user choose any number; cgmNone shows the chips without choosing.
  /// The choice is read with ItemIndex (the first chosen chip, -1 for none), Selected and SelectedItems, and set with ItemIndex and Selected. OnChange fires after every change of the choice, whoever makes it. A property link can show a field in ItemIndex; the control does not send the choice back to the field, which OnChange can do, and the texts of Items cannot be filled by a list link.
  /// Tab enters the group on the chosen chip (the first one when none is chosen) and the arrow keys, Home and End move the focus among the chips; Space chooses the chip.
  /// With AutoSize True the height follows the lines of chips up to MaxHeight and a longer content scrolls; the same with AutoSize False and the height set.
  /// Kind, Variant, Shape and SizePreset are the ones of all the chips; the chips are made and freed by the group and are not saved in the form.
  /// Changing Items keeps the choice of the chips that remain, by position.
  /// </remarks>
  TS4YChipGroup = class(TS4YCustomChipBox)
  public const
    /// <summary>Name given to the chips of the group in cgmSingle, which makes them a group of radio buttons.</summary>
    C_RADIO_GROUP_NAME = 'S4YChipGroup';
  private
    FPendingItemIndex: Integer;
    FSelectionMode: TS4YChipSelectionMode;
    FShowCheckMark: Boolean;
    FUpdating: Boolean;
    FOnChange: TNotifyEvent;
    procedure ChipCheckedChange(Sender: TObject);
    function GetItemIndex: Integer;
    function GetSelected(Index: Integer): Boolean;
    function GetSelectedItems: TArray<string>;
    function IsItemIndexStored: Boolean;
    procedure SetItemIndex(const Value: Integer);
    procedure SetSelected(Index: Integer; const Value: Boolean);
    procedure SetSelectionMode(const Value: TS4YChipSelectionMode);
    procedure SetShowCheckMark(const Value: Boolean);
    procedure UpdateTabStops;
  protected
    /// <summary>Gives the chip its text, its settings and what the mode of selection asks of it.</summary>
    procedure ConfigureChip(const AChip: TS4YChip; AIndex: Integer); override;
    /// <summary>Gives the chips the tab stops that the mode of selection asks for.</summary>
    procedure ChipsSynced; override;
    /// <summary>Creates a chip that tells the group when its choice changes.</summary>
    function CreateChip: TS4YChip; override;
    /// <summary>Fires OnChange.</summary>
    procedure DoChange; virtual;
    /// <summary>Applies the ItemIndex of the file.</summary>
    procedure Loaded; override;
  public
    /// <summary>Creates the group with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>True when the chip at the position Index is chosen. Choosing it, in cgmSingle, un-chooses the others.</summary>
    property Selected[Index: Integer]: Boolean read GetSelected write SetSelected;
    /// <summary>The texts of the chosen chips, in the order of Items.</summary>
    property SelectedItems: TArray<string> read GetSelectedItems;
  published
    property Align;
    property Anchors;
    property AutoSize;
    property Enabled;
    property Height;
    property HorizontalGap;
    /// <summary>Position in Items of the chosen chip, or of the first chosen one in cgmMultiple; -1 when no chip is chosen. Setting it chooses that chip and un-chooses the others. It is saved in the form only in cgmSingle.</summary>
    property ItemIndex: Integer read GetItemIndex write SetItemIndex stored IsItemIndexStored default -1;
    property Items;
    property Kind;
    property Margins;
    property MaxHeight;
    property Opacity;
    property Padding;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    /// <summary>How the user chooses the chips: none, one at a time or any number. The default is cgmSingle.</summary>
    property SelectionMode: TS4YChipSelectionMode read FSelectionMode write SetSelectionMode default cgmSingle;
    property Shape;
    /// <summary>When True, the default, a chosen chip shows a check mark in place of its icon.</summary>
    property ShowCheckMark: Boolean read FShowCheckMark write SetShowCheckMark default True;
    property Size;
    property SizePreset;
    property Variant default tgvOutlined;
    property VerticalGap;
    property Visible;
    property Width;

    /// <summary>Fires after the choice changes, whether by the user, by ItemIndex or by Selected.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  System.Math,
  System.SysUtils;

constructor TS4YChipGroup.Create(AOwner: TComponent);
begin
  inherited;

  FPendingItemIndex := -1;
  FSelectionMode := cgmSingle;
  FShowCheckMark := True;
end;

procedure TS4YChipGroup.ChipCheckedChange(Sender: TObject);
begin
  if FUpdating or (csLoading in ComponentState) then
    Exit;

  // In cgmSingle a chip that is un-chosen because another one is chosen is not a change on its own:
  // the other chip has already been chosen and fires the event.
  if (FSelectionMode = cgmSingle) and not TS4YChip(Sender).Checked and (GetItemIndex >= 0) then
    Exit;

  UpdateTabStops;
  DoChange;
end;

procedure TS4YChipGroup.ConfigureChip(const AChip: TS4YChip; AIndex: Integer);
begin
  inherited;

  AChip.ShowCheckMark := FShowCheckMark;
  AChip.Checkable := FSelectionMode <> cgmNone;

  if FSelectionMode = cgmSingle then
    AChip.GroupName := C_RADIO_GROUP_NAME
  else
    AChip.GroupName := '';

  if (FSelectionMode = cgmNone) and AChip.Checked then
    AChip.Checked := False;
end;

procedure TS4YChipGroup.ChipsSynced;
begin
  inherited;

  UpdateTabStops;
end;

function TS4YChipGroup.CreateChip: TS4YChip;
begin
  Result := inherited;
  Result.OnCheckedChange := ChipCheckedChange;
end;

procedure TS4YChipGroup.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TS4YChipGroup.GetItemIndex: Integer;
begin
  if csLoading in ComponentState then
    Exit(FPendingItemIndex);

  Result := -1;

  for var LIndex := 0 to Chips.Count - 1 do
  begin
    if Chips[LIndex].Checked then
      Exit(LIndex);
  end;
end;

function TS4YChipGroup.GetSelected(Index: Integer): Boolean;
begin
  Result := Chips[Index].Checked;
end;

function TS4YChipGroup.GetSelectedItems: TArray<string>;
begin
  Result := nil;

  for var LIndex := 0 to Chips.Count - 1 do
  begin
    if Chips[LIndex].Checked then
      Result := Result + [Items[LIndex]];
  end;
end;

function TS4YChipGroup.IsItemIndexStored: Boolean;
begin
  Result := (FSelectionMode = cgmSingle) and (GetItemIndex >= 0);
end;

procedure TS4YChipGroup.Loaded;
begin
  inherited;

  if FPendingItemIndex >= 0 then
    SetItemIndex(FPendingItemIndex);

  UpdateTabStops;
end;

procedure TS4YChipGroup.SetItemIndex(const Value: Integer);
var
  LOldIndex: Integer;
begin
  if csLoading in ComponentState then
  begin
    FPendingItemIndex := Value;
    Exit;
  end;

  LOldIndex := GetItemIndex;

  if (Value < 0) or (Value >= Chips.Count) or (FSelectionMode = cgmNone) then
  begin
    if LOldIndex < 0 then
      Exit;
  end;

  FUpdating := True;
  try
    // The chip to choose first: in cgmSingle it un-chooses the others by itself
    if (Value >= 0) and (Value < Chips.Count) and (FSelectionMode <> cgmNone) then
      Chips[Value].Checked := True;

    for var LIndex := 0 to Chips.Count - 1 do
    begin
      if LIndex <> Value then
        Chips[LIndex].Checked := False;
    end;
  finally
    FUpdating := False;
  end;

  if GetItemIndex <> LOldIndex then
  begin
    UpdateTabStops;
    DoChange;
  end;
end;

procedure TS4YChipGroup.SetSelected(Index: Integer; const Value: Boolean);
begin
  if FSelectionMode = cgmNone then
    Exit;

  Chips[Index].Checked := Value;
end;

procedure TS4YChipGroup.SetSelectionMode(const Value: TS4YChipSelectionMode);
var
  LOldIndex: Integer;
begin
  if FSelectionMode = Value then
    Exit;

  LOldIndex := GetItemIndex;
  FUpdating := True;
  try
    FSelectionMode := Value;
    SyncChips;
  finally
    FUpdating := False;
  end;

  UpdateTabStops;

  if GetItemIndex <> LOldIndex then
    DoChange;
end;

procedure TS4YChipGroup.SetShowCheckMark(const Value: Boolean);
begin
  if FShowCheckMark = Value then
    Exit;

  FShowCheckMark := Value;
  SyncChips;
end;

procedure TS4YChipGroup.UpdateTabStops;
var
  LChosen: Integer;
begin
  // In cgmSingle Tab enters the group on one chip, the chosen one or the first, as with radio buttons;
  // the arrow keys reach the others.
  LChosen := GetItemIndex;

  if LChosen < 0 then
    LChosen := 0;

  for var LIndex := 0 to Chips.Count - 1 do
  begin
    if FSelectionMode = cgmSingle then
      Chips[LIndex].TabStop := LIndex = LChosen
    else
      Chips[LIndex].TabStop := True;
  end;
end;

end.
