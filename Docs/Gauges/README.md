# Gauges for FireMonkey

Indicators of a value in a range, in the modern look: a track that fills with the value, the value written next to it and a caption.

```
Download                    72
━━━━━━━━━━━━━━━━━━━━━━──────────
```

- `TS4YLinearGauge` draws the value as a horizontal or vertical **bar**, with the caption and the value on one side of it.
- `TS4YCircularGauge` draws it as a **ring**, an open arc or a half circle, with the value and the caption in the middle.
- The value goes from `Min` to `Max`; a large change of `Value` moves the fill with an animation, a small one is drawn at once.
- The value is written with a format of its own (`ValueFormat`), or with a text given by the application (`OnGetValueText`).
- Every part of the gauge comes from a **style**: the track, the fill and the fonts of the texts. The track and the fill can have any shape designed in the style; properties can replace the colors of the simple shapes.

Units: `Soft4You.FMX.Controls.Gauges.Linear` for `TS4YLinearGauge` and `Soft4You.FMX.Controls.Gauges.Circular` for `TS4YCircularGauge`, in `Sources\Gauges`; the base class of the gauges is in `Soft4You.FMX.Controls.Gauges`, the types in `Soft4You.FMX.Controls.Gauges.Types`.

## Installation

The gauges are part of the Soft4You FMX Control Suite. They are built into the runtime package `Soft4You.FMX.Controls.Suite`, and their registration into the design-time package `SuiteD`: see the README in the root of the repository. They appear in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\Gauges` to the Delphi library path to compile your own projects with the units, and the folder `Resources`, where the packages compile the default styles.

## Files

| File | Content |
|---|---|
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.pas` | `TS4YCustomGauge`, the base class of the gauges |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Linear.pas` | `TS4YLinearGauge` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Circular.pas` | `TS4YCircularGauge` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Types.pas` | Enumerations, sets and event types |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Register.pas` | Registration in the Tool Palette (design time) |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Linear.Win.rc` / `.Mac.rc` | Resource scripts that link the style of `TS4YLinearGauge` as the resource `S4YLinearGaugeStyle` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Linear.Win.style` / `.Mac.style` | Default style of `TS4YLinearGauge` (the two are identical) |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Circular.Win.rc` / `.Mac.rc` | Resource scripts that link the style of `TS4YCircularGauge` as the resource `S4YCircularGaugeStyle` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Circular.Win.style` / `.Mac.style` | Default style of `TS4YCircularGauge` (the two are identical) |
| `Graphics\Gauges\TS4YLinearGauge.svg`, `TS4YCircularGauge.svg` | Vector masters of the icons of the Tool Palette |
| `Graphics\Gauges\TS4YLinearGauge.bmp`, `TS4YCircularGauge.bmp`, `GaugesDesign.rc` | Icons of the Tool Palette (24x24 bitmaps) and the resource script that links them |

## Properties of all the gauges

