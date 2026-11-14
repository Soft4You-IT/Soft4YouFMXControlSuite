# Gauges for FireMonkey

Indicators of a value in a range, in the modern look: a track that fills with the value, the value written next to it and a caption.

```
Download                    72
━━━━━━━━━━━━━━━━━━━━━━──────────
```

- `TS4YLinearGauge` draws the value as a horizontal or vertical **bar**, with the caption and the value on one side of it.
- `TS4YCircularGauge` draws it as a **ring**, an open arc or a half circle, with the value and the caption in the middle.
- `TS4YLinearMeter` and `TS4YCircularMeter` are the same gauges with a **graduation**: ticks and numbers along the bar, like a ruler or a thermometer, or along the arc, like the dial of an instrument. They can color **ranges** of the scale, such as a green, a yellow and a red zone, and mark a **target** value; the circular meter shows the value with a **needle**, the linear one can add a **pointer** beside the bar.
- The value goes from `Min` to `Max`; a large change of `Value` moves the fill with an animation, a small one is drawn at once.
- The value is written with a format of its own (`ValueFormat`), or with a text given by the application (`OnGetValueText`).
- Every part of the gauge comes from a **style**: the track, the fill and the fonts of the texts. The track and the fill can have any shape designed in the style; properties can replace the colors of the simple shapes.

Units: `Soft4You.FMX.Controls.Gauges.Linear` for `TS4YLinearGauge`, `Soft4You.FMX.Controls.Gauges.Circular` for `TS4YCircularGauge`, `Soft4You.FMX.Controls.Gauges.LinearMeter` for `TS4YLinearMeter` and `Soft4You.FMX.Controls.Gauges.CircularMeter` for `TS4YCircularMeter`, in `Sources\Gauges`; the base class of the gauges is in `Soft4You.FMX.Controls.Gauges`, the graduation, the ranges, the needle and the pointer of the meters in `Soft4You.FMX.Controls.Gauges.Scales`, the types in `Soft4You.FMX.Controls.Gauges.Types`.

## Installation

The gauges are part of the Soft4You FMX Control Suite. They are built into the runtime package `Soft4You.FMX.Controls.Suite`, and their registration into the design-time package `SuiteD`: see the README in the root of the repository. They appear in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\Gauges` to the Delphi library path to compile your own projects with the units, and the folder `Resources`, where the packages compile the default styles.

## Files

| File | Content |
|---|---|
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.pas` | `TS4YCustomGauge`, the base class of the gauges |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Linear.pas` | `TS4YLinearGauge` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Circular.pas` | `TS4YCircularGauge` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.LinearMeter.pas` | `TS4YLinearMeter` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.CircularMeter.pas` | `TS4YCircularMeter` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Scales.pas` | The graduation of the meters (`TS4YMeterGraduation`, `TS4YLinearMeterGraduation`, `TS4YCircularMeterGraduation`) their ranges (`TS4YMeterRange`, `TS4YMeterRanges`), the needle of the circular meter (`TS4YCircularMeterNeedle`) and the pointer of the linear one (`TS4YLinearMeterPointer`) |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Types.pas` | Enumerations, sets and event types |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Register.pas` | Registration in the Tool Palette (design time) |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Linear.Win.rc` / `.Mac.rc` | Resource scripts that link the style of `TS4YLinearGauge` as the resource `S4YLinearGaugeStyle` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Linear.Win.style` / `.Mac.style` | Default style of `TS4YLinearGauge` (the two are identical) |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Circular.Win.rc` / `.Mac.rc` | Resource scripts that link the style of `TS4YCircularGauge` as the resource `S4YCircularGaugeStyle` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.Circular.Win.style` / `.Mac.style` | Default style of `TS4YCircularGauge` (the two are identical) |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.LinearMeter.Win.rc` / `.Mac.rc`, `.Win.style` / `.Mac.style` | Resource scripts and default style of `TS4YLinearMeter`, the resource `S4YLinearMeterStyle` |
| `Sources\Gauges\Soft4You.FMX.Controls.Gauges.CircularMeter.Win.rc` / `.Mac.rc`, `.Win.style` / `.Mac.style` | Resource scripts and default style of `TS4YCircularMeter`, the resource `S4YCircularMeterStyle` |
| `Graphics\Gauges\TS4YLinearGauge.svg`, `TS4YCircularGauge.svg`, `TS4YLinearMeter.svg`, `TS4YCircularMeter.svg` | Vector masters of the icons of the Tool Palette |
| `Graphics\Gauges\TS4YLinearGauge.bmp`, `TS4YCircularGauge.bmp`, `TS4YLinearMeter.bmp`, `TS4YCircularMeter.bmp`, `GaugesDesign.rc` | Icons of the Tool Palette (24x24 bitmaps) and the resource script that links them |

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

