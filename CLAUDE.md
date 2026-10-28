# Regole di codifica Delphi

## Prefissi identificatori

Rispettare sempre i seguenti prefissi:

| Prefisso | Uso |
|---|---|
| `F` | Field privato/protetto di classe |
| `A` | Parametro di funzione/procedura |
| `L` | Variabile locale |
| `C_` | Costante (non stringa) |
| `S_` | Costante stringa (`const` o `resourcestring`) |
| `T` | Tipo (class, record, enum, alias) |
| `I` | Interfaccia |
| `E` | Eccezione |

## Nomi leggibili, niente abbreviazioni

Usare sempre nomi completi e autoesplicativi. Nessuna troncatura, neanche abbreviazioni di uso comune.

- `FHasSelection` non `FHasSel`
- `LParagraph` non `LPara`
- `LLayout` non `LL`
- `BackgroundColor` non `BGColor`
- `SelectionColor` non `SelColor`
- `Position` non `Pos`

La regola vale per field (`F`), variabili locali (`L`), parametri (`A`), costanti (`C_`).

## Parametri booleani

I parametri di tipo `Boolean` non usano il prefisso `A`. Si scrivono con il solo nome:

```delphi
procedure SetBold(Bold: Boolean);       // corretto
procedure SetBold(ABold: Boolean);      // sbagliato
```

## Nomi dei metodi — prefissi operazionali

Usare prefissi coerenti per i metodi che operano su elementi esistenti:

| Prefisso | Significato |
|---|---|
| `Insert*` | Crea e inserisce un elemento nuovo |
| `Update*` | Modifica un elemento esistente al cursore |
| `Delete*` | Elimina un elemento |

## Costanti

- Tutte maiuscole: `C_EDITOR_FONT_SIZE`
- Parole composte separate da underscore: `C_EDITOR_FONT_NAME` non `C_EditorFontName`
- Per costanti che rappresentano valori iniziali di proprietà modificabili, usare il prefisso `DEFAULT` dopo `C_`: `C_DEFAULT_SELECTION_COLOR`

## Formattazione

- Indentazione: **2 spazi** (niente tab)
- `begin` e `end` sempre su riga propria
- Vietati: `with`, `Break`, `Continue`

## Righe vuote tra i blocchi di codice

Dentro il corpo di un metodo i blocchi di codice sono separati da una riga vuota. Una riga vuota va:

- **dopo ogni blocco di controllo** (`if`, `for`, `while`, `case`, `try`, `repeat`), con o senza `else` e anche quando occupa due sole righe, se dopo c'è un'altra istruzione allo stesso livello. Anche una serie di `if` consecutivi ha una riga vuota tra l'uno e l'altro;
- **prima di un blocco di controllo** preceduto da un'istruzione semplice allo stesso livello, compreso il controllo che esce subito (`if ... then Exit;`);
- **prima di un commento** che apre un nuovo blocco dopo un'istruzione semplice. Un commento che chiude il blocco e spiega l'istruzione precedente resta attaccato.

Eccezioni, che restano attaccate:

- `try` subito dopo la creazione dell'oggetto che protegge (`LBuilder := TStringBuilder.Create;` seguito da `try`);
- il valore di default seguito dall'`if` che può sostituirlo (`LIndent := ''; if Level > 0 then LIndent := ...;`).

Mai righe vuote subito dopo `begin`, subito prima di `end` / `else` / `except` / `finally` / `until`, né dentro un'istruzione su più righe. Le direttive `{$IFDEF}` non separano né vengono separate. I metodi brevi con sole assegnazioni restano compatti.

```delphi
begin
  Result := nil;
  LSVGDOM := TSkSVGDOM.Make(ASVGText);

  if not Assigned(LSVGDOM) then
    Exit;

  LWidth := AWidth;
  LHeight := AHeight;

  if (LWidth <= 0) or (LHeight <= 0) then
  begin
    ...
  end;

  Result := TBitmap.Create(LWidth, LHeight);
  try
    ...
  except
    FreeAndNil(Result);
  end;
end;
```

## Variabili inline

In generale, dichiarare le variabili nella sezione `var` della funzione o procedura. Eccezioni ammesse:

1. Contatori di ciclo `for`: `for var I := 0 to N do` è accettabile
2. Variabili inline in blocchi condizionali la cui unica uscita è `Exit`:
   ```delphi
   if Condition then
   begin
     var LValue := Compute;
     // ... usa LValue ...
     Exit;
   end;
   ```

In nessun caso usare variabili inline in cicli quando la variabile è riutilizzata all'interno del ciclo stesso.

## Struttura delle classi

Rispettare questo ordine all'interno di ogni sezione di visibilità, con **una riga vuota** tra ogni gruppo:

**`public`**
1. Metodi di classe (`class function`, `class procedure`)
2. Costruttori e distruttori (`constructor`, `destructor`)
3. Altri metodi (`procedure`, `function`)
4. Proprietà (ordine alfabetico; eventi `OnXxx` in fondo)

**`protected` e `private`**
1. Campi (`F…`)
2. Metodi
3. Proprietà