| Property | Default | Meaning |
|---|---|---|
| `Value` | 0 | The value shown, from `Min` to `Max`. A value out of the range is brought to `Min` or `Max` |
| `Min` | 0 | The start of the range, where the fill is empty. A `Min` greater than `Max` moves `Max` to it |
| `Max` | 100 | The end of the range, where the fill is full. A `Max` lower than `Min` moves `Min` to it |
| `AnimationDuration` | 0.3 | Seconds the fill takes to reach the new value when `Value` changes by more than 5% of the range; 0 changes it at once (see below) |
| `Caption` | empty | Text that describes the value, for example *Download* or *CPU* |
| `ShowValue` | `True` | Writes the value |
| `ValueFormat` | `%.0f` | Format of the value, as for the `Format` function of Delphi with the value as its only argument (see below) |
| `Thickness` | 8 (linear), 12 (circular) | Thickness of the track and of the fill, in pixels |
| `FillBrush` | blue | Brush of the fill, used in place of the one of the style (see [Styles](#styles)) |
| `TrackBrush` | light gray | Brush of the track, used in place of the one of the style |
| `StyledBrushes` | `[gsbFill, gsbTrack]` | Which brushes come from the style instead of `FillBrush` and `TrackBrush` |

These properties are public in the base class `TS4YCustomGauge`, so that code can work on any gauge through it, for example in a loop or in an `OnGetValueText` shared by several gauges.

The usual `TControl` properties (`Align`, `Anchors`, `Position`, `Size`, `Margins`, `Padding`, `Opacity`, `Visible`, `Enabled`, `HitTest`, `Cursor`, `RotationAngle`, `Scale`, `PopupMenu`, `StyleLookup`) are published too. `Padding` leaves room between the edges of the control and its content.

### Value and animation

A change of `Value` larger than 5% of the range (`Max - Min`) moves the fill to the new value in `AnimationDuration` seconds; a smaller one is drawn at once, so that the fill follows a value that changes often, like the progress of a download. A change while the fill is moving starts from where the fill is, so it never jumps. In the designer the changes are always immediate.

The value written follows the fill: during the animation it counts up or down to the new value.

Setting `Min` or `Max` brings `Value` into the new range at once, without animation. The form file stores `Max`, `Min` and `Value` one at a time: the gauge checks that they are coherent only when the form is loaded.

### Text of the value

`ValueFormat` is passed to `Format` with the value, a floating point number:

| `ValueFormat` | Value 42.4 |
|---|---|
| `%.0f` (default) | `42` |
| `%.1f %%` | `42.4 %` |
| `%.0f GB` | `42 GB` |
| empty | nothing |

A format that does not fit a floating point value, such as `%d`, is replaced by the default. The decimal separator is the one of the system.

`OnGetValueText` fires each time the value is written, with the value drawn in `AValue` and the text formatted with `ValueFormat` in `AText`, which the event can replace:

```delphi
procedure TMainForm.DiskGaugeGetValueText(Sender: TObject; const AValue: Single; var AText: string);
begin
  AText := Format('%.0f of %.0f GB', [AValue, TS4YLinearGauge(Sender).Max]);
end;
```

With `ShowValue = False` the value is not written and the event does not fire.

## TS4YLinearGauge

A horizontal or vertical bar that fills with the value: a horizontal bar fills from the left, a vertical one from the bottom.

| Property | Default | Meaning |
|---|---|---|
| `Orientation` | `Horizontal` | Direction of the bar |
| `TextPosition` | `gtpBefore` | Side of the bar with the caption and the value: `gtpBefore` (above a horizontal bar, on the left of a vertical one), `gtpAfter` (below, on the right) or `gtpNone` (hidden) |

The caption is at the start of the bar, where the fill begins, and the value at its end:

```
TextPosition = gtpBefore             TextPosition = gtpAfter         Vertical, gtpBefore
Download                72           ━━━━━━━━━━━━━━━━━──────            72 ┃
━━━━━━━━━━━━━━━━━━━──────            Download                72            ┃
                                                                           █
                                                                       CPU █
```

The bar takes the whole length of the control inside `Padding`; across it, the bar and the texts are one block in the middle of the control, 4 pixels apart. Texts of different sizes are aligned towards the bar. A new gauge is 200 x 40 pixels, with a bar 8 pixels thick.

## TS4YCircularGauge

A ring or an arc that fills clockwise with the value, with the value and, under it, the caption in the middle.

| Property | Default | Meaning |
|---|---|---|
| `StartAngle` | 0 | Angle where the arc starts and the fill begins, in degrees: 0 is the top of the circle, 90 its right side, -90 its left side |
| `SweepAngle` | 360 | Length of the arc in degrees, clockwise from `StartAngle`, from 0 to 360 |

| Shape | `StartAngle` | `SweepAngle` |
|---|---|---|
| Ring, filled from the top | 0 | 360 |
| Arc open at the bottom, like a speedometer | -135 | 270 |
| Half circle, filled from the left | -90 | 180 |

The arc is as large as the area inside `Padding` allows, keeping the circle round: a half circle fills a control twice as wide as tall, a ring a square one. The value and the caption are centered in the area enclosed by the arc, for example in the upper half of the circle for a half circle. A new gauge is 120 x 120 pixels, with an arc 12 pixels thick.

## Styles

The look of `TS4YLinearGauge` comes from a style named `S4YLinearGaugeStyle`, the look of `TS4YCircularGauge` from a style named `S4YCircularGaugeStyle`. Each style is a container of invisible parts with the same names.

### Style of the linear gauge


| Part (`StyleName`) | In the default style | Use |
|---|---|---|
| `track` | `TRectangle`, light gray, rounded corners | Drawn on the whole bar |
| `fill` | `TRectangle`, blue, rounded corners | Drawn on the part of the bar covered by the value, over the track |
| `valuetext` | `TText`, bold | Font and color of the value |
| `captiontext` | `TText` | Font and color of the caption |

The track and the fill can be **any graphic object**: a `TRectangle` with square or rounded corners, a `TPath`, a `TImage`, or a `TLayout` with several objects inside, for example a bar with a gradient and a glossy line over it. The gauge draws a copy of the part as it is, resized to the bar or to its filled part; the objects inside the part follow their `Align`, `Margins` and `Anchors`. The size of the parts in the style does not matter.

When a part is a shape, `FillBrush` and `TrackBrush` can replace its fill: changing one of them in the Object Inspector or in code removes the matching brush (`gsbFill` or `gsbTrack`) from `StyledBrushes`, and the part takes the brush of the property. Putting the brush back in `StyledBrushes` makes the gauge read it from the style again. A part made of several objects keeps the brushes of its objects.

The style linked into the package is used when no other style defines `S4YLinearGaugeStyle`. To change the look of all the linear gauges of an application:

1. In the style of a `TStyleBook`, add a `TLayout` with `StyleName = 'S4YLinearGaugeStyle'` and, inside it, the parts listed above. The default style, `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Linear.Win.style`, is a text file with all of them and can be used as a model.
2. Change the parts: their colors and fonts, or replace a shape with another object.

A style with another name is used by the gauges whose `StyleLookup` is set to that name; when no style has that name, they use `S4YLinearGaugeStyle` as the others. The style of the parent class of the gauges is never used. A part missing from a style is replaced by a rectangle with the brush of the property, and a missing text by the default font and colors.

### Style of the circular gauge

| Part (`StyleName`) | In the default style | Use |
|---|---|---|
| `track` | `TArc`, light gray border, round ends | Gives the brush and the ends of the whole arc |
| `fill` | `TArc`, blue border, round ends | Gives the brush and the ends of the filled part of the arc |
| `valuetext` | `TText`, bold, size 24 | Font and color of the value |
| `captiontext` | `TText` | Font and color of the caption |

The gauge does not draw a copy of the parts: it draws the arc itself, with `StartAngle`, `SweepAngle` and `Thickness`, and takes from the `TArc` of the style the brush of its border (`Stroke`: color, gradient, dash) and its ends (`Stroke.Cap`: `Round` or `Flat`). The thickness and the angles of the `TArc` in the style do not matter. `FillBrush` and `TrackBrush` replace the color of the border, as for the linear gauge, and keep the ends of the style.

A part that is not a `TArc` gives nothing: the arc is drawn with the brush of the property and flat ends. A missing part is replaced by an arc with the brush of the property and round ends.

To change the look of all the circular gauges, add to a `TStyleBook` a `TLayout` with `StyleName = 'S4YCircularGaugeStyle'`; the default style, `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Circular.Win.style`, can be used as a model.

## Example

The space used on a disk:

```delphi
uses
  Soft4You.FMX.Controls.Gauges.Types,
  Soft4You.FMX.Controls.Gauges.Linear;

procedure TMainForm.ShowDiskSpace(const AUsedGigabytes, ASizeGigabytes: Single);
begin
  DiskGauge.Caption := 'Disk C:';
  DiskGauge.Max := ASizeGigabytes;
  DiskGauge.ValueFormat := '%.0f GB';
  DiskGauge.Value := AUsedGigabytes;

  // Red when the disk is almost full: the fill takes the brush of the property.
  if AUsedGigabytes > ASizeGigabytes * 0.9 then
    DiskGauge.FillBrush.Color := TAlphaColors.Red
  else
    DiskGauge.StyledBrushes := DiskGauge.StyledBrushes + [gsbFill];
end;
```

## Demo

`Demos\Gauges\S4YGaugesDemo.dproj` (also part of the project group `Demos\Soft4You.FMX.Controls.Demos.groupproj`) shows a horizontal and a vertical linear gauge and a circular gauge with the same settings. The panel on the left changes `Value` with a track bar, `Min` and `Max`, the animation (a button sets a random value, to see it), `Caption`, `ShowValue`, `ValueFormat`, a text given by `OnGetValueText`, the fill from the style or from `FillBrush`, `Orientation` of the first gauge, `TextPosition` and `Thickness` of the linear gauges, and the shape, `StartAngle`, `SweepAngle` and `Thickness` of the circular one.

`Demos\Gauges\S4YGaugesGallery.dproj` (also in the project group) shows what the gauges can look like, one example per tab: the default styles; the shapes of the circular gauge; a dashboard whose values are changed by a timer; a fill whose color changes with the level of the value, with the text from `OnGetValueText`; a download in small steps; a row of vertical bars without texts, like an equalizer; the styles of a `TStyleBook` (a gradient, a glossy line over the fill, square corners, flat ends, a dotted track, a gradient arc); and styles for a dark background. The styles are in the style book of the form and can be used as models.

Install the suite packages first.

## Notes

- The gauges stream their `StyledBrushes` after the brushes: a form saved with an explicit `StyledBrushes` keeps it when loaded.
- The gauges are indicators: they do not take the focus and do not change the value with the mouse or the keyboard.
