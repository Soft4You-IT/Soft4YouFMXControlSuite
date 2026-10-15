unit Soft4You.FMX.Controls.HTMLEditor;

{ *****************************************************************************
  S4YFMXHTMLEditor - WYSIWYG HTML editor for Delphi FireMonkey (FMX)
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{ *******************************************************************************
  THTMLEditor  -  WYSIWYG HTML editor for Delphi FMX
  100% native Delphi - no WebBrowser, no COM/OLE. SVG images are rendered via Skia4Delphi.
  Platforms: Windows, macOS, iOS, Android. Requires Skia4Delphi.

  Architecture:
  Document model  : THTMLParagraph  containing  THTMLRun  (inline styled text)
  Layout engine   : TLayoutEngine   - word-wrap, line metrics via TTextLayout
  Renderer        : TCanvas FMX     - text, selection, caret, border
  HTML I/O        : THTMLParser / THTMLGenerator

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
  Soft4You.HTML.Generator;

const
  C_EDITOR_PADDING = 10.0; // px inner margin
  C_EDITOR_LINE_SPACING = 1.0; // line-height multiplier - 1.0 matches TMemo natural height
  C_EDITOR_PARA_SPACING = 6.0; // extra px between paragraphs
  C_EDITOR_BLOCKQUOTE_INDENT = 24.0; // px per indent level
  C_EDITOR_LIST_INDENT = 20.0;
  C_EDITOR_CARET_BLINK = 530; // ms
  C_EDITOR_UNDO_LEVELS = 100;
  C_EDITOR_SCROLL_STEP = 40.0;
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


  // Mouse management constants
  C_TRIPLE_CLICK_MS = 600;
  C_CLICK_DIST_2 = 25;



type

  // ===========================================================================
  // Placeholder events  (declared before TLayoutEngine which references them)
  // ===========================================================================

  TGetListMarkerEvent = procedure(Sender: TObject; IndentLevel: Integer;
    var Marker: string; var Handled: Boolean) of object;

  TDrawListMarkerEvent = procedure(Sender: TObject; Canvas: TCanvas; const Bounds: TRectF;
    IndentLevel: Integer; var Handled: Boolean) of object;

  TDrawPlaceholderEvent = procedure(Sender: TObject; Canvas: TCanvas; const Bounds: TRectF; const RawText: string;
    var Handled: Boolean) of object;

  TGetPlaceholderLabelEvent = procedure(Sender: TObject; const RawText: string; var DisplayLabel: string) of object;

  TLinkClickEvent = procedure(Sender: TObject; const URL: string; const LinkText: string) of object;
  TLinkHoverEvent = procedure(Sender: TObject; const URL: string; var Cursor: TCursor) of object;

  TImageLoadContext = (ilcParse, ilcInsert, ilcReload, ilcRender);
  TLoadImageEvent = procedure(Sender: TObject; const ASrc: string; var ABitmap: TBitmap;
    AContext: TImageLoadContext) of object;

  // ===========================================================================
  // Layout Engine
  // ===========================================================================

  TLayoutEngine = class
  private
    FMeasure: TTextLayout;
    FMeasureCache: TDictionary<string, TSizeF>;
    // Placeholder chip metrics -- set by THTMLEditor.DoLayout before each layout pass
    FPlaceholderPaddingH: Single;
    FPlaceholderPaddingV: Single;
    FPlaceholderBold: Boolean;
    FPlaceholderGetLabel: TGetPlaceholderLabelEvent;
    FPlaceholderSender: TObject;
    FLineSpacing: Single;
    FParagraphSpacing: Single;
    procedure SetupFont(TS: THTMLTextStyle);
    function MeasureStr(const S: string; TS: THTMLTextStyle): TSizeF;
    function EffectiveSize(TS: THTMLTextStyle): Single;
    function HeadingSize(BT: THTMLBlockType): Single;
    procedure LayoutParagraph(Para: THTMLParagraph; ParaIdx: Integer; AvailW, StartY: Single;
      var Lines: TArray<TLayoutLine>; var Frags: TArray<TLayoutFrag>; var Y: Single);
    procedure LayoutTable(Doc: THTMLDocument; AFirstParaIdx: Integer; AvailW: Single;
      var Lines: TArray<TLayoutLine>; var Frags: TArray<TLayoutFrag>; var Y: Single;
      out ANextParaIdx: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearMeasureCache;
    procedure DoLayout(Doc: THTMLDocument; AvailW: Single; out Lines: TArray<TLayoutLine>;
      out Frags: TArray<TLayoutFrag>; out TotalH: Single);
    function MeasureCharOffset(const S: string; CharIdx: Integer; TS: THTMLTextStyle): Single;
    function CharAtX(const S: string; X: Single; TS: THTMLTextStyle): Integer;
    property LineSpacing: Single read FLineSpacing write FLineSpacing;
    property ParagraphSpacing: Single read FParagraphSpacing write FParagraphSpacing;
    property PlaceholderBold: Boolean read FPlaceholderBold write FPlaceholderBold;
    property PlaceholderGetLabel: TGetPlaceholderLabelEvent read FPlaceholderGetLabel write FPlaceholderGetLabel;
    property PlaceholderPaddingH: Single read FPlaceholderPaddingH write FPlaceholderPaddingH;
    property PlaceholderPaddingV: Single read FPlaceholderPaddingV write FPlaceholderPaddingV;
    property PlaceholderSender: TObject read FPlaceholderSender write FPlaceholderSender;
  end;

  // ===========================================================================
  // Undo entry
  // ===========================================================================

  TUndoEntry = class
    Doc: THTMLDocument;
    CaretPos: TDocPos;
    SelStart: TDocPos;
    SelEnd: TDocPos;
    constructor Create(ADoc: THTMLDocument; const ACaret, ASS, ASE: TDocPos);
    destructor Destroy; override;
  end;

  // ===========================================================================
  // Event type for state notification
  // ===========================================================================

  TEditorState = record
    Alignment: THTMLAlignment;
    BackgroundColor: TAlphaColor;
    CanOutdent: Boolean;
    ColumnNumber: Integer;  // 1-based column within the visual line (0 when no layout)
    FontColor: TAlphaColor;
    FontName: string;
    FontSize: Single;
    HasSelection: Boolean;
    ImageAlt: string;
    ImageHeight: Integer;
    ImageSrc: string;
    ImageWidth: Integer;
    IndentLevel: Integer;
    IsBold: Boolean;
    IsImage: Boolean;
    IsInTable: Boolean;
    IsItalic: Boolean;
    IsOrderedList: Boolean;
    IsStrikeOut: Boolean;
    IsSubscript: Boolean;
    IsSuperscript: Boolean;
    IsUnderline: Boolean;
    IsUnorderedList: Boolean;
    LineNumber: Integer;    // 1-based visual line in the document (0 when no layout)
    LinkURL: string;
    ParagraphFormat: TParagraphFormat;
    TableCol: Integer;      // 0-based, -1 when not in table
    TableRow: Integer;      // 0-based, -1 when not in table
  end;

  TEditorStateEvent = procedure(Sender: TObject; const State: TEditorState) of object;

  // ===========================================================================
  // TPlaceholderAppearance
  // ===========================================================================

  TPlaceholderAppearance = class(TPersistent)
  private
    FOnChange: TNotifyEvent;
    FFillColor: TAlphaColor;
    FTextColor: TAlphaColor;
    FBorderColor: TAlphaColor;
    FBorderRadius: Single;
    FHorizontalPadding: Single;
    FVerticalPadding: Single;
    FBold: Boolean;
    procedure SetFillColor(V: TAlphaColor);
    procedure SetTextColor(V: TAlphaColor);
    procedure SetBorderColor(V: TAlphaColor);
    procedure SetBorderRadius(V: Single);
    procedure SetHorizontalPadding(V: Single);
    procedure SetVerticalPadding(V: Single);
    procedure SetBold(V: Boolean);
    procedure Changed;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property FillColor: TAlphaColor read FFillColor write SetFillColor;
    property TextColor: TAlphaColor read FTextColor write SetTextColor;
    property BorderColor: TAlphaColor read FBorderColor write SetBorderColor;
    property BorderRadius: Single read FBorderRadius write SetBorderRadius;
    property HorizontalPadding: Single read FHorizontalPadding write SetHorizontalPadding;
    property VerticalPadding: Single read FVerticalPadding write SetVerticalPadding;
    property Bold: Boolean read FBold write SetBold;
  end;

  // ===========================================================================
  // THTMLEditor - the control
  // ===========================================================================

  THTMLEditor = class(TStyledControl)
  private
    FDoc: THTMLDocument;
    FLayoutEngine: TLayoutEngine;
    FLines: TArray<TLayoutLine>;
    FFrags: TArray<TLayoutFrag>;
    FTotalHeight: Single;
    FScrollY: Single;
    // Scrollbar - created at runtime only (not at design-time)
    FScrollBar: TScrollBar; // nil at design-time / when not needed
    FScrollBarMax: Single; // max scroll offset = ContentH - ViewH
    FScrollBarVisible: Boolean; // whether the scrollbar is currently visible
    FSyncing: Boolean; // guard: avoid OnScrollChange loop
    FCaretPos: TDocPos;
    FSelStart: TDocPos;
    FSelEnd: TDocPos;
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
    FMouseDownPos: TDocPos;
    FClickSeq: Integer; // consecutive click count (1=single, 2=double, 3=triple)
    FLastClickTime: TDateTime; // time of last click for triple-click detection
    FLastClickPt: TPointF; // position of last click
    FUndoStack: TObjectList<TUndoEntry>;
    FRedoStack: TObjectList<TUndoEntry>;
    FPlaceholders: TList<THTMLRun>;
    FInsertStyle: THTMLTextStyle;
    FInsertStyleSet: Boolean;
    FBatchMode: Boolean; // when True, InsertChar/InsertParagraphBreak skip DoLayout+Repaint
    FContextMenu: TPopupMenu;
    FAutoLoadRemoteImages: Boolean;
    FReadOnly: Boolean;
    FShowBorder: Boolean;
    FBackgroundColor: TAlphaColor;
    FFontColor: TAlphaColor;
    FLayouting: Boolean; // re-entry guard for DoLayout
    FFont: TFont; // default font (configurable from Object Inspector)
    FPlaceholderPrefix: string;
    FPlaceholderSuffix: string;
    FPlaceholderAppearance: TPlaceholderAppearance;
    FHoverLinkURL: string;    // URL under mouse cursor ('' = none)
    FClickedLinkURL: string;  // URL at MouseDown, cleared on MouseUp
    FClickedLinkText: string; // visible text of the clicked link
    FLang: string;
    FLineSpacing: Single;
    FParagraphSpacing: Single;
    FPrettyHTML: Boolean;
    FTitle: string;
    FImageCache: TObjectDictionary<string, TBitmap>;
    FOnChange: TNotifyEvent;
    FOnStateChange: TEditorStateEvent;
    FOnDrawListMarker: TDrawListMarkerEvent;
    FOnDrawPlaceholder: TDrawPlaceholderEvent;
    FOnGetListMarker: TGetListMarkerEvent;
    FOnGetPlaceholderLabel: TGetPlaceholderLabelEvent;
    FOnLinkClick: TLinkClickEvent;
    FOnLinkHover: TLinkHoverEvent;
    FOnLoadImage: TLoadImageEvent;

    // Layout
    function AvailableWidth: Single;
    function ContentLeft: Single;
    function ContentTop: Single;

    // Painting helpers
    procedure PaintHorizontalRule(C: TCanvas; Y, W, X: Single; APara: THTMLParagraph);
    procedure PaintImage(C: TCanvas; const F: TLayoutFrag; APara: THTMLParagraph);
    procedure PaintImageRun(C: TCanvas; const F: TLayoutFrag; ARun: THTMLRun);
    procedure PaintSelection(C: TCanvas);
    procedure PaintTableCellBorders(C: TCanvas);

    // State helpers
    function GetCurrentAlignment: THTMLAlignment;
    function GetCurrentParagraphFormat: TParagraphFormat;
    function GetCurrentIsOrderedList: Boolean;
    function GetCurrentIsUnorderedList: Boolean;

    // Image support
    function RenderSVGToBitmap(const ASVGDOM: ISkSVGDOM; AWidth, AHeight: Integer): TBitmap;
    function LoadBitmapFromSrc(const ASrc: string; AWidth: Integer = 0; AHeight: Integer = 0): TBitmap;
    function LoadImage(const ASrc: string; AContext: TImageLoadContext = ilcRender; AWidth: Integer = 0; AHeight: Integer = 0): TBitmap;
    procedure PreloadImages;
    procedure PrepareImageDimensions;

    // Position helpers (run-structure-independent)
    function DocPosToAbsChar(const P: TDocPos): Integer;
    function AbsCharToDocPos(AParaIdx, AAbsChar: Integer; APreferRight: Boolean = False): TDocPos;

    // Caret & navigation
    procedure UpdateCaretXY;
    function HitTest(X, Y: Single): TDocPos;
    function LinkURLAt(X, Y: Single): string;
    function LinkTextForURL(const P: TDocPos; const URL: string): string;
    function DocPosToXY(const P: TDocPos; out X, Y, H: Single): Boolean;
    function FragmentIndexAt(ParaIdx, RunIdx, CharIdx: Integer): Integer;
    function NextDocPos(const P: TDocPos): TDocPos;
    function PrevDocPos(const P: TDocPos): TDocPos;
    function LineAbove(const P: TDocPos): TDocPos;
    function LineBelow(const P: TDocPos): TDocPos;
    function LineStart(const P: TDocPos): TDocPos;
    function LineEnd(const P: TDocPos): TDocPos;
    function DocStart: TDocPos;
    function DocEnd: TDocPos;
    function WordRight(const P: TDocPos): TDocPos;
    function WordLeft(const P: TDocPos): TDocPos;
    function PosCompare(const A, B: TDocPos): Integer;
    procedure GetSelectionRange(out S, E: TDocPos);
    procedure GetListBlockRange(out AFirst, ALast: Integer);
    procedure RenumberListBlock(AFirst, ALast: Integer);

    // Editing
    procedure InsertChar(Ch: Char);
    procedure InsertString(const S: string);
    procedure DeleteBack;
    procedure DeleteForward;
    procedure DeleteSelection;
    function GetFullHTML: string;
    procedure SetFullHTML(const V: string);
    function GetSelectionHTML: string;
    function GetSelectionText: string;
    procedure InsertParagraphBreak;
    procedure InsertLineBreak;
    procedure MergeWithPrevious(ParaIdx: Integer);

    // Search helpers
    function ParagraphSearchText(AParaIdx: Integer): string;
    procedure SelectRange(const AStart, AEnd: TDocPos);

    // Style helpers
    procedure ApplyFormatToSelection(ABold, AItalic, AUnderline, AStrikeOut, ASuperscript, ASubscript: Integer; // -1=no DoChange, 0=off, 1=on
      const AFontName: string; AFontSize: Single; // ''/ 0 = no DoChange
      AColor, ABackgroundColor: TAlphaColor; // claNull = no DoChange
      const ALinkURL: string = #0); // #0 = no DoChange
    procedure SplitRunAt(ParaIdx, RunIdx, CharIdx: Integer);
    procedure NormalizeRuns(ParaIdx: Integer);

    // Undo
    procedure ClearRedo;

    // Timer
    procedure OnCaretTick(Sender: TObject);

    // Scrollbar
    procedure UpdateScrollBar;
    procedure ScrollTo(Y: Single);
    procedure OnScrollChange(Sender: TObject);

    // Properties
    function GetHTML: string;
    procedure SetHTML(const V: string);
    procedure SetLineSpacing(const V: Single);
    procedure SetParagraphSpacing(const V: Single);
    procedure SetReadOnly(const V: Boolean);
    procedure SetBackgroundColor(const V: TAlphaColor);
    procedure SetFontColor(const V: TAlphaColor);
    procedure SetFont(const V: TFont);
    procedure FontChanged(Sender: TObject);

    // Placeholder
    procedure SetPlaceholderPrefix(const V: string);
    procedure SetPlaceholderSuffix(const V: string);
    procedure AppearanceChanged(Sender: TObject);
    procedure ScanForPlaceholders(Doc: THTMLDocument);
    procedure RebuildPlaceholderList;
    function GetPlaceholderLabel(const RawText: string): string;
    function GetCurrentRun: THTMLRun;
    procedure PaintPlaceholderFragment(C: TCanvas; const F: TLayoutFrag);

    // Word / line selection
    function CharAtPos(const P: TDocPos): Char;
    procedure SelectWordAt(const P: TDocPos);
    procedure SelectParagraphAt(const P: TDocPos);

    // Context menu
    procedure BuildContextMenu;
    procedure UpdateContextMenuState;
    procedure ContextMenuItemClick(Sender: TObject);

    // Full-document import/export
    procedure ScanDocumentMeta(const AHTML: string; out ATitle, ALang: string);

    // Table helpers
    procedure GetTableBounds(ATableID: Integer; out AFirstIdx, ALastIdx: Integer);
    function FindFirstCellInRow(ATableID, ARow: Integer): Integer;

    // Misc
    function EnsureValidDocument: Boolean;

  protected
    procedure DoChanged;
    procedure DoNotifyState;

    // Layout & rendering
    procedure DoLayout;
    procedure InvalidateRender;
    procedure PaintBackground(C: TCanvas);
    procedure PaintBorder(C: TCanvas);
    procedure PaintCaret(C: TCanvas);
    procedure PaintFragment(C: TCanvas; const F: TLayoutFrag);

    // State & style
    function GetState: TEditorState;
    function StyleAtCaret: THTMLTextStyle;

    // Editing support
    procedure EnsureCaretVisible;
    procedure SaveUndo;
    procedure SetCaretPos(const P: TDocPos; ExtendSel: Boolean);

    // Table navigation
    function DoTableTab(AShift: TShiftState): Boolean;
    function IsTableCellOf(AParaIdx, ATableID: Integer): Boolean;

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
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // -- Formatting ---------------------------------------------------------
    procedure ToggleBold;
    procedure ToggleItalic;
    procedure ToggleUnderline;
    procedure ToggleStrikeOut;
    procedure ToggleSuperscript;
    procedure ToggleSubscript;
    procedure DecreaseFontSize;
    procedure IncreaseFontSize;
    procedure SetCurrentFontName(const Name: string);
    procedure SetCurrentFontSize(Size: Single);
    procedure SetCurrentFontColor(Color: TAlphaColor);
    procedure SetCurrentBackgroundColor(Color: TAlphaColor);
    procedure ClearFormatting;
    procedure AlignLeft;
    procedure AlignCenter;
    procedure AlignRight;
    procedure AlignJustify;
    procedure SetHeading(Level: Integer); // 0=p, 1..6=h1..h6 (legacy -- prefer SetCurrentParagraphFormat)
    procedure SetCurrentParagraphFormat(AFormat: TParagraphFormat);
    procedure ToggleOrderedList;
    procedure ToggleUnorderedList;
    procedure Indent;
    procedure Outdent;
    procedure InsertHorizontalRule(AColor: TAlphaColor = claNull; AThickness: Single = 0);
    procedure InsertImage(const ASrc: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
    procedure InsertInlineImage(const ASrc: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
    procedure UpdateImage(const ASrc: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
    procedure ReloadImages;
    procedure InsertTable(ARows: Integer = 2; ACols: Integer = 2);
    procedure InsertTableRow;
    procedure DeleteTableRow;
    procedure InsertTableColumn;
    procedure DeleteTableColumn;
    procedure InsertLink(const AURL, AText: string);
    procedure UpdateLink(const AURL: string);
    procedure RemoveLink;
    function GetLinkAtCaret: string;
    procedure InsertText(const S: string);
    procedure InsertHTML(const HTML: string);
    procedure InsertPlaceholder(const RawText: string; const ADisplayName: string = '');
    procedure UpdatePlaceholder(const ANewRawText: string; const ANewDisplayName: string = '');

    // -- Editing ------------------------------------------------------------
    procedure SelectAll;
    procedure ClearSelection;
    procedure Undo;
    procedure Redo;
    procedure Cut;
    procedure Copy;
    procedure Paste;
    procedure PasteAsPlainText;

    // -- Navigation ---------------------------------------------------------
    procedure ScrollToParagraph(AIndex: Integer);
    procedure ScrollToDocPos(const APos: TDocPos);

    // -- Document info -------------------------------------------------------
    function CharCount: Integer;
    function WordCount: Integer;

    // -- Images -------------------------------------------------------------
    procedure LoadRemoteImages;

    // -- Search -------------------------------------------------------------
    function FindNext(const AText: string; ACaseSensitive: Boolean = False): Boolean;
    function FindPrev(const AText: string; ACaseSensitive: Boolean = False): Boolean;
    function ReplaceAll(const AFindText, AReplaceText: string; ACaseSensitive: Boolean = False): Integer;

    property CurrentRun: THTMLRun read GetCurrentRun;
    property FullHTML: string read GetFullHTML write SetFullHTML;
    property HasSelection: Boolean read FHasSelection;
    property Placeholders: TList<THTMLRun> read FPlaceholders;
    property SelHTML: string read GetSelectionHTML;
    property SelText: string read GetSelectionText;
    property State: TEditorState read GetState;

  published
    property BackgroundColor: TAlphaColor read FBackgroundColor write SetBackgroundColor default claWhite;
    property FontColor: TAlphaColor read FFontColor write SetFontColor default claBlack;
    property Font: TFont read FFont write SetFont;
    property HTML: string read GetHTML write SetHTML;
    property Lang: string read FLang write FLang;
    property LineSpacing: Single read FLineSpacing write SetLineSpacing;
    property ParagraphSpacing: Single read FParagraphSpacing write SetParagraphSpacing;
    property PlaceholderAppearance: TPlaceholderAppearance read FPlaceholderAppearance write FPlaceholderAppearance;
    property PlaceholderPrefix: string read FPlaceholderPrefix write SetPlaceholderPrefix;
    property PlaceholderSuffix: string read FPlaceholderSuffix write SetPlaceholderSuffix;
    property PrettyHTML: Boolean read FPrettyHTML write FPrettyHTML default False;
    property AutoLoadRemoteImages: Boolean read FAutoLoadRemoteImages write FAutoLoadRemoteImages default True;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property ShowBorder: Boolean read FShowBorder write FShowBorder default True;
    property Title: string read FTitle write FTitle;
    property Align;
    property Anchors;
    property Height;
    property Margins;
    property Opacity;
    property Padding;
    property Position;
    property Size;
    property Visible;
    property Width;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnDrawListMarker: TDrawListMarkerEvent read FOnDrawListMarker write FOnDrawListMarker;
    property OnDrawPlaceholder: TDrawPlaceholderEvent read FOnDrawPlaceholder write FOnDrawPlaceholder;
    property OnGetListMarker: TGetListMarkerEvent read FOnGetListMarker write FOnGetListMarker;
    property OnGetPlaceholderLabel: TGetPlaceholderLabelEvent read FOnGetPlaceholderLabel write FOnGetPlaceholderLabel;
    property OnLinkClick: TLinkClickEvent read FOnLinkClick write FOnLinkClick;
    property OnLinkHover: TLinkHoverEvent read FOnLinkHover write FOnLinkHover;
    property OnLoadImage: TLoadImageEvent read FOnLoadImage write FOnLoadImage;
    property OnStateChange: TEditorStateEvent read FOnStateChange write FOnStateChange;
    property OnResize;
    property OnClick;
    property OnDblClick;
  end;

implementation

// -----------------------------------------------------------------------------
// FMX helper for THTMLTextStyle
// -----------------------------------------------------------------------------

function TextStyleToFMXFontStyle(const AStyle: THTMLTextStyle): TFontStyles;
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
// TUndoEntry
// -----------------------------------------------------------------------------

constructor TUndoEntry.Create(ADoc: THTMLDocument; const ACaret, ASS, ASE: TDocPos);
begin
  inherited Create;
  Doc := ADoc;
  CaretPos := ACaret;
  SelStart := ASS;
  SelEnd := ASE;
end;

destructor TUndoEntry.Destroy;
begin
  Doc.Free;
  inherited;
end;

// -----------------------------------------------------------------------------
// TPlaceholderAppearance
// -----------------------------------------------------------------------------

constructor TPlaceholderAppearance.Create;
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

procedure TPlaceholderAppearance.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPlaceholderAppearance.Assign(Source: TPersistent);
var
  LSourceAppearance: TPlaceholderAppearance;
begin
  if Source is TPlaceholderAppearance then
  begin
    LSourceAppearance := TPlaceholderAppearance(Source);
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

procedure TPlaceholderAppearance.SetFillColor(V: TAlphaColor);
begin
  if FFillColor <> V then
  begin
    FFillColor := V;
    Changed;
  end;
end;

procedure TPlaceholderAppearance.SetTextColor(V: TAlphaColor);
begin
  if FTextColor <> V then
  begin
    FTextColor := V;
    Changed;
  end;
end;

procedure TPlaceholderAppearance.SetBorderColor(V: TAlphaColor);
begin
  if FBorderColor <> V then
  begin
    FBorderColor := V;
    Changed;
  end;
end;

procedure TPlaceholderAppearance.SetBorderRadius(V: Single);
begin
  if FBorderRadius <> V then
  begin
    FBorderRadius := V;
    Changed;
  end;
end;

procedure TPlaceholderAppearance.SetHorizontalPadding(V: Single);
begin
  if FHorizontalPadding <> V then
  begin
    FHorizontalPadding := V;
    Changed;
  end;
end;

procedure TPlaceholderAppearance.SetVerticalPadding(V: Single);
begin
  if FVerticalPadding <> V then
  begin
    FVerticalPadding := V;
    Changed;
  end;
end;

procedure TPlaceholderAppearance.SetBold(V: Boolean);
begin
  if FBold <> V then
  begin
    FBold := V;
    Changed;
  end;
end;

// -----------------------------------------------------------------------------
// TLayoutEngine
// -----------------------------------------------------------------------------

constructor TLayoutEngine.Create;
begin
  inherited;
  FMeasure := TTextLayoutManager.DefaultTextLayout.Create;
  FMeasureCache := TDictionary<string, TSizeF>.Create;
  FLineSpacing := C_EDITOR_LINE_SPACING;
  FParagraphSpacing := C_EDITOR_PARA_SPACING;
end;

destructor TLayoutEngine.Destroy;
begin
  FMeasure.Free;
  FMeasureCache.Free;
  inherited;
end;

procedure TLayoutEngine.ClearMeasureCache;
begin
  FMeasureCache.Clear;
end;

procedure TLayoutEngine.SetupFont(TS: THTMLTextStyle);
begin
  FMeasure.Font.Family := TS.FontName;
  FMeasure.Font.Size := EffectiveSize(TS);
  FMeasure.Font.Style := TextStyleToFMXFontStyle(TS);
end;

function TLayoutEngine.EffectiveSize(TS: THTMLTextStyle): Single;
begin
  Result := TS.FontSize;
  if TS.Superscript or TS.Subscript then
    Result := Result * 0.65;
end;

function TLayoutEngine.HeadingSize(BT: THTMLBlockType): Single;
begin
  case BT of
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

function TLayoutEngine.MeasureStr(const S: string; TS: THTMLTextStyle): TSizeF;
var
  LEffSize: Single;
  LKey: string;
  LMeasureText: string;
  LWithSentinelW: Single;
  LSentinelW: Single;
begin
  LEffSize := EffectiveSize(TS);
  LKey := S + #0 + TS.FontName + #0 + IntToStr(Round(LEffSize * 10)) +
          #0 + Char(Ord(TS.Bold) + Ord(TS.Italic) * 2 + 1);

  if FMeasureCache.TryGetValue(LKey, Result) then
    Exit;

  FMeasure.BeginUpdate;
  FMeasure.Font.Family := TS.FontName;
  FMeasure.Font.Size := LEffSize;
  FMeasure.Font.Style := TextStyleToFMXFontStyle(TS);
  FMeasure.MaxSize := TPointF.Create(65535, 65535);
  FMeasure.WordWrap := False;

  if S = '' then
  begin
    FMeasure.Text := ' ';
    FMeasure.EndUpdate;
    Result := TSizeF.Create(0, FMeasure.Height);
  end
  else if S[High(S)] = ' ' then
  begin
    // Platform text layouts (DirectWrite, CoreText) strip trailing whitespace
    // from the bounding-box width they report. Append a sentinel glyph to
    // prevent trimming, then subtract the sentinel's own width.
    FMeasure.Text := S + 'i';
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
    LMeasureText := S;
    FMeasure.Text := LMeasureText;
    FMeasure.EndUpdate;
    Result := TSizeF.Create(FMeasure.Width, FMeasure.Height);
  end;

  FMeasureCache.Add(LKey, Result);
end;

function TLayoutEngine.MeasureCharOffset(const S: string; CharIdx: Integer; TS: THTMLTextStyle): Single;
var
  LSub: string;
begin
  if (CharIdx <= 0) or (S = '') then
    Exit(0);
  LSub := S.Substring(0, Min(CharIdx, S.Length));
  Result := MeasureStr(LSub, TS).Width;
end;

function TLayoutEngine.CharAtX(const S: string; X: Single; TS: THTMLTextStyle): Integer;
var
  LLow, LHigh, LMid: Integer;
  LWidth: Single;
  LWidth0: Single;
  LWidth1: Single;
begin
  if S = '' then
    Exit(0);
  if X <= 0 then
    Exit(0);
  LLow := 0;
  LHigh := S.Length;
  while LLow < LHigh do
  begin
    LMid := (LLow + LHigh + 1) div 2;
    LWidth := MeasureStr(S.Substring(0, LMid), TS).Width;
    if LWidth <= X then
      LLow := LMid
    else
      LHigh := LMid - 1;
  end;
  // Snap to nearer side
  if LLow < S.Length then
  begin
    LWidth0 := MeasureStr(S.Substring(0, LLow), TS).Width;
    LWidth1 := MeasureStr(S.Substring(0, LLow + 1), TS).Width;
    if (X - LWidth0) > (LWidth1 - X) then
      Inc(LLow);
  end;
  Result := LLow;
end;

procedure TLayoutEngine.LayoutParagraph(Para: THTMLParagraph; ParaIdx: Integer; AvailW, StartY: Single;
  var Lines: TArray<TLayoutLine>; var Frags: TArray<TLayoutFrag>; var Y: Single);

  procedure FlushLine(var ALineFrags: TArray<TLayoutFrag>; ALineW, ALineH, ALineAsc: Single;
    AIsFirst, AIsLast: Boolean);
  var
    LLine: TLayoutLine;
    LFragment: TLayoutFrag;
    LXOffset: Single;
    LExtraX: Single;
    LIndentX: Single;
    LEffW: Single;
    LCurX: Single;
    LNonSpaceFrags: Integer;
    LSpaceSum: Single;
    LFragStart: Integer;
    LLineIdx: Integer;
  begin
    if Length(ALineFrags) = 0 then
      Exit;

    if Para.BlockType = btLI then
      LIndentX := (Para.IndentLevel + 2) * C_EDITOR_LIST_INDENT
    else
      LIndentX := Para.IndentLevel * C_EDITOR_BLOCKQUOTE_INDENT;
    LEffW := AvailW - LIndentX;

    LXOffset := LIndentX;
    LExtraX := 0;
    case Para.Alignment of
      haCenter:
        LXOffset := LIndentX + (LEffW - ALineW) / 2;
      haRight:
        LXOffset := LIndentX + LEffW - ALineW;
      haJustify:
        if (not AIsLast) and (Length(ALineFrags) > 1) then
        begin
          LNonSpaceFrags := 0;
          LSpaceSum := 0;
          for var I := 0 to High(ALineFrags) do
          begin
            Inc(LNonSpaceFrags);
            LSpaceSum := LSpaceSum + ALineFrags[I].W;
          end;
          if LNonSpaceFrags > 1 then
            LExtraX := (LEffW - LSpaceSum) / (LNonSpaceFrags - 1);
        end;
    end;

    LFragStart := Length(Frags);
    LLineIdx := Length(Lines);
    LCurX := LXOffset;
    LLine.Y := Y;
    LLine.H := ALineH * FLineSpacing;
    LLine.Ascent := ALineAsc;
    LLine.ParaIdx := ParaIdx;
    LLine.IsFirst := AIsFirst;
    LLine.IsLast := AIsLast;
    LLine.FragStart := LFragStart;
    LLine.FragCount := Length(ALineFrags);
    SetLength(Frags, LFragStart + Length(ALineFrags));

    for var I := 0 to High(ALineFrags) do
    begin
      LFragment := ALineFrags[I];
      LFragment.X := LCurX;
      LFragment.Y := Y;
      LFragment.LineIdx := LLineIdx;
      LCurX := LCurX + LFragment.W;
      if I < High(ALineFrags) then
        LCurX := LCurX + LExtraX;
      Frags[LFragStart + I] := LFragment;
    end;

    SetLength(Lines, Length(Lines) + 1);
    Lines[High(Lines)] := LLine;
    Y := Y + LLine.H;
    SetLength(ALineFrags, 0);
  end;

  function FindWordEnd(const S: string; AStart: Integer): Integer;
  begin
    Result := AStart;
    while (Result < S.Length) and (S[Low(S) + Result] <> ' ') do
      Inc(Result);
    while (Result < S.Length) and (S[Low(S) + Result] = ' ') do
      Inc(Result);
  end;

var
  LIndentX: Single;
  LRunIdx: Integer;
  LCharOfs: Integer;
  LTextStyle: THTMLTextStyle;
  LWord, LRest: string;
  LWSize: TSizeF;
  LLineFrags: TArray<TLayoutFrag>;
  LLineW: Single;
  LLineH: Single;
  LLineAsc: Single;
  LIsFirstLine: Boolean;
  LFragment: TLayoutFrag;
  LSepIdx: Integer;
  LEffAvail: Single;
  LHF: TLayoutFrag;
  LHLn: TLayoutLine;
  LES: THTMLTextStyle;
  LEH: Single;
  LEF: TLayoutFrag;
  LHS: Single;
  LBH: Single;
  LLastRI2: Integer;
  LES2: THTMLTextStyle;
  LEH2: Single;
  LEF3: TLayoutFrag;
  LLabelText: string;
  LPhTS: THTMLTextStyle;
  LTSize: TSizeF;
  LPhW: Single;
  LPhH: Single;
  LImgW: Integer;
  LImgH: Integer;
  LImgX: Single;

begin
  LIndentX := Para.IndentLevel * C_EDITOR_BLOCKQUOTE_INDENT;
  if Para.BlockType = btLI then
    LIndentX := (Para.IndentLevel + 2) * C_EDITOR_LIST_INDENT;

  LEffAvail := AvailW - LIndentX;
  if LEffAvail < 20 then
    LEffAvail := 20;

  if Para.BlockType = btHR then
  begin
    LHF := Default(TLayoutFrag);
    LHF.ParaIdx := ParaIdx;
    LHF.RunIdx := -1;
    LHF.CharStart := 0;
    LHF.CharEnd := 0;
    LHF.X := LIndentX;
    LHF.Y := Y;
    LHF.W := LEffAvail;
    LHF.H := 16;
    LHF.Ascent := 8;
    LHF.LineIdx := Length(Lines);
    LHF.IsHR := True;
    SetLength(Frags, Length(Frags) + 1);
    Frags[High(Frags)] := LHF;

    LHLn.Y := Y;
    LHLn.H := 16;
    LHLn.Ascent := 8;
    LHLn.ParaIdx := ParaIdx;
    LHLn.IsFirst := True;
    LHLn.IsLast := True;
    LHLn.FragStart := Length(Frags) - 1;
    LHLn.FragCount := 1;
    SetLength(Lines, Length(Lines) + 1);
    Lines[High(Lines)] := LHLn;
    Y := Y + 16 + FParagraphSpacing;
    Exit;
  end;

  if Para.BlockType = btImage then
  begin
    LImgW := Para.ImageWidth;
    LImgH := Para.ImageHeight;
    if LImgW = 0 then
      LImgW := Round(LEffAvail);
    if LImgH = 0 then
      LImgH := 100;
    if LImgW > Round(LEffAvail) then
      LImgW := Round(LEffAvail);
    case Para.Alignment of
      haCenter: LImgX := LIndentX + (LEffAvail - LImgW) / 2;
      haRight:  LImgX := LIndentX + LEffAvail - LImgW;
    else
      LImgX := LIndentX;
    end;
    LHF := Default(TLayoutFrag);
    LHF.ParaIdx := ParaIdx;
    LHF.RunIdx := -1;
    LHF.CharStart := 0;
    LHF.CharEnd := 0;
    LHF.X := LImgX;
    LHF.Y := Y;
    LHF.W := LImgW;
    LHF.H := LImgH;
    LHF.Ascent := LImgH;
    LHF.LineIdx := Length(Lines);
    LHF.IsImage := True;
    SetLength(Frags, Length(Frags) + 1);
    Frags[High(Frags)] := LHF;

    LHLn.Y := Y;
    LHLn.H := LImgH;
    LHLn.Ascent := LImgH;
    LHLn.ParaIdx := ParaIdx;
    LHLn.IsFirst := True;
    LHLn.IsLast := True;
    LHLn.FragStart := Length(Frags) - 1;
    LHLn.FragCount := 1;
    SetLength(Lines, Length(Lines) + 1);
    Lines[High(Lines)] := LHLn;
    Y := Y + LImgH + FParagraphSpacing;
    Exit;
  end;

  if (ParaIdx > 0) and (Para.BlockType in [btParagraph, btH1, btH2, btH3, btH4, btH5, btH6, btBlockquote, btPre]) then
    Y := Y + FParagraphSpacing;

  LLineFrags := nil;
  LLineW := 0;
  LLineH := 0;
  LLineAsc := 0;
  LIsFirstLine := True;

  if Para.Runs.Count = 0 then
  begin
    LES.Init;
    LEH := MeasureStr(' ', LES).Height;
    LEF := Default (TLayoutFrag);
    LEF.ParaIdx := ParaIdx;
    LEF.RunIdx := 0;
    LEF.CharStart := 0;
    LEF.CharEnd := 0;
    LEF.X := LIndentX;
    LEF.Y := Y;
    LEF.W := 0;
    LEF.H := LEH;
    LEF.Ascent := LEH * 0.75;
    LEF.LineIdx := Length(Lines);
    SetLength(LLineFrags, 1);
    LLineFrags[0] := LEF;
    FlushLine(LLineFrags, 0, LEH, LEH * 0.75, True, True);
    Exit;
  end;

  LRunIdx := 0;
  LCharOfs := 0;

  for var LRun in Para.Runs do
  begin
    LTextStyle := LRun.Style;
    LHS := HeadingSize(Para.BlockType);
    if LHS > 0 then
    begin
      LTextStyle.FontSize := LHS;
      LTextStyle.Bold := True;
    end;
    if Para.BlockType = btPre then
      LTextStyle.FontName := 'Courier New';

    if LRun.IsLineBreak then
    begin
      LBH := MeasureStr(' ', LTextStyle).Height;
      FlushLine(LLineFrags, LLineW, Max(LLineH, LBH), Max(LLineAsc, LBH * 0.75), LIsFirstLine, False);
      LIsFirstLine := False;
      LLineW := 0;
      LLineH := 0;
      LLineAsc := 0;
      Inc(LRunIdx);
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
      LPhTS := LTextStyle;
      LPhTS.Bold := LRun.Style.Bold or FPlaceholderBold;
      LPhTS.Italic := LRun.Style.Italic;
      LTSize := MeasureStr(LLabelText, LPhTS);
      LPhW := LTSize.Width + 2 * FPlaceholderPaddingH;
      LPhH := Max(LTSize.Height + 2 * FPlaceholderPaddingV, LTSize.Height);
      if (LLineW > 0) and (LLineW + LPhW > LEffAvail + 0.5) then
      begin
        FlushLine(LLineFrags, LLineW, LLineH, LLineAsc, LIsFirstLine, False);
        LIsFirstLine := False;
        LLineW := 0;
        LLineH := 0;
        LLineAsc := 0;
      end;
      LFragment := Default (TLayoutFrag);
      LFragment.ParaIdx := ParaIdx;
      LFragment.RunIdx := LRunIdx;
      LFragment.CharStart := 0;
      LFragment.CharEnd := LRun.Text.Length;
      LFragment.X := LIndentX + LLineW;
      LFragment.Y := Y;
      LFragment.W := LPhW;
      LFragment.H := LPhH;
      LFragment.Ascent := LPhH * 0.78;
      LFragment.IsPlaceholder := True;
      SetLength(LLineFrags, Length(LLineFrags) + 1);
      LLineFrags[High(LLineFrags)] := LFragment;
      LLineW := LLineW + LPhW;
      LLineH := Max(LLineH, LPhH);
      LLineAsc := Max(LLineAsc, LFragment.Ascent);
      Inc(LRunIdx);
    end
    else if LRun.IsImage then
    begin
      LImgW := LRun.ImageWidth;
      LImgH := LRun.ImageHeight;
      if LImgW <= 0 then LImgW := 100;
      if LImgH <= 0 then LImgH := 50;
      if (LLineW > 0) and (LLineW + LImgW > LEffAvail + 0.5) then
      begin
        FlushLine(LLineFrags, LLineW, LLineH, LLineAsc, LIsFirstLine, False);
        LIsFirstLine := False;
        LLineW := 0;
        LLineH := 0;
        LLineAsc := 0;
      end;
      LFragment := Default(TLayoutFrag);
      LFragment.ParaIdx := ParaIdx;
      LFragment.RunIdx := LRunIdx;
      LFragment.CharStart := 0;
      LFragment.CharEnd := 1;
      LFragment.X := LIndentX + LLineW;
      LFragment.Y := Y;
      LFragment.W := LImgW;
      LFragment.H := LImgH;
      LFragment.Ascent := LImgH;
      LFragment.IsImage := True;
      SetLength(LLineFrags, Length(LLineFrags) + 1);
      LLineFrags[High(LLineFrags)] := LFragment;
      LLineW := LLineW + LImgW;
      LLineH := Max(LLineH, LImgH);
      LLineAsc := Max(LLineAsc, LImgH);
      Inc(LRunIdx);
    end
    else
    begin
      LRest := LRun.Text;
      LCharOfs := 0;

      while LRest <> '' do
      begin
        if Para.BlockType = btPre then
          LSepIdx := LRest.Length
        else
        begin
          LSepIdx := FindWordEnd(LRest, 0);
          if LSepIdx = 0 then
            LSepIdx := LRest.Length;
        end;
        LWord := LRest.Substring(0, LSepIdx);
        LRest := LRest.Substring(LSepIdx);
        LWSize := MeasureStr(LWord, LTextStyle);

        if (LLineW > 0) and (LLineW + LWSize.Width > LEffAvail + 0.5) then
        begin
          FlushLine(LLineFrags, LLineW, LLineH, LLineAsc, LIsFirstLine, False);
          LIsFirstLine := False;
          LLineW := 0;
          LLineH := 0;
          LLineAsc := 0;
        end;

        LFragment.ParaIdx := ParaIdx;
        LFragment.RunIdx := LRunIdx;
        LFragment.CharStart := LCharOfs;
        LFragment.CharEnd := LCharOfs + LWord.Length;
        LFragment.X := LIndentX + LLineW;
        LFragment.Y := Y;
        LFragment.W := LWSize.Width;
        LFragment.H := LWSize.Height;
        LFragment.Ascent := LWSize.Height * 0.78;
        LFragment.LineIdx := -1;
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

      Inc(LRunIdx);
    end;
  end;

  if Length(LLineFrags) > 0 then
    FlushLine(LLineFrags, LLineW, Max(LLineH, 12), Max(LLineAsc, 9), LIsFirstLine, True)
  else if (Length(Lines) = 0) or ((Para.Runs.Count > 0) and not LIsFirstLine) then
  begin
    LLastRI2 := Para.Runs.Count - 1;
    LES2.Init;
    if Para.Runs.Count > 0 then
      LES2 := Para.Runs[LLastRI2].Style;
    LEH2 := MeasureStr(' ', LES2).Height;
    LEF3 := Default (TLayoutFrag);
    LEF3.ParaIdx := ParaIdx;
    LEF3.RunIdx := LLastRI2;
    LEF3.CharStart := 0;
    LEF3.CharEnd := 0;
    LEF3.X := LIndentX;
    LEF3.Y := Y;
    LEF3.W := 0;
    LEF3.H := LEH2;
    LEF3.Ascent := LEH2 * 0.75;
    SetLength(LLineFrags, 1);
    LLineFrags[0] := LEF3;
    FlushLine(LLineFrags, 0, LEH2, LEH2 * 0.75, LIsFirstLine, True);
  end;
end;

procedure TLayoutEngine.LayoutTable(Doc: THTMLDocument; AFirstParaIdx: Integer;
  AvailW: Single; var Lines: TArray<TLayoutLine>; var Frags: TArray<TLayoutFrag>;
  var Y: Single; out ANextParaIdx: Integer);
var
  LTableID: Integer;
  LCols: Integer;
  LLastPI: Integer;
  LMaxRow: Integer;
  LPI: Integer;
  LParagraph: THTMLParagraph;
  LCellW: Single;
  LCellPad: Single;
  LRow: Integer;
  LCol: Integer;
  LCellPI: Integer;
  LRowStartY: Single;
  LRowH: Single;
  LCellLocalLines: array of TArray<TLayoutLine>;
  LCellLocalFrags: array of TArray<TLayoutFrag>;
  LCellHeights: array of Single;
  LLocalLines: TArray<TLayoutLine>;
  LLocalFrags: TArray<TLayoutFrag>;
  LLocalY: Single;
  LGlobalFragOffset: Integer;
  LGlobalLineOffset: Integer;
  LXOffset: Single;
  LYOffset: Single;
  LLine: TLayoutLine;
  LFragment: TLayoutFrag;
  I: integer;
begin
  LTableID := Doc.Paragraphs[AFirstParaIdx].TableID;
  LCols := Doc.Paragraphs[AFirstParaIdx].TableCols;
  if LCols < 1 then
    LCols := 1;
  LCellPad := C_DEFAULT_TABLE_CELL_PADDING;
  LCellW := AvailW / LCols;

  // Find last para index of this table and max row
  LLastPI := AFirstParaIdx;
  LMaxRow := 0;
  LPI := AFirstParaIdx;
  while LPI < Doc.Paragraphs.Count do
  begin
    LParagraph := Doc.Paragraphs[LPI];
    if (LParagraph.BlockType <> btTableCell) or (LParagraph.TableID <> LTableID) then
      LPI := Doc.Paragraphs.Count // exit condition
    else
    begin
      LLastPI := LPI;
      if LParagraph.TableRow > LMaxRow then
        LMaxRow := LParagraph.TableRow;
      Inc(LPI);
    end;
  end;

  ANextParaIdx := LLastPI + 1;

  SetLength(LCellLocalLines, LCols);
  SetLength(LCellLocalFrags, LCols);
  SetLength(LCellHeights, LCols);

  // Process row by row
  for LRow := 0 to LMaxRow do
  begin
    LRowStartY := Y;

    // Layout each cell independently
    for LCol := 0 to LCols - 1 do
    begin
      LCellLocalLines[LCol] := nil;
      LCellLocalFrags[LCol] := nil;
      LCellHeights[LCol] := 0;
      // Find the para for (LRow, LCol)
      LCellPI := -1;
      LPI := AFirstParaIdx;
      while (LPI <= LLastPI) and (LCellPI < 0) do
      begin
        LParagraph := Doc.Paragraphs[LPI];
        if (LParagraph.TableID = LTableID) and (LParagraph.TableRow = LRow) and (LParagraph.TableCol = LCol) then
          LCellPI := LPI
        else
          Inc(LPI);
      end;
      if LCellPI >= 0 then
      begin
        LLocalLines := nil;
        LLocalFrags := nil;
        LLocalY := 0;
        LayoutParagraph(Doc.Paragraphs[LCellPI], LCellPI,
          LCellW - 2 * LCellPad, 0, LLocalLines, LLocalFrags, LLocalY);
        LCellLocalLines[LCol] := LLocalLines;
        LCellLocalFrags[LCol] := LLocalFrags;
        LCellHeights[LCol] := LLocalY;
      end;
    end;

    // Row height = max cell content height + 2*padding, minimum C_DEFAULT_TABLE_MIN_ROW_HEIGHT
    LRowH := C_DEFAULT_TABLE_MIN_ROW_HEIGHT;
    for LCol := 0 to LCols - 1 do
      if LCellHeights[LCol] + 2 * LCellPad > LRowH then
        LRowH := LCellHeights[LCol] + 2 * LCellPad;

    // Merge each cell's layout into global arrays
    for LCol := 0 to LCols - 1 do
    begin
      LXOffset := LCol * LCellW + LCellPad;
      LYOffset := LRowStartY + LCellPad;
      LGlobalFragOffset := Length(Frags);
      LGlobalLineOffset := Length(Lines);

      // Append frags with adjusted X/Y and fixed LineIdx
      SetLength(Frags, Length(Frags) + Length(LCellLocalFrags[LCol]));
      for I := 0 to High(LCellLocalFrags[LCol]) do
      begin
        LFragment := LCellLocalFrags[LCol][I];
        LFragment.X := LFragment.X + LXOffset;
        LFragment.Y := LFragment.Y + LYOffset;
        LFragment.LineIdx := LFragment.LineIdx + LGlobalLineOffset;
        Frags[LGlobalFragOffset + I] := LFragment;
      end;

      // Append lines with adjusted Y, fixed FragStart, and cell geometry
      SetLength(Lines, Length(Lines) + Length(LCellLocalLines[LCol]));
      for I := 0 to High(LCellLocalLines[LCol]) do
      begin
        LLine := LCellLocalLines[LCol][I];
        LLine.Y := LLine.Y + LYOffset;
        LLine.FragStart := LLine.FragStart + LGlobalFragOffset;
        LLine.CellX := LCol * LCellW;
        LLine.CellW := LCellW;
        LLine.CellRowY := LRowStartY;
        LLine.CellRowH := LRowH;
        Lines[LGlobalLineOffset + I] := LLine;
      end;
    end;

    Y := Y + LRowH;
  end;

  // Add inter-table spacing
  Y := Y + FParagraphSpacing;
end;

procedure TLayoutEngine.DoLayout(Doc: THTMLDocument; AvailW: Single; out Lines: TArray<TLayoutLine>;
  out Frags: TArray<TLayoutFrag>; out TotalH: Single);
var
  LYPosition: Single;
  LPara: THTMLParagraph;
  LParaIdx: Integer;
  LNextIdx: Integer;
begin
  Lines := nil;
  Frags := nil;
  LYPosition := 0;

  LParaIdx := 0;
  while LParaIdx < Doc.Paragraphs.Count do
  begin
    LPara := Doc.Paragraphs[LParaIdx];
    if LPara.BlockType = btTableCell then
    begin
      LayoutTable(Doc, LParaIdx, AvailW, Lines, Frags, LYPosition, LNextIdx);
      LParaIdx := LNextIdx;
    end
    else
    begin
      LayoutParagraph(LPara, LParaIdx, AvailW, LYPosition, Lines, Frags, LYPosition);
      Inc(LParaIdx);
    end;
  end;

  TotalH := LYPosition + FParagraphSpacing;
end;

// -----------------------------------------------------------------------------
// THTMLEditor
// -----------------------------------------------------------------------------

constructor THTMLEditor.Create(AOwner: TComponent);
var
  LParagraph: THTMLParagraph;
begin
  inherited;
  StyleLookup := ''; // no style - we paint entirely ourselves
  DisableFocusEffect := True; // prevent FMX from drawing its own focus rect
  CanFocus := True; // enable keyboard focus
  Cursor := crIBeam; // text-cursor pointer when hovering
  FDoc := THTMLDocument.Create;
  FLayoutEngine := TLayoutEngine.Create;
  FLineSpacing := C_EDITOR_LINE_SPACING;
  FParagraphSpacing := C_EDITOR_PARA_SPACING;
  FImageCache := TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
  FPlaceholderAppearance := TPlaceholderAppearance.Create;
  FPlaceholderAppearance.OnChange := AppearanceChanged;
  FPlaceholderPrefix := S_DEFAULT_PLACEHOLDER_PREFIX;
  FPlaceholderSuffix := S_DEFAULT_PLACEHOLDER_SUFFIX;
  FUndoStack := TObjectList<TUndoEntry>.Create(True);
  FRedoStack := TObjectList<TUndoEntry>.Create(True);
  FPlaceholders := TList<THTMLRun>.Create;
  FAutoLoadRemoteImages := True;
  FBackgroundColor := claWhite;
  FFontColor := claBlack;
  FShowBorder := True;
  FCaretPos := TDocPos.Invalid;
  FSelStart := TDocPos.Invalid;
  FSelEnd := TDocPos.Invalid;
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
  LParagraph := THTMLParagraph.Create;
  LParagraph.BlockType := btBodyText;
  FDoc.Paragraphs.Add(LParagraph);
  FCaretPos := TDocPos.At(0, 0, 0);

  Width := 400;
  Height := 300;
end;

destructor THTMLEditor.Destroy;
begin
  FCaretTimer.Free;
  FRenderCache.Free;
  FLayoutEngine.Free;
  FImageCache.Free;
  FUndoStack.Free;
  FRedoStack.Free;
  FPlaceholders.Free;
  FDoc.Free;
  FFont.Free;
  FPlaceholderAppearance.Free;
  inherited; // TStyledControl frees all child controls
end;

procedure THTMLEditor.DoEnter;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  // Always re-layout on focus: guarantees FFrags is current before
  // UpdateCaretXY runs, regardless of how focus arrived (click or Tab).
  DoLayout;
  FCaretOn := True;
  FCaretTimer.Enabled := True;
  InvalidateRender;
end;

procedure THTMLEditor.DoExit;
begin
  inherited;
  if csDesigning in ComponentState then
    Exit;
  FCaretTimer.Enabled := False;
  FCaretOn := False;
  InvalidateRender;
end;

procedure THTMLEditor.Resize;
begin
  inherited;
  DoLayout;
  InvalidateRender;
end;

procedure THTMLEditor.InvalidateRender;
begin
  FRenderDirty := True;
  Repaint;
end;

procedure THTMLEditor.OnCaretTick(Sender: TObject);
begin
  FCaretOn := not FCaretOn;
  InvalidateRender;
end;

// -- Layout -------------------------------------------------------------------

function THTMLEditor.AvailableWidth: Single;
var
  LSBW: Single;
begin
  LSBW := 0;
  if FScrollBarVisible and (FScrollBar <> nil) then
    LSBW := FScrollBar.Width;
  Result := Width - LSBW - C_EDITOR_PADDING * 2;
  if Result < 20 then
    Result := 20;
end;

function THTMLEditor.ContentLeft: Single;
begin
  Result := C_EDITOR_PADDING;
end;

function THTMLEditor.ContentTop: Single;
begin
  Result := C_EDITOR_PADDING - FScrollY;
end;

procedure THTMLEditor.DoLayout;
var
  LWasVisible: Boolean;
begin
  if FLayouting then
    Exit;
  if FDoc = nil then
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
    FLayoutEngine.DoLayout(FDoc, AvailableWidth, FLines, FFrags, FTotalHeight);
    UpdateScrollBar;
    // If scrollbar visibility changed, the available width changed too -
    // redo layout so text wraps correctly for the new width.
    if FScrollBarVisible <> LWasVisible then
    begin
      FLayoutEngine.DoLayout(FDoc, AvailableWidth, FLines, FFrags, FTotalHeight);
      UpdateScrollBar;
    end;
    UpdateCaretXY;
    EnsureCaretVisible; // scroll to show caret after every layout (typing, delete, paste...)
  finally
    FLayouting := False;
  end;
end;

procedure THTMLEditor.UpdateScrollBar;
var
  LViewH, LContentH: Single;
begin
  LViewH := Height - C_EDITOR_PADDING * 2;
  // Exclude the trailing paragraph spacing so the scrollbar does not appear
  // just because of the 6px empty margin after the last line.
  LContentH := FTotalHeight - FLayoutEngine.ParagraphSpacing;
  if LContentH > LViewH then
  begin
    FScrollBarMax := LContentH - LViewH;
    FScrollY := Max(0, Min(FScrollY, FScrollBarMax));
    FScrollBarVisible := True;
  end
  else
  begin
    FScrollBarVisible := False;
    FScrollBarMax := 0;
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
      FScrollBar.Max := FScrollBarMax;
      FScrollBar.SmallChange := C_EDITOR_SCROLL_STEP;
      FScrollBar.Value := FScrollY;
    end;
  finally
    FSyncing := False;
  end;
end;

// -- Painting -----------------------------------------------------------------

procedure THTMLEditor.Paint;
var
  LSBW: Single;
  LState: TCanvasSaveState;
  LListParagraph: THTMLParagraph;
  LFirstFragFound: Boolean;
  LMarkerX: Single;
  LMarkerY: Single;
  LTextStyle: THTMLTextStyle;
  LLayout: TTextLayout;
  LPhysW: Integer;
  LPhysH: Integer;

  procedure RenderTo(C: TCanvas);
  begin
    LState := C.SaveState;
    try
      C.IntersectClipRect(TRectF.Create(1, 1, Width - LSBW - 1, Height - 1));
      PaintBackground(C);
      PaintTableCellBorders(C);
      for var I := 0 to High(FFrags) do
      begin
        if FFrags[I].IsHR then
          PaintHorizontalRule(C, FFrags[I].Y + ContentTop, FFrags[I].W, FFrags[I].X + ContentLeft,
            FDoc.Paragraphs[FFrags[I].ParaIdx])
        else if FFrags[I].IsImage then
        begin
          if FFrags[I].RunIdx < 0 then
            PaintImage(C, FFrags[I], FDoc.Paragraphs[FFrags[I].ParaIdx])
          else
            PaintImageRun(C, FFrags[I], FDoc.Paragraphs[FFrags[I].ParaIdx].Runs[FFrags[I].RunIdx]);
        end
        else
          PaintFragment(C, FFrags[I]);
      end;
      PaintSelection(C);
      for var I := 0 to FDoc.Paragraphs.Count - 1 do
      begin
        LListParagraph := FDoc.Paragraphs[I];
        if LListParagraph.BlockType = btLI then
        begin
          LFirstFragFound := False;
          for var J := 0 to High(FFrags) do
          begin
            if (not LFirstFragFound) and (FFrags[J].ParaIdx = I) then
            begin
              LFirstFragFound := True;
              LMarkerX := FFrags[J].X + ContentLeft - C_EDITOR_LIST_INDENT;
              LMarkerY := FFrags[J].Y + ContentTop;
              LTextStyle.Init;
              if LListParagraph.Runs.Count > 0 then
                LTextStyle := LListParagraph.Runs[0].Style;
              C.Fill.Kind := TBrushKind.Solid;
              C.Fill.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
              if LListParagraph.ListOrdered then
              begin
                LLayout := TTextLayoutManager.DefaultTextLayout.Create(C);
                try
                  LLayout.BeginUpdate;
                  LLayout.Font.Family := LTextStyle.FontName;
                  LLayout.Font.Size := LTextStyle.FontSize;
                  LLayout.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
                  LLayout.WordWrap := False;
                  LLayout.MaxSize := TPointF.Create(C_EDITOR_LIST_INDENT - 2, FFrags[J].H + 4);
                  LLayout.Text := IntToStr(LListParagraph.ListIndex) + '.';
                  LLayout.TopLeft := TPointF.Create(LMarkerX, LMarkerY);
                  LLayout.EndUpdate;
                  LLayout.RenderLayout(C);
                finally
                  LLayout.Free;
                end;
              end
              else
              begin
                var LMarkerRect := TRectF.Create(LMarkerX + 2, LMarkerY + FFrags[J].H * 0.35,
                  LMarkerX + 8, LMarkerY + FFrags[J].H * 0.65);
                var LMarkerHandled := False;
                var LMarkerChar := '';
                if Assigned(FOnGetListMarker) then
                  FOnGetListMarker(Self, LListParagraph.IndentLevel, LMarkerChar, LMarkerHandled);
                if LMarkerHandled then
                begin
                  var LCharLayout := TTextLayoutManager.DefaultTextLayout.Create(C);
                  try
                    LCharLayout.BeginUpdate;
                    LCharLayout.Font.Family := LTextStyle.FontName;
                    LCharLayout.Font.Size := LTextStyle.FontSize;
                    LCharLayout.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
                    LCharLayout.WordWrap := False;
                    LCharLayout.HorizontalAlign := TTextAlign.Center;
                    LCharLayout.MaxSize := TPointF.Create(C_EDITOR_LIST_INDENT - 2, FFrags[J].H + 4);
                    LCharLayout.Text := LMarkerChar;
                    LCharLayout.TopLeft := TPointF.Create(LMarkerX, LMarkerY);
                    LCharLayout.EndUpdate;
                    LCharLayout.RenderLayout(C);
                  finally
                    LCharLayout.Free;
                  end;
                end
                else
                begin
                  if Assigned(FOnDrawListMarker) then
                    FOnDrawListMarker(Self, C, LMarkerRect, LListParagraph.IndentLevel, LMarkerHandled);
                  if not LMarkerHandled then
                    case LListParagraph.IndentLevel mod 3 of
                      0: C.FillEllipse(LMarkerRect, AbsoluteOpacity);
                      1:
                      begin
                        C.Stroke.Kind := TBrushKind.Solid;
                        C.Stroke.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
                        C.Stroke.Thickness := 1.5;
                        C.DrawEllipse(LMarkerRect, AbsoluteOpacity);
                      end;
                    else
                      C.FillRect(LMarkerRect, AbsoluteOpacity);
                    end;
                end;
              end;
            end;
          end;
        end;
      end;
      PaintCaret(C);
    finally
      C.RestoreState(LState);
    end;
    PaintBorder(C);
  end;

begin
  LSBW := 0;
  if FScrollBarVisible and (FScrollBar <> nil) then
    LSBW := FScrollBar.Width;

  LPhysW := Round(Width);
  LPhysH := Round(Height);

  if FRenderDirty
     or (FRenderCache.Width <> LPhysW)
     or (FRenderCache.Height <> LPhysH)
     or (Abs(AbsoluteOpacity - FLastPaintOpacity) > 0.001) then
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
end;

procedure THTMLEditor.PaintBackground(C: TCanvas);
begin
  C.Fill.Kind := TBrushKind.Solid;
  C.Fill.Color := FBackgroundColor;
  C.FillRect(TRectF.Create(0, 0, Width, Height), AbsoluteOpacity);
end;

procedure THTMLEditor.PaintTableCellBorders(C: TCanvas);
var
  LLine: TLayoutLine;
  LPara: THTMLParagraph;
  LRect: TRectF;
begin
  C.Stroke.Kind := TBrushKind.Solid;
  C.Stroke.Color := C_DEFAULT_TABLE_BORDER_COLOR;
  C.Stroke.Thickness := C_DEFAULT_TABLE_BORDER_WIDTH;
  C.Fill.Kind := TBrushKind.None;
  for var I := 0 to High(FLines) do
  begin
    LLine := FLines[I];
    if LLine.IsFirst and (LLine.ParaIdx < FDoc.Paragraphs.Count) then
    begin
      LPara := FDoc.Paragraphs[LLine.ParaIdx];
      if LPara.BlockType = btTableCell then
      begin
        LRect := TRectF.Create(
          LLine.CellX + ContentLeft,
          LLine.CellRowY + ContentTop,
          LLine.CellX + LLine.CellW + ContentLeft,
          LLine.CellRowY + LLine.CellRowH + ContentTop);
        C.DrawRect(LRect, 0, 0, AllCorners, AbsoluteOpacity);
      end;
    end;
  end;
end;

procedure THTMLEditor.PaintHorizontalRule(C: TCanvas; Y, W, X: Single; APara: THTMLParagraph);
var
  LColor: TAlphaColor;
  LThickness: Single;
begin
  if APara.HRColor <> claNull then
    LColor := APara.HRColor
  else
    LColor := C_DEFAULT_HR_TAG_STROKE_COLOR;
  if APara.HRThickness > 0 then
    LThickness := APara.HRThickness
  else
    LThickness := C_DEFAULT_HR_THICKNESS;
  C.Stroke.Kind := TBrushKind.Solid;
  C.Stroke.Color := LColor;
  C.Stroke.Thickness := LThickness;
  C.DrawLine(TPointF.Create(X, Y + 8), TPointF.Create(X + W, Y + 8), AbsoluteOpacity);
end;

function THTMLEditor.RenderSVGToBitmap(const ASVGDOM: ISkSVGDOM; AWidth, AHeight: Integer): TBitmap;
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

function THTMLEditor.LoadBitmapFromSrc(const ASrc: string; AWidth, AHeight: Integer): TBitmap;
var
  LComma: Integer;
  LHeader: string;
  LBase64: string;
  LBytes: TBytes;
  LStream: TBytesStream;
  LSVGText: string;
  LSVGDOM: ISkSVGDOM;
begin
  if StartsWithCI(ASrc, 'http://') or StartsWithCI(ASrc, 'https://') then
  begin
    var LClient := THTTPClient.Create;
    var LDownloadStream := TMemoryStream.Create;
    try
      LClient.Get(ASrc, LDownloadStream);
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
    if ASrc.StartsWith('data:') then
    begin
      LComma := ASrc.IndexOf(',');
      if LComma >= 0 then
      begin
        LHeader := ASrc.Substring(0, LComma).ToLower;
        if LHeader.Contains('svg') then
        begin
          FreeAndNil(Result);
          if LHeader.Contains(';base64') then
          begin
            LBytes := TNetEncoding.Base64.DecodeStringToBytes(ASrc.Substring(LComma + 1));
            LSVGText := TEncoding.UTF8.GetString(LBytes);
          end
          else
            LSVGText := TNetEncoding.URL.Decode(ASrc.Substring(LComma + 1));
          LSVGDOM := TSkSVGDOM.Make(LSVGText);
          Result := RenderSVGToBitmap(LSVGDOM, AWidth, AHeight);
        end
        else if LHeader.Contains(';base64') then
        begin
          LBase64 := ASrc.Substring(LComma + 1);
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
    else if ASrc.ToLower.EndsWith('.svg') then
    begin
      FreeAndNil(Result);
      LSVGDOM := TSkSVGDOM.MakeFromFile(ASrc);
      Result := RenderSVGToBitmap(LSVGDOM, AWidth, AHeight);
    end
    else
      Result.LoadFromFile(ASrc);
  except
    FreeAndNil(Result);
  end;
end;

function THTMLEditor.LoadImage(const ASrc: string; AContext: TImageLoadContext; AWidth, AHeight: Integer): TBitmap;
begin
  if ASrc = '' then
    Exit(nil);
  if FImageCache.TryGetValue(ASrc, Result) then
    Exit;
  if not FAutoLoadRemoteImages and
     (StartsWithCI(ASrc, 'http://') or StartsWithCI(ASrc, 'https://')) then
    Exit(nil);
  Result := LoadBitmapFromSrc(ASrc, AWidth, AHeight);
  if Assigned(FOnLoadImage) then
    FOnLoadImage(Self, ASrc, Result, AContext);
  if Assigned(Result) then
    FImageCache.Add(ASrc, Result);
end;

procedure THTMLEditor.PreloadImages;
const
  C_DEFAULT_DEFERRED_IMAGE_WIDTH  = 200;
  C_DEFAULT_DEFERRED_IMAGE_HEIGHT = 120;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LBmp: TBitmap;
  LDeferred: Boolean;
begin
  for LPara in FDoc.Paragraphs do
  begin
    if (LPara.BlockType = btImage) and (LPara.ImageSrc <> '') then
    begin
      LDeferred := not FAutoLoadRemoteImages and
                   (StartsWithCI(LPara.ImageSrc, 'http://') or StartsWithCI(LPara.ImageSrc, 'https://'));
      if LDeferred then
      begin
        if LPara.ImageWidth = 0 then
          LPara.ImageWidth := C_DEFAULT_DEFERRED_IMAGE_WIDTH;
        if LPara.ImageHeight = 0 then
          LPara.ImageHeight := C_DEFAULT_DEFERRED_IMAGE_HEIGHT;
      end
      else
      begin
        LBmp := LoadImage(LPara.ImageSrc, ilcParse);
        if Assigned(LBmp) then
        begin
          if LPara.ImageWidth = 0 then
            LPara.ImageWidth := LBmp.Width;
          if LPara.ImageHeight = 0 then
            LPara.ImageHeight := LBmp.Height;
        end;
      end;
    end;
    for LRun in LPara.Runs do
    begin
      if not LRun.IsImage or (LRun.ImageSrc = '') then
        Continue;
      LDeferred := not FAutoLoadRemoteImages and
                   (StartsWithCI(LRun.ImageSrc, 'http://') or StartsWithCI(LRun.ImageSrc, 'https://'));
      if LDeferred then
      begin
        if LRun.ImageWidth = 0 then
          LRun.ImageWidth := C_DEFAULT_DEFERRED_IMAGE_WIDTH;
        if LRun.ImageHeight = 0 then
          LRun.ImageHeight := C_DEFAULT_DEFERRED_IMAGE_HEIGHT;
      end
      else
      begin
        LBmp := LoadImage(LRun.ImageSrc, ilcParse);
        if Assigned(LBmp) then
        begin
          if LRun.ImageWidth = 0 then
            LRun.ImageWidth := LBmp.Width;
          if LRun.ImageHeight = 0 then
            LRun.ImageHeight := LBmp.Height;
        end;
      end;
    end;
  end;
end;

procedure THTMLEditor.PrepareImageDimensions;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LBmp: TBitmap;
begin
  for LPara in FDoc.Paragraphs do
  begin
    if LPara.BlockType = btImage then
    begin
      if (LPara.ImageWidth = 0) or (LPara.ImageHeight = 0) then
      begin
        LBmp := LoadImage(LPara.ImageSrc);
        if Assigned(LBmp) then
        begin
          if LPara.ImageWidth = 0 then
            LPara.ImageWidth := LBmp.Width;
          if LPara.ImageHeight = 0 then
            LPara.ImageHeight := LBmp.Height;
        end;
      end;
    end;
    for LRun in LPara.Runs do
    begin
      if not LRun.IsImage then
        Continue;
      if (LRun.ImageWidth > 0) and (LRun.ImageHeight > 0) then
        Continue;
      LBmp := LoadImage(LRun.ImageSrc);
      if not Assigned(LBmp) then
        Continue;
      if LRun.ImageWidth = 0 then
        LRun.ImageWidth := LBmp.Width;
      if LRun.ImageHeight = 0 then
        LRun.ImageHeight := LBmp.Height;
    end;
  end;
end;

procedure THTMLEditor.LoadRemoteImages;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LBmp: TBitmap;
begin
  for LPara in FDoc.Paragraphs do
  begin
    if (LPara.BlockType = btImage) and (LPara.ImageSrc <> '') and
       (StartsWithCI(LPara.ImageSrc, 'http://') or StartsWithCI(LPara.ImageSrc, 'https://')) then
    begin
      if not FImageCache.TryGetValue(LPara.ImageSrc, LBmp) then
      begin
        LBmp := LoadBitmapFromSrc(LPara.ImageSrc);
        if Assigned(FOnLoadImage) then
          FOnLoadImage(Self, LPara.ImageSrc, LBmp, ilcParse);
        if Assigned(LBmp) then
          FImageCache.Add(LPara.ImageSrc, LBmp);
      end;
      if Assigned(LBmp) and (LBmp.Width > 0) then
      begin
        LPara.ImageWidth := LBmp.Width;
        LPara.ImageHeight := LBmp.Height;
      end;
    end;
    for LRun in LPara.Runs do
    begin
      if not LRun.IsImage or (LRun.ImageSrc = '') then
        Continue;
      if not (StartsWithCI(LRun.ImageSrc, 'http://') or StartsWithCI(LRun.ImageSrc, 'https://')) then
        Continue;
      if not FImageCache.TryGetValue(LRun.ImageSrc, LBmp) then
      begin
        LBmp := LoadBitmapFromSrc(LRun.ImageSrc);
        if Assigned(FOnLoadImage) then
          FOnLoadImage(Self, LRun.ImageSrc, LBmp, ilcParse);
        if Assigned(LBmp) then
          FImageCache.Add(LRun.ImageSrc, LBmp);
      end;
      if Assigned(LBmp) and (LBmp.Width > 0) then
      begin
        LRun.ImageWidth := LBmp.Width;
        LRun.ImageHeight := LBmp.Height;
      end;
    end;
  end;
  FLayoutEngine.ClearMeasureCache;
  DoLayout;
  InvalidateRender;
end;

procedure THTMLEditor.PaintImage(C: TCanvas; const F: TLayoutFrag; APara: THTMLParagraph);
const
  C_IMG_PLACEHOLDER_BG = $FFD8D8D8;
  C_IMG_PLACEHOLDER_BORDER = $FFA0A0A0;
var
  LBmp: TBitmap;
  LDestRect: TRectF;
  LSrcRect: TRectF;
  LSelS: TDocPos;
  LSelE: TDocPos;
  LFPos: TDocPos;
begin
  LDestRect := TRectF.Create(
    F.X + ContentLeft, F.Y + ContentTop,
    F.X + ContentLeft + F.W, F.Y + ContentTop + F.H);
  LBmp := LoadImage(APara.ImageSrc, ilcRender, Round(F.W), Round(F.H));
  if Assigned(LBmp) and (LBmp.Width > 0) and (LBmp.Height > 0) then
  begin
    LSrcRect := TRectF.Create(0, 0, LBmp.Width, LBmp.Height);
    C.DrawBitmap(LBmp, LSrcRect, LDestRect, AbsoluteOpacity);
  end
  else
  begin
    C.Fill.Kind := TBrushKind.Solid;
    C.Fill.Color := C_IMG_PLACEHOLDER_BG;
    C.FillRect(LDestRect, AbsoluteOpacity);
    C.Stroke.Kind := TBrushKind.Solid;
    C.Stroke.Color := C_IMG_PLACEHOLDER_BORDER;
    C.Stroke.Thickness := 1;
    C.DrawRect(LDestRect, AbsoluteOpacity);
    if APara.ImageAlt <> '' then
    begin
      C.Fill.Color := $FF606060;
      C.Font.Size := 11;
      C.FillText(LDestRect, APara.ImageAlt, False, AbsoluteOpacity, [],
        TTextAlign.Center, TTextAlign.Center);
    end;
  end;
  if FHasSelection then
  begin
    GetSelectionRange(LSelS, LSelE);
    LFPos := TDocPos.At(F.ParaIdx, 0, 0);
    if (PosCompare(LSelS, LFPos) <= 0) and (PosCompare(LSelE, LFPos) > 0) then
    begin
      C.Fill.Kind := TBrushKind.Solid;
      C.Fill.Color := C_DEFAULT_SELECTION_COLOR;
      C.FillRect(LDestRect, AbsoluteOpacity * 0.5);
    end;
  end;
end;

procedure THTMLEditor.PaintSelection(C: TCanvas);
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LFragment: TLayoutFrag;
  LFStart: TDocPos;
  LFEnd: TDocPos;
  LCS: Integer;
  LCE: Integer;
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LTextStyle: THTMLTextStyle;
  LHS: Single;
  LX0: Single;
  LX1: Single;
  LY0: Single;
  LLineH: Single;
  LLSI: Integer;
begin
  if not FHasSelection then
    Exit;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  if PosCompare(LSelectionStart, LSelectionEnd) = 0 then
    Exit;

  C.Fill.Kind := TBrushKind.Solid;
  C.Fill.Color := C_DEFAULT_SELECTION_COLOR;

  for var I := 0 to High(FFrags) do
  begin
    LFragment := FFrags[I];
    if LFragment.IsHR then
    begin
      LFStart := TDocPos.At(LFragment.ParaIdx, 0, 0);
      if (PosCompare(LSelectionStart, LFStart) <= 0) and (PosCompare(LSelectionEnd, LFStart) > 0) then
      begin
        LX0 := ContentLeft + LFragment.X;
        LX1 := ContentLeft + LFragment.X + LFragment.W;
        LY0 := ContentTop + LFragment.Y;
        C.FillRect(TRectF.Create(LX0, LY0, LX1, LY0 + LFragment.H), AbsoluteOpacity * 0.5);
      end;
    end
    else if (not LFragment.IsImage) and (not LFragment.IsPlaceholder) then
    begin
      LFStart := TDocPos.At(LFragment.ParaIdx, LFragment.RunIdx, LFragment.CharStart);
      LFEnd := TDocPos.At(LFragment.ParaIdx, LFragment.RunIdx, LFragment.CharEnd);
      if (PosCompare(LFStart, LSelectionEnd) < 0) and (PosCompare(LFEnd, LSelectionStart) > 0) then
      begin
        LCS := Max(LFragment.CharStart, IfThen((LFragment.ParaIdx = LSelectionStart.ParaIdx) and (LFragment.RunIdx = LSelectionStart.RunIdx), LSelectionStart.CharIdx,
          LFragment.CharStart));
        LCE := Min(LFragment.CharEnd, IfThen((LFragment.ParaIdx = LSelectionEnd.ParaIdx) and (LFragment.RunIdx = LSelectionEnd.RunIdx), LSelectionEnd.CharIdx, LFragment.CharEnd));
        if LCS < LCE then
        begin
          LPara := FDoc.Paragraphs[LFragment.ParaIdx];
          if (LFragment.RunIdx >= 0) and (LFragment.RunIdx < LPara.Runs.Count) then
          begin
            LRun := LPara.Runs[LFragment.RunIdx];
            LTextStyle := LRun.Style;
            LHS := FLayoutEngine.HeadingSize(LPara.BlockType);
            if LHS > 0 then
            begin
              LTextStyle.FontSize := LHS;
              LTextStyle.Bold := True;
            end;
            LX0 := ContentLeft + LFragment.X + FLayoutEngine.MeasureCharOffset(LRun.Text.Substring(LFragment.CharStart),
              LCS - LFragment.CharStart, LTextStyle);
            LX1 := ContentLeft + LFragment.X + FLayoutEngine.MeasureCharOffset(LRun.Text.Substring(LFragment.CharStart),
              LCE - LFragment.CharStart, LTextStyle);
            LY0 := ContentTop + LFragment.Y;
            LLineH := 0;
            LLSI := 0;
            while (LLSI <= High(FLines)) and (LLineH = 0) do
            begin
              if FLines[LLSI].ParaIdx = LFragment.ParaIdx then
                LLineH := FLines[LLSI].H;
              Inc(LLSI);
            end;
            if LLineH = 0 then
              LLineH := LFragment.H;
            C.FillRect(TRectF.Create(LX0, LY0, LX1, LY0 + LLineH), AbsoluteOpacity * 0.5);
          end;
        end;
      end;
    end;
  end;
end;

procedure THTMLEditor.PaintImageRun(C: TCanvas; const F: TLayoutFrag; ARun: THTMLRun);
const
  C_IMG_PLACEHOLDER_BG = $FFD8D8D8;
  C_IMG_PLACEHOLDER_BORDER = $FFA0A0A0;
var
  LBmp: TBitmap;
  LDestRect: TRectF;
  LSrcRect: TRectF;
  LSelS: TDocPos;
  LSelE: TDocPos;
  LFPos: TDocPos;
begin
  LDestRect := TRectF.Create(
    F.X + ContentLeft, F.Y + ContentTop,
    F.X + ContentLeft + F.W, F.Y + ContentTop + F.H);
  LBmp := LoadImage(ARun.ImageSrc, ilcRender, Round(F.W), Round(F.H));
  if Assigned(LBmp) and (LBmp.Width > 0) and (LBmp.Height > 0) then
  begin
    LSrcRect := TRectF.Create(0, 0, LBmp.Width, LBmp.Height);
    C.DrawBitmap(LBmp, LSrcRect, LDestRect, AbsoluteOpacity);
  end
  else
  begin
    C.Fill.Kind := TBrushKind.Solid;
    C.Fill.Color := C_IMG_PLACEHOLDER_BG;
    C.FillRect(LDestRect, AbsoluteOpacity);
    C.Stroke.Kind := TBrushKind.Solid;
    C.Stroke.Color := C_IMG_PLACEHOLDER_BORDER;
    C.Stroke.Thickness := 1;
    C.DrawRect(LDestRect, AbsoluteOpacity);
    if ARun.ImageAlt <> '' then
    begin
      C.Fill.Color := $FF606060;
      C.Font.Size := 11;
      C.FillText(LDestRect, ARun.ImageAlt, False, AbsoluteOpacity, [],
        TTextAlign.Center, TTextAlign.Center);
    end;
  end;
  if FHasSelection then
  begin
    GetSelectionRange(LSelS, LSelE);
    LFPos := TDocPos.At(F.ParaIdx, F.RunIdx, 0);
    if (PosCompare(LSelS, LFPos) <= 0) and (PosCompare(LSelE, LFPos) > 0) then
    begin
      C.Fill.Kind := TBrushKind.Solid;
      C.Fill.Color := C_DEFAULT_SELECTION_COLOR;
      C.FillRect(LDestRect, AbsoluteOpacity * 0.5);
    end;
  end;
end;

procedure THTMLEditor.PaintFragment(C: TCanvas; const F: TLayoutFrag);
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LTextStyle: THTMLTextStyle;
  LPX, LPY: Single;
  LLayout: TTextLayout;
  LEffSize: Single;
  LFragText: String;
  LHS: Single;
  LUY: Single;
  LSY: Single;
begin
  if (F.ParaIdx < 0) or (F.ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LPara := FDoc.Paragraphs[F.ParaIdx];
  if LPara.BlockType in [btHR, btImage] then
    Exit;
  if (F.RunIdx < 0) or (F.RunIdx >= LPara.Runs.Count) then
    Exit;
  LRun := LPara.Runs[F.RunIdx];
  if LRun.IsLineBreak then
    Exit;
  if F.IsPlaceholder or LRun.IsPlaceholder then
  begin
    PaintPlaceholderFragment(C, F);
    Exit;
  end;
  LFragText := LRun.Text.Substring(F.CharStart, F.CharEnd - F.CharStart);
  if LFragText = '' then
    Exit;

  LTextStyle := LRun.Style;
  LHS := FLayoutEngine.HeadingSize(LPara.BlockType);
  if LHS > 0 then
  begin
    LTextStyle.FontSize := LHS;
    LTextStyle.Bold := True;
  end;

  LPX := ContentLeft + F.X;
  LPY := ContentTop + F.Y;

  // Subscript/Superscript vertical offset -- anchored to the line baseline
  LEffSize := FLayoutEngine.EffectiveSize(LTextStyle);
  if LTextStyle.Superscript or LTextStyle.Subscript then
  begin
    var LLineAscent: Single := LEffSize;
    if (F.LineIdx >= 0) and (F.LineIdx < Length(FLines)) then
      LLineAscent := FLines[F.LineIdx].Ascent;
    if LTextStyle.Superscript then
      LPY := LPY - LLineAscent * 0.35
    else
      LPY := LPY + LLineAscent * 0.6;
  end;

  // Background highlight
  if LTextStyle.BackgroundColor <> claNull then
  begin
    C.Fill.Kind := TBrushKind.Solid;
    C.Fill.Color := LTextStyle.BackgroundColor;
    C.FillRect(TRectF.Create(LPX, LPY, LPX + F.W, LPY + F.H), AbsoluteOpacity);
  end;

  LLayout := TTextLayoutManager.DefaultTextLayout.Create(C);
  try
    LLayout.BeginUpdate;
    LLayout.Font.Family := LTextStyle.FontName;
    LLayout.Font.Size := LEffSize;
    LLayout.Font.Style := TextStyleToFMXFontStyle(LTextStyle);
    LLayout.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
    LLayout.MaxSize := TPointF.Create(F.W + 4, F.H + 4);
    LLayout.WordWrap := False;
    LLayout.TopLeft := TPointF.Create(LPX, LPY);
    LLayout.Text := LFragText;
    LLayout.EndUpdate;
    LLayout.RenderLayout(C);
  finally
    LLayout.Free;
  end;

  // Underline
  if LTextStyle.Underline then
  begin
    LUY := LPY + F.H * 0.88;
    C.Stroke.Kind := TBrushKind.Solid;
    C.Stroke.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
    C.Stroke.Thickness := 1;
    C.DrawLine(TPointF.Create(LPX, LUY), TPointF.Create(LPX + F.W, LUY), AbsoluteOpacity);
  end;
  if LTextStyle.StrikeOut then
  begin
    LSY := LPY + F.H * 0.5;
    C.Stroke.Kind := TBrushKind.Solid;
    C.Stroke.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, FFontColor);
    C.Stroke.Thickness := 1;
    C.DrawLine(TPointF.Create(LPX, LSY), TPointF.Create(LPX + F.W, LSY), AbsoluteOpacity);
  end;
end;

procedure THTMLEditor.PaintPlaceholderFragment(C: TCanvas; const F: TLayoutFrag);
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LBounds: TRectF;
  LApp: TPlaceholderAppearance;
  LLabelText: string;
  LHandled: Boolean;
  LLayout: TTextLayout;
  LTextStyle: THTMLTextStyle;
  LCorners: TCorners;
  LSelS: TDocPos;
  LSelE: TDocPos;
  LFPos: TDocPos;
  LIsCurrent: Boolean;
  LEffectiveFillColor: TAlphaColor;
  LBorderColor: TAlphaColor;
begin
  if (F.ParaIdx < 0) or (F.ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LPara := FDoc.Paragraphs[F.ParaIdx];
  if (F.RunIdx < 0) or (F.RunIdx >= LPara.Runs.Count) then
    Exit;
  LRun := LPara.Runs[F.RunIdx];

  LBounds := TRectF.Create(ContentLeft + F.X, ContentTop + F.Y, ContentLeft + F.X + F.W, ContentTop + F.Y + F.H);

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
    FOnDrawPlaceholder(Self, C, LBounds, LRun.Text, LHandled);
  if LHandled then
    Exit;

  LIsCurrent := FCaretPos.IsValid and not FHasSelection and
                (FCaretPos.ParaIdx = F.ParaIdx) and (FCaretPos.RunIdx = F.RunIdx);

  LApp := FPlaceholderAppearance;
  LCorners := [TCorner.TopLeft, TCorner.TopRight, TCorner.BottomLeft, TCorner.BottomRight];

  // Fill -- use run's BackgroundColor if explicitly set, otherwise appearance default
  LEffectiveFillColor := IfThen(LRun.Style.BackgroundColor <> claNull, LRun.Style.BackgroundColor, LApp.FillColor);
  C.Fill.Kind := TBrushKind.Solid;
  C.Fill.Color := LEffectiveFillColor;
  C.FillRect(LBounds, LApp.BorderRadius, LApp.BorderRadius, LCorners, AbsoluteOpacity);

  // Border -- priority: explicit per-run -> auto-derive from fill -> global default
  if LRun.PlaceholderBorderColor <> claNull then
    LBorderColor := LRun.PlaceholderBorderColor
  else if LEffectiveFillColor <> claNull then
    LBorderColor := DarkenColor(LEffectiveFillColor)
  else
    LBorderColor := LApp.BorderColor;
  if LBorderColor <> claNull then
  begin
    C.Stroke.Kind := TBrushKind.Solid;
    C.Stroke.Color := LBorderColor;
    C.Stroke.Thickness := IfThen(LIsCurrent, 2.5, 1);
    C.DrawRect(LBounds, LApp.BorderRadius, LApp.BorderRadius, LCorners, AbsoluteOpacity);
  end;

  // Label text -- run style overrides appearance defaults
  LTextStyle := LRun.Style;
  if LApp.Bold then
    LTextStyle.Bold := True;
  LLayout := TTextLayoutManager.DefaultTextLayout.Create(C);
  try
    LLayout.BeginUpdate;
    LLayout.Font.Family := LTextStyle.FontName;
    LLayout.Font.Size := FLayoutEngine.EffectiveSize(LTextStyle);
    LLayout.Font.Style := TextStyleToFMXFontStyle(LTextStyle);
    LLayout.Color := IfThen(LTextStyle.Color <> claNull, LTextStyle.Color, LApp.TextColor);
    LLayout.MaxSize := TPointF.Create(F.W, F.H);
    LLayout.WordWrap := False;
    LLayout.TopLeft := TPointF.Create(LBounds.Left + LApp.HorizontalPadding, LBounds.Top + LApp.VerticalPadding);
    LLayout.Text := LLabelText;
    LLayout.EndUpdate;
    LLayout.RenderLayout(C);
  finally
    LLayout.Free;
  end;

  // Selection overlay
  if FHasSelection then
  begin
    GetSelectionRange(LSelS, LSelE);
    LFPos := TDocPos.At(F.ParaIdx, F.RunIdx, 0);
    if (PosCompare(LSelS, LFPos) <= 0) and (PosCompare(LSelE, LFPos) > 0) then
    begin
      C.Fill.Kind := TBrushKind.Solid;
      C.Fill.Color := C_DEFAULT_SELECTION_COLOR;
      C.FillRect(LBounds, LApp.BorderRadius, LApp.BorderRadius, LCorners, AbsoluteOpacity * 0.5);
    end;
  end;
end;

procedure THTMLEditor.PaintCaret(C: TCanvas);
begin
  if csDesigning in ComponentState then
    Exit;
  if not FCaretOn then
    Exit;
  if not FCaretPos.IsValid then
    Exit;
  C.Stroke.Kind := TBrushKind.Solid;
  C.Stroke.Color := TAlphaColors.Black;
  C.Stroke.Thickness := 1.5;
  C.DrawLine(TPointF.Create(FCaretScreenX, FCaretScreenY), TPointF.Create(FCaretScreenX, FCaretScreenY + FCaretScreenH),
    AbsoluteOpacity);
end;

procedure THTMLEditor.PaintBorder(C: TCanvas);
begin
  if not FShowBorder then
    Exit;
  C.Stroke.Kind := TBrushKind.Solid;
  C.Stroke.Color := $FFA0A0A0;
  C.Stroke.Thickness := 1;
  C.DrawRect(TRectF.Create(0, 0, Width, Height), AbsoluteOpacity);
end;

// -- Caret & Navigation -------------------------------------------------------

procedure THTMLEditor.UpdateCaretXY;
var
  LXPosition, LYPosition, LHeight: Single;
begin
  if DocPosToXY(FCaretPos, LXPosition, LYPosition, LHeight) then
  begin
    FCaretScreenX := LXPosition;
    FCaretScreenY := LYPosition;
    FCaretScreenH := LHeight;
  end
  else if FCaretScreenH = 0 then
  begin
    // DocPosToXY failed and coordinates were never set: place the caret at
    // the top-left of the content area with a default height so it is at
    // least visible rather than drawing a zero-length invisible line.
    FCaretScreenX := ContentLeft;
    FCaretScreenY := ContentTop;
    FCaretScreenH := 16;
  end;
end;

function THTMLEditor.DocPosToXY(const P: TDocPos; out X, Y, H: Single): Boolean;
var
  LPara: THTMLParagraph;
  LFragment: TLayoutFrag;
  LTextStyle: THTMLTextStyle;
  LHS: Single;
  LOfs: Single;
  LLastFound: Boolean;
  LFragment2: TLayoutFrag;
begin
  Result := False;
  X := ContentLeft;
  Y := ContentTop;
  H := 16;
  if not P.IsValid then
    Exit;
  if P.ParaIdx >= FDoc.Paragraphs.Count then
    Exit;

  LPara := FDoc.Paragraphs[P.ParaIdx];

  if LPara.BlockType in [btImage, btHR] then
  begin
    for var I := 0 to High(FFrags) do
      if FFrags[I].ParaIdx = P.ParaIdx then
      begin
        if FCaretAtImageRight then
          X := ContentLeft + FFrags[I].X + FFrags[I].W
        else
          X := ContentLeft + FFrags[I].X;
        Y := ContentTop + FFrags[I].Y;
        H := FFrags[I].H;
        Result := True;
        Exit;
      end;
    Exit;
  end;

  for var I := 0 to High(FFrags) do
  begin
    LFragment := FFrags[I];
    if (not LFragment.IsHR) and (not LFragment.IsImage or (LFragment.RunIdx >= 0)) and (LFragment.ParaIdx = P.ParaIdx) and (LFragment.RunIdx = P.RunIdx) and (P.CharIdx >= LFragment.CharStart) and
      ((LFragment.IsImage and (LFragment.RunIdx >= 0)) or (P.CharIdx <= LFragment.CharEnd)) then
    begin
      if LFragment.IsPlaceholder or (LFragment.IsImage and (LFragment.RunIdx >= 0)) then
      begin
        if P.CharIdx = 0 then
          X := ContentLeft + LFragment.X
        else
          X := ContentLeft + LFragment.X + LFragment.W;
        Y := ContentTop + LFragment.Y;
        H := LFragment.H;
        Result := True;
        Exit;
      end;
      LTextStyle.Init;
      if (LFragment.RunIdx >= 0) and (LFragment.RunIdx < LPara.Runs.Count) then
        LTextStyle := LPara.Runs[LFragment.RunIdx].Style;
      LHS := FLayoutEngine.HeadingSize(LPara.BlockType);
      if LHS > 0 then
      begin
        LTextStyle.FontSize := LHS;
        LTextStyle.Bold := True;
      end;

      LOfs := 0;
      if (LFragment.RunIdx >= 0) and (LFragment.RunIdx < LPara.Runs.Count) then
        LOfs := FLayoutEngine.MeasureCharOffset(LPara.Runs[LFragment.RunIdx].Text.Substring(LFragment.CharStart),
          P.CharIdx - LFragment.CharStart, LTextStyle);
      X := ContentLeft + LFragment.X + LOfs;
      Y := ContentTop + LFragment.Y;
      H := LFragment.H;
      Result := True;
      Exit;
    end;
  end;

  LLastFound := False;
  for var I := High(FFrags) downto 0 do
    if (not LLastFound) and (FFrags[I].ParaIdx = P.ParaIdx) and not FFrags[I].IsHR and not FFrags[I].IsImage then
    begin
      LFragment2 := FFrags[I];
      X := ContentLeft + LFragment2.X + LFragment2.W;
      Y := ContentTop + LFragment2.Y;
      H := LFragment2.H;
      Result := True;
      LLastFound := True;
    end;
end;

procedure THTMLEditor.EnsureCaretVisible;
var
  X, Y, H, DocY, ViewH: Single;
begin
  if not DocPosToXY(FCaretPos, X, Y, H) then
    Exit;
  // DocPosToXY returns screen Y = ContentTop + F.Y
  // Document coordinate of the caret: DocY = Y - ContentTop = F.Y
  // Scroll range is [0, FScrollBarMax]; viewport is [FScrollY, FScrollY + ViewH]
  DocY := Y - ContentTop;
  ViewH := Height - C_EDITOR_PADDING * 2;
  if DocY < FScrollY then
    ScrollTo(DocY)
  else if DocY + H > FScrollY + ViewH then
    ScrollTo(DocY + H - ViewH);
end;

procedure THTMLEditor.ScrollTo(Y: Single);
begin
  FScrollY := Max(0, Min(Y, FScrollBarMax));
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

procedure THTMLEditor.OnScrollChange(Sender: TObject);
begin
  if FSyncing then
    Exit;
  FScrollY := Max(0, Min(FScrollBar.Value, FScrollBarMax));
  UpdateCaretXY;
  InvalidateRender;
end;

function THTMLEditor.HitTest(X, Y: Single): TDocPos;
var
  DocX, DocY: Single;
  LBestLineY: Single;
  LLine: TLayoutLine;
  LDistance, LDistanceX: Single;
  LFragment: TLayoutFrag;
  LBestFragment: TLayoutFrag;
  LBestFrag: Integer;
  LBestDist: Single;
  LPara2: THTMLParagraph;
  LRun2: THTMLRun;
  LTextStyle: THTMLTextStyle;
  LHS: Single;
  LFragSub: string;
  LCI: Integer;
  LClickedCellParaIdx: Integer;
begin
  Result := DocStart;
  DocX := X - ContentLeft;
  DocY := Y - ContentTop;

  // Pre-pass: if the click lands inside a table cell bounding box, record
  // that cell's ParaIdx so Pass 2 can ignore fragments from other cells.
  LClickedCellParaIdx := -1;
  for var I := 0 to High(FLines) do
  begin
    LLine := FLines[I];
    if LLine.IsFirst and (LLine.ParaIdx < FDoc.Paragraphs.Count) and
       (FDoc.Paragraphs[LLine.ParaIdx].BlockType = btTableCell) then
    begin
      if (DocX >= LLine.CellX) and (DocX < LLine.CellX + LLine.CellW) and
         (DocY >= LLine.CellRowY) and (DocY < LLine.CellRowY + LLine.CellRowH) then
        LClickedCellParaIdx := LLine.ParaIdx;
    end;
  end;

  // Pass 1: find minimum Y distance across all lines
  LBestLineY := MaxSingle;
  for var I := 0 to High(FLines) do
  begin
    LLine := FLines[I];
    if (DocY >= LLine.Y) and (DocY < LLine.Y + LLine.H) then
      LDistance := 0
    else
      LDistance := Min(Abs(DocY - LLine.Y), Abs(DocY - (LLine.Y + LLine.H)));
    if LDistance < LBestLineY then
      LBestLineY := LDistance;
  end;

  // Pass 2: among all lines with that Y distance, pick best frag by combined Y+X dist
  LBestFrag := -1;
  LBestDist := MaxSingle;
  for var I := 0 to High(FLines) do
  begin
    LLine := FLines[I];
    if (DocY >= LLine.Y) and (DocY < LLine.Y + LLine.H) then
      LDistance := 0
    else
      LDistance := Min(Abs(DocY - LLine.Y), Abs(DocY - (LLine.Y + LLine.H)));
    if LDistance <= LBestLineY + 0.1 then
      for var J := LLine.FragStart to LLine.FragStart + LLine.FragCount - 1 do
      begin
        if (LClickedCellParaIdx < 0) or (FFrags[J].ParaIdx = LClickedCellParaIdx) then
        begin
          LFragment := FFrags[J];
          if DocX < LFragment.X then
            LDistanceX := LFragment.X - DocX
          else if DocX > LFragment.X + LFragment.W then
            LDistanceX := DocX - (LFragment.X + LFragment.W)
          else
            LDistanceX := 0;
          if LDistance + LDistanceX < LBestDist then
          begin
            LBestDist := LDistance + LDistanceX;
            LBestFrag := J;
          end;
        end;
      end;
  end;
  if LBestFrag < 0 then
    Exit;

  LBestFragment := FFrags[LBestFrag];
  if LBestFragment.ParaIdx >= FDoc.Paragraphs.Count then
    Exit;
  LPara2 := FDoc.Paragraphs[LBestFragment.ParaIdx];
  if LBestFragment.IsImage or LBestFragment.IsHR then
  begin
    if LBestFragment.IsImage and (LBestFragment.RunIdx >= 0) then
    begin
      if DocX - LBestFragment.X >= LBestFragment.W / 2 then
        Result := TDocPos.At(LBestFragment.ParaIdx, LBestFragment.RunIdx, 1)
      else
        Result := TDocPos.At(LBestFragment.ParaIdx, LBestFragment.RunIdx, 0);
    end
    else
    begin
      if (DocX - LBestFragment.X >= LBestFragment.W / 2) and (LBestFragment.ParaIdx + 1 < FDoc.Paragraphs.Count) then
        Result := TDocPos.At(LBestFragment.ParaIdx + 1, 0, 0)
      else
        Result := TDocPos.At(LBestFragment.ParaIdx, 0, 0);
    end;
    Exit;
  end;
  if (LBestFragment.RunIdx < 0) or (LBestFragment.RunIdx >= LPara2.Runs.Count) then
  begin
    Result := TDocPos.At(LBestFragment.ParaIdx, 0, 0);
    Exit;
  end;

  LRun2 := LPara2.Runs[LBestFragment.RunIdx];

  if LBestFragment.IsPlaceholder or LRun2.IsPlaceholder then
  begin
    if DocX - LBestFragment.X < LBestFragment.W / 2 then
      Result := TDocPos.At(LBestFragment.ParaIdx, LBestFragment.RunIdx, 0)
    else
      Result := TDocPos.At(LBestFragment.ParaIdx, LBestFragment.RunIdx, LRun2.Text.Length);
    Exit;
  end;

  LTextStyle := LRun2.Style;
  LHS := FLayoutEngine.HeadingSize(LPara2.BlockType);
  if LHS > 0 then
  begin
    LTextStyle.FontSize := LHS;
    LTextStyle.Bold := True;
  end;

  LFragSub := LRun2.Text.Substring(LBestFragment.CharStart, LBestFragment.CharEnd - LBestFragment.CharStart);
  LCI := FLayoutEngine.CharAtX(LFragSub, DocX - LBestFragment.X, LTextStyle);
  Result := TDocPos.At(LBestFragment.ParaIdx, LBestFragment.RunIdx, LBestFragment.CharStart + LCI);
end;

function THTMLEditor.LinkURLAt(X, Y: Single): string;
var
  LHitPosition: TDocPos;
  LPara: THTMLParagraph;
begin
  Result := '';
  if Length(FFrags) = 0 then
    Exit;
  LHitPosition := HitTest(X, Y);
  if not LHitPosition.IsValid then
    Exit;
  if LHitPosition.ParaIdx >= FDoc.Paragraphs.Count then
    Exit;
  LPara := FDoc.Paragraphs[LHitPosition.ParaIdx];
  if (LHitPosition.RunIdx >= 0) and (LHitPosition.RunIdx < LPara.Runs.Count) then
    Result := LPara.Runs[LHitPosition.RunIdx].Style.LinkURL;
end;

function THTMLEditor.LinkTextForURL(const P: TDocPos; const URL: string): string;
var
  LStringBuilder: TStringBuilder;
  LPara: THTMLParagraph;
  LRun: THTMLRun;
begin
  Result := '';
  if (URL = '') or not P.IsValid then
    Exit;
  if P.ParaIdx >= FDoc.Paragraphs.Count then
    Exit;
  LPara := FDoc.Paragraphs[P.ParaIdx];
  LStringBuilder := TStringBuilder.Create;
  try
    for var I := 0 to LPara.Runs.Count - 1 do
    begin
      LRun := LPara.Runs[I];
      if (LRun.Style.LinkURL = URL) and not LRun.IsLineBreak then
        LStringBuilder.Append(LRun.Text);
    end;
    Result := LStringBuilder.ToString;
  finally
    LStringBuilder.Free;
  end;
end;

procedure THTMLEditor.SetCaretPos(const P: TDocPos; ExtendSel: Boolean);
begin
  if ExtendSel then
  begin
    if not FHasSelection then
    begin
      FSelStart := FCaretPos;
      FSelEnd := FCaretPos;
      FHasSelection := True;
    end;
    FSelEnd := P;
    if PosCompare(FSelStart, FSelEnd) = 0 then
      FHasSelection := False;
  end
  else
  begin
    FHasSelection := False;
    FSelStart := TDocPos.Invalid;
    FSelEnd := TDocPos.Invalid;
  end;
  FCaretPos := P;
  FCaretOn := True;
  FInsertStyleSet := False;
  // Restart the blink cycle so the caret is always ON for a full interval
  // after any caret move (click, keyboard, etc.). Simply assigning Enabled
  // when it is already True does NOT reset the timer in Delphi.
  FCaretTimer.Enabled := False;
  FCaretTimer.Enabled := IsFocused;
  UpdateCaretXY;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

function THTMLEditor.FragmentIndexAt(ParaIdx, RunIdx, CharIdx: Integer): Integer;
begin
  for var I := 0 to High(FFrags) do
  begin
    if FFrags[I].ParaIdx <> ParaIdx then
      Continue;
    if FFrags[I].IsImage or FFrags[I].IsHR then
    begin
      if FFrags[I].RunIdx < 0 then
        Exit(I)
      else if FFrags[I].RunIdx = RunIdx then
        Exit(I)
      else
        Continue;
    end;
    if (FFrags[I].RunIdx = RunIdx) and (CharIdx >= FFrags[I].CharStart) and (CharIdx <= FFrags[I].CharEnd) then
      Exit(I);
  end;
  Result := -1;
end;

function THTMLEditor.PosCompare(const A, B: TDocPos): Integer;
begin
  if A.ParaIdx <> B.ParaIdx then
    Exit(Sign(A.ParaIdx - B.ParaIdx));
  if A.RunIdx <> B.RunIdx then
    Exit(Sign(A.RunIdx - B.RunIdx));
  Result := Sign(A.CharIdx - B.CharIdx);
end;

procedure THTMLEditor.GetSelectionRange(out S, E: TDocPos);
begin
  if PosCompare(FSelStart, FSelEnd) <= 0 then
  begin
    S := FSelStart;
    E := FSelEnd;
  end
  else
  begin
    S := FSelEnd;
    E := FSelStart;
  end;
end;

// Finds the contiguous block of btLI paragraphs that contains the caret.
// Used when there is no active selection and the caret sits on a list item.
procedure THTMLEditor.GetListBlockRange(out AFirst, ALast: Integer);
var
  LPI: Integer;
  LOrdered: Boolean;
begin
  AFirst := FCaretPos.ParaIdx;
  ALast  := FCaretPos.ParaIdx;
  if not FCaretPos.IsValid or (AFirst >= FDoc.Paragraphs.Count) then
    Exit;
  if FDoc.Paragraphs[AFirst].BlockType <> btLI then
    Exit;
  LOrdered := FDoc.Paragraphs[AFirst].ListOrdered;
  LPI := AFirst - 1;
  while (LPI >= 0) and (FDoc.Paragraphs[LPI].BlockType = btLI) and
        (FDoc.Paragraphs[LPI].ListOrdered = LOrdered) do
  begin
    AFirst := LPI;
    Dec(LPI);
  end;
  LPI := ALast + 1;
  while (LPI < FDoc.Paragraphs.Count) and (FDoc.Paragraphs[LPI].BlockType = btLI) and
        (FDoc.Paragraphs[LPI].ListOrdered = LOrdered) do
  begin
    ALast := LPI;
    Inc(LPI);
  end;
end;

// Renumbers all ordered btLI items in AFirst..ALast.
// Counters are per-indent-level: going deeper resets the level counter;
// going back to a shallower level continues where it left off.
procedure THTMLEditor.RenumberListBlock(AFirst, ALast: Integer);
const
  C_MAX_INDENT = 31;
var
  LCounters: array[0..C_MAX_INDENT] of Integer;
  LLastIndent: Integer;
  LIndentLevel: Integer;
begin
  FillChar(LCounters, SizeOf(LCounters), 0);
  LLastIndent := -1;
  for var I := AFirst to Min(ALast, FDoc.Paragraphs.Count - 1) do
    if FDoc.Paragraphs[I].BlockType = btLI then
    begin
      LIndentLevel := Min(FDoc.Paragraphs[I].IndentLevel, C_MAX_INDENT);
      if LIndentLevel > LLastIndent then
        LCounters[LIndentLevel] := 0;
      if FDoc.Paragraphs[I].ListOrdered then
      begin
        Inc(LCounters[LIndentLevel]);
        FDoc.Paragraphs[I].ListIndex := LCounters[LIndentLevel];
      end;
      LLastIndent := LIndentLevel;
    end;
end;

procedure THTMLEditor.ClearSelection;
begin
  FHasSelection := False;
  FSelStart := TDocPos.Invalid;
  FSelEnd := TDocPos.Invalid;
end;

function THTMLEditor.DocStart: TDocPos;
begin
  if FDoc.Paragraphs.Count = 0 then
    Exit(TDocPos.Invalid);
  Result := TDocPos.At(0, 0, 0);
end;

function THTMLEditor.DocEnd: TDocPos;
var
  LLastPI: Integer;
  LParagraph: THTMLParagraph;
  LLastRI: Integer;
begin
  if FDoc.Paragraphs.Count = 0 then
    Exit(TDocPos.Invalid);
  LLastPI := FDoc.Paragraphs.Count - 1;
  LParagraph := FDoc.Paragraphs[LLastPI];
  if LParagraph.Runs.Count = 0 then
    Exit(TDocPos.At(LLastPI, 0, 0));
  LLastRI := LParagraph.Runs.Count - 1;
  Exit(TDocPos.At(LLastPI, LLastRI, LParagraph.Runs[LLastRI].Text.Length));
end;

function THTMLEditor.NextDocPos(const P: TDocPos): TDocPos;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LNextCharIdx: Integer;
  LRightIdx: Integer;
begin
  if not P.IsValid then
    Exit(TDocPos.Invalid);
  if P.ParaIdx >= FDoc.Paragraphs.Count then
    Exit(P);
  LPara := FDoc.Paragraphs[P.ParaIdx];
  if LPara.Runs.Count = 0 then
  begin
    if P.ParaIdx + 1 < FDoc.Paragraphs.Count then
      Exit(TDocPos.At(P.ParaIdx + 1, 0, 0))
    else
      Exit(P);
  end;
  if P.RunIdx >= LPara.Runs.Count then
    Exit(P);
  LRun := LPara.Runs[P.RunIdx];
  if LRun.IsPlaceholder or LRun.IsImage then
  begin
    if LRun.IsImage then
      LRightIdx := 1
    else
      LRightIdx := LRun.Text.Length;
    if P.CharIdx < LRightIdx then
      Exit(TDocPos.At(P.ParaIdx, P.RunIdx, LRightIdx));
    if P.RunIdx + 1 < LPara.Runs.Count then
      Exit(TDocPos.At(P.ParaIdx, P.RunIdx + 1, 0));
    if P.ParaIdx + 1 < FDoc.Paragraphs.Count then
      Exit(TDocPos.At(P.ParaIdx + 1, 0, 0));
    Exit(P);
  end
  else if P.CharIdx < LRun.Text.Length then
  begin
    if (P.CharIdx < LRun.Text.Length - 1) and
       LRun.Text[P.CharIdx + 1].IsHighSurrogate and
       LRun.Text[P.CharIdx + 2].IsLowSurrogate then
      LNextCharIdx := P.CharIdx + 2
    else
      LNextCharIdx := P.CharIdx + 1;
    // Skip the phantom position at end of text run: (textRun, textRun.Length)
    // is visually identical to (nextRun, 0) for any run type.
    if (LNextCharIdx >= LRun.Text.Length) and (P.RunIdx + 1 < LPara.Runs.Count) then
      Exit(TDocPos.At(P.ParaIdx, P.RunIdx + 1, 0))
    else
      Exit(TDocPos.At(P.ParaIdx, P.RunIdx, LNextCharIdx));
  end;
  if P.RunIdx + 1 < LPara.Runs.Count then
    Exit(TDocPos.At(P.ParaIdx, P.RunIdx + 1, 0));
  if P.ParaIdx + 1 < FDoc.Paragraphs.Count then
    Exit(TDocPos.At(P.ParaIdx + 1, 0, 0));
  Result := P;
end;

function THTMLEditor.PrevDocPos(const P: TDocPos): TDocPos;
var
  LPara: THTMLParagraph;
  LPrevPara: THTMLParagraph;
  LCurRun: THTMLRun;
  LPrevRun: THTMLRun;
  LRI: integer;
  LPrevRightIdx: Integer;
begin
  if not P.IsValid then
    Exit(TDocPos.Invalid);
  if P.ParaIdx >= FDoc.Paragraphs.Count then
    Exit(P);
  LPara := FDoc.Paragraphs[P.ParaIdx];
  if LPara.Runs.Count > 0 then
  begin
    if P.RunIdx < LPara.Runs.Count then
    begin
      LCurRun := LPara.Runs[P.RunIdx];
      if LCurRun.IsPlaceholder or LCurRun.IsImage then
      begin
        if P.CharIdx > 0 then
          Exit(TDocPos.At(P.ParaIdx, P.RunIdx, 0));
      end
      else if P.CharIdx > 0 then
      begin
        if (P.CharIdx > 1) and
           LCurRun.Text[P.CharIdx].IsLowSurrogate and
           LCurRun.Text[P.CharIdx - 1].IsHighSurrogate then
          Exit(TDocPos.At(P.ParaIdx, P.RunIdx, P.CharIdx - 2))
        else
          Exit(TDocPos.At(P.ParaIdx, P.RunIdx, P.CharIdx - 1));
      end;
    end;
  end;
  if (P.RunIdx > 0) and (P.RunIdx - 1 < LPara.Runs.Count) then
  begin
    LPrevRun := LPara.Runs[P.RunIdx - 1];
    if LPrevRun.IsPlaceholder or LPrevRun.IsImage then
    begin
      if LPrevRun.IsImage then
        LPrevRightIdx := 1
      else
        LPrevRightIdx := LPrevRun.Text.Length;
      Exit(TDocPos.At(P.ParaIdx, P.RunIdx - 1, LPrevRightIdx));
    end
    else
      // Skip the phantom (prevRun, prevRun.Length) -- visually identical to (curRun, 0).
      Exit(PrevDocPos(TDocPos.At(P.ParaIdx, P.RunIdx - 1, LPrevRun.Text.Length)));
  end;
  if P.ParaIdx > 0 then
  begin
    LPrevPara := FDoc.Paragraphs[P.ParaIdx - 1];
    if LPrevPara.Runs.Count = 0 then
      Exit(TDocPos.At(P.ParaIdx - 1, 0, 0));
    LRI := LPrevPara.Runs.Count - 1;
    if LPrevPara.Runs[LRI].IsPlaceholder or LPrevPara.Runs[LRI].IsImage then
    begin
      if LPrevPara.Runs[LRI].IsImage then
        LPrevRightIdx := 1
      else
        LPrevRightIdx := LPrevPara.Runs[LRI].Text.Length;
      Exit(TDocPos.At(P.ParaIdx - 1, LRI, LPrevRightIdx));
    end
    else
      Exit(TDocPos.At(P.ParaIdx - 1, LRI, LPrevPara.Runs[LRI].Text.Length));
  end;
  Result := P;
end;

function THTMLEditor.LineStart(const P: TDocPos): TDocPos;
var
  LFragmentIndex: Integer;
  LLineIndex: Integer;
  LLine: TLayoutLine;
begin
  LFragmentIndex := FragmentIndexAt(P.ParaIdx, P.RunIdx, P.CharIdx);
  if LFragmentIndex < 0 then
    Exit(P);
  LLineIndex := FFrags[LFragmentIndex].LineIdx;
  if (LLineIndex < 0) or (LLineIndex >= Length(FLines)) then
    Exit(P);
  LLine := FLines[LLineIndex];
  for var I := LLine.FragStart to LLine.FragStart + LLine.FragCount - 1 do
    if not FFrags[I].IsHR and (not FFrags[I].IsImage or (FFrags[I].RunIdx >= 0)) then
      Exit(TDocPos.At(FFrags[I].ParaIdx, FFrags[I].RunIdx, FFrags[I].CharStart));
  Result := P;
end;

function THTMLEditor.LineEnd(const P: TDocPos): TDocPos;
var
  LFragmentIndex: Integer;
  LLineIndex: Integer;
  LLine: TLayoutLine;
begin
  LFragmentIndex := FragmentIndexAt(P.ParaIdx, P.RunIdx, P.CharIdx);
  if LFragmentIndex < 0 then
    Exit(P);
  LLineIndex := FFrags[LFragmentIndex].LineIdx;
  if (LLineIndex < 0) or (LLineIndex >= Length(FLines)) then
    Exit(P);
  LLine := FLines[LLineIndex];
  for var I := LLine.FragStart + LLine.FragCount - 1 downto LLine.FragStart do
    if not FFrags[I].IsHR and (not FFrags[I].IsImage or (FFrags[I].RunIdx >= 0)) then
      Exit(TDocPos.At(FFrags[I].ParaIdx, FFrags[I].RunIdx, FFrags[I].CharEnd));
  Result := P;
end;

function THTMLEditor.LineAbove(const P: TDocPos): TDocPos;
var
  LFragmentIndex: Integer;
  LLineIndex: Integer;
  LXPosition, LYPosition, LHeight: Single;
  LDocX: Single;
  LLineY: Single;
  LCurCell: THTMLParagraph;
  LTargetPI: Integer;
  LSearchI: Integer;
begin
  Result := P;
  LFragmentIndex := FragmentIndexAt(P.ParaIdx, P.RunIdx, P.CharIdx);
  if LFragmentIndex < 0 then
    Exit;
  LLineIndex := FFrags[LFragmentIndex].LineIdx - 1;

  if (P.ParaIdx < FDoc.Paragraphs.Count) and
     (FDoc.Paragraphs[P.ParaIdx].BlockType = btTableCell) then
  begin
    LCurCell := FDoc.Paragraphs[P.ParaIdx];

    // Within-cell: LLineIndex still belongs to this paragraph
    if (LLineIndex >= 0) and (FLines[LLineIndex].ParaIdx = P.ParaIdx) then
    begin
      if not DocPosToXY(P, LXPosition, LYPosition, LHeight) then
        Exit;
      LDocX := LXPosition - ContentLeft;
      LLineY := FLines[LLineIndex].Y + FLines[LLineIndex].H / 2;
      Result := HitTest(ContentLeft + LDocX, ContentTop + LLineY);
      Exit;
    end;

    // LLineIndex is outside this cell (sibling column or before document start).
    // Try to navigate to the row above in the same column.
    LTargetPI := -1;
    if LCurCell.TableRow > 0 then
    begin
      LSearchI := 0;
      while (LSearchI < FDoc.Paragraphs.Count) and (LTargetPI < 0) do
      begin
        if (FDoc.Paragraphs[LSearchI].BlockType = btTableCell) and
           (FDoc.Paragraphs[LSearchI].TableID  = LCurCell.TableID) and
           (FDoc.Paragraphs[LSearchI].TableCol = LCurCell.TableCol) and
           (FDoc.Paragraphs[LSearchI].TableRow = LCurCell.TableRow - 1) then
          LTargetPI := LSearchI
        else
          Inc(LSearchI);
      end;
    end;

    if LTargetPI >= 0 then
    begin
      // Last line of the cell directly above
      LLineIndex := -1;
      LSearchI := High(FLines);
      while (LSearchI >= 0) and (LLineIndex < 0) do
      begin
        if FLines[LSearchI].ParaIdx = LTargetPI then
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
      while (LSearchI < FDoc.Paragraphs.Count) and
            not ((FDoc.Paragraphs[LSearchI].BlockType = btTableCell) and
                 (FDoc.Paragraphs[LSearchI].TableID = LCurCell.TableID)) do
        Inc(LSearchI);
      if (LSearchI = 0) or (LSearchI >= FDoc.Paragraphs.Count) then
        Exit; // table starts at document beginning
      LTargetPI := LSearchI - 1;
      LLineIndex := -1;
      LSearchI := High(FLines);
      while (LSearchI >= 0) and (LLineIndex < 0) do
      begin
        if FLines[LSearchI].ParaIdx = LTargetPI then
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

  if not DocPosToXY(P, LXPosition, LYPosition, LHeight) then
    Exit;
  LDocX := LXPosition - ContentLeft;
  LLineY := FLines[LLineIndex].Y + FLines[LLineIndex].H / 2;
  Result := HitTest(ContentLeft + LDocX, ContentTop + LLineY);
end;

function THTMLEditor.LineBelow(const P: TDocPos): TDocPos;
var
  LFragmentIndex: Integer;
  LLineIndex: Integer;
  LXPosition, LYPosition, LHeight: Single;
  LDocX: Single;
  LLineY: Single;
  LCurCell: THTMLParagraph;
  LTargetPI: Integer;
  LSearchI: Integer;
  LNeedRowBelow: Boolean;
begin
  Result := P;
  LFragmentIndex := FragmentIndexAt(P.ParaIdx, P.RunIdx, P.CharIdx);
  if LFragmentIndex < 0 then
    Exit;
  LLineIndex := FFrags[LFragmentIndex].LineIdx + 1;

  if (P.ParaIdx < FDoc.Paragraphs.Count) and
     (FDoc.Paragraphs[P.ParaIdx].BlockType = btTableCell) then
  begin
    LCurCell := FDoc.Paragraphs[P.ParaIdx];
    LNeedRowBelow := False;

    if LLineIndex >= Length(FLines) then
      LNeedRowBelow := True
    else if FLines[LLineIndex].ParaIdx = P.ParaIdx then
    begin
      // Within-cell navigation
      if not DocPosToXY(P, LXPosition, LYPosition, LHeight) then
        Exit;
      LDocX := LXPosition - ContentLeft;
      LLineY := FLines[LLineIndex].Y + FLines[LLineIndex].H / 2;
      Result := HitTest(ContentLeft + LDocX, ContentTop + LLineY);
      Exit;
    end
    else
      LNeedRowBelow := True; // LLineIndex is in a sibling column

    if LNeedRowBelow then
    begin
      // Try to find the cell in the row below, same column
      LTargetPI := -1;
      LSearchI := 0;
      while (LSearchI < FDoc.Paragraphs.Count) and (LTargetPI < 0) do
      begin
        if (FDoc.Paragraphs[LSearchI].BlockType = btTableCell) and
           (FDoc.Paragraphs[LSearchI].TableID  = LCurCell.TableID) and
           (FDoc.Paragraphs[LSearchI].TableCol = LCurCell.TableCol) and
           (FDoc.Paragraphs[LSearchI].TableRow = LCurCell.TableRow + 1) then
          LTargetPI := LSearchI
        else
          Inc(LSearchI);
      end;

      if LTargetPI >= 0 then
      begin
        // First line of the cell in the row below
        LLineIndex := -1;
        LSearchI := 0;
        while (LSearchI < Length(FLines)) and (LLineIndex < 0) do
        begin
          if FLines[LSearchI].ParaIdx = LTargetPI then
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
        LSearchI := FDoc.Paragraphs.Count - 1;
        while (LSearchI >= 0) and
              not ((FDoc.Paragraphs[LSearchI].BlockType = btTableCell) and
                   (FDoc.Paragraphs[LSearchI].TableID = LCurCell.TableID)) do
          Dec(LSearchI);
        if (LSearchI < 0) or (LSearchI + 1 >= FDoc.Paragraphs.Count) then
          Exit; // table ends at document end
        LTargetPI := LSearchI + 1;
        LLineIndex := -1;
        LSearchI := 0;
        while (LSearchI < Length(FLines)) and (LLineIndex < 0) do
        begin
          if FLines[LSearchI].ParaIdx = LTargetPI then
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

  if not DocPosToXY(P, LXPosition, LYPosition, LHeight) then
    Exit;
  LDocX := LXPosition - ContentLeft;
  LLineY := FLines[LLineIndex].Y + FLines[LLineIndex].H / 2;
  Result := HitTest(ContentLeft + LDocX, ContentTop + LLineY);
end;

function THTMLEditor.WordRight(const P: TDocPos): TDocPos;
var
  LCur: TDocPos;
  LPara: THTMLParagraph;
  LNext: TDocPos;
begin
  LCur := P;
  while PosCompare(LCur, DocEnd) < 0 do
  begin
    LNext := NextDocPos(LCur);
    if LNext.Equals(LCur) then
      Break;
    LPara := FDoc.Paragraphs[LCur.ParaIdx];
    if (LCur.RunIdx < LPara.Runs.Count) and (LCur.CharIdx < LPara.Runs[LCur.RunIdx].Text.Length) then
    begin
      if LPara.Runs[LCur.RunIdx].Text[Low(string) + LCur.CharIdx] = ' ' then
        Break;
    end
    else
      Break;
    LCur := LNext;
  end;
  while PosCompare(LCur, DocEnd) < 0 do
  begin
    LNext := NextDocPos(LCur);
    if LNext.Equals(LCur) then
      Break;
    LPara := FDoc.Paragraphs[LCur.ParaIdx];
    if (LCur.RunIdx < LPara.Runs.Count) and (LCur.CharIdx < LPara.Runs[LCur.RunIdx].Text.Length) then
    begin
      if LPara.Runs[LCur.RunIdx].Text[Low(string) + LCur.CharIdx] <> ' ' then
        Break;
    end
    else
      Break;
    LCur := LNext;
  end;
  Result := LCur;
end;

function THTMLEditor.WordLeft(const P: TDocPos): TDocPos;
var
  LCur: TDocPos;
  LPrev: TDocPos;
  LPara: THTMLParagraph;
  LCharacter: String;
begin
  LCur := PrevDocPos(P);
  while PosCompare(LCur, DocStart) > 0 do
  begin
    LPrev := PrevDocPos(LCur);
    LPara := FDoc.Paragraphs[LCur.ParaIdx];
    if (LCur.RunIdx < LPara.Runs.Count) and (LCur.CharIdx > 0) and (LCur.CharIdx <= LPara.Runs[LCur.RunIdx].Text.Length)
    then
    begin
      LCharacter := LPara.Runs[LCur.RunIdx].Text[Low(string) + LCur.CharIdx - 1];
      if LCharacter <> ' ' then
        Break;
    end
    else
      Break;
    LCur := LPrev;
  end;
  while PosCompare(LCur, DocStart) > 0 do
  begin
    LPrev := PrevDocPos(LCur);
    LPara := FDoc.Paragraphs[LPrev.ParaIdx];
    if (LPrev.RunIdx < LPara.Runs.Count) and (LPrev.CharIdx >= 0) and
      (LPrev.CharIdx < LPara.Runs[LPrev.RunIdx].Text.Length) then
    begin
      LCharacter := LPara.Runs[LPrev.RunIdx].Text[Low(string) + LPrev.CharIdx];
      if LCharacter = ' ' then
        Break;
    end
    else
      Break;
    LCur := LPrev;
  end;
  Result := LCur;
end;

// -- Mouse ---------------------------------------------------------------------

procedure THTMLEditor.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LHitPosition: TDocPos;
  LElapsedMs: Int64;
  LDist2: Single;
  LSavedScrollY: Single;
begin
  // Save scroll as the VERY FIRST operation: TControl.MouseDown (inherited) calls
  // SetFocusedControl -> DoEnter -> DoLayout -> EnsureCaretVisible and resets
  // FScrollY to show DocStart.  SetFocus may do the same if inherited did not.
  // We restore FScrollY after all potentially-scrolling operations so that
  // HitTest maps screen coordinates to the correct document position.
  LSavedScrollY := FScrollY;
  inherited;
  SetFocus;
  if Length(FFrags) = 0 then
    DoLayout;
  ScrollTo(LSavedScrollY);
  FCaretAtImageRight := False;
  LHitPosition := HitTest(X, Y);
  FMouseDownPos := LHitPosition;
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
       (LHitPosition.ParaIdx < FDoc.Paragraphs.Count) then
    begin
      var LClickParagraph := FDoc.Paragraphs[LHitPosition.ParaIdx];
      if (LHitPosition.RunIdx >= 0) and (LHitPosition.RunIdx < LClickParagraph.Runs.Count) and
         LClickParagraph.Runs[LHitPosition.RunIdx].IsImage then
      begin
        FDragging := False;
        SelectWordAt(LHitPosition);
        Exit;
      end;
    end;
  end;

  FDragging := True;
  SetCaretPos(LHitPosition, ssShift in Shift);
  FCaretOn := True;
  InvalidateRender;
end;

function IsWordChar(const C: Char): Boolean; inline;
begin
  Result := C.IsLetterOrDigit or (C = '_');
end;

// Returns the character to the right of caret position P (#0 if none / not text).
function THTMLEditor.CharAtPos(const P: TDocPos): Char;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
begin
  Result := #0;
  if not P.IsValid or (P.ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LPara := FDoc.Paragraphs[P.ParaIdx];
  if P.RunIdx >= LPara.Runs.Count then
    Exit;
  LRun := LPara.Runs[P.RunIdx];
  if LRun.IsLineBreak or LRun.IsPlaceholder or LRun.IsImage or (P.CharIdx >= LRun.Text.Length) then
    Exit;
  Result := LRun.Text.Chars[P.CharIdx];
end;

procedure THTMLEditor.SelectWordAt(const P: TDocPos);
var
  LPara: THTMLParagraph;
  LWS, LWE: TDocPos;
  LCur: TDocPos;
  LRun: THTMLRun;
  LAnchor: TDocPos;
  LPL: TDocPos;
begin
  if not P.IsValid or (P.ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LPara := FDoc.Paragraphs[P.ParaIdx];

  if (P.RunIdx < LPara.Runs.Count) and
     (LPara.Runs[P.RunIdx].IsPlaceholder or LPara.Runs[P.RunIdx].IsImage) then
  begin
    LRun := LPara.Runs[P.RunIdx];
    FSelStart := TDocPos.At(P.ParaIdx, P.RunIdx, 0);
    FSelEnd := TDocPos.At(P.ParaIdx, P.RunIdx, LRun.Text.Length);
    FHasSelection := True;
    FCaretPos := FSelEnd;
    FCaretOn := True;
    FInsertStyleSet := False;
    UpdateCaretXY;
    EnsureCaretVisible;
    InvalidateRender;
    DoNotifyState;
    Exit;
  end;

  LAnchor := P;
  if not IsWordChar(CharAtPos(LAnchor)) then
  begin
    LPL := PrevDocPos(LAnchor);
    if (LPL.ParaIdx = P.ParaIdx) and IsWordChar(CharAtPos(LPL)) then
      LAnchor := LPL
    else
      Exit;
  end;

  LWS := LAnchor;
  while True do
  begin
    LCur := PrevDocPos(LWS);
    if LCur.Equals(LWS) then
      Break;
    if (LCur.ParaIdx <> P.ParaIdx) or not IsWordChar(CharAtPos(LCur)) then
      Break;
    LWS := LCur;
  end;

  LWE := LAnchor;
  while IsWordChar(CharAtPos(LWE)) do
  begin
    LWE := NextDocPos(LWE);
    if LWE.ParaIdx <> P.ParaIdx then
      Break;
  end;

  if PosCompare(LWS, LWE) = 0 then
    Exit;
  FSelStart := LWS;
  FSelEnd := LWE;
  FHasSelection := True;
  FCaretPos := LWE;
  FCaretOn := True;
  FInsertStyleSet := False;
  UpdateCaretXY;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.SelectParagraphAt(const P: TDocPos);
var
  LPara: THTMLParagraph;
  LWS, LWE: TDocPos;
  LRI: Integer;
begin
  if not P.IsValid or (P.ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LPara := FDoc.Paragraphs[P.ParaIdx];

  LWS := TDocPos.At(P.ParaIdx, 0, 0);
  LWE := LWS;
  LRI := LPara.Runs.Count - 1;
  while (LRI >= 0) and LPara.Runs[LRI].IsLineBreak do
    Dec(LRI);
  if LRI >= 0 then
    LWE := TDocPos.At(P.ParaIdx, LRI, LPara.Runs[LRI].Text.Length);

  if PosCompare(LWS, LWE) = 0 then
  begin
    FCaretPos := LWS;
    ClearSelection;
    FCaretOn := True;
    FInsertStyleSet := False;
    UpdateCaretXY;
    EnsureCaretVisible;
    InvalidateRender;
    DoNotifyState;
    Exit;
  end;

  FSelStart := LWS;
  FSelEnd := LWE;
  FHasSelection := True;
  FCaretPos := LWE;
  FCaretOn := True;
  FInsertStyleSet := False;
  UpdateCaretXY;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

// -- Context Menu --------------------------------------------------------------

procedure THTMLEditor.BuildContextMenu;
  procedure AddItem(const AText: string; ATag: Integer);
  var
    Item: TMenuItem;
  begin
    Item := TMenuItem.Create(FContextMenu);
    Item.Text := AText;
    Item.Tag := ATag;
    Item.OnClick := ContextMenuItemClick;
    FContextMenu.AddObject(Item);
  end;

  procedure AddSep;
  var
    Item: TMenuItem;
  begin
    Item := TMenuItem.Create(FContextMenu);
    Item.Text := '-';
    FContextMenu.AddObject(Item);
  end;

begin
  FContextMenu := TPopupMenu.Create(Self);
  FContextMenu.Stored := False;
  AddItem('Undo', C_CONTEXT_POPUP_ITEM_UNDO);
  AddItem('Redo', C_CONTEXT_POPUP_ITEM_REDO);
  AddSep;
  AddItem('Cut', C_CONTEXT_POPUP_ITEM_CUT);
  AddItem('Copy', C_CONTEXT_POPUP_ITEM_COPY);
  AddItem('Paste', C_CONTEXT_POPUP_ITEM_PASTE);
  AddSep;
  AddItem('Select All', C_CONTEXT_POPUP_ITEM_SELECT_ALL);
  PopupMenu := FContextMenu;
end;

procedure THTMLEditor.UpdateContextMenuState;
var
  LHasSel, LCanUndo, LCanRedo, LCanPaste: Boolean;
  LClipSvc: IFMXClipboardService;
  LItem: TMenuItem;
  LValue: TValue;
begin
  LHasSel := FHasSelection;
  LCanUndo := FUndoStack.Count > 0;
  LCanRedo := FRedoStack.Count > 0;
  LCanPaste := False;
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipSvc) then
  begin
    LValue := LClipSvc.GetClipboard;
    LCanPaste := (LValue.IsType<string> and (LValue.AsType<string> <> ''))
              or THTMLClipboard.HasImage;
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
          LItem.Enabled := LHasSel and not FReadOnly;
        C_CONTEXT_POPUP_ITEM_COPY:
          LItem.Enabled := LHasSel;
        C_CONTEXT_POPUP_ITEM_PASTE:
          LItem.Enabled := LCanPaste and not FReadOnly;
        C_CONTEXT_POPUP_ITEM_SELECT_ALL:
          LItem.Enabled := True;
      end;
    end;
  end;
end;

procedure THTMLEditor.ContextMenuItemClick(Sender: TObject);
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

function THTMLEditor.ShowContextMenu(const ScreenPosition: TPointF): Boolean;
var
  LLocalPt: TPointF;
  LHitPosition: TDocPos;
  LPara: THTMLParagraph;
  LIsAtom: Boolean;
begin
  if not FHasSelection then
  begin
    LLocalPt := ScreenToLocal(ScreenPosition);
    if Length(FFrags) = 0 then
      DoLayout;
    LHitPosition := HitTest(LLocalPt.X, LLocalPt.Y);
    LIsAtom := LHitPosition.IsValid
      and (LHitPosition.ParaIdx < FDoc.Paragraphs.Count)
      and (LHitPosition.RunIdx >= 0);
    if LIsAtom then
    begin
      LPara := FDoc.Paragraphs[LHitPosition.ParaIdx];
      LIsAtom := (LHitPosition.RunIdx < LPara.Runs.Count)
        and (LPara.Runs[LHitPosition.RunIdx].IsImage or LPara.Runs[LHitPosition.RunIdx].IsPlaceholder);
    end;
    if LIsAtom then
      SelectWordAt(LHitPosition)
    else
      SetCaretPos(LHitPosition, False);
  end;
  UpdateContextMenuState;
  Result := inherited ShowContextMenu(ScreenPosition);
end;

procedure THTMLEditor.MouseMove(Shift: TShiftState; X, Y: Single);
var
  LHitPosition: TDocPos;
  LURL: String;
  LNewCursor: TCursor;
  LScrollStep: Single;
begin
  inherited;
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
    if not LHitPosition.Equals(FCaretPos) then
    begin
      if not FHasSelection then
      begin
        FHasSelection := True;
        FSelStart := FMouseDownPos;
      end;
      FSelEnd := LHitPosition;
      FCaretPos := LHitPosition;
      if PosCompare(FSelStart, FSelEnd) = 0 then
        FHasSelection := False;
      UpdateCaretXY;
      InvalidateRender;
      DoNotifyState;
    end;
  end
  else
  begin
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

procedure THTMLEditor.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;
  if (Button = TMouseButton.mbLeft) and (FClickedLinkURL <> '') and not FHasSelection and (LinkURLAt(X, Y) = FClickedLinkURL)
  then
  begin
    if Assigned(FOnLinkClick) then
      FOnLinkClick(Self, FClickedLinkURL, FClickedLinkText);
  end;
  FClickedLinkURL := '';
  FClickedLinkText := '';
  FDragging := False;
end;

procedure THTMLEditor.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  inherited;
  ScrollTo(FScrollY - Sign(WheelDelta) * C_EDITOR_SCROLL_STEP);
  Handled := True;
end;

// -- Keyboard ------------------------------------------------------------------

procedure THTMLEditor.DialogKey(var Key: Word; Shift: TShiftState);
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

function THTMLEditor.IsTableCellOf(AParaIdx, ATableID: Integer): Boolean;
begin
  Result := (AParaIdx >= 0) and (AParaIdx < FDoc.Paragraphs.Count) and
    (FDoc.Paragraphs[AParaIdx].BlockType = btTableCell) and
    (FDoc.Paragraphs[AParaIdx].TableID = ATableID);
end;

// Moves the caret to the next/previous table cell. Returns False when Tab must
// keep its normal meaning (focus change): caret outside a table, Ctrl/Alt
// combinations, Shift+Tab in the first cell, Tab in the last cell when read-only.
function THTMLEditor.DoTableTab(AShift: TShiftState): Boolean;
var
  LCurPara: THTMLParagraph;
  LNewCell: THTMLParagraph;
  LTargetIdx: Integer;
  LTableID: Integer;
  LTableCols: Integer;
  LNewRow: Integer;
begin
  Result := False;
  if not FCaretPos.IsValid or (FCaretPos.ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  if (AShift * [ssCtrl, ssAlt, ssCommand]) <> [] then
    Exit;
  LCurPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  if LCurPara.BlockType <> btTableCell then
    Exit;
  LTableID := LCurPara.TableID;

  if ssShift in AShift then
  begin
    LTargetIdx := FCaretPos.ParaIdx - 1;
    if not IsTableCellOf(LTargetIdx, LTableID) then
      Exit;
    ClearSelection;
    SetCaretPos(TDocPos.At(LTargetIdx, 0, 0), False);
    Result := True;
    Exit;
  end;

  LTargetIdx := FCaretPos.ParaIdx + 1;
  if IsTableCellOf(LTargetIdx, LTableID) then
  begin
    ClearSelection;
    SetCaretPos(TDocPos.At(LTargetIdx, 0, 0), False);
    Result := True;
    Exit;
  end;

  // Last cell: Tab appends a new row
  if FReadOnly then
    Exit;
  ClearSelection;
  SaveUndo;
  LTableCols := LCurPara.TableCols;
  LNewRow := 0;
  for var I := 0 to FDoc.Paragraphs.Count - 1 do
    if IsTableCellOf(I, LTableID) and (FDoc.Paragraphs[I].TableRow > LNewRow) then
      LNewRow := FDoc.Paragraphs[I].TableRow;
  Inc(LNewRow);
  for var I := 0 to LTableCols - 1 do
  begin
    LNewCell := THTMLParagraph.Create;
    LNewCell.BlockType := btTableCell;
    LNewCell.TableID := LTableID;
    LNewCell.TableRow := LNewRow;
    LNewCell.TableCol := I;
    LNewCell.TableCols := LTableCols;
    FDoc.Paragraphs.Insert(LTargetIdx + I, LNewCell);
  end;
  DoLayout;
  DoChanged;
  SetCaretPos(TDocPos.At(LTargetIdx, 0, 0), False);
  Result := True;
end;

procedure THTMLEditor.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
var
  LExtend: Boolean;
  LNextParaIdx: Integer;
  LNewCaretPos: TDocPos;
begin
  inherited;
  LExtend := ssShift in Shift;

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
          ToggleBold;
          Key := 0;
          Exit;
        end;
      'I':
        begin
          ToggleItalic;
          Key := 0;
          Exit;
        end;
      'U':
        begin
          ToggleUnderline;
          Key := 0;
          Exit;
        end;
      'Z':
        begin
          Undo;
          Key := 0;
          Exit;
        end;
      'Y':
        begin
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
        else if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
                (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType in [btImage, btHR]) and
                FCaretAtImageRight then
        begin
          LNewCaretPos := PrevDocPos(FCaretPos);
          FDoc.Paragraphs.Delete(FCaretPos.ParaIdx);
          EnsureValidDocument;
          FCaretAtImageRight := False;
          FCaretPos := LNewCaretPos;
          if not FCaretPos.IsValid then
            FCaretPos := DocStart;
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
        else if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
                (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType in [btImage, btHR]) and
                not FCaretAtImageRight then
        begin
          LNextParaIdx := FCaretPos.ParaIdx;
          FDoc.Paragraphs.Delete(LNextParaIdx);
          EnsureValidDocument;
          FCaretAtImageRight := False;
          FCaretPos := TDocPos.At(Min(LNextParaIdx, FDoc.Paragraphs.Count - 1), 0, 0);
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
          // In a table cell, Enter inserts a line break instead of splitting the cell
          if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
             (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType = btTableCell) then
            InsertLineBreak
          else
            InsertParagraphBreak;
        end;
      end;
    vkLeft:
    begin
      if (not (ssCtrl in Shift)) and FCaretPos.IsValid and
         (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
         (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType in [btImage, btHR]) and
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
          SetCaretPos(WordLeft(FCaretPos), LExtend)
        else
          SetCaretPos(PrevDocPos(FCaretPos), LExtend);
      end;
    end;
    vkRight:
    begin
      if (not (ssCtrl in Shift)) and FCaretPos.IsValid and
         (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
         (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType in [btImage, btHR]) and
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
          SetCaretPos(WordRight(FCaretPos), LExtend)
        else
          SetCaretPos(NextDocPos(FCaretPos), LExtend);
      end;
    end;
    vkUp:
    begin
      LNewCaretPos := LineAbove(FCaretPos);
      FCaretAtImageRight := LNewCaretPos.IsValid and
        (LNewCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
        (FDoc.Paragraphs[LNewCaretPos.ParaIdx].BlockType in [btImage, btHR]);
      SetCaretPos(LNewCaretPos, LExtend);
    end;
    vkDown:
    begin
      FCaretAtImageRight := False;
      SetCaretPos(LineBelow(FCaretPos), LExtend);
    end;
    vkHome:
      if ssCtrl in Shift then
        SetCaretPos(DocStart, LExtend)
      else
        SetCaretPos(LineStart(FCaretPos), LExtend);
    vkEnd:
      if ssCtrl in Shift then
        SetCaretPos(DocEnd, LExtend)
      else
        SetCaretPos(LineEnd(FCaretPos), LExtend);
    vkPrior:
      ScrollTo(FScrollY - Height + C_EDITOR_PADDING);
    vkNext:
      ScrollTo(FScrollY + Height - C_EDITOR_PADDING);
  end;
  Key := 0;
end;

// -- Editing -------------------------------------------------------------------

function THTMLEditor.StyleAtCaret: THTMLTextStyle;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
begin
  if FInsertStyleSet then
  begin
    Result := FInsertStyle;
    Exit;
  end;
  // Style of character at (or just before) caret
  if not FCaretPos.IsValid then
  begin
    Result.Init;
    Exit;
  end;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then
  begin
    Result.Init;
    Exit;
  end;
  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  if (FCaretPos.RunIdx >= 0) and (FCaretPos.RunIdx < LPara.Runs.Count) then
  begin
    LRun := LPara.Runs[FCaretPos.RunIdx];
    // Atoms always report their own style regardless of CharIdx
    if LRun.IsPlaceholder or LRun.IsImage then
    begin
      Result := LRun.Style;
      Exit;
    end;
    Result := LRun.Style;
    // If at start of run, try previous run's style
    if (FCaretPos.CharIdx = 0) and (FCaretPos.RunIdx > 0) then
      Result := LPara.Runs[FCaretPos.RunIdx - 1].Style;
  end
  else
    Result.Init;
end;

procedure THTMLEditor.SplitRunAt(ParaIdx, RunIdx, CharIdx: Integer);
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LR2: THTMLRun;
begin
  if ParaIdx >= FDoc.Paragraphs.Count then
    Exit;
  LPara := FDoc.Paragraphs[ParaIdx];
  if RunIdx >= LPara.Runs.Count then
    Exit;
  LRun := LPara.Runs[RunIdx];
  if LRun.IsLineBreak or LRun.IsPlaceholder or LRun.IsImage or (CharIdx = 0) or (CharIdx >= LRun.Text.Length) then
    Exit;
  LR2 := THTMLRun.Create;
  LR2.Style := LRun.Style;
  LR2.Text := LRun.Text.Substring(CharIdx);
  LRun.Text := LRun.Text.Substring(0, CharIdx);
  LPara.Runs.Insert(RunIdx + 1, LR2);
end;

procedure THTMLEditor.NormalizeRuns(ParaIdx: Integer);
var
  LPara: THTMLParagraph;
  I: Integer;
  LR1, LR2: THTMLRun;
begin
  if ParaIdx >= FDoc.Paragraphs.Count then
    Exit;
  LPara := FDoc.Paragraphs[ParaIdx];
  I := 0;
  while I < LPara.Runs.Count - 1 do
  begin
    LR1 := LPara.Runs[I];
    LR2 := LPara.Runs[I + 1];
    if (not LR1.IsLineBreak) and (not LR2.IsLineBreak) and
       (not LR1.IsPlaceholder) and (not LR2.IsPlaceholder) and
       (not LR1.IsImage) and (not LR2.IsImage) and
       LR1.Style.EqualsFormat(LR2.Style) then
    begin
      LR1.Text := LR1.Text + LR2.Text;
      LPara.Runs.Delete(I + 1);
    end
    else
      Inc(I);
  end;
  I := 0;
  while I < LPara.Runs.Count do
  begin
    if (not LPara.Runs[I].IsLineBreak) and (not LPara.Runs[I].IsImage) and (LPara.Runs[I].Text = '') then
      LPara.Runs.Delete(I)
    else
      Inc(I);
  end;
end;

procedure THTMLEditor.InsertChar(Ch: Char);
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LTextStyle: THTMLTextStyle;
  LRI: Integer;
  LNewR: THTMLRun;
  LNewR2: THTMLRun;
  LSegIdx3: Integer;
  LSegOfs3: Integer;
  LCurSeg3: Integer;
  LAcc3: Integer;
  LRI2: Integer;
  LFound3: Boolean;
begin
  if not FCaretPos.IsValid then
    Exit;
  EnsureValidDocument;
  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  LTextStyle := StyleAtCaret;

  if LPara.Runs.Count = 0 then
  begin
    LRun := THTMLRun.Create;
    LRun.Style := LTextStyle;
    LPara.Runs.Add(LRun);
    FCaretPos.RunIdx := 0;
    FCaretPos.CharIdx := 0;
  end
  else if FCaretPos.RunIdx >= LPara.Runs.Count then
  begin
    LRI := LPara.Runs.Count - 1;
    LRun := LPara.Runs[LRI];
    FCaretPos.RunIdx := LRI;
    FCaretPos.CharIdx := LRun.Text.Length;
  end
  else
    LRun := LPara.Runs[FCaretPos.RunIdx];

  if LRun.IsPlaceholder or LRun.IsImage then
  begin
    LNewR := THTMLRun.Create;
    LNewR.Style := LTextStyle;
    LNewR.Text := Ch;
    if FCaretPos.CharIdx = 0 then
      LPara.Runs.Insert(FCaretPos.RunIdx, LNewR)
    else
    begin
      LPara.Runs.Insert(FCaretPos.RunIdx + 1, LNewR);
      Inc(FCaretPos.RunIdx);
    end;
    FCaretPos.CharIdx := 1;
  end
  else if LRun.IsLineBreak then
  begin
    LNewR := THTMLRun.Create;
    LNewR.Style := LTextStyle;
    LNewR.Text := Ch;
    LPara.Runs.Insert(FCaretPos.RunIdx, LNewR);
    FCaretPos.CharIdx := 1;
  end
  else
  begin
    if not LRun.Style.EqualsFormat(LTextStyle) then
    begin
      SplitRunAt(FCaretPos.ParaIdx, FCaretPos.RunIdx, FCaretPos.CharIdx);
      if FCaretPos.CharIdx = 0 then
      begin
        LNewR := THTMLRun.Create;
        LNewR.Style := LTextStyle;
        LNewR.Text := Ch;
        LPara.Runs.Insert(FCaretPos.RunIdx, LNewR);
        FCaretPos.CharIdx := 1;
      end
      else
      begin
        LNewR2 := THTMLRun.Create;
        LNewR2.Style := LTextStyle;
        LNewR2.Text := Ch;
        LPara.Runs.Insert(FCaretPos.RunIdx + 1, LNewR2);
        Inc(FCaretPos.RunIdx);
        FCaretPos.CharIdx := 1;
      end;
    end
    else
    begin
      LRun.Text := LRun.Text.Substring(0, FCaretPos.CharIdx) + Ch + LRun.Text.Substring(FCaretPos.CharIdx);
      Inc(FCaretPos.CharIdx);
    end;
  end;

  LSegIdx3 := 0;
  LSegOfs3 := FCaretPos.CharIdx;
  for var LRI3 := 0 to FCaretPos.RunIdx - 1 do
    if LRI3 < LPara.Runs.Count then
    begin
      if LPara.Runs[LRI3].IsLineBreak or LPara.Runs[LRI3].IsPlaceholder or LPara.Runs[LRI3].IsImage then
      begin
        Inc(LSegIdx3);
        LSegOfs3 := FCaretPos.CharIdx;
      end
      else
        Inc(LSegOfs3, LPara.Runs[LRI3].Text.Length);
    end;

  NormalizeRuns(FCaretPos.ParaIdx);

  LCurSeg3 := 0;
  LAcc3 := 0;
  FCaretPos.RunIdx := 0;
  FCaretPos.CharIdx := 0;
  LRI2 := 0;
  LFound3 := False;
  while (LRI2 < LPara.Runs.Count) and not LFound3 do
  begin
    if LPara.Runs[LRI2].IsLineBreak or LPara.Runs[LRI2].IsPlaceholder or LPara.Runs[LRI2].IsImage then
    begin
      if LCurSeg3 = LSegIdx3 then
        LFound3 := True
      else
      begin
        Inc(LCurSeg3);
        LAcc3 := 0;
      end;
    end
    else if LCurSeg3 = LSegIdx3 then
    begin
      if LSegOfs3 <= LAcc3 + LPara.Runs[LRI2].Text.Length then
      begin
        FCaretPos.RunIdx := LRI2;
        FCaretPos.CharIdx := LSegOfs3 - LAcc3;
        LFound3 := True;
      end
      else
      begin
        Inc(LAcc3, LPara.Runs[LRI2].Text.Length);
        FCaretPos.RunIdx := LRI2;
        FCaretPos.CharIdx := LPara.Runs[LRI2].Text.Length;
      end;
    end;
    Inc(LRI2);
  end;

  if not FBatchMode then
  begin
    DoLayout;
    DoChanged;
    DoNotifyState;
    InvalidateRender;
  end;
end;

procedure THTMLEditor.InsertString(const S: string);
begin
  if S = '' then
    Exit;
  FBatchMode := True;
  try
    for var LCharacter in S do
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

procedure THTMLEditor.DeleteBack;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LRI: Integer;
  LCI: Integer;
  LPrevCI: Integer;
  LStep: Integer;
  LFirst, LLast: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then
  begin
    FCaretPos := DocEnd;
    Exit;
  end;
  if PosCompare(FCaretPos, DocStart) = 0 then
    Exit;
  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];

  if (LPara.Runs.Count = 0) or ((FCaretPos.RunIdx = 0) and (FCaretPos.CharIdx = 0)) then
  begin
    // Never merge table cells with adjacent paragraphs
    if LPara.BlockType = btTableCell then
      Exit;

    // Backspace on empty list item -> strip list marker, keep indentation
    if (LPara.BlockType = btLI) and (LPara.Runs.Count = 0) then
    begin
      GetListBlockRange(LFirst, LLast);
      LPara.BlockType := btParagraph;
      if LFirst <= FCaretPos.ParaIdx - 1 then
        RenumberListBlock(LFirst, FCaretPos.ParaIdx - 1);
      if FCaretPos.ParaIdx + 1 <= LLast then
        RenumberListBlock(FCaretPos.ParaIdx + 1, LLast);
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
    if (LPara.BlockType = btParagraph) and (LPara.IndentLevel > 0) and (LPara.Runs.Count = 0) then
    begin
      LPara.IndentLevel := LPara.IndentLevel - 1;
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

    if FCaretPos.ParaIdx > 0 then
    begin
      MergeWithPrevious(FCaretPos.ParaIdx);
      DoLayout;
      DoChanged;
      InvalidateRender;
    end;
    Exit;
  end;

  LRI := FCaretPos.RunIdx;
  LCI := FCaretPos.CharIdx;
  if LRI >= LPara.Runs.Count then
  begin
    LRI := LPara.Runs.Count - 1;
    LCI := LPara.Runs[LRI].Text.Length;
  end;
  LRun := LPara.Runs[LRI];

  if LCI = 0 then
  begin
    FCaretPos := PrevDocPos(FCaretPos);
    DeleteForward;
    Exit;
  end;

  if LRun.IsPlaceholder or LRun.IsImage then
  begin
    if LRun.IsPlaceholder then
      FPlaceholders.Remove(LRun);
    LPara.Runs.Delete(LRI);
    var LNewRI := Max(0, LRI - 1);
    var LNewCI: Integer;
    if LPara.Runs.Count = 0 then
    begin
      LNewRI := 0;
      LNewCI := 0;
    end
    else if LNewRI < LPara.Runs.Count then
      LNewCI := LPara.Runs[LNewRI].Text.Length
    else
    begin
      LNewRI := LPara.Runs.Count - 1;
      LNewCI := LPara.Runs[LNewRI].Text.Length;
    end;
    NormalizeRuns(FCaretPos.ParaIdx);
    FCaretPos := TDocPos.At(FCaretPos.ParaIdx, LNewRI, LNewCI);
    DoLayout;
    DoChanged;
    InvalidateRender;
    Exit;
  end
  else if LRun.IsLineBreak then
  begin
    LPara.Runs.Delete(LRI);
    LPrevCI := 0;
    if LRI > 0 then
      LPrevCI := LPara.Runs[LRI - 1].Text.Length;
    FCaretPos := TDocPos.At(FCaretPos.ParaIdx, Max(0, LRI - 1), LPrevCI);
  end
  else
  begin
    LStep := 1;
    if (LCI > 1) and LRun.Text[LCI].IsLowSurrogate and LRun.Text[LCI - 1].IsHighSurrogate then
      LStep := 2;
    LRun.Text := LRun.Text.Substring(0, LCI - LStep) + LRun.Text.Substring(LCI);
    FCaretPos.CharIdx := LCI - LStep;
  end;

  NormalizeRuns(FCaretPos.ParaIdx);
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.DeleteForward;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LRI: Integer;
  LCI: Integer;
  LNR: THTMLRun;
  LStep: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  if PosCompare(FCaretPos, DocEnd) = 0 then
    Exit;

  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];

  if LPara.Runs.Count = 0 then
  begin
    if FCaretPos.ParaIdx < FDoc.Paragraphs.Count - 1 then
    begin
      MergeWithPrevious(FCaretPos.ParaIdx + 1);
      DoLayout;
      DoChanged;
      InvalidateRender;
    end;
    Exit;
  end;

  LRI := Min(FCaretPos.RunIdx, LPara.Runs.Count - 1);
  LCI := FCaretPos.CharIdx;
  LRun := LPara.Runs[LRI];

  if (LRun.IsPlaceholder or LRun.IsImage) and (LCI < LRun.Text.Length) then
  begin
    if LRun.IsPlaceholder then
      FPlaceholders.Remove(LRun);
    LPara.Runs.Delete(LRI);
    var LNewRI2 := Min(LRI, Max(0, LPara.Runs.Count - 1));
    FCaretPos := TDocPos.At(FCaretPos.ParaIdx, LNewRI2, 0);
    NormalizeRuns(FCaretPos.ParaIdx);
    DoLayout;
    DoChanged;
    InvalidateRender;
    Exit;
  end
  else if LRun.IsLineBreak then
  begin
    LPara.Runs.Delete(LRI);
    if LRI >= LPara.Runs.Count then
      LRI := Max(0, LPara.Runs.Count - 1);
    FCaretPos := TDocPos.At(FCaretPos.ParaIdx, LRI, 0);
  end
  else if LCI >= LRun.Text.Length then
  begin
    if LRI + 1 < LPara.Runs.Count then
    begin
      LNR := LPara.Runs[LRI + 1];
      if LNR.IsLineBreak then
        LPara.Runs.Delete(LRI + 1)
      else
      begin
        LStep := 1;
        if (LNR.Text.Length > 1) and LNR.Text[1].IsHighSurrogate and LNR.Text[2].IsLowSurrogate then
          LStep := 2;
        LNR.Text := LNR.Text.Substring(LStep);
      end;
    end
    else
    begin
      if FCaretPos.ParaIdx + 1 < FDoc.Paragraphs.Count then
        MergeWithPrevious(FCaretPos.ParaIdx + 1);
    end;
  end
  else
  begin
    LStep := 1;
    if (LCI < LRun.Text.Length - 1) and
       LRun.Text[LCI + 1].IsHighSurrogate and LRun.Text[LCI + 2].IsLowSurrogate then
      LStep := 2;
    LRun.Text := LRun.Text.Substring(0, LCI) + LRun.Text.Substring(LCI + LStep);
  end;

  NormalizeRuns(FCaretPos.ParaIdx);
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.DeleteSelection;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LSI, LEI: Integer;
  LSRI, LERI, LSCI, LECI: Integer;
  LRun: THTMLRun;
  LPara: THTMLParagraph;
  LSRISplitWillHappen: Boolean;
  LDelFrom: Integer;
  LDelTo: Integer;
  LNewRI: Integer;
  LMaxCI: Integer;
  LParaS: THTMLParagraph;
  LSRunFrom: Integer;
  LParaE: THTMLParagraph;
begin
  if not FHasSelection then
    Exit;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  if PosCompare(LSelectionStart, LSelectionEnd) = 0 then
  begin
    ClearSelection;
    Exit;
  end;

  LSI := LSelectionStart.ParaIdx;
  LSRI := LSelectionStart.RunIdx;
  LSCI := LSelectionStart.CharIdx;
  LEI := LSelectionEnd.ParaIdx;
  LERI := LSelectionEnd.RunIdx;
  LECI := LSelectionEnd.CharIdx;

  if LSI = LEI then
  begin
    LPara := FDoc.Paragraphs[LSI];

    LSRISplitWillHappen := (LSRI < LPara.Runs.Count) and (not LPara.Runs[LSRI].IsLineBreak) and (LSCI > 0) and
      (LSCI < LPara.Runs[LSRI].Text.Length);

    SplitRunAt(LSI, LERI, LECI);

    if LSRISplitWillHappen and (LSRI <= LERI) then
      Inc(LERI);

    SplitRunAt(LSI, LSRI, LSCI);

    LDelFrom := LSRI;
    if LSCI > 0 then
      Inc(LDelFrom);
    LDelTo := LERI;

    for var I := LDelTo downto LDelFrom do
      if I < LPara.Runs.Count then
        LPara.Runs.Delete(I);
    NormalizeRuns(LSI);
    LNewRI := Min(LSRI, Max(0, LPara.Runs.Count - 1));
    LMaxCI := 0;
    if LPara.Runs.Count > 0 then
      LMaxCI := LPara.Runs[Min(LSRI, LPara.Runs.Count - 1)].Text.Length;
    FCaretPos := TDocPos.At(LSI, LNewRI, Min(LSCI, LMaxCI));
  end
  else
  begin
    LParaS := FDoc.Paragraphs[LSI];
    SplitRunAt(LSI, LSRI, LSCI);
    LSRunFrom := IfThen(LSCI > 0, LSRI + 1, LSRI);
    for var I := LParaS.Runs.Count - 1 downto LSRunFrom do
      LParaS.Runs.Delete(I);

    LParaE := FDoc.Paragraphs[LEI];
    SplitRunAt(LEI, LERI, LECI);
    for var I := Min(LERI, LParaE.Runs.Count - 1) downto 0 do
      LParaE.Runs.Delete(I);

    while LParaE.Runs.Count > 0 do
    begin
      LRun := LParaE.Runs[0];
      LParaE.Runs.Extract(LRun);
      LParaS.Runs.Add(LRun);
    end;

    for var I := LEI downto LSI + 1 do
      FDoc.Paragraphs.Delete(I);

    NormalizeRuns(LSI);
    if LParaS.IsEmpty then
    begin
      LParaS.BlockType := btBodyText;
      LParaS.IndentLevel := 0;
    end;
    FCaretPos := TDocPos.At(LSI, Min(LSRI, Max(0, LParaS.Runs.Count - 1)), LSCI);
    if FCaretPos.RunIdx >= LParaS.Runs.Count then
      FCaretPos.RunIdx := Max(0, LParaS.Runs.Count - 1);
    if LParaS.Runs.Count > 0 then
      FCaretPos.CharIdx := Min(FCaretPos.CharIdx, LParaS.Runs[FCaretPos.RunIdx].Text.Length)
    else
      FCaretPos.CharIdx := 0;
  end;

  RebuildPlaceholderList;
  ClearSelection;
  DoLayout;
  DoChanged;
  InvalidateRender;
  DoNotifyState;
end;

function THTMLEditor.GetSelectionHTML: string;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LTempDoc: THTMLDocument;
  LGen: THTMLGenerator;
  LPI: Integer;
  LFirstPara: THTMLParagraph;
  LLastPara: THTMLParagraph;
begin
  Result := '';
  if not FHasSelection then
    Exit;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  if PosCompare(LSelectionStart, LSelectionEnd) = 0 then
    Exit;
  LTempDoc := THTMLDocument.Create;
  LGen := THTMLGenerator.Create;
  try
    for LPI := LSelectionStart.ParaIdx to LSelectionEnd.ParaIdx do
      LTempDoc.Paragraphs.Add(FDoc.Paragraphs[LPI].Clone);
    // Trim end of last paragraph (skip non-text blocks -- they have no runs)
    LLastPara := LTempDoc.Paragraphs.Last;
    if not (LLastPara.BlockType in [btHR, btImage]) then
    begin
      if LSelectionEnd.RunIdx < LLastPara.Runs.Count then
      begin
        if LSelectionEnd.CharIdx < LLastPara.Runs[LSelectionEnd.RunIdx].Text.Length then
          LLastPara.Runs[LSelectionEnd.RunIdx].Text := LLastPara.Runs[LSelectionEnd.RunIdx].Text.Substring(0, LSelectionEnd.CharIdx);
        for var I := LLastPara.Runs.Count - 1 downto LSelectionEnd.RunIdx + 1 do
          LLastPara.Runs.Delete(I);
      end;
    end;
    // Trim start of first paragraph
    LFirstPara := LTempDoc.Paragraphs.First;
    if not (LFirstPara.BlockType in [btHR, btImage]) then
    begin
      if LSelectionStart.RunIdx < LFirstPara.Runs.Count then
      begin
        // Delete runs before LSelectionStart.RunIdx (high to low to avoid index shift)
        for var I := LSelectionStart.RunIdx - 1 downto 0 do
          LFirstPara.Runs.Delete(I);
        // Former LSelectionStart.RunIdx is now at index 0; trim its leading chars
        if (LSelectionStart.CharIdx > 0) and (LFirstPara.Runs.Count > 0) and
           not LFirstPara.Runs[0].IsLineBreak then
          LFirstPara.Runs[0].Text := LFirstPara.Runs[0].Text.Substring(LSelectionStart.CharIdx);
      end;
    end;
    Result := LGen.Generate(LTempDoc);
  finally
    LTempDoc.Free;
    LGen.Free;
  end;
end;

function THTMLEditor.GetSelectionText: string;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LPI, LRI, LCI: Integer;
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LEndCI: Integer;
begin
  Result := '';
  if not FHasSelection then
    Exit;
  GetSelectionRange(LSelectionStart, LSelectionEnd);
  LPI := LSelectionStart.ParaIdx;
  LRI := LSelectionStart.RunIdx;
  LCI := LSelectionStart.CharIdx;
  while PosCompare(TDocPos.At(LPI, LRI, LCI), LSelectionEnd) < 0 do
  begin
    if LPI >= FDoc.Paragraphs.Count then
      Break;
    LPara := FDoc.Paragraphs[LPI];
    if LRI >= LPara.Runs.Count then
    begin
      Result := Result + sLineBreak;
      Inc(LPI);
      LRI := 0;
      LCI := 0;
    end
    else
    begin
      LRun := LPara.Runs[LRI];
      LEndCI := IfThen((LPI = LSelectionEnd.ParaIdx) and (LRI = LSelectionEnd.RunIdx), LSelectionEnd.CharIdx, LRun.Text.Length);
      if LRun.IsLineBreak then
        Result := Result + sLineBreak
      else
        Result := Result + LRun.Text.Substring(LCI, LEndCI - LCI);
      LCI := LEndCI;
      if LCI >= LRun.Text.Length then
      begin
        Inc(LRI);
        LCI := 0;
      end;
      if LRI >= LPara.Runs.Count then
      begin
        if LPI < LSelectionEnd.ParaIdx then
          Result := Result + sLineBreak;
        Inc(LPI);
        LRI := 0;
        LCI := 0;
      end;
    end;
  end;
end;

function THTMLEditor.WordCount: Integer;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LFullText: string;
begin
  LFullText := '';
  for LPara in FDoc.Paragraphs do
  begin
    for LRun in LPara.Runs do
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

function THTMLEditor.CharCount: Integer;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
begin
  Result := 0;
  for LPara in FDoc.Paragraphs do
    for LRun in LPara.Runs do
      if not LRun.IsImage and not LRun.IsLineBreak and not LRun.IsPlaceholder then
        Inc(Result, LRun.Text.Length);
end;

function THTMLEditor.ParagraphSearchText(AParaIdx: Integer): string;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
begin
  Result := '';
  if (AParaIdx < 0) or (AParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LPara := FDoc.Paragraphs[AParaIdx];
  for LRun in LPara.Runs do
    if not LRun.IsImage and not LRun.IsLineBreak and not LRun.IsPlaceholder then
      Result := Result + LRun.Text;
end;

procedure THTMLEditor.SelectRange(const AStart, AEnd: TDocPos);
begin
  FSelStart := AStart;
  FSelEnd := AEnd;
  FHasSelection := PosCompare(AStart, AEnd) <> 0;
  FCaretPos := AEnd;
  FCaretOn := True;
  FCaretTimer.Enabled := False;
  FCaretTimer.Enabled := IsFocused;
  UpdateCaretXY;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

function THTMLEditor.FindNext(const AText: string; ACaseSensitive: Boolean): Boolean;
var
  LFindText: string;
  LSearchFrom: TDocPos;
  LSelS, LSelE: TDocPos;
  LFromParaIdx, LFromCharIdx: Integer;
  LParaIdx: Integer;
  LParaText, LSearchText: string;
  LMatchPos: Integer;
  LFoundStart, LFoundEnd: TDocPos;
begin
  Result := False;
  if AText = '' then
    Exit;
  if FDoc.Paragraphs.Count = 0 then
    Exit;

  if ACaseSensitive then
    LFindText := AText
  else
    LFindText := AText.ToUpper;

  if FHasSelection then
  begin
    GetSelectionRange(LSelS, LSelE);
    LSearchFrom := LSelE;
  end
  else
    LSearchFrom := FCaretPos;

  if not LSearchFrom.IsValid then
    LSearchFrom := DocStart;

  LFromParaIdx := Max(0, Min(LSearchFrom.ParaIdx, FDoc.Paragraphs.Count - 1));
  LFromCharIdx := DocPosToAbsChar(LSearchFrom);

  // Pass 1: from caret paragraph (at caret offset) forward to end
  for LParaIdx := LFromParaIdx to FDoc.Paragraphs.Count - 1 do
  begin
    LParaText := ParagraphSearchText(LParaIdx);
    if ACaseSensitive then
      LSearchText := LParaText
    else
      LSearchText := LParaText.ToUpper;

    if LParaIdx = LFromParaIdx then
      LMatchPos := LSearchText.IndexOf(LFindText, LFromCharIdx)
    else
      LMatchPos := LSearchText.IndexOf(LFindText);

    if LMatchPos >= 0 then
    begin
      LFoundStart := AbsCharToDocPos(LParaIdx, LMatchPos);
      LFoundEnd := AbsCharToDocPos(LParaIdx, LMatchPos + AText.Length, True);
      SelectRange(LFoundStart, LFoundEnd);
      Exit(True);
    end;
  end;

  // Pass 2: wrap -- from beginning to caret paragraph (exclusive)
  for LParaIdx := 0 to LFromParaIdx - 1 do
  begin
    LParaText := ParagraphSearchText(LParaIdx);
    if ACaseSensitive then
      LSearchText := LParaText
    else
      LSearchText := LParaText.ToUpper;

    LMatchPos := LSearchText.IndexOf(LFindText);
    if LMatchPos >= 0 then
    begin
      LFoundStart := AbsCharToDocPos(LParaIdx, LMatchPos);
      LFoundEnd := AbsCharToDocPos(LParaIdx, LMatchPos + AText.Length, True);
      SelectRange(LFoundStart, LFoundEnd);
      Exit(True);
    end;
  end;

  // Pass 3: wrap -- same paragraph, any occurrence before the current offset
  LParaText := ParagraphSearchText(LFromParaIdx);
  if ACaseSensitive then
    LSearchText := LParaText
  else
    LSearchText := LParaText.ToUpper;

  LMatchPos := LSearchText.IndexOf(LFindText);
  if (LMatchPos >= 0) and (LMatchPos < LFromCharIdx) then
  begin
    LFoundStart := AbsCharToDocPos(LFromParaIdx, LMatchPos);
    LFoundEnd := AbsCharToDocPos(LFromParaIdx, LMatchPos + AText.Length, True);
    SelectRange(LFoundStart, LFoundEnd);
    Exit(True);
  end;
end;

function THTMLEditor.FindPrev(const AText: string; ACaseSensitive: Boolean): Boolean;
var
  LFindText: string;
  LSearchFrom: TDocPos;
  LSelS, LSelE: TDocPos;
  LFromParaIdx, LFromCharIdx: Integer;
  LParaIdx: Integer;
  LParaText, LSearchText: string;
  LMatchPos, LLastMatchPos: Integer;
  LFoundStart, LFoundEnd: TDocPos;
begin
  Result := False;
  if AText = '' then
    Exit;
  if FDoc.Paragraphs.Count = 0 then
    Exit;

  if ACaseSensitive then
    LFindText := AText
  else
    LFindText := AText.ToUpper;

  // Start searching just before the selection start (or caret)
  if FHasSelection then
  begin
    GetSelectionRange(LSelS, LSelE);
    LSearchFrom := LSelS;
  end
  else
    LSearchFrom := FCaretPos;

  if not LSearchFrom.IsValid then
    LSearchFrom := DocEnd;

  LFromParaIdx := Max(0, Min(LSearchFrom.ParaIdx, FDoc.Paragraphs.Count - 1));
  LFromCharIdx := DocPosToAbsChar(LSearchFrom);

  // Pass 1: current paragraph -- find the last occurrence strictly before caret
  LParaText := ParagraphSearchText(LFromParaIdx);
  if ACaseSensitive then
    LSearchText := LParaText
  else
    LSearchText := LParaText.ToUpper;

  LLastMatchPos := -1;
  LMatchPos := LSearchText.IndexOf(LFindText);
  while (LMatchPos >= 0) and (LMatchPos < LFromCharIdx) do
  begin
    LLastMatchPos := LMatchPos;
    LMatchPos := LSearchText.IndexOf(LFindText, LMatchPos + 1);
  end;

  if LLastMatchPos >= 0 then
  begin
    LFoundStart := AbsCharToDocPos(LFromParaIdx, LLastMatchPos);
    LFoundEnd := AbsCharToDocPos(LFromParaIdx, LLastMatchPos + AText.Length, True);
    SelectRange(LFoundStart, LFoundEnd);
    Exit(True);
  end;

  // Pass 2: paragraphs before caret (reversed)
  for LParaIdx := LFromParaIdx - 1 downto 0 do
  begin
    LParaText := ParagraphSearchText(LParaIdx);
    if ACaseSensitive then
      LSearchText := LParaText
    else
      LSearchText := LParaText.ToUpper;

    LLastMatchPos := LSearchText.LastIndexOf(LFindText);
    if LLastMatchPos >= 0 then
    begin
      LFoundStart := AbsCharToDocPos(LParaIdx, LLastMatchPos);
      LFoundEnd := AbsCharToDocPos(LParaIdx, LLastMatchPos + AText.Length, True);
      SelectRange(LFoundStart, LFoundEnd);
      Exit(True);
    end;
  end;

  // Pass 3: wrap -- paragraphs after caret (reversed)
  for LParaIdx := FDoc.Paragraphs.Count - 1 downto LFromParaIdx + 1 do
  begin
    LParaText := ParagraphSearchText(LParaIdx);
    if ACaseSensitive then
      LSearchText := LParaText
    else
      LSearchText := LParaText.ToUpper;

    LLastMatchPos := LSearchText.LastIndexOf(LFindText);
    if LLastMatchPos >= 0 then
    begin
      LFoundStart := AbsCharToDocPos(LParaIdx, LLastMatchPos);
      LFoundEnd := AbsCharToDocPos(LParaIdx, LLastMatchPos + AText.Length, True);
      SelectRange(LFoundStart, LFoundEnd);
      Exit(True);
    end;
  end;

  // Pass 4: wrap -- current paragraph, last occurrence at or after caret
  LParaText := ParagraphSearchText(LFromParaIdx);
  if ACaseSensitive then
    LSearchText := LParaText
  else
    LSearchText := LParaText.ToUpper;

  LLastMatchPos := LSearchText.LastIndexOf(LFindText);
  if (LLastMatchPos >= 0) and (LLastMatchPos >= LFromCharIdx) then
  begin
    LFoundStart := AbsCharToDocPos(LFromParaIdx, LLastMatchPos);
    LFoundEnd := AbsCharToDocPos(LFromParaIdx, LLastMatchPos + AText.Length, True);
    SelectRange(LFoundStart, LFoundEnd);
    Exit(True);
  end;
end;

function THTMLEditor.ReplaceAll(const AFindText, AReplaceText: string; ACaseSensitive: Boolean): Integer;
var
  LFindText: string;
  LParaIdx: Integer;
  LPara: THTMLParagraph;
  LParaText, LSearchText: string;
  LRun: THTMLRun;
  LMatchPositions: TList<Integer>;
  LMatchPos, LSearchStart: Integer;
  LMatchIdx: Integer;
  LStartPos, LEndPos: TDocPos;
  LSRI, LSCI, LERI, LECI: Integer;
  LSRISplitWillHappen: Boolean;
  LDelFrom, LDelTo, LI: Integer;
  LReplaceStyle: THTMLTextStyle;
  LNewRun: THTMLRun;
begin
  Result := 0;
  if AFindText = '' then
    Exit;

  if not ACaseSensitive then
    LFindText := AFindText.ToUpper
  else
    LFindText := AFindText;

  SaveUndo;

  LMatchPositions := TList<Integer>.Create;
  try
    for LParaIdx := 0 to FDoc.Paragraphs.Count - 1 do
    begin
      LPara := FDoc.Paragraphs[LParaIdx];
      LParaText := '';
      for LRun in LPara.Runs do
        if not LRun.IsImage and not LRun.IsLineBreak and not LRun.IsPlaceholder then
          LParaText := LParaText + LRun.Text;

      if not ACaseSensitive then
        LSearchText := LParaText.ToUpper
      else
        LSearchText := LParaText;

      // Collect all match positions in this paragraph
      LMatchPositions.Clear;
      LSearchStart := 0;
      LMatchPos := LSearchText.IndexOf(LFindText, LSearchStart);
      while LMatchPos >= 0 do
      begin
        LMatchPositions.Add(LMatchPos);
        LSearchStart := LMatchPos + LFindText.Length;
        LMatchPos := LSearchText.IndexOf(LFindText, LSearchStart);
      end;

      // Process right-to-left so earlier offsets remain valid
      for LMatchIdx := LMatchPositions.Count - 1 downto 0 do
      begin
        LMatchPos := LMatchPositions[LMatchIdx];
        LPara := FDoc.Paragraphs[LParaIdx]; // re-fetch; structure unchanged for this para
        LStartPos := AbsCharToDocPos(LParaIdx, LMatchPos);
        LEndPos := AbsCharToDocPos(LParaIdx, LMatchPos + AFindText.Length, True);

        LSRI := LStartPos.RunIdx;
        LSCI := LStartPos.CharIdx;
        LERI := LEndPos.RunIdx;
        LECI := LEndPos.CharIdx;

        // Capture style from the first matched run before any splits
        if LSRI < LPara.Runs.Count then
          LReplaceStyle := LPara.Runs[LSRI].Style
        else if LPara.Runs.Count > 0 then
          LReplaceStyle := LPara.Runs[LPara.Runs.Count - 1].Style
        else
          LReplaceStyle := StyleAtCaret;

        LSRISplitWillHappen := (LSRI < LPara.Runs.Count) and
          not LPara.Runs[LSRI].IsLineBreak and (LSCI > 0) and
          (LSCI < LPara.Runs[LSRI].Text.Length);

        SplitRunAt(LParaIdx, LERI, LECI);
        if LSRISplitWillHappen and (LSRI <= LERI) then
          Inc(LERI);
        SplitRunAt(LParaIdx, LSRI, LSCI);

        LDelFrom := LSRI;
        if LSCI > 0 then
          Inc(LDelFrom);
        LDelTo := LERI;

        for LI := LDelTo downto LDelFrom do
          if LI < LPara.Runs.Count then
            LPara.Runs.Delete(LI);

        if AReplaceText <> '' then
        begin
          LNewRun := THTMLRun.Create;
          LNewRun.Text := AReplaceText;
          LNewRun.Style := LReplaceStyle;
          if LDelFrom <= LPara.Runs.Count then
            LPara.Runs.Insert(LDelFrom, LNewRun)
          else
            LPara.Runs.Add(LNewRun);
        end;

        NormalizeRuns(LParaIdx);
        Inc(Result);
      end;
    end;
  finally
    LMatchPositions.Free;
  end;

  if Result > 0 then
  begin
    RebuildPlaceholderList;
    ClearSelection;
    DoLayout;
    DoChanged;
    InvalidateRender;
    DoNotifyState;
  end;
end;

procedure THTMLEditor.ScrollToParagraph(AIndex: Integer);
var
  LLineIdx: Integer;
begin
  if (AIndex < 0) or (AIndex >= FDoc.Paragraphs.Count) then
    Exit;
  for LLineIdx := 0 to High(FLines) do
    if FLines[LLineIdx].ParaIdx = AIndex then
    begin
      ScrollTo(FLines[LLineIdx].Y);
      Exit;
    end;
end;

procedure THTMLEditor.ScrollToDocPos(const APos: TDocPos);
var
  LX, LY, LH: Single;
begin
  if DocPosToXY(APos, LX, LY, LH) then
    ScrollTo(LY - ContentTop);
end;

procedure THTMLEditor.InsertParagraphBreak;
var
  LPara, LNewPara: THTMLParagraph;
  LMoveFrom: Integer;
  LRun: THTMLRun;
  LNewParaIdx: Integer;
  LFirst, LLast: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];

  // Enter on empty list item -> exit the list (standard Word/Docs behavior)
  if (LPara.BlockType = btLI) and (LPara.Runs.Count = 0) then
  begin
    GetListBlockRange(LFirst, LLast);
    LPara.BlockType := btParagraph;
    LPara.IndentLevel := 0;
    if LFirst <= FCaretPos.ParaIdx - 1 then
      RenumberListBlock(LFirst, FCaretPos.ParaIdx - 1);
    if FCaretPos.ParaIdx + 1 <= LLast then
      RenumberListBlock(FCaretPos.ParaIdx + 1, LLast);
    FHasSelection := False;
    FSelStart := TDocPos.Invalid;
    FSelEnd := TDocPos.Invalid;
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

  SplitRunAt(FCaretPos.ParaIdx, FCaretPos.RunIdx, FCaretPos.CharIdx);

  LNewPara := THTMLParagraph.Create;
  if LPara.BlockType in [btH1 .. btH6] then
    LNewPara.BlockType := btParagraph
  else
    LNewPara.BlockType := LPara.BlockType;
  LNewPara.Alignment := LPara.Alignment;
  LNewPara.IndentLevel := LPara.IndentLevel;
  LNewPara.ListOrdered := LPara.ListOrdered;
  if LPara.BlockType = btTableCell then
  begin
    LNewPara.TableID := LPara.TableID;
    LNewPara.TableRow := LPara.TableRow;
    LNewPara.TableCol := LPara.TableCol;
    LNewPara.TableCols := LPara.TableCols;
    LNewPara.IsHeader := LPara.IsHeader;
  end;

  LMoveFrom := IfThen(FCaretPos.CharIdx > 0, FCaretPos.RunIdx + 1, FCaretPos.RunIdx);
  while LMoveFrom < LPara.Runs.Count do
  begin
    LRun := LPara.Runs[LMoveFrom];
    LPara.Runs.Extract(LRun);
    LNewPara.Runs.Add(LRun);
  end;

  LNewParaIdx := FCaretPos.ParaIdx + 1;
  FDoc.Paragraphs.Insert(LNewParaIdx, LNewPara);

  // Renumber the full enclosing list block
  if LNewPara.BlockType = btLI then
  begin
    LFirst := LNewParaIdx;
    while (LFirst > 0) and (FDoc.Paragraphs[LFirst - 1].BlockType = btLI) do
      Dec(LFirst);
    LLast := LNewParaIdx;
    while (LLast < FDoc.Paragraphs.Count - 1) and (FDoc.Paragraphs[LLast + 1].BlockType = btLI) do
      Inc(LLast);
    RenumberListBlock(LFirst, LLast);
  end;

  NormalizeRuns(FCaretPos.ParaIdx);

  FCaretPos := TDocPos.At(LNewParaIdx, 0, 0);
  FHasSelection := False;
  FSelStart := TDocPos.Invalid;
  FSelEnd := TDocPos.Invalid;

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

procedure THTMLEditor.InsertLineBreak;
var
  LPara: THTMLParagraph;
  LBrRun: THTMLRun;
  LRI, LCI: Integer;
  LInsertIdx: Integer;
  LAfterIdx: Integer;
  LAnchorRun: THTMLRun;
  LLI3: Integer;
  LFoundLine3: Boolean;
  LFS: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  EnsureValidDocument;

  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  LRI := FCaretPos.RunIdx;
  LCI := FCaretPos.CharIdx;

  if (LPara.Runs.Count > 0) and (LRI >= LPara.Runs.Count) then
  begin
    LRI := LPara.Runs.Count - 1;
    LCI := LPara.Runs[LRI].Text.Length;
  end;

  if (LPara.Runs.Count = 0) or (LCI = 0) then
    LInsertIdx := LRI
  else
  begin
    SplitRunAt(FCaretPos.ParaIdx, LRI, LCI);
    LInsertIdx := LRI + 1;
  end;

  LBrRun := THTMLRun.Create;
  LBrRun.IsLineBreak := True;
  LBrRun.Style := StyleAtCaret;
  if LInsertIdx < LPara.Runs.Count then
    LPara.Runs.Insert(LInsertIdx, LBrRun)
  else
    LPara.Runs.Add(LBrRun);

  LAfterIdx := LInsertIdx + 1;
  if LAfterIdx >= LPara.Runs.Count then
  begin
    LAnchorRun := THTMLRun.Create;
    LAnchorRun.Style := LBrRun.Style;
    LPara.Runs.Insert(LAfterIdx, LAnchorRun);
  end;

  FCaretPos := TDocPos.At(FCaretPos.ParaIdx, LAfterIdx, 0);
  FHasSelection := False;
  FSelStart := TDocPos.Invalid;
  FSelEnd := TDocPos.Invalid;

  DoLayout;
  DoChanged;

  FCaretScreenX := ContentLeft;
  FCaretScreenH := 16;
  FCaretScreenY := ContentTop;
  LLI3 := 0;
  LFoundLine3 := False;
  while (LLI3 <= High(FLines)) and not LFoundLine3 do
  begin
    LFS := FLines[LLI3].FragStart;
    if (FLines[LLI3].ParaIdx = FCaretPos.ParaIdx) and (LFS >= 0) and (LFS < Length(FFrags)) and
      (FFrags[LFS].RunIdx = LAfterIdx) then
    begin
      FCaretScreenY := ContentTop + FLines[LLI3].Y;
      FCaretScreenH := IfThen(FFrags[LFS].H > 0, FFrags[LFS].H, FLines[LLI3].H / FLayoutEngine.LineSpacing);
      LFoundLine3 := True;
    end;
    Inc(LLI3);
  end;

  FCaretOn := True;
  FCaretTimer.Enabled := False;
  FCaretTimer.Enabled := IsFocused;
  EnsureCaretVisible;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.MergeWithPrevious(ParaIdx: Integer);
var
  LRun: THTMLRun;
  LPrevPara: THTMLParagraph;
  LCurPara: THTMLParagraph;
  LOldRunCount: Integer;
  LPrevEndCI: Integer;
begin
  if (ParaIdx <= 0) or (ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LPrevPara := FDoc.Paragraphs[ParaIdx - 1];
  LCurPara := FDoc.Paragraphs[ParaIdx];
  // Non-text blocks (HR/Image) are atomic: just delete them, adjust caret
  if LPrevPara.BlockType in [btHR, btImage] then
  begin
    FDoc.Paragraphs.Delete(ParaIdx - 1);
    FCaretPos := TDocPos.At(ParaIdx - 1, 0, 0);
    Exit;
  end;
  if LCurPara.BlockType in [btHR, btImage] then
  begin
    LOldRunCount := LPrevPara.Runs.Count;
    if LOldRunCount > 0 then
      LPrevEndCI := LPrevPara.Runs[LOldRunCount - 1].Text.Length
    else
      LPrevEndCI := 0;
    FCaretPos := TDocPos.At(ParaIdx - 1, Max(0, LOldRunCount - 1), LPrevEndCI);
    FDoc.Paragraphs.Delete(ParaIdx);
    Exit;
  end;
  LOldRunCount := LPrevPara.Runs.Count;
  if LOldRunCount > 0 then
    LPrevEndCI := LPrevPara.Runs[LOldRunCount - 1].Text.Length
  else
    LPrevEndCI := 0;
  FCaretPos := TDocPos.At(ParaIdx - 1, Max(0, LOldRunCount - 1), LPrevEndCI);
  while LCurPara.Runs.Count > 0 do
  begin
    LRun := LCurPara.Runs[0];
    LCurPara.Runs.Extract(LRun);
    LPrevPara.Runs.Add(LRun);
  end;
  FDoc.Paragraphs.Delete(ParaIdx);
  NormalizeRuns(ParaIdx - 1);
end;

// -- Style application ---------------------------------------------------------

function THTMLEditor.DocPosToAbsChar(const P: TDocPos): Integer;
var
  LParagraph: THTMLParagraph;
  LRunIdx: Integer;
begin
  Result := 0;
  if (P.ParaIdx < 0) or (P.ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LParagraph := FDoc.Paragraphs[P.ParaIdx];
  for LRunIdx := 0 to P.RunIdx - 1 do
  begin
    if LRunIdx < LParagraph.Runs.Count then
      Result := Result + LParagraph.Runs[LRunIdx].Text.Length;
  end;
  Result := Result + P.CharIdx;
end;

function THTMLEditor.AbsCharToDocPos(AParaIdx, AAbsChar: Integer; APreferRight: Boolean): TDocPos;
var
  LParagraph: THTMLParagraph;
  LRunIdx: Integer;
  LRemaining: Integer;
  LRunLen: Integer;
begin
  Result := TDocPos.At(AParaIdx, 0, 0);
  if (AParaIdx < 0) or (AParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LParagraph := FDoc.Paragraphs[AParaIdx];
  if LParagraph.Runs.Count = 0 then
    Exit;
  LRunIdx := 0;
  LRemaining := AAbsChar;
  while LRunIdx < LParagraph.Runs.Count - 1 do
  begin
    LRunLen := LParagraph.Runs[LRunIdx].Text.Length;
    // APreferRight: advance when LRemaining >= run length (boundary -> start of next run)
    // default:      advance when LRemaining >  run length (boundary -> end of current run)
    if (APreferRight and (LRemaining < LRunLen)) or
       ((not APreferRight) and (LRemaining <= LRunLen)) then
      Break;
    LRemaining := LRemaining - LRunLen;
    Inc(LRunIdx);
  end;
  Result := TDocPos.At(AParaIdx, LRunIdx, Min(LRemaining, LParagraph.Runs[LRunIdx].Text.Length));
end;

procedure THTMLEditor.ApplyFormatToSelection(ABold, AItalic, AUnderline, AStrikeOut, ASuperscript, ASubscript: Integer;
  const AFontName: string; AFontSize: Single; AColor, ABackgroundColor: TAlphaColor; const ALinkURL: string);

  procedure ApplyToStyle(var TS: THTMLTextStyle);
  begin
    if ABold >= 0 then
      TS.Bold := ABold = 1;
    if AItalic >= 0 then
      TS.Italic := AItalic = 1;
    if AUnderline >= 0 then
      TS.Underline := AUnderline = 1;
    if AStrikeOut >= 0 then
      TS.StrikeOut := AStrikeOut = 1;
    if ASuperscript >= 0 then
      TS.Superscript := ASuperscript = 1;
    if ASubscript >= 0 then
      TS.Subscript := ASubscript = 1;
    if AFontName <> '' then
      TS.FontName := AFontName;
    if AFontSize > 0 then
      TS.FontSize := AFontSize;
    if (AColor <> claNull) and (AColor <> $00000000) then
      TS.Color := AColor;
    if (ABackgroundColor <> claNull) and (ABackgroundColor <> $00000000) then
      TS.BackgroundColor := ABackgroundColor;
    if ALinkURL <> #0 then
      TS.LinkURL := ALinkURL;
  end;

var
  LSelectionStart, LSelectionEnd: TDocPos;
  LERunExcl: Integer;
  LPI: Integer;
  LRI: Integer;
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LStyle: THTMLTextStyle;
  LSelStartAbsChar: Integer;
  LSelEndAbsChar: Integer;
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

  LSelStartAbsChar := DocPosToAbsChar(FSelStart);
  LSelEndAbsChar   := DocPosToAbsChar(FSelEnd);
  LCaretAbsChar    := DocPosToAbsChar(FCaretPos);

  SplitRunAt(LSelectionEnd.ParaIdx, LSelectionEnd.RunIdx, LSelectionEnd.CharIdx);
  SplitRunAt(LSelectionStart.ParaIdx, LSelectionStart.RunIdx, LSelectionStart.CharIdx);
  LERunExcl := LSelectionEnd.RunIdx;
  if LSelectionEnd.CharIdx > 0 then
    Inc(LERunExcl);
  if LSelectionStart.CharIdx > 0 then
  begin
    Inc(LSelectionStart.RunIdx);
    if LSelectionStart.ParaIdx = LSelectionEnd.ParaIdx then
      Inc(LERunExcl);
  end;
  LSelectionEnd.RunIdx := LERunExcl;

  LPI := LSelectionStart.ParaIdx;
  LRI := LSelectionStart.RunIdx;
  while PosCompare(TDocPos.At(LPI, LRI, 0), TDocPos.At(LSelectionEnd.ParaIdx, LSelectionEnd.RunIdx, 0)) < 0 do
  begin
    if LPI >= FDoc.Paragraphs.Count then
      Break;
    LPara := FDoc.Paragraphs[LPI];
    if LRI >= LPara.Runs.Count then
    begin
      Inc(LPI);
      LRI := 0;
    end
    else
    begin
      LRun := LPara.Runs[LRI];
      if not LRun.IsLineBreak then
      begin
        LStyle := LRun.Style;
        ApplyToStyle(LStyle);
        LRun.Style := LStyle;
      end;
      Inc(LRI);
      if LRI >= LPara.Runs.Count then
      begin
        Inc(LPI);
        LRI := 0;
      end;
    end;
  end;

  for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
    NormalizeRuns(I);

  FSelStart  := AbsCharToDocPos(FSelStart.ParaIdx,  LSelStartAbsChar, True);
  FSelEnd    := AbsCharToDocPos(FSelEnd.ParaIdx,    LSelEndAbsChar,   False);
  FCaretPos  := AbsCharToDocPos(FCaretPos.ParaIdx,  LCaretAbsChar,    LCaretAbsChar = LSelStartAbsChar);
  FHasSelection := FSelStart.IsValid and not FSelStart.Equals(FSelEnd);

  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

// -- Public Formatting ---------------------------------------------------------

procedure THTMLEditor.ToggleBold;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Bold, 0, 1);
  ApplyFormatToSelection(V, -1, -1, -1, -1, -1, '', 0, claNull, claNull);
end;

procedure THTMLEditor.ToggleItalic;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Italic, 0, 1);
  ApplyFormatToSelection(-1, V, -1, -1, -1, -1, '', 0, claNull, claNull);
end;

procedure THTMLEditor.ToggleUnderline;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Underline, 0, 1);
  ApplyFormatToSelection(-1, -1, V, -1, -1, -1, '', 0, claNull, claNull);
end;

procedure THTMLEditor.ToggleStrikeOut;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.StrikeOut, 0, 1);
  ApplyFormatToSelection(-1, -1, -1, V, -1, -1, '', 0, claNull, claNull);
end;

procedure THTMLEditor.ToggleSuperscript;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Superscript, 0, 1);
  ApplyFormatToSelection(-1, -1, -1, -1, V, 0, '', 0, claNull, claNull);
end;

procedure THTMLEditor.ToggleSubscript;
var
  V: Integer;
begin
  V := IfThen(StyleAtCaret.Subscript, 0, 1);
  ApplyFormatToSelection(-1, -1, -1, -1, 0, V, '', 0, claNull, claNull);
end;

procedure THTMLEditor.SetCurrentFontName(const Name: string);
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, Name, 0, claNull, claNull);
end;

procedure THTMLEditor.DecreaseFontSize;
var
  LPresets: TArray<TFontSizePreset>;
  LCur: Single;
  I: Integer;
begin
  LPresets := FontSizePresets;
  LCur := StyleAtCaret.FontSize;
  I := High(LPresets);
  while (I > 0) and (LPresets[I].Size >= LCur) do
    Dec(I);
  SetCurrentFontSize(LPresets[I].Size);
end;

procedure THTMLEditor.IncreaseFontSize;
var
  LPresets: TArray<TFontSizePreset>;
  LCur: Single;
  I: Integer;
begin
  LPresets := FontSizePresets;
  LCur := StyleAtCaret.FontSize;
  I := 0;
  while (I < High(LPresets)) and (LPresets[I].Size <= LCur) do
    Inc(I);
  SetCurrentFontSize(LPresets[I].Size);
end;

procedure THTMLEditor.SetCurrentFontSize(Size: Single);
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', Size, claNull, claNull);
end;

procedure THTMLEditor.SetCurrentFontColor(Color: TAlphaColor);
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', 0, Color, claNull);
end;

procedure THTMLEditor.SetCurrentBackgroundColor(Color: TAlphaColor);
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', 0, claNull, Color);
end;

procedure THTMLEditor.ClearFormatting;
var
  LTextStyle: THTMLTextStyle;
  LSelectionStart, LSelectionEnd: TDocPos;
  LERunExcl2: Integer;
  LPI: Integer;
  LRI: Integer;
  LPara: THTMLParagraph;
  LSelStartAbsChar: Integer;
  LSelEndAbsChar: Integer;
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
  LSelStartAbsChar := DocPosToAbsChar(FSelStart);
  LSelEndAbsChar   := DocPosToAbsChar(FSelEnd);
  LCaretAbsChar    := DocPosToAbsChar(FCaretPos);
  SplitRunAt(LSelectionEnd.ParaIdx, LSelectionEnd.RunIdx, LSelectionEnd.CharIdx);
  SplitRunAt(LSelectionStart.ParaIdx, LSelectionStart.RunIdx, LSelectionStart.CharIdx);
  LERunExcl2 := LSelectionEnd.RunIdx;
  if LSelectionEnd.CharIdx > 0 then
    Inc(LERunExcl2);
  if LSelectionStart.CharIdx > 0 then
  begin
    Inc(LSelectionStart.RunIdx);
    if LSelectionStart.ParaIdx = LSelectionEnd.ParaIdx then
      Inc(LERunExcl2);
  end;
  LSelectionEnd.RunIdx := LERunExcl2;
  LPI := LSelectionStart.ParaIdx;
  LRI := LSelectionStart.RunIdx;
  while PosCompare(TDocPos.At(LPI, LRI, 0), TDocPos.At(LSelectionEnd.ParaIdx, LSelectionEnd.RunIdx, 0)) < 0 do
  begin
    if LPI >= FDoc.Paragraphs.Count then
      Break;
    LPara := FDoc.Paragraphs[LPI];
    if LRI >= LPara.Runs.Count then
    begin
      Inc(LPI);
      LRI := 0;
    end
    else
    begin
      LPara.Runs[LRI].Style := LTextStyle;
      Inc(LRI);
      if LRI >= LPara.Runs.Count then
      begin
        Inc(LPI);
        LRI := 0;
      end;
    end;
  end;
  for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
    NormalizeRuns(I);
  FSelStart  := AbsCharToDocPos(FSelStart.ParaIdx,  LSelStartAbsChar, True);
  FSelEnd    := AbsCharToDocPos(FSelEnd.ParaIdx,    LSelEndAbsChar,   False);
  FCaretPos  := AbsCharToDocPos(FCaretPos.ParaIdx,  LCaretAbsChar,    LCaretAbsChar = LSelStartAbsChar);
  FHasSelection := FSelStart.IsValid and not FSelStart.Equals(FSelEnd);
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.AlignLeft;
var
  LSelectionStart, LSelectionEnd: TDocPos;
begin
  SaveUndo;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    for var I := LSelectionStart.ParaIdx to LSelectionEnd.ParaIdx do
      if I < FDoc.Paragraphs.Count then
        FDoc.Paragraphs[I].Alignment := haLeft;
  end
  else if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) then
    FDoc.Paragraphs[FCaretPos.ParaIdx].Alignment := haLeft;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.AlignCenter;
var
  LSelectionStart, LSelectionEnd: TDocPos;
begin
  SaveUndo;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    for var I := LSelectionStart.ParaIdx to LSelectionEnd.ParaIdx do
      if I < FDoc.Paragraphs.Count then
        FDoc.Paragraphs[I].Alignment := haCenter;
  end
  else if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) then
    FDoc.Paragraphs[FCaretPos.ParaIdx].Alignment := haCenter;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.SetCurrentParagraphFormat(AFormat: TParagraphFormat);
const
  C_PARA_BLOCK_TYPES: array[TParagraphFormat] of THTMLBlockType = (
    btBodyText, btParagraph, btH1, btH2, btH3, btH4, btH5, btH6, btPre);
var
  LSelectionStart, LSelectionEnd: TDocPos;
begin
  if not FCaretPos.IsValid then
    Exit;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then
    Exit;
  SaveUndo;
  if FHasSelection then
    GetSelectionRange(LSelectionStart, LSelectionEnd)
  else
  begin
    LSelectionStart := FCaretPos;
    LSelectionEnd := FCaretPos;
  end;
  for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
    FDoc.Paragraphs[I].BlockType := C_PARA_BLOCK_TYPES[AFormat];
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.AlignRight;
var
  LSelectionStart, LSelectionEnd: TDocPos;
begin
  SaveUndo;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    for var I := LSelectionStart.ParaIdx to LSelectionEnd.ParaIdx do
      if I < FDoc.Paragraphs.Count then
        FDoc.Paragraphs[I].Alignment := haRight;
  end
  else if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) then
    FDoc.Paragraphs[FCaretPos.ParaIdx].Alignment := haRight;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.AlignJustify;
var
  LSelectionStart, LSelectionEnd: TDocPos;
begin
  SaveUndo;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    for var I := LSelectionStart.ParaIdx to LSelectionEnd.ParaIdx do
      if I < FDoc.Paragraphs.Count then
        FDoc.Paragraphs[I].Alignment := haJustify;
  end
  else if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) then
    FDoc.Paragraphs[FCaretPos.ParaIdx].Alignment := haJustify;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.SetHeading(Level: Integer);
const
  C_BLOCK_TYPES: array [0 .. 6] of THTMLBlockType = (btParagraph, btH1, btH2, btH3, btH4, btH5, btH6);
var
  LLevel: Integer;
  LSelectionStart, LSelectionEnd: TDocPos;
begin
  if not FCaretPos.IsValid then
    Exit;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then
    Exit;
  SaveUndo;
  LLevel := Max(0, Min(6, Level));
  if FHasSelection then
    GetSelectionRange(LSelectionStart, LSelectionEnd)
  else
  begin
    LSelectionStart := FCaretPos;
    LSelectionEnd := FCaretPos;
  end;
  for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
    FDoc.Paragraphs[I].BlockType := C_BLOCK_TYPES[LLevel];
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.ToggleOrderedList;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LFirst, LLast: Integer;
  LIndent: Integer;
  LAllOrdered: Boolean;
  LOnList: Boolean;
begin
  if not FCaretPos.IsValid then
    Exit;
  SaveUndo;
  LAllOrdered := GetCurrentIsOrderedList;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LFirst := LSelectionStart.ParaIdx;
    LLast  := Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1);
    LIndent := -1; // no indent filter for explicit selection
  end
  else
  begin
    LOnList := FCaretPos.IsValid and
               (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
               (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType = btLI);
    if LOnList then
    begin
      LIndent := FDoc.Paragraphs[FCaretPos.ParaIdx].IndentLevel;
      GetListBlockRange(LFirst, LLast);
    end
    else
    begin
      LFirst  := FCaretPos.ParaIdx;
      LLast   := FCaretPos.ParaIdx;
      LIndent := -1;
    end;
  end;
  if LAllOrdered then
  begin
    for var I := LFirst to LLast do
      if (LIndent < 0) or (FDoc.Paragraphs[I].IndentLevel = LIndent) then
      begin
        FDoc.Paragraphs[I].BlockType  := btParagraph;
        FDoc.Paragraphs[I].IndentLevel := 0;
      end;
  end
  else
  begin
    for var I := LFirst to LLast do
      if (LIndent < 0) or (FDoc.Paragraphs[I].IndentLevel = LIndent) then
      begin
        FDoc.Paragraphs[I].BlockType   := btLI;
        FDoc.Paragraphs[I].ListOrdered := True;
      end;
    RenumberListBlock(LFirst, LLast);
  end;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.ToggleUnorderedList;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LFirst, LLast: Integer;
  LIndent: Integer;
  LAllUnordered: Boolean;
  LOnList: Boolean;
begin
  if not FCaretPos.IsValid then
    Exit;
  SaveUndo;
  LAllUnordered := GetCurrentIsUnorderedList;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    LFirst := LSelectionStart.ParaIdx;
    LLast  := Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1);
    LIndent := -1;
  end
  else
  begin
    LOnList := FCaretPos.IsValid and
               (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
               (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType = btLI);
    if LOnList then
    begin
      LIndent := FDoc.Paragraphs[FCaretPos.ParaIdx].IndentLevel;
      GetListBlockRange(LFirst, LLast);
    end
    else
    begin
      LFirst  := FCaretPos.ParaIdx;
      LLast   := FCaretPos.ParaIdx;
      LIndent := -1;
    end;
  end;
  if LAllUnordered then
  begin
    for var I := LFirst to LLast do
      if (LIndent < 0) or (FDoc.Paragraphs[I].IndentLevel = LIndent) then
      begin
        FDoc.Paragraphs[I].BlockType   := btParagraph;
        FDoc.Paragraphs[I].IndentLevel := 0;
      end;
  end
  else
  begin
    for var I := LFirst to LLast do
      if (LIndent < 0) or (FDoc.Paragraphs[I].IndentLevel = LIndent) then
      begin
        FDoc.Paragraphs[I].BlockType   := btLI;
        FDoc.Paragraphs[I].ListOrdered := False;
      end;
  end;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.Indent;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LFirst, LLast: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  SaveUndo;
  if FHasSelection then
    GetSelectionRange(LSelectionStart, LSelectionEnd)
  else
  begin
    LSelectionStart := FCaretPos;
    LSelectionEnd := FCaretPos;
  end;
  for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
    FDoc.Paragraphs[I].IndentLevel := FDoc.Paragraphs[I].IndentLevel + 1;
  // Extend to the full enclosing list block and renumber
  LFirst := LSelectionStart.ParaIdx;
  while (LFirst > 0) and (FDoc.Paragraphs[LFirst - 1].BlockType = btLI) do
    Dec(LFirst);
  LLast := Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1);
  while (LLast < FDoc.Paragraphs.Count - 1) and (FDoc.Paragraphs[LLast + 1].BlockType = btLI) do
    Inc(LLast);
  RenumberListBlock(LFirst, LLast);
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.Outdent;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LFirst, LLast: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  SaveUndo;
  if FHasSelection then
    GetSelectionRange(LSelectionStart, LSelectionEnd)
  else
  begin
    LSelectionStart := FCaretPos;
    LSelectionEnd := FCaretPos;
  end;
  for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
    FDoc.Paragraphs[I].IndentLevel := Max(0, FDoc.Paragraphs[I].IndentLevel - 1);
  // Extend to the full enclosing list block and renumber
  LFirst := LSelectionStart.ParaIdx;
  while (LFirst > 0) and (FDoc.Paragraphs[LFirst - 1].BlockType = btLI) do
    Dec(LFirst);
  LLast := Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1);
  while (LLast < FDoc.Paragraphs.Count - 1) and (FDoc.Paragraphs[LLast + 1].BlockType = btLI) do
    Inc(LLast);
  RenumberListBlock(LFirst, LLast);
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.InsertHorizontalRule(AColor: TAlphaColor = claNull; AThickness: Single = 0);
var
  LHR: THTMLParagraph;
  LNewP: THTMLParagraph;
begin
  if not FCaretPos.IsValid then
    Exit;
  SaveUndo;
  LHR := THTMLParagraph.Create;
  LHR.BlockType := btHR;
  LHR.HRColor := AColor;
  LHR.HRThickness := AThickness;
  FDoc.Paragraphs.Insert(FCaretPos.ParaIdx + 1, LHR);
  FCaretPos := TDocPos.At(FCaretPos.ParaIdx + 1, 0, 0);
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count - 1 then
  begin
    LNewP := THTMLParagraph.Create;
    LNewP.BlockType := btParagraph;
    FDoc.Paragraphs.Add(LNewP);
  end;
  FCaretPos := TDocPos.At(FCaretPos.ParaIdx + 1, 0, 0);
  DoLayout;
  DoChanged;
  InvalidateRender;
end;

procedure THTMLEditor.InsertImage(const ASrc: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
begin
  InsertInlineImage(ASrc, AWidth, AHeight, AAlt);
end;

procedure THTMLEditor.InsertInlineImage(const ASrc: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LBmp: TBitmap;
  LInsertIdx: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  SaveUndo;
  if FHasSelection then
    DeleteSelection;
  EnsureValidDocument;
  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  SplitRunAt(FCaretPos.ParaIdx, FCaretPos.RunIdx, FCaretPos.CharIdx);
  LInsertIdx := FCaretPos.RunIdx;
  if (LPara.Runs.Count > 0) and (FCaretPos.CharIdx > 0) then
    Inc(LInsertIdx);
  LRun := THTMLRun.Create;
  LRun.IsImage := True;
  LRun.ImageSrc := ASrc;
  LRun.ImageWidth := AWidth;
  LRun.ImageHeight := AHeight;
  LRun.ImageAlt := AAlt;
  LRun.Style := StyleAtCaret;
  LRun.Text := #$FFFC;
  if (LRun.ImageWidth = 0) or (LRun.ImageHeight = 0) then
  begin
    LBmp := LoadImage(ASrc, ilcInsert);
    if Assigned(LBmp) then
    begin
      if LRun.ImageWidth = 0 then
        LRun.ImageWidth := LBmp.Width;
      if LRun.ImageHeight = 0 then
        LRun.ImageHeight := LBmp.Height;
    end;
  end;
  LPara.Runs.Insert(LInsertIdx, LRun);
  FCaretPos := TDocPos.At(FCaretPos.ParaIdx, LInsertIdx, LRun.Text.Length);
  NormalizeRuns(FCaretPos.ParaIdx);
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

procedure THTMLEditor.UpdateImage(const ASrc: string; AWidth: Integer = 0; AHeight: Integer = 0; const AAlt: string = '');
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LBmp: TBitmap;
begin
  if not FCaretPos.IsValid then
    Exit;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then
    Exit;
  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  if (FCaretPos.RunIdx < 0) or (FCaretPos.RunIdx >= LPara.Runs.Count) then
    Exit;
  LRun := LPara.Runs[FCaretPos.RunIdx];
  if not LRun.IsImage then
    Exit;
  SaveUndo;
  LRun.ImageSrc := ASrc;
  LRun.ImageAlt := AAlt;
  LRun.ImageWidth := AWidth;
  LRun.ImageHeight := AHeight;
  if (LRun.ImageWidth = 0) or (LRun.ImageHeight = 0) then
  begin
    LBmp := LoadImage(ASrc, ilcInsert);
    if Assigned(LBmp) then
    begin
      if LRun.ImageWidth = 0 then
        LRun.ImageWidth := LBmp.Width;
      if LRun.ImageHeight = 0 then
        LRun.ImageHeight := LBmp.Height;
    end;
  end;
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

procedure THTMLEditor.ReloadImages;
var
  LSrcs: TArray<string>;
  LSrc: string;
  LBmp: TBitmap;
begin
  LSrcs := FImageCache.Keys.ToArray;
  for LSrc in LSrcs do
  begin
    LBmp := LoadBitmapFromSrc(LSrc);
    if Assigned(FOnLoadImage) then
      FOnLoadImage(Self, LSrc, LBmp, ilcReload);
    if Assigned(LBmp) then
      FImageCache.AddOrSetValue(LSrc, LBmp);
  end;
  DoLayout;
  InvalidateRender;
end;

procedure THTMLEditor.InsertTable(ARows: Integer = 2; ACols: Integer = 2);
var
  LInsertAt: Integer;
  LNewPara: THTMLParagraph;
  LRow: Integer;
  LCol: Integer;
  LTableID: Integer;
  LFirstCellIdx: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  if ARows < 1 then ARows := 1;
  if ACols < 1 then ACols := 1;
  SaveUndo;
  LTableID := NextTableID;
  LInsertAt := FCaretPos.ParaIdx + 1;
  LFirstCellIdx := LInsertAt;
  for LRow := 0 to ARows - 1 do
    for LCol := 0 to ACols - 1 do
    begin
      LNewPara := THTMLParagraph.Create;
      LNewPara.BlockType := btTableCell;
      LNewPara.TableID := LTableID;
      LNewPara.TableRow := LRow;
      LNewPara.TableCol := LCol;
      LNewPara.TableCols := ACols;
      FDoc.Paragraphs.Insert(LInsertAt, LNewPara);
      Inc(LInsertAt);
    end;
  // Ensure a paragraph after the table for cursor placement
  if (LInsertAt >= FDoc.Paragraphs.Count) or
     (FDoc.Paragraphs[LInsertAt].BlockType = btTableCell) then
  begin
    LNewPara := THTMLParagraph.Create;
    LNewPara.BlockType := btParagraph;
    FDoc.Paragraphs.Insert(LInsertAt, LNewPara);
  end;
  DoLayout;
  DoChanged;
  SetCaretPos(TDocPos.At(LFirstCellIdx, 0, 0), False);
end;

procedure THTMLEditor.GetTableBounds(ATableID: Integer; out AFirstIdx, ALastIdx: Integer);
var
  LPI: Integer;
begin
  AFirstIdx := -1;
  ALastIdx := -1;
  for LPI := 0 to FDoc.Paragraphs.Count - 1 do
    if (FDoc.Paragraphs[LPI].BlockType = btTableCell) and
       (FDoc.Paragraphs[LPI].TableID = ATableID) then
    begin
      if AFirstIdx < 0 then
        AFirstIdx := LPI;
      ALastIdx := LPI;
    end;
end;

function THTMLEditor.FindFirstCellInRow(ATableID, ARow: Integer): Integer;
var
  LPI: Integer;
  LFound: Boolean;
begin
  Result := -1;
  LFound := False;
  for LPI := 0 to FDoc.Paragraphs.Count - 1 do
    if (FDoc.Paragraphs[LPI].BlockType = btTableCell) and
       (FDoc.Paragraphs[LPI].TableID = ATableID) and
       (FDoc.Paragraphs[LPI].TableRow = ARow) and not LFound then
    begin
      Result := LPI;
      LFound := True;
    end;
end;

procedure THTMLEditor.InsertTableRow;
var
  LCurPara: THTMLParagraph;
  LTableID, LTargetRow, LTableCols: Integer;
  LFirstIdx, LLastIdx: Integer;
  LInsertAt, LNewFirstCellIdx: Integer;
  LPI: Integer;
  LNewCell: THTMLParagraph;
  LNewRowIdx: Integer;
begin
  if FReadOnly then Exit;
  if not FCaretPos.IsValid then Exit;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then Exit;
  LCurPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  if LCurPara.BlockType <> btTableCell then Exit;

  SaveUndo;
  LTableID := LCurPara.TableID;
  LTargetRow := LCurPara.TableRow;
  LTableCols := LCurPara.TableCols;
  LNewRowIdx := LTargetRow + 1;

  GetTableBounds(LTableID, LFirstIdx, LLastIdx);

  // Shift existing rows after the target row up by one
  for LPI := LFirstIdx to LLastIdx do
    if FDoc.Paragraphs[LPI].TableRow > LTargetRow then
      FDoc.Paragraphs[LPI].TableRow := FDoc.Paragraphs[LPI].TableRow + 1;

  // Find insertion point: right after the last cell of LTargetRow
  LInsertAt := LFirstIdx;
  for LPI := LFirstIdx to LLastIdx do
    if FDoc.Paragraphs[LPI].TableRow = LTargetRow then
      LInsertAt := LPI + 1;

  // Insert new row (one empty cell per column)
  LNewFirstCellIdx := LInsertAt;
  for var LCol := 0 to LTableCols - 1 do
  begin
    LNewCell := THTMLParagraph.Create;
    LNewCell.BlockType := btTableCell;
    LNewCell.TableID := LTableID;
    LNewCell.TableRow := LNewRowIdx;
    LNewCell.TableCol := LCol;
    LNewCell.TableCols := LTableCols;
    FDoc.Paragraphs.Insert(LInsertAt + LCol, LNewCell);
  end;

  DoLayout;
  DoChanged;
  SetCaretPos(TDocPos.At(LNewFirstCellIdx, 0, 0), False);
end;

procedure THTMLEditor.DeleteTableRow;
var
  LCurPara: THTMLParagraph;
  LTableID, LTargetRow: Integer;
  LFirstIdx, LLastIdx: Integer;
  LPI: Integer;
  LPara: THTMLParagraph;
  LNewCaretIdx: Integer;
  LRowCount: Integer;
  LNewPara: THTMLParagraph;
begin
  if FReadOnly then Exit;
  if not FCaretPos.IsValid then Exit;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then Exit;
  LCurPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  if LCurPara.BlockType <> btTableCell then Exit;

  SaveUndo;
  LTableID := LCurPara.TableID;
  LTargetRow := LCurPara.TableRow;

  GetTableBounds(LTableID, LFirstIdx, LLastIdx);

  // Count distinct rows (max TableRow + 1)
  LRowCount := 0;
  for LPI := LFirstIdx to LLastIdx do
    if FDoc.Paragraphs[LPI].TableRow > LRowCount then
      LRowCount := FDoc.Paragraphs[LPI].TableRow;
  Inc(LRowCount);

  // Delete all cells belonging to the target row (right-to-left)
  for LPI := LLastIdx downto LFirstIdx do
  begin
    LPara := FDoc.Paragraphs[LPI];
    if (LPara.BlockType = btTableCell) and (LPara.TableID = LTableID) and
       (LPara.TableRow = LTargetRow) then
      FDoc.Paragraphs.Delete(LPI);
  end;

  LNewCaretIdx := 0;

  if LRowCount = 1 then
  begin
    // Last row deleted -- ensure a normal paragraph exists at that position
    LNewCaretIdx := Max(0, Min(LFirstIdx, FDoc.Paragraphs.Count));
    if (LNewCaretIdx >= FDoc.Paragraphs.Count) or
       (FDoc.Paragraphs[LNewCaretIdx].BlockType = btTableCell) then
    begin
      LNewPara := THTMLParagraph.Create;
      LNewPara.BlockType := btParagraph;
      FDoc.Paragraphs.Insert(LNewCaretIdx, LNewPara);
    end;
  end
  else
  begin
    // Renumber remaining rows
    GetTableBounds(LTableID, LFirstIdx, LLastIdx);
    for LPI := LFirstIdx to LLastIdx do
    begin
      LPara := FDoc.Paragraphs[LPI];
      if LPara.TableRow > LTargetRow then
        LPara.TableRow := LPara.TableRow - 1;
    end;

    // Place caret at first cell of:
    //   - LTargetRow (now the row that was LTargetRow+1) if not last row
    //   - LTargetRow-1 if the deleted row was the last one
    if LTargetRow >= LRowCount - 1 then
      LNewCaretIdx := FindFirstCellInRow(LTableID, LTargetRow - 1)
    else
      LNewCaretIdx := FindFirstCellInRow(LTableID, LTargetRow);

    if LNewCaretIdx < 0 then
      LNewCaretIdx := LFirstIdx;
  end;

  DoLayout;
  DoChanged;
  SetCaretPos(TDocPos.At(Max(0, LNewCaretIdx), 0, 0), False);
end;

procedure THTMLEditor.InsertTableColumn;
var
  LCurPara: THTMLParagraph;
  LTableID, LTargetCol, LTableCols: Integer;
  LFirstIdx, LLastIdx: Integer;
  LMaxRow, LRow: Integer;
  LPI: Integer;
  LPara: THTMLParagraph;
  LInsertAt: Integer;
  LNewCell: THTMLParagraph;
  LNewCellIdx: Integer;
begin
  if FReadOnly then Exit;
  if not FCaretPos.IsValid then Exit;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then Exit;
  LCurPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  if LCurPara.BlockType <> btTableCell then Exit;

  SaveUndo;
  LTableID := LCurPara.TableID;
  LTargetCol := LCurPara.TableCol;
  LTableCols := LCurPara.TableCols;

  GetTableBounds(LTableID, LFirstIdx, LLastIdx);

  // Find max row index
  LMaxRow := 0;
  for LPI := LFirstIdx to LLastIdx do
    if FDoc.Paragraphs[LPI].TableRow > LMaxRow then
      LMaxRow := FDoc.Paragraphs[LPI].TableRow;

  // Step 1: shift TableCol and update TableCols on all existing cells
  for LPI := LFirstIdx to LLastIdx do
  begin
    LPara := FDoc.Paragraphs[LPI];
    if LPara.TableCol > LTargetCol then
      LPara.TableCol := LPara.TableCol + 1;
    LPara.TableCols := LTableCols + 1;
  end;

  // Step 2: insert one new cell per row, processing last row first
  //         so that earlier paragraph indices remain valid
  LNewCellIdx := -1;
  for LRow := LMaxRow downto 0 do
  begin
    // Find the para index of the cell at (LRow, LTargetCol)
    LInsertAt := -1;
    for LPI := LFirstIdx to LLastIdx do
    begin
      LPara := FDoc.Paragraphs[LPI];
      if (LPara.TableID = LTableID) and (LPara.TableRow = LRow) and
         (LPara.TableCol = LTargetCol) then
        LInsertAt := LPI + 1;
    end;
    if LInsertAt < 0 then
      LInsertAt := LLastIdx + 1;

    LNewCell := THTMLParagraph.Create;
    LNewCell.BlockType := btTableCell;
    LNewCell.TableID := LTableID;
    LNewCell.TableRow := LRow;
    LNewCell.TableCol := LTargetCol + 1;
    LNewCell.TableCols := LTableCols + 1;
    FDoc.Paragraphs.Insert(LInsertAt, LNewCell);

    // Track the new cell in the caret's row
    if LRow = LCurPara.TableRow then
      LNewCellIdx := LInsertAt;

    // LLastIdx grows by one after each insertion
    Inc(LLastIdx);
  end;

  if LNewCellIdx < 0 then
    LNewCellIdx := LFirstIdx;

  DoLayout;
  DoChanged;
  SetCaretPos(TDocPos.At(LNewCellIdx, 0, 0), False);
end;

procedure THTMLEditor.DeleteTableColumn;
var
  LCurPara: THTMLParagraph;
  LTableID, LTargetCol, LTableCols: Integer;
  LFirstIdx, LLastIdx: Integer;
  LPI: Integer;
  LPara: THTMLParagraph;
  LNewCaretIdx: Integer;
  LNewCaretCol: Integer;
  LNewCaretFound: Boolean;
  LNewPara: THTMLParagraph;
begin
  if FReadOnly then Exit;
  if not FCaretPos.IsValid then Exit;
  if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then Exit;
  LCurPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  if LCurPara.BlockType <> btTableCell then Exit;

  SaveUndo;
  LTableID := LCurPara.TableID;
  LTargetCol := LCurPara.TableCol;
  LTableCols := LCurPara.TableCols;

  GetTableBounds(LTableID, LFirstIdx, LLastIdx);

  // Delete all cells in the target column (right-to-left)
  for LPI := LLastIdx downto LFirstIdx do
  begin
    LPara := FDoc.Paragraphs[LPI];
    if (LPara.TableID = LTableID) and (LPara.TableCol = LTargetCol) then
      FDoc.Paragraphs.Delete(LPI);
  end;

  LNewCaretIdx := 0;

  if LTableCols = 1 then
  begin
    // Last column deleted -- ensure a normal paragraph at that position
    LNewCaretIdx := Max(0, Min(LFirstIdx, FDoc.Paragraphs.Count));
    if (LNewCaretIdx >= FDoc.Paragraphs.Count) or
       (FDoc.Paragraphs[LNewCaretIdx].BlockType = btTableCell) then
    begin
      LNewPara := THTMLParagraph.Create;
      LNewPara.BlockType := btParagraph;
      FDoc.Paragraphs.Insert(LNewCaretIdx, LNewPara);
    end;
  end
  else
  begin
    // Update remaining cells
    GetTableBounds(LTableID, LFirstIdx, LLastIdx);
    for LPI := LFirstIdx to LLastIdx do
    begin
      LPara := FDoc.Paragraphs[LPI];
      LPara.TableCols := LTableCols - 1;
      if LPara.TableCol > LTargetCol then
        LPara.TableCol := LPara.TableCol - 1;
    end;

    // Find new caret: same row, adjacent column
    // Prefer LTargetCol (now the cell that was at LTargetCol+1),
    // or LTargetCol-1 if the deleted column was the last one
    LNewCaretCol := Min(LTargetCol, LTableCols - 2);
    LNewCaretFound := False;
    for LPI := LFirstIdx to LLastIdx do
    begin
      LPara := FDoc.Paragraphs[LPI];
      if (LPara.TableRow = LCurPara.TableRow) and (LPara.TableCol = LNewCaretCol) and
         not LNewCaretFound then
      begin
        LNewCaretIdx := LPI;
        LNewCaretFound := True;
      end;
    end;

    if not LNewCaretFound then
      LNewCaretIdx := LFirstIdx;
  end;

  DoLayout;
  DoChanged;
  SetCaretPos(TDocPos.At(Max(0, LNewCaretIdx), 0, 0), False);
end;

procedure THTMLEditor.InsertText(const S: string);
begin
  if S = '' then
    Exit;
  SaveUndo;
  InsertString(S);
end;

procedure THTMLEditor.InsertLink(const AURL, AText: string);
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

procedure THTMLEditor.UpdateLink(const AURL: string);
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LStyle: THTMLTextStyle;
begin
  if FHasSelection then
    ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', 0, claNull, claNull, AURL)
  else if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) then
  begin
    LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
    if (FCaretPos.RunIdx < LPara.Runs.Count) and (LPara.Runs[FCaretPos.RunIdx].Style.LinkURL <> '') then
    begin
      LRun := LPara.Runs[FCaretPos.RunIdx];
      LStyle := LRun.Style;
      LStyle.LinkURL := AURL;
      SaveUndo;
      LRun.Style := LStyle;
      DoLayout;
      InvalidateRender;
      DoNotifyState;
    end;
  end;
end;

procedure THTMLEditor.RemoveLink;
begin
  ApplyFormatToSelection(-1, -1, -1, -1, -1, -1, '', 0, claNull, claNull, '');
end;

function THTMLEditor.GetLinkAtCaret: string;
begin
  Result := StyleAtCaret.LinkURL;
end;

procedure THTMLEditor.InsertHTML(const HTML: string);
var
  LInsDoc: THTMLDocument;
  LCurPara: THTMLParagraph;
  LTailPara: THTMLParagraph;
  LSrcPara: THTMLParagraph;
  LMoveFrom: Integer;
  LInsertAt: Integer;
  LOrigParaIdx: Integer;
  LParser: THTMLParser;
  LLastRI: Integer;
  LTargSeg: Integer;
  LTargOfs: Integer;
  LCurSeg: Integer;
  LAcc: Integer;
  LLI4: Integer;
  LFound4: Boolean;
  LLastSrc: THTMLParagraph;
  LRun: THTMLRun;
begin
  if HTML = '' then
    Exit;
  SaveUndo;
  if FHasSelection then
    DeleteSelection;
  LParser := THTMLParser.Create;
  try
    LInsDoc := LParser.Parse(HTML);
  finally
    LParser.Free;
  end;
  try
    if LInsDoc.Paragraphs.Count = 0 then
      Exit;
    if FCaretPos.ParaIdx >= FDoc.Paragraphs.Count then
      Exit;

    SplitRunAt(FCaretPos.ParaIdx, FCaretPos.RunIdx, FCaretPos.CharIdx);
    LCurPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
    LOrigParaIdx := FCaretPos.ParaIdx;

    if FCaretPos.RunIdx >= LCurPara.Runs.Count then
      LMoveFrom := LCurPara.Runs.Count
    else if FCaretPos.CharIdx = 0 then
      LMoveFrom := FCaretPos.RunIdx
    else
      LMoveFrom := FCaretPos.RunIdx + 1;

    if LInsDoc.Paragraphs.Count = 1 then
    begin
      LSrcPara := LInsDoc.Paragraphs[0];
      LInsertAt := LMoveFrom;
      for var LRI := 0 to LSrcPara.Runs.Count - 1 do
        LCurPara.Runs.Insert(LInsertAt + LRI, LSrcPara.Runs[LRI].Clone);

      LLastRI := LInsertAt + LSrcPara.Runs.Count - 1;
      LTargSeg := 0;
      LTargOfs := 0;
      if LLastRI >= 0 then
      begin
        for var I := 0 to LLastRI - 1 do
          if LCurPara.Runs[I].IsLineBreak then
          begin
            Inc(LTargSeg);
            LTargOfs := 0;
          end
          else
            Inc(LTargOfs, LCurPara.Runs[I].Text.Length);
        if not LCurPara.Runs[LLastRI].IsLineBreak then
          Inc(LTargOfs, LCurPara.Runs[LLastRI].Text.Length);
      end;

      NormalizeRuns(LOrigParaIdx);

      LCurSeg := 0;
      LAcc := 0;
      FCaretPos.RunIdx := 0;
      FCaretPos.CharIdx := 0;
      LLI4 := 0;
      LFound4 := False;
      while (LLI4 < LCurPara.Runs.Count) and not LFound4 do
      begin
        if LCurPara.Runs[LLI4].IsLineBreak then
        begin
          if LCurSeg = LTargSeg then
            LFound4 := True
          else
          begin
            Inc(LCurSeg);
            LAcc := 0;
          end;
        end
        else if LCurSeg = LTargSeg then
        begin
          if LTargOfs <= LAcc + LCurPara.Runs[LLI4].Text.Length then
          begin
            FCaretPos.RunIdx := LLI4;
            FCaretPos.CharIdx := LTargOfs - LAcc;
            LFound4 := True;
          end
          else
          begin
            Inc(LAcc, LCurPara.Runs[LLI4].Text.Length);
            FCaretPos.RunIdx := LLI4;
            FCaretPos.CharIdx := LCurPara.Runs[LLI4].Text.Length;
          end;
        end;
        Inc(LLI4);
      end;
    end
    else
    begin
      LTailPara := THTMLParagraph.Create;
      LLastSrc := LInsDoc.Paragraphs[LInsDoc.Paragraphs.Count - 1];
      LTailPara.BlockType := LLastSrc.BlockType;
      LTailPara.Alignment := LLastSrc.Alignment;
      LTailPara.IndentLevel := LLastSrc.IndentLevel;
      LTailPara.ListOrdered := LLastSrc.ListOrdered;
      while LMoveFrom < LCurPara.Runs.Count do
      begin
        LRun := LCurPara.Runs[LMoveFrom];
        LCurPara.Runs.Extract(LRun);
        LTailPara.Runs.Add(LRun);
      end;

      LSrcPara := LInsDoc.Paragraphs[0];
      LCurPara.BlockType := LSrcPara.BlockType;
      LCurPara.Alignment := LSrcPara.Alignment;
      LCurPara.IndentLevel := LSrcPara.IndentLevel;
      LCurPara.ListOrdered := LSrcPara.ListOrdered;
      for var LRI := 0 to LSrcPara.Runs.Count - 1 do
        LCurPara.Runs.Add(LSrcPara.Runs[LRI].Clone);

      NormalizeRuns(LOrigParaIdx);

      LInsertAt := LOrigParaIdx + 1;
      for var LPI := 1 to LInsDoc.Paragraphs.Count - 2 do
      begin
        FDoc.Paragraphs.Insert(LInsertAt, LInsDoc.Paragraphs[LPI].Clone);
        Inc(LInsertAt);
      end;

      LSrcPara := LInsDoc.Paragraphs[LInsDoc.Paragraphs.Count - 1];
      for var LRI := LSrcPara.Runs.Count - 1 downto 0 do
        LTailPara.Runs.Insert(0, LSrcPara.Runs[LRI].Clone);

      FDoc.Paragraphs.Insert(LInsertAt, LTailPara);
      NormalizeRuns(LInsertAt);
      FCaretPos := TDocPos.At(LInsertAt, 0, 0);
    end;

    FHasSelection := False;
    FSelStart := TDocPos.Invalid;
    FSelEnd := TDocPos.Invalid;
    ScanForPlaceholders(FDoc);
    RebuildPlaceholderList;
  finally
    LInsDoc.Free;
  end;
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

// -- Editing commands ----------------------------------------------------------

procedure THTMLEditor.SelectAll;
begin
  FHasSelection := True;
  FSelStart := DocStart;
  FSelEnd := DocEnd;
  FCaretPos := DocEnd;
  UpdateCaretXY;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.Undo;
var
  Entry: TUndoEntry;
  RedoEntry: TUndoEntry;
begin
  if FUndoStack.Count = 0 then
    Exit;
  Entry := FUndoStack.Last;
  FUndoStack.Extract(Entry);
  // Save current to redo
  RedoEntry := TUndoEntry.Create(FDoc.Clone, FCaretPos, FSelStart, FSelEnd);
  FRedoStack.Add(RedoEntry);
  // Restore
  FDoc.Free;
  FDoc := Entry.Doc;
  Entry.Doc := nil; // prevent double-free
  FCaretPos := Entry.CaretPos;
  FSelStart := Entry.SelStart;
  FSelEnd := Entry.SelEnd;
  FHasSelection := FSelStart.IsValid and not FSelStart.Equals(FSelEnd);
  Entry.Free;
  RebuildPlaceholderList;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.Redo;
var
  Entry: TUndoEntry;
  UndoEntry: TUndoEntry;
begin
  if FRedoStack.Count = 0 then
    Exit;
  Entry := FRedoStack.Last;
  FRedoStack.Extract(Entry);
  UndoEntry := TUndoEntry.Create(FDoc.Clone, FCaretPos, FSelStart, FSelEnd);
  FUndoStack.Add(UndoEntry);
  FDoc.Free;
  FDoc := Entry.Doc;
  Entry.Doc := nil;
  FCaretPos := Entry.CaretPos;
  FSelStart := Entry.SelStart;
  FSelEnd := Entry.SelEnd;
  FHasSelection := FSelStart.IsValid and not FSelStart.Equals(FSelEnd);
  Entry.Free;
  RebuildPlaceholderList;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

procedure THTMLEditor.Cut;
begin
  if not FHasSelection then
    Exit;
  Copy;
  SaveUndo;
  DeleteSelection;
end;

procedure THTMLEditor.Copy;
begin
  if not FHasSelection then
    Exit;
  THTMLClipboard.SetHTML(GetSelectionHTML, GetSelectionText);
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

procedure THTMLEditor.Paste;
var
  LSvc: IFMXClipboardService;
  LValue: TValue;
  LText: string;
  LFragment: string;
  LDataURI: string;
  LBitmap: TBitmap;
begin
  if FReadOnly then
    Exit;
  // HTML clipboard (preserves formatting; handles SaveUndo+DeleteSelection via InsertHTML)
  if THTMLClipboard.GetHTML(LFragment) then
  begin
    InsertHTML(LFragment);
    Exit;
  end;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LSvc) then
    Exit;
  LValue := LSvc.GetClipboard;
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

procedure THTMLEditor.PasteAsPlainText;
var
  LSvc: IFMXClipboardService;
  LValue: TValue;
  LText: string;
begin
  if FReadOnly then
    Exit;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LSvc) then
    Exit;
  LValue := LSvc.GetClipboard;
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

function THTMLEditor.GetCurrentAlignment: THTMLAlignment;
begin
  if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) then
    Result := FDoc.Paragraphs[FCaretPos.ParaIdx].Alignment
  else
    Result := haLeft;
end;

function THTMLEditor.GetCurrentParagraphFormat: TParagraphFormat;
var
  LBT: THTMLBlockType;
begin
  if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) then
    LBT := FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType
  else
    LBT := btParagraph;
  case LBT of
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

