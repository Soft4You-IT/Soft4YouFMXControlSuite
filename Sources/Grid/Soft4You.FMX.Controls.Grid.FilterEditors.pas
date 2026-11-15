unit Soft4You.FMX.Controls.Grid.FilterEditors;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YGrid - editors of the filter row
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.UITypes,
  System.Rtti,
  FMX.Edit,
  FMX.DateTimeCtrls,
  FMX.StdCtrls,
  FMX.ListBox,
  Soft4You.FMX.Controls.Grid.Types;

type
  /// <summary>
  /// The editor of the filter of a text column: the filter is the text written, a string; no text, no filter.
  /// </summary>
  TS4YGridTextFilterEditor = class(TEdit, IS4YGridFilterEditor)
  private
    FOnFilterSubmit: TNotifyEvent;
    FOnFilterValueChange: TNotifyEvent;
    FSettingValue: Boolean;
    procedure TextChangeTracking(Sender: TObject);
  protected
    /// <summary>Returns editstyle, the style of TEdit, also for the editors that descend from this one.</summary>
    function GetDefaultStyleLookupName: string; override;
    /// <summary>Asks to filter when Enter is pressed; Esc clears the text and asks to filter.</summary>
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
    /// <summary>Shows AText without firing the change.</summary>
    procedure SetTextSilently(const AText: string);
  public
    /// <summary>Creates an empty editor.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Returns the text written, or an empty value when there is no text.</summary>
    function GetFilterValue: TValue; virtual;
    /// <summary>Shows AValue as text; an empty value clears the editor.</summary>
    procedure SetFilterValue(const AValue: TValue); virtual;
    /// <summary>Sets the event fired when the user changes the text.</summary>
    procedure SetOnFilterValueChange(const AEvent: TNotifyEvent);
    /// <summary>Sets the event fired when the user presses Enter.</summary>
    procedure SetOnFilterSubmit(const AEvent: TNotifyEvent);
  end;

  /// <summary>
  /// The kind of number of a TS4YGridNumberFilterEditor.
  /// </summary>
  /// <remarks>
  /// gnkInteger: whole numbers, the filter is an Int64.
  /// gnkFloat: numbers with decimals, the filter is a Double.
  /// </remarks>
  TS4YGridNumberKind = (
    gnkInteger,
    gnkFloat
  );

  /// <summary>
  /// The editor of the filter of a number column: it accepts only the characters of a number; no number, no filter.
  /// </summary>
  TS4YGridNumberFilterEditor = class(TS4YGridTextFilterEditor)
  private
    FNumberKind: TS4YGridNumberKind;
    procedure SetNumberKind(const Value: TS4YGridNumberKind);
  public
    /// <summary>Creates an empty editor of whole numbers.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Returns the number written, an Int64 or a Double, or an empty value when it is not a number.</summary>
    function GetFilterValue: TValue; override;
    /// <summary>Shows the number AValue; an empty value clears the editor.</summary>
    procedure SetFilterValue(const AValue: TValue); override;

    /// <summary>Whole numbers or numbers with decimals.</summary>
    property NumberKind: TS4YGridNumberKind read FNumberKind write SetNumberKind;
  end;

  /// <summary>
  /// The editor of the filter of a date column: the filter is the date chosen, a TDate; no date, no filter.
  /// </summary>
  TS4YGridDateFilterEditor = class(TDateEdit, IS4YGridFilterEditor)
  private
    FOnFilterSubmit: TNotifyEvent;
    FOnFilterValueChange: TNotifyEvent;
    FSettingValue: Boolean;
    procedure DateChange(Sender: TObject);
  protected
    /// <summary>Returns dateeditstyle, the style of TDateEdit.</summary>
    function GetDefaultStyleLookupName: string; override;
    /// <summary>Asks to filter when Enter is pressed; Esc clears the date and asks to filter.</summary>
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
  public
    /// <summary>Creates an empty editor with the button that clears the date.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Returns the date chosen, or an empty value when there is no date.</summary>
    function GetFilterValue: TValue;
    /// <summary>Shows the date AValue; an empty value clears the editor.</summary>
    procedure SetFilterValue(const AValue: TValue);
    /// <summary>Sets the event fired when the user changes the date.</summary>
    procedure SetOnFilterValueChange(const AEvent: TNotifyEvent);
    /// <summary>Sets the event fired when the user presses Enter.</summary>
    procedure SetOnFilterSubmit(const AEvent: TNotifyEvent);
  end;

  /// <summary>
  /// The state of the filter of a check column.
  /// </summary>
  /// <remarks>
  /// gcfAny: no filter, every row; the box is shown faded.
  /// gcfChecked: the rows whose box is checked.
  /// gcfUnchecked: the rows whose box is not checked.
  /// </remarks>
  TS4YGridCheckFilterState = (
    gcfAny,
    gcfChecked,
    gcfUnchecked
  );

  /// <summary>
  /// The editor of the filter of a check column, a check box with three states: any row (faded), checked rows,
  /// unchecked rows; a click passes to the next state and asks to filter.
  /// </summary>
  TS4YGridCheckFilterEditor = class(TCheckBox, IS4YGridFilterEditor)
  public const
    /// <summary>Opacity of the box when there is no filter.</summary>
    C_ANY_OPACITY = 0.4;
  private
    FOnFilterSubmit: TNotifyEvent;
    FOnFilterValueChange: TNotifyEvent;
    FSettingValue: Boolean;
    FState: TS4YGridCheckFilterState;
    procedure CheckChange(Sender: TObject);
    procedure SetState(const Value: TS4YGridCheckFilterState);
    procedure ShowState;
  protected
    /// <summary>Returns checkboxstyle, the style of TCheckBox.</summary>
    function GetDefaultStyleLookupName: string; override;
  public
    /// <summary>Creates an editor without filter.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Esc shows any row again and asks to filter.</summary>
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;

    /// <summary>Returns True for checked rows, False for unchecked rows, an empty value for any row.</summary>
    function GetFilterValue: TValue;
    /// <summary>Shows the Boolean AValue; an empty value shows the state without filter.</summary>
    procedure SetFilterValue(const AValue: TValue);
    /// <summary>Sets the event fired when the user changes the state.</summary>
    procedure SetOnFilterValueChange(const AEvent: TNotifyEvent);
    /// <summary>Sets the event fired after the change of the state.</summary>
    procedure SetOnFilterSubmit(const AEvent: TNotifyEvent);

    /// <summary>The state of the filter.</summary>
    property State: TS4YGridCheckFilterState read FState write SetState;
  end;

  /// <summary>
  /// The editor of the filter of a column with a list of values, such as a TPopupColumn: a drop-down list whose
  /// first item, empty, is no filter; the filter is the text of the item chosen, a string. A choice asks to filter.
  /// </summary>
  TS4YGridListFilterEditor = class(TComboBox, IS4YGridFilterEditor)
  private
    FOnFilterSubmit: TNotifyEvent;
    FOnFilterValueChange: TNotifyEvent;
    FSettingValue: Boolean;
    procedure ListChange(Sender: TObject);
  protected
    /// <summary>Returns comboboxstyle, the style of TComboBox.</summary>
    function GetDefaultStyleLookupName: string; override;
    /// <summary>Esc, with the list closed, chooses the empty item and asks to filter.</summary>
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
  public
    /// <summary>Creates an editor with only the empty item.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Returns the text of the item chosen, or an empty value for the empty item.</summary>
    function GetFilterValue: TValue;
    /// <summary>Shows the empty item and then the items of AItems.</summary>
    procedure SetFilterItems(const AItems: TStrings);
    /// <summary>Chooses the item with the text AValue; an empty value chooses the empty item.</summary>
    procedure SetFilterValue(const AValue: TValue);
    /// <summary>Sets the event fired when the user chooses an item.</summary>
    procedure SetOnFilterValueChange(const AEvent: TNotifyEvent);
    /// <summary>Sets the event fired after the choice.</summary>
    procedure SetOnFilterSubmit(const AEvent: TNotifyEvent);
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  FMX.Types;