A ring or an arc that fills clockwise, or counterclockwise, with the value, with the value and, under it, the caption in the middle.

| Property | Default | Meaning |
|---|---|---|
| `StartAngle` | 0 | Angle where the arc starts and the fill begins, in degrees: 0 is the top of the circle, 90 its right side, -90 its left side |
| `SweepAngle` | 360 | Length of the arc in degrees from `StartAngle`, from 0 to 360 |
| `Reversed` | `False` | The arc goes counterclockwise from `StartAngle` instead of clockwise, and the value grows in that direction |

| Shape | `StartAngle` | `SweepAngle` |
|---|---|---|
| Ring, filled from the top | 0 | 360 |
| Arc open at the bottom, like a speedometer | -135 | 270 |
| Half circle, filled from the left | -90 | 180 |
| Half circle upside down, filled from the left through the bottom | -90 | 180, `Reversed` |
| Half circle on the right, filled from the bottom | 180 | 180, `Reversed` |
| Half circle on the left, filled from the bottom | 180 | 180 |

With the same angles, `Reversed` draws the mirror image of the arc: the half circle from the left over the top becomes the half circle from the left under the bottom. Each arc can so be drawn in both directions, also the half circles on the sides and any part of a circle.

The arc is as large as the area inside `Padding` allows, keeping the circle round: a half circle fills a control twice as wide as tall, a ring a square one. The value and the caption are centered in the area enclosed by the arc, for example in the upper half of the circle for a half circle. A new gauge is 120 x 120 pixels, with an arc 12 pixels thick.

## Meters

`TS4YLinearMeter` and `TS4YCircularMeter` descend from `TS4YLinearGauge` and `TS4YCircularGauge`: they have all their properties, and add a graduation along the track, in the property `Graduation`, colored ranges, a target value, a needle (circular meter) and a pointer (linear meter).

```
     0    20    40    60    80   100
━━━━━━━━━━━━━━━━━━━━━──────────────────
|  '  |  '  |  '  |  '  |  '  |  '  |
```

A new `TS4YCircularMeter` is an arc open at the bottom (`StartAngle` -135, `SweepAngle` 270), 160 x 160 pixels, with a needle and without the fill; a new `TS4YLinearMeter` is horizontal, 240 x 64 pixels, with the fill and without the pointer.

### Graduation

| Property | Default | Meaning |
|---|---|---|
| `Visible` | `True` | Draws the graduation |
| `Position` | `gasInside` (circular), `gbsAfter` (linear) | Side of the track where the graduation is drawn: inside or outside the arc (`gasInside`, `gasOutside`); before the bar, above it or on its left, or after it, below it or on its right (`gbsBefore`, `gbsAfter`) |
| `MajorStep` | 0 | Step between the major ticks, in the units of the value; 0 chooses it from the range: 1, 2, 2.5 or 5 times a power of 10, for about five steps |
| `MinorCount` | 4 | Number of minor ticks between two major ticks; 0 draws only the major ticks |
| `MajorTickLength` | 8 | Length of the major ticks, in pixels |
| `MinorTickLength` | 4 | Length of the minor ticks, in pixels |
| `ShowLabels` | `True` | Writes the number of each major tick |
| `LabelFormat` | `%.0f` | Format of the numbers, as for `Format` with the value as its only argument, for example `%.0f%%` or `%.1f`; a format that does not fit a floating point value is replaced by the default |

