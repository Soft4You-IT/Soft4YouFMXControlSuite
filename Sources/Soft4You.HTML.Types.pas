unit Soft4You.HTML.Types;

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
  System.Math,
  System.UITypes,
  System.UIConsts;

const
  /// <summary>Default font family of the editor. Empty means the platform default font (Segoe UI, Helvetica Neue, Roboto).</summary>
  S_EDITOR_FONT_NAME = ''; // '' = platform default (Segoe UI / Helvetica / Roboto)
  /// <summary>Default font size of the editor, in points.</summary>
  C_EDITOR_FONT_SIZE = 12.0; // pt

  // Preset font sizes
  /// <summary>Preset font size: very small, in points.</summary>
  C_FONT_SIZE_VERY_SMALL = 8.0;
  /// <summary>Preset font size: small, in points.</summary>
  C_FONT_SIZE_SMALL      = 10.0;
  /// <summary>Preset font size: medium (the default size), in points.</summary>
  C_FONT_SIZE_MEDIUM     = 12.0;
  /// <summary>Preset font size: large, in points.</summary>
  C_FONT_SIZE_LARGE      = 14.0;
  /// <summary>Preset font size: very large, in points.</summary>
  C_FONT_SIZE_VERY_LARGE = 18.0;
  /// <summary>Preset font size: huge, in points.</summary>
  C_FONT_SIZE_HUGE       = 24.0;

resourcestring
  S_FONT_SIZE_VERY_SMALL = 'Molto piccolo';
  S_FONT_SIZE_SMALL      = 'Piccolo';
  S_FONT_SIZE_MEDIUM     = 'Normale';
  S_FONT_SIZE_LARGE      = 'Grande';
  S_FONT_SIZE_VERY_LARGE = 'Molto grande';
  S_FONT_SIZE_HUGE       = 'Enorme';

const
  /// <summary>Color of the border of a table cell when the table has borders and the cell does not say otherwise.</summary>
  C_DEFAULT_TABLE_BORDER_COLOR = $FFB0B0B0;
  /// <summary>Width of the border of a table cell, in pixels, when the table has borders and the cell does not say otherwise.</summary>
  C_DEFAULT_TABLE_BORDER_WIDTH = 1.0;
  /// <summary>Largest space between the cells of a table, in pixels.</summary>
  C_MAXIMUM_TABLE_CELL_SPACING = 50.0;

// ===========================================================================
// Enumerations
// ===========================================================================

