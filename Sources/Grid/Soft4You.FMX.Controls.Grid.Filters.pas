unit Soft4You.FMX.Controls.Grid.Filters;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YGrid - filters of the columns: syntax of the text, values, comparison
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  FMX.Grid,
  Soft4You.FMX.Controls.Grid.Types;

type
  /// <summary>
  /// The filter of a column of TS4YGrid: the text written in the filter row, and what the grid reads in it, an operator
  /// and a value of the type of the column.
  /// </summary>
  /// <remarks>
  /// The syntax of the text is positional: an operator (=, &lt;&gt;, !=, &lt;, &lt;=, &gt;, &gt;=, !) only at the
  /// start, and * only as the first or the last character of a text without operator (abc* starts with, *abc ends
  /// with, *abc* contains). A value between double quotes is always text; a double quote in it is written twice. A
  /// text without operator uses the default operator of the column: contains for the text, equal for the others; !
  /// is its opposite. = and &lt;&gt; alone are empty and not empty.
  /// </remarks>
  TS4YGridFilter = record
    /// <summary>True when the operator is written in the text; False when it is the default operator.</summary>
    ExplicitOperator: Boolean;
    /// <summary>
    /// The values of a list of texts and values, from the lines Text=Value of FilterItems; empty for a list of texts.
    /// </summary>
    Items: TArray<TS4YGridFilterItem>;
    /// <summary>The kind of value of the column.</summary>
    Kind: TS4YGridFilterValueKind;
    /// <summary>The operator read in the text; gfoNone without text.</summary>
    FilterOperator: TS4YGridFilterOperator;
    /// <summary>The state of the text: empty, incomplete, valid or invalid.</summary>
    State: TS4YGridFilterState;
    /// <summary>The text, as it is written.</summary>
    Text: string;
    /// <summary>The value read in the text, of the type of the column; empty when the filter is not valid.</summary>
    Value: TValue;
    /// <summary>The text of the value, without the operator and the double quotes, also when it cannot be read.</summary>
    ValueText: string;
    /// <summary>The kind of the values of Items: the kind of value of the type of the column.</summary>
    ValueKind: TS4YGridFilterValueKind;

    /// <summary>Returns the operator of a text without operator for AKind: contains for text, equal otherwise.</summary>
    /// <summary>
    /// Returns the values of a list with lines Text=Value, such as Open=1, each value read for AValueKind; an empty
    /// array when no line has the sign =, a list of texts. A line without = has its text as value.
    /// </summary>
    class function CreateItems(const AItems: TStrings; const AValueKind: TS4YGridFilterValueKind):
      TArray<TS4YGridFilterItem>; static;
    /// <summary>Returns the operator of a text without operator for AKind: contains for text, equal otherwise.</summary>
    class function DefaultOperator(const AKind: TS4YGridFilterValueKind): TS4YGridFilterOperator; static;
    /// <summary>
    /// Returns the text of a filter with AOperator and AValue, in the form the grid writes: the operator, a space and
    /// the value, between double quotes when it needs them.
    /// </summary>
    /// <remarks>
    /// Explicit False leaves out the default operator; True writes it too, as for a choice in the menu. An empty
    /// AValue writes only the operator, so that the user writes the value after it. With AItems, the value is written
    /// as the text of its item.
    /// </remarks>
    class function FormatText(const AKind: TS4YGridFilterValueKind; const AOperator: TS4YGridFilterOperator;
      const AValue: TValue; const Explicit: Boolean; const AItems: TArray<TS4YGridFilterItem> = nil): string; static;
    /// <summary>Returns True when AOperator can be used for AKind.</summary>
    class function IsOperatorAllowed(const AKind: TS4YGridFilterValueKind;
      const AOperator: TS4YGridFilterOperator): Boolean; static;
    /// <summary>Returns True when AValue is empty: no value, an empty text, a Null or Unassigned variant.</summary>
    class function IsValueEmpty(const AValue: TValue): Boolean; static;
    /// <summary>
    /// Returns the filter written as AText in a column of AKind; with AItems, the value is the text of an item, and the
    /// filter gets the value of the item, of AValueKind.
    /// </summary>
    class function Parse(const AText: string; const AKind: TS4YGridFilterValueKind;
      const AItems: TArray<TS4YGridFilterItem> = nil; const AValueKind: TS4YGridFilterValueKind = gvkText):
      TS4YGridFilter; static;
    /// <summary>Returns in ANumber the number in AValue: an integer, a float, a variant or a text that is a number.</summary>
    class function TryValueToNumber(const AValue: TValue; out ANumber: Double): Boolean; static;

    /// <summary>Returns True when the filter is applied: State is gfsValid.</summary>
    function IsActive: Boolean;
    /// <summary>
    /// Returns True when the value of a row, AValue, passes the filter; always True when the filter is not applied, or
    /// when AValue cannot be compared with the value of the filter.
    /// </summary>
    /// <remarks>
    /// With Items, AValue is compared with the value of the item of the filter; a text of an item counts as its value.
    /// </remarks>
    function Matches(const AValue: TValue): Boolean;
  end;

  /// <summary>
  /// An item of the menu of the filter of a column, the menu of the button of its editor.
  /// </summary>
  TS4YGridFilterMenuItem = class
  private
    FAction: TS4YGridFilterMenuAction;
    FChecked: Boolean;
    FColumn: TColumn;
    FFilterOperator: TS4YGridFilterOperator;
    FText: string;
    FValue: TValue;
    FOnClick: TNotifyEvent;
  public
    /// <summary>What the item does.</summary>
    property Action: TS4YGridFilterMenuAction read FAction write FAction;
    /// <summary>True shows the item as chosen, as the operator of the filter.</summary>
    property Checked: Boolean read FChecked write FChecked;
    /// <summary>The column of the filter.</summary>
    property Column: TColumn read FColumn write FColumn;
    /// <summary>The operator written by an item gmaOperator.</summary>
    property FilterOperator: TS4YGridFilterOperator read FFilterOperator write FFilterOperator;
    /// <summary>The text of the item.</summary>
    property Text: string read FText write FText;
    /// <summary>The value written by an item gmaValue.</summary>
    property Value: TValue read FValue write FValue;

    /// <summary>Fires when the user chooses an item gmaCustom; Sender is the item.</summary>
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

  /// <summary>
  /// The items of the menu of the filter of a column: the grid adds its items, and the application can add, remove or
  /// change them in OnFilterMenu.
  /// </summary>
  TS4YGridFilterMenuItems = class
  private
    FColumn: TColumn;
    FItems: TObjectList<TS4YGridFilterMenuItem>;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): TS4YGridFilterMenuItem;
  public
    /// <summary>Creates an empty list of items of the menu of AColumn.</summary>
    constructor Create(const AColumn: TColumn);
    /// <summary>Destroys the items.</summary>
    destructor Destroy; override;

    /// <summary>Adds an item of the application with the text AText, which fires AOnClick.</summary>
    function Add(const AText: string; const AOnClick: TNotifyEvent): TS4YGridFilterMenuItem;
    /// <summary>Adds an item with the action AAction and the text AText.</summary>
    function AddAction(const AAction: TS4YGridFilterMenuAction; const AText: string): TS4YGridFilterMenuItem;
    /// <summary>Adds a line between two groups of items.</summary>
    function AddSeparator: TS4YGridFilterMenuItem;
    /// <summary>Removes all the items.</summary>
    procedure Clear;
    /// <summary>Removes the item at AIndex.</summary>
    procedure Delete(const AIndex: Integer);
    /// <summary>Returns the position of the first item with the action AAction, -1 when there is none.</summary>
    function IndexOfAction(const AAction: TS4YGridFilterMenuAction): Integer;
    /// <summary>Inserts at AIndex an item of the application with the text AText, which fires AOnClick.</summary>
    function Insert(const AIndex: Integer; const AText: string; const AOnClick: TNotifyEvent): TS4YGridFilterMenuItem;

    /// <summary>The column of the filter: the items added take it.</summary>
    property Column: TColumn read FColumn write FColumn;
    /// <summary>The number of items.</summary>
    property Count: Integer read GetCount;
    /// <summary>The items, by position.</summary>
    property Items[const AIndex: Integer]: TS4YGridFilterMenuItem read GetItem; default;
  end;

  /// <summary>
  /// The event that lets the application change the menu of the filter of a column before it is shown.
  /// </summary>
  TS4YGridFilterMenuEvent = procedure(Sender: TObject; const AColumn: TColumn;
    const AItems: TS4YGridFilterMenuItems) of object;

