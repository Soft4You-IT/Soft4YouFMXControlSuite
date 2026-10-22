# TS4YFlexBox for FireMonkey — Installation and usage guide

FMX components that implement the CSS Flexbox model (W3C Level 1):

- **`TS4YFlexBox`**: the container, with the CSS container properties.
- **`TS4YFlexItem`**: the flexbox item, with the CSS item properties.
  Every control that takes part in the layout lives inside a `TS4YFlexItem`.

Namespace: `Soft4You.FMX.Controls.FlexBox.*`.

FlexBox is one of the controls of the Soft4You FMX Control Suite. It is built into the two packages of the suite, `Soft4You.FMX.Controls.Suite` (runtime) and `Soft4You.FMX.Controls.SuiteD` (design time), together with the other controls.

## Where the files are

```
Soft4YouFMXControlSuite/
├── Sources/FlexBox/
│   ├── Soft4You.FMX.Controls.FlexBox.Engine.pas      <- Pure CSS FlexBox algorithm (stateless, no FMX)
│   ├── Soft4You.FMX.Controls.FlexBox.pas             <- TS4YFlexBox and TS4YFlexItem (runtime)
│   ├── Soft4You.FMX.Controls.FlexBox.Strings.pas     <- Runtime messages (resourcestring)
│   ├── Soft4You.FMX.Controls.FlexBox.Types.pas       <- Simple types (breakpoint modes and overrides)
│   ├── Soft4You.FMX.Controls.FlexBox.SizeConstraints.pas <- Min/max width and height of an item
│   ├── Soft4You.FMX.Controls.FlexBox.ItemBase.pas    <- Base of TS4YFlexItem (breaks the circular dependency with the breakpoints)
│   ├── Soft4You.FMX.Controls.FlexBox.Breakpoints.pas <- Breakpoint collection (thresholds on the width)
│   ├── Soft4You.FMX.Controls.FlexBox.Design.pas      <- Automatic wrapping in the designer (design time)
│   └── Soft4You.FMX.Controls.FlexBox.Register.pas    <- Registration of the components in the palette
├── Packages/D11/
│   ├── Soft4You.FMX.Controls.Suite.dpk / .dproj      <- RUNTIME package -> Build (do not Install)
│   ├── Soft4You.FMX.Controls.SuiteD.dpk / .dproj     <- DESIGN package  -> Install
│   └── Soft4You.FMX.Controls.Suite.groupproj         <- Group with the packages and the demos
├── Graphics/FlexBox/
│   ├── FlexBoxDesign.rc                              <- Resource script of the palette icons (resources TS4YFLEXBOX and TS4YFLEXITEM)
│   ├── FlexBoxDesign.res                             <- Compiled from FlexBoxDesign.rc (see below)
│   ├── FlexBox24.bmp / FlexBox16.bmp                 <- Icon of TS4YFlexBox (the palette uses the 24x24 one)
│   └── FlexItem24.bmp / FlexItem16.bmp               <- Icon of TS4YFlexItem
├── Tests/FlexBox/
│   └── Soft4You.FMX.Controls.FlexBox.Engine.Tests.pas <- DUnitX suite (49 tests)
├── Docs/FlexBox/
│   ├── README.md                                     <- This file
│   ├── ANALYSIS_ChildrenFiltering.md                 <- Analysis of the children filtering
│   └── fmx-flexbox-roadmap.html                      <- Architecture and roadmap
└── Demos/FlexBox/
    └── S4YFlexBoxDemo.dpr / frmMain.pas / .fmx       <- Sample dashboard (see "Demo")
```

---

## How it works

A `TS4YFlexBox` positions its `TS4YFlexItem`s. Every item contains **one
control**. While the height of the item is automatic (`AutoHeight = True`) the
control is `Align = Top` and the item follows its height; with an explicit height
(`AutoHeight = False`) the control stays `Align = Top` with its own height (never
`Client`): the item has the given height and the control, for example a
`TExpander`, can open and close by itself. The flex properties of a control
(`FlexGrow`, `FlexShrink`, ...) are properties of the item that contains it, so
they are changed in the Object Inspector by selecting the item.

To put several controls in one position of the flexbox, use a container (layout,
panel, ...) as the content of the item.

### Automatic wrapping

When a control that is not a `TS4YFlexItem` becomes a child of a `TS4YFlexBox`,
a `TS4YFlexItem` is created with the same position and size, and the control is
moved inside it with `Align = Top` (automatic height, see below). The `Margins`
of the control pass to the item.

- **At design time**: drag a control into the flexbox; the item is created by the
  designer (name, Structure view, undo) and the control is inserted into it.