type

  /// <summary>
  /// Horizontal alignment of a paragraph.
  /// </summary>
  /// <remarks>
  /// haLeft, haCenter and haRight align the lines; haJustify stretches every line but the last one to the full width.
  /// </remarks>
  TS4YHTMLAlignment = (haLeft, haCenter, haRight, haJustify);

  /// <summary>
  /// Kind of block that a paragraph of the document represents.
  /// </summary>
  /// <remarks>
  /// btParagraph and btBodyText are plain text blocks; btH1 to btH6 are headings; btBlockquote is an indented quote;
  /// btLI is a list item (the list type is given by the paragraph, btUL and btOL are the list containers used while parsing);
  /// btHR is a horizontal rule; btImage is a block-level image; btTableCell is plain text inside a table cell (a cell can also hold headings, lists and other blocks); btPre is preformatted text.
  /// </remarks>
  TS4YHTMLBlockType = (btParagraph, btH1, btH2, btH3, btH4, btH5, btH6,
    btBlockquote, btUL, btOL, btLI, btHR, btImage, btTableCell, btBodyText, btPre);

  /// <summary>
  /// Paragraph format offered to the user, used by SetCurrentParagraphFormat and reported in the editor state.
  /// </summary>
  /// <remarks>
  /// It is the subset of block types that the user can choose for a paragraph: body text, paragraph, headings 1 to 6 and preformatted text.
  /// </remarks>
  TS4YParagraphFormat = (pfBodyText, pfParagraph, pfH1, pfH2, pfH3, pfH4, pfH5, pfH6, pfPre);

  /// <summary>
  /// How a relative local image path is resolved.
  /// </summary>
  /// <remarks>
  /// ipmApplication: as the operating system does, relative to the current directory of the process.
  /// ipmDocument: relative to the folder of the document (DocumentPath).
  /// </remarks>
  TS4YImagePathMode = (ipmApplication, ipmDocument);

  /// <summary>
  /// Which local files an image source may point to.
  /// </summary>
  /// <remarks>
  /// liaAnywhere: any file the process can read.
  /// liaDocumentFolder: only files inside DocumentPath or its subfolders; relative segments, file: URLs and network paths are checked on the resolved path.
  /// Use liaDocumentFolder when the content comes from somebody else (for example a received e-mail).
  /// </remarks>
  TS4YLocalImageAccess = (liaAnywhere, liaDocumentFolder);

  /// <summary>
  /// Options of SaveToFile.
  /// </summary>
  /// <remarks>
  /// Call Init first, then set what differs from the defaults.
  /// </remarks>
  TS4YSaveOptions = record
    /// <summary>
    /// Copy the existing local images next to the saved file and point the saved HTML to the copies.
    /// </summary>
    /// <remarks>
    /// Ignored when AutoLoadLocalImages is False or when OnBeforeLoadImage refuses the image. Remote, data: and missing sources are left as they are.
    /// </remarks>
    CopyImages: Boolean;
    /// <summary>
    /// Name of the subfolder that receives the copied images. Empty means the file name followed by _files.
    /// </summary>
    ImagesFolderName: string;
    /// <summary>
    /// After saving, make the document itself point to the copies of the images.
    /// </summary>
    /// <remarks>
    /// When False the document keeps pointing to the original images and DocumentPath does not move.
    /// </remarks>
    UpdateModel: Boolean;
    /// <summary>
    /// Sets all options to their defaults (nothing is copied).
    /// </summary>
    procedure Init;
  end;

  // ===========================================================================
  // Text style
  // ===========================================================================

  /// <summary>
  /// Character formatting of a run of text.
  /// </summary>
  /// <remarks>
  /// Call Init to get the default style before setting individual fields.
  /// </remarks>
  TS4YHTMLTextStyle = record
    /// <summary>Font family. Empty means the default font of the editor.</summary>
    FontName: string;
    /// <summary>Font size in points.</summary>
    FontSize: Single; // pt
    /// <summary>Bold text.</summary>
    Bold: Boolean;
    /// <summary>Italic text.</summary>
    Italic: Boolean;
    /// <summary>Underlined text.</summary>
    Underline: Boolean;
    /// <summary>Strikethrough text.</summary>
    StrikeOut: Boolean;
    /// <summary>Superscript text.</summary>
    Superscript: Boolean;
    /// <summary>Subscript text.</summary>
    Subscript: Boolean;
    /// <summary>Text color. claNull means the default font color of the editor.</summary>
    Color: TAlphaColor;
    /// <summary>Background (highlight) color behind the text. claNull means transparent.</summary>
    BackgroundColor: TAlphaColor; // claNull = transparent
    /// <summary>Target of the hyperlink the text belongs to. Empty means the text is not a link.</summary>
    LinkURL: string;
    /// <summary>Sets the style to the editor defaults: default font and size, no emphasis, no colors, no link.</summary>
    procedure Init;
    /// <summary>
    /// Compares two styles.
    /// </summary>
    /// <param name="AOther">The style to compare with.</param>
    /// <returns>True when all fields are equal (font sizes within 0.01 pt).</returns>
    function EqualsFormat(const AOther: TS4YHTMLTextStyle): Boolean;
  end;

  // ===========================================================================
  // Placeholder generation style (passed from TS4YHTMLEditor to TS4YHTMLGenerator)
  // ===========================================================================

  /// <summary>
  /// Appearance of the placeholders in the generated HTML.
  /// </summary>
  /// <remarks>
  /// Filled by the editor from PlaceholderAppearance and passed to the HTML generator.
  /// </remarks>
  TS4YPlaceholderGeneratorStyle = record
    /// <summary>Background color of the placeholder.</summary>
    FillColor: TAlphaColor;
    /// <summary>Text color of the placeholder.</summary>
    TextColor: TAlphaColor;
    /// <summary>Border color of the placeholder.</summary>
    BorderColor: TAlphaColor;
    /// <summary>Corner radius of the placeholder, in pixels.</summary>
    BorderRadius: Single;
    /// <summary>Left and right padding inside the placeholder, in pixels.</summary>
    HorizontalPadding: Single;
    /// <summary>Top and bottom padding inside the placeholder, in pixels.</summary>
    VerticalPadding: Single;
    /// <summary>Draw the placeholder text in bold.</summary>
    Bold: Boolean;
    /// <summary>Clears all fields (colors claNull, sizes 0, not bold).</summary>
    procedure Init;
  end;

  // ===========================================================================
  // Caret position  (paragraph / run / char index)
  // ===========================================================================

  /// <summary>
  /// A position in the document: a character offset inside a run of a paragraph.
  /// </summary>
  /// <remarks>
  /// It is the unit of the caret and of the selection. The position is relative to the run structure, which can change when adjacent runs with the same style are merged.
  /// </remarks>
  TS4YDocumentPosition = record
    /// <summary>Index of the paragraph. -1 means the position is not valid.</summary>
    ParagraphIndex: Integer; // -1 = invalid
    /// <summary>Index of the run inside the paragraph.</summary>
    RunIndex: Integer;
    /// <summary>Character offset inside the text of the run. 0 means before the first character.</summary>
    CharIndex: Integer; // 0 = before first char of run
    /// <summary>
    /// Returns a position that is not valid (paragraph index -1).
    /// </summary>
    class function Invalid: TS4YDocumentPosition; static; inline;
    /// <summary>
    /// Creates a position.
    /// </summary>
    /// <param name="AParagraphIndex">Index of the paragraph.</param>
    /// <param name="ARunIndex">Index of the run in the paragraph.</param>
    /// <param name="ACharIndex">Character offset in the run.</param>
    class function At(AParagraphIndex, ARunIndex, ACharIndex: Integer): TS4YDocumentPosition; static; inline;
    /// <summary>
    /// Tells whether the position refers to a paragraph.
    /// </summary>
    /// <returns>True when ParagraphIndex is not negative.</returns>
    function IsValid: Boolean; inline;
    /// <summary>
    /// Compares two positions.
    /// </summary>
    /// <param name="AOther">The position to compare with.</param>
    /// <returns>True when paragraph, run and character index are all equal.</returns>
    function Equals(const AOther: TS4YDocumentPosition): Boolean; inline;
  end;

  // ===========================================================================
  // Table length  (width of a table or of a table cell)
  // ===========================================================================

  /// <summary>
  /// How a width is given.
  /// </summary>
  /// <remarks>
  /// tlkAuto means that the width was not set, tlkPixels is a width in pixels and tlkPercent a percentage of the available width.
  /// </remarks>
  TS4YTableLengthKind = (tlkAuto, tlkPixels, tlkPercent);

  /// <summary>
  /// A width of a table or of a table cell, in pixels or as a percentage.
  /// </summary>
  /// <remarks>
  /// A record that is not set has Kind tlkAuto, so the default value means "not set".
  /// </remarks>
  TS4YTableLength = record
    /// <summary>How the width is given.</summary>
    Kind: TS4YTableLengthKind;
    /// <summary>Width in pixels or in percent, depending on Kind. It is 0 when Kind is tlkAuto.</summary>
    Value: Single;
    /// <summary>
    /// Returns a width that is not set.
    /// </summary>
    class function Auto: TS4YTableLength; static; inline;
    /// <summary>
    /// Creates a width in pixels.
    /// </summary>
    /// <param name="AValue">Width in pixels; a value that is not positive gives a width that is not set.</param>
    class function Pixels(AValue: Single): TS4YTableLength; static;
    /// <summary>
    /// Creates a width as a percentage of the available width.
    /// </summary>
    /// <param name="AValue">Percentage; a value that is not positive gives a width that is not set.</param>
    class function Percent(AValue: Single): TS4YTableLength; static;
    /// <summary>
    /// Tells whether the width was not set.
    /// </summary>
    /// <returns>True when Kind is tlkAuto.</returns>
    function IsAuto: Boolean; inline;
    /// <summary>
    /// Compares two widths.
    /// </summary>
    /// <param name="AOther">The width to compare with.</param>
    /// <returns>True when kind and value are equal.</returns>
    function Equals(const AOther: TS4YTableLength): Boolean; inline;
  end;

  // ===========================================================================
  // Table cell box  (padding and vertical alignment of a table cell)
  // ===========================================================================

  /// <summary>
  /// Where the content of a table cell sits when the cell is taller than the content.
  /// </summary>
  /// <remarks>
  /// tvaTop puts the content at the top of the cell (the default), tvaMiddle in the middle and tvaBottom at the bottom.
  /// </remarks>
  TS4YTableVerticalAlignment = (tvaTop, tvaMiddle, tvaBottom);

  /// <summary>
  /// The space between the border of a table cell and its content, in pixels.
  /// </summary>
  /// <remarks>
  /// A record that is not set (IsSet is False) means that the cell has the default padding.
  /// </remarks>
  TS4YTablePadding = record
    /// <summary>Tells whether the padding was set. When it is False the other fields are not used.</summary>
    IsSet: Boolean;
    /// <summary>Space on the left.</summary>
    Left: Single;
    /// <summary>Space above.</summary>
    Top: Single;
    /// <summary>Space on the right.</summary>
    Right: Single;
    /// <summary>Space below.</summary>
    Bottom: Single;
    /// <summary>
    /// Returns a padding that is not set.
    /// </summary>
    class function Default: TS4YTablePadding; static; inline;
    /// <summary>
    /// Creates the same padding on the four sides.
    /// </summary>
    /// <param name="AValue">Space in pixels.</param>
    class function Uniform(AValue: Single): TS4YTablePadding; static;
    /// <summary>
    /// Creates a padding with a value for each side.
    /// </summary>
    /// <param name="ALeft">Space on the left.</param>
    /// <param name="ATop">Space above.</param>
    /// <param name="ARight">Space on the right.</param>
    /// <param name="ABottom">Space below.</param>
    class function Sides(ALeft, ATop, ARight, ABottom: Single): TS4YTablePadding; static;
    /// <summary>
    /// Compares two paddings.
    /// </summary>
    /// <param name="AOther">The padding to compare with.</param>
    /// <returns>True when both are not set, or when both are set with the same four values.</returns>
    function Equals(const AOther: TS4YTablePadding): Boolean;
  end;

  // ===========================================================================
  // Table cell borders  (one border for each side of a table cell)
  // ===========================================================================

  /// <summary>
  /// A side of a table cell.
  /// </summary>
  TS4YTableSide = (tsTop, tsRight, tsBottom, tsLeft);

  /// <summary>
  /// A set of sides of a table cell.
  /// </summary>
  TS4YTableSides = set of TS4YTableSide;

  /// <summary>
  /// One side of the border of a table cell: its width in pixels and its color.
  /// </summary>
  /// <remarks>
  /// A width of 0 means that the side has no border.
  /// </remarks>
  TS4YTableBorderSide = record
    /// <summary>Width in pixels; 0 means no border.</summary>
    Width: Single;
    /// <summary>Color of the border.</summary>
    Color: TAlphaColor;
    /// <summary>
    /// Returns the border that a table with borders draws on each side of its cells.
    /// </summary>
    class function Default: TS4YTableBorderSide; static;
    /// <summary>
    /// Returns a side without border.
    /// </summary>
    class function None: TS4YTableBorderSide; static;
    /// <summary>
    /// Creates a side with a solid border.
    /// </summary>
    /// <param name="AWidth">Width in pixels; a value that is not positive gives a side without border.</param>
    /// <param name="AColor">Color of the border.</param>
    class function Solid(AWidth: Single; AColor: TAlphaColor): TS4YTableBorderSide; static;
    /// <summary>
    /// Tells whether the side has a border that is drawn.
    /// </summary>
    /// <returns>True when the width is positive and the color is not claNull.</returns>
    function IsVisible: Boolean;
    /// <summary>
    /// Compares two sides.
    /// </summary>
    /// <param name="AOther">The side to compare with.</param>
    /// <returns>True when both are not drawn, or when width and color are equal.</returns>
    function Equals(const AOther: TS4YTableBorderSide): Boolean;
  end;

  /// <summary>
  /// The borders of a table cell, one for each side.
  /// </summary>
  /// <remarks>
  /// A record that is not set (IsSet is False) means that the cell follows its table: it has the default border on each
  /// side when the table has borders and none otherwise. A record that is set gives the four sides explicitly.
  /// </remarks>
  TS4YTableBorders = record
    /// <summary>Tells whether the borders were set. When it is False the other fields are not used.</summary>
    IsSet: Boolean;
    /// <summary>Border above.</summary>
    Top: TS4YTableBorderSide;
    /// <summary>Border on the right.</summary>
    Right: TS4YTableBorderSide;
    /// <summary>Border below.</summary>
    Bottom: TS4YTableBorderSide;
    /// <summary>Border on the left.</summary>
    Left: TS4YTableBorderSide;
    /// <summary>
    /// Returns borders that are not set, so that the cell follows its table.
    /// </summary>
    class function Default: TS4YTableBorders; static; inline;
    /// <summary>
    /// Returns borders that are set and have no border on any side.
    /// </summary>
    class function None: TS4YTableBorders; static;
    /// <summary>
    /// Creates the same border on the four sides.
    /// </summary>
    /// <param name="ASide">The border of each side.</param>
    class function Uniform(const ASide: TS4YTableBorderSide): TS4YTableBorders; static;
    /// <summary>
    /// Creates borders with a border for each side.
    /// </summary>
    /// <param name="ATop">Border above.</param>
    /// <param name="ARight">Border on the right.</param>
    /// <param name="ABottom">Border below.</param>
    /// <param name="ALeft">Border on the left.</param>
    class function Sides(const ATop, ARight, ABottom, ALeft: TS4YTableBorderSide): TS4YTableBorders; static;
    /// <summary>
    /// Compares two sets of borders.
    /// </summary>
    /// <param name="AOther">The borders to compare with.</param>
    /// <returns>True when both are not set, or when both are set with equal sides.</returns>
    function Equals(const AOther: TS4YTableBorders): Boolean;
  end;

  // ===========================================================================
  // Table cell reference  (position of a cell in a table)
  // ===========================================================================

  /// <summary>
  /// A reference to a cell of a table: the table and the position of the cell in it.
  /// </summary>
  /// <remarks>
  /// A paragraph of a table that sits inside the cell of another table lists the cells that contain it as references.
  /// </remarks>
  TS4YTableCellReference = record
    /// <summary>Identifier of the table, as in TS4YHTMLParagraph.TableID.</summary>
    TableID: Integer;
    /// <summary>Zero-based row of the cell.</summary>
    Row: Integer;
    /// <summary>Zero-based column of the cell.</summary>
    Column: Integer;
    /// <summary>
    /// Creates a reference.
    /// </summary>
    /// <param name="ATableID">Identifier of the table.</param>
    /// <param name="ARow">Zero-based row of the cell.</param>
    /// <param name="AColumn">Zero-based column of the cell.</param>
    class function At(ATableID, ARow, AColumn: Integer): TS4YTableCellReference; static; inline;
    /// <summary>
    /// Compares two references.
    /// </summary>
    /// <param name="AOther">The reference to compare with.</param>
    /// <returns>True when table, row and column are all equal.</returns>
    function Equals(const AOther: TS4YTableCellReference): Boolean; inline;
  end;

  // ===========================================================================
  // Layout types  (produced by TS4YLayoutEngine)
  // ===========================================================================

  /// <summary>
  /// A piece of a line produced by the layout engine: a word, an image, a rule or a placeholder.
  /// </summary>
  /// <remarks>
  /// Coordinates are in pixels, relative to the document (without scrolling). The layout is recalculated by the editor; applications normally do not use this type.
  /// </remarks>
  TS4YLayoutFragment = record
    /// <summary>Index of the paragraph that the fragment belongs to.</summary>
    ParagraphIndex: Integer;
    /// <summary>Index of the run that the fragment belongs to. Negative for block-level images and rules.</summary>
    RunIndex: Integer;
    /// <summary>First character of the fragment inside the text of the run (inclusive).</summary>
    CharStart: Integer; // inclusive, within Run.Text
    /// <summary>End of the fragment inside the text of the run (exclusive).</summary>
    CharEnd: Integer;   // exclusive
    /// <summary>Position of the top left corner of the fragment.</summary>
    X, Y: Single;
    /// <summary>Size of the fragment.</summary>
    Width, Height: Single;
    /// <summary>Distance from the top of the line box to the baseline.</summary>
    Ascent: Single;    // distance from top of line-box to baseline
    /// <summary>Index of the line that holds the fragment.</summary>
    LineIndex: Integer;
    /// <summary>The fragment is a trailing space that can be omitted at the end of a line.</summary>
    IsSpace: Boolean;        // trailing space that can be omitted at EOL
    /// <summary>The fragment is a horizontal rule.</summary>
    IsHR: Boolean;
    /// <summary>The fragment is an image.</summary>
    IsImage: Boolean;
    /// <summary>The fragment is a placeholder chip (mirrors the run flag).</summary>
    IsPlaceholder: Boolean;  // mirrors Run.IsPlaceholder; drives chip rendering
  end;

  /// <summary>
  /// A line of text produced by the layout engine.
  /// </summary>
  /// <remarks>
  /// The table cell fields are valid only for the paragraphs that belong to a table cell. Applications normally do not use this type.
  /// </remarks>
  TS4YLayoutLine = record
    /// <summary>Top of the line, relative to the document.</summary>
    Y: Single;
    /// <summary>Height of the line box.</summary>
    Height: Single; // line-box height
    /// <summary>Largest ascent among the fragments of the line.</summary>
    Ascent: Single; // max ascent in line
    /// <summary>Index of the paragraph that the line belongs to.</summary>
    ParagraphIndex: Integer;
    /// <summary>The line is the first of its paragraph.</summary>
    IsFirst: Boolean;
    /// <summary>The line is the last of its paragraph.</summary>
    IsLast: Boolean;
    /// <summary>Index of the first fragment of the line in the fragment array.</summary>
    FragmentStart: Integer; // index into FFrags array
    /// <summary>Number of fragments in the line.</summary>
    FragmentCount: Integer;
  end;

  /// <summary>
  /// The rectangle that the layout engine gives to a table cell.
  /// </summary>
  /// <remarks>
  /// Coordinates are in pixels, relative to the document (without scrolling). A cell that spans rows or columns has one rectangle that covers all of them. The cells of nested tables have their own rectangles. Applications normally do not use this type.
  /// </remarks>
  TS4YLayoutCell = record
    /// <summary>Identifier of the table of the cell.</summary>
    TableID: Integer;
    /// <summary>Zero-based row of the cell.</summary>
    Row: Integer;
    /// <summary>Zero-based column of the cell.</summary>
    Column: Integer;
    /// <summary>Number of columns that the cell covers.</summary>
    ColumnSpan: Integer;
    /// <summary>Index of the first paragraph of the cell, the one that holds its attributes.</summary>
    FirstParagraphIndex: Integer;
    /// <summary>Number of tables that contain the table of the cell; 0 when the table is not nested.</summary>
    Depth: Integer;
    /// <summary>Borders of the cell that are drawn: always set, a side without border has a width of 0.</summary>
    Borders: TS4YTableBorders;
    /// <summary>Background color of the cell; claNull means none.</summary>
    BackgroundColor: TAlphaColor;
    /// <summary>Left edge of the cell.</summary>
    X: Single;
    /// <summary>Top edge of the cell.</summary>
    Y: Single;
    /// <summary>Width of the cell.</summary>
    Width: Single;
    /// <summary>Height of the cell.</summary>
    Height: Single;
    /// <summary>Width of the space that the table of the cell was laid out in.</summary>
    TableAvailableWidth: Single;
  end;

  // ===========================================================================
  // Font size presets
  // ===========================================================================

  /// <summary>A font size offered to the user, with its caption.</summary>
  TS4YFontSizePreset = record
    /// <summary>Font size in points.</summary>
    Size: Single;
    /// <summary>Text to show to the user for this size.</summary>
    Caption: string;
    /// <summary>
    /// Creates a preset.
    /// </summary>
    /// <param name="ASize">Font size in points.</param>
    /// <param name="ACaption">Caption to show.</param>
    constructor Create(ASize: Single; const ACaption: string);
  end;