implementation

uses
  System.SysUtils,
  System.Math,
  System.Variants,
  System.TypInfo,
  System.DateUtils;

const
  C_QUOTE = '"';
  C_WILDCARD = '*';
  C_SYMBOL_EMPTY = '=';
  C_SYMBOL_NOT = '!';
  // The operators of two characters first: < would be read in <=.
  C_SYMBOLS: array[0..7] of string = ('<>', '!=', '<=', '>=', '<', '>', '=', '!');
  // The first characters of a value that would be read as an operator.
  C_OPERATOR_CHARACTERS = '=<>!"*';

// Returns AText without the operator at its start, and the operator in ASymbol; '' when there is none.
function SplitOperator(const AText: string; out ASymbol: string): string;
var
  LIndex: Integer;
begin
  ASymbol := '';
  Result := AText;
  LIndex := 0;

  while (ASymbol = '') and (LIndex <= High(C_SYMBOLS)) do
  begin
    if AText.StartsWith(C_SYMBOLS[LIndex]) then
    begin
      ASymbol := C_SYMBOLS[LIndex];
      Result := AText.Substring(ASymbol.Length).TrimLeft;
    end;

    Inc(LIndex);
  end;
end;

// Returns the operator of ASymbol for AKind: ! is the opposite of the default operator.
function SymbolToOperator(const ASymbol: string; const AKind: TS4YGridFilterValueKind): TS4YGridFilterOperator;
begin
  if (ASymbol = '<>') or (ASymbol = '!=') then
    Result := gfoNotEqual
  else if ASymbol = '<' then
    Result := gfoLess
  else if ASymbol = '<=' then
    Result := gfoLessOrEqual
  else if ASymbol = '>' then
    Result := gfoGreater
  else if ASymbol = '>=' then
    Result := gfoGreaterOrEqual
  else if ASymbol = '=' then
    Result := gfoEqual
  else if (ASymbol = C_SYMBOL_NOT) and (AKind = gvkText) then
    Result := gfoNotContains
  else if ASymbol = C_SYMBOL_NOT then
    Result := gfoNotEqual
  else
    Result := gfoNone;
