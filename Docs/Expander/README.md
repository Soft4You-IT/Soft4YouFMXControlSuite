# TS4YExpander for FireMonkey

An expander (a collapsible panel with a header) that extends the standard FMX `TExpander` with an icon in the header, an optional height animation, a click on the whole header and a badge counter on the header.

Unit: `Soft4You.FMX.Controls.Expander` (in `Sources\Expander`). It uses `TS4YBadge` (`Soft4You.FMX.Controls.Badge`) for the badge, so the two controls are always installed together.

## Installation

`TS4YExpander` is part of the Soft4You FMX Control Suite. It is built into the runtime package `Soft4You.FMX.Controls.Suite`, and its registration into the design-time package `SuiteD`: see the README in the root of the repository. It appears in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\Expander` (and `Sources\Badge`) to the Delphi library path to compile your own projects with the unit.

## Files

| File | Content |
|---|---|
| `Sources\Expander\Soft4You.FMX.Controls.Expander.pas` | The control |
| `Sources\Expander\Soft4You.FMX.Controls.Expander.Register.pas` | Registration in the Tool Palette (design time) |
| `Sources\Expander\Soft4You.FMX.Controls.Expander.Win.rc` / `.Mac.rc` | Resource scripts that link the style as the resource `S4YExpanderStyle` |
| `Sources\Expander\Soft4You.FMX.Controls.Expander.Win.style` / `.Mac.style` | Default style of the expander (the two are identical) |
| `Graphics\Expander\TS4YExpander.svg` | Vector master of the icon of the Tool Palette |
| `Graphics\Expander\TS4YExpander.bmp`, `ExpanderDesign.rc` | Icon of the Tool Palette (24x24 bitmap) and the resource script that links it |

The style resource is linked into the package (`{$R *.win.res}` or `{$R *.mac.res}` in the unit), so the control looks the same without any other file. The style has the elements the control looks for by name: `header` (the clickable header), `icon` (a `TGlyph` for the icon) and `badge` (a `TS4YBadge`). With another `StyleLookup` the control uses that style instead, and the elements that it does not have are simply not shown.

## What it adds to TExpander

| Property | Default | Meaning |
|---|---|---|
| `ClickOnHeader` | `True` | A click on the header expands or collapses the control |
| `Animated` | `False` | The change of height is animated |
| `AnimationDuration` | 0.25 | Duration of the animation, in seconds |
| `ExpandedHeight` | | Height of the control when expanded. It is saved in the form file only while the control is collapsed: a collapsed control is streamed with the height of its header, and without this value the height to restore on expansion would be lost |
| `Images`, `ImageIndex` | none, -1 | Image list and image shown in the icon of the header |
| `ShowIcon` | `True` | Shows or hides the icon |
| `BadgeSettings` | see below | Badge of the header |

The properties of `TExpander` (`IsExpanded`, `Text`, `Align`, `Margins`, ...) work as usual.

### BadgeSettings

A small set of settings for the badge of the header. The expander keeps them and pushes them to the real `TS4YBadge` of the style whenever the style is applied, so they can be set at any moment, also at design time before the style exists.

| Property | Default | Meaning |
|---|---|---|
| `Style` | `bdgsNumeric` | `bdgsNumeric` shows `CurrentValue`, `bdgsText` shows `Text` |
| `CurrentValue` | 0 | Counter shown in a numeric badge |
| `MaxValue` | 99 | Above it the badge shows `MaxValue+` |
| `Text` | empty | Text of a `bdgsText` badge |
| `Visible` | `False` | Shows the badge |
| `HitTest` | `False` | The badge reacts to the mouse (needed for `OnClick` and `PopupMenu`) |
| `PopupMenu` | none | Menu of the badge |
| `BlinkSettings` | off | Blinking of the badge, as in `TS4YBadge` |
| `OnClick`, `OnChange` | | Events of the badge |

## Example

An expander with a counter that opens with an animation:

```delphi
uses
  Soft4You.FMX.Controls.Expander;

procedure TMainForm.PrepareExpander;
begin
  OrdersExpander.Text := 'Orders';
  OrdersExpander.Animated := True;
  OrdersExpander.BadgeSettings.Visible := True;
  OrdersExpander.BadgeSettings.CurrentValue := 12;
  OrdersExpander.IsExpanded := False;
end;
```

In the designer, drop a `TS4YExpander` on the form and put the content (a layout, a list, ...) inside it; set `Text`, `Animated` and `BadgeSettings` in the Object Inspector.

## Demo

`Demos\Expander\S4YExpanderDemo.dproj` (also part of the project group in `Packages\D11`) is a small application with three expanders: *Orders* with a badge counter on the header, *Shipping* and *History*, which starts collapsed. The panel on the right changes `Animated`, `AnimationDuration` and `ClickOnHeader` of the three expanders, the visibility and the value of the badge of *Orders*, and expands or collapses all of them. Install the suite packages first.
