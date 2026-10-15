# TNativeHTMLEditor — Architettura

## Pipeline generale

Il componente è organizzato in quattro livelli indipendenti che lavorano in pipeline:

```
HTML string
    ↓  TS4YHTMLParser
TS4YHTMLDocument  (modello dati)
    ↓  TS4YLayoutEngine
FFrags / FLines  (layout calcolato)
    ↓  Paint / TCanvas
Pixel su schermo
```

---

## 1. Modello dati (`TS4YHTMLDocument`)

Il documento è una lista di **paragrafi** (`TS4YHTMLParagraph`), ciascuno contenente una lista di **run** (`TS4YHTMLRun`).

```
TS4YHTMLDocument
 └─ TS4YHTMLParagraph  [BlockType, Alignment, IndentLevel, ListOrdered, ListIndex]
      └─ TS4YHTMLRun   [Text: string, Style: TS4YHTMLTextStyle, IsLineBreak, IsImage, IsPlaceholder]
      └─ TS4YHTMLRun   ...
 └─ TS4YHTMLParagraph  ...
```

Un **run** è il segmento minimo di testo omogeneo per stile. Se scrivi "ciao **mondo**", il paragrafo ha due run: `"ciao "` con stile normale e `"mondo"` con Bold=True.

Un paragrafo **vuoto** è rappresentato con `Runs.Count = 0` — non da un run con `Text=''`. Questa distinzione è critica per il layout (dettaglio nella sezione Layout engine).

La posizione del cursore è un `TS4YDocumentPosition` con tre interi:

```
ParagraphIndex  →  indice del paragrafo
RunIndex   →  indice del run dentro quel paragrafo
CharIndex  →  posizione all'interno di Run.Text (0 = prima del primo char)
```

### Run speciali

`TS4YHTMLRun` usa flag booleani per identificare i tipi non-testo:

| Flag | Significato |
|---|---|
| `IsImage` | Run è un'immagine inline (ha `ImageSource`, `ImageWidth`, `ImageHeight`) |
| `IsPlaceholder` | Run è un chip non modificabile (ha `RawText`, `DisplayName`) |
| `IsLineBreak` | Run rappresenta un `<br>` |

### Indentazione (`IndentLevel`)

Ogni `TS4YHTMLParagraph` ha un campo `IndentLevel: Integer` (0 = nessuna indentazione):

- **`btBlockquote`**: ogni livello di `<blockquote>` annidato incrementa `IndentLevel` di 1.
- **`btLI`**: `IndentLevel = 0` per liste al primo livello, `IndentLevel = 1` per il primo annidamento, ecc. `Indent`/`Outdent` modificano questo valore; `Outdent` è abilitato solo se `IndentLevel > 0`.

---

## 2. Layout engine (`TS4YLayoutEngine`)

Il layout engine converte il modello dati in due array piatti:

- **`FFrags: TArray<TS4YLayoutFragment>`** — ogni frammento è un pezzo di testo misurabile, con coordinate X/Y/W/H in pixel (coordinate documento, senza scroll).
- **`FLines: TArray<TS4YLayoutLine>`** — ogni riga logica del documento, con Y, H, ascent, e gli indici di inizio/fine nei `FFrags`.

### Come funziona `LayoutParagraph`

1. Per ogni run, spezza il testo in parole (`FindWordEnd` cerca il primo spazio e poi tutti gli spazi successivi).
2. Misura ogni parola con `TTextLayout.MeasureStr` usando il font del run.
3. Se la parola non entra sulla riga corrente (`LineW + WordW > AvailW`), chiama `FlushLine` che finalizza la riga: applica l'allineamento (haLeft/haCenter/haRight/haJustify), assegna le coordinate X/Y a ogni fragment, e aggiunge la riga a `FLines`.
4. Al termine di tutti i run, fa un `FlushLine` finale per l'ultima riga.

### Indentazione nel layout

Per i paragrafi `btBlockquote`, l'offset orizzontale è:

```
LIndentX := IndentLevel * C_EDITOR_BLOCKQUOTE_INDENT
```

Per i paragrafi `btLI`, l'offset include sia il margine fisso che lo spazio per il marcatore:

```
LIndentX := (IndentLevel + 2) * C_EDITOR_LIST_INDENT
```

