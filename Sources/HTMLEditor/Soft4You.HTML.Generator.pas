unit Soft4You.HTML.Generator;

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
  Soft4You.HTML.Types,
  Soft4You.HTML.Document;

type

  // ===========================================================================
  // TS4YHTMLGenerator
  // ===========================================================================

  /// <summary>Converts a TS4YHTMLDocument into HTML text.</summary>
  TS4YHTMLGenerator = class
  private
    FPretty: Boolean;
    FImageSourceConverter: TFunc<string, string>;
    FPlaceholderStyle: TS4YPlaceholderGeneratorStyle;
    function ConvertImageSource(const ASource: string): string;
    function HtmlEncode(const AText: string): string;
    function ColorToHex(AColor: TAlphaColor): string;
    function BorderSideToCSS(const ASide: TS4YTableBorderSide): string;
    function StyleDiff(const ACurrentStyle, ABaseStyle: TS4YHTMLTextStyle): string;
  public
    /// <summary>
    /// Writes the document as HTML.
    /// </summary>
    /// <param name="ADocument">Document to write.</param>
    /// <returns>The HTML of the content, without the html and body elements.</returns>
    function Generate(ADocument: TS4YHTMLDocument): string;

    /// <summary>
    /// Function that maps the source of each image to the value written in its src attribute.
    /// </summary>
    /// <remarks>
    /// It is called once for every image. When it is not assigned the source is written as it is.
    /// </remarks>
    property ImageSourceConverter: TFunc<string, string> read FImageSourceConverter write FImageSourceConverter;
    /// <summary>
    /// Colors and sizes used to write the placeholders as styled elements.
    /// </summary>
    /// <remarks>
    /// The colors of a single placeholder take precedence over these values.
    /// </remarks>
    property PlaceholderStyle: TS4YPlaceholderGeneratorStyle read FPlaceholderStyle write FPlaceholderStyle;
    /// <summary>
    /// Tells whether the output is formatted for reading.
    /// </summary>
    /// <remarks>
    /// When True the blocks are separated by line breaks and the rows of a table are indented. The default is False.
    /// </remarks>
    property Pretty: Boolean read FPretty write FPretty;
  end;

implementation

// -----------------------------------------------------------------------------
// TS4YHTMLGenerator
// -----------------------------------------------------------------------------

function TS4YHTMLGenerator.ConvertImageSource(const ASource: string): string;
begin
  Result := ASource;

  if Assigned(FImageSourceConverter) then
    Result := FImageSourceConverter(ASource);
end;

function TS4YHTMLGenerator.HtmlEncode(const AText: string): string;
begin
  Result := AText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;');
end;

function TS4YHTMLGenerator.ColorToHex(AColor: TAlphaColor): string;
begin
  Result := Format('#%.2x%.2x%.2x', [TAlphaColorRec(AColor).R, TAlphaColorRec(AColor).G, TAlphaColorRec(AColor).B]);
end;