- **At run time**: `LButton.Parent := LFlexBox` creates the item automatically.
  After the assignment `LButton.Parent` is the `TS4YFlexItem`, not the flexbox.
- **While the DFM is loading** no wrapping takes place.
- **An item hosts one control only**: a second control dropped on an item that is
  already taken (for example on its padding) is not accepted by the item and gets
  an item of its own in the flexbox.
- **An item dropped on another item** (for example in the Structure view) does
  not become a child of the other one: it goes back to the flexbox, in the
  position before the target (see "Reordering the items" in the Design time
  chapter).
- **Empty items**: an item left without controls is deleted and the other items
  are positioned again.
- **An item lives only in a `TS4YFlexBox`**: at run time, assigning to a
  `TS4YFlexItem` a `Parent` other than a flexbox (for example a panel, or another
  item) raises `EInvalidOperation`. The rule does not apply while the DFM is
  loading nor at design time, where the designer creates the item in transit
  before putting it back into the flexbox.
- **The item is not in the palette**: the flexbox creates it, it must not be
  inserted by hand. It is registered with `RegisterNoIcon`, so in the Structure
  view it has the generic icon of the IDE.

### Automatic height and design size

As in CSS (`height: auto`), the height of an item can be **automatic** or
**explicit**:

- **Automatic** (`AutoHeight = True`, the default): the natural height of the
  item is the height of the contained control plus the `Padding` of the item. If
  the content changes height by itself (a `TExpander` that opens or closes, for
  example) the item follows it and the flexbox is laid out again.
- **Explicit** (`AutoHeight = False`): the height is the one that was set, and
  the content fills it. It becomes explicit by itself when the `Height` of the
  item is changed or the item is resized in the designer. To make it automatic
  again, set `AutoHeight` back to `True`: the content keeps the height it had, so
  it may be necessary to bring it back by hand to the wanted one.

The **design size** of the item (the last `Width`/`Height` chosen by the user,
used by the engine as the natural size) is different from the size calculated by
the layout (for example stretched with `AlignItems = aiStretch`). So reducing an
item brings the line back to the natural sizes of the other items. In the `.fmx`
file `Size` (the calculated one) is saved and, only if different,
`DesignWidth`/`DesignHeight` (not visible in the Object Inspector).

### Automatic width

The width too can be **automatic** (`AutoWidth = True`, the default) or
**explicit** (`AutoWidth = False`, which becomes true by itself when the `Width`
of the item is changed or the item is resized in the designer). As in CSS, an
automatic size on the cross axis adapts, an explicit one does not:

- **Stretch** (`AlignItems = aiStretch`, or `AlignSelf = asStretch`): it applies
  only to an automatic size. An item with an explicit height in a row, or with an
  explicit width in a column, keeps its own size.
- **Fit-content** in a column: the width of an automatic item does not exceed the
  available width of the flexbox (with an `AlignItems` other than stretch the
  design width remains, reduced if it does not fit). An explicit width is not
  reduced.
- **Single line** (`Wrap = fwNoWrap`): the only line takes the whole cross size of
  the flexbox, as in CSS. So in a row without wrap the automatic items stretch to
  the height of the flexbox, and `AlignItems`/`AlignSelf` with `Center` or
  `FlexEnd` position the items in the height of the flexbox. With `fwWrap` the
  lines are as tall as their content.

The design width remains the natural width of the item: it is the `FlexBasis`
when this is `fbuAuto`, and the starting width of the fit-content. The content
(`Align = Top`) follows the width of the item. To use the own width of the
content instead (for example a `TLabel` with `AutoSize`) see "Width from the
content".

### Width from the content

With `FitContent = True` (default `False`) the item takes the **own size of the
content**: the automatic (not explicit) width and height become those of the
content plus the `Padding` of the item. It is the case of a `TLabel` with
`AutoSize` (and `WordWrap = False`, otherwise `AutoSize` adapts only the height),
of a button or of an image that already have their own size.

- The content is no longer `Align = Top`: it keeps its size, at the top left
  (after the `Padding` of the item), even when the item grows because of
  `FlexGrow` or stretch. It is not stretched, otherwise its own size would be
  lost at the next layout.
- When the content changes size (for example the text of a label), the flexbox
  calculates itself again. The item hooks the `OnResized` event of the content,
  chaining the handler that the user may already have assigned; if the user
  assigns another one afterwards, the size is anyway read again at every layout.
- An explicit size (`AutoWidth = False`, `AutoHeight = False`) stays the chosen
  one: `FitContent` applies only to the automatic sizes.
