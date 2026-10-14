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
  // THTMLRun
  // ===========================================================================

  THTMLRun = class
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
    FStyle: THTMLTextStyle;
    FText: string;
  public
    constructor Create;

    function Clone: THTMLRun;

    property DisplayText: string read FDisplayText write FDisplayText;
    property ImageAlt: string read FImageAlt write FImageAlt;
    property ImageHeight: Integer read FImageHeight write FImageHeight;
    property ImageSrc: string read FImageSrc write FImageSrc;
    property ImageWidth: Integer read FImageWidth write FImageWidth;
    property IsImage: Boolean read FIsImage write FIsImage;
    property IsLineBreak: Boolean read FIsLineBreak write FIsLineBreak;
    property IsPlaceholder: Boolean read FIsPlaceholder write FIsPlaceholder;
    property PlaceholderBorderColor: TAlphaColor read FPlaceholderBorderColor write FPlaceholderBorderColor;
    property Style: THTMLTextStyle read FStyle write FStyle;
    property Text: string read FText write FText;
  end;

  // ===========================================================================
  // THTMLParagraph
  // ===========================================================================

  THTMLParagraph = class
  private
    FBlockType: THTMLBlockType;
    FAlignment: THTMLAlignment;
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
    FRuns: TObjectList<THTMLRun>;
  public
    constructor Create;
    destructor Destroy; override;

    function Clone: THTMLParagraph;
    function PlainText: string;
    function IsEmpty: Boolean;

    property BlockType: THTMLBlockType read FBlockType write FBlockType;
    property Alignment: THTMLAlignment read FAlignment write FAlignment;
    property IndentLevel: Integer read FIndentLevel write FIndentLevel;  // 0..N  (blockquote / list nesting)
    property ListOrdered: Boolean read FListOrdered write FListOrdered;  // true = <ol>, used when BlockType = btLI
    property ListIndex: Integer read FListIndex write FListIndex;    // 1-based counter for <ol>
    property HRColor: TAlphaColor read FHRColor write FHRColor;  // claNull = use default
    property HRThickness: Single read FHRThickness write FHRThickness;   // 0 = use default
    property ImageSrc: string read FImageSrc write FImageSrc;
    property ImageAlt: string read FImageAlt write FImageAlt;
    property ImageWidth: Integer read FImageWidth write FImageWidth;   // 0 = natural width from bitmap
    property ImageHeight: Integer read FImageHeight write FImageHeight;  // 0 = natural height from bitmap
    property IsHeader: Boolean read FIsHeader write FIsHeader;     // <th> -- rendered bold + center
    property TableCol: Integer read FTableCol write FTableCol;     // 0-based column index (btTableCell only)
    property TableCols: Integer read FTableCols write FTableCols;    // total columns in table (btTableCell only)
    property TableID: Integer read FTableID write FTableId;      // groups cells of same table; 0 = not a cell
    property TableRow: Integer read FTableRow write FTableRow;     // 0-based row index (btTableCell only)
    property Runs: TObjectList<THTMLRun> read FRuns;
  end;

  // ===========================================================================
  // THTMLDocument
  // ===========================================================================

  THTMLDocument = class
  private
    FParagraphs: TObjectList<THTMLParagraph>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function Clone: THTMLDocument;

    property Paragraphs: TObjectList<THTMLParagraph> read FParagraphs;
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
// THTMLRun
// -----------------------------------------------------------------------------

constructor THTMLRun.Create;
begin
  inherited;
  FStyle.Init;
end;

function THTMLRun.Clone: THTMLRun;
begin
  Result := THTMLRun.Create;
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
// THTMLParagraph
// -----------------------------------------------------------------------------

constructor THTMLParagraph.Create;
begin
  inherited;
  FRuns := TObjectList<THTMLRun>.Create(True);
  FBlockType := btBodyText;
end;

destructor THTMLParagraph.Destroy;
begin
  FRuns.Free;
  inherited;
end;

function THTMLParagraph.Clone: THTMLParagraph;
var
  LRun: THTMLRun;
begin
  Result := THTMLParagraph.Create;
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

function THTMLParagraph.PlainText: string;
var
  LRun: THTMLRun;
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

function THTMLParagraph.IsEmpty: Boolean;
var
  LRun: THTMLRun;
begin
  for LRun in Runs do
    if (not LRun.IsLineBreak) and (LRun.Text <> '') then
      Exit(False);
  Result := True;
end;

// -----------------------------------------------------------------------------
// THTMLDocument
// -----------------------------------------------------------------------------

constructor THTMLDocument.Create;
begin
  inherited;
  FParagraphs := TObjectList<THTMLParagraph>.Create(True);
end;

destructor THTMLDocument.Destroy;
begin
  FParagraphs.Free;
  inherited;
end;

procedure THTMLDocument.Clear;
begin
  FParagraphs.Clear;
end;

function THTMLDocument.Clone: THTMLDocument;
var
  LParagraph: THTMLParagraph;
begin
  Result := THTMLDocument.Create;
  for LParagraph in Paragraphs do
    Result.Paragraphs.Add(LParagraph.Clone);
end;

end.
