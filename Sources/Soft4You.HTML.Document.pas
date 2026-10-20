unit Soft4You.HTML.Document;

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
  System.UITypes,
  System.Generics.Collections,
  Soft4You.HTML.Types;

type

  // ===========================================================================
  // TS4YHTMLRun
  // ===========================================================================

  /// <summary>A piece of inline content of a paragraph: a text with one style, a line break, an inline image or a placeholder.</summary>
  TS4YHTMLRun = class
  private
    FDisplayText: string;
    FImageAlt: string;
    FImageHeight: Integer;
    FImageSource: string;
    FImageWidth: Integer;
    FIsImage: Boolean;
    FIsLineBreak: Boolean;
    FIsPlaceholder: Boolean;
    FPlaceholderBorderColor: TAlphaColor;
    FStyle: TS4YHTMLTextStyle;
    FText: string;
  public
    /// <summary>Creates an empty run with the default text style.</summary>
    constructor Create;

    /// <summary>
    /// Creates an independent copy of the run.
    /// </summary>
    /// <returns>A new run that the caller owns.</returns>
    function Clone: TS4YHTMLRun;

    /// <summary>Label shown instead of the raw text when the run is a placeholder. Empty means that the label comes from OnGetPlaceholderLabel or from Text.</summary>
    property DisplayText: string read FDisplayText write FDisplayText;
    /// <summary>Alternative text of the inline image.</summary>
    property ImageAlt: string read FImageAlt write FImageAlt;
    /// <summary>Height of the inline image in pixels; 0 uses the natural height.</summary>
    property ImageHeight: Integer read FImageHeight write FImageHeight;
    /// <summary>Source of the inline image, as written in the src attribute.</summary>
    property ImageSource: string read FImageSource write FImageSource;
    /// <summary>Width of the inline image in pixels; 0 uses the natural width.</summary>
    property ImageWidth: Integer read FImageWidth write FImageWidth;
    /// <summary>True when the run is an inline image.</summary>
    property IsImage: Boolean read FIsImage write FIsImage;
    /// <summary>True when the run is a line break (br).</summary>
    property IsLineBreak: Boolean read FIsLineBreak write FIsLineBreak;
    /// <summary>True when the run is a placeholder, which is edited as a single unit.</summary>
    property IsPlaceholder: Boolean read FIsPlaceholder write FIsPlaceholder;
    /// <summary>Border color of this placeholder; claNull uses the color derived from the placeholder appearance.</summary>
    property PlaceholderBorderColor: TAlphaColor read FPlaceholderBorderColor write FPlaceholderBorderColor;
    /// <summary>Text style of the run.</summary>
    property Style: TS4YHTMLTextStyle read FStyle write FStyle;
    /// <summary>Text of the run. For a placeholder it is the raw text as stored in the HTML.</summary>
    property Text: string read FText write FText;
  end;

  // ===========================================================================
  // TS4YHTMLParagraph
  // ===========================================================================

  /// <summary>A block of the document: a paragraph, a heading, a list item, a table cell, an image, a horizontal rule and so on, with the runs that make up its content.</summary>
  TS4YHTMLParagraph = class
  private
    FBlockType: TS4YHTMLBlockType;
    FAlignment: TS4YHTMLAlignment;
    FIndentLevel: Integer;  // 0..N  (blockquote / list nesting)
    FListOrdered: Boolean;  // true = <ol>, used when BlockType = btLI
    FListIndex: Integer;    // 1-based counter for <ol>
    FHRColor: TAlphaColor;  // claNull = use default
    FHRThickness: Single;   // 0 = use default
    FImageSource: string;
    FImageAlt: string;
    FImageWidth: Integer;   // 0 = natural width from bitmap
    FImageHeight: Integer;  // 0 = natural height from bitmap
    FIsHeader: Boolean;     // <th> -- rendered bold + center
    FTableCol: Integer;     // 0-based column index (table cell paragraphs only)
    FTableCols: Integer;    // total columns in table (table cell paragraphs only)
    FTableColSpan: Integer; // columns covered by the cell, 1 or more (table cell paragraphs only)
    FTableContainers: TArray<TS4YTableCellReference>;  // cells that contain the table, outermost first (nested tables only)
    FTableID: Integer;      // groups cells of same table; 0 = not a cell
    FTableRow: Integer;     // 0-based row index (table cell paragraphs only)
    FTableRowSpan: Integer; // rows covered by the cell, 1 or more (table cell paragraphs only)
    FRuns: TObjectList<TS4YHTMLRun>;
  public
    /// <summary>Creates an empty paragraph of type btBodyText.</summary>
    constructor Create;
    /// <summary>Frees the paragraph and its runs.</summary>
    destructor Destroy; override;

    /// <summary>
    /// Creates an independent copy of the paragraph, runs included.
    /// </summary>
    /// <returns>A new paragraph that the caller owns.</returns>
    function Clone: TS4YHTMLParagraph;
    /// <summary>
    /// Returns the text of the paragraph without any formatting.
    /// </summary>
    /// <returns>The text of the runs in order. Line breaks become sLineBreak and an inline image contributes its alternative text.</returns>
    function PlainText: string;
    /// <summary>
    /// Tells whether the paragraph has no text.
    /// </summary>
    /// <returns>True when no run has text. Line breaks are ignored; an inline image counts as content because its Text is the object replacement character.</returns>
    function IsEmpty: Boolean;
    /// <summary>
    /// Tells whether the paragraph belongs to a table cell.
    /// </summary>
    /// <returns>True when TableID is not 0.</returns>
    function IsTableCell: Boolean;
    /// <summary>
    /// Tells whether the paragraph belongs to a table that sits inside a cell of another table.
    /// </summary>
    /// <returns>True when TableContainers is not empty.</returns>
    function IsNestedTableCell: Boolean;
    /// <summary>
    /// Tells whether the paragraph is in a table, directly or inside a table nested in one of its cells.
    /// </summary>
    /// <param name="ATableID">Identifier of the table.</param>
    /// <returns>True when ATableID is the table of the paragraph or one of the tables that contain it.</returns>
    function BelongsToTable(ATableID: Integer): Boolean;

    /// <summary>Horizontal alignment of the paragraph.</summary>
    property Alignment: TS4YHTMLAlignment read FAlignment write FAlignment;
    /// <summary>Kind of block that the paragraph represents.</summary>
    property BlockType: TS4YHTMLBlockType read FBlockType write FBlockType;
    /// <summary>Color of the horizontal rule, when BlockType is btHR; claNull uses the default color.</summary>
    property HRColor: TAlphaColor read FHRColor write FHRColor;  // claNull = use default
    /// <summary>Thickness of the horizontal rule in pixels, when BlockType is btHR; 0 uses the default thickness.</summary>
    property HRThickness: Single read FHRThickness write FHRThickness;   // 0 = use default
    /// <summary>Alternative text of the image, when BlockType is btImage.</summary>
    property ImageAlt: string read FImageAlt write FImageAlt;
    /// <summary>Height of the image in pixels, when BlockType is btImage; 0 uses the natural height.</summary>
    property ImageHeight: Integer read FImageHeight write FImageHeight;  // 0 = natural height from bitmap
    /// <summary>Source of the image, when BlockType is btImage, as written in the src attribute.</summary>
    property ImageSource: string read FImageSource write FImageSource;
    /// <summary>Width of the image in pixels, when BlockType is btImage; 0 uses the natural width.</summary>
    property ImageWidth: Integer read FImageWidth write FImageWidth;   // 0 = natural width from bitmap
    /// <summary>Nesting level of a list item or of a block quote; 0 is the outermost level.</summary>
    property IndentLevel: Integer read FIndentLevel write FIndentLevel;  // 0..N  (blockquote / list nesting)
    /// <summary>True when the paragraph is a table header cell (th), drawn in bold and centered.</summary>
    property IsHeader: Boolean read FIsHeader write FIsHeader;     // <th> -- rendered bold + center
    /// <summary>Number of the item in an ordered list, starting from 1.</summary>
    property ListIndex: Integer read FListIndex write FListIndex;    // 1-based counter for <ol>
    /// <summary>True when the list item belongs to an ordered list (ol), False for a bulleted list (ul).</summary>
    property ListOrdered: Boolean read FListOrdered write FListOrdered;  // true = <ol>, used when BlockType = btLI
    /// <summary>Runs that make up the content of the paragraph. The paragraph owns them.</summary>
    property Runs: TObjectList<TS4YHTMLRun> read FRuns;
    /// <summary>Zero-based column of the cell, when IsTableCell is True.</summary>
    property TableCol: Integer read FTableCol write FTableCol;     // 0-based column index (table cell paragraphs only)
    /// <summary>Number of columns of the table that the cell belongs to, when IsTableCell is True.</summary>
    property TableCols: Integer read FTableCols write FTableCols;    // total columns in table (table cell paragraphs only)
    /// <summary>
    /// Number of columns that the cell covers, when IsTableCell is True; 1 for a normal cell.
    /// </summary>
    /// <remarks>
    /// The cell sits in the column TableCol; the columns to its right that it covers have no paragraph of their own.
    /// </remarks>
    property TableColSpan: Integer read FTableColSpan write FTableColSpan;  // columns covered by the cell, 1 or more (table cell paragraphs only)
    /// <summary>
    /// The cells that contain the table of this paragraph, from the outermost to the innermost; empty when the table is not inside another table.
    /// </summary>
    /// <remarks>
    /// TableID, TableRow and TableCol always describe the innermost cell, the one that holds the paragraph.
    /// </remarks>
    property TableContainers: TArray<TS4YTableCellReference> read FTableContainers write FTableContainers;
    /// <summary>Identifier that groups the cells of the same table; 0 when the paragraph is not a table cell.</summary>
    property TableID: Integer read FTableID write FTableID;      // groups cells of same table; 0 = not a cell
    /// <summary>Zero-based row of the cell, when IsTableCell is True.</summary>
    property TableRow: Integer read FTableRow write FTableRow;     // 0-based row index (table cell paragraphs only)
    /// <summary>
    /// Number of rows that the cell covers, when IsTableCell is True; 1 for a normal cell.
    /// </summary>
    /// <remarks>
    /// The cell sits in the row TableRow; the rows below it that it covers have no paragraph of their own in the covered columns.
    /// </remarks>
    property TableRowSpan: Integer read FTableRowSpan write FTableRowSpan;  // rows covered by the cell, 1 or more (table cell paragraphs only)
  end;

  // ===========================================================================
  // TS4YHTMLDocument
  // ===========================================================================

  /// <summary>A parsed HTML document: the ordered list of its blocks.</summary>
  TS4YHTMLDocument = class
  private
    FParagraphs: TObjectList<TS4YHTMLParagraph>;
  public
    /// <summary>Creates an empty document.</summary>
    constructor Create;
    /// <summary>Frees the document and its paragraphs.</summary>
    destructor Destroy; override;

    /// <summary>Removes every paragraph.</summary>
    procedure Clear;
    /// <summary>
    /// Creates an independent copy of the document, paragraphs and runs included.
    /// </summary>
    /// <returns>A new document that the caller owns.</returns>
    function Clone: TS4YHTMLDocument;

    /// <summary>Blocks of the document in order. The document owns them.</summary>
    property Paragraphs: TObjectList<TS4YHTMLParagraph> read FParagraphs;
  end;