- Setting `FitContent = False` again brings the content back to `Align = Top`.
- A `TLabel` created at run time takes its own size only when the text changes:
  assign `Text` after inserting it in the flexbox.

---

## Installation step by step

The component is installed with the packages of the suite, which also contain
the other controls. Open `Packages\D11\Soft4You.FMX.Controls.Suite.groupproj`.

### 1. Compile the icons into a resource

The palette icons are in `Graphics\FlexBox\FlexBoxDesign.res`, compiled from
`FlexBoxDesign.rc`. The compiled file is in the repository and the design package
compiles it again by itself when needed (`RcCompile` in the project), so this
step is only necessary to do it by hand. From the command line, in the
`Graphics\FlexBox` folder:

```bat
brcc32.exe FlexBoxDesign.rc
```

or with windres (MinGW):

```bat
windres FlexBoxDesign.rc -O res -o FlexBoxDesign.res
```

### 2. Build the runtime package

1. Open `Soft4You.FMX.Controls.Suite.dpk`
2. `Project > Build Soft4You.FMX.Controls.Suite`
3. Do **NOT** press Install (it is `{$RUNONLY}`)

### 3. Install the design-time package

1. Open `Soft4You.FMX.Controls.SuiteD.dpk`
2. `Component > Install Package` (or right click > Install)
3. The IDE asks for confirmation > OK

### 4. Check

Open the Tool Palette (`View > Tool Palette`).
Look for the page **"Soft4You FMX Controls Suite"**: `TS4YFlexBox` must appear.
`TS4YFlexItem` is not in the palette: the flexbox creates it.

Add the folder `Sources\FlexBox` to the Delphi library path: it is needed to
compile the demo and your own projects.

---

## Use in a project

### Without a package (direct embedding)

Add the runtime units to the project:

```
Soft4You.FMX.Controls.FlexBox.Engine.pas
Soft4You.FMX.Controls.FlexBox.Strings.pas
Soft4You.FMX.Controls.FlexBox.Types.pas
Soft4You.FMX.Controls.FlexBox.SizeConstraints.pas
Soft4You.FMX.Controls.FlexBox.ItemBase.pas
Soft4You.FMX.Controls.FlexBox.Breakpoints.pas
Soft4You.FMX.Controls.FlexBox.pas
```

No external dependencies.

### With the runtime package

In `Project > Options > Packages`, add `Soft4You.FMX.Controls.Suite` as a runtime
package. The application will look for `Soft4You.FMX.Controls.Suite<version>.bpl`
in the folder of the executable.

---

## Platforms

The component has **not been tested yet on any platform**. The code does not use
Windows-specific APIs (`TFlexEngine` is pure Pascal and the component uses only
FMX), so in theory it is portable, but the compatibility has to be checked.

| Platform          | Status      |
|-------------------|-------------|
| Windows 32/64     | Not tested  |
| macOS ARM/x86     | Not tested  |
| iOS ARM64         | Not tested  |
| Android ARM/ARM64 | Not tested  |
| Linux 64 (FMXL)   | Not tested  |

---

## Supported CSS properties

### Container (on TS4YFlexBox)

| Delphi property   | CSS equivalent     | Values                                                          |
|-------------------|--------------------|-----------------------------------------------------------------|
| `Direction`       | `flex-direction`   | `fdRow`, `fdRowReverse`, `fdColumn`, `fdColumnReverse`          |
| `Wrap`            | `flex-wrap`        | `fwNoWrap`, `fwWrap`, `fwWrapReverse`                           |
| `JustifyContent`  | `justify-content`  | `jcFlexStart/End/Center/SpaceBetween/SpaceAround/SpaceEvenly`   |
| `AlignItems`      | `align-items`      | `aiStretch/FlexStart/FlexEnd/Center/Baseline`                   |
| `AlignContent`    | `align-content`    | `acFlexStart/End/Center/SpaceBetween/SpaceAround/Evenly/Stretch`|
| `ColumnGap`       | `column-gap`       | `Single` (pixels)                                               |
| `RowGap`          | `row-gap`          | `Single` (pixels)                                               |

### Item (on TS4YFlexItem)

