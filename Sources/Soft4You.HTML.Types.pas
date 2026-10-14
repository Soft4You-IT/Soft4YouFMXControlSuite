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

  THTMLAlignment = (haLeft, haCenter, haRight, haJustify);

  THTMLBlockType = (btParagraph, btH1, btH2, btH3, btH4, btH5, btH6,
    btBlockquote, btUL, btOL, btLI, btHR, btImage, btTableCell, btBodyText, btPre);

  TParagraphFormat = (pfBodyText, pfParagraph, pfH1, pfH2, pfH3, pfH4, pfH5, pfH6, pfPre);

  // ===========================================================================
  // Text style
  // ===========================================================================

  THTMLTextStyle = record
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
    function EqualsFormat(const O: THTMLTextStyle): Boolean;
  end;

  // ===========================================================================
  // Placeholder generation style (passed from THTMLEditor to THTMLGenerator)
  // ===========================================================================

  TPlaceholderGenStyle = record
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

  TDocPos = record
    ParaIdx: Integer; // -1 = invalid
    RunIdx: Integer;
    CharIdx: Integer; // 0 = before first char of run
    class function Invalid: TDocPos; static; inline;
    class function At(P, R, C: Integer): TDocPos; static; inline;
    function IsValid: Boolean; inline;
    function Equals(const O: TDocPos): Boolean; inline;
  end;

  // ===========================================================================
  // Layout types  (produced by TLayoutEngine)
  // ===========================================================================

  TLayoutFrag = record
    ParaIdx: Integer;
    RunIdx: Integer;
    CharStart: Integer; // inclusive, within Run.Text
    CharEnd: Integer;   // exclusive
    X, Y: Single;
    W, H: Single;
    Ascent: Single;    // distance from top of line-box to baseline
    LineIdx: Integer;
    IsSpace: Boolean;        // trailing space that can be omitted at EOL
    IsHR: Boolean;
    IsImage: Boolean;
    IsPlaceholder: Boolean;  // mirrors Run.IsPlaceholder; drives chip rendering
  end;

  TLayoutLine = record
    Y: Single;
    H: Single;      // line-box height
    Ascent: Single; // max ascent in line
    ParaIdx: Integer;
    IsFirst: Boolean;
    IsLast: Boolean;
    FragStart: Integer; // index into FFrags array
    FragCount: Integer;
    // Table cell geometry -- only valid when Para.BlockType = btTableCell
    CellX: Single;    // left edge of this cell
    CellW: Single;    // width of this cell
    CellRowH: Single; // total height of this cell's row (for border rect)
    CellRowY: Single; // top Y of this cell's row (for border rect)
  end;

  // ===========================================================================
  // Font size presets
  // ===========================================================================

  TFontSizePreset = record
    Size: Single;
    Caption: string;
    constructor Create(ASize: Single; const ACaption: string);
  end;

function FontSizePresets: TArray<TFontSizePreset>;

// ===========================================================================
// Helpers
// ===========================================================================

function DarkenColor(C: TAlphaColor; AFactor: Single = 0.65): TAlphaColor;
function TrimS(const S: string): string; inline;
function StartsWithCI(const S, Prefix: string): Boolean; inline;

implementation

// -----------------------------------------------------------------------------
// DarkenColor
// -----------------------------------------------------------------------------

function DarkenColor(C: TAlphaColor; AFactor: Single): TAlphaColor;
var
  LR, LG, LB: Integer;
begin
  LR := Round(TAlphaColorRec(C).R * AFactor);
  LG := Round(TAlphaColorRec(C).G * AFactor);
  LB := Round(TAlphaColorRec(C).B * AFactor);
  if LR > 255 then LR := 255;
  if LG > 255 then LG := 255;
  if LB > 255 then LB := 255;
  Result := TAlphaColor(($FF shl 24) or (LR shl 16) or (LG shl 8) or LB);
end;

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function TrimS(const S: string): string;
begin
  Result := S.Trim;
end;

function StartsWithCI(const S, Prefix: string): Boolean;
begin
  Result := S.ToLower.StartsWith(Prefix.ToLower);
end;

// -----------------------------------------------------------------------------
// TFontSizePreset
// -----------------------------------------------------------------------------

constructor TFontSizePreset.Create(ASize: Single; const ACaption: string);
begin
  Size    := ASize;
  Caption := ACaption;
end;

// -----------------------------------------------------------------------------
// FontSizePresets
// -----------------------------------------------------------------------------

function FontSizePresets: TArray<TFontSizePreset>;
begin
  Result := [
    TFontSizePreset.Create(C_FONT_SIZE_VERY_SMALL, S_FONT_SIZE_VERY_SMALL),
    TFontSizePreset.Create(C_FONT_SIZE_SMALL,       S_FONT_SIZE_SMALL),
    TFontSizePreset.Create(C_FONT_SIZE_MEDIUM,      S_FONT_SIZE_MEDIUM),
    TFontSizePreset.Create(C_FONT_SIZE_LARGE,       S_FONT_SIZE_LARGE),
    TFontSizePreset.Create(C_FONT_SIZE_VERY_LARGE,  S_FONT_SIZE_VERY_LARGE),
    TFontSizePreset.Create(C_FONT_SIZE_HUGE,        S_FONT_SIZE_HUGE)
  ];
end;

// -----------------------------------------------------------------------------
// TPlaceholderGenStyle
// -----------------------------------------------------------------------------

procedure TPlaceholderGenStyle.Init;
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
// THTMLTextStyle
// -----------------------------------------------------------------------------

procedure THTMLTextStyle.Init;
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

function THTMLTextStyle.EqualsFormat(const O: THTMLTextStyle): Boolean;
begin
  Result := (FontName = O.FontName) and (Abs(FontSize - O.FontSize) < 0.01) and
    (Bold = O.Bold) and (Italic = O.Italic) and (Underline = O.Underline) and
    (StrikeOut = O.StrikeOut) and (Superscript = O.Superscript) and
    (Subscript = O.Subscript) and (Color = O.Color) and (BackgroundColor = O.BackgroundColor) and
    (LinkURL = O.LinkURL);
end;

// -----------------------------------------------------------------------------
// TDocPos
// -----------------------------------------------------------------------------

class function TDocPos.Invalid: TDocPos;
begin
  Result.ParaIdx := -1;
  Result.RunIdx := 0;
  Result.CharIdx := 0;
end;

class function TDocPos.At(P, R, C: Integer): TDocPos;
begin
  Result.ParaIdx := P;
  Result.RunIdx := R;
  Result.CharIdx := C;
end;

function TDocPos.IsValid: Boolean;
begin
  Result := ParaIdx >= 0;
end;

function TDocPos.Equals(const O: TDocPos): Boolean;
begin
  Result := (ParaIdx = O.ParaIdx) and (RunIdx = O.RunIdx) and (CharIdx = O.CharIdx);
end;

end.