/// <summary>
/// Returns a new table identifier, unique in the process.
/// </summary>
/// <returns>The next value of a counter shared by the parser and the editor.</returns>
function NextTableID: Integer;

implementation

var
  GTableIDCounter: Integer = 0;

function NextTableID: Integer;
begin
  Inc(GTableIDCounter);
  Result := GTableIDCounter;
end;

// -----------------------------------------------------------------------------
// TS4YHTMLRun
// -----------------------------------------------------------------------------

constructor TS4YHTMLRun.Create;
begin
  inherited;
  FStyle.Init;
end;

function TS4YHTMLRun.Clone: TS4YHTMLRun;
begin
  Result := TS4YHTMLRun.Create;
  Result.DisplayText := DisplayText;
  Result.ImageAlt := ImageAlt;
  Result.ImageHeight := ImageHeight;
  Result.ImageSource := ImageSource;
  Result.ImageWidth := ImageWidth;
  Result.IsImage := IsImage;
  Result.IsLineBreak := IsLineBreak;
  Result.IsPlaceholder := IsPlaceholder;
  Result.PlaceholderBorderColor := PlaceholderBorderColor;
  Result.Style := Style;
  Result.Text := Text;
end;

// -----------------------------------------------------------------------------
// TS4YHTMLParagraph
// -----------------------------------------------------------------------------

