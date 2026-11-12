# TS4YStepProgressBar for FireMonkey

A progress indicator made of steps along a horizontal or vertical line, like the ones that show the phases of an installation or the pages of a wizard.

```
  ●━━━━━━━━●━━━━━━━━◉─────────○─────────○
Start   Download   Verify    Copy     Finish
```

- The **steps** are defined by the application, in the list `Steps`: each one has a caption, an optional description, an image and a `Failed` flag. The list has always a first and a last step, which cannot be removed or moved.
- `CurrentStep` says which step is in progress; `NextStep` and `PreviousStep` move to the next or the previous one.
- The steps before the current one are drawn as **completed**, the current one as **current**, the ones after it as **pending**, and a step with `Failed = True` as **failed**, wherever it is.
- The part of the line up to the current step can be highlighted, and it fills with an animation when the step changes.
- The user can change the current step with the mouse and the keyboard, if the application allows it (`Interactions`).
- Every part of the control comes from a **style**: line, markers, numbers and labels, in each of the four states. The markers and the line can have any shape designed in the style, not only a circle and a bar; properties can replace the colors of the simple shapes, and two events can draw the markers and the line from code.

Unit: `Soft4You.FMX.Controls.StepProgressBar` (in `Sources\StepProgressBar`); the types are in `Soft4You.FMX.Controls.StepProgressBar.Types`.

## Installation

`TS4YStepProgressBar` is part of the Soft4You FMX Control Suite. It is built into the runtime package `Soft4You.FMX.Controls.Suite`, and its registration into the design-time package `SuiteD`: see the README in the root of the repository. It appears in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\StepProgressBar` to the Delphi library path to compile your own projects with the units, and the folder `Resources`, where the packages compile the default style.

## Files

| File | Content |
|---|---|
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.pas` | The control, its steps and its settings |
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Types.pas` | Enumerations, sets and event types |
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Strings.pas` | Texts of the control and of its editor: captions of the first steps, error messages |
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Design.pas` | Editor of the steps in the IDE (design time) |
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Register.pas` | Registration in the Tool Palette and of the editor of the steps (design time) |
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Win.rc` / `.Mac.rc` | Resource scripts that link the style as the resource `S4YStepProgressBarStyle` |
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Win.style` / `.Mac.style` | Default style of the control (the two are identical) |
| `Graphics\StepProgressBar\TS4YStepProgressBar.svg` | Vector master of the icon of the Tool Palette |
| `Graphics\StepProgressBar\TS4YStepProgressBar.bmp`, `StepProgressBarDesign.rc` | Icon of the Tool Palette (24x24 bitmap) and the resource script that links it |

## Properties