/// <summary>
/// Returns the standard font size presets, from very small to huge.
/// </summary>
/// <remarks>
/// The captions are localizable resource strings.
/// </remarks>
function FontSizePresets: TArray<TS4YFontSizePreset>;

// ===========================================================================
// Helpers
// ===========================================================================

/// <summary>
/// Makes a color darker.
/// </summary>
/// <param name="AColor">The color to darken.</param>
/// <param name="AFactor">Multiplier of each color channel; values below 1 darken, values above 1 lighten.</param>
/// <returns>The new color, fully opaque.</returns>
function DarkenColor(AColor: TAlphaColor; AFactor: Single = 0.65): TAlphaColor;
/// <summary>Removes leading and trailing white space from a string.</summary>
function TrimS(const AText: string): string; inline;
/// <summary>
/// Case-insensitive test for the start of a string.
/// </summary>
/// <param name="AText">The text to examine.</param>
/// <param name="APrefix">The expected beginning.</param>
/// <returns>True when AText starts with APrefix, ignoring case.</returns>
function StartsWithCI(const AText, APrefix: string): Boolean; inline;

// Image source paths
/// <summary>
/// Converts a file: URL to a file system path.
/// </summary>
/// <param name="AUrl">A file: URL (file:///C:/dir/a%20b.png, UNC and localhost forms); any other text is returned unchanged.</param>
/// <returns>The path, for example C:\dir\a b.png.</returns>
function FileUrlToPath(const AUrl: string): string;
/// <summary>
/// Tells whether an image source is a relative file system path.
/// </summary>
/// <param name="ASource">The image source.</param>
/// <returns>True for a relative path; False for URLs, absolute paths and empty text.</returns>
function IsRelativeLocalPath(const ASource: string): Boolean;
/// <summary>
/// Tells whether an image source is a remote address.
/// </summary>
/// <param name="ASource">The image source.</param>
/// <returns>True for http: and https: sources.</returns>
function IsRemoteImageSource(const ASource: string): Boolean;
/// <summary>
/// Tells whether an image source is read from the file system.
/// </summary>
/// <param name="ASource">The image source.</param>
/// <returns>True for file: URLs and for relative or absolute paths; False for data:, cid: and other schemes.</returns>
function IsLocalImageSource(const ASource: string): Boolean;
/// <summary>
/// Finds the path or URL that an image source is read from.
/// </summary>
/// <param name="ASource">The image source as written in the document.</param>
/// <param name="ADocumentPath">Folder of the document.</param>
/// <param name="AMode">How relative paths are resolved.</param>
/// <returns>The file path to read; URLs and absolute paths are not changed.</returns>
function ResolveImagePath(const ASource, ADocumentPath: string; AMode: TS4YImagePathMode): string;
/// <summary>
/// Makes an image source relative to the document folder.
/// </summary>
/// <param name="ASource">The image source.</param>
/// <param name="ADocumentPath">Folder of the document.</param>
/// <returns>The path relative to the folder (with / separators) when the file is inside it or in a subfolder; otherwise the source unchanged.</returns>
function MakeDocumentRelativePath(const ASource, ADocumentPath: string): string;
/// <summary>
/// Tells whether a path is inside a folder.
/// </summary>
/// <param name="APath">The path to test.</param>
/// <param name="AFolder">The folder.</param>
/// <returns>True when the path, made absolute and normalized, is in the folder or in one of its subfolders; False when either is empty.</returns>
/// <remarks>
/// Symbolic links are not resolved.
/// </remarks>
function IsPathInsideFolder(const APath, AFolder: string): Boolean;
/// <summary>
/// Converts a file system path to a file: URL.
/// </summary>
/// <param name="APath">An absolute path.</param>
/// <returns>The URL, for example file:///C:/dir/a%20b.png.</returns>
function PathToFileUrl(const APath: string): string;
/// <summary>
/// Makes a relative local image source absolute.
/// </summary>
/// <param name="ASource">The image source.</param>
/// <returns>A file: URL resolved against the current directory when the source is a relative path; anything else unchanged.</returns>
function ImageSourceToFileUrl(const ASource: string): string;

