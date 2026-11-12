# TS4YStepProgressBar for FireMonkey

A progress indicator made of steps along a horizontal or vertical line, like the ones that show the phases of an installation or the pages of a wizard.

```
  ●━━━━━━━━●━━━━━━━━◉─────────○─────────○
Start   Download   Verify    Copy     Finish
```

- The **steps** are defined by the application, in the collection `Steps`: each one has a caption, an optional description, an image and a `Failed` flag.
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
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Register.pas` | Registration in the Tool Palette (design time) |
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Win.rc` / `.Mac.rc` | Resource scripts that link the style as the resource `S4YStepProgressBarStyle` |
| `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Win.style` / `.Mac.style` | Default style of the control (the two are identical) |
| `Graphics\StepProgressBar\TS4YStepProgressBar.svg` | Vector master of the icon of the Tool Palette |
| `Graphics\StepProgressBar\TS4YStepProgressBar.bmp`, `StepProgressBarDesign.rc` | Icon of the Tool Palette (24x24 bitmap) and the resource script that links it |

## Properties

| Property | Default | Meaning |
|---|---|---|
| `Steps` | empty | The steps, in their order along the line (see below) |
| `CurrentStep` | 0 | Index of the step in progress, from 0. A value out of range is brought to the first or the last step |
| `Orientation` | `Horizontal` | `Horizontal`: steps from left to right. `Vertical`: from top to bottom |
| `LabelPosition` | `slpAfter` | Side of the line with the captions and the descriptions: `slpBefore` (above a horizontal line, on the left of a vertical one), `slpAfter` (below, on the right) or `slpNone` (hidden) |
| `MarkerSize` | 28 | Width and height of the markers, in pixels |
| `LineThickness` | 3 | Thickness of the line, in pixels |
| `HighlightProgress` | `True` | Draws the line up to the current step with the completed brush; with `False` the whole line has the pending brush and only the markers show the progress |
| `AnimationDuration` | 0.3 | Seconds the line takes to fill up to the new current step; 0 changes it at once. Used only with `HighlightProgress = True` |
| `Interactions` | `[]` | How the user can change the current step (see below); with the empty set the control is an indicator only |
| `CompletedMarker`, `CurrentMarker`, `PendingMarker`, `FailedMarker` | | How the markers in each state are drawn (see below) |
| `Line` | | Brushes of the line (see below) |
| `Images` | none | Image list for the markers that show an image |

The usual `TControl` properties (`Align`, `Anchors`, `Position`, `Size`, `Margins`, `Padding`, `Opacity`, `Visible`, `Enabled`, `HitTest`, `Cursor`, `RotationAngle`, `Scale`, `PopupMenu`, `StyleLookup`, `TabOrder`, `TabStop`) are published too. `Padding` leaves room between the edges of the control and its content.

The steps are distributed evenly along the control: each one has the same share of the width (or of the height, when vertical), with the marker in the middle and the caption centered under it.

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

Each item of `Steps` (`TS4YStepItem`) has:

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
| `Fill`, `Stroke` | the colors of the default style | Fill and border used in place of the ones of the part of the style, when that part is a shape (`TCircle`, `TRectangle`, `TPath`, ...); a part made of several objects is drawn as the style defines it |
| `StyledBrushes` | `[smbFill, smbStroke]` | Which of the two brushes come from the style; changing `Fill` or `Stroke` switches the matching one off |

For example a check mark on all the completed steps:

```delphi
StepBar.Images := ImageList;
StepBar.CompletedMarker.Content := smcImage;
StepBar.CompletedMarker.ImageIndex := 0;   // the check mark in ImageList
```

### Line

`Line` (`TS4YStepLineSettings`) has `CompletedFill` and `PendingFill`, used in place of the fill of the parts `linecompleted` and `linepending` of the style when they are shapes, and `StyledBrushes` (`[slbCompleted, slbPending]`), which works like the one of the markers.

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
| `completedmarker`, `currentmarker`, `pendingmarker`, `failedmarker` | `TCircle` | Drawn as the marker of the steps in each state |
| `focusframe` | `TCircle`, dotted border | Drawn around the current marker while the control has the focus (`stiKeyboard`) |
| `completedtext`, `currenttext`, `pendingtext`, `failedtext` | `TText` | Font and color of the number in the markers |
| `completedlabel`, `currentlabel`, `pendinglabel`, `failedlabel` | `TText` | Font and color of the captions |
| `description` | `TText` | Font and color of the descriptions |