end;

// Reads the value after the operator: the * at its sides, and the text between double quotes. False when the double
// quotes are not closed, or other characters follow them.
function ReadValue(const AText: string; out AValue: string; out ALeadingWildcard, ATrailingWildcard: Boolean): Boolean;
var
  LText: string;
  LIndex: Integer;
  LClosed: Boolean;
  LBuilder: TStringBuilder;
  LRest: string;
begin
  Result := True;
  AValue := '';
  ATrailingWildcard := False;
  LText := AText.Trim;
  ALeadingWildcard := LText.StartsWith(C_WILDCARD);

  if ALeadingWildcard then
    LText := LText.Substring(1).TrimLeft;

  if not LText.StartsWith(C_QUOTE) then
  begin
    ATrailingWildcard := LText.EndsWith(C_WILDCARD);

    if ATrailingWildcard then
      LText := LText.Substring(0, LText.Length - 1);

    AValue := LText.Trim;
    Exit;
  end;

  // Between double quotes: the text as it is, with "" for a double quote.
  LClosed := False;
  LIndex := 1;
  LBuilder := TStringBuilder.Create;
  try
    while not LClosed and (LIndex < LText.Length) do
    begin
      if (LText.Chars[LIndex] = C_QUOTE) and (LIndex + 1 < LText.Length) and (LText.Chars[LIndex + 1] = C_QUOTE) then
      begin
        LBuilder.Append(C_QUOTE);
        Inc(LIndex, 2);
      end
      else if LText.Chars[LIndex] = C_QUOTE then
      begin
        LClosed := True;
        Inc(LIndex);
      end
      else
      begin
        LBuilder.Append(LText.Chars[LIndex]);
        Inc(LIndex);
      end;
    end;

    AValue := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;

  LRest := LText.Substring(LIndex).Trim;
  ATrailingWildcard := LRest = C_WILDCARD;
  Result := LClosed and ((LRest = '') or ATrailingWildcard);
end;

// Returns in AValue the value of AText for AKind.
function TryTextToValue(const AText: string; const AKind: TS4YGridFilterValueKind; out AValue: TValue): Boolean;
var
  LInteger: Int64;
  LFloat: Double;
  LDate: TDateTime;
  LBoolean: Boolean;