implementation

uses
  System.IOUtils;

// -----------------------------------------------------------------------------
// DarkenColor
// -----------------------------------------------------------------------------

function DarkenColor(AColor: TAlphaColor; AFactor: Single): TAlphaColor;
var
  LR, LG, LB: Integer;
begin
  LR := Round(TAlphaColorRec(AColor).R * AFactor);
  LG := Round(TAlphaColorRec(AColor).G * AFactor);
  LB := Round(TAlphaColorRec(AColor).B * AFactor);
  if LR > 255 then
    LR := 255;
  if LG > 255 then
    LG := 255;
  if LB > 255 then
    LB := 255;
  Result := TAlphaColor(($FF shl 24) or (LR shl 16) or (LG shl 8) or LB);
end;

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function TrimS(const AText: string): string;
begin
  Result := AText.Trim;
end;

function StartsWithCI(const AText, APrefix: string): Boolean;
begin
  Result := AText.ToLower.StartsWith(APrefix.ToLower);
end;

// -----------------------------------------------------------------------------
// Image source paths
// -----------------------------------------------------------------------------

// Decodes %XX sequences as UTF-8 bytes; unlike TNetEncoding.URL a '+' stays a '+'
function DecodePercentEscapes(const AText: string): string;
var
  LBytes: TBytes;
  LIndex: Integer;
  LCount: Integer;
  LHexValue: Integer;
  LUtf8: TBytes;
