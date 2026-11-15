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
  FMX.StdCtrls,
  Soft4You.FMX.Controls.Grid.Types;

type
  /// <summary>
  /// The editor of the filter of a column of text, numbers, dates, times or lists: the user writes the text of the
  /// filter, an operator and a value, with the syntax of the filters; no text, no filter.
  /// </summary>
  /// <remarks>
  /// The grid reads the text at each change: a text that cannot be read is shown with InvalidFontColor.
  /// </remarks>
  TS4YGridTextFilterEditor = class(TEdit, IS4YGridFilterEditor)
  public const
    /// <summary>Default value of InvalidFontColor.</summary>
    C_DEFAULT_INVALID_FONT_COLOR = TAlphaColors.Red;
  private
    FInvalid: Boolean;
    FInvalidFontColor: TAlphaColor;
    FOnFilterSubmit: TNotifyEvent;
    FOnFilterValueChange: TNotifyEvent;
    FSettingValue: Boolean;
    procedure SetInvalid(const Value: Boolean);
    procedure SetInvalidFontColor(const Value: TAlphaColor);
    procedure ShowInvalid;
    procedure TextChangeTracking(Sender: TObject);
  protected
    /// <summary>Returns editstyle, the style of TEdit.</summary>
    function GetDefaultStyleLookupName: string; override;
    /// <summary>Asks to filter when Enter is pressed; Esc clears the text and asks to filter.</summary>
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
  public
    /// <summary>Creates an empty editor.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Returns the text written, or an empty value when there is no text.</summary>
    function GetFilterValue: TValue;
    /// <summary>Shows AText without firing the change.</summary>
    procedure SetFilterText(const AText: string);
    /// <summary>Shows AValue as text; an empty value clears the editor.</summary>
    procedure SetFilterValue(const AValue: TValue);
    /// <summary>Sets the event fired when the user changes the text.</summary>
    procedure SetOnFilterValueChange(const AEvent: TNotifyEvent);
    /// <summary>Sets the event fired when the user presses Enter.</summary>
    procedure SetOnFilterSubmit(const AEvent: TNotifyEvent);

    /// <summary>True shows the text with InvalidFontColor: the text cannot be read as a filter.</summary>
    property Invalid: Boolean read FInvalid write SetInvalid;
    /// <summary>The color of a text that cannot be read, from the part filterinvalidtext of the style of the grid.</summary>
    property InvalidFontColor: TAlphaColor read FInvalidFontColor write SetInvalidFontColor;
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

implementation

uses
  System.SysUtils,
  FMX.Types,
  FMX.Graphics;

{ TS4YGridTextFilterEditor }

constructor TS4YGridTextFilterEditor.Create(AOwner: TComponent);
begin
  inherited;

  FInvalidFontColor := C_DEFAULT_INVALID_FONT_COLOR;
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

procedure TS4YGridTextFilterEditor.SetFilterText(const AText: string);
begin
  FSettingValue := True;
  try
    Text := AText;
  finally
    FSettingValue := False;
  end;
end;

procedure TS4YGridTextFilterEditor.SetFilterValue(const AValue: TValue);
begin
  if AValue.IsEmpty then
    SetFilterText('')
  else
    SetFilterText(AValue.ToString);
end;

procedure TS4YGridTextFilterEditor.SetInvalid(const Value: Boolean);
begin
  if FInvalid = Value then
    Exit;

  FInvalid := Value;
  ShowInvalid;
end;

procedure TS4YGridTextFilterEditor.SetInvalidFontColor(const Value: TAlphaColor);
begin
  if FInvalidFontColor = Value then
    Exit;

  FInvalidFontColor := Value;
  ShowInvalid;
end;

procedure TS4YGridTextFilterEditor.SetOnFilterSubmit(const AEvent: TNotifyEvent);
begin
  FOnFilterSubmit := AEvent;
end;

procedure TS4YGridTextFilterEditor.SetOnFilterValueChange(const AEvent: TNotifyEvent);
begin
  FOnFilterValueChange := AEvent;
end;

procedure TS4YGridTextFilterEditor.ShowInvalid;
begin
  // The color of the style, or the one of a text that cannot be read.
  if FInvalid then
  begin
    StyledSettings := StyledSettings - [TStyledSetting.FontColor];
    TextSettings.FontColor := FInvalidFontColor;
  end
  else
    StyledSettings := StyledSettings + [TStyledSetting.FontColor];
end;

procedure TS4YGridTextFilterEditor.TextChangeTracking(Sender: TObject);
begin
  if not FSettingValue and Assigned(FOnFilterValueChange) then
    FOnFilterValueChange(Self);
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

end.