function THTMLEditor.GetCurrentIsOrderedList: Boolean;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LFirst, LLast: Integer;
  LIndent: Integer;
begin
  Result := False;
  if not FCaretPos.IsValid then
    Exit;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    Result := True;
    for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
      if (FDoc.Paragraphs[I].BlockType <> btLI) or not FDoc.Paragraphs[I].ListOrdered then
        Result := False;
  end
  else
  begin
    if (FCaretPos.ParaIdx >= FDoc.Paragraphs.Count) or
       (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType <> btLI) then
      Exit;
    LIndent := FDoc.Paragraphs[FCaretPos.ParaIdx].IndentLevel;
    GetListBlockRange(LFirst, LLast);
    Result := True;
    for var I := LFirst to LLast do
      if (FDoc.Paragraphs[I].IndentLevel = LIndent) and
         ((FDoc.Paragraphs[I].BlockType <> btLI) or not FDoc.Paragraphs[I].ListOrdered) then
        Result := False;
  end;
end;

function THTMLEditor.GetCurrentIsUnorderedList: Boolean;
var
  LSelectionStart, LSelectionEnd: TDocPos;
  LFirst, LLast: Integer;
  LIndent: Integer;
begin
  Result := False;
  if not FCaretPos.IsValid then
    Exit;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    Result := True;
    for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
      if (FDoc.Paragraphs[I].BlockType <> btLI) or FDoc.Paragraphs[I].ListOrdered then
        Result := False;
  end
  else
  begin
    if (FCaretPos.ParaIdx >= FDoc.Paragraphs.Count) or
       (FDoc.Paragraphs[FCaretPos.ParaIdx].BlockType <> btLI) then
      Exit;
    LIndent := FDoc.Paragraphs[FCaretPos.ParaIdx].IndentLevel;
    GetListBlockRange(LFirst, LLast);
    Result := True;
    for var I := LFirst to LLast do
      if (FDoc.Paragraphs[I].IndentLevel = LIndent) and
         ((FDoc.Paragraphs[I].BlockType <> btLI) or FDoc.Paragraphs[I].ListOrdered) then
        Result := False;
  end;