begin
  Result := False;
  AValue := TValue.Empty;

  case AKind of
    gvkText, gvkList:
      begin
        AValue := AText;
        Result := True;
      end;
    gvkInteger:
      if TryStrToInt64(AText, LInteger) then
      begin
        AValue := LInteger;
        Result := True;
      end;
    gvkFloat:
      if TryStrToFloat(AText, LFloat) then
      begin
        AValue := LFloat;
        Result := True;
      end;
    gvkDate:
      if TryStrToDate(AText, LDate) then
      begin
        AValue := TValue.From<TDate>(LDate);
        Result := True;
      end;
    gvkTime:
      if TryStrToTime(AText, LDate) then
      begin
        AValue := TValue.From<TTime>(LDate);
        Result := True;
      end;
    gvkBoolean:
      if TryStrToBool(AText, LBoolean) then
      begin
        AValue := LBoolean;
        Result := True;
      end;
  end;
end;

// Returns in ADateTime the date and time in AValue: a date, a number, a variant or a text that is a date.
function TryValueToDateTime(const AValue: TValue; out ADateTime: TDateTime): Boolean;
var
  LVariant: Variant;
begin
  Result := True;

  case AValue.Kind of
    tkInteger, tkInt64:
      ADateTime := AValue.AsInt64;
    tkFloat:
      ADateTime := AValue.AsExtended;
    tkString, tkLString, tkWString, tkUString:
      Result := TryStrToDateTime(AValue.AsString, ADateTime);
    tkVariant:
      begin
        LVariant := AValue.AsVariant;

        if VarIsType(LVariant, varDate) or VarIsNumeric(LVariant) then
          ADateTime := VarToDateTime(LVariant)
        else if VarIsStr(LVariant) then
          Result := TryStrToDateTime(VarToStr(LVariant), ADateTime)
        else
          Result := False;
      end;
  else
    Result := False;
  end;
end;

// Returns in ABoolean the Boolean in AValue: a Boolean, a number, a variant or a text such as True.
function TryValueToBoolean(const AValue: TValue; out ABoolean: Boolean): Boolean;
var
  LVariant: Variant;
begin
  Result := True;

  case AValue.Kind of
    tkEnumeration:
      if AValue.TypeInfo = TypeInfo(Boolean) then
        ABoolean := AValue.AsBoolean
      else
        Result := False;
    tkInteger, tkInt64:
      ABoolean := AValue.AsInt64 <> 0;
    tkString, tkLString, tkWString, tkUString:
      Result := TryStrToBool(AValue.AsString, ABoolean);
    tkVariant:
      begin
        LVariant := AValue.AsVariant;

        if VarIsType(LVariant, varBoolean) or VarIsNumeric(LVariant) then
          ABoolean := LVariant
        else if VarIsStr(LVariant) then
          Result := TryStrToBool(VarToStr(LVariant), ABoolean)
        else
          Result := False;
      end;
  else
    Result := False;
  end;
end;

// Returns the text of AValue, also of a variant.
function ValueToText(const AValue: TValue): string;
begin
  if AValue.Kind = tkVariant then
    Result := VarToStr(AValue.AsVariant)
  else
    Result := AValue.ToString;
end;

// Returns AValue as it is written in the text of a filter of AKind, between double quotes when it needs them.
function FormatValue(const AKind: TS4YGridFilterValueKind; const AValue: TValue): string;
var
  LNumber: Double;
  LDateTime: TDateTime;
  LBoolean: Boolean;
begin
  Result := ValueToText(AValue);

  case AKind of
    gvkInteger:
      if TS4YGridFilter.TryValueToNumber(AValue, LNumber) and (Frac(LNumber) = 0) then
        Result := IntToStr(Trunc(LNumber));
    gvkFloat:
      if TS4YGridFilter.TryValueToNumber(AValue, LNumber) then
        Result := FloatToStr(LNumber);
    gvkDate:
      if TryValueToDateTime(AValue, LDateTime) then
        Result := DateToStr(LDateTime);
    gvkTime:
      if TryValueToDateTime(AValue, LDateTime) and (SecondOf(LDateTime) = 0) and (MilliSecondOf(LDateTime) = 0) then
        Result := FormatDateTime(FormatSettings.ShortTimeFormat, LDateTime)
      else if TryValueToDateTime(AValue, LDateTime) then
        Result := TimeToStr(LDateTime);
    gvkBoolean:
      if TryValueToBoolean(AValue, LBoolean) then
        Result := BoolToStr(LBoolean, True);
  end;

  // A text that would be read as an operator, or with spaces at its sides, goes between double quotes.
  if (Result <> '') and ((Pos(Result.Chars[0], C_OPERATOR_CHARACTERS) > 0) or Result.EndsWith(C_WILDCARD) or
    (Result.Trim <> Result)) then
    Result := C_QUOTE + Result.Replace(C_QUOTE, C_QUOTE + C_QUOTE) + C_QUOTE;
