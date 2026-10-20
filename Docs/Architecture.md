# TS4YHTMLEditor - Architecture

This document describes the internals of the control, for people who modify it. If you only use the control in an application, read the [Developer Guide](DeveloperGuide.md) and the [README](../README.md) instead.

## Overall pipeline

The component is made of four independent levels that work as a pipeline:

```
HTML string
    ↓  TS4YHTMLParser
TS4YHTMLDocument  (data model)
    ↓  TS4YLayoutEngine
FFrags / FLines  (computed layout)
    ↓  Paint / TCanvas
Pixels on screen
```

The opposite direction is `TS4YHTMLGenerator`, which writes a `TS4YHTMLDocument` back as HTML.

---

## 1. Data model (`TS4YHTMLDocument`)

The document is a list of **paragraphs** (`TS4YHTMLParagraph`), each holding a list of **runs** (`TS4YHTMLRun`). The units are `Soft4You.HTML.Document` (the classes) and `Soft4You.HTML.Types` (enumerations and the text style record).

```
TS4YHTMLDocument
 └─ TS4YHTMLParagraph  [BlockType, Alignment, IndentLevel, ListOrdered, ListIndex, table and image attributes]
      └─ TS4YHTMLRun   [Text, Style: TS4YHTMLTextStyle, IsLineBreak, IsImage, IsPlaceholder, ...]
      └─ TS4YHTMLRun   ...
 └─ TS4YHTMLParagraph  ...
```

A **paragraph** is not only an HTML `<p>`: it is any block of the document. Lists, headings, quotes, table cells and so on are all paragraphs with a different `BlockType`. There is no tree: a list is a sequence of `btLI` paragraphs, a table is a sequence of `btTableCell` paragraphs.

### Block types

| `BlockType` | Created from | Attributes it uses |
|---|---|---|
| `btBodyText` | Text outside any block tag | `Alignment` |
| `btParagraph` | `<p>`; also the single empty paragraph of a document parsed from an empty text | `Alignment` |
| `btH1` ... `btH6` | `<h1>` ... `<h6>` | `Alignment` |
| `btBlockquote` | `<blockquote>` | `IndentLevel` = nesting depth of the quotes |
| `btLI` | `<li>` | `ListOrdered`, `ListIndex` (1-based, ordered lists only), `IndentLevel` = list nesting depth minus 1 |
| `btPre` | `<pre>` | none beyond the runs |
| `btHR` | `<hr>` | `HRColor`, `HRThickness`; the paragraph has no runs |
| `btTableCell` | Plain text inside `<td>` or `<th>`, also `<p>` inside a cell | `TableID`, `TableRow`, `TableCol`, `TableCols`, `IsHeader` (see Tables) |
| `btImage` | Not created by the parser nor by `InsertImage`; see below | `ImageSource`, `ImageAlt`, `ImageWidth`, `ImageHeight` |
| `btUL`, `btOL` | Never. `<ul>` and `<ol>` only change the nesting depth and the counter used while parsing: they do not produce paragraphs | - |

All paragraphs also have `Alignment` (`haLeft`, `haCenter`, `haRight`, `haJustify`) and `Runs`.

### Runs

A **run** is the smallest segment of text with a single style. If you write "ciao **mondo**", the paragraph has two runs: `"ciao "` with the normal style and `"mondo"` with `Bold = True`. Adjacent runs with the same style are merged (`AddTextRun` while parsing, `NormalizeRuns` while editing).

`TS4YHTMLRun` uses boolean flags to tell the kinds that are not plain text:

| Flag | Meaning | Other fields used |
|---|---|---|
| (none) | Styled text | `Text`, `Style` |
| `IsImage` | Inline image. `Text` holds the object replacement character `#$FFFC`, so the image takes exactly one character position | `ImageSource`, `ImageAlt`, `ImageWidth`, `ImageHeight`, `Style` |
| `IsPlaceholder` | Non-editable chip. `Text` is the raw text as stored in the HTML | `DisplayText` (label shown instead of the text), `PlaceholderBorderColor`, `Style` |
| `IsLineBreak` | A `<br>` | none |

`Style` (`TS4YHTMLTextStyle`) holds the font, size, bold, italic, underline, strikethrough, superscript, subscript, text color, background color and link URL of the run.