The graphic parts (line, markers and focus frame) can be **any graphic object**: a `TCircle`, a `TRectangle` with rounded corners, a `TPath` with a shape of its own, a `TLine` with a dashed border, a `TImage`, or a `TLayout` with several objects inside, for example a square with a check mark. The control draws a copy of the part as it is, resized to the area of the marker (`MarkerSize` x `MarkerSize`), of the stretch of line (`LineThickness` thick, from the center of a marker to the center of the next one) or of the focus frame; the objects inside the part follow their `Align`, `Margins` and `Anchors`. The number or the image of `Content` is drawn over the marker.

The size of the parts in the style does not matter: the geometry is given by the properties of the control. The line passes under the markers, so a marker with a transparent center shows the line through it.

A stretch of line is horizontal or vertical according to `Orientation`. A part that works in one direction only, such as a `TLine` with `LineType = Top`, needs a style of its own (`StyleLookup`) for the bars of the other direction; a `TRectangle` works in both.

The style linked into the package is used when no other style defines `S4YStepProgressBarStyle`. To change the look of all the step bars of an application:

1. In the style of a `TStyleBook`, add a `TLayout` with `StyleName = 'S4YStepProgressBarStyle'` and, inside it, the parts listed above. The default style, `Sources\StepProgressBar\Soft4You.FMX.Controls.StepProgressBar.Win.style`, is a text file with all of them and can be used as a model.
2. Change the parts: their colors and fonts, or replace a shape with another object.

A style with another name is used by the controls whose `StyleLookup` is set to that name; when no style has that name, they use `S4YStepProgressBarStyle` as the others. The style of the parent class of the control is never used. A part missing from a style is replaced by a circle (markers and focus frame) or a bar (line) with the brushes of the properties, and a missing text by the default font and colors.

## Example

The progress of an installation:

```delphi
uses
  Soft4You.FMX.Controls.StepProgressBar;

procedure TMainForm.PrepareSteps;
begin
  StepBar.Steps.Clear;
  StepBar.Steps.Add.Caption := 'Start';
  StepBar.Steps.Add.Caption := 'Download';
  StepBar.Steps.Add.Caption := 'Verify';
  StepBar.Steps.Add.Caption := 'Copy files';
  StepBar.Steps.Add.Caption := 'Finish';
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

In the designer, drop a `TS4YStepProgressBar` on the form and add the steps with the collection editor of `Steps`. While `Steps` is empty, the designer shows three sample steps, so that the control can be seen and placed.

## Demo

`Demos\StepProgressBar\S4YStepProgressBarDemo.dproj` (also part of the project group `Demos\Soft4You.FMX.Controls.Demos.groupproj`) shows two step bars: a horizontal one for an installation, moved by the buttons *Next* and *Previous*, where the current step can be marked as failed; and a vertical one for a wizard, with all the `Interactions`, where a click or the keyboard selects a step and `OnStepChanging` does not allow skipping a step forward. The panel on the right switches each interaction of the wizard on and off, and changes `HighlightProgress`, the animation, the numbers in the markers and `LabelPosition` of both bars. Install the suite packages first.

## Notes

- The marker settings and the line stream their `StyledBrushes` after the brushes: a form saved with an explicit `StyledBrushes` keeps it when loaded.
- `CurrentStep` is stored before `Steps` in the form: the control checks its range only when the form is loaded.
- The `Stroke` of the marker settings starts with the thickness 1, the default of `TStrokeBrush`; the default style draws the borders with the thickness 2. Set `Stroke.Thickness` too when you replace the border of the style.
- The images of `Images` are drawn when the control paints: after changing the image list, call `Repaint` to show the change.