{ TS4YGridTextFilterEditor }

constructor TS4YGridTextFilterEditor.Create(AOwner: TComponent);
begin
  inherited;

  OnChangeTracking := TextChangeTracking;
end;

function TS4YGridTextFilterEditor.GetDefaultStyleLookupName: string;
begin
  Result := 'editstyle';
end;

function TS4YGridTextFilterEditor.GetFilterValue: TValue;
begin
  if Text = '' then
    Result := TValue.Empty
  else
    Result := Text;
end;

procedure TS4YGridTextFilterEditor.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
var
  LKey: Word;
begin
  // Esc with a filter clears it, and is not passed on, for example to close the form.
  if (Key = vkEscape) and (Text <> '') then
  begin
    Key := 0;
    Text := '';

    if Assigned(FOnFilterSubmit) then
      FOnFilterSubmit(Self);

    Exit;
  end;

  LKey := Key;

  inherited;

  if (LKey = vkReturn) and Assigned(FOnFilterSubmit) then
    FOnFilterSubmit(Self);
end;

procedure TS4YGridTextFilterEditor.SetFilterValue(const AValue: TValue);
begin
  if AValue.IsEmpty then
    SetTextSilently('')
  else
    SetTextSilently(AValue.ToString);
end;

procedure TS4YGridTextFilterEditor.SetOnFilterSubmit(const AEvent: TNotifyEvent);
begin
  FOnFilterSubmit := AEvent;