**Images are always inline in practice.** The parser turns every `<img>` into an image run inside the current paragraph, and `InsertImage` does the same as `InsertInlineImage`. The `btImage` block (an image that is a paragraph on its own, with the `Image*` attributes on the paragraph) is still supported by the layout, the painter, the caret code and the generator, but nothing in the component creates it: a document built by hand with such a paragraph is saved as a bare `<img>` and read back as an inline image.

### Empty paragraphs

An empty paragraph is represented with `Runs.Count = 0`, not with a run whose `Text` is `''`. The distinction is critical for the layout (details in the layout engine section). `IsEmpty` is true when no run has text: line breaks are ignored, while an image counts as content because its `Text` is `#$FFFC`.

The parser drops the empty paragraphs it finds, except when the document would otherwise have none: a parsed document always has at least one paragraph.

### Tables

A table is a run of consecutive paragraphs that have a `TableID`, in row-major order. A paragraph belongs to a table cell when `IsTableCell` is True, that is when its `TableID` is not 0; the block type says what the paragraph is (`btTableCell` for plain text, but also `btH2`, `btLI`, `btHR` and so on):

- `TableID` groups the cells of the same table. It comes from `NextTableID`, a counter shared by the parser and the editor, so two tables never share an identifier.
- `TableRow` and `TableCol` are zero-based. `TableCols` is the number of columns of the table (the highest number of cells of a row); the parser fills it for every cell when it reaches `</table>`.
- `TableColSpan` and `TableRowSpan` (both 1 for a normal cell) say how many columns and rows a cell covers. A merged cell is one paragraph, stored at its top-left position; the positions it covers have no paragraph. The parser skips the columns that a `rowspan` cell of a previous row still covers, limits both spans to 100, and shortens a `rowspan` that goes past the last row. `TableCols` counts the columns covered, not the cells.
- A cell is a run of one or more paragraphs with the same `TableID`, `TableRow` and `TableCol`. The first one holds the attributes of the cell (`TableColSpan`, `TableRowSpan`); the others have both spans at 1. The parser gives the cell every paragraph that ends while the `<td>` is open, so `<p>`, headings, lists, blockquotes, `<hr>` and `<pre>` stay in the cell, and an empty cell keeps one empty paragraph. `<caption>` and `<colgroup>` are skipped and `<col>` is ignored.
- A table can sit inside a cell of another table. Its paragraphs have their own `TableID`, `TableRow` and `TableCol`, and `TableContainers` lists the cells that contain the table, from the outermost to the innermost (empty for a table that is not nested). `BelongsToTable` and `IsInCell` tell whether a paragraph is in a table or a cell at any depth. In document order the paragraphs of the nested table sit between the paragraphs of the cell that contains it, so the range of a cell includes them. A cell that holds a nested table always starts with a paragraph of its own (empty when needed) that keeps the attributes of the cell; the generator does not write that empty paragraph, nor an empty one that follows the nested table.
- A `<th>` has `IsHeader = True`, centered alignment and bold text.
- The generator reads the cells by `TableRow` and `TableCol`. A cell with one `btTableCell` paragraph is written as its runs, and a cell with several paragraphs or other blocks is written with the markup of each one inside the `<td>`. It writes an empty `<td>` for a position that has no cell and is not covered by a merged cell. It writes `colspan` and `rowspan` only when they are greater than 1.
- The layout gives a cell the width of the columns it covers and stacks its paragraphs, and the row grows to hold them. A cell that spans rows grows the last row it covers when its text does not fit. A table in a cell is laid out in the width of the cell. Dragging the border between two columns (`MouseDown`, `MouseMove` and `MouseUp` in the editor) moves it: the first movement saves one undo step and freezes the width of every column of the table, then the column on the left grows and the other shrinks by the same amount (24 pixels at least). The widths are written to the cells as a percentage of the table, or in pixels when the table width is in pixels, and the layout runs on every movement; `OnChange` is raised once, when the mouse is released. The outer edge of the table works the same way but changes the width of the table (`TableWidth`, a percentage of the space or pixels) and leaves the columns alone: the right edge of a table on the left grows it by the distance dragged, a centered table grows by twice that distance, and a table on the right is dragged by its left edge. The width has a minimum of 24 pixels per column and a maximum of the space (`TableAvailableWidth` of the cell rectangles), and a `max-width` that the new width goes past is dropped. The width of the table comes from `TableWidth` (pixels or percent of the space; the whole space when it is not set) limited by `TableMaximumWidth`, and `TableAlignment` places a table that is narrower than the space. A column takes the `TableCellWidth` of the first cell that sets one and does not span columns; the columns without a width share what is left (24 pixels at least), and all the columns are scaled to the width of the table. When every column has a width and the table has none, the table is as wide as its columns. `TableHasBorder` is False only for a table read with `border="0"` or `border:none`: its borders are not drawn.
- The first paragraph of a cell also holds its box: `TableCellBackgroundColor` (the cell takes the `bgcolor` of its table when it has none), `TableCellPadding` (`padding` of one to four values, or the `cellpadding` of the table; not set means 4 pixels) and `TableCellVerticalAlignment` (`valign`, `vertical-align`; the default is the top, which differs from a browser, where a cell is centered). The padding sets the width of the content, the height of the row and where the content starts; a cell taller than its content puts it in the middle or at the bottom. The background is filled from the rectangles of `FCells` before the borders, the outer cell first. The generator writes these only when the cell has them.
- The text of a cell takes the text alignment written on the cell or its table (`align`, `text-align`; it wins over the centering of a `th`) and the text style that their `style` writes (font, size, weight, color, decoration). The parser pushes the style when the table or the cell starts and takes it back when it ends; `background` and `background-color` are not part of the text style, because on a block or a cell they color the block or the cell. The same applies to `p`, `div`, `h1`-`h6`, `li`, `blockquote`, `ul` and `ol` (`OpenBlockStyle`, `CloseBlockStyle`): a `p` or `li` that is still open ends when the next one starts, and the blocks left open inside a cell or a table end with it. The layout gives every cell a rectangle (`TS4YLayoutCell`, in `FCells`), also a cell that only holds a nested table; the borders are drawn from these rectangles, and a click uses the innermost rectangle that contains the point. Moving the caret up or down finds the cell that covers the position above or below, also when it starts elsewhere. A mouse click inside a cell is resolved among the lines of that cell only, so a click in the empty part of a tall cell still lands in it. The commands that insert or delete a row or a column do nothing in a table that contains merged cells, that is nested, or that has a table nested in one of its cells. `Up` and `Down` enter and leave a nested table, `Tab` and `Shift+Tab` move between the cells of the table that holds the caret and skip the tables nested in a cell, and a table inserted while the caret is in a cell is nested in that cell. In a cell, `Enter` starts a new paragraph of the cell (`Shift+Enter` inserts a line break), `Backspace` and `Delete` merge only paragraphs of the same cell, and `Tab` moves to the first paragraph of the next cell.