end;

// Returns the position of the item with the text AText, -1 when there is none.
function IndexOfItemText(const AItems: TArray<TS4YGridFilterItem>; const AText: string): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  LIndex := 0;

  while (Result < 0) and (LIndex <= High(AItems)) do
  begin
    if AnsiSameText(AItems[LIndex].Text, AText) then
      Result := LIndex;

    Inc(LIndex);
  end;
end;

// Returns the position of the item with the value AValue, or with the text AValue, -1 when there is none.
function IndexOfItemValue(const AItems: TArray<TS4YGridFilterItem>; const AValue: TValue): Integer;
var
  LIndex: Integer;
  LNumber: Double;
  LItemNumber: Double;
begin
  Result := -1;

  if AValue.Kind in [tkString, tkLString, tkWString, tkUString] then
    Result := IndexOfItemText(AItems, AValue.AsString);

  LIndex := 0;

  while (Result < 0) and (LIndex <= High(AItems)) do
  begin
    if TS4YGridFilter.TryValueToNumber(AValue, LNumber) and
      TS4YGridFilter.TryValueToNumber(AItems[LIndex].Value, LItemNumber) and SameValue(LNumber, LItemNumber) then
      Result := LIndex
    else if AnsiSameText(ValueToText(AValue), ValueToText(AItems[LIndex].Value)) then
      Result := LIndex;

    Inc(LIndex);
  end;
end;

// Returns the result of the comparison of the value of a row with the value of the filter, ACompare as CompareValue.
function CompareMatches(const AOperator: TS4YGridFilterOperator; const ACompare: Integer): Boolean;
begin
  case AOperator of
    gfoEqual:
      Result := ACompare = 0;
    gfoNotEqual:
      Result := ACompare <> 0;
    gfoLess:
      Result := ACompare < 0;
    gfoLessOrEqual:
      Result := ACompare <= 0;
    gfoGreater:
      Result := ACompare > 0;
    gfoGreaterOrEqual:
      Result := ACompare >= 0;
  else
    Result := True;
  end;
end;

{ TS4YGridFilter }

class function TS4YGridFilter.CreateItems(const AItems: TStrings;
  const AValueKind: TS4YGridFilterValueKind): TArray<TS4YGridFilterItem>;
var
  LHasValues: Boolean;
  LValue: TValue;
begin
  Result := nil;

  if not Assigned(AItems) then
    Exit;

  LHasValues := False;

  for var I := 0 to AItems.Count - 1 do
    if AItems.Names[I] <> '' then
      LHasValues := True;

  // A list of texts: the texts are the values.
  if not LHasValues then
    Exit;

  SetLength(Result, AItems.Count);

  for var I := 0 to AItems.Count - 1 do
  begin
    if AItems.Names[I] <> '' then
    begin
      Result[I].Text := AItems.Names[I];
      Result[I].Value := AItems.ValueFromIndex[I];
    end
    else
    begin
      Result[I].Text := AItems[I];
      Result[I].Value := AItems[I];
    end;

    // A value that cannot be read for the column stays a text.
    if TryTextToValue(Result[I].Value.AsString, AValueKind, LValue) then
      Result[I].Value := LValue;
  end;
end;

class function TS4YGridFilter.DefaultOperator(const AKind: TS4YGridFilterValueKind): TS4YGridFilterOperator;
begin
  if AKind = gvkText then
    Result := gfoContains
  else
    Result := gfoEqual;
end;

class function TS4YGridFilter.FormatText(const AKind: TS4YGridFilterValueKind;
  const AOperator: TS4YGridFilterOperator; const AValue: TValue; const Explicit: Boolean;
  const AItems: TArray<TS4YGridFilterItem>): string;
var
  LValue: string;
  LIndex: Integer;
