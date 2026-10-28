unit Soft4You.HTML.Parser;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YHTMLEditor - WYSIWYG HTML editor
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.UIConsts,
  System.Math,
  System.Generics.Collections,
  Soft4You.HTML.Types,
  Soft4You.HTML.Document,
  Soft4You.HTML.Colors;

type

  // ===========================================================================
  // TS4YHTMLParser
  // ===========================================================================

  /// <summary>Converts HTML text into a TS4YHTMLDocument.</summary>
  TS4YHTMLParser = class
  private
    type
      // What the parser knows about a table while it reads it; kept for the outer table when another one starts in a cell
      TTableState = record
        TableID: Integer;
        Row: Integer;
        Column: Integer;
        Columns: Integer;
        Covered: TArray<Integer>;
        RowOpen: Boolean;
        InTable: Boolean;
        CellOpen: Boolean;
        CellIsHeader: Boolean;
        CellRow: Integer;
        CellColumn: Integer;
        CellColSpan: Integer;
        CellRowSpan: Integer;
        CellParagraphCount: Integer;
        CellWidth: TS4YTableLength;
        CellBackground: TAlphaColor;
        CellPadding: TS4YTablePadding;
        CellVerticalAlignment: TS4YTableVerticalAlignment;
        CellBorders: TS4YTableBorders;
        TableBackground: TAlphaColor;
        TablePadding: TS4YTablePadding;
        CellStylePushed: Boolean;
        TableStylePushed: Boolean;
        CellAlignment: TS4YHTMLAlignment;
        CellHasAlignment: Boolean;
        TableTextAlignment: TS4YHTMLAlignment;
        TableHasTextAlignment: Boolean;
        Containers: TArray<TS4YTableCellReference>;
        Width: TS4YTableLength;
        MaximumWidth: Single;
        Alignment: TS4YHTMLAlignment;
        HasBorder: Boolean;
        CellSpacing: Single;
        CellBlockBase: Integer;
        TableBlockBase: Integer;
      end;
      // A block whose style was looked at: its tag and whether a text style was pushed for it
      TBlockStyleEntry = record
        Tag: string;
        IsPushed: Boolean;
      end;
  private
    FInput: string;
    FPosition: Integer;
    FLength: Integer;
    FDocument: TS4YHTMLDocument;
    FStyleStack: TList<TS4YHTMLTextStyle>;
    FBorderColorStack: TList<TAlphaColor>;
    FCurrentParagraph: TS4YHTMLParagraph;
    FListDepth: Integer;
    FInOrderedList: Boolean;
    FOrderedListCounter: Integer;
    FTableID: Integer;
    FTableRow: Integer;
    FTableColumn: Integer;
    FTableColumns: Integer;
    FTableCovered: TArray<Integer>;  // rows still covered in each column by a cell started in a previous row
    FTableRowOpen: Boolean;
    FInTable: Boolean;
    FCellOpen: Boolean;  // between a td/th and its end: the paragraphs that end now belong to the cell
    FCellIsHeader: Boolean;
    FCellRow: Integer;
    FCellColumn: Integer;
    FCellColSpan: Integer;
    FCellRowSpan: Integer;
    FCellParagraphCount: Integer;  // paragraphs added to the open cell so far
    FTableContainers: TArray<TS4YTableCellReference>;  // cells that contain the table being read, outermost first
    FTableWidth: TS4YTableLength;  // width, maximum width, alignment, border and cell spacing of the table being read
    FTableMaximumWidth: Single;
    FTableAlignment: TS4YHTMLAlignment;
    FTableHasBorder: Boolean;
    FTableCellSpacing: Single;
    FCellWidth: TS4YTableLength;  // width asked for the open cell
    FCellBackground: TAlphaColor;  // background, padding, vertical alignment and borders of the open cell
    FCellPadding: TS4YTablePadding;
    FCellVerticalAlignment: TS4YTableVerticalAlignment;
    FCellBorders: TS4YTableBorders;
    FTableBackground: TAlphaColor;  // background and padding that the cells of the table being read get by default
    FTablePadding: TS4YTablePadding;
    FBlockStyles: TList<TBlockStyleEntry>;  // the blocks that are open (p, div, h1, li, ...), innermost last
    FCellBlockBase: Integer;  // number of open blocks when the open cell started
    FTableBlockBase: Integer;  // number of open blocks when the table being read started
    FCellStylePushed: Boolean;  // a text style was pushed for the open cell (bold of th, font and color of the cell)
    FTableStylePushed: Boolean;  // a text style was pushed for the table being read
    FCellAlignment: TS4YHTMLAlignment;  // text alignment written on the open cell or inherited from its table
    FCellHasAlignment: Boolean;
    FTableTextAlignment: TS4YHTMLAlignment;  // text alignment written on the table being read
    FTableHasTextAlignment: Boolean;
    FTableStack: TList<TTableState>;  // the outer tables, while a table nested in one of their cells is read
    FInPreformatted: Boolean;
    FDivAlignment: TS4YHTMLAlignment;

    function PeekChar: Char; inline;
    function ReadChar: Char; inline;
    procedure SkipUntil(const AText: string);
    function ReadTag(out ATagName, AAttributes: string; out IsClose, IsSelf: Boolean): Boolean;
    function ReadTextNode: string;
    function GetAttribute(const AAttributes, AName: string): string;
    function ExtractCSSValue(const ACSS, AProp: string): string;
    function ParseColor(const AText: string): TAlphaColor;
    function ParseFontSize(const AText: string; ABaseSize: Single): Single;
    procedure ParseInlineStyle(const ACSS: string; var ATextStyle: TS4YHTMLTextStyle);
    function ExtractBorderColor(const ACSS: string): TAlphaColor;
    procedure FlushParagraph;
    procedure EndTableRow;
    procedure EndTableCell;
    procedure EnterNestedTable;
    procedure LeaveNestedTable;
    procedure AddParagraph(AParagraph: TS4YHTMLParagraph);
    function ParseTableSpan(const AAttributes, AName: string): Integer;
    function ParseTableLength(const AText: string): TS4YTableLength;
    procedure ReadTableAttributes(const AAttributes: string);
    procedure ReadCellAttributes(const AAttributes: string);
    function ParseBackgroundColor(const AAttributes: string): TAlphaColor;
    function ParsePadding(const AStyle: string): TS4YTablePadding;
    function SplitCSSValue(const AText: string): TArray<string>;
    function ParseBorderLineStyle(const AText: string): Integer;
    function ParseBorderWidth(const AText: string; out AWidth: Single): Boolean;
    function ParseBorders(const AStyle: string): TS4YTableBorders;
    function ParseTextStyleOfBlock(const AStyle: string; var ATextStyle: TS4YHTMLTextStyle): Boolean;
    function ParseTextAlignment(const AText: string; out AAlignment: TS4YHTMLAlignment): Boolean;
    function IsBlockStyleTag(const ATag: string): Boolean;
    procedure OpenBlockStyle(const ATag, AAttributes: string);
    procedure CloseBlockStyle(const ATag: string);
    procedure UnwindBlockStyles(ABase: Integer);
    procedure EnsureParagraph(ABlockType: TS4YHTMLBlockType = btBodyText);
    procedure PushStyle(const ATextStyle: TS4YHTMLTextStyle; ABorderColor: TAlphaColor = claNull);
    procedure PopStyle;
    function TopStyle: TS4YHTMLTextStyle;
    function TopBorderColor: TAlphaColor;
    procedure HandleTag(const ATag, AAttributes: string; IsClose, IsSelf: Boolean);
    procedure AddTextRun(const AText: string);
    function HtmlDecode(const AText: string): string;
    function BaseStyle: TS4YHTMLTextStyle;
  public
    /// <summary>
    /// Parses a fragment of HTML.
    /// </summary>
    /// <param name="AHTML">HTML to parse.</param>
    /// <returns>A new document that the caller owns and must free. It has at least one paragraph, also for an empty input.</returns>
    function Parse(const AHTML: string): TS4YHTMLDocument;
  end;

implementation

const
  C_MAXIMUM_TABLE_SPAN = 100;

// -----------------------------------------------------------------------------
// TS4YHTMLParser
// -----------------------------------------------------------------------------

function TS4YHTMLParser.BaseStyle: TS4YHTMLTextStyle;
begin
  Result.Init;
end;

function TS4YHTMLParser.TopStyle: TS4YHTMLTextStyle;
begin
  if FStyleStack.Count > 0 then
    Result := FStyleStack.Last
  else
    Result := BaseStyle;
end;

procedure TS4YHTMLParser.PushStyle(const ATextStyle: TS4YHTMLTextStyle; ABorderColor: TAlphaColor);
begin
  FStyleStack.Add(ATextStyle);
  FBorderColorStack.Add(ABorderColor);
end;

procedure TS4YHTMLParser.PopStyle;
begin
  if FStyleStack.Count > 0 then
  begin
    FStyleStack.Delete(FStyleStack.Count - 1);
    FBorderColorStack.Delete(FBorderColorStack.Count - 1);
  end;
end;

function TS4YHTMLParser.TopBorderColor: TAlphaColor;
begin
  if FBorderColorStack.Count > 0 then
    Result := FBorderColorStack.Last
  else
    Result := claNull;
end;

function TS4YHTMLParser.PeekChar: Char;
begin
  if FPosition <= FLength then
    Result := FInput[FPosition]
  else
    Result := #0;
end;

function TS4YHTMLParser.ReadChar: Char;
begin
  if FPosition <= FLength then
  begin
    Result := FInput[FPosition];
    Inc(FPosition);
  end
  else
    Result := #0;
end;

procedure TS4YHTMLParser.SkipUntil(const AText: string);
var
  LFoundIndex: Integer;
begin
  LFoundIndex := FInput.IndexOf(AText, FPosition - 1);

  if LFoundIndex >= 0 then
    FPosition := LFoundIndex + Length(AText) + 1
  else
    FPosition := FLength + 1;