end;

function THTMLEditor.GetState: TEditorState;
var
  LTextStyle: THTMLTextStyle;
  LSelectionStart, LSelectionEnd: TDocPos;
  LImageRun: THTMLRun;
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
  Result.ImageSrc := '';
  Result.ImageWidth := 0;
  Result.ImageHeight := 0;
  Result.ImageAlt := '';
  if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) and
     (FCaretPos.RunIdx >= 0) and
     (FCaretPos.RunIdx < FDoc.Paragraphs[FCaretPos.ParaIdx].Runs.Count) then
  begin
    LImageRun := FDoc.Paragraphs[FCaretPos.ParaIdx].Runs[FCaretPos.RunIdx];
    if LImageRun.IsImage then
    begin
      Result.IsImage := True;
      Result.ImageSrc := LImageRun.ImageSrc;
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
  if FCaretPos.IsValid and (FCaretPos.ParaIdx < FDoc.Paragraphs.Count) then
    Result.IndentLevel := FDoc.Paragraphs[FCaretPos.ParaIdx].IndentLevel
  else
    Result.IndentLevel := 0;
  Result.CanOutdent := False;
  Result.LineNumber := 0;
  Result.ColumnNumber := 0;
  if FCaretPos.IsValid then
  begin
    if FHasSelection then
    begin
      GetSelectionRange(LSelectionStart, LSelectionEnd);
      for var I := LSelectionStart.ParaIdx to Min(LSelectionEnd.ParaIdx, FDoc.Paragraphs.Count - 1) do
        if FDoc.Paragraphs[I].IndentLevel > 0 then
        begin
          Result.CanOutdent := True;
          Break;
        end;
    end
    else if FCaretPos.ParaIdx < FDoc.Paragraphs.Count then
      Result.CanOutdent := FDoc.Paragraphs[FCaretPos.ParaIdx].IndentLevel > 0;

    var LCurPara: THTMLParagraph;
    if FCaretPos.ParaIdx < FDoc.Paragraphs.Count then
      LCurPara := FDoc.Paragraphs[FCaretPos.ParaIdx]
    else
      LCurPara := nil;
    Result.IsInTable := Assigned(LCurPara) and (LCurPara.BlockType = btTableCell);
    if Result.IsInTable then
    begin
      Result.TableRow := LCurPara.TableRow;
      Result.TableCol := LCurPara.TableCol;
    end
    else
    begin
      Result.TableRow := -1;
      Result.TableCol := -1;
    end;

    var LLineIdx: Integer;
    var LColumnOffset: Integer;
    var LFoundInLine: Boolean;
    LFoundInLine := False;
    for LLineIdx := 0 to High(FLines) do
    begin
      if FLines[LLineIdx].ParaIdx <> FCaretPos.ParaIdx then
        Continue;
      LColumnOffset := 0;
      LFoundInLine := False;
      for var LFragIdx := FLines[LLineIdx].FragStart to FLines[LLineIdx].FragStart + FLines[LLineIdx].FragCount - 1 do
      begin
        if (LFragIdx < 0) or (LFragIdx >= Length(FFrags)) then
          Continue;
        if FFrags[LFragIdx].RunIdx < FCaretPos.RunIdx then
        begin
          if not FFrags[LFragIdx].IsImage and not FFrags[LFragIdx].IsPlaceholder then
            Inc(LColumnOffset, FFrags[LFragIdx].CharEnd - FFrags[LFragIdx].CharStart);
        end
        else if FFrags[LFragIdx].RunIdx = FCaretPos.RunIdx then
        begin
          if FCaretPos.CharIdx >= FFrags[LFragIdx].CharStart then
          begin
            Inc(LColumnOffset, FCaretPos.CharIdx - FFrags[LFragIdx].CharStart);
            LFoundInLine := True;
          end;
        end;
      end;
      if LFoundInLine then
      begin
        Result.LineNumber := LLineIdx + 1;
        Result.ColumnNumber := LColumnOffset + 1;
        Break;
      end;
    end;
  end;