### Positions

The position of the caret is a `TS4YDocumentPosition` with three integers:

```
ParagraphIndex  →  index of the paragraph (-1 = not valid)
RunIndex   →  index of the run inside that paragraph
CharIndex  →  position inside Run.Text (0 = before the first character)
```

### Ownership and copies

`TS4YHTMLDocument` owns its paragraphs and `TS4YHTMLParagraph` owns its runs (`TObjectList` with `OwnsObjects = True`). `Clone` makes a deep copy at each level. Undo and redo store a snapshot (`Clone`) of the whole document, together with the caret and the selection.

### Indentation (`IndentLevel`)

Every `TS4YHTMLParagraph` has an `IndentLevel: Integer` field (0 = no indentation):

- **`btBlockquote`**: each level of nested `<blockquote>` adds 1 to `IndentLevel`.
- **`btLI`**: `IndentLevel = 0` for first-level lists, `IndentLevel = 1` for the first nesting, and so on. `Indent`/`Outdent` change this value; `Outdent` is enabled only when `IndentLevel > 0`.

---

## 2. Layout engine (`TS4YLayoutEngine`)

The layout engine converts the data model into two flat arrays:

- **`FFrags: TArray<TS4YLayoutFragment>`** - each fragment is a measurable piece of text, with X/Y/W/H coordinates in pixels (document coordinates, without scroll).
- **`FLines: TArray<TS4YLayoutLine>`** - each logical line of the document, with Y, H, ascent, and the start/end indexes in `FFrags`.
- **`FCells: TArray<TS4YLayoutCell>`** - the rectangle of every table cell, nested tables included.

