# TS4YBlockScrollBox for FireMonkey

A scroll box that stacks its children as the blocks of the CSS flow (`display: block`): each child under the previous one, in the order of the children. The box decides the position and the width of every child, the child its height. When the flow is taller or wider than the box, the scroll bars show the rest.

It is the parent that a `TS4YFlexBox` needs to behave as a block of a web page: inside the box the flexbox has the width of the box (`width: auto`), follows it without hooking any event, and the next block moves when the flexbox changes height.

Unit: `Soft4You.FMX.Controls.BlockScrollBox` (in `Sources\BlockScrollBox`).

## Installation

`TS4YBlockScrollBox` is part of the Soft4You FMX Control Suite. It is built into the runtime package `Soft4You.FMX.Controls.Suite`, and its registration into the design-time package `SuiteD`: see the README in the root of the repository. It appears in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\BlockScrollBox` to the Delphi library path to compile your own projects with the unit. `TS4YFlexBox` uses the unit `Soft4You.FMX.Controls.BlockScrollBox.Abstracts`, so a project with the flexbox needs that folder too.

## Files

| File | Content |
|---|---|
| `Sources\BlockScrollBox\Soft4You.FMX.Controls.BlockScrollBox.pas` | The control |
| `Sources\BlockScrollBox\Soft4You.FMX.Controls.BlockScrollBox.Abstracts.pas` | The interfaces between the flow and the children with their own rules (`IS4YBlockFlowContainer`, `IS4YBlockFlowChild`) |
| `Sources\BlockScrollBox\Soft4You.FMX.Controls.BlockScrollBox.Register.pas` | Registration in the Tool Palette (design time) |
| `Graphics\BlockScrollBox\TS4YBlockScrollBox.svg` | Vector master of the icon of the Tool Palette |
| `Graphics\BlockScrollBox\TS4YBlockScrollBox.bmp`, `BlockScrollBoxDesign.rc` | Icon of the Tool Palette (24x24 bitmap) and the resource script that links it |
| `Tests\BlockScrollBox` | DUnitX tests of the flow (see "Running the tests") |
| `Demos\BlockScrollBox` | Sample application (see "Demo") |

## The block flow

| Rule | CSS |
|---|---|
| The children are stacked from the top, in the order of the children (`Index`) | normal flow of `display: block` |
| The first child starts after the `Padding` of the box, each child is separated from the next by their `Margins` | `padding`, `margin` |
| The vertical margins are added: the `Margins.Bottom` of a child and the `Margins.Top` of the next one both count | no margin collapsing |
| The height of a child is its own | `height: auto` (or a set height) |
| The box is as tall as the flow (plus `Padding.Bottom`): when it is taller than the box, the vertical bar appears | scrollable overflow |
| A child wider than the box, or its content that overflows, makes the horizontal bar appear | scrollable overflow |
| A child with `Visible = False` takes no space | `display: none` |

Any control can be a child: a panel, a label, a memo, a `TS4YExpander`, a `TS4YFlexBox`. The `Position` of a child is not yours to set: the flow gives it (see "Order of the children" for what a new `Position.Y` does).

## Align of the children

In the box the `Align` of a child does not align it: it tells the flow how to treat the child. Only the values that have a meaning in the CSS model are kept; when a child is added, when the form is loaded and when its `Align` changes, the other values become the nearest one:

| `Align` | The child | CSS | Values that become it |
|---|---|---|---|
| `None` | keeps its own width, on the left | a width set | `Left`, `MostLeft`, `Fit`, `FitLeft`, `Scale`, `Vertical` |
| `Top` | fills the width of the box, minus its `Margins` | `width: auto` | `Client`, `Contents`, `Bottom`, `MostTop`, `MostBottom`, `VertCenter`, `Horizontal` |
| `Center` | keeps its own width, centered | `margin: 0 auto` | `HorzCenter` |
| `Right` | keeps its own width, on the right | `margin-left: auto` | `MostRight`, `FitRight` |

A child with `Center` or `Right` that is wider than the box goes on the left, as a block with automatic margins in CSS, and the horizontal bar shows the rest.

A child with `Align = Top` has no width of its own, so it never makes the horizontal bar appear: its content is cropped or not, as the child decides. The flexbox is the exception (see below).

### Anchors

The `Anchors` of the children do not count in the flow. A child with `Align = None` gets `Anchors = [akTop]`, visible in the Object Inspector and saved in the form file. It is needed by the box: with the default anchors FMX does not tell the parent that the child was moved with `SetBounds`, which is how the designer moves it, and the box would not see the new `Position.Y`.

## Order of the children

The order of the flow is the order of the children:

- **A new child goes at the end** of the flow, wherever it is dropped (as `appendChild` in a web page).
- **A new `Position.Y` moves the child** after all the children whose `Y` is smaller; then the flow gives it its `Y` again. It works at design time (in the Object Inspector, or dragging the child in the designer) and in code. `Position.Y := 0` moves the child to the top.
- **`Position.X` is not kept**: the flow gives the horizontal position.
- **In code** the order can also be changed with `Index`.

In the designer, dragging a child is only a convenience: dropped on a sibling, the FMX designer puts it inside the sibling, not before or after it. Drop it on the margin between two children, or set `Position.Y` in the Object Inspector.

## A flexbox in the flow

A `TS4YFlexBox` takes part in the flow with its own rules (it implements `IS4YBlockFlowChild`). With `AutoWidth = True` and `Align = None`, or with `Align = Top`, its width is automatic, as `width: auto` of a block container in CSS:

- **Width**: the width of the box minus the `Padding` of the box and the `Margins` of the flexbox. It is never more, even when the items do not fit: the flexbox does not grow to its content.
- **Overflow**: items that do not fit (for example with `FlexShrink = 0` or a minimum width) overflow the flexbox, and the horizontal bar of the box counts them. With `ClipChildren = True` the flexbox crops them and the bar does not appear (`overflow: hidden`).
- **Minimum width**: `MinWidth` of the flexbox (`min-width`) is the only way to make the flexbox wider than the box: the items wrap at that width and the horizontal bar appears.
- **Height**: the flexbox sets it (`AutoHeight`); when it changes, for example because the items wrap at a new width, the next blocks move.
- **No event is hooked**: the box tells the flexbox its width, so the `OnResized` of the parent is left alone (outside the box the flexbox needs it, see the FlexBox README).
- **Position**: as for every child, the flow gives it.

A flexbox with `AutoWidth = False` keeps its own width, like any other child with `Align = None`, `Center` or `Right`; the bar still counts its items that overflow.

Changing `ClipChildren` of the flexbox does not start a layout: call `ArrangeChildren` of the box afterwards, so that the horizontal bar follows.

### Example

A page with a title, a flexbox of cards and a footer, in a box that fills the form:

```delphi
uses
  FMX.StdCtrls,
  Soft4You.FMX.Controls.BlockScrollBox,
  Soft4You.FMX.Controls.FlexBox,
  Soft4You.FMX.Controls.FlexBox.Engine;

