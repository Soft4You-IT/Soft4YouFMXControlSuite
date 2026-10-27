# TS4YBadge for FireMonkey

A badge like the notification counter of a smartphone icon: a small circle that shows a number, or a short text, over another control.

- **Numeric badge** (`BadgeStyle = bdgsNumeric`, the default): `CurrentValue` is shown inside a circle. With `CurrentValue = 0` the badge is hidden. Above `MaxValue` (default 99) it shows `MaxValue+`, for example `99+`.
- **Text badge** (`BadgeStyle = bdgsText`): `Text` is shown; with an empty text the badge is hidden.

The color, the border and the font can be customized, the badge can blink, and it can position itself on a corner or an edge of its parent control.

Unit: `Soft4You.FMX.Controls.Badge` (in `Sources\Badge`).

## Installation

`TS4YBadge` is part of the Soft4You FMX Control Suite. It is built into the runtime package `Soft4You.FMX.Controls.Suite`, and its registration into the design-time package `SuiteD`: see the README in the root of the repository. It appears in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\Badge` to the Delphi library path to compile your own projects with the unit.

## Files

| File | Content |
|---|---|
| `Sources\Badge\Soft4You.FMX.Controls.Badge.pas` | The control |
| `Sources\Badge\Soft4You.FMX.Controls.Badge.Register.pas` | Registration in the Tool Palette (design time) |
| `Sources\Badge\Soft4You.FMX.Controls.Badge.Win.rc` / `.Mac.rc` | Resource scripts that link the style as the resource `S4YBadgeStyle` |
| `Sources\Badge\Soft4You.FMX.Controls.Badge.Win.style` / `.Mac.style` | Default style of the badge (the two are identical) |
| `Graphics\Badge\TS4YBadge.svg` | Vector master of the icon of the Tool Palette |
| `Graphics\Badge\TS4YBadge.bmp`, `BadgeDesign.rc` | Icon of the Tool Palette (24x24 bitmap) and the resource script that links it |

The style resource is linked into the package (`{$R *.win.res}` or `{$R *.mac.res}` in the unit), so the badge looks the same without any other file. With another `StyleLookup` the badge uses that style instead.

## Properties

| Property | Default | Meaning |
|---|---|---|
| `BadgeStyle` | `bdgsNumeric` | `bdgsNumeric` shows `CurrentValue`, `bdgsText` shows `Text` |
| `CurrentValue` | 0 | Value of the counter; with 0 the numeric badge is hidden |
| `MaxValue` | 99 | Above it the badge shows `MaxValue+` |
| `Text` | empty | Text of a `bdgsText` badge |
| `AutoRadius` | `True` | The corner radius follows the height, so a short value gives a circle and a longer one a pill |
| `Fill` | red | Background of the badge |
| `Stroke` | white, 1 | Border of the badge |
| `StyledBrushes` | `[bdgbFill, bdgbStroke]` | Which of the two brushes come from the style; changing `Fill` or `Stroke` in the Object Inspector switches the matching one off |
| `TextSettings`, `StyledSettings` | white text | Font, color and alignment of the text |
| `BlinkSettings.Enabled` / `Interval` | `False` / 1000 ms | Blinking of the badge |
| `AutoPosition.AutoPosition` | `bdgpNone` | Places the badge on one of nine positions of its parent: `bdgpUpLeft`, `bdgpUpCenter`, `bdgpUpRight`, `bdgpCenterLeft`, `bdgpCenter`, `bdgpCenterRight`, `bdgpBottomLeft`, `bdgpBottomCenter`, `bdgpBottomRight` |
| `AutoPosition.OffsetX` / `OffsetY` | `bdpoEdge` | Where the badge sits compared to the edges of the parent: `bdpoInner` (inside), `bdpoEdge` (centered on the edge), `bdpoOuter` (outside) |

The usual `TControl` properties (`Align`, `Anchors`, `Position`, `Size`, `Margins`, `Opacity`, `Visible`, `HitTest`, `RotationAngle`, `Scale`, `PopupMenu`, `StyleLookup`) are published too.

The badge is never narrower than tall, and it widens with a longer text.

## Example

A counter over the top right corner of a button:

```delphi
uses
  FMX.StdCtrls,
  Soft4You.FMX.Controls.Badge;

procedure TMainForm.ShowUnreadCount(Count: Integer);
begin
  if Badge = nil then
  begin
    Badge := TS4YBadge.Create(Self);
    Badge.Parent := MessagesButton;
    Badge.AutoPosition.AutoPosition := bdgpUpRight;
    Badge.MaxValue := 9;
  end;

  Badge.CurrentValue := Count;   // 0 hides the badge, 12 shows "9+"
end;
```

In the designer, drop a `TS4YBadge` on the form (or on a control), set `AutoPosition` and `CurrentValue`.

## Demo

`Demos\Badge\S4YBadgeDemo.dproj` (also part of the project group `Demos\Soft4You.FMX.Controls.Demos.groupproj`) is a small application with a button and a label that carry a badge each: a numeric counter on the button and a green `NEW` text badge on the label. The panel on the right changes `CurrentValue`, `MaxValue`, `BadgeStyle`, `Text`, `AutoPosition`, the offset, `BlinkSettings` and `AutoRadius` of the badge of the button at run time. Install the suite packages first.

## Notes

- The badge streams its `StyledBrushes` after `Fill` and `Stroke`: a form saved with an explicit `StyledBrushes` keeps it when loaded.
- `ResultingTextSettings` and `DefaultTextSettings` are public read-only properties, useful for descendants.