### How `LayoutParagraph` works

1. For each run, it splits the text into words (`FindWordEnd` looks for the first space and then all the spaces that follow).
2. It measures each word with `TTextLayout.MeasureStr`, using the font of the run.
3. If the word does not fit on the current line (`LineW + WordW > AvailW`), it calls `FlushLine`, which finalizes the line: it applies the alignment (haLeft/haCenter/haRight/haJustify), assigns the X/Y coordinates to every fragment, and adds the line to `FLines`.
4. After all the runs, it does a final `FlushLine` for the last line.

### Indentation in the layout

For `btBlockquote` paragraphs, the horizontal offset is:

```
LIndentX := IndentLevel * C_EDITOR_BLOCKQUOTE_INDENT
```

For `btLI` paragraphs, the offset includes both the fixed margin and the space for the marker:

```
LIndentX := (IndentLevel + 2) * C_EDITOR_LIST_INDENT
```

The `+2` stands for 1 unit of left margin plus 1 unit for the marker area (bullet/number). In this way `IndentLevel = 0` produces the base indentation typical of browsers (~40 px with `C_EDITOR_LIST_INDENT = 20`).

### Special case - empty paragraph (`Runs.Count = 0`)

The loop has nothing to iterate. The code explicitly creates a placeholder fragment with `W=0` and `CharStart=CharEnd=0`, which is needed so that `DocumentPositionToXY` can find the position of the caret in a paragraph without text.

```pascal
// Empty paragraph - still needs at least one empty fragment for caret
if Para.Runs.Count = 0 then begin
  // creates an empty fragment and calls FlushLine
  Exit;
end;
```

> **Critical note:** a run with `Text=''` (`Runs.Count = 1` but empty text) does NOT take the special case. The `while Rest <> ''` loop never iterates, `LineFrags` stays empty, and `FlushLine` is skipped. The result is zero fragments for that paragraph, so `DocumentPositionToXY` cannot find the position of the caret. An empty paragraph must always have `Runs.Count = 0`.

### When the layout is recomputed

`DoLayout` is called every time that:
- a character is typed
- Enter is pressed
- the control is resized
- the HTML is set

---

## 3. Rendering (`Paint`)

`Paint` does not draw directly to the screen: it draws into a **cache** (`FRenderCache`, a `TBitmap` as big as the control) and then copies the cache to the canvas. The cache is redrawn only when `FRenderDirty` is `True` (`InvalidateRender`), or when the size or the opacity change; otherwise `Paint` only copies the bitmap. The caret is not part of the cache: `Paint` draws it over the copy (see below).

Redrawing the cache (`RenderTo`, a local procedure of `Paint`) follows this sequence:

```
IntersectClipRect   -> inner area, scrollbar excluded
PaintBackground     -> fills the background (BackgroundColor)
PaintTableCellBackgrounds -> fills the cells that have a background color, the outer cell first
PaintTableCellBorders
loop FFrags         -> PaintFragment / PaintImage / PaintImageRun / PaintHorizontalRule
                       (only the fragments near the visible area, see below)
PaintSelection      -> selection rectangles (also limited to the visible area)
list markers        -> bullet / number for the visible btLI paragraphs
PaintBorder         -> border of the control (outside the clip)
```

After copying the cache, `Paint` clips to the same inner area and calls `PaintCaret`.

### Drawing limited to the visible area (culling)

The cost of a frame must follow the window, not the length of the document: each text fragment builds a `TTextLayout`, which is the expensive operation. For this reason the loop on `FFrags` draws a fragment only if its vertical range intersects the visible area, extended by `C_RENDER_CULL_MARGIN` (64 px) above and below:

```pascal
GetRenderCullLimits(LCullTop, LCullBottom);
if (FFrags[I].Y + FFrags[I].Height >= LCullTop) and (FFrags[I].Y <= LCullBottom) then
  // draw
```