begin
  case AOperator of
    gfoNone:
      Exit('');
    gfoEmpty:
      Exit(C_SYMBOL_EMPTY);
    gfoNotEmpty:
      Exit('<>');
  end;

  LValue := '';
  LIndex := -1;

  // A value of a list of texts and values is written as the text of its item.
  if not IsValueEmpty(AValue) and (Length(AItems) > 0) then
    LIndex := IndexOfItemValue(AItems, AValue);

  if LIndex >= 0 then
    LValue := FormatValue(gvkText, AItems[LIndex].Text)
  else if not IsValueEmpty(AValue) then
    LValue := FormatValue(AKind, AValue);

  // The default operator is written only when it is chosen.
  if not Explicit and (AOperator = DefaultOperator(AKind)) then
    Exit(LValue);

  case AOperator of
    gfoContains:
      if LValue = '' then
        Result := ''
      else
        Result := C_WILDCARD + LValue + C_WILDCARD;
    gfoStartsWith:
      if LValue = '' then
        Result := ''
      else
        Result := LValue + C_WILDCARD;
    gfoEndsWith:
      if LValue = '' then
        Result := ''
      else
        Result := C_WILDCARD + LValue;
    gfoNotContains:
      Result := C_SYMBOL_NOT + ' ' + LValue;
    gfoEqual:
      Result := '= ' + LValue;
    gfoNotEqual:
      Result := '<> ' + LValue;
    gfoLess:
      Result := '< ' + LValue;
    gfoLessOrEqual:
      Result := '<= ' + LValue;
    gfoGreater:
      Result := '> ' + LValue;
    gfoGreaterOrEqual:
      Result := '>= ' + LValue;
  else
    Result := LValue;
  end;
end;

class function TS4YGridFilter.IsOperatorAllowed(const AKind: TS4YGridFilterValueKind;
  const AOperator: TS4YGridFilterOperator): Boolean;
begin
  case AKind of
    gvkText:
      Result := not (AOperator in [gfoLess, gfoLessOrEqual, gfoGreater, gfoGreaterOrEqual]);
    gvkList, gvkBoolean:
      Result := AOperator in [gfoNone, gfoEqual, gfoNotEqual, gfoEmpty, gfoNotEmpty];
  else
    Result := not (AOperator in [gfoContains, gfoNotContains, gfoStartsWith, gfoEndsWith]);
  end;
end;

class function TS4YGridFilter.IsValueEmpty(const AValue: TValue): Boolean;
begin
  if AValue.IsEmpty then
    Result := True
  else if AValue.Kind = tkVariant then
    Result := VarIsNull(AValue.AsVariant) or VarIsEmpty(AValue.AsVariant) or (VarToStr(AValue.AsVariant) = '')
  else if AValue.Kind in [tkString, tkLString, tkWString, tkUString, tkChar, tkWChar] then
    Result := AValue.ToString = ''
  else
    Result := False;
end;

function TS4YGridFilter.IsActive: Boolean;
begin
  Result := State = gfsValid;
end;

function TS4YGridFilter.Matches(const AValue: TValue): Boolean;
var
  LRowText: string;
  LFilterText: string;
  LRowNumber: Double;
  LFilterNumber: Double;
  LRowDate: TDateTime;
  LFilterDate: TDateTime;
  LRowBoolean: Boolean;
  LFilterBoolean: Boolean;
  LCompare: Integer;
  LRowValue: TValue;
  LIndex: Integer;
  LFilter: TS4YGridFilter;
