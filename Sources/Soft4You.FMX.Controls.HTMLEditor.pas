unit Soft4You.FMX.Controls.HTMLEditor;

{ *****************************************************************************
  S4YFMXHTMLEditor - WYSIWYG HTML editor for Delphi FireMonkey (FMX)
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{ *******************************************************************************
  TS4YHTMLEditor  -  WYSIWYG HTML editor for Delphi FMX
  100% native Delphi - no WebBrowser, no COM/OLE. SVG images are rendered via Skia4Delphi.
  Platforms: Windows, macOS, iOS, Android. Requires Skia4Delphi.

  Architecture:
  Document model  : TS4YHTMLParagraph  containing  TS4YHTMLRun  (inline styled text)
  Layout engine   : TS4YLayoutEngine   - word-wrap, line metrics via TTextLayout
  Renderer        : TCanvas FMX     - text, selection, caret, border
  HTML I/O        : TS4YHTMLParser / TS4YHTMLGenerator

  Supported HTML (email subset):
  Blocks : <p> <h1>..<h6> <blockquote> <ul> <ol> <li> <hr>
  Inline : <b><strong> <i><em> <u> <s><del><strike>
  <sup> <sub> <span style="..."> <font ...> <a href="..."> <br>
  CSS    : font-family, font-size, font-weight, font-style,
  text-decoration, color, background-color
  Entities: &amp; &lt; &gt; &quot; &nbsp; &#N; &#xN;
  ******************************************************************************* }

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.UIConsts,
  System.RTTI,
  System.Generics.Collections,
  System.Math,
  System.Character,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.TextLayout,
  FMX.Platform,
  FMX.StdCtrls,
  FMX.Menus,
  FMX.Forms,
  System.NetEncoding,
  System.Net.HttpClient,
  Skia,
  Skia.FMX,
  System.Bindings.Helper,
  Data.Bind.Components,
  Soft4You.FMX.Clipboard.Html,
  Soft4You.HTML.Types,
  Soft4You.HTML.Document,
  Soft4You.HTML.Parser,
  Soft4You.HTML.Generator,
  Soft4You.HTML.ImageExporter;

const
  C_EDITOR_PADDING = 10.0; // px inner margin
  C_EDITOR_LINE_SPACING = 1.0; // line-height multiplier - 1.0 matches TMemo natural height
  C_EDITOR_PARA_SPACING = 6.0; // extra px between paragraphs
  C_EDITOR_BLOCKQUOTE_INDENT = 24.0; // px per indent level
  C_EDITOR_LIST_INDENT = 20.0;
  C_EDITOR_CARET_BLINK = 530; // ms
  C_EDITOR_UNDO_LEVELS = 100;
  C_EDITOR_SCROLL_STEP = 40.0;
  C_COLUMN_BORDER_TOLERANCE = 3.0;  // px from a column border where the mouse grabs it
  C_AUTO_SCROLL_ZONE = 40.0; // px from top/bottom edge that triggers auto-scroll on drag

  // Context popup menu items constants
  C_CONTEXT_POPUP_ITEM_UNDO = 0;
  C_CONTEXT_POPUP_ITEM_REDO = 1;
  C_CONTEXT_POPUP_ITEM_SEP_1 = 2;
  C_CONTEXT_POPUP_ITEM_CUT = 3;
  C_CONTEXT_POPUP_ITEM_COPY = 4;
  C_CONTEXT_POPUP_ITEM_PASTE = 5;
  C_CONTEXT_POPUP_ITEM_SEP_2 = 6;
  C_CONTEXT_POPUP_ITEM_SELECT_ALL = 7;

  // Placeholder constants
  S_DEFAULT_PLACEHOLDER_PREFIX = '';
  S_DEFAULT_PLACEHOLDER_SUFFIX = '';

  // Default colors constants
  C_DEFAULT_SELECTION_COLOR = $ff95cbff; //$FF316AC5;
  C_DEFAULT_HR_TAG_STROKE_COLOR = $FFB0B0B0;
  C_DEFAULT_HR_THICKNESS = 1.0;
  C_DEFAULT_TABLE_BORDER_COLOR = $FFB0B0B0;
  C_DEFAULT_TABLE_BORDER_WIDTH = 1.0;
  C_DEFAULT_TABLE_CELL_PADDING = 4.0;
  C_DEFAULT_TABLE_MIN_ROW_HEIGHT = 20.0;
  C_MINIMUM_TABLE_COLUMN_WIDTH = 24.0;  // narrowest column that a column without width gets

  // Mouse management constants
  C_TRIPLE_CLICK_MS = 600;
  C_CLICK_DIST_2 = 25;

  // Rendering: fragments farther than this many pixels from the visible area are not
  // painted. It must exceed what a fragment draws outside its own box (sub/superscript
  // shift, underline, background), otherwise parts of them would be cut.
  C_RENDER_CULL_MARGIN = 64;

type

  // ===========================================================================
  // Placeholder events  (declared before TS4YLayoutEngine which references them)
  // ===========================================================================

  /// <summary>
  /// Lets the application supply a text character as the bullet of an unordered list item.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="IndentLevel">Indent level of the list item (0 for the first level).</param>
  /// <param name="Marker">Receives the character to draw, for example a bullet.</param>
  /// <param name="Handled">Set to True when Marker was supplied; otherwise the default bullet is drawn.</param>
  /// <remarks>
  /// It takes priority over TS4YDrawListMarkerEvent. Numbered lists always draw their number.
  /// It is called while the editor paints, only for the items near the visible area and again at every redraw: keep it fast, always return the same result for the same input, and do not change the editor from inside it.
  /// </remarks>
  TS4YGetListMarkerEvent = procedure(Sender: TObject; IndentLevel: Integer;
    var Marker: string; var Handled: Boolean) of object;

  /// <summary>
  /// Lets the application draw the bullet of an unordered list item.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="Canvas">Canvas to draw on.</param>
  /// <param name="Bounds">Rectangle reserved for the bullet.</param>
  /// <param name="IndentLevel">Indent level of the list item (0 for the first level).</param>
  /// <param name="Handled">Set to True when the bullet was drawn; otherwise the default bullet is drawn.</param>
  /// <remarks>
  /// It is called while the editor paints, only for the items near the visible area and again at every redraw: keep it fast and draw on Canvas only.
  /// </remarks>
  TS4YDrawListMarkerEvent = procedure(Sender: TObject; Canvas: TCanvas; const Bounds: TRectF;
    IndentLevel: Integer; var Handled: Boolean) of object;

  /// <summary>
  /// Lets the application draw a placeholder chip.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="Canvas">Canvas to draw on.</param>
  /// <param name="Bounds">Rectangle of the chip.</param>
  /// <param name="RawText">Text of the placeholder, including the prefix and the suffix.</param>
  /// <param name="Handled">Set to True when the chip was drawn; otherwise the default chip is drawn.</param>
  /// <remarks>
  /// It is called while the editor paints, only for the placeholders near the visible area and again at every redraw: keep it fast and draw on Canvas only.
  /// </remarks>
  TS4YDrawPlaceholderEvent = procedure(Sender: TObject; Canvas: TCanvas; const Bounds: TRectF; const RawText: string;
    var Handled: Boolean) of object;

  /// <summary>
  /// Maps the raw text of a placeholder to the label shown to the user.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="RawText">Text of the placeholder, including the prefix and the suffix.</param>
  /// <param name="DisplayLabel">Receives the label to show; it starts as the raw text.</param>
  /// <remarks>
  /// It is called during layout and painting, also for placeholders that are not visible, and many times: it must be a pure and fast mapping.
  /// </remarks>
  TS4YGetPlaceholderLabelEvent = procedure(Sender: TObject; const RawText: string; var DisplayLabel: string) of object;

  /// <summary>
  /// The user clicked a hyperlink.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="URL">Target of the link.</param>
  /// <param name="LinkText">Visible text of the link.</param>
  /// <remarks>
  /// It is fired when the mouse button is released over the link and nothing is selected.
  /// </remarks>
  TS4YLinkClickEvent = procedure(Sender: TObject; const URL: string; const LinkText: string) of object;
  /// <summary>
  /// The pointer is over a hyperlink.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="URL">Target of the link under the pointer.</param>
  /// <param name="Cursor">Cursor to show; it starts as the hand cursor and can be changed.</param>
  TS4YLinkHoverEvent = procedure(Sender: TObject; const URL: string; var Cursor: TCursor) of object;

  /// <summary>
  /// Why an image is being loaded.
  /// </summary>
  /// <remarks>
  /// ilcParse: the document is being loaded.
  /// ilcInsert: the application inserted or replaced an image.
  /// ilcReload: the images were reloaded.
  /// ilcRender: the image is needed to draw the document.
  /// ilcSave: the image is about to be copied by SaveToFile.
  /// </remarks>
  TS4YImageLoadContext = (ilcParse, ilcInsert, ilcReload, ilcRender, ilcSave);
  /// <summary>
  /// Lets the application refuse to read or download an image.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="ASource">The image source exactly as written in the document.</param>
  /// <param name="AContext">Why the image is needed.</param>
  /// <param name="Allow">Set to False to refuse the image; it starts as True.</param>
  /// <remarks>
  /// It is fired for every non-empty source, including data: sources. A refused image is not read; TS4YLoadImageEvent still fires with a nil bitmap so a substitute can be supplied.
  /// A refusal without a substitute is remembered until the content or the path settings change. The check of LocalImageAccess comes first and cannot be overridden here.
  /// </remarks>
  TS4YBeforeLoadImageEvent = procedure(Sender: TObject; const ASource: string;
    AContext: TS4YImageLoadContext; var Allow: Boolean) of object;
  /// <summary>
  /// Lets the application provide or replace the bitmap of an image.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="ASource">The image source exactly as written in the document.</param>
  /// <param name="ABitmap">The bitmap loaded by the editor, or nil when none could be loaded or the image was refused. Assign a new bitmap to override it.</param>
  /// <param name="AContext">Why the image is needed.</param>
  /// <remarks>
  /// The bitmap assigned becomes owned by the image cache of the editor. Use it for sources that the editor cannot load itself, such as cid: images.
  /// </remarks>
  TS4YLoadImageEvent = procedure(Sender: TObject; const ASource: string; var ABitmap: TBitmap;
    AContext: TS4YImageLoadContext) of object;

  // ===========================================================================
  // Layout Engine
  // ===========================================================================

  TS4YLayoutEngine = class
  private
    FMeasure: TTextLayout;
    FMeasureCache: TDictionary<string, TSizeF>;
    // Placeholder chip metrics -- set by TS4YHTMLEditor.DoLayout before each layout pass
    FPlaceholderPaddingH: Single;
    FPlaceholderPaddingV: Single;
    FPlaceholderBold: Boolean;
    FPlaceholderGetLabel: TS4YGetPlaceholderLabelEvent;
    FPlaceholderSender: TObject;
    FLineSpacing: Single;
    FParagraphSpacing: Single;
    procedure SetupFont(ATextStyle: TS4YHTMLTextStyle);
    function MeasureStr(const AText: string; ATextStyle: TS4YHTMLTextStyle): TSizeF;
    function EffectiveSize(ATextStyle: TS4YHTMLTextStyle): Single;
    function HeadingSize(ABlockType: TS4YHTMLBlockType): Single;
    procedure LayoutParagraph(AParagraph: TS4YHTMLParagraph; AParagraphIndex: Integer; AAvailableWidth, AStartY: Single;
      var ALines: TArray<TS4YLayoutLine>; var AFragments: TArray<TS4YLayoutFragment>; var AY: Single);
    procedure LayoutTable(ADocument: TS4YHTMLDocument; AFirstParagraphIndex: Integer; AAvailableWidth: Single;
      var ALines: TArray<TS4YLayoutLine>; var AFragments: TArray<TS4YLayoutFragment>; var AY: Single;
      out ANextParagraphIndex: Integer; var ACells: TArray<TS4YLayoutCell>);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearMeasureCache;
    procedure DoLayout(ADocument: TS4YHTMLDocument; AAvailableWidth: Single; out ALines: TArray<TS4YLayoutLine>;
      out AFragments: TArray<TS4YLayoutFragment>; out ACells: TArray<TS4YLayoutCell>; out ATotalHeight: Single);
    function MeasureCharOffset(const AText: string; ACharIndex: Integer; ATextStyle: TS4YHTMLTextStyle): Single;
    function CharAtX(const AText: string; AX: Single; ATextStyle: TS4YHTMLTextStyle): Integer;
    property LineSpacing: Single read FLineSpacing write FLineSpacing;
    property ParagraphSpacing: Single read FParagraphSpacing write FParagraphSpacing;
    property PlaceholderBold: Boolean read FPlaceholderBold write FPlaceholderBold;
    property PlaceholderGetLabel: TS4YGetPlaceholderLabelEvent read FPlaceholderGetLabel write FPlaceholderGetLabel;
    property PlaceholderPaddingH: Single read FPlaceholderPaddingH write FPlaceholderPaddingH;
    property PlaceholderPaddingV: Single read FPlaceholderPaddingV write FPlaceholderPaddingV;
    property PlaceholderSender: TObject read FPlaceholderSender write FPlaceholderSender;
  end;

  // ===========================================================================
  // Undo entry
  // ===========================================================================

  TS4YUndoEntry = class
  private
    FCaretPosition: TS4YDocumentPosition;
    FDocument: TS4YHTMLDocument;
    FSelectionEnd: TS4YDocumentPosition;
    FSelectionStart: TS4YDocumentPosition;
  public
    constructor Create(ADocument: TS4YHTMLDocument; const ACaret, ASelectionStart, ASelectionEnd: TS4YDocumentPosition);
    destructor Destroy; override;

    property CaretPosition: TS4YDocumentPosition read FCaretPosition write FCaretPosition;
    property Document: TS4YHTMLDocument read FDocument write FDocument;
    property SelEnd: TS4YDocumentPosition read FSelectionEnd write FSelectionEnd;
    property SelStart: TS4YDocumentPosition read FSelectionStart write FSelectionStart;
  end;

  // ===========================================================================
  // Event type for state notification
  // ===========================================================================

  /// <summary>
  /// Snapshot of the formatting at the caret, for updating a toolbar.
  /// </summary>
  /// <remarks>
  /// Passed to OnStateChange and returned by the State property.
  /// </remarks>
  TS4YEditorState = record
    /// <summary>Alignment of the paragraph at the caret.</summary>
    Alignment: TS4YHTMLAlignment;
    /// <summary>Highlight color of the character at the caret.</summary>
    BackgroundColor: TAlphaColor;
    /// <summary>True when Outdent would have an effect.</summary>
    CanOutdent: Boolean;
    /// <summary>1-based column within the visual line; 0 when there is no layout.</summary>
    ColumnNumber: Integer;  // 1-based column within the visual line (0 when no layout)
    /// <summary>Text color of the character at the caret.</summary>
    FontColor: TAlphaColor;
    /// <summary>Font family at the caret.</summary>
    FontName: string;
    /// <summary>Font size at the caret, in points.</summary>
    FontSize: Single;
    /// <summary>True when some text is selected.</summary>
    HasSelection: Boolean;
    /// <summary>Alternative text of the image at the caret; empty when the caret is not on an image.</summary>
    ImageAlt: string;
    /// <summary>Height in pixels of the image at the caret; 0 when the caret is not on an image.</summary>
    ImageHeight: Integer;
    /// <summary>Source of the image at the caret; empty when the caret is not on an image.</summary>
    ImageSource: string;
    /// <summary>Width in pixels of the image at the caret; 0 when the caret is not on an image.</summary>
    ImageWidth: Integer;
    /// <summary>Indent level of the paragraph at the caret; 0 means no indent.</summary>
    IndentLevel: Integer;
    /// <summary>The text at the caret is bold.</summary>
    IsBold: Boolean;
    /// <summary>The caret is on an image.</summary>
    IsImage: Boolean;
    /// <summary>The caret is in a table cell.</summary>
    IsInTable: Boolean;
    /// <summary>The text at the caret is italic.</summary>
    IsItalic: Boolean;
    /// <summary>The paragraph at the caret is an item of a numbered list.</summary>
    IsOrderedList: Boolean;
    /// <summary>The text at the caret is struck through.</summary>
    IsStrikeOut: Boolean;
    /// <summary>The text at the caret is a subscript.</summary>
    IsSubscript: Boolean;
    /// <summary>The text at the caret is a superscript.</summary>
    IsSuperscript: Boolean;
    /// <summary>The text at the caret is underlined.</summary>
    IsUnderline: Boolean;
    /// <summary>The paragraph at the caret is an item of a bulleted list.</summary>
    IsUnorderedList: Boolean;
    /// <summary>1-based visual line in the document; 0 when there is no layout.</summary>
    LineNumber: Integer;    // 1-based visual line in the document (0 when no layout)
    /// <summary>Target of the link at the caret; empty when the caret is not on a link.</summary>
    LinkURL: string;
    /// <summary>Format of the paragraph at the caret.</summary>
    ParagraphFormat: TS4YParagraphFormat;
    /// <summary>0-based column of the table cell at the caret; -1 when not in a table.</summary>
    TableCol: Integer;      // 0-based, -1 when not in table
    /// <summary>0-based row of the table cell at the caret; -1 when not in a table.</summary>
    TableRow: Integer;      // 0-based, -1 when not in table
  end;

  /// <summary>
  /// The formatting state at the caret changed.
  /// </summary>
  /// <param name="Sender">The editor that fired the event.</param>
  /// <param name="State">The new state.</param>
  /// <remarks>
  /// It is fired when the caret or the selection moves, after edits, and after the content is replaced. The state is computed for every call: keep the handler light.
  /// </remarks>
  TS4YEditorStateEvent = procedure(Sender: TObject; const State: TS4YEditorState) of object;

  // ===========================================================================
  // TS4YPlaceholderAppearance
  // ===========================================================================

  /// <summary>
  /// Visual style of the placeholder chips.
  /// </summary>
  /// <remarks>
  /// Changing any value redraws the editor. Use OnDrawPlaceholder for full control of the drawing.
  /// </remarks>
  TS4YPlaceholderAppearance = class(TPersistent)
  private
    FOnChange: TNotifyEvent;
    FFillColor: TAlphaColor;
    FTextColor: TAlphaColor;
    FBorderColor: TAlphaColor;
    FBorderRadius: Single;
    FHorizontalPadding: Single;
    FVerticalPadding: Single;
    FBold: Boolean;
    procedure SetFillColor(Value: TAlphaColor);
    procedure SetTextColor(Value: TAlphaColor);
    procedure SetBorderColor(Value: TAlphaColor);
    procedure SetBorderRadius(Value: Single);
    procedure SetHorizontalPadding(Value: Single);
    procedure SetVerticalPadding(Value: Single);
    procedure SetBold(Value: Boolean);
    procedure Changed;
  public
    constructor Create;
    /// <summary>Copies all values from another TS4YPlaceholderAppearance.</summary>
    procedure Assign(Source: TPersistent); override;
    /// <summary>Fired when any value changes. Used by the editor to redraw; applications normally do not need it.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Draw the placeholder text in bold.</summary>
    property Bold: Boolean read FBold write SetBold;
    /// <summary>Color of the border of the chip.</summary>
    property BorderColor: TAlphaColor read FBorderColor write SetBorderColor;
    /// <summary>Corner radius of the chip, in pixels.</summary>
    property BorderRadius: Single read FBorderRadius write SetBorderRadius;
    /// <summary>Background color of the chip.</summary>
    property FillColor: TAlphaColor read FFillColor write SetFillColor;
    /// <summary>Left and right padding inside the chip, in pixels.</summary>
    property HorizontalPadding: Single read FHorizontalPadding write SetHorizontalPadding;
    /// <summary>Text color of the chip.</summary>
    property TextColor: TAlphaColor read FTextColor write SetTextColor;
    /// <summary>Top and bottom padding inside the chip, in pixels.</summary>
    property VerticalPadding: Single read FVerticalPadding write SetVerticalPadding;
  end;

  // ===========================================================================
  // TS4YHTMLEditor - the control
  // ===========================================================================

  /// <summary>
  /// WYSIWYG HTML editor control for FireMonkey.
  /// </summary>
  /// <remarks>
  /// The content is a document of paragraphs and runs, built from HTML and exported back to HTML. The control draws it into an off-screen cache, so the cost of a repaint follows the size of the window and not the length of the document.
  /// Use it from the main thread only. Setting the content (HTML, FullHTML, LoadFromFile) clears the undo history and does not fire OnChange.
  /// See Docs/DeveloperGuide.md for how events behave and what to be careful about.
  /// </remarks>
  TS4YHTMLEditor = class(TStyledControl)
  private
    FDocument: TS4YHTMLDocument;
    FLayoutEngine: TS4YLayoutEngine;
    FLines: TArray<TS4YLayoutLine>;
    FCells: TArray<TS4YLayoutCell>;
    FFrags: TArray<TS4YLayoutFragment>;
    FTotalHeight: Single;
    FScrollY: Single;
    // Scrollbar - created at runtime only (not at design-time)
    FScrollBar: TScrollBar; // nil at design-time / when not needed
    FScrollBarMaximum: Single; // max scroll offset = ContentH - ViewH
    FScrollBarVisible: Boolean; // whether the scrollbar is currently visible
    FSyncing: Boolean; // guard: avoid OnScrollChange loop
    FCaretPosition: TS4YDocumentPosition;
    FSelectionStart: TS4YDocumentPosition;
    FSelectionEnd: TS4YDocumentPosition;
    FHasSelection: Boolean;
    FCaretOn: Boolean; // visible blink state
    FCaretTimer: TTimer;
    FRenderCache: TBitmap;
    FRenderDirty: Boolean;
    FLastPaintOpacity: Single;
    FCaretAtImageRight: Boolean;
    FCaretScreenX: Single;
    FCaretScreenY: Single;
    FCaretScreenH: Single;
    FDragging: Boolean;
    FIsResizingColumn: Boolean;  // a column border of a table is being dragged
    FIsResizeChanged: Boolean;  // the dragging has changed the widths already
    FResizeTableID: Integer;
    FResizeBoundary: Integer;  // the border between the columns FResizeBoundary - 1 and FResizeBoundary
    FResizeStartX: Single;
    FResizeStartWidths: TArray<Single>;  // width of the columns of the table when the dragging started
    FIsResizingTable: Boolean;  // the outer edge of the table is dragged: the width of the table changes
    FResizeAvailableWidth: Single;  // space that the table has
    FResizeTableAlignment: TS4YHTMLAlignment;
    FResizeIsPixels: Boolean;  // the width of the table is in pixels
    FIsOverColumnBorder: Boolean;
    FMouseDownPosition: TS4YDocumentPosition;
    FClickSeq: Integer; // consecutive click count (1=single, 2=double, 3=triple)
    FLastClickTime: TDateTime; // time of last click for triple-click detection
    FLastClickPt: TPointF; // position of last click
    FUndoStack: TObjectList<TS4YUndoEntry>;
    FRedoStack: TObjectList<TS4YUndoEntry>;
    FPlaceholders: TList<TS4YHTMLRun>;
    FInsertStyle: TS4YHTMLTextStyle;
    FInsertStyleSet: Boolean;
    FBatchMode: Boolean; // when True, InsertChar/InsertParagraphBreak skip DoLayout+Repaint
    FContextMenu: TPopupMenu;
    FAutoLoadLocalImages: Boolean;
    FAutoLoadRemoteImages: Boolean;
    FDocumentPath: string;
    FImagePathMode: TS4YImagePathMode;
    FLocalImageAccess: TS4YLocalImageAccess;
    FReadOnly: Boolean;
    FShowBorder: Boolean;
    FBackgroundColor: TAlphaColor;
    FFontColor: TAlphaColor;
    FLayouting: Boolean; // re-entry guard for DoLayout
    FFont: TFont; // default font (configurable from Object Inspector)
    FPlaceholderPrefix: string;
    FPlaceholderSuffix: string;
    FPlaceholderAppearance: TS4YPlaceholderAppearance;
    FHoverLinkURL: string;    // URL under mouse cursor ('' = none)
    FClickedLinkURL: string;  // URL at MouseDown, cleared on MouseUp
    FClickedLinkText: string; // visible text of the clicked link
    FLanguage: string;
    FLineSpacing: Single;
    FParagraphSpacing: Single;
    FPrettyHTML: Boolean;
    FTitle: string;
    FImageCache: TObjectDictionary<string, TBitmap>;
    FRefusedImages: TDictionary<string, Boolean>;
    FOnChange: TNotifyEvent;
    FOnStateChange: TS4YEditorStateEvent;
    FOnDrawListMarker: TS4YDrawListMarkerEvent;
    FOnDrawPlaceholder: TS4YDrawPlaceholderEvent;
    FOnGetListMarker: TS4YGetListMarkerEvent;
    FOnGetPlaceholderLabel: TS4YGetPlaceholderLabelEvent;
    FOnLinkClick: TS4YLinkClickEvent;
    FOnLinkHover: TS4YLinkHoverEvent;
    FOnBeforeLoadImage: TS4YBeforeLoadImageEvent;
    FOnLoadImage: TS4YLoadImageEvent;

    // Layout
    function AvailableWidth: Single;
    function ContentLeft: Single;
    function ContentTop: Single;

    // Painting helpers
    procedure PaintHorizontalRule(ACanvas: TCanvas; AY, AWidth, AX: Single; AParagraph: TS4YHTMLParagraph);
    procedure PaintImage(ACanvas: TCanvas; const AFragment: TS4YLayoutFragment; AParagraph: TS4YHTMLParagraph);
    procedure PaintImageRun(ACanvas: TCanvas; const AFragment: TS4YLayoutFragment; ARun: TS4YHTMLRun);
    procedure PaintSelection(ACanvas: TCanvas);
    procedure GetRenderCullLimits(out ACullTop, ACullBottom: Single);
    procedure PaintTableCellBorders(ACanvas: TCanvas);

    // State helpers
    function GetCurrentAlignment: TS4YHTMLAlignment;
    function GetCurrentParagraphFormat: TS4YParagraphFormat;
    function GetCurrentIsOrderedList: Boolean;
    function GetCurrentIsUnorderedList: Boolean;

    // Image support
    function RenderSVGToBitmap(const ASVGDOM: ISkSVGDOM; AWidth, AHeight: Integer): TBitmap;
    function LoadBitmapFromSource(const ASource: string; AWidth: Integer = 0; AHeight: Integer = 0): TBitmap;
    function LoadImage(const ASource: string; AContext: TS4YImageLoadContext = ilcRender; AWidth: Integer = 0; AHeight: Integer = 0): TBitmap;
    function IsDeferredImageSource(const ASource: string): Boolean;
    function IsImageLoadAllowed(const ASource: string; AContext: TS4YImageLoadContext): Boolean;
    function IsLocalImageAccessAllowed(const ASource: string): Boolean;
    function LoadAllowedBitmap(const ASource: string; AContext: TS4YImageLoadContext; AWidth: Integer = 0; AHeight: Integer = 0): TBitmap;
    procedure LoadDeferredImages(ALocal: Boolean);
    procedure PreloadImages;
    procedure PrepareImageDimensions;

    // Position helpers (run-structure-independent)
    function DocumentPositionToAbsChar(const APosition: TS4YDocumentPosition): Integer;
    function AbsCharToDocumentPosition(AParagraphIndex, AAbsChar: Integer; PreferRight: Boolean = False): TS4YDocumentPosition;

    // Caret & navigation
    procedure UpdateCaretXY;
    function HitTest(AX, AY: Single): TS4YDocumentPosition;
    function LinkURLAt(AX, AY: Single): string;
    function LinkTextForURL(const APosition: TS4YDocumentPosition; const AURL: string): string;
    function DocumentPositionToXY(const APosition: TS4YDocumentPosition; out AX, AY, AHeight: Single): Boolean;
    function FragmentIndexAt(AParagraphIndex, ARunIndex, ACharIndex: Integer): Integer;
    function NextDocumentPosition(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
    function PreviousDocumentPosition(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
    function LineAbove(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
    function LineBelow(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
    function LineStart(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
    function LineEnd(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
    function DocumentStart: TS4YDocumentPosition;
    function DocumentEnd: TS4YDocumentPosition;
    function WordRight(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
    function WordLeft(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
    function PositionCompare(const ALeft, ARight: TS4YDocumentPosition): Integer;
    procedure GetSelectionRange(out AStartPosition, AEndPosition: TS4YDocumentPosition);
    procedure GetListBlockRange(out AFirst, ALast: Integer);
    procedure RenumberListBlock(AFirst, ALast: Integer);

    // Editing
    procedure InsertChar(AChar: Char);
    procedure InsertString(const AText: string);
    procedure DeleteBack;
    procedure DeleteForward;
    procedure DeleteSelection;
    function BuildFullHTML(const AImageSourceConverter: TFunc<string, string>): string;
    function GetFullHTML: string;
    procedure SetFullHTML(const Value: string);
    function GetSelectionHTML: string;
    function GetSelectionText: string;
    procedure InsertParagraphBreak;
    procedure InsertLineBreak;
    procedure MergeWithPrevious(AParagraphIndex: Integer);

    // Search helpers
    function ParagraphSearchText(AParagraphIndex: Integer): string;
    procedure SelectRange(const AStart, AEnd: TS4YDocumentPosition);

    // Style helpers
    procedure ApplyFormatToSelection(ABold, AItalic, AUnderline, AStrikeOut, ASuperscript, ASubscript: Integer; // -1=no DoChange, 0=off, 1=on
      const AFontName: string; AFontSize: Single; // ''/ 0 = no DoChange
      AColor, ABackgroundColor: TAlphaColor; // claNull = no DoChange
      const ALinkURL: string = #0); // #0 = no DoChange
    procedure SplitRunAt(AParagraphIndex, ARunIndex, ACharIndex: Integer);
    procedure NormalizeRuns(AParagraphIndex: Integer);

    // Undo
    procedure ClearRedo;

    // Timer
    procedure OnCaretTick(Sender: TObject);

    // Scrollbar
    procedure UpdateScrollBar;
    procedure ScrollTo(AY: Single);
    procedure OnScrollChange(Sender: TObject);

    // Properties
    function BuildHTML(const AImageSourceConverter: TFunc<string, string>): string;
    function GetHTML: string;
    procedure SetHTML(const Value: string);
    procedure SetLineSpacing(const Value: Single);
    procedure SetParagraphSpacing(const Value: Single);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetDocumentPath(const Value: string);
    procedure SetImagePathMode(const Value: TS4YImagePathMode);
    procedure SetLocalImageAccess(const Value: TS4YLocalImageAccess);
    procedure ReloadImagesAfterPathChange;
    procedure UpdateSourcesAfterExport(const AExporter: TS4YImageExporter; const ADestinationFolder: string);
    function StoredImageSource(const ASource: string): string;
    procedure SetBackgroundColor(const Value: TAlphaColor);
    procedure SetFontColor(const Value: TAlphaColor);
    procedure SetFont(const Value: TFont);
    procedure FontChanged(Sender: TObject);

    // Placeholder
    procedure SetPlaceholderPrefix(const Value: string);
    procedure SetPlaceholderSuffix(const Value: string);
    procedure AppearanceChanged(Sender: TObject);
    procedure ScanForPlaceholders(ADocument: TS4YHTMLDocument);
    procedure RebuildPlaceholderList;
    function GetPlaceholderLabel(const ARawText: string): string;
    function GetCurrentRun: TS4YHTMLRun;
    procedure PaintPlaceholderFragment(ACanvas: TCanvas; const AFragment: TS4YLayoutFragment);

    // Word / line selection
    function CharAtPosition(const APosition: TS4YDocumentPosition): Char;
    procedure SelectWordAt(const APosition: TS4YDocumentPosition);
    procedure SelectParagraphAt(const APosition: TS4YDocumentPosition);

    // Context menu
    procedure BuildContextMenu;
    procedure UpdateContextMenuState;
    procedure ContextMenuItemClick(Sender: TObject);

    // Full-document import/export
    procedure ScanDocumentMeta(const AHTML: string; out ATitle, ALanguage: string);

    // Table helpers
    procedure GetTableBounds(ATableID: Integer; out AFirstIndex, ALastIndex: Integer);
    function FindFirstCellInRow(ATableID, ARow: Integer): Integer;

    // Misc
    function EnsureValidDocument: Boolean;

  protected
    procedure DoChanged;
    procedure DoNotifyState;

    // Layout & rendering
    procedure DoLayout;
    procedure InvalidateRender;
    procedure PaintBackground(ACanvas: TCanvas);
    procedure PaintBorder(ACanvas: TCanvas);
    procedure PaintCaret(ACanvas: TCanvas);
    procedure PaintFragment(ACanvas: TCanvas; const AFragment: TS4YLayoutFragment);

    // State & style
    function GetState: TS4YEditorState;
    function StyleAtCaret: TS4YHTMLTextStyle;

    // Editing support
    procedure EnsureCaretVisible;
    procedure SaveUndo;
    procedure SetCaretPosition(const APosition: TS4YDocumentPosition; ExtendSel: Boolean);
    procedure ApplyCaretPosition(const APosition: TS4YDocumentPosition; ExtendSel: Boolean);
    procedure ResetSelection;
    procedure MoveCaretPosition(const APosition: TS4YDocumentPosition; ExtendSel: Boolean);
    function IsPlaceholderPosition(const APosition: TS4YDocumentPosition): Boolean;

    // Table navigation
    function DoTableTab(AShift: TShiftState): Boolean;
    function IsTableCellOf(AParagraphIndex, ATableID: Integer): Boolean;
    function FindTableCellAt(ATableID, ARow, ACol: Integer): Integer;
    function FindColumnBorderAt(ADocumentX, ADocumentY: Single; out ATableID, ABoundary: Integer): Boolean;
    function GetColumnWidths(ATableID: Integer): TArray<Single>;
    procedure ApplyColumnWidths(ATableID: Integer; const AWidths: TArray<Single>);
    procedure ApplyTableWidth(ATableID: Integer; AWidth: Single);
    procedure StartColumnResize(ATableID, ABoundary: Integer; AX: Single);
    procedure ContinueColumnResize(AX: Single);
    procedure FinishColumnResize;
    function InSameBlockScope(AFirstIndex, ASecondIndex: Integer): Boolean;
    function IsParagraphInLayoutCell(ACellIndex, AParagraphIndex: Integer): Boolean;
    function InSameTableCell(AFirstIndex, ASecondIndex: Integer): Boolean;
    function TableHasNesting(ATableID: Integer): Boolean;
    function TableHasSpans(ATableID: Integer): Boolean;

    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure DialogKey(var Key: Word; Shift: TShiftState); override;
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Resize; override;
    function ShowContextMenu(const ScreenPosition: TPointF): Boolean; override;

  public
    /// <summary>Creates the control with an empty document, a 400 x 300 size and the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // -- Formatting ---------------------------------------------------------
    /// <summary>Toggles bold on the selection or, with no selection, at the caret.</summary>
    procedure ToggleBold;
    /// <summary>Toggles italic on the selection or, with no selection, at the caret.</summary>
    procedure ToggleItalic;
    /// <summary>Toggles underline on the selection or, with no selection, at the caret.</summary>
    procedure ToggleUnderline;
    /// <summary>Toggles strikethrough on the selection or, with no selection, at the caret.</summary>
    procedure ToggleStrikeOut;
    /// <summary>Toggles superscript on the selection or, with no selection, at the caret.</summary>
    procedure ToggleSuperscript;
    /// <summary>Toggles subscript on the selection or, with no selection, at the caret.</summary>
    procedure ToggleSubscript;
    /// <summary>Decreases the font size of the selection or of the caret by one step.</summary>
    procedure DecreaseFontSize;
    /// <summary>Increases the font size of the selection or of the caret by one step.</summary>
    procedure IncreaseFontSize;
    /// <summary>
    /// Applies a font family to the selection or, with no selection, at the caret.
    /// </summary>
    /// <param name="AName">Font family name.</param>
    procedure SetCurrentFontName(const AName: string);
    /// <summary>
    /// Applies a font size to the selection or, with no selection, at the caret.
    /// </summary>
    /// <param name="ASize">Font size in points.</param>
    procedure SetCurrentFontSize(ASize: Single);
    /// <summary>
    /// Applies a text color to the selection or, with no selection, at the caret.
    /// </summary>
    /// <param name="AColor">Text color.</param>
    procedure SetCurrentFontColor(AColor: TAlphaColor);
    /// <summary>
    /// Applies a highlight color to the selection or, with no selection, at the caret.
    /// </summary>
    /// <param name="AColor">Highlight color; claNull removes it.</param>
    procedure SetCurrentBackgroundColor(AColor: TAlphaColor);
    /// <summary>Removes all character formatting from the selection.</summary>
    procedure ClearFormatting;
    /// <summary>Aligns the paragraphs of the selection, or the paragraph at the caret, to the left.</summary>
    procedure AlignLeft;
    /// <summary>Centers the paragraphs of the selection, or the paragraph at the caret.</summary>
    procedure AlignCenter;
    /// <summary>Aligns the paragraphs of the selection, or the paragraph at the caret, to the right.</summary>
    procedure AlignRight;
    /// <summary>Justifies the paragraphs of the selection, or the paragraph at the caret.</summary>
    procedure AlignJustify;
    /// <summary>
    /// Sets the heading level of the paragraphs of the selection, or of the paragraph at the caret.
    /// </summary>
    /// <param name="ALevel">Heading level from 1 to 6; 0 makes a plain paragraph. Values outside 0..6 are limited to that range.</param>
    /// <remarks>
    /// Kept for compatibility. Prefer SetCurrentParagraphFormat.
    /// </remarks>
    procedure SetHeading(ALevel: Integer); // 0=p, 1..6=h1..h6 (legacy -- prefer SetCurrentParagraphFormat)
    /// <summary>
    /// Sets the format of the paragraphs of the selection, or of the paragraph at the caret.
    /// </summary>
    /// <param name="AFormat">The new format: body text, paragraph, heading 1 to 6, or preformatted.</param>
    procedure SetCurrentParagraphFormat(AFormat: TS4YParagraphFormat);
    /// <summary>Turns the paragraphs of the selection, or the paragraph at the caret, into a numbered list, or back into plain paragraphs.</summary>
    procedure ToggleOrderedList;
    /// <summary>Turns the paragraphs of the selection, or the paragraph at the caret, into a bulleted list, or back into plain paragraphs.</summary>
    procedure ToggleUnorderedList;
    /// <summary>Increases the indent level of the paragraphs of the selection (nests list items, indents quotes).</summary>
    procedure Indent;
    /// <summary>
    /// Decreases the indent level of the paragraphs of the selection.
    /// </summary>
    /// <remarks>
    /// It has an effect only when State.CanOutdent is True.
    /// </remarks>
    procedure Outdent;
    /// <summary>
    /// Inserts a horizontal rule after the paragraph at the caret.
    /// </summary>
    /// <param name="AColor">Color of the rule; claNull uses the default color.</param>
    /// <param name="AThickness">Thickness in pixels; 0 uses the default thickness.</param>
    procedure InsertHorizontalRule(AColor: TAlphaColor = claNull; AThickness: Single = 0);
    /// <summary>
    /// Inserts an image at the caret.
    /// </summary>
    /// <param name="ASource">Image source: a file path, a file: URL, an http(s) address or a data: URI.</param>
    /// <param name="AWidth">Width in pixels; 0 uses the natural width of the image.</param>
    /// <param name="AHeight">Height in pixels; 0 uses the natural height of the image.</param>
    /// <param name="AAlt">Alternative text.</param>
    /// <remarks>
    /// In ImagePathMode ipmDocument the source is stored relative to DocumentPath when the file is inside that folder.
    /// The current implementation inserts the image as an inline run, the same as InsertInlineImage.
    /// </remarks>
    procedure InsertImage(const ASource: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
    /// <summary>
    /// Inserts an image as an inline run in the paragraph at the caret.
    /// </summary>
    /// <param name="ASource">Image source: a file path, a file: URL, an http(s) address or a data: URI.</param>
    /// <param name="AWidth">Width in pixels; 0 uses the natural width of the image.</param>
    /// <param name="AHeight">Height in pixels; 0 uses the natural height of the image.</param>
    /// <param name="AAlt">Alternative text.</param>
    /// <remarks>
    /// If some text is selected it is deleted first, so OnChange can fire twice.
    /// </remarks>
    procedure InsertInlineImage(const ASource: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
    /// <summary>
    /// Replaces the image at the caret.
    /// </summary>
    /// <param name="ASource">New image source.</param>
    /// <param name="AWidth">Width in pixels; 0 uses the natural width.</param>
    /// <param name="AHeight">Height in pixels; 0 uses the natural height.</param>
    /// <param name="AAlt">Alternative text.</param>
    /// <remarks>
    /// It does nothing when the caret is not on an inline image; check State.IsImage first.
    /// </remarks>
    procedure UpdateImage(const ASource: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
    /// <summary>
    /// Reads again every image that is in the image cache and redraws.
    /// </summary>
    /// <remarks>
    /// Use it when image files changed on disk. Each image goes through the same checks as the first load
    /// (LocalImageAccess and OnBeforeLoadImage), and OnLoadImage receives the ilcReload context.
    /// An image that is now refused is not replaced.
    /// </remarks>
    procedure ReloadImages;
    /// <summary>
    /// Inserts an empty table after the paragraph at the caret.
    /// </summary>
    /// <param name="ARows">Number of rows; at least 1.</param>
    /// <param name="ACols">Number of columns; at least 1.</param>
    /// <remarks>
    /// The caret moves to the first cell.
    /// </remarks>
    procedure InsertTable(ARows: Integer = 2; ACols: Integer = 2);
    /// <summary>
    /// Inserts a row after the row that contains the caret.
    /// </summary>
    /// <remarks>
    /// It does nothing when ReadOnly is True.
    /// </remarks>
    procedure InsertTableRow;
    /// <summary>
    /// Deletes the row that contains the caret.
    /// </summary>
    /// <remarks>
    /// It does nothing when ReadOnly is True.
    /// </remarks>
    procedure DeleteTableRow;
    /// <summary>
    /// Inserts a column after the column that contains the caret.
    /// </summary>
    /// <remarks>
    /// It does nothing when ReadOnly is True.
    /// </remarks>
    procedure InsertTableColumn;
    /// <summary>
    /// Deletes the column that contains the caret.
    /// </summary>
    /// <remarks>
    /// It does nothing when ReadOnly is True.
    /// </remarks>
    procedure DeleteTableColumn;
    /// <summary>
    /// Inserts text as a new hyperlink at the caret.
    /// </summary>
    /// <param name="AURL">Target of the link.</param>
    /// <param name="AText">Visible text of the link.</param>
    /// <remarks>
    /// It does nothing when either value is empty.
    /// </remarks>
    procedure InsertLink(const AURL, AText: string);
    /// <summary>
    /// Sets the target of a link.
    /// </summary>
    /// <param name="AURL">The new target; an empty string removes the link.</param>
    /// <remarks>
    /// It applies to the selection or, with no selection, to the link at the caret.
    /// </remarks>
    procedure UpdateLink(const AURL: string);
    /// <summary>Removes the hyperlink from the selection. The text is kept.</summary>
    procedure RemoveLink;
    /// <summary>
    /// Gets the link at the caret.
    /// </summary>
    /// <returns>The target of the link at the caret, or an empty string when the caret is not on a link.</returns>
    function GetLinkAtCaret: string;
    /// <summary>
    /// Inserts plain text at the caret, replacing the selection.
    /// </summary>
    /// <param name="AText">Text to insert; line breaks start new paragraphs.</param>
    procedure InsertText(const AText: string);
    /// <summary>
    /// Parses an HTML fragment and inserts it at the caret, replacing the selection.
    /// </summary>
    /// <param name="AHTML">HTML fragment to insert.</param>
    procedure InsertHTML(const AHTML: string);
    /// <summary>
    /// Inserts a placeholder chip at the caret.
    /// </summary>
    /// <param name="ARawText">Text of the placeholder, without the prefix and the suffix.</param>
    /// <param name="ADisplayName">Label to show; empty uses OnGetPlaceholderLabel or the raw text.</param>
    /// <remarks>
    /// It does nothing when PlaceholderPrefix or PlaceholderSuffix is empty.
    /// </remarks>
    procedure InsertPlaceholder(const ARawText: string; const ADisplayName: string = '');
    /// <summary>
    /// Replaces the placeholder at the caret.
    /// </summary>
    /// <param name="ANewRawText">New text of the placeholder, without the prefix and the suffix.</param>
    /// <param name="ANewDisplayName">New label to show; empty uses OnGetPlaceholderLabel or the raw text.</param>
    /// <remarks>
    /// It does nothing when the caret is not on a placeholder, or when PlaceholderPrefix or PlaceholderSuffix is empty.
    /// </remarks>
    procedure UpdatePlaceholder(const ANewRawText: string; const ANewDisplayName: string = '');

    // -- Editing ------------------------------------------------------------
    /// <summary>Selects the whole document.</summary>
    procedure SelectAll;
    /// <summary>Removes the selection without changing the content.</summary>
    procedure ClearSelection;
    /// <summary>
    /// Undoes the last change.
    /// </summary>
    /// <remarks>
    /// Up to 100 levels are kept, as copies of the document. It is not blocked by ReadOnly.
    /// </remarks>
    procedure Undo;
    /// <summary>
    /// Redoes the last undone change.
    /// </summary>
    /// <remarks>
    /// It is not blocked by ReadOnly.
    /// </remarks>
    procedure Redo;
    /// <summary>Copies the selection to the clipboard and deletes it.</summary>
    procedure Cut;
    /// <summary>Copies the selection to the clipboard, as HTML and as plain text where the platform supports it.</summary>
    procedure Copy;
    /// <summary>
    /// Pastes the clipboard at the caret, keeping the formatting when the clipboard holds HTML.
    /// </summary>
    /// <remarks>
    /// It does nothing when ReadOnly is True.
    /// </remarks>
    procedure Paste;
    /// <summary>
    /// Pastes the clipboard at the caret as plain text.
    /// </summary>
    /// <remarks>
    /// It does nothing when ReadOnly is True. Shortcut: Ctrl+Shift+V.
    /// </remarks>
    procedure PasteAsPlainText;

    // -- Navigation ---------------------------------------------------------
    /// <summary>
    /// Scrolls the document so that a paragraph is at the top.
    /// </summary>
    /// <param name="AIndex">Index of the paragraph; invalid indexes are ignored.</param>
    procedure ScrollToParagraph(AIndex: Integer);
    /// <summary>
    /// Scrolls the document so that a position is visible.
    /// </summary>
    /// <param name="APosition">The position to show.</param>
    procedure ScrollToDocumentPosition(const APosition: TS4YDocumentPosition);

    // -- Document info -------------------------------------------------------
    /// <summary>
    /// Counts the characters of the document.
    /// </summary>
    /// <returns>Number of text characters; images and placeholders are not counted.</returns>
    function CharCount: Integer;
    /// <summary>
    /// Counts the words of the document.
    /// </summary>
    /// <returns>Number of words, separated by white space.</returns>
    function WordCount: Integer;

    // -- Images -------------------------------------------------------------
    /// <summary>
    /// Loads the local images that were skipped because AutoLoadLocalImages is False.
    /// </summary>
    procedure LoadLocalImages;
    /// <summary>
    /// Downloads the remote images that were skipped because AutoLoadRemoteImages is False.
    /// </summary>
    /// <remarks>
    /// The download is synchronous on the calling thread, with no timeout set by the component.
    /// </remarks>
    procedure LoadRemoteImages;
    /// <summary>
    /// Finds the file or URL that an image source is read from.
    /// </summary>
    /// <param name="ASource">The image source as written in the document.</param>
    /// <returns>The file path or URL, according to ImagePathMode and DocumentPath.</returns>
    function ResolveImageSource(const ASource: string): string;

    // -- Files --------------------------------------------------------------
    /// <summary>
    /// Loads an HTML file into the editor.
    /// </summary>
    /// <param name="AFileName">Name of the file.</param>
    /// <param name="AEncoding">Encoding of the file; nil means UTF-8.</param>
    /// <remarks>
    /// DocumentPath is set to the folder of the file first, so document-relative images resolve. Title and Language are read from the file. OnChange is not fired.
    /// </remarks>
    procedure LoadFromFile(const AFileName: string; AEncoding: TEncoding = nil);
    /// <summary>
    /// Saves the document as a complete HTML file.
    /// </summary>
    /// <param name="AFileName">Name of the file.</param>
    /// <param name="AEncoding">Encoding of the file; nil means UTF-8.</param>
    /// <remarks>
    /// In ipmDocument mode the image sources are left as they are and DocumentPath moves to the folder of the file. In ipmApplication mode relative sources are written as absolute file: URLs in the saved text; the document is not changed.
    /// </remarks>
    procedure SaveToFile(const AFileName: string; AEncoding: TEncoding = nil); overload;
    /// <summary>
    /// Saves the document as a complete HTML file, with options.
    /// </summary>
    /// <param name="AFileName">Name of the file.</param>
    /// <param name="AOptions">Options such as copying the images next to the file.</param>
    /// <param name="AEncoding">Encoding of the file; nil means UTF-8.</param>
    /// <remarks>
    /// See TS4YSaveOptions. If the destination cannot be written the exception is raised normally.
    /// </remarks>
    procedure SaveToFile(const AFileName: string; const AOptions: TS4YSaveOptions; AEncoding: TEncoding = nil); overload;

    // -- Search -------------------------------------------------------------
    /// <summary>
    /// Selects the next occurrence of a text, starting from the end of the selection or from the caret.
    /// </summary>
    /// <param name="AText">Text to find.</param>
    /// <param name="CaseSensitive">True for a case-sensitive search.</param>
    /// <returns>True when the text was found; the search wraps around the document.</returns>
    function FindNext(const AText: string; CaseSensitive: Boolean = False): Boolean;
    /// <summary>
    /// Selects the previous occurrence of a text, starting from the start of the selection or from the caret.
    /// </summary>
    /// <param name="AText">Text to find.</param>
    /// <param name="CaseSensitive">True for a case-sensitive search.</param>
    /// <returns>True when the text was found; the search wraps around the document.</returns>
    function FindPrevious(const AText: string; CaseSensitive: Boolean = False): Boolean;
    /// <summary>
    /// Replaces every occurrence of a text in the document.
    /// </summary>
    /// <param name="AFindText">Text to find.</param>
    /// <param name="AReplaceText">Replacement text.</param>
    /// <param name="CaseSensitive">True for a case-sensitive search.</param>
    /// <returns>Number of replacements.</returns>
    /// <remarks>
    /// It is a single undo step.
    /// </remarks>
    function ReplaceAll(const AFindText, AReplaceText: string; CaseSensitive: Boolean = False): Integer;

    /// <summary>
    /// The run of text that contains the caret.
    /// </summary>
    /// <value>The run, or nil when there is none.</value>
    /// <remarks>
    /// The run belongs to the document: do not free it and do not keep it after the content changes.
    /// </remarks>
    property CurrentRun: TS4YHTMLRun read GetCurrentRun;
    /// <summary>
    /// The complete HTML document, with doctype, head and body.
    /// </summary>
    /// <remarks>
    /// Reading it generates the HTML with Title and Language. Writing it replaces the content, extracts Title and Language, clears the undo history and does not fire OnChange.
    /// </remarks>
    property FullHTML: string read GetFullHTML write SetFullHTML;
    /// <summary>True when some text is selected.</summary>
    property HasSelection: Boolean read FHasSelection;
    /// <summary>
    /// All placeholder runs of the document.
    /// </summary>
    /// <remarks>
    /// The list is kept in sync with every edit and is read-only: do not change it or its runs from outside.
    /// </remarks>
    property Placeholders: TList<TS4YHTMLRun> read FPlaceholders;
    /// <summary>The selection as an HTML fragment; empty when nothing is selected.</summary>
    property SelHTML: string read GetSelectionHTML;
    /// <summary>The selection as plain text; empty when nothing is selected.</summary>
    property SelText: string read GetSelectionText;
    /// <summary>
    /// The formatting state at the caret.
    /// </summary>
    /// <remarks>
    /// A fresh snapshot is computed at every read.
    /// </remarks>
    property State: TS4YEditorState read GetState;

  published
    property Align;
    property Anchors;
    /// <summary>
    /// Load images whose source is a local file as soon as the content is set.
    /// </summary>
    /// <remarks>
    /// When False they are drawn as placeholders until LoadLocalImages is called.
    /// </remarks>
    property AutoLoadLocalImages: Boolean read FAutoLoadLocalImages write FAutoLoadLocalImages default True;
    /// <summary>
    /// Load images whose source is an http or https address as soon as the content is set.
    /// </summary>
    /// <remarks>
    /// When False they are drawn as placeholders until LoadRemoteImages is called. Loading is synchronous on the calling thread.
    /// </remarks>
    property AutoLoadRemoteImages: Boolean read FAutoLoadRemoteImages write FAutoLoadRemoteImages default True;
    /// <summary>Background color of the editor.</summary>
    property BackgroundColor: TAlphaColor read FBackgroundColor write SetBackgroundColor default claWhite;
    /// <summary>
    /// Folder of the document, used to resolve relative image paths when ImagePathMode is ipmDocument.
    /// </summary>
    /// <remarks>
    /// LoadFromFile sets it. Changing it reloads the images.
    /// </remarks>
    property DocumentPath: string read FDocumentPath write SetDocumentPath;
    /// <summary>Default font of the editor, used for text that has no font of its own.</summary>
    property Font: TFont read FFont write SetFont;
    /// <summary>Default text color, used for text that has no color of its own.</summary>
    property FontColor: TAlphaColor read FFontColor write SetFontColor default claBlack;
    property Height;
    /// <summary>
    /// The HTML of the body of the document, as a fragment without doctype.
    /// </summary>
    /// <remarks>
    /// Reading it generates the HTML from the document each time; an empty document gives an empty string.
    /// Writing it replaces the content, clears the undo history, moves the caret to the start and does not fire OnChange. It is notified to LiveBindings after every edit.
    /// </remarks>
    property HTML: string read GetHTML write SetHTML;
    /// <summary>
    /// How relative local image paths are resolved.
    /// </summary>
    /// <remarks>
    /// Changing it reloads the images.
    /// </remarks>
    property ImagePathMode: TS4YImagePathMode read FImagePathMode write SetImagePathMode default ipmApplication;
    /// <summary>Language of the document, written as the lang attribute of FullHTML.</summary>
    property Language: string read FLanguage write FLanguage;
    /// <summary>Line height multiplier: 1.0 is the natural height. Changing it lays the document out again.</summary>
    property LineSpacing: Single read FLineSpacing write SetLineSpacing;
    /// <summary>
    /// Which local files images may be read from.
    /// </summary>
    /// <remarks>
    /// Use liaDocumentFolder for content from untrusted sources, with an empty DocumentPath to read no local file at all. Changing it reloads the images.
    /// </remarks>
    property LocalImageAccess: TS4YLocalImageAccess read FLocalImageAccess write SetLocalImageAccess default liaAnywhere;
    property Margins;
    property Opacity;
    property Padding;
    /// <summary>Extra vertical space between blocks, in pixels. Changing it lays the document out again.</summary>
    property ParagraphSpacing: Single read FParagraphSpacing write SetParagraphSpacing;
    /// <summary>Visual style of the placeholder chips.</summary>
    property PlaceholderAppearance: TS4YPlaceholderAppearance read FPlaceholderAppearance write FPlaceholderAppearance;
    /// <summary>
    /// Text that starts a placeholder in the HTML.
    /// </summary>
    /// <remarks>
    /// Placeholders are disabled until both PlaceholderPrefix and PlaceholderSuffix are set.
    /// </remarks>
    property PlaceholderPrefix: string read FPlaceholderPrefix write SetPlaceholderPrefix;
    /// <summary>
    /// Text that ends a placeholder in the HTML.
    /// </summary>
    /// <remarks>
    /// Placeholders are disabled until both PlaceholderPrefix and PlaceholderSuffix are set.
    /// </remarks>
    property PlaceholderSuffix: string read FPlaceholderSuffix write SetPlaceholderSuffix;
    property Position;
    /// <summary>Generate indented HTML.</summary>
    property PrettyHTML: Boolean read FPrettyHTML write FPrettyHTML default False;
    /// <summary>
    /// Prevents the user from changing the document.
    /// </summary>
    /// <remarks>
    /// It blocks typing, Backspace, Delete, Enter, paste, the shortcuts that change the document (Ctrl+B, I, U, X, Z, Y) and the table row and column commands. Selection, copy and link clicks keep working.
    /// It does not block the methods called from code: InsertText, ToggleBold, Undo and the others still change the document.
    /// </remarks>
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    /// <summary>Draw a one-pixel border around the control.</summary>
    property ShowBorder: Boolean read FShowBorder write FShowBorder default True;
    property Size;
    /// <summary>Title of the document, written as the title element of FullHTML.</summary>
    property Title: string read FTitle write FTitle;
    property Visible;
    property Width;
    /// <summary>
    /// Fired before an image is read or downloaded; set Allow to False to refuse it.
    /// </summary>
    /// <remarks>
    /// See TS4YBeforeLoadImageEvent.
    /// </remarks>
    property OnBeforeLoadImage: TS4YBeforeLoadImageEvent read FOnBeforeLoadImage write FOnBeforeLoadImage;
    /// <summary>
    /// Fired after the document changes: typing, deleting, formatting, insertions, paste, undo and redo, replace.
    /// </summary>
    /// <remarks>
    /// One action can fire it more than once (for example inserting an image over a selection), so treat it as "something changed", not as a counter.
    /// It is not fired when HTML, FullHTML or LoadFromFile set the content.
    /// </remarks>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClick;
    property OnDblClick;
    /// <summary>
    /// Custom drawing of a list bullet.
    /// </summary>
    /// <remarks>
    /// See TS4YDrawListMarkerEvent. It is called only for the items near the visible area.
    /// </remarks>
    property OnDrawListMarker: TS4YDrawListMarkerEvent read FOnDrawListMarker write FOnDrawListMarker;
    /// <summary>
    /// Custom drawing of a placeholder chip.
    /// </summary>
    /// <remarks>
    /// See TS4YDrawPlaceholderEvent. It is called only for the placeholders near the visible area.
    /// </remarks>
    property OnDrawPlaceholder: TS4YDrawPlaceholderEvent read FOnDrawPlaceholder write FOnDrawPlaceholder;
    /// <summary>
    /// Supplies a text character as the bullet of a list item.
    /// </summary>
    /// <remarks>
    /// See TS4YGetListMarkerEvent. It takes priority over OnDrawListMarker.
    /// </remarks>
    property OnGetListMarker: TS4YGetListMarkerEvent read FOnGetListMarker write FOnGetListMarker;
    /// <summary>
    /// Maps the raw text of a placeholder to the label shown.
    /// </summary>
    /// <remarks>
    /// See TS4YGetPlaceholderLabelEvent.
    /// </remarks>
    property OnGetPlaceholderLabel: TS4YGetPlaceholderLabelEvent read FOnGetPlaceholderLabel write FOnGetPlaceholderLabel;
    /// <summary>Fired when the user clicks a hyperlink.</summary>
    property OnLinkClick: TS4YLinkClickEvent read FOnLinkClick write FOnLinkClick;
    /// <summary>Fired when the pointer is over a hyperlink; the cursor can be changed.</summary>
    property OnLinkHover: TS4YLinkHoverEvent read FOnLinkHover write FOnLinkHover;
    /// <summary>
    /// Lets the application provide or replace the bitmap of an image.
    /// </summary>
    /// <remarks>
    /// See TS4YLoadImageEvent.
    /// </remarks>
    property OnLoadImage: TS4YLoadImageEvent read FOnLoadImage write FOnLoadImage;
    property OnResize;
    /// <summary>
    /// Fired when the caret or the selection moves, after edits, and after the content is replaced; use it to update a toolbar.
    /// </summary>
    /// <remarks>
    /// See TS4YEditorStateEvent.
    /// </remarks>
    property OnStateChange: TS4YEditorStateEvent read FOnStateChange write FOnStateChange;
  end;

implementation

uses
  System.IOUtils;

// -----------------------------------------------------------------------------
// FMX helper for TS4YHTMLTextStyle
// -----------------------------------------------------------------------------

function TextStyleToFMXFontStyle(const AStyle: TS4YHTMLTextStyle): TFontStyles;
begin
  Result := [];
  if AStyle.Bold then
    Include(Result, TFontStyle.fsBold);
  if AStyle.Italic then
    Include(Result, TFontStyle.fsItalic);
  if AStyle.Underline then
    Include(Result, TFontStyle.fsUnderline);
  if AStyle.StrikeOut then
    Include(Result, TFontStyle.fsStrikeOut);
end;

// -----------------------------------------------------------------------------
// TS4YUndoEntry
// -----------------------------------------------------------------------------

constructor TS4YUndoEntry.Create(ADocument: TS4YHTMLDocument; const ACaret, ASelectionStart, ASelectionEnd: TS4YDocumentPosition);
begin
  inherited Create;
  FDocument := ADocument;
  FCaretPosition := ACaret;
  FSelectionStart := ASelectionStart;
  FSelectionEnd := ASelectionEnd;
end;

destructor TS4YUndoEntry.Destroy;
begin
  FDocument.Free;
  inherited;
end;

// -----------------------------------------------------------------------------
// TS4YPlaceholderAppearance
// -----------------------------------------------------------------------------

constructor TS4YPlaceholderAppearance.Create;
begin
  inherited;
  FFillColor := $FFD0E8FF; // soft blue fill
  FTextColor := $FF1060C0; // dark blue text
  FBorderColor := $FF88BBEE; // medium blue border
  FBorderRadius := 4;
  FHorizontalPadding := 6;
  FVerticalPadding := 1;
  FBold := True;
end;

procedure TS4YPlaceholderAppearance.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YPlaceholderAppearance.Assign(Source: TPersistent);
var
  LSourceAppearance: TS4YPlaceholderAppearance;
begin
  if Source is TS4YPlaceholderAppearance then
  begin
    LSourceAppearance := TS4YPlaceholderAppearance(Source);
    FFillColor := LSourceAppearance.FFillColor;
    FTextColor := LSourceAppearance.FTextColor;
    FBorderColor := LSourceAppearance.FBorderColor;
    FBorderRadius := LSourceAppearance.FBorderRadius;
    FHorizontalPadding := LSourceAppearance.FHorizontalPadding;
    FVerticalPadding := LSourceAppearance.FVerticalPadding;
    FBold := LSourceAppearance.FBold;
    Changed;
  end
  else
    inherited;
end;

procedure TS4YPlaceholderAppearance.SetFillColor(Value: TAlphaColor);
begin
  if FFillColor <> Value then
  begin
    FFillColor := Value;
    Changed;
  end;
end;

procedure TS4YPlaceholderAppearance.SetTextColor(Value: TAlphaColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    Changed;
  end;
end;

procedure TS4YPlaceholderAppearance.SetBorderColor(Value: TAlphaColor);
begin
  if FBorderColor <> Value then
  begin
    FBorderColor := Value;
    Changed;
  end;
end;

procedure TS4YPlaceholderAppearance.SetBorderRadius(Value: Single);
begin
  if FBorderRadius <> Value then
  begin
    FBorderRadius := Value;
    Changed;
  end;
end;

procedure TS4YPlaceholderAppearance.SetHorizontalPadding(Value: Single);
begin
  if FHorizontalPadding <> Value then
  begin
    FHorizontalPadding := Value;
    Changed;
  end;
end;

procedure TS4YPlaceholderAppearance.SetVerticalPadding(Value: Single);
begin
  if FVerticalPadding <> Value then
  begin
    FVerticalPadding := Value;
    Changed;
  end;
end;

procedure TS4YPlaceholderAppearance.SetBold(Value: Boolean);
begin
  if FBold <> Value then
  begin
    FBold := Value;
    Changed;
  end;
end;

// -----------------------------------------------------------------------------
// TS4YLayoutEngine
// -----------------------------------------------------------------------------

constructor TS4YLayoutEngine.Create;
begin
  inherited;
  FMeasure := TTextLayoutManager.DefaultTextLayout.Create;
  FMeasureCache := TDictionary<string, TSizeF>.Create;
  FLineSpacing := C_EDITOR_LINE_SPACING;
  FParagraphSpacing := C_EDITOR_PARA_SPACING;
end;

destructor TS4YLayoutEngine.Destroy;
begin
  FMeasure.Free;
  FMeasureCache.Free;
  inherited;
end;

procedure TS4YLayoutEngine.ClearMeasureCache;
begin
  FMeasureCache.Clear;
end;

procedure TS4YLayoutEngine.SetupFont(ATextStyle: TS4YHTMLTextStyle);
begin
  FMeasure.Font.Family := ATextStyle.FontName;
  FMeasure.Font.Size := EffectiveSize(ATextStyle);
  FMeasure.Font.Style := TextStyleToFMXFontStyle(ATextStyle);
end;

function TS4YLayoutEngine.EffectiveSize(ATextStyle: TS4YHTMLTextStyle): Single;
begin
  Result := ATextStyle.FontSize;
  if ATextStyle.Superscript or ATextStyle.Subscript then
    Result := Result * 0.65;
end;

function TS4YLayoutEngine.HeadingSize(ABlockType: TS4YHTMLBlockType): Single;
begin
  case ABlockType of
    btH1:
      Result := 24;
    btH2:
      Result := 20;
    btH3:
      Result := 16;
    btH4:
      Result := 14;
    btH5:
      Result := 12;
    btH6:
      Result := 10;
  else
    Result := 0; // not a heading
  end;
end;

function TS4YLayoutEngine.MeasureStr(const AText: string; ATextStyle: TS4YHTMLTextStyle): TSizeF;
var
  LEffSize: Single;
  LKey: string;
  LMeasureText: string;
  LWithSentinelW: Single;
  LSentinelW: Single;
begin
  LEffSize := EffectiveSize(ATextStyle);
  LKey := AText + #0 + ATextStyle.FontName + #0 + IntToStr(Round(LEffSize * 10)) +
          #0 + Char(Ord(ATextStyle.Bold) + Ord(ATextStyle.Italic) * 2 + 1);

  if FMeasureCache.TryGetValue(LKey, Result) then
    Exit;

  FMeasure.BeginUpdate;
  FMeasure.Font.Family := ATextStyle.FontName;
  FMeasure.Font.Size := LEffSize;
  FMeasure.Font.Style := TextStyleToFMXFontStyle(ATextStyle);
  FMeasure.MaxSize := TPointF.Create(65535, 65535);
  FMeasure.WordWrap := False;

  if AText = '' then
  begin
    FMeasure.Text := ' ';
    FMeasure.EndUpdate;
    Result := TSizeF.Create(0, FMeasure.Height);
  end
  else if AText[High(AText)] = ' ' then
  begin
    // Platform text layouts (DirectWrite, CoreText) strip trailing whitespace
    // from the bounding-box width they report. Append a sentinel glyph to
    // prevent trimming, then subtract the sentinel's own width.
    FMeasure.Text := AText + 'i';
    FMeasure.EndUpdate;
    LWithSentinelW := FMeasure.Width;
    FMeasure.BeginUpdate;
    FMeasure.Text := 'i';
    FMeasure.EndUpdate;
    LSentinelW := FMeasure.Width;
    Result := TSizeF.Create(Max(0.0, LWithSentinelW - LSentinelW), FMeasure.Height);
  end
  else
  begin
    LMeasureText := AText;
    FMeasure.Text := LMeasureText;
    FMeasure.EndUpdate;
    Result := TSizeF.Create(FMeasure.Width, FMeasure.Height);
  end;

  FMeasureCache.Add(LKey, Result);
end;

function TS4YLayoutEngine.MeasureCharOffset(const AText: string; ACharIndex: Integer; ATextStyle: TS4YHTMLTextStyle): Single;
var
  LSubstring: string;
begin
  if (ACharIndex <= 0) or (AText = '') then
    Exit(0);
  LSubstring := AText.Substring(0, Min(ACharIndex, AText.Length));
  Result := MeasureStr(LSubstring, ATextStyle).Width;
end;

function TS4YLayoutEngine.CharAtX(const AText: string; AX: Single; ATextStyle: TS4YHTMLTextStyle): Integer;
var
  LLow, LHigh, LMiddle: Integer;
  LWidth: Single;
  LWidth0: Single;
  LWidth1: Single;
begin
  if AText = '' then
    Exit(0);
  if AX <= 0 then
    Exit(0);
  LLow := 0;
  LHigh := AText.Length;
  while LLow < LHigh do
  begin
    LMiddle := (LLow + LHigh + 1) div 2;
    LWidth := MeasureStr(AText.Substring(0, LMiddle), ATextStyle).Width;
    if LWidth <= AX then
      LLow := LMiddle
    else
      LHigh := LMiddle - 1;
  end;
  // Snap to nearer side
  if LLow < AText.Length then
  begin
    LWidth0 := MeasureStr(AText.Substring(0, LLow), ATextStyle).Width;
    LWidth1 := MeasureStr(AText.Substring(0, LLow + 1), ATextStyle).Width;
    if (AX - LWidth0) > (LWidth1 - AX) then
      Inc(LLow);
  end;
  Result := LLow;
end;

procedure TS4YLayoutEngine.LayoutParagraph(AParagraph: TS4YHTMLParagraph; AParagraphIndex: Integer; AAvailableWidth, AStartY: Single;
  var ALines: TArray<TS4YLayoutLine>; var AFragments: TArray<TS4YLayoutFragment>; var AY: Single);

  procedure FlushLine(var ALineFrags: TArray<TS4YLayoutFragment>; ALineW, ALineH, ALineAsc: Single;
    IsFirst, IsLast: Boolean);
  var
    LLine: TS4YLayoutLine;
    LFragment: TS4YLayoutFragment;
    LXOffset: Single;
    LExtraX: Single;
    LIndentX: Single;
    LEffectiveWidth: Single;
    LCurrentX: Single;
    LNonSpaceFrags: Integer;
    LSpaceSum: Single;
    LFragmentStart: Integer;
    LLineIndex: Integer;
  begin
    if Length(ALineFrags) = 0 then
      Exit;

    if AParagraph.BlockType = btLI then
      LIndentX := (AParagraph.IndentLevel + 2) * C_EDITOR_LIST_INDENT
    else
      LIndentX := AParagraph.IndentLevel * C_EDITOR_BLOCKQUOTE_INDENT;
    LEffectiveWidth := AAvailableWidth - LIndentX;

    LXOffset := LIndentX;
    LExtraX := 0;
    case AParagraph.Alignment of
      haCenter:
        LXOffset := LIndentX + (LEffectiveWidth - ALineW) / 2;
      haRight:
        LXOffset := LIndentX + LEffectiveWidth - ALineW;
      haJustify:
        if (not IsLast) and (Length(ALineFrags) > 1) then
        begin
          LNonSpaceFrags := 0;
          LSpaceSum := 0;
          for var I := 0 to High(ALineFrags) do
          begin
            Inc(LNonSpaceFrags);
            LSpaceSum := LSpaceSum + ALineFrags[I].Width;
          end;
          if LNonSpaceFrags > 1 then
            LExtraX := (LEffectiveWidth - LSpaceSum) / (LNonSpaceFrags - 1);
        end;
    end;

    LFragmentStart := Length(AFragments);
    LLineIndex := Length(ALines);
    LCurrentX := LXOffset;
    LLine.Y := AY;
    LLine.Height := ALineH * FLineSpacing;
    LLine.Ascent := ALineAsc;
    LLine.ParagraphIndex := AParagraphIndex;
    LLine.IsFirst := IsFirst;
    LLine.IsLast := IsLast;
    LLine.FragmentStart := LFragmentStart;
    LLine.FragmentCount := Length(ALineFrags);
    SetLength(AFragments, LFragmentStart + Length(ALineFrags));

    for var I := 0 to High(ALineFrags) do
    begin
      LFragment := ALineFrags[I];
      LFragment.X := LCurrentX;
      LFragment.Y := AY;
      LFragment.LineIndex := LLineIndex;
      LCurrentX := LCurrentX + LFragment.Width;
      if I < High(ALineFrags) then
        LCurrentX := LCurrentX + LExtraX;
      AFragments[LFragmentStart + I] := LFragment;
    end;

    SetLength(ALines, Length(ALines) + 1);
    ALines[High(ALines)] := LLine;
    AY := AY + LLine.Height;
    SetLength(ALineFrags, 0);
  end;

  function FindWordEnd(const AText: string; AStart: Integer): Integer;
  begin
    Result := AStart;
    while (Result < AText.Length) and (AText[Low(AText) + Result] <> ' ') do
      Inc(Result);
    while (Result < AText.Length) and (AText[Low(AText) + Result] = ' ') do
      Inc(Result);
  end;

var
  LIndentX: Single;
  LRunIndex: Integer;
  LCharOfs: Integer;
  LTextStyle: TS4YHTMLTextStyle;
  LWord, LRest: string;
  LWSize: TSizeF;
  LLineFrags: TArray<TS4YLayoutFragment>;
  LLineW: Single;
  LLineH: Single;
  LLineAsc: Single;
  LIsFirstLine: Boolean;
  LFragment: TS4YLayoutFragment;
  LSeparatorIndex: Integer;
  LEffectiveAvailableWidth: Single;
  LHorizontalRuleFragment: TS4YLayoutFragment;
  LHorizontalRuleLine: TS4YLayoutLine;
  LEmptyStyle: TS4YHTMLTextStyle;
  LEmptyHeight: Single;
  LEmptyFragment: TS4YLayoutFragment;
  LHeadingSize: Single;
  LBaseHeight: Single;
  LLastRunIndex2: Integer;
  LEmptyStyle2: TS4YHTMLTextStyle;
  LEmptyHeight2: Single;
  LEmptyFragment3: TS4YLayoutFragment;
  LLabelText: string;
  LPlaceholderTextStyle: TS4YHTMLTextStyle;
  LTSize: TSizeF;
  LPlaceholderWidth: Single;
  LPlaceholderHeight: Single;
  LImageWidth: Integer;
  LImageHeight: Integer;
  LImageX: Single;

begin
  LIndentX := AParagraph.IndentLevel * C_EDITOR_BLOCKQUOTE_INDENT;
  if AParagraph.BlockType = btLI then
    LIndentX := (AParagraph.IndentLevel + 2) * C_EDITOR_LIST_INDENT;

  LEffectiveAvailableWidth := AAvailableWidth - LIndentX;
  if LEffectiveAvailableWidth < 20 then
    LEffectiveAvailableWidth := 20;

  if AParagraph.BlockType = btHR then
  begin
    LHorizontalRuleFragment := Default(TS4YLayoutFragment);
    LHorizontalRuleFragment.ParagraphIndex := AParagraphIndex;
    LHorizontalRuleFragment.RunIndex := -1;
    LHorizontalRuleFragment.CharStart := 0;
    LHorizontalRuleFragment.CharEnd := 0;
    LHorizontalRuleFragment.X := LIndentX;
    LHorizontalRuleFragment.Y := AY;
    LHorizontalRuleFragment.Width := LEffectiveAvailableWidth;
    LHorizontalRuleFragment.Height := 16;
    LHorizontalRuleFragment.Ascent := 8;
    LHorizontalRuleFragment.LineIndex := Length(ALines);
    LHorizontalRuleFragment.IsHR := True;
    SetLength(AFragments, Length(AFragments) + 1);
    AFragments[High(AFragments)] := LHorizontalRuleFragment;

    LHorizontalRuleLine.Y := AY;
    LHorizontalRuleLine.Height := 16;
    LHorizontalRuleLine.Ascent := 8;
    LHorizontalRuleLine.ParagraphIndex := AParagraphIndex;
    LHorizontalRuleLine.IsFirst := True;
    LHorizontalRuleLine.IsLast := True;
    LHorizontalRuleLine.FragmentStart := Length(AFragments) - 1;
    LHorizontalRuleLine.FragmentCount := 1;
    SetLength(ALines, Length(ALines) + 1);
    ALines[High(ALines)] := LHorizontalRuleLine;
    AY := AY + 16 + FParagraphSpacing;
    Exit;
  end;

  if AParagraph.BlockType = btImage then
  begin
    LImageWidth := AParagraph.ImageWidth;
    LImageHeight := AParagraph.ImageHeight;
    if LImageWidth = 0 then
      LImageWidth := Round(LEffectiveAvailableWidth);
    if LImageHeight = 0 then
      LImageHeight := 100;
    if LImageWidth > Round(LEffectiveAvailableWidth) then
      LImageWidth := Round(LEffectiveAvailableWidth);
    case AParagraph.Alignment of
      haCenter: LImageX := LIndentX + (LEffectiveAvailableWidth - LImageWidth) / 2;
      haRight:  LImageX := LIndentX + LEffectiveAvailableWidth - LImageWidth;
    else
      LImageX := LIndentX;
    end;
    LHorizontalRuleFragment := Default(TS4YLayoutFragment);
    LHorizontalRuleFragment.ParagraphIndex := AParagraphIndex;
    LHorizontalRuleFragment.RunIndex := -1;
    LHorizontalRuleFragment.CharStart := 0;
    LHorizontalRuleFragment.CharEnd := 0;
    LHorizontalRuleFragment.X := LImageX;
    LHorizontalRuleFragment.Y := AY;
    LHorizontalRuleFragment.Width := LImageWidth;
    LHorizontalRuleFragment.Height := LImageHeight;
    LHorizontalRuleFragment.Ascent := LImageHeight;
    LHorizontalRuleFragment.LineIndex := Length(ALines);
    LHorizontalRuleFragment.IsImage := True;
    SetLength(AFragments, Length(AFragments) + 1);
    AFragments[High(AFragments)] := LHorizontalRuleFragment;

    LHorizontalRuleLine.Y := AY;
    LHorizontalRuleLine.Height := LImageHeight;
    LHorizontalRuleLine.Ascent := LImageHeight;
    LHorizontalRuleLine.ParagraphIndex := AParagraphIndex;
    LHorizontalRuleLine.IsFirst := True;
    LHorizontalRuleLine.IsLast := True;
    LHorizontalRuleLine.FragmentStart := Length(AFragments) - 1;
    LHorizontalRuleLine.FragmentCount := 1;
    SetLength(ALines, Length(ALines) + 1);
    ALines[High(ALines)] := LHorizontalRuleLine;
    AY := AY + LImageHeight + FParagraphSpacing;
    Exit;
  end;

  if (AParagraphIndex > 0) and (AParagraph.BlockType in [btParagraph, btH1, btH2, btH3, btH4, btH5, btH6, btBlockquote, btPre]) then
    AY := AY + FParagraphSpacing;

  LLineFrags := nil;
  LLineW := 0;
  LLineH := 0;
  LLineAsc := 0;
  LIsFirstLine := True;

  if AParagraph.Runs.Count = 0 then
  begin
    LEmptyStyle.Init;
    LEmptyHeight := MeasureStr(' ', LEmptyStyle).Height;
    LEmptyFragment := Default(TS4YLayoutFragment);
    LEmptyFragment.ParagraphIndex := AParagraphIndex;
    LEmptyFragment.RunIndex := 0;
    LEmptyFragment.CharStart := 0;
    LEmptyFragment.CharEnd := 0;
    LEmptyFragment.X := LIndentX;
    LEmptyFragment.Y := AY;
    LEmptyFragment.Width := 0;
    LEmptyFragment.Height := LEmptyHeight;
    LEmptyFragment.Ascent := LEmptyHeight * 0.75;
    LEmptyFragment.LineIndex := Length(ALines);
    SetLength(LLineFrags, 1);
    LLineFrags[0] := LEmptyFragment;
    FlushLine(LLineFrags, 0, LEmptyHeight, LEmptyHeight * 0.75, True, True);
    Exit;
  end;

  LRunIndex := 0;
  LCharOfs := 0;

  for var LRun in AParagraph.Runs do
  begin
    LTextStyle := LRun.Style;
    LHeadingSize := HeadingSize(AParagraph.BlockType);
    if LHeadingSize > 0 then
    begin
      LTextStyle.FontSize := LHeadingSize;
      LTextStyle.Bold := True;
    end;
    if AParagraph.BlockType = btPre then
      LTextStyle.FontName := 'Courier New';

    if LRun.IsLineBreak then
    begin
      LBaseHeight := MeasureStr(' ', LTextStyle).Height;
      FlushLine(LLineFrags, LLineW, Max(LLineH, LBaseHeight), Max(LLineAsc, LBaseHeight * 0.75), LIsFirstLine, False);
      LIsFirstLine := False;
      LLineW := 0;
      LLineH := 0;
      LLineAsc := 0;
      Inc(LRunIndex);
      LCharOfs := 0;
    end
    else if LRun.IsPlaceholder then
    begin
      if LRun.DisplayText <> '' then
        LLabelText := LRun.DisplayText
      else
      begin
        LLabelText := LRun.Text;
        if Assigned(FPlaceholderGetLabel) then
          FPlaceholderGetLabel(FPlaceholderSender, LRun.Text, LLabelText);
      end;
      LPlaceholderTextStyle := LTextStyle;
      LPlaceholderTextStyle.Bold := LRun.Style.Bold or FPlaceholderBold;
      LPlaceholderTextStyle.Italic := LRun.Style.Italic;
      LTSize := MeasureStr(LLabelText, LPlaceholderTextStyle);
      LPlaceholderWidth := LTSize.Width + 2 * FPlaceholderPaddingH;
      LPlaceholderHeight := Max(LTSize.Height + 2 * FPlaceholderPaddingV, LTSize.Height);
      if (LLineW > 0) and (LLineW + LPlaceholderWidth > LEffectiveAvailableWidth + 0.5) then
      begin
        FlushLine(LLineFrags, LLineW, LLineH, LLineAsc, LIsFirstLine, False);
        LIsFirstLine := False;
        LLineW := 0;
        LLineH := 0;
        LLineAsc := 0;
      end;
      LFragment := Default(TS4YLayoutFragment);
      LFragment.ParagraphIndex := AParagraphIndex;
      LFragment.RunIndex := LRunIndex;
      LFragment.CharStart := 0;
      LFragment.CharEnd := LRun.Text.Length;
      LFragment.X := LIndentX + LLineW;
      LFragment.Y := AY;
      LFragment.Width := LPlaceholderWidth;
      LFragment.Height := LPlaceholderHeight;
      LFragment.Ascent := LPlaceholderHeight * 0.78;
      LFragment.IsPlaceholder := True;
      SetLength(LLineFrags, Length(LLineFrags) + 1);
      LLineFrags[High(LLineFrags)] := LFragment;
      LLineW := LLineW + LPlaceholderWidth;
      LLineH := Max(LLineH, LPlaceholderHeight);
      LLineAsc := Max(LLineAsc, LFragment.Ascent);
      Inc(LRunIndex);
    end
    else if LRun.IsImage then
    begin
      LImageWidth := LRun.ImageWidth;
      LImageHeight := LRun.ImageHeight;
      if LImageWidth <= 0 then
        LImageWidth := 100;
      if LImageHeight <= 0 then
        LImageHeight := 50;
      if (LLineW > 0) and (LLineW + LImageWidth > LEffectiveAvailableWidth + 0.5) then
      begin
        FlushLine(LLineFrags, LLineW, LLineH, LLineAsc, LIsFirstLine, False);
        LIsFirstLine := False;
        LLineW := 0;
        LLineH := 0;
        LLineAsc := 0;
      end;
      LFragment := Default(TS4YLayoutFragment);
      LFragment.ParagraphIndex := AParagraphIndex;
      LFragment.RunIndex := LRunIndex;
      LFragment.CharStart := 0;
      LFragment.CharEnd := 1;
      LFragment.X := LIndentX + LLineW;
      LFragment.Y := AY;
      LFragment.Width := LImageWidth;
      LFragment.Height := LImageHeight;
      LFragment.Ascent := LImageHeight;
      LFragment.IsImage := True;
      SetLength(LLineFrags, Length(LLineFrags) + 1);
      LLineFrags[High(LLineFrags)] := LFragment;
      LLineW := LLineW + LImageWidth;
      LLineH := Max(LLineH, LImageHeight);
      LLineAsc := Max(LLineAsc, LImageHeight);
      Inc(LRunIndex);
    end
    else
    begin
      LRest := LRun.Text;
      LCharOfs := 0;

      while LRest <> '' do
      begin
        if AParagraph.BlockType = btPre then
          LSeparatorIndex := LRest.Length
        else
        begin
          LSeparatorIndex := FindWordEnd(LRest, 0);
          if LSeparatorIndex = 0 then
            LSeparatorIndex := LRest.Length;
        end;
        LWord := LRest.Substring(0, LSeparatorIndex);
        LRest := LRest.Substring(LSeparatorIndex);
        LWSize := MeasureStr(LWord, LTextStyle);

        if (LLineW > 0) and (LLineW + LWSize.Width > LEffectiveAvailableWidth + 0.5) then
        begin
          FlushLine(LLineFrags, LLineW, LLineH, LLineAsc, LIsFirstLine, False);
          LIsFirstLine := False;
          LLineW := 0;
          LLineH := 0;
          LLineAsc := 0;
        end;

        LFragment.ParagraphIndex := AParagraphIndex;
        LFragment.RunIndex := LRunIndex;
        LFragment.CharStart := LCharOfs;
        LFragment.CharEnd := LCharOfs + LWord.Length;
        LFragment.X := LIndentX + LLineW;
        LFragment.Y := AY;
        LFragment.Width := LWSize.Width;
        LFragment.Height := LWSize.Height;
        LFragment.Ascent := LWSize.Height * 0.78;
        LFragment.LineIndex := -1;
        LFragment.IsSpace := LWord.Trim = '';
        LFragment.IsHR := False;
        LFragment.IsImage := False;
        LFragment.IsPlaceholder := False;

        SetLength(LLineFrags, Length(LLineFrags) + 1);
        LLineFrags[High(LLineFrags)] := LFragment;

        LLineW := LLineW + LWSize.Width;
        LLineH := Max(LLineH, LWSize.Height);
        LLineAsc := Max(LLineAsc, LFragment.Ascent);
        LCharOfs := LCharOfs + LWord.Length;
      end;

      Inc(LRunIndex);
    end;
  end;

  if Length(LLineFrags) > 0 then
    FlushLine(LLineFrags, LLineW, Max(LLineH, 12), Max(LLineAsc, 9), LIsFirstLine, True)
  else if (Length(ALines) = 0) or ((AParagraph.Runs.Count > 0) and not LIsFirstLine) then
  begin
    LLastRunIndex2 := AParagraph.Runs.Count - 1;
    LEmptyStyle2.Init;
    if AParagraph.Runs.Count > 0 then
      LEmptyStyle2 := AParagraph.Runs[LLastRunIndex2].Style;
    LEmptyHeight2 := MeasureStr(' ', LEmptyStyle2).Height;
    LEmptyFragment3 := Default(TS4YLayoutFragment);
    LEmptyFragment3.ParagraphIndex := AParagraphIndex;
    LEmptyFragment3.RunIndex := LLastRunIndex2;
    LEmptyFragment3.CharStart := 0;
    LEmptyFragment3.CharEnd := 0;
    LEmptyFragment3.X := LIndentX;
    LEmptyFragment3.Y := AY;
    LEmptyFragment3.Width := 0;
    LEmptyFragment3.Height := LEmptyHeight2;
    LEmptyFragment3.Ascent := LEmptyHeight2 * 0.75;
    SetLength(LLineFrags, 1);
    LLineFrags[0] := LEmptyFragment3;
    FlushLine(LLineFrags, 0, LEmptyHeight2, LEmptyHeight2 * 0.75, LIsFirstLine, True);
  end;
end;

procedure TS4YLayoutEngine.LayoutTable(ADocument: TS4YHTMLDocument; AFirstParagraphIndex: Integer;
  AAvailableWidth: Single; var ALines: TArray<TS4YLayoutLine>; var AFragments: TArray<TS4YLayoutFragment>;
  var AY: Single; out ANextParagraphIndex: Integer; var ACells: TArray<TS4YLayoutCell>);
var
  LTableID: Integer;
  LCols: Integer;
  LLastPI: Integer;
  LMaximumRow: Integer;
  LParagraphIndex: Integer;
  LParagraph: TS4YHTMLParagraph;
  LCellW: Single;  // width of a column when all the columns are equal
  LIsUniform: Boolean;
  LTableWidth: Single;
  LTableLeft: Single;
  LAutoWidth: Single;
  LAutoCount: Integer;
  LFixedSum: Single;
  LTotalWidth: Single;
  LFirstParagraph: TS4YHTMLParagraph;
  LColumnWidths: TArray<Single>;
  LColumnIsSet: TArray<Boolean>;
  LColumnX: TArray<Single>;
  LCellPad: Single;
  LRow: Integer;
  LCellIndex: Integer;
  LCellCount: Integer;
  LColSpan: Integer;
  LRowSpan: Integer;
  LCellHeight: Single;
  LSpanHeight: Single;
  LRowTop: Single;
  LRowHeights: TArray<Single>;
  LCellParagraphs: TArray<Integer>;      // first paragraph of each cell
  LCellLastParagraphs: TArray<Integer>;  // last paragraph of each cell
  LCellLocalLines: array of TArray<TS4YLayoutLine>;
  LCellLocalFrags: array of TArray<TS4YLayoutFragment>;
  LCellLocalCells: array of TArray<TS4YLayoutCell>;  // rectangles of the cells of the tables nested in each cell
  LCellHeights: array of Single;
  LLocalCells: TArray<TS4YLayoutCell>;
  LLayoutCell: TS4YLayoutCell;
  LNextIndex: Integer;
  LIsSkipped: Boolean;
  LLocalLines: TArray<TS4YLayoutLine>;
  LLocalFrags: TArray<TS4YLayoutFragment>;
  LLocalY: Single;
  LGlobalFragmentOffset: Integer;
  LGlobalLineOffset: Integer;
  LXOffset: Single;
  LYOffset: Single;
  LLine: TS4YLayoutLine;
  LFragment: TS4YLayoutFragment;
  LIndex: integer;

  // Number of columns of the cell, limited to the columns of the table
  function ColumnSpanOf(ACell: TS4YHTMLParagraph): Integer;
  begin
    Result := ACell.TableColSpan;
    if Result < 1 then
      Result := 1;
    if ACell.TableCol + Result > LCols then
      Result := LCols - ACell.TableCol;
  end;

  // Left edge of a column, relative to the space of the table
  function ColumnLeft(AColumn: Integer): Single;
  begin
    if LIsUniform then
      Result := LTableLeft + AColumn * LCellW
    else
      Result := LColumnX[AColumn];
  end;

  // Width of a cell that starts in a column and covers ASpan columns
  function ColumnSpanWidth(AColumn, ASpan: Integer): Single;
  begin
    if LIsUniform then
      Result := LCellW * ASpan
    else
      Result := LColumnX[AColumn + ASpan] - LColumnX[AColumn];
  end;

  // Number of rows of the cell, limited to the rows of the table
  function RowSpanOf(ACell: TS4YHTMLParagraph): Integer;
  begin
    Result := ACell.TableRowSpan;
    if Result < 1 then
      Result := 1;
    if ACell.TableRow + Result - 1 > LMaximumRow then
      Result := LMaximumRow - ACell.TableRow + 1;
  end;

begin
  LTableID := ADocument.Paragraphs[AFirstParagraphIndex].TableID;
  LCols := ADocument.Paragraphs[AFirstParagraphIndex].TableCols;
  if LCols < 1 then
    LCols := 1;
  LCellPad := C_DEFAULT_TABLE_CELL_PADDING;

  // Find last para index of this table and max row
  LLastPI := AFirstParagraphIndex;
  LMaximumRow := 0;
  LParagraphIndex := AFirstParagraphIndex;
  while LParagraphIndex < ADocument.Paragraphs.Count do
  begin
    LParagraph := ADocument.Paragraphs[LParagraphIndex];
    if not LParagraph.BelongsToTable(LTableID) then
      LParagraphIndex := ADocument.Paragraphs.Count // exit condition
    else
    begin
      LLastPI := LParagraphIndex;
      // The paragraphs of tables nested in the cells belong to the extent of the table but not to its grid
      if (LParagraph.TableID = LTableID) and (LParagraph.TableRow > LMaximumRow) then
        LMaximumRow := LParagraph.TableRow;
      Inc(LParagraphIndex);
    end;
  end;

  ANextParagraphIndex := LLastPI + 1;

  // The cells that sit inside the grid, in document order (row by row). A cell is a run of paragraphs
  // that have the same position: the first one holds the attributes of the cell.
  // The paragraphs of a table nested in a cell are part of the range of that cell.
  LCellCount := 0;
  LIsSkipped := False;
  SetLength(LCellParagraphs, LLastPI - AFirstParagraphIndex + 1);
  SetLength(LCellLastParagraphs, LLastPI - AFirstParagraphIndex + 1);
  for LParagraphIndex := AFirstParagraphIndex to LLastPI do
  begin
    LParagraph := ADocument.Paragraphs[LParagraphIndex];
    if LParagraph.TableID = LTableID then
    begin
      LIsSkipped := LParagraph.TableCol >= LCols;
      if not LIsSkipped then
      begin
        if (LCellCount > 0) and (LParagraphIndex = LCellLastParagraphs[LCellCount - 1] + 1) and
           (LParagraph.TableRow = ADocument.Paragraphs[LCellParagraphs[LCellCount - 1]].TableRow) and
           (LParagraph.TableCol = ADocument.Paragraphs[LCellParagraphs[LCellCount - 1]].TableCol) then
          LCellLastParagraphs[LCellCount - 1] := LParagraphIndex
        else
        begin
          LCellParagraphs[LCellCount] := LParagraphIndex;
          LCellLastParagraphs[LCellCount] := LParagraphIndex;
          Inc(LCellCount);
        end;
      end;
    end
    else if not LIsSkipped and (LCellCount > 0) then
      LCellLastParagraphs[LCellCount - 1] := LParagraphIndex;
  end;
  SetLength(LCellParagraphs, LCellCount);
  SetLength(LCellLastParagraphs, LCellCount);
  SetLength(LCellLocalLines, LCellCount);
  SetLength(LCellLocalFrags, LCellCount);
  SetLength(LCellLocalCells, LCellCount);
  SetLength(LCellHeights, LCellCount);

  // Width of the table and of its columns
  LFirstParagraph := ADocument.Paragraphs[AFirstParagraphIndex];
  LTableWidth := AAvailableWidth;
  case LFirstParagraph.TableWidth.Kind of
    tlkPixels:
      LTableWidth := Min(AAvailableWidth, LFirstParagraph.TableWidth.Value);
    tlkPercent:
      LTableWidth := AAvailableWidth * Min(LFirstParagraph.TableWidth.Value, 100) / 100;
  end;
  if (LFirstParagraph.TableMaximumWidth > 0) and (LTableWidth > LFirstParagraph.TableMaximumWidth) then
    LTableWidth := LFirstParagraph.TableMaximumWidth;
  // A column takes the width of the first cell that asks for one, ignoring the cells that span columns
  SetLength(LColumnWidths, LCols);
  SetLength(LColumnIsSet, LCols);
  for LCellIndex := 0 to LCellCount - 1 do
  begin
    LParagraph := ADocument.Paragraphs[LCellParagraphs[LCellIndex]];
    if (ColumnSpanOf(LParagraph) = 1) and not LParagraph.TableCellWidth.IsAuto and not LColumnIsSet[LParagraph.TableCol] then
    begin
      LColumnIsSet[LParagraph.TableCol] := True;
      if LParagraph.TableCellWidth.Kind = tlkPixels then
        LColumnWidths[LParagraph.TableCol] := LParagraph.TableCellWidth.Value
      else
        LColumnWidths[LParagraph.TableCol] := LTableWidth * Min(LParagraph.TableCellWidth.Value, 100) / 100;
    end;
  end;
  LAutoCount := 0;
  LFixedSum := 0;
  for LIndex := 0 to LCols - 1 do
    if LColumnIsSet[LIndex] then
      LFixedSum := LFixedSum + LColumnWidths[LIndex]
    else
      Inc(LAutoCount);
  LIsUniform := LAutoCount = LCols;
  if LIsUniform then
  begin
    // No column has a width: all of them share the table
    LCellW := LTableWidth / LCols;
    LTableLeft := 0;
    case LFirstParagraph.TableAlignment of
      haCenter:
        LTableLeft := (AAvailableWidth - LTableWidth) / 2;
      haRight:
        LTableLeft := AAvailableWidth - LTableWidth;
    end;
  end
  else
  begin
    // The columns without width share what the others leave, and the columns are scaled to the table
    if LAutoCount > 0 then
    begin
      LAutoWidth := (LTableWidth - LFixedSum) / LAutoCount;
      if LAutoWidth < C_MINIMUM_TABLE_COLUMN_WIDTH then
        LAutoWidth := C_MINIMUM_TABLE_COLUMN_WIDTH;
      for LIndex := 0 to LCols - 1 do
        if not LColumnIsSet[LIndex] then
          LColumnWidths[LIndex] := LAutoWidth;
    end;
    LTotalWidth := 0;
    for LIndex := 0 to LCols - 1 do
      LTotalWidth := LTotalWidth + LColumnWidths[LIndex];
    // When every column has a width and the table has none, the table is as wide as its columns
    if (LAutoCount = 0) and LFirstParagraph.TableWidth.IsAuto and (LFirstParagraph.TableMaximumWidth <= 0) then
      LTableWidth := Min(LTotalWidth, AAvailableWidth);
    if (LTotalWidth > 0) and (Abs(LTotalWidth - LTableWidth) > 0.01) then
      for LIndex := 0 to LCols - 1 do
        LColumnWidths[LIndex] := LColumnWidths[LIndex] * LTableWidth / LTotalWidth;
    LTableLeft := 0;
    case LFirstParagraph.TableAlignment of
      haCenter:
        LTableLeft := (AAvailableWidth - LTableWidth) / 2;
      haRight:
        LTableLeft := AAvailableWidth - LTableWidth;
    end;
    SetLength(LColumnX, LCols + 1);
    LColumnX[0] := LTableLeft;
    for LIndex := 0 to LCols - 1 do
      LColumnX[LIndex + 1] := LColumnX[LIndex] + LColumnWidths[LIndex];
  end;

  // Layout each cell at the width of the columns it covers
  for LCellIndex := 0 to LCellCount - 1 do
  begin
    LParagraph := ADocument.Paragraphs[LCellParagraphs[LCellIndex]];
    LLocalLines := nil;
    LLocalFrags := nil;
    LLocalCells := nil;
    LLocalY := 0;
    LParagraphIndex := LCellParagraphs[LCellIndex];
    while LParagraphIndex <= LCellLastParagraphs[LCellIndex] do
    begin
      if ADocument.Paragraphs[LParagraphIndex].TableID = LTableID then
      begin
        LayoutParagraph(ADocument.Paragraphs[LParagraphIndex], LParagraphIndex,
          ColumnSpanWidth(LParagraph.TableCol, ColumnSpanOf(LParagraph)) - 2 * LCellPad, LLocalY, LLocalLines, LLocalFrags,
          LLocalY);
        Inc(LParagraphIndex);
      end
      else
      begin
        // A table nested in the cell
        LayoutTable(ADocument, LParagraphIndex, ColumnSpanWidth(LParagraph.TableCol, ColumnSpanOf(LParagraph)) - 2 * LCellPad,
          LLocalLines, LLocalFrags, LLocalY, LNextIndex, LLocalCells);
        LParagraphIndex := LNextIndex;
      end;
    end;
    LCellLocalLines[LCellIndex] := LLocalLines;
    LCellLocalFrags[LCellIndex] := LLocalFrags;
    LCellLocalCells[LCellIndex] := LLocalCells;
    LCellHeights[LCellIndex] := LLocalY;
  end;

  // Row height = max content height of the cells that end in the row + 2*padding, minimum C_DEFAULT_TABLE_MIN_ROW_HEIGHT
  SetLength(LRowHeights, LMaximumRow + 1);
  for LRow := 0 to LMaximumRow do
    LRowHeights[LRow] := C_DEFAULT_TABLE_MIN_ROW_HEIGHT;
  for LCellIndex := 0 to LCellCount - 1 do
  begin
    LParagraph := ADocument.Paragraphs[LCellParagraphs[LCellIndex]];
    if (RowSpanOf(LParagraph) = 1) and (LCellHeights[LCellIndex] + 2 * LCellPad > LRowHeights[LParagraph.TableRow]) then
      LRowHeights[LParagraph.TableRow] := LCellHeights[LCellIndex] + 2 * LCellPad;
  end;
  // A cell that spans rows grows the last row it covers when its content does not fit
  for LCellIndex := 0 to LCellCount - 1 do
  begin
    LParagraph := ADocument.Paragraphs[LCellParagraphs[LCellIndex]];
    LRowSpan := RowSpanOf(LParagraph);
    if LRowSpan > 1 then
    begin
      LSpanHeight := 0;
      for LRow := LParagraph.TableRow to LParagraph.TableRow + LRowSpan - 1 do
        LSpanHeight := LSpanHeight + LRowHeights[LRow];
      LCellHeight := LCellHeights[LCellIndex] + 2 * LCellPad;
      if LCellHeight > LSpanHeight then
        LRowHeights[LParagraph.TableRow + LRowSpan - 1] :=
          LRowHeights[LParagraph.TableRow + LRowSpan - 1] + LCellHeight - LSpanHeight;
    end;
  end;

  // Merge each cell's layout into global arrays
  for LCellIndex := 0 to LCellCount - 1 do
  begin
    LParagraph := ADocument.Paragraphs[LCellParagraphs[LCellIndex]];
    LColSpan := ColumnSpanOf(LParagraph);
    LRowSpan := RowSpanOf(LParagraph);
    LRowTop := AY;
    for LRow := 0 to LParagraph.TableRow - 1 do
      LRowTop := LRowTop + LRowHeights[LRow];
    LSpanHeight := 0;
    for LRow := LParagraph.TableRow to LParagraph.TableRow + LRowSpan - 1 do
      LSpanHeight := LSpanHeight + LRowHeights[LRow];

    LXOffset := ColumnLeft(LParagraph.TableCol) + LCellPad;
    LYOffset := LRowTop + LCellPad;
    LGlobalFragmentOffset := Length(AFragments);
    LGlobalLineOffset := Length(ALines);

    // Append frags with adjusted X/Y and fixed LineIndex
    SetLength(AFragments, Length(AFragments) + Length(LCellLocalFrags[LCellIndex]));
    for LIndex := 0 to High(LCellLocalFrags[LCellIndex]) do
    begin
      LFragment := LCellLocalFrags[LCellIndex][LIndex];
      LFragment.X := LFragment.X + LXOffset;
      LFragment.Y := LFragment.Y + LYOffset;
      LFragment.LineIndex := LFragment.LineIndex + LGlobalLineOffset;
      AFragments[LGlobalFragmentOffset + LIndex] := LFragment;
    end;

    // Append lines with adjusted Y, fixed FragmentStart, and cell geometry
    SetLength(ALines, Length(ALines) + Length(LCellLocalLines[LCellIndex]));
    for LIndex := 0 to High(LCellLocalLines[LCellIndex]) do
    begin
      LLine := LCellLocalLines[LCellIndex][LIndex];
      LLine.Y := LLine.Y + LYOffset;
      LLine.FragmentStart := LLine.FragmentStart + LGlobalFragmentOffset;
      ALines[LGlobalLineOffset + LIndex] := LLine;
    end;

    // The rectangles of the cells of the tables nested in this cell, then the rectangle of the cell itself
    for LIndex := 0 to High(LCellLocalCells[LCellIndex]) do
    begin
      LLayoutCell := LCellLocalCells[LCellIndex][LIndex];
      LLayoutCell.X := LLayoutCell.X + LXOffset;
      LLayoutCell.Y := LLayoutCell.Y + LYOffset;
      SetLength(ACells, Length(ACells) + 1);
      ACells[High(ACells)] := LLayoutCell;
    end;
    LLayoutCell.TableID := LTableID;
    LLayoutCell.Row := LParagraph.TableRow;
    LLayoutCell.Column := LParagraph.TableCol;
    LLayoutCell.FirstParagraphIndex := LCellParagraphs[LCellIndex];
    LLayoutCell.Depth := Length(LParagraph.TableContainers);
    LLayoutCell.X := ColumnLeft(LParagraph.TableCol);
    LLayoutCell.HasBorder := LFirstParagraph.TableHasBorder;
    LLayoutCell.Y := LRowTop;
    LLayoutCell.Width := ColumnSpanWidth(LParagraph.TableCol, LColSpan);
    LLayoutCell.ColumnSpan := LColSpan;
    LLayoutCell.TableAvailableWidth := AAvailableWidth;
    LLayoutCell.Height := LSpanHeight;
    SetLength(ACells, Length(ACells) + 1);
    ACells[High(ACells)] := LLayoutCell;
  end;

  for LRow := 0 to LMaximumRow do
    AY := AY + LRowHeights[LRow];

  // Add inter-table spacing
  AY := AY + FParagraphSpacing;
end;

procedure TS4YLayoutEngine.DoLayout(ADocument: TS4YHTMLDocument; AAvailableWidth: Single; out ALines: TArray<TS4YLayoutLine>;
  out AFragments: TArray<TS4YLayoutFragment>; out ACells: TArray<TS4YLayoutCell>; out ATotalHeight: Single);
var
  LYPosition: Single;
  LParagraph: TS4YHTMLParagraph;
  LParagraphIndex: Integer;
  LNextIndex: Integer;
begin
  ALines := nil;
  AFragments := nil;
  ACells := nil;
  LYPosition := 0;

  LParagraphIndex := 0;
  while LParagraphIndex < ADocument.Paragraphs.Count do
  begin
    LParagraph := ADocument.Paragraphs[LParagraphIndex];
    if LParagraph.IsTableCell then
    begin
      LayoutTable(ADocument, LParagraphIndex, AAvailableWidth, ALines, AFragments, LYPosition, LNextIndex, ACells);
      LParagraphIndex := LNextIndex;
    end
    else
    begin
      LayoutParagraph(LParagraph, LParagraphIndex, AAvailableWidth, LYPosition, ALines, AFragments, LYPosition);
      Inc(LParagraphIndex);
    end;
  end;

  ATotalHeight := LYPosition + FParagraphSpacing;
end;

// -----------------------------------------------------------------------------
// TS4YHTMLEditor
// -----------------------------------------------------------------------------

constructor TS4YHTMLEditor.Create(AOwner: TComponent);
var
  LParagraph: TS4YHTMLParagraph;
begin
  inherited;
  StyleLookup := ''; // no style - we paint entirely ourselves
  DisableFocusEffect := True; // prevent FMX from drawing its own focus rect
  CanFocus := True; // enable keyboard focus
  Cursor := crIBeam; // text-cursor pointer when hovering
  FDocument := TS4YHTMLDocument.Create;
  FLayoutEngine := TS4YLayoutEngine.Create;
  FLineSpacing := C_EDITOR_LINE_SPACING;
  FParagraphSpacing := C_EDITOR_PARA_SPACING;
  FImageCache := TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
  FRefusedImages := TDictionary<string, Boolean>.Create;
  FPlaceholderAppearance := TS4YPlaceholderAppearance.Create;
  FPlaceholderAppearance.OnChange := AppearanceChanged;
  FPlaceholderPrefix := S_DEFAULT_PLACEHOLDER_PREFIX;
  FPlaceholderSuffix := S_DEFAULT_PLACEHOLDER_SUFFIX;
  FUndoStack := TObjectList<TS4YUndoEntry>.Create(True);
  FRedoStack := TObjectList<TS4YUndoEntry>.Create(True);
  FPlaceholders := TList<TS4YHTMLRun>.Create;
  FAutoLoadLocalImages := True;
  FLocalImageAccess := liaAnywhere;
  FAutoLoadRemoteImages := True;
  FBackgroundColor := claWhite;
  FFontColor := claBlack;
  FShowBorder := True;
  FCaretPosition := TS4YDocumentPosition.Invalid;
  FSelectionStart := TS4YDocumentPosition.Invalid;
  FSelectionEnd := TS4YDocumentPosition.Invalid;
  FInsertStyle.Init;

  // Default font - exposed as a published property so the developer can
  // configure it from the Object Inspector.  Family='' means "FMX platform
  // default" (Segoe UI on Windows, Helvetica Neue on macOS, Roboto on Android).
  // OnChanged is attached *after* the initial values are set so the callback
  // is not fired spuriously during construction.
  FFont := TFont.Create;
  FFont.Family := S_EDITOR_FONT_NAME;
  FFont.Size := C_EDITOR_FONT_SIZE;
  FFont.OnChanged := FontChanged;

  // Vertical scrollbar - created only at runtime so it never shows up in the
  // Form Designer as an accessible child component (same behaviour as TMemo).
  if not(csDesigning in ComponentState) then
  begin
    FScrollBar := TScrollBar.Create(Self);
    FScrollBar.Stored := False; // never written to DFM
    FScrollBar.Orientation := TOrientation.Vertical;
    FScrollBar.Align := TAlignLayout.Right;
    FScrollBar.Width := 16;
    FScrollBar.Visible := False;
    FScrollBar.CanFocus := False; // never steals keyboard focus from editor
    FScrollBar.Cursor := crArrow; // prevent inheriting crIBeam from parent
    // Inset 1 px on all sides so it doesn't overlap the border stroke
    FScrollBar.Margins.Top := 1;
    FScrollBar.Margins.Bottom := 1;
    FScrollBar.Margins.Right := 1;
    FScrollBar.Parent := Self;
    FScrollBar.OnChange := OnScrollChange;

    BuildContextMenu;
  end;

  // Caret blink timer
  FCaretTimer := TTimer.Create(Self);
  FCaretTimer.Interval := C_EDITOR_CARET_BLINK;
  FCaretTimer.OnTimer := OnCaretTick;
  FCaretTimer.Enabled := False;
  FRenderCache := TBitmap.Create(0, 0);
  FRenderDirty := True;
  FLastPaintOpacity := 1.0;

  // Default content
  LParagraph := TS4YHTMLParagraph.Create;
  LParagraph.BlockType := btBodyText;
  FDocument.Paragraphs.Add(LParagraph);
  FCaretPosition := TS4YDocumentPosition.At(0, 0, 0);

  Width := 400;
  Height := 300;
end;

destructor TS4YHTMLEditor.Destroy;
begin
  FCaretTimer.Free;
  FRenderCache.Free;
  FLayoutEngine.Free;
  FRefusedImages.Free;
  FImageCache.Free;
  FUndoStack.Free;
  FRedoStack.Free;
  FPlaceholders.Free;
  FDocument.Free;
  FFont.Free;
  FPlaceholderAppearance.Free;
  inherited; // TStyledControl frees all child controls
end;

procedure TS4YHTMLEditor.DoEnter;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  // Always re-layout on focus: guarantees FFrags is current before
  // UpdateCaretXY runs, regardless of how focus arrived (click or Tab).
  DoLayout;
  FCaretOn := True;
  FCaretTimer.Enabled := True;
  Repaint;
end;

procedure TS4YHTMLEditor.DoExit;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  FCaretTimer.Enabled := False;
  FCaretOn := False;
  Repaint;
end;

procedure TS4YHTMLEditor.Resize;
begin
  inherited;
  DoLayout;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.InvalidateRender;
begin
  FRenderDirty := True;
  Repaint;
end;

procedure TS4YHTMLEditor.OnCaretTick(Sender: TObject);
begin
  FCaretOn := not FCaretOn;
  Repaint;
end;

// -- Layout -------------------------------------------------------------------

function TS4YHTMLEditor.AvailableWidth: Single;
var
  LScrollBarWidth: Single;
begin
  LScrollBarWidth := 0;
  if FScrollBarVisible and (FScrollBar <> nil) then
    LScrollBarWidth := FScrollBar.Width;
  Result := Width - LScrollBarWidth - C_EDITOR_PADDING * 2;
  if Result < 20 then
    Result := 20;
end;

function TS4YHTMLEditor.ContentLeft: Single;
begin
  Result := C_EDITOR_PADDING;
end;

function TS4YHTMLEditor.ContentTop: Single;
begin
  Result := C_EDITOR_PADDING - FScrollY;
end;

procedure TS4YHTMLEditor.DoLayout;
var
  LWasVisible: Boolean;
begin
  if FLayouting then
    Exit;
  if FDocument = nil then
    Exit;
  FLayouting := True;
  try
    // Propagate metrics to the layout engine before each pass
    FLayoutEngine.LineSpacing := FLineSpacing;
    FLayoutEngine.ParagraphSpacing := FParagraphSpacing;
    FLayoutEngine.PlaceholderPaddingH := FPlaceholderAppearance.HorizontalPadding;
    FLayoutEngine.PlaceholderPaddingV := FPlaceholderAppearance.VerticalPadding;
    FLayoutEngine.PlaceholderBold := FPlaceholderAppearance.Bold;
    FLayoutEngine.PlaceholderGetLabel := FOnGetPlaceholderLabel;
    FLayoutEngine.PlaceholderSender := Self;
    // Resolve natural image dimensions before the first layout pass
    PrepareImageDimensions;
    // First pass: layout with current scrollbar visibility to measure content
    LWasVisible := FScrollBarVisible;
    FLayoutEngine.DoLayout(FDocument, AvailableWidth, FLines, FFrags, FCells, FTotalHeight);
    UpdateScrollBar;
    // If scrollbar visibility changed, the available width changed too -
    // redo layout so text wraps correctly for the new width.
    if FScrollBarVisible <> LWasVisible then
    begin
      FLayoutEngine.DoLayout(FDocument, AvailableWidth, FLines, FFrags, FCells, FTotalHeight);
      UpdateScrollBar;
    end;
    UpdateCaretXY;
    EnsureCaretVisible; // scroll to show caret after every layout (typing, delete, paste...)
  finally
    FLayouting := False;
  end;
end;

procedure TS4YHTMLEditor.UpdateScrollBar;
var
  LViewH, LContentH: Single;
begin
  LViewH := Height - C_EDITOR_PADDING * 2;
  // Exclude the trailing paragraph spacing so the scrollbar does not appear
  // just because of the 6px empty margin after the last line.
  LContentH := FTotalHeight - FLayoutEngine.ParagraphSpacing;
  if LContentH > LViewH then
  begin
    FScrollBarMaximum := LContentH - LViewH;
    FScrollY := Max(0, Min(FScrollY, FScrollBarMaximum));
    FScrollBarVisible := True;
  end
  else
  begin
    FScrollBarVisible := False;
    FScrollBarMaximum := 0;
    FScrollY := 0;
  end;

  if FScrollBar = nil then
    Exit;

  FSyncing := True;
  try
    FScrollBar.Visible := FScrollBarVisible;
    if FScrollBarVisible then
    begin
      FScrollBar.Min := 0;
      FScrollBar.Max := FScrollBarMaximum;
      FScrollBar.SmallChange := C_EDITOR_SCROLL_STEP;
      FScrollBar.Value := FScrollY;
    end;
  finally
    FSyncing := False;
  end;
end;

// -- Painting -----------------------------------------------------------------

procedure TS4YHTMLEditor.Paint;
var
  LScrollBarWidth: Single;
  LState: TCanvasSaveState;
  LCaretState: TCanvasSaveState;
  LListParagraph: TS4YHTMLParagraph;
  LMarkerX: Single;
  LMarkerY: Single;
  LTextStyle: TS4YHTMLTextStyle;
  LLayout: TTextLayout;
  LPhysW: Integer;
  LPhysH: Integer;

  procedure RenderTo(ACanvas: TCanvas);
  var
    LMarkerRectangle: TRectF;
    LMarkerHandled: Boolean;
    LMarkerChar: string;
    LCharLayout: TTextLayout;
    LCullTop: Single;
    LCullBottom: Single;
    LFragmentIndex: Integer;
    LFirstFragmentOfParagraph: TArray<Integer>;
  begin
    LState := ACanvas.SaveState;
    try
      ACanvas.IntersectClipRect(TRectF.Create(1, 1, Width - LScrollBarWidth - 1, Height - 1));
      PaintBackground(ACanvas);
      PaintTableCellBorders(ACanvas);
      // Painting is limited to the fragments near the visible area: the cost of a frame
      // follows the window, not the length of the document. PERFORMANCE-CRITICAL: do not
      // go back to painting every fragment (each one builds a text layout).
      GetRenderCullLimits(LCullTop, LCullBottom);
      for var I := 0 to High(FFrags) do
      begin
        if (FFrags[I].Y + FFrags[I].Height >= LCullTop) and (FFrags[I].Y <= LCullBottom) then
        begin
          if FFrags[I].IsHR then
            PaintHorizontalRule(ACanvas, FFrags[I].Y + ContentTop, FFrags[I].Width, FFrags[I].X + ContentLeft,
              FDocument.Paragraphs[FFrags[I].ParagraphIndex])
          else if FFrags[I].IsImage then
          begin
            if FFrags[I].RunIndex < 0 then
              PaintImage(ACanvas, FFrags[I], FDocument.Paragraphs[FFrags[I].ParagraphIndex])
            else
              PaintImageRun(ACanvas, FFrags[I], FDocument.Paragraphs[FFrags[I].ParagraphIndex].Runs[FFrags[I].RunIndex]);
          end
          else
            PaintFragment(ACanvas, FFrags[I]);
        end;
      end;
      PaintSelection(ACanvas);
      // First fragment of every paragraph, found in a single pass (list markers hang from it)
      SetLength(LFirstFragmentOfParagraph, FDocument.Paragraphs.Count);
      for var I := 0 to High(LFirstFragmentOfParagraph) do
        LFirstFragmentOfParagraph[I] := -1;
      for var I := High(FFrags) downto 0 do
        if (FFrags[I].ParagraphIndex >= 0) and (FFrags[I].ParagraphIndex < Length(LFirstFragmentOfParagraph)) then
          LFirstFragmentOfParagraph[FFrags[I].ParagraphIndex] := I;
      for var I := 0 to FDocument.Paragraphs.Count - 1 do
      begin
        LListParagraph := FDocument.Paragraphs[I];
        if LListParagraph.BlockType = btLI then
        begin
          LFragmentIndex := LFirstFragmentOfParagraph[I];
          if (LFragmentIndex >= 0) and
             (FFrags[LFragmentIndex].Y + FFrags[LFragmentIndex].Height >= LCullTop) and
             (FFrags[LFragmentIndex].Y <= LCullBottom) then
          begin
            LMarkerX := FFrags[LFragmentIndex].X + ContentLeft - C_EDITOR_LIST_INDENT;
            LMarkerY := FFrags[LFragmentIndex].Y + ContentTop;
            LTextStyle.Init;
            if LListParagraph.Runs.Count > 0 then
              LTextStyle := LListParagraph.Runs[0].Style;
            ACanvas.Fill.Kind := TBrushKind.Solid;
            ACanvas.Fill.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
            if LListParagraph.ListOrdered then
            begin
              LLayout := TTextLayoutManager.DefaultTextLayout.Create(ACanvas);
              try
                LLayout.BeginUpdate;
                LLayout.Font.Family := LTextStyle.FontName;
                LLayout.Font.Size := LTextStyle.FontSize;
                LLayout.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
                LLayout.WordWrap := False;
                LLayout.MaxSize := TPointF.Create(C_EDITOR_LIST_INDENT - 2, FFrags[LFragmentIndex].Height + 4);
                LLayout.Text := IntToStr(LListParagraph.ListIndex) + '.';
                LLayout.TopLeft := TPointF.Create(LMarkerX, LMarkerY);
                LLayout.EndUpdate;
                LLayout.RenderLayout(ACanvas);
              finally
                LLayout.Free;
              end;
            end
            else
            begin
              LMarkerRectangle := TRectF.Create(LMarkerX + 2, LMarkerY + FFrags[LFragmentIndex].Height * 0.35,
                LMarkerX + 8, LMarkerY + FFrags[LFragmentIndex].Height * 0.65);
              LMarkerHandled := False;
              LMarkerChar := '';
              if Assigned(FOnGetListMarker) then
                FOnGetListMarker(Self, LListParagraph.IndentLevel, LMarkerChar, LMarkerHandled);
              if LMarkerHandled then
              begin
                LCharLayout := TTextLayoutManager.DefaultTextLayout.Create(ACanvas);
                try
                  LCharLayout.BeginUpdate;
                  LCharLayout.Font.Family := LTextStyle.FontName;
                  LCharLayout.Font.Size := LTextStyle.FontSize;
                  LCharLayout.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
                  LCharLayout.WordWrap := False;
                  LCharLayout.HorizontalAlign := TTextAlign.Center;
                  LCharLayout.MaxSize := TPointF.Create(C_EDITOR_LIST_INDENT - 2, FFrags[LFragmentIndex].Height + 4);
                  LCharLayout.Text := LMarkerChar;
                  LCharLayout.TopLeft := TPointF.Create(LMarkerX, LMarkerY);
                  LCharLayout.EndUpdate;
                  LCharLayout.RenderLayout(ACanvas);
                finally
                  LCharLayout.Free;
                end;
              end
              else
              begin
                if Assigned(FOnDrawListMarker) then
                  FOnDrawListMarker(Self, ACanvas, LMarkerRectangle, LListParagraph.IndentLevel, LMarkerHandled);
                if not LMarkerHandled then
                  case LListParagraph.IndentLevel mod 3 of
                    0: ACanvas.FillEllipse(LMarkerRectangle, AbsoluteOpacity);
                    1:
                    begin
                      ACanvas.Stroke.Kind := TBrushKind.Solid;
                      ACanvas.Stroke.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
                      ACanvas.Stroke.Thickness := 1.5;
                      ACanvas.DrawEllipse(LMarkerRectangle, AbsoluteOpacity);
                    end;
                  else
                    ACanvas.FillRect(LMarkerRectangle, AbsoluteOpacity);
                  end;
              end;
            end;
          end;
        end;
      end;
    finally
      ACanvas.RestoreState(LState);
    end;
    PaintBorder(ACanvas);
  end;

begin
  LScrollBarWidth := 0;
  if FScrollBarVisible and (FScrollBar <> nil) then
    LScrollBarWidth := FScrollBar.Width;

  LPhysW := Round(Width);
  LPhysH := Round(Height);

  if FRenderDirty or
    (FRenderCache.Width <> LPhysW) or
    (FRenderCache.Height <> LPhysH) or
    (Abs(AbsoluteOpacity - FLastPaintOpacity) > 0.001) then
  begin
    FRenderCache.SetSize(LPhysW, LPhysH);
    if FRenderCache.Canvas.BeginScene then
    try
      FRenderCache.Canvas.Clear(0);
      RenderTo(FRenderCache.Canvas);
    finally
      FRenderCache.Canvas.EndScene;
    end;
    FLastPaintOpacity := AbsoluteOpacity;
    FRenderDirty := False;
  end;

  Canvas.DrawBitmap(FRenderCache,
    TRectF.Create(0, 0, LPhysW, LPhysH),
    TRectF.Create(0, 0, Width, Height),
    1.0, False);

  // The caret is drawn over the cache, not into it: a blink only repaints, it does not render the document again
  LCaretState := Canvas.SaveState;
  try
    Canvas.IntersectClipRect(TRectF.Create(1, 1, Width - LScrollBarWidth - 1, Height - 1));
    PaintCaret(Canvas);
  finally
    Canvas.RestoreState(LCaretState);
  end;
end;

procedure TS4YHTMLEditor.PaintBackground(ACanvas: TCanvas);
begin
  ACanvas.Fill.Kind := TBrushKind.Solid;
  ACanvas.Fill.Color := FBackgroundColor;
  ACanvas.FillRect(TRectF.Create(0, 0, Width, Height), AbsoluteOpacity);
end;

procedure TS4YHTMLEditor.PaintTableCellBorders(ACanvas: TCanvas);
var
  LRectangle: TRectF;
begin
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.Stroke.Color := C_DEFAULT_TABLE_BORDER_COLOR;
  ACanvas.Stroke.Thickness := C_DEFAULT_TABLE_BORDER_WIDTH;
  ACanvas.Fill.Kind := TBrushKind.None;
  for var I := 0 to High(FCells) do
    if FCells[I].HasBorder then
    begin
      LRectangle := TRectF.Create(
        FCells[I].X + ContentLeft,
        FCells[I].Y + ContentTop,
        FCells[I].X + FCells[I].Width + ContentLeft,
        FCells[I].Y + FCells[I].Height + ContentTop);
      ACanvas.DrawRect(LRectangle, 0, 0, AllCorners, AbsoluteOpacity);
    end;
end;

procedure TS4YHTMLEditor.PaintHorizontalRule(ACanvas: TCanvas; AY, AWidth, AX: Single; AParagraph: TS4YHTMLParagraph);
var
  LColor: TAlphaColor;
  LThickness: Single;
begin
  if AParagraph.HRColor <> claNull then
    LColor := AParagraph.HRColor
  else
    LColor := C_DEFAULT_HR_TAG_STROKE_COLOR;
  if AParagraph.HRThickness > 0 then
    LThickness := AParagraph.HRThickness
  else
    LThickness := C_DEFAULT_HR_THICKNESS;
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.Stroke.Color := LColor;
  ACanvas.Stroke.Thickness := LThickness;
  ACanvas.DrawLine(TPointF.Create(AX, AY + 8), TPointF.Create(AX + AWidth, AY + 8), AbsoluteOpacity);
end;

function TS4YHTMLEditor.RenderSVGToBitmap(const ASVGDOM: ISkSVGDOM; AWidth, AHeight: Integer): TBitmap;
var
  LIntrinsicSize: TSizeF;
  LWidth: Integer;
  LHeight: Integer;
begin
  Result := nil;
  if not Assigned(ASVGDOM) then
    Exit;
  LWidth := AWidth;
  LHeight := AHeight;
  if (LWidth <= 0) or (LHeight <= 0) then
  begin
    if Assigned(ASVGDOM.Root) then
      LIntrinsicSize := ASVGDOM.Root.GetIntrinsicSize(TSizeF.Create(0, 0))
    else
      LIntrinsicSize := TSizeF.Create(0, 0);
    if LWidth <= 0 then
      LWidth := Round(LIntrinsicSize.Width);
    if LHeight <= 0 then
      LHeight := Round(LIntrinsicSize.Height);
    if LWidth <= 0 then
      LWidth := 300;
    if LHeight <= 0 then
      LHeight := 150;
  end;
  Result := TBitmap.Create(LWidth, LHeight);
  try
    Result.SkiaDraw(
      procedure(const ACanvas: ISkCanvas)
      begin
        ASVGDOM.SetContainerSize(TSizeF.Create(LWidth, LHeight));
        ASVGDOM.Render(ACanvas);
      end
    );
  except
    FreeAndNil(Result);
  end;
end;

function TS4YHTMLEditor.LoadBitmapFromSource(const ASource: string; AWidth, AHeight: Integer): TBitmap;
var
  LComma: Integer;
  LHeader: string;
  LBase64: string;
  LBytes: TBytes;
  LStream: TBytesStream;
  LSVGText: string;
  LSVGDOM: ISkSVGDOM;
  LFilePath: string;
begin
  if IsRemoteImageSource(ASource) then
  begin
    var LClient := THTTPClient.Create;
    var LDownloadStream := TMemoryStream.Create;
    try
      LClient.Get(ASource, LDownloadStream);
      LDownloadStream.Position := 0;
      Result := TBitmap.Create;
      try
        Result.LoadFromStream(LDownloadStream);
      except
        FreeAndNil(Result);
      end;
    except
      Result := nil;
    end;
    LClient.Free;
    LDownloadStream.Free;
    Exit;
  end;
  Result := TBitmap.Create;
  try
    if ASource.StartsWith('data:') then
    begin
      LComma := ASource.IndexOf(',');
      if LComma >= 0 then
      begin
        LHeader := ASource.Substring(0, LComma).ToLower;
        if LHeader.Contains('svg') then
        begin
          FreeAndNil(Result);
          if LHeader.Contains(';base64') then
          begin
            LBytes := TNetEncoding.Base64.DecodeStringToBytes(ASource.Substring(LComma + 1));
            LSVGText := TEncoding.UTF8.GetString(LBytes);
          end
          else
            LSVGText := TNetEncoding.URL.Decode(ASource.Substring(LComma + 1));
          LSVGDOM := TSkSVGDOM.Make(LSVGText);
          Result := RenderSVGToBitmap(LSVGDOM, AWidth, AHeight);
        end
        else if LHeader.Contains(';base64') then
        begin
          LBase64 := ASource.Substring(LComma + 1);
          LBytes := TNetEncoding.Base64.DecodeStringToBytes(LBase64);
          LStream := TBytesStream.Create(LBytes);
          try
            Result.LoadFromStream(LStream);
          finally
            LStream.Free;
          end;
        end
        else
          FreeAndNil(Result);
      end
      else
        FreeAndNil(Result);
    end
    else
    begin
      LFilePath := ResolveImageSource(ASource);
      // A missing file is drawn as "not found": no exception is raised for it
      if not TFile.Exists(LFilePath) then
        FreeAndNil(Result)
      else if LFilePath.ToLower.EndsWith('.svg') then
      begin
        FreeAndNil(Result);
        LSVGDOM := TSkSVGDOM.MakeFromFile(LFilePath);
        Result := RenderSVGToBitmap(LSVGDOM, AWidth, AHeight);
      end
      else
        Result.LoadFromFile(LFilePath);
    end;
  except
    FreeAndNil(Result);
  end;
end;

function TS4YHTMLEditor.ResolveImageSource(const ASource: string): string;
begin
  Result := ResolveImagePath(ASource, FDocumentPath, FImagePathMode);
end;

// Source to store in the document: in document mode a local file inside DocumentPath
// is stored relative to it; anything else is stored as passed
function TS4YHTMLEditor.StoredImageSource(const ASource: string): string;
begin
  Result := ASource;
  if FImagePathMode = ipmDocument then
    Result := MakeDocumentRelativePath(ASource, FDocumentPath);
end;

function TS4YHTMLEditor.LoadImage(const ASource: string; AContext: TS4YImageLoadContext; AWidth, AHeight: Integer): TBitmap;
begin
  if ASource = '' then
    Exit(nil);
  if FImageCache.TryGetValue(ASource, Result) then
    Exit;
  // Refused by OnBeforeLoadImage and nobody provided a bitmap: the event is not asked again
  // until the images are reloaded
  if FRefusedImages.ContainsKey(ASource) then
    Exit(nil);
  if IsDeferredImageSource(ASource) then
    Exit(nil);
  Result := LoadAllowedBitmap(ASource, AContext, AWidth, AHeight);
  if Assigned(Result) then
    FImageCache.Add(ASource, Result);
end;

// LocalImageAccess is checked first and cannot be overridden by OnBeforeLoadImage
function TS4YHTMLEditor.IsImageLoadAllowed(const ASource: string; AContext: TS4YImageLoadContext): Boolean;
begin
  Result := IsLocalImageAccessAllowed(ASource);
  if Result and Assigned(FOnBeforeLoadImage) then
    FOnBeforeLoadImage(Self, ASource, AContext, Result);
end;

function TS4YHTMLEditor.IsLocalImageAccessAllowed(const ASource: string): Boolean;
begin
  Result := True;
  if (FLocalImageAccess = liaDocumentFolder) and IsLocalImageSource(ASource) then
    Result := IsPathInsideFolder(ResolveImageSource(ASource), FDocumentPath);
end;

// Loads the image unless OnBeforeLoadImage refuses it, then lets OnLoadImage replace or
// provide the bitmap (also for a refused image: it stays nil if the handler gives nothing).
// A refusal without a substitute bitmap is remembered in FRefusedImages
function TS4YHTMLEditor.LoadAllowedBitmap(const ASource: string; AContext: TS4YImageLoadContext; AWidth, AHeight: Integer): TBitmap;
var
  LIsAllowed: Boolean;
begin
  Result := nil;
  LIsAllowed := IsImageLoadAllowed(ASource, AContext);
  if LIsAllowed then
    Result := LoadBitmapFromSource(ASource, AWidth, AHeight);
  if Assigned(FOnLoadImage) then
    FOnLoadImage(Self, ASource, Result, AContext);
  if not LIsAllowed and (Result = nil) then
    FRefusedImages.AddOrSetValue(ASource, True)
  else
    FRefusedImages.Remove(ASource);
end;

// True when the source belongs to a kind of images that is not loaded automatically
function TS4YHTMLEditor.IsDeferredImageSource(const ASource: string): Boolean;
begin
  Result := (not FAutoLoadRemoteImages and IsRemoteImageSource(ASource)) or
    (not FAutoLoadLocalImages and IsLocalImageSource(ASource));
end;

procedure TS4YHTMLEditor.PreloadImages;
const
  C_DEFAULT_DEFERRED_IMAGE_WIDTH  = 200;
  C_DEFAULT_DEFERRED_IMAGE_HEIGHT = 120;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LBitmap: TBitmap;
  LDeferred: Boolean;
begin
  for LParagraph in FDocument.Paragraphs do
  begin
    if (LParagraph.BlockType = btImage) and (LParagraph.ImageSource <> '') then
    begin
      LDeferred := IsDeferredImageSource(LParagraph.ImageSource);
      if LDeferred then
      begin
        if LParagraph.ImageWidth = 0 then
          LParagraph.ImageWidth := C_DEFAULT_DEFERRED_IMAGE_WIDTH;
        if LParagraph.ImageHeight = 0 then
          LParagraph.ImageHeight := C_DEFAULT_DEFERRED_IMAGE_HEIGHT;
      end
      else
      begin
        LBitmap := LoadImage(LParagraph.ImageSource, ilcParse);
        if Assigned(LBitmap) then
        begin
          if LParagraph.ImageWidth = 0 then
            LParagraph.ImageWidth := LBitmap.Width;
          if LParagraph.ImageHeight = 0 then
            LParagraph.ImageHeight := LBitmap.Height;
        end;
      end;
    end;
    for LRun in LParagraph.Runs do
    begin
      if LRun.IsImage and (LRun.ImageSource <> '') then
      begin
        LDeferred := IsDeferredImageSource(LRun.ImageSource);
        if LDeferred then
        begin
          if LRun.ImageWidth = 0 then
            LRun.ImageWidth := C_DEFAULT_DEFERRED_IMAGE_WIDTH;
          if LRun.ImageHeight = 0 then
            LRun.ImageHeight := C_DEFAULT_DEFERRED_IMAGE_HEIGHT;
        end
        else
        begin
          LBitmap := LoadImage(LRun.ImageSource, ilcParse);
          if Assigned(LBitmap) then
          begin
            if LRun.ImageWidth = 0 then
              LRun.ImageWidth := LBitmap.Width;
            if LRun.ImageHeight = 0 then
              LRun.ImageHeight := LBitmap.Height;
          end;
        end;
      end;
    end;
  end;
end;

procedure TS4YHTMLEditor.PrepareImageDimensions;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LBitmap: TBitmap;
begin
  for LParagraph in FDocument.Paragraphs do
  begin
    if LParagraph.BlockType = btImage then
    begin
      if (LParagraph.ImageWidth = 0) or (LParagraph.ImageHeight = 0) then
      begin
        LBitmap := LoadImage(LParagraph.ImageSource);
        if Assigned(LBitmap) then
        begin
          if LParagraph.ImageWidth = 0 then
            LParagraph.ImageWidth := LBitmap.Width;
          if LParagraph.ImageHeight = 0 then
            LParagraph.ImageHeight := LBitmap.Height;
        end;
      end;
    end;
    for LRun in LParagraph.Runs do
    begin
      if LRun.IsImage and ((LRun.ImageWidth <= 0) or (LRun.ImageHeight <= 0)) then
      begin
        LBitmap := LoadImage(LRun.ImageSource);
        if Assigned(LBitmap) then
        begin
          if LRun.ImageWidth = 0 then
            LRun.ImageWidth := LBitmap.Width;
          if LRun.ImageHeight = 0 then
            LRun.ImageHeight := LBitmap.Height;
        end;
      end;
    end;
  end;
end;

procedure TS4YHTMLEditor.LoadLocalImages;
begin
  LoadDeferredImages(True);
end;

procedure TS4YHTMLEditor.LoadRemoteImages;
begin
  LoadDeferredImages(False);
end;

// Loads on request the images of one kind (local files or remote URLs), whatever
// the corresponding AutoLoad property says
procedure TS4YHTMLEditor.LoadDeferredImages(ALocal: Boolean);
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LBitmap: TBitmap;
begin
  for LParagraph in FDocument.Paragraphs do
  begin
    if (LParagraph.BlockType = btImage) and (LParagraph.ImageSource <> '') and
       ((ALocal and IsLocalImageSource(LParagraph.ImageSource)) or
        (not ALocal and IsRemoteImageSource(LParagraph.ImageSource))) then
    begin
      if not FImageCache.TryGetValue(LParagraph.ImageSource, LBitmap) then
      begin
        LBitmap := LoadAllowedBitmap(LParagraph.ImageSource, ilcParse);
        if Assigned(LBitmap) then
          FImageCache.Add(LParagraph.ImageSource, LBitmap);
      end;
      if Assigned(LBitmap) and (LBitmap.Width > 0) then
      begin
        LParagraph.ImageWidth := LBitmap.Width;
        LParagraph.ImageHeight := LBitmap.Height;
      end;
    end;
    for LRun in LParagraph.Runs do
    begin
      if LRun.IsImage and (LRun.ImageSource <> '') and
         ((ALocal and IsLocalImageSource(LRun.ImageSource)) or
          (not ALocal and IsRemoteImageSource(LRun.ImageSource))) then
      begin
        if not FImageCache.TryGetValue(LRun.ImageSource, LBitmap) then
        begin
          LBitmap := LoadAllowedBitmap(LRun.ImageSource, ilcParse);
          if Assigned(LBitmap) then
            FImageCache.Add(LRun.ImageSource, LBitmap);
        end;
        if Assigned(LBitmap) and (LBitmap.Width > 0) then
        begin
          LRun.ImageWidth := LBitmap.Width;
          LRun.ImageHeight := LBitmap.Height;
        end;
      end;
    end;
  end;
  FLayoutEngine.ClearMeasureCache;
  DoLayout;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.PaintImage(ACanvas: TCanvas; const AFragment: TS4YLayoutFragment; AParagraph: TS4YHTMLParagraph);
const
  C_IMG_PLACEHOLDER_BG = $FFD8D8D8;
  C_IMG_PLACEHOLDER_BORDER = $FFA0A0A0;
var
  LBitmap: TBitmap;
  LDestinationRectangle: TRectF;
  LSourceRectangle: TRectF;
  LSelectionStart: TS4YDocumentPosition;
  LSelectionEnd: TS4YDocumentPosition;
  LFragmentPosition: TS4YDocumentPosition;
begin
  LDestinationRectangle := TRectF.Create(
    AFragment.X + ContentLeft, AFragment.Y + ContentTop,
    AFragment.X + ContentLeft + AFragment.Width, AFragment.Y + ContentTop + AFragment.Height);
  LBitmap := LoadImage(AParagraph.ImageSource, ilcRender, Round(AFragment.Width), Round(AFragment.Height));
  if Assigned(LBitmap) and (LBitmap.Width > 0) and (LBitmap.Height > 0) then
  begin
    LSourceRectangle := TRectF.Create(0, 0, LBitmap.Width, LBitmap.Height);
    ACanvas.DrawBitmap(LBitmap, LSourceRectangle, LDestinationRectangle, AbsoluteOpacity);
  end
  else
  begin
    ACanvas.Fill.Kind := TBrushKind.Solid;
    ACanvas.Fill.Color := C_IMG_PLACEHOLDER_BG;
    ACanvas.FillRect(LDestinationRectangle, AbsoluteOpacity);
    ACanvas.Stroke.Kind := TBrushKind.Solid;
    ACanvas.Stroke.Color := C_IMG_PLACEHOLDER_BORDER;
    ACanvas.Stroke.Thickness := 1;
    ACanvas.DrawRect(LDestinationRectangle, AbsoluteOpacity);
    if AParagraph.ImageAlt <> '' then
    begin
      ACanvas.Fill.Color := $FF606060;
      ACanvas.Font.Size := 11;
      ACanvas.FillText(LDestinationRectangle, AParagraph.ImageAlt, False, AbsoluteOpacity, [],
        TTextAlign.Center, TTextAlign.Center);
    end;
  end;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LFragmentPosition := TS4YDocumentPosition.At(AFragment.ParagraphIndex, 0, 0);
    if (PositionCompare(LSelectionStart, LFragmentPosition) <= 0) and (PositionCompare(LSelectionEnd, LFragmentPosition) > 0) then
    begin
      ACanvas.Fill.Kind := TBrushKind.Solid;
      ACanvas.Fill.Color := C_DEFAULT_SELECTION_COLOR;
      ACanvas.FillRect(LDestinationRectangle, AbsoluteOpacity * 0.5);
    end;
  end;
end;

// Document-space limits of the area that is painted: the visible window plus a margin
procedure TS4YHTMLEditor.GetRenderCullLimits(out ACullTop, ACullBottom: Single);
begin
  ACullTop := -C_RENDER_CULL_MARGIN - ContentTop;
  ACullBottom := Height + C_RENDER_CULL_MARGIN - ContentTop;
end;

procedure TS4YHTMLEditor.PaintSelection(ACanvas: TCanvas);
var
  LCullTop: Single;
  LCullBottom: Single;
  LFirstLineHeight: TArray<Single>;
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFragment: TS4YLayoutFragment;
  LFStart: TS4YDocumentPosition;
  LFragmentEnd: TS4YDocumentPosition;
  LCharStart: Integer;
  LCharEnd: Integer;
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LTextStyle: TS4YHTMLTextStyle;
  LHeadingSize: Single;
  LStartX: Single;
  LEndX: Single;
  LStartY: Single;
  LLineH: Single;
begin
  if not FHasSelection then
    Exit;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  if PositionCompare(LSelectionStart, LSelectionEnd) = 0 then
    Exit;

  ACanvas.Fill.Kind := TBrushKind.Solid;
  ACanvas.Fill.Color := C_DEFAULT_SELECTION_COLOR;

  // PERFORMANCE-CRITICAL: like the fragments, the selection is painted only near the visible area,
  // and the height of the first line of each paragraph is found in a single pass, not once per fragment
  GetRenderCullLimits(LCullTop, LCullBottom);
  SetLength(LFirstLineHeight, FDocument.Paragraphs.Count);
  for var I := 0 to High(FLines) do
    if (FLines[I].ParagraphIndex >= 0) and (FLines[I].ParagraphIndex < Length(LFirstLineHeight)) and
       (LFirstLineHeight[FLines[I].ParagraphIndex] = 0) then
      LFirstLineHeight[FLines[I].ParagraphIndex] := FLines[I].Height;

  for var I := 0 to High(FFrags) do
  begin
    LFragment := FFrags[I];
    if (LFragment.Y + LFragment.Height >= LCullTop) and (LFragment.Y <= LCullBottom) then
    begin
      if LFragment.IsHR then
      begin
        LFStart := TS4YDocumentPosition.At(LFragment.ParagraphIndex, 0, 0);
        if (PositionCompare(LSelectionStart, LFStart) <= 0) and (PositionCompare(LSelectionEnd, LFStart) > 0) then
        begin
          LStartX := ContentLeft + LFragment.X;
          LEndX := ContentLeft + LFragment.X + LFragment.Width;
          LStartY := ContentTop + LFragment.Y;
          ACanvas.FillRect(TRectF.Create(LStartX, LStartY, LEndX, LStartY + LFragment.Height), AbsoluteOpacity * 0.5);
        end;
      end
      else if (not LFragment.IsImage) and (not LFragment.IsPlaceholder) then
      begin
        LFStart := TS4YDocumentPosition.At(LFragment.ParagraphIndex, LFragment.RunIndex, LFragment.CharStart);
        LFragmentEnd := TS4YDocumentPosition.At(LFragment.ParagraphIndex, LFragment.RunIndex, LFragment.CharEnd);
        if (PositionCompare(LFStart, LSelectionEnd) < 0) and (PositionCompare(LFragmentEnd, LSelectionStart) > 0) then
        begin
          LCharStart := Max(LFragment.CharStart, IfThen((LFragment.ParagraphIndex = LSelectionStart.ParagraphIndex) and (LFragment.RunIndex = LSelectionStart.RunIndex), LSelectionStart.CharIndex,
            LFragment.CharStart));
          LCharEnd := Min(LFragment.CharEnd, IfThen((LFragment.ParagraphIndex = LSelectionEnd.ParagraphIndex) and (LFragment.RunIndex = LSelectionEnd.RunIndex), LSelectionEnd.CharIndex, LFragment.CharEnd));
          if LCharStart < LCharEnd then
          begin
            LParagraph := FDocument.Paragraphs[LFragment.ParagraphIndex];
            if (LFragment.RunIndex >= 0) and (LFragment.RunIndex < LParagraph.Runs.Count) then
            begin
              LRun := LParagraph.Runs[LFragment.RunIndex];
              LTextStyle := LRun.Style;
              LHeadingSize := FLayoutEngine.HeadingSize(LParagraph.BlockType);
              if LHeadingSize > 0 then
              begin
                LTextStyle.FontSize := LHeadingSize;
                LTextStyle.Bold := True;
              end;
              LStartX := ContentLeft + LFragment.X + FLayoutEngine.MeasureCharOffset(LRun.Text.Substring(LFragment.CharStart),
                LCharStart - LFragment.CharStart, LTextStyle);
              LEndX := ContentLeft + LFragment.X + FLayoutEngine.MeasureCharOffset(LRun.Text.Substring(LFragment.CharStart),
                LCharEnd - LFragment.CharStart, LTextStyle);
              LStartY := ContentTop + LFragment.Y;
              LLineH := LFirstLineHeight[LFragment.ParagraphIndex];
              if LLineH = 0 then
                LLineH := LFragment.Height;
              ACanvas.FillRect(TRectF.Create(LStartX, LStartY, LEndX, LStartY + LLineH), AbsoluteOpacity * 0.5);
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TS4YHTMLEditor.PaintImageRun(ACanvas: TCanvas; const AFragment: TS4YLayoutFragment; ARun: TS4YHTMLRun);
const
  C_IMG_PLACEHOLDER_BG = $FFD8D8D8;
  C_IMG_PLACEHOLDER_BORDER = $FFA0A0A0;
var
  LBitmap: TBitmap;
  LDestinationRectangle: TRectF;
  LSourceRectangle: TRectF;
  LSelectionStart: TS4YDocumentPosition;
  LSelectionEnd: TS4YDocumentPosition;
  LFragmentPosition: TS4YDocumentPosition;
begin
  LDestinationRectangle := TRectF.Create(
    AFragment.X + ContentLeft, AFragment.Y + ContentTop,
    AFragment.X + ContentLeft + AFragment.Width, AFragment.Y + ContentTop + AFragment.Height);
  LBitmap := LoadImage(ARun.ImageSource, ilcRender, Round(AFragment.Width), Round(AFragment.Height));
  if Assigned(LBitmap) and (LBitmap.Width > 0) and (LBitmap.Height > 0) then
  begin
    LSourceRectangle := TRectF.Create(0, 0, LBitmap.Width, LBitmap.Height);
    ACanvas.DrawBitmap(LBitmap, LSourceRectangle, LDestinationRectangle, AbsoluteOpacity);
  end
  else
  begin
    ACanvas.Fill.Kind := TBrushKind.Solid;
    ACanvas.Fill.Color := C_IMG_PLACEHOLDER_BG;
    ACanvas.FillRect(LDestinationRectangle, AbsoluteOpacity);
    ACanvas.Stroke.Kind := TBrushKind.Solid;
    ACanvas.Stroke.Color := C_IMG_PLACEHOLDER_BORDER;
    ACanvas.Stroke.Thickness := 1;
    ACanvas.DrawRect(LDestinationRectangle, AbsoluteOpacity);
    if ARun.ImageAlt <> '' then
    begin
      ACanvas.Fill.Color := $FF606060;
      ACanvas.Font.Size := 11;
      ACanvas.FillText(LDestinationRectangle, ARun.ImageAlt, False, AbsoluteOpacity, [],
        TTextAlign.Center, TTextAlign.Center);
    end;
  end;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LFragmentPosition := TS4YDocumentPosition.At(AFragment.ParagraphIndex, AFragment.RunIndex, 0);
    if (PositionCompare(LSelectionStart, LFragmentPosition) <= 0) and (PositionCompare(LSelectionEnd, LFragmentPosition) > 0) then
    begin
      ACanvas.Fill.Kind := TBrushKind.Solid;
      ACanvas.Fill.Color := C_DEFAULT_SELECTION_COLOR;
      ACanvas.FillRect(LDestinationRectangle, AbsoluteOpacity * 0.5);
    end;
  end;
end;

procedure TS4YHTMLEditor.PaintFragment(ACanvas: TCanvas; const AFragment: TS4YLayoutFragment);
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LTextStyle: TS4YHTMLTextStyle;
  LPaintX, LPaintY: Single;
  LLayout: TTextLayout;
  LEffSize: Single;
  LFragmentText: String;
  LHeadingSize: Single;
  LUnderlineY: Single;
  LStrikeOutY: Single;
  LLineAscent: Single;
begin
  if (AFragment.ParagraphIndex < 0) or (AFragment.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[AFragment.ParagraphIndex];
  if LParagraph.BlockType in [btHR, btImage] then
    Exit;
  if (AFragment.RunIndex < 0) or (AFragment.RunIndex >= LParagraph.Runs.Count) then
    Exit;
  LRun := LParagraph.Runs[AFragment.RunIndex];
  if LRun.IsLineBreak then
    Exit;
  if AFragment.IsPlaceholder or LRun.IsPlaceholder then
  begin
    PaintPlaceholderFragment(ACanvas, AFragment);
    Exit;
  end;
  LFragmentText := LRun.Text.Substring(AFragment.CharStart, AFragment.CharEnd - AFragment.CharStart);
  if LFragmentText = '' then
    Exit;

  LTextStyle := LRun.Style;
  LHeadingSize := FLayoutEngine.HeadingSize(LParagraph.BlockType);
  if LHeadingSize > 0 then
  begin
    LTextStyle.FontSize := LHeadingSize;
    LTextStyle.Bold := True;
  end;

  LPaintX := ContentLeft + AFragment.X;
  LPaintY := ContentTop + AFragment.Y;

  // Subscript/Superscript vertical offset -- anchored to the line baseline
  LEffSize := FLayoutEngine.EffectiveSize(LTextStyle);
  if LTextStyle.Superscript or LTextStyle.Subscript then
  begin
    LLineAscent := LEffSize;
    if (AFragment.LineIndex >= 0) and (AFragment.LineIndex < Length(FLines)) then
      LLineAscent := FLines[AFragment.LineIndex].Ascent;
    if LTextStyle.Superscript then
      LPaintY := LPaintY - LLineAscent * 0.35
    else
      LPaintY := LPaintY + LLineAscent * 0.6;
  end;

  // Background highlight
  if LTextStyle.BackgroundColor <> claNull then
  begin
    ACanvas.Fill.Kind := TBrushKind.Solid;
    ACanvas.Fill.Color := LTextStyle.BackgroundColor;
    ACanvas.FillRect(TRectF.Create(LPaintX, LPaintY, LPaintX + AFragment.Width, LPaintY + AFragment.Height), AbsoluteOpacity);
  end;

  LLayout := TTextLayoutManager.DefaultTextLayout.Create(ACanvas);
  try
    LLayout.BeginUpdate;
    LLayout.Font.Family := LTextStyle.FontName;
    LLayout.Font.Size := LEffSize;
    LLayout.Font.Style := TextStyleToFMXFontStyle(LTextStyle);
    LLayout.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
    LLayout.MaxSize := TPointF.Create(AFragment.Width + 4, AFragment.Height + 4);
    LLayout.WordWrap := False;
    LLayout.TopLeft := TPointF.Create(LPaintX, LPaintY);
    LLayout.Text := LFragmentText;
    LLayout.EndUpdate;
    LLayout.RenderLayout(ACanvas);
  finally
    LLayout.Free;
  end;

  // Underline
  if LTextStyle.Underline then
  begin
    LUnderlineY := LPaintY + AFragment.Height * 0.88;
    ACanvas.Stroke.Kind := TBrushKind.Solid;
    ACanvas.Stroke.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
    ACanvas.Stroke.Thickness := 1;
    ACanvas.DrawLine(TPointF.Create(LPaintX, LUnderlineY), TPointF.Create(LPaintX + AFragment.Width, LUnderlineY), AbsoluteOpacity);
  end;
  if LTextStyle.StrikeOut then
  begin
    LStrikeOutY := LPaintY + AFragment.Height * 0.5;
    ACanvas.Stroke.Kind := TBrushKind.Solid;
    ACanvas.Stroke.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
    ACanvas.Stroke.Thickness := 1;
    ACanvas.DrawLine(TPointF.Create(LPaintX, LStrikeOutY), TPointF.Create(LPaintX + AFragment.Width, LStrikeOutY), AbsoluteOpacity);
  end;
end;

procedure TS4YHTMLEditor.PaintPlaceholderFragment(ACanvas: TCanvas; const AFragment: TS4YLayoutFragment);
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LBounds: TRectF;
  LAppearance: TS4YPlaceholderAppearance;
  LLabelText: string;
  LHandled: Boolean;
  LLayout: TTextLayout;
  LTextStyle: TS4YHTMLTextStyle;
  LCorners: TCorners;
  LSelectionStart: TS4YDocumentPosition;
  LSelectionEnd: TS4YDocumentPosition;
  LFragmentPosition: TS4YDocumentPosition;
  LIsCurrent: Boolean;
  LEffectiveFillColor: TAlphaColor;
  LBorderColor: TAlphaColor;
begin
  if (AFragment.ParagraphIndex < 0) or (AFragment.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[AFragment.ParagraphIndex];
  if (AFragment.RunIndex < 0) or (AFragment.RunIndex >= LParagraph.Runs.Count) then
    Exit;
  LRun := LParagraph.Runs[AFragment.RunIndex];

  LBounds := TRectF.Create(ContentLeft + AFragment.X, ContentTop + AFragment.Y, ContentLeft + AFragment.X + AFragment.Width, ContentTop + AFragment.Y + AFragment.Height);

  if LRun.DisplayText <> '' then
    LLabelText := LRun.DisplayText
  else
  begin
    LLabelText := LRun.Text;
    if Assigned(FOnGetPlaceholderLabel) then
      FOnGetPlaceholderLabel(Self, LRun.Text, LLabelText);
  end;

  // Custom draw event -- caller can fully override rendering
  LHandled := False;
  if Assigned(FOnDrawPlaceholder) then
    FOnDrawPlaceholder(Self, ACanvas, LBounds, LRun.Text, LHandled);
  if LHandled then
    Exit;

  LIsCurrent := FCaretPosition.IsValid and not FHasSelection and
                (FCaretPosition.ParagraphIndex = AFragment.ParagraphIndex) and (FCaretPosition.RunIndex = AFragment.RunIndex);

  LAppearance := FPlaceholderAppearance;
  LCorners := [TCorner.TopLeft, TCorner.TopRight, TCorner.BottomLeft, TCorner.BottomRight];

  // Fill -- use run's BackgroundColor if explicitly set, otherwise appearance default
  LEffectiveFillColor := IfThen(LRun.Style.BackgroundColor <> claNull, LRun.Style.BackgroundColor, LAppearance.FillColor);
  ACanvas.Fill.Kind := TBrushKind.Solid;
  ACanvas.Fill.Color := LEffectiveFillColor;
  ACanvas.FillRect(LBounds, LAppearance.BorderRadius, LAppearance.BorderRadius, LCorners, AbsoluteOpacity);

  // Border -- priority: explicit per-run -> auto-derive from fill -> global default
  if LRun.PlaceholderBorderColor <> claNull then
    LBorderColor := LRun.PlaceholderBorderColor
  else if LEffectiveFillColor <> claNull then
    LBorderColor := DarkenColor(LEffectiveFillColor)
  else
    LBorderColor := LAppearance.BorderColor;
  if LBorderColor <> claNull then
  begin
    ACanvas.Stroke.Kind := TBrushKind.Solid;
    ACanvas.Stroke.Color := LBorderColor;
    ACanvas.Stroke.Thickness := IfThen(LIsCurrent, 2.5, 1);
    ACanvas.DrawRect(LBounds, LAppearance.BorderRadius, LAppearance.BorderRadius, LCorners, AbsoluteOpacity);
  end;

  // Label text -- run style overrides appearance defaults
  LTextStyle := LRun.Style;
  if LAppearance.Bold then
    LTextStyle.Bold := True;
  LLayout := TTextLayoutManager.DefaultTextLayout.Create(ACanvas);
  try
    LLayout.BeginUpdate;
    LLayout.Font.Family := LTextStyle.FontName;
    LLayout.Font.Size := FLayoutEngine.EffectiveSize(LTextStyle);
    LLayout.Font.Style := TextStyleToFMXFontStyle(LTextStyle);
    LLayout.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, LAppearance.TextColor);
    LLayout.MaxSize := TPointF.Create(AFragment.Width, AFragment.Height);
    LLayout.WordWrap := False;
    LLayout.TopLeft := TPointF.Create(LBounds.Left + LAppearance.HorizontalPadding, LBounds.Top + LAppearance.VerticalPadding);
    LLayout.Text := LLabelText;
    LLayout.EndUpdate;
    LLayout.RenderLayout(ACanvas);
  finally
    LLayout.Free;
  end;

  // Selection overlay
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LFragmentPosition := TS4YDocumentPosition.At(AFragment.ParagraphIndex, AFragment.RunIndex, 0);
    if (PositionCompare(LSelectionStart, LFragmentPosition) <= 0) and (PositionCompare(LSelectionEnd, LFragmentPosition) > 0) then
    begin
      ACanvas.Fill.Kind := TBrushKind.Solid;
      ACanvas.Fill.Color := C_DEFAULT_SELECTION_COLOR;
      ACanvas.FillRect(LBounds, LAppearance.BorderRadius, LAppearance.BorderRadius, LCorners, AbsoluteOpacity * 0.5);
    end;
  end;
end;

procedure TS4YHTMLEditor.PaintCaret(ACanvas: TCanvas);
begin
  if csDesigning in ComponentState then
    Exit;
  if not FCaretOn then
    Exit;
  if not FCaretPosition.IsValid then
    Exit;
  // While a selection is dragged the caret would follow the mouse pointer
  if FDragging and FHasSelection then
    Exit;
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.Stroke.Color := TAlphaColors.Black;
  ACanvas.Stroke.Thickness := 1.5;
  ACanvas.DrawLine(TPointF.Create(FCaretScreenX, FCaretScreenY), TPointF.Create(FCaretScreenX, FCaretScreenY + FCaretScreenH),
    AbsoluteOpacity);
end;

procedure TS4YHTMLEditor.PaintBorder(ACanvas: TCanvas);
begin
  if not FShowBorder then
    Exit;
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.Stroke.Color := $FFA0A0A0;
  ACanvas.Stroke.Thickness := 1;
  ACanvas.DrawRect(TRectF.Create(0, 0, Width, Height), AbsoluteOpacity);
end;

// -- Caret & Navigation -------------------------------------------------------

procedure TS4YHTMLEditor.UpdateCaretXY;
var
  LXPosition, LYPosition, LHeight: Single;
begin
  if DocumentPositionToXY(FCaretPosition, LXPosition, LYPosition, LHeight) then
  begin
    FCaretScreenX := LXPosition;
    FCaretScreenY := LYPosition;
    FCaretScreenH := LHeight;
  end
  else if FCaretScreenH = 0 then
  begin
    // DocumentPositionToXY failed and coordinates were never set: place the caret at
    // the top-left of the content area with a default height so it is at
    // least visible rather than drawing a zero-length invisible line.
    FCaretScreenX := ContentLeft;
    FCaretScreenY := ContentTop;
    FCaretScreenH := 16;
  end;
end;

function TS4YHTMLEditor.DocumentPositionToXY(const APosition: TS4YDocumentPosition; out AX, AY, AHeight: Single): Boolean;
var
  LParagraph: TS4YHTMLParagraph;
  LFragment: TS4YLayoutFragment;
  LTextStyle: TS4YHTMLTextStyle;
  LHeadingSize: Single;
  LOfs: Single;
  LLastFound: Boolean;
  LFragment2: TS4YLayoutFragment;
begin
  Result := False;
  AX := ContentLeft;
  AY := ContentTop;
  AHeight := 16;
  if not APosition.IsValid then
    Exit;
  if APosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;

  LParagraph := FDocument.Paragraphs[APosition.ParagraphIndex];

  if LParagraph.BlockType in [btImage, btHR] then
  begin
    for var I := 0 to High(FFrags) do
      if FFrags[I].ParagraphIndex = APosition.ParagraphIndex then
      begin
        if FCaretAtImageRight then
          AX := ContentLeft + FFrags[I].X + FFrags[I].Width
        else
          AX := ContentLeft + FFrags[I].X;
        AY := ContentTop + FFrags[I].Y;
        AHeight := FFrags[I].Height;
        Result := True;
        Exit;
      end;
    Exit;
  end;

  for var I := 0 to High(FFrags) do
  begin
    LFragment := FFrags[I];
    if (not LFragment.IsHR) and (not LFragment.IsImage or (LFragment.RunIndex >= 0)) and (LFragment.ParagraphIndex = APosition.ParagraphIndex) and (LFragment.RunIndex = APosition.RunIndex) and (APosition.CharIndex >= LFragment.CharStart) and
      ((LFragment.IsImage and (LFragment.RunIndex >= 0)) or (APosition.CharIndex <= LFragment.CharEnd)) then
    begin
      if LFragment.IsPlaceholder or (LFragment.IsImage and (LFragment.RunIndex >= 0)) then
      begin
        if APosition.CharIndex = 0 then
          AX := ContentLeft + LFragment.X
        else
          AX := ContentLeft + LFragment.X + LFragment.Width;
        AY := ContentTop + LFragment.Y;
        AHeight := LFragment.Height;
        Result := True;
        Exit;
      end;
      LTextStyle.Init;
      if (LFragment.RunIndex >= 0) and (LFragment.RunIndex < LParagraph.Runs.Count) then
        LTextStyle := LParagraph.Runs[LFragment.RunIndex].Style;
      LHeadingSize := FLayoutEngine.HeadingSize(LParagraph.BlockType);
      if LHeadingSize > 0 then
      begin
        LTextStyle.FontSize := LHeadingSize;
        LTextStyle.Bold := True;
      end;

      LOfs := 0;
      if (LFragment.RunIndex >= 0) and (LFragment.RunIndex < LParagraph.Runs.Count) then
        LOfs := FLayoutEngine.MeasureCharOffset(LParagraph.Runs[LFragment.RunIndex].Text.Substring(LFragment.CharStart),
          APosition.CharIndex - LFragment.CharStart, LTextStyle);
      AX := ContentLeft + LFragment.X + LOfs;
      AY := ContentTop + LFragment.Y;
      AHeight := LFragment.Height;
      Result := True;
      Exit;
    end;
  end;

  LLastFound := False;
  for var I := High(FFrags) downto 0 do
    if (not LLastFound) and (FFrags[I].ParagraphIndex = APosition.ParagraphIndex) and not FFrags[I].IsHR and not FFrags[I].IsImage then
    begin
      LFragment2 := FFrags[I];
      AX := ContentLeft + LFragment2.X + LFragment2.Width;
      AY := ContentTop + LFragment2.Y;
      AHeight := LFragment2.Height;
      Result := True;
      LLastFound := True;
    end;
end;

procedure TS4YHTMLEditor.EnsureCaretVisible;
var
  LX, LY, LHeight, LDocumentY, LViewHeight: Single;
begin
  if not DocumentPositionToXY(FCaretPosition, LX, LY, LHeight) then
    Exit;
  // DocumentPositionToXY returns screen Y = ContentTop + F.Y
  // Document coordinate of the caret: DocY = Y - ContentTop = F.Y
  // Scroll range is [0, FScrollBarMaximum]; viewport is [FScrollY, FScrollY + ViewH]
  LDocumentY := LY - ContentTop;
  LViewHeight := Height - C_EDITOR_PADDING * 2;
  if LDocumentY < FScrollY then
    ScrollTo(LDocumentY)
  else if LDocumentY + LHeight > FScrollY + LViewHeight then
    ScrollTo(LDocumentY + LHeight - LViewHeight);
end;

procedure TS4YHTMLEditor.ScrollTo(AY: Single);
begin
  FScrollY := Max(0, Min(AY, FScrollBarMaximum));
  if (FScrollBar <> nil) and FScrollBar.Visible then
  begin
    FSyncing := True;
    try
      FScrollBar.Value := FScrollY;
    finally
      FSyncing := False;
    end;
  end;
  UpdateCaretXY;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.OnScrollChange(Sender: TObject);
begin
  if FSyncing then
    Exit;
  FScrollY := Max(0, Min(FScrollBar.Value, FScrollBarMaximum));
  UpdateCaretXY;
  InvalidateRender;
end;

function TS4YHTMLEditor.HitTest(AX, AY: Single): TS4YDocumentPosition;
var
  LDocumentX, LDocumentY: Single;
  LBestLineY: Single;
  LLine: TS4YLayoutLine;
  LDistance, LDistanceX: Single;
  LFragment: TS4YLayoutFragment;
  LBestFragment: TS4YLayoutFragment;
  LBestFragmentIndex: Integer;
  LBestDist: Single;
  LPara2: TS4YHTMLParagraph;
  LRun2: TS4YHTMLRun;
  LTextStyle: TS4YHTMLTextStyle;
  LHeadingSize: Single;
  LFragmentSubstring: string;
  LCharIndex: Integer;
  LClickedCell: Integer;
begin
  Result := DocumentStart;
  LDocumentX := AX - ContentLeft;
  LDocumentY := AY - ContentTop;

  // Pre-pass: if the click lands inside a table cell, record the innermost one
  // so the next passes can ignore the lines of the other cells.
  LClickedCell := -1;
  for var I := 0 to High(FCells) do
    if (LDocumentX >= FCells[I].X) and (LDocumentX < FCells[I].X + FCells[I].Width) and
       (LDocumentY >= FCells[I].Y) and (LDocumentY < FCells[I].Y + FCells[I].Height) and
       ((LClickedCell < 0) or (FCells[I].Depth >= FCells[LClickedCell].Depth)) then
      LClickedCell := I;

  // Pass 1: find minimum Y distance across all lines (only those of the clicked cell, when there is one)
  LBestLineY := MaxSingle;
  for var I := 0 to High(FLines) do
  begin
    LLine := FLines[I];
    if (LClickedCell < 0) or IsParagraphInLayoutCell(LClickedCell, LLine.ParagraphIndex) then
    begin
      if (LDocumentY >= LLine.Y) and (LDocumentY < LLine.Y + LLine.Height) then
        LDistance := 0
      else
        LDistance := Min(Abs(LDocumentY - LLine.Y), Abs(LDocumentY - (LLine.Y + LLine.Height)));
      if LDistance < LBestLineY then
        LBestLineY := LDistance;
    end;
  end;

  // Pass 2: among all lines with that Y distance, pick best frag by combined Y+X dist
  LBestFragmentIndex := -1;
  LBestDist := MaxSingle;
  for var I := 0 to High(FLines) do
  begin
    LLine := FLines[I];
    if (LDocumentY >= LLine.Y) and (LDocumentY < LLine.Y + LLine.Height) then
      LDistance := 0
    else
      LDistance := Min(Abs(LDocumentY - LLine.Y), Abs(LDocumentY - (LLine.Y + LLine.Height)));
    if (LDistance <= LBestLineY + 0.1) and
       ((LClickedCell < 0) or IsParagraphInLayoutCell(LClickedCell, LLine.ParagraphIndex)) then
      for var J := LLine.FragmentStart to LLine.FragmentStart + LLine.FragmentCount - 1 do
      begin
        if (LClickedCell < 0) or IsParagraphInLayoutCell(LClickedCell, FFrags[J].ParagraphIndex) then
        begin
          LFragment := FFrags[J];
          if LDocumentX < LFragment.X then
            LDistanceX := LFragment.X - LDocumentX
          else if LDocumentX > LFragment.X + LFragment.Width then
            LDistanceX := LDocumentX - (LFragment.X + LFragment.Width)
          else
            LDistanceX := 0;
          if LDistance + LDistanceX < LBestDist then
          begin
            LBestDist := LDistance + LDistanceX;
            LBestFragmentIndex := J;
          end;
        end;
      end;
  end;
  if LBestFragmentIndex < 0 then
    Exit;

  LBestFragment := FFrags[LBestFragmentIndex];
  if LBestFragment.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LPara2 := FDocument.Paragraphs[LBestFragment.ParagraphIndex];
  if LBestFragment.IsImage or LBestFragment.IsHR then
  begin
    if LBestFragment.IsImage and (LBestFragment.RunIndex >= 0) then
    begin
      if LDocumentX - LBestFragment.X >= LBestFragment.Width / 2 then
        Result := TS4YDocumentPosition.At(LBestFragment.ParagraphIndex, LBestFragment.RunIndex, 1)
      else
        Result := TS4YDocumentPosition.At(LBestFragment.ParagraphIndex, LBestFragment.RunIndex, 0);
    end
    else
    begin
      if (LDocumentX - LBestFragment.X >= LBestFragment.Width / 2) and (LBestFragment.ParagraphIndex + 1 < FDocument.Paragraphs.Count) then
        Result := TS4YDocumentPosition.At(LBestFragment.ParagraphIndex + 1, 0, 0)
      else
        Result := TS4YDocumentPosition.At(LBestFragment.ParagraphIndex, 0, 0);
    end;
    Exit;
  end;
  if (LBestFragment.RunIndex < 0) or (LBestFragment.RunIndex >= LPara2.Runs.Count) then
  begin
    Result := TS4YDocumentPosition.At(LBestFragment.ParagraphIndex, 0, 0);
    Exit;
  end;

  LRun2 := LPara2.Runs[LBestFragment.RunIndex];

  if LBestFragment.IsPlaceholder or LRun2.IsPlaceholder then
  begin
    if LDocumentX - LBestFragment.X < LBestFragment.Width / 2 then
      Result := TS4YDocumentPosition.At(LBestFragment.ParagraphIndex, LBestFragment.RunIndex, 0)
    else
      Result := TS4YDocumentPosition.At(LBestFragment.ParagraphIndex, LBestFragment.RunIndex, LRun2.Text.Length);
    Exit;
  end;

  LTextStyle := LRun2.Style;
  LHeadingSize := FLayoutEngine.HeadingSize(LPara2.BlockType);
  if LHeadingSize > 0 then
  begin
    LTextStyle.FontSize := LHeadingSize;
    LTextStyle.Bold := True;
  end;

  LFragmentSubstring := LRun2.Text.Substring(LBestFragment.CharStart, LBestFragment.CharEnd - LBestFragment.CharStart);
  LCharIndex := FLayoutEngine.CharAtX(LFragmentSubstring, LDocumentX - LBestFragment.X, LTextStyle);
  Result := TS4YDocumentPosition.At(LBestFragment.ParagraphIndex, LBestFragment.RunIndex, LBestFragment.CharStart + LCharIndex);
end;

function TS4YHTMLEditor.LinkURLAt(AX, AY: Single): string;
var
  LHitPosition: TS4YDocumentPosition;
  LParagraph: TS4YHTMLParagraph;
begin
  Result := '';
  if Length(FFrags) = 0 then
    Exit;
  LHitPosition := HitTest(AX, AY);
  if not LHitPosition.IsValid then
    Exit;
  if LHitPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LParagraph := FDocument.Paragraphs[LHitPosition.ParagraphIndex];
  if (LHitPosition.RunIndex >= 0) and (LHitPosition.RunIndex < LParagraph.Runs.Count) then
    Result := LParagraph.Runs[LHitPosition.RunIndex].Style.LinkURL;
end;

function TS4YHTMLEditor.LinkTextForURL(const APosition: TS4YDocumentPosition; const AURL: string): string;
var
  LStringBuilder: TStringBuilder;
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
begin
  Result := '';
  if (AURL = '') or not APosition.IsValid then
    Exit;
  if APosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LParagraph := FDocument.Paragraphs[APosition.ParagraphIndex];
  LStringBuilder := TStringBuilder.Create;
  try
    for var I := 0 to LParagraph.Runs.Count - 1 do
    begin
      LRun := LParagraph.Runs[I];
      if (LRun.Style.LinkURL = AURL) and not LRun.IsLineBreak then
        LStringBuilder.Append(LRun.Text);
    end;
    Result := LStringBuilder.ToString;
  finally
    LStringBuilder.Free;
  end;
end;

procedure TS4YHTMLEditor.SetCaretPosition(const APosition: TS4YDocumentPosition; ExtendSel: Boolean);
begin
  ApplyCaretPosition(APosition, ExtendSel);
  InvalidateRender;
  DoNotifyState;
end;

// Moves the caret and selection, then renders the document again only when the move changes what
// the render cache contains: a selection (before or after) or a placeholder under the caret.
// Otherwise the caret is drawn over the cache and a repaint is enough.
procedure TS4YHTMLEditor.MoveCaretPosition(const APosition: TS4YDocumentPosition; ExtendSel: Boolean);
var
  LOldPosition: TS4YDocumentPosition;
  LHadSelection: Boolean;
begin
  LOldPosition := FCaretPosition;
  LHadSelection := FHasSelection;
  ApplyCaretPosition(APosition, ExtendSel);
  if LHadSelection or FHasSelection or IsPlaceholderPosition(LOldPosition) or IsPlaceholderPosition(FCaretPosition) then
    InvalidateRender
  else
    Repaint;
  DoNotifyState;
end;

function TS4YHTMLEditor.IsPlaceholderPosition(const APosition: TS4YDocumentPosition): Boolean;
begin
  Result := False;
  if (APosition.ParagraphIndex < 0) or (APosition.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  if (APosition.RunIndex < 0) or (APosition.RunIndex >= FDocument.Paragraphs[APosition.ParagraphIndex].Runs.Count) then
    Exit;
  Result := FDocument.Paragraphs[APosition.ParagraphIndex].Runs[APosition.RunIndex].IsPlaceholder;
end;

procedure TS4YHTMLEditor.ApplyCaretPosition(const APosition: TS4YDocumentPosition; ExtendSel: Boolean);
begin
  if ExtendSel then
  begin
    if not FHasSelection then
    begin
      FSelectionStart := FCaretPosition;
      FSelectionEnd := FCaretPosition;
      FHasSelection := True;
    end;
    FSelectionEnd := APosition;
    if PositionCompare(FSelectionStart, FSelectionEnd) = 0 then
      FHasSelection := False;
  end
  else
  begin
    FHasSelection := False;
    FSelectionStart := TS4YDocumentPosition.Invalid;
    FSelectionEnd := TS4YDocumentPosition.Invalid;
  end;
  FCaretPosition := APosition;
  FCaretOn := True;
  FInsertStyleSet := False;
  // Restart the blink cycle so the caret is always ON for a full interval
  // after any caret move (click, keyboard, etc.). Simply assigning Enabled
  // when it is already True does NOT reset the timer in Delphi.
  FCaretTimer.Enabled := False;
  FCaretTimer.Enabled := IsFocused;
  UpdateCaretXY;
  EnsureCaretVisible;
end;

function TS4YHTMLEditor.FragmentIndexAt(AParagraphIndex, ARunIndex, ACharIndex: Integer): Integer;
begin
  // PERFORMANCE: linear scan used by hit testing and caret positioning. It must keep
  // returning at the first matching fragment (Exit(I)); never collect all the
  // matches or let the loop run on after a hit.
  for var I := 0 to High(FFrags) do
  begin
    if FFrags[I].ParagraphIndex = AParagraphIndex then
    begin
      if FFrags[I].IsImage or FFrags[I].IsHR then
      begin
        if (FFrags[I].RunIndex < 0) or (FFrags[I].RunIndex = ARunIndex) then
          Exit(I);
      end
      else if (FFrags[I].RunIndex = ARunIndex) and (ACharIndex >= FFrags[I].CharStart) and (ACharIndex <= FFrags[I].CharEnd) then
        Exit(I);
    end;
  end;
  Result := -1;
end;

function TS4YHTMLEditor.PositionCompare(const ALeft, ARight: TS4YDocumentPosition): Integer;
begin
  if ALeft.ParagraphIndex <> ARight.ParagraphIndex then
    Exit(Sign(ALeft.ParagraphIndex - ARight.ParagraphIndex));
  if ALeft.RunIndex <> ARight.RunIndex then
    Exit(Sign(ALeft.RunIndex - ARight.RunIndex));
  Result := Sign(ALeft.CharIndex - ARight.CharIndex);
end;

procedure TS4YHTMLEditor.GetSelectionRange(out AStartPosition, AEndPosition: TS4YDocumentPosition);
begin
  if PositionCompare(FSelectionStart, FSelectionEnd) <= 0 then
  begin
    AStartPosition := FSelectionStart;
    AEndPosition := FSelectionEnd;
  end
  else
  begin
    AStartPosition := FSelectionEnd;
    AEndPosition := FSelectionStart;
  end;
end;

// Finds the contiguous block of btLI paragraphs that contains the caret.
// Used when there is no active selection and the caret sits on a list item.
procedure TS4YHTMLEditor.GetListBlockRange(out AFirst, ALast: Integer);
var
  LParagraphIndex: Integer;
  LOrdered: Boolean;
begin
  AFirst := FCaretPosition.ParagraphIndex;
  ALast  := FCaretPosition.ParagraphIndex;
  if not FCaretPosition.IsValid or (AFirst >= FDocument.Paragraphs.Count) then
    Exit;
  if FDocument.Paragraphs[AFirst].BlockType <> btLI then
    Exit;
  LOrdered := FDocument.Paragraphs[AFirst].ListOrdered;
  LParagraphIndex := AFirst - 1;
  while (LParagraphIndex >= 0) and (FDocument.Paragraphs[LParagraphIndex].BlockType = btLI) and
        (FDocument.Paragraphs[LParagraphIndex].ListOrdered = LOrdered) and InSameBlockScope(LParagraphIndex, ALast) do
  begin
    AFirst := LParagraphIndex;
    Dec(LParagraphIndex);
  end;
  LParagraphIndex := ALast + 1;
  while (LParagraphIndex < FDocument.Paragraphs.Count) and (FDocument.Paragraphs[LParagraphIndex].BlockType = btLI) and
        (FDocument.Paragraphs[LParagraphIndex].ListOrdered = LOrdered) and InSameBlockScope(LParagraphIndex, AFirst) do
  begin
    ALast := LParagraphIndex;
    Inc(LParagraphIndex);
  end;
end;

// Renumbers all ordered btLI items in AFirst..ALast.
// Counters are per-indent-level: going deeper resets the level counter;
// going back to a shallower level continues where it left off.
procedure TS4YHTMLEditor.RenumberListBlock(AFirst, ALast: Integer);
const
  C_MAX_INDENT = 31;
var
  LCounters: array[0..C_MAX_INDENT] of Integer;
  LLastIndent: Integer;
  LIndentLevel: Integer;
begin
  FillChar(LCounters, SizeOf(LCounters), 0);
  LLastIndent := -1;
  for var I := AFirst to Min(ALast, FDocument.Paragraphs.Count - 1) do
    if FDocument.Paragraphs[I].BlockType = btLI then
    begin
      LIndentLevel := Min(FDocument.Paragraphs[I].IndentLevel, C_MAX_INDENT);
      if LIndentLevel > LLastIndent then
        LCounters[LIndentLevel] := 0;
      if FDocument.Paragraphs[I].ListOrdered then
      begin
        Inc(LCounters[LIndentLevel]);
        FDocument.Paragraphs[I].ListIndex := LCounters[LIndentLevel];
      end;
      LLastIndent := LIndentLevel;
    end;
end;

procedure TS4YHTMLEditor.ResetSelection;
begin
  FHasSelection := False;
  FSelectionStart := TS4YDocumentPosition.Invalid;
  FSelectionEnd := TS4YDocumentPosition.Invalid;
end;

procedure TS4YHTMLEditor.ClearSelection;
begin
  if not FHasSelection then
    Exit;
  ResetSelection;
  InvalidateRender;
  DoNotifyState;
end;

function TS4YHTMLEditor.DocumentStart: TS4YDocumentPosition;
begin
  if FDocument.Paragraphs.Count = 0 then
    Exit(TS4YDocumentPosition.Invalid);
  Result := TS4YDocumentPosition.At(0, 0, 0);
end;

function TS4YHTMLEditor.DocumentEnd: TS4YDocumentPosition;
var
  LLastPI: Integer;
  LParagraph: TS4YHTMLParagraph;
  LLastRI: Integer;
begin
  if FDocument.Paragraphs.Count = 0 then
    Exit(TS4YDocumentPosition.Invalid);
  LLastPI := FDocument.Paragraphs.Count - 1;
  LParagraph := FDocument.Paragraphs[LLastPI];
  if LParagraph.Runs.Count = 0 then
    Exit(TS4YDocumentPosition.At(LLastPI, 0, 0));
  LLastRI := LParagraph.Runs.Count - 1;
  Exit(TS4YDocumentPosition.At(LLastPI, LLastRI, LParagraph.Runs[LLastRI].Text.Length));
end;

function TS4YHTMLEditor.NextDocumentPosition(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LNextCharIndex: Integer;
  LRightIndex: Integer;
begin
  if not APosition.IsValid then
    Exit(TS4YDocumentPosition.Invalid);
  if APosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit(APosition);
  LParagraph := FDocument.Paragraphs[APosition.ParagraphIndex];
  if LParagraph.Runs.Count = 0 then
  begin
    if APosition.ParagraphIndex + 1 < FDocument.Paragraphs.Count then
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex + 1, 0, 0))
    else
      Exit(APosition);
  end;
  if APosition.RunIndex >= LParagraph.Runs.Count then
    Exit(APosition);
  LRun := LParagraph.Runs[APosition.RunIndex];
  if LRun.IsPlaceholder or LRun.IsImage then
  begin
    if LRun.IsImage then
      LRightIndex := 1
    else
      LRightIndex := LRun.Text.Length;
    if APosition.CharIndex < LRightIndex then
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex, LRightIndex));
    if APosition.RunIndex + 1 < LParagraph.Runs.Count then
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex + 1, 0));
    if APosition.ParagraphIndex + 1 < FDocument.Paragraphs.Count then
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex + 1, 0, 0));
    Exit(APosition);
  end
  else if APosition.CharIndex < LRun.Text.Length then
  begin
    if (APosition.CharIndex < LRun.Text.Length - 1) and
       LRun.Text[APosition.CharIndex + 1].IsHighSurrogate and
       LRun.Text[APosition.CharIndex + 2].IsLowSurrogate then
      LNextCharIndex := APosition.CharIndex + 2
    else
      LNextCharIndex := APosition.CharIndex + 1;
    // Skip the phantom position at end of text run: (textRun, textRun.Length)
    // is visually identical to (nextRun, 0) for any run type.
    if (LNextCharIndex >= LRun.Text.Length) and (APosition.RunIndex + 1 < LParagraph.Runs.Count) then
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex + 1, 0))
    else
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex, LNextCharIndex));
  end;
  if APosition.RunIndex + 1 < LParagraph.Runs.Count then
    Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex + 1, 0));
  if APosition.ParagraphIndex + 1 < FDocument.Paragraphs.Count then
    Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex + 1, 0, 0));
  Result := APosition;
end;

function TS4YHTMLEditor.PreviousDocumentPosition(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
var
  LParagraph: TS4YHTMLParagraph;
  LPreviousParagraph: TS4YHTMLParagraph;
  LCurrentRun: TS4YHTMLRun;
  LPreviousRun: TS4YHTMLRun;
  LRunIndex: integer;
  LPreviousRightIndex: Integer;
begin
  if not APosition.IsValid then
    Exit(TS4YDocumentPosition.Invalid);
  if APosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit(APosition);
  LParagraph := FDocument.Paragraphs[APosition.ParagraphIndex];
  if LParagraph.Runs.Count > 0 then
  begin
    if APosition.RunIndex < LParagraph.Runs.Count then
    begin
      LCurrentRun := LParagraph.Runs[APosition.RunIndex];
      if LCurrentRun.IsPlaceholder or LCurrentRun.IsImage then
      begin
        if APosition.CharIndex > 0 then
          Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex, 0));
      end
      else if APosition.CharIndex > 0 then
      begin
        if (APosition.CharIndex > 1) and
           LCurrentRun.Text[APosition.CharIndex].IsLowSurrogate and
           LCurrentRun.Text[APosition.CharIndex - 1].IsHighSurrogate then
          Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex, APosition.CharIndex - 2))
        else
          Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex, APosition.CharIndex - 1));
      end;
    end;
  end;
  if (APosition.RunIndex > 0) and (APosition.RunIndex - 1 < LParagraph.Runs.Count) then
  begin
    LPreviousRun := LParagraph.Runs[APosition.RunIndex - 1];
    if LPreviousRun.IsPlaceholder or LPreviousRun.IsImage then
    begin
      if LPreviousRun.IsImage then
        LPreviousRightIndex := 1
      else
        LPreviousRightIndex := LPreviousRun.Text.Length;
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex - 1, LPreviousRightIndex));
    end
    else if LPreviousRun.IsLineBreak then
    begin
      // A line break has no characters to step over: the previous position is the end of
      // the line before it, which is a different place from (curRun, 0). A line break
      // has no fragment of its own, so use the end of the text run before it when there
      // is one, otherwise the break itself.
      if (APosition.RunIndex > 1) and
         not (LParagraph.Runs[APosition.RunIndex - 2].IsLineBreak or LParagraph.Runs[APosition.RunIndex - 2].IsPlaceholder or
              LParagraph.Runs[APosition.RunIndex - 2].IsImage) then
        Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex - 2, LParagraph.Runs[APosition.RunIndex - 2].Text.Length))
      else
        Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex - 1, 0));
    end
    else
      // Skip the phantom (prevRun, prevRun.Length) -- visually identical to (curRun, 0).
      Exit(PreviousDocumentPosition(TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex - 1, LPreviousRun.Text.Length)));
  end;
  if APosition.ParagraphIndex > 0 then
  begin
    LPreviousParagraph := FDocument.Paragraphs[APosition.ParagraphIndex - 1];
    if LPreviousParagraph.Runs.Count = 0 then
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex - 1, 0, 0));
    LRunIndex := LPreviousParagraph.Runs.Count - 1;
    if LPreviousParagraph.Runs[LRunIndex].IsPlaceholder or LPreviousParagraph.Runs[LRunIndex].IsImage then
    begin
      if LPreviousParagraph.Runs[LRunIndex].IsImage then
        LPreviousRightIndex := 1
      else
        LPreviousRightIndex := LPreviousParagraph.Runs[LRunIndex].Text.Length;
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex - 1, LRunIndex, LPreviousRightIndex));
    end
    else
      Exit(TS4YDocumentPosition.At(APosition.ParagraphIndex - 1, LRunIndex, LPreviousParagraph.Runs[LRunIndex].Text.Length));
  end;
  Result := APosition;
end;

function TS4YHTMLEditor.LineStart(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
var
  LFragmentIndex: Integer;
  LLineIndex: Integer;
  LLine: TS4YLayoutLine;
begin
  LFragmentIndex := FragmentIndexAt(APosition.ParagraphIndex, APosition.RunIndex, APosition.CharIndex);
  if LFragmentIndex < 0 then
    Exit(APosition);
  LLineIndex := FFrags[LFragmentIndex].LineIndex;
  if (LLineIndex < 0) or (LLineIndex >= Length(FLines)) then
    Exit(APosition);
  LLine := FLines[LLineIndex];
  for var I := LLine.FragmentStart to LLine.FragmentStart + LLine.FragmentCount - 1 do
    if not FFrags[I].IsHR and (not FFrags[I].IsImage or (FFrags[I].RunIndex >= 0)) then
      Exit(TS4YDocumentPosition.At(FFrags[I].ParagraphIndex, FFrags[I].RunIndex, FFrags[I].CharStart));
  Result := APosition;
end;

function TS4YHTMLEditor.LineEnd(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
var
  LFragmentIndex: Integer;
  LLineIndex: Integer;
  LLine: TS4YLayoutLine;
begin
  LFragmentIndex := FragmentIndexAt(APosition.ParagraphIndex, APosition.RunIndex, APosition.CharIndex);
  if LFragmentIndex < 0 then
    Exit(APosition);
  LLineIndex := FFrags[LFragmentIndex].LineIndex;
  if (LLineIndex < 0) or (LLineIndex >= Length(FLines)) then
    Exit(APosition);
  LLine := FLines[LLineIndex];
  for var I := LLine.FragmentStart + LLine.FragmentCount - 1 downto LLine.FragmentStart do
    if not FFrags[I].IsHR and (not FFrags[I].IsImage or (FFrags[I].RunIndex >= 0)) then
      Exit(TS4YDocumentPosition.At(FFrags[I].ParagraphIndex, FFrags[I].RunIndex, FFrags[I].CharEnd));
  Result := APosition;
end;

function TS4YHTMLEditor.LineAbove(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
var
  LFragmentIndex: Integer;
  LLineIndex: Integer;
  LXPosition, LYPosition, LHeight: Single;
  LDocumentX: Single;
  LLineY: Single;
  LCurrentCell: TS4YHTMLParagraph;
  LTargetPI: Integer;
  LSearchI: Integer;
begin
  Result := APosition;
  LFragmentIndex := FragmentIndexAt(APosition.ParagraphIndex, APosition.RunIndex, APosition.CharIndex);
  if LFragmentIndex < 0 then
    Exit;
  LLineIndex := FFrags[LFragmentIndex].LineIndex - 1;

  if (APosition.ParagraphIndex < FDocument.Paragraphs.Count) and
     FDocument.Paragraphs[APosition.ParagraphIndex].IsTableCell then
  begin
    LCurrentCell := FDocument.Paragraphs[APosition.ParagraphIndex];

    // Within-cell: LLineIndex still belongs to this cell
    if (LLineIndex >= 0) and FDocument.Paragraphs[FLines[LLineIndex].ParagraphIndex].IsInCell(LCurrentCell.TableID,
         LCurrentCell.TableRow, LCurrentCell.TableCol) then
    begin
      if not DocumentPositionToXY(APosition, LXPosition, LYPosition, LHeight) then
        Exit;
      LDocumentX := LXPosition - ContentLeft;
      LLineY := FLines[LLineIndex].Y + FLines[LLineIndex].Height / 2;
      Result := HitTest(ContentLeft + LDocumentX, ContentTop + LLineY);
      Exit;
    end;

    // LLineIndex is outside this cell (sibling column or before document start).
    // Try to navigate to the row above in the same column.
    LTargetPI := -1;
    if LCurrentCell.TableRow > 0 then
      LTargetPI := FindTableCellAt(LCurrentCell.TableID, LCurrentCell.TableRow - 1, LCurrentCell.TableCol);

    if LTargetPI >= 0 then
    begin
      // Last line of the cell directly above
      LLineIndex := -1;
      LSearchI := High(FLines);
      while (LSearchI >= 0) and (LLineIndex < 0) do
      begin
        if FDocument.Paragraphs[FLines[LSearchI].ParagraphIndex].IsInCell(FDocument.Paragraphs[LTargetPI].TableID,
             FDocument.Paragraphs[LTargetPI].TableRow, FDocument.Paragraphs[LTargetPI].TableCol) then
          LLineIndex := LSearchI
        else
          Dec(LSearchI);
      end;
      if LLineIndex < 0 then
        Exit;
    end
    else
    begin
      // First row (or no row above found): exit table upward.
      // Find the paragraph immediately before the first cell of this table.
      LSearchI := 0;
      while (LSearchI < FDocument.Paragraphs.Count) and
            not (FDocument.Paragraphs[LSearchI].IsTableCell and
                 (FDocument.Paragraphs[LSearchI].TableID = LCurrentCell.TableID)) do
        Inc(LSearchI);
      if (LSearchI = 0) or (LSearchI >= FDocument.Paragraphs.Count) then
        Exit; // table starts at document beginning
      LTargetPI := LSearchI - 1;
      LLineIndex := -1;
      LSearchI := High(FLines);
      while (LSearchI >= 0) and (LLineIndex < 0) do
      begin
        if FLines[LSearchI].ParagraphIndex = LTargetPI then
          LLineIndex := LSearchI
        else
          Dec(LSearchI);
      end;
      if LLineIndex < 0 then
        Exit;
    end;
  end
  else
  begin
    if LLineIndex < 0 then
      Exit;
  end;

  if not DocumentPositionToXY(APosition, LXPosition, LYPosition, LHeight) then
    Exit;
  LDocumentX := LXPosition - ContentLeft;
  LLineY := FLines[LLineIndex].Y + FLines[LLineIndex].Height / 2;
  Result := HitTest(ContentLeft + LDocumentX, ContentTop + LLineY);
end;

function TS4YHTMLEditor.LineBelow(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
var
  LFragmentIndex: Integer;
  LLineIndex: Integer;
  LXPosition, LYPosition, LHeight: Single;
  LDocumentX: Single;
  LLineY: Single;
  LCurrentCell: TS4YHTMLParagraph;
  LTargetPI: Integer;
  LSearchI: Integer;
  LNeedRowBelow: Boolean;
begin
  Result := APosition;
  LFragmentIndex := FragmentIndexAt(APosition.ParagraphIndex, APosition.RunIndex, APosition.CharIndex);
  if LFragmentIndex < 0 then
    Exit;
  LLineIndex := FFrags[LFragmentIndex].LineIndex + 1;

  if (APosition.ParagraphIndex < FDocument.Paragraphs.Count) and
     FDocument.Paragraphs[APosition.ParagraphIndex].IsTableCell then
  begin
    LCurrentCell := FDocument.Paragraphs[APosition.ParagraphIndex];
    LNeedRowBelow := False;

    if LLineIndex >= Length(FLines) then
      LNeedRowBelow := True
    else if FDocument.Paragraphs[FLines[LLineIndex].ParagraphIndex].IsInCell(LCurrentCell.TableID,
              LCurrentCell.TableRow, LCurrentCell.TableCol) then
    begin
      // Within-cell navigation
      if not DocumentPositionToXY(APosition, LXPosition, LYPosition, LHeight) then
        Exit;
      LDocumentX := LXPosition - ContentLeft;
      LLineY := FLines[LLineIndex].Y + FLines[LLineIndex].Height / 2;
      Result := HitTest(ContentLeft + LDocumentX, ContentTop + LLineY);
      Exit;
    end
    else
      LNeedRowBelow := True; // LLineIndex is in a sibling column

    if LNeedRowBelow then
    begin
      // Try to find the cell in the row below, same column
      LTargetPI := FindTableCellAt(LCurrentCell.TableID, LCurrentCell.TableRow + LCurrentCell.TableRowSpan,
        LCurrentCell.TableCol);

      if LTargetPI >= 0 then
      begin
        // First line of the cell in the row below
        LLineIndex := -1;
        LSearchI := 0;
        while (LSearchI < Length(FLines)) and (LLineIndex < 0) do
        begin
          if FLines[LSearchI].ParagraphIndex = LTargetPI then
            LLineIndex := LSearchI
          else
            Inc(LSearchI);
        end;
        if LLineIndex < 0 then
          Exit;
      end
      else
      begin
        // Last row: exit table downward.
        // Find the paragraph immediately after the last cell of this table.
        LSearchI := FDocument.Paragraphs.Count - 1;
        while (LSearchI >= 0) and not FDocument.Paragraphs[LSearchI].BelongsToTable(LCurrentCell.TableID) do
          Dec(LSearchI);
        if (LSearchI < 0) or (LSearchI + 1 >= FDocument.Paragraphs.Count) then
          Exit; // table ends at document end
        LTargetPI := LSearchI + 1;
        LLineIndex := -1;
        LSearchI := 0;
        while (LSearchI < Length(FLines)) and (LLineIndex < 0) do
        begin
          if FLines[LSearchI].ParagraphIndex = LTargetPI then
            LLineIndex := LSearchI
          else
            Inc(LSearchI);
        end;
        if LLineIndex < 0 then
          Exit;
      end;
    end;
  end
  else
  begin
    if LLineIndex >= Length(FLines) then
      Exit;
  end;

  if not DocumentPositionToXY(APosition, LXPosition, LYPosition, LHeight) then
    Exit;
  LDocumentX := LXPosition - ContentLeft;
  LLineY := FLines[LLineIndex].Y + FLines[LLineIndex].Height / 2;
  Result := HitTest(ContentLeft + LDocumentX, ContentTop + LLineY);
end;

function TS4YHTMLEditor.WordRight(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
var
  LCurrent: TS4YDocumentPosition;
  LParagraph: TS4YHTMLParagraph;
  LNext: TS4YDocumentPosition;
  LKeepScanning: Boolean;
begin
  LCurrent := APosition;
  LKeepScanning := True;
  while LKeepScanning and (PositionCompare(LCurrent, DocumentEnd) < 0) do
  begin
    LNext := NextDocumentPosition(LCurrent);
    if LNext.Equals(LCurrent) then
    begin
      LKeepScanning := False;
    end
    else
    begin
      LParagraph := FDocument.Paragraphs[LCurrent.ParagraphIndex];
      if (LCurrent.RunIndex < LParagraph.Runs.Count) and (LCurrent.CharIndex < LParagraph.Runs[LCurrent.RunIndex].Text.Length) and
         (LParagraph.Runs[LCurrent.RunIndex].Text[Low(string) + LCurrent.CharIndex] <> ' ') then
      begin
        LCurrent := LNext;
      end
      else
      begin
        LKeepScanning := False;
      end;
    end;
  end;
  LKeepScanning := True;
  while LKeepScanning and (PositionCompare(LCurrent, DocumentEnd) < 0) do
  begin
    LNext := NextDocumentPosition(LCurrent);
    if LNext.Equals(LCurrent) then
    begin
      LKeepScanning := False;
    end
    else
    begin
      LParagraph := FDocument.Paragraphs[LCurrent.ParagraphIndex];
      if (LCurrent.RunIndex < LParagraph.Runs.Count) and (LCurrent.CharIndex < LParagraph.Runs[LCurrent.RunIndex].Text.Length) and
         (LParagraph.Runs[LCurrent.RunIndex].Text[Low(string) + LCurrent.CharIndex] = ' ') then
      begin
        LCurrent := LNext;
      end
      else
      begin
        LKeepScanning := False;
      end;
    end;
  end;
  Result := LCurrent;
end;

function TS4YHTMLEditor.WordLeft(const APosition: TS4YDocumentPosition): TS4YDocumentPosition;
var
  LCurrent: TS4YDocumentPosition;
  LPrevious: TS4YDocumentPosition;
  LParagraph: TS4YHTMLParagraph;
  LCharacter: String;
  LKeepScanning: Boolean;
begin
  LCurrent := PreviousDocumentPosition(APosition);
  LKeepScanning := True;
  while LKeepScanning and (PositionCompare(LCurrent, DocumentStart) > 0) do
  begin
    LPrevious := PreviousDocumentPosition(LCurrent);
    LParagraph := FDocument.Paragraphs[LCurrent.ParagraphIndex];
    if (LCurrent.RunIndex < LParagraph.Runs.Count) and (LCurrent.CharIndex > 0) and (LCurrent.CharIndex <= LParagraph.Runs[LCurrent.RunIndex].Text.Length)
    then
    begin
      LCharacter := LParagraph.Runs[LCurrent.RunIndex].Text[Low(string) + LCurrent.CharIndex - 1];
      if LCharacter = ' ' then
      begin
        LCurrent := LPrevious;
      end
      else
      begin
        LKeepScanning := False;
      end;
    end
    else
    begin
      LKeepScanning := False;
    end;
  end;
  LKeepScanning := True;
  while LKeepScanning and (PositionCompare(LCurrent, DocumentStart) > 0) do
  begin
    LPrevious := PreviousDocumentPosition(LCurrent);
    LParagraph := FDocument.Paragraphs[LPrevious.ParagraphIndex];
    if (LPrevious.RunIndex < LParagraph.Runs.Count) and (LPrevious.CharIndex >= 0) and
      (LPrevious.CharIndex < LParagraph.Runs[LPrevious.RunIndex].Text.Length) then
    begin
      LCharacter := LParagraph.Runs[LPrevious.RunIndex].Text[Low(string) + LPrevious.CharIndex];
      if LCharacter = ' ' then
      begin
        LKeepScanning := False;
      end
      else
      begin
        LCurrent := LPrevious;
      end;
    end
    else
    begin
      LKeepScanning := False;
    end;
  end;
  Result := LCurrent;
end;

// -- Mouse ---------------------------------------------------------------------

procedure TS4YHTMLEditor.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LHitPosition: TS4YDocumentPosition;
  LElapsedMs: Int64;
  LDist2: Single;
  LSavedScrollY: Single;
  LClickParagraph: TS4YHTMLParagraph;
  LBorderTableID: Integer;
  LBorderBoundary: Integer;
begin
  // Save scroll as the VERY FIRST operation: TControl.MouseDown (inherited) calls
  // SetFocusedControl -> DoEnter -> DoLayout -> EnsureCaretVisible and resets
  // FScrollY to show DocumentStart.  SetFocus may do the same if inherited did not.
  // We restore FScrollY after all potentially-scrolling operations so that
  // HitTest maps screen coordinates to the correct document position.
  LSavedScrollY := FScrollY;
  inherited;
  SetFocus;
  if Length(FFrags) = 0 then
    DoLayout;
  ScrollTo(LSavedScrollY);
  FCaretAtImageRight := False;
  // A click on the border between two columns grabs it instead of moving the caret
  if (Button = TMouseButton.mbLeft) and not FReadOnly and
     FindColumnBorderAt(X - ContentLeft, Y - ContentTop, LBorderTableID, LBorderBoundary) then
  begin
    StartColumnResize(LBorderTableID, LBorderBoundary, X - ContentLeft);
    Exit;
  end;
  LHitPosition := HitTest(X, Y);
  FMouseDownPosition := LHitPosition;
  FClickedLinkURL := '';
  FClickedLinkText := '';
  if Button = TMouseButton.mbLeft then
  begin
    FClickedLinkURL := LinkURLAt(X, Y);
    FClickedLinkText := LinkTextForURL(LHitPosition, FClickedLinkURL);
  end;

  if Button = TMouseButton.mbLeft then
  begin
    LElapsedMs := Round(Abs(Now - FLastClickTime) * 86400000.0);
    LDist2 := Sqr(X - FLastClickPt.X) + Sqr(Y - FLastClickPt.Y);
    if (LElapsedMs <= C_TRIPLE_CLICK_MS) and (LDist2 <= C_CLICK_DIST_2) then
      Inc(FClickSeq)
    else
      FClickSeq := 1;
    FLastClickTime := Now;
    FLastClickPt := TPointF.Create(X, Y);

    if FClickSeq = 3 then
    begin
      FClickSeq := 0;
      FDragging := False;
      SelectParagraphAt(LHitPosition);
      Exit;
    end;
    if (FClickSeq = 2) or (ssDouble in Shift) then
    begin
      FDragging := False;
      SelectWordAt(LHitPosition);
      Exit;
    end;

    if not (ssShift in Shift) and LHitPosition.IsValid and
       (LHitPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
    begin
      LClickParagraph := FDocument.Paragraphs[LHitPosition.ParagraphIndex];
      if (LHitPosition.RunIndex >= 0) and (LHitPosition.RunIndex < LClickParagraph.Runs.Count) and
         LClickParagraph.Runs[LHitPosition.RunIndex].IsImage then
      begin
        FDragging := False;
        SelectWordAt(LHitPosition);
        Exit;
      end;
    end;
  end;

  FDragging := True;
  MoveCaretPosition(LHitPosition, ssShift in Shift);
end;

function IsWordChar(const AChar: Char): Boolean; inline;
begin
  Result := AChar.IsLetterOrDigit or (AChar = '_');
end;

// Returns the character to the right of caret position P (#0 if none / not text).
function TS4YHTMLEditor.CharAtPosition(const APosition: TS4YDocumentPosition): Char;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
begin
  Result := #0;
  if not APosition.IsValid or (APosition.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[APosition.ParagraphIndex];
  if APosition.RunIndex >= LParagraph.Runs.Count then
    Exit;
  LRun := LParagraph.Runs[APosition.RunIndex];
  if LRun.IsLineBreak or LRun.IsPlaceholder or LRun.IsImage or (APosition.CharIndex >= LRun.Text.Length) then
    Exit;
  Result := LRun.Text.Chars[APosition.CharIndex];
end;

procedure TS4YHTMLEditor.SelectWordAt(const APosition: TS4YDocumentPosition);
var
  LParagraph: TS4YHTMLParagraph;
  LWordStart, LWordEnd: TS4YDocumentPosition;
  LCurrent: TS4YDocumentPosition;
  LRun: TS4YHTMLRun;
  LAnchor: TS4YDocumentPosition;
  LPreviousPosition: TS4YDocumentPosition;
  LKeepScanning: Boolean;
begin
  if not APosition.IsValid or (APosition.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[APosition.ParagraphIndex];

  if (APosition.RunIndex < LParagraph.Runs.Count) and
     (LParagraph.Runs[APosition.RunIndex].IsPlaceholder or LParagraph.Runs[APosition.RunIndex].IsImage) then
  begin
    LRun := LParagraph.Runs[APosition.RunIndex];
    FSelectionStart := TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex, 0);
    FSelectionEnd := TS4YDocumentPosition.At(APosition.ParagraphIndex, APosition.RunIndex, LRun.Text.Length);
    FHasSelection := True;
    FCaretPosition := FSelectionEnd;
    FCaretOn := True;
    FInsertStyleSet := False;
    UpdateCaretXY;
    EnsureCaretVisible;
    InvalidateRender;
    DoNotifyState;
    Exit;
  end;

  LAnchor := APosition;
  if not IsWordChar(CharAtPosition(LAnchor)) then
  begin
    LPreviousPosition := PreviousDocumentPosition(LAnchor);
    if (LPreviousPosition.ParagraphIndex = APosition.ParagraphIndex) and IsWordChar(CharAtPosition(LPreviousPosition)) then
      LAnchor := LPreviousPosition
    else
      Exit;
  end;

  LWordStart := LAnchor;
  LKeepScanning := True;
  while LKeepScanning do
  begin
    LCurrent := PreviousDocumentPosition(LWordStart);
    if LCurrent.Equals(LWordStart) or
       (LCurrent.ParagraphIndex <> APosition.ParagraphIndex) or
       not IsWordChar(CharAtPosition(LCurrent)) then
    begin
      LKeepScanning := False;
    end
    else
    begin
      LWordStart := LCurrent;
    end;
  end;

  LWordEnd := LAnchor;
  LKeepScanning := True;
  while LKeepScanning and IsWordChar(CharAtPosition(LWordEnd)) do
  begin
    LWordEnd := NextDocumentPosition(LWordEnd);
    if LWordEnd.ParagraphIndex <> APosition.ParagraphIndex then
      LKeepScanning := False;
  end;

  if PositionCompare(LWordStart, LWordEnd) = 0 then
    Exit;
  FSelectionStart := LWordStart;
  FSelectionEnd := LWordEnd;
  FHasSelection := True;
  FCaretPosition := LWordEnd;
  FCaretOn := True;
  FInsertStyleSet := False;
  UpdateCaretXY;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.SelectParagraphAt(const APosition: TS4YDocumentPosition);
var
  LParagraph: TS4YHTMLParagraph;
  LWordStart, LWordEnd: TS4YDocumentPosition;
  LRunIndex: Integer;
begin
  if not APosition.IsValid or (APosition.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[APosition.ParagraphIndex];

  LWordStart := TS4YDocumentPosition.At(APosition.ParagraphIndex, 0, 0);
  LWordEnd := LWordStart;
  LRunIndex := LParagraph.Runs.Count - 1;
  while (LRunIndex >= 0) and LParagraph.Runs[LRunIndex].IsLineBreak do
    Dec(LRunIndex);
  if LRunIndex >= 0 then
    LWordEnd := TS4YDocumentPosition.At(APosition.ParagraphIndex, LRunIndex, LParagraph.Runs[LRunIndex].Text.Length);

  if PositionCompare(LWordStart, LWordEnd) = 0 then
  begin
    FCaretPosition := LWordStart;
    ResetSelection;
    FCaretOn := True;
    FInsertStyleSet := False;
    UpdateCaretXY;
    EnsureCaretVisible;
    InvalidateRender;
    DoNotifyState;
    Exit;
  end;

  FSelectionStart := LWordStart;
  FSelectionEnd := LWordEnd;
  FHasSelection := True;
  FCaretPosition := LWordEnd;
  FCaretOn := True;
  FInsertStyleSet := False;
  UpdateCaretXY;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

// -- Context Menu --------------------------------------------------------------

procedure TS4YHTMLEditor.BuildContextMenu;
  procedure AddItem(const AText: string; ATag: Integer);
  var
    LMenuItem: TMenuItem;
  begin
    LMenuItem := TMenuItem.Create(FContextMenu);
    LMenuItem.Text := AText;
    LMenuItem.Tag := ATag;
    LMenuItem.OnClick := ContextMenuItemClick;
    FContextMenu.AddObject(LMenuItem);
  end;

  procedure AddSeparator;
  var
    LMenuItem: TMenuItem;
  begin
    LMenuItem := TMenuItem.Create(FContextMenu);
    LMenuItem.Text := '-';
    FContextMenu.AddObject(LMenuItem);
  end;

begin
  FContextMenu := TPopupMenu.Create(Self);
  FContextMenu.Stored := False;
  AddItem('Undo', C_CONTEXT_POPUP_ITEM_UNDO);
  AddItem('Redo', C_CONTEXT_POPUP_ITEM_REDO);
  AddSeparator;
  AddItem('Cut', C_CONTEXT_POPUP_ITEM_CUT);
  AddItem('Copy', C_CONTEXT_POPUP_ITEM_COPY);
  AddItem('Paste', C_CONTEXT_POPUP_ITEM_PASTE);
  AddSeparator;
  AddItem('Select All', C_CONTEXT_POPUP_ITEM_SELECT_ALL);
  PopupMenu := FContextMenu;
end;

procedure TS4YHTMLEditor.UpdateContextMenuState;
var
  LHasSelection, LCanUndo, LCanRedo, LCanPaste: Boolean;
  LClipSvc: IFMXClipboardService;
  LItem: TMenuItem;
  LValue: TValue;
begin
  LHasSelection := FHasSelection;
  LCanUndo := FUndoStack.Count > 0;
  LCanRedo := FRedoStack.Count > 0;
  LCanPaste := False;
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipSvc) then
  begin
    LValue := LClipSvc.GetClipboard;
    LCanPaste := (LValue.IsType<string> and (LValue.AsType<string> <> '')) or
      TS4YHTMLClipboard.HasImage;
  end;

  for var I := 0 to FContextMenu.ItemsCount - 1 do
  begin
    LItem := FContextMenu.Items[I];
    if LItem.Text <> '-' then
    begin
      case LItem.Tag of
        C_CONTEXT_POPUP_ITEM_UNDO:
          LItem.Enabled := LCanUndo and not FReadOnly;
        C_CONTEXT_POPUP_ITEM_REDO:
          LItem.Enabled := LCanRedo and not FReadOnly;
        C_CONTEXT_POPUP_ITEM_CUT:
          LItem.Enabled := LHasSelection and not FReadOnly;
        C_CONTEXT_POPUP_ITEM_COPY:
          LItem.Enabled := LHasSelection;
        C_CONTEXT_POPUP_ITEM_PASTE:
          LItem.Enabled := LCanPaste and not FReadOnly;
        C_CONTEXT_POPUP_ITEM_SELECT_ALL:
          LItem.Enabled := True;
      end;
    end;
  end;
end;

procedure TS4YHTMLEditor.ContextMenuItemClick(Sender: TObject);
begin
  case TMenuItem(Sender).Tag of
    C_CONTEXT_POPUP_ITEM_UNDO:
      Undo;
    C_CONTEXT_POPUP_ITEM_REDO:
      Redo;
    C_CONTEXT_POPUP_ITEM_CUT:
      Cut;
    C_CONTEXT_POPUP_ITEM_COPY:
      Copy;
    C_CONTEXT_POPUP_ITEM_PASTE:
      Paste;
    C_CONTEXT_POPUP_ITEM_SELECT_ALL:
      SelectAll;
  end;
end;

function TS4YHTMLEditor.ShowContextMenu(const ScreenPosition: TPointF): Boolean;
var
  LLocalPt: TPointF;
  LHitPosition: TS4YDocumentPosition;
  LParagraph: TS4YHTMLParagraph;
  LIsAtom: Boolean;
begin
  if not FHasSelection then
  begin
    LLocalPt := ScreenToLocal(ScreenPosition);
    if Length(FFrags) = 0 then
      DoLayout;
    LHitPosition := HitTest(LLocalPt.X, LLocalPt.Y);
    LIsAtom := LHitPosition.IsValid and
      (LHitPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
      (LHitPosition.RunIndex >= 0);
    if LIsAtom then
    begin
      LParagraph := FDocument.Paragraphs[LHitPosition.ParagraphIndex];
      LIsAtom := (LHitPosition.RunIndex < LParagraph.Runs.Count) and
        (LParagraph.Runs[LHitPosition.RunIndex].IsImage or LParagraph.Runs[LHitPosition.RunIndex].IsPlaceholder);
    end;
    if LIsAtom then
      SelectWordAt(LHitPosition)
    else
      SetCaretPosition(LHitPosition, False);
  end;
  UpdateContextMenuState;
  Result := inherited ShowContextMenu(ScreenPosition);
end;

procedure TS4YHTMLEditor.MouseMove(Shift: TShiftState; X, Y: Single);
var
  LHitPosition: TS4YDocumentPosition;
  LURL: String;
  LNewCursor: TCursor;
  LScrollStep: Single;
  LBorderTableID: Integer;
  LBorderBoundary: Integer;
begin
  inherited;
  if FIsResizingColumn then
  begin
    if ssLeft in Shift then
      ContinueColumnResize(X - ContentLeft)
    else
      FinishColumnResize;
    Exit;
  end;
  if FDragging and (ssLeft in Shift) then
  begin
    if Y < C_AUTO_SCROLL_ZONE then
    begin
      LScrollStep := (C_AUTO_SCROLL_ZONE - Y) / C_AUTO_SCROLL_ZONE * C_EDITOR_SCROLL_STEP;
      ScrollTo(FScrollY - Max(1.0, LScrollStep));
    end
    else if Y > Height - C_AUTO_SCROLL_ZONE then
    begin
      LScrollStep := (Y - (Height - C_AUTO_SCROLL_ZONE)) / C_AUTO_SCROLL_ZONE * C_EDITOR_SCROLL_STEP;
      ScrollTo(FScrollY + Max(1.0, LScrollStep));
    end;
    LHitPosition := HitTest(X, Y);
    if not LHitPosition.Equals(FCaretPosition) then
    begin
      if not FHasSelection then
      begin
        FHasSelection := True;
        FSelectionStart := FMouseDownPosition;
      end;
      FSelectionEnd := LHitPosition;
      FCaretPosition := LHitPosition;
      if PositionCompare(FSelectionStart, FSelectionEnd) = 0 then
        FHasSelection := False;
      UpdateCaretXY;
      InvalidateRender;
      DoNotifyState;
    end;
  end
  else if not FReadOnly and FindColumnBorderAt(X - ContentLeft, Y - ContentTop, LBorderTableID, LBorderBoundary) then
  begin
    FIsOverColumnBorder := True;
    Cursor := crSizeWE;
  end
  else
  begin
    if FIsOverColumnBorder then
    begin
      FIsOverColumnBorder := False;
      Cursor := crIBeam;
      FHoverLinkURL := '';
    end;
    LURL := LinkURLAt(X, Y);
    if LURL <> FHoverLinkURL then
    begin
      FHoverLinkURL := LURL;
      if LURL <> '' then
      begin
        LNewCursor := crHandPoint;
        if Assigned(FOnLinkHover) then
          FOnLinkHover(Self, LURL, LNewCursor);
        Cursor := LNewCursor;
      end
      else
        Cursor := crIBeam;
    end;
  end;
end;

procedure TS4YHTMLEditor.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;
  if FIsResizingColumn then
  begin
    FinishColumnResize;
    Exit;
  end;
  if (Button = TMouseButton.mbLeft) and (FClickedLinkURL <> '') and not FHasSelection and (LinkURLAt(X, Y) = FClickedLinkURL)
  then
  begin
    if Assigned(FOnLinkClick) then
      FOnLinkClick(Self, FClickedLinkURL, FClickedLinkText);
  end;
  FClickedLinkURL := '';
  FClickedLinkText := '';
  FDragging := False;
  Repaint;
end;

procedure TS4YHTMLEditor.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  inherited;
  ScrollTo(FScrollY - Sign(WheelDelta) * C_EDITOR_SCROLL_STEP);
  Handled := True;
end;

// -- Keyboard ------------------------------------------------------------------

procedure TS4YHTMLEditor.DialogKey(var Key: Word; Shift: TShiftState);
begin
  // FMX handles Tab (focus cycling) in the form before the focused control's
  // KeyDown: Tab inside a table cell must be taken here. IsFocused guards
  // against the form also offering DialogKey to non-focused controls.
  if (Key = vkTab) and IsFocused and DoTableTab(Shift) then
  begin
    Key := 0;
    Exit;
  end;
  inherited;
end;

function TS4YHTMLEditor.IsTableCellOf(AParagraphIndex, ATableID: Integer): Boolean;
begin
  Result := (AParagraphIndex >= 0) and (AParagraphIndex < FDocument.Paragraphs.Count) and
    FDocument.Paragraphs[AParagraphIndex].IsTableCell and
    (FDocument.Paragraphs[AParagraphIndex].TableID = ATableID);
end;

// True when both paragraphs belong to the same table cell.
function TS4YHTMLEditor.InSameTableCell(AFirstIndex, ASecondIndex: Integer): Boolean;
begin
  Result := (AFirstIndex >= 0) and (AFirstIndex < FDocument.Paragraphs.Count) and
    (ASecondIndex >= 0) and (ASecondIndex < FDocument.Paragraphs.Count) and
    FDocument.Paragraphs[AFirstIndex].IsTableCell and FDocument.Paragraphs[ASecondIndex].IsTableCell and
    (FDocument.Paragraphs[AFirstIndex].TableID = FDocument.Paragraphs[ASecondIndex].TableID) and
    (FDocument.Paragraphs[AFirstIndex].TableRow = FDocument.Paragraphs[ASecondIndex].TableRow) and
    (FDocument.Paragraphs[AFirstIndex].TableCol = FDocument.Paragraphs[ASecondIndex].TableCol);
end;

// True when the paragraph is in the cell of FCells, directly or inside a table nested in that cell.
function TS4YHTMLEditor.IsParagraphInLayoutCell(ACellIndex, AParagraphIndex: Integer): Boolean;
begin
  Result := (AParagraphIndex >= 0) and (AParagraphIndex < FDocument.Paragraphs.Count) and
    FDocument.Paragraphs[AParagraphIndex].IsInCell(FCells[ACellIndex].TableID, FCells[ACellIndex].Row,
      FCells[ACellIndex].Column);
end;

// True when both paragraphs are outside tables or in the same table cell: lists and merges never cross a cell.
function TS4YHTMLEditor.InSameBlockScope(AFirstIndex, ASecondIndex: Integer): Boolean;
begin
  Result := (FDocument.Paragraphs[AFirstIndex].IsTableCell = FDocument.Paragraphs[ASecondIndex].IsTableCell) and
    (not FDocument.Paragraphs[AFirstIndex].IsTableCell or InSameTableCell(AFirstIndex, ASecondIndex));
end;

// Finds the border between two columns of a table under a point of the document. The border that belongs to the
// innermost table wins. A cell that spans several columns hides the borders that it crosses.
function TS4YHTMLEditor.FindColumnBorderAt(ADocumentX, ADocumentY: Single; out ATableID, ABoundary: Integer): Boolean;
var
  LIndex: Integer;
  LBestDepth: Integer;
  LColumns: Integer;
  LAlignment: TS4YHTMLAlignment;
begin
  Result := False;
  ATableID := 0;
  ABoundary := 0;
  LBestDepth := -1;
  for LIndex := 0 to High(FCells) do
    if (ADocumentY >= FCells[LIndex].Y) and (ADocumentY < FCells[LIndex].Y + FCells[LIndex].Height) and
       (FCells[LIndex].Depth >= LBestDepth) then
    begin
      LColumns := FDocument.Paragraphs[FCells[LIndex].FirstParagraphIndex].TableCols;
      LAlignment := FDocument.Paragraphs[FCells[LIndex].FirstParagraphIndex].TableAlignment;
      // The right edge of the last column is the edge of the table, which stays where it is in a table on the right
      if ((FCells[LIndex].Column + FCells[LIndex].ColumnSpan < LColumns) or
          ((FCells[LIndex].Column + FCells[LIndex].ColumnSpan = LColumns) and (LAlignment <> haRight))) and
         (Abs(ADocumentX - (FCells[LIndex].X + FCells[LIndex].Width)) <= C_COLUMN_BORDER_TOLERANCE) then
      begin
        Result := True;
        ATableID := FCells[LIndex].TableID;
        ABoundary := FCells[LIndex].Column + FCells[LIndex].ColumnSpan;
        LBestDepth := FCells[LIndex].Depth;
      end
      else if ((FCells[LIndex].Column > 0) or ((FCells[LIndex].Column = 0) and (LAlignment = haRight))) and
              (Abs(ADocumentX - FCells[LIndex].X) <= C_COLUMN_BORDER_TOLERANCE) then
      begin
        Result := True;
        ATableID := FCells[LIndex].TableID;
        ABoundary := FCells[LIndex].Column;
        LBestDepth := FCells[LIndex].Depth;
      end;
    end;
end;

// The width in pixels of every column of the table, as the last layout gave it. A column edge that no cell
// starts or ends at (all the cells that cross it span columns) is placed between its neighbours.
function TS4YHTMLEditor.GetColumnWidths(ATableID: Integer): TArray<Single>;
var
  LIndex: Integer;
  LColumns: Integer;
  LEdges: TArray<Single>;
  LKnown: TArray<Boolean>;
  LPrevious: Integer;
  LNext: Integer;
begin
  LColumns := 0;
  for LIndex := 0 to High(FCells) do
    if FCells[LIndex].TableID = ATableID then
      LColumns := FDocument.Paragraphs[FCells[LIndex].FirstParagraphIndex].TableCols;
  SetLength(Result, LColumns);
  if LColumns < 1 then
    Exit;
  SetLength(LEdges, LColumns + 1);
  SetLength(LKnown, LColumns + 1);
  for LIndex := 0 to High(FCells) do
    if FCells[LIndex].TableID = ATableID then
    begin
      LEdges[FCells[LIndex].Column] := FCells[LIndex].X;
      LKnown[FCells[LIndex].Column] := True;
      if FCells[LIndex].Column + FCells[LIndex].ColumnSpan <= LColumns then
      begin
        LEdges[FCells[LIndex].Column + FCells[LIndex].ColumnSpan] := FCells[LIndex].X + FCells[LIndex].Width;
        LKnown[FCells[LIndex].Column + FCells[LIndex].ColumnSpan] := True;
      end;
    end;
  for LIndex := 0 to LColumns do
    if not LKnown[LIndex] then
    begin
      LPrevious := LIndex - 1;
      while (LPrevious > 0) and not LKnown[LPrevious] do
        Dec(LPrevious);
      LNext := LIndex + 1;
      while (LNext < LColumns) and not LKnown[LNext] do
        Inc(LNext);
      if (LPrevious >= 0) and (LNext <= LColumns) and LKnown[LPrevious] and LKnown[LNext] then
        LEdges[LIndex] := LEdges[LPrevious] + (LEdges[LNext] - LEdges[LPrevious]) * (LIndex - LPrevious) / (LNext - LPrevious);
    end;
  for LIndex := 0 to LColumns - 1 do
    Result[LIndex] := LEdges[LIndex + 1] - LEdges[LIndex];
end;

// Gives the cells of the table the widths of the columns: a percentage of the table when its width is not in
// pixels, so that the table keeps its proportions, and pixels otherwise.
procedure TS4YHTMLEditor.ApplyColumnWidths(ATableID: Integer; const AWidths: TArray<Single>);
var
  LIndex: Integer;
  LTotal: Single;
  LWidth: Single;
  LIsPixels: Boolean;
begin
  LTotal := 0;
  for LWidth in AWidths do
    LTotal := LTotal + LWidth;
  if LTotal <= 0 then
    Exit;
  LIsPixels := False;
  for LIndex := 0 to High(FCells) do
    if FCells[LIndex].TableID = ATableID then
      LIsPixels := FDocument.Paragraphs[FCells[LIndex].FirstParagraphIndex].TableWidth.Kind = tlkPixels;
  for LIndex := 0 to High(FCells) do
    if (FCells[LIndex].TableID = ATableID) and (FCells[LIndex].ColumnSpan = 1) and
       (FCells[LIndex].Column < Length(AWidths)) then
    begin
      LWidth := AWidths[FCells[LIndex].Column];
      if LIsPixels then
        FDocument.Paragraphs[FCells[LIndex].FirstParagraphIndex].TableCellWidth := TS4YTableLength.Pixels(Round(LWidth))
      else
        FDocument.Paragraphs[FCells[LIndex].FirstParagraphIndex].TableCellWidth :=
          TS4YTableLength.Percent(Round(LWidth / LTotal * 10000) / 100);
    end;
end;

// Gives the table a width: a percentage of its space, or pixels when the width of the table is in pixels. A maximum
// width that the new width goes past is dropped.
procedure TS4YHTMLEditor.ApplyTableWidth(ATableID: Integer; AWidth: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FDocument.Paragraphs.Count - 1 do
    if FDocument.Paragraphs[LIndex].TableID = ATableID then
    begin
      if FResizeIsPixels then
        FDocument.Paragraphs[LIndex].TableWidth := TS4YTableLength.Pixels(Round(AWidth))
      else
        FDocument.Paragraphs[LIndex].TableWidth :=
          TS4YTableLength.Percent(Round(AWidth / FResizeAvailableWidth * 10000) / 100);
      if (FDocument.Paragraphs[LIndex].TableMaximumWidth > 0) and (AWidth > FDocument.Paragraphs[LIndex].TableMaximumWidth) then
        FDocument.Paragraphs[LIndex].TableMaximumWidth := 0;
    end;
end;

procedure TS4YHTMLEditor.StartColumnResize(ATableID, ABoundary: Integer; AX: Single);
begin
  FIsResizingColumn := True;
  FIsResizeChanged := False;
  FResizeTableID := ATableID;
  FResizeBoundary := ABoundary;
  FResizeStartX := AX;
  FResizeStartWidths := GetColumnWidths(ATableID);
  FDragging := False;
  // The border at the start or at the end of the table changes the width of the whole table
  FIsResizingTable := (ABoundary = 0) or (ABoundary >= Length(FResizeStartWidths));
  if FIsResizingTable then
  begin
    FResizeAvailableWidth := 0;
    for var I := 0 to High(FCells) do
      if FCells[I].TableID = ATableID then
      begin
        FResizeAvailableWidth := FCells[I].TableAvailableWidth;
        FResizeTableAlignment := FDocument.Paragraphs[FCells[I].FirstParagraphIndex].TableAlignment;
        FResizeIsPixels := FDocument.Paragraphs[FCells[I].FirstParagraphIndex].TableWidth.Kind = tlkPixels;
      end;
  end;
end;

// Moves the border to the mouse: the column on its left grows and the one on its right shrinks by the same amount,
// each of them keeping at least C_MINIMUM_TABLE_COLUMN_WIDTH.
procedure TS4YHTMLEditor.ContinueColumnResize(AX: Single);
var
  LDelta: Single;
  LWidths: TArray<Single>;
  LSavedScrollY: Single;
  LStartWidth: Single;
  LNewWidth: Single;
  LFactor: Single;
  LWidth: Single;
begin
  if FIsResizingTable then
  begin
    // The edge that is dragged moves the table by the same amount in a table on the left, by half in a centered
    // table (it grows on both sides) and in the other direction in a table on the right (its left edge is dragged)
    LStartWidth := 0;
    for LWidth in FResizeStartWidths do
      LStartWidth := LStartWidth + LWidth;
    case FResizeTableAlignment of
      haCenter:
        LFactor := 2;
      haRight:
        LFactor := -1;
    else
      LFactor := 1;
    end;
    if FResizeAvailableWidth <= 0 then
      Exit;
    LNewWidth := LStartWidth + LFactor * (AX - FResizeStartX);
    LNewWidth := Max(LNewWidth, Length(FResizeStartWidths) * C_MINIMUM_TABLE_COLUMN_WIDTH);
    LNewWidth := Min(LNewWidth, FResizeAvailableWidth);
    if (Abs(LNewWidth - LStartWidth) < 0.5) and not FIsResizeChanged then
      Exit;
    if not FIsResizeChanged then
    begin
      SaveUndo;
      FIsResizeChanged := True;
    end;
    ApplyTableWidth(FResizeTableID, LNewWidth);
    LSavedScrollY := FScrollY;
    DoLayout;
    ScrollTo(LSavedScrollY);
    Exit;
  end;
  if (FResizeBoundary < 1) or (FResizeBoundary >= Length(FResizeStartWidths)) then
    Exit;
  LDelta := AX - FResizeStartX;
  LDelta := Max(LDelta, C_MINIMUM_TABLE_COLUMN_WIDTH - FResizeStartWidths[FResizeBoundary - 1]);
  LDelta := Min(LDelta, FResizeStartWidths[FResizeBoundary] - C_MINIMUM_TABLE_COLUMN_WIDTH);
  if (LDelta = 0) and not FIsResizeChanged then
    Exit;
  if not FIsResizeChanged then
  begin
    SaveUndo;
    FIsResizeChanged := True;
  end;
  LWidths := System.Copy(FResizeStartWidths);
  LWidths[FResizeBoundary - 1] := LWidths[FResizeBoundary - 1] + LDelta;
  LWidths[FResizeBoundary] := LWidths[FResizeBoundary] - LDelta;
  ApplyColumnWidths(FResizeTableID, LWidths);
  // DoLayout scrolls to the caret; the view must stay where the user is working
  LSavedScrollY := FScrollY;
  DoLayout;
  ScrollTo(LSavedScrollY);
end;

procedure TS4YHTMLEditor.FinishColumnResize;
begin
  FIsResizingColumn := False;
  if FIsResizeChanged then
  begin
    FIsResizeChanged := False;
    DoChanged;
    DoNotifyState;
  end;
end;

// Finds the cell of the table that covers a position of the grid, also when it starts in a previous row or column.
// Returns the index of its paragraph, or -1 when the position is empty.
function TS4YHTMLEditor.FindTableCellAt(ATableID, ARow, ACol: Integer): Integer;
var
  LParagraphIndex: Integer;
  LCell: TS4YHTMLParagraph;
begin
  Result := -1;
  for LParagraphIndex := 0 to FDocument.Paragraphs.Count - 1 do
  begin
    LCell := FDocument.Paragraphs[LParagraphIndex];
    if (Result < 0) and LCell.IsTableCell and (LCell.TableID = ATableID) and
       (LCell.TableRow <= ARow) and (ARow < LCell.TableRow + LCell.TableRowSpan) and
       (LCell.TableCol <= ACol) and (ACol < LCell.TableCol + LCell.TableColSpan) then
      Result := LParagraphIndex;
  end;
end;

// True when the table is nested in a cell of another table or has a table nested in one of its cells.
function TS4YHTMLEditor.TableHasNesting(ATableID: Integer): Boolean;
var
  LParagraphIndex: Integer;
begin
  Result := False;
  for LParagraphIndex := 0 to FDocument.Paragraphs.Count - 1 do
    if FDocument.Paragraphs[LParagraphIndex].BelongsToTable(ATableID) and
       ((FDocument.Paragraphs[LParagraphIndex].TableID <> ATableID) or
        FDocument.Paragraphs[LParagraphIndex].IsNestedTableCell) then
      Result := True;
end;

// True when at least one cell of the table covers more than one row or column.
function TS4YHTMLEditor.TableHasSpans(ATableID: Integer): Boolean;
var
  LParagraphIndex: Integer;
begin
  Result := False;
  for LParagraphIndex := 0 to FDocument.Paragraphs.Count - 1 do
    if IsTableCellOf(LParagraphIndex, ATableID) and
       ((FDocument.Paragraphs[LParagraphIndex].TableColSpan > 1) or (FDocument.Paragraphs[LParagraphIndex].TableRowSpan > 1)) then
      Result := True;
end;

// Moves the caret to the next/previous table cell. Returns False when Tab must
// keep its normal meaning (focus change): caret outside a table, Ctrl/Alt
// combinations, Shift+Tab in the first cell, Tab in the last cell when read-only.
function TS4YHTMLEditor.DoTableTab(AShift: TShiftState): Boolean;
var
  LCurrentParagraph: TS4YHTMLParagraph;
  LNewCell: TS4YHTMLParagraph;
  LTargetIndex: Integer;
  LTableID: Integer;
  LTableCols: Integer;
  LNewRow: Integer;
  LPreviousRow: Integer;
  LPreviousColumn: Integer;
begin
  Result := False;
  if not FCaretPosition.IsValid or (FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  if (AShift * [ssCtrl, ssAlt, ssCommand]) <> [] then
    Exit;
  LCurrentParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  if not LCurrentParagraph.IsTableCell then
    Exit;
  LTableID := LCurrentParagraph.TableID;

  if ssShift in AShift then
  begin
    // First paragraph of the previous cell: go back over the current cell, with the tables nested in it,
    // then over the cell that holds the paragraph before it
    LTargetIndex := FCaretPosition.ParagraphIndex;
    while (LTargetIndex > 0) and FDocument.Paragraphs[LTargetIndex - 1].IsInCell(LTableID, LCurrentParagraph.TableRow,
            LCurrentParagraph.TableCol) do
      Dec(LTargetIndex);
    Dec(LTargetIndex);
    if (LTargetIndex < 0) or not FDocument.Paragraphs[LTargetIndex].TryGetCellIn(LTableID, LPreviousRow, LPreviousColumn) then
      Exit;
    while (LTargetIndex > 0) and FDocument.Paragraphs[LTargetIndex - 1].IsInCell(LTableID, LPreviousRow,
            LPreviousColumn) do
      Dec(LTargetIndex);
    ResetSelection;
    SetCaretPosition(TS4YDocumentPosition.At(LTargetIndex, 0, 0), False);
    Result := True;
    Exit;
  end;

  // First paragraph of the next cell: skip the rest of the current cell, with the tables nested in it
  LTargetIndex := FCaretPosition.ParagraphIndex + 1;
  while (LTargetIndex < FDocument.Paragraphs.Count) and FDocument.Paragraphs[LTargetIndex].IsInCell(LTableID,
          LCurrentParagraph.TableRow, LCurrentParagraph.TableCol) do
    Inc(LTargetIndex);
  if IsTableCellOf(LTargetIndex, LTableID) then
  begin
    ResetSelection;
    SetCaretPosition(TS4YDocumentPosition.At(LTargetIndex, 0, 0), False);
    Result := True;
    Exit;
  end;

  // Last cell: Tab appends a new row
  if FReadOnly then
    Exit;
  ResetSelection;
  SaveUndo;
  LTableCols := LCurrentParagraph.TableCols;
  LNewRow := 0;
  for var I := 0 to FDocument.Paragraphs.Count - 1 do
    if IsTableCellOf(I, LTableID) and (FDocument.Paragraphs[I].TableRow > LNewRow) then
      LNewRow := FDocument.Paragraphs[I].TableRow;
  Inc(LNewRow);
  for var I := 0 to LTableCols - 1 do
  begin
    LNewCell := TS4YHTMLParagraph.Create;
    LNewCell.BlockType := btTableCell;
    LNewCell.TableID := LTableID;
    LNewCell.TableContainers := System.Copy(LCurrentParagraph.TableContainers);
    LNewCell.TableRow := LNewRow;
    LNewCell.TableCol := I;
    LNewCell.TableCols := LTableCols;
    LNewCell.CopyTableLayoutFrom(LCurrentParagraph);
    FDocument.Paragraphs.Insert(LTargetIndex + I, LNewCell);
  end;
  DoLayout;
  DoChanged;
  SetCaretPosition(TS4YDocumentPosition.At(LTargetIndex, 0, 0), False);
  Result := True;
end;

procedure TS4YHTMLEditor.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
var
  LExtend: Boolean;
  LNextParagraphIndex: Integer;
  LNewCaretPosition: TS4YDocumentPosition;
begin
  inherited;
  LExtend := ssShift in Shift;

  // Escape removes the selection; without one the key is left to the form (for example a cancel button)
  if Key = vkEscape then
  begin
    if FHasSelection then
    begin
      ClearSelection;
      Key := 0;
    end;
    Exit;
  end;

  // Printable char
  if (KeyChar >= ' ') and (KeyChar <> #0) then
  begin
    if not FReadOnly then
    begin
      if FHasSelection then
      begin
        SaveUndo;
        DeleteSelection;
      end
      else if not FInsertStyleSet then
        SaveUndo;
      InsertChar(KeyChar);
      FInsertStyleSet := False;
    end;
    Key := 0;
    KeyChar := #0;
    Exit;
  end;

  // Ctrl+letter shortcuts
  if ssCtrl in Shift then
  begin
    case UpCase(Chr(Key and $FF)) of
      'A':
        begin
          SelectAll;
          Key := 0;
          Exit;
        end;
      'B':
        begin
          // A read-only control ignores the shortcuts that change the document
          if not FReadOnly then
            ToggleBold;
          Key := 0;
          Exit;
        end;
      'I':
        begin
          if not FReadOnly then
            ToggleItalic;
          Key := 0;
          Exit;
        end;
      'U':
        begin
          if not FReadOnly then
            ToggleUnderline;
          Key := 0;
          Exit;
        end;
      'Z':
        begin
          if not FReadOnly then
            Undo;
          Key := 0;
          Exit;
        end;
      'Y':
        begin
          if not FReadOnly then
            Redo;
          Key := 0;
          Exit;
        end;
      'C':
        begin
          Copy;
          Key := 0;
          Exit;
        end;
      'X':
        begin
          if not FReadOnly then
            Cut;
          Key := 0;
          Exit;
        end;
      'V':
        begin
          if ssShift in Shift then
            PasteAsPlainText
          else
            Paste;
          Key := 0;
          Exit;
        end;
    end;
  end;

  case Key of
    vkBack:
      if not FReadOnly then
      begin
        SaveUndo;
        if FHasSelection then
          DeleteSelection
        else if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
                (FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType in [btImage, btHR]) and
                FCaretAtImageRight then
        begin
          LNewCaretPosition := PreviousDocumentPosition(FCaretPosition);
          FDocument.Paragraphs.Delete(FCaretPosition.ParagraphIndex);
          EnsureValidDocument;
          FCaretAtImageRight := False;
          FCaretPosition := LNewCaretPosition;
          if not FCaretPosition.IsValid then
            FCaretPosition := DocumentStart;
          DoLayout;
          DoChanged;
          InvalidateRender;
        end
        else
          DeleteBack;
      end;
    vkDelete:
      if not FReadOnly then
      begin
        SaveUndo;
        if FHasSelection then
          DeleteSelection
        else if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
                (FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType in [btImage, btHR]) and
                not FCaretAtImageRight then
        begin
          LNextParagraphIndex := FCaretPosition.ParagraphIndex;
          FDocument.Paragraphs.Delete(LNextParagraphIndex);
          EnsureValidDocument;
          FCaretAtImageRight := False;
          FCaretPosition := TS4YDocumentPosition.At(Min(LNextParagraphIndex, FDocument.Paragraphs.Count - 1), 0, 0);
          DoLayout;
          DoChanged;
          InvalidateRender;
        end
        else
          DeleteForward;
      end;
    vkReturn:
      if not FReadOnly then
      begin
        SaveUndo;
        if ssShift in Shift then
        begin
          if FHasSelection then
            DeleteSelection;
          InsertLineBreak;
        end
        else
        begin
          if FHasSelection then
            DeleteSelection;
          InsertParagraphBreak;
        end;
      end;
    vkLeft:
    begin
      if (not (ssCtrl in Shift)) and FCaretPosition.IsValid and
         (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
         (FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType in [btImage, btHR]) and
         FCaretAtImageRight then
      begin
        FCaretAtImageRight := False;
        UpdateCaretXY;
        EnsureCaretVisible;
        InvalidateRender;
        DoNotifyState;
      end
      else
      begin
        FCaretAtImageRight := False;
        if ssCtrl in Shift then
          MoveCaretPosition(WordLeft(FCaretPosition), LExtend)
        else
          MoveCaretPosition(PreviousDocumentPosition(FCaretPosition), LExtend);
      end;
    end;
    vkRight:
    begin
      if (not (ssCtrl in Shift)) and FCaretPosition.IsValid and
         (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
         (FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType in [btImage, btHR]) and
         not FCaretAtImageRight then
      begin
        FCaretAtImageRight := True;
        UpdateCaretXY;
        EnsureCaretVisible;
        InvalidateRender;
        DoNotifyState;
      end
      else
      begin
        FCaretAtImageRight := False;
        if ssCtrl in Shift then
          MoveCaretPosition(WordRight(FCaretPosition), LExtend)
        else
          MoveCaretPosition(NextDocumentPosition(FCaretPosition), LExtend);
      end;
    end;
    vkUp:
    begin
      LNewCaretPosition := LineAbove(FCaretPosition);
      FCaretAtImageRight := LNewCaretPosition.IsValid and
        (LNewCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
        (FDocument.Paragraphs[LNewCaretPosition.ParagraphIndex].BlockType in [btImage, btHR]);
      MoveCaretPosition(LNewCaretPosition, LExtend);
    end;
    vkDown:
    begin
      FCaretAtImageRight := False;
      MoveCaretPosition(LineBelow(FCaretPosition), LExtend);
    end;
    vkHome:
      if ssCtrl in Shift then
        MoveCaretPosition(DocumentStart, LExtend)
      else
        MoveCaretPosition(LineStart(FCaretPosition), LExtend);
    vkEnd:
      if ssCtrl in Shift then
        MoveCaretPosition(DocumentEnd, LExtend)
      else
        MoveCaretPosition(LineEnd(FCaretPosition), LExtend);
    vkPrior:
      ScrollTo(FScrollY - Height + C_EDITOR_PADDING);
    vkNext:
      ScrollTo(FScrollY + Height - C_EDITOR_PADDING);
  end;
  Key := 0;
end;

// -- Editing -------------------------------------------------------------------

function TS4YHTMLEditor.StyleAtCaret: TS4YHTMLTextStyle;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
begin
  if FInsertStyleSet then
  begin
    Result := FInsertStyle;
    Exit;
  end;
  // Style of character at (or just before) caret
  if not FCaretPosition.IsValid then
  begin
    Result.Init;
    Exit;
  end;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
  begin
    Result.Init;
    Exit;
  end;
  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  if (FCaretPosition.RunIndex >= 0) and (FCaretPosition.RunIndex < LParagraph.Runs.Count) then
  begin
    LRun := LParagraph.Runs[FCaretPosition.RunIndex];
    // Atoms always report their own style regardless of CharIndex
    if LRun.IsPlaceholder or LRun.IsImage then
    begin
      Result := LRun.Style;
      Exit;
    end;
    Result := LRun.Style;
    // If at start of run, try previous run's style
    if (FCaretPosition.CharIndex = 0) and (FCaretPosition.RunIndex > 0) then
      Result := LParagraph.Runs[FCaretPosition.RunIndex - 1].Style;
  end
  else
    Result.Init;
end;

procedure TS4YHTMLEditor.SplitRunAt(AParagraphIndex, ARunIndex, ACharIndex: Integer);
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LSecondRun: TS4YHTMLRun;
begin
  if AParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LParagraph := FDocument.Paragraphs[AParagraphIndex];
  if ARunIndex >= LParagraph.Runs.Count then
    Exit;
  LRun := LParagraph.Runs[ARunIndex];
  if LRun.IsLineBreak or LRun.IsPlaceholder or LRun.IsImage or (ACharIndex = 0) or (ACharIndex >= LRun.Text.Length) then
    Exit;
  LSecondRun := TS4YHTMLRun.Create;
  LSecondRun.Style := LRun.Style;
  LSecondRun.Text := LRun.Text.Substring(ACharIndex);
  LRun.Text := LRun.Text.Substring(0, ACharIndex);
  LParagraph.Runs.Insert(ARunIndex + 1, LSecondRun);
end;

procedure TS4YHTMLEditor.NormalizeRuns(AParagraphIndex: Integer);
var
  LParagraph: TS4YHTMLParagraph;
  LIndex: Integer;
  LFirstRun, LSecondRun: TS4YHTMLRun;
begin
  if AParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LParagraph := FDocument.Paragraphs[AParagraphIndex];
  LIndex := 0;
  while LIndex < LParagraph.Runs.Count - 1 do
  begin
    LFirstRun := LParagraph.Runs[LIndex];
    LSecondRun := LParagraph.Runs[LIndex + 1];
    if (not LFirstRun.IsLineBreak) and (not LSecondRun.IsLineBreak) and
       (not LFirstRun.IsPlaceholder) and (not LSecondRun.IsPlaceholder) and
       (not LFirstRun.IsImage) and (not LSecondRun.IsImage) and
       LFirstRun.Style.EqualsFormat(LSecondRun.Style) then
    begin
      LFirstRun.Text := LFirstRun.Text + LSecondRun.Text;
      LParagraph.Runs.Delete(LIndex + 1);
    end
    else
      Inc(LIndex);
  end;
  LIndex := 0;
  while LIndex < LParagraph.Runs.Count do
  begin
    if (not LParagraph.Runs[LIndex].IsLineBreak) and (not LParagraph.Runs[LIndex].IsImage) and (LParagraph.Runs[LIndex].Text = '') then
      LParagraph.Runs.Delete(LIndex)
    else
      Inc(LIndex);
  end;
end;

procedure TS4YHTMLEditor.InsertChar(AChar: Char);
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LTextStyle: TS4YHTMLTextStyle;
  LRunIndex: Integer;
  LNewRun: TS4YHTMLRun;
  LNewRun2: TS4YHTMLRun;
  LSegmentIndex3: Integer;
  LSegmentOffset3: Integer;
  LCurrentSegment3: Integer;
  LAccumulated3: Integer;
  LRunIndex2: Integer;
  LFound3: Boolean;
begin
  if not FCaretPosition.IsValid then
    Exit;
  EnsureValidDocument;
  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  LTextStyle := StyleAtCaret;

  if LParagraph.Runs.Count = 0 then
  begin
    LRun := TS4YHTMLRun.Create;
    LRun.Style := LTextStyle;
    LParagraph.Runs.Add(LRun);
    FCaretPosition.RunIndex := 0;
    FCaretPosition.CharIndex := 0;
  end
  else if FCaretPosition.RunIndex >= LParagraph.Runs.Count then
  begin
    LRunIndex := LParagraph.Runs.Count - 1;
    LRun := LParagraph.Runs[LRunIndex];
    FCaretPosition.RunIndex := LRunIndex;
    FCaretPosition.CharIndex := LRun.Text.Length;
  end
  else
    LRun := LParagraph.Runs[FCaretPosition.RunIndex];

  if LRun.IsPlaceholder or LRun.IsImage then
  begin
    LNewRun := TS4YHTMLRun.Create;
    LNewRun.Style := LTextStyle;
    LNewRun.Text := AChar;
    if FCaretPosition.CharIndex = 0 then
      LParagraph.Runs.Insert(FCaretPosition.RunIndex, LNewRun)
    else
    begin
      LParagraph.Runs.Insert(FCaretPosition.RunIndex + 1, LNewRun);
      Inc(FCaretPosition.RunIndex);
    end;
    FCaretPosition.CharIndex := 1;
  end
  else if LRun.IsLineBreak then
  begin
    LNewRun := TS4YHTMLRun.Create;
    LNewRun.Style := LTextStyle;
    LNewRun.Text := AChar;
    LParagraph.Runs.Insert(FCaretPosition.RunIndex, LNewRun);
    FCaretPosition.CharIndex := 1;
  end
  else
  begin
    if not LRun.Style.EqualsFormat(LTextStyle) then
    begin
      SplitRunAt(FCaretPosition.ParagraphIndex, FCaretPosition.RunIndex, FCaretPosition.CharIndex);
      if FCaretPosition.CharIndex = 0 then
      begin
        LNewRun := TS4YHTMLRun.Create;
        LNewRun.Style := LTextStyle;
        LNewRun.Text := AChar;
        LParagraph.Runs.Insert(FCaretPosition.RunIndex, LNewRun);
        FCaretPosition.CharIndex := 1;
      end
      else
      begin
        LNewRun2 := TS4YHTMLRun.Create;
        LNewRun2.Style := LTextStyle;
        LNewRun2.Text := AChar;
        LParagraph.Runs.Insert(FCaretPosition.RunIndex + 1, LNewRun2);
        Inc(FCaretPosition.RunIndex);
        FCaretPosition.CharIndex := 1;
      end;
    end
    else
    begin
      LRun.Text := LRun.Text.Substring(0, FCaretPosition.CharIndex) + AChar + LRun.Text.Substring(FCaretPosition.CharIndex);
      Inc(FCaretPosition.CharIndex);
    end;
  end;

  LSegmentIndex3 := 0;
  LSegmentOffset3 := FCaretPosition.CharIndex;
  for var LRunIndex3 := 0 to FCaretPosition.RunIndex - 1 do
    if LRunIndex3 < LParagraph.Runs.Count then
    begin
      if LParagraph.Runs[LRunIndex3].IsLineBreak or LParagraph.Runs[LRunIndex3].IsPlaceholder or LParagraph.Runs[LRunIndex3].IsImage then
      begin
        Inc(LSegmentIndex3);
        LSegmentOffset3 := FCaretPosition.CharIndex;
      end
      else
        Inc(LSegmentOffset3, LParagraph.Runs[LRunIndex3].Text.Length);
    end;

  NormalizeRuns(FCaretPosition.ParagraphIndex);

  LCurrentSegment3 := 0;
  LAccumulated3 := 0;
  FCaretPosition.RunIndex := 0;
  FCaretPosition.CharIndex := 0;
  LRunIndex2 := 0;
  LFound3 := False;
  while (LRunIndex2 < LParagraph.Runs.Count) and not LFound3 do
  begin
    if LParagraph.Runs[LRunIndex2].IsLineBreak or LParagraph.Runs[LRunIndex2].IsPlaceholder or LParagraph.Runs[LRunIndex2].IsImage then
    begin
      if LCurrentSegment3 = LSegmentIndex3 then
        LFound3 := True
      else
      begin
        Inc(LCurrentSegment3);
        LAccumulated3 := 0;
      end;
    end
    else if LCurrentSegment3 = LSegmentIndex3 then
    begin
      if LSegmentOffset3 <= LAccumulated3 + LParagraph.Runs[LRunIndex2].Text.Length then
      begin
        FCaretPosition.RunIndex := LRunIndex2;
        FCaretPosition.CharIndex := LSegmentOffset3 - LAccumulated3;
        LFound3 := True;
      end
      else
      begin
        Inc(LAccumulated3, LParagraph.Runs[LRunIndex2].Text.Length);
        FCaretPosition.RunIndex := LRunIndex2;
        FCaretPosition.CharIndex := LParagraph.Runs[LRunIndex2].Text.Length;
      end;
    end;
    Inc(LRunIndex2);
  end;

  if not FBatchMode then
  begin
    DoLayout;
    DoChanged;
    DoNotifyState;
    InvalidateRender;
  end;
end;

procedure TS4YHTMLEditor.InsertString(const AText: string);
begin
  if AText = '' then
    Exit;
  FBatchMode := True;
  try
    for var LCharacter in AText do
    begin
      case LCharacter of
        #13:
          ;
        #10:
          InsertParagraphBreak;
      else
        InsertChar(LCharacter);
      end;
    end;
  finally
    FBatchMode := False;
  end;
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.DeleteBack;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LRunIndex: Integer;
  LCharIndex: Integer;
  LPreviousCharIndex: Integer;
  LStep: Integer;
  LFirst, LLast: Integer;
  LNewRunIndex: Integer;
  LNewCharIndex: Integer;
begin
  if not FCaretPosition.IsValid then
    Exit;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
  begin
    FCaretPosition := DocumentEnd;
    Exit;
  end;
  if PositionCompare(FCaretPosition, DocumentStart) = 0 then
    Exit;
  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];

  if (LParagraph.Runs.Count = 0) or ((FCaretPosition.RunIndex = 0) and (FCaretPosition.CharIndex = 0)) then
  begin
    // Never merge table cells with adjacent paragraphs; the paragraphs of the same cell can be merged
    if LParagraph.IsTableCell and not InSameTableCell(FCaretPosition.ParagraphIndex - 1, FCaretPosition.ParagraphIndex) then
      Exit;

    // Backspace on empty list item -> strip list marker, keep indentation
    if (LParagraph.BlockType = btLI) and (LParagraph.Runs.Count = 0) then
    begin
      GetListBlockRange(LFirst, LLast);
      LParagraph.BlockType := btParagraph;
      if LFirst <= FCaretPosition.ParagraphIndex - 1 then
        RenumberListBlock(LFirst, FCaretPosition.ParagraphIndex - 1);
      if FCaretPosition.ParagraphIndex + 1 <= LLast then
        RenumberListBlock(FCaretPosition.ParagraphIndex + 1, LLast);
      DoLayout;
      DoChanged;
      UpdateCaretXY;
      FCaretOn := True;
      FCaretTimer.Enabled := False;
      FCaretTimer.Enabled := IsFocused;
      EnsureCaretVisible;
      InvalidateRender;
      DoNotifyState;
      Exit;
    end;

    // Backspace on empty indented paragraph -> decrease indentation
    if (LParagraph.BlockType = btParagraph) and (LParagraph.IndentLevel > 0) and (LParagraph.Runs.Count = 0) then
    begin
      LParagraph.IndentLevel := LParagraph.IndentLevel - 1;
      DoLayout;
      DoChanged;
      UpdateCaretXY;
      FCaretOn := True;
      FCaretTimer.Enabled := False;
      FCaretTimer.Enabled := IsFocused;
      EnsureCaretVisible;
      InvalidateRender;
      DoNotifyState;
      Exit;
    end;

    if FCaretPosition.ParagraphIndex > 0 then
    begin
      MergeWithPrevious(FCaretPosition.ParagraphIndex);
      DoLayout;
      DoChanged;
      InvalidateRender;
    end;
    Exit;
  end;

  LRunIndex := FCaretPosition.RunIndex;
  LCharIndex := FCaretPosition.CharIndex;
  if LRunIndex >= LParagraph.Runs.Count then
  begin
    LRunIndex := LParagraph.Runs.Count - 1;
    LCharIndex := LParagraph.Runs[LRunIndex].Text.Length;
  end;
  LRun := LParagraph.Runs[LRunIndex];

  if LCharIndex = 0 then
  begin
    FCaretPosition := PreviousDocumentPosition(FCaretPosition);
    DeleteForward;
    Exit;
  end;

  if LRun.IsPlaceholder or LRun.IsImage then
  begin
    if LRun.IsPlaceholder then
      FPlaceholders.Remove(LRun);
    LParagraph.Runs.Delete(LRunIndex);
    LNewRunIndex := Max(0, LRunIndex - 1);
    if LParagraph.Runs.Count = 0 then
    begin
      LNewRunIndex := 0;
      LNewCharIndex := 0;
    end
    else if LNewRunIndex < LParagraph.Runs.Count then
      LNewCharIndex := LParagraph.Runs[LNewRunIndex].Text.Length
    else
    begin
      LNewRunIndex := LParagraph.Runs.Count - 1;
      LNewCharIndex := LParagraph.Runs[LNewRunIndex].Text.Length;
    end;
    NormalizeRuns(FCaretPosition.ParagraphIndex);
    FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex, LNewRunIndex, LNewCharIndex);
    DoLayout;
    DoChanged;
    InvalidateRender;
    Exit;
  end
  else if LRun.IsLineBreak then
  begin
    LParagraph.Runs.Delete(LRunIndex);
    LPreviousCharIndex := 0;
    if LRunIndex > 0 then
      LPreviousCharIndex := LParagraph.Runs[LRunIndex - 1].Text.Length;
    FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex, Max(0, LRunIndex - 1), LPreviousCharIndex);
  end
  else
  begin
    LStep := 1;
    if (LCharIndex > 1) and LRun.Text[LCharIndex].IsLowSurrogate and LRun.Text[LCharIndex - 1].IsHighSurrogate then
      LStep := 2;
    LRun.Text := LRun.Text.Substring(0, LCharIndex - LStep) + LRun.Text.Substring(LCharIndex);
    FCaretPosition.CharIndex := LCharIndex - LStep;
  end;

  NormalizeRuns(FCaretPosition.ParagraphIndex);
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.DeleteForward;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LRunIndex: Integer;
  LCharIndex: Integer;
  LNextRun: TS4YHTMLRun;
  LStep: Integer;
  LNewRunIndex: Integer;
  LCaretAbsChar: Integer;
  LRemapCaret: Boolean;
begin
  if not FCaretPosition.IsValid then
    Exit;
  if PositionCompare(FCaretPosition, DocumentEnd) = 0 then
    Exit;
  LCaretAbsChar := 0;
  LRemapCaret := False;

  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];

  if LParagraph.Runs.Count = 0 then
  begin
    if FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count - 1 then
    begin
      MergeWithPrevious(FCaretPosition.ParagraphIndex + 1);
      DoLayout;
      DoChanged;
      InvalidateRender;
    end;
    Exit;
  end;

  LRunIndex := Min(FCaretPosition.RunIndex, LParagraph.Runs.Count - 1);
  LCharIndex := FCaretPosition.CharIndex;
  LRun := LParagraph.Runs[LRunIndex];

  if (LRun.IsPlaceholder or LRun.IsImage) and (LCharIndex < LRun.Text.Length) then
  begin
    if LRun.IsPlaceholder then
      FPlaceholders.Remove(LRun);
    LParagraph.Runs.Delete(LRunIndex);
    LNewRunIndex := Min(LRunIndex, Max(0, LParagraph.Runs.Count - 1));
    FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex, LNewRunIndex, 0);
    NormalizeRuns(FCaretPosition.ParagraphIndex);
    DoLayout;
    DoChanged;
    InvalidateRender;
    Exit;
  end
  else if LRun.IsLineBreak then
  begin
    // NormalizeRuns below can merge or drop the runs around the break (e.g. the empty
    // run after a trailing break): remember the caret as a character offset instead
    LCaretAbsChar := DocumentPositionToAbsChar(FCaretPosition);
    LRemapCaret := True;
    LParagraph.Runs.Delete(LRunIndex);
    if LRunIndex >= LParagraph.Runs.Count then
      LRunIndex := Max(0, LParagraph.Runs.Count - 1);
    FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex, LRunIndex, 0);
  end
  else if LCharIndex >= LRun.Text.Length then
  begin
    if LRunIndex + 1 < LParagraph.Runs.Count then
    begin
      LNextRun := LParagraph.Runs[LRunIndex + 1];
      if LNextRun.IsLineBreak then
        LParagraph.Runs.Delete(LRunIndex + 1)
      else
      begin
        LStep := 1;
        if (LNextRun.Text.Length > 1) and LNextRun.Text[1].IsHighSurrogate and LNextRun.Text[2].IsLowSurrogate then
          LStep := 2;
        LNextRun.Text := LNextRun.Text.Substring(LStep);
      end;
    end
    else
    begin
      if FCaretPosition.ParagraphIndex + 1 < FDocument.Paragraphs.Count then
        MergeWithPrevious(FCaretPosition.ParagraphIndex + 1);
    end;
  end
  else
  begin
    LStep := 1;
    if (LCharIndex < LRun.Text.Length - 1) and
       LRun.Text[LCharIndex + 1].IsHighSurrogate and LRun.Text[LCharIndex + 2].IsLowSurrogate then
      LStep := 2;
    LRun.Text := LRun.Text.Substring(0, LCharIndex) + LRun.Text.Substring(LCharIndex + LStep);
  end;

  NormalizeRuns(FCaretPosition.ParagraphIndex);
  if LRemapCaret then
    FCaretPosition := AbsCharToDocumentPosition(FCaretPosition.ParagraphIndex, LCaretAbsChar);
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.DeleteSelection;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LSelectionStartParagraphIndex, LSelectionEndParagraphIndex: Integer;
  LSelectionStartRunIndex, LSelectionEndRunIndex, LSelectionStartCharIndex, LSelectionEndCharIndex: Integer;
  LRun: TS4YHTMLRun;
  LParagraph: TS4YHTMLParagraph;
  LSRISplitWillHappen: Boolean;
  LDeleteFrom: Integer;
  LDeleteTo: Integer;
  LNewRunIndex: Integer;
  LMaximumCharIndex: Integer;
  LStartParagraph: TS4YHTMLParagraph;
  LSRunFrom: Integer;
  LEndParagraph: TS4YHTMLParagraph;
begin
  if not FHasSelection then
    Exit;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  if PositionCompare(LSelectionStart, LSelectionEnd) = 0 then
  begin
    ResetSelection;
    Exit;
  end;

  LSelectionStartParagraphIndex := LSelectionStart.ParagraphIndex;
  LSelectionStartRunIndex := LSelectionStart.RunIndex;
  LSelectionStartCharIndex := LSelectionStart.CharIndex;
  LSelectionEndParagraphIndex := LSelectionEnd.ParagraphIndex;
  LSelectionEndRunIndex := LSelectionEnd.RunIndex;
  LSelectionEndCharIndex := LSelectionEnd.CharIndex;

  if LSelectionStartParagraphIndex = LSelectionEndParagraphIndex then
  begin
    LParagraph := FDocument.Paragraphs[LSelectionStartParagraphIndex];

    LSRISplitWillHappen := (LSelectionStartRunIndex < LParagraph.Runs.Count) and (not LParagraph.Runs[LSelectionStartRunIndex].IsLineBreak) and (LSelectionStartCharIndex > 0) and
      (LSelectionStartCharIndex < LParagraph.Runs[LSelectionStartRunIndex].Text.Length);

    SplitRunAt(LSelectionStartParagraphIndex, LSelectionEndRunIndex, LSelectionEndCharIndex);

    if LSRISplitWillHappen and (LSelectionStartRunIndex <= LSelectionEndRunIndex) then
      Inc(LSelectionEndRunIndex);

    SplitRunAt(LSelectionStartParagraphIndex, LSelectionStartRunIndex, LSelectionStartCharIndex);

    LDeleteFrom := LSelectionStartRunIndex;
    if LSelectionStartCharIndex > 0 then
      Inc(LDeleteFrom);
    LDeleteTo := LSelectionEndRunIndex;

    for var I := LDeleteTo downto LDeleteFrom do
      if I < LParagraph.Runs.Count then
        LParagraph.Runs.Delete(I);
    NormalizeRuns(LSelectionStartParagraphIndex);
    LNewRunIndex := Min(LSelectionStartRunIndex, Max(0, LParagraph.Runs.Count - 1));
    LMaximumCharIndex := 0;
    if LParagraph.Runs.Count > 0 then
      LMaximumCharIndex := LParagraph.Runs[Min(LSelectionStartRunIndex, LParagraph.Runs.Count - 1)].Text.Length;
    FCaretPosition := TS4YDocumentPosition.At(LSelectionStartParagraphIndex, LNewRunIndex, Min(LSelectionStartCharIndex, LMaximumCharIndex));
  end
  else
  begin
    LStartParagraph := FDocument.Paragraphs[LSelectionStartParagraphIndex];
    SplitRunAt(LSelectionStartParagraphIndex, LSelectionStartRunIndex, LSelectionStartCharIndex);
    LSRunFrom := IfThen(LSelectionStartCharIndex > 0, LSelectionStartRunIndex + 1, LSelectionStartRunIndex);
    for var I := LStartParagraph.Runs.Count - 1 downto LSRunFrom do
      LStartParagraph.Runs.Delete(I);

    LEndParagraph := FDocument.Paragraphs[LSelectionEndParagraphIndex];
    SplitRunAt(LSelectionEndParagraphIndex, LSelectionEndRunIndex, LSelectionEndCharIndex);
    for var I := Min(LSelectionEndRunIndex, LEndParagraph.Runs.Count - 1) downto 0 do
      LEndParagraph.Runs.Delete(I);

    while LEndParagraph.Runs.Count > 0 do
    begin
      LRun := LEndParagraph.Runs[0];
      LEndParagraph.Runs.Extract(LRun);
      LStartParagraph.Runs.Add(LRun);
    end;

    for var I := LSelectionEndParagraphIndex downto LSelectionStartParagraphIndex + 1 do
      FDocument.Paragraphs.Delete(I);

    NormalizeRuns(LSelectionStartParagraphIndex);
    if LStartParagraph.IsEmpty then
    begin
      LStartParagraph.BlockType := btBodyText;
      LStartParagraph.IndentLevel := 0;
    end;
    FCaretPosition := TS4YDocumentPosition.At(LSelectionStartParagraphIndex, Min(LSelectionStartRunIndex, Max(0, LStartParagraph.Runs.Count - 1)), LSelectionStartCharIndex);
    if FCaretPosition.RunIndex >= LStartParagraph.Runs.Count then
      FCaretPosition.RunIndex := Max(0, LStartParagraph.Runs.Count - 1);
    if LStartParagraph.Runs.Count > 0 then
      FCaretPosition.CharIndex := Min(FCaretPosition.CharIndex, LStartParagraph.Runs[FCaretPosition.RunIndex].Text.Length)
    else
      FCaretPosition.CharIndex := 0;
  end;

  RebuildPlaceholderList;
  ResetSelection;
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

function TS4YHTMLEditor.GetSelectionHTML: string;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LTempDocument: TS4YHTMLDocument;
  LGenerator: TS4YHTMLGenerator;
  LParagraphIndex: Integer;
  LFirstParagraph: TS4YHTMLParagraph;
  LLastParagraph: TS4YHTMLParagraph;
begin
  Result := '';
  if not FHasSelection then
    Exit;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  if PositionCompare(LSelectionStart, LSelectionEnd) = 0 then
    Exit;
  LTempDocument := TS4YHTMLDocument.Create;
  LGenerator := TS4YHTMLGenerator.Create;
  try
    for LParagraphIndex := LSelectionStart.ParagraphIndex to LSelectionEnd.ParagraphIndex do
      LTempDocument.Paragraphs.Add(FDocument.Paragraphs[LParagraphIndex].Clone);
    // Trim end of last paragraph (skip non-text blocks -- they have no runs)
    LLastParagraph := LTempDocument.Paragraphs.Last;
    if not (LLastParagraph.BlockType in [btHR, btImage]) then
    begin
      if LSelectionEnd.RunIndex < LLastParagraph.Runs.Count then
      begin
        if LSelectionEnd.CharIndex < LLastParagraph.Runs[LSelectionEnd.RunIndex].Text.Length then
          LLastParagraph.Runs[LSelectionEnd.RunIndex].Text := LLastParagraph.Runs[LSelectionEnd.RunIndex].Text.Substring(0, LSelectionEnd.CharIndex);
        for var I := LLastParagraph.Runs.Count - 1 downto LSelectionEnd.RunIndex + 1 do
          LLastParagraph.Runs.Delete(I);
      end;
    end;
    // Trim start of first paragraph
    LFirstParagraph := LTempDocument.Paragraphs.First;
    if not (LFirstParagraph.BlockType in [btHR, btImage]) then
    begin
      if LSelectionStart.RunIndex < LFirstParagraph.Runs.Count then
      begin
        // Delete runs before LSelectionStart.RunIndex (high to low to avoid index shift)
        for var I := LSelectionStart.RunIndex - 1 downto 0 do
          LFirstParagraph.Runs.Delete(I);
        // Former LSelectionStart.RunIndex is now at index 0; trim its leading chars
        if (LSelectionStart.CharIndex > 0) and (LFirstParagraph.Runs.Count > 0) and
           not LFirstParagraph.Runs[0].IsLineBreak then
          LFirstParagraph.Runs[0].Text := LFirstParagraph.Runs[0].Text.Substring(LSelectionStart.CharIndex);
      end;
    end;
    Result := LGenerator.Generate(LTempDocument);
  finally
    LTempDocument.Free;
    LGenerator.Free;
  end;
end;

function TS4YHTMLEditor.GetSelectionText: string;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LParagraphIndex, LRunIndex, LCharIndex: Integer;
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LEndCharIndex: Integer;
begin
  Result := '';
  if not FHasSelection then
    Exit;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  LParagraphIndex := LSelectionStart.ParagraphIndex;
  LRunIndex := LSelectionStart.RunIndex;
  LCharIndex := LSelectionStart.CharIndex;
  while (PositionCompare(TS4YDocumentPosition.At(LParagraphIndex, LRunIndex, LCharIndex), LSelectionEnd) < 0) and
    (LParagraphIndex < FDocument.Paragraphs.Count) do
  begin
    LParagraph := FDocument.Paragraphs[LParagraphIndex];
    if LRunIndex >= LParagraph.Runs.Count then
    begin
      Result := Result + sLineBreak;
      Inc(LParagraphIndex);
      LRunIndex := 0;
      LCharIndex := 0;
    end
    else
    begin
      LRun := LParagraph.Runs[LRunIndex];
      LEndCharIndex := IfThen((LParagraphIndex = LSelectionEnd.ParagraphIndex) and (LRunIndex = LSelectionEnd.RunIndex), LSelectionEnd.CharIndex, LRun.Text.Length);
      if LRun.IsLineBreak then
        Result := Result + sLineBreak
      else
        Result := Result + LRun.Text.Substring(LCharIndex, LEndCharIndex - LCharIndex);
      LCharIndex := LEndCharIndex;
      if LCharIndex >= LRun.Text.Length then
      begin
        Inc(LRunIndex);
        LCharIndex := 0;
      end;
      if LRunIndex >= LParagraph.Runs.Count then
      begin
        if LParagraphIndex < LSelectionEnd.ParagraphIndex then
          Result := Result + sLineBreak;
        Inc(LParagraphIndex);
        LRunIndex := 0;
        LCharIndex := 0;
      end;
    end;
  end;
end;

function TS4YHTMLEditor.WordCount: Integer;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LFullText: string;
begin
  LFullText := '';
  for LParagraph in FDocument.Paragraphs do
  begin
    for LRun in LParagraph.Runs do
      if not LRun.IsImage and not LRun.IsLineBreak and not LRun.IsPlaceholder then
        LFullText := LFullText + LRun.Text;
    LFullText := LFullText + ' ';
  end;
  LFullText := LFullText.Trim;
  if LFullText = '' then
  begin
    Result := 0;
    Exit;
  end;
  Result := Length(LFullText.Split([' ', #9, #10, #13], TStringSplitOptions.ExcludeEmpty));
end;

function TS4YHTMLEditor.CharCount: Integer;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
begin
  Result := 0;
  for LParagraph in FDocument.Paragraphs do
    for LRun in LParagraph.Runs do
      if not LRun.IsImage and not LRun.IsLineBreak and not LRun.IsPlaceholder then
        Inc(Result, LRun.Text.Length);
end;

function TS4YHTMLEditor.ParagraphSearchText(AParagraphIndex: Integer): string;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
begin
  Result := '';
  if (AParagraphIndex < 0) or (AParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[AParagraphIndex];
  for LRun in LParagraph.Runs do
    if not LRun.IsImage and not LRun.IsLineBreak and not LRun.IsPlaceholder then
      Result := Result + LRun.Text;
end;

procedure TS4YHTMLEditor.SelectRange(const AStart, AEnd: TS4YDocumentPosition);
begin
  FSelectionStart := AStart;
  FSelectionEnd := AEnd;
  FHasSelection := PositionCompare(AStart, AEnd) <> 0;
  FCaretPosition := AEnd;
  FCaretOn := True;
  FCaretTimer.Enabled := False;
  FCaretTimer.Enabled := IsFocused;
  UpdateCaretXY;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

function TS4YHTMLEditor.FindNext(const AText: string; CaseSensitive: Boolean): Boolean;
var
  LFindText: string;
  LSearchFrom: TS4YDocumentPosition;
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFromParagraphIndex, LFromCharIndex: Integer;
  LParagraphIndex: Integer;
  LParagraphText, LSearchText: string;
  LMatchPosition: Integer;
  LFoundStart, LFoundEnd: TS4YDocumentPosition;
begin
  Result := False;
  if AText = '' then
    Exit;
  if FDocument.Paragraphs.Count = 0 then
    Exit;

  if CaseSensitive then
    LFindText := AText
  else
    LFindText := AText.ToUpper;

  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LSearchFrom := LSelectionEnd;
  end
  else
    LSearchFrom := FCaretPosition;

  if not LSearchFrom.IsValid then
    LSearchFrom := DocumentStart;

  LFromParagraphIndex := Max(0, Min(LSearchFrom.ParagraphIndex, FDocument.Paragraphs.Count - 1));
  LFromCharIndex := DocumentPositionToAbsChar(LSearchFrom);

  // Pass 1: from caret paragraph (at caret offset) forward to end
  for LParagraphIndex := LFromParagraphIndex to FDocument.Paragraphs.Count - 1 do
  begin
    LParagraphText := ParagraphSearchText(LParagraphIndex);
    if CaseSensitive then
      LSearchText := LParagraphText
    else
      LSearchText := LParagraphText.ToUpper;

    if LParagraphIndex = LFromParagraphIndex then
      LMatchPosition := LSearchText.IndexOf(LFindText, LFromCharIndex)
    else
      LMatchPosition := LSearchText.IndexOf(LFindText);

    if LMatchPosition >= 0 then
    begin
      LFoundStart := AbsCharToDocumentPosition(LParagraphIndex, LMatchPosition);
      LFoundEnd := AbsCharToDocumentPosition(LParagraphIndex, LMatchPosition + AText.Length, True);
      SelectRange(LFoundStart, LFoundEnd);
      Exit(True);
    end;
  end;

  // Pass 2: wrap -- from beginning to caret paragraph (exclusive)
  for LParagraphIndex := 0 to LFromParagraphIndex - 1 do
  begin
    LParagraphText := ParagraphSearchText(LParagraphIndex);
    if CaseSensitive then
      LSearchText := LParagraphText
    else
      LSearchText := LParagraphText.ToUpper;

    LMatchPosition := LSearchText.IndexOf(LFindText);
    if LMatchPosition >= 0 then
    begin
      LFoundStart := AbsCharToDocumentPosition(LParagraphIndex, LMatchPosition);
      LFoundEnd := AbsCharToDocumentPosition(LParagraphIndex, LMatchPosition + AText.Length, True);
      SelectRange(LFoundStart, LFoundEnd);
      Exit(True);
    end;
  end;

  // Pass 3: wrap -- same paragraph, any occurrence before the current offset
  LParagraphText := ParagraphSearchText(LFromParagraphIndex);
  if CaseSensitive then
    LSearchText := LParagraphText
  else
    LSearchText := LParagraphText.ToUpper;

  LMatchPosition := LSearchText.IndexOf(LFindText);
  if (LMatchPosition >= 0) and (LMatchPosition < LFromCharIndex) then
  begin
    LFoundStart := AbsCharToDocumentPosition(LFromParagraphIndex, LMatchPosition);
    LFoundEnd := AbsCharToDocumentPosition(LFromParagraphIndex, LMatchPosition + AText.Length, True);
    SelectRange(LFoundStart, LFoundEnd);
    Exit(True);
  end;
end;

function TS4YHTMLEditor.FindPrevious(const AText: string; CaseSensitive: Boolean): Boolean;
var
  LFindText: string;
  LSearchFrom: TS4YDocumentPosition;
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFromParagraphIndex, LFromCharIndex: Integer;
  LParagraphIndex: Integer;
  LParagraphText, LSearchText: string;
  LMatchPosition, LLastMatchPosition: Integer;
  LFoundStart, LFoundEnd: TS4YDocumentPosition;
begin
  Result := False;
  if AText = '' then
    Exit;
  if FDocument.Paragraphs.Count = 0 then
    Exit;

  if CaseSensitive then
    LFindText := AText
  else
    LFindText := AText.ToUpper;

  // Start searching just before the selection start (or caret)
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LSearchFrom := LSelectionStart;
  end
  else
    LSearchFrom := FCaretPosition;

  if not LSearchFrom.IsValid then
    LSearchFrom := DocumentEnd;

  LFromParagraphIndex := Max(0, Min(LSearchFrom.ParagraphIndex, FDocument.Paragraphs.Count - 1));
  LFromCharIndex := DocumentPositionToAbsChar(LSearchFrom);

  // Pass 1: current paragraph -- find the last occurrence strictly before caret
  LParagraphText := ParagraphSearchText(LFromParagraphIndex);
  if CaseSensitive then
    LSearchText := LParagraphText
  else
    LSearchText := LParagraphText.ToUpper;

  LLastMatchPosition := -1;
  LMatchPosition := LSearchText.IndexOf(LFindText);
  while (LMatchPosition >= 0) and (LMatchPosition < LFromCharIndex) do
  begin
    LLastMatchPosition := LMatchPosition;
    LMatchPosition := LSearchText.IndexOf(LFindText, LMatchPosition + 1);
  end;

  if LLastMatchPosition >= 0 then
  begin
    LFoundStart := AbsCharToDocumentPosition(LFromParagraphIndex, LLastMatchPosition);
    LFoundEnd := AbsCharToDocumentPosition(LFromParagraphIndex, LLastMatchPosition + AText.Length, True);
    SelectRange(LFoundStart, LFoundEnd);
    Exit(True);
  end;

  // Pass 2: paragraphs before caret (reversed)
  for LParagraphIndex := LFromParagraphIndex - 1 downto 0 do
  begin
    LParagraphText := ParagraphSearchText(LParagraphIndex);
    if CaseSensitive then
      LSearchText := LParagraphText
    else
      LSearchText := LParagraphText.ToUpper;

    LLastMatchPosition := LSearchText.LastIndexOf(LFindText);
    if LLastMatchPosition >= 0 then
    begin
      LFoundStart := AbsCharToDocumentPosition(LParagraphIndex, LLastMatchPosition);
      LFoundEnd := AbsCharToDocumentPosition(LParagraphIndex, LLastMatchPosition + AText.Length, True);
      SelectRange(LFoundStart, LFoundEnd);
      Exit(True);
    end;
  end;

  // Pass 3: wrap -- paragraphs after caret (reversed)
  for LParagraphIndex := FDocument.Paragraphs.Count - 1 downto LFromParagraphIndex + 1 do
  begin
    LParagraphText := ParagraphSearchText(LParagraphIndex);
    if CaseSensitive then
      LSearchText := LParagraphText
    else
      LSearchText := LParagraphText.ToUpper;

    LLastMatchPosition := LSearchText.LastIndexOf(LFindText);
    if LLastMatchPosition >= 0 then
    begin
      LFoundStart := AbsCharToDocumentPosition(LParagraphIndex, LLastMatchPosition);
      LFoundEnd := AbsCharToDocumentPosition(LParagraphIndex, LLastMatchPosition + AText.Length, True);
      SelectRange(LFoundStart, LFoundEnd);
      Exit(True);
    end;
  end;

  // Pass 4: wrap -- current paragraph, last occurrence at or after caret
  LParagraphText := ParagraphSearchText(LFromParagraphIndex);
  if CaseSensitive then
    LSearchText := LParagraphText
  else
    LSearchText := LParagraphText.ToUpper;

  LLastMatchPosition := LSearchText.LastIndexOf(LFindText);
  if (LLastMatchPosition >= 0) and (LLastMatchPosition >= LFromCharIndex) then
  begin
    LFoundStart := AbsCharToDocumentPosition(LFromParagraphIndex, LLastMatchPosition);
    LFoundEnd := AbsCharToDocumentPosition(LFromParagraphIndex, LLastMatchPosition + AText.Length, True);
    SelectRange(LFoundStart, LFoundEnd);
    Exit(True);
  end;
end;

function TS4YHTMLEditor.ReplaceAll(const AFindText, AReplaceText: string; CaseSensitive: Boolean): Integer;
var
  LFindText: string;
  LParagraphIndex: Integer;
  LParagraph: TS4YHTMLParagraph;
  LParagraphText, LSearchText: string;
  LRun: TS4YHTMLRun;
  LMatchPositions: TList<Integer>;
  LMatchPosition, LSearchStart: Integer;
  LMatchIndex: Integer;
  LStartPosition, LEndPosition: TS4YDocumentPosition;
  LSelectionStartRunIndex, LSelectionStartCharIndex, LSelectionEndRunIndex, LSelectionEndCharIndex: Integer;
  LSRISplitWillHappen: Boolean;
  LDeleteFrom, LDeleteTo, LIndex: Integer;
  LReplaceStyle: TS4YHTMLTextStyle;
  LNewRun: TS4YHTMLRun;
begin
  Result := 0;
  if AFindText = '' then
    Exit;

  if not CaseSensitive then
    LFindText := AFindText.ToUpper
  else
    LFindText := AFindText;

  SaveUndo;

  LMatchPositions := TList<Integer>.Create;
  try
    for LParagraphIndex := 0 to FDocument.Paragraphs.Count - 1 do
    begin
      LParagraph := FDocument.Paragraphs[LParagraphIndex];
      LParagraphText := '';
      for LRun in LParagraph.Runs do
        if not LRun.IsImage and not LRun.IsLineBreak and not LRun.IsPlaceholder then
          LParagraphText := LParagraphText + LRun.Text;

      if not CaseSensitive then
        LSearchText := LParagraphText.ToUpper
      else
        LSearchText := LParagraphText;

      // Collect all match positions in this paragraph
      LMatchPositions.Clear;
      LSearchStart := 0;
      LMatchPosition := LSearchText.IndexOf(LFindText, LSearchStart);
      while LMatchPosition >= 0 do
      begin
        LMatchPositions.Add(LMatchPosition);
        LSearchStart := LMatchPosition + LFindText.Length;
        LMatchPosition := LSearchText.IndexOf(LFindText, LSearchStart);
      end;

      // Process right-to-left so earlier offsets remain valid
      for LMatchIndex := LMatchPositions.Count - 1 downto 0 do
      begin
        LMatchPosition := LMatchPositions[LMatchIndex];
        LParagraph := FDocument.Paragraphs[LParagraphIndex]; // re-fetch; structure unchanged for this para
        LStartPosition := AbsCharToDocumentPosition(LParagraphIndex, LMatchPosition);
        LEndPosition := AbsCharToDocumentPosition(LParagraphIndex, LMatchPosition + AFindText.Length, True);

        LSelectionStartRunIndex := LStartPosition.RunIndex;
        LSelectionStartCharIndex := LStartPosition.CharIndex;
        LSelectionEndRunIndex := LEndPosition.RunIndex;
        LSelectionEndCharIndex := LEndPosition.CharIndex;

        // Capture style from the first matched run before any splits
        if LSelectionStartRunIndex < LParagraph.Runs.Count then
          LReplaceStyle := LParagraph.Runs[LSelectionStartRunIndex].Style
        else if LParagraph.Runs.Count > 0 then
          LReplaceStyle := LParagraph.Runs[LParagraph.Runs.Count - 1].Style
        else
          LReplaceStyle := StyleAtCaret;

        LSRISplitWillHappen := (LSelectionStartRunIndex < LParagraph.Runs.Count) and
          not LParagraph.Runs[LSelectionStartRunIndex].IsLineBreak and (LSelectionStartCharIndex > 0) and
          (LSelectionStartCharIndex < LParagraph.Runs[LSelectionStartRunIndex].Text.Length);

        SplitRunAt(LParagraphIndex, LSelectionEndRunIndex, LSelectionEndCharIndex);
        if LSRISplitWillHappen and (LSelectionStartRunIndex <= LSelectionEndRunIndex) then
          Inc(LSelectionEndRunIndex);
        SplitRunAt(LParagraphIndex, LSelectionStartRunIndex, LSelectionStartCharIndex);

        LDeleteFrom := LSelectionStartRunIndex;
        if LSelectionStartCharIndex > 0 then
          Inc(LDeleteFrom);
        LDeleteTo := LSelectionEndRunIndex;

        for LIndex := LDeleteTo downto LDeleteFrom do
          if LIndex < LParagraph.Runs.Count then
            LParagraph.Runs.Delete(LIndex);

        if AReplaceText <> '' then
        begin
          LNewRun := TS4YHTMLRun.Create;
          LNewRun.Text := AReplaceText;
          LNewRun.Style := LReplaceStyle;
          if LDeleteFrom <= LParagraph.Runs.Count then
            LParagraph.Runs.Insert(LDeleteFrom, LNewRun)
          else
            LParagraph.Runs.Add(LNewRun);
        end;

        NormalizeRuns(LParagraphIndex);
        Inc(Result);
      end;
    end;
  finally
    LMatchPositions.Free;
  end;

  if Result > 0 then
  begin
    RebuildPlaceholderList;
    ResetSelection;
    DoLayout;
    DoChanged;
    InvalidateRender;
    DoNotifyState;
  end;
end;

procedure TS4YHTMLEditor.ScrollToParagraph(AIndex: Integer);
var
  LLineIndex: Integer;
begin
  if (AIndex < 0) or (AIndex >= FDocument.Paragraphs.Count) then
    Exit;
  for LLineIndex := 0 to High(FLines) do
    if FLines[LLineIndex].ParagraphIndex = AIndex then
    begin
      ScrollTo(FLines[LLineIndex].Y);
      Exit;
    end;
end;

procedure TS4YHTMLEditor.ScrollToDocumentPosition(const APosition: TS4YDocumentPosition);
var
  LX, LY, LH: Single;
begin
  if DocumentPositionToXY(APosition, LX, LY, LH) then
    ScrollTo(LY - ContentTop);
end;

procedure TS4YHTMLEditor.InsertParagraphBreak;
var
  LParagraph, LNewParagraph: TS4YHTMLParagraph;
  LMoveFrom: Integer;
  LRun: TS4YHTMLRun;
  LNewParagraphIndex: Integer;
  LFirst, LLast: Integer;
begin
  if not FCaretPosition.IsValid then
    Exit;
  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];

  // Enter on empty list item -> exit the list (standard Word/Docs behavior)
  if (LParagraph.BlockType = btLI) and (LParagraph.Runs.Count = 0) then
  begin
    GetListBlockRange(LFirst, LLast);
    LParagraph.BlockType := btParagraph;
    LParagraph.IndentLevel := 0;
    if LFirst <= FCaretPosition.ParagraphIndex - 1 then
      RenumberListBlock(LFirst, FCaretPosition.ParagraphIndex - 1);
    if FCaretPosition.ParagraphIndex + 1 <= LLast then
      RenumberListBlock(FCaretPosition.ParagraphIndex + 1, LLast);
    FHasSelection := False;
    FSelectionStart := TS4YDocumentPosition.Invalid;
    FSelectionEnd := TS4YDocumentPosition.Invalid;
    if not FBatchMode then
    begin
      DoLayout;
      DoChanged;
      UpdateCaretXY;
      FCaretOn := True;
      FCaretTimer.Enabled := False;
      FCaretTimer.Enabled := IsFocused;
      EnsureCaretVisible;
      InvalidateRender;
      DoNotifyState;
    end;
    Exit;
  end;

  SplitRunAt(FCaretPosition.ParagraphIndex, FCaretPosition.RunIndex, FCaretPosition.CharIndex);

  LNewParagraph := TS4YHTMLParagraph.Create;
  if LParagraph.BlockType in [btH1 .. btH6] then
  begin
    if LParagraph.IsTableCell then
      LNewParagraph.BlockType := btTableCell
    else
      LNewParagraph.BlockType := btParagraph;
  end
  else
    LNewParagraph.BlockType := LParagraph.BlockType;
  LNewParagraph.Alignment := LParagraph.Alignment;
  LNewParagraph.IndentLevel := LParagraph.IndentLevel;
  LNewParagraph.ListOrdered := LParagraph.ListOrdered;
  if LParagraph.IsTableCell then
  begin
    // The new paragraph joins the cell; the first paragraph keeps the spans of the cell
    LNewParagraph.TableID := LParagraph.TableID;
    LNewParagraph.TableRow := LParagraph.TableRow;
    LNewParagraph.TableCol := LParagraph.TableCol;
    LNewParagraph.TableCols := LParagraph.TableCols;
    LNewParagraph.IsHeader := LParagraph.IsHeader;
  end;

  LMoveFrom := IfThen(FCaretPosition.CharIndex > 0, FCaretPosition.RunIndex + 1, FCaretPosition.RunIndex);
  while LMoveFrom < LParagraph.Runs.Count do
  begin
    LRun := LParagraph.Runs[LMoveFrom];
    LParagraph.Runs.Extract(LRun);
    LNewParagraph.Runs.Add(LRun);
  end;

  LNewParagraphIndex := FCaretPosition.ParagraphIndex + 1;
  FDocument.Paragraphs.Insert(LNewParagraphIndex, LNewParagraph);

  // Renumber the full enclosing list block
  if LNewParagraph.BlockType = btLI then
  begin
    LFirst := LNewParagraphIndex;
    while (LFirst > 0) and (FDocument.Paragraphs[LFirst - 1].BlockType = btLI) and
          InSameBlockScope(LFirst - 1, LNewParagraphIndex) do
      Dec(LFirst);
    LLast := LNewParagraphIndex;
    while (LLast < FDocument.Paragraphs.Count - 1) and (FDocument.Paragraphs[LLast + 1].BlockType = btLI) and
          InSameBlockScope(LLast + 1, LNewParagraphIndex) do
      Inc(LLast);
    RenumberListBlock(LFirst, LLast);
  end;

  NormalizeRuns(FCaretPosition.ParagraphIndex);

  FCaretPosition := TS4YDocumentPosition.At(LNewParagraphIndex, 0, 0);
  FHasSelection := False;
  FSelectionStart := TS4YDocumentPosition.Invalid;
  FSelectionEnd := TS4YDocumentPosition.Invalid;

  if not FBatchMode then
  begin
    DoLayout;
    DoChanged;

    UpdateCaretXY;

    FCaretOn := True;
    FCaretTimer.Enabled := False;
    FCaretTimer.Enabled := IsFocused;
    EnsureCaretVisible;
    InvalidateRender;
    DoNotifyState;
  end;
end;

procedure TS4YHTMLEditor.InsertLineBreak;
var
  LParagraph: TS4YHTMLParagraph;
  LLineBreakRun: TS4YHTMLRun;
  LRunIndex, LCharIndex: Integer;
  LInsertIndex: Integer;
  LAfterIndex: Integer;
  LAnchorRun: TS4YHTMLRun;
  LLineIndex3: Integer;
  LFoundLine3: Boolean;
  LFragmentStart: Integer;
begin
  if not FCaretPosition.IsValid then
    Exit;
  EnsureValidDocument;

  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  LRunIndex := FCaretPosition.RunIndex;
  LCharIndex := FCaretPosition.CharIndex;

  if (LParagraph.Runs.Count > 0) and (LRunIndex >= LParagraph.Runs.Count) then
  begin
    LRunIndex := LParagraph.Runs.Count - 1;
    LCharIndex := LParagraph.Runs[LRunIndex].Text.Length;
  end;

  if (LParagraph.Runs.Count = 0) or (LCharIndex = 0) then
    LInsertIndex := LRunIndex
  else
  begin
    SplitRunAt(FCaretPosition.ParagraphIndex, LRunIndex, LCharIndex);
    LInsertIndex := LRunIndex + 1;
  end;

  LLineBreakRun := TS4YHTMLRun.Create;
  LLineBreakRun.IsLineBreak := True;
  LLineBreakRun.Style := StyleAtCaret;
  if LInsertIndex < LParagraph.Runs.Count then
    LParagraph.Runs.Insert(LInsertIndex, LLineBreakRun)
  else
    LParagraph.Runs.Add(LLineBreakRun);

  LAfterIndex := LInsertIndex + 1;
  if LAfterIndex >= LParagraph.Runs.Count then
  begin
    LAnchorRun := TS4YHTMLRun.Create;
    LAnchorRun.Style := LLineBreakRun.Style;
    LParagraph.Runs.Insert(LAfterIndex, LAnchorRun);
  end;

  FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex, LAfterIndex, 0);
  FHasSelection := False;
  FSelectionStart := TS4YDocumentPosition.Invalid;
  FSelectionEnd := TS4YDocumentPosition.Invalid;

  DoLayout;
  DoChanged;

  FCaretScreenX := ContentLeft;
  FCaretScreenH := 16;
  FCaretScreenY := ContentTop;
  LLineIndex3 := 0;
  LFoundLine3 := False;
  while (LLineIndex3 <= High(FLines)) and not LFoundLine3 do
  begin
    LFragmentStart := FLines[LLineIndex3].FragmentStart;
    if (FLines[LLineIndex3].ParagraphIndex = FCaretPosition.ParagraphIndex) and (LFragmentStart >= 0) and (LFragmentStart < Length(FFrags)) and
      (FFrags[LFragmentStart].RunIndex = LAfterIndex) then
    begin
      // The X of the first fragment keeps the indentation of lists, quotes and table cells
      FCaretScreenX := ContentLeft + FFrags[LFragmentStart].X;
      FCaretScreenY := ContentTop + FLines[LLineIndex3].Y;
      FCaretScreenH := IfThen(FFrags[LFragmentStart].Height > 0, FFrags[LFragmentStart].Height, FLines[LLineIndex3].Height / FLayoutEngine.LineSpacing);
      LFoundLine3 := True;
    end;
    Inc(LLineIndex3);
  end;

  FCaretOn := True;
  FCaretTimer.Enabled := False;
  FCaretTimer.Enabled := IsFocused;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.MergeWithPrevious(AParagraphIndex: Integer);
var
  LRun: TS4YHTMLRun;
  LPreviousParagraph: TS4YHTMLParagraph;
  LCurrentParagraph: TS4YHTMLParagraph;
  LOldRunCount: Integer;
  LPreviousEndCharIndex: Integer;
begin
  if (AParagraphIndex <= 0) or (AParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  // Paragraphs of different cells, or of a cell and the text around the table, are never merged
  if not InSameBlockScope(AParagraphIndex - 1, AParagraphIndex) then
    Exit;
  LPreviousParagraph := FDocument.Paragraphs[AParagraphIndex - 1];
  LCurrentParagraph := FDocument.Paragraphs[AParagraphIndex];
  // Non-text blocks (HR/Image) are atomic: just delete them, adjust caret
  if LPreviousParagraph.BlockType in [btHR, btImage] then
  begin
    FDocument.Paragraphs.Delete(AParagraphIndex - 1);
    FCaretPosition := TS4YDocumentPosition.At(AParagraphIndex - 1, 0, 0);
    Exit;
  end;
  if LCurrentParagraph.BlockType in [btHR, btImage] then
  begin
    LOldRunCount := LPreviousParagraph.Runs.Count;
    if LOldRunCount > 0 then
      LPreviousEndCharIndex := LPreviousParagraph.Runs[LOldRunCount - 1].Text.Length
    else
      LPreviousEndCharIndex := 0;
    FCaretPosition := TS4YDocumentPosition.At(AParagraphIndex - 1, Max(0, LOldRunCount - 1), LPreviousEndCharIndex);
    FDocument.Paragraphs.Delete(AParagraphIndex);
    Exit;
  end;
  LOldRunCount := LPreviousParagraph.Runs.Count;
  if LOldRunCount > 0 then
    LPreviousEndCharIndex := LPreviousParagraph.Runs[LOldRunCount - 1].Text.Length
  else
    LPreviousEndCharIndex := 0;
  FCaretPosition := TS4YDocumentPosition.At(AParagraphIndex - 1, Max(0, LOldRunCount - 1), LPreviousEndCharIndex);
  while LCurrentParagraph.Runs.Count > 0 do
  begin
    LRun := LCurrentParagraph.Runs[0];
    LCurrentParagraph.Runs.Extract(LRun);
    LPreviousParagraph.Runs.Add(LRun);
  end;
  FDocument.Paragraphs.Delete(AParagraphIndex);
  NormalizeRuns(AParagraphIndex - 1);
end;

// -- Style application ---------------------------------------------------------

function TS4YHTMLEditor.DocumentPositionToAbsChar(const APosition: TS4YDocumentPosition): Integer;
var
  LParagraph: TS4YHTMLParagraph;
  LRunIndex: Integer;
begin
  Result := 0;
  if (APosition.ParagraphIndex < 0) or (APosition.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[APosition.ParagraphIndex];
  for LRunIndex := 0 to APosition.RunIndex - 1 do
  begin
    if LRunIndex < LParagraph.Runs.Count then
      Result := Result + LParagraph.Runs[LRunIndex].Text.Length;
  end;
  Result := Result + APosition.CharIndex;
end;

function TS4YHTMLEditor.AbsCharToDocumentPosition(AParagraphIndex, AAbsChar: Integer; PreferRight: Boolean): TS4YDocumentPosition;
var
  LParagraph: TS4YHTMLParagraph;
  LRunIndex: Integer;
  LRemaining: Integer;
  LRunLength: Integer;
  LAdvancing: Boolean;
begin
  Result := TS4YDocumentPosition.At(AParagraphIndex, 0, 0);
  if (AParagraphIndex < 0) or (AParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[AParagraphIndex];
  if LParagraph.Runs.Count = 0 then
    Exit;
  LRunIndex := 0;
  LRemaining := AAbsChar;
  LAdvancing := True;
  while LAdvancing and (LRunIndex < LParagraph.Runs.Count - 1) do
  begin
    LRunLength := LParagraph.Runs[LRunIndex].Text.Length;
    // PreferRight: advance when LRemaining >= run length (boundary -> start of next run)
    // default:      advance when LRemaining >  run length (boundary -> end of current run)
    if (PreferRight and (LRemaining < LRunLength)) or
       ((not PreferRight) and (LRemaining <= LRunLength)) then
    begin
      LAdvancing := False;
    end
    else
    begin
      LRemaining := LRemaining - LRunLength;
      Inc(LRunIndex);
    end;
  end;
  Result := TS4YDocumentPosition.At(AParagraphIndex, LRunIndex, Min(LRemaining, LParagraph.Runs[LRunIndex].Text.Length));
end;

procedure TS4YHTMLEditor.ApplyFormatToSelection(ABold, AItalic, AUnderline, AStrikeOut, ASuperscript, ASubscript: Integer;
  const AFontName: string; AFontSize: Single; AColor, ABackgroundColor: TAlphaColor; const ALinkURL: string);

  procedure ApplyToStyle(var ATextStyle: TS4YHTMLTextStyle);
  begin
    if ABold >= 0 then
      ATextStyle.Bold := ABold = 1;
    if AItalic >= 0 then
      ATextStyle.Italic := AItalic = 1;
    if AUnderline >= 0 then
      ATextStyle.Underline := AUnderline = 1;
    if AStrikeOut >= 0 then
      ATextStyle.StrikeOut := AStrikeOut = 1;
    if ASuperscript >= 0 then
      ATextStyle.Superscript := ASuperscript = 1;
    if ASubscript >= 0 then
      ATextStyle.Subscript := ASubscript = 1;
    if AFontName <> '' then
      ATextStyle.FontName := AFontName;
    if AFontSize > 0 then
      ATextStyle.FontSize := AFontSize;
    if (AColor <> claNull) and (AColor <> $00000000) then
      ATextStyle.Color := AColor;
    if (ABackgroundColor <> claNull) and (ABackgroundColor <> $00000000) then
      ATextStyle.BackgroundColor := ABackgroundColor;
    if ALinkURL <> #0 then
      ATextStyle.LinkURL := ALinkURL;
  end;

var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LERunExcl: Integer;
  LParagraphIndex: Integer;
  LRunIndex: Integer;
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LStyle: TS4YHTMLTextStyle;
  LSelectionStartAbsChar: Integer;
  LSelectionEndAbsChar: Integer;
  LCaretAbsChar: Integer;
begin
  if not FHasSelection then
  begin
    FInsertStyle := StyleAtCaret;
    ApplyToStyle(FInsertStyle);
    FInsertStyleSet := True;
    DoNotifyState;
    Exit;
  end;

  SaveUndo;
  GetSelectionRange(LSelectionStart, LSelectionEnd);

  LSelectionStartAbsChar := DocumentPositionToAbsChar(FSelectionStart);
  LSelectionEndAbsChar   := DocumentPositionToAbsChar(FSelectionEnd);
  LCaretAbsChar    := DocumentPositionToAbsChar(FCaretPosition);

  SplitRunAt(LSelectionEnd.ParagraphIndex, LSelectionEnd.RunIndex, LSelectionEnd.CharIndex);
  SplitRunAt(LSelectionStart.ParagraphIndex, LSelectionStart.RunIndex, LSelectionStart.CharIndex);
  LERunExcl := LSelectionEnd.RunIndex;
  if LSelectionEnd.CharIndex > 0 then
    Inc(LERunExcl);
  if LSelectionStart.CharIndex > 0 then
  begin
    Inc(LSelectionStart.RunIndex);
    if LSelectionStart.ParagraphIndex = LSelectionEnd.ParagraphIndex then
      Inc(LERunExcl);
  end;
  LSelectionEnd.RunIndex := LERunExcl;

  LParagraphIndex := LSelectionStart.ParagraphIndex;
  LRunIndex := LSelectionStart.RunIndex;
  while (PositionCompare(TS4YDocumentPosition.At(LParagraphIndex, LRunIndex, 0), TS4YDocumentPosition.At(LSelectionEnd.ParagraphIndex, LSelectionEnd.RunIndex, 0)) < 0) and
    (LParagraphIndex < FDocument.Paragraphs.Count) do
  begin
    LParagraph := FDocument.Paragraphs[LParagraphIndex];
    if LRunIndex >= LParagraph.Runs.Count then
    begin
      Inc(LParagraphIndex);
      LRunIndex := 0;
    end
    else
    begin
      LRun := LParagraph.Runs[LRunIndex];
      if not LRun.IsLineBreak then
      begin
        LStyle := LRun.Style;
        ApplyToStyle(LStyle);
        LRun.Style := LStyle;
      end;
      Inc(LRunIndex);
      if LRunIndex >= LParagraph.Runs.Count then
      begin
        Inc(LParagraphIndex);
        LRunIndex := 0;
      end;
    end;
  end;

  for var I := LSelectionStart.ParagraphIndex to Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1) do
    NormalizeRuns(I);

  FSelectionStart  := AbsCharToDocumentPosition(FSelectionStart.ParagraphIndex,  LSelectionStartAbsChar, True);
  FSelectionEnd    := AbsCharToDocumentPosition(FSelectionEnd.ParagraphIndex,    LSelectionEndAbsChar,   False);
  FCaretPosition  := AbsCharToDocumentPosition(FCaretPosition.ParagraphIndex,  LCaretAbsChar,    LCaretAbsChar = LSelectionStartAbsChar);
  FHasSelection := FSelectionStart.IsValid and not FSelectionStart.Equals(FSelectionEnd);

  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

// -- Public Formatting ---------------------------------------------------------

procedure TS4YHTMLEditor.ToggleBold;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Bold, 0, 1);
  ApplyFormatToSelection(V, -1, -1, -1, -1, -1, '', 0, claNull, claNull);
end;

procedure TS4YHTMLEditor.ToggleItalic;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Italic, 0, 1);
  ApplyFormatToSelection(-1, V, -1, -1, -1, -1, '', 0, claNull, claNull);
end;

procedure TS4YHTMLEditor.ToggleUnderline;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Underline, 0, 1);
  ApplyFormatToSelection(-1, -1, V, -1, -1, -1, '', 0, claNull, claNull);
end;

procedure TS4YHTMLEditor.ToggleStrikeOut;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.StrikeOut, 0, 1);
  ApplyFormatToSelection(-1, -1, -1, V, -1, -1, '', 0, claNull, claNull);
end;

procedure TS4YHTMLEditor.ToggleSuperscript;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Superscript, 0, 1);
  ApplyFormatToSelection(-1, -1, -1, -1, V, 0, '', 0, claNull, claNull);
end;

procedure TS4YHTMLEditor.ToggleSubscript;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Subscript, 0, 1);
  ApplyFormatToSelection(-1, -1, -1, -1, 0, V, '', 0, claNull, claNull);
end;

procedure TS4YHTMLEditor.SetCurrentFontName(const AName: string);
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, AName, 0, claNull, claNull);
end;

procedure TS4YHTMLEditor.DecreaseFontSize;
var
  LPresets: TArray<TS4YFontSizePreset>;
  LCurrent: Single;
  LIndex: Integer;
begin
  LPresets := FontSizePresets;
  LCurrent := StyleAtCaret.FontSize;
  LIndex := High(LPresets);
  while (LIndex > 0) and (LPresets[LIndex].Size >= LCurrent) do
    Dec(LIndex);
  SetCurrentFontSize(LPresets[LIndex].Size);
end;

procedure TS4YHTMLEditor.IncreaseFontSize;
var
  LPresets: TArray<TS4YFontSizePreset>;
  LCurrent: Single;
  LIndex: Integer;
begin
  LPresets := FontSizePresets;
  LCurrent := StyleAtCaret.FontSize;
  LIndex := 0;
  while (LIndex < High(LPresets)) and (LPresets[LIndex].Size <= LCurrent) do
    Inc(LIndex);
  SetCurrentFontSize(LPresets[LIndex].Size);
end;

procedure TS4YHTMLEditor.SetCurrentFontSize(ASize: Single);
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', ASize, claNull, claNull);
end;

procedure TS4YHTMLEditor.SetCurrentFontColor(AColor: TAlphaColor);
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', 0, AColor, claNull);
end;

procedure TS4YHTMLEditor.SetCurrentBackgroundColor(AColor: TAlphaColor);
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', 0, claNull, AColor);
end;

procedure TS4YHTMLEditor.ClearFormatting;
var
  LTextStyle: TS4YHTMLTextStyle;
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LERunExcl2: Integer;
  LParagraphIndex: Integer;
  LRunIndex: Integer;
  LParagraph: TS4YHTMLParagraph;
  LSelectionStartAbsChar: Integer;
  LSelectionEndAbsChar: Integer;
  LCaretAbsChar: Integer;
begin
  LTextStyle.Init;
  if not FHasSelection then
  begin
    FInsertStyle := LTextStyle;
    FInsertStyleSet := True;
    DoNotifyState;
    Exit;
  end;
  SaveUndo;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  LSelectionStartAbsChar := DocumentPositionToAbsChar(FSelectionStart);
  LSelectionEndAbsChar   := DocumentPositionToAbsChar(FSelectionEnd);
  LCaretAbsChar    := DocumentPositionToAbsChar(FCaretPosition);
  SplitRunAt(LSelectionEnd.ParagraphIndex, LSelectionEnd.RunIndex, LSelectionEnd.CharIndex);
  SplitRunAt(LSelectionStart.ParagraphIndex, LSelectionStart.RunIndex, LSelectionStart.CharIndex);
  LERunExcl2 := LSelectionEnd.RunIndex;
  if LSelectionEnd.CharIndex > 0 then
    Inc(LERunExcl2);
  if LSelectionStart.CharIndex > 0 then
  begin
    Inc(LSelectionStart.RunIndex);
    if LSelectionStart.ParagraphIndex = LSelectionEnd.ParagraphIndex then
      Inc(LERunExcl2);
  end;
  LSelectionEnd.RunIndex := LERunExcl2;
  LParagraphIndex := LSelectionStart.ParagraphIndex;
  LRunIndex := LSelectionStart.RunIndex;
  while (PositionCompare(TS4YDocumentPosition.At(LParagraphIndex, LRunIndex, 0), TS4YDocumentPosition.At(LSelectionEnd.ParagraphIndex, LSelectionEnd.RunIndex, 0)) < 0) and
    (LParagraphIndex < FDocument.Paragraphs.Count) do
  begin
    LParagraph := FDocument.Paragraphs[LParagraphIndex];
    if LRunIndex >= LParagraph.Runs.Count then
    begin
      Inc(LParagraphIndex);
      LRunIndex := 0;
    end
    else
    begin
      LParagraph.Runs[LRunIndex].Style := LTextStyle;
      Inc(LRunIndex);
      if LRunIndex >= LParagraph.Runs.Count then
      begin
        Inc(LParagraphIndex);
        LRunIndex := 0;
      end;
    end;
  end;
  for var I := LSelectionStart.ParagraphIndex to Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1) do
    NormalizeRuns(I);
  FSelectionStart  := AbsCharToDocumentPosition(FSelectionStart.ParagraphIndex,  LSelectionStartAbsChar, True);
  FSelectionEnd    := AbsCharToDocumentPosition(FSelectionEnd.ParagraphIndex,    LSelectionEndAbsChar,   False);
  FCaretPosition  := AbsCharToDocumentPosition(FCaretPosition.ParagraphIndex,  LCaretAbsChar,    LCaretAbsChar = LSelectionStartAbsChar);
  FHasSelection := FSelectionStart.IsValid and not FSelectionStart.Equals(FSelectionEnd);
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.AlignLeft;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
begin
  SaveUndo;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    for var I := LSelectionStart.ParagraphIndex to LSelectionEnd.ParagraphIndex do
      if I < FDocument.Paragraphs.Count then
        FDocument.Paragraphs[I].Alignment := haLeft;
  end
  else if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
    FDocument.Paragraphs[FCaretPosition.ParagraphIndex].Alignment := haLeft;
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.AlignCenter;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
begin
  SaveUndo;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    for var I := LSelectionStart.ParagraphIndex to LSelectionEnd.ParagraphIndex do
      if I < FDocument.Paragraphs.Count then
        FDocument.Paragraphs[I].Alignment := haCenter;
  end
  else if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
    FDocument.Paragraphs[FCaretPosition.ParagraphIndex].Alignment := haCenter;
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.SetCurrentParagraphFormat(AFormat: TS4YParagraphFormat);
const
  C_PARA_BLOCK_TYPES: array[TS4YParagraphFormat] of TS4YHTMLBlockType = (
    btBodyText, btParagraph, btH1, btH2, btH3, btH4, btH5, btH6, btPre);
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
begin
  if not FCaretPosition.IsValid then
    Exit;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  SaveUndo;
  if FHasSelection then
    GetSelectionRange(LSelectionStart, LSelectionEnd)
  else
  begin
    LSelectionStart := FCaretPosition;
    LSelectionEnd := FCaretPosition;
  end;
  for var I := LSelectionStart.ParagraphIndex to Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1) do
    FDocument.Paragraphs[I].BlockType := C_PARA_BLOCK_TYPES[AFormat];
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.AlignRight;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
begin
  SaveUndo;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    for var I := LSelectionStart.ParagraphIndex to LSelectionEnd.ParagraphIndex do
      if I < FDocument.Paragraphs.Count then
        FDocument.Paragraphs[I].Alignment := haRight;
  end
  else if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
    FDocument.Paragraphs[FCaretPosition.ParagraphIndex].Alignment := haRight;
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.AlignJustify;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
begin
  SaveUndo;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    for var I := LSelectionStart.ParagraphIndex to LSelectionEnd.ParagraphIndex do
      if I < FDocument.Paragraphs.Count then
        FDocument.Paragraphs[I].Alignment := haJustify;
  end
  else if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
    FDocument.Paragraphs[FCaretPosition.ParagraphIndex].Alignment := haJustify;
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.SetHeading(ALevel: Integer);
const
  C_BLOCK_TYPES: array [0 .. 6] of TS4YHTMLBlockType = (btParagraph, btH1, btH2, btH3, btH4, btH5, btH6);
var
  LLevel: Integer;
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
begin
  if not FCaretPosition.IsValid then
    Exit;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  SaveUndo;
  LLevel := Max(0, Min(6, ALevel));
  if FHasSelection then
    GetSelectionRange(LSelectionStart, LSelectionEnd)
  else
  begin
    LSelectionStart := FCaretPosition;
    LSelectionEnd := FCaretPosition;
  end;
  for var I := LSelectionStart.ParagraphIndex to Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1) do
    FDocument.Paragraphs[I].BlockType := C_BLOCK_TYPES[LLevel];
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.ToggleOrderedList;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFirst, LLast: Integer;
  LIndent: Integer;
  LAllOrdered: Boolean;
  LOnList: Boolean;
begin
  if not FCaretPosition.IsValid then
    Exit;
  SaveUndo;
  LAllOrdered := GetCurrentIsOrderedList;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LFirst := LSelectionStart.ParagraphIndex;
    LLast  := Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1);
    LIndent := -1; // no indent filter for explicit selection
  end
  else
  begin
    LOnList := FCaretPosition.IsValid and
               (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
               (FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType = btLI);
    if LOnList then
    begin
      LIndent := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].IndentLevel;
      GetListBlockRange(LFirst, LLast);
    end
    else
    begin
      LFirst  := FCaretPosition.ParagraphIndex;
      LLast   := FCaretPosition.ParagraphIndex;
      LIndent := -1;
    end;
  end;
  if LAllOrdered then
  begin
    for var I := LFirst to LLast do
      if (LIndent < 0) or (FDocument.Paragraphs[I].IndentLevel = LIndent) then
      begin
        FDocument.Paragraphs[I].BlockType  := btParagraph;
        FDocument.Paragraphs[I].IndentLevel := 0;
      end;
  end
  else
  begin
    for var I := LFirst to LLast do
      if (LIndent < 0) or (FDocument.Paragraphs[I].IndentLevel = LIndent) then
      begin
        FDocument.Paragraphs[I].BlockType   := btLI;
        FDocument.Paragraphs[I].ListOrdered := True;
      end;
    RenumberListBlock(LFirst, LLast);
  end;
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.ToggleUnorderedList;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFirst, LLast: Integer;
  LIndent: Integer;
  LAllUnordered: Boolean;
  LOnList: Boolean;
begin
  if not FCaretPosition.IsValid then
    Exit;
  SaveUndo;
  LAllUnordered := GetCurrentIsUnorderedList;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LFirst := LSelectionStart.ParagraphIndex;
    LLast  := Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1);
    LIndent := -1;
  end
  else
  begin
    LOnList := FCaretPosition.IsValid and
               (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
               (FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType = btLI);
    if LOnList then
    begin
      LIndent := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].IndentLevel;
      GetListBlockRange(LFirst, LLast);
    end
    else
    begin
      LFirst  := FCaretPosition.ParagraphIndex;
      LLast   := FCaretPosition.ParagraphIndex;
      LIndent := -1;
    end;
  end;
  if LAllUnordered then
  begin
    for var I := LFirst to LLast do
      if (LIndent < 0) or (FDocument.Paragraphs[I].IndentLevel = LIndent) then
      begin
        FDocument.Paragraphs[I].BlockType   := btParagraph;
        FDocument.Paragraphs[I].IndentLevel := 0;
      end;
  end
  else
  begin
    for var I := LFirst to LLast do
      if (LIndent < 0) or (FDocument.Paragraphs[I].IndentLevel = LIndent) then
      begin
        FDocument.Paragraphs[I].BlockType   := btLI;
        FDocument.Paragraphs[I].ListOrdered := False;
      end;
  end;
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.Indent;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFirst, LLast: Integer;
begin
  if not FCaretPosition.IsValid then
    Exit;
  SaveUndo;
  if FHasSelection then
    GetSelectionRange(LSelectionStart, LSelectionEnd)
  else
  begin
    LSelectionStart := FCaretPosition;
    LSelectionEnd := FCaretPosition;
  end;
  for var I := LSelectionStart.ParagraphIndex to Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1) do
    FDocument.Paragraphs[I].IndentLevel := FDocument.Paragraphs[I].IndentLevel + 1;
  // Extend to the full enclosing list block and renumber
  LFirst := LSelectionStart.ParagraphIndex;
  while (LFirst > 0) and (FDocument.Paragraphs[LFirst - 1].BlockType = btLI) do
    Dec(LFirst);
  LLast := Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1);
  while (LLast < FDocument.Paragraphs.Count - 1) and (FDocument.Paragraphs[LLast + 1].BlockType = btLI) do
    Inc(LLast);
  RenumberListBlock(LFirst, LLast);
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.Outdent;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFirst, LLast: Integer;
begin
  if not FCaretPosition.IsValid then
    Exit;
  SaveUndo;
  if FHasSelection then
    GetSelectionRange(LSelectionStart, LSelectionEnd)
  else
  begin
    LSelectionStart := FCaretPosition;
    LSelectionEnd := FCaretPosition;
  end;
  for var I := LSelectionStart.ParagraphIndex to Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1) do
    FDocument.Paragraphs[I].IndentLevel := Max(0, FDocument.Paragraphs[I].IndentLevel - 1);
  // Extend to the full enclosing list block and renumber
  LFirst := LSelectionStart.ParagraphIndex;
  while (LFirst > 0) and (FDocument.Paragraphs[LFirst - 1].BlockType = btLI) do
    Dec(LFirst);
  LLast := Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1);
  while (LLast < FDocument.Paragraphs.Count - 1) and (FDocument.Paragraphs[LLast + 1].BlockType = btLI) do
    Inc(LLast);
  RenumberListBlock(LFirst, LLast);
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.InsertHorizontalRule(AColor: TAlphaColor = claNull; AThickness: Single = 0);
var
  LHorizontalRule: TS4YHTMLParagraph;
  LNewParagraph: TS4YHTMLParagraph;
begin
  if not FCaretPosition.IsValid then
    Exit;
  SaveUndo;
  LHorizontalRule := TS4YHTMLParagraph.Create;
  LHorizontalRule.BlockType := btHR;
  LHorizontalRule.HRColor := AColor;
  LHorizontalRule.HRThickness := AThickness;
  FDocument.Paragraphs.Insert(FCaretPosition.ParagraphIndex + 1, LHorizontalRule);
  FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex + 1, 0, 0);
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count - 1 then
  begin
    LNewParagraph := TS4YHTMLParagraph.Create;
    LNewParagraph.BlockType := btParagraph;
    FDocument.Paragraphs.Add(LNewParagraph);
  end;
  FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex + 1, 0, 0);
  DoLayout;
  DoChanged;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.InsertImage(const ASource: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
begin
  InsertInlineImage(ASource, AWidth, AHeight, AAlt);
end;

procedure TS4YHTMLEditor.InsertInlineImage(const ASource: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LBitmap: TBitmap;
  LInsertIndex: Integer;
begin
  if not FCaretPosition.IsValid then
    Exit;
  SaveUndo;
  if FHasSelection then
    DeleteSelection;
  EnsureValidDocument;
  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  SplitRunAt(FCaretPosition.ParagraphIndex, FCaretPosition.RunIndex, FCaretPosition.CharIndex);
  LInsertIndex := FCaretPosition.RunIndex;
  if (LParagraph.Runs.Count > 0) and (FCaretPosition.CharIndex > 0) then
    Inc(LInsertIndex);
  LRun := TS4YHTMLRun.Create;
  LRun.IsImage := True;
  LRun.ImageSource := StoredImageSource(ASource);
  LRun.ImageWidth := AWidth;
  LRun.ImageHeight := AHeight;
  LRun.ImageAlt := AAlt;
  LRun.Style := StyleAtCaret;
  LRun.Text := #$FFFC;
  if (LRun.ImageWidth = 0) or (LRun.ImageHeight = 0) then
  begin
    LBitmap := LoadImage(LRun.ImageSource, ilcInsert);
    if Assigned(LBitmap) then
    begin
      if LRun.ImageWidth = 0 then
        LRun.ImageWidth := LBitmap.Width;
      if LRun.ImageHeight = 0 then
        LRun.ImageHeight := LBitmap.Height;
    end;
  end;
  LParagraph.Runs.Insert(LInsertIndex, LRun);
  FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex, LInsertIndex, LRun.Text.Length);
  NormalizeRuns(FCaretPosition.ParagraphIndex);
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.UpdateImage(const ASource: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LBitmap: TBitmap;
begin
  if not FCaretPosition.IsValid then
    Exit;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  if (FCaretPosition.RunIndex < 0) or (FCaretPosition.RunIndex >= LParagraph.Runs.Count) then
    Exit;
  LRun := LParagraph.Runs[FCaretPosition.RunIndex];
  if not LRun.IsImage then
    Exit;
  SaveUndo;
  LRun.ImageSource := StoredImageSource(ASource);
  LRun.ImageAlt := AAlt;
  LRun.ImageWidth := AWidth;
  LRun.ImageHeight := AHeight;
  if (LRun.ImageWidth = 0) or (LRun.ImageHeight = 0) then
  begin
    LBitmap := LoadImage(LRun.ImageSource, ilcInsert);
    if Assigned(LBitmap) then
    begin
      if LRun.ImageWidth = 0 then
        LRun.ImageWidth := LBitmap.Width;
      if LRun.ImageHeight = 0 then
        LRun.ImageHeight := LBitmap.Height;
    end;
  end;
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.ReloadImages;
var
  LSrcs: TArray<string>;
  LSource: string;
  LBitmap: TBitmap;
begin
  LSrcs := FImageCache.Keys.ToArray;
  for LSource in LSrcs do
  begin
    LBitmap := LoadAllowedBitmap(LSource, ilcReload);
    if Assigned(LBitmap) then
      FImageCache.AddOrSetValue(LSource, LBitmap);
  end;
  DoLayout;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.InsertTable(ARows: Integer = 2; ACols: Integer = 2);
var
  LInsertAt: Integer;
  LNewParagraph: TS4YHTMLParagraph;
  LRow: Integer;
  LCol: Integer;
  LTableID: Integer;
  LFirstCellIndex: Integer;
  LCurrentParagraph: TS4YHTMLParagraph;
  LContainers: TArray<TS4YTableCellReference>;
begin
  if not FCaretPosition.IsValid then
    Exit;
  if ARows < 1 then
    ARows := 1;
  if ACols < 1 then
    ACols := 1;
  SaveUndo;
  LTableID := NextTableID;
  LInsertAt := FCaretPosition.ParagraphIndex + 1;
  LFirstCellIndex := LInsertAt;
  // A table inserted while the caret is in a cell is nested in that cell
  LCurrentParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  LContainers := nil;
  if LCurrentParagraph.IsTableCell then
  begin
    LContainers := System.Copy(LCurrentParagraph.TableContainers);
    SetLength(LContainers, Length(LContainers) + 1);
    LContainers[High(LContainers)] := TS4YTableCellReference.At(LCurrentParagraph.TableID,
      LCurrentParagraph.TableRow, LCurrentParagraph.TableCol);
  end;
  for LRow := 0 to ARows - 1 do
    for LCol := 0 to ACols - 1 do
    begin
      LNewParagraph := TS4YHTMLParagraph.Create;
      LNewParagraph.BlockType := btTableCell;
      LNewParagraph.TableID := LTableID;
      LNewParagraph.TableContainers := System.Copy(LContainers);
      LNewParagraph.TableRow := LRow;
      LNewParagraph.TableCol := LCol;
      LNewParagraph.TableCols := ACols;
      FDocument.Paragraphs.Insert(LInsertAt, LNewParagraph);
      Inc(LInsertAt);
    end;
  // Ensure a paragraph after the table for cursor placement
  if LCurrentParagraph.IsTableCell then
  begin
    // In a cell the paragraph that follows the table belongs to the cell, unless the cell goes on
    if (LInsertAt >= FDocument.Paragraphs.Count) or
       not FDocument.Paragraphs[LInsertAt].IsInCell(LCurrentParagraph.TableID, LCurrentParagraph.TableRow,
         LCurrentParagraph.TableCol) then
    begin
      LNewParagraph := TS4YHTMLParagraph.Create;
      LNewParagraph.BlockType := btTableCell;
      LNewParagraph.TableID := LCurrentParagraph.TableID;
      LNewParagraph.TableContainers := System.Copy(LCurrentParagraph.TableContainers);
      LNewParagraph.TableRow := LCurrentParagraph.TableRow;
      LNewParagraph.TableCol := LCurrentParagraph.TableCol;
      LNewParagraph.TableCols := LCurrentParagraph.TableCols;
      LNewParagraph.IsHeader := LCurrentParagraph.IsHeader;
      FDocument.Paragraphs.Insert(LInsertAt, LNewParagraph);
    end;
  end
  else if (LInsertAt >= FDocument.Paragraphs.Count) or
          FDocument.Paragraphs[LInsertAt].IsTableCell then
  begin
    LNewParagraph := TS4YHTMLParagraph.Create;
    LNewParagraph.BlockType := btParagraph;
    FDocument.Paragraphs.Insert(LInsertAt, LNewParagraph);
  end;
  DoLayout;
  DoChanged;
  SetCaretPosition(TS4YDocumentPosition.At(LFirstCellIndex, 0, 0), False);
end;

procedure TS4YHTMLEditor.GetTableBounds(ATableID: Integer; out AFirstIndex, ALastIndex: Integer);
var
  LParagraphIndex: Integer;
begin
  AFirstIndex := -1;
  ALastIndex := -1;
  for LParagraphIndex := 0 to FDocument.Paragraphs.Count - 1 do
    if FDocument.Paragraphs[LParagraphIndex].IsTableCell and
       (FDocument.Paragraphs[LParagraphIndex].TableID = ATableID) then
    begin
      if AFirstIndex < 0 then
        AFirstIndex := LParagraphIndex;
      ALastIndex := LParagraphIndex;
    end;
end;

function TS4YHTMLEditor.FindFirstCellInRow(ATableID, ARow: Integer): Integer;
var
  LParagraphIndex: Integer;
  LFound: Boolean;
begin
  Result := -1;
  LFound := False;
  for LParagraphIndex := 0 to FDocument.Paragraphs.Count - 1 do
    if FDocument.Paragraphs[LParagraphIndex].IsTableCell and
       (FDocument.Paragraphs[LParagraphIndex].TableID = ATableID) and
       (FDocument.Paragraphs[LParagraphIndex].TableRow = ARow) and not LFound then
    begin
      Result := LParagraphIndex;
      LFound := True;
    end;
end;

procedure TS4YHTMLEditor.InsertTableRow;
var
  LCurrentParagraph: TS4YHTMLParagraph;
  LTableID, LTargetRow, LTableCols: Integer;
  LFirstIndex, LLastIndex: Integer;
  LInsertAt, LNewFirstCellIndex: Integer;
  LParagraphIndex: Integer;
  LNewCell: TS4YHTMLParagraph;
  LNewRowIndex: Integer;
begin
  if FReadOnly then
    Exit;
  if not FCaretPosition.IsValid then
    Exit;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LCurrentParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  if not LCurrentParagraph.IsTableCell then
    Exit;

  // Rows and columns cannot be added or removed in a table that has merged cells or nested tables
  if TableHasSpans(LCurrentParagraph.TableID) or TableHasNesting(LCurrentParagraph.TableID) then
    Exit;

  SaveUndo;
  LTableID := LCurrentParagraph.TableID;
  LTargetRow := LCurrentParagraph.TableRow;
  LTableCols := LCurrentParagraph.TableCols;
  LNewRowIndex := LTargetRow + 1;

  GetTableBounds(LTableID, LFirstIndex, LLastIndex);

  // Shift existing rows after the target row up by one
  for LParagraphIndex := LFirstIndex to LLastIndex do
    if FDocument.Paragraphs[LParagraphIndex].TableRow > LTargetRow then
      FDocument.Paragraphs[LParagraphIndex].TableRow := FDocument.Paragraphs[LParagraphIndex].TableRow + 1;

  // Find insertion point: right after the last cell of LTargetRow
  LInsertAt := LFirstIndex;
  for LParagraphIndex := LFirstIndex to LLastIndex do
    if FDocument.Paragraphs[LParagraphIndex].TableRow = LTargetRow then
      LInsertAt := LParagraphIndex + 1;

  // Insert new row (one empty cell per column)
  LNewFirstCellIndex := LInsertAt;
  for var LCol := 0 to LTableCols - 1 do
  begin
    LNewCell := TS4YHTMLParagraph.Create;
    LNewCell.BlockType := btTableCell;
    LNewCell.TableID := LTableID;
    LNewCell.TableRow := LNewRowIndex;
    LNewCell.TableCol := LCol;
    LNewCell.TableCols := LTableCols;
    LNewCell.CopyTableLayoutFrom(LCurrentParagraph);
    FDocument.Paragraphs.Insert(LInsertAt + LCol, LNewCell);
  end;

  DoLayout;
  DoChanged;
  SetCaretPosition(TS4YDocumentPosition.At(LNewFirstCellIndex, 0, 0), False);
end;

procedure TS4YHTMLEditor.DeleteTableRow;
var
  LCurrentParagraph: TS4YHTMLParagraph;
  LTableID, LTargetRow: Integer;
  LFirstIndex, LLastIndex: Integer;
  LParagraphIndex: Integer;
  LParagraph: TS4YHTMLParagraph;
  LNewCaretIndex: Integer;
  LRowCount: Integer;
  LNewParagraph: TS4YHTMLParagraph;
begin
  if FReadOnly then
    Exit;
  if not FCaretPosition.IsValid then
    Exit;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LCurrentParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  if not LCurrentParagraph.IsTableCell then
    Exit;

  // Rows and columns cannot be added or removed in a table that has merged cells or nested tables
  if TableHasSpans(LCurrentParagraph.TableID) or TableHasNesting(LCurrentParagraph.TableID) then
    Exit;

  SaveUndo;
  LTableID := LCurrentParagraph.TableID;
  LTargetRow := LCurrentParagraph.TableRow;

  GetTableBounds(LTableID, LFirstIndex, LLastIndex);

  // Count distinct rows (max TableRow + 1)
  LRowCount := 0;
  for LParagraphIndex := LFirstIndex to LLastIndex do
    if FDocument.Paragraphs[LParagraphIndex].TableRow > LRowCount then
      LRowCount := FDocument.Paragraphs[LParagraphIndex].TableRow;
  Inc(LRowCount);

  // Delete all cells belonging to the target row (right-to-left)
  for LParagraphIndex := LLastIndex downto LFirstIndex do
  begin
    LParagraph := FDocument.Paragraphs[LParagraphIndex];
    if LParagraph.IsTableCell and (LParagraph.TableID = LTableID) and
       (LParagraph.TableRow = LTargetRow) then
      FDocument.Paragraphs.Delete(LParagraphIndex);
  end;

  LNewCaretIndex := 0;

  if LRowCount = 1 then
  begin
    // Last row deleted -- ensure a normal paragraph exists at that position
    LNewCaretIndex := Max(0, Min(LFirstIndex, FDocument.Paragraphs.Count));
    if (LNewCaretIndex >= FDocument.Paragraphs.Count) or
       FDocument.Paragraphs[LNewCaretIndex].IsTableCell then
    begin
      LNewParagraph := TS4YHTMLParagraph.Create;
      LNewParagraph.BlockType := btParagraph;
      FDocument.Paragraphs.Insert(LNewCaretIndex, LNewParagraph);
    end;
  end
  else
  begin
    // Renumber remaining rows
    GetTableBounds(LTableID, LFirstIndex, LLastIndex);
    for LParagraphIndex := LFirstIndex to LLastIndex do
    begin
      LParagraph := FDocument.Paragraphs[LParagraphIndex];
      if LParagraph.TableRow > LTargetRow then
        LParagraph.TableRow := LParagraph.TableRow - 1;
    end;

    // Place caret at first cell of:
    //   - LTargetRow (now the row that was LTargetRow+1) if not last row
    //   - LTargetRow-1 if the deleted row was the last one
    if LTargetRow >= LRowCount - 1 then
      LNewCaretIndex := FindFirstCellInRow(LTableID, LTargetRow - 1)
    else
      LNewCaretIndex := FindFirstCellInRow(LTableID, LTargetRow);

    if LNewCaretIndex < 0 then
      LNewCaretIndex := LFirstIndex;
  end;

  DoLayout;
  DoChanged;
  SetCaretPosition(TS4YDocumentPosition.At(Max(0, LNewCaretIndex), 0, 0), False);
end;

procedure TS4YHTMLEditor.InsertTableColumn;
var
  LCurrentParagraph: TS4YHTMLParagraph;
  LTableID, LTargetCol, LTableCols: Integer;
  LFirstIndex, LLastIndex: Integer;
  LMaximumRow, LRow: Integer;
  LParagraphIndex: Integer;
  LParagraph: TS4YHTMLParagraph;
  LInsertAt: Integer;
  LNewCell: TS4YHTMLParagraph;
  LNewCellIndex: Integer;
begin
  if FReadOnly then
    Exit;
  if not FCaretPosition.IsValid then
    Exit;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LCurrentParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  if not LCurrentParagraph.IsTableCell then
    Exit;

  // Rows and columns cannot be added or removed in a table that has merged cells or nested tables
  if TableHasSpans(LCurrentParagraph.TableID) or TableHasNesting(LCurrentParagraph.TableID) then
    Exit;

  SaveUndo;
  LTableID := LCurrentParagraph.TableID;
  LTargetCol := LCurrentParagraph.TableCol;
  LTableCols := LCurrentParagraph.TableCols;

  GetTableBounds(LTableID, LFirstIndex, LLastIndex);

  // Find max row index
  LMaximumRow := 0;
  for LParagraphIndex := LFirstIndex to LLastIndex do
    if FDocument.Paragraphs[LParagraphIndex].TableRow > LMaximumRow then
      LMaximumRow := FDocument.Paragraphs[LParagraphIndex].TableRow;

  // Step 1: shift TableCol and update TableCols on all existing cells
  for LParagraphIndex := LFirstIndex to LLastIndex do
  begin
    LParagraph := FDocument.Paragraphs[LParagraphIndex];
    if LParagraph.TableCol > LTargetCol then
      LParagraph.TableCol := LParagraph.TableCol + 1;
    LParagraph.TableCols := LTableCols + 1;
  end;

  // Step 2: insert one new cell per row, processing last row first
  //         so that earlier paragraph indices remain valid
  LNewCellIndex := -1;
  for LRow := LMaximumRow downto 0 do
  begin
    // Find the para index of the cell at (LRow, LTargetCol)
    LInsertAt := -1;
    for LParagraphIndex := LFirstIndex to LLastIndex do
    begin
      LParagraph := FDocument.Paragraphs[LParagraphIndex];
      if (LParagraph.TableID = LTableID) and (LParagraph.TableRow = LRow) and
         (LParagraph.TableCol = LTargetCol) then
        LInsertAt := LParagraphIndex + 1;
    end;
    if LInsertAt < 0 then
      LInsertAt := LLastIndex + 1;

    LNewCell := TS4YHTMLParagraph.Create;
    LNewCell.BlockType := btTableCell;
    LNewCell.TableID := LTableID;
    LNewCell.TableRow := LRow;
    LNewCell.TableCol := LTargetCol + 1;
    LNewCell.TableCols := LTableCols + 1;
    LNewCell.CopyTableLayoutFrom(LCurrentParagraph);
    FDocument.Paragraphs.Insert(LInsertAt, LNewCell);

    // Track the new cell in the caret's row
    if LRow = LCurrentParagraph.TableRow then
      LNewCellIndex := LInsertAt;

    // LLastIndex grows by one after each insertion
    Inc(LLastIndex);
  end;

  if LNewCellIndex < 0 then
    LNewCellIndex := LFirstIndex;

  DoLayout;
  DoChanged;
  SetCaretPosition(TS4YDocumentPosition.At(LNewCellIndex, 0, 0), False);
end;

procedure TS4YHTMLEditor.DeleteTableColumn;
var
  LCurrentParagraph: TS4YHTMLParagraph;
  LTableID, LTargetCol, LTableCols: Integer;
  LFirstIndex, LLastIndex: Integer;
  LParagraphIndex: Integer;
  LParagraph: TS4YHTMLParagraph;
  LNewCaretIndex: Integer;
  LNewCaretCol: Integer;
  LNewCaretFound: Boolean;
  LNewParagraph: TS4YHTMLParagraph;
begin
  if FReadOnly then
    Exit;
  if not FCaretPosition.IsValid then
    Exit;
  if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
    Exit;
  LCurrentParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  if not LCurrentParagraph.IsTableCell then
    Exit;

  // Rows and columns cannot be added or removed in a table that has merged cells or nested tables
  if TableHasSpans(LCurrentParagraph.TableID) or TableHasNesting(LCurrentParagraph.TableID) then
    Exit;

  SaveUndo;
  LTableID := LCurrentParagraph.TableID;
  LTargetCol := LCurrentParagraph.TableCol;
  LTableCols := LCurrentParagraph.TableCols;

  GetTableBounds(LTableID, LFirstIndex, LLastIndex);

  // Delete all cells in the target column (right-to-left)
  for LParagraphIndex := LLastIndex downto LFirstIndex do
  begin
    LParagraph := FDocument.Paragraphs[LParagraphIndex];
    if (LParagraph.TableID = LTableID) and (LParagraph.TableCol = LTargetCol) then
      FDocument.Paragraphs.Delete(LParagraphIndex);
  end;

  LNewCaretIndex := 0;

  if LTableCols = 1 then
  begin
    // Last column deleted -- ensure a normal paragraph at that position
    LNewCaretIndex := Max(0, Min(LFirstIndex, FDocument.Paragraphs.Count));
    if (LNewCaretIndex >= FDocument.Paragraphs.Count) or
       FDocument.Paragraphs[LNewCaretIndex].IsTableCell then
    begin
      LNewParagraph := TS4YHTMLParagraph.Create;
      LNewParagraph.BlockType := btParagraph;
      FDocument.Paragraphs.Insert(LNewCaretIndex, LNewParagraph);
    end;
  end
  else
  begin
    // Update remaining cells
    GetTableBounds(LTableID, LFirstIndex, LLastIndex);
    for LParagraphIndex := LFirstIndex to LLastIndex do
    begin
      LParagraph := FDocument.Paragraphs[LParagraphIndex];
      LParagraph.TableCols := LTableCols - 1;
      if LParagraph.TableCol > LTargetCol then
        LParagraph.TableCol := LParagraph.TableCol - 1;
    end;

    // Find new caret: same row, adjacent column
    // Prefer LTargetCol (now the cell that was at LTargetCol+1),
    // or LTargetCol-1 if the deleted column was the last one
    LNewCaretCol := Min(LTargetCol, LTableCols - 2);
    LNewCaretFound := False;
    for LParagraphIndex := LFirstIndex to LLastIndex do
    begin
      LParagraph := FDocument.Paragraphs[LParagraphIndex];
      if (LParagraph.TableRow = LCurrentParagraph.TableRow) and (LParagraph.TableCol = LNewCaretCol) and
         not LNewCaretFound then
      begin
        LNewCaretIndex := LParagraphIndex;
        LNewCaretFound := True;
      end;
    end;

    if not LNewCaretFound then
      LNewCaretIndex := LFirstIndex;
  end;

  DoLayout;
  DoChanged;
  SetCaretPosition(TS4YDocumentPosition.At(Max(0, LNewCaretIndex), 0, 0), False);
end;

procedure TS4YHTMLEditor.InsertText(const AText: string);
begin
  if AText = '' then
    Exit;
  SaveUndo;
  InsertString(AText);
end;

procedure TS4YHTMLEditor.InsertLink(const AURL, AText: string);
begin
  if (AURL = '') or (AText = '') then
    Exit;
  SaveUndo;
  FInsertStyle := StyleAtCaret;
  FInsertStyle.LinkURL := AURL;
  FInsertStyleSet := True;
  InsertString(AText);
  FInsertStyleSet := False;
end;

procedure TS4YHTMLEditor.UpdateLink(const AURL: string);
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LStyle: TS4YHTMLTextStyle;
begin
  if FHasSelection then
    ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', 0, claNull, claNull, AURL)
  else if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
  begin
    LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
    if (FCaretPosition.RunIndex < LParagraph.Runs.Count) and (LParagraph.Runs[FCaretPosition.RunIndex].Style.LinkURL <> '') then
    begin
      LRun := LParagraph.Runs[FCaretPosition.RunIndex];
      LStyle := LRun.Style;
      LStyle.LinkURL := AURL;
      SaveUndo;
      LRun.Style := LStyle;
      DoLayout;
      DoChanged;
      InvalidateRender;
      DoNotifyState;
    end;
  end;
end;

procedure TS4YHTMLEditor.RemoveLink;
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', 0, claNull, claNull, '');
end;

function TS4YHTMLEditor.GetLinkAtCaret: string;
begin
  Result := StyleAtCaret.LinkURL;
end;

procedure TS4YHTMLEditor.InsertHTML(const AHTML: string);
var
  LInsertedDocument: TS4YHTMLDocument;
  LCurrentParagraph: TS4YHTMLParagraph;
  LTailParagraph: TS4YHTMLParagraph;
  LSourceParagraph: TS4YHTMLParagraph;
  LMoveFrom: Integer;
  LInsertAt: Integer;
  LOriginalParagraphIndex: Integer;
  LParser: TS4YHTMLParser;
  LLastRI: Integer;
  LTargetSegment: Integer;
  LTargOfs: Integer;
  LCurrentSegment: Integer;
  LAcc: Integer;
  LLineIndex4: Integer;
  LFound4: Boolean;
  LLastSource: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
begin
  if AHTML = '' then
    Exit;
  SaveUndo;
  if FHasSelection then
    DeleteSelection;
  LParser := TS4YHTMLParser.Create;
  try
    LInsertedDocument := LParser.Parse(AHTML);
  finally
    LParser.Free;
  end;
  try
    if LInsertedDocument.Paragraphs.Count = 0 then
      Exit;
    if FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count then
      Exit;

    SplitRunAt(FCaretPosition.ParagraphIndex, FCaretPosition.RunIndex, FCaretPosition.CharIndex);
    LCurrentParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
    LOriginalParagraphIndex := FCaretPosition.ParagraphIndex;

    if FCaretPosition.RunIndex >= LCurrentParagraph.Runs.Count then
      LMoveFrom := LCurrentParagraph.Runs.Count
    else if FCaretPosition.CharIndex = 0 then
      LMoveFrom := FCaretPosition.RunIndex
    else
      LMoveFrom := FCaretPosition.RunIndex + 1;

    if LInsertedDocument.Paragraphs.Count = 1 then
    begin
      LSourceParagraph := LInsertedDocument.Paragraphs[0];
      LInsertAt := LMoveFrom;
      for var LRunIndex := 0 to LSourceParagraph.Runs.Count - 1 do
        LCurrentParagraph.Runs.Insert(LInsertAt + LRunIndex, LSourceParagraph.Runs[LRunIndex].Clone);

      LLastRI := LInsertAt + LSourceParagraph.Runs.Count - 1;
      LTargetSegment := 0;
      LTargOfs := 0;
      if LLastRI >= 0 then
      begin
        for var I := 0 to LLastRI - 1 do
          if LCurrentParagraph.Runs[I].IsLineBreak then
          begin
            Inc(LTargetSegment);
            LTargOfs := 0;
          end
          else
            Inc(LTargOfs, LCurrentParagraph.Runs[I].Text.Length);
        if not LCurrentParagraph.Runs[LLastRI].IsLineBreak then
          Inc(LTargOfs, LCurrentParagraph.Runs[LLastRI].Text.Length);
      end;

      NormalizeRuns(LOriginalParagraphIndex);

      LCurrentSegment := 0;
      LAcc := 0;
      FCaretPosition.RunIndex := 0;
      FCaretPosition.CharIndex := 0;
      LLineIndex4 := 0;
      LFound4 := False;
      while (LLineIndex4 < LCurrentParagraph.Runs.Count) and not LFound4 do
      begin
        if LCurrentParagraph.Runs[LLineIndex4].IsLineBreak then
        begin
          if LCurrentSegment = LTargetSegment then
            LFound4 := True
          else
          begin
            Inc(LCurrentSegment);
            LAcc := 0;
          end;
        end
        else if LCurrentSegment = LTargetSegment then
        begin
          if LTargOfs <= LAcc + LCurrentParagraph.Runs[LLineIndex4].Text.Length then
          begin
            FCaretPosition.RunIndex := LLineIndex4;
            FCaretPosition.CharIndex := LTargOfs - LAcc;
            LFound4 := True;
          end
          else
          begin
            Inc(LAcc, LCurrentParagraph.Runs[LLineIndex4].Text.Length);
            FCaretPosition.RunIndex := LLineIndex4;
            FCaretPosition.CharIndex := LCurrentParagraph.Runs[LLineIndex4].Text.Length;
          end;
        end;
        Inc(LLineIndex4);
      end;
    end
    else
    begin
      LTailParagraph := TS4YHTMLParagraph.Create;
      LLastSource := LInsertedDocument.Paragraphs[LInsertedDocument.Paragraphs.Count - 1];
      LTailParagraph.BlockType := LLastSource.BlockType;
      LTailParagraph.Alignment := LLastSource.Alignment;
      LTailParagraph.IndentLevel := LLastSource.IndentLevel;
      LTailParagraph.ListOrdered := LLastSource.ListOrdered;
      while LMoveFrom < LCurrentParagraph.Runs.Count do
      begin
        LRun := LCurrentParagraph.Runs[LMoveFrom];
        LCurrentParagraph.Runs.Extract(LRun);
        LTailParagraph.Runs.Add(LRun);
      end;

      LSourceParagraph := LInsertedDocument.Paragraphs[0];
      LCurrentParagraph.BlockType := LSourceParagraph.BlockType;
      LCurrentParagraph.Alignment := LSourceParagraph.Alignment;
      LCurrentParagraph.IndentLevel := LSourceParagraph.IndentLevel;
      LCurrentParagraph.ListOrdered := LSourceParagraph.ListOrdered;
      for var LRunIndex := 0 to LSourceParagraph.Runs.Count - 1 do
        LCurrentParagraph.Runs.Add(LSourceParagraph.Runs[LRunIndex].Clone);

      NormalizeRuns(LOriginalParagraphIndex);

      LInsertAt := LOriginalParagraphIndex + 1;
      for var LParagraphIndex := 1 to LInsertedDocument.Paragraphs.Count - 2 do
      begin
        FDocument.Paragraphs.Insert(LInsertAt, LInsertedDocument.Paragraphs[LParagraphIndex].Clone);
        Inc(LInsertAt);
      end;

      LSourceParagraph := LInsertedDocument.Paragraphs[LInsertedDocument.Paragraphs.Count - 1];
      for var LRunIndex := LSourceParagraph.Runs.Count - 1 downto 0 do
        LTailParagraph.Runs.Insert(0, LSourceParagraph.Runs[LRunIndex].Clone);

      FDocument.Paragraphs.Insert(LInsertAt, LTailParagraph);
      NormalizeRuns(LInsertAt);
      FCaretPosition := TS4YDocumentPosition.At(LInsertAt, 0, 0);
    end;

    FHasSelection := False;
    FSelectionStart := TS4YDocumentPosition.Invalid;
    FSelectionEnd := TS4YDocumentPosition.Invalid;
    ScanForPlaceholders(FDocument);
    RebuildPlaceholderList;
  finally
    LInsertedDocument.Free;
  end;
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

// -- Editing commands ----------------------------------------------------------

procedure TS4YHTMLEditor.SelectAll;
begin
  FHasSelection := True;
  FSelectionStart := DocumentStart;
  FSelectionEnd := DocumentEnd;
  FCaretPosition := DocumentEnd;
  UpdateCaretXY;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.Undo;
var
  Entry: TS4YUndoEntry;
  RedoEntry: TS4YUndoEntry;
begin
  if FUndoStack.Count = 0 then
    Exit;
  Entry := FUndoStack.Last;
  FUndoStack.Extract(Entry);
  // Save current to redo
  RedoEntry := TS4YUndoEntry.Create(FDocument.Clone, FCaretPosition, FSelectionStart, FSelectionEnd);
  FRedoStack.Add(RedoEntry);
  // Restore
  FDocument.Free;
  FDocument := Entry.Document;
  Entry.Document := nil; // prevent double-free
  FCaretPosition := Entry.CaretPosition;
  FSelectionStart := Entry.SelStart;
  FSelectionEnd := Entry.SelEnd;
  FHasSelection := FSelectionStart.IsValid and not FSelectionStart.Equals(FSelectionEnd);
  Entry.Free;
  RebuildPlaceholderList;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.Redo;
var
  Entry: TS4YUndoEntry;
  UndoEntry: TS4YUndoEntry;
begin
  if FRedoStack.Count = 0 then
    Exit;
  Entry := FRedoStack.Last;
  FRedoStack.Extract(Entry);
  UndoEntry := TS4YUndoEntry.Create(FDocument.Clone, FCaretPosition, FSelectionStart, FSelectionEnd);
  FUndoStack.Add(UndoEntry);
  FDocument.Free;
  FDocument := Entry.Document;
  Entry.Document := nil;
  FCaretPosition := Entry.CaretPosition;
  FSelectionStart := Entry.SelStart;
  FSelectionEnd := Entry.SelEnd;
  FHasSelection := FSelectionStart.IsValid and not FSelectionStart.Equals(FSelectionEnd);
  Entry.Free;
  RebuildPlaceholderList;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure TS4YHTMLEditor.Cut;
begin
  if not FHasSelection then
    Exit;
  Copy;
  SaveUndo;
  DeleteSelection;
end;

procedure TS4YHTMLEditor.Copy;
begin
  if not FHasSelection then
    Exit;
  TS4YHTMLClipboard.SetHTML(GetSelectionHTML, GetSelectionText);
end;

function BitmapToDataURI(ABitmap: TBitmap): string;
var
  LStream: TMemoryStream;
  LEncoder: TBase64Encoding;
begin
  Result := '';
  LStream := TMemoryStream.Create;
  try
    ABitmap.SaveToStream(LStream);
    if LStream.Size = 0 then
      Exit;
    LEncoder := TBase64Encoding.Create(0);
    try
      Result := 'data:image/png;base64,' +
        LEncoder.EncodeBytesToString(LStream.Memory, LStream.Size);
    finally
      LEncoder.Free;
    end;
  finally
    LStream.Free;
  end;
end;

procedure TS4YHTMLEditor.Paste;
var
  LClipboardService: IFMXClipboardService;
  LValue: TValue;
  LText: string;
  LFragment: string;
  LDataURI: string;
  LBitmap: TBitmap;
begin
  if FReadOnly then
    Exit;
  // HTML clipboard (preserves formatting; handles SaveUndo+DeleteSelection via InsertHTML)
  if TS4YHTMLClipboard.GetHTML(LFragment) then
  begin
    InsertHTML(LFragment);
    Exit;
  end;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboardService) then
    Exit;
  LValue := LClipboardService.GetClipboard;
  if LValue.IsEmpty then
    Exit;
  // Bitmap -> <img> with inline data URI
  if LValue.IsObject then
  begin
    LBitmap := TBitmap.Create;
    try
      try
        LBitmap.Assign(TPersistent(LValue.AsObject));
      except
        Exit;
      end;
      if not LBitmap.IsEmpty then
      begin
        LDataURI := BitmapToDataURI(LBitmap);
        if LDataURI <> '' then
        begin
          SaveUndo;
          if FHasSelection then
            DeleteSelection;
          InsertHTML('<img src="' + LDataURI + '"/>');
        end;
      end;
    finally
      LBitmap.Free;
    end;
    Exit;
  end;
  // Plain text fallback
  LText := LValue.ToString;
  if LText = '' then
    Exit;
  if LooksLikeHTML(LText) then
    InsertHTML(LText)
  else
  begin
    SaveUndo;
    if FHasSelection then
      DeleteSelection;
    InsertString(LText);
  end;
end;

procedure TS4YHTMLEditor.PasteAsPlainText;
var
  LClipboardService: IFMXClipboardService;
  LValue: TValue;
  LText: string;
begin
  if FReadOnly then
    Exit;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboardService) then
    Exit;
  LValue := LClipboardService.GetClipboard;
  if LValue.IsEmpty then
    Exit;
  LText := LValue.ToString;
  if LText = '' then
    Exit;
  SaveUndo;
  if FHasSelection then
    DeleteSelection;
  InsertString(LText);
end;

function TS4YHTMLEditor.GetCurrentAlignment: TS4YHTMLAlignment;
begin
  if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
    Result := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].Alignment
  else
    Result := haLeft;
end;

function TS4YHTMLEditor.GetCurrentParagraphFormat: TS4YParagraphFormat;
var
  LBlockType: TS4YHTMLBlockType;
begin
  if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
    LBlockType := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType
  else
    LBlockType := btParagraph;
  case LBlockType of
    btBodyText: Result := pfBodyText;
    btParagraph: Result := pfParagraph;
    btH1: Result := pfH1;
    btH2: Result := pfH2;
    btH3: Result := pfH3;
    btH4: Result := pfH4;
    btH5: Result := pfH5;
    btH6: Result := pfH6;
    btPre: Result := pfPre;
  else
    Result := pfParagraph;
  end;
end;

function TS4YHTMLEditor.GetCurrentIsOrderedList: Boolean;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFirst, LLast: Integer;
  LIndent: Integer;
begin
  Result := False;
  if not FCaretPosition.IsValid then
    Exit;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    Result := True;
    for var I := LSelectionStart.ParagraphIndex to Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1) do
      if (FDocument.Paragraphs[I].BlockType <> btLI) or not FDocument.Paragraphs[I].ListOrdered then
        Result := False;
  end
  else
  begin
    if (FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count) or
       (FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType <> btLI) then
      Exit;
    LIndent := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].IndentLevel;
    GetListBlockRange(LFirst, LLast);
    Result := True;
    for var I := LFirst to LLast do
      if (FDocument.Paragraphs[I].IndentLevel = LIndent) and
         ((FDocument.Paragraphs[I].BlockType <> btLI) or not FDocument.Paragraphs[I].ListOrdered) then
        Result := False;
  end;
end;

function TS4YHTMLEditor.GetCurrentIsUnorderedList: Boolean;
var
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LFirst, LLast: Integer;
  LIndent: Integer;
begin
  Result := False;
  if not FCaretPosition.IsValid then
    Exit;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    Result := True;
    for var I := LSelectionStart.ParagraphIndex to Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1) do
      if (FDocument.Paragraphs[I].BlockType <> btLI) or FDocument.Paragraphs[I].ListOrdered then
        Result := False;
  end
  else
  begin
    if (FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count) or
       (FDocument.Paragraphs[FCaretPosition.ParagraphIndex].BlockType <> btLI) then
      Exit;
    LIndent := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].IndentLevel;
    GetListBlockRange(LFirst, LLast);
    Result := True;
    for var I := LFirst to LLast do
      if (FDocument.Paragraphs[I].IndentLevel = LIndent) and
         ((FDocument.Paragraphs[I].BlockType <> btLI) or FDocument.Paragraphs[I].ListOrdered) then
        Result := False;
  end;
end;

function TS4YHTMLEditor.GetState: TS4YEditorState;
var
  LTextStyle: TS4YHTMLTextStyle;
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
  LImageRun: TS4YHTMLRun;
  LCurrentParagraph: TS4YHTMLParagraph;
  LLineIndex: Integer;
  LColumnOffset: Integer;
  LFoundInLine: Boolean;
  LParagraphIndex: Integer;
  LLastParagraphIndex: Integer;
begin
  LTextStyle := StyleAtCaret;
  Result.IsBold := LTextStyle.Bold;
  Result.IsItalic := LTextStyle.Italic;
  Result.IsUnderline := LTextStyle.Underline;
  Result.IsStrikeOut := LTextStyle.StrikeOut;
  Result.IsSuperscript := LTextStyle.Superscript;
  Result.IsSubscript := LTextStyle.Subscript;
  Result.FontName := LTextStyle.FontName;
  Result.FontSize := LTextStyle.FontSize;
  Result.FontColor := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
  Result.BackgroundColor := LTextStyle.BackgroundColor;
  Result.LinkURL := LTextStyle.LinkURL;
  Result.IsImage := False;
  Result.ImageSource := '';
  Result.ImageWidth := 0;
  Result.ImageHeight := 0;
  Result.ImageAlt := '';
  if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) and
     (FCaretPosition.RunIndex >= 0) and
     (FCaretPosition.RunIndex < FDocument.Paragraphs[FCaretPosition.ParagraphIndex].Runs.Count) then
  begin
    LImageRun := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].Runs[FCaretPosition.RunIndex];
    if LImageRun.IsImage then
    begin
      Result.IsImage := True;
      Result.ImageSource := LImageRun.ImageSource;
      Result.ImageWidth := LImageRun.ImageWidth;
      Result.ImageHeight := LImageRun.ImageHeight;
      Result.ImageAlt := LImageRun.ImageAlt;
    end;
  end;
  Result.Alignment := GetCurrentAlignment;
  Result.HasSelection := FHasSelection;
  Result.IsOrderedList := GetCurrentIsOrderedList;
  Result.IsUnorderedList := GetCurrentIsUnorderedList;
  Result.ParagraphFormat := GetCurrentParagraphFormat;
  if FCaretPosition.IsValid and (FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count) then
    Result.IndentLevel := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].IndentLevel
  else
    Result.IndentLevel := 0;
  Result.CanOutdent := False;
  Result.LineNumber := 0;
  Result.ColumnNumber := 0;
  if FCaretPosition.IsValid then
  begin
    if FHasSelection then
    begin
      GetSelectionRange(LSelectionStart, LSelectionEnd);
      // PERFORMANCE: stop at the first indented paragraph (the 'not Result.CanOutdent'
      // test in the while condition). A big selection must not be scanned to its end
      // on every caret move: do not turn this into a loop that always runs to the end.
      LParagraphIndex := LSelectionStart.ParagraphIndex;
      LLastParagraphIndex := Min(LSelectionEnd.ParagraphIndex, FDocument.Paragraphs.Count - 1);
      while not Result.CanOutdent and (LParagraphIndex <= LLastParagraphIndex) do
      begin
        Result.CanOutdent := FDocument.Paragraphs[LParagraphIndex].IndentLevel > 0;
        Inc(LParagraphIndex);
      end;
    end
    else if FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count then
      Result.CanOutdent := FDocument.Paragraphs[FCaretPosition.ParagraphIndex].IndentLevel > 0;

    if FCaretPosition.ParagraphIndex < FDocument.Paragraphs.Count then
      LCurrentParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex]
    else
      LCurrentParagraph := nil;
    Result.IsInTable := Assigned(LCurrentParagraph) and LCurrentParagraph.IsTableCell;
    if Result.IsInTable then
    begin
      Result.TableRow := LCurrentParagraph.TableRow;
      Result.TableCol := LCurrentParagraph.TableCol;
    end
    else
    begin
      Result.TableRow := -1;
      Result.TableCol := -1;
    end;

    // PERFORMANCE-CRITICAL: GetState runs on every caret move and this scan visits
    // every line before the caret paragraph. Keep it a plain 'for' loop that ends
    // with Exit (nothing follows it). Rewriting it as 'while ... and not LFoundInLine'
    // (to avoid Exit) measured about 60% slower on a large document: the for loop
    // keeps its bound and counter in registers, the while re-evaluates High(FLines)
    // and the flag on every line.
    LFoundInLine := False;
    for LLineIndex := 0 to High(FLines) do
    begin
      if FLines[LLineIndex].ParagraphIndex = FCaretPosition.ParagraphIndex then
      begin
        LColumnOffset := 0;
        LFoundInLine := False;
        for var LFragmentIndex := FLines[LLineIndex].FragmentStart to FLines[LLineIndex].FragmentStart + FLines[LLineIndex].FragmentCount - 1 do
        begin
          if (LFragmentIndex >= 0) and (LFragmentIndex < Length(FFrags)) then
          begin
            if FFrags[LFragmentIndex].RunIndex < FCaretPosition.RunIndex then
            begin
              if not FFrags[LFragmentIndex].IsImage and not FFrags[LFragmentIndex].IsPlaceholder then
                Inc(LColumnOffset, FFrags[LFragmentIndex].CharEnd - FFrags[LFragmentIndex].CharStart);
            end
            else if FFrags[LFragmentIndex].RunIndex = FCaretPosition.RunIndex then
            begin
              if FCaretPosition.CharIndex >= FFrags[LFragmentIndex].CharStart then
              begin
                Inc(LColumnOffset, FCaretPosition.CharIndex - FFrags[LFragmentIndex].CharStart);
                LFoundInLine := True;
              end;
            end;
          end;
        end;
        if LFoundInLine then
        begin
          // Exit instead of Break: nothing follows the search (see the note above)
          Result.LineNumber := LLineIndex + 1;
          Result.ColumnNumber := LColumnOffset + 1;
          Exit;
        end;
      end;
    end;
  end;
end;

// -- Undo helpers --------------------------------------------------------------

procedure TS4YHTMLEditor.SaveUndo;
begin
  if FUndoStack.Count >= C_EDITOR_UNDO_LEVELS then
    FUndoStack.Delete(0);
  FUndoStack.Add(TS4YUndoEntry.Create(FDocument.Clone, FCaretPosition, FSelectionStart, FSelectionEnd));
  ClearRedo;
end;

procedure TS4YHTMLEditor.ClearRedo;
begin
  FRedoStack.Clear;
end;

// -- Placeholder support -------------------------------------------------------

procedure TS4YHTMLEditor.AppearanceChanged(Sender: TObject);
begin
  DoLayout;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.SetPlaceholderPrefix(const Value: string);
begin
  if FPlaceholderPrefix = Value then
    Exit;
  FPlaceholderPrefix := Value;
end;

procedure TS4YHTMLEditor.SetPlaceholderSuffix(const Value: string);
begin
  if FPlaceholderSuffix = Value then
    Exit;
  FPlaceholderSuffix := Value;
end;

function TS4YHTMLEditor.GetPlaceholderLabel(const ARawText: string): string;
begin
  Result := ARawText;
  if Assigned(FOnGetPlaceholderLabel) then
    FOnGetPlaceholderLabel(Self, ARawText, Result);
end;

procedure TS4YHTMLEditor.ScanForPlaceholders(ADocument: TS4YHTMLDocument);
var
  LParagraph: TS4YHTMLParagraph;
  LIndex: Integer;
  LRun: TS4YHTMLRun;
  LText: string;
  LPStart: Integer;
  LPSEnd: Integer;
  LSaveStyle: TS4YHTMLTextStyle;
  LSaveBorderColor: TAlphaColor;
  LInsertionIndex: Integer;
  LBeforeText: string;
  LPhText: string;
  LAfterText: string;
  LSplitRun: TS4YHTMLRun;
  LPlaceholderRun: TS4YHTMLRun;
begin
  if (FPlaceholderPrefix = '') or (FPlaceholderSuffix = '') then
    Exit;
  for LParagraph in ADocument.Paragraphs do
  begin
    LIndex := 0;
    while LIndex < LParagraph.Runs.Count do
    begin
      LRun := LParagraph.Runs[LIndex];
      if LRun.IsLineBreak or LRun.IsPlaceholder then
      begin
        Inc(LIndex);
      end
      else
      begin
        LText := LRun.Text;
        LPStart := LText.IndexOf(FPlaceholderPrefix);
        if LPStart < 0 then
        begin
          Inc(LIndex);
        end
        else
        begin
          LPSEnd := LText.IndexOf(FPlaceholderSuffix, LPStart + FPlaceholderPrefix.Length);
          if LPSEnd < 0 then
          begin
            Inc(LIndex);
          end
          else
          begin
            LPSEnd := LPSEnd + FPlaceholderSuffix.Length;
            LSaveStyle := LRun.Style;
            LSaveBorderColor := LRun.PlaceholderBorderColor;
            LBeforeText := LText.Substring(0, LPStart);
            LPhText := LText.Substring(LPStart, LPSEnd - LPStart);
            LAfterText := LText.Substring(LPSEnd);
            LParagraph.Runs.Delete(LIndex);
            LInsertionIndex := LIndex;
            if LBeforeText <> '' then
            begin
              LSplitRun := TS4YHTMLRun.Create;
              LSplitRun.Style := LSaveStyle;
              LSplitRun.Text := LBeforeText;
              LParagraph.Runs.Insert(LInsertionIndex, LSplitRun);
              Inc(LInsertionIndex);
            end;
            LPlaceholderRun := TS4YHTMLRun.Create;
            LPlaceholderRun.Style := LSaveStyle;
            LPlaceholderRun.PlaceholderBorderColor := LSaveBorderColor;
            LPlaceholderRun.Text := LPhText;
            LPlaceholderRun.IsPlaceholder := True;
            LParagraph.Runs.Insert(LInsertionIndex, LPlaceholderRun);
            Inc(LInsertionIndex);
            if LAfterText <> '' then
            begin
              LSplitRun := TS4YHTMLRun.Create;
              LSplitRun.Style := LSaveStyle;
              LSplitRun.Text := LAfterText;
              LParagraph.Runs.Insert(LInsertionIndex, LSplitRun);
            end;
            LIndex := LInsertionIndex;
          end;
        end;
      end;
    end;
  end;
end;

procedure TS4YHTMLEditor.RebuildPlaceholderList;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
begin
  FPlaceholders.Clear;
  for LParagraph in FDocument.Paragraphs do
    for LRun in LParagraph.Runs do
      if LRun.IsPlaceholder then
        FPlaceholders.Add(LRun);
end;

procedure TS4YHTMLEditor.InsertPlaceholder(const ARawText: string; const ADisplayName: string = '');
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LTextStyle: TS4YHTMLTextStyle;
  LInsertIndex: Integer;
begin
  if not FCaretPosition.IsValid then
    Exit;
  if (FPlaceholderPrefix = '') or (FPlaceholderSuffix = '') then
    Exit;
  SaveUndo;
  if FHasSelection then
    DeleteSelection;
  EnsureValidDocument;
  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  LTextStyle := StyleAtCaret;
  SplitRunAt(FCaretPosition.ParagraphIndex, FCaretPosition.RunIndex, FCaretPosition.CharIndex);
  LInsertIndex := FCaretPosition.RunIndex;
  if (LParagraph.Runs.Count > 0) and (FCaretPosition.CharIndex > 0) then
    Inc(LInsertIndex);
  LRun := TS4YHTMLRun.Create;
  LRun.Style := LTextStyle;
  LRun.Text := FPlaceholderPrefix + ARawText + FPlaceholderSuffix;
  LRun.DisplayText := ADisplayName;
  LRun.IsPlaceholder := True;
  LParagraph.Runs.Insert(LInsertIndex, LRun);
  FPlaceholders.Add(LRun);
  FCaretPosition := TS4YDocumentPosition.At(FCaretPosition.ParagraphIndex, LInsertIndex, LRun.Text.Length);
  NormalizeRuns(FCaretPosition.ParagraphIndex);
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

function TS4YHTMLEditor.GetCurrentRun: TS4YHTMLRun;
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LPreviousRun: TS4YHTMLRun;
  LRunIndex: Integer;
  LSelectionStart, LSelectionEnd: TS4YDocumentPosition;
begin
  Result := nil;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    if (LSelectionStart.ParagraphIndex <> LSelectionEnd.ParagraphIndex) or (LSelectionStart.RunIndex <> LSelectionEnd.RunIndex) then
      Exit;
    if LSelectionStart.ParagraphIndex >= FDocument.Paragraphs.Count then
      Exit;
    LParagraph := FDocument.Paragraphs[LSelectionStart.ParagraphIndex];
    if (LSelectionStart.RunIndex >= 0) and (LSelectionStart.RunIndex < LParagraph.Runs.Count) then
      Result := LParagraph.Runs[LSelectionStart.RunIndex];
    Exit;
  end;
  if not FCaretPosition.IsValid or (FCaretPosition.ParagraphIndex >= FDocument.Paragraphs.Count) then
    Exit;
  LParagraph := FDocument.Paragraphs[FCaretPosition.ParagraphIndex];
  LRunIndex := FCaretPosition.RunIndex;
  if (LRunIndex < 0) or (LRunIndex >= LParagraph.Runs.Count) then
    Exit;
  LRun := LParagraph.Runs[LRunIndex];
  // Atomic runs: always return the atom regardless of CharIndex
  if LRun.IsPlaceholder or LRun.IsImage then
  begin
    Result := LRun;
    Exit;
  end;
  // Trailing edge: at CharIndex=0 prefer the run to the left
  if (FCaretPosition.CharIndex = 0) and (LRunIndex > 0) then
  begin
    LPreviousRun := LParagraph.Runs[LRunIndex - 1];
    if not LPreviousRun.IsLineBreak then
    begin
      Result := LPreviousRun;
      Exit;
    end;
  end;
  // Return the current run if it is not a line break
  if not LRun.IsLineBreak then
    Result := LRun;
end;

procedure TS4YHTMLEditor.UpdatePlaceholder(const ANewRawText: string; const ANewDisplayName: string = '');
var
  LRun: TS4YHTMLRun;
begin
  LRun := GetCurrentRun;
  if (LRun = nil) or not LRun.IsPlaceholder then
    Exit;
  if (FPlaceholderPrefix = '') or (FPlaceholderSuffix = '') then
    Exit;
  SaveUndo;
  LRun.Text := FPlaceholderPrefix + ANewRawText + FPlaceholderSuffix;
  LRun.DisplayText := ANewDisplayName;
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

// -- Full-document import/export -----------------------------------------------

procedure TS4YHTMLEditor.ScanDocumentMeta(const AHTML: string; out ATitle, ALanguage: string);
var
  LLower: string;
  LHtmlTagEnd: Integer;
  LAttrs: string;
  LLanguagePosition: Integer;
  LLanguageEnd: Integer;
  LTitleStart: Integer;
  LTitleEnd: Integer;
begin
  ATitle := '';
  ALanguage := '';
  LLower := AHTML.ToLower;
  // lang attribute from <html ...>
  LHtmlTagEnd := LLower.IndexOf('<html');
  if LHtmlTagEnd >= 0 then
  begin
    LHtmlTagEnd := LLower.IndexOf('>', LHtmlTagEnd);
    if LHtmlTagEnd >= 0 then
    begin
      LAttrs := LLower.Substring(0, LHtmlTagEnd);
      LLanguagePosition := LAttrs.IndexOf('lang="');
      if LLanguagePosition >= 0 then
      begin
        Inc(LLanguagePosition, 6);
        LLanguageEnd := LAttrs.IndexOf('"', LLanguagePosition);
        if LLanguageEnd > LLanguagePosition then
          ALanguage := AHTML.Substring(LLanguagePosition, LLanguageEnd - LLanguagePosition);
      end;
    end;
  end;
  // text of <title>
  LTitleStart := LLower.IndexOf('<title>');
  if LTitleStart >= 0 then
  begin
    Inc(LTitleStart, 7);
    LTitleEnd := LLower.IndexOf('</title>', LTitleStart);
    if LTitleEnd > LTitleStart then
      ATitle := AHTML.Substring(LTitleStart, LTitleEnd - LTitleStart).Trim;
  end;
end;

procedure TS4YHTMLEditor.SetFullHTML(const Value: string);
var
  LLower: string;
  LBodyOpen: Integer;
  LBodyTagEnd: Integer;
  LBodyClose: Integer;
  LFragment: string;
  LTitle: string;
  LLanguage: string;
begin
  ScanDocumentMeta(Value, LTitle, LLanguage);
  FTitle := LTitle;
  FLanguage := LLanguage;
  LLower := Value.ToLower;
  LBodyOpen := LLower.IndexOf('<body');
  if LBodyOpen >= 0 then
  begin
    LBodyTagEnd := LLower.IndexOf('>', LBodyOpen);
    if LBodyTagEnd >= 0 then
    begin
      LBodyClose := LLower.IndexOf('</body>', LBodyTagEnd);
      if LBodyClose >= 0 then
        LFragment := Value.Substring(LBodyTagEnd + 1, LBodyClose - LBodyTagEnd - 1).Trim
      else
        LFragment := Value.Substring(LBodyTagEnd + 1).Trim;
    end
    else
      LFragment := '';
  end
  else
    LFragment := Value;
  SetHTML(LFragment);
end;

function TS4YHTMLEditor.GetFullHTML: string;
begin
  Result := BuildFullHTML(nil);
end;

function TS4YHTMLEditor.BuildFullHTML(const AImageSourceConverter: TFunc<string, string>): string;
var
  LStringBuilder: TStringBuilder;
  LLanguageAttribute: string;
  LBodyContent: string;
begin
  if FLanguage <> '' then
    LLanguageAttribute := ' lang="' + FLanguage + '"'
  else
    LLanguageAttribute := '';
  LBodyContent := BuildHTML(AImageSourceConverter);
  LStringBuilder := TStringBuilder.Create;
  try
    LStringBuilder.Append('<!DOCTYPE html>').Append(sLineBreak);
    LStringBuilder.Append('<html' + LLanguageAttribute + '>').Append(sLineBreak);
    LStringBuilder.Append('<head>').Append(sLineBreak);
    LStringBuilder.Append('  <meta charset="UTF-8">').Append(sLineBreak);
    if FTitle <> '' then
      LStringBuilder.Append('  <title>' + FTitle.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;') + '</title>').Append(sLineBreak);
    LStringBuilder.Append('</head>').Append(sLineBreak);
    LStringBuilder.Append('<body>').Append(sLineBreak);
    LStringBuilder.Append(LBodyContent).Append(sLineBreak);
    LStringBuilder.Append('</body>').Append(sLineBreak);
    LStringBuilder.Append('</html>');
    Result := LStringBuilder.ToString;
  finally
    LStringBuilder.Free;
  end;
end;

// -- HTML get/set --------------------------------------------------------------

function TS4YHTMLEditor.GetHTML: string;
begin
  Result := BuildHTML(nil);
end;

function TS4YHTMLEditor.BuildHTML(const AImageSourceConverter: TFunc<string, string>): string;
var
  LGenerator: TS4YHTMLGenerator;
  LPlaceholderStyle: TS4YPlaceholderGeneratorStyle;
begin
  if (FDocument.Paragraphs.Count = 1) and FDocument.Paragraphs[0].IsEmpty and
    (FDocument.Paragraphs[0].BlockType in [btParagraph, btBodyText]) and
    (FDocument.Paragraphs[0].IndentLevel = 0) and (FDocument.Paragraphs[0].Alignment = haLeft) then
    Exit('');
  LGenerator := TS4YHTMLGenerator.Create;
  try
    LGenerator.Pretty := FPrettyHTML;
    LGenerator.ImageSourceConverter := AImageSourceConverter;
    LPlaceholderStyle.Init;
    LPlaceholderStyle.FillColor := FPlaceholderAppearance.FillColor;
    LPlaceholderStyle.TextColor := FPlaceholderAppearance.TextColor;
    LPlaceholderStyle.BorderColor := FPlaceholderAppearance.BorderColor;
    LPlaceholderStyle.BorderRadius := FPlaceholderAppearance.BorderRadius;
    LPlaceholderStyle.HorizontalPadding := FPlaceholderAppearance.HorizontalPadding;
    LPlaceholderStyle.VerticalPadding := FPlaceholderAppearance.VerticalPadding;
    LPlaceholderStyle.Bold := FPlaceholderAppearance.Bold;
    LGenerator.PlaceholderStyle := LPlaceholderStyle;
    Result := LGenerator.Generate(FDocument);
  finally
    LGenerator.Free;
  end;
end;

procedure TS4YHTMLEditor.SetHTML(const Value: string);
var
  LParser: TS4YHTMLParser;
  LNewDocument: TS4YHTMLDocument;
  LParagraph: TS4YHTMLParagraph;
begin
  FUndoStack.Clear;
  FRedoStack.Clear;
  FImageCache.Clear;
  FRefusedImages.Clear;
  LParser := TS4YHTMLParser.Create;
  try
    LNewDocument := LParser.Parse(Value);
    if LNewDocument.Paragraphs.Count = 0 then
    begin
      LParagraph := TS4YHTMLParagraph.Create;
      LParagraph.BlockType := btParagraph;
      LNewDocument.Paragraphs.Add(LParagraph);
    end;
    ScanForPlaceholders(LNewDocument);
    FDocument.Free;
    FDocument := LNewDocument;
    RebuildPlaceholderList;
  finally
    LParser.Free;
  end;
  PreloadImages;
  FCaretPosition := DocumentStart;
  ResetSelection;
  FScrollY := 0;
  FInsertStyleSet := False;
  FLayoutEngine.ClearMeasureCache;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

// -- Misc ----------------------------------------------------------------------

function TS4YHTMLEditor.EnsureValidDocument: Boolean;
var
  LParagraph: TS4YHTMLParagraph;
begin
  if FDocument.Paragraphs.Count = 0 then
  begin
    LParagraph := TS4YHTMLParagraph.Create;
    LParagraph.BlockType := btParagraph;
    FDocument.Paragraphs.Add(LParagraph);
    FCaretPosition := TS4YDocumentPosition.At(0, 0, 0);
  end;
  Result := True;
end;

procedure TS4YHTMLEditor.DoChanged;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
  TBindings.Notify(Self, 'HTML');
end;

procedure TS4YHTMLEditor.DoNotifyState;
begin
  if Assigned(FOnStateChange) then
    FOnStateChange(Self, GetState);
end;

procedure TS4YHTMLEditor.SetLineSpacing(const Value: Single);
begin
  if FLineSpacing = Value then
    Exit;
  FLineSpacing := Value;
  DoLayout;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.SetParagraphSpacing(const Value: Single);
begin
  if FParagraphSpacing = Value then
    Exit;
  FParagraphSpacing := Value;
  DoLayout;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.SetReadOnly(const Value: Boolean);
begin
  FReadOnly := Value;
end;

procedure TS4YHTMLEditor.ReloadImagesAfterPathChange;
begin
  FImageCache.Clear;
  FRefusedImages.Clear;
  PreloadImages;
  FLayoutEngine.ClearMeasureCache;
  DoLayout;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.SetDocumentPath(const Value: string);
begin
  if FDocumentPath = Value then
    Exit;
  FDocumentPath := Value;
  ReloadImagesAfterPathChange;
end;

procedure TS4YHTMLEditor.SetImagePathMode(const Value: TS4YImagePathMode);
begin
  if FImagePathMode = Value then
    Exit;
  FImagePathMode := Value;
  ReloadImagesAfterPathChange;
end;

procedure TS4YHTMLEditor.SetLocalImageAccess(const Value: TS4YLocalImageAccess);
begin
  if FLocalImageAccess = Value then
    Exit;
  FLocalImageAccess := Value;
  ReloadImagesAfterPathChange;
end;

procedure TS4YHTMLEditor.LoadFromFile(const AFileName: string; AEncoding: TEncoding);
var
  LEncoding: TEncoding;
begin
  LEncoding := AEncoding;
  if LEncoding = nil then
    LEncoding := TEncoding.UTF8;
  // The path is set before the HTML so the images are resolved against the right folder
  FDocumentPath := ExcludeTrailingPathDelimiter(ExtractFilePath(TPath.GetFullPath(AFileName)));
  SetFullHTML(TFile.ReadAllText(AFileName, LEncoding));
end;

procedure TS4YHTMLEditor.SaveToFile(const AFileName: string; AEncoding: TEncoding);
var
  LOptions: TS4YSaveOptions;
begin
  LOptions.Init;
  SaveToFile(AFileName, LOptions, AEncoding);
end;

procedure TS4YHTMLEditor.SaveToFile(const AFileName: string; const AOptions: TS4YSaveOptions; AEncoding: TEncoding);
var
  LEncoding: TEncoding;
  LDestinationFolder: string;
  LFolderName: string;
  LContent: string;
  LExporter: TS4YImageExporter;
  LHasCopies: Boolean;
begin
  LEncoding := AEncoding;
  if LEncoding = nil then
    LEncoding := TEncoding.UTF8;
  LDestinationFolder := ExcludeTrailingPathDelimiter(ExtractFilePath(TPath.GetFullPath(AFileName)));
  LFolderName := AOptions.ImagesFolderName;
  if LFolderName = '' then
    LFolderName := TPath.GetFileNameWithoutExtension(AFileName) + '_files';
  LExporter := nil;
  try
    if AOptions.CopyImages and FAutoLoadLocalImages then
    begin
      LExporter := TS4YImageExporter.Create(LDestinationFolder, LFolderName,
        function(const ASource: string): string
        begin
          Result := ResolveImageSource(ASource);
        end,
        function(const ASource: string): Boolean
        begin
          Result := IsImageLoadAllowed(ASource, ilcSave);
        end);
    end;
    // Copied images point to the copies. Other relative sources depend on the current
    // directory in ipmApplication mode: they are written as absolute file: URLs
    LContent := BuildFullHTML(
      function(ASource: string): string
      begin
        if (LExporter <> nil) and LExporter.TryConvert(ASource, Result) then
          Exit;
        if FImagePathMode = ipmDocument then
          Result := ASource
        else
          Result := ImageSourceToFileUrl(ASource);
      end);
    TFile.WriteAllText(AFileName, LContent, LEncoding);
    LHasCopies := (LExporter <> nil) and (LExporter.Destinations.Count > 0);
    if LHasCopies and AOptions.UpdateModel then
      UpdateSourcesAfterExport(LExporter, LDestinationFolder);
    // The model still points to the original images unless it was updated: the document
    // folder moves only when the sources stay valid there
    if (FImagePathMode = ipmDocument) and (not LHasCopies or AOptions.UpdateModel) then
      DocumentPath := LDestinationFolder;
    if LHasCopies and AOptions.UpdateModel then
      ReloadImagesAfterPathChange;
  finally
    LExporter.Free;
  end;
end;

// Points the images of the document to their copies: relative to the new document folder
// in ipmDocument mode, absolute paths otherwise
procedure TS4YHTMLEditor.UpdateSourcesAfterExport(const AExporter: TS4YImageExporter; const ADestinationFolder: string);
var
  LParagraph: TS4YHTMLParagraph;
  LRun: TS4YHTMLRun;
  LNewSource: string;

  function NewSourceFor(const AOldSource: string; out ANewSource: string): Boolean;
  begin
    Result := AExporter.Destinations.TryGetValue(AOldSource, ANewSource);
    if Result and (FImagePathMode = ipmDocument) then
      ANewSource := MakeDocumentRelativePath(ANewSource, ADestinationFolder);
  end;

begin
  for LParagraph in FDocument.Paragraphs do
  begin
    if NewSourceFor(LParagraph.ImageSource, LNewSource) then
      LParagraph.ImageSource := LNewSource;
    for LRun in LParagraph.Runs do
    begin
      if LRun.IsImage and NewSourceFor(LRun.ImageSource, LNewSource) then
        LRun.ImageSource := LNewSource;
    end;
  end;
end;

procedure TS4YHTMLEditor.SetBackgroundColor(const Value: TAlphaColor);
begin
  FBackgroundColor := Value;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.SetFontColor(const Value: TAlphaColor);
begin
  FFontColor := Value;
  InvalidateRender;
end;

procedure TS4YHTMLEditor.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
  // FontChanged fires automatically via FFont.OnChanged
end;

procedure TS4YHTMLEditor.FontChanged(Sender: TObject);
begin
  // Keep FInsertStyle in sync so that new text typed into an empty/default
  // document reflects the font chosen in the Object Inspector.
  FInsertStyle.FontName := FFont.Family;
  FInsertStyle.FontSize := FFont.Size;
  FInsertStyleSet := False;
end;

end.
