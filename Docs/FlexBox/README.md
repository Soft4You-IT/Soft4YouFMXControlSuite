# TS4YFlexBox per FireMonkey — Guida all'installazione e all'uso

Componenti FMX che implementano il modello CSS Flexbox (W3C Level 1):

- **`TS4YFlexBox`**: il contenitore, con le proprietà CSS del container.
- **`TS4YFlexItem`**: l'elemento del flexbox, con le proprietà CSS dell'item.
  Ogni controllo che partecipa al layout vive dentro un `TS4YFlexItem`.

Namespace: `Soft4You.FMX.Controls.FlexBox.*`.

## Struttura del progetto

```
S4YFlexBox/
├── Sources/
│   ├── Soft4You.FMX.Controls.FlexBox.Engine.pas    ← Algoritmo CSS FlexBox puro (stateless, no FMX)
│   ├── Soft4You.FMX.Controls.FlexBox.pas           ← TS4YFlexBox e TS4YFlexItem (runtime)
│   ├── Soft4You.FMX.Controls.FlexBox.Strings.pas   ← Messaggi (resourcestring) del runtime
│   ├── Soft4You.FMX.Controls.FlexBox.Types.pas     ← Tipi semplici (modalità e override dei breakpoint)
│   ├── Soft4You.FMX.Controls.FlexBox.ItemBase.pas  ← Base di TS4YFlexItem (rompe la dipendenza circolare coi breakpoint)
│   ├── Soft4You.FMX.Controls.FlexBox.Breakpoints.pas ← Collezione dei breakpoint (soglie sulla larghezza)
│   ├── Soft4You.FMX.Controls.FlexBox.Design.pas    ← Wrapping automatico nel designer (design-time)
│   └── Soft4You.FMX.Controls.FlexBox.Register.pas  ← Registrazione dei componenti nella palette
├── Packages/
│   ├── S4YFlexBox.dpk / .dproj                     ← Package RUNTIME  → Build (non Install)
│   ├── S4YFlexBoxD.dpk / .dproj                    ← Package DESIGN   → Install
│   └── S4YFlexBox.groupproj                        ← Gruppo con i due package
├── Resources/
│   ├── FlexBoxDesign.rc                            ← Resource script icona palette (risorsa TS4YFLEXBOX)
│   ├── FlexBoxDesign.res                           ← Compilato da FlexBoxDesign.rc (vedi sotto)
│   ├── FlexBox24.bmp / FlexBox16.bmp               ← Icona di TS4YFlexBox (24×24 usata dalla palette)
│   └── FlexItem24.bmp / FlexItem16.bmp             ← Icona di TS4YFlexItem (risorsa TS4YFLEXITEM)
├── Tests/
│   └── Soft4You.FMX.Controls.FlexBox.Engine.Tests.pas  ← Suite DUnitX (29 test)
├── Docs/
│   ├── ANALYSIS_ChildrenFiltering.md               ← Analisi del filtraggio dei figli
│   └── fmx-flexbox-roadmap.html                    ← Architettura e roadmap
├── Demo/
│   └── S4YFelxBoxDemo.dpr / frmMain.pas / .fmx     ← Dashboard di esempio (vedi "Demo")
└── README.md
```

| Cartella    | Contenuto                                              |
|-------------|--------------------------------------------------------|
| `Sources`   | Tutte le unit (`.pas`) del componente                  |
| `Packages`  | Package runtime e design-time, gruppo di progetti      |
| `Resources` | Icona della palette (`.rc`, `.res`, `.bmp`)            |
| `Tests`     | Test DUnitX del motore                                 |
| `Docs`      | Documentazione aggiuntiva                              |
| `Demo`      | Applicazione di esempio (dashboard "Sales overview")   |

---

## Come funziona

Un `TS4YFlexBox` posiziona i suoi `TS4YFlexItem`. Ogni item contiene **un solo
controllo**. Finché l'altezza dell'item è automatica (`AutoHeight = True`) il
controllo è `Align = Top` e l'item ne segue l'altezza; con un'altezza esplicita
(`AutoHeight = False`) il controllo resta `Align = Top` con la propria altezza (mai `Client`): l'item ha l'altezza data e il controllo, per esempio un `TExpander`, puo' aprirsi e chiudersi da solo. Le proprietà flex di un
controllo (`FlexGrow`, `FlexShrink`, …) sono proprietà dell'item che lo contiene,
quindi si modificano nell'Object Inspector selezionando l'item.

Per inserire più controlli in una posizione del flexbox si usa come contenuto
dell'item un contenitore (layout, panel, ecc.).

### Wrapping automatico

Quando un controllo che non è un `TS4YFlexItem` diventa figlio di un
`TS4YFlexBox`, viene creato un `TS4YFlexItem` con la stessa posizione e le stesse
dimensioni, e il controllo viene spostato al suo interno con `Align = Top`
(altezza automatica, vedi sotto). I margini (`Margins`) del controllo passano
all'item.

- **A design-time**: trascina un controllo nel flexbox; l'item viene creato dal
  designer (nome, Structure view, annulla) e il controllo viene inserito al suo
  interno.