end;

// -- Undo helpers --------------------------------------------------------------

procedure THTMLEditor.SaveUndo;
begin
  if FUndoStack.Count >= C_EDITOR_UNDO_LEVELS then
    FUndoStack.Delete(0);
  FUndoStack.Add(TUndoEntry.Create(FDoc.Clone, FCaretPos, FSelStart, FSelEnd));
  ClearRedo;
end;

procedure THTMLEditor.ClearRedo;
begin
  FRedoStack.Clear;
end;

// -- Placeholder support -------------------------------------------------------

procedure THTMLEditor.AppearanceChanged(Sender: TObject);
begin
  DoLayout;
  InvalidateRender;
end;

procedure THTMLEditor.SetPlaceholderPrefix(const V: string);
begin
  if FPlaceholderPrefix = V then
    Exit;
  FPlaceholderPrefix := V;
end;

procedure THTMLEditor.SetPlaceholderSuffix(const V: string);
begin
  if FPlaceholderSuffix = V then
    Exit;
  FPlaceholderSuffix := V;
end;

function THTMLEditor.GetPlaceholderLabel(const RawText: string): string;
begin
  Result := RawText;
  if Assigned(FOnGetPlaceholderLabel) then
    FOnGetPlaceholderLabel(Self, RawText, Result);