| Delphi property   | CSS equivalent   | Values                                     |
|-------------------|------------------|--------------------------------------------|
| `FlexGrow`        | `flex-grow`      | `Single` >= 0 (default: 0)                 |
| `FlexShrink`      | `flex-shrink`    | `Single` >= 0 (default: 1)                 |
| `FlexBasis`       | `flex-basis`     | `Single` (numeric value)                   |
| `FlexBasisUnit`   | *(basis unit)*   | `fbuAuto`, `fbuPixel`, `fbuPercent`        |
| `AlignSelf`       | `align-self`     | `asAuto/Stretch/FlexStart/FlexEnd/Center`  |
| `Order`           | `order`          | `Integer` (default: 0)                     |
| `AutoHeight`      | `height: auto`   | `Boolean` (default: `True`)                |
| `AutoWidth`       | `width: auto`    | `Boolean` (default: `True`)                |
| `FitContent`      | `width/height: auto` = size of the content | `Boolean` (default: `False`), see "Width from the content" |
| `SizeConstraints` | `min-/max-width`, `min-/max-height` | group with `MinWidth`, `MaxWidth`, `MinHeight`, `MaxHeight` (`Single` >= 0, default: 0 = no limit), like `Margins` |
| `Index`           | *(source order)* | position of the item in the flexbox, not saved |

The limits of `SizeConstraints` (`MinWidth`, `MaxWidth`, `MinHeight`, `MaxHeight`)
work as in CSS: they also limit an explicit size (`max-width` wins over `width`),
they apply to flex-grow and flex-shrink (the space that an item cannot take or
give up goes to the others) and to the stretch on the cross axis, and they count
to decide how many items fit on a line with wrap. They concern the item, not the
content: if the content is taller than `MaxHeight`, it overflows.

With the same `Order` the source order counts, that is the position of the item
in the flexbox (`Index`).

Behaviour of the "natural" size of an item (used with `FlexBasisUnit = fbuAuto`):
it is the design size (see above); its `Margins` are the CSS margins of the
element and its `Padding` is the space between the border of the item and the
contained control.

The published properties of `TS4YFlexItem` are only these, plus `Height`,
`Margins`, `Padding`, `Size`, `Visible` and `Width`: position and alignment are
decided by the flexbox.

---

## Programmatic API

```delphi
// The item of a control is its Parent, after the assignment to the flexbox
LButton.Parent := LFlexBox;
LItem := LButton.Parent as TS4YFlexItem;
LItem.FlexGrow := 1;
LItem.FlexBasis := 200;
LItem.FlexBasisUnit := fbuPixel;

// Explicit creation of the item (equivalent to the automatic wrapping)
LItem := LFlexBox.WrapControl(LButton);

// Force a new calculation
LFlexBox.InvalidateLayout;

// Reordering: with the same Order the position of the item counts
LItem.Index := 0;
```

---

## Events

The events fire **when the layout is finished** and only if something has
changed; they do not fire at design time nor while loading. A handler that
changes the content starts a new layout: it does not re-enter the one in
progress. During the construction (adding the items, intermediate resizing) the
layout is calculated again at every change, so the events can fire several times
before the final configuration.

### TS4YFlexItem

| Event | When |
|-------|------|
| `OnFlexStateChanged(Sender; AState, APreviousState: TFlexItemState)` | The size on the main axis changes compared to the flex-basis: `fisShrunk` (smaller), `fisAtBasis` (equal, tolerance 0.5 px), `fisGrown` (larger) |
| `OnLayoutChanged(Sender)` | Position or size of the item changed (tolerance 0.5 px) compared to the last notified layout; it also fires at the first layout |
| `OnLineChanged(Sender; ALineIndex, APreviousLineIndex: Integer)` | The item moves to another row (or column) because of the wrapping |

At the **first layout** the events fire immediately: `APreviousLineIndex` is `-1`
and `APreviousState` is equal to `AState`, so the initial appearance can be set
in the same handler.

### TS4YFlexBox

| Event | When |
|-------|------|
| `OnBreakpointsChanged(Sender)` | The set of active breakpoints changes (see "Breakpoints"); it fires before `OnLineCountChanged` |
| `OnLayoutApplied(Sender)` | After every layout, with all the items already positioned |
| `OnLineCountChanged(Sender; ALineCount, APreviousLineCount: Integer)` | The number of rows (or columns) changes; at the first layout `APreviousLineCount` is `-1` |

For now there is no event for every change of position/size of an item.

### Breakpoints

The breakpoints change the properties of the **flexbox** and of its **items**
according to the width of the flexbox (`Width`), like the CSS media queries. They
are defined in the `Breakpoints` collection and are read according to
`BreakpointMode`, one for the whole list:

- `bmMaxWidth` (default): the rule applies **up to** `Width` (like `max-width`)
- `bmMinWidth`: the rule applies **from** `Width` upwards (like `min-width`)

The comparison is inclusive. When `BreakpointMode` is changed the rules stay but
they are read the other way round: it is worth rethinking the base values.