- **A runtime**: `LButton.Parent := LFlexBox` crea l'item in automatico. Dopo
  l'assegnazione `LButton.Parent` è il `TS4YFlexItem`, non il flexbox.
- **Durante il caricamento del DFM** non avviene alcun wrapping.
- **Un item ospita un solo controllo**: un secondo controllo rilasciato su un
  item occupato (ad esempio sul suo padding) non viene accettato dall'item e
  ottiene un item dedicato nel flexbox.
- **Un item rilasciato su un altro item** (ad esempio nella Structure view) non
  diventa figlio dell'altro: torna nel flexbox in posizione precedente a quello
  di destinazione (vedi "Riordino degli item" nel capitolo Design-time).
- **Item vuoti**: un item che resta senza controlli viene eliminato e gli
  altri item si riposizionano.
- **Un item vive solo in un `TS4YFlexBox`**: a runtime assegnare a un
  `TS4YFlexItem` un `Parent` diverso da un flexbox (per esempio un pannello, o
  un altro item) solleva `EInvalidOperation`. La regola non vale durante il
  caricamento del DFM né a design-time, dove il designer crea l'item in
  transito prima di riportarlo nel flexbox.
- **L'item non è in palette**: lo crea il flexbox, non va inserito a mano.
  È registrato con `RegisterNoIcon`, per cui nella Structure view ha l'icona
  generica dell'IDE.

### Altezza automatica e dimensione di design

Come in CSS (`height: auto`), l'altezza di un item può essere **automatica** o
**esplicita**:

- **Automatica** (`AutoHeight = True`, il default): l'altezza naturale dell'item è
  l'altezza del controllo contenuto più il `Padding` dell'item. Se il contenuto
  cambia altezza da solo (un `TExpander` che si apre o si chiude, ad esempio)
  l'item lo segue e il flexbox si riorganizza.
- **Esplicita** (`AutoHeight = False`): l'altezza è quella impostata, e il
  contenuto la riempie. Diventa esplicita da sola quando si modifica `Height`
  dell'item o lo si ridimensiona nel designer. Per tornare automatica si rimette
  `AutoHeight` a `True`: il contenuto resta all'altezza che aveva, quindi può
  servire riportarlo a mano a quella voluta.

