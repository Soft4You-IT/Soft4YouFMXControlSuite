# Changelog

The changes of each release of the Soft4You FMX Control Suite, the newest first. The version numbers are explained in the section "Versioning" of the [README](README.md); each release has the sections that apply among **Added**, **Changed**, **Fixed** and **Breaking changes** (changes that can stop existing projects from compiling or forms from loading).

## Unreleased

### Added

- `TS4YStepProgressBar`: progress indicator made of steps along a horizontal or vertical line, with completed, current, pending and failed steps, an animated line that can also show the progress inside the current step, steps that the user can select with the mouse and the keyboard, with a halo around the step under the mouse pointer, and a look that comes from a style, where the markers and the line can have any shape. The size of the markers, also different for each state, their position on the line or beside it, the spaces between markers, line and labels, and the visibility of the line can be set. The list of the steps has always a first and a last step, and the steps are edited in the IDE with an editor of their own, opened also with a double click on the control. Each step can have a look of its own in the states chosen, with its marker settings, a part of the style for the marker and a text of the style for the caption; the first and the last step of a new control have a start and an end marker.
- `TS4YLinearGauge`: gauge drawn as a horizontal or vertical bar that fills with a value in a range, with a caption and the value written on one side of the bar. A large change of the value is animated, the value has a format of its own or a text given by an event, and the look comes from a style, where the track and the fill can have any shape; properties can replace their brushes.
- `TS4YCircularGauge`: gauge drawn as a ring, an open arc or a half circle that fills with a value in a range, with the value and the caption in the middle. The start and the length of the arc can be set; it has the same range, animation, format of the value, brushes and style mechanism as `TS4YLinearGauge`, and the arcs of the style give the brush and the round or flat ends.

### Fixed

- `TS4YBadge` and `TS4YExpander` use a style named `S4YBadgeStyle` or `S4YExpanderStyle` in the style book of the form or in the active style, instead of always the style linked into the package. A `StyleLookup` that names no style makes them use their own style: before, they were left without one.

## 1.0.0 - 2026-10-29

First public release.

### Added

- `TS4YHTMLEditor`: WYSIWYG HTML editor with formatting, lists, tables, images, links, placeholders, find and replace.
- `TS4YFlexBox` and `TS4YFlexItem`: container that lays out its items with the CSS Flexbox model (W3C Level 1).
- `TS4YBlockScrollBox`: scroll box that stacks its children as the blocks of the CSS flow; a `TS4YFlexBox` in it behaves as a block of a web page.
- `TS4YBadge`: badge like the notification counter of a smartphone icon, with a number or a short text.
- `TS4YExpander`: collapsible panel with an icon in the header, a height animation, a click on the whole header and a badge counter.
- `TS4YColorSelector`: foreground and background color swatches, like in the drawing programs.
- Runtime and design-time packages for Delphi 11, 12 and 13, also for the 64-bit IDE of Delphi 12.3 and newer.
- The IDE splash screen and About box show the version of the installed suite.