`GetRenderCullLimits` computes `-C_RENDER_CULL_MARGIN - ContentTop` and `Height + C_RENDER_CULL_MARGIN - ContentTop`. `ContentTop` includes the scroll, so it brings the document coordinates into screen space. The margin exists because a fragment can draw outside its own box (superscript/subscript, underline, background): it must be larger than what a fragment draws outside itself.

`PaintSelection` uses the same limits, so a selection of the whole document costs as much as a selection of one screen. It also finds the height of the first line of each paragraph once per frame, in a single pass over `FLines`, instead of searching for it for every fragment.

**Constraint to keep:** do not go back to drawing all the fragments. The `PERFORMANCE-CRITICAL` comments in the code remind of it. Effect for the people who use the control: `OnDrawListMarker`, `OnGetListMarker` and the placeholder drawing events are fired only for the elements near the visible area (see `Docs/DeveloperGuide.md`).

**`PaintFragment`** creates an FMX `TTextLayout`, sets font/size/style, positions it at `ContentLeft + F.X, ContentTop + F.Y` and calls `RenderLayout`. `ContentTop` is `EDITOR_PADDING - FScrollY`.

**`PaintCaret`** draws a vertical line at `FCaretScreenX, FCaretScreenY`, with height `FCaretScreenH`, **only if `FCaretOn = True`** and not while a selection is being dragged with the mouse (`FDragging and FHasSelection`: the caret would follow the pointer). It is drawn by `Paint` on the screen canvas, over the copy of the cache, and not inside the cache: a blink or a caret move that does not change what the cache contains costs a bitmap copy and one line, not a render of the document.

**Caret blink:** a `TTimer` with a 530 ms interval (`C_EDITOR_CARET_BLINK`) calls `OnCaretTick`, which toggles `FCaretOn` and calls `Repaint` (not `InvalidateRender`). The timer is active only when the control has the focus (`DoEnter`/`DoExit`, which also only repaint) and never at design time.

What the cache still depends on, besides the content, the scroll and the size: the selection, the images with a selection, and the placeholder under the caret (`PaintPlaceholderFragment` highlights it). `MoveCaretPosition` uses this list to decide when a caret move needs a new render (see the caret section).

### Rendering of list markers

After the fragment loop, a second loop on the paragraphs looks for those with `BlockType = btLI`. The first fragment of each paragraph is obtained from a table (`LFirstFragmentOfParagraph`) built in a single pass over `FFrags` from the last to the first (so the lowest index remains for each paragraph): without the table the cost would be items x fragments. The marker is drawn only if that fragment is in the extended visible area, in the area to the left of the text (`X = FragX - C_EDITOR_LIST_INDENT`).

**Rendering priority of the bullet** (unordered list):

1. If `OnGetListMarker` is assigned -> it returns a Unicode character; it is rendered with a `TTextLayout` centered in the marker area.
2. Otherwise, if `OnDrawListMarker` is assigned -> the drawing is delegated to the handler; if `Handled=True` the default is skipped.
3. Default: cycle on `IndentLevel mod 3`:
   - `0` -> filled disc (`FillEllipse`)
   - `1` -> empty circle (`DrawEllipse`)
   - `2+` -> filled square (`FillRect`)

For ordered lists the marker is always a `TTextLayout` with the number followed by a period (`"1."`, `"2."`, ...).

---

## 4. Keyboard input

`KeyDown` handles two kinds of input:

### Printable characters (`KeyChar >= ' '`)

```
KeyDown → InsertChar(Ch)
           ├─ takes the current style (StyleAtCaret)
           ├─ if the paragraph is empty: creates the first run
           ├─ if the style of the run does not match: splits the run and creates a new one
           ├─ otherwise: inserts the character in the string of the current run
           ├─ NormalizeRuns: merges adjacent runs with the same style
           ├─ recomputes FCaretPosition using an absolute offset (invariant to NormalizeRuns)
           └─ DoLayout → Changed → Repaint
```

### Special keys