Il `+2` fissa: 1 unità di margine sinistro + 1 unità per l'area del marcatore (bullet/numero). In questo modo `IndentLevel = 0` produce il rientro base tipico dei browser (~40 px con `C_EDITOR_LIST_INDENT = 20`).

### Caso speciale — paragrafo vuoto (`Runs.Count = 0`)

Il loop non ha nulla da iterare. Il codice crea esplicitamente un fragment placeholder con `W=0` e `CharStart=CharEnd=0`, necessario affinché `DocumentPositionToXY` possa trovare la posizione del cursore in un paragrafo senza testo.

```pascal
// Empty paragraph – still needs at least one empty fragment for caret
if Para.Runs.Count = 0 then begin
  // crea un fragment vuoto e chiama FlushLine
  Exit;
end;
```

> **Nota critica:** un run con `Text=''` (Runs.Count = 1 ma testo vuoto) NON entra nel caso speciale. Il loop `while Rest <> ''` non itera mai, `LineFrags` rimane vuoto, e `FlushLine` viene saltato. Il risultato è zero fragment per quel paragrafo, rendendo `DocumentPositionToXY` incapace di trovare la posizione del cursore. Un paragrafo vuoto deve sempre avere `Runs.Count = 0`.

### Quando viene ricalcolato il layout

`DoLayout` viene chiamato ogni volta che:
- viene digitato un carattere
- viene premuto Invio
- il controllo viene ridimensionato
- viene impostato l'HTML

---

## 3. Rendering (`Paint`)

`Paint` viene chiamato da FMX ogni volta che il controllo deve essere ridisegnato. La sequenza è fissa:

```
PaintBG        → riempie il rettangolo di sfondo (con BackgroundColor)
PaintSelection → disegna i rettangoli blu della selezione
loop FFrags    → PaintFrag per ogni fragment (testo)
loop Paragraphs → list markers (bullet / numero per <ul>/<ol>)
PaintCaret     → disegna la linea verticale del cursore
PaintBorder    → disegna il bordo del controllo
```

**`PaintFrag`** crea un `TTextLayout` FMX per ogni fragment, imposta font/dimensione/stile, lo posiziona a `ContentLeft + F.X, ContentTop + F.Y`, e chiama `RenderLayout`. Il `ContentTop` incorpora lo scroll: `EDITOR_PADDING - FScrollY`.

**`PaintCaret`** disegna semplicemente una linea verticale nelle coordinate `FCaretScreenX, FCaretScreenY` con altezza `FCaretScreenH`. Disegna **solo se `FCaretOn = True`**.

**Blink del cursore:** Un `TTimer` con intervallo 530ms chiama `OnCaretTick`, che alterna `FCaretOn` tra True e False e chiama `Repaint`. L'effetto lampeggio è interamente gestito con questo toggle + ridisegno.

### Rendering dei marcatori di lista

Dopo il loop dei fragment, un secondo loop sui paragrafi cerca quelli con `BlockType = btLI`. Per ciascuno, il codice trova il primo fragment di quel paragrafo per ricavare la posizione Y e poi disegna il marcatore nell'area a sinistra del testo (`X = FragX - C_EDITOR_LIST_INDENT`).

**Priorità di rendering del bullet** (unordered list):

1. Se `OnGetListMarker` è assegnato → restituisce un carattere Unicode; viene renderizzato con `TTextLayout` centrato nell'area marker.
2. Altrimenti se `OnDrawListMarker` è assegnato → delega il disegno all'handler; se `Handled=True` il default viene saltato.
3. Default: ciclo su `IndentLevel mod 3`:
   - `0` → disco pieno (`FillEllipse`)
   - `1` → cerchio vuoto (`DrawEllipse`)
   - `2+` → quadrato pieno (`FillRect`)

Per le liste ordinate il marcatore è sempre un `TTextLayout` con il numero seguito da punto (`"1."`, `"2."`, …).

---

## 4. Input da tastiera

`KeyDown` gestisce due tipi di input:

### Caratteri stampabili (`KeyChar >= ' '`)

```
KeyDown → InsertChar(Ch)
           ├─ prende lo stile corrente (StyleAtCaret)
           ├─ se il paragrafo è vuoto: crea il primo run
           ├─ se lo stile del run non corrisponde: splitta il run e ne crea uno nuovo
           ├─ altrimenti: inserisce il carattere nella stringa del run corrente
           ├─ NormalizeRuns: fonde run adiacenti con lo stesso stile
           ├─ ricalcola FCaretPosition usando un offset assoluto (invariante a NormalizeRuns)
           └─ DoLayout → Changed → Repaint
```

