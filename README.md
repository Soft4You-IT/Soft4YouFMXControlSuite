# Soft4You FMX Control Suite

A suite of native controls for Delphi FireMonkey (FMX), by Soft4You. 100% Delphi: no WebBrowser, no COM/OLE and no third-party dependency is required.

Supported platforms: **Windows, macOS, iOS, Android**. Developed and tested on Windows with Delphi 11.3 (RAD Studio 22.0); the packages have also been built and installed on Delphi 12 and 13.1.

## The controls

| Control | Description | Documentation |
|---|---|---|
| `TS4YHTMLEditor` | WYSIWYG HTML editor: formatting, lists, tables, images, links, placeholders, find and replace | [Docs\HTMLEditor](Docs/HTMLEditor/README.md) |
| `TS4YFlexBox`, `TS4YFlexItem` | Container that lays out its items with the CSS Flexbox model (W3C Level 1) | [Docs\FlexBox](Docs/FlexBox/README.md) |
| `TS4YBlockScrollBox` | Scroll box that stacks its children as the blocks of the CSS flow (`display: block`); a `TS4YFlexBox` in it behaves as a block of a web page | [Docs\BlockScrollBox](Docs/BlockScrollBox/README.md) |
| `TS4YBadge` | Badge like the notification counter of a smartphone icon: a number or a short text over another control | [Docs\Badge](Docs/Badge/README.md) |
| `TS4YExpander` | Collapsible panel with an icon in the header, a height animation, a click on the whole header and a badge counter | [Docs\Expander](Docs/Expander/README.md) |

All the controls are built into the same two packages and appear in the Tool Palette page **Soft4You FMX Controls Suite**. `TS4YExpander` uses `TS4YBadge`, so the two are always installed together.

---

## Repository layout

| Folder | Content |
|---|---|
| `Sources\HTMLEditor` | Units of the HTML editor (`.pas`) |
| `Sources\FlexBox` | Units of the FlexBox control (`TS4YFlexBox`, `TS4YFlexItem`) |
| `Sources\BlockScrollBox` | Units of the BlockScrollBox control (`TS4YBlockScrollBox`) and the interfaces of the block flow, used by the FlexBox too |
| `Sources\Badge` | Units of the Badge control (`TS4YBadge`), with its styles and resource scripts |
| `Sources\Expander` | Units of the Expander control (`TS4YExpander`), with its styles and resource scripts |
| `Sources\Design` | Design-time unit shared by all the controls of the suite (IDE splash screen and About box) |
| `Packages\D11`, `D12`, `D13` | Runtime and design-time packages and their project group, one folder for each Delphi version (11, 12, 13) |
| `Resources` | Resources compiled by the packages from the `.rc` files (styles of the Badge and the Expander, Tool Palette icons, version information); created when the packages are built, not in the repository |
| `Graphics` | Source artwork: one folder for each control with its Tool Palette icon (24x24 bitmap, its SVG master and the resource script `XxxDesign.rc` compiled into the design-time package); `Soft4YouFMXControlSuite.svg` is the master of the icon of the suite, shown in the IDE splash screen and About box (`S4YSplash.bmp` and `S4YAbout.bmp`, 24x24), compiled with `Soft4You.FMX.Controls.SuiteD.rc` into `Soft4You.FMX.Controls.SuiteD.dcr` of each `Packages` folder |
| `Demos\HTMLEditor` | Sample FMX applications: `Desktop` (full demo), `Mobile` (mobile test app, work in progress), `Test` (HTML test files), `Icons` (toolbar icons of the desktop demo) |
| `Demos\FlexBox` | Sample FMX dashboard built with `TS4YFlexBox` |
| `Demos\BlockScrollBox` | Sample FMX application with `TS4YBlockScrollBox`: a page of blocks with a flexbox of cards, and the settings to make them overflow, add blocks and change their order |
| `Demos\Badge` | Sample FMX application with `TS4YBadge`: a counter and a text badge, and the settings to change them |
| `Demos\Expander` | Sample FMX application with three `TS4YExpander`: a badge on the header, the animation and the header click |
| `Docs\HTMLEditor` | Documentation of the HTML editor: [`README.md`](Docs/HTMLEditor/README.md) (installation, properties, methods, events), [`DeveloperGuide.md`](Docs/HTMLEditor/DeveloperGuide.md) (how to use the control, behaviour and warnings), `Architecture.md` (internals) |
| `Docs\FlexBox` | Documentation of the FlexBox control: [`README.md`](Docs/FlexBox/README.md) (installation, properties, examples), analysis and roadmap |
| `Docs\BlockScrollBox` | Documentation of the BlockScrollBox control: [`README.md`](Docs/BlockScrollBox/README.md) |
| `Docs\Badge` | Documentation of the Badge control: [`README.md`](Docs/Badge/README.md) |
| `Docs\Expander` | Documentation of the Expander control: [`README.md`](Docs/Expander/README.md) |
| `Tests\FlexBox` | DUnitX tests of the FlexBox layout engine |
| `Tests\BlockScrollBox` | DUnitX tests of the block flow of `TS4YBlockScrollBox` |

---

## Requirements

- Delphi 11 Alexandria or newer with FireMonkey (FMX).
  The project files in `Packages\D12` and `Packages\D13` are copies of the Delphi 11 ones: the IDE upgrades them the first time it opens them. They have been built and installed on Delphi 12 and on Delphi 13.1.