| Property | Default | Meaning |
|---|---|---|
| `Steps` | Start, Step, End | The steps, in their order along the line (see below) |
| `CurrentStep` | 0 | Index of the step in progress, from 0. A value out of range is brought to the first or the last step |
| `Orientation` | `Horizontal` | `Horizontal`: steps from left to right. `Vertical`: from top to bottom |
| `LabelPosition` | `slpAfter` | Side of the markers and the line with the captions and the descriptions: `slpBefore` (above a horizontal line, on the left of a vertical one), `slpAfter` (below, on the right) or `slpNone` (hidden) |
| `LabelSpacing` | 6 | Space between the labels and the markers (or the line, when it is between them), in pixels |
| `MarkerPosition` | `smpCenter` | Where the markers are compared to the line: `smpCenter` (on the line), `smpBefore` (above a horizontal line, on the left of a vertical one) or `smpAfter` (below, on the right) |
| `MarkerSize` | 28 x 28 | `Width` and `Height` of the markers, in pixels, also when the line is vertical; the `Size` of the marker settings of a state can replace it (see [Markers](#markers)) |
| `LineSpacing` | 0 | Space between the markers and the line, in pixels (see [Layout](#layout)); a negative value makes the line go under the markers |
| `LineThickness` | 3 | Thickness of the line, in pixels |
| `HighlightProgress` | `True` | Draws the line up to the current step with the completed brush; with `False` the whole line has the pending brush and only the markers show the progress |
| `AnimationDuration` | 0.3 | Seconds the line takes to fill up to the new current step; 0 changes it at once. Used only with `HighlightProgress = True` |
| `Interactions` | `[]` | How the user can change the current step (see below); with the empty set the control is an indicator only |
| `CompletedMarker`, `CurrentMarker`, `PendingMarker`, `FailedMarker` | | How the markers in each state are drawn (see below) |
| `Line` | | Brushes and visibility of the line (see below) |
| `Images` | none | Image list for the markers that show an image |

The usual `TControl` properties (`Align`, `Anchors`, `Position`, `Size`, `Margins`, `Padding`, `Opacity`, `Visible`, `Enabled`, `HitTest`, `Cursor`, `RotationAngle`, `Scale`, `PopupMenu`, `StyleLookup`, `TabOrder`, `TabStop`) are published too. `Padding` leaves room between the edges of the control and its content.

### Layout

The steps are distributed evenly along the control: each one has the same share of the width (or of the height, when vertical), with the marker in the middle and the caption centered on it.

Across the line, the markers and the line form a band, placed on the side opposite to the labels (in the middle with `slpNone`); the labels go beyond the whole band, `LabelSpacing` away from it, so they never cover the line. `MarkerPosition` decides the order inside the band. In a horizontal bar with `LabelPosition = slpAfter`:

```
smpCenter                smpBefore                smpAfter
                          (1)    (2)    (3)       ─────────────────
(1)───(2)───(3)          ─────────────────         (1)    (2)    (3)
Start Copy  End          Start  Copy    End       Start  Copy    End
```

`LineSpacing` is the space between the markers and the line:

- with `smpCenter` the line runs from the edge of a marker to the edge of the next one, and `LineSpacing` is the gap left on both sides of each marker; with a negative value the line goes under the markers;
- with `smpBefore` and `smpAfter` the line is continuous, from the center of the first step to the center of the last one, and `LineSpacing` is the gap between the markers and the line.

With `Line.Visible = False` the band is made of the markers only.

### Interactions

`Interactions` is a set: each interaction is switched on and off by itself.

| Value | What it does |
|---|---|
| `stiClickMarker` | A click on the marker of a step makes it the current one |
| `stiClickLabel` | A click on the caption or the description of a step makes it the current one |
| `stiHandCursor` | The mouse pointer becomes a hand over the parts that a click can select (so it needs `stiClickMarker`, `stiClickLabel` or both); elsewhere the control keeps its own `Cursor` |
| `stiKeyboard` | The control can receive the focus (with a click or with Tab) and shows it with a dotted frame around the current marker; the left and up arrows move to the previous step, the right and down arrows to the next one, Home and End to the first and the last one |

For example a wizard where the user can go to a step with the mouse or the keyboard:

```delphi
WizardBar.Interactions := [stiClickMarker, stiClickLabel, stiHandCursor, stiKeyboard];
```

Every change made by the user fires `OnStepChanging`, which can refuse it: a rule like "only back to a completed step" goes there.

### Steps

`Steps` (`TS4YStepList`) has always a first and a last step: a new control has three steps, *Start*, *Step* and *End*. The first and the last steps cannot be removed or moved, and no step can take their place; the list changes the steps between them:

| Member | Meaning |
|---|---|
| `Add` | Adds a new step before the last one and returns it |
| `Insert(AIndex)` | Inserts a new step at `AIndex`, from 1 (after the first step) to `Count - 1` (before the last step), and returns it |
| `Delete(AIndex)` | Removes the step at `AIndex`, from 1 to `Count - 2` |
| `Move(ACurrentIndex, ANewIndex)` | Moves a step; both indexes go from 1 to `Count - 2` |
| `Clear` | Removes the steps between the first and the last one |
| `Count`, `Items[I]` | Number of the steps and the step at an index (`Steps[I]`) |

An operation on the first or the last step, or an index out of these ranges, raises `ES4YStepListError`. Setting `Index` of a step moves it like `Move`, and freeing a step between the first and the last one removes it like `Delete`.

Each step (`TS4YStepItem`) has:

| Property | Default | Meaning |
|---|---|---|
| `Caption` | empty | Text next to the marker |
| `Description` | empty | Second line of text under the caption, with the font of the description |
| `Failed` | `False` | Draws the step as failed, whatever its position |
| `ImageIndex` | -1 | Image of the step in `Images`, used by the markers whose settings show the image of the step |
| `Tag` | 0 | A value free for the application |

### Markers

The four properties `CompletedMarker`, `CurrentMarker`, `PendingMarker` and `FailedMarker` (`TS4YStepMarkerSettings`) have:

| Property | Default | Meaning |
|---|---|---|
| `Content` | `smcNumber` | What is drawn over the marker: `smcNone`, `smcNumber` (the number of the step, from 1) or `smcImage` |
| `ImageIndex` | -1 | Image of `Images` shown when `Content = smcImage`; with -1 each step shows its own `ImageIndex` |
| `Size` | 0 x 0 | `Width` and `Height` of the markers in this state, in pixels; a value of 0 takes the width or the height of `MarkerSize` of the control |
| `Fill`, `Stroke` | the colors of the default style | Fill and border used in place of the ones of the part of the style, when that part is a shape (`TCircle`, `TRectangle`, `TPath`, ...); a part made of several objects is drawn as the style defines it |
| `StyledBrushes` | `[smbFill, smbStroke]` | Which of the two brushes come from the style; changing `Fill` or `Stroke` switches the matching one off |

The markers of all the states are centered on the same axis, and the band of the markers and the line is as thick as the largest of them: the line and the labels do not move when a step changes state. For example smaller markers for the steps still to reach and a larger one for the current step:

```delphi
StepBar.PendingMarker.Size.Width := 16;
StepBar.PendingMarker.Size.Height := 16;
StepBar.CurrentMarker.Size.Width := 36;
StepBar.CurrentMarker.Size.Height := 36;
```

A step changes size at once when it changes state, for example when the line reaches it.

A check mark on all the completed steps:

```delphi
StepBar.Images := ImageList;
StepBar.CompletedMarker.Content := smcImage;
StepBar.CompletedMarker.ImageIndex := 0;   // the check mark in ImageList
```

### Line

`Line` (`TS4YStepLineSettings`) has `CompletedFill` and `PendingFill`, used in place of the fill of the parts `linecompleted` and `linepending` of the style when they are shapes, and `StyledBrushes` (`[slbCompleted, slbPending]`), which works like the one of the markers.

`Line.Visible` (default `True`) hides the line: only the markers and the labels are drawn, the change of the current step is not animated and `HighlightProgress`, `LineSpacing` and `LineThickness` have no effect.

## Methods and events

| Member | Meaning |
|---|---|
| `NextStep` | Makes the next step the current one. Returns `False` at the last step, or when `OnStepChanging` refuses the change |
| `PreviousStep` | Makes the previous step the current one. Returns `False` at the first step, or when `OnStepChanging` refuses the change |
| `OnStepChanging` | Fires before the current step changes, with the new step in `ANewStep`; setting `Allow` to `False` keeps the current step |
| `OnStepChanged` | Fires after the current step has changed |
| `OnDrawMarker` | Fires before each marker is drawn, with the canvas, the area of the marker, the index of the step and its state. Setting `Handled` to `True` replaces the part of the style with what the event has drawn; the number or the image of `Content` is not drawn either |
| `OnDrawLine` | Fires before each stretch of the line is drawn, with the canvas, the area of the stretch, the index of the step where it starts and `Completed`. The line has one stretch between each pair of steps; while it fills, the stretch it is crossing comes in two parts, one completed and one not. Setting `Handled` to `True` replaces the part of the style |

`OnStepChanging` and `OnStepChanged` fire for every change: `CurrentStep`, `NextStep`, `PreviousStep`, a click on a step and a key.

A marker drawn by the event, a rounded square:

```delphi
procedure TMainForm.StepBarDrawMarker(Sender: TObject; const ACanvas: TCanvas; const ARect: TRectF;
  const AStepIndex: Integer; const AState: TS4YStepState; var Handled: Boolean);
begin
  ACanvas.Fill.Kind := TBrushKind.Solid;

  if AState = sstPending then
    ACanvas.Fill.Color := TAlphaColors.Silver
  else
    ACanvas.Fill.Color := TAlphaColors.Darkorange;

  ACanvas.FillRect(ARect, 4, 4, AllCorners, 1);
  Handled := True;
end;
```

## Styles

The look of the control comes from a style named `S4YStepProgressBarStyle`. The style is a container of invisible parts:

| Part (`StyleName`) | In the default style | Use |
|---|---|---|
| `linecompleted`, `linepending` | `TRectangle` | Drawn for each stretch of the line, completed or not |
| `completedmarker`, `currentmarker`, `pendingmarker`, `failedmarker` | `TEllipse` | Drawn as the marker of the steps in each state |
| `focusframe` | `TEllipse`, dotted border | Drawn around the current marker while the control has the focus (`stiKeyboard`) |
| `completedtext`, `currenttext`, `pendingtext`, `failedtext` | `TText` | Font and color of the number in the markers |
| `completedlabel`, `currentlabel`, `pendinglabel`, `failedlabel` | `TText` | Font and color of the captions |
| `description` | `TText` | Font and color of the descriptions |

The graphic parts (line, markers and focus frame) can be **any graphic object**: a `TCircle`, a `TRectangle` with rounded corners, a `TPath` with a shape of its own, a `TLine` with a dashed border, a `TImage`, or a `TLayout` with several objects inside, for example a square with a check mark. The control draws a copy of the part as it is, resized to the area of the marker (the size of its state, see [Markers](#markers)), of the stretch of line (`LineThickness` thick, as long as described in [Layout](#layout)) or of the focus frame; the objects inside the part follow their `Align`, `Margins` and `Anchors`. The number or the image of `Content` is drawn over the marker.

The size of the parts in the style does not matter: the geometry is given by the properties of the control. A part keeps the proportions only if its class does: in markers wider than tall, a `TEllipse` (the default) becomes an oval that fills the area, while a `TCircle` stays a circle as large as the shorter side, centered in the area. With `smpCenter` the line stops at the edges of the area of the markers, so a marker with a transparent center does not show the line through it, unless `LineSpacing` is negative.

A stretch of line is horizontal or vertical according to `Orientation`. A part that works in one direction only, such as a `TLine` with `LineType = Top`, needs a style of its own (`StyleLookup`) for the bars of the other direction; a `TRectangle` works in both.

The style linked into the package is used when no other style defines `S4YStepProgressBarStyle`. To change the look of all the step bars of an application:

1. In the style of a `TStyleBook`, add a `TLayout` with `StyleName = 'S4YStepProgressBarStyle'` and, inside it, the parts listed above. The default style, `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Win.style`, is a text file with all of them and can be used as a model.
2. Change the parts: their colors and fonts, or replace a shape with another object.

A style with another name is used by the controls whose `StyleLookup` is set to that name; when no style has that name, they use `S4YStepProgressBarStyle` as the others. The style of the parent class of the control is never used. A part missing from a style is replaced by an ellipse (markers and focus frame) or a bar (line) with the brushes of the properties, and a missing text by the default font and colors.

## Example

The progress of an installation:

```delphi
uses
  Soft4You.FMX.Controls.StepProgressBar;

procedure TMainForm.PrepareSteps;
begin
  // Clear keeps the first and the last step; Add inserts the new ones before the last.
  StepBar.Steps.Clear;
  StepBar.Steps[0].Caption := 'Start';
  StepBar.Steps.Add.Caption := 'Download';
  StepBar.Steps.Add.Caption := 'Verify';
  StepBar.Steps.Add.Caption := 'Copy files';
  StepBar.Steps[StepBar.Steps.Count - 1].Caption := 'Finish';
  StepBar.CurrentStep := 0;
end;

procedure TMainForm.PhaseCompleted(Succeeded: Boolean);
begin
  if Succeeded then
    StepBar.NextStep
  else
    StepBar.Steps[StepBar.CurrentStep].Failed := True;
end;
```

In the designer, drop a `TS4YStepProgressBar` on the form and click the button of `Steps` in the Object Inspector: the editor of the steps lists them, and the selected step is shown in the Object Inspector. The buttons *Add*, *Insert*, *Delete*, *Move up* and *Move down* work on the steps between the first and the last one; *Insert* puts the new step in place of the selected one.

## Demo

`Demos\StepProgressBar\S4YStepProgressBarDemo.dproj` (also part of the project group `Demos\Soft4You.FMX.Controls.Demos.groupproj`) shows two step bars: a horizontal one for an installation, moved by the buttons *Next* and *Previous*, where the current step can be marked as failed; and a vertical one for a wizard, with all the `Interactions`, where a click or the keyboard selects a step and `OnStepChanging` does not allow skipping a step forward. The panel on the right switches each interaction of the wizard on and off, and changes `HighlightProgress`, the animation, the numbers in the markers, `LabelPosition`, `Line.Visible`, `MarkerPosition`, `MarkerSize`, the size of the pending and current markers, `LineSpacing` and `LabelSpacing` of both bars. Install the suite packages first.

## Notes

- The marker settings and the line stream their `StyledBrushes` after the brushes: a form saved with an explicit `StyledBrushes` keeps it when loaded.
- The form file stores the steps as `StepItems`, after `CurrentStep`: the control checks the range of `CurrentStep` only when the form is loaded.
- The `Stroke` of the marker settings starts with the thickness 1, the default of `TStrokeBrush`; the default style draws the borders with the thickness 2. Set `Stroke.Thickness` too when you replace the border of the style.
- The images of `Images` are drawn when the control paints: after changing the image list, call `Repaint` to show the change.
