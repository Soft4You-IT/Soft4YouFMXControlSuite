unit Soft4You.HTML.Parser;

{ *****************************************************************************
  S4YFMXHTMLEditor - WYSIWYG HTML editor for Delphi FireMonkey (FMX)
  Original author: Carlo Marona (Soft4You) - 2026

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

  TS4YHTMLParser = class
  private
    FInput: string;
    FPosition: Integer;
    FLength: Integer;
    FDoc: TS4YHTMLDocument;
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
    FInTable: Boolean;
    FInPreformatted: Boolean;
    FDivAlignment: TS4YHTMLAlignment;

    function PeekChar: Char; inline;
    function ReadChar: Char; inline;
    procedure SkipUntil(const AText: string);
    function ReadTag(out ATagName, AAttributes: string; out IsClose, IsSelf: Boolean): Boolean;
    function ReadTextNode: string;
    function GetAttr(const AAttributes, AName: string): string;
    function ExtractCSSValue(const ACSS, AProp: string): string;
    function ParseColor(const AText: string): TAlphaColor;
    function ParseFontSize(const AText: string; ABaseSize: Single): Single;
    procedure ParseInlineStyle(const ACSS: string; var ATextStyle: TS4YHTMLTextStyle);
    function ExtractBorderColor(const ACSS: string): TAlphaColor;
    procedure FlushPara;
    procedure EnsurePara(ABlockType: TS4YHTMLBlockType = btBodyText);
    procedure PushStyle(const ATextStyle: TS4YHTMLTextStyle; ABorderColor: TAlphaColor = claNull);
    procedure PopStyle;
    function TopStyle: TS4YHTMLTextStyle;
    function TopBorderColor: TAlphaColor;
    procedure HandleTag(const ATag, AAttributes: string; IsClose, IsSelf: Boolean);
    procedure AddTextRun(const AText: string);
    function HtmlDecode(const AText: string): string;
    function BaseStyle: TS4YHTMLTextStyle;
  public
    function Parse(const AHTML: string): TS4YHTMLDocument;
  end;

implementation

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
    while (FPosition <= FLength) and not(PeekChar in ['>', '/', ' ', #9, #10, #13]) do
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
      else if LChar in ['"', ''''] then
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

function TS4YHTMLParser.GetAttr(const AAttributes, AName: string): string;
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
    while (LScanPosition < LAttributeLength) and (LAttributesLower[Low(LAttributesLower) + LScanPosition] in [' ', #9, #10, #13]) do
      Inc(LScanPosition);
    if LScanPosition >= LAttributeLength then
      Break;
    // Try to match the attribute name at this exact token boundary
    if LAttributesLower.Substring(LScanPosition, LNameWithEquals.Length) = LNameWithEquals then
    begin
      Inc(LScanPosition, LNameWithEquals.Length);
      if LScanPosition >= LAttributeLength then
        Break;
      LQuoteChar := LAttributesLower[Low(LAttributesLower) + LScanPosition];
      if LQuoteChar in ['"', ''''] then
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
        while (LValueEnd < LAttributeLength) and not (LAttributesLower[Low(LAttributesLower) + LValueEnd] in [' ', '>']) do
          Inc(LValueEnd);
        Result := AAttributes.Substring(LScanPosition, LValueEnd - LScanPosition);
      end;
      Exit;
    end;
    // Not this attribute -- skip its name
    while (LScanPosition < LAttributeLength) and not (LAttributesLower[Low(LAttributesLower) + LScanPosition] in [' ', '=']) do
      Inc(LScanPosition);
    // Skip optional =value
    if (LScanPosition < LAttributeLength) and (LAttributesLower[Low(LAttributesLower) + LScanPosition] = '=') then
    begin
      Inc(LScanPosition); // skip '='
      if (LScanPosition < LAttributeLength) and (LAttributesLower[Low(LAttributesLower) + LScanPosition] in ['"', '''']) then
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
        while (LScanPosition < LAttributeLength) and not (LAttributesLower[Low(LAttributesLower) + LScanPosition] in [' ', '>']) do
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

procedure TS4YHTMLParser.FlushPara;
begin
  if (FCurrentParagraph <> nil) and (not FCurrentParagraph.IsEmpty or (FDoc.Paragraphs.Count = 0)) then
  begin
    FDoc.Paragraphs.Add(FCurrentParagraph);
    FCurrentParagraph := nil;
  end
  else if FCurrentParagraph <> nil then
  begin
    FCurrentParagraph.Free;
    FCurrentParagraph := nil;
  end;
end;

procedure TS4YHTMLParser.EnsurePara(ABlockType: TS4YHTMLBlockType);
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
  EnsurePara;
  LTextStyle := TopStyle;
  LBorderColor := TopBorderColor;
  if (FCurrentParagraph.Runs.Count > 0) and FCurrentParagraph.Runs.Last.Style.EqualsFormat(LTextStyle) and
     not FCurrentParagraph.Runs.Last.IsLineBreak and
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
  I: Integer;
  LPixelSize: Integer;
  LColor: TAlphaColor;
begin
  if (ATag = '!--') or StartsWithCI(ATag, '!') then
    Exit; // comments/doctype
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
      FlushPara
    else
    begin
      FlushPara;
      FCurrentParagraph := TS4YHTMLParagraph.Create;
      FCurrentParagraph.BlockType := btParagraph;
      LParagraphStyle := GetAttr(AAttributes, 'style');
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
      LAlignAttribute := GetAttr(AAttributes, 'align').ToLower;
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
    LStyleAttribute := GetAttr(AAttributes, 'style');
    LPixelSize := StrToIntDef(GetAttr(AAttributes, 'width').Trim, 0);
    if (LPixelSize = 0) and (LStyleAttribute <> '') then
    begin
      LSizeAttribute := ExtractCSSValue(LStyleAttribute.ToLower, 'width');
      if LSizeAttribute <> '' then
        LPixelSize := StrToIntDef(LSizeAttribute.Replace('px', '').Replace('pt', '').Trim, 0);
    end;
    var LImageWidth := LPixelSize;
    LPixelSize := StrToIntDef(GetAttr(AAttributes, 'height').Trim, 0);
    if (LPixelSize = 0) and (LStyleAttribute <> '') then
    begin
      LSizeAttribute := ExtractCSSValue(LStyleAttribute.ToLower, 'height');
      if LSizeAttribute <> '' then
        LPixelSize := StrToIntDef(LSizeAttribute.Replace('px', '').Replace('pt', '').Trim, 0);
    end;
    var LImageHeight := LPixelSize;
    var LImageSource := GetAttr(AAttributes, 'src');
    var LImageAltText := GetAttr(AAttributes, 'alt');
    LAlignAttribute := GetAttr(AAttributes, 'align').ToLower;
    if (LAlignAttribute = '') and (LStyleAttribute <> '') then
    begin
      LStyleLower := ExtractCSSValue(LStyleAttribute.ToLower, 'text-align');
      if LStyleLower <> '' then
        LAlignAttribute := LStyleLower;
    end;
    var LParagraphWasNil := FCurrentParagraph = nil;
    EnsurePara;
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
    LImageRun.ImageSrc := LImageSource;
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
    EnsurePara;
    LLineBreakRun := TS4YHTMLRun.Create;
    LLineBreakRun.IsLineBreak := True;
    FCurrentParagraph.Runs.Add(LLineBreakRun);
    Exit;
  end;

  if ATag = 'hr' then
  begin
    if IsClose then
      Exit;
    FlushPara;
    LHorizontalRuleParagraph := TS4YHTMLParagraph.Create;
    LHorizontalRuleParagraph.BlockType := btHR;
    LColorAttribute := GetAttr(AAttributes, 'color');
    if LColorAttribute <> '' then
      LHorizontalRuleParagraph.HRColor := ParseColor(LColorAttribute);
    LSizeAttribute := GetAttr(AAttributes, 'size');
    if LSizeAttribute <> '' then
    begin
      LPixelSize := StrToIntDef(LSizeAttribute.Trim, 0);
      if LPixelSize > 0 then
        LHorizontalRuleParagraph.HRThickness := LPixelSize;
    end;
    LStyleAttribute := GetAttr(AAttributes, 'style');
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
    FDoc.Paragraphs.Add(LHorizontalRuleParagraph);
    Exit;
  end;

  // Headings
  LBlockType := btParagraph;
  if (Length(ATag) = 2) and (ATag[Low(ATag)] = 'h') and (ATag[Low(ATag) + 1] in ['1' .. '6']) then
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
      FlushPara
    else
    begin
      FlushPara;
      FCurrentParagraph := TS4YHTMLParagraph.Create;
      FCurrentParagraph.BlockType := LBlockType;
    end;
    Exit;
  end;

  if ATag = 'blockquote' then
  begin
    if IsClose then
    begin
      FlushPara;
      Dec(FListDepth);
    end
    else
    begin
      FlushPara;
      Inc(FListDepth);
      EnsurePara(btBlockquote);
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
      FlushPara
    else
    begin
      FlushPara;
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
      FlushPara;
      FInPreformatted := False;
    end
    else
    begin
      FlushPara;
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
      FlushPara;
      FDivAlignment := haLeft;
    end
    else
    begin
      FlushPara;
      FDivAlignment := haLeft;
      LStyleAttribute := GetAttr(AAttributes, 'style');
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
      FlushPara;
      for I := 0 to FDoc.Paragraphs.Count - 1 do
        if (FDoc.Paragraphs[I].BlockType = btTableCell) and
           (FDoc.Paragraphs[I].TableID = FTableID) then
          FDoc.Paragraphs[I].TableCols := FTableColumns;
      FInTable := False;
    end
    else
    begin
      FlushPara;
      FTableID := NextTableID;
      FTableRow := -1;
      FTableColumn := 0;
      FTableColumns := 0;
      FInTable := True;
    end;
    Exit;
  end;

  if ATag = 'tr' then
  begin
    if IsClose then
    begin
      FlushPara;
      if FTableColumn > FTableColumns then
        FTableColumns := FTableColumn;
    end
    else
    begin
      FlushPara;
      Inc(FTableRow);
      FTableColumn := 0;
    end;
    Exit;
  end;

  if (ATag = 'td') or (ATag = 'th') then
  begin
    if IsClose then
    begin
      FlushPara;
      if ATag = 'th' then
        PopStyle;
    end
    else
    begin
      FlushPara;
      FCurrentParagraph := TS4YHTMLParagraph.Create;
      FCurrentParagraph.BlockType := btTableCell;
      FCurrentParagraph.TableID := FTableID;
      FCurrentParagraph.TableRow := FTableRow;
      FCurrentParagraph.TableCol := FTableColumn;
      FCurrentParagraph.IsHeader := (ATag = 'th');
      if FCurrentParagraph.IsHeader then
      begin
        FCurrentParagraph.Alignment := haCenter;
        LTextStyle := TopStyle;
        LTextStyle.Bold := True;
        PushStyle(LTextStyle);
      end;
      Inc(FTableColumn);
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
      LLinkURL := GetAttr(AAttributes, 'href');
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
      LStyleAttribute := GetAttr(AAttributes, 'style');
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
      LFaceAttribute := GetAttr(AAttributes, 'face');
      LSizeAttribute := GetAttr(AAttributes, 'size');
      LColorAttribute := GetAttr(AAttributes, 'color');
      LStyleAttribute := GetAttr(AAttributes, 'style');
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
            if (LEntity.Length > 1) and (LEntity[Low(LEntity) + 1] in ['x', 'X']) then
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
  I: Integer;
begin
  FInput := AHTML;
  FLength := Length(AHTML);
  FPosition := Low(AHTML);
  FDoc := TS4YHTMLDocument.Create;
  FStyleStack := TList<TS4YHTMLTextStyle>.Create;
  FBorderColorStack := TList<TAlphaColor>.Create;
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
          for I := 0 to High(LPreformattedParts) do
          begin
            if LPreformattedParts[I] <> '' then
              AddTextRun(LPreformattedParts[I]);
            if I < High(LPreformattedParts) then
            begin
              FlushPara;
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
            AddTextRun(LTextNode);
        end;
      end;
    end;

    FlushPara;

    if FDoc.Paragraphs.Count = 0 then
    begin
      LParagraph := TS4YHTMLParagraph.Create;
      LParagraph.BlockType := btParagraph;
      FDoc.Paragraphs.Add(LParagraph);
    end;

    Result := FDoc;
    FDoc := nil;
  finally
    FStyleStack.Free;
    FBorderColorStack.Free;
    FCurrentParagraph.Free;
  end;
end;

end.
