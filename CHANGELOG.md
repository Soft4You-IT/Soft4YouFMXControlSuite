# Changelog

The changes of each release of the Soft4You FMX Control Suite, the newest first. The version numbers are explained in the section "Versioning" of the [README](README.md); each release has the sections that apply among **Added**, **Changed**, **Fixed** and **Breaking changes** (changes that can stop existing projects from compiling or forms from loading).

## Unreleased

### Added

- `TS4YStepProgressBar`: progress indicator made of steps along a horizontal or vertical line, with completed, current, pending and failed steps, an animated line, steps that the user can select with the mouse and the keyboard, and a look that comes from a style, where the markers and the line can have any shape. The size of the markers, also different for each state, their position on the line or beside it, the spaces between markers, line and labels, and the visibility of the line can be set.

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
