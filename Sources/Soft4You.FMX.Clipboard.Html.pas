unit Soft4You.FMX.Clipboard.Html;

{ *****************************************************************************
  S4YFMXHTMLEditor - WYSIWYG HTML editor for Delphi FireMonkey (FMX)
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{ *******************************************************************************
  TS4YHTMLClipboard  -  platform-aware HTML clipboard read/write
  Windows  : CF_HTML (UTF-8 with byte-offset header) + CF_UNICODETEXT fallback
  Other    : IFMXClipboardService with HTML fragment as plain text
             (round-trip within the editor via LooksLikeHTML detection)
  TODO MACOS   : NSPasteboard with public.html UTI
  TODO IOS     : UIPasteboard with public.html UTI
  TODO ANDROID : ClipboardManager with text/html MIME type
  ******************************************************************************* }

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.RTTI,
  FMX.Platform;

/// <summary>
/// Tells whether a text looks like an HTML fragment.
/// </summary>
/// <param name="AText">Text to check.</param>
/// <returns>True when the text contains an angle-bracket tag.</returns>
function LooksLikeHTML(const AText: string): Boolean;

type
  /// <summary>Reads and writes HTML on the system clipboard.</summary>
  TS4YHTMLClipboard = class
  public
    /// <summary>
    /// Puts an HTML fragment on the clipboard.
    /// </summary>
    /// <param name="AFragment">HTML fragment.</param>
    /// <param name="APlainText">Plain text version, for the applications that do not read HTML.</param>
    /// <remarks>
    /// On Windows both formats are written (HTML Format and Unicode text). On the other platforms only AFragment is written.
    /// </remarks>
    class procedure SetHTML(const AFragment, APlainText: string);
    /// <summary>
    /// Reads an HTML fragment from the clipboard.
    /// </summary>
    /// <param name="AFragment">HTML fragment found on the clipboard; empty when there is none.</param>
    /// <returns>True when a fragment was found.</returns>
    /// <remarks>
    /// On Windows the HTML Format is read. On the other platforms the clipboard text is returned when it looks like HTML.
    /// </remarks>
    class function GetHTML(out AFragment: string): Boolean;
    /// <summary>
    /// Tells whether the clipboard holds an image.
    /// </summary>
    /// <returns>True when an image is available.</returns>
    class function HasImage: Boolean;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  System.Character;

// -----------------------------------------------------------------------------

function LooksLikeHTML(const AText: string): Boolean;
begin
  Result := False;

  for var LIndex := 1 to AText.Length - 1 do
    if (AText[LIndex] = '<') and (AText[LIndex + 1].IsLetter or (AText[LIndex + 1] = '/') or (AText[LIndex + 1] = '!')) then
      Exit(True);
end;

// -----------------------------------------------------------------------------
// TS4YHTMLClipboard
// -----------------------------------------------------------------------------

{$IFDEF MSWINDOWS}

function BuildCFHTML(const AFragment: string): RawByteString;
const
  C_HEADER =
    'Version:0.9'#13#10 +
    'StartHTML:%09d'#13#10 +
    'EndHTML:%09d'#13#10 +
    'StartFragment:%09d'#13#10 +
    'EndFragment:%09d'#13#10;
  S_HTML_PRE  = '<html><body>'#13#10'<!--StartFragment-->';
  S_HTML_POST = '<!--EndFragment-->'#13#10'</body></html>';
var
  LHeaderLength: Integer;
  LPreBytes:  RawByteString;
  LFragmentBytes: RawByteString;
  LPostBytes: RawByteString;
  LStartHTML: Integer;
  LStartFragment: Integer;
  LEndFragment:   Integer;
  LEndHTML:   Integer;
begin
  LHeaderLength := Length(RawByteString(Format(C_HEADER, [0, 0, 0, 0])));
  LPreBytes  := UTF8Encode(S_HTML_PRE);
  LFragmentBytes := UTF8Encode(AFragment);
  LPostBytes := UTF8Encode(S_HTML_POST);
  LStartHTML := LHeaderLength;
  LStartFragment := LStartHTML + Length(LPreBytes);
  LEndFragment   := LStartFragment + Length(LFragmentBytes);
  LEndHTML   := LEndFragment   + Length(LPostBytes);
  Result :=
    RawByteString(Format(C_HEADER, [LStartHTML, LEndHTML, LStartFragment, LEndFragment])) +
    LPreBytes + LFragmentBytes + LPostBytes;
end;

class procedure TS4YHTMLClipboard.SetHTML(const AFragment, APlainText: string);
var
  LCFHtml: UINT;
  LData:   RawByteString;
  LGlobalMemory:   HGLOBAL;
  LPointer:    Pointer;
begin
  LCFHtml := RegisterClipboardFormat('HTML Format');

  if not OpenClipboard(0) then
    Exit;

  try
    EmptyClipboard;
    // CF_HTML (UTF-8 with byte-offset header)
    LData := BuildCFHTML(AFragment);
    LGlobalMemory := GlobalAlloc(GMEM_MOVEABLE, NativeUInt(Length(LData)) + 1);

    if LGlobalMemory <> 0 then
    begin
      LPointer := GlobalLock(LGlobalMemory);

      if LPointer <> nil then
      begin
        Move(LData[Low(LData)], LPointer^, Length(LData));
        PByte(PByte(LPointer) + NativeUInt(Length(LData)))^ := 0;
        GlobalUnlock(LGlobalMemory);
        SetClipboardData(LCFHtml, LGlobalMemory);
      end;
    end;

    // CF_UNICODETEXT (plain text fallback for apps that don't read CF_HTML)
    LGlobalMemory := GlobalAlloc(GMEM_MOVEABLE, NativeUInt(Length(APlainText) + 1) * SizeOf(WideChar));

    if LGlobalMemory <> 0 then
    begin
      LPointer := GlobalLock(LGlobalMemory);

      if LPointer <> nil then
      begin
        if Length(APlainText) > 0 then
          Move(APlainText[Low(APlainText)], LPointer^, Length(APlainText) * SizeOf(WideChar));

        PWideChar(PWideChar(LPointer) + Length(APlainText))^ := #0;
        GlobalUnlock(LGlobalMemory);
        SetClipboardData(CF_UNICODETEXT, LGlobalMemory);
      end;
    end;
  finally
    CloseClipboard;
  end;
end;

class function TS4YHTMLClipboard.GetHTML(out AFragment: string): Boolean;
var
  LCFHtml:    UINT;
  LGlobalMemory:      HGLOBAL;
  LPointer:       Pointer;
  LSize:      NativeUInt;
  LRaw:       RawByteString;
  LFull:      string;
  LLower:     string;
  LStartFragment: Integer;
  LEndFragment:   Integer;
begin
  Result   := False;
  AFragment := '';
  LCFHtml  := RegisterClipboardFormat('HTML Format');

  if not IsClipboardFormatAvailable(LCFHtml) then
    Exit;

  if not OpenClipboard(0) then
    Exit;

  try
    LGlobalMemory := GetClipboardData(LCFHtml);

    if LGlobalMemory = 0 then
      Exit;

    LPointer := GlobalLock(LGlobalMemory);

    if LPointer = nil then
      Exit;

    try
      LSize := GlobalSize(LGlobalMemory);
      SetLength(LRaw, LSize);
      Move(LPointer^, LRaw[Low(LRaw)], LSize);
    finally
      GlobalUnlock(LGlobalMemory);
    end;
  finally
    CloseClipboard;
  end;

  LFull      := UTF8ToString(LRaw);
  LLower     := LFull.ToLower;
  LStartFragment := LLower.IndexOf('<!--startfragment-->');
  LEndFragment   := LLower.IndexOf('<!--endfragment-->');

  if (LStartFragment >= 0) and (LEndFragment > LStartFragment) then
  begin
    Inc(LStartFragment, Length('<!--startfragment-->'));
    AFragment := LFull.Substring(LStartFragment, LEndFragment - LStartFragment).Trim;
    Result := AFragment <> '';
  end;
end;

class function TS4YHTMLClipboard.HasImage: Boolean;
begin
  Result := IsClipboardFormatAvailable(CF_DIB);
end;

{$ELSE}

// -- Non-Windows fallback ------------------------------------------------------

class procedure TS4YHTMLClipboard.SetHTML(const AFragment, APlainText: string);
var
  LClipboardService: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboardService) then
    LClipboardService.SetClipboard(AFragment);
end;

class function TS4YHTMLClipboard.GetHTML(out AFragment: string): Boolean;
var
  LClipboardService: IFMXClipboardService;
  LV:   TValue;
  LS:   string;
begin
  Result    := False;
  AFragment := '';

  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboardService) then
    Exit;

  LV := LClipboardService.GetClipboard;

  if LV.IsEmpty then
    Exit;

  LS := LV.ToString;

  if LooksLikeHTML(LS) then
  begin
    AFragment := LS;
    Result    := True;
  end;
end;

class function TS4YHTMLClipboard.HasImage: Boolean;
var
  LClipboardService: IFMXClipboardService;
  LValue: TValue;
begin
  Result := False;

  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LClipboardService) then
    Exit;

  LValue := LClipboardService.GetClipboard;
  Result := not LValue.IsEmpty and not LValue.IsType<string>;
end;

{$ENDIF MSWINDOWS}

end.