begin
  if not AText.Contains('%') then
    Exit(AText);
  LUtf8 := TEncoding.UTF8.GetBytes(AText);
  SetLength(LBytes, Length(LUtf8));
  LCount := 0;
  LIndex := 0;
  while LIndex < Length(LUtf8) do
  begin
    if (LUtf8[LIndex] = Ord('%')) and (LIndex + 2 < Length(LUtf8)) and
       TryStrToInt('$' + Char(LUtf8[LIndex + 1]) + Char(LUtf8[LIndex + 2]), LHexValue) then
    begin
      LBytes[LCount] := Byte(LHexValue);
      Inc(LIndex, 3);
    end
    else
    begin
      LBytes[LCount] := LUtf8[LIndex];
      Inc(LIndex);
    end;
    Inc(LCount);
  end;
  Result := TEncoding.UTF8.GetString(LBytes, 0, LCount);
end;

// file:///C:/dir/a%20b.png -> C:\dir\a b.png    file://server/share/x.png -> \\server\share\x.png
function FileUrlToPath(const AUrl: string): string;
var
  LRest: string;
  LAuthority: string;
  LSlash: Integer;
begin
  if not StartsWithCI(AUrl, 'file:') then
    Exit(AUrl);
  LRest := AUrl.Substring(5);
  LAuthority := '';
  if LRest.StartsWith('//') then
  begin
    LRest := LRest.Substring(2);
    LSlash := LRest.IndexOf('/');
    if LSlash < 0 then
    begin
      LAuthority := LRest;
      LRest := '';
    end
    else
    begin
      LAuthority := LRest.Substring(0, LSlash);
      LRest := LRest.Substring(LSlash);
    end;
  end;
  LRest := DecodePercentEscapes(LRest);
{$IFDEF MSWINDOWS}
  // '/C:/dir' -> 'C:/dir'
  if (Length(LRest) >= 3) and (LRest[Low(LRest)] = '/') and (LRest[Low(LRest) + 2] = ':') then
    LRest := LRest.Substring(1);
  LRest := LRest.Replace('/', PathDelim);
  if (LAuthority <> '') and not SameText(LAuthority, 'localhost') then
    LRest := PathDelim + PathDelim + LAuthority + LRest;
{$ENDIF}
  Result := LRest;
