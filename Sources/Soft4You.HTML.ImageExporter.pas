unit Soft4You.HTML.ImageExporter;

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
  System.Generics.Collections;

type

  // Maps an image source of the document to the file it is read from
  TS4YImagePathResolver = reference to function(const ASource: string): string;

  // Tells whether an image source may be copied
  TS4YImageSourceFilter = reference to function(const ASource: string): Boolean;

  // ===========================================================================
  // TS4YImageExporter
  // Copies the local images of a document into a subfolder next to the saved file
  // ===========================================================================

  TS4YImageExporter = class
  private
    FDestinationFolder: string;
    FFolderName: string;
    FIsAllowed: TS4YImageSourceFilter;
    FResolver: TS4YImagePathResolver;
    FCopiedPaths: TDictionary<string, string>;
    FDestinations: TDictionary<string, string>;
    FSources: TDictionary<string, string>;
    FUsedNames: TDictionary<string, string>;
    function AreFilesEqual(const AFirstFile, ASecondFile: string): Boolean;
    function CopyToDestination(const ASourceFile: string): string;
  public
    constructor Create(const ADestinationFolder, AFolderName: string; const AResolver: TS4YImagePathResolver;
      const AIsAllowed: TS4YImageSourceFilter);
    destructor Destroy; override;

    // True when the source is a local image that exists: ANewSource is then the
    // source to write in the saved document (relative to the destination folder)
    function TryConvert(const ASource: string; out ANewSource: string): Boolean;

    // Original source -> full path of its copy
    property Destinations: TDictionary<string, string> read FDestinations;
  end;

implementation

uses
  System.IOUtils,
  Soft4You.HTML.Types;

// -----------------------------------------------------------------------------
// TS4YImageExporter
// -----------------------------------------------------------------------------

constructor TS4YImageExporter.Create(const ADestinationFolder, AFolderName: string; const AResolver: TS4YImagePathResolver;
  const AIsAllowed: TS4YImageSourceFilter);
begin
  inherited Create;
  FIsAllowed := AIsAllowed;
  FDestinationFolder := ADestinationFolder;
  FFolderName := AFolderName;
  FResolver := AResolver;
  FCopiedPaths := TDictionary<string, string>.Create;
  FDestinations := TDictionary<string, string>.Create;
  FSources := TDictionary<string, string>.Create;
  FUsedNames := TDictionary<string, string>.Create;
end;

destructor TS4YImageExporter.Destroy;
begin
  FUsedNames.Free;
  FSources.Free;
  FDestinations.Free;
  FCopiedPaths.Free;
  inherited Destroy;
end;

function TS4YImageExporter.AreFilesEqual(const AFirstFile, ASecondFile: string): Boolean;
var
  LFirstBytes: TBytes;
  LSecondBytes: TBytes;
begin
  LFirstBytes := TFile.ReadAllBytes(AFirstFile);
  LSecondBytes := TFile.ReadAllBytes(ASecondFile);
  Result := (Length(LFirstBytes) = Length(LSecondBytes)) and
    ((Length(LFirstBytes) = 0) or CompareMem(@LFirstBytes[0], @LSecondBytes[0], Length(LFirstBytes)));
end;

// Copies the file into the images folder and returns the full path of the copy.
// A different file with the same name is never overwritten: the copy gets a
// numeric suffix (logo_2.png); an identical file already there is reused
function TS4YImageExporter.CopyToDestination(const ASourceFile: string): string;
var
  LImagesFolder: string;
  LBaseName: string;
  LExtension: string;
  LName: string;
  LCounter: Integer;
  LIsDone: Boolean;
begin
  LImagesFolder := TPath.Combine(FDestinationFolder, FFolderName);
  LBaseName := TPath.GetFileNameWithoutExtension(ASourceFile);
  LExtension := TPath.GetExtension(ASourceFile);
  LCounter := 1;
  LIsDone := False;
  Result := '';
  while not LIsDone do
  begin
    if LCounter = 1 then
      LName := LBaseName + LExtension
    else
      LName := LBaseName + '_' + IntToStr(LCounter) + LExtension;
    Inc(LCounter);
    if not FUsedNames.ContainsKey(LName.ToLower) then
    begin
      Result := TPath.Combine(LImagesFolder, LName);
      if not TFile.Exists(Result) then
      begin
        TDirectory.CreateDirectory(LImagesFolder);
        TFile.Copy(ASourceFile, Result, False);
        LIsDone := True;
      end
      else
      begin
        LIsDone := SameText(TPath.GetFullPath(ASourceFile), TPath.GetFullPath(Result)) or
          AreFilesEqual(ASourceFile, Result);
      end;
      if LIsDone then
        FUsedNames.Add(LName.ToLower, ASourceFile);
    end;
  end;
end;

function TS4YImageExporter.TryConvert(const ASource: string; out ANewSource: string): Boolean;
var
  LSourceFile: string;
  LKey: string;
  LCopyPath: string;
begin
  ANewSource := ASource;
  Result := False;
  if FSources.TryGetValue(ASource, ANewSource) then
    Exit(True);
  ANewSource := ASource;
  if not IsLocalImageSource(ASource) then
    Exit;
  if Assigned(FIsAllowed) and not FIsAllowed(ASource) then
    Exit;
  LSourceFile := TPath.GetFullPath(FResolver(ASource));
  if not TFile.Exists(LSourceFile) then
    Exit;
  LKey := LSourceFile.ToLower;
  if not FCopiedPaths.TryGetValue(LKey, LCopyPath) then
  begin
    LCopyPath := CopyToDestination(LSourceFile);
    FCopiedPaths.Add(LKey, LCopyPath);
  end;
  ANewSource := FFolderName + '/' + TPath.GetFileName(LCopyPath);
  FSources.Add(ASource, ANewSource);
  FDestinations.Add(ASource, LCopyPath);
  Result := True;
end;

end.