end;

procedure THTMLEditor.ScanForPlaceholders(Doc: THTMLDocument);
var
  LPara: THTMLParagraph;
  I: Integer;
  LRun: THTMLRun;
  LText: string;
  LPStart: Integer;
  LPSEnd: Integer;
  LSaveStyle: THTMLTextStyle;
  LSaveBorderColor: TAlphaColor;
  LInsIdx: Integer;
  LBeforeText: string;
  LPhText: string;
  LAfterText: string;
  LSplitRun: THTMLRun;
  LPhRun: THTMLRun;
begin
  if (FPlaceholderPrefix = '') or (FPlaceholderSuffix = '') then
    Exit;
  for LPara in Doc.Paragraphs do
  begin
    I := 0;
    while I < LPara.Runs.Count do
    begin
      LRun := LPara.Runs[I];
      if LRun.IsLineBreak or LRun.IsPlaceholder then
      begin
        Inc(I);
      end
      else
      begin
        LText := LRun.Text;
        LPStart := LText.IndexOf(FPlaceholderPrefix);
        if LPStart < 0 then
        begin
          Inc(I);
        end
        else
        begin
          LPSEnd := LText.IndexOf(FPlaceholderSuffix, LPStart + FPlaceholderPrefix.Length);
          if LPSEnd < 0 then
          begin
            Inc(I);
          end
          else
          begin
            LPSEnd := LPSEnd + FPlaceholderSuffix.Length;
            LSaveStyle := LRun.Style;
            LSaveBorderColor := LRun.PlaceholderBorderColor;
            LBeforeText := LText.Substring(0, LPStart);
            LPhText := LText.Substring(LPStart, LPSEnd - LPStart);
            LAfterText := LText.Substring(LPSEnd);
            LPara.Runs.Delete(I);
            LInsIdx := I;
            if LBeforeText <> '' then
            begin
              LSplitRun := THTMLRun.Create;
              LSplitRun.Style := LSaveStyle;
              LSplitRun.Text := LBeforeText;
              LPara.Runs.Insert(LInsIdx, LSplitRun);
              Inc(LInsIdx);
            end;
            LPhRun := THTMLRun.Create;
            LPhRun.Style := LSaveStyle;
            LPhRun.PlaceholderBorderColor := LSaveBorderColor;
            LPhRun.Text := LPhText;
            LPhRun.IsPlaceholder := True;
            LPara.Runs.Insert(LInsIdx, LPhRun);
            Inc(LInsIdx);
            if LAfterText <> '' then
            begin
              LSplitRun := THTMLRun.Create;
              LSplitRun.Style := LSaveStyle;
              LSplitRun.Text := LAfterText;
              LPara.Runs.Insert(LInsIdx, LSplitRun);
            end;
            I := LInsIdx;
          end;
        end;
      end;
    end;
  end;