constructor TS4YHTMLParagraph.Create;
begin
  inherited;
  FRuns := TObjectList<TS4YHTMLRun>.Create(True);
  FBlockType := btBodyText;
  FTableColSpan := 1;
  FTableRowSpan := 1;
end;

destructor TS4YHTMLParagraph.Destroy;
begin
  FRuns.Free;
  inherited;
end;

function TS4YHTMLParagraph.Clone: TS4YHTMLParagraph;
var
  LRun: TS4YHTMLRun;
begin
  Result := TS4YHTMLParagraph.Create;
  Result.BlockType := BlockType;
  Result.Alignment := Alignment;
  Result.IndentLevel := IndentLevel;
  Result.ListOrdered := ListOrdered;
  Result.ListIndex := ListIndex;
  Result.HRColor := HRColor;
  Result.HRThickness := HRThickness;
  Result.ImageSource := ImageSource;
  Result.ImageAlt := ImageAlt;
  Result.ImageWidth := ImageWidth;
  Result.ImageHeight := ImageHeight;
  Result.IsHeader := IsHeader;
  Result.TableCol := TableCol;
  Result.TableCols := TableCols;
  Result.TableColSpan := TableColSpan;
  Result.TableContainers := Copy(TableContainers);
  Result.TableID := TableID;
  Result.TableRow := TableRow;
  Result.TableRowSpan := TableRowSpan;
  for LRun in Runs do
    Result.Runs.Add(LRun.Clone);