end;

function TS4YHTMLParser.ReadTag(out ATagName, AAttributes: string; out IsClose, IsSelf: Boolean): Boolean;
var
  LStringBuilder: TStringBuilder;
  LChar: Char;
  LInQuoteChar: Char;
  LFoundEnd: Boolean;
begin
  Inc(FPosition);

  if FPosition > FLength then
    Exit(False);

  IsClose := PeekChar = '/';

  if IsClose then
    Inc(FPosition);

  LStringBuilder := TStringBuilder.Create;
  try
    while (FPosition <= FLength) and not CharInSet(PeekChar, ['>', '/', ' ', #9, #10, #13]) do
      LStringBuilder.Append(ReadChar);

    ATagName := LStringBuilder.ToString.ToLower;
    LStringBuilder.Clear;

    // HTML comments: skip until --> without quote tracking, which avoids
    // apostrophes in comment text being misread as attribute delimiters.
    if ATagName = '!--' then
    begin
      SkipUntil('-->');
      AAttributes := '';
      IsSelf := False;
      Result := ATagName <> '';
      Exit;
    end;

    LInQuoteChar := #0;
    LFoundEnd := False;

    while (FPosition <= FLength) and not LFoundEnd do
    begin
      LChar := ReadChar;

      if LInQuoteChar <> #0 then
      begin
        if LChar = LInQuoteChar then
          LInQuoteChar := #0;

        LStringBuilder.Append(LChar);
      end
      else if CharInSet(LChar, ['"', '''']) then
      begin
        LInQuoteChar := LChar;
        LStringBuilder.Append(LChar);
      end
      else if LChar = '>' then
        LFoundEnd := True
      else
        LStringBuilder.Append(LChar);
    end;

    AAttributes := LStringBuilder.ToString.Trim;
    IsSelf := (AAttributes.EndsWith('/')) or (ATagName = 'br') or (ATagName = 'hr') or (ATagName = 'img');

    if AAttributes.EndsWith('/') then
      AAttributes := AAttributes.Substring(0, AAttributes.Length - 1).Trim;

    Result := ATagName <> '';
  finally
    LStringBuilder.Free;
  end;
end;

function TS4YHTMLParser.ReadTextNode: string;
var
  LStringBuilder: TStringBuilder;
  LChar: Char;
begin
  LStringBuilder := TStringBuilder.Create;
  try
    while (FPosition <= FLength) and (PeekChar <> '<') do
    begin
      LChar := ReadChar;
      LStringBuilder.Append(LChar);
    end;

    Result := HtmlDecode(LStringBuilder.ToString);
  finally
    LStringBuilder.Free;
  end;
end;

function TS4YHTMLParser.GetAttribute(const AAttributes, AName: string): string;
var
  LScanPosition, LValueEnd, LAttributeLength: Integer;
  LQuoteChar: Char;
  LNameWithEquals: string;
  LAttributesLower: string;
begin
  Result := '';
  LNameWithEquals := AName.ToLower + '=';
  LAttributesLower := AAttributes.ToLower;
  LAttributeLength := LAttributesLower.Length;
  LScanPosition := 0;

  while LScanPosition < LAttributeLength do
  begin
    // Skip whitespace between attributes
    while (LScanPosition < LAttributeLength) and CharInSet(LAttributesLower[Low(LAttributesLower) + LScanPosition], [' ', #9, #10, #13]) do
      Inc(LScanPosition);

    if LScanPosition >= LAttributeLength then
      Exit;

    // Try to match the attribute name at this exact token boundary
    if LAttributesLower.Substring(LScanPosition, LNameWithEquals.Length) = LNameWithEquals then
    begin
      Inc(LScanPosition, LNameWithEquals.Length);

      if LScanPosition >= LAttributeLength then
        Exit;

      LQuoteChar := LAttributesLower[Low(LAttributesLower) + LScanPosition];

      if CharInSet(LQuoteChar, ['"', '''']) then
      begin
        Inc(LScanPosition); // skip opening quote
        LValueEnd := LScanPosition;

        while (LValueEnd < LAttributeLength) and (LAttributesLower[Low(LAttributesLower) + LValueEnd] <> LQuoteChar) do
          Inc(LValueEnd);

        Result := AAttributes.Substring(LScanPosition, LValueEnd - LScanPosition);
      end
      else
      begin
        LValueEnd := LScanPosition;

        while (LValueEnd < LAttributeLength) and not CharInSet(LAttributesLower[Low(LAttributesLower) + LValueEnd], [' ', '>']) do
          Inc(LValueEnd);

        Result := AAttributes.Substring(LScanPosition, LValueEnd - LScanPosition);
      end;

      Exit;
    end;

    // Not this attribute -- skip its name
    while (LScanPosition < LAttributeLength) and not CharInSet(LAttributesLower[Low(LAttributesLower) + LScanPosition], [' ', '=']) do
      Inc(LScanPosition);

    // Skip optional =value
    if (LScanPosition < LAttributeLength) and (LAttributesLower[Low(LAttributesLower) + LScanPosition] = '=') then
    begin
      Inc(LScanPosition); // skip '='

      if (LScanPosition < LAttributeLength) and CharInSet(LAttributesLower[Low(LAttributesLower) + LScanPosition], ['"', '''']) then
      begin
        LQuoteChar := LAttributesLower[Low(LAttributesLower) + LScanPosition];
        Inc(LScanPosition); // skip opening quote
        // Skip until closing quote -- this prevents matching inside attribute values
        while (LScanPosition < LAttributeLength) and (LAttributesLower[Low(LAttributesLower) + LScanPosition] <> LQuoteChar) do
          Inc(LScanPosition);

        if LScanPosition < LAttributeLength then
          Inc(LScanPosition); // skip closing quote
      end
      else
      begin
        while (LScanPosition < LAttributeLength) and not CharInSet(LAttributesLower[Low(LAttributesLower) + LScanPosition], [' ', '>']) do
          Inc(LScanPosition);
      end;
    end;
  end;
end;

function TS4YHTMLParser.ExtractCSSValue(const ACSS, AProp: string): string;
var
  LParts: TArray<string>;
  LPair: TArray<string>;
  LPart: string;
begin
  Result := '';
  LParts := ACSS.Split([';']);

  for LPart in LParts do
  begin
    LPair := LPart.Split([':'], 2);

    if (Length(LPair) >= 2) and (TrimS(LPair[0]) = AProp) then
    begin
      Result := TrimS(LPair[1]);
      Exit;
    end;
  end;
end;

function TS4YHTMLParser.ParseColor(const AText: string): TAlphaColor;
begin
  if not HTMLColorToAlphaColor(AText, Result) then
    Result := claNull;
end;

function TS4YHTMLParser.ParseFontSize(const AText: string; ABaseSize: Single): Single;
var
  LValue: string;
  LNumericValue: Single;
begin
  Result := ABaseSize;
  LValue := TrimS(AText.ToLower);

  if LValue = '' then
    Exit;

  if LValue.EndsWith('pt') then
    Result := StrToFloatDef(TrimS(LValue.Replace('pt', '')), ABaseSize)
  else if LValue.EndsWith('px') then
    Result := StrToFloatDef(TrimS(LValue.Replace('px', '')), ABaseSize * 1.33) / 1.33
  else if LValue.EndsWith('em') then
    Result := ABaseSize * StrToFloatDef(TrimS(LValue.Replace('em', '')), 1)
  else if LValue.EndsWith('%') then
    Result := ABaseSize * StrToFloatDef(TrimS(LValue.Replace('%', '')), 100) / 100
  else
  begin
    LNumericValue := StrToFloatDef(LValue, 0);

    if LNumericValue > 0 then
      Result := LNumericValue;
  end;
end;

procedure TS4YHTMLParser.ParseInlineStyle(const ACSS: string; var ATextStyle: TS4YHTMLTextStyle);
var
  LParts: TArray<string>;
  LPair: TArray<string>;
  LProp: string;
  LPropertyValue: string;
  LPart: string;
  LColor: TAlphaColor;
begin
  LParts := ACSS.Split([';']);

  for LPart in LParts do
  begin
    LPair := LPart.Split([':'], 2);

    if Length(LPair) >= 2 then
    begin
      LProp := TrimS(LPair[0].ToLower);
      LPropertyValue := TrimS(LPair[1]);

      if LProp = 'font-family' then
        ATextStyle.FontName := LPropertyValue.Trim(['"', '''', ' '])
      else if LProp = 'font-size' then
        ATextStyle.FontSize := ParseFontSize(LPropertyValue, ATextStyle.FontSize)
      else if LProp = 'font-weight' then
      begin
        if (LPropertyValue.ToLower = 'bold') or (LPropertyValue = '700') or (LPropertyValue = '800') or (LPropertyValue = '900') then
          ATextStyle.Bold := True
        else
          ATextStyle.Bold := False;
      end
      else if LProp = 'font-style' then
        ATextStyle.Italic := (LPropertyValue.ToLower = 'italic') or (LPropertyValue.ToLower = 'oblique')
      else if LProp = 'text-decoration' then
      begin
        ATextStyle.Underline := LPropertyValue.ToLower.Contains('underline');
        ATextStyle.StrikeOut := LPropertyValue.ToLower.Contains('line-through');
      end
      else if LProp = 'color' then
      begin
        LColor := ParseColor(LPropertyValue);

        if LColor <> claNull then
          ATextStyle.Color := LColor;
      end
      else if (LProp = 'background-color') or (LProp = 'background') then
      begin
        LColor := ParseColor(LPropertyValue);

        if LColor <> claNull then
          ATextStyle.BackgroundColor := LColor;
      end;
    end;
  end;
end;

function TS4YHTMLParser.ExtractBorderColor(const ACSS: string): TAlphaColor;
var
  LColorValue: string;
  LBorderValue: string;
  LParts: TArray<string>;
  LPart: string;
  LCandidate: TAlphaColor;
begin
  Result := claNull;
  LColorValue := ExtractCSSValue(ACSS.ToLower, 'border-color');

  if LColorValue <> '' then
  begin
    Result := ParseColor(LColorValue);

    if Result <> claNull then
      Exit;
  end;

  LBorderValue := ExtractCSSValue(ACSS.ToLower, 'border');

  if LBorderValue = '' then
    Exit;

  LParts := LBorderValue.Trim.Split([' ']);

  for LPart in LParts do
  begin
    LCandidate := ParseColor(TrimS(LPart));

    if LCandidate <> claNull then
    begin
      Result := LCandidate;
      Exit;
    end;
  end;
end;

// Adds a finished paragraph to the document. Inside a cell it becomes a paragraph of the cell.
procedure TS4YHTMLParser.AddParagraph(AParagraph: TS4YHTMLParagraph);
begin
  if FCellOpen then
  begin
    if AParagraph.BlockType in [btBodyText, btParagraph] then
      AParagraph.BlockType := btTableCell;

    AParagraph.TableID := FTableID;
    AParagraph.TableContainers := Copy(FTableContainers);
    AParagraph.TableWidth := FTableWidth;
    AParagraph.TableMaximumWidth := FTableMaximumWidth;
    AParagraph.TableAlignment := FTableAlignment;
    AParagraph.TableHasBorder := FTableHasBorder;
    AParagraph.TableCellSpacing := FTableCellSpacing;
    AParagraph.TableRow := FCellRow;
    AParagraph.TableCol := FCellColumn;
    AParagraph.IsHeader := FCellIsHeader;

    // A text alignment written on the cell (or its table) wins over the centering of a th
    if FCellHasAlignment then
    begin
      if AParagraph.Alignment = haLeft then
        AParagraph.Alignment := FCellAlignment;
    end
    else if FCellIsHeader and (AParagraph.Alignment = haLeft) then
      AParagraph.Alignment := haCenter;

    // The attributes of the cell are kept by its first paragraph
    if FCellParagraphCount = 0 then
    begin
      AParagraph.TableColSpan := FCellColSpan;
      AParagraph.TableRowSpan := FCellRowSpan;
      AParagraph.TableCellWidth := FCellWidth;
      AParagraph.TableCellBackgroundColor := FCellBackground;
      AParagraph.TableCellPadding := FCellPadding;
      AParagraph.TableCellVerticalAlignment := FCellVerticalAlignment;
      AParagraph.TableCellBorders := FCellBorders;
    end;

    Inc(FCellParagraphCount);
  end;

  FDocument.Paragraphs.Add(AParagraph);
end;

// Starts a table inside the open cell: the state of the outer table is kept until the nested one ends.
procedure TS4YHTMLParser.EnterNestedTable;
var
  LState: TTableState;
  LEmptyParagraph: TS4YHTMLParagraph;
  LContainers: TArray<TS4YTableCellReference>;
begin
  // The cell needs a paragraph of its own before the table: it holds the attributes of the cell
  if FCellParagraphCount = 0 then
  begin
    LEmptyParagraph := TS4YHTMLParagraph.Create;
    LEmptyParagraph.BlockType := btTableCell;
    AddParagraph(LEmptyParagraph);
  end;

  LState.TableID := FTableID;
  LState.Row := FTableRow;
  LState.Column := FTableColumn;
  LState.Columns := FTableColumns;
  LState.Covered := FTableCovered;
  LState.RowOpen := FTableRowOpen;
  LState.InTable := FInTable;
  LState.CellOpen := FCellOpen;
  LState.CellIsHeader := FCellIsHeader;
  LState.CellRow := FCellRow;
  LState.CellColumn := FCellColumn;
  LState.CellColSpan := FCellColSpan;
  LState.CellRowSpan := FCellRowSpan;
  LState.CellParagraphCount := FCellParagraphCount;
  LState.CellWidth := FCellWidth;
  LState.CellBackground := FCellBackground;
  LState.CellPadding := FCellPadding;
  LState.CellVerticalAlignment := FCellVerticalAlignment;
  LState.CellBorders := FCellBorders;
  LState.TableBackground := FTableBackground;
  LState.TablePadding := FTablePadding;
  LState.CellStylePushed := FCellStylePushed;
  LState.TableStylePushed := FTableStylePushed;
  LState.CellAlignment := FCellAlignment;
  LState.CellHasAlignment := FCellHasAlignment;
  LState.TableTextAlignment := FTableTextAlignment;
  LState.TableHasTextAlignment := FTableHasTextAlignment;
  LState.CellBlockBase := FCellBlockBase;
  LState.TableBlockBase := FTableBlockBase;
  LState.Containers := FTableContainers;
  LState.Width := FTableWidth;
  LState.MaximumWidth := FTableMaximumWidth;
  LState.Alignment := FTableAlignment;
  LState.HasBorder := FTableHasBorder;
  LState.CellSpacing := FTableCellSpacing;
  FTableStack.Add(LState);
  LContainers := Copy(FTableContainers);
  SetLength(LContainers, Length(LContainers) + 1);
  LContainers[High(LContainers)] := TS4YTableCellReference.At(FTableID, FCellRow, FCellColumn);
  FTableContainers := LContainers;
end;

// Ends a nested table: the outer table and its open cell are current again.
procedure TS4YHTMLParser.LeaveNestedTable;
var
  LState: TTableState;
begin
  LState := FTableStack.Last;
  FTableStack.Delete(FTableStack.Count - 1);
  FTableID := LState.TableID;
  FTableRow := LState.Row;
  FTableColumn := LState.Column;
  FTableColumns := LState.Columns;
  FTableCovered := LState.Covered;
  FTableRowOpen := LState.RowOpen;
  FInTable := LState.InTable;
  FCellOpen := LState.CellOpen;
  FCellIsHeader := LState.CellIsHeader;
  FCellRow := LState.CellRow;
  FCellColumn := LState.CellColumn;
  FCellColSpan := LState.CellColSpan;
  FCellRowSpan := LState.CellRowSpan;
  FCellParagraphCount := LState.CellParagraphCount;
  FCellWidth := LState.CellWidth;
  FCellBackground := LState.CellBackground;
  FCellPadding := LState.CellPadding;
  FCellVerticalAlignment := LState.CellVerticalAlignment;
  FCellBorders := LState.CellBorders;
  FTableBackground := LState.TableBackground;
  FTablePadding := LState.TablePadding;
  FCellStylePushed := LState.CellStylePushed;
  FTableStylePushed := LState.TableStylePushed;
  FCellAlignment := LState.CellAlignment;
  FCellHasAlignment := LState.CellHasAlignment;
  FTableTextAlignment := LState.TableTextAlignment;
  FTableHasTextAlignment := LState.TableHasTextAlignment;
  FCellBlockBase := LState.CellBlockBase;
  FTableBlockBase := LState.TableBlockBase;
  FTableContainers := LState.Containers;
  FTableWidth := LState.Width;
  FTableMaximumWidth := LState.MaximumWidth;
  FTableAlignment := LState.Alignment;
  FTableHasBorder := LState.HasBorder;
  FTableCellSpacing := LState.CellSpacing;
end;

// Closes the open cell. A cell with no content keeps one empty paragraph.
procedure TS4YHTMLParser.EndTableCell;
var
  LEmptyParagraph: TS4YHTMLParagraph;
begin
  if not FCellOpen then
    Exit;

  FlushParagraph;

  if FCellParagraphCount = 0 then
  begin
    LEmptyParagraph := TS4YHTMLParagraph.Create;
    LEmptyParagraph.BlockType := btTableCell;
    AddParagraph(LEmptyParagraph);
  end;

  FCellOpen := False;
  UnwindBlockStyles(FCellBlockBase);

  if FCellStylePushed then
    PopStyle;

  FCellStylePushed := False;
end;

// Closes the current table row: records the width of the row and lets the rowspan cells advance by one row.
procedure TS4YHTMLParser.EndTableRow;
begin
  if not FTableRowOpen then
    Exit;

  FTableRowOpen := False;

  if FTableColumn > FTableColumns then
    FTableColumns := FTableColumn;

  for var LColumn := 0 to High(FTableCovered) do
  begin
    if FTableCovered[LColumn] > 0 then
    begin
      if LColumn + 1 > FTableColumns then
        FTableColumns := LColumn + 1;

      Dec(FTableCovered[LColumn]);
    end;
  end;
end;

// Reads the colspan or rowspan attribute of a cell: 1 when missing or not valid, never above C_MAXIMUM_TABLE_SPAN.
// Reads a width written as 120, 120px, 120pt or 50%. Anything else (auto, em, ...) is a width that is not set.
function TS4YHTMLParser.ParseTableLength(const AText: string): TS4YTableLength;
var
  LText: string;
begin
  Result := TS4YTableLength.Auto;
  LText := TrimS(AText.ToLower);

  if LText = '' then
    Exit;

  if LText.EndsWith('%') then
    Result := TS4YTableLength.Percent(StrToFloatDef(TrimS(LText.Replace('%', '')), 0))
  else if LText.EndsWith('pt') then
    Result := TS4YTableLength.Pixels(StrToFloatDef(TrimS(LText.Replace('pt', '')), 0) * 1.33)
  else if LText.EndsWith('px') then
    Result := TS4YTableLength.Pixels(StrToFloatDef(TrimS(LText.Replace('px', '')), 0))
  else
    Result := TS4YTableLength.Pixels(StrToFloatDef(LText, 0));
end;

// Reads a text alignment written as left, center, right or justify.
function TS4YHTMLParser.ParseTextAlignment(const AText: string; out AAlignment: TS4YHTMLAlignment): Boolean;
var
  LText: string;
begin
  Result := True;
  LText := TrimS(AText.ToLower);

  if LText = 'center' then
    AAlignment := haCenter
  else if LText = 'right' then
    AAlignment := haRight
  else if LText = 'justify' then
    AAlignment := haJustify
  else if LText = 'left' then
    AAlignment := haLeft
  else
    Result := False;
end;

// True for the tags whose style attribute can give a text style to their content.
function TS4YHTMLParser.IsBlockStyleTag(const ATag: string): Boolean;
begin
  Result := (ATag = 'p') or (ATag = 'div') or (ATag = 'blockquote') or (ATag = 'ul') or (ATag = 'ol') or
    (ATag = 'li') or ((Length(ATag) = 2) and (ATag[Low(ATag)] = 'h') and CharInSet(ATag[Low(ATag) + 1], ['1' .. '6']));
end;

// A block starts: the font, size, weight and color of its style apply to its content until it ends. A p or an li
// that is still open ends when the next one starts, as it does in a browser.
procedure TS4YHTMLParser.OpenBlockStyle(const ATag, AAttributes: string);
var
  LEntry: TBlockStyleEntry;
  LTextStyle: TS4YHTMLTextStyle;
begin
  if ((ATag = 'p') or (ATag = 'li')) and (FBlockStyles.Count > 0) and (FBlockStyles.Last.Tag = ATag) then
    CloseBlockStyle(ATag);

  LTextStyle := TopStyle;
  LEntry.Tag := ATag;
  LEntry.IsPushed := ParseTextStyleOfBlock(GetAttribute(AAttributes, 'style'), LTextStyle);

  if LEntry.IsPushed then
    PushStyle(LTextStyle, TopBorderColor);

  FBlockStyles.Add(LEntry);
end;

// A block ends: the blocks that were opened inside it and never closed end with it.
procedure TS4YHTMLParser.CloseBlockStyle(const ATag: string);
var
  LIndex: Integer;
begin
  LIndex := FBlockStyles.Count - 1;

  while (LIndex >= 0) and (FBlockStyles[LIndex].Tag <> ATag) do
    Dec(LIndex);

  if LIndex >= 0 then
    UnwindBlockStyles(LIndex);
end;

// Ends the open blocks from the one at position ABase on, taking back the text styles that they pushed.
procedure TS4YHTMLParser.UnwindBlockStyles(ABase: Integer);
begin
  while FBlockStyles.Count > ABase do
  begin
    if FBlockStyles.Last.IsPushed then
      PopStyle;

    FBlockStyles.Delete(FBlockStyles.Count - 1);
  end;
end;

// Applies the text properties of the style of a block, a cell or a table (font, size, weight, color, ...) to a
// text style. The background properties are left out: on a block they color the block, not the text.
// Returns True when the text style changed.
function TS4YHTMLParser.ParseTextStyleOfBlock(const AStyle: string; var ATextStyle: TS4YHTMLTextStyle): Boolean;
var
  LParts: TArray<string>;
  LPart: string;
  LFiltered: string;
  LBefore: TS4YHTMLTextStyle;
begin
  Result := False;

  if AStyle = '' then
    Exit;

  LFiltered := '';
  LParts := AStyle.Split([';']);

  for LPart in LParts do
    if not TrimS(LPart.ToLower).StartsWith('background') then
      LFiltered := LFiltered + LPart + ';';

  LBefore := ATextStyle;
  ParseInlineStyle(LFiltered, ATextStyle);
  Result := not ATextStyle.EqualsFormat(LBefore);
end;

// Reads the background color of an element from the bgcolor attribute and from the background-color and background
// styles; the style wins. In the background shorthand the first part that is a color is used.
function TS4YHTMLParser.ParseBackgroundColor(const AAttributes: string): TAlphaColor;
var
  LStyle: string;
  LValue: string;
  LPart: string;
  LColor: TAlphaColor;
begin
  Result := ParseColor(GetAttribute(AAttributes, 'bgcolor'));
  LStyle := GetAttribute(AAttributes, 'style').ToLower;

  if LStyle = '' then
    Exit;

  LValue := ExtractCSSValue(LStyle, 'background-color');
  if LValue = '' then
    LValue := ExtractCSSValue(LStyle, 'background');

  for LPart in LValue.Split([' ']) do
  begin
    LColor := ParseColor(LPart);

    if LColor <> claNull then
    begin
      Result := LColor;
      Exit;
    end;
  end;
end;

// Reads the padding of an element from the padding style (one to four values) and the padding-left, padding-top,
// padding-right and padding-bottom styles. A padding that is not written gives a padding that is not set.
function TS4YHTMLParser.ParsePadding(const AStyle: string): TS4YTablePadding;
var
  LTokens: TArray<string>;
  LValue: string;
  LLeft: Single;
  LTop: Single;
  LRight: Single;
  LBottom: Single;
  LIsSet: Boolean;

  function PixelsOf(const AText: string): Single;
  var
    LLength: TS4YTableLength;
  begin
    LLength := ParseTableLength(AText);

    if LLength.Kind = tlkPixels then
      Result := LLength.Value
    else
      Result := 0;
  end;

begin
  LLeft := 0;
  LTop := 0;
  LRight := 0;
  LBottom := 0;
  LIsSet := False;
  LValue := ExtractCSSValue(AStyle, 'padding');

  if LValue <> '' then
  begin
    LTokens := LValue.Split([' ']);
    LIsSet := True;

    case Length(LTokens) of
      1:
        begin
          LTop := PixelsOf(LTokens[0]);
          LRight := LTop;
          LBottom := LTop;
          LLeft := LTop;
        end;
      2:
        begin
          LTop := PixelsOf(LTokens[0]);
          LBottom := LTop;
          LRight := PixelsOf(LTokens[1]);
          LLeft := LRight;
        end;
      3:
        begin
          LTop := PixelsOf(LTokens[0]);
          LRight := PixelsOf(LTokens[1]);
          LLeft := LRight;
          LBottom := PixelsOf(LTokens[2]);
        end;
      4:
        begin
          LTop := PixelsOf(LTokens[0]);
          LRight := PixelsOf(LTokens[1]);
          LBottom := PixelsOf(LTokens[2]);
          LLeft := PixelsOf(LTokens[3]);
        end;
    else
      LIsSet := False;
    end;
  end;

  LValue := ExtractCSSValue(AStyle, 'padding-left');

  if LValue <> '' then
  begin
    LLeft := PixelsOf(LValue);
    LIsSet := True;
  end;

  LValue := ExtractCSSValue(AStyle, 'padding-top');

  if LValue <> '' then
  begin
    LTop := PixelsOf(LValue);
    LIsSet := True;
  end;

  LValue := ExtractCSSValue(AStyle, 'padding-right');

  if LValue <> '' then
  begin
    LRight := PixelsOf(LValue);
    LIsSet := True;
  end;

  LValue := ExtractCSSValue(AStyle, 'padding-bottom');

  if LValue <> '' then
  begin
    LBottom := PixelsOf(LValue);
    LIsSet := True;
  end;

  if LIsSet then
    Result := TS4YTablePadding.Sides(LLeft, LTop, LRight, LBottom)
  else
    Result := TS4YTablePadding.Default;
end;

// Splits the value of a CSS property at the spaces that are not inside parentheses, so that rgb(1, 2, 3) is one token.
function TS4YHTMLParser.SplitCSSValue(const AText: string): TArray<string>;
var
  LTokens: TList<string>;
  LCurrent: string;
  LDepth: Integer;
  LChar: Char;
begin
  LTokens := TList<string>.Create;
  try
    LCurrent := '';
    LDepth := 0;

    for LChar in AText do
    begin
      if LChar = '(' then
      begin
        Inc(LDepth);
      end
      else if LChar = ')' then
      begin
        Dec(LDepth);
      end;

      if (LChar = ' ') and (LDepth <= 0) then
      begin
        if LCurrent <> '' then
        begin
          LTokens.Add(LCurrent);
        end;

        LCurrent := '';
      end
      else
      begin
        LCurrent := LCurrent + LChar;
      end;
    end;

    if LCurrent <> '' then
    begin
      LTokens.Add(LCurrent);
    end;

    Result := LTokens.ToArray;
  finally
    LTokens.Free;
  end;
end;

// Reads the style of a border line: 1 for none and hidden, 2 for a line (solid, dashed, dotted, ...), 0 when the text
// is not a border style. Every kind of line is drawn as a solid one.
function TS4YHTMLParser.ParseBorderLineStyle(const AText: string): Integer;
var
  LText: string;
begin
  LText := TrimS(AText.ToLower);

  if (LText = 'none') or (LText = 'hidden') then
  begin
    Result := 1;
  end
  else if (LText = 'solid') or (LText = 'dashed') or (LText = 'dotted') or (LText = 'double') or
          (LText = 'groove') or (LText = 'ridge') or (LText = 'inset') or (LText = 'outset') then
  begin
    Result := 2;
  end
  else
  begin
    Result := 0;
  end;
end;

// Reads the width of a border written as thin, medium, thick, 2, 2px or 2pt. Zero is a valid width.
function TS4YHTMLParser.ParseBorderWidth(const AText: string; out AWidth: Single): Boolean;
var
  LText: string;
  LFactor: Single;
begin
  Result := True;
  AWidth := 0;
  LText := TrimS(AText.ToLower);

  if LText = 'thin' then
  begin
    AWidth := 1;
  end
  else if LText = 'medium' then
  begin
    AWidth := 3;
  end
  else if LText = 'thick' then
  begin
    AWidth := 5;
  end
  else if (LText <> '') and CharInSet(LText[1], ['0'..'9', '.']) then
  begin
    LFactor := 1;

    if LText.EndsWith('px') then
    begin
      LText := TrimS(LText.Substring(0, Length(LText) - 2));
    end
    else if LText.EndsWith('pt') then
    begin
      LText := TrimS(LText.Substring(0, Length(LText) - 2));
      LFactor := 1.33;
    end;

    AWidth := StrToFloatDef(LText, -1) * LFactor;
    Result := AWidth >= 0;
  end
  else
  begin
    Result := False;
  end;
end;

// Reads the borders of a cell from the border, border-width, border-style, border-color, border-top, border-right,
// border-bottom and border-left styles and from their width, style and color forms (border-top-width, ...).
// A side that is not written keeps the border of its table: the default one when the table has borders, none otherwise.
// No border style at all gives borders that are not set.
function TS4YHTMLParser.ParseBorders(const AStyle: string): TS4YTableBorders;
const
  C_SIDE_NAMES: array[0..3] of string = ('top', 'right', 'bottom', 'left');
var
  LWidth: array[0..3] of Single;
  LLineStyle: array[0..3] of Integer;  // 0 = not written, 1 = none, 2 = a line
  LColor: array[0..3] of TAlphaColor;
  LHasColor: array[0..3] of Boolean;
  LSides: array[0..3] of TS4YTableBorderSide;
  LBase: TS4YTableBorderSide;
  LIsSet: Boolean;
  LValue: string;
  LSide: Integer;

  procedure SetWidth(ASide: Integer; const AText: string);
  var
    LParsed: Single;
  begin
    if ParseBorderWidth(AText, LParsed) then
    begin
      LWidth[ASide] := LParsed;
      LIsSet := True;
    end;
  end;

  procedure SetLineStyle(ASide: Integer; const AText: string);
  begin
    if ParseBorderLineStyle(AText) <> 0 then
    begin
      LLineStyle[ASide] := ParseBorderLineStyle(AText);
      LIsSet := True;
    end;
  end;

  procedure SetColor(ASide: Integer; const AText: string);
  var
    LParsed: TAlphaColor;
  begin
    LParsed := ParseColor(TrimS(AText));

    if LParsed <> claNull then
    begin
      LColor[ASide] := LParsed;
      LHasColor[ASide] := True;
      LIsSet := True;
    end;
  end;

  // border and border-top, ...: the width, the style and the color in any order. What is missing is the initial
  // value of the property: no line, medium width, no color of its own.
  procedure SetShorthand(ASide: Integer; const AText: string);
  var
    LToken: string;
    LParsed: Single;
    LParsedColor: TAlphaColor;
  begin
    LLineStyle[ASide] := 1;
    LWidth[ASide] := 3;
    LHasColor[ASide] := False;

    for LToken in SplitCSSValue(AText) do
    begin
      if ParseBorderWidth(LToken, LParsed) then
      begin
        LWidth[ASide] := LParsed;
      end
      else if ParseBorderLineStyle(LToken) <> 0 then
      begin
        LLineStyle[ASide] := ParseBorderLineStyle(LToken);
      end
      else
      begin
        LParsedColor := ParseColor(LToken);

        if LParsedColor <> claNull then
        begin
          LColor[ASide] := LParsedColor;
          LHasColor[ASide] := True;
        end;
      end;
    end;

    LIsSet := True;
  end;

  // border-width, border-style and border-color: one to four values in the order top, right, bottom, left.
  // AKind is 0 for the width, 1 for the style and 2 for the color.
  procedure SetAllSides(const AText: string; AKind: Integer);
  var
    LTokens: TArray<string>;
    LValues: array[0..3] of string;
    LIndex: Integer;
  begin
    LTokens := SplitCSSValue(AText);

    case Length(LTokens) of
      1:
        begin
          LValues[0] := LTokens[0];
          LValues[1] := LTokens[0];
          LValues[2] := LTokens[0];
          LValues[3] := LTokens[0];
        end;
      2:
        begin
          LValues[0] := LTokens[0];
          LValues[1] := LTokens[1];
          LValues[2] := LTokens[0];
          LValues[3] := LTokens[1];
        end;
      3:
        begin
          LValues[0] := LTokens[0];
          LValues[1] := LTokens[1];
          LValues[2] := LTokens[2];
          LValues[3] := LTokens[1];
        end;
      4:
        begin
          LValues[0] := LTokens[0];
          LValues[1] := LTokens[1];
          LValues[2] := LTokens[2];
          LValues[3] := LTokens[3];
        end;
    else
      Exit;
    end;

    for LIndex := 0 to 3 do
    begin
      case AKind of
        0: SetWidth(LIndex, LValues[LIndex]);
        1: SetLineStyle(LIndex, LValues[LIndex]);
      else
        SetColor(LIndex, LValues[LIndex]);
      end;
    end;
  end;

begin
  LIsSet := False;

  for LSide := 0 to 3 do
  begin
    LWidth[LSide] := -1;
    LLineStyle[LSide] := 0;
    LColor[LSide] := claNull;
    LHasColor[LSide] := False;
  end;

  // From the most general to the most specific, so that the specific form wins
  LValue := ExtractCSSValue(AStyle, 'border');

  if LValue <> '' then
  begin
    for LSide := 0 to 3 do
    begin
      SetShorthand(LSide, LValue);
    end;
  end;

  LValue := ExtractCSSValue(AStyle, 'border-width');

  if LValue <> '' then
  begin
    SetAllSides(LValue, 0);
  end;

  LValue := ExtractCSSValue(AStyle, 'border-style');

  if LValue <> '' then
  begin
    SetAllSides(LValue, 1);
  end;

  LValue := ExtractCSSValue(AStyle, 'border-color');

  if LValue <> '' then
  begin
    SetAllSides(LValue, 2);
  end;

  for LSide := 0 to 3 do
  begin
    LValue := ExtractCSSValue(AStyle, 'border-' + C_SIDE_NAMES[LSide]);

    if LValue <> '' then
    begin
      SetShorthand(LSide, LValue);
    end;

    LValue := ExtractCSSValue(AStyle, 'border-' + C_SIDE_NAMES[LSide] + '-width');

    if LValue <> '' then
    begin
      SetWidth(LSide, LValue);
    end;

    LValue := ExtractCSSValue(AStyle, 'border-' + C_SIDE_NAMES[LSide] + '-style');

    if LValue <> '' then
    begin
      SetLineStyle(LSide, LValue);
    end;

    LValue := ExtractCSSValue(AStyle, 'border-' + C_SIDE_NAMES[LSide] + '-color');

    if LValue <> '' then
    begin
      SetColor(LSide, LValue);
    end;
  end;

  if not LIsSet then
  begin
    Result := TS4YTableBorders.Default;
    Exit;
  end;

  if FTableHasBorder then
  begin
    LBase := TS4YTableBorderSide.Default;
  end
  else
  begin
    LBase := TS4YTableBorderSide.None;
  end;

  for LSide := 0 to 3 do
  begin
    LSides[LSide] := LBase;

    if LLineStyle[LSide] = 1 then
    begin
      LSides[LSide] := TS4YTableBorderSide.None;
    end
    else
    begin
      // A line where the table had none: medium and black until the width and the color say otherwise
      if (LLineStyle[LSide] = 2) and not LSides[LSide].IsVisible then
      begin
        LSides[LSide] := TS4YTableBorderSide.Solid(3, TAlphaColors.Black);
      end;

      if (LWidth[LSide] >= 0) and LSides[LSide].IsVisible then
      begin
        LSides[LSide] := TS4YTableBorderSide.Solid(LWidth[LSide], LSides[LSide].Color);
      end;

      if LHasColor[LSide] and LSides[LSide].IsVisible then
      begin
        LSides[LSide].Color := LColor[LSide];
      end;
    end;
  end;

  Result := TS4YTableBorders.Sides(LSides[0], LSides[1], LSides[2], LSides[3]);
end;

// Reads the background, padding, vertical alignment and borders of the cell that starts now. What the cell does not
// write comes from the table: its bgcolor, its cellpadding and its border.
procedure TS4YHTMLParser.ReadCellAttributes(const AAttributes: string);
var
  LStyle: string;
  LValue: string;
begin
  LStyle := GetAttribute(AAttributes, 'style').ToLower;
  FCellBackground := ParseBackgroundColor(AAttributes);
  if FCellBackground = claNull then
    FCellBackground := FTableBackground;

  FCellPadding := ParsePadding(LStyle);
  if not FCellPadding.IsSet then
    FCellPadding := FTablePadding;

  FCellBorders := ParseBorders(LStyle);

  // The text alignment of the cell, or of its table
  FCellHasAlignment := FTableHasTextAlignment;
  FCellAlignment := FTableTextAlignment;

  if ParseTextAlignment(GetAttribute(AAttributes, 'align'), FCellAlignment) then
    FCellHasAlignment := True;

  if (LStyle <> '') and ParseTextAlignment(ExtractCSSValue(LStyle, 'text-align'), FCellAlignment) then
    FCellHasAlignment := True;

  FCellVerticalAlignment := tvaTop;
  LValue := GetAttribute(AAttributes, 'valign').ToLower;

  if LStyle <> '' then
    if ExtractCSSValue(LStyle, 'vertical-align') <> '' then
      LValue := ExtractCSSValue(LStyle, 'vertical-align');

  if (LValue = 'middle') or (LValue = 'center') then
    FCellVerticalAlignment := tvaMiddle
  else if LValue = 'bottom' then
    FCellVerticalAlignment := tvaBottom;
end;

// Reads the width, the maximum width, the alignment and the border of the table that starts now.
procedure TS4YHTMLParser.ReadTableAttributes(const AAttributes: string);
var
  LStyle: string;
  LValue: string;
  LTokens: TArray<string>;
  LLeft: string;
  LRight: string;
begin
  FTableWidth := ParseTableLength(GetAttribute(AAttributes, 'width'));
  FTableHasTextAlignment := False;
  FTableBackground := ParseBackgroundColor(AAttributes);
  FTablePadding := TS4YTablePadding.Default;
  LValue := GetAttribute(AAttributes, 'cellpadding');

  if ParseTableLength(LValue).Kind = tlkPixels then
    FTablePadding := TS4YTablePadding.Uniform(ParseTableLength(LValue).Value);

  FTableMaximumWidth := 0;
  FTableAlignment := haLeft;
  FTableHasBorder := True;
  LStyle := GetAttribute(AAttributes, 'style').ToLower;

  if LStyle <> '' then
  begin
    LValue := ExtractCSSValue(LStyle, 'width');

    if LValue <> '' then
      FTableWidth := ParseTableLength(LValue);

    LValue := ExtractCSSValue(LStyle, 'max-width');

    if LValue <> '' then
    begin
      // Only a maximum in pixels is used
      if ParseTableLength(LValue).Kind = tlkPixels then
        FTableMaximumWidth := ParseTableLength(LValue).Value;
    end;

    // Automatic horizontal margins center the table, an automatic left margin alone puts it on the right
    LLeft := ExtractCSSValue(LStyle, 'margin-left');
    LRight := ExtractCSSValue(LStyle, 'margin-right');
    LValue := ExtractCSSValue(LStyle, 'margin');

    if LValue <> '' then
    begin
      LTokens := LValue.Split([' ']);

      case Length(LTokens) of
        1:
          begin
            LLeft := LTokens[0];
            LRight := LTokens[0];
          end;
        2, 3:
          begin
            LLeft := LTokens[1];
            LRight := LTokens[1];
          end;
        4:
          begin
            LLeft := LTokens[3];
            LRight := LTokens[1];
          end;
      end;
    end;

    if (LLeft = 'auto') and (LRight = 'auto') then
      FTableAlignment := haCenter
    else if LLeft = 'auto' then
      FTableAlignment := haRight;

    LValue := ExtractCSSValue(LStyle, 'border');

    if (LValue = 'none') or (LValue = '0') or LValue.StartsWith('0 ') or LValue.StartsWith('0px') or
       LValue.StartsWith('none') or (ExtractCSSValue(LStyle, 'border-style') = 'none') then
      FTableHasBorder := False;
  end;

  if LStyle <> '' then
    FTableHasTextAlignment := ParseTextAlignment(ExtractCSSValue(LStyle, 'text-align'), FTableTextAlignment);

  LValue := GetAttribute(AAttributes, 'align').ToLower;

  if LValue = 'center' then
    FTableAlignment := haCenter
  else if LValue = 'right' then
    FTableAlignment := haRight;

  if TrimS(GetAttribute(AAttributes, 'border')) = '0' then
    FTableHasBorder := False;

  // The space between the cells comes from cellspacing, or from the first value of border-spacing, which wins. A table
  // with collapsed borders has none: that is how a browser draws it, whatever cellspacing says.
  FTableCellSpacing := 0;
  LValue := TrimS(GetAttribute(AAttributes, 'cellspacing'));

  if (LValue <> '') and CharInSet(LValue[1], ['0'..'9', '.']) then
    ParseBorderWidth(LValue, FTableCellSpacing);

  if LStyle <> '' then
  begin
    LTokens := SplitCSSValue(ExtractCSSValue(LStyle, 'border-spacing'));

    if (Length(LTokens) > 0) and CharInSet(LTokens[0][1], ['0'..'9', '.']) then
      ParseBorderWidth(LTokens[0], FTableCellSpacing);

    if ExtractCSSValue(LStyle, 'border-collapse') = 'collapse' then
      FTableCellSpacing := 0;
  end;

  FTableCellSpacing := Min(Max(FTableCellSpacing, 0), C_MAXIMUM_TABLE_CELL_SPACING);
end;

function TS4YHTMLParser.ParseTableSpan(const AAttributes, AName: string): Integer;
begin
  Result := StrToIntDef(Trim(GetAttribute(AAttributes, AName)), 1);
  if Result < 1 then
    Result := 1;

  if Result > C_MAXIMUM_TABLE_SPAN then
    Result := C_MAXIMUM_TABLE_SPAN;
end;

procedure TS4YHTMLParser.FlushParagraph;
begin
  // A space kept after the last inline element would only be a trailing space
  if (FCurrentParagraph <> nil) and (FCurrentParagraph.Runs.Count > 1) and
     not FCurrentParagraph.Runs.Last.IsImage and not FCurrentParagraph.Runs.Last.IsLineBreak and
     (FCurrentParagraph.Runs.Last.Text = ' ') then
    FCurrentParagraph.Runs.Delete(FCurrentParagraph.Runs.Count - 1);

  if (FCurrentParagraph <> nil) and (not FCurrentParagraph.IsEmpty or ((FDocument.Paragraphs.Count = 0) and not FCellOpen)) then
  begin
    AddParagraph(FCurrentParagraph);
    FCurrentParagraph := nil;
  end
  else if FCurrentParagraph <> nil then
  begin
    FCurrentParagraph.Free;
    FCurrentParagraph := nil;
  end;
end;

procedure TS4YHTMLParser.EnsureParagraph(ABlockType: TS4YHTMLBlockType);
begin
  if FCurrentParagraph = nil then
  begin
    FCurrentParagraph := TS4YHTMLParagraph.Create;
    FCurrentParagraph.BlockType := ABlockType;

    if FDivAlignment <> haLeft then
    begin
      FCurrentParagraph.Alignment := FDivAlignment;
      FDivAlignment := haLeft;
    end;
  end;
end;

procedure TS4YHTMLParser.AddTextRun(const AText: string);
var
  LRun: TS4YHTMLRun;
  LTextStyle: TS4YHTMLTextStyle;
  LBorderColor: TAlphaColor;
begin
  if AText = '' then
    Exit;

  EnsureParagraph;
  LTextStyle := TopStyle;
  LBorderColor := TopBorderColor;

  if (FCurrentParagraph.Runs.Count > 0) and FCurrentParagraph.Runs.Last.Style.EqualsFormat(LTextStyle) and
     not FCurrentParagraph.Runs.Last.IsLineBreak and
     not FCurrentParagraph.Runs.Last.IsImage and
     (FCurrentParagraph.Runs.Last.PlaceholderBorderColor = LBorderColor) then
    FCurrentParagraph.Runs.Last.Text := FCurrentParagraph.Runs.Last.Text + AText
  else
  begin
    LRun := TS4YHTMLRun.Create;
    LRun.Text := AText;
    LRun.Style := LTextStyle;
    LRun.PlaceholderBorderColor := LBorderColor;
    FCurrentParagraph.Runs.Add(LRun);
  end;
end;

procedure TS4YHTMLParser.HandleTag(const ATag, AAttributes: string; IsClose, IsSelf: Boolean);
var
  LTextStyle: TS4YHTMLTextStyle;
  LBlockType: TS4YHTMLBlockType;
  LLineBreakRun: TS4YHTMLRun;
  LHorizontalRuleParagraph: TS4YHTMLParagraph;
  LLinkURL: string;
  LParagraphStyle: string;
  LStyleLower: string;
  LAlignAttribute: string;
  LStyleAttribute: string;
  LFaceAttribute: string;
  LSizeAttribute: string;
  LColorAttribute: string;
  LIndex: Integer;
  LPixelSize: Integer;
  LColor: TAlphaColor;
  LCellStyleWidth: string;
begin
  if (ATag = '!--') or StartsWithCI(ATag, '!') then
    Exit; // comments/doctype

  if IsBlockStyleTag(ATag) then
  begin
    if IsClose then
      CloseBlockStyle(ATag)
    else if not IsSelf then
      OpenBlockStyle(ATag, AAttributes);
  end;

  if ATag = 'head' then
  begin
    SkipUntil('</head>');
    Exit;
  end;

  if ATag = 'style' then
  begin
    SkipUntil('</style>');
    Exit;
  end;

  if ATag = 'script' then
  begin
    SkipUntil('</script>');
    Exit;
  end;

  // Block elements
  if ATag = 'p' then
  begin
    if IsClose then
      FlushParagraph
    else
    begin
      FlushParagraph;
      FCurrentParagraph := TS4YHTMLParagraph.Create;
      FCurrentParagraph.BlockType := btParagraph;
      LParagraphStyle := GetAttribute(AAttributes, 'style');

      if LParagraphStyle <> '' then
      begin
        LStyleLower := LParagraphStyle.ToLower;

        if LStyleLower.Contains('center') then
          FCurrentParagraph.Alignment := haCenter
        else if LStyleLower.Contains('right') then
          FCurrentParagraph.Alignment := haRight
        else if LStyleLower.Contains('justify') then
          FCurrentParagraph.Alignment := haJustify;
      end;

      LAlignAttribute := GetAttribute(AAttributes, 'align').ToLower;

      if LAlignAttribute = 'center' then
        FCurrentParagraph.Alignment := haCenter
      else if LAlignAttribute = 'right' then
        FCurrentParagraph.Alignment := haRight
      else if LAlignAttribute = 'justify' then
        FCurrentParagraph.Alignment := haJustify;
    end;

    Exit;
  end;

  if ATag = 'img' then
  begin
    if IsClose then
      Exit;

    LStyleAttribute := GetAttribute(AAttributes, 'style');
    LPixelSize := StrToIntDef(GetAttribute(AAttributes, 'width').Trim, 0);

    if (LPixelSize = 0) and (LStyleAttribute <> '') then
    begin
      LSizeAttribute := ExtractCSSValue(LStyleAttribute.ToLower, 'width');

      if LSizeAttribute <> '' then
        LPixelSize := StrToIntDef(LSizeAttribute.Replace('px', '').Replace('pt', '').Trim, 0);
    end;

    var LImageWidth := LPixelSize;
    LPixelSize := StrToIntDef(GetAttribute(AAttributes, 'height').Trim, 0);

    if (LPixelSize = 0) and (LStyleAttribute <> '') then
    begin
      LSizeAttribute := ExtractCSSValue(LStyleAttribute.ToLower, 'height');

      if LSizeAttribute <> '' then
        LPixelSize := StrToIntDef(LSizeAttribute.Replace('px', '').Replace('pt', '').Trim, 0);
    end;

    var LImageHeight := LPixelSize;
    var LImageSource := GetAttribute(AAttributes, 'src');
    var LImageAltText := GetAttribute(AAttributes, 'alt');
    LAlignAttribute := GetAttribute(AAttributes, 'align').ToLower;

    if (LAlignAttribute = '') and (LStyleAttribute <> '') then
    begin
      LStyleLower := ExtractCSSValue(LStyleAttribute.ToLower, 'text-align');

      if LStyleLower <> '' then
        LAlignAttribute := LStyleLower;
    end;

    var LParagraphWasNil := FCurrentParagraph = nil;
    EnsureParagraph;

    if LParagraphWasNil and (LAlignAttribute <> '') then
    begin
      if LAlignAttribute = 'center' then
        FCurrentParagraph.Alignment := haCenter
      else if LAlignAttribute = 'right' then
        FCurrentParagraph.Alignment := haRight
      else if LAlignAttribute = 'justify' then
        FCurrentParagraph.Alignment := haJustify;
    end;

    var LImageRun := TS4YHTMLRun.Create;
    LImageRun.IsImage := True;
    LImageRun.ImageSource := LImageSource;
    LImageRun.ImageAlt := LImageAltText;
    LImageRun.ImageWidth := LImageWidth;
    LImageRun.ImageHeight := LImageHeight;
    LImageRun.Style := TopStyle;
    LImageRun.Text := #$FFFC;
    FCurrentParagraph.Runs.Add(LImageRun);
    Exit;
  end;

  if ATag = 'br' then
  begin
    if IsClose then
      Exit;

    EnsureParagraph;
    LLineBreakRun := TS4YHTMLRun.Create;
    LLineBreakRun.IsLineBreak := True;
    FCurrentParagraph.Runs.Add(LLineBreakRun);
    Exit;
  end;

  if ATag = 'hr' then
  begin
    if IsClose then
      Exit;

    FlushParagraph;
    LHorizontalRuleParagraph := TS4YHTMLParagraph.Create;
    LHorizontalRuleParagraph.BlockType := btHR;
    LColorAttribute := GetAttribute(AAttributes, 'color');

    if LColorAttribute <> '' then
      LHorizontalRuleParagraph.HRColor := ParseColor(LColorAttribute);

    LSizeAttribute := GetAttribute(AAttributes, 'size');

    if LSizeAttribute <> '' then
    begin
      LPixelSize := StrToIntDef(LSizeAttribute.Trim, 0);

      if LPixelSize > 0 then
        LHorizontalRuleParagraph.HRThickness := LPixelSize;
    end;

    LStyleAttribute := GetAttribute(AAttributes, 'style');

    if LStyleAttribute <> '' then
    begin
      LStyleLower := LStyleAttribute.ToLower;
      LColorAttribute := ExtractCSSValue(LStyleLower, 'color');

      if LColorAttribute <> '' then
        LHorizontalRuleParagraph.HRColor := ParseColor(LColorAttribute);

      LColorAttribute := ExtractCSSValue(LStyleLower, 'border-color');

      if LColorAttribute <> '' then
        LHorizontalRuleParagraph.HRColor := ParseColor(LColorAttribute);

      LSizeAttribute := ExtractCSSValue(LStyleLower, 'height');
      if LSizeAttribute = '' then
        LSizeAttribute := ExtractCSSValue(LStyleLower, 'border-width');

      if LSizeAttribute <> '' then
      begin
        LSizeAttribute := LSizeAttribute.Replace('px', '').Replace('pt', '').Trim;
        LPixelSize := StrToIntDef(LSizeAttribute, 0);

        if LPixelSize > 0 then
          LHorizontalRuleParagraph.HRThickness := LPixelSize;
      end;
    end;

    AddParagraph(LHorizontalRuleParagraph);
    Exit;
  end;

  // Headings
  LBlockType := btParagraph;

  if (Length(ATag) = 2) and (ATag[Low(ATag)] = 'h') and CharInSet(ATag[Low(ATag) + 1], ['1' .. '6']) then
  begin
    case ATag[Low(ATag) + 1] of
      '1': LBlockType := btH1;
      '2': LBlockType := btH2;
      '3': LBlockType := btH3;
      '4': LBlockType := btH4;
      '5': LBlockType := btH5;
      '6': LBlockType := btH6;
    end;

    if IsClose then
      FlushParagraph
    else
    begin
      FlushParagraph;
      FCurrentParagraph := TS4YHTMLParagraph.Create;
      FCurrentParagraph.BlockType := LBlockType;
    end;

    Exit;
  end;

  if ATag = 'blockquote' then
  begin
    if IsClose then
    begin
      FlushParagraph;
      Dec(FListDepth);
    end
    else
    begin
      FlushParagraph;
      Inc(FListDepth);
      EnsureParagraph(btBlockquote);
      FCurrentParagraph.IndentLevel := FListDepth;
    end;

    Exit;
  end;

  if ATag = 'ul' then
  begin
    if IsClose then
      Dec(FListDepth)
    else
    begin
      FListDepth := Max(0, FListDepth);
      Inc(FListDepth);
      FInOrderedList := False;
    end;

    Exit;
  end;

  if ATag = 'ol' then
  begin
    if IsClose then
      Dec(FListDepth)
    else
    begin
      Inc(FListDepth);
      FInOrderedList := True;
      FOrderedListCounter := 0;
    end;

    Exit;
  end;

  if ATag = 'li' then
  begin
    if IsClose then
      FlushParagraph
    else
    begin
      FlushParagraph;
      FCurrentParagraph := TS4YHTMLParagraph.Create;
      FCurrentParagraph.BlockType := btLI;
      FCurrentParagraph.IndentLevel := FListDepth - 1;
      FCurrentParagraph.ListOrdered := FInOrderedList;

      if FInOrderedList then
      begin
        Inc(FOrderedListCounter);
        FCurrentParagraph.ListIndex := FOrderedListCounter;
      end;
    end;

    Exit;
  end;

  if ATag = 'pre' then
  begin
    if IsClose then
    begin
      FlushParagraph;
      FInPreformatted := False;
    end
    else
    begin
      FlushParagraph;
      FCurrentParagraph := TS4YHTMLParagraph.Create;
      FCurrentParagraph.BlockType := btPre;
      FInPreformatted := True;
    end;

    Exit;
  end;

  if ATag = 'div' then
  begin
    if IsClose then
    begin
      FlushParagraph;
      FDivAlignment := haLeft;
    end
    else
    begin
      FlushParagraph;
      FDivAlignment := haLeft;
      LStyleAttribute := GetAttribute(AAttributes, 'style');

      if LStyleAttribute <> '' then
      begin
        LStyleLower := ExtractCSSValue(LStyleAttribute.ToLower, 'text-align');

        if LStyleLower = 'center' then
          FDivAlignment := haCenter
        else if LStyleLower = 'right' then
          FDivAlignment := haRight
        else if LStyleLower = 'justify' then
          FDivAlignment := haJustify;
      end;
    end;

    Exit;
  end;

  if ATag = 'table' then
  begin
    if IsClose then
    begin
      EndTableCell;
      FlushParagraph;
      EndTableRow;

      for LIndex := 0 to FDocument.Paragraphs.Count - 1 do
        if FDocument.Paragraphs[LIndex].IsTableCell and
           (FDocument.Paragraphs[LIndex].TableID = FTableID) then
        begin
          FDocument.Paragraphs[LIndex].TableCols := FTableColumns;

          // A rowspan cannot go past the last row of the table
          if FDocument.Paragraphs[LIndex].TableRow + FDocument.Paragraphs[LIndex].TableRowSpan - 1 > FTableRow then
            FDocument.Paragraphs[LIndex].TableRowSpan := FTableRow - FDocument.Paragraphs[LIndex].TableRow + 1;
        end;

      FInTable := False;
      UnwindBlockStyles(FTableBlockBase);

      if FTableStylePushed then
        PopStyle;

      FTableStylePushed := False;

      // A table nested in a cell ends: the outer table goes on
      if FTableStack.Count > 0 then
        LeaveNestedTable;
    end
    else
    begin
      FlushParagraph;

      if FInTable and FCellOpen then
        EnterNestedTable
      else
        FTableContainers := nil;

      FTableID := NextTableID;
      ReadTableAttributes(AAttributes);
      LTextStyle := TopStyle;
      FTableBlockBase := FBlockStyles.Count;
      FTableStylePushed := ParseTextStyleOfBlock(GetAttribute(AAttributes, 'style'), LTextStyle);

      if FTableStylePushed then
        PushStyle(LTextStyle, TopBorderColor);

      FTableRow := -1;
      FTableColumn := 0;
      FTableColumns := 0;
      FTableCovered := nil;
      FTableRowOpen := False;
      FCellOpen := False;
      FInTable := True;
    end;

    Exit;
  end;

  if ATag = 'tr' then
  begin
    EndTableCell;

    if IsClose then
    begin
      FlushParagraph;
      EndTableRow;
    end
    else
    begin
      FlushParagraph;
      EndTableRow; // the previous row, when its closing tag was omitted
      Inc(FTableRow);
      FTableColumn := 0;
      FTableRowOpen := True;
    end;

    Exit;
  end;

  if (ATag = 'td') or (ATag = 'th') then
  begin
    if IsClose then
      EndTableCell
    else
    begin
      EndTableCell; // the previous cell, when its closing tag was omitted
      FlushParagraph;

      // Skip the columns that a cell of a previous row still covers
      while (FTableColumn < Length(FTableCovered)) and (FTableCovered[FTableColumn] > 0) do
        Inc(FTableColumn);

      FCellOpen := FInTable;
      FCellIsHeader := FInTable and (ATag = 'th');
      FCellRow := FTableRow;
      FCellColumn := FTableColumn;
      FCellColSpan := ParseTableSpan(AAttributes, 'colspan');
      FCellRowSpan := ParseTableSpan(AAttributes, 'rowspan');
      FCellWidth := ParseTableLength(GetAttribute(AAttributes, 'width'));

      if GetAttribute(AAttributes, 'style') <> '' then
      begin
        LCellStyleWidth := ExtractCSSValue(GetAttribute(AAttributes, 'style').ToLower, 'width');

        if LCellStyleWidth <> '' then
          FCellWidth := ParseTableLength(LCellStyleWidth);
      end;

      ReadCellAttributes(AAttributes);
      FCellParagraphCount := 0;

      // The text of the cell takes the style of the cell: bold for a th, and the font and color that it writes
      LTextStyle := TopStyle;

      if FCellIsHeader then
        LTextStyle.Bold := True;

      FCellBlockBase := FBlockStyles.Count;
      FCellStylePushed := ParseTextStyleOfBlock(GetAttribute(AAttributes, 'style'), LTextStyle) or FCellIsHeader;

      if FCellStylePushed then
        PushStyle(LTextStyle, TopBorderColor);

      if Length(FTableCovered) < FTableColumn + FCellColSpan then
        SetLength(FTableCovered, FTableColumn + FCellColSpan);

      for var LColumn := FTableColumn to FTableColumn + FCellColSpan - 1 do
        FTableCovered[LColumn] := FCellRowSpan;

      Inc(FTableColumn, FCellColSpan);
    end;

    Exit;
  end;

  if ATag = 'caption' then
  begin
    SkipUntil('</caption>');
    Exit;
  end;

  if ATag = 'colgroup' then
  begin
    SkipUntil('</colgroup>');
    Exit;
  end;

  if ATag = 'col' then
    Exit;

  if ATag = 'tbody' then
    Exit;

  if ATag = 'thead' then
    Exit;

  if ATag = 'tfoot' then
    Exit;

  // Inline elements - push/pop style stack
  LTextStyle := TopStyle;

  if ATag = 'b' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.Bold := True;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'strong' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.Bold := True;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'i' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.Italic := True;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'em' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.Italic := True;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'u' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.Underline := True;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if (ATag = 's') or (ATag = 'del') or (ATag = 'strike') then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.StrikeOut := True;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'sup' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.Superscript := True;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'sub' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.Subscript := True;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'small' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.FontSize := LTextStyle.FontSize * 0.8;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'big' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LTextStyle.FontSize := LTextStyle.FontSize * 1.2;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'a' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LLinkURL := GetAttribute(AAttributes, 'href');
      LTextStyle.Underline := True;
      LTextStyle.Color := $FF0000EE;
      LTextStyle.LinkURL := LLinkURL;
      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  if ATag = 'span' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LStyleAttribute := GetAttribute(AAttributes, 'style');

      if LStyleAttribute <> '' then
        ParseInlineStyle(LStyleAttribute, LTextStyle);

      PushStyle(LTextStyle, ExtractBorderColor(LStyleAttribute));
    end;

    Exit;
  end;

  if ATag = 'font' then
  begin
    if IsClose then
      PopStyle
    else
    begin
      LFaceAttribute := GetAttribute(AAttributes, 'face');
      LSizeAttribute := GetAttribute(AAttributes, 'size');
      LColorAttribute := GetAttribute(AAttributes, 'color');
      LStyleAttribute := GetAttribute(AAttributes, 'style');

      if LFaceAttribute <> '' then
        LTextStyle.FontName := LFaceAttribute;

      if LSizeAttribute <> '' then
      begin
        LPixelSize := StrToIntDef(LSizeAttribute.Trim, 0);

        if LPixelSize > 0 then
          LTextStyle.FontSize := LPixelSize;
      end;

      if LColorAttribute <> '' then
      begin
        LColor := ParseColor(LColorAttribute);

        if LColor <> claNull then
          LTextStyle.Color := LColor;
      end;

      if LStyleAttribute <> '' then
        ParseInlineStyle(LStyleAttribute, LTextStyle);

      PushStyle(LTextStyle);
    end;

    Exit;
  end;

  // Ignore unknown tags
end;

function TS4YHTMLParser.HtmlDecode(const AText: string): string;
var
  LScanPosition, LEntityEnd: Integer;
  LEntity: string;
  LCode: Integer;
begin
  if not AText.Contains('&') then
    Exit(AText);

  Result := '';
  LScanPosition := Low(AText);

  while LScanPosition <= High(AText) do
  begin
    if AText[LScanPosition] = '&' then
    begin
      LEntityEnd := LScanPosition + 1;

      while (LEntityEnd <= High(AText)) and (AText[LEntityEnd] <> ';') and (LEntityEnd - LScanPosition < 12) do
        Inc(LEntityEnd);

      if (LEntityEnd <= High(AText)) and (AText[LEntityEnd] = ';') then
      begin
        LEntity := AText.Substring(LScanPosition - Low(AText) + 1, LEntityEnd - LScanPosition - 1);

        if LEntity = 'amp' then
          Result := Result + '&'
        else if LEntity = 'lt' then
          Result := Result + '<'
        else if LEntity = 'gt' then
          Result := Result + '>'
        else if LEntity = 'quot' then
          Result := Result + '"'
        else if LEntity = 'apos' then
          Result := Result + ''''
        else if LEntity = 'nbsp' then
          Result := Result + #$00A0
        else if LEntity = 'copy' then
          Result := Result + #$00A9
        else if LEntity = 'reg' then
          Result := Result + #$00AE
        else if LEntity = 'trade' then
          Result := Result + #$2122
        else if LEntity = 'mdash' then
          Result := Result + '--'
        else if LEntity = 'ndash' then
          Result := Result + '-'
        else if LEntity = 'hellip' then
          Result := Result + #$2026
        else if (LEntity <> '') and (LEntity[Low(LEntity)] = '#') then
        begin
          try
            if (LEntity.Length > 1) and CharInSet(LEntity[Low(LEntity) + 1], ['x', 'X']) then
              LCode := StrToInt('$' + LEntity.Substring(2))
            else
              LCode := LEntity.Substring(1).ToInteger;

            if LCode < $10000 then
              Result := Result + WideChar(LCode)
            else
            begin
              Dec(LCode, $10000);
              Result := Result + WideChar($D800 or (LCode shr 10)) + WideChar($DC00 or (LCode and $3FF));
            end;
          except
            Result := Result + '&' + LEntity + ';';
          end;
        end
        else
          Result := Result + '&' + LEntity + ';';

        LScanPosition := LEntityEnd + 1;
      end
      else
      begin
        Result := Result + AText[LScanPosition];
        Inc(LScanPosition);
      end;
    end
    else
    begin
      Result := Result + AText[LScanPosition];
      Inc(LScanPosition);
    end;
  end;
end;

function TS4YHTMLParser.Parse(const AHTML: string): TS4YHTMLDocument;
var
  LTagName, LAttributes: string;
  LIsClose, LIsSelf: Boolean;
  LTextNode: string;
  LBaseStyle: TS4YHTMLTextStyle;
  LParagraph: TS4YHTMLParagraph;
  LPreformattedParts: TArray<string>;
  LIndex: Integer;
begin
  FInput := AHTML;
  FLength := Length(AHTML);
  FPosition := Low(AHTML);
  FDocument := TS4YHTMLDocument.Create;
  FStyleStack := TList<TS4YHTMLTextStyle>.Create;
  FBorderColorStack := TList<TAlphaColor>.Create;
  FTableStack := TList<TTableState>.Create;
  FBlockStyles := TList<TBlockStyleEntry>.Create;
  FInTable := False;
  FCellOpen := False;
  FCellStylePushed := False;
  FTableStylePushed := False;
  FTableContainers := nil;
  FCurrentParagraph := nil;
  FDivAlignment := haLeft;
  FListDepth := 0;
  FInOrderedList := False;
  FOrderedListCounter := 0;
  FInPreformatted := False;

  try
    LBaseStyle := BaseStyle;
    PushStyle(LBaseStyle);

    while FPosition <= FLength do
    begin
      if PeekChar = '<' then
      begin
        if ReadTag(LTagName, LAttributes, LIsClose, LIsSelf) then
        begin
          HandleTag(LTagName, LAttributes, LIsClose, LIsSelf);

          if LIsSelf and not LIsClose then
            HandleTag(LTagName, LAttributes, True, False); // auto-close
        end;
      end
      else
      begin
        LTextNode := ReadTextNode;

        if FInPreformatted then
        begin
          LTextNode := LTextNode.Replace(#13#10, #10).Replace(#13, #10);
          LPreformattedParts := LTextNode.Split([#10]);

          for LIndex := 0 to High(LPreformattedParts) do
          begin
            if LPreformattedParts[LIndex] <> '' then
              AddTextRun(LPreformattedParts[LIndex]);

            if LIndex < High(LPreformattedParts) then
            begin
              FlushParagraph;
              FCurrentParagraph := TS4YHTMLParagraph.Create;
              FCurrentParagraph.BlockType := btPre;
            end;
          end;
        end
        else
        begin
          LTextNode := LTextNode.Replace(#13#10, ' ').Replace(#10, ' ').Replace(#13, ' ').Replace(#9, ' ');

          while LTextNode.Contains('  ') do
            LTextNode := LTextNode.Replace('  ', ' ');

          if LTextNode.Trim <> '' then
            AddTextRun(LTextNode)
          else if (LTextNode = ' ') and (FCurrentParagraph <> nil) and (FCurrentParagraph.Runs.Count > 0) and
                  not FCurrentParagraph.Runs.Last.IsLineBreak and not FCurrentParagraph.Runs.Last.Text.EndsWith(' ') then
            // A space between two inline elements (<b>a</b> <i>b</i>) separates the words; between blocks it is dropped
            AddTextRun(' ');
        end;
      end;
    end;

    FlushParagraph;

    if FDocument.Paragraphs.Count = 0 then
    begin
      LParagraph := TS4YHTMLParagraph.Create;
      LParagraph.BlockType := btParagraph;
      FDocument.Paragraphs.Add(LParagraph);
    end;

    Result := FDocument;
    FDocument := nil;
  finally
    FStyleStack.Free;
    FBorderColorStack.Free;
    FTableStack.Free;
    FBlockStyles.Free;
    FCurrentParagraph.Free;
  end;
end;

end.
