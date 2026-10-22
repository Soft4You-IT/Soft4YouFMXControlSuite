unit Soft4You.FMX.Controls.HTMLEditor.SVGRenderer.Skia;

{ *****************************************************************************
  S4YFMXHTMLEditor - WYSIWYG HTML editor for Delphi FireMonkey (FMX)
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{ *******************************************************************************
  Optional SVG renderer for TS4YHTMLEditor based on Skia4Delphi.
  The editor does not depend on Skia4Delphi: add this unit to the uses clause of the
  project to register the renderer in TS4YHTMLEditor.DefaultSVGRenderer, or assign
  TS4YSkiaSVGRenderer.RenderSVG to the OnRenderSVG event of a single editor.
  ******************************************************************************* }

interface

uses
  FMX.Graphics;

type
  /// <summary>
  /// Renders SVG images to bitmaps with Skia4Delphi.
  /// </summary>
  TS4YSkiaSVGRenderer = class
  public
    /// <summary>
    /// Renders the SVG text to a new bitmap; the caller owns it.
    /// </summary>
    /// <param name="ASVGText">The SVG document.</param>
    /// <param name="AWidth">The width in pixels; 0 or less means the intrinsic width.</param>
    /// <param name="AHeight">The height in pixels; 0 or less means the intrinsic height.</param>
    /// <returns>The bitmap, or nil when the SVG cannot be rendered.</returns>
    class function Render(const ASVGText: string; AWidth, AHeight: Integer): TBitmap;
    /// <summary>
    /// Handler for TS4YHTMLEditor.OnRenderSVG.
    /// </summary>
    class procedure RenderSVG(Sender: TObject; const ASVGText: string; AWidth, AHeight: Integer;
      var ABitmap: TBitmap);
  end;

implementation

uses
  System.SysUtils,
  System.Types,
  Skia,
  Skia.FMX,
  Soft4You.FMX.Controls.HTMLEditor;

const
  C_DEFAULT_SVG_WIDTH = 300;
  C_DEFAULT_SVG_HEIGHT = 150;

class function TS4YSkiaSVGRenderer.Render(const ASVGText: string; AWidth, AHeight: Integer): TBitmap;
var
  LSVGDOM: ISkSVGDOM;
  LIntrinsicSize: TSizeF;
  LWidth: Integer;
  LHeight: Integer;
begin
  Result := nil;
  LSVGDOM := TSkSVGDOM.Make(ASVGText);

  if not Assigned(LSVGDOM) then
    Exit;

  LWidth := AWidth;
  LHeight := AHeight;

  if (LWidth <= 0) or (LHeight <= 0) then
  begin
    if Assigned(LSVGDOM.Root) then
      LIntrinsicSize := LSVGDOM.Root.GetIntrinsicSize(TSizeF.Create(0, 0))
    else
      LIntrinsicSize := TSizeF.Create(0, 0);

    if LWidth <= 0 then
      LWidth := Round(LIntrinsicSize.Width);

    if LHeight <= 0 then
      LHeight := Round(LIntrinsicSize.Height);

    if LWidth <= 0 then
      LWidth := C_DEFAULT_SVG_WIDTH;

    if LHeight <= 0 then
      LHeight := C_DEFAULT_SVG_HEIGHT;
  end;

  Result := TBitmap.Create(LWidth, LHeight);
  try
    Result.SkiaDraw(
      procedure(const ACanvas: ISkCanvas)
      begin
        LSVGDOM.SetContainerSize(TSizeF.Create(LWidth, LHeight));
        LSVGDOM.Render(ACanvas);
      end
    );
  except
    FreeAndNil(Result);
  end;
end;

class procedure TS4YSkiaSVGRenderer.RenderSVG(Sender: TObject; const ASVGText: string;
  AWidth, AHeight: Integer; var ABitmap: TBitmap);
begin
  ABitmap := Render(ASVGText, AWidth, AHeight);
end;

initialization
  TS4YHTMLEditor.DefaultSVGRenderer :=
    function(const ASVGText: string; AWidth, AHeight: Integer): TBitmap
    begin
      Result := TS4YSkiaSVGRenderer.Render(ASVGText, AWidth, AHeight);
    end;

end.