- Optional: [Skia4Delphi](https://github.com/skia4delphi/skia4delphi) (MIT license), only for the unit `Soft4You.FMX.Controls.HTMLEditor.SVGRenderer.Skia` that renders SVG images (see [SVG images](Docs/HTMLEditor/README.md#svg-images)). The packages do not require it; its platform support (for example Delphi 12 for Android) applies to that unit.

---

## Installation

The suite has two packages, in a folder for each version of Delphi (`Packages\D11`, `D12`, `D13`):

| Package | Type | What to do |
|---|---|---|
| `Soft4You.FMX.Controls.Suite` | Runtime | **Build** (do not install) |
| `Soft4You.FMX.Controls.SuiteD` | Design time | **Build** and **Install** |

1. Open `Packages\D11\Soft4You.FMX.Controls.Suite.groupproj` (use `D12` or `D13` for those versions of Delphi). The group contains the two packages; the demos and the tests have a group of their own, `Demos\Soft4You.FMX.Controls.Demos.groupproj` and `Tests\Soft4You.FMX.Controls.Tests.groupproj`, the same for every version of Delphi.
2. Build the runtime package `Soft4You.FMX.Controls.Suite`.
3. Build and install the design-time package `Soft4You.FMX.Controls.SuiteD`. It registers the controls, their property editors and the splash screen and About box of the suite.
   The 64-bit IDE (Delphi 12.3 and newer) loads only packages built for Windows 64-bit: select the **Windows 64-bit** platform for both packages, build them, and install `Soft4You.FMX.Controls.SuiteD` from the 64-bit IDE. The 32-bit IDE needs the **Windows 32-bit** build, as before.
4. Add the folders of the controls you use (`Sources\HTMLEditor`, `Sources\FlexBox`, `Sources\BlockScrollBox`, `Sources\Badge`, `Sources\Expander`) to the Delphi library path; the FlexBox also needs `Sources\BlockScrollBox`, to compile your own projects with their units. Add also the folder `Resources`: the packages compile into it the resources with the styles of the Badge and the Expander, so build the packages before your projects. The demos find the units of the repository through the search path of their project.

The compiled units and the demo executables are written in `Bin`; the `.bpl` and `.dcp` files of the packages go to the shared folders of the IDE.

---

## Demos and tests

Each control has a sample application in `Demos\<Control>`. Install the packages first. The HTML editor also has a mobile test app (`Demos\HTMLEditor\Mobile`, work in progress). The layout engine of `TS4YFlexBox` is covered by DUnitX tests (`Tests\FlexBox`), and so is the block flow of `TS4YBlockScrollBox` (`Tests\BlockScrollBox`).

---

## Versioning

The suite has a single version, the same for the two packages and for every version of Delphi. It is written in the version information of the packages (the properties of the `.bpl` file) as `Major.Minor.Release.Build`:

| Part | Changes when |
|---|---|
| `Major` | A change is not compatible with the previous version: for example a published property renamed or removed, which stops the forms that use it from loading |
| `Minor` | New controls or features. **Even** in the releases, **odd** in the development builds |
| `Release` | A release with fixes only |
| `Build` | Always `0` |

The releases are tagged on `main`, and their packages open in the **Release** configuration, with the version of the release (for example `1.2.0.0`). The `develop` branch opens in the **Debug** configuration, with an odd `Minor` (for example `1.3.0.0`): a package with an odd `Minor` is a development build, not a release. The IDE splash screen and About box show the version of the installed package, followed by "(development)" for a development build (the Debug configuration sets the "Debug build" flag of the version information). The changes that are not compatible are listed under "Breaking changes" in the notes of each release.

---

## License

Released under the **Mozilla Public License 2.0** (MPL-2.0) — see [LICENSE](LICENSE).

MPL-2.0 is a file-level copyleft license:

- you may use the controls, unmodified or modified, in open source and closed source applications, commercial or not;
- if you modify the source files of these controls and distribute the result (in source or binary form), you must make the source of your modified files available under the MPL-2.0, so that improvements flow back to the original component;
- your own files that merely use the controls are not affected and may stay under any license.

Copyright (c) 2023-2026 **Carlo Marona (Soft4You)**. The suite started in 2026; the Badge comes from earlier code (2023).

---

## Code documentation

The public API of every control is documented with DocXML comments (`/// <summary>`), which Delphi shows as Help Insight tooltips in the code editor. Behaviour and warnings that do not fit in a tooltip are in the documentation of each control, linked in the table above.

---

## AI-assisted development

The suite is the work of Carlo Marona (Soft4You), who designs and directs it. Artificial intelligence was used for part of the controls, through [Claude](https://www.anthropic.com/claude) (Anthropic) and Claude Code:

- `TS4YHTMLEditor` and `TS4YFlexBox` were developed with the assistance of Claude from the start.
- `TS4YBadge` and `TS4YExpander` were first written by Carlo Marona and later refined with the assistance of Claude, mainly `TS4YExpander`.

---

## Credits

- [Skia4Delphi](https://github.com/skia4delphi/skia4delphi) — MIT license, used by the optional SVG renderer unit.
- Demo toolbar icons: [Google Material Symbols](https://fonts.google.com/icons) — Apache License 2.0.