Every breakpoint has `Width`, the set `ContainerOverrides` and the values of the
container properties that it can override: `Direction`, `Wrap`, `JustifyContent`,
`AlignItems`, `AlignContent`, `ColumnGap`, `RowGap`. A value applies only if the
property is in `ContainerOverrides` (otherwise the value of the breakpoint is
ignored).

**Cascade, as in CSS**: all the breakpoints that match the width apply, from the
least to the most specific, and the last one wins on the same properties. The
component calculates the order and it **does not depend on the position in the
list**: with `bmMaxWidth` from the largest `Width` to the smallest, with
`bmMinWidth` from the smallest to the largest (with the same `Width` the position
counts). The properties that no active breakpoint touches stay the base ones.

Example, base `Direction = fdRow`, `ColumnGap = 0`, `bmMaxWidth`:

| `Width` | `ContainerOverrides` | Values |
|---------|----------------------|--------|
| 900 | `ColumnGap` | `ColumnGap = 8` |
| 600 | `Direction` | `Direction = fdColumn` |
| 400 | `ColumnGap` | `ColumnGap = 2` |

| Width | Active breakpoints | `Direction` | `ColumnGap` |
|-------|--------------------|-------------|-------------|
| 1000 | none | `fdRow` | 0 |
| 800 | 900 | `fdRow` | 8 |
| 500 | 900, 600 | `fdColumn` | 8 |
| 350 | 900, 600, 400 | `fdColumn` | 2 |

Notes:

- The effective values are calculated at every layout: the published properties
  (`Direction`, ...) stay the base ones and the saved file contains only the base
  and the rules.
- The width that is compared is the `Width` of the flexbox (padding included).
- **The breakpoints also apply at design time**: the canvas shows the effective
  layout for the current width of the flexbox, while the Object Inspector always
  shows the base values. To try a threshold, just resize the flexbox.
- `ActiveBreakpoints` lists the active breakpoints in the order of application.
- `ColumnGap` is the gap between items on the same main axis (also with
  `fdColumn`), unlike CSS where with a column `row-gap` counts.
- The thresholds depend on the width of the flexbox, which does not depend on its
  content: changing `Direction` from a breakpoint cannot make the threshold fire
  again. With the automatic width (in the backlog) this will have to be
  reconsidered.

#### Item overrides

Every breakpoint also has `ItemOverrides`: a collection of elements that name an
item (`Item`, a drop-down in the Object Inspector) and which of its properties the
breakpoint overrides (`Overrides`). They are needed when a property of the item
only makes sense in one direction: going from row to column, for example,
`FlexBasis = 320 px` and `FlexGrow = 1` would apply to the height.

| Entry of `Overrides` | Property of the element |
|----------------------|-------------------------|
| `ioFlexGrow` | `FlexGrow` |
| `ioFlexShrink` | `FlexShrink` |
| `ioFlexBasis` | `FlexBasis` and `FlexBasisUnit` |
| `ioAlignSelf` | `AlignSelf` |
| `ioOrder` | `Order` |
| `ioVisible` | `Visible` |
| `ioWidth` | `AutoWidth` and `Width` |
| `ioHeight` | `AutoHeight` and `Height` |
| `ioMargins` | `Margins` |
| `ioMinWidth` | `SizeConstraints.MinWidth` |
| `ioMaxWidth` | `SizeConstraints.MaxWidth` |
| `ioMinHeight` | `SizeConstraints.MinHeight` |
| `ioMaxHeight` | `SizeConstraints.MaxHeight` |

The cascade is the one of the container: the overrides of all the active
breakpoints apply, in the same order, and what none of them touches stays the base
value of the item. Notes:

- The published properties of the item do not change. With `ioVisible` the item is
  hidden or shown for as long as the breakpoint lasts; the `Visible` chosen by the
  user is kept (and if it is set while an override is active, it applies when the
  override ends).
- If the item is deleted, its overrides disappear.
- A height override (`ioHeight`) only changes the height of the item, like the
  explicit base height: the content stays `Top` with its own height and does not
  adapt to the item (a `TExpander` opens and closes by itself). With the automatic
  height, instead, the item follows the content.
- With the same property on the same item in the same breakpoint, the last
  element of the list wins.

---

## Demo

`Demos\FlexBox\S4YFlexBoxDemo.dproj` is a "Sales overview" dashboard built only
with standard FMX controls inside the flexboxes, without application logic (the
data is fixed in the `.fmx`). It needs the suite packages
(`Soft4You.FMX.Controls.Suite` and `Soft4You.FMX.Controls.SuiteD`) installed, and
it is part of the project group in `Packages\D11`. It shows:

| Area | What it shows |
|------|---------------|
| Sidebar (column) | `Direction = fdColumn`, "spacer" item with `FlexGrow = 1` that pushes "Log out" to the bottom |
| Header | `JustifyContent = jcSpaceBetween`, `AlignItems = aiCenter`, title (`AutoSize` label) and user button with `FitContent` (width from the content), search hidden below 560 px with an `ioVisible` override |
| KPI cards | `Wrap`, `FlexBasis` in percent (23%, 48% below 760 px) and `FlexGrow` |
| Bar chart | nested flexbox with `AlignItems = aiFlexEnd`, 12 items with explicit height and `FlexBasis = 0`, `FlexGrow = 1` |
| Traffic, orders, activity | `FlexBasis` in pixels and proportional grow (2:1) |
| Breakpoints (main flexbox) | below 1000 px it hides "Team activity"; below 760 px it shows only KPIs and chart |

Two things remain in the code: the sidebar hides below 700 px of form width (the
sidebar is not an item of a flexbox) and the StatusBar shows sizes, number of rows
and active breakpoints, updated by `OnLayoutApplied` and `OnLineCountChanged`.

---

## Usage examples

The examples build the layouts in code. `AParent` is the control that hosts the
`TS4YFlexBox`. The units needed:

```delphi
uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Objects,
  Soft4You.FMX.Controls.FlexBox,
  Soft4You.FMX.Controls.FlexBox.Engine;
```

### Example 1 — Navigation bar with grow and gap

Equivalent CSS:

```css
.navbar {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 8px;
  padding: 8px;
}
.logo    { flex: 0 0 120px; }
.spacer  { flex: 1; }
.btn     { flex: 0 0 auto; }
```

```delphi
procedure BuildNavBar(AParent: TControl);
var
  LNavBar: TS4YFlexBox;
  LLogo: TRectangle;
  LSpacer: TControl;   // empty control used as a spacer
  LLoginButton: TButton;
  LSignupButton: TButton;
  LLogoItem: TS4YFlexItem;
  LSpacerItem: TS4YFlexItem;
begin
  LNavBar := TS4YFlexBox.Create(AParent.Owner);
  LNavBar.Parent := AParent;
  LNavBar.Align := TAlignLayout.Top;
  LNavBar.Height := 56;
  LNavBar.Direction := fdRow;
  LNavBar.AlignItems := aiCenter;
  LNavBar.ColumnGap := 8;
  LNavBar.Padding.Left := 16;
  LNavBar.Padding.Right := 16;

  // Logo: fixed width of 120px, it neither grows nor shrinks
  LLogo := TRectangle.Create(LNavBar);
  LLogo.Width := 120;
  LLogo.Height := 32;
  LLogo.Parent := LNavBar;
  LLogoItem := LLogo.Parent as TS4YFlexItem;
  LLogoItem.FlexGrow := 0;
  LLogoItem.FlexShrink := 0;
  LLogoItem.FlexBasis := 120;
  LLogoItem.FlexBasisUnit := fbuPixel;

  // Spacer: it grows to fill the central space
  LSpacer := TControl.Create(LNavBar);
  LSpacer.Width := 0;
  LSpacer.Height := 1;
  LSpacer.Parent := LNavBar;
  LSpacerItem := LSpacer.Parent as TS4YFlexItem;
  LSpacerItem.FlexGrow := 1;

  // Buttons on the right: automatic size (auto basis)
  // No explicit flex property = grow:0, shrink:1, basis:auto (CSS default)
  LLoginButton := TButton.Create(LNavBar);
  LLoginButton.Text := 'Login';
  LLoginButton.Width := 80;
  LLoginButton.Height := 36;
  LLoginButton.Parent := LNavBar;

  LSignupButton := TButton.Create(LNavBar);
  LSignupButton.Text := 'Sign up';
  LSignupButton.Width := 90;
  LSignupButton.Height := 36;
  LSignupButton.Parent := LNavBar;
end;
```

Note: the size of the control must be set **before** `Parent`, because the item
takes position and size of the control at the moment of the wrapping.

### Example 2 — Card grid with wrap

Equivalent CSS:

```css
.grid {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-content: flex-start;
}
.card { flex: 0 0 200px; height: 150px; }
```