end;

procedure TS4YGridTextFilterEditor.SetOnFilterValueChange(const AEvent: TNotifyEvent);
begin
  FOnFilterValueChange := AEvent;
end;

procedure TS4YGridTextFilterEditor.SetTextSilently(const AText: string);
begin
  FSettingValue := True;
  try
    Text := AText;
  finally
    FSettingValue := False;
  end;
end;

procedure TS4YGridTextFilterEditor.TextChangeTracking(Sender: TObject);
begin
  if not FSettingValue and Assigned(FOnFilterValueChange) then
    FOnFilterValueChange(Self);
end;

{ TS4YGridNumberFilterEditor }

constructor TS4YGridNumberFilterEditor.Create(AOwner: TComponent);
begin
  inherited;

  KeyboardType := TVirtualKeyboardType.NumbersAndPunctuation;
  SetNumberKind(gnkInteger);
end;

function TS4YGridNumberFilterEditor.GetFilterValue: TValue;
var
  LInteger: Int64;
  LFloat: Double;
begin
  // A text that is not yet a number, such as '-', is no filter.
  Result := TValue.Empty;

  if FNumberKind = gnkInteger then
  begin
    if TryStrToInt64(Text, LInteger) then
      Result := LInteger;
  end
  else
  begin
    if TryStrToFloat(Text, LFloat) then
      Result := LFloat;
  end;
end;

procedure TS4YGridNumberFilterEditor.SetFilterValue(const AValue: TValue);
begin
  if AValue.IsEmpty then
    SetTextSilently('')
  else if FNumberKind = gnkInteger then
    SetTextSilently(IntToStr(AValue.AsInt64))
  else
    SetTextSilently(FloatToStr(AValue.AsExtended));
end;

procedure TS4YGridNumberFilterEditor.SetNumberKind(const Value: TS4YGridNumberKind);
begin
  FNumberKind := Value;

  if FNumberKind = gnkInteger then
    FilterChar := '-0123456789'
  else
    FilterChar := '-0123456789' + FormatSettings.DecimalSeparator;
end;

{ TS4YGridDateFilterEditor }

constructor TS4YGridDateFilterEditor.Create(AOwner: TComponent);
begin
  inherited;

  ShowClearButton := True;
  IsEmpty := True;
  OnChange := DateChange;
end;

procedure TS4YGridDateFilterEditor.DateChange(Sender: TObject);
begin
  if not FSettingValue and Assigned(FOnFilterValueChange) then
    FOnFilterValueChange(Self);
end;

function TS4YGridDateFilterEditor.GetDefaultStyleLookupName: string;
begin
  Result := 'dateeditstyle';
end;

function TS4YGridDateFilterEditor.GetFilterValue: TValue;
begin
  if IsEmpty then
    Result := TValue.Empty
  else
    Result := TValue.From<TDate>(Date);
end;

procedure TS4YGridDateFilterEditor.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
var
  LKey: Word;
begin
  if (Key = vkEscape) and not IsEmpty then
  begin
    Key := 0;
    IsEmpty := True;

    if Assigned(FOnFilterSubmit) then
      FOnFilterSubmit(Self);

    Exit;
  end;

  LKey := Key;

  inherited;

  if (LKey = vkReturn) and Assigned(FOnFilterSubmit) then
    FOnFilterSubmit(Self);
end;

procedure TS4YGridDateFilterEditor.SetFilterValue(const AValue: TValue);
begin
  FSettingValue := True;
  try
    if AValue.IsEmpty then
      IsEmpty := True
    else
    begin
      Date := AValue.AsExtended;
      IsEmpty := False;
    end;
  finally
    FSettingValue := False;
  end;
end;

procedure TS4YGridDateFilterEditor.SetOnFilterSubmit(const AEvent: TNotifyEvent);
begin
  FOnFilterSubmit := AEvent;
end;

procedure TS4YGridDateFilterEditor.SetOnFilterValueChange(const AEvent: TNotifyEvent);
begin
  FOnFilterValueChange := AEvent;
end;

{ TS4YGridCheckFilterEditor }

constructor TS4YGridCheckFilterEditor.Create(AOwner: TComponent);
begin
  inherited;

  OnChange := CheckChange;
  ShowState;
end;