The major ticks are on the multiples of the step between `Min` and `Max`: with `Min` = 3 and `Max` = 97 and a step of 20, they are at 20, 40, 60 and 80. `Min` and `Max` have a tick only when they are multiples of the step; to have them both, choose a step that divides the range, for example `MajorStep` = 40 with `Max` = 240. A step too small for the range is made larger, so that no more than 1000 ticks are drawn.

The meter keeps room for the graduation: outside the arc, the arc becomes smaller; beside the bar, the bar, the graduation and the texts stay one block in the middle of the control. Inside the arc, the graduation takes room from the value and the caption in the middle: on a small meter, a smaller font for the value in the style, or `ShowLabels` = `False`, leaves them more room. On a whole ring (`SweepAngle` = 360) the end of the range is at the same place as its start, and only the start is drawn. The numbers at the ends of a bar are moved inside the control instead of being cut.

### Ranges

`Ranges` is a collection of ranges of values with a color of their own, edited in the IDE with the collection editor or in code:

```delphi
Meter.Ranges.Add(0, 60, TAlphaColors.Green);
Meter.Ranges.Add(60, 80, TAlphaColors.Gold);
Meter.Ranges.Add(80, 100, TAlphaColors.Red);
```

| Property | Default | Meaning |
|---|---|---|
| `Ranges` | empty | The ranges: `StartValue`, `EndValue` (in any order) and `Color` of each one |
| `RangePlacement` | `[garTrack]`, `[gbrTrack]` | Where the ranges are drawn: on the track (`garTrack`, `gbrTrack`); in a thin band inside or outside the arc (`garInside`, `garOutside`); in a thin band before or after the bar (`gbrBefore`, `gbrAfter`). More than one place can be chosen, for example the track and a band outside it |
| `RangeBandThickness` | 4 | Thickness of the bands, in pixels |
| `FillFromRange` | `False` | The fill takes the color of the range that contains the value; out of the ranges it keeps its brush |

On the track the ranges are under the fill, so they are seen where the fill does not cover them; in the bands they are always seen. A range at an end of the track takes the rounded end of the track: the round ends of the `TArc` of the style, the rounded corners of the `TRectangle`. A band is 3 pixels away from the track, and a graduation on the same side is drawn beyond it. Where two ranges overlap, the later one is drawn over the earlier one, and it is the one `FillFromRange` uses.

### Target

| Property | Default | Meaning |
|---|---|---|
| `ShowTarget` | `False` | Marks the value of `Target` with a line across the track, 4 pixels longer than its thickness on each side |
| `Target` | 0 | The value to reach; a value out of the range is marked at its nearest end |

### Needle and pointer

The needle of `TS4YCircularMeter` is a line from the center of the arc towards the value, with a circle over the center; the pointer of `TS4YLinearMeter` is a small triangle beside the bar, with its tip towards the value. Both follow the animation of the value.

| Property | Default | Meaning |
|---|---|---|
| `Needle.Visible` | `True` | Draws the needle of the circular meter |
| `Needle.Length` | 90 | Length of the needle, in percent of the distance from the center to the inner edge of the track, from 0 to 100 |
| `Pointer.Visible` | `False` | Draws the pointer of the linear meter |
| `Pointer.Position` | `gbsBefore` | Side of the bar where the pointer is drawn: before it, above it or on its left (`gbsBefore`), or after it, below it or on its right (`gbsAfter`) |
| `ShowFill` | `False` (circular), `True` (linear) | Draws the filled part of the track. Without it the needle or the pointer shows the value, and the ranges on the track are seen whole |

With the needle visible, the value and the caption are written beside the center of the arc, beyond the circle of the needle, instead of in the middle of the area enclosed by the arc: on the side opposite to the middle of the arc, so below the center for an arc at the top, above it for an arc at the bottom, on the left of it for a half circle on the right. When there is not enough room on that side, as in a half circle, the arc becomes smaller to make it. The tip of the pointer touches the bar, or the band of the ranges on the same side; a graduation on the same side is drawn beyond the pointer.

### Style of the meters

The style of `TS4YLinearMeter` is `S4YLinearMeterStyle`, the style of `TS4YCircularMeter` is `S4YCircularMeterStyle`. They have the parts of the style of the gauge they descend from (`track`, `fill`, `valuetext`, `captiontext`) and these more:

| Part (`StyleName`) | In the default style | Use |
|---|---|---|
| `majortick` | `TLine`, gray, 1.5 pixels | Gives the brush of the major ticks (`Stroke`: color, thickness, dash, ends) |
| `minortick` | `TLine`, light gray, 1 pixel | Gives the brush of the minor ticks |
| `target` | `TLine`, dark gray, 3 pixels | Gives the brush of the mark of the target |
| `scaletext` | `TText`, size 11 | Font and color of the numbers |
| `needle` | `TLine`, red, 3 pixels, round ends | Circular meter: gives the brush of the needle |
| `needlecap` | `TCircle`, dark gray, 12 pixels | Circular meter: gives the brushes (`Fill`, `Stroke`) and, with its width, the size of the circle over the center |
| `pointer` | `TPath`, dark gray triangle, 10 x 8 pixels | Linear meter: gives the brushes of the pointer and, with its width and height, its size along the bar and away from it |

The ticks and the target can be any shape, a `TLine` or a `TRectangle` for example: only the brush of its border is used, the meter draws the lines itself. The needle too can be any shape, of which only the brush of the border is used; the circle of the needle and the pointer can be any shape, of which the brushes and the size are used, and the meter draws a circle and a triangle with them. A missing tick is replaced by a gray line 1.5 pixels thick, a missing target by a dark gray line 3 pixels thick, a missing needle by a red line 3 pixels thick, a missing circle of the needle by a dark gray circle 12 pixels wide, a missing pointer by a dark gray triangle 10 x 8 pixels, a missing text by the default font. The colors of the ranges come from the collection, not from the style. With `FillFromRange` the fill keeps the round ends of its `TArc` or the rounded corners of its `TRectangle`, with the color of the range. The style of the gauge the meter descends from is not used.

## Styles

The look of `TS4YLinearGauge` comes from a style named `S4YLinearGaugeStyle`, the look of `TS4YCircularGauge` from a style named `S4YCircularGaugeStyle`. Each style is a container of invisible parts with the same names. The styles of the meters are described in [Style of the meters](#style-of-the-meters).

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

`Demos\Gauges\S4YGaugesDemo.dproj` (also part of the project group `Demos\Soft4You.FMX.Controls.Demos.groupproj`) has two tabs. The tab Gauges shows a horizontal and a vertical linear gauge and a circular gauge with the same settings: the panel on the left changes `Value` with a track bar, `Min` and `Max`, the animation (a button sets a random value, to see it), `Caption`, `ShowValue`, `ValueFormat`, a text given by `OnGetValueText`, the fill from the style or from `FillBrush`, `Orientation` of the first gauge, `TextPosition` and `Thickness` of the linear gauges, and the shape, `StartAngle`, `SweepAngle` and `Thickness` of the circular one. The tab Meters shows a circular meter and a horizontal and a vertical linear meter, with green, yellow and red ranges: its panel changes `Value`, the graduation (`Visible`, `ShowLabels`, `MajorStep`, `Position`), the ranges and their places (`RangePlacement`), `FillFromRange`, the target (`ShowTarget`, `Target`), the needle (`Visible`, `Length`), the pointer (`Visible`, `Position`) and `ShowFill`.

`Demos\Gauges\S4YGaugesGallery.dproj` (also in the project group) shows what the gauges can look like, one example per tab: the default styles; the shapes of the circular gauge; meters whose values are changed by a timer: a speedometer with its zones on the track, a manometer with a target and its ranges in a band outside the arc, a vertical thermometer whose fill takes the color of the range, and a tuner with a pointer and no fill; a dashboard whose values are changed by a timer; a fill whose color changes with the level of the value, with the text from `OnGetValueText`; a download in small steps; a row of vertical bars without texts, like an equalizer; the styles of a `TStyleBook` (a gradient, a glossy line over the fill, square corners, flat ends, a dotted track, a gradient arc); and styles for a dark background. The styles are in the style book of the form and can be used as models.

Install the suite packages first.

## Notes

- The gauges stream their `StyledBrushes` after the brushes: a form saved with an explicit `StyledBrushes` keeps it when loaded.
- The gauges are indicators: they do not take the focus and do not change the value with the mouse or the keyboard.
