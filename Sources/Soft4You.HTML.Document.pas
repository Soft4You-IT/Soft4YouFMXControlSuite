unit Soft4You.HTML.Document;

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
  System.Generics.Collections,
  Soft4You.HTML.Types;

type

  // ===========================================================================
  // TS4YHTMLRun
  // ===========================================================================

  TS4YHTMLRun = class
  private
    FDisplayText: string;
    FImageAlt: string;
    FImageHeight: Integer;
    FImageSrc: string;
    FImageWidth: Integer;
    FIsImage: Boolean;
    FIsLineBreak: Boolean;
    FIsPlaceholder: Boolean;
    FPlaceholderBorderColor: TAlphaColor;
    FStyle: TS4YHTMLTextStyle;
    FText: string;
  public
    constructor Create;

    function Clone: TS4YHTMLRun;

    property DisplayText: string read FDisplayText write FDisplayText;
    property ImageAlt: string read FImageAlt write FImageAlt;
    property ImageHeight: Integer read FImageHeight write FImageHeight;
    property ImageSrc: string read FImageSrc write FImageSrc;
    property ImageWidth: Integer read FImageWidth write FImageWidth;
    property IsImage: Boolean read FIsImage write FIsImage;
    property IsLineBreak: Boolean read FIsLineBreak write FIsLineBreak;
    property IsPlaceholder: Boolean read FIsPlaceholder write FIsPlaceholder;
    property PlaceholderBorderColor: TAlphaColor read FPlaceholderBorderColor write FPlaceholderBorderColor;
    property Style: TS4YHTMLTextStyle read FStyle write FStyle;
    property Text: string read FText write FText;
  end;

  // ===========================================================================
  // TS4YHTMLParagraph
  // ===========================================================================

  TS4YHTMLParagraph = class
  private
    FBlockType: TS4YHTMLBlockType;
    FAlignment: TS4YHTMLAlignment;
    FIndentLevel: Integer;  // 0..N  (blockquote / list nesting)
    FListOrdered: Boolean;  // true = <ol>, used when BlockType = btLI
    FListIndex: Integer;    // 1-based counter for <ol>
    FHRColor: TAlphaColor;  // claNull = use default
    FHRThickness: Single;   // 0 = use default
    FImageSrc: string;
    FImageAlt: string;
    FImageWidth: Integer;   // 0 = natural width from bitmap
    FImageHeight: Integer;  // 0 = natural height from bitmap
    FIsHeader: Boolean;     // <th> -- rendered bold + center
    FTableCol: Integer;     // 0-based column index (btTableCell only)
    FTableCols: Integer;    // total columns in table (btTableCell only)
    FTableID: Integer;      // groups cells of same table; 0 = not a cell
    FTableRow: Integer;     // 0-based row index (btTableCell only)
    FRuns: TObjectList<TS4YHTMLRun>;
  public
    constructor Create;
    destructor Destroy; override;

    function Clone: TS4YHTMLParagraph;
    function PlainText: string;
    function IsEmpty: Boolean;

    property Alignment: TS4YHTMLAlignment read FAlignment write FAlignment;
    property BlockType: TS4YHTMLBlockType read FBlockType write FBlockType;
    property HRColor: TAlphaColor read FHRColor write FHRColor;  // claNull = use default
    property HRThickness: Single read FHRThickness write FHRThickness;   // 0 = use default
    property ImageAlt: string read FImageAlt write FImageAlt;
    property ImageHeight: Integer read FImageHeight write FImageHeight;  // 0 = natural height from bitmap
    property ImageSrc: string read FImageSrc write FImageSrc;
    property ImageWidth: Integer read FImageWidth write FImageWidth;   // 0 = natural width from bitmap
    property IndentLevel: Integer read FIndentLevel write FIndentLevel;  // 0..N  (blockquote / list nesting)
    property IsHeader: Boolean read FIsHeader write FIsHeader;     // <th> -- rendered bold + center
    property ListIndex: Integer read FListIndex write FListIndex;    // 1-based counter for <ol>
    property ListOrdered: Boolean read FListOrdered write FListOrdered;  // true = <ol>, used when BlockType = btLI
    property Runs: TObjectList<TS4YHTMLRun> read FRuns;
    property TableCol: Integer read FTableCol write FTableCol;     // 0-based column index (btTableCell only)
    property TableCols: Integer read FTableCols write FTableCols;    // total columns in table (btTableCell only)
    property TableID: Integer read FTableID write FTableID;      // groups cells of same table; 0 = not a cell
    property TableRow: Integer read FTableRow write FTableRow;     // 0-based row index (btTableCell only)
  end;

  // ===========================================================================
  // TS4YHTMLDocument
  // ===========================================================================

  TS4YHTMLDocument = class
  private
    FParagraphs: TObjectList<TS4YHTMLParagraph>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function Clone: TS4YHTMLDocument;

    property Paragraphs: TObjectList<TS4YHTMLParagraph> read FParagraphs;
  end;