### Tasti speciali

| Tasto | Azione |
|---|---|
| `vkBack` | `DeleteBack`: cancella il char prima del cursore; se a inizio paragrafo, fonde con il paragrafo precedente (`MergeWithPrev`) |
| `vkDelete` | `DeleteFwd`: cancella il char dopo il cursore |
| `vkReturn` | `InsertParagraphBreak`: divide il paragrafo corrente in due |
| `←→↑↓` | `SetCaretPosition` con `PreviousDocumentPosition/NextDocumentPosition/LineAbove/LineBelow` |
| `Home/End` | inizio/fine riga o documento (con Ctrl) |
| `Ctrl+Z/Y` | Undo/Redo (snapshot dell'intero documento) |
| `Ctrl+B/I/U` | toggle grassetto/corsivo/sottolineato sulla selezione |
| `Ctrl+C/X/V` | clipboard |

### `InsertParagraphBreak` (Invio) in dettaglio

1. Splitta il run al punto del cursore (`SplitRunAt`)
2. Crea un nuovo `TS4YHTMLParagraph` copiando BlockType/Alignment/IndentLevel
3. Sposta tutti i run **dopo** il cursore nel nuovo paragrafo
4. Il vecchio paragrafo viene normalizzato (`NormalizeRuns`) — se non rimane nulla, `Runs.Count` sarà 0
5. `DoLayout` viene chiamato **prima** di `SetCaretPosition`, così `FFrags` contiene già il fragment placeholder del nuovo paragrafo vuoto
6. `SetCaretPosition(NewParaIdx, 0, 0)` sposta il cursore all'inizio della nuova riga

---

## 5. Caret: dal documento allo schermo

Il caret non ha coordinate native — le sue coordinate pixel vengono calcolate on-demand da `DocumentPositionToXY`:

```
DocumentPositionToXY(FCaretPosition)
  → cerca in FFrags il fragment che contiene (ParagraphIndex, RunIndex, CharIndex)
  → misura con MeasureCharOffset la distanza in pixel dall'inizio del fragment
  → ritorna X = ContentLeft + F.X + offset
             Y = ContentTop + F.Y
             H = altezza della riga
```

`UpdateCaretXY` chiama `DocumentPositionToXY` e salva il risultato in `FCaretScreenX/Y/H`. Questi vengono usati da `PaintCaret` ad ogni ridisegno.

`SetCaretPosition` è il punto unico di accesso per spostare il cursore:
- aggiorna `FCaretPosition`
- resetta il blink (toggle `False/True` del timer — necessario perché Delphi non resetta l'intervallo se `Enabled` è già `True`)
- chiama `UpdateCaretXY`
- chiama `EnsureCaretVisible` (scroll se il cursore è fuori viewport)
- chiama `Repaint`
- chiama `NotifyState` (notifica alla toolbar lo stato corrente di grassetto/corsivo/ecc)

---

## 6. Cache dei placeholder (`FPlaceholders`)

`FPlaceholders: TList<TS4YHTMLRun>` è una cache che tiene traccia di tutti i run con `IsPlaceholder = True` presenti nel documento, senza dover scansionare ogni volta l'intero albero.

La cache è esposta in sola lettura come `property Placeholders: TList<TS4YHTMLRun>`.

### Punti di sincronizzazione

| Operazione | Aggiornamento |
|---|---|
| `SetHTML` | `RebuildPlaceholderList` (ricostruzione completa) |
| `InsertHTML` | `RebuildPlaceholderList` |
| `InsertPlaceholder` | `FPlaceholders.Add(LRun)` (incrementale) |
| `DeleteBack` / `DeleteFwd` su placeholder | `FPlaceholders.Remove(LRun)` prima della rimozione del run |
| `DeleteSel` | `RebuildPlaceholderList` (operazione complessa) |
| `Undo` / `Redo` | `RebuildPlaceholderList` dopo il ripristino del documento |

`RebuildPlaceholderList` scansiona l'intero documento e ricrea la lista da zero; viene usato solo nelle operazioni che modificano strutturalmente il documento. Le operazioni semplici usano aggiornamento incrementale.
