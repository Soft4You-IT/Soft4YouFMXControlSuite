# TS4YHTMLEditor — Soft4You FMX HTML Editor

WYSIWYG HTML editor component for Delphi FireMonkey (FMX). 100% native Delphi — no WebBrowser and no COM/OLE dependencies. The only third-party dependency is [Skia4Delphi](https://github.com/skia4delphi/skia4delphi), used to render SVG images.

Supported platforms: **Windows, macOS, iOS, Android**. Developed and tested on Windows with Delphi 11.3 (RAD Studio 22.0).

---

## Repository layout

| Folder | Content |
|---|---|
| `Sources` | All component units (`.pas`) |
| `Packages` | Runtime and design-time packages, project group |
| `Demo` | Sample FMX application |
| `Docs` | Additional documentation: [`DeveloperGuide.md`](Docs/DeveloperGuide.md) (how to use the control, behaviour and warnings), `Architecture.md` (internals, in Italian) |

---

## Requirements

- Delphi 11 Alexandria or newer with FireMonkey (FMX) for Windows, macOS and iOS; Delphi 12 Athens or newer for Android. These limits come from Skia4Delphi's platform support.
- [Skia4Delphi](https://github.com/skia4delphi/skia4delphi) (MIT license), installed in the IDE. The runtime package requires `Skia.Package.FMX` and `Skia.Package.RTL`.

---

## License

Released under the **Mozilla Public License 2.0** (MPL-2.0) — see [LICENSE](LICENSE).

MPL-2.0 is a file-level copyleft license:

- you may use the component, unmodified or modified, in open source and closed source applications, commercial or not;
- if you modify the source files of this component and distribute the result (in source or binary form), you must make the source of your modified files available under the MPL-2.0, so that improvements flow back to the original component;
- your own files that merely use the component are not affected and may stay under any license.

Original author: **Carlo Marona (Soft4You)** — project started in 2026.

---

## Code documentation

The public API (the `TS4YHTMLEditor` control, its events and the types in `Soft4You.HTML.Types`) is documented with DocXML comments (`/// <summary>`), which Delphi shows as Help Insight tooltips in the code editor. For behaviour and warnings that do not fit in a tooltip, read the [Developer Guide](Docs/DeveloperGuide.md).

---

## Architecture

| Layer | Class | Unit |
|---|---|---|
| Document model | `TS4YHTMLDocument` / `TS4YHTMLParagraph` / `TS4YHTMLRun` | `Soft4You.HTML.Document` |
| Types & styles | `TS4YHTMLTextStyle`, `TS4YHTMLBlockType`, `TS4YDocumentPosition`, `TS4YLayoutFragment` | `Soft4You.HTML.Types` |
| HTML parser | `TS4YHTMLParser` | `Soft4You.HTML.Parser` |
| HTML generator | `TS4YHTMLGenerator` | `Soft4You.HTML.Generator` |
| Image export (copy on save) | `TS4YImageExporter` | `Soft4You.HTML.ImageExporter` |
| Layout engine | `TS4YLayoutEngine` | `Soft4You.FMX.Controls.HTMLEditor` |
| Editor control | `TS4YHTMLEditor` | `Soft4You.FMX.Controls.HTMLEditor` |
| Clipboard (HTML) | `TS4YHTMLClipboard` | `Soft4You.FMX.Clipboard.Html` |
| Emoji catalogue | `TS4YEmojiData` | `Soft4You.Unicode.EmojiData` |

---

## Installation

0. Install Skia4Delphi (see [Requirements](#requirements)).
1. Open `Packages\S4YFMXHTMLEditor.dpk` (runtime package) and **Build** it.
2. Open `Packages\S4YFMXHTMLEditorD.dpk` (design-time package, registers the component and the HTML property editor) and **Build** and **Install** it.
3. `TS4YHTMLEditor` appears in the Tool Palette under the registered category.
4. Add the `Sources` folder to the Delphi library path (needed to compile the Demo and your own projects).
5. Add `Soft4You.FMX.Controls.HTMLEditor` to the `uses` clause of any unit that references the component programmatically.

---

## Quick Start

For how the control behaves, when events fire and what to be careful about, read the [Developer Guide](Docs/DeveloperGuide.md).

```delphi
uses
  Soft4You.FMX.Controls.HTMLEditor, Soft4You.HTML.Types;

// Set content
HTMLEditor.HTML := '<p>Hello <b>world</b>!</p>';

// Read back
ShowMessage(HTMLEditor.HTML);

// Full document (with <!DOCTYPE html> wrapper)
Memo1.Text := HTMLEditor.FullHTML;

// React to state changes (update toolbar buttons)
procedure TfrmMain.HTMLEditorStateChange(Sender: TObject; const State: TS4YEditorState);
begin
  btnBold.IsPressed        := State.IsBold;
  btnItalic.IsPressed      := State.IsItalic;
  btnOutdent.Enabled       := State.CanOutdent;
  cbFont.Text              := State.FontName;
  pnlFontColor.Color       := State.FontColor;
  pnlHighlight.Color       := State.BackgroundColor;
end;
```

---

## Supported HTML

### Block elements

| Tag | Description |
|---|---|
| `<p>` | Paragraph |
| `<h1>` … `<h6>` | Headings |
| `<blockquote>` | Indented quote |
| `<ul>` / `<ol>` / `<li>` | Unordered and ordered lists |
| `<hr>` | Horizontal rule |
| `<img>` | Inline image (a run inside the paragraph, so it can sit in the middle of a text) |
| `<table>` / `<tr>` / `<td>` / `<th>` | Tables, including `colspan` and `rowspan` |
| `<pre>` | Preformatted text |

### Inline elements

| Tag / attribute | Description |
|---|---|
| `<b>`, `<strong>` | Bold |
| `<i>`, `<em>` | Italic |
| `<u>` | Underline |
| `<s>`, `<del>`, `<strike>` | Strikethrough |
| `<sup>` | Superscript |
| `<sub>` | Subscript |
| `<span style="…">` | Inline style override |
| `<font face="…" size="…" color="…">` | Legacy font tag |
| `<a href="…">` | Hyperlink |
| `<br>` | Line break within paragraph |
| `<code>` | Inline code (rendered as preformatted) |

### CSS properties (inline style)

`font-family`, `font-size` (pt/px/em/%), `font-weight`, `font-style`, `text-decoration`, `color`, `background-color`, `text-align`

### HTML entities

`&amp;` `&lt;` `&gt;` `&quot;` `&apos;` `&nbsp;` `&copy;` `&reg;` `&trade;` `&mdash;` `&ndash;` `&hellip;` `&#N;` `&#xN;`

---

## Properties

### Published (Object Inspector)

| Property | Type | Default | Description |
|---|---|---|---|
| `HTML` | `string` | `''` | HTML content of the document body (fragment, no doctype) |
| `AutoLoadLocalImages` | `Boolean` | `True` | Load images whose `src` is a local file (relative or absolute path, `file:` URL). When `False` they are drawn as placeholders until `LoadLocalImages` is called |
| `AutoLoadRemoteImages` | `Boolean` | `True` | Load images whose `src` is `http://` or `https://`. When `False` they are drawn as placeholders until `LoadRemoteImages` is called |
| `BackgroundColor` | `TAlphaColor` | `claWhite` | Editor canvas background color |
| `DocumentPath` | `string` | `''` | Folder that relative image paths are resolved against when `ImagePathMode = ipmDocument`. Set by `LoadFromFile`; see [Images and files](#images-and-files) |
| `Font` | `TFont` | platform default | Default font for new text |
| `FontColor` | `TAlphaColor` | `claBlack` | Default text color, used where a run has no color of its own |
| `ImagePathMode` | `TS4YImagePathMode` | `ipmApplication` | How relative local image paths are resolved: `ipmApplication` (process working directory) or `ipmDocument` (relative to `DocumentPath`) |
| `Language` | `string` | `''` | Document language attribute (used in `FullHTML` export) |
| `LineSpacing` | `Single` | `1.0` | Line-height multiplier (1.0 = natural height, 1.5 = 1.5× line spacing) |
| `LocalImageAccess` | `TS4YLocalImageAccess` | `liaAnywhere` | Which local files images may be read from: `liaAnywhere` (any readable file) or `liaDocumentFolder` (only inside `DocumentPath`); see [Images and files](#images-and-files) |
| `ParagraphSpacing` | `Single` | `6.0` | Extra vertical space in px added between block elements |
| `PlaceholderAppearance` | `TS4YPlaceholderAppearance` | — | Visual style of placeholder chips |
| `PlaceholderPrefix` | `string` | `''` | Prefix that identifies a placeholder run in raw text |
| `PlaceholderSuffix` | `string` | `''` | Suffix that identifies a placeholder run in raw text |
| `PrettyHTML` | `Boolean` | `False` | Emit indented HTML from the generator |
| `ReadOnly` | `Boolean` | `False` | Blocks the user's typing, deleting, paste and the editing shortcuts; selection, copy and link clicks still work. It does not block the editing methods called from code; see the [Developer Guide](Docs/DeveloperGuide.md#4-read-only-mode) |
| `ShowBorder` | `Boolean` | `True` | Draws a 1px border around the control |
| `Title` | `string` | `''` | Document title (used in `FullHTML` export) |

### Runtime-only

| Property | Type | Description |
|---|---|---|
| `CurrentRun` | `TS4YHTMLRun` | Run under the caret, or `nil` |
| `FullHTML` | `string` | Full `<!DOCTYPE html>…</html>` document; writable (replaces content and extracts `Title`/`Language`) |
| `HasSelection` | `Boolean` | `True` when text is selected |
| `Placeholders` | `TList<TS4YHTMLRun>` | All placeholder runs in the document (O(1) cache, read-only) |
| `State` | `TS4YEditorState` | Snapshot of formatting state at the caret position |

---

## TS4YEditorState record

Returned by the `State` property and passed to `OnStateChange`.

```delphi
TS4YEditorState = record
  Alignment: TS4YHTMLAlignment;       // haLeft, haCenter, haRight, haJustify
  BackgroundColor: TAlphaColor;    // per-character background (highlight) color at caret
  CanOutdent: Boolean;             // True when Outdent would have effect
  FontColor: TAlphaColor;          // per-character font color at caret
  FontName: string;
  FontSize: Single;                // pt
  HasSelection: Boolean;
  ImageAlt: string;                   // alt text of image at caret ('' if not an image)
  ImageHeight: Integer;               // pixel height of image at caret (0 if not an image)
  ImageSource: string;                   // src of image at caret ('' if not an image)
  ImageWidth: Integer;                // pixel width of image at caret (0 if not an image)
  IndentLevel: Integer;               // indent level of the paragraph at caret (0 = no indent)
  IsBold, IsItalic, IsUnderline, IsStrikeOut: Boolean;
  IsImage: Boolean;                   // True when caret is on an image run
  IsOrderedList, IsUnorderedList: Boolean;
  IsSubscript, IsSuperscript: Boolean;
  LineNumber: Integer;                // 1-based visual line in the rendered document (0 = no layout)
  ColumnNumber: Integer;              // 1-based character position within the visual line (0 = no layout)
  LinkURL: string;                    // URL of the link at caret ('' if not a link)
  ParagraphFormat: TS4YParagraphFormat;  // pfBodyText, pfParagraph, pfH1..pfH6, pfPre
end;
```

---

## Methods

### Formatting

| Method | Description |
|---|---|
| `ToggleBold` | Toggle bold on selection or at caret |
| `ToggleItalic` | Toggle italic |
| `ToggleUnderline` | Toggle underline |
| `ToggleStrikeOut` | Toggle strikethrough |
| `ToggleSuperscript` | Toggle superscript |
| `ToggleSubscript` | Toggle subscript |
| `IncreaseFontSize` | Increase font size one step |
| `DecreaseFontSize` | Decrease font size one step |
| `SetCurrentFontName(Name)` | Apply font family to selection or caret |
| `SetCurrentFontSize(Size)` | Apply font size (pt) to selection or caret |
| `SetCurrentFontColor(Color)` | Apply text color to selection or caret |
| `SetCurrentBackgroundColor(Color)` | Apply per-character background (highlight) color to selection or caret |
| `ClearFormatting` | Remove all inline styles from selection |
| `AlignLeft` / `AlignCenter` / `AlignRight` / `AlignJustify` | Set paragraph alignment |
| `SetCurrentParagraphFormat(AFormat)` | Set block type: `pfBodyText`, `pfParagraph`, `pfH1`…`pfH6`, `pfPre` |
| `SetHeading(Level)` | Set heading level 0–6 (0 = paragraph) — legacy shorthand |
| `ToggleOrderedList` | Toggle numbered list |
| `ToggleUnorderedList` | Toggle bullet list |
| `Indent` | Increase indent level (blockquote or list nesting) |
| `Outdent` | Decrease indent level; enabled only when `State.CanOutdent = True` |

### Insertion

| Method | Description |
|---|---|
| `InsertLink(URL, Text)` | Insert `Text` as a new hyperlink run at the caret (requires non-empty URL and Text) |
| `UpdateLink(URL)` | Set `URL` on the selection, or on the link run at the caret when there is no selection; `URL = ''` removes the link |
| `RemoveLink` | Remove the hyperlink URL from the selection (text is kept) |
| `GetLinkAtCaret` | Return the URL of the link run at the caret, or `''` if not a link |
| `InsertText(S)` | Insert plain text at caret |
| `InsertHTML(HTML)` | Parse and insert an HTML fragment at caret |
| `InsertHorizontalRule([Color, Thickness])` | Insert a horizontal rule |
| `InsertImage(Src[, Width, Height, Alt])` | Insert an image at the caret (currently inserted as an inline run, the same as `InsertInlineImage`) |
| `InsertInlineImage(Src[, Width, Height, Alt])` | Insert an inline image (as a run inside a paragraph) |
| `UpdateImage(Src[, Width, Height, Alt])` | Replace the image under the caret (use `State.IsImage` to check) |
| `InsertTable([Rows, Cols])` | Insert an empty table (default 2×2) |
| `InsertTableRow` | Insert a new row after the row containing the caret (does nothing in a table with merged cells) |
| `DeleteTableRow` | Delete the row containing the caret (does nothing in a table with merged cells) |
| `InsertTableColumn` | Insert a new column after the column containing the caret (does nothing in a table with merged cells) |
| `DeleteTableColumn` | Delete the column containing the caret (does nothing in a table with merged cells) |
| `InsertPlaceholder(RawText[, DisplayName])` | Insert a non-editable placeholder chip |
| `UpdatePlaceholder(NewRawText[, NewDisplayName])` | Replace the placeholder under the caret |
| `ReloadImages` | Re-fetch all images from their source paths/URLs, with the same checks as the first load |
| `LoadLocalImages` | Load the local images skipped because `AutoLoadLocalImages` is `False` |
| `LoadRemoteImages` | Load the remote images skipped because `AutoLoadRemoteImages` is `False` |
| `ResolveImageSource(Src)` | Return the file path (or URL) that a `src` is read from, according to `ImagePathMode` and `DocumentPath` |

### Files

| Method | Description |
|---|---|
| `LoadFromFile(FileName[, Encoding])` | Read an HTML file (UTF-8 by default) into the editor. Sets `DocumentPath` to the folder of the file before loading, so document-relative images resolve. Title and language are read like `FullHTML` |
| `SaveToFile(FileName[, Encoding])` | Write the full HTML document (UTF-8 by default). See [Images and files](#images-and-files) for what happens to the image paths |
| `SaveToFile(FileName, Options[, Encoding])` | Same, with a `TS4YSaveOptions` record, e.g. to copy the images next to the file |

### Editing

| Method | Description |
|---|---|
| `SelectAll` | Select the entire document |
| `ClearSelection` | Remove the selection and keep the caret where it is |
| `ClearSelection` | Deselect all — removes the selection without altering content |
| `Undo` | Undo last change (up to 100 levels) |
| `Redo` | Redo last undone change |
| `Cut` | Cut selection to clipboard (CF_HTML + CF_UNICODETEXT on Windows) |
| `Copy` | Copy selection to clipboard |
| `Paste` | Paste from clipboard (HTML-aware) |
| `PasteAsPlainText` | Paste from clipboard stripping all formatting (`Ctrl+Shift+V`) |

### Navigation

| Method | Description |
|---|---|
| `ScrollToParagraph(Index)` | Scroll the document so that paragraph at `Index` is visible at the top |
| `ScrollToDocumentPosition(Pos)` | Scroll to make a specific `TS4YDocumentPosition` position visible |

### Document info

| Method / Property | Description |
|---|---|
| `CharCount` | Total number of text characters in the document (images and placeholders excluded) |
| `WordCount` | Number of words (whitespace-delimited) in the document |
| `SelText` | Plain text of the current selection (`''` when no selection) |
| `SelHTML` | HTML fragment of the current selection (`''` when no selection) |

### Search

| Method | Description |
|---|---|
| `FindNext(Text[, CaseSensitive])` | Select the next occurrence of `Text` from the caret; wraps around; returns `False` when not found |
| `FindPrevious(Text[, CaseSensitive])` | Select the previous occurrence; wraps around; returns `False` when not found |
| `ReplaceAll(FindText, ReplaceText[, CaseSensitive])` | Replace all occurrences in the document; returns the count of replacements |

Search highlights the match via the normal selection. Each successive `FindNext` / `FindPrevious` call starts from the end / start of the current selection, enabling repeated stepping. `ReplaceAll` is a single undoable operation.

---

## Events

| Event | Signature | Description |
|---|---|---|
| `OnBeforeLoadImage` | `procedure(Sender; const ASource: string; AContext: TS4YImageLoadContext; var Allow: Boolean)` | Fired before an image is read or downloaded; set `Allow=False` to refuse it. `OnLoadImage` still fires with a `nil` bitmap, so it can provide a substitute; if still `nil` the image is drawn as "not found". Also consulted (context `ilcSave`) before `SaveToFile` copies an image |
| `OnChange` | `TNotifyEvent` | Fired after every change to the document (typing, deleting, formatting, inserting, paste, undo/redo, replace); one action may fire it more than once. Not fired when `HTML` / `FullHTML` / `LoadFromFile` set the content |
| `OnDrawListMarker` | `procedure(Sender; Canvas; const Bounds; IndentLevel: Integer; var Handled)` | Custom drawing of a list bullet; set `Handled=True` to suppress default rendering. Called only for items near the visible area, and again at every redraw |
| `OnDrawPlaceholder` | `procedure(Sender; Canvas; const Bounds; const RawText; var Handled)` | Custom rendering of placeholder chips. Called only for chips near the visible area, and again at every redraw |
| `OnGetListMarker` | `procedure(Sender; IndentLevel: Integer; var Marker: string; var Handled)` | Return a text character (e.g. `•`, `◦`) to use as bullet; takes priority over `OnDrawListMarker`. Same calling rules as `OnDrawListMarker` |
| `OnGetPlaceholderLabel` | `procedure(Sender; const RawText: string; var DisplayLabel: string)` | Map raw placeholder text to a display label |
| `OnLinkClick` | `procedure(Sender; const URL, LinkText: string)` | User clicked a hyperlink |
| `OnLinkHover` | `procedure(Sender; const URL: string; var Cursor: TCursor)` | Mouse entered/left a link |
| `OnLoadImage` | `procedure(Sender; const ASource: string; var ABitmap: TBitmap; AContext: TS4YImageLoadContext)` | Custom image loading — assign a `TBitmap` to override or provide the default file/URL loading. `ASource` is the original `src`, as written in the document |
| `OnStateChange` | `procedure(Sender; const State: TS4YEditorState)` | Fired when caret moves or selection changes — use to update toolbar |

---

## Images and files

### Image sources

`src` values are kept exactly as written in the document and are never rewritten while editing. The editor reads them as follows:

- **Local files**: relative or absolute paths, and `file:` URLs (`file:///C:/dir/a%20b.png`, UNC and `localhost` forms). A missing file is drawn as "not found" without raising an exception.
- **Remote images**: `http://` and `https://`.
- **Embedded images**: `data:` URIs (base64 raster images and SVG).
- Other schemes (for example `cid:`) are not loaded by the editor: supply the bitmap in `OnLoadImage`.

`AutoLoadLocalImages` and `AutoLoadRemoteImages` control whether local and remote images are loaded automatically; `LoadLocalImages` and `LoadRemoteImages` load them on request.

### Relative paths: `ImagePathMode`

| Mode | A relative `src` is resolved against |
|---|---|
| `ipmApplication` (default) | The process working directory (often, but not always, the executable folder) |
| `ipmDocument` | `DocumentPath`, the folder of the document. `LoadFromFile` sets it for you; set it yourself when the HTML comes from elsewhere |

In `ipmDocument` mode `InsertImage`, `InsertInlineImage` and `UpdateImage` store the source relative to `DocumentPath` (with `/` separators) when the file is inside that folder or one of its subfolders; any other source is stored as passed. Absolute paths and URLs already present in the HTML are never rewritten.

### Saving: `SaveToFile`

`SaveToFile` writes the document and treats the image paths as follows:

- `ipmDocument`: the sources are left untouched and `DocumentPath` moves to the folder of the saved file.
- `ipmApplication`: a relative path depends on the working directory, so it would break when the file is opened elsewhere. In the saved text it is written as an absolute `file:///...` URL (the document in memory is not changed). Absolute paths, remote URLs and `data:` URIs are written as they are.

To make the saved document self-contained, pass a `TS4YSaveOptions` record:

```delphi
var
  LOptions: TS4YSaveOptions;
begin
  LOptions.Init;
  LOptions.CopyImages := True;      // copy the local images next to the file
  // LOptions.ImagesFolderName := 'images';   // default: '<file name>_files'
  // LOptions.UpdateModel := True;            // also point the document to the copies
  HTMLEditor.SaveToFile('C:\Docs\letter.html', LOptions);
end;
```

| Option | Default | Meaning |
|---|---|---|
| `CopyImages` | `False` | Copy the existing local images into a subfolder next to the saved file; the saved HTML points to the copies. Remote, `data:` and missing sources are left as they are. Nothing is copied when `AutoLoadLocalImages` is `False` or when `OnBeforeLoadImage` refuses the image |
| `ImagesFolderName` | `''` | Name of the subfolder; empty means `<file name>_files` |
| `UpdateModel` | `False` | After saving, the document itself points to the copies (relative paths in `ipmDocument`, absolute paths in `ipmApplication`). When `False` the document keeps pointing to the original images and `DocumentPath` does not move |

The same image used several times is copied once. Two different files with the same name get a numeric suffix (`logo.png`, `logo_2.png`); a file already in the destination folder is never overwritten (an identical one is reused). If the destination cannot be written, the exception is raised normally.

### Restricting local files: `LocalImageAccess`

By default (`liaAnywhere`) an image can be read from any local file the process can read, which is what an editor for your own documents needs. When the content comes from somebody else (for example an incoming e-mail), set `LocalImageAccess := liaDocumentFolder`:

- a local image is loaded only if its resolved path is inside `DocumentPath` or one of its subfolders, with `..` segments, `file:` URLs and network paths (`\\server\share`, `file://server/share`) evaluated on the final normalized path;
- with an empty `DocumentPath` no local image is loaded: this is the intended setup for content you only display, such as a received e-mail set with `HTML` / `SetHTML`, where no local file must be read or even probed;
- `data:` and remote images are not affected (use `AutoLoadRemoteImages` and `OnBeforeLoadImage` for those);
- the check cannot be overridden by `OnBeforeLoadImage`, and it also applies to the images copied by `SaveToFile`;
- symbolic links inside the folder are not resolved.

Changing the property reloads the images.

Typical setups:

| Scenario | Suggested settings |
|---|---|
| Editing your own documents (the default use) | `LocalImageAccess = liaAnywhere`; `LoadFromFile` / `ImagePathMode = ipmDocument` if the images are relative to the document |
| Displaying untrusted content, e.g. a received e-mail | `LocalImageAccess = liaDocumentFolder` and an empty `DocumentPath`; supply `cid:` images in `OnLoadImage`; decide about remote images with `AutoLoadRemoteImages` / `OnBeforeLoadImage` |
| Composing a message with images chosen by the user | `liaAnywhere` if you trust what the user pastes; otherwise `liaDocumentFolder` with `DocumentPath` set to a working folder of the draft, copying the chosen images there |

### Controlling what is loaded: `OnBeforeLoadImage`

`OnBeforeLoadImage` is fired before an image is read or downloaded, for every non-empty `src` (including `data:`), and lets the application refuse it:

```delphi
procedure TfrmMain.HTMLEditorBeforeLoadImage(Sender: TObject; const ASource: string;
  AContext: TS4YImageLoadContext; var Allow: Boolean);
begin
  // e.g. in a mail client: never touch local files named by an incoming message
  Allow := not IsLocalImageSource(ASource);   // from Soft4You.HTML.Types
end;
```

A refused image is not read; `OnLoadImage` still fires with a `nil` bitmap so a replacement can be supplied, and if none is the image is drawn as "not found". A refusal without a replacement is remembered, so the events are not fired again at every repaint; the memory is cleared when the content or the path settings change, and `LoadLocalImages` / `LoadRemoteImages` ask again. The context tells why the image is needed: `ilcParse` (loading a document), `ilcInsert`, `ilcReload`, `ilcRender` and `ilcSave` (about to be copied by `SaveToFile`).

---

## List behaviour

- **Base indent level** (`IndentLevel = 0`): items are visually indented from the left margin (same as browser default — approximately 40 px of text offset with a 20 px marker area).
- **Nested lists** (`Indent` / `Outdent`): each level adds one indent step. `State.CanOutdent` is `False` at level 0.
- **Bullet cycling** (unordered lists, default): the marker shape cycles with `IndentLevel mod 3` — filled disc (0), open circle (1), filled square (2+).
- **Custom markers**: use `OnGetListMarker` to return a text character, or `OnDrawListMarker` for full canvas control. `OnGetListMarker` takes priority.

---

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `Ctrl+B` | Toggle bold |
| `Ctrl+I` | Toggle italic |
| `Ctrl+U` | Toggle underline |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |
| `Ctrl+A` | Select all |
| `Esc` | Remove the selection (the key is left to the form when there is none) |
| `Ctrl+C` | Copy |
| `Ctrl+X` | Cut |
| `Ctrl+V` | Paste |
| `Ctrl+Shift+V` | Paste as plain text (strips formatting) |
| `Ctrl+Home` / `Ctrl+End` | Move to document start/end |
| `Shift+arrows` | Extend selection |
| `Ctrl+Shift+Home/End` | Extend selection to start/end |
| `Home` / `End` | Move to line start/end |
| `Arrow keys` | Character/line navigation; up/down navigate table rows |
| `Tab` / `Shift+Tab` | In a table: next / previous cell (`Tab` in the last cell appends a row). Elsewhere: normal focus change |
| `Enter` | Insert paragraph break (inside a table cell: line break) |
| `Shift+Enter` | Insert line break (`<br>`) |
| `Backspace` / `Delete` | Delete character or selection |
| `Ctrl+Backspace` | Delete word left |

Mouse: single click places caret, double-click selects word, triple-click selects paragraph. Clicking on an image selects it. Drag to extend selection with auto-scroll near edges.

---

## TS4YPlaceholderAppearance

Configure via Object Inspector or code:

```delphi
HTMLEditor.PlaceholderAppearance.FillColor        := $FFE8F0FE;
HTMLEditor.PlaceholderAppearance.TextColor        := $FF1A73E8;
HTMLEditor.PlaceholderAppearance.BorderColor      := $FF1A73E8;
HTMLEditor.PlaceholderAppearance.BorderRadius     := 4;
HTMLEditor.PlaceholderAppearance.HorizontalPadding := 6;
HTMLEditor.PlaceholderAppearance.VerticalPadding  := 2;
HTMLEditor.PlaceholderAppearance.Bold             := True;
```

A placeholder is inserted as a run with `IsPlaceholder = True`. Its raw text is `PlaceholderPrefix + RawText + PlaceholderSuffix`. Use `OnGetPlaceholderLabel` to display a human-readable label instead of the raw text.

All placeholder runs are accessible at O(1) via the `Placeholders` property (a `TList<TS4YHTMLRun>` kept in sync with every edit operation).

---

## Performance Notes

- **Layout cache**: `TS4YLayoutEngine` caches text measurements (`MeasureStr`) in a `TDictionary`. The cache is cleared on every `SetHTML` call. Subsequent layouts (resize, keypress) are near-instant for typical documents.
- **Render cache**: the control renders to an off-screen `TBitmap` and blits it to the canvas on FMX-initiated repaints. Only changes that affect visual output trigger a re-render. The caret is drawn inside the cache, so each caret move and blink re-renders it.
- **Visible-area painting**: a re-render draws only the fragments, images, rules and list markers within 64 px of the visible area, so the cost of a frame follows the window size and not the document length. Consequently the list-marker and placeholder drawing events are not called for items far out of view.
- **Emoji / color fonts**: the first `SetHTML` call on a document containing emoji is slower due to DirectWrite color-font fallback (Windows). Subsequent layout operations on the same document are fast thanks to the measurement cache.
- **Image cache**: images are loaded once per `src` value and cached in an internal `TObjectDictionary`. Orphaned entries (deleted images) are retained to support undo and shared `src` values; the cache is cleared on `SetHTML`, when `ImagePathMode` or `DocumentPath` change, or on destruction.
- **Placeholder cache**: `FPlaceholders: TList<TS4YHTMLRun>` is kept in sync incrementally on every edit. Accessing `Editor.Placeholders` is O(1) — no document scan needed.

---

## Known Limitations

- **Image security**: the editor reads local files and `file:` URLs named by the HTML without any check. When displaying content from untrusted sources (for example e-mail), set `LocalImageAccess` to `liaDocumentFolder` (or `AutoLoadLocalImages` to `False`) and filter with `OnBeforeLoadImage`.
- **Tables**: `colspan` and `rowspan` are read, drawn and written back, but merged cells cannot be created or split in the editor, and rows or columns cannot be inserted or deleted in a table that has them. Each cell is a single paragraph; `Enter` inserts a line break.
- **IME**: input composition (CJK pre-edit text) is not supported, so the control is not usable with Chinese, Japanese or Korean input methods.
- **Accessibility**: no VoiceOver / TalkBack support.
- **CSS subset**: only the inline CSS properties listed above are supported. External stylesheets and CSS classes are ignored.
- **RTF clipboard**: only plain text and HTML clipboard formats are supported. RTF is not read or written.
- **macOS / iOS / Android clipboard**: CF_HTML is a Windows-only format. On other platforms the HTML fragment is placed on the clipboard as plain text; round-trip within the same editor instance works via `LooksLikeHTML` detection.

---

## Demo

The `Demo` folder contains a sample FMX application (`Demo\S4YHTMLEditorDemo.dproj`, also part of the project group in `Packages`) with a complete toolbar, emoji picker, placeholder and color dialogs. Install the component package first.

---

## AI-assisted development

This component was designed and directed by Carlo Marona (Soft4You) and developed with the assistance of [Claude](https://www.anthropic.com/claude) (Anthropic), used through Claude Code.

---

## Credits

- [Skia4Delphi](https://github.com/skia4delphi/skia4delphi) — MIT license, SVG rendering.
- Demo toolbar icons: [Google Material Symbols](https://fonts.google.com/icons) — Apache License 2.0.