begin
  if State <> gfsValid then
    Exit(True);

  if FilterOperator = gfoEmpty then
    Exit(IsValueEmpty(AValue));

  if FilterOperator = gfoNotEmpty then
    Exit(not IsValueEmpty(AValue));

  // A row without value is different from any value, and does not contain it.
  if IsValueEmpty(AValue) then
    Exit(FilterOperator in [gfoNotEqual, gfoNotContains]);

  // A list of texts and values compares the values, as the column does; a text of an item counts as its value.
  if (Kind = gvkList) and (Length(Items) > 0) then
  begin
    LRowValue := AValue;
    LIndex := -1;

    if AValue.Kind in [tkString, tkLString, tkWString, tkUString] then
      LIndex := IndexOfItemText(Items, AValue.AsString);

    if LIndex >= 0 then
      LRowValue := Items[LIndex].Value;

    LFilter := Self;
    LFilter.Kind := ValueKind;
    LFilter.Items := nil;
    Exit(LFilter.Matches(LRowValue));
  end;

  case Kind of
    gvkText, gvkList:
      begin
        LRowText := AnsiUpperCase(ValueToText(AValue));
        LFilterText := AnsiUpperCase(ValueToText(Value));

        case FilterOperator of
          gfoContains:
            Result := LRowText.Contains(LFilterText);
          gfoNotContains:
            Result := not LRowText.Contains(LFilterText);
          gfoStartsWith:
            Result := LRowText.StartsWith(LFilterText);
          gfoEndsWith:
            Result := LRowText.EndsWith(LFilterText);
          gfoEqual:
            Result := LRowText = LFilterText;
          gfoNotEqual:
            Result := LRowText <> LFilterText;
        else
          Result := True;
        end;
      end;
    gvkInteger, gvkFloat:
      begin
        if not TryValueToNumber(AValue, LRowNumber) or not TryValueToNumber(Value, LFilterNumber) then
          Exit(True);

        Result := CompareMatches(FilterOperator, CompareValue(LRowNumber, LFilterNumber));
      end;
    gvkDate:
      begin
        if not TryValueToDateTime(AValue, LRowDate) or not TryValueToDateTime(Value, LFilterDate) then
          Exit(True);

        // Only the day: the time of a column of date and time is not compared.
        Result := CompareMatches(FilterOperator, CompareValue(Trunc(LRowDate), Trunc(LFilterDate)));
      end;
    gvkTime:
      begin
        if not TryValueToDateTime(AValue, LRowDate) or not TryValueToDateTime(Value, LFilterDate) then
          Exit(True);

        // Only the time, to the millisecond.
        Result := CompareMatches(FilterOperator, CompareValue(Round(Frac(LRowDate) * MSecsPerDay),
          Round(Frac(LFilterDate) * MSecsPerDay)));
      end;
    gvkBoolean:
      begin
        if not TryValueToBoolean(AValue, LRowBoolean) or not TryValueToBoolean(Value, LFilterBoolean) then
          Exit(True);

        LCompare := Ord(LRowBoolean) - Ord(LFilterBoolean);
        Result := CompareMatches(FilterOperator, LCompare);
      end;
  else
    Result := True;
  end;
end;

class function TS4YGridFilter.Parse(const AText: string; const AKind: TS4YGridFilterValueKind;
  const AItems: TArray<TS4YGridFilterItem>; const AValueKind: TS4YGridFilterValueKind): TS4YGridFilter;
var
  LSymbol: string;
  LRest: string;
  LText: string;
  LLeadingWildcard: Boolean;
  LTrailingWildcard: Boolean;
  LValue: TValue;
  LIndex: Integer;
begin
  Result.ExplicitOperator := False;
  Result.Items := AItems;
  Result.ValueKind := AValueKind;
  Result.Kind := AKind;
  Result.FilterOperator := gfoNone;
  Result.State := gfsEmpty;
  Result.Text := AText;
  Result.Value := TValue.Empty;
  Result.ValueText := '';

  if AText.Trim = '' then
    Exit;

  LRest := SplitOperator(AText.Trim, LSymbol);
  Result.ExplicitOperator := LSymbol <> '';

  // = and <> alone: a row without value, a row with a value.
  if (LRest = '') and (LSymbol = C_SYMBOL_EMPTY) then
  begin
    Result.FilterOperator := gfoEmpty;
    Result.State := gfsValid;
    Exit;
  end;

  if (LRest = '') and (SymbolToOperator(LSymbol, AKind) = gfoNotEqual) and (LSymbol <> C_SYMBOL_NOT) then
  begin
    Result.FilterOperator := gfoNotEmpty;
    Result.State := gfsValid;
    Exit;
  end;

  if not ReadValue(LRest, LText, LLeadingWildcard, LTrailingWildcard) then
  begin
    Result.ValueText := LRest;

    if LSymbol <> '' then
      Result.FilterOperator := SymbolToOperator(LSymbol, AKind)
    else
      Result.FilterOperator := DefaultOperator(AKind);

    Result.State := gfsInvalid;
    Exit;
  end;

  Result.ValueText := LText;
  Result.ExplicitOperator := Result.ExplicitOperator or LLeadingWildcard or LTrailingWildcard;

  // The * at the sides are the operator of a text without operator.
  if LSymbol <> '' then
    Result.FilterOperator := SymbolToOperator(LSymbol, AKind)
  else if LLeadingWildcard and LTrailingWildcard then
    Result.FilterOperator := gfoContains
  else if LLeadingWildcard then
    Result.FilterOperator := gfoEndsWith
  else if LTrailingWildcard then
    Result.FilterOperator := gfoStartsWith
  else
    Result.FilterOperator := DefaultOperator(AKind);

  if ((LSymbol <> '') and (LLeadingWildcard or LTrailingWildcard)) or
    not IsOperatorAllowed(AKind, Result.FilterOperator) then
    Result.State := gfsInvalid
  else if LText = '' then
    Result.State := gfsIncomplete
  else if (AKind = gvkList) and (Length(AItems) > 0) then
  begin
    // Only the texts of the items: the filter gets the value of the item.
    LIndex := IndexOfItemText(AItems, LText);

    if LIndex >= 0 then
    begin
      Result.ValueText := AItems[LIndex].Text;
      Result.Value := AItems[LIndex].Value;
      Result.State := gfsValid;
    end
    else
      Result.State := gfsInvalid;
  end
  else if TryTextToValue(LText, AKind, LValue) then
  begin
    Result.Value := LValue;
    Result.State := gfsValid;
  end
  else
    Result.State := gfsInvalid;