procedure TS4YGridCheckFilterEditor.CheckChange(Sender: TObject);
begin
  if FSettingValue then
    Exit;

  // A click inverts the box: any row -> checked -> unchecked -> any row.
  case FState of
    gcfAny:
      SetState(gcfChecked);
    gcfChecked:
      SetState(gcfUnchecked);
    gcfUnchecked:
      SetState(gcfAny);
  end;

  if Assigned(FOnFilterValueChange) then
    FOnFilterValueChange(Self);

  if Assigned(FOnFilterSubmit) then
    FOnFilterSubmit(Self);
end;

function TS4YGridCheckFilterEditor.GetDefaultStyleLookupName: string;
begin
  Result := 'checkboxstyle';
end;

function TS4YGridCheckFilterEditor.GetFilterValue: TValue;
begin
  case FState of
    gcfChecked:
      Result := True;
    gcfUnchecked:
      Result := False;
  else
    Result := TValue.Empty;
  end;
end;

procedure TS4YGridCheckFilterEditor.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
begin
  if (Key = vkEscape) and (FState <> gcfAny) then
  begin
    Key := 0;
    SetState(gcfAny);

    if Assigned(FOnFilterValueChange) then
      FOnFilterValueChange(Self);

    if Assigned(FOnFilterSubmit) then
      FOnFilterSubmit(Self);

    Exit;
  end;

  inherited;
end;

procedure TS4YGridCheckFilterEditor.SetFilterValue(const AValue: TValue);
begin
  if AValue.IsEmpty then
    SetState(gcfAny)
  else if AValue.AsBoolean then
    SetState(gcfChecked)
  else
    SetState(gcfUnchecked);
end;

procedure TS4YGridCheckFilterEditor.SetOnFilterSubmit(const AEvent: TNotifyEvent);
begin
  FOnFilterSubmit := AEvent;
end;

procedure TS4YGridCheckFilterEditor.SetOnFilterValueChange(const AEvent: TNotifyEvent);
begin
  FOnFilterValueChange := AEvent;
end;

procedure TS4YGridCheckFilterEditor.SetState(const Value: TS4YGridCheckFilterState);
begin
  FState := Value;
  ShowState;
end;

procedure TS4YGridCheckFilterEditor.ShowState;
begin
  FSettingValue := True;
  try
    IsChecked := FState = gcfChecked;

    if FState = gcfAny then
      Opacity := C_ANY_OPACITY
    else
      Opacity := 1;
  finally
    FSettingValue := False;
  end;
end;

{ TS4YGridListFilterEditor }

constructor TS4YGridListFilterEditor.Create(AOwner: TComponent);
begin
  inherited;

  Items.Add('');
  ItemIndex := 0;
  OnChange := ListChange;
end;

function TS4YGridListFilterEditor.GetDefaultStyleLookupName: string;
begin
  Result := 'comboboxstyle';
end;

function TS4YGridListFilterEditor.GetFilterValue: TValue;
begin
  if ItemIndex <= 0 then
    Result := TValue.Empty
  else
    Result := Items[ItemIndex];
end;

procedure TS4YGridListFilterEditor.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
begin
  // With the list open, Esc closes it.
  if (Key = vkEscape) and not DroppedDown and (ItemIndex > 0) then
  begin
    Key := 0;
    ItemIndex := 0;
    Exit;
  end;

  inherited;
end;

procedure TS4YGridListFilterEditor.ListChange(Sender: TObject);
begin
  if FSettingValue then
    Exit;

  if Assigned(FOnFilterValueChange) then
    FOnFilterValueChange(Self);

  if Assigned(FOnFilterSubmit) then
    FOnFilterSubmit(Self);
end;

procedure TS4YGridListFilterEditor.SetFilterItems(const AItems: TStrings);
begin
  FSettingValue := True;
  try
    Items.BeginUpdate;
    try
      Items.Clear;
      Items.Add('');

      if Assigned(AItems) then
        Items.AddStrings(AItems);
    finally
      Items.EndUpdate;
    end;

    ItemIndex := 0;
  finally
    FSettingValue := False;
  end;
end;

procedure TS4YGridListFilterEditor.SetFilterValue(const AValue: TValue);
begin
  FSettingValue := True;
  try
    // A value that is not in the list shows the empty item.
    if AValue.IsEmpty then
      ItemIndex := 0
    else
      ItemIndex := Max(0, Items.IndexOf(AValue.ToString));
  finally
    FSettingValue := False;
  end;
end;

procedure TS4YGridListFilterEditor.SetOnFilterSubmit(const AEvent: TNotifyEvent);
begin
  FOnFilterSubmit := AEvent;
end;

procedure TS4YGridListFilterEditor.SetOnFilterValueChange(const AEvent: TNotifyEvent);
begin
  FOnFilterValueChange := AEvent;
end;

end.