end;

function TS4YHTMLParagraph.PlainText: string;
var
  LRun: TS4YHTMLRun;
begin
  Result := '';
  for LRun in Runs do
  begin
    if LRun.IsLineBreak then
      Result := Result + sLineBreak
    else if LRun.IsImage then
      Result := Result + LRun.ImageAlt
    else
      Result := Result + LRun.Text;
  end;
end;

function TS4YHTMLParagraph.IsEmpty: Boolean;
var
  LRun: TS4YHTMLRun;
begin
  for LRun in Runs do
    if (not LRun.IsLineBreak) and (LRun.Text <> '') then
      Exit(False);
  Result := True;
end;

function TS4YHTMLParagraph.IsTableCell: Boolean;
begin
  Result := FTableID <> 0;
end;

function TS4YHTMLParagraph.IsNestedTableCell: Boolean;
begin
  Result := Length(FTableContainers) > 0;
end;

function TS4YHTMLParagraph.BelongsToTable(ATableID: Integer): Boolean;
var
  LContainer: TS4YTableCellReference;
begin
  Result := (FTableID <> 0) and (FTableID = ATableID);
  for LContainer in FTableContainers do
    if LContainer.TableID = ATableID then
      Result := True;
end;

// -----------------------------------------------------------------------------
// TS4YHTMLDocument
// -----------------------------------------------------------------------------

constructor TS4YHTMLDocument.Create;
begin
  inherited;
  FParagraphs := TObjectList<TS4YHTMLParagraph>.Create(True);
end;

destructor TS4YHTMLDocument.Destroy;
begin
  FParagraphs.Free;
  inherited;
end;

procedure TS4YHTMLDocument.Clear;
begin
  FParagraphs.Clear;
end;

function TS4YHTMLDocument.Clone: TS4YHTMLDocument;
var
  LParagraph: TS4YHTMLParagraph;
begin
  Result := TS4YHTMLDocument.Create;
  for LParagraph in Paragraphs do
    Result.Paragraphs.Add(LParagraph.Clone);
end;

end.