procedure TMainForm.CreatePage;
var
  LBox: TS4YBlockScrollBox;
  LCards: TS4YFlexBox;
  LFooter: TLabel;
  LTitle: TLabel;
begin
  LBox := TS4YBlockScrollBox.Create(Self);
  LBox.Align := TAlignLayout.Client;
  LBox.Padding.Rect := TRectF.Create(16, 16, 16, 16);
  LBox.Parent := Self;

  LTitle := TLabel.Create(Self);
  LTitle.Align := TAlignLayout.Top;
  LTitle.Text := 'Dashboard';
  LTitle.Parent := LBox;

  // width: auto: the width of the box, the items wrap and set the height
  LCards := TS4YFlexBox.Create(Self);
  LCards.Wrap := fwWrap;
  LCards.Margins.Top := 8;
  LCards.Parent := LBox;

  LFooter := TLabel.Create(Self);
  LFooter.Align := TAlignLayout.Top;
  LFooter.Margins.Top := 8;
  LFooter.Text := 'Updated every hour';
  LFooter.Parent := LBox;
end;
```

In the designer, drop a `TS4YBlockScrollBox` on the form with `Align = Client`, then drop the children in it in the order of the page: each one goes at the end.

## Demo

`Demos\BlockScrollBox\S4YBlockScrollBoxDemo.dproj` (also part of the project group `Demos\Soft4You.FMX.Controls.Demos.groupproj`) is a page in a `TS4YBlockScrollBox`: a title, a paragraph that wraps, a flexbox of six cards, a block in the center, one on the right, a block 900 pixels wide that makes the horizontal bar appear, and a footer. Resize the window: the cards wrap again and the blocks after them move. The panel on the right turns off the wrapping of the cards (they overflow and the horizontal bar counts them), sets `ClipChildren` and `MinWidth` of the flexbox, adds a block at the end of the flow and moves the footer to the top or back to the end with `Position.Y`. Install the suite packages first.

## Limits

- Only `display: block`: no `inline-block`, `float`, positioned children or margin collapsing.
- A generic child with `Align = Top` has no width of its own: if its content is wider than the box, the horizontal bar does not see it. Only a flexbox tells the box what its content overflows.
- The box sets the position of the children directly: animations of `Position` or `Width` of a child are overridden by the next layout of the flow.
- `Anchors = [akTop]` on the children with `Align = None`, see "Anchors".

## Running the tests

The project `Tests\BlockScrollBox\S4YBlockScrollBoxTests.dproj` runs the DUnitX tests of the box (22 tests, `Soft4You.FMX.Controls.BlockScrollBox.Tests`): the flow and the `Padding` and `Margins`, the mapping of `Align`, `Center` and `Right`, the anchors, the invisible children, the width of the flow for the horizontal bar, the order of the children (a new child at the end, `Position.Y`, `SetBounds`, `Index`, `Position.X` ignored) and the flexbox in the flow (width, overflow, `ClipChildren`, `MinWidth`, `Align = Top`, a height that moves the next child, `AutoWidth = False`).