| Key | Action |
|---|---|
| `vkBack` | `DeleteBack`: deletes the character before the caret; at the start of a paragraph, merges with the previous paragraph (`MergeWithPrev`) |
| `vkDelete` | `DeleteForward`: deletes the character after the caret |
| `vkReturn` | `InsertParagraphBreak`: splits the current paragraph in two |
| `←→↑↓` | `MoveCaretPosition` with `PreviousDocumentPosition/NextDocumentPosition/LineAbove/LineBelow` |
| `Home/End` | start/end of the line or of the document (with Ctrl) |
| `Esc` | `ClearSelection` when there is a selection; otherwise the key is left to the form |
| `Ctrl+Z/Y` | Undo/Redo (snapshot of the whole document) |
| `Ctrl+B/I/U` | toggles bold/italic/underline on the selection |
| `Ctrl+C/X/V` | clipboard |

### `InsertParagraphBreak` (Enter) in detail

1. Splits the run at the caret (`SplitRunAt`)
2. Creates a new `TS4YHTMLParagraph`, copying BlockType/Alignment/IndentLevel
3. Moves all the runs **after** the caret into the new paragraph
4. The old paragraph is normalized (`NormalizeRuns`) - if nothing remains, `Runs.Count` will be 0
5. `DoLayout` is called **before** `SetCaretPosition`, so `FFrags` already contains the placeholder fragment of the new empty paragraph
6. `SetCaretPosition(NewParaIdx, 0, 0)` moves the caret to the start of the new line

---

## 5. Caret: from the document to the screen

The caret has no native coordinates - its pixel coordinates are computed on demand by `DocumentPositionToXY`:

```
DocumentPositionToXY(FCaretPosition)
  → looks in FFrags for the fragment that contains (ParagraphIndex, RunIndex, CharIndex)
  → measures with MeasureCharOffset the distance in pixels from the start of the fragment
  → returns X = ContentLeft + F.X + offset
            Y = ContentTop + F.Y
            H = height of the line
```

`UpdateCaretXY` calls `DocumentPositionToXY` and saves the result in `FCaretScreenX/Y/H`. They are used by `PaintCaret` at every repaint.

`ApplyCaretPosition` is the single place that moves the caret and the selection:
- updates `FCaretPosition` (and `FSelectionStart/End` when it extends the selection)
- resets the blink (toggle `False/True` of the timer - needed because Delphi does not reset the interval if `Enabled` is already `True`)
- calls `UpdateCaretXY`
- calls `EnsureCaretVisible` (scrolls if the caret is outside the viewport; `ScrollTo` invalidates the render by itself)

Two procedures call it, and differ in what they redraw:

- **`SetCaretPosition`**: after `ApplyCaretPosition` it calls `InvalidateRender` and `DoNotifyState`. It is used by the operations that also change the document (tables, paragraph breaks, ...), which count on the render being redone.
- **`MoveCaretPosition`**: used by the mouse click and by keyboard navigation. It calls `InvalidateRender` only if the cache changes: when there was or there is a selection, or when the old or the new position is on a placeholder (`IsPlaceholderPosition`). Otherwise it calls `Repaint`, and the caret is redrawn over the existing cache. It always calls `DoNotifyState` (notification to the toolbar of the current state of bold/italic/etc).

The selection is removed by `ResetSelection` (private, no redraw: the internal callers redraw and notify by themselves) and by the public `ClearSelection`, which does nothing when there is no selection and otherwise calls `ResetSelection`, `InvalidateRender` and `DoNotifyState`.

---

## 6. Placeholder cache (`FPlaceholders`)

`FPlaceholders: TList<TS4YHTMLRun>` is a cache that tracks all the runs with `IsPlaceholder = True` in the document, without having to scan the whole tree every time.

The cache is exposed read-only as `property Placeholders: TList<TS4YHTMLRun>`.

### Synchronization points

| Operation | Update |
|---|---|
| `SetHTML` | `RebuildPlaceholderList` (full rebuild) |
| `InsertHTML` | `RebuildPlaceholderList` |
| `InsertPlaceholder` | `FPlaceholders.Add(LRun)` (incremental) |
| `DeleteBack` / `DeleteForward` on a placeholder | `FPlaceholders.Remove(LRun)` before the run is removed |
| `DeleteSel` | `RebuildPlaceholderList` (complex operation) |
| `Undo` / `Redo` | `RebuildPlaceholderList` after the document is restored |

`RebuildPlaceholderList` scans the whole document and recreates the list from scratch; it is used only by the operations that change the structure of the document. The simple operations use an incremental update.

---

## 7. Images: loading, paths and saving

### Loading (`LoadImage`)

