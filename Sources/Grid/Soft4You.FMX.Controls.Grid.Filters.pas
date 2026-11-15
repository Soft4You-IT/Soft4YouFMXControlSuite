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
  System.Rtti,
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

    /// <summary>Returns the operator of a text without operator for AKind: contains for text, equal otherwise.</summary>
    class function DefaultOperator(const AKind: TS4YGridFilterValueKind): TS4YGridFilterOperator; static;
    /// <summary>
    /// Returns the text of a filter with AOperator and AValue, in the form the grid writes: the operator, a space and
    /// the value, between double quotes when it needs them.
    /// </summary>
    /// <remarks>
    /// Explicit False leaves out the default operator; True writes it too, as for a choice in the menu. An empty
    /// AValue writes only the operator, so that the user writes the value after it.
    /// </remarks>
    class function FormatText(const AKind: TS4YGridFilterValueKind; const AOperator: TS4YGridFilterOperator;
      const AValue: TValue; const Explicit: Boolean): string; static;
    /// <summary>Returns True when AOperator can be used for AKind.</summary>
    class function IsOperatorAllowed(const AKind: TS4YGridFilterValueKind;
      const AOperator: TS4YGridFilterOperator): Boolean; static;
    /// <summary>Returns True when AValue is empty: no value, an empty text, a Null or Unassigned variant.</summary>
    class function IsValueEmpty(const AValue: TValue): Boolean; static;
    /// <summary>Returns the filter written as AText in a column of AKind.</summary>
    class function Parse(const AText: string; const AKind: TS4YGridFilterValueKind): TS4YGridFilter; static;
    /// <summary>Returns in ANumber the number in AValue: an integer, a float, a variant or a text that is a number.</summary>
    class function TryValueToNumber(const AValue: TValue; out ANumber: Double): Boolean; static;

    /// <summary>Returns True when the filter is applied: State is gfsValid.</summary>
    function IsActive: Boolean;
    /// <summary>
    /// Returns True when the value of a row, AValue, passes the filter; always True when the filter is not applied, or
    /// when AValue cannot be compared with the value of the filter.
    /// </summary>
    function Matches(const AValue: TValue): Boolean;
  end;

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

class function TS4YGridFilter.DefaultOperator(const AKind: TS4YGridFilterValueKind): TS4YGridFilterOperator;
begin
  if AKind = gvkText then
    Result := gfoContains
  else
    Result := gfoEqual;
end;

class function TS4YGridFilter.FormatText(const AKind: TS4YGridFilterValueKind;
  const AOperator: TS4YGridFilterOperator; const AValue: TValue; const Explicit: Boolean): string;
var
  LValue: string;
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

  if not IsValueEmpty(AValue) then
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

class function TS4YGridFilter.Parse(const AText: string; const AKind: TS4YGridFilterValueKind): TS4YGridFilter;
var
  LSymbol: string;
  LRest: string;
  LText: string;
  LLeadingWildcard: Boolean;
  LTrailingWildcard: Boolean;
  LValue: TValue;
begin
  Result.Kind := AKind;
  Result.FilterOperator := gfoNone;
  Result.State := gfsEmpty;
  Result.Text := AText;
  Result.Value := TValue.Empty;

  if AText.Trim = '' then
    Exit;

  LRest := SplitOperator(AText.Trim, LSymbol);

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
    if LSymbol <> '' then
      Result.FilterOperator := SymbolToOperator(LSymbol, AKind)
    else
      Result.FilterOperator := DefaultOperator(AKind);

    Result.State := gfsInvalid;
    Exit;
  end;

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

end.