// The border of one side as the value of a border style: none, or width, solid and color
function TS4YHTMLGenerator.BorderSideToCSS(const ASide: TS4YTableBorderSide): string;
begin
  if ASide.IsVisible then
    Result := Format('%.0fpx solid %s', [ASide.Width, ColorToHex(ASide.Color)])
  else
    Result := 'none';
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
  LBlockEnd: Integer;  // the paragraphs from LParagraphIndex up to here are being written

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
          LStringBuilder.Append(' src="' + ConvertImageSource(LEmitRun.ImageSource) + '"');

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
    LListItem: TS4YHTMLParagraph;
    LListTag: string;
    LFirstOrdered: Boolean;
    LContinueList: Boolean;
  begin
    LListItem := ADocument.Paragraphs[LParagraphIndex];
    LFirstOrdered := LListItem.ListOrdered;

    if LFirstOrdered then
      LListTag := 'ol'
    else
      LListTag := 'ul';

    LStringBuilder.Append('<' + LListTag + '>' + LNewLine);
    LContinueList := True;

    while LContinueList and
          (LParagraphIndex < LBlockEnd) and
          (ADocument.Paragraphs[LParagraphIndex].BlockType = btLI) and
          (ADocument.Paragraphs[LParagraphIndex].IndentLevel >= ABaseLevel) do
    begin
      LListItem := ADocument.Paragraphs[LParagraphIndex];

      if LListItem.IndentLevel > ABaseLevel then
      begin
        // Item jumps deeper without a parent li -- open sub-list at its actual level
        EmitListBlock(LListItem.IndentLevel);
      end
      else if LListItem.ListOrdered <> LFirstOrdered then
      begin
        // Different list type at same level -- end this list; outer loop starts a new one
        LContinueList := False;
      end
      else
      begin
        // Emit list item
        LStringBuilder.Append('<li>');
        EmitRuns(LListItem);
        Inc(LParagraphIndex);

        // If next items are deeper, nest a sub-list inside this <li>
        if (LParagraphIndex < LBlockEnd) and
           (ADocument.Paragraphs[LParagraphIndex].BlockType = btLI) and
           (ADocument.Paragraphs[LParagraphIndex].IndentLevel > ABaseLevel) then
        begin
          LStringBuilder.Append(LNewLine);
          EmitListBlock(ADocument.Paragraphs[LParagraphIndex].IndentLevel);
        end;

        LStringBuilder.Append('</li>' + LNewLine);
      end;
    end;

    LStringBuilder.Append('</' + LListTag + '>' + LNewLine);
  end;

  procedure EmitBlocks(AEndIndex, ATableID: Integer); forward;

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
    LCellSpans: string;
    LScanIndex: Integer;
    LEndIndex: Integer;
    LCellEnd: Integer;
    LTableStyle: string;
    LTableAttributes: string;
    LFirstCell: TS4YHTMLParagraph;

    // A width as written in a style: 120px or 30%
    function LengthToCSS(const ALength: TS4YTableLength): string;
    begin
      if ALength.Kind = tlkPercent then
        Result := FloatToStr(Round(ALength.Value * 100) / 100, TFormatSettings.Invariant) + '%'
      else
        Result := Format('%.0fpx', [ALength.Value]);
    end;

    // True when a cell that starts in another position covers the given one
    function IsCovered(ARow, ACol: Integer): Boolean;
    var
      LCoverIndex: Integer;
      LCoverCell: TS4YHTMLParagraph;
    begin
      Result := False;

      for LCoverIndex := AFirstPI to LEndIndex - 1 do
      begin
        LCoverCell := ADocument.Paragraphs[LCoverIndex];

        if (LCoverCell.TableID = LTableID) and (LCoverCell.TableRow <= ARow) and (ARow < LCoverCell.TableRow + LCoverCell.TableRowSpan) and
           (LCoverCell.TableCol <= ACol) and (ACol < LCoverCell.TableCol + LCoverCell.TableColSpan) then
          Result := True;
      end;
    end;

  begin
    LTableID := ADocument.Paragraphs[AFirstPI].TableID;
    LCols := ADocument.Paragraphs[AFirstPI].TableCols;

    if LCols < 1 then
      LCols := 1;

    LMaximumRow := 0;
    LScanIndex := AFirstPI;

    while (LScanIndex < ADocument.Paragraphs.Count) and
          ADocument.Paragraphs[LScanIndex].BelongsToTable(LTableID) do
    begin
      // The paragraphs of the tables nested in the cells belong to the extent of the table but not to its grid
      if (ADocument.Paragraphs[LScanIndex].TableID = LTableID) and
         (ADocument.Paragraphs[LScanIndex].TableRow > LMaximumRow) then
        LMaximumRow := ADocument.Paragraphs[LScanIndex].TableRow;

      Inc(LScanIndex);
    end;

    LEndIndex := LScanIndex;

    // The width of the table is 100% when it was not set; the border is on unless the table was written without it
    LFirstCell := ADocument.Paragraphs[AFirstPI];

    // The cells touch (collapsed borders) unless the table has a space between its cells
    if LFirstCell.TableCellSpacing > 0 then
      LTableStyle := Format('border-collapse:separate;border-spacing:%.0fpx;', [LFirstCell.TableCellSpacing])
    else
      LTableStyle := 'border-collapse:collapse;';

    if LFirstCell.TableWidth.IsAuto then
      LTableStyle := LTableStyle + 'width:100%'
    else
      LTableStyle := LTableStyle + 'width:' + LengthToCSS(LFirstCell.TableWidth);

    if LFirstCell.TableMaximumWidth > 0 then
      LTableStyle := LTableStyle + ';max-width:' + LengthToCSS(TS4YTableLength.Pixels(LFirstCell.TableMaximumWidth));

    LTableAttributes := ' border="1"';
    if not LFirstCell.TableHasBorder then
      LTableAttributes := ' border="0"';

    // Outlook ignores border-spacing, so the attribute is written too
    if LFirstCell.TableCellSpacing > 0 then
      LTableAttributes := LTableAttributes + Format(' cellspacing="%.0f"', [LFirstCell.TableCellSpacing]);

    case LFirstCell.TableAlignment of
      haCenter:
        begin
          LTableAttributes := LTableAttributes + ' align="center"';
          LTableStyle := LTableStyle + ';margin-left:auto;margin-right:auto';
        end;
      haRight:
        begin
          LTableAttributes := LTableAttributes + ' align="right"';
          LTableStyle := LTableStyle + ';margin-left:auto';
        end;
    end;

    LStringBuilder.Append('<table' + LTableAttributes + ' style="' + LTableStyle + '">' + LNewLine);

    for LRow := 0 to LMaximumRow do
    begin
      if FPretty then
        LStringBuilder.Append('  ');

      LStringBuilder.Append('<tr>' + LNewLine);
      LCol := 0;

      while LCol < LCols do
      begin
        LCell := nil;
        LScanIndex := AFirstPI;

        while (LScanIndex < ADocument.Paragraphs.Count) and (LCell = nil) do
        begin
          if ADocument.Paragraphs[LScanIndex].IsTableCell and
             (ADocument.Paragraphs[LScanIndex].TableID = LTableID) and
             (ADocument.Paragraphs[LScanIndex].TableRow = LRow) and
             (ADocument.Paragraphs[LScanIndex].TableCol = LCol) then
            LCell := ADocument.Paragraphs[LScanIndex]
          else
            Inc(LScanIndex);
        end;

        if LCell = nil then
        begin
          // A position covered by a colspan or rowspan cell has no <td>
          if not IsCovered(LRow, LCol) then
          begin
            if FPretty then
              LStringBuilder.Append('    ');

            LStringBuilder.Append('<td></td>' + LNewLine);
          end;

          Inc(LCol);
        end
        else
        begin
          if LCell.IsHeader then
            LCellTag := 'th'
          else
            LCellTag := 'td';

          // The padding is written in the shortest form; the default (4px) is written when the cell has none of its own
          LCellStyle := 'padding:4px;';

          if LCell.TableCellPadding.IsSet then
          begin
            if (LCell.TableCellPadding.Top = LCell.TableCellPadding.Right) and
               (LCell.TableCellPadding.Top = LCell.TableCellPadding.Bottom) and
               (LCell.TableCellPadding.Top = LCell.TableCellPadding.Left) then
              LCellStyle := Format('padding:%.0fpx;', [LCell.TableCellPadding.Top])
            else
              LCellStyle := Format('padding:%.0fpx %.0fpx %.0fpx %.0fpx;', [LCell.TableCellPadding.Top,
                LCell.TableCellPadding.Right, LCell.TableCellPadding.Bottom, LCell.TableCellPadding.Left]);
          end;

          case LCell.Alignment of
            haCenter:  LCellStyle := LCellStyle + 'text-align:center;';
            haRight:   LCellStyle := LCellStyle + 'text-align:right;';
            haJustify: LCellStyle := LCellStyle + 'text-align:justify;';
          else
            // A th is centered unless it says otherwise
            if LCell.IsHeader then
              LCellStyle := LCellStyle + 'text-align:left;';
          end;

          if not LCell.TableCellWidth.IsAuto then
            LCellStyle := LCellStyle + 'width:' + LengthToCSS(LCell.TableCellWidth) + ';';

          if LCell.TableCellBackgroundColor <> claNull then
            LCellStyle := LCellStyle + 'background-color:' + ColorToHex(LCell.TableCellBackgroundColor) + ';';

          // Borders are written only when the cell has its own; the four sides are given, in the shortest form
          if LCell.TableCellBorders.IsSet then
          begin
            if LCell.TableCellBorders.Top.Equals(LCell.TableCellBorders.Right) and
               LCell.TableCellBorders.Top.Equals(LCell.TableCellBorders.Bottom) and
               LCell.TableCellBorders.Top.Equals(LCell.TableCellBorders.Left) then
              LCellStyle := LCellStyle + 'border:' + BorderSideToCSS(LCell.TableCellBorders.Top) + ';'
            else
              LCellStyle := LCellStyle +
                'border-top:' + BorderSideToCSS(LCell.TableCellBorders.Top) + ';' +
                'border-right:' + BorderSideToCSS(LCell.TableCellBorders.Right) + ';' +
                'border-bottom:' + BorderSideToCSS(LCell.TableCellBorders.Bottom) + ';' +
                'border-left:' + BorderSideToCSS(LCell.TableCellBorders.Left) + ';';
          end;

          case LCell.TableCellVerticalAlignment of
            tvaMiddle: LCellStyle := LCellStyle + 'vertical-align:middle;';
            tvaBottom: LCellStyle := LCellStyle + 'vertical-align:bottom;';
          end;

          if FPretty then
            LStringBuilder.Append('    ');

          LCellSpans := '';

          if LCell.TableColSpan > 1 then
            LCellSpans := LCellSpans + ' colspan="' + IntToStr(LCell.TableColSpan) + '"';

          if LCell.TableRowSpan > 1 then
            LCellSpans := LCellSpans + ' rowspan="' + IntToStr(LCell.TableRowSpan) + '"';

          LStringBuilder.Append('<' + LCellTag + LCellSpans + ' style="' + LCellStyle + '">');

          // The paragraphs that follow the first one and have the same position belong to the same cell
          LCellEnd := LScanIndex + 1;

          while (LCellEnd < LEndIndex) and ADocument.Paragraphs[LCellEnd].IsInCell(LTableID, LRow, LCol) do
            Inc(LCellEnd);

          if (LCellEnd = LScanIndex + 1) and (LCell.BlockType = btTableCell) then
            EmitRuns(LCell)
          else
          begin
            LParagraphIndex := LScanIndex;
            EmitBlocks(LCellEnd, LTableID);
          end;

          LStringBuilder.Append('</' + LCellTag + '>' + LNewLine);

          if LCell.TableColSpan > 1 then
            Inc(LCol, LCell.TableColSpan)
          else
            Inc(LCol);
        end;
      end;

      if FPretty then
        LStringBuilder.Append('  ');

      LStringBuilder.Append('</tr>' + LNewLine);
    end;

    LStringBuilder.Append('</table>' + LNewLine);
    LParagraphIndex := LEndIndex;
  end;

  procedure EmitBlocks(AEndIndex, ATableID: Integer);
  var
    LSavedEnd: Integer;
  begin
    LSavedEnd := LBlockEnd;
    LBlockEnd := AEndIndex;

    while LParagraphIndex < LBlockEnd do
    begin
      LParagraph := ADocument.Paragraphs[LParagraphIndex];

      if (ATableID <> 0) and (LParagraph.TableID = ATableID) and (LParagraph.Runs.Count = 0) and
         (((LParagraphIndex + 1 < LBlockEnd) and (ADocument.Paragraphs[LParagraphIndex + 1].TableID <> ATableID)) or
          ((LParagraphIndex + 1 = LBlockEnd) and (LParagraphIndex > 0) and
           (ADocument.Paragraphs[LParagraphIndex - 1].TableID <> ATableID))) then
      begin
        // The empty paragraph before or after a table nested in the cell is not written: it only holds the
        // attributes of the cell, or a place for the caret
        Inc(LParagraphIndex);
      end
      else if LParagraph.IsTableCell and (LParagraph.TableID <> ATableID) then
      begin
        EmitTable(LParagraphIndex);
        // LParagraphIndex is already advanced by EmitTable
      end
      else if LParagraph.BlockType = btHR then
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
          LStringBuilder.Append(' src="' + ConvertImageSource(LParagraph.ImageSource) + '"');

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

        if (LParagraphIndex < LBlockEnd) and (ADocument.Paragraphs[LParagraphIndex].BlockType = btBodyText) then
          LStringBuilder.Append('<br>' + LNewLine)
        else
          LStringBuilder.Append(LNewLine);
      end
      else if LParagraph.BlockType = btPre then
      begin
        LStringBuilder.Append('<pre>');

        while (LParagraphIndex < LBlockEnd) and (ADocument.Paragraphs[LParagraphIndex].BlockType = btPre) do
        begin
          EmitRuns(ADocument.Paragraphs[LParagraphIndex]);
          Inc(LParagraphIndex);

          if (LParagraphIndex < LBlockEnd) and (ADocument.Paragraphs[LParagraphIndex].BlockType = btPre) then
            LStringBuilder.Append(#10);
        end;

        LStringBuilder.Append('</pre>' + LNewLine);
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

    LBlockEnd := LSavedEnd;
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
    EmitBlocks(ADocument.Paragraphs.Count, 0);

    Result := LStringBuilder.ToString;
  finally
    LStringBuilder.Free;
  end;
end;

end.