end;

procedure THTMLEditor.RebuildPlaceholderList;
var
  LParagraph: THTMLParagraph;
  LRun: THTMLRun;
begin
  FPlaceholders.Clear;
  for LParagraph in FDoc.Paragraphs do
    for LRun in LParagraph.Runs do
      if LRun.IsPlaceholder then
        FPlaceholders.Add(LRun);
end;

procedure THTMLEditor.InsertPlaceholder(const RawText: string; const ADisplayName: string = '');
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LTextStyle: THTMLTextStyle;
  LInsertIdx: Integer;
begin
  if not FCaretPos.IsValid then
    Exit;
  if (FPlaceholderPrefix = '') or (FPlaceholderSuffix = '') then
    Exit;
  SaveUndo;
  if FHasSelection then
    DeleteSelection;
  EnsureValidDocument;
  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  LTextStyle := StyleAtCaret;
  SplitRunAt(FCaretPos.ParaIdx, FCaretPos.RunIdx, FCaretPos.CharIdx);
  LInsertIdx := FCaretPos.RunIdx;
  if (LPara.Runs.Count > 0) and (FCaretPos.CharIdx > 0) then
    Inc(LInsertIdx);
  LRun := THTMLRun.Create;
  LRun.Style := LTextStyle;
  LRun.Text := FPlaceholderPrefix + RawText + FPlaceholderSuffix;
  LRun.DisplayText := ADisplayName;
  LRun.IsPlaceholder := True;
  LPara.Runs.Insert(LInsertIdx, LRun);
  FPlaceholders.Add(LRun);
  FCaretPos := TDocPos.At(FCaretPos.ParaIdx, LInsertIdx, LRun.Text.Length);
  NormalizeRuns(FCaretPos.ParaIdx);
  DoLayout;
  DoChanged;
  DoNotifyState;
  InvalidateRender;