end;

class function TS4YGridFilter.TryValueToNumber(const AValue: TValue; out ANumber: Double): Boolean;
var
  LVariant: Variant;
begin
  Result := True;

  case AValue.Kind of
    tkInteger, tkInt64:
      ANumber := AValue.AsInt64;
    tkFloat:
      ANumber := AValue.AsExtended;
    tkString, tkLString, tkWString, tkUString:
      Result := TryStrToFloat(AValue.AsString, ANumber);
    tkVariant:
      begin
        LVariant := AValue.AsVariant;

        if VarIsNumeric(LVariant) then
          ANumber := LVariant
        else if VarIsStr(LVariant) then
          Result := TryStrToFloat(VarToStr(LVariant), ANumber)
        else
          Result := False;
      end;
  else
    Result := False;
  end;
end;

{ TS4YGridFilterMenuItems }

constructor TS4YGridFilterMenuItems.Create(const AColumn: TColumn);
begin
  inherited Create;

  FColumn := AColumn;
  FItems := TObjectList<TS4YGridFilterMenuItem>.Create;
end;

destructor TS4YGridFilterMenuItems.Destroy;
begin
  FItems.Free;

  inherited;
end;

function TS4YGridFilterMenuItems.Add(const AText: string; const AOnClick: TNotifyEvent): TS4YGridFilterMenuItem;
begin
  Result := Insert(FItems.Count, AText, AOnClick);
end;

function TS4YGridFilterMenuItems.AddAction(const AAction: TS4YGridFilterMenuAction;
  const AText: string): TS4YGridFilterMenuItem;
begin
  Result := Insert(FItems.Count, AText, nil);
  Result.Action := AAction;
end;

function TS4YGridFilterMenuItems.AddSeparator: TS4YGridFilterMenuItem;
begin
  Result := AddAction(gmaSeparator, '');
end;

procedure TS4YGridFilterMenuItems.Clear;
begin
  FItems.Clear;
end;

procedure TS4YGridFilterMenuItems.Delete(const AIndex: Integer);
begin
  FItems.Delete(AIndex);
end;

function TS4YGridFilterMenuItems.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TS4YGridFilterMenuItems.GetItem(const AIndex: Integer): TS4YGridFilterMenuItem;
begin
  Result := FItems[AIndex];
end;

function TS4YGridFilterMenuItems.IndexOfAction(const AAction: TS4YGridFilterMenuAction): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  LIndex := 0;

  while (Result < 0) and (LIndex < FItems.Count) do
  begin
    if FItems[LIndex].Action = AAction then
      Result := LIndex;

    Inc(LIndex);
  end;
end;

function TS4YGridFilterMenuItems.Insert(const AIndex: Integer; const AText: string;
  const AOnClick: TNotifyEvent): TS4YGridFilterMenuItem;
begin
  Result := TS4YGridFilterMenuItem.Create;
  Result.Action := gmaCustom;
  Result.Column := FColumn;
  Result.Text := AText;
  Result.OnClick := AOnClick;
  FItems.Insert(AIndex, Result);
end;

end.