```delphi
procedure BuildCardGrid(AParent: TControl);
var
  LGrid: TS4YFlexBox;
  LCard: TRectangle;
  LItem: TS4YFlexItem;
  LIndex: Integer;
begin
  LGrid := TS4YFlexBox.Create(AParent.Owner);
  LGrid.Parent := AParent;
  LGrid.Align := TAlignLayout.Client;
  LGrid.Wrap := fwWrap;
  LGrid.AlignContent := acFlexStart;
  LGrid.ColumnGap := 16;
  LGrid.RowGap := 16;
  LGrid.Padding.Left := 16;
  LGrid.Padding.Top := 16;
  LGrid.Padding.Right := 16;

  for LIndex := 1 to 9 do
  begin
    LCard := TRectangle.Create(LGrid);
    LCard.Width := 200;
    LCard.Height := 150;
    LCard.Parent := LGrid;

    // Every card has a fixed basis of 200px; it neither grows nor shrinks
    LItem := LCard.Parent as TS4YFlexItem;
    LItem.FlexGrow := 0;
    LItem.FlexShrink := 0;
    LItem.FlexBasis := 200;
    LItem.FlexBasisUnit := fbuPixel;
  end;
end;
```

### Example 3 — Sidebar (column) with a "push to bottom" spacer

Equivalent CSS:

```css
.sidebar {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.menu-item        { flex: 0 0 40px; }
.menu-item.active { flex: 0 0 40px; }
.spacer           { flex: 1; }
.footer-item      { flex: 0 0 40px; }
```

```delphi
procedure BuildSidebar(AParent: TControl);
var
  LSidebar: TS4YFlexBox;
  LDashboardButton: TButton;
  LUsersButton: TButton;
  LReportsButton: TButton;
  LSpacer: TControl;
  LLogoutButton: TButton;
begin
  LSidebar := TS4YFlexBox.Create(AParent.Owner);
  LSidebar.Parent := AParent;
  LSidebar.Align := TAlignLayout.Left;
  LSidebar.Width := 200;
  LSidebar.Direction := fdColumn;
  LSidebar.RowGap := 4;
  LSidebar.Padding.Left := 8;
  LSidebar.Padding.Right := 8;
  LSidebar.Padding.Top := 8;
  LSidebar.Padding.Bottom := 8;

  LDashboardButton := TButton.Create(LSidebar);
  LDashboardButton.Text := 'Dashboard';
  LDashboardButton.Height := 40;
  LDashboardButton.Parent := LSidebar;

  LUsersButton := TButton.Create(LSidebar);
  LUsersButton.Text := 'Users';
  LUsersButton.Height := 40;
  LUsersButton.Parent := LSidebar;

  LReportsButton := TButton.Create(LSidebar);
  LReportsButton.Text := 'Reports';
  LReportsButton.Height := 40;
  LReportsButton.Parent := LSidebar;

  // Elastic spacer that pushes Logout to the bottom
  LSpacer := TControl.Create(LSidebar);
  LSpacer.Height := 0;
  LSpacer.Parent := LSidebar;
  (LSpacer.Parent as TS4YFlexItem).FlexGrow := 1;

  // Logout always stays at the bottom
  LLogoutButton := TButton.Create(LSidebar);
  LLogoutButton.Text := 'Logout';
  LLogoutButton.Height := 40;
  LLogoutButton.Parent := LSidebar;
end;
```

### Example 4 — align-self for single items

`AlignSelf` overrides `AlignItems` of the container on the single item.

```delphi
procedure BuildMixedAlign(AParent: TControl);
var
  LBox: TS4YFlexBox;
  LRectangles: array[0..3] of TRectangle;
  LAlignments: array[0..3] of TAlignSelf;
  LIndex: Integer;
begin
  // Height 120: first at the top, second in the middle, third at the bottom,
  // fourth stretched to the whole height
  LBox := TS4YFlexBox.Create(AParent.Owner);
  LBox.Parent := AParent;
  LBox.Align := TAlignLayout.Top;
  LBox.Height := 120;
  LBox.Direction := fdRow;
  LBox.AlignItems := aiFlexStart;  // default of the container
  LBox.ColumnGap := 8;
  LBox.Padding.Left := 8;

  LAlignments[0] := asFlexStart;  // redundant (same as the container)
  LAlignments[1] := asCenter;
  LAlignments[2] := asFlexEnd;
  LAlignments[3] := asStretch;    // stretches to the whole height

  for LIndex := 0 to 3 do
  begin
    LRectangles[LIndex] := TRectangle.Create(LBox);
    LRectangles[LIndex].Width := 60;
    LRectangles[LIndex].Height := 40;
    LRectangles[LIndex].Parent := LBox;
    (LRectangles[LIndex].Parent as TS4YFlexItem).AlignSelf := LAlignments[LIndex];
  end;
end;
```

### Example 5 — Order to reorder without changing the order of the children

