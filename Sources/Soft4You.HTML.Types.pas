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

  // How a relative local image path is resolved:
  //   ipmApplication - as the operating system does (relative to the current directory)
  //   ipmDocument    - relative to the folder of the document (DocumentPath)
  TS4YImagePathMode = (ipmApplication, ipmDocument);

  // Which local files an image source may point to:
  //   liaAnywhere       - any file the process can read
  //   liaDocumentFolder - only files inside DocumentPath or its subfolders (relative
  //                       segments, file: URLs and network paths are checked on the resolved path)
  TS4YLocalImageAccess = (liaAnywhere, liaDocumentFolder);

  // Options of TS4YHTMLEditor.SaveToFile (call Init first, then set what differs)
  //   CopyImages       - copy the local images next to the saved file and point the saved
  //                      HTML to the copies (ignored when AutoLoadLocalImages is False)
  //   ImagesFolderName - subfolder of the copies; empty = '<file name>_files'
  //   UpdateModel      - after saving, the document itself also points to the copies
  TS4YSaveOptions = record
    CopyImages: Boolean;
    ImagesFolderName: string;
    UpdateModel: Boolean;
    procedure Init;
  end;

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

// Image source paths
function FileUrlToPath(const AUrl: string): string;
function IsRelativeLocalPath(const ASource: string): Boolean;
function IsRemoteImageSource(const ASource: string): Boolean;
function IsLocalImageSource(const ASource: string): Boolean;
function ResolveImagePath(const ASource, ADocumentPath: string; AMode: TS4YImagePathMode): string;
function MakeDocumentRelativePath(const ASource, ADocumentPath: string): string;
function IsPathInsideFolder(const APath, AFolder: string): Boolean;
function PathToFileUrl(const APath: string): string;
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

end.