// Returns the next unique table ID (shared counter for parser and editor)
function NextTableID: Integer;

implementation

var
  GTableIDCounter: Integer = 0;

function NextTableID: Integer;
begin
  Inc(GTableIDCounter);
  Result := GTableIDCounter;
end;

// -----------------------------------------------------------------------------
// TS4YHTMLRun
// -----------------------------------------------------------------------------

constructor TS4YHTMLRun.Create;
begin
  inherited;
  FStyle.Init;
end;

function TS4YHTMLRun.Clone: TS4YHTMLRun;
begin
  Result := TS4YHTMLRun.Create;
  Result.DisplayText := DisplayText;
  Result.ImageAlt := ImageAlt;
  Result.ImageHeight := ImageHeight;
  Result.ImageSrc := ImageSrc;
  Result.ImageWidth := ImageWidth;
  Result.IsImage := IsImage;
  Result.IsLineBreak := IsLineBreak;
  Result.IsPlaceholder := IsPlaceholder;
  Result.PlaceholderBorderColor := PlaceholderBorderColor;
  Result.Style := Style;
  Result.Text := Text;
end;

// -----------------------------------------------------------------------------
// TS4YHTMLParagraph
// -----------------------------------------------------------------------------

constructor TS4YHTMLParagraph.Create;
begin
  inherited;
  FRuns := TObjectList<TS4YHTMLRun>.Create(True);
  FBlockType := btBodyText;
end;

destructor TS4YHTMLParagraph.Destroy;
begin
  FRuns.Free;
  inherited;
end;

function TS4YHTMLParagraph.Clone: TS4YHTMLParagraph;
var
  LRun: TS4YHTMLRun;
begin
  Result := TS4YHTMLParagraph.Create;
  Result.BlockType := BlockType;
  Result.Alignment := Alignment;
  Result.IndentLevel := IndentLevel;
  Result.ListOrdered := ListOrdered;
  Result.ListIndex := ListIndex;
  Result.HRColor := HRColor;
  Result.HRThickness := HRThickness;
  Result.ImageSrc := ImageSrc;
  Result.ImageAlt := ImageAlt;
  Result.ImageWidth := ImageWidth;
  Result.ImageHeight := ImageHeight;
  Result.IsHeader := IsHeader;
  Result.TableCol := TableCol;
  Result.TableCols := TableCols;
  Result.TableID := TableID;
  Result.TableRow := TableRow;
  for LRun in Runs do
    Result.Runs.Add(LRun.Clone);
end;

function TS4YHTMLParagraph.PlainText: string;
var
  LRun: TS4YHTMLRun;
begin
  Result := '';
  for LRun in Runs do
  begin
    if LRun.IsLineBreak then
      Result := Result + sLineBreak
    else if LRun.IsImage then
      Result := Result + LRun.ImageAlt
    else
      Result := Result + LRun.Text;
  end;
end;

function TS4YHTMLParagraph.IsEmpty: Boolean;
var
  LRun: TS4YHTMLRun;
begin
  for LRun in Runs do
    if (not LRun.IsLineBreak) and (LRun.Text <> '') then
      Exit(False);
  Result := True;
end;

// -----------------------------------------------------------------------------
// TS4YHTMLDocument
// -----------------------------------------------------------------------------

constructor TS4YHTMLDocument.Create;
begin
  inherited;
  FParagraphs := TObjectList<TS4YHTMLParagraph>.Create(True);
end;

destructor TS4YHTMLDocument.Destroy;
begin
  FParagraphs.Free;
  inherited;
end;

procedure TS4YHTMLDocument.Clear;
begin
  FParagraphs.Clear;
end;

function TS4YHTMLDocument.Clone: TS4YHTMLDocument;
var
  LParagraph: TS4YHTMLParagraph;
begin
  Result := TS4YHTMLDocument.Create;
  for LParagraph in Paragraphs do
    Result.Paragraphs.Add(LParagraph.Clone);
end;

end.