```delphi
procedure BuildOrderExample(AParent: TControl);
var
  LBox: TS4YFlexBox;
  LButtonA: TButton;
  LButtonB: TButton;
  LButtonC: TButton;
begin
  // Creation order: A, B, C
  // Visual order with Order: C(0), A(1), B(2)
  LBox := TS4YFlexBox.Create(AParent.Owner);
  LBox.Parent := AParent;
  LBox.Align := TAlignLayout.Top;
  LBox.Height := 50;
  LBox.Direction := fdRow;
  LBox.ColumnGap := 8;

  LButtonA := TButton.Create(LBox);
  LButtonA.Text := 'A';
  LButtonA.Width := 60;
  LButtonA.Height := 40;
  LButtonA.Parent := LBox;
  (LButtonA.Parent as TS4YFlexItem).Order := 1;

  LButtonB := TButton.Create(LBox);
  LButtonB.Text := 'B';
  LButtonB.Width := 60;
  LButtonB.Height := 40;
  LButtonB.Parent := LBox;
  (LButtonB.Parent as TS4YFlexItem).Order := 2;

  LButtonC := TButton.Create(LBox);
  LButtonC.Text := 'C';
  LButtonC.Width := 60;
  LButtonC.Height := 40;
  LButtonC.Parent := LBox;
  (LButtonC.Parent as TS4YFlexItem).Order := 0;  // C appears first
end;
```

---

## Design time

There are no dedicated windows or editors: everything is done in the designer and
in the Object Inspector.

1. Drag a control (from the palette or from another container) into a
   `TS4YFlexBox`: the designer creates a `TS4YFlexItem` and inserts the control
   into it.
2. Select the `TS4YFlexItem` (in the Structure view or by clicking on the border
   of the item) to change `FlexGrow`, `FlexShrink`, `FlexBasis`, `FlexBasisUnit`,
   `AlignSelf` and `Order` in the Object Inspector.
3. To put several controls in one position of the flexbox, insert a layout or a
   panel and drag the controls into that container.

### Reordering the items

The reliable way to change the order of the items is the **`Index`** property of
the item in the Object Inspector (it starts from 0; the order is saved anyway,
because it is the order of the objects in the file).

Dragging an item over another one in the Structure view puts the item back into
the flexbox and inserts it before the target: the form shows the new order, but
**the Structure view is not updated** (it keeps the old order until the form is
reopened). The FMX designer does not let the package force its update:
`Modified`/`SelectComponent` and a custom sprig (`RegisterSprigType`) were tried
without success.

The drop **between** two items (the single insertion line) does not move anything
either: a complete log of the IDE (hooks on `SetParent`, `DoAddObject`,
`DoInsertObject`, `DoRemoveObject`, `ChangeOrder`, `SetChildOrder` and designer
notifications) showed that the IDE calls nothing of our objects, neither for that
drop nor for Control > Bring to Front / Send to Back. The FMX designer does not
implement `SetChildOrder` for FMX components. The topic is suspended; the idea not
tried yet is a context menu entry (`IComponentEditor`: Move first/before/after/last).

---

## Known limits

- The automatic width is the design one, which adapts (stretch and fit-content);
  the width calculated from the content (for example a `TLabel` with `AutoSize`)
  needs `FitContent = True` on the item.
- `FlexBasis` and `FlexGrow` apply on the main axis: going from row to column (for
  example with a breakpoint) a basis of 320 px becomes a height: this is fixed with
  the item overrides of the breakpoint (see "Item overrides").
- A content with automatic height does not fill the item when this is stretched or
  made to grow by the layout (in CSS it would, because it would be the item).
- Reordering by dragging: the Structure view is not updated (see Design time).
- Forms saved before the automatic height are converted when opened (content from
  `Client` to `Top`).

---

## Running the tests

```delphi
// In a DUnitX console project:
uses Soft4You.FMX.Controls.FlexBox.Engine.Tests;
// Or use the DUnitX GUI runner
```

The unit is in `Tests\FlexBox`. The 49 tests cover: row/column, justify-content
(all the values), flex-grow, flex-shrink, flex-basis (auto/px/%), align-items,
align-self, order, wrap/wrap-reverse, gap, align-content, reverse, automatic and
explicit sizes and single line (`SingleLineFillsContainer`). They test the engine
only (`TFlexEngine`), not the components.

---

## Version and compatibility

- **Delphi**: 11 Alexandria, 12 Athens (recommended)
- **Delphi 10.4**: compatible, it requires removing the `inline var` in
  `Soft4You.FMX.Controls.FlexBox.Engine.Tests.pas`
- **Specification**: W3C CSS Flexbox Level 1
  https://www.w3.org/TR/css-flexbox-1/
