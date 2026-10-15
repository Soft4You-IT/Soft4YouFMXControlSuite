unit Soft4You.HTML.Generator;

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
  Soft4You.HTML.Types,
  Soft4You.HTML.Document;

type

  // ===========================================================================
  // TS4YHTMLGenerator
  // ===========================================================================

  TS4YHTMLGenerator = class
  private
    FPretty: Boolean;
    FPlaceholderStyle: TS4YPlaceholderGeneratorStyle;
    function HtmlEncode(const AText: string): string;
    function ColorToHex(AColor: TAlphaColor): string;
    function StyleDiff(const ACurrentStyle, ABaseStyle: TS4YHTMLTextStyle): string;
  public
    function Generate(ADocument: TS4YHTMLDocument): string;

    property PlaceholderStyle: TS4YPlaceholderGeneratorStyle read FPlaceholderStyle write FPlaceholderStyle;
    property Pretty: Boolean read FPretty write FPretty;
  end;

implementation

// -----------------------------------------------------------------------------
// TS4YHTMLGenerator
// -----------------------------------------------------------------------------

function TS4YHTMLGenerator.HtmlEncode(const AText: string): string;
begin
  Result := AText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;');
end;

function TS4YHTMLGenerator.ColorToHex(AColor: TAlphaColor): string;
begin
  Result := Format('#%.2x%.2x%.2x', [TAlphaColorRec(AColor).R, TAlphaColorRec(AColor).G, TAlphaColorRec(AColor).B]);
end;

function TS4YHTMLGenerator.StyleDiff(const ACurrentStyle, ABaseStyle: TS4YHTMLTextStyle): string;
var
  LStringBuilder: TStringBuilder;
begin
  LStringBuilder := TStringBuilder.Create;
  try
    if ACurrentStyle.FontName <> ABaseStyle.FontName then
      LStringBuilder.Append('font-family:' + ACurrentStyle.FontName + ';');
    if Abs(ACurrentStyle.FontSize - ABaseStyle.FontSize) > 0.01 then
      LStringBuilder.Append(Format('font-size:%.0fpt;', [ACurrentStyle.FontSize]));
    // Bold, italic, underline, strikeout are emitted as semantic tags
    // (<b><i><u><s>) by the caller -- skip them here.
    if (ACurrentStyle.Color <> ABaseStyle.Color) and (ACurrentStyle.Color <> claNull) then
      LStringBuilder.Append('color:' + ColorToHex(ACurrentStyle.Color) + ';');
    if (ACurrentStyle.BackgroundColor <> ABaseStyle.BackgroundColor) and (ACurrentStyle.BackgroundColor <> claNull) then
      LStringBuilder.Append('background-color:' + ColorToHex(ACurrentStyle.BackgroundColor) + ';');
    Result := LStringBuilder.ToString;
  finally
    LStringBuilder.Free;
  end;
end;

