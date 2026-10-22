# Analisi: Filtraggio figli in TS4YFlexBox.BuildContext

> Nota: analisi storica. Con l'introduzione di `TS4YFlexItem` il flexbox posiziona solo gli item (`TS4YFlexBox.IsFlexChild`); i filtri qui descritti restano validi per `Visible`, `csLoading` e `csDestroying`, mentre il controllo su `Align` non e' piu' necessario perche' i controlli vivono dentro gli item.

## Il problema in dettaglio

In FMX la gerarchia visuale si divide in **due livelli distinti**:

```
TFmxObject.Children[]      → lista RAW di tutti i figli dell'oggetto FMX
TControl.Controls[]        → sottoinsieme filtrato: solo i TControl diretti
```

`Controls[]` è già un filtro rispetto a `Children[]` (esclude i `TFmxObject` non-TControl),
ma **non è sufficiente** per il nostro scopo. Ci sono almeno tre categorie di figli
che `Controls[]` include e che TS4YFlexBox NON deve layoutare:

---

## Categoria 1 — Style objects (csSubComponent)

I controlli `TStyledControl` (TButton, TEdit, TPanel, ecc.) creano a runtime
un albero di "style objects" e lo aggiungono come figlio diretto.
Questi oggetti hanno `csSubComponent` nel `ComponentStyle` e/o `StyleName <> ''`.

```
TButton (nostro figlio flex)
  └── TRectangle  [style]       ← Controls[0] di TButton, ma anche Controls[?] di noi?
```

**In realtà**: gli style objects vengono aggiunti come figli del TStyledControl stesso,
non del nostro TS4YFlexBox. Quindi `Controls[]` di TS4YFlexBox **non li vede direttamente**.
Questo problema riguarda solo i figli DIRETTI con `csSubComponent` impostato da noi,
che in questo caso non esistono. ✅ Non ci tocca.

---

## Categoria 2 — TAnimation, TEffect, e altri TFmxObject non-TControl

Quando si aggiunge una `TFloatAnimation` o un `TEffect` a un figlio,
questi oggetti vengono aggiunti a `Children[]` del figlio, non del TS4YFlexBox.
`Controls[]` filtra già i non-TControl. ✅ Non ci tocca.

---

## Categoria 3 — Il problema REALE: figli con Align <> alNone

Questo è il caso che conta. FMX gestisce i figli in due modi:

1. **Align = alNone**: posizione libera, gestita da noi tramite `SetBounds`
2. **Align <> alNone** (Top, Bottom, Client, ecc.): posizione gestita da FMX stesso
   tramite il suo sistema di allineamento nativo

Se un figlio ha `Align = TAlignLayout.Client`, FMX lo posiziona lui.
Se poi TS4YFlexBox chiama `SetBounds` su di lui, i due sistemi si pestano i piedi
e il controllo rimbalza indefinitamente tra le due posizioni.

**Soluzione già presente nel nostro codice:**
```pascal
if Child.Align <> TAlignLayout.None then Continue;
```
Questo esclude correttamente i figli "gestiti da FMX". ✅ Già corretto.

---

## Categoria 4 — Il problema REALE #2: ControlsCount vs Children durante DoRealign

`ControlsCount` e `Controls[]` restituiscono i figli **al momento della chiamata**.
Durante `DoRealign`, FMX può stare ancora costruendo l'albero (es. caricamento DFM).
Il rischio è iterare una lista in modifica.

**Fix**: snapshot della lista figli all'inizio di `BuildContext`, prima di qualsiasi
operazione che potrebbe modificarla.

---

## Categoria 5 — Il problema REALE #3: OriginalIndex non è l'indice in Controls[]

Nel codice attuale, `Input.OriginalIndex := I` usa `I` come indice nel loop,
ma questo indice **salta** i figli filtrati (invisibili, Align <> None).
Quindi `OriginalIndex` non corrisponde più all'indice in `Controls[]`.

In `ApplyResults` poi facciamo `Controls[R.OriginalIndex]` che punta al controllo
SBAGLIATO se ci sono buchi nella sequenza.

**Questo è il bug più insidioso e silenzioso dell'implementazione attuale.**

### Esempio del bug:
```
Controls[0] = Button1   (Align=Top    → saltato)
Controls[1] = Button2   (Align=None   → incluso, OriginalIndex=0 ← SBAGLIATO)
Controls[2] = Button3   (invisible    → saltato)
Controls[3] = Button4   (Align=None   → incluso, OriginalIndex=1 ← SBAGLIATO)
```
`ApplyResults` scrive su `Controls[0]` (Button1) invece di `Controls[1]` (Button2).

---

## La Fix

La soluzione corretta è usare un **riferimento diretto al TControl** invece
dell'indice. Costruiamo un array parallelo `FlexChildren: TArray<TControl>`
che contiene esattamente i figli che partecipano al layout, nello stesso ordine
degli `Items` del `TFlexContext`.

`OriginalIndex` diventa allora l'indice in `FlexChildren[]`, non in `Controls[]`.

```pascal
// BuildContext restituisce anche i figli partecipanti
function BuildContext(out FlexChildren: TArray<TControl>): TFlexContext;

// ApplyResults usa direttamente i riferimenti
procedure ApplyResults(const Results: TArray<TFlexItemResult>;
                       const FlexChildren: TArray<TControl>);
```

In `ApplyResults`:
```pascal
// Prima (SBAGLIATO):
Child := TControl(Controls[R.OriginalIndex]);

// Dopo (CORRETTO):
Child := FlexChildren[R.OriginalIndex];
```

`OriginalIndex` è l'indice in `FlexChildren`, che è un array compatto senza buchi,
costruito nello stesso momento e con gli stessi filtri di `BuildContext`.

---

## Fix secondaria: invisibilità durante il layout

Un figlio può diventare invisibile *mentre* siamo in `DoRealign` (raro ma possibile
in animazioni). Dobbiamo anche difenderci da `nil` nell'array:

```pascal
if (R.OriginalIndex < 0) or (R.OriginalIndex > High(FlexChildren)) then Continue;
Child := FlexChildren[R.OriginalIndex];
if (Child = nil) or not Child.Visible then Continue;
```

---

## Riepilogo filtri da applicare in BuildContext

Un figlio partecipa al layout FlexBox se e solo se:

```pascal
function IsFlexChild(Child: TControl): Boolean;
begin
  Result :=
    Assigned(Child)                              and  // non nil
    Child.Visible                                and  // visibile
    (Child.Align = TAlignLayout.None)            and  // non gestito da FMX
    not (csDestroying in Child.ComponentState)   and  // non in distruzione
    not (csLoading in Child.ComponentState);          // non ancora caricato
end;
```

Il check `csLoading` è importante: durante il caricamento del DFM i figli vengono
aggiunti uno alla volta. Se `DoRealign` viene chiamato mentre il DFM non è ancora
completamente letto, alcuni figli non hanno ancora le dimensioni corrette.
La soluzione è anche controllare `csLoading in ComponentState` del TS4YFlexBox stesso:

```pascal
procedure TS4YFlexBox.DoRealign;
begin
  if FInLayout > 0 then Exit;
  if csLoading in ComponentState then Exit;   // ← aggiunto
  if csDestroying in ComponentState then Exit; // ← aggiunto
  ...
end;
```