end;

// True when the source starts with a URL scheme (data:, http:, cid:, file: ...)
function HasUrlScheme(const ASource: string): Boolean;
var
  LColon: Integer;
  LIndex: Integer;
begin
  Result := False;
  LColon := ASource.IndexOf(':');
  // A scheme has at least 2 characters ('C:' is a drive letter, not a scheme)
  if LColon < 2 then
    Exit;
  Result := True;
  for LIndex := 0 to LColon - 1 do
  begin
    if not CharInSet(ASource[Low(ASource) + LIndex], ['a'..'z', 'A'..'Z', '0'..'9', '+', '-', '.']) then
      Result := False;
  end;
end;

// True for a file system path that is not absolute; False for URLs and absolute paths
function IsRelativeLocalPath(const ASource: string): Boolean;
begin
  Result := (ASource <> '') and not HasUrlScheme(ASource) and TPath.IsRelativePath(ASource);
end;

// http: and https: sources
function IsRemoteImageSource(const ASource: string): Boolean;
begin
  Result := StartsWithCI(ASource, 'http://') or StartsWithCI(ASource, 'https://');
end;

// Sources read from the file system: file: URLs and relative or absolute paths.
// data:, cid: and any other scheme are not local
function IsLocalImageSource(const ASource: string): Boolean;
begin
  Result := StartsWithCI(ASource, 'file:') or ((ASource <> '') and not HasUrlScheme(ASource));
end;

