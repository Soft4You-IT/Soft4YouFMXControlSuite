# TS4YHTMLEditor - Developer Guide

This guide is for developers who **use** `TS4YHTMLEditor` in an application. It explains how the control behaves and what to be careful about. The [README](../README.md) is the reference for installation, supported HTML, and the complete list of properties, methods and events. [Architecture.md](Architecture.md) describes the internals for people who modify the component.

Everything below was checked against the source code of the component. Where the behaviour is a limitation rather than a design choice, it is said so.

---

## 1. How the control works, in five lines

1. The HTML is parsed into a **document model**: a list of paragraphs, each holding a list of styled runs.
2. A **layout engine** turns the model into positioned fragments (pieces of text, images, rules) for the current width.
3. The control draws the fragments into an off-screen **render cache** (a bitmap) and copies it to the screen.
4. The selection and the list markers are part of that cache, so changing the selection redraws it. The caret is drawn over the cache: blinking it, or moving it without a selection, only repaints the caret.
5. Everything runs on the **UI thread**. The control is not thread-safe: call it only from the main thread.

What this means for you: the cost of a layout grows with the length of the document, while the cost of a repaint follows the size of the window (only what is near the visible area is drawn).

The document model is described in [Architecture.md](Architecture.md#1-data-model-ts4yhtmldocument). The control does not expose it as a whole: from the outside you reach it through `CurrentRun` and `Placeholders`, and you can use the classes `TS4YHTMLParser` and `TS4YHTMLGenerator` on their own (see the recipe at the end of this guide).

---

## 2. Getting content in and out

| You want to | Use | Notes |
|---|---|---|
| Set the body of a document | `HTML` | A fragment, no `<html>`/`<body>` wrapper |
| Set or read a complete document | `FullHTML` | Reads `Title` and `Language`; writing extracts them from `<title>` and `<html lang>` |
| Load or save a file | `LoadFromFile` / `SaveToFile` | UTF-8 by default. `LoadFromFile` also sets `DocumentPath` |
| Insert at the caret | `InsertText`, `InsertHTML`, `InsertImage`, ... | Undoable, fire `OnChange` |

Points to know:

- **Setting the content does not fire `OnChange`.** `HTML := ...`, `FullHTML := ...` and `LoadFromFile` replace the document and fire only `OnStateChange`. `OnChange` is for edits made after the content is loaded, so a handler such as "mark the document as modified" is not triggered by loading.
- **Setting the content clears the undo and redo history**, the caret goes to the start, and the scroll position is reset.
- **Reading `HTML` regenerates it** from the model each time. If you need it often (for example on every `OnChange`), keep it in a variable instead of reading it repeatedly on a large document.
- An empty document reads back as `''`, not as an empty paragraph.
- `HTML` is notified to LiveBindings after each edit, so the property can be used as a binding source.

---

## 3. Events: when they fire and what they may do

| Event | Fires | Keep in mind |
|---|---|---|
| `OnChange` | After every change to the document: typing, deleting, formatting (`ToggleBold`, fonts, colours, alignment, headings, lists, `Indent`), `InsertText`, `InsertHTML`, `InsertLink`, `InsertImage`, tables, `Cut`, `Paste`, `Undo`, `Redo`, `ReplaceAll` | **Not** after `HTML`/`FullHTML`/`LoadFromFile`; may fire more than once for one action, see the note below |
| `OnStateChange` | When the caret or selection moves, after edits, and after the content is replaced | The `State` record is computed for each call: keep the handler light |
| `OnLinkClick` | On mouse release over a link, if nothing is selected | |
| `OnLinkHover` | When the pointer enters a link; you may change the cursor | |
| `OnBeforeLoadImage` / `OnLoadImage` | While images are loaded; see section 5 | |
| `OnGetListMarker`, `OnDrawListMarker` | While the editor draws a list item | See the warning below |
| `OnGetPlaceholderLabel`, `OnDrawPlaceholder` | While the editor lays out or draws a placeholder | See the warning below |

### `OnChange` means "the document changed", not "once per action"

One user action can fire `OnChange` more than once. For example, inserting an image while some text is selected first deletes the selection (one event) and then inserts the image (a second event). Use `OnChange` as "something changed" (set a flag, schedule a refresh), never as a counter. Setting the content with `HTML`, `FullHTML` or `LoadFromFile` does not fire it.

### Drawing events run while painting

`OnDrawListMarker`, `OnGetListMarker`, `OnDrawPlaceholder` and `OnGetPlaceholderLabel` are called from inside the painting code. Therefore:

- **They are called only for the items near the visible area**, not for every item of the document. A list item that is scrolled far out of view does not trigger `OnDrawListMarker` or `OnGetListMarker`, and a placeholder far out of view does not trigger `OnDrawPlaceholder`. Do not use these events to count, collect or initialise something for all the items of the document; use `Placeholders` or the document itself for that.
- **They are called repeatedly**, once for every time the render cache is redrawn: on scroll, on resize, on every edit, on selection change, and when the caret enters or leaves a placeholder. A caret blink, or a caret move without a selection, does not redraw the cache. The result must always be the same for the same input, and the handler must be fast (no I/O, no dialogs, no allocation of big objects).
- **Do not modify the editor from inside them** (no `HTML :=`, no `Insert...`, no `Repaint` loops). Draw on the `Canvas` you receive and nothing else.
- `OnGetPlaceholderLabel` is also called during layout, so it can be called for placeholders that are not visible. Treat it as a pure mapping from the raw text to the label.

`OnGetListMarker` has priority over `OnDrawListMarker` for bullets (unordered lists). Numbered lists always draw the number.

### Updating a toolbar from `OnStateChange`

`State` holds the formatting at the caret (bold, font, list type, alignment, image properties, link, position in line and column ...). Assign it to your buttons in the handler. Do not enable or disable controls in a way that moves the focus away from the editor.

---

## 4. Read-only mode

`ReadOnly := True` is meant for displaying content. It blocks the **user's** attempts to change the document:

- typing, `Backspace`, `Delete`, `Enter`;
- `Paste` and `PasteAsPlainText`;
- the shortcuts that change the document: `Ctrl+B`, `Ctrl+I`, `Ctrl+U`, `Ctrl+X`, `Ctrl+Z`, `Ctrl+Y` (the keys are consumed and do nothing);
- adding or removing table rows and columns, and `Tab` appending a row;
- the Undo, Redo, Cut and Paste items of the context menu.

Selection, copy and clicking links still work.

**What it does not block:** the methods that your own code calls. As with the `Lines` of a `TMemo`, `ReadOnly` limits the user, not the program: `InsertText`, `InsertHTML`, `ToggleBold`, `Undo` and the other editing methods still change a read-only document. This is deliberate, so that an application can fill or update a view that the user cannot edit. If you wire such methods to buttons, disable the buttons yourself while the control is read-only.

---

## 5. Images

The complete rules for sources, relative paths, saving and local-file access are in the README section [Images and files](../README.md#images-and-files). The points below are the ones that most often surprise.

- **Loading is synchronous, on the UI thread.** A remote image (`http://`, `https://`) is downloaded while the document is being loaded, and the application waits for it. There is no timeout set by the component. For documents with many or slow remote images, set `AutoLoadRemoteImages := False` and call `LoadRemoteImages` at a moment of your choice, or supply the bitmaps yourself in `OnLoadImage`.
- With `AutoLoadLocalImages` or `AutoLoadRemoteImages` set to `False`, the images are drawn as placeholders of 200 x 120 pixels (if the HTML gives no size) until you call `LoadLocalImages` or `LoadRemoteImages`.
- **Each `src` is loaded once** and kept in a cache. The cache is cleared when you set the content, change `DocumentPath`, `ImagePathMode` or `LocalImageAccess`, or call `ReloadImages`. If a file changed on disk, call `ReloadImages`: it applies the same checks as the first load (`LocalImageAccess`, `OnBeforeLoadImage`), so an image that is now refused keeps its previous bitmap.
- **Refused images are remembered.** If `OnBeforeLoadImage` refuses an image and `OnLoadImage` supplies nothing, the editor does not ask again at each repaint. The memory is cleared at the same moments as the cache.
- `OnLoadImage` receives the `src` exactly as written in the document and a context (`ilcParse`, `ilcInsert`, `ilcReload`, `ilcRender`, `ilcSave`) that tells why the image is needed. The bitmap you assign is owned by the editor's cache.
- **Untrusted content:** when you display HTML you did not write (for example an e-mail), use `LocalImageAccess := liaDocumentFolder` with an empty `DocumentPath`, and decide about remote images with `AutoLoadRemoteImages` and `OnBeforeLoadImage`. The default (`liaAnywhere`) lets the HTML name any readable file.

---

## 6. Placeholders

Placeholders are non-editable chips for merge fields. `PlaceholderPrefix` and `PlaceholderSuffix` tell the parser which raw text becomes a chip. **Both are empty by default, and placeholders are disabled until both are set**: with either one empty, `InsertPlaceholder` and `UpdatePlaceholder` do nothing and the text is not recognised in the HTML.

- Insert one with `InsertPlaceholder(RawText[, DisplayName])`, replace the one under the caret with `UpdatePlaceholder`.
- `Placeholders` is a live list of all placeholder runs, kept in sync on every edit. Reading it is cheap. Do not modify the list or the runs from outside.
- The label shown can come from `DisplayName`, from `OnGetPlaceholderLabel`, or be the raw text, in that order of priority.
- Style the chips with `PlaceholderAppearance`. For full control use `OnDrawPlaceholder` (see section 3 for its constraints).

---

## 7. Undo and redo

- Up to 100 levels, kept as complete copies of the document. With very large documents each step costs memory and time proportional to the document size.
- Setting the content (`HTML`, `FullHTML`, `LoadFromFile`) clears the history.
- `ReplaceAll` is a single undo step.

---

## 8. Performance

What is cheap:

- Moving the caret, scrolling, selecting: the repaint cost follows the window size, not the document length. Blinking the caret and moving it without a selection only repaint the caret over the cache.
- Reading `Placeholders`, `HasSelection`, `State`.

What costs time, in proportion to the document length:

- A full layout, which is redone on every edit, on resize and when the font or the spacing properties change. For bulk changes, build the HTML string first and set it once instead of inserting piece by piece.
- Setting the content, which parses, loads images and lays out.
- `HTML` / `FullHTML` getters, `SelHTML`, `CharCount`, `WordCount`.
- Undo snapshots (see above).
- The first display of a document with emoji on Windows (colour-font fallback); later layouts are fast.

Rules of thumb:

- Do not set `LineSpacing`, `ParagraphSpacing` or the font repeatedly in a loop: each change triggers a layout.
- Keep the drawing events (section 3) and `OnStateChange` light, they run very often.
- Load heavy or remote images on demand (section 5).

---

## 9. Design time and platforms

- At design time the control shows its content but does not blink the caret and does not create the scrollbar.
- Supported platforms: Windows, macOS, iOS, Android. Developed and tested on Windows.
- Clipboard: on Windows the control exchanges `CF_HTML` and plain text. On the other platforms the HTML fragment is placed on the clipboard as plain text, and pasting it back into the same editor restores the formatting.
- The keyboard shortcuts test the `Ctrl` key only; the control does not map them to `Cmd` on macOS.

---

## 10. Recipes

### A formatting toolbar

```delphi
procedure TfrmMain.HTMLEditorStateChange(Sender: TObject; const State: TS4YEditorState);
begin
  btnBold.IsPressed := State.IsBold;
  btnItalic.IsPressed := State.IsItalic;
  btnOutdent.Enabled := State.CanOutdent;
  lblPosition.Text := Format('Ln %d, Col %d', [State.LineNumber, State.ColumnNumber]);
end;

procedure TfrmMain.btnBoldClick(Sender: TObject);
begin
  HTMLEditor.ToggleBold;
  HTMLEditor.SetFocus;
end;
```

### Style the cells of a table from a toolbar

The commands act on the cell that holds the caret, or on every cell that the selection touches (in the table where the selection starts). The commands for the borders, the alignment and the width of the table use the innermost table that holds the caret. All of them do nothing outside a table and in read-only mode, and each one is a single undo step and raises `OnChange` once. `State` tells the current values, so that a toolbar can follow the caret.

```delphi
procedure TfrmMain.HTMLEditorStateChange(Sender: TObject; const State: TS4YEditorState);
begin
  gbTable.Enabled := State.IsInTable;
  btnBorder.IsPressed := State.TableHasBorder;
  btnMiddle.IsPressed := State.TableCellVerticalAlignment = tvaMiddle;
end;

procedure TfrmMain.btnCellColorClick(Sender: TObject);
begin
  HTMLEditor.SetTableCellBackgroundColor(TAlphaColors.Lightyellow);
  HTMLEditor.SetTableCellPadding(TS4YTablePadding.Uniform(8));
  HTMLEditor.SetTableWidth(TS4YTableLength.Percent(80));
end;
```

### Open and save a document with its images

```delphi
HTMLEditor.ImagePathMode := ipmDocument;
HTMLEditor.LoadFromFile(LFileName);

var LOptions: TS4YSaveOptions;
LOptions.Init;
LOptions.CopyImages := True;
HTMLEditor.SaveToFile(LFileName, LOptions);
```

### Show an incoming e-mail safely

```delphi
HTMLEditor.ReadOnly := True;
HTMLEditor.LocalImageAccess := liaDocumentFolder;  // DocumentPath stays empty: no local file is read
HTMLEditor.AutoLoadRemoteImages := False;           // no network access until the user agrees
HTMLEditor.HTML := LMessageBody;
// later, if the user allows it:
HTMLEditor.LoadRemoteImages;
```

Remember (section 4) that `ReadOnly` does not stop the editing methods that your own code calls.

### Detect that the user changed the document

```delphi
procedure TfrmMain.HTMLEditorChange(Sender: TObject);
begin
  FModified := True;   // not fired by HTML := / LoadFromFile
end;

function TfrmMain.IsDocumentModified: Boolean;
begin
  // alternative that ignores edits which were undone: compare with the text saved or loaded last
  Result := HTMLEditor.HTML <> FSavedHTML;
end;
```

Set `FModified := False` (and refresh `FSavedHTML`) yourself after loading or saving.

### Convert HTML without a control

The parser and the generator do not need a visual control (they do not use FMX), so they can clean up or reformat HTML in a service or a console tool.

```delphi
uses
  Soft4You.HTML.Document,
  Soft4You.HTML.Parser,
  Soft4You.HTML.Generator;

function TidyHTML(const AHTML: string): string;
var
  LParser: TS4YHTMLParser;
  LGenerator: TS4YHTMLGenerator;
  LDocument: TS4YHTMLDocument;
begin
  LParser := TS4YHTMLParser.Create;
  LGenerator := TS4YHTMLGenerator.Create;
  try
    LDocument := LParser.Parse(AHTML);
    try
      LGenerator.Pretty := True;
      Result := LGenerator.Generate(LDocument);
    finally
      LDocument.Free;
    end;
  finally
    LGenerator.Free;
    LParser.Free;
  end;
end;
```

What to expect from the round trip:

- `Parse` returns a new document that you must free, and it always has at least one paragraph (an empty input gives `<p></p>`).
- Only the HTML the editor supports is kept (see the README). The text inside an unknown tag such as `section` is kept, the tag itself is dropped; `video` and similar elements are lost.
- White space is collapsed, as a browser does outside `pre`. A single space between two inline elements (`<b>a</b> <i>b</i>`) is kept as a space; between blocks, after a `<br>` and at the end of a paragraph it is dropped.
- In tables `colspan` and `rowspan` are kept (up to 100), and a row with fewer cells than the widest one is completed with empty cells. The editor cannot merge or split cells, and it does not insert or delete rows and columns in a table that has merged cells. A cell keeps all its block elements (`p`, headings, lists, `hr`) as paragraphs with the same `TableID`, `TableRow` and `TableCol`, and a table inside a cell is kept as a nested table (see `TableContainers` in the architecture notes). The width of a table or of a cell (`width` attribute or style, in pixels, points or percent), `max-width`, `align`, automatic horizontal margins and `border="0"` are kept and written back, and so are the background, padding, vertical alignment and text alignment of a cell. The font, size, weight and color written on a table, a cell or a block (`p`, `div`, `h1`-`h6`, `li`, ...) become the style of the runs inside it.
- `Generate` writes the content only, without the `html` and `body` elements. `Pretty := True` adds line breaks between the blocks and indents the rows of tables.
- `ImageSourceConverter` is called for every image and returns the value to write in its `src`.