end;

function THTMLEditor.GetCurrentRun: THTMLRun;
var
  LPara: THTMLParagraph;
  LRun: THTMLRun;
  LPrevRun: THTMLRun;
  LRunIdx: Integer;
  LSelectionStart, LSelectionEnd: TDocPos;
begin
  Result := nil;
  if FHasSelection then
  begin
    GetSelectionRange(LSelectionStart, LSelectionEnd);
    if (LSelectionStart.ParaIdx <> LSelectionEnd.ParaIdx) or (LSelectionStart.RunIdx <> LSelectionEnd.RunIdx) then
      Exit;
    if LSelectionStart.ParaIdx >= FDoc.Paragraphs.Count then
      Exit;
    LPara := FDoc.Paragraphs[LSelectionStart.ParaIdx];
    if (LSelectionStart.RunIdx >= 0) and (LSelectionStart.RunIdx < LPara.Runs.Count) then
      Result := LPara.Runs[LSelectionStart.RunIdx];
    Exit;
  end;
  if not FCaretPos.IsValid or (FCaretPos.ParaIdx >= FDoc.Paragraphs.Count) then
    Exit;
  LPara := FDoc.Paragraphs[FCaretPos.ParaIdx];
  LRunIdx := FCaretPos.RunIdx;
  if (LRunIdx < 0) or (LRunIdx >= LPara.Runs.Count) then
    Exit;
  LRun := LPara.Runs[LRunIdx];
  // Atomic runs: always return the atom regardless of CharIdx
  if LRun.IsPlaceholder or LRun.IsImage then
  begin
    Result := LRun;
    Exit;
  end;
  // Trailing edge: at CharIdx=0 prefer the run to the left
  if (FCaretPos.CharIdx = 0) and (LRunIdx > 0) then
  begin
    LPrevRun := LPara.Runs[LRunIdx - 1];
    if not LPrevRun.IsLineBreak then
    begin
      Result := LPrevRun;
      Exit;
    end;
  end;
  // Return the current run if it is not a line break
  if not LRun.IsLineBreak then
    Result := LRun;
