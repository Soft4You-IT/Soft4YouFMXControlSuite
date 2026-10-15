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

// Returns True when S looks like an HTML fragment (contains an angle-bracket tag).
function LooksLikeHTML(const AText: string): Boolean;

type
  TS4YHTMLClipboard = class
  public
    class procedure SetHTML(const AFragment, APlainText: string);
    class function GetHTML(out AFragment: string): Boolean;
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
  for var LI := 1 to AText.Length - 1 do
    if (AText[LI] = '<') and (AText[LI + 1].IsLetter or (AText[LI + 1] = '/') or (AText[LI + 1] = '!')) then
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
  LHeaderLen: Integer;
  LPreBytes:  RawByteString;
  LFragBytes: RawByteString;
  LPostBytes: RawByteString;
  LStartHTML: Integer;
  LStartFrag: Integer;
  LEndFrag:   Integer;
  LEndHTML:   Integer;
begin
  LHeaderLen := Length(RawByteString(Format(C_HEADER, [0, 0, 0, 0])));
  LPreBytes  := UTF8Encode(S_HTML_PRE);
  LFragBytes := UTF8Encode(AFragment);
  LPostBytes := UTF8Encode(S_HTML_POST);
  LStartHTML := LHeaderLen;
  LStartFrag := LStartHTML + Length(LPreBytes);
  LEndFrag   := LStartFrag + Length(LFragBytes);
  LEndHTML   := LEndFrag   + Length(LPostBytes);
  Result :=
    RawByteString(Format(C_HEADER, [LStartHTML, LEndHTML, LStartFrag, LEndFrag])) +
    LPreBytes + LFragBytes + LPostBytes;
end;

class procedure TS4YHTMLClipboard.SetHTML(const AFragment, APlainText: string);
var
  LCFHtml: UINT;
  LData:   RawByteString;
  LHMem:   HGLOBAL;
  LPtr:    Pointer;
begin
  LCFHtml := RegisterClipboardFormat('HTML Format');
  if not OpenClipboard(0) then
    Exit;
  try
    EmptyClipboard;
    // CF_HTML (UTF-8 with byte-offset header)
    LData := BuildCFHTML(AFragment);
    LHMem := GlobalAlloc(GMEM_MOVEABLE, NativeUInt(Length(LData)) + 1);
    if LHMem <> 0 then
    begin
      LPtr := GlobalLock(LHMem);
      if LPtr <> nil then
      begin
        Move(LData[Low(LData)], LPtr^, Length(LData));
        PByte(PByte(LPtr) + NativeUInt(Length(LData)))^ := 0;
        GlobalUnlock(LHMem);
        SetClipboardData(LCFHtml, LHMem);
      end;
    end;
    // CF_UNICODETEXT (plain text fallback for apps that don't read CF_HTML)
    LHMem := GlobalAlloc(GMEM_MOVEABLE, NativeUInt(Length(APlainText) + 1) * SizeOf(WideChar));
    if LHMem <> 0 then
    begin
      LPtr := GlobalLock(LHMem);
      if LPtr <> nil then
      begin
        if Length(APlainText) > 0 then
          Move(APlainText[Low(APlainText)], LPtr^, Length(APlainText) * SizeOf(WideChar));
        PWideChar(PWideChar(LPtr) + Length(APlainText))^ := #0;
        GlobalUnlock(LHMem);
        SetClipboardData(CF_UNICODETEXT, LHMem);
      end;
    end;
  finally
    CloseClipboard;
  end;
end;

class function TS4YHTMLClipboard.GetHTML(out AFragment: string): Boolean;
var
  LCFHtml:    UINT;
  LHMem:      HGLOBAL;
  LPtr:       Pointer;
  LSize:      NativeUInt;
  LRaw:       RawByteString;
  LFull:      string;
  LLower:     string;
  LStartFrag: Integer;
  LEndFrag:   Integer;
begin
  Result   := False;
  AFragment := '';
  LCFHtml  := RegisterClipboardFormat('HTML Format');
  if not IsClipboardFormatAvailable(LCFHtml) then
    Exit;
  if not OpenClipboard(0) then
    Exit;
  try
    LHMem := GetClipboardData(LCFHtml);
    if LHMem = 0 then
      Exit;
    LPtr := GlobalLock(LHMem);
    if LPtr = nil then
      Exit;
    try
      LSize := GlobalSize(LHMem);
      SetLength(LRaw, LSize);
      Move(LPtr^, LRaw[Low(LRaw)], LSize);
    finally
      GlobalUnlock(LHMem);
    end;
  finally
    CloseClipboard;
  end;
  LFull      := UTF8ToString(LRaw);
  LLower     := LFull.ToLower;
  LStartFrag := LLower.IndexOf('<!--startfragment-->');
  LEndFrag   := LLower.IndexOf('<!--endfragment-->');
  if (LStartFrag >= 0) and (LEndFrag > LStartFrag) then
  begin
    Inc(LStartFrag, Length('<!--startfragment-->'));
    AFragment := LFull.Substring(LStartFrag, LEndFrag - LStartFrag).Trim;
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
  LSvc: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LSvc) then
    LSvc.SetClipboard(AFragment);
end;

class function TS4YHTMLClipboard.GetHTML(out AFragment: string): Boolean;
var
  LSvc: IFMXClipboardService;
  LV:   TValue;
  LS:   string;
begin
  Result    := False;
  AFragment := '';
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LSvc) then
    Exit;
  LV := LSvc.GetClipboard;
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
  LSvc: IFMXClipboardService;
  LValue: TValue;
begin
  Result := False;
  if not TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, LSvc) then
    Exit;
  LValue := LSvc.GetClipboard;
  Result := not LValue.IsEmpty and not LValue.IsType<string>;
end;

{$ENDIF MSWINDOWS}

end.
