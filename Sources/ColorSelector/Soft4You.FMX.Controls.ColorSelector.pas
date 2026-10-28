unit Soft4You.FMX.Controls.ColorSelector;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YColorSelector - foreground and background color swatches
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.UITypes,

  FMX.Layouts,
  FMX.Objects,

  Soft4You.FMX.Controls.ColorSelector.Types;

const
  C_DEFAULT_FOREGROUND_COLOR = TAlphaColors.White;
  C_DEFAULT_BACKGROUND_COLOR = TAlphaColors.Black;

type
  /// <summary>
  /// Two overlapping color swatches, the foreground color at the top left and the background color at the bottom
  /// right, like in the drawing programs.
  /// </summary>
  /// <remarks>
  /// A click on a swatch fires OnColorSelect: the application shows a color picker and sets the new color. The
  /// swatches fill the area inside the Padding and follow the size of the control.
  /// </remarks>
  TS4YColorSelector = class(TLayout)
  private
    FBackgroundRectangle: TRectangle;
    FForegroundRectangle: TRectangle;
    FOnColorSelect: TS4YColorSelectEvent;

    function CreateSwatch(const AColor: TAlphaColor): TRectangle;
    procedure SwatchClickHandler(Sender: TObject);
    function GetBackgroundColor: TAlphaColor;
    function GetForegroundColor: TAlphaColor;
    procedure SetBackgroundColor(const Value: TAlphaColor);
    procedure SetForegroundColor(const Value: TAlphaColor);
    procedure UpdateSwatchesLayout;
  protected
    /// <summary>Fires OnColorSelect for the given color.</summary>
    procedure DoColorSelect(const ATarget: TS4YColorTarget; const ACurrentColor: TAlphaColor); virtual;
    procedure PaddingChanged; override;
    procedure Resize; override;
  public
    /// <summary>Creates the selector with white as foreground color and black as background color.</summary>
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    /// <summary>The background color, shown by the swatch at the bottom right.</summary>
    property BackgroundColor: TAlphaColor read GetBackgroundColor write SetBackgroundColor default C_DEFAULT_BACKGROUND_COLOR;
    /// <summary>The foreground color, shown by the swatch at the top left.</summary>
    property ForegroundColor: TAlphaColor read GetForegroundColor write SetForegroundColor default C_DEFAULT_FOREGROUND_COLOR;
    property Margins;
    property Opacity;
    property Position;
    property Size;
    property Visible;
    /// <summary>Fired when the user clicks one of the two swatches.</summary>
    property OnColorSelect: TS4YColorSelectEvent read FOnColorSelect write FOnColorSelect;
  end;

implementation

uses
  System.Types;

const
  C_DEFAULT_WIDTH = 64;
  C_DEFAULT_HEIGHT = 48;
  // Each swatch takes this fraction of the width and of the height of the area inside the Padding
  C_SWATCH_SIZE_RATIO = 0.72;
  C_SWATCH_BORDER_COLOR = TAlphaColor($FF808080);

{ TS4YColorSelector }

constructor TS4YColorSelector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetSize(C_DEFAULT_WIDTH, C_DEFAULT_HEIGHT);
  // The foreground swatch is created last, so it is drawn over the background one
  FBackgroundRectangle := CreateSwatch(C_DEFAULT_BACKGROUND_COLOR);
  FForegroundRectangle := CreateSwatch(C_DEFAULT_FOREGROUND_COLOR);
  UpdateSwatchesLayout;
end;

function TS4YColorSelector.CreateSwatch(const AColor: TAlphaColor): TRectangle;
begin
  Result := TRectangle.Create(Self);
  Result.Parent := Self;
  Result.Stored := False;
  Result.Fill.Color := AColor;
  Result.Stroke.Color := C_SWATCH_BORDER_COLOR;
  Result.HitTest := True;
  Result.OnClick := SwatchClickHandler;
end;

procedure TS4YColorSelector.DoColorSelect(const ATarget: TS4YColorTarget; const ACurrentColor: TAlphaColor);
begin
  if Assigned(FOnColorSelect) then
  begin
    FOnColorSelect(Self, ATarget, ACurrentColor);
  end;
end;

function TS4YColorSelector.GetBackgroundColor: TAlphaColor;
begin
  Result := FBackgroundRectangle.Fill.Color;
end;

function TS4YColorSelector.GetForegroundColor: TAlphaColor;
begin
  Result := FForegroundRectangle.Fill.Color;
end;

procedure TS4YColorSelector.PaddingChanged;
begin
  inherited;
  UpdateSwatchesLayout;
end;

procedure TS4YColorSelector.Resize;
begin
  inherited;
  UpdateSwatchesLayout;
end;

procedure TS4YColorSelector.SetBackgroundColor(const Value: TAlphaColor);
begin
  FBackgroundRectangle.Fill.Color := Value;
end;

procedure TS4YColorSelector.SetForegroundColor(const Value: TAlphaColor);
begin
  FForegroundRectangle.Fill.Color := Value;
end;

procedure TS4YColorSelector.SwatchClickHandler(Sender: TObject);
begin
  if Sender = FForegroundRectangle then
  begin
    DoColorSelect(ctForeground, FForegroundRectangle.Fill.Color);
  end
  else
  begin
    DoColorSelect(ctBackground, FBackgroundRectangle.Fill.Color);
  end;
end;

procedure TS4YColorSelector.UpdateSwatchesLayout;
var
  LAvailableWidth: Single;
  LAvailableHeight: Single;
  LSwatchWidth: Single;
  LSwatchHeight: Single;
begin
  // Resize and PaddingChanged can arrive from the inherited constructor, before the swatches exist
  if not Assigned(FBackgroundRectangle) or not Assigned(FForegroundRectangle) then
  begin
    Exit;
  end;

  LAvailableWidth := Width - Padding.Left - Padding.Right;
  LAvailableHeight := Height - Padding.Top - Padding.Bottom;
  LSwatchWidth := LAvailableWidth * C_SWATCH_SIZE_RATIO;
  LSwatchHeight := LAvailableHeight * C_SWATCH_SIZE_RATIO;
  // Background swatch: bottom right corner of the area inside the Padding
  FBackgroundRectangle.Size.Size := TSizeF.Create(LSwatchWidth, LSwatchHeight);
  FBackgroundRectangle.Position.X := Padding.Left + LAvailableWidth - LSwatchWidth;
  FBackgroundRectangle.Position.Y := Padding.Top + LAvailableHeight - LSwatchHeight;
  // Foreground swatch: top left corner of the area inside the Padding
  FForegroundRectangle.Size.Size := TSizeF.Create(LSwatchWidth, LSwatchHeight);
  FForegroundRectangle.Position.X := Padding.Left;
  FForegroundRectangle.Position.Y := Padding.Top;
end;

end.