I costruttori e distruttori appartengono solo alla sezione `public`.

## Proprietà

- Elenco in **ordine alfabetico** all'interno di ogni sezione
- Gli **eventi** (`OnXxx`) sempre in fondo all'elenco, dopo tutte le altre proprietà
- Usare il **field diretto** nella dichiarazione della property quando non c'è logica aggiuntiva:
  ```delphi
  property HasSelection: Boolean read FHasSelection;  // corretto
  property HasSelection: Boolean read GetHasSelection; // sbagliato se GetHasSelection fa solo Result := FHasSelection
  ```
- Usare metodi getter/setter solo quando: (1) c'è logica da eseguire, oppure (2) la classe implementa un'interfaccia che li richiede

## Versioning dei pacchetti

Lo schema per gli utenti è nella sezione "Versioning" del README. Regole operative:

- Una sola versione della suite, identica nei sei progetti dei pacchetti (`Packages\D11|D12|D13\Soft4You.FMX.Controls.Suite.dproj` e `...SuiteD.dproj`), FileVersion = ProductVersion. Demo e test non si versionano.
- I pacchetti D12 e D13 hanno le piattaforme Win32 e Win64 (Win64 serve all'IDE a 64 bit, da Delphi 12.3), quelli D11 solo Win32; i gruppi di versione sono comunque gli stessi in tutti e sei i dproj. La versione sta nei gruppi `Cfg_1_Win32` e `Cfg_1_Win64` (Debug) e `Cfg_2_Win32` e `Cfg_2_Win64` (Release), in `VerInfo_MajorVer`/`VerInfo_MinorVer`/`VerInfo_Release` e in `FileVersion`/`ProductVersion` di `VerInfo_Keys`. Build sempre 0, niente incremento automatico.
- Le altre chiavi di `VerInfo_Keys` (`CompanyName`, `FileDescription`, `InternalName`, `LegalCopyright`, `ProductName`, `Comments`, ...) sono identiche nei sei gruppi `Base_Win32`, `Base_Win64`, `Cfg_1_Win32`, `Cfg_1_Win64`, `Cfg_2_Win32` e `Cfg_2_Win64`: si cambiano tutte insieme. `OriginalFilename` resta vuoto (il nome del `.bpl` dipende da `{$LIBSUFFIX AUTO}`).
- **Debug** (sviluppo): Minor dispari. Dopo ogni merge in `develop` che tocca il codice dei pacchetti (`Sources`, oppure `Packages`/`Graphics` per ciò che entra nei pacchetti), **compreso il merge del ramo di rilascio**, la Minor Debug va al dispari successivo (+2; +1 se fosse pari). Un solo bump per branch mergiato, in un commit separato direttamente su `develop`. Merge che toccano solo `Docs`, `Demos` o `Tests`: nessun bump.
- **Release**: Minor pari, +2 rispetto al rilascio precedente (mai calcolata dalla Debug); `Release` +1 per un rilascio di sole correzioni; `Major` +1 (Minor e Release a 0) per modifiche incompatibili, come una proprietà published rinominata o tolta. Si imposta sul ramo `rel_*`.
- **Configurazione predefinita**: sul ramo `rel_*` si porta a Release (`<Config Condition="'$(Config)'==''">Release</Config>` nei sei dproj), così chi scarica il tag compila in Release. Il commit di bump dopo il merge del rilascio in `develop` la riporta a Debug.

## Risorse compilate (`Resources`)

Gli `RcCompile` dei pacchetti (stili di Badge ed Expander, icone `XxxDesign.rc`) e la risorsa di progetto con le informazioni di versione (`Soft4You.FMX.Controls.Suite.res`, `...SuiteD.res`) vanno in `Resources\` nella radice: `BRCC_OutputDir` nel gruppo Base dei sei dproj. La build crea la cartella e la aggiunge da sola al percorso di ricerca delle risorse, quindi non va messa nel `DCC_UnitSearchPath` dei pacchetti; la cartella è esclusa da git. Applicazioni e demo che usano Badge o Expander dai sorgenti hanno bisogno di `Resources` nel percorso di ricerca e dei pacchetti già compilati.

La cartella è condivisa da D11, D12 e D13: ogni build sovrascrive `Suite.res` e `SuiteD.res` di quella precedente. È innocuo solo finché le informazioni di versione sono identiche nei sei dproj (vedi "Versioning dei pacchetti").

## File .pas — line ending

Scrivere sempre i file `.pas` con line ending **CRLF** (`\r\n`). I file con soli LF compilano ma l'IDE Delphi non riesce a eseguire il refactoring dei nomi. Quando si genera un file `.pas` via PowerShell, normalizzare prima di scrivere:

```powershell
$c = ($c -replace "`r`n", "`n") -replace "`n", "`r`n"
[System.IO.File]::WriteAllText($path, $c, [System.Text.Encoding]::UTF8)
```

Per file contenenti caratteri non-ASCII (emoji, ecc.) usare UTF-8 con BOM (`[System.Text.Encoding]::UTF8` in .NET include il BOM).
