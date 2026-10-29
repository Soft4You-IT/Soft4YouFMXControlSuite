# Contributing

Thank you for your interest in the Soft4You FMX Control Suite. This guide explains how to report a problem, how to propose a change and the coding rules of the sources.

## Reporting a problem

Open an [issue](https://github.com/Soft4You-IT/Soft4YouFMXControlSuite/issues) with:

- the version of the suite (shown in the IDE splash screen and About box) and of Delphi;
- the platform (Windows, macOS, iOS, Android);
- the steps to reproduce the problem, and if possible a small project or the HTML that shows it.

## Proposing a change

The repository has two long-lived branches:

- `main` contains only the releases, each one tagged (`v1.0.0`, ...);
- `develop` is the development branch: every change goes here first.

1. Create your branch from `develop`, with a prefix that tells what it is: `fea_` for a feature, `fix_` for a fix, `doc_` for documentation only, followed by a name in PascalCase with underscores (for example `fix_Expander_Header_Click`).
2. Keep a branch to one topic, and document the change in the same branch: the README of the control in `Docs`, the XML documentation of the sources, the demos where they apply.
3. Build the packages of at least one Delphi version (see "Installation" in the [README](README.md)) and run the tests in `Tests` if you changed a control that has them.
4. Open the pull request against **`develop`**, not against `main`.

Before committing, check that the IDE did not write settings of your installation into the project files: the list of the installed packages (`DCC_UsePackage`) in the demos, packages excluded with an absolute path (`Excluded_Packages`), the path of the file an image was loaded from (`FileName`) in the `.fmx` forms.

The version numbers and the releases are handled by the maintainer.

## License of the contributions

The suite is released under the [Mozilla Public License 2.0](LICENSE). By submitting a contribution you agree that it is released under the same license.

## Coding rules

### Identifier prefixes

| Prefix | Use |
|---|---|
| `F` | Private or protected field of a class |
| `A` | Parameter of a function or procedure |
| `L` | Local variable |
| `C_` | Constant (not a string) |
| `S_` | String constant (`const` or `resourcestring`) |
| `T` | Type (class, record, enumeration, alias) |
| `I` | Interface |
| `E` | Exception |

### Readable names, no abbreviations

Always use full, self-explaining names. No truncation, not even of common abbreviations.

- `FHasSelection`, not `FHasSel`
- `LParagraph`, not `LPara`
- `LLayout`, not `LL`
- `BackgroundColor`, not `BGColor`
- `SelectionColor`, not `SelColor`
- `Position`, not `Pos`

The rule applies to fields (`F`), local variables (`L`), parameters (`A`) and constants (`C_`).

### Boolean parameters

`Boolean` parameters do not use the `A` prefix; they are written with the bare name:

```delphi
procedure SetBold(Bold: Boolean);       // correct
procedure SetBold(ABold: Boolean);      // wrong
```

### Method names

Use consistent prefixes for the methods that work on existing elements:

| Prefix | Meaning |
|---|---|
| `Insert*` | Creates and inserts a new element |
| `Update*` | Changes an existing element at the cursor |
| `Delete*` | Deletes an element |

### Constants

- All uppercase: `C_EDITOR_FONT_SIZE`
- Compound words separated by underscores: `C_EDITOR_FONT_NAME`, not `C_EditorFontName`
- For constants that are the initial values of changeable properties, use the prefix `DEFAULT` after `C_`: `C_DEFAULT_SELECTION_COLOR`

### Formatting

- Indentation: **2 spaces** (no tabs)
- `begin` and `end` always on their own line
- Not allowed: `with`, `Break`, `Continue`

### Blank lines between blocks of code

Inside the body of a method the blocks of code are separated by a blank line. A blank line goes:

- **after every control block** (`if`, `for`, `while`, `case`, `try`, `repeat`), with or without `else` and even when it takes only two lines, if another statement follows at the same level. A series of consecutive `if`s also has a blank line between one and the next;
- **before a control block** preceded by a simple statement at the same level, including the check that exits at once (`if ... then Exit;`);
- **before a comment** that opens a new block after a simple statement. A comment that closes the block and explains the previous statement stays attached.

Exceptions, which stay attached:

- `try` right after the creation of the object it protects (`LBuilder := TStringBuilder.Create;` followed by `try`);
- the default value followed by the `if` that can replace it (`LIndent := ''; if Level > 0 then LIndent := ...;`).

Never blank lines right after `begin`, right before `end` / `else` / `except` / `finally` / `until`, or inside a statement on several lines. The `{$IFDEF}` directives neither separate nor are separated. Short methods with assignments only stay compact.

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

### Inline variables

In general, declare the variables in the `var` section of the function or procedure. Allowed exceptions:

1. Counters of `for` loops: `for var I := 0 to N do` is acceptable
2. Inline variables in conditional blocks whose only exit is `Exit`:
   ```delphi
   if Condition then
   begin
     var LValue := Compute;
     // ... use LValue ...
     Exit;
   end;
   ```

Never use inline variables in loops when the variable is reused inside the loop itself.

### Structure of the classes

Keep this order inside every visibility section, with **a blank line** between the groups:

**`public`**
1. Class methods (`class function`, `class procedure`)
2. Constructors and destructors (`constructor`, `destructor`)
3. Other methods (`procedure`, `function`)
4. Properties (alphabetical order; `OnXxx` events last)

**`protected` and `private`**
1. Fields (`F…`)
2. Methods
3. Properties

Constructors and destructors belong only to the `public` section.

### Properties

- Listed in **alphabetical order** inside every section
- The **events** (`OnXxx`) always at the end of the list, after all the other properties
- Use the **field directly** in the declaration of the property when there is no additional logic:
  ```delphi
  property HasSelection: Boolean read FHasSelection;  // correct
  property HasSelection: Boolean read GetHasSelection; // wrong if GetHasSelection only does Result := FHasSelection
  ```
- Use getter/setter methods only when (1) there is logic to run, or (2) the class implements an interface that requires them

### Header of the sources

Every unit in `Sources` starts with this header, right after the `unit` line: the copyright line shows the years of the file (the year of creation, or `first-last` if the code is older), the text of the license is the one of Exhibit A of the MPL 2.0.

```delphi
{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YXxx - short description of the content of the unit
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }
```

The copyright line is not removed, and is not replaced with "Original author": the MPL (section 3.4) requires whoever redistributes the code to keep the copyright notices.

### Line endings of the `.pas` files

Always write the `.pas` files with **CRLF** line endings (`\r\n`). Files with LF only compile, but the Delphi IDE cannot refactor the names in them. When a `.pas` file is generated with PowerShell, normalize it before writing:

```powershell
$c = ($c -replace "`r`n", "`n") -replace "`n", "`r`n"
[System.IO.File]::WriteAllText($path, $c, [System.Text.Encoding]::UTF8)
```

For files with non-ASCII characters (emoji, ...) use UTF-8 with BOM (`[System.Text.Encoding]::UTF8` in .NET includes the BOM).