The model always keeps the original `src` (`ImageSource` of the paragraph or the run). The bitmap lives in the `FImageCache` cache (key: the original `src`). For each `LoadImage(ASource, AContext)` request the following steps are taken, stopping at the first one that decides:

| Step | Outcome |
|---|---|
| empty `src` | no bitmap |
| present in `FImageCache` | the bitmap of the cache |
| present in `FRefusedImages` | no bitmap, no event (the refusal is already known) |
| `IsDeferredImageSource` (`AutoLoadLocalImages` / `AutoLoadRemoteImages` set to `False`) | no bitmap: the image is drawn as a placeholder until `LoadLocalImages` / `LoadRemoteImages` |
| `IsImageLoadAllowed`: first `LocalImageAccess`, then `OnBeforeLoadImage` | if refused nothing is read |
| `LoadBitmapFromSource` | remote (HTTP), `data:` (raster and SVG), or a local file (path resolved with `ResolveImageSource`; a missing file means no bitmap, with no exception) |
| `OnLoadImage` | can replace or provide the bitmap, also for a refused image (it receives `nil`) |

A non-nil bitmap enters `FImageCache`. If the image was refused and `OnLoadImage` provides nothing, the source enters `FRefusedImages`, so the events are not fired at every repaint. `LoadLocalImages`, `LoadRemoteImages` and `ReloadImages` go through `LoadAllowedBitmap` (same checks) and therefore ask the application again.

`FImageCache` and `FRefusedImages` are emptied together by `SetHTML` and by `ReloadImagesAfterPathChange`, which is called by the setters of `DocumentPath`, `ImagePathMode` and `LocalImageAccess`.

### Relative paths

`ResolveImagePath` (in `Soft4You.HTML.Types`) turns the `src` into the path to read: `file:` URLs are decoded (`FileUrlToPath`: UTF-8 percent-encoding, UNC, `localhost`); a relative path stays relative to the current directory in `ipmApplication`, or is combined with `DocumentPath` in `ipmDocument`. URLs and absolute paths found in the document are never rewritten. In `ipmDocument`, `InsertImage` / `InsertInlineImage` / `UpdateImage` store the `src` relative to `DocumentPath` (`MakeDocumentRelativePath`) only if the file is inside that folder.

`LoadFromFile` sets `FDocumentPath` directly (without reloading the images) and then calls `SetFullHTML`, so the images are loaded once, with the right folder.

### Safety of local files

`LocalImageAccess = liaDocumentFolder` makes `IsLocalImageAccessAllowed` check that the resolved and normalized path (`IsPathInsideFolder`) is inside `DocumentPath`. The check comes before `OnBeforeLoadImage` and cannot be overridden by it. With an empty `DocumentPath` no local image is allowed: it is the configuration meant for content received from third parties (for example an e-mail loaded with `SetHTML`). `data:` and remote images do not depend on this property.

### Saving (`SaveToFile`)

```
SaveToFile(AFileName, AOptions)
   ↓ BuildFullHTML(converter)
TS4YHTMLGenerator.ImageSourceConverter   (applied at the two points where the generator writes src="...")
```

The converter is chosen according to `ImagePathMode` and the options:

- `ipmDocument`: no rewriting; after the write, `DocumentPath` moves to the destination folder.
- `ipmApplication`: relative `src` values become absolute `file:///...` (`ImageSourceToFileUrl`) only in the saved text; the model does not change.
- `CopyImages`: `TS4YImageExporter` (`Soft4You.HTML.ImageExporter`) copies the existing local images into a subfolder next to the file and returns the `src` relative to the copy. It asks `IsImageLoadAllowed(ASource, ilcSave)` before copying, so it respects `LocalImageAccess` and `OnBeforeLoadImage`. It copies nothing if `AutoLoadLocalImages` is `False`. Names in conflict get a numeric suffix; a different file that is already there is never overwritten, an identical one is reused.
- `UpdateModel`: at the end `UpdateSourcesAfterExport` rewrites the `src` values of the model to point to the copies (relative in `ipmDocument`, absolute in `ipmApplication`) and reloads the images. Without `UpdateModel`, and with copies made, `DocumentPath` does not move: the `src` values in memory must keep resolving against the originals.
