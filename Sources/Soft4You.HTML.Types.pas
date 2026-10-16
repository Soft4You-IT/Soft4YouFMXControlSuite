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
  System.UITypes,
  System.UIConsts;

const
  S_EDITOR_FONT_NAME = ''; // '' = platform default (Segoe UI / Helvetica / Roboto)
  C_EDITOR_FONT_SIZE = 12.0; // pt

  // Preset font sizes
  C_FONT_SIZE_VERY_SMALL = 8.0;
  C_FONT_SIZE_SMALL      = 10.0;
  C_FONT_SIZE_MEDIUM     = 12.0;
  C_FONT_SIZE_LARGE      = 14.0;
  C_FONT_SIZE_VERY_LARGE = 18.0;
  C_FONT_SIZE_HUGE       = 24.0;

resourcestring
  S_FONT_SIZE_VERY_SMALL = 'Molto piccolo';
  S_FONT_SIZE_SMALL      = 'Piccolo';
  S_FONT_SIZE_MEDIUM     = 'Normale';
  S_FONT_SIZE_LARGE      = 'Grande';
  S_FONT_SIZE_VERY_LARGE = 'Molto grande';
  S_FONT_SIZE_HUGE       = 'Enorme';

// ===========================================================================
// Enumerations
// ===========================================================================

type

  TS4YHTMLAlignment = (haLeft, haCenter, haRight, haJustify);

  TS4YHTMLBlockType = (btParagraph, btH1, btH2, btH3, btH4, btH5, btH6,
    btBlockquote, btUL, btOL, btLI, btHR, btImage, btTableCell, btBodyText, btPre);

  TS4YParagraphFormat = (pfBodyText, pfParagraph, pfH1, pfH2, pfH3, pfH4, pfH5, pfH6, pfPre);

  // ===========================================================================
  // Text style
  // ===========================================================================

  TS4YHTMLTextStyle = record
    FontName: string;
    FontSize: Single; // pt
    Bold: Boolean;
    Italic: Boolean;
    Underline: Boolean;
    StrikeOut: Boolean;
    Superscript: Boolean;
    Subscript: Boolean;
    Color: TAlphaColor;
    BackgroundColor: TAlphaColor; // claNull = transparent
    LinkURL: string;
    procedure Init;
    function EqualsFormat(const AOther: TS4YHTMLTextStyle): Boolean;
  end;

  // ===========================================================================
  // Placeholder generation style (passed from TS4YHTMLEditor to TS4YHTMLGenerator)
  // ===========================================================================

  TS4YPlaceholderGeneratorStyle = record
    FillColor: TAlphaColor;
    TextColor: TAlphaColor;
    BorderColor: TAlphaColor;
    BorderRadius: Single;
    HorizontalPadding: Single;
    VerticalPadding: Single;
    Bold: Boolean;
    procedure Init;
  end;

  // ===========================================================================
  // Caret position  (paragraph / run / char index)
  // ===========================================================================

  TS4YDocumentPosition = record
    ParagraphIndex: Integer; // -1 = invalid
    RunIndex: Integer;
    CharIndex: Integer; // 0 = before first char of run
    class function Invalid: TS4YDocumentPosition; static; inline;
    class function At(AParagraphIndex, ARunIndex, ACharIndex: Integer): TS4YDocumentPosition; static; inline;
    function IsValid: Boolean; inline;
    function Equals(const AOther: TS4YDocumentPosition): Boolean; inline;
  end;

  // ===========================================================================
  // Layout types  (produced by TS4YLayoutEngine)
  // ===========================================================================

  TS4YLayoutFragment = record
    ParagraphIndex: Integer;
    RunIndex: Integer;
    CharStart: Integer; // inclusive, within Run.Text
    CharEnd: Integer;   // exclusive
    X, Y: Single;
    Width, Height: Single;
    Ascent: Single;    // distance from top of line-box to baseline
    LineIndex: Integer;
    IsSpace: Boolean;        // trailing space that can be omitted at EOL
    IsHR: Boolean;
    IsImage: Boolean;
    IsPlaceholder: Boolean;  // mirrors Run.IsPlaceholder; drives chip rendering
  end;

  TS4YLayoutLine = record
    Y: Single;
    Height: Single; // line-box height
    Ascent: Single; // max ascent in line
    ParagraphIndex: Integer;
    IsFirst: Boolean;
    IsLast: Boolean;
    FragmentStart: Integer; // index into FFrags array
    FragmentCount: Integer;
    // Table cell geometry -- only valid when Para.BlockType = btTableCell
    CellX: Single;    // left edge of this cell
    CellWidth: Single;    // width of this cell
    CellRowHeight: Single; // total height of this cell's row (for border rect)
    CellRowY: Single; // top Y of this cell's row (for border rect)
  end;

  // ===========================================================================
  // Font size presets
  // ===========================================================================

  TS4YFontSizePreset = record
    Size: Single;
    Caption: string;
    constructor Create(ASize: Single; const ACaption: string);
  end;

function FontSizePresets: TArray<TS4YFontSizePreset>;

// ===========================================================================
// Helpers
// ===========================================================================

function DarkenColor(AColor: TAlphaColor; AFactor: Single = 0.65): TAlphaColor;
function TrimS(const AText: string): string; inline;
function StartsWithCI(const AText, APrefix: string): Boolean; inline;

implementation

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

end.