function TS4YHTMLGenerator.Generate(ADocument: TS4YHTMLDocument): string;
var
  LStringBuilder: TStringBuilder;
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LBase: TS4YHTMLTextStyle;
  LOpenTag, LCloseTag, LCSS: string;
  LAlignCSS: string;
  LIndent: string;
  LStyleAttribute: string;
  LNewLine: string;
  LIsLink: Boolean;
  LParagraphIndex: Integer;
  LFillColor: TAlphaColor;
  LTextColor: TAlphaColor;
  LBorderColor: TAlphaColor;
  LChipBold: Boolean;
  LChipCSS: string;

  procedure EmitRuns(AParagraph: TS4YHTMLParagraph);
  begin
    for var LEmitRun in AParagraph.Runs do
    begin
      if LEmitRun.IsPlaceholder then
      begin
        if LEmitRun.Style.BackgroundColor <> claNull then
          LFillColor := LEmitRun.Style.BackgroundColor
        else
          LFillColor := FPlaceholderStyle.FillColor;
        if LEmitRun.Style.Color <> claNull then
          LTextColor := LEmitRun.Style.Color
        else
          LTextColor := FPlaceholderStyle.TextColor;
        if LEmitRun.PlaceholderBorderColor <> claNull then
          LBorderColor := LEmitRun.PlaceholderBorderColor
        else if LFillColor <> claNull then
          LBorderColor := DarkenColor(LFillColor)
        else
          LBorderColor := FPlaceholderStyle.BorderColor;
        LChipBold := LEmitRun.Style.Bold or FPlaceholderStyle.Bold;
        LChipCSS := 'display:inline-block;';
        if LFillColor <> claNull then
          LChipCSS := LChipCSS + 'background-color:' + ColorToHex(LFillColor) + ';';
        if LTextColor <> claNull then
          LChipCSS := LChipCSS + 'color:' + ColorToHex(LTextColor) + ';';
        if LBorderColor <> claNull then
          LChipCSS := LChipCSS + 'border:1px solid ' + ColorToHex(LBorderColor) + ';';
        if FPlaceholderStyle.BorderRadius > 0 then
          LChipCSS := LChipCSS + Format('border-radius:%.0fpx;', [FPlaceholderStyle.BorderRadius]);
        if (FPlaceholderStyle.HorizontalPadding > 0) or (FPlaceholderStyle.VerticalPadding > 0) then
          LChipCSS := LChipCSS + Format('padding:%.0fpx %.0fpx;', [FPlaceholderStyle.VerticalPadding, FPlaceholderStyle.HorizontalPadding]);
        LStringBuilder.Append('<span style="' + LChipCSS + '">');
        if LChipBold then
          LStringBuilder.Append('<b>');
        LStringBuilder.Append(HtmlEncode(LEmitRun.Text));
        if LChipBold then
          LStringBuilder.Append('</b>');
        LStringBuilder.Append('</span>');
      end
      else if LEmitRun.IsImage then
      begin
        LStringBuilder.Append('<img');
        if LEmitRun.ImageSource <> '' then
          LStringBuilder.Append(' src="' + LEmitRun.ImageSource + '"');
        if LEmitRun.ImageWidth > 0 then
          LStringBuilder.Append(' width="' + IntToStr(LEmitRun.ImageWidth) + '"');
        if LEmitRun.ImageHeight > 0 then
          LStringBuilder.Append(' height="' + IntToStr(LEmitRun.ImageHeight) + '"');
        if LEmitRun.ImageAlt <> '' then
          LStringBuilder.Append(' alt="' + HtmlEncode(LEmitRun.ImageAlt) + '"');
        LStringBuilder.Append('/>');
      end
      else if LEmitRun.IsLineBreak then
        LStringBuilder.Append('<br/>')
      else
      begin
        LCSS := StyleDiff(LEmitRun.Style, LBase);
        LIsLink := (LEmitRun.Style.LinkURL <> '') and (LEmitRun.Style.LinkURL <> LBase.LinkURL);
        if LIsLink then
          LStringBuilder.Append('<a href="' + HtmlEncode(LEmitRun.Style.LinkURL) + '">');
        if LEmitRun.Style.Superscript then
          LStringBuilder.Append('<sup>');
        if LEmitRun.Style.Subscript then
          LStringBuilder.Append('<sub>');
        if LEmitRun.Style.Bold then
          LStringBuilder.Append('<b>');
        if LEmitRun.Style.Italic then
          LStringBuilder.Append('<i>');
        if LEmitRun.Style.Underline then
          LStringBuilder.Append('<u>');
        if LEmitRun.Style.StrikeOut then
          LStringBuilder.Append('<s>');
        if LCSS <> '' then
          LStringBuilder.Append('<span style="' + LCSS + '">');
        LStringBuilder.Append(HtmlEncode(LEmitRun.Text));
        if LCSS <> '' then
          LStringBuilder.Append('</span>');
        if LEmitRun.Style.StrikeOut then
          LStringBuilder.Append('</s>');
        if LEmitRun.Style.Underline then
          LStringBuilder.Append('</u>');
        if LEmitRun.Style.Italic then
          LStringBuilder.Append('</i>');
        if LEmitRun.Style.Bold then
          LStringBuilder.Append('</b>');
        if LEmitRun.Style.Subscript then
          LStringBuilder.Append('</sub>');
        if LEmitRun.Style.Superscript then
          LStringBuilder.Append('</sup>');
        if LIsLink then
          LStringBuilder.Append('</a>');
      end;
    end;
  end;

  procedure EmitListBlock(ABaseLevel: Integer);
  var
    LLI: TS4YHTMLParagraph;
    LListTag: string;
    LFirstOrdered: Boolean;
  begin
    LLI := ADocument.Paragraphs[LParagraphIndex];
    LFirstOrdered := LLI.ListOrdered;
    if LFirstOrdered then
      LListTag := 'ol'
    else
      LListTag := 'ul';
    LStringBuilder.Append('<' + LListTag + '>' + LNewLine);
    while (LParagraphIndex < ADocument.Paragraphs.Count) and
          (ADocument.Paragraphs[LParagraphIndex].BlockType = btLI) and
          (ADocument.Paragraphs[LParagraphIndex].IndentLevel >= ABaseLevel) do
    begin
      LLI := ADocument.Paragraphs[LParagraphIndex];
      // Item jumps deeper without a parent li -- open sub-list at its actual level
      if LLI.IndentLevel > ABaseLevel then
      begin
        EmitListBlock(LLI.IndentLevel);
        Continue;
      end;
      // Different list type at same level -- end this list; outer loop starts a new one
      if LLI.ListOrdered <> LFirstOrdered then
        Break;
      // Emit list item
      LStringBuilder.Append('<li>');
      EmitRuns(LLI);
      Inc(LParagraphIndex);
      // If next items are deeper, nest a sub-list inside this <li>
      if (LParagraphIndex < ADocument.Paragraphs.Count) and
         (ADocument.Paragraphs[LParagraphIndex].BlockType = btLI) and
         (ADocument.Paragraphs[LParagraphIndex].IndentLevel > ABaseLevel) then
      begin
        LStringBuilder.Append(LNewLine);
        EmitListBlock(ADocument.Paragraphs[LParagraphIndex].IndentLevel);
      end;
      LStringBuilder.Append('</li>' + LNewLine);
    end;
    LStringBuilder.Append('</' + LListTag + '>' + LNewLine);
  end;

  procedure EmitTable(AFirstPI: Integer);
  var
    LTableID: Integer;
    LCols: Integer;
    LRow: Integer;
    LMaximumRow: Integer;
    LCol: Integer;
    LCell: TS4YHTMLParagraph;
    LCellTag: string;
    LCellStyle: string;
    LScanIndex: Integer;
  begin
    LTableID := ADocument.Paragraphs[AFirstPI].TableID;
    LCols := ADocument.Paragraphs[AFirstPI].TableCols;
    if LCols < 1 then
      LCols := 1;
    LMaximumRow := 0;
    LScanIndex := AFirstPI;
    while (LScanIndex < ADocument.Paragraphs.Count) and
          (ADocument.Paragraphs[LScanIndex].BlockType = btTableCell) and
          (ADocument.Paragraphs[LScanIndex].TableID = LTableID) do
    begin
      if ADocument.Paragraphs[LScanIndex].TableRow > LMaximumRow then
        LMaximumRow := ADocument.Paragraphs[LScanIndex].TableRow;
      Inc(LScanIndex);
    end;
    LStringBuilder.Append('<table border="1" style="border-collapse:collapse;width:100%">' + LNewLine);
    for LRow := 0 to LMaximumRow do
    begin
      if FPretty then
        LStringBuilder.Append('  ');
      LStringBuilder.Append('<tr>' + LNewLine);
      for LCol := 0 to LCols - 1 do
      begin
        LCell := nil;
        LScanIndex := AFirstPI;
        while (LScanIndex < ADocument.Paragraphs.Count) and (LCell = nil) do
        begin
          if (ADocument.Paragraphs[LScanIndex].BlockType = btTableCell) and
             (ADocument.Paragraphs[LScanIndex].TableID = LTableID) and
             (ADocument.Paragraphs[LScanIndex].TableRow = LRow) and
             (ADocument.Paragraphs[LScanIndex].TableCol = LCol) then
            LCell := ADocument.Paragraphs[LScanIndex]
          else
            Inc(LScanIndex);
        end;
        if LCell = nil then
        begin
          if FPretty then
            LStringBuilder.Append('    ');
          LStringBuilder.Append('<td></td>' + LNewLine);
        end
        else
        begin
          if LCell.IsHeader then
            LCellTag := 'th'
          else
            LCellTag := 'td';
          LCellStyle := 'padding:4px;';
          case LCell.Alignment of
            haCenter:  LCellStyle := LCellStyle + 'text-align:center;';
            haRight:   LCellStyle := LCellStyle + 'text-align:right;';
            haJustify: LCellStyle := LCellStyle + 'text-align:justify;';
          end;
          if FPretty then
            LStringBuilder.Append('    ');
          LStringBuilder.Append('<' + LCellTag + ' style="' + LCellStyle + '">');
          EmitRuns(LCell);
          LStringBuilder.Append('</' + LCellTag + '>' + LNewLine);
        end;
      end;
      if FPretty then
        LStringBuilder.Append('  ');
      LStringBuilder.Append('</tr>' + LNewLine);
    end;
    LStringBuilder.Append('</table>' + LNewLine);
    LParagraphIndex := AFirstPI;
    while (LParagraphIndex < ADocument.Paragraphs.Count) and
          (ADocument.Paragraphs[LParagraphIndex].BlockType = btTableCell) and
          (ADocument.Paragraphs[LParagraphIndex].TableID = LTableID) do
      Inc(LParagraphIndex);
  end;

