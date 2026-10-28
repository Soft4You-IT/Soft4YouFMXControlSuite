# Changelog

The changes of each release of the Soft4You FMX Control Suite, the newest first. The version numbers are explained in the section "Versioning" of the [README](README.md); each release has the sections that apply among **Added**, **Changed**, **Fixed** and **Breaking changes** (changes that can stop existing projects from compiling or forms from loading).

## 1.0.0 - unreleased

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

### Breaking changes

For projects that used the controls from the earlier private library of Soft4You:

- `TS4YColorSelector`: the types of the event are now `TS4YColorTarget` and `TS4YColorSelectEvent`, in the unit `Soft4You.FMX.Controls.ColorSelector.Types` (they were `TColorTarget` and `TOnColorSelect`). See [Upgrading from the private library](Docs/ColorSelector/README.md#upgrading-from-the-private-library).
- The resources with the styles of `TS4YBadge` and `TS4YExpander` are compiled by the packages into the folder `Resources`, which must be in the library path of the projects that use them.