end;

procedure THTMLEditor.UpdatePlaceholder(const ANewRawText: string; const ANewDisplayName: string = '');
var
  LRun: THTMLRun;
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

procedure THTMLEditor.ScanDocumentMeta(const AHTML: string; out ATitle, ALang: string);
var
  LLower: string;
  LHtmlTagEnd: Integer;
  LAttrs: string;
  LLangPos: Integer;
  LLangEnd: Integer;
  LTitleStart: Integer;
  LTitleEnd: Integer;
begin
  ATitle := '';
  ALang := '';
  LLower := AHTML.ToLower;
  // lang attribute from <html ...>
  LHtmlTagEnd := LLower.IndexOf('<html');
  if LHtmlTagEnd >= 0 then
  begin
    LHtmlTagEnd := LLower.IndexOf('>', LHtmlTagEnd);
    if LHtmlTagEnd >= 0 then
    begin
      LAttrs := LLower.Substring(0, LHtmlTagEnd);
      LLangPos := LAttrs.IndexOf('lang="');
      if LLangPos >= 0 then
      begin
        Inc(LLangPos, 6);
        LLangEnd := LAttrs.IndexOf('"', LLangPos);
        if LLangEnd > LLangPos then
          ALang := AHTML.Substring(LLangPos, LLangEnd - LLangPos);
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

procedure THTMLEditor.SetFullHTML(const V: string);
var
  LLower: string;
  LBodyOpen: Integer;
  LBodyTagEnd: Integer;
  LBodyClose: Integer;
  LFragment: string;
  LTitle: string;
  LLang: string;
begin
  ScanDocumentMeta(V, LTitle, LLang);
  FTitle := LTitle;
  FLang := LLang;
  LLower := V.ToLower;
  LBodyOpen := LLower.IndexOf('<body');
  if LBodyOpen >= 0 then
  begin
    LBodyTagEnd := LLower.IndexOf('>', LBodyOpen);
    if LBodyTagEnd >= 0 then
    begin
      LBodyClose := LLower.IndexOf('</body>', LBodyTagEnd);
      if LBodyClose >= 0 then
        LFragment := V.Substring(LBodyTagEnd + 1, LBodyClose - LBodyTagEnd - 1).Trim
      else
        LFragment := V.Substring(LBodyTagEnd + 1).Trim;
    end
    else
      LFragment := '';
  end
  else
    LFragment := V;
  SetHTML(LFragment);
end;

function THTMLEditor.GetFullHTML: string;
var
  LStringBuilder: TStringBuilder;
  LLangAttr: string;
  LBodyContent: string;
begin
  if FLang <> '' then
    LLangAttr := ' lang="' + FLang + '"'
  else
    LLangAttr := '';
  LBodyContent := GetHTML;
  LStringBuilder := TStringBuilder.Create;
  try
    LStringBuilder.Append('<!DOCTYPE html>').Append(sLineBreak);
    LStringBuilder.Append('<html' + LLangAttr + '>').Append(sLineBreak);
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

function THTMLEditor.GetHTML: string;
var
  LGen: THTMLGenerator;
  LPlaceholderStyle: TPlaceholderGenStyle;
begin
  if (FDoc.Paragraphs.Count = 1) and FDoc.Paragraphs[0].IsEmpty and
    (FDoc.Paragraphs[0].BlockType in [btParagraph, btBodyText]) and
    (FDoc.Paragraphs[0].IndentLevel = 0) and (FDoc.Paragraphs[0].Alignment = haLeft) then
    Exit('');
  LGen := THTMLGenerator.Create;
  try
    LGen.Pretty := FPrettyHTML;
    LPlaceholderStyle.Init;
    LPlaceholderStyle.FillColor := FPlaceholderAppearance.FillColor;
    LPlaceholderStyle.TextColor := FPlaceholderAppearance.TextColor;
    LPlaceholderStyle.BorderColor := FPlaceholderAppearance.BorderColor;
    LPlaceholderStyle.BorderRadius := FPlaceholderAppearance.BorderRadius;
    LPlaceholderStyle.HorizontalPadding := FPlaceholderAppearance.HorizontalPadding;
    LPlaceholderStyle.VerticalPadding := FPlaceholderAppearance.VerticalPadding;
    LPlaceholderStyle.Bold := FPlaceholderAppearance.Bold;
    LGen.PlaceholderStyle := LPlaceholderStyle;
    Result := LGen.Generate(FDoc);
  finally
    LGen.Free;
  end;
end;

procedure THTMLEditor.SetHTML(const V: string);
var
  LParser: THTMLParser;
  LNewDoc: THTMLDocument;
  LParagraph: THTMLParagraph;
begin
  FUndoStack.Clear;
  FRedoStack.Clear;
  FImageCache.Clear;
  LParser := THTMLParser.Create;
  try
    LNewDoc := LParser.Parse(V);
    if LNewDoc.Paragraphs.Count = 0 then
    begin
      LParagraph := THTMLParagraph.Create;
      LParagraph.BlockType := btParagraph;
      LNewDoc.Paragraphs.Add(LParagraph);
    end;
    ScanForPlaceholders(LNewDoc);
    FDoc.Free;
    FDoc := LNewDoc;
    RebuildPlaceholderList;
  finally
    LParser.Free;
  end;
  PreloadImages;
  FCaretPos := DocStart;
  ClearSelection;
  FScrollY := 0;
  FInsertStyleSet := False;
  FLayoutEngine.ClearMeasureCache;
  DoLayout;
  InvalidateRender;
  DoNotifyState;
end;

// -- Misc ----------------------------------------------------------------------

function THTMLEditor.EnsureValidDocument: Boolean;
var
  LParagraph: THTMLParagraph;
begin
  if FDoc.Paragraphs.Count = 0 then
  begin
    LParagraph := THTMLParagraph.Create;
    LParagraph.BlockType := btParagraph;
    FDoc.Paragraphs.Add(LParagraph);
    FCaretPos := TDocPos.At(0, 0, 0);
  end;
  Result := True;
end;

procedure THTMLEditor.DoChanged;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
  TBindings.Notify(Self, 'HTML');
end;

procedure THTMLEditor.DoNotifyState;
begin
  if Assigned(FOnStateChange) then
    FOnStateChange(Self, GetState);
end;

procedure THTMLEditor.SetLineSpacing(const V: Single);
begin
  if FLineSpacing = V then
    Exit;
  FLineSpacing := V;
  DoLayout;
  InvalidateRender;
end;

procedure THTMLEditor.SetParagraphSpacing(const V: Single);
begin
  if FParagraphSpacing = V then
    Exit;
  FParagraphSpacing := V;
  DoLayout;
  InvalidateRender;
end;

procedure THTMLEditor.SetReadOnly(const V: Boolean);
begin
  FReadOnly := V;
end;

procedure THTMLEditor.SetBackgroundColor(const V: TAlphaColor);
begin
  FBackgroundColor := V;
  InvalidateRender;
end;

procedure THTMLEditor.SetFontColor(const V: TAlphaColor);
begin
  FFontColor := V;
  InvalidateRender;
end;

procedure THTMLEditor.SetFont(const V: TFont);
begin
  FFont.Assign(V);
  // FontChanged fires automatically via FFont.OnChanged
end;

procedure THTMLEditor.FontChanged(Sender: TObject);
begin
  // Keep FInsertStyle in sync so that new text typed into an empty/default
  // document reflects the font chosen in the Object Inspector.
  FInsertStyle.FontName := FFont.Family;
  FInsertStyle.FontSize := FFont.Size;
  FInsertStyleSet := False;
end;

end.