La **dimensione di design** dell'item (l'ultima `Width`/`Height` scelta
dall'utente, usata dal motore come dimensione naturale) è distinta dalla
dimensione calcolata dal layout (ad esempio stirata con `AlignItems = aiStretch`).
Così ridurre un item riporta la riga alle dimensioni naturali degli altri. Nel
file `.fmx` si salvano `Size` (quella calcolata) e, solo se diverse,
`DesignWidth`/`DesignHeight` (non visibili nell'Object Inspector).

### Larghezza automatica

Anche la larghezza può essere **automatica** (`AutoWidth = True`, il default) o
**esplicita** (`AutoWidth = False`, che diventa vera da sola quando si modifica
`Width` dell'item o lo si ridimensiona nel designer). Come in CSS, una
dimensione automatica sull'asse trasversale si adatta, una esplicita no:

- **Stretch** (`AlignItems = aiStretch`, o `AlignSelf = asStretch`): vale solo per
  una dimensione automatica. Un item con altezza esplicita in una riga, o con
  larghezza esplicita in una colonna, mantiene la propria dimensione.
- **Fit-content** in colonna: la larghezza di un item automatico non supera la
  larghezza disponibile del flexbox (con `AlignItems` diverso da stretch resta
  la larghezza di design, ridotta se non entra). Una larghezza esplicita non
  viene ridotta.
- **Linea singola** (`Wrap = fwNoWrap`): l'unica linea occupa tutta la dimensione
  trasversale del flexbox, come in CSS. Quindi in una riga senza wrap gli item
  automatici si stirano all'altezza del flexbox, e `AlignItems`/`AlignSelf` con
  `Center` o `FlexEnd` posizionano gli item nell'altezza del flexbox. Con
  `fwWrap` le linee restano alte quanto il loro contenuto.

La larghezza di design resta la larghezza naturale dell'item: è il `FlexBasis`
quando questo è `fbuAuto`, e la larghezza di partenza del fit-content. Il
contenuto (`Align = Top`) segue la larghezza dell'item. Per usare invece la
larghezza propria del contenuto (per esempio una `TLabel` con `AutoSize`) vedi
"Larghezza dal contenuto".

### Larghezza dal contenuto

Con `FitContent = True` (default `False`) l'item prende la dimensione **propria
del contenuto**: la larghezza e l'altezza automatiche (non esplicite) diventano
quelle del contenuto più il `Padding` dell'item. È il caso di una `TLabel` con
`AutoSize` (e `WordWrap = False`, altrimenti `AutoSize` adatta solo l'altezza),
di un pulsante o di un'immagine che hanno già la propria misura.

- Il contenuto non è più `Align = Top`: resta alla sua dimensione, in alto a
  sinistra (dopo il `Padding` dell'item), anche quando l'item cresce per
  `FlexGrow` o stretch. Non viene stirato, altrimenti la sua misura propria si
  perderebbe al layout successivo.
- Quando il contenuto cambia dimensione (per esempio il testo di una label), il
  flexbox si ricalcola da solo. L'item si aggancia all'evento `OnResized` del
  contenuto, concatenando l'eventuale handler già assegnato dall'utente; se
  l'utente ne assegna un altro dopo, la misura viene comunque riletta a ogni
  layout.
- Una dimensione esplicita (`AutoWidth = False`, `AutoHeight = False`) resta
  quella scelta: `FitContent` vale solo per le dimensioni automatiche.
- Rimettendo `FitContent = False` il contenuto torna `Align = Top`.
- Una `TLabel` creata a run-time prende la propria misura solo quando cambia il
  testo: assegnare `Text` dopo averla inserita nel flexbox.

---

## Installazione passo per passo

### 1. Compila l'icona in risorsa

Prima di tutto, compila `FlexBoxDesign.rc` → `FlexBoxDesign.res`.
Esegui da riga di comando nella cartella `Resources`:

```bat
brcc32.exe FlexBoxDesign.rc
```

oppure con windres (MinGW):

```bat
windres FlexBoxDesign.rc -O res -o FlexBoxDesign.res
```

> Il file `FlexBoxDesign.res` incluso nel repository è già compilato.

### 2. Installa il package Runtime

1. `File → Open → Package` → seleziona `S4YFlexBox.dpk`
2. `Project → Build S4YFlexBox`
3. **NON** premere Install (è `{$RUNONLY}`)

### 3. Installa il package Design-time

1. `File → Open → Package` → seleziona `S4YFlexBoxD.dpk`
2. `Component → Install Package` (oppure tasto destro → Install)
3. L'IDE chiede conferma → OK

### 4. Verifica

Apri la Component Palette (`View → Tool Palette`).
Cerca il tab **"FireMonkey Layouts"**: deve apparire `TS4YFlexBox`.
`TS4YFlexItem` non compare in palette: lo crea il flexbox.

---

## Uso in un progetto

### Senza package (embed diretto)

Aggiungi al progetto le unit runtime:
```
Soft4You.FMX.Controls.FlexBox.Engine.pas
Soft4You.FMX.Controls.FlexBox.Strings.pas
Soft4You.FMX.Controls.FlexBox.Types.pas
Soft4You.FMX.Controls.FlexBox.ItemBase.pas
Soft4You.FMX.Controls.FlexBox.Breakpoints.pas
Soft4You.FMX.Controls.FlexBox.pas
```
Nessuna dipendenza esterna.

### Con package runtime

In `Project → Options → Packages`, aggiungi `S4YFlexBox` come
package runtime. L'app cercherà `S4YFlexBox.bpl` nella stessa cartella
dell'eseguibile.

---

## Piattaforme

Il componente **non è ancora stato testato su nessuna piattaforma**. Il codice
non usa API specifiche di Windows (`TFlexEngine` è puro Pascal e il componente
usa solo FMX), quindi in teoria è portabile, ma la compatibilità va verificata.

| Piattaforma       | Stato         |
|-------------------|---------------|
| Windows 32/64     | Non testato   |
| macOS ARM/x86     | Non testato   |
| iOS ARM64         | Non testato   |
| Android ARM/ARM64 | Non testato   |
| Linux 64 (FMXL)   | Non testato   |

---

## Proprietà CSS supportate

### Container (su TS4YFlexBox)

| Proprietà Delphi  | CSS equivalente    | Valori                                                         |
|-------------------|--------------------|----------------------------------------------------------------|
| `Direction`       | `flex-direction`   | `fdRow`, `fdRowReverse`, `fdColumn`, `fdColumnReverse`         |
| `Wrap`            | `flex-wrap`        | `fwNoWrap`, `fwWrap`, `fwWrapReverse`                          |
| `JustifyContent`  | `justify-content`  | `jcFlexStart/End/Center/SpaceBetween/SpaceAround/SpaceEvenly`  |
| `AlignItems`      | `align-items`      | `aiStretch/FlexStart/FlexEnd/Center/Baseline`                  |
| `AlignContent`    | `align-content`    | `acFlexStart/End/Center/SpaceBetween/SpaceAround/Evenly/Stretch`|
| `ColumnGap`       | `column-gap`       | `Single` (pixel)                                               |
| `RowGap`          | `row-gap`          | `Single` (pixel)                                               |

### Item (su TS4YFlexItem)

| Proprietà Delphi  | CSS equivalente  | Valori                                     |
|-------------------|------------------|--------------------------------------------|
| `FlexGrow`        | `flex-grow`      | `Single` ≥ 0 (default: 0)                 |
| `FlexShrink`      | `flex-shrink`    | `Single` ≥ 0 (default: 1)                 |
| `FlexBasis`       | `flex-basis`     | `Single` (valore numerico)                 |
| `FlexBasisUnit`   | *(unità basis)*  | `fbuAuto`, `fbuPixel`, `fbuPercent`        |
| `AlignSelf`       | `align-self`     | `asAuto/Stretch/FlexStart/FlexEnd/Center`  |
| `Order`           | `order`          | `Integer` (default: 0)                     |
| `AutoHeight`      | `height: auto`   | `Boolean` (default: `True`)                |
| `AutoWidth`       | `width: auto`    | `Boolean` (default: `True`)                |
| `FitContent`      | `width/height: auto` = dimensione del contenuto | `Boolean` (default: `False`), vedi "Larghezza dal contenuto" |
| `SizeConstraints` | `min-/max-width`, `min-/max-height` | gruppo con `MinWidth`, `MaxWidth`, `MinHeight`, `MaxHeight` (`Single` ≥ 0, default: 0 = nessun limite), come `Margins` |
| `Index`           | *(ordine sorgente)* | posizione dell'item nel flexbox, non salvata |

I limiti di `SizeConstraints` (`MinWidth`, `MaxWidth`, `MinHeight`, `MaxHeight`) valgono come in CSS: limitano anche una dimensione esplicita
(`max-width` batte `width`), si applicano a flex-grow e flex-shrink (lo spazio che un
item non può prendere o cedere va agli altri) e allo stretch sull'asse cross, e
contano per decidere quanti item stanno su una linea con il wrap. Riguardano l'item,
non il contenuto: se il contenuto è più alto di `MaxHeight`, sborda.

A parità di `Order` conta l'ordine sorgente, cioè la posizione dell'item nel
flexbox (`Index`).

Comportamenti con la dimensione "naturale" di un item (usata con
`FlexBasisUnit = fbuAuto`): è la dimensione di design (vedi sopra); i suoi `Margins` sono i margini CSS dell'elemento e il suo
`Padding` è lo spazio tra il bordo dell'item e il controllo contenuto.

Le proprietà pubblicate di `TS4YFlexItem` sono solo queste, più `Height`, `Margins`,
`Padding`, `Size`, `Visible` e `Width`: posizione e allineamento sono decisi dal flexbox.

---

## API programmatica

```delphi
// L'item di un controllo è il suo Parent, dopo l'assegnazione al flexbox
LButton.Parent := LFlexBox;
LItem := LButton.Parent as TS4YFlexItem;
LItem.FlexGrow := 1;
LItem.FlexBasis := 200;
LItem.FlexBasisUnit := fbuPixel;

// Creazione esplicita dell'item (equivalente al wrapping automatico)
LItem := LFlexBox.WrapControl(LButton);

// Forza ricalcolo
LFlexBox.InvalidateLayout;

// Riordino: a parità di Order conta la posizione dell'item
LItem.Index := 0;
```

---

## Eventi

Gli eventi partono **a layout concluso** e solo se qualcosa è cambiato; non
partono a design-time né durante il caricamento. Un handler che modifica il
contenuto avvia un nuovo layout: non rientra in quello in corso. Durante la
costruzione (aggiunta degli item, ridimensionamenti intermedi) il layout
viene ricalcolato a ogni modifica, quindi gli eventi possono scattare più volte
prima della configurazione finale.

### TS4YFlexItem

| Evento | Quando |
|--------|--------|
| `OnFlexStateChanged(Sender; AState, APreviousState: TFlexItemState)` | La dimensione sull'asse principale cambia rispetto al flex-basis: `fisShrunk` (minore), `fisAtBasis` (uguale, tolleranza 0,5 px), `fisGrown` (maggiore) |
| `OnLayoutChanged(Sender)` | Posizione o dimensione dell'item cambiate (tolleranza 0,5 px) rispetto all'ultimo layout notificato; scatta anche al primo layout |
| `OnLineChanged(Sender; ALineIndex, APreviousLineIndex: Integer)` | L'item passa a un'altra riga (o colonna) per il wrapping |

Al **primo layout** gli eventi scattano subito: `APreviousLineIndex` è `-1` e
`APreviousState` è uguale ad `AState`, così l'aspetto iniziale si imposta
nello stesso handler.

### TS4YFlexBox

| Evento | Quando |
|--------|--------|
| `OnBreakpointsChanged(Sender)` | Cambia l'insieme dei breakpoint attivi (vedi "Breakpoint"); scatta prima di `OnLineCountChanged` |
| `OnLayoutApplied(Sender)` | Dopo ogni layout, con tutti gli item già posizionati |
| `OnLineCountChanged(Sender; ALineCount, APreviousLineCount: Integer)` | Cambia il numero di righe (o colonne); al primo layout `APreviousLineCount` è `-1` |

Non è previsto per ora un evento per ogni cambio di posizione/dimensione
dell'item.

### Breakpoint

I breakpoint cambiano le proprietà del **flexbox** e dei suoi **item** in base alla larghezza del flexbox
(`Width`), come le media query CSS. Si definiscono nella collezione
`Breakpoints` e si leggono secondo `BreakpointMode`, una sola per tutta la
lista:

- `bmMaxWidth` (default): la regola vale **fino a** `Width` (come `max-width`)
- `bmMinWidth`: la regola vale **da** `Width` in su (come `min-width`)

Il confronto è inclusivo. Cambiando `BreakpointMode` le regole restano ma si
leggono all'opposto: conviene ripensare i valori di base.

Ogni breakpoint ha `Width`, l'insieme `ContainerOverrides` e i valori delle proprietà
del container che può sovrascrivere: `Direction`, `Wrap`, `JustifyContent`, `AlignItems`,
`AlignContent`, `ColumnGap`, `RowGap`. Vale un valore solo se la proprietà è
in `ContainerOverrides` (altrimenti il valore del breakpoint è ignorato).

**Cascata, come in CSS**: si applicano tutti i breakpoint che corrispondono alla
larghezza, dal meno al più specifico, e l'ultimo vince sulle stesse proprietà.
L'ordine lo calcola il componente e **non dipende dalla posizione nella lista**:
con `bmMaxWidth` dalla `Width` più grande alla più piccola, con `bmMinWidth`
dalla più piccola alla più grande (a parità di `Width` vale la posizione). Le
proprietà che nessun breakpoint attivo tocca restano quelle di base.

Esempio, base `Direction = fdRow`, `ColumnGap = 0`, `bmMaxWidth`:

| `Width` | `ContainerOverrides` | Valori |
|---------|-------------|--------|
| 900 | `ColumnGap` | `ColumnGap = 8` |
| 600 | `Direction` | `Direction = fdColumn` |
| 400 | `ColumnGap` | `ColumnGap = 2` |

| Larghezza | Breakpoint attivi | `Direction` | `ColumnGap` |
|-----------|-------------------|-------------|-------------|
| 1000 | nessuno | `fdRow` | 0 |
| 800 | 900 | `fdRow` | 8 |
| 500 | 900, 600 | `fdColumn` | 8 |
| 350 | 900, 600, 400 | `fdColumn` | 2 |

Note:

- I valori effettivi si calcolano a ogni layout: le proprietà pubblicate
  (`Direction`, ...) restano quelle di base e nel file salvato finiscono solo
  la base e le regole.
- La larghezza confrontata è `Width` del flexbox (padding compreso).
- **I breakpoint valgono anche a design-time**: il canvas mostra il layout effettivo
  per la larghezza attuale del flexbox, mentre l'Object Inspector mostra sempre i
  valori di base. Per provare una soglia basta ridimensionare il flexbox.
- `ActiveBreakpoints` elenca i breakpoint attivi nell'ordine di applicazione.
- `ColumnGap` è il gap tra item sullo stesso asse principale (anche con
  `fdColumn`), diversamente da CSS dove con la colonna conta `row-gap`.
- Le soglie dipendono dalla larghezza del flexbox, che non dipende dal suo
  contenuto: cambiare `Direction` da un breakpoint non può far riscattare la
  soglia. Con la larghezza automatica (in backlog) andrà riconsiderato.

#### Override degli item

Ogni breakpoint ha anche `ItemOverrides`: una collezione di elementi che indicano
un item (`Item`, a tendina nell'Object Inspector) e quali sue proprietà il
breakpoint sovrascrive (`Overrides`). Servono quando una proprietà dell'item ha
senso solo in una direzione: passando da riga a colonna, per esempio,
`FlexBasis = 320 px` e `FlexGrow = 1` varrebbero sull'altezza.

| Voce di `Overrides` | Proprietà dell'elemento |
|---------------------|-------------------------|
| `ioFlexGrow` | `FlexGrow` |
| `ioFlexShrink` | `FlexShrink` |
| `ioFlexBasis` | `FlexBasis` e `FlexBasisUnit` |
| `ioAlignSelf` | `AlignSelf` |
| `ioOrder` | `Order` |
| `ioVisible` | `Visible` |
| `ioWidth` | `AutoWidth` e `Width` |
| `ioHeight` | `AutoHeight` e `Height` |
| `ioMargins` | `Margins` |
| `ioMinWidth` | `SizeConstraints.MinWidth` |
| `ioMaxWidth` | `SizeConstraints.MaxWidth` |
| `ioMinHeight` | `SizeConstraints.MinHeight` |
| `ioMaxHeight` | `SizeConstraints.MaxHeight` |

La cascata è quella del container: si applicano gli override di tutti i
breakpoint attivi, nello stesso ordine, e ciò che nessuno tocca resta il valore
di base dell'item. Note:

- Le proprietà pubblicate dell'item non cambiano. Con `ioVisible` l'item viene
  nascosto o mostrato per la durata del breakpoint; la `Visible` scelta
  dall'utente si conserva (e se la imposti mentre un override è attivo, vale
  quando l'override cessa).
- Se l'item viene eliminato, i suoi override spariscono.
- Un override di altezza (`ioHeight`) cambia solo l'altezza dell'item, come l'altezza
  esplicita di base: il contenuto resta `Top` con la propria altezza e non si
  adatta all'item (un `TExpander` si apre e si chiude da solo). Con l'altezza
  automatica, invece, l'item segue il contenuto.
- A parità di proprietà sullo stesso item nello stesso breakpoint vale l'ultimo
  elemento della lista.

---

## Demo

`Demo\S4YFelxBoxDemo.dproj` è una dashboard "Sales overview" costruita solo con controlli standard
FMX dentro i flexbox, senza logica applicativa (i dati sono fissi nel `.fmx`). Richiede i package
`S4YFlexBox` e `S4YFlexBoxD` installati. Mostra:

| Zona | Cosa dimostra |
|------|---------------|
| Sidebar (colonna) | `Direction = fdColumn`, item "spacer" con `FlexGrow = 1` che spinge "Log out" in fondo |
| Header | `JustifyContent = jcSpaceBetween`, `AlignItems = aiCenter`, titolo (label `AutoSize`) e pulsante utente con `FitContent` (larghezza dal contenuto), ricerca nascosta sotto 560 px con un override `ioVisible` |
| Card KPI | `Wrap`, `FlexBasis` in percentuale (23%, 48% sotto 760 px) e `FlexGrow` |
| Grafico a barre | flexbox annidato con `AlignItems = aiFlexEnd`, 12 item con altezza esplicita e `FlexBasis = 0`, `FlexGrow = 1` |
| Traffico, ordini, attività | `FlexBasis` in pixel e grow proporzionale (2:1) |
| Breakpoint (flexbox principale) | sotto 1000 px nasconde "Team activity"; sotto 760 px mostra solo KPI e grafico |

Nel codice restano due cose: la sidebar si nasconde sotto 700 px di larghezza del form (la sidebar non
è un item di un flexbox) e la StatusBar mostra dimensioni, numero di righe e breakpoint attivi, aggiornata
da `OnLayoutApplied` e `OnLineCountChanged`.

---

## Esempi d'uso

Gli esempi costruiscono i layout via codice. `AParent` è il controllo che
ospita il `TS4YFlexBox`. Le unit necessarie:

```delphi
uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Objects,
  Soft4You.FMX.Controls.FlexBox,
  Soft4You.FMX.Controls.FlexBox.Engine;
```

### Esempio 1 — Navigation bar con grow e gap

CSS equivalente:

```css
.navbar {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 8px;
  padding: 8px;
}
.logo    { flex: 0 0 120px; }
.spacer  { flex: 1; }
.btn     { flex: 0 0 auto; }
```

```delphi
procedure BuildNavBar(AParent: TControl);
var
  LNavBar: TS4YFlexBox;
  LLogo: TRectangle;
  LSpacer: TControl;   // controllo vuoto come spacer
  LLoginButton: TButton;
  LSignupButton: TButton;
  LLogoItem: TS4YFlexItem;
  LSpacerItem: TS4YFlexItem;
begin
  LNavBar := TS4YFlexBox.Create(AParent.Owner);
  LNavBar.Parent := AParent;
  LNavBar.Align := TAlignLayout.Top;
  LNavBar.Height := 56;
  LNavBar.Direction := fdRow;
  LNavBar.AlignItems := aiCenter;
  LNavBar.ColumnGap := 8;
  LNavBar.Padding.Left := 16;
  LNavBar.Padding.Right := 16;

  // Logo: larghezza fissa 120px, non cresce né si restringe
  LLogo := TRectangle.Create(LNavBar);
  LLogo.Width := 120;
  LLogo.Height := 32;
  LLogo.Parent := LNavBar;
  LLogoItem := LLogo.Parent as TS4YFlexItem;
  LLogoItem.FlexGrow := 0;
  LLogoItem.FlexShrink := 0;
  LLogoItem.FlexBasis := 120;
  LLogoItem.FlexBasisUnit := fbuPixel;

  // Spacer: cresce per riempire lo spazio centrale
  LSpacer := TControl.Create(LNavBar);
  LSpacer.Width := 0;
  LSpacer.Height := 1;
  LSpacer.Parent := LNavBar;
  LSpacerItem := LSpacer.Parent as TS4YFlexItem;
  LSpacerItem.FlexGrow := 1;

  // Pulsanti a destra: dimensione automatica (auto basis)
  // Nessuna prop flex esplicita = grow:0, shrink:1, basis:auto (default CSS)
  LLoginButton := TButton.Create(LNavBar);
  LLoginButton.Text := 'Login';
  LLoginButton.Width := 80;
  LLoginButton.Height := 36;
  LLoginButton.Parent := LNavBar;

  LSignupButton := TButton.Create(LNavBar);
  LSignupButton.Text := 'Sign up';
  LSignupButton.Width := 90;
  LSignupButton.Height := 36;
  LSignupButton.Parent := LNavBar;
end;
```

Nota: la dimensione del controllo va impostata **prima** di `Parent`, perché
l'item prende posizione e dimensioni del controllo nel momento del wrapping.

### Esempio 2 — Card grid con wrap

CSS equivalente:

```css
.grid {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-content: flex-start;
}
.card { flex: 0 0 200px; height: 150px; }
```

```delphi
procedure BuildCardGrid(AParent: TControl);
var
  LGrid: TS4YFlexBox;
  LCard: TRectangle;
  LItem: TS4YFlexItem;
  LIndex: Integer;
begin
  LGrid := TS4YFlexBox.Create(AParent.Owner);
  LGrid.Parent := AParent;
  LGrid.Align := TAlignLayout.Client;
  LGrid.Wrap := fwWrap;
  LGrid.AlignContent := acFlexStart;
  LGrid.ColumnGap := 16;
  LGrid.RowGap := 16;
  LGrid.Padding.Left := 16;
  LGrid.Padding.Top := 16;
  LGrid.Padding.Right := 16;

  for LIndex := 1 to 9 do
  begin
    LCard := TRectangle.Create(LGrid);
    LCard.Width := 200;
    LCard.Height := 150;
    LCard.Parent := LGrid;

    // Ogni card ha basis=200px fissa; non cresce, non si restringe
    LItem := LCard.Parent as TS4YFlexItem;
    LItem.FlexGrow := 0;
    LItem.FlexShrink := 0;
    LItem.FlexBasis := 200;
    LItem.FlexBasisUnit := fbuPixel;
  end;
end;
```

### Esempio 3 — Sidebar (column) con spacer "push to bottom"

CSS equivalente:

```css
.sidebar {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.menu-item        { flex: 0 0 40px; }
.menu-item.active { flex: 0 0 40px; }
.spacer           { flex: 1; }
.footer-item      { flex: 0 0 40px; }
```

```delphi
procedure BuildSidebar(AParent: TControl);
var
  LSidebar: TS4YFlexBox;
  LDashboardButton: TButton;
  LUsersButton: TButton;
  LReportsButton: TButton;
  LSpacer: TControl;
  LLogoutButton: TButton;
begin
  LSidebar := TS4YFlexBox.Create(AParent.Owner);
  LSidebar.Parent := AParent;
  LSidebar.Align := TAlignLayout.Left;
  LSidebar.Width := 200;
  LSidebar.Direction := fdColumn;
  LSidebar.RowGap := 4;
  LSidebar.Padding.Left := 8;
  LSidebar.Padding.Right := 8;
  LSidebar.Padding.Top := 8;
  LSidebar.Padding.Bottom := 8;

  LDashboardButton := TButton.Create(LSidebar);
  LDashboardButton.Text := 'Dashboard';
  LDashboardButton.Height := 40;
  LDashboardButton.Parent := LSidebar;

  LUsersButton := TButton.Create(LSidebar);
  LUsersButton.Text := 'Users';
  LUsersButton.Height := 40;
  LUsersButton.Parent := LSidebar;

  LReportsButton := TButton.Create(LSidebar);
  LReportsButton.Text := 'Reports';
  LReportsButton.Height := 40;
  LReportsButton.Parent := LSidebar;

  // Spacer elastico che spinge il Logout in fondo
  LSpacer := TControl.Create(LSidebar);
  LSpacer.Height := 0;
  LSpacer.Parent := LSidebar;
  (LSpacer.Parent as TS4YFlexItem).FlexGrow := 1;

  // Logout resta sempre in fondo
  LLogoutButton := TButton.Create(LSidebar);
  LLogoutButton.Text := 'Logout';
  LLogoutButton.Height := 40;
  LLogoutButton.Parent := LSidebar;
end;
```

### Esempio 4 — align-self per singoli item

`AlignSelf` sovrascrive `AlignItems` del container sul singolo item.

```delphi
procedure BuildMixedAlign(AParent: TControl);
var
  LBox: TS4YFlexBox;
  LRectangles: array[0..3] of TRectangle;
  LAlignments: array[0..3] of TAlignSelf;
  LIndex: Integer;
begin
  // Altezza 120: primo in alto, secondo al centro, terzo in basso,
  // quarto allungato a tutta l'altezza
  LBox := TS4YFlexBox.Create(AParent.Owner);
  LBox.Parent := AParent;
  LBox.Align := TAlignLayout.Top;
  LBox.Height := 120;
  LBox.Direction := fdRow;
  LBox.AlignItems := aiFlexStart;  // default del container
  LBox.ColumnGap := 8;
  LBox.Padding.Left := 8;

  LAlignments[0] := asFlexStart;  // ridondante (uguale al container)
  LAlignments[1] := asCenter;
  LAlignments[2] := asFlexEnd;
  LAlignments[3] := asStretch;    // si allunga a tutta l'altezza

  for LIndex := 0 to 3 do
  begin
    LRectangles[LIndex] := TRectangle.Create(LBox);
    LRectangles[LIndex].Width := 60;
    LRectangles[LIndex].Height := 40;
    LRectangles[LIndex].Parent := LBox;
    (LRectangles[LIndex].Parent as TS4YFlexItem).AlignSelf := LAlignments[LIndex];
  end;
end;
```

### Esempio 5 — Order per riordinare senza cambiare l'ordine dei figli

```delphi
procedure BuildOrderExample(AParent: TControl);
var
  LBox: TS4YFlexBox;
  LButtonA: TButton;
  LButtonB: TButton;
  LButtonC: TButton;
begin
  // Ordine di creazione: A, B, C
  // Ordine visivo con Order: C(0), A(1), B(2)
  LBox := TS4YFlexBox.Create(AParent.Owner);
  LBox.Parent := AParent;
  LBox.Align := TAlignLayout.Top;
  LBox.Height := 50;
  LBox.Direction := fdRow;
  LBox.ColumnGap := 8;

  LButtonA := TButton.Create(LBox);
  LButtonA.Text := 'A';
  LButtonA.Width := 60;
  LButtonA.Height := 40;
  LButtonA.Parent := LBox;
  (LButtonA.Parent as TS4YFlexItem).Order := 1;

  LButtonB := TButton.Create(LBox);
  LButtonB.Text := 'B';
  LButtonB.Width := 60;
  LButtonB.Height := 40;
  LButtonB.Parent := LBox;
  (LButtonB.Parent as TS4YFlexItem).Order := 2;

  LButtonC := TButton.Create(LBox);
  LButtonC.Text := 'C';
  LButtonC.Width := 60;
  LButtonC.Height := 40;
  LButtonC.Parent := LBox;
  (LButtonC.Parent as TS4YFlexItem).Order := 0;  // C appare per primo
end;
```

---

## Design-time

Non ci sono finestre né editor dedicati: tutto si fa nel designer e
nell'Object Inspector.

1. Trascina un controllo (dalla palette o da un altro contenitore) dentro un
   `TS4YFlexBox`: il designer crea un `TS4YFlexItem` e vi inserisce il controllo.
2. Seleziona il `TS4YFlexItem` (nella Structure view o cliccando sul bordo
   dell'item) per modificare `FlexGrow`, `FlexShrink`, `FlexBasis`,
   `FlexBasisUnit`, `AlignSelf` e `Order` nell'Object Inspector.
3. Per mettere più controlli in una posizione del flexbox, inserisci un layout
   o un panel e trascina i controlli dentro quel contenitore.

### Riordino degli item

Il modo affidabile per cambiare l'ordine degli item è la property **`Index`**
dell'item nell'Object Inspector (parte da 0; l'ordine si salva comunque, perché è
quello degli oggetti nel file).

Trascinando un item sopra un altro nella Structure view, l'item viene riportato
nel flexbox e inserito prima di quello di destinazione: il form mostra l'ordine
nuovo, ma **la Structure view non si aggiorna** (resta con l'ordine vecchio fino
alla riapertura del form). Il designer FMX non permette al package di forzarne
l'aggiornamento: sono stati provati senza successo `Modified`/`SelectComponent`
e uno sprig personalizzato (`RegisterSprigType`).

Anche il drop **tra** due item (la riga singola di inserimento) non sposta nulla: un
log completo dell'IDE (hook su `SetParent`, `DoAddObject`, `DoInsertObject`,
`DoRemoveObject`, `ChangeOrder`, `SetChildOrder` e notifiche del designer) ha
mostrato che l'IDE non chiama niente dei nostri oggetti, né per quel drop né per
Control > Bring to Front / Send to Back. Il designer FMX non implementa
`SetChildOrder` per i componenti FMX. L'argomento è sospeso; l'idea non provata è
una voce di menu contestuale (`IComponentEditor`: Move first/before/after/last).

---

## Limiti noti

- La larghezza automatica è quella di design, che si adatta (stretch e
  fit-content); la larghezza calcolata dal contenuto (per esempio una `TLabel`
  con `AutoSize`) richiede `FitContent = True` sull'item.
- `FlexBasis` e `FlexGrow` valgono sull'asse principale: passando da riga a
  colonna (per esempio con un breakpoint) un basis di 320 px diventa un'altezza:
  si corregge con gli override degli item del breakpoint (vedi "Override degli
  item").
- Un contenuto in altezza automatica non riempie l'item quando questo viene
  stirato o fatto crescere dal layout (in CSS lo farebbe, perché sarebbe lui
  l'item).
- Riordino per trascinamento: Structure view non aggiornata (vedi Design-time).
- I form salvati prima dell'altezza automatica si convertono all'apertura
  (contenuto da `Client` a `Top`).

---

## Eseguire i test

```delphi
// In un progetto DUnitX console:
uses Soft4You.FMX.Controls.FlexBox.Engine.Tests;
// Oppure usa il DUnitX GUI runner
```

I 38 test coprono: row/column, justify-content (tutti i valori),
flex-grow, flex-shrink, flex-basis (auto/px/%), align-items,
align-self, order, wrap/wrap-reverse, gap, align-content, reverse,
dimensioni auto/esplicite e linea singola (`SingleLineFillsContainer`).
Testano il solo motore (`TFlexEngine`), non i componenti.

---

## Versione e compatibilità

- **Delphi**: 11 Alexandria, 12 Athens (consigliato)
- **Delphi 10.4**: compatibile, richiede rimozione delle `inline var`
  in `Soft4You.FMX.Controls.FlexBox.Engine.Tests.pas`
- **Specifica**: W3C CSS Flexbox Level 1
  https://www.w3.org/TR/css-flexbox-1/