begin
  LBase.Init;
  LStringBuilder := TStringBuilder.Create;
  LParagraphIndex := 0;
  if FPretty then
    LNewLine := sLineBreak
  else
    LNewLine := '';
  try
    while LParagraphIndex < ADocument.Paragraphs.Count do
    begin
      LParagraph := ADocument.Paragraphs[LParagraphIndex];

      if LParagraph.BlockType = btHR then
      begin
        LStyleAttribute := '';
        if LParagraph.HRColor <> claNull then
          LStyleAttribute := LStyleAttribute + 'color:' + ColorToHex(LParagraph.HRColor) + ';';
        if LParagraph.HRThickness > 0 then
          LStyleAttribute := LStyleAttribute + Format('height:%.0fpx;', [LParagraph.HRThickness]);
        if LStyleAttribute <> '' then
          LStringBuilder.Append('<hr style="' + LStyleAttribute + '"/>' + LNewLine)
        else
          LStringBuilder.Append('<hr/>' + LNewLine);
        Inc(LParagraphIndex);
      end
      else if LParagraph.BlockType = btImage then
      begin
        LStringBuilder.Append('<img');
        if LParagraph.ImageSource <> '' then
          LStringBuilder.Append(' src="' + LParagraph.ImageSource + '"');
        if LParagraph.ImageWidth > 0 then
          LStringBuilder.Append(' width="' + IntToStr(LParagraph.ImageWidth) + '"');
        if LParagraph.ImageHeight > 0 then
          LStringBuilder.Append(' height="' + IntToStr(LParagraph.ImageHeight) + '"');
        if LParagraph.ImageAlt <> '' then
          LStringBuilder.Append(' alt="' + LParagraph.ImageAlt + '"');
        case LParagraph.Alignment of
          haCenter: LStringBuilder.Append(' align="center"');
          haRight:  LStringBuilder.Append(' align="right"');
        end;
        LStringBuilder.Append('/>' + LNewLine);
        Inc(LParagraphIndex);
      end
      else if LParagraph.BlockType = btBodyText then
      begin
        case LParagraph.Alignment of
          haCenter:  LStringBuilder.Append('<div style="text-align:center;">');
          haRight:   LStringBuilder.Append('<div style="text-align:right;">');
          haJustify: LStringBuilder.Append('<div style="text-align:justify;">');
        end;
        EmitRuns(LParagraph);
        case LParagraph.Alignment of
          haCenter, haRight, haJustify: LStringBuilder.Append('</div>');
        end;
        Inc(LParagraphIndex);
        if (LParagraphIndex < ADocument.Paragraphs.Count) and (ADocument.Paragraphs[LParagraphIndex].BlockType = btBodyText) then
          LStringBuilder.Append('<br>' + LNewLine)
        else
          LStringBuilder.Append(LNewLine);
      end
      else if LParagraph.BlockType = btPre then
      begin
        LStringBuilder.Append('<pre>');
        while (LParagraphIndex < ADocument.Paragraphs.Count) and (ADocument.Paragraphs[LParagraphIndex].BlockType = btPre) do
        begin
          EmitRuns(ADocument.Paragraphs[LParagraphIndex]);
          Inc(LParagraphIndex);
          if (LParagraphIndex < ADocument.Paragraphs.Count) and (ADocument.Paragraphs[LParagraphIndex].BlockType = btPre) then
            LStringBuilder.Append(#10);
        end;
        LStringBuilder.Append('</pre>' + LNewLine);
      end
      else if LParagraph.BlockType = btTableCell then
      begin
        EmitTable(LParagraphIndex);
        // LParagraphIndex is already advanced by EmitTable
      end
      else if LParagraph.BlockType = btLI then
      begin
        EmitListBlock(LParagraph.IndentLevel);
        // LParagraphIndex already advanced by EmitListBlock
      end
      else
      begin
        case LParagraph.Alignment of
          haCenter:  LAlignCSS := 'text-align:center;';
          haRight:   LAlignCSS := 'text-align:right;';
          haJustify: LAlignCSS := 'text-align:justify;';
        else
          LAlignCSS := '';
        end;

        LIndent := '';
        if LParagraph.IndentLevel > 0 then
          LIndent := Format('margin-left:%dpx;', [LParagraph.IndentLevel * 24]);

        LStyleAttribute := '';
        if (LAlignCSS <> '') or (LIndent <> '') then
          LStyleAttribute := ' style="' + LAlignCSS + LIndent + '"';

        case LParagraph.BlockType of
          btH1:
            begin
              LOpenTag := '<h1' + LStyleAttribute + '>';
              LCloseTag := '</h1>';
            end;
          btH2:
            begin
              LOpenTag := '<h2' + LStyleAttribute + '>';
              LCloseTag := '</h2>';
            end;
          btH3:
            begin
              LOpenTag := '<h3' + LStyleAttribute + '>';
              LCloseTag := '</h3>';
            end;
          btH4:
            begin
              LOpenTag := '<h4' + LStyleAttribute + '>';
              LCloseTag := '</h4>';
            end;
          btH5:
            begin
              LOpenTag := '<h5' + LStyleAttribute + '>';
              LCloseTag := '</h5>';
            end;
          btH6:
            begin
              LOpenTag := '<h6' + LStyleAttribute + '>';
              LCloseTag := '</h6>';
            end;
          btBlockquote:
            begin
              LOpenTag := '<blockquote' + LStyleAttribute + '>';
              LCloseTag := '</blockquote>';
            end;
        else
          begin
            LOpenTag := '<p' + LStyleAttribute + '>';
            LCloseTag := '</p>';
          end;
        end;

        LStringBuilder.Append(LOpenTag);
        EmitRuns(LParagraph);
        LStringBuilder.Append(LCloseTag + LNewLine);
        Inc(LParagraphIndex);
      end;
    end;

    Result := LStringBuilder.ToString;
  finally
    LStringBuilder.Free;
  end;
end;

end.
