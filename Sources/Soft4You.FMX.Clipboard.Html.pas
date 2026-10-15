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
  LHMem:   HGLOBAL;
  LPointer:    Pointer;
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
      LPointer := GlobalLock(LHMem);
      if LPointer <> nil then
      begin
        Move(LData[Low(LData)], LPointer^, Length(LData));
        PByte(PByte(LPointer) + NativeUInt(Length(LData)))^ := 0;
        GlobalUnlock(LHMem);
        SetClipboardData(LCFHtml, LHMem);
      end;
    end;
    // CF_UNICODETEXT (plain text fallback for apps that don't read CF_HTML)
    LHMem := GlobalAlloc(GMEM_MOVEABLE, NativeUInt(Length(APlainText) + 1) * SizeOf(WideChar));
    if LHMem <> 0 then
    begin
      LPointer := GlobalLock(LHMem);
      if LPointer <> nil then
      begin
        if Length(APlainText) > 0 then
          Move(APlainText[Low(APlainText)], LPointer^, Length(APlainText) * SizeOf(WideChar));
        PWideChar(PWideChar(LPointer) + Length(APlainText))^ := #0;
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
    LHMem := GetClipboardData(LCFHtml);
    if LHMem = 0 then
      Exit;
    LPointer := GlobalLock(LHMem);
    if LPointer = nil then
      Exit;
    try
      LSize := GlobalSize(LHMem);
      SetLength(LRaw, LSize);
      Move(LPointer^, LRaw[Low(LRaw)], LSize);
    finally
      GlobalUnlock(LHMem);
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