function ResolveImagePath(const ASource, ADocumentPath: string; AMode: TS4YImagePathMode): string;
begin
  if StartsWithCI(ASource, 'file:') then
    Exit(FileUrlToPath(ASource));
  Result := ASource;
  if IsRelativeLocalPath(ASource) then
  begin
    Result := ASource.Replace('\', PathDelim);
    if (AMode = ipmDocument) and (ADocumentPath <> '') then
      Result := TPath.GetFullPath(TPath.Combine(ADocumentPath, Result));
  end;
end;

// Returns the source relative to the document folder (with '/' separators) when the file is
// inside it or in a subfolder; otherwise returns the source unchanged
function MakeDocumentRelativePath(const ASource, ADocumentPath: string): string;
var
  LPath: string;
  LBase: string;
  LFullPath: string;
begin
  Result := ASource;
  if ADocumentPath = '' then
    Exit;
  if StartsWithCI(ASource, 'file:') then
    LPath := FileUrlToPath(ASource)
  else if (ASource <> '') and not HasUrlScheme(ASource) then
    LPath := ASource
  else
    Exit;
  if TPath.IsRelativePath(LPath) then
    Exit;
  LBase := IncludeTrailingPathDelimiter(TPath.GetFullPath(ADocumentPath));
  LFullPath := TPath.GetFullPath(LPath);
{$IFDEF MSWINDOWS}
  if LFullPath.StartsWith(LBase, True) then
{$ELSE}
  if LFullPath.StartsWith(LBase, False) then
{$ENDIF}
    Result := LFullPath.Substring(LBase.Length).Replace(PathDelim, '/');
end;

// True when the path, once made absolute and normalized, is inside the folder or one of its
// subfolders; False when either is empty. Symbolic links are not resolved
function IsPathInsideFolder(const APath, AFolder: string): Boolean;
var
  LBase: string;
  LFullPath: string;
begin
  Result := False;
  if (APath = '') or (AFolder = '') then
    Exit;
  LBase := IncludeTrailingPathDelimiter(TPath.GetFullPath(AFolder));
  LFullPath := TPath.GetFullPath(APath);
{$IFDEF MSWINDOWS}
  Result := LFullPath.StartsWith(LBase, True);
{$ELSE}
  Result := LFullPath.StartsWith(LBase, False);
{$ENDIF}
end;

// C:\dir\a b.png -> file:///C:/dir/a%20b.png    \\server\share\x.png -> file://server/share/x.png
function PathToFileUrl(const APath: string): string;
var
  LPath: string;
  LBytes: TBytes;
  LByte: Byte;
  LBuilder: TStringBuilder;
begin
  LPath := APath.Replace('\', '/');
  LBuilder := TStringBuilder.Create;
  try
    if LPath.StartsWith('//') then
      LBuilder.Append('file:')
    else if LPath.StartsWith('/') then
      LBuilder.Append('file://')
    else
      LBuilder.Append('file:///');
    LBytes := TEncoding.UTF8.GetBytes(LPath);
    for LByte in LBytes do
    begin
      if CharInSet(Char(LByte), ['a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_', '~', '/', ':']) then
        LBuilder.Append(Char(LByte))
      else
        LBuilder.Append('%' + IntToHex(LByte, 2));
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

// Relative local path -> file: URL resolved against the current directory; anything else unchanged
function ImageSourceToFileUrl(const ASource: string): string;
begin
  Result := ASource;
  if IsRelativeLocalPath(ASource) then
    Result := PathToFileUrl(TPath.GetFullPath(ASource.Replace('\', PathDelim)));
end;

// -----------------------------------------------------------------------------
// TS4YFontSizePreset
// -----------------------------------------------------------------------------

constructor TS4YFontSizePreset.Create(ASize: Single; const ACaption: string);
begin
  Size    := ASize;
  Caption := ACaption;
end;

// -----------------------------------------------------------------------------
// FontSizePresets
// -----------------------------------------------------------------------------

function FontSizePresets: TArray<TS4YFontSizePreset>;
begin
  Result := [
    TS4YFontSizePreset.Create(C_FONT_SIZE_VERY_SMALL, S_FONT_SIZE_VERY_SMALL),
    TS4YFontSizePreset.Create(C_FONT_SIZE_SMALL,       S_FONT_SIZE_SMALL),
    TS4YFontSizePreset.Create(C_FONT_SIZE_MEDIUM,      S_FONT_SIZE_MEDIUM),
    TS4YFontSizePreset.Create(C_FONT_SIZE_LARGE,       S_FONT_SIZE_LARGE),
    TS4YFontSizePreset.Create(C_FONT_SIZE_VERY_LARGE,  S_FONT_SIZE_VERY_LARGE),
    TS4YFontSizePreset.Create(C_FONT_SIZE_HUGE,        S_FONT_SIZE_HUGE)
  ];
end;

// -----------------------------------------------------------------------------
// TS4YPlaceholderGeneratorStyle
// -----------------------------------------------------------------------------

procedure TS4YSaveOptions.Init;
begin
  CopyImages := False;
  ImagesFolderName := '';
  UpdateModel := False;
end;

procedure TS4YPlaceholderGeneratorStyle.Init;
begin
  FillColor := claNull;
  TextColor := claNull;
  BorderColor := claNull;
  BorderRadius := 0;
  HorizontalPadding := 0;
  VerticalPadding := 0;
  Bold := False;
end;

// -----------------------------------------------------------------------------
// TS4YHTMLTextStyle
// -----------------------------------------------------------------------------

procedure TS4YHTMLTextStyle.Init;
begin
  FontName := S_EDITOR_FONT_NAME;
  FontSize := C_EDITOR_FONT_SIZE;
  Bold := False;
  Italic := False;
  Underline := False;
  StrikeOut := False;
  Superscript := False;
  Subscript := False;
  Color := claNull;
  BackgroundColor := claNull;
  LinkURL := '';
end;

function TS4YHTMLTextStyle.EqualsFormat(const AOther: TS4YHTMLTextStyle): Boolean;
begin
  Result := (FontName = AOther.FontName) and (Abs(FontSize - AOther.FontSize) < 0.01) and
    (Bold = AOther.Bold) and (Italic = AOther.Italic) and (Underline = AOther.Underline) and
    (StrikeOut = AOther.StrikeOut) and (Superscript = AOther.Superscript) and
    (Subscript = AOther.Subscript) and (Color = AOther.Color) and (BackgroundColor = AOther.BackgroundColor) and
    (LinkURL = AOther.LinkURL);
end;

// -----------------------------------------------------------------------------
// TS4YDocumentPosition
// -----------------------------------------------------------------------------

class function TS4YDocumentPosition.Invalid: TS4YDocumentPosition;
begin
  Result.ParagraphIndex := -1;
  Result.RunIndex := 0;
  Result.CharIndex := 0;
end;

class function TS4YDocumentPosition.At(AParagraphIndex, ARunIndex, ACharIndex: Integer): TS4YDocumentPosition;
begin
  Result.ParagraphIndex := AParagraphIndex;
  Result.RunIndex := ARunIndex;
  Result.CharIndex := ACharIndex;
end;

function TS4YDocumentPosition.IsValid: Boolean;
begin
  Result := ParagraphIndex >= 0;
end;

function TS4YDocumentPosition.Equals(const AOther: TS4YDocumentPosition): Boolean;
begin
  Result := (ParagraphIndex = AOther.ParagraphIndex) and (RunIndex = AOther.RunIndex) and (CharIndex = AOther.CharIndex);
end;

// -----------------------------------------------------------------------------
// TS4YTableLength
// -----------------------------------------------------------------------------

class function TS4YTableLength.Auto: TS4YTableLength;
begin
  Result.Kind := tlkAuto;
  Result.Value := 0;
end;

class function TS4YTableLength.Pixels(AValue: Single): TS4YTableLength;
begin
  if AValue > 0 then
  begin
    Result.Kind := tlkPixels;
    Result.Value := AValue;
  end
  else
    Result := Auto;
end;

class function TS4YTableLength.Percent(AValue: Single): TS4YTableLength;
begin
  if AValue > 0 then
  begin
    Result.Kind := tlkPercent;
    Result.Value := AValue;
  end
  else
    Result := Auto;
end;

function TS4YTableLength.IsAuto: Boolean;
begin
  Result := Kind = tlkAuto;
end;

function TS4YTableLength.Equals(const AOther: TS4YTableLength): Boolean;
begin
  Result := (Kind = AOther.Kind) and (Value = AOther.Value);
end;

// -----------------------------------------------------------------------------
// TS4YTablePadding
// -----------------------------------------------------------------------------

class function TS4YTablePadding.Default: TS4YTablePadding;
begin
  Result.IsSet := False;
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := 0;
  Result.Bottom := 0;
end;

class function TS4YTablePadding.Uniform(AValue: Single): TS4YTablePadding;
begin
  Result := Sides(AValue, AValue, AValue, AValue);
end;

class function TS4YTablePadding.Sides(ALeft, ATop, ARight, ABottom: Single): TS4YTablePadding;
begin
  Result.IsSet := True;
  Result.Left := Max(0, ALeft);
  Result.Top := Max(0, ATop);
  Result.Right := Max(0, ARight);
  Result.Bottom := Max(0, ABottom);
end;

function TS4YTablePadding.Equals(const AOther: TS4YTablePadding): Boolean;
begin
  if IsSet <> AOther.IsSet then
    Result := False
  else if not IsSet then
    Result := True
  else
    Result := (Left = AOther.Left) and (Top = AOther.Top) and (Right = AOther.Right) and (Bottom = AOther.Bottom);
end;

// -----------------------------------------------------------------------------
// TS4YTableBorderSide
// -----------------------------------------------------------------------------

class function TS4YTableBorderSide.Default: TS4YTableBorderSide;
begin
  Result := Solid(C_DEFAULT_TABLE_BORDER_WIDTH, C_DEFAULT_TABLE_BORDER_COLOR);
end;

class function TS4YTableBorderSide.None: TS4YTableBorderSide;
begin
  Result.Width := 0;
  Result.Color := claNull;
end;

class function TS4YTableBorderSide.Solid(AWidth: Single; AColor: TAlphaColor): TS4YTableBorderSide;
begin
  if AWidth > 0 then
  begin
    Result.Width := AWidth;
    Result.Color := AColor;
  end
  else
  begin
    Result := None;
  end;
end;

function TS4YTableBorderSide.IsVisible: Boolean;
begin
  Result := (Width > 0) and (Color <> claNull);
end;

function TS4YTableBorderSide.Equals(const AOther: TS4YTableBorderSide): Boolean;
begin
  if IsVisible <> AOther.IsVisible then
    Result := False
  else if not IsVisible then
    Result := True
  else
    Result := (Width = AOther.Width) and (Color = AOther.Color);
end;

// -----------------------------------------------------------------------------
// TS4YTableBorders
// -----------------------------------------------------------------------------

class function TS4YTableBorders.Default: TS4YTableBorders;
begin
  Result.IsSet := False;
  Result.Top := TS4YTableBorderSide.None;
  Result.Right := TS4YTableBorderSide.None;
  Result.Bottom := TS4YTableBorderSide.None;
  Result.Left := TS4YTableBorderSide.None;
end;

class function TS4YTableBorders.None: TS4YTableBorders;
begin
  Result := Uniform(TS4YTableBorderSide.None);
end;

class function TS4YTableBorders.Uniform(const ASide: TS4YTableBorderSide): TS4YTableBorders;
begin
  Result := Sides(ASide, ASide, ASide, ASide);
end;

class function TS4YTableBorders.Sides(const ATop, ARight, ABottom, ALeft: TS4YTableBorderSide): TS4YTableBorders;
begin
  Result.IsSet := True;
  Result.Top := ATop;
  Result.Right := ARight;
  Result.Bottom := ABottom;
  Result.Left := ALeft;
end;

function TS4YTableBorders.Equals(const AOther: TS4YTableBorders): Boolean;
begin
  if IsSet <> AOther.IsSet then
    Result := False
  else if not IsSet then
    Result := True
  else
    Result := Top.Equals(AOther.Top) and Right.Equals(AOther.Right) and Bottom.Equals(AOther.Bottom) and
      Left.Equals(AOther.Left);
end;

// -----------------------------------------------------------------------------
// TS4YTableCellReference
// -----------------------------------------------------------------------------

class function TS4YTableCellReference.At(ATableID, ARow, AColumn: Integer): TS4YTableCellReference;
begin
  Result.TableID := ATableID;
  Result.Row := ARow;
  Result.Column := AColumn;
end;

function TS4YTableCellReference.Equals(const AOther: TS4YTableCellReference): Boolean;
begin
  Result := (TableID = AOther.TableID) and (Row = AOther.Row) and (Column = AOther.Column);
end;

end.
