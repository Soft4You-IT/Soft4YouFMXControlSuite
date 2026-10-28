# TS4YColorSelector for FireMonkey

Two overlapping color swatches, like in the drawing programs: the foreground color at the top left and the background color at the bottom right. A click on a swatch tells the application which color the user wants to change; the application shows its own color picker and sets the new color.

Units: `Soft4You.FMX.Controls.ColorSelector` and `Soft4You.FMX.Controls.ColorSelector.Types` (in `Sources\ColorSelector`).

## Installation

`TS4YColorSelector` is part of the Soft4You FMX Control Suite. It is built into the runtime package `Soft4You.FMX.Controls.Suite`, and its registration into the design-time package `SuiteD`: see the README in the root of the repository. It appears in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\ColorSelector` to the Delphi library path to compile your own projects with the units.

## Files

| File | Content |
|---|---|
| `Sources\ColorSelector\Soft4You.FMX.Controls.ColorSelector.pas` | The control |
| `Sources\ColorSelector\Soft4You.FMX.Controls.ColorSelector.Types.pas` | The types of the event: `TS4YColorTarget` and `TS4YColorSelectEvent` |
| `Sources\ColorSelector\Soft4You.FMX.Controls.ColorSelector.Register.pas` | Registration in the Tool Palette (design time) |
| `Graphics\ColorSelector\TS4YColorSelector.svg` | Vector master of the icon of the Tool Palette |
| `Graphics\ColorSelector\TS4YColorSelector.bmp`, `ColorSelectorDesign.rc` | Icon of the Tool Palette (24x24 bitmap) and the resource script that links it |

## Properties and event

| Member | Default | Meaning |
|---|---|---|
| `ForegroundColor` | white | Color of the swatch at the top left |
| `BackgroundColor` | black | Color of the swatch at the bottom right |
| `OnColorSelect` | | Fired when the user clicks a swatch: `ATarget` is `ctForeground` or `ctBackground`, `ACurrentColor` the color of that swatch |

Each swatch takes 72% of the width and of the height of the area inside the `Padding`, so the two overlap in the middle and follow the size of the control (64x48 when it is created). `Align`, `Anchors`, `Margins`, `Opacity`, `Padding`, `Position`, `Size` and `Visible` are published too.

The selector does not choose a color by itself: without a handler of `OnColorSelect` a click does nothing.

## Example

The handler opens a popup with a `TColorPanel`; the panel changes the color that was clicked:

```delphi
uses
  FMX.Colors,
  Soft4You.FMX.Controls.ColorSelector,
  Soft4You.FMX.Controls.ColorSelector.Types;

procedure TMainForm.ColorSelectorColorSelect(Sender: TObject; ATarget: TS4YColorTarget; ACurrentColor: TAlphaColor);
begin
  FColorTarget := ATarget;
  ColorPanel.Color := ACurrentColor;
  ColorPopup.IsOpen := True;
end;

procedure TMainForm.ColorPanelChange(Sender: TObject);
begin
  if FColorTarget = ctForeground then
  begin
    ColorSelector.ForegroundColor := ColorPanel.Color;
  end
  else
  begin
    ColorSelector.BackgroundColor := ColorPanel.Color;
  end;
end;
```

## Upgrading from the private library

The control comes from an earlier library of Soft4You, where the types of the event were `TColorTarget` and `TOnColorSelect`, declared in the unit of the control. In the suite they are `TS4YColorTarget` and `TS4YColorSelectEvent`, in `Soft4You.FMX.Controls.ColorSelector.Types`: in an existing form add that unit to the `uses` and change `TColorTarget` to `TS4YColorTarget` in the handlers of `OnColorSelect`. The values `ctForeground` and `ctBackground` and the names of the properties did not change.
