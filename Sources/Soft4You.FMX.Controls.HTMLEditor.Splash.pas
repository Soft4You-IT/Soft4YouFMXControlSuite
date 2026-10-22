unit Soft4You.FMX.Controls.HTMLEditor.Splash;

{ *****************************************************************************
  S4YFMXHTMLEditor - WYSIWYG HTML editor for Delphi FireMonkey (FMX)
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{ Design-time only: shows the package in the IDE splash screen and in the
  About box. The bitmaps (24x24, lower-left pixel = transparent color) are
  linked from S4YFMXHTMLEditorD.dcr. }

interface

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  ToolsAPI;

const
  C_SPLASH_BITMAP_NAME = 'S4YSPLASH';
  C_ABOUT_BITMAP_NAME = 'S4YABOUT';
  S_PLUGIN_TITLE = 'S4YFMXHTMLEditor';
  S_PLUGIN_DESCRIPTION = 'WYSIWYG HTML editor for Delphi FireMonkey (FMX). ' +
    'Copyright Soft4You 2026.';
  S_LICENSE_STATUS = 'MPL 2.0';

var
  AboutPluginIndex: Integer = -1;

function LoadPluginBitmap(const AResourceName: string): HBITMAP;
begin
  Result := LoadBitmap(FindResourceHInstance(HInstance), PChar(AResourceName));
end;

procedure RegisterSplashScreen;
var
  LBitmap: HBITMAP;
begin
  if SplashScreenServices = nil then
  begin
    Exit;
  end;

  LBitmap := LoadPluginBitmap(C_SPLASH_BITMAP_NAME);

  if LBitmap <> 0 then
  begin
    SplashScreenServices.AddPluginBitmap(S_PLUGIN_TITLE, LBitmap, False, S_LICENSE_STATUS);
  end;
end;

procedure RegisterAboutBox;
var
  LAboutBoxServices: IOTAAboutBoxServices;
  LBitmap: HBITMAP;
begin
  if not Supports(BorlandIDEServices, IOTAAboutBoxServices, LAboutBoxServices) then
  begin
    Exit;
  end;

  LBitmap := LoadPluginBitmap(C_ABOUT_BITMAP_NAME);

  if LBitmap <> 0 then
  begin
    AboutPluginIndex := LAboutBoxServices.AddPluginInfo(S_PLUGIN_TITLE,
      S_PLUGIN_DESCRIPTION, LBitmap, False, S_LICENSE_STATUS);
  end;
end;

procedure UnregisterAboutBox;
var
  LAboutBoxServices: IOTAAboutBoxServices;
begin
  if (AboutPluginIndex >= 0) and
    Supports(BorlandIDEServices, IOTAAboutBoxServices, LAboutBoxServices) then
  begin
    LAboutBoxServices.RemovePluginInfo(AboutPluginIndex);
  end;

  AboutPluginIndex := -1;
end;

initialization
  RegisterSplashScreen;
  RegisterAboutBox;

finalization
  UnregisterAboutBox;

end.
