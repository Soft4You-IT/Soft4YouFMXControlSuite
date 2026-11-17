# TS4YGrid for FireMonkey

![TS4YGrid](../Screenshots/grid.png)

A grid with a **filter row** under the header: an editor for each column, where the user writes the filter of that column, an operator and a value, such as `> 100`, `ros*` or `<> Rome`. Every column has a text field, read with the type of the column (text, number, date, time, a value of a list), except a check column, which has a check box with three states. The button of a text field opens a **menu** with the operators, the values of the list of the column, a calendar, today or the current time, and an item that clears the filter. The data can be filtered when the user presses Enter, or by themselves after a pause in the typing.

Under the cells, a **footer** can show a total, an average, a count, the lowest or the highest value, or a text, under each column.

A click on the header of a column can **sort** the rows by that column, and Shift+click by more columns; the header shows the arrow of the direction and the position of each column in the order.

`TS4YGrid` is a `TGrid`: the cells get their values from `OnGetValue` or from the LiveBindings, as in a `TGrid`, and every property, column and event of `TGrid` is there. The grid **does not filter or sort the data itself**: it reads the filters and keeps them, with the keys of the order, and tells the application when to filter, with `OnFilter`, and when to sort, with `OnSort`; the application filters and sorts its own data, for example a list of objects or a `TDataSet`, and sets `RowCount` again. To filter in memory, `FilterMatches` compares a value with the filter of its column; to filter with a query, the operator and the value of each filter are given apart.

The filter row and the footer take the look of the style of the grid, from the platform or from a `TStyleBook`: they are added to that style, not drawn with a style of their own.

Unit: `Soft4You.FMX.Controls.Grid`, in `Sources\Grid`.

## Installation

The grid is part of the Soft4You FMX Control Suite. It is built into the runtime package `Soft4You.FMX.Controls.Suite`, and its registration into the design-time package `SuiteD`: see the README in the root of the repository. It appears in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\Grid` to the Delphi library path to compile your own projects with the units.

## Files

| File | Content |
|---|---|
| `Sources\Grid\Soft4You.FMX.Controls.Grid.pas` | `TS4YGrid`, its model `TS4YGridModel`, the settings of the filter row (`TS4YGridFilterRow`), of the footer (`TS4YGridFooterRow`), of the order (`TS4YGridSorting`) and of the columns (`TS4YGridColumnSetting`, `TS4YGridColumnSettings`) |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.Style.pas` | `TS4YStyledGrid`, the presentation that adds the filter row and the footer to the style of the grid and draws the arrows of the order in the header, and the rows themselves, `TS4YGridBand` and `TS4YGridFooterBand` |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.Filters.pas` | `TS4YGridFilter`, the filter of a column: the syntax of its text, its value and the comparison with the values of the rows; the items of the menu of a filter (`TS4YGridFilterMenuItem`, `TS4YGridFilterMenuItems`) |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.FilterEditors.pas` | The editors of the filter row: `TS4YGridTextFilterEditor` with its button `TS4YGridFilterMenuButton`, and `TS4YGridCheckFilterEditor` |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.Types.pas` | The interface of the editors `IS4YGridFilterEditor`, the operators, the kinds of value and the states of the filters (`TS4YGridFilterOperator`, `TS4YGridFilterValueKind`, `TS4YGridFilterState`), the actions of the menu (`TS4YGridFilterMenuAction`), what the footer shows (`TS4YGridFooterKind`), a key of the order (`TS4YGridSortKey`), the place of the position in the order (`TS4YGridSortOrderPosition`) and the event types |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.Register.pas` | Registration in the Tool Palette (design time) |
| `Graphics\Grid\TS4YGrid.svg`, `TS4YGrid.bmp`, `GridDesign.rc` | Icon of the Tool Palette (vector master and 24x24 bitmap) and the resource script that links it |

## Filter row

| Property | Default | Meaning |
|---|---|---|
| `FilterRow.Visible` | `False` | Shows the filter row under the header; the filters apply only while it is shown (see [Showing and hiding the filter row](#showing-and-hiding-the-filter-row)) |
| `FilterRow.Height` | 0 | Height of the row, in pixels; 0 is automatic: the height of the editors with the padding of the style (see [Styles](#styles)), at least the height of the rows of the grid |
| `FilterRow.ClearOnHide` | `False` | Clears the texts of the filters when the row is hidden; `False` keeps them, and they apply again when the row is shown again |
| `FilterRow.ShowButton` | `False` | Shows a button on the right side of the header, which shows or hides the row |
| `FilterRow.ShortCut` | Ctrl+Shift+F | The keys that show or hide the row, when the grid or an editor of the row has the focus; 0 has no keys |
| `FilterRow.AutoFilter` | `False` | Fires `OnFilter` by itself when the user stops typing in an editor of text, number or date for `FilterDelay` milliseconds; `False` filters only with Enter |
| `FilterRow.FilterDelay` | 400 | Milliseconds without typing after which `AutoFilter` fires `OnFilter`; 0 fires it at each change |
| `FilterRow.ShowMenuButton` | `True` | Shows the button of the menu of the filter in the text fields (see [Filter menu](#filter-menu)) |
| `FilterRow.EditStyleLookup` | empty | The name of the style of the text fields of the row; empty uses `editstyle`, the style of `TEdit` |
| `FilterRow.CheckBoxStyleLookup` | empty | The name of the style of the check boxes of the row; empty uses `checkcellstyle`, the style of the check boxes of the cells of the grid, or `checkboxstyle` when it is not found |
| `FilterRow.MenuStyleLookup` | empty | The name of the style of the popup of the menu, looked for in the style book of the form and in the style of the platform; empty uses `popupstyle`, the style of `TPopup` |
| `FilterRow.MenuItemStyleLookup` | empty | The name of the style of the items of the menu; empty uses `listboxitemstyle`, the style of the items of `TListBox`. The lines between the groups of items take the color of its text |
| `FilterRow.CalendarStyleLookup` | empty | The name of the style of the calendar of the menu of a date filter; empty uses `calendarstyle`, the style of `TCalendar` |

The row follows the columns: an editor has the width of its column, moves with it when the columns are moved or scrolled horizontally, and is hidden with it. The cells of the grid start under the row.

### Showing and hiding the filter row

The filters apply only while the filter row is shown. When it is hidden, the grid has no filter: `IsFiltered` is `False`, `FilterMatches` lets every row pass, and `FilterOperator`, `FilterValue` and `FilterState` give no filter, so the application shows all its data without checking whether the row is shown. `FilterText` keeps the texts written: when the row is shown again, they apply again. With `ClearOnHide`, hiding the row clears them. Showing or hiding the row fires `OnFilter` when there is at least one filter, so the application filters its data again. A filter set by code while the row is hidden applies only when the row is shown.

The user shows and hides the row with:

- the **button** on the right side of the header, with `FilterRow.ShowButton`: a funnel, pressed while the row is shown; it is square, as high as the header, which leaves the space for it, and it takes the style of the items of the header;
- the **keys** of `FilterRow.ShortCut`, Ctrl+Shift+F by default, when the grid or an editor of its row has the focus: the other grids of the form do not react.

Both call `ToggleFilterRow`, which an action of the application can call too, for example from a button of its tool bar. When it shows the row, the focus goes to the editor of the current column, or to the first editor shown; when it hides the row, the focus goes back to the cells.

`OnFilterRowToggle` fires when the row is shown or hidden, whatever the way, also with `FilterRow.Visible` by code (not while the form is loaded): for example to show the state in a control of the application, as the demo does with its check box, or to save it. `FilterRow.Visible` can also be bound with the LiveBindings, for example to a check box with a `TLinkControlToProperty` whose `ComponentProperty` is `FilterRow.Visible`: the grid tells the LiveBindings when the row is shown or hidden, also by the user.

### Editors

| Type of the column | Editor | Kind of value | Value of the filter |
|---|---|---|---|
| `TCheckColumn` | Check box with three states: any row (shown faded), checked rows, unchecked rows; a click passes to the next state. The box is placed as the boxes of the cells, by the `HorzAlign` of the column | Boolean | `Boolean` |
| `TPopupColumn`, or any column with `FilterItems` | Text field with the button of the menu, where the values of the list can be chosen | list | `string`; with lines `Text=Value`, the value of the type of the column (see [Lists of texts and values](#lists-of-texts-and-values)) |
| `TIntegerColumn` | Text field with the button of the menu | integer | `Int64` |
| `TFloatColumn`, `TCurrencyColumn` | Text field with the button of the menu | decimal | `Double` |
| `TDateColumn`, `TDateTimeColumn` | Text field with the button of the menu, with the calendar and today | date | `TDate` |
| `TTimeColumn` | Text field with the button of the menu, with the current time | time | `TTime` |
| Any other column, such as `TStringColumn` | Text field with the button of the menu | text | `string` |

The user writes in a text field the filter of the column with the [syntax of the filters](#filter-syntax), or builds it with the [menu](#filter-menu). No text means no filter. The `FilterItems` of a column come before its type: a text column with a few possible values, such as *Open*, *Closed*, *Suspended*, can show them in its menu. On a phone or a tablet, the fields of the numbers, the dates and the times open the keyboard with the numbers.

A column of date and time is filtered by the day: its time is not compared.

**Esc** in an editor with a filter clears it and fires `OnFilter`.

To give a column an editor of your own, handle `OnCreateFilterEditor` and create a `TControl` that implements `IS4YGridFilterEditor`, the interface of the unit `Soft4You.FMX.Controls.Grid.Types`: the grid becomes its parent and frees it. Its value becomes the filter of the column with the default operator of the column; a value the text of a filter cannot hold, such as a range of two dates, is kept as it is in `FilterValue`, and the application filters with it. The editors of the unit `Soft4You.FMX.Controls.Grid.FilterEditors` can be used as models, or as base classes.

### Lists of texts and values

The cells of a column can show a text for each value of the data, such as an integer column with the values of an enumerated type, shown as *Open*, *Closed*, *Suspended* by `OnGetValue` or by a `CustomFormat` of the LiveBindings. Its `FilterItems` can then have a line `Text=Value` for each value:

```
Open=0
Closed=1
Suspended=2
```

- the user sees the texts in the menu, and writes them in the field: `Open`, `! Closed`, `<> Suspended`, without difference between upper and lower case; a text that is not in the list, or the value itself, such as `1`, is invalid;
- `FilterValue` is the value of the text, of the type of the column: an `Int64` for an integer column, a `string` for a text column with codes such as `Rome=RM`;
- `FilterMatches` compares the value of a row with it: the application passes the value of its data, such as `Ord(Customer.Status)`; a row given as the text of an item, such as the text shown in the cell, counts as the value of that item;
- `FilterValue`, `SetFilter` and the menu write the text of a value: `FilterValue[StatusColumn] := 2` writes *Suspended*;
- a line without `=` is a text that is its own value; a list where no line has `=` is a list of texts, as before, and accepts any text.

`ColumnSettings[].SetFilterEnum(TypeInfo(TStatus), ['Open', 'Closed', 'Suspended'])` fills `FilterItems` from an enumerated type: a line for each value, with the text of `ATexts` in the order of the values and the ordinal number as value. The texts are given by the application, so that they can be translated; an empty array uses the names of the values (`stOpen=0`).

```pascal
Grid.ColumnSettings.Add(StatusColumn).SetFilterEnum(TypeInfo(TStatus), [SOpen, SClosed, SSuspended]);
...
if Grid.FilterMatches(StatusColumn, Ord(LCustomer.Status)) then
```

### Settings of the columns

`ColumnSettings` is a collection, saved in the form, with the settings of the grid for some of its columns; a column without an item has the default settings.

| Property | Default | Meaning |
|---|---|---|
| `Column` | | The column of the grid the item is for |
| `Filterable` | `True` | Shows the editor of the column in the filter row |
| `FilterItems` | empty | The values the user can choose as filter of the column, in the menu of its filter: when there are some, the filter is a value of a list, whatever the type of the column. Lines `Text=Value` show the texts and give the values (see [Lists of texts and values](#lists-of-texts-and-values)) |
| `FilterMenu` | | A `TPopupMenu` of the application for the button of the editor of the column, instead of the menu of the grid (see [Filter menu](#filter-menu)) |
| `FooterKind` | `gfkNone` | What the footer shows under the column (see [Footer](#footer)) |
| `FooterText` | empty | The text of the footer when `FooterKind` is `gfkText`, for example *Total* |
| `FooterFormat` | empty | Format of the value of the footer, as for the `Format` function of Delphi, for example `'%.2f'`; empty writes it as the column writes its cells |
| `FooterAlignment` | `Trailing` | Alignment of the text of the footer in the cell of the column |
| `Sortable` | `True` | Lets the user sort the rows by the column with a click on its header (see [Sorting](#sorting)) |

## Filter syntax

The text of a filter is an **operator** and a **value**: the operator, when there is one, is at the start, and the value after it. The spaces after the operator do not count: `>10`, `> 10` and `>   10` are the same filter. This section can be copied into the guide of an application, for its users.

| Text | Meaning | Columns |
|---|---|---|
| `abc` | A value alone: the default operator of the column, **contains** for a text column, **equal to** for the others | all |
| `= abc` | Equal to | all |
| `<> abc`, `!= abc` | Not equal to | all |
| `! abc` | The opposite of the default operator: **does not contain** for a text column, **not equal to** for the others | all |
| `abc*` | Starts with | text |
| `*abc` | Ends with | text |
| `*abc*` | Contains, written explicitly | text |
| `< 10`, `<= 10`, `> 10`, `>= 10` | Less than, less than or equal to, greater than, greater than or equal to | numbers, dates, times |
| `=` alone | Is empty: the rows without a value | all |
| `<>` alone, `!=` alone | Is not empty: the rows with a value | all |

The texts are compared without difference between upper and lower case. The numbers, the dates and the times are written as in the regional settings of the computer, such as `1,5` or `15/03/2026` in Italian. A column with a list of values accepts only equal to, not equal to, is empty and is not empty; when its list has texts and values, only the texts of the list.

**The operators are read only at the start, and `*` only as the first or the last character.** Everything else is part of the value: `a*b` looks for *a\*b*, and `x=y` for *x=y*.

**Double quotes.** A value between double quotes is always text, as it is written; a double quote inside it is written twice. They are needed only when the value starts with a character of an operator (`=`, `<`, `>`, `!`, `"`, `*`), ends with `*`, or starts or ends with spaces, which are otherwise left out. The operator and the `*` of starts with and ends with stay outside the double quotes.

| Text | Meaning |
|---|---|
| `!2` | Does not contain *2* |
| `"!2"` | Contains *!2* |
| `= "<none>"` | Equal to *&lt;none&gt;* |
| `"*Special"*` | Starts with *\*Special* |
| `*"a*"*` | Contains *a\** |
| `"says ""yes"""` | Contains *says "yes"* |
| `" Rome"` | Contains *&nbsp;Rome*, with the space |

**States of the text.**

| State | Example | Filter |
|---|---|---|
| Empty | no text | none |
| Incomplete | an operator without a value, such as `>` or `!` | none yet; the text keeps its color |
| Valid | `>= 100` | applied |
| Invalid | `> abc` on a number column, `15/13/2026` on a date column, a double quote not closed, `ros*` on a list | none; the text takes the color of the part `filterinvalidtext` of the style, red by default |

The operators of two characters are written together: `> =5` is *greater than "=5"*, which is invalid on a number column.

**The text written by the grid.** When the grid writes a filter, with the menu, `SetFilter` or `FilterValue`, it writes the operator, a space and the value (`>= 100`, `! abc`, `<> Rome`), with the double quotes when the value needs them (`= "*Special*"`). The default operator is left out, unless it is chosen in the menu. A text written by the user is never changed while it is written.

## Filter menu

The button of a text field, three dots one above the other, opens the menu of the filter of its column. The menu of the grid has, from top to bottom:

| Column | Items |
|---|---|
| Text | Contains, Does not contain, Starts with, Ends with, Equal to, Not equal to |
| Numbers, dates, times | Equal to, Not equal to, Less than, Less than or equal to, Greater than, Greater than or equal to |
| List | Equal to, Not equal to, then the values of the list |
| All | Is empty, Is not empty |
| Date | Calendar..., Today |
| Time | Current time |
| All | Clear filter, as Esc |

The operator of the text, or the default one when there is no text, is shown selected, and so is the value of a list that is written. An **operator** chosen in the menu replaces the operator of the text and leaves the value: `100` becomes `>= 100`, `abc` becomes `*abc*`; a value that is still invalid stays too. A **value**, today, the current time or a date chosen in the **calendar** replace the value and leave the operator. After a choice the editor gets the focus again, with the cursor at the end of the text, and the data are filtered at once when the text changed and the filter is complete; an operator without a value waits for the user to write it. The menu is as wide as the column, or as its longest text when it is wider, up to 480 pixels, and at most 360 pixels high: a longer list scrolls. The texts of the items are `resourcestring` in English, which can be translated.

The application can change the menu:

- `OnFilterMenu(Sender, AColumn, AItems)` fires before the menu is shown: the application can add, insert and remove items of `AItems`. An item added with `AItems.Add` or `AItems.Insert` fires its `OnClick`, with the item as `Sender` (its `Column` is the column of the filter): the application writes the filter, for example with `SetFilter`, and calls `Filter` when the data must be filtered.
- `ColumnSettings[].FilterMenu` gives a column a `TPopupMenu` of the application, shown under the editor in place of the menu of the grid; its `PopupComponent` is the editor. The application does what its items do, with `FilterText`, `SetFilter` and `Filter`.
- `Model.GetFilterMenu`, `Model.ApplyFilterMenuItem`, `Model.ApplyFilterOperator` and `Model.ApplyFilterValue` build the menu of the grid and do what its items do, also from a menu of the application.
- `FilterRow.ShowMenuButton` hides the buttons; `FilterRow.MenuStyleLookup`, `FilterRow.MenuItemStyleLookup` and `FilterRow.CalendarStyleLookup` give the popup, its items and its calendar styles of their own (see [Styles](#styles)).

```pascal
procedure TMainForm.GridFilterMenu(Sender: TObject; const AColumn: TColumn; const AItems: TS4YGridFilterMenuItems);
begin
  // An item of the application, before the item that clears the filter.
  if AColumn = AmountColumn then
    AItems.Insert(AItems.IndexOfAction(gmaClear), 'Above the average', AboveAverageClick);
end;

procedure TMainForm.AboveAverageClick(Sender: TObject);
begin
  Grid.SetFilter(AmountColumn, gfoGreater, TValue.From<Currency>(FAverage));
  Grid.Filter;
end;
```

## Filters in code

| Member | Meaning |
|---|---|
| `FilterText[AColumn]` | The text of the filter of a column, as it is written; setting it reads it with the syntax of the filters and shows it in the editor |
| `FilterOperator[AColumn]` | The operator read in the text, a `TS4YGridFilterOperator`; `gfoNone` without text. A text without operator gives the default operator of the column |
| `FilterValue[AColumn]` | The value read in the text, a `TValue` of the type of the column (see [Editors](#editors)); empty when the filter is not applied, and for is empty and is not empty. Setting it sets the filter with the default operator of the column |
| `FilterState[AColumn]` | The state of the text: `gfsEmpty`, `gfsIncomplete`, `gfsValid` (the filter is applied) or `gfsInvalid` |
| `SetFilter(AColumn, AOperator, AValue)` | Sets the filter of a column, and writes its text; `gfoNone` removes it |
| `FilterMatches(AColumn, AValue)` | True when a value of a row passes the filter of its column; True when the column has no filter applied |
| `IsFiltered` | True when at least one column has a filter applied; always `False` while the row is hidden |
| `ToggleFilterRow` | Shows or hides the filter row, as the button of the header and `FilterRow.ShortCut` |
| `Filtered` | The same as `IsFiltered`, as a public read-only property for the LiveBindings (see [LiveBindings](#livebindings)) |
| `ClearFilters` | Clears the filters of all the columns |
| `Filter` | Fires `OnFilter` |

Setting a filter by code shows it in the editor and fires `OnFilterChanged`, not `OnFilter`: call `Filter` to filter the data.

| `TS4YGridFilterOperator` | Meaning |
|---|---|
| `gfoNone` | No filter |
| `gfoContains`, `gfoNotContains` | Contains, does not contain the value (text) |
| `gfoStartsWith`, `gfoEndsWith` | Starts with, ends with the value (text) |
| `gfoEqual`, `gfoNotEqual` | Equal to, not equal to the value |
| `gfoLess`, `gfoLessOrEqual`, `gfoGreater`, `gfoGreaterOrEqual` | The comparisons (numbers, dates, times) |
| `gfoEmpty`, `gfoNotEmpty` | Is empty, is not empty: the filter has no value |

| Event | Fires |
|---|---|
| `OnFilterChanged(Sender, AColumn)` | When the filter of a column changes, in its editor (at each key) or by code |
| `OnFilter(Sender)` | When the application must filter its data: Enter or Esc in an editor, a choice in the menu, a click on a check box of the row, the pause in the typing with `AutoFilter`, a call to `Filter`, the row shown or hidden while there are filters |
| `OnFilterMenu(Sender, AColumn, AItems)` | Before the menu of the filter of a column is shown |
| `OnFilterRowToggle(Sender)` | When the filter row is shown or hidden |
| `OnCreateFilterEditor(Sender, AColumn, var AEditor)` | When the grid creates the editor of a column: an editor of your own instead of the one of the grid |

Typing in an editor fires `OnFilterChanged` at each change, but `OnFilter` only with Enter, or with `AutoFilter` after a pause, so the data are not filtered again at each key; each key starts the pause again. A choice in the menu and a click on a check box are explicit, and filter at once.

**In memory**, `FilterMatches` does the comparison of the operators: the texts without difference between upper and lower case, the numbers as numbers, the dates only by the day and the times to the millisecond, also when the value of the row is a text or a variant. A row without a value passes only not equal to, does not contain and is empty. A value that cannot be compared with the filter, such as a text that is not a number in a number column, passes the filter.

**With a query**, the application reads the operator and the value of each column and writes the condition:

```pascal
procedure TMainForm.GridFilter(Sender: TObject);
var
  LWhere: string;
begin
  LWhere := '';

  case Grid.FilterOperator[AmountColumn] of
    gfoEqual:
      LWhere := 'Amount = :Amount';
    gfoGreater:
      LWhere := 'Amount > :Amount';
    gfoGreaterOrEqual:
      LWhere := 'Amount >= :Amount';
    gfoEmpty:
      LWhere := 'Amount is null';
    // ... the other operators
  end;

  if Grid.FilterState[AmountColumn] <> gfsValid then
    LWhere := '';

  // Build the query with LWhere, and give the parameter the value Grid.FilterValue[AmountColumn].AsExtended.
end;
```

## Footer

| Property | Default | Meaning |
|---|---|---|
| `FooterRow.Visible` | `False` | Shows the footer under the cells, over the horizontal scroll bar |
| `FooterRow.Height` | 0 | Height of the footer, in pixels; 0 is the height of the rows of the grid, plus the top and bottom padding of the style (see [Styles](#styles)) |

What the footer shows under each column is in `ColumnSettings`, with `FooterKind`:

| `FooterKind` | Shows |
|---|---|
| `gfkNone` | Nothing |
| `gfkSum` | The sum of the values of the rows |
| `gfkAverage` | The average of the values of the rows |
| `gfkCount` | The number of rows with a value |
| `gfkMin` | The lowest value, also of a date column |
| `gfkMax` | The highest value, also of a date column |
| `gfkText` | The text `FooterText` |

The values are read from the **rows of the grid**, the ones of `RowCount`, in the same way as the cells: from `OnGetValue` or from the LiveBindings. After the application has filtered its data and set `RowCount` again, the footer shows the totals of the rows shown. A value that is a number, or a text that is a number, is counted in the sum, the average and the extremes; any value that is not empty is counted by `gfkCount`. The value is written as the column writes its cells, with its decimals and its separator of the thousands, or with `FooterFormat`; the average of an integer column keeps two decimals.

The footer is calculated again when the number of rows changes, when a cell is edited in the grid and when the settings change. A `TGrid` does not see the changes of the data of the application: after one, call `UpdateFooter`.

| Member | Meaning |
|---|---|
| `UpdateFooter` | Calculates and draws the footer again |
| `OnGetFooterText(Sender, AColumn, var AText)` | Fires for each visible column with the text calculated, which the application can change: for example the total of all its data and not only of the rows shown, or a calculation of its own |

With the LiveBindings on a `TDataSet` (a `TLinkGridToDataSource`), the values of all the rows are read through the link: in the demo the footer of 200 rows of a `TFDMemTable` is calculated in a few milliseconds, and the current record of the data set does not move. On large data sets prefer `OnGetFooterText` with the totals calculated by the data set.

## Height of the header

In a `TGrid` the height of the header comes only from the style: it is the height of the part `header` of `gridstyle`, the style of `TGrid` and of `TStringGrid` too. Changing it means copying the whole style of the grid into a style book, for all the grids that use it. `TS4YGrid` sets it for each grid:

| Property | Default | Meaning |
|---|---|---|
| `HeaderHeightMode` | `ghmStyle` | Where the height comes from: `ghmStyle` the style of the grid, `ghmExplicit` `HeaderHeight`, `ghmRowHeight` the height of the rows |
| `HeaderHeight` | 0 | The height of the header, in pixels, with `ghmExplicit`; 0 keeps the height of the style |

With `ghmRowHeight` the header is as high as the rows, and follows `RowHeight` when it changes; `HeaderHeight` is ignored, but keeps its value for when the mode goes back to `ghmExplicit`. The height is applied again each time the style of the grid is loaded, for example when the style book of the form changes, and is seen in the form designer too. The filter row and the cells are placed under the header, and the button of the filter row stays square, as high as the header.

```delphi
// The header as high as the rows, also when RowHeight changes later.
Grid.HeaderHeightMode := ghmRowHeight;
Grid.RowHeight := 30;
```

## Sorting

With `Sorting.Enabled`, a click on the header of a column chooses the order of the rows. The order can have more **keys**: the rows are sorted by the first column, then, where the values of the first column are the same, by the second, and so on.

| Gesture | Effect |
|---|---|
| Click | Sorts only by the column; when the rows are already sorted only by it, inverts the direction |
| Shift+click | Adds the column as the next key; when it is already a key, inverts its direction and leaves the other keys |
| Ctrl+click (Cmd+click on macOS) | Removes the column from the order |
| Alt+click | Removes all the keys: back to the order of the data |

The header of each key shows an arrow, pointing up from the lowest value to the highest and down from the highest to the lowest; with more keys, also the position of the column in the order (1, 2, 3...), on the left of the arrow by default. The text of the header leaves the space for them. Moving a column by dragging its header does not change the order.

| Property | Default | Meaning |
|---|---|---|
| `Sorting.Enabled` | `False` | Lets the user choose the order with a click on the header |
| `Sorting.MultiColumn` | `True` | Lets Shift+click sort by more columns; `False` makes Shift+click a click |
| `Sorting.ShowOrder` | `True` | Shows the position of each column in the order when there are more keys |
| `Sorting.OrderPosition` | `gopBefore` | Where the position is shown: `gopBefore` on the left of the arrow, `gopAfter` on the right |
| `Sorting.OrderSpacing` | 3 | Space between the position and the arrow, in pixels |

The grid **does not sort the data itself**: as for the filters, it keeps the keys and fires `OnSort`, and the application sorts its data, for example a list of objects with a comparer that reads the keys, or a `TFDMemTable` with `IndexFieldNames` (`'City;Amount:D'`). With `OnGetValue`, call `Model.ClearCache` after sorting, as after a filter. The filters and the order are independent: an application that does both can filter its data and then sort them in one procedure, called by `OnFilter` and `OnSort`.

| Member | Meaning |
|---|---|
| `SortCount` | The number of keys; 0 when the rows have the order of the data |
| `SortColumn[I]`, `SortDescending[I]` | The column and the direction of each key, the first key first |
| `SortIndexOf(AColumn)` | The position of a column among the keys, -1 when it is not a key |
| `IsSorted` | True when there is at least one key |
| `Sorted` | The same as `IsSorted`, as a public read-only property for the LiveBindings (see [LiveBindings](#livebindings)) |
| `SetSort(AColumn, Descending)` | Sorts only by a column |
| `AddSort(AColumn, Descending)` | Adds a column as the last key, or changes its direction when it is already a key |
| `RemoveSort(AColumn)` | Removes a column from the keys |
| `ClearSort` | Removes all the keys |
| `OnSort(Sender)` | When the order changes, with a click or by code: the application sorts its data |

The methods work also when `Sorting.Enabled` is `False`, and the header shows the order they set; `Sortable` and `Enabled` are only about the clicks. The key of a column removed from the grid is forgotten without `OnSort`: the LiveBindings create the columns again when the link changes, so sort again after such a change. The clicks need the option `HeaderClick` or `ColumnMove` in `Options`, as the `OnHeaderClick` of `TGrid`, which still fires.

## Demo

`Demos\Grid\S4YGridDemo.dproj` (also part of the project group `Demos\Soft4You.FMX.Controls.Demos.groupproj`) has three tabs:

- **Objects**: 200 customers in a list of objects, shown with `OnGetValue` and filtered by the application in `OnFilter` with `FilterMatches`, with the cities in the menu of their filter (`FilterItems`), an item of the application in the menu of the amount (`OnFilterMenu`), an integer column of the status that shows texts, filtered with `SetFilterEnum` and a footer with a text, an average, a sum and a date; the panel on the left changes the filter row (`Visible`, `AutoFilter`, `FilterDelay`, `ClearOnHide`, `ShowButton`, `ClearFilters`; Ctrl+Shift+F shows and hides it) and the footer (`Visible`, the `FooterKind` of the amount, the sum of all the data with `OnGetFooterText`), the order (`Sorting.Enabled`, `MultiColumn`, `ShowOrder`, `OrderPosition`, `OrderSpacing`) and the height of the header (`HeaderHeightMode`, `HeaderHeight`, `RowHeight`), and shows the last `OnFilterChanged` with the text, the operator and the value read, the rows shown and the keys of the last `OnSort`; the application sorts the list with a comparer that reads the keys, after the filters;
- **LiveBindings**: the same customers in a `TFDMemTable`, shown through a `TLinkGridToDataSource`, filtered by the data set in `OnFilterRecord`, which compares each field with `FilterMatches`, and sorted with its `IndexFieldNames` in `OnSort`, with the footer read through the link;
- **Style book**: the grid with a dark style of the `TStyleBook` of the form, with the parts `filterrowbackground`, `footerbackground`, `footertext` and `filterinvalidtext`, dark fields of the filters (`DarkEditStyle`) and a dark menu of the filters, with a style of the popup (`DarkMenuStyle`) and of its items (`DarkMenuItemStyle`).

Install the suite packages first.

## Example

A list of objects shown with `OnGetValue`, filtered by the application with the filters of the grid:

```pascal
procedure TMainForm.GridFilter(Sender: TObject);
begin
  FVisible.Clear;

  for var LCustomer in FCustomers do
    if Grid.FilterMatches(NameColumn, LCustomer.Name) and Grid.FilterMatches(AmountColumn, LCustomer.Amount) then
      FVisible.Add(LCustomer);

  // As in any TGrid, the values already shown are cleared: the rows are now other customers.
  Grid.Model.ClearCache;
  Grid.RowCount := FVisible.Count;
  Grid.Repaint;
  Grid.UpdateFooter;
end;

procedure TMainForm.GridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
begin
  if ACol = NameColumn.Index then
    Value := FVisible[ARow].Name
  else if ACol = AmountColumn.Index then
    Value := FVisible[ARow].Amount;
end;
```

## LiveBindings

A `TLinkGridToDataSource` fills a `TS4YGrid` as a `TGrid`: it creates a column for each field, of the type of the field (`TStringColumn`, `TIntegerColumn`, `TCurrencyColumn`, `TDateColumn`, `TCheckColumn` and so on), so the filter row gets the editors of those types. The columns created by the link are not in the form: their `ColumnSettings` are added in code, after the link is active, for example in `OnCreate` of the form, finding the columns by their `Header`, which is the name of the field.

The application filters the data set in `OnFilter`, for example with its `Filtered` property and `OnFilterRecord`, where `FilterMatches` compares the fields with the filters of their columns; the link shows the records that pass, and the footer is calculated again.

```pascal
procedure TMainForm.CustomersFilterRecord(DataSet: TDataSet; var Accept: Boolean);
var
  LField: TField;
  LValue: TValue;
begin
  // The header of each column of the link is the name of its field.
  Accept := True;

  for var I := 0 to Grid.ColumnCount - 1 do
  begin
    LField := DataSet.FindField(Grid.Columns[I].Header);

    if Accept and Assigned(LField) then
    begin
      if LField.IsNull then
        LValue := TValue.Empty
      else
        LValue := TValue.FromVariant(LField.Value);

      Accept := Grid.FilterMatches(Grid.Columns[I], LValue);
    end;
  end;
end;
```

**The grid as a source of bindings.** The settings of the grid can be bound to the controls of the application, also in the direction from the grid to the controls: the grid tells the LiveBindings when `FilterRow`, `FooterRow` and `Sorting` change, also when the user shows or hides the filter row with the button of the header or with the keys, so a check box bound to `FilterRow.Visible` with a `TLinkControlToProperty` follows the row. The public read-only properties `Filtered` and `Sorted` tell whether the data are filtered and sorted, and the LiveBindings are told when they change, not at each key typed in a filter: for example, a `TBindExpression` with `SourceExpression` `Filtered` and `ControlExpression` `Enabled` enables a button that clears the filters. The filters and the keys of the order themselves are indexed by column, so they cannot be bound.

## Styles

The filter row is added to the style of the grid when the style is applied: to the part `background`, aligned to the top after the header, so the part `content` with the cells starts under it. The row draws a line on its bottom side with the brush `linefill` of the style, the brush of the lines of the grid, and its editors take the styles of the form, looked for in its style book and in the style of the platform: `editstyle`, the style of `TEdit`, for the text fields, and `checkcellstyle`, the style of the check boxes of the cells of the grid, for the check boxes, so that a check box of the row looks as the ones of the cells. `FilterRow.EditStyleLookup` and `FilterRow.CheckBoxStyleLookup` give the editors of the row styles of their own, different from the other controls of the application; a style that is not found leaves the style of `TEdit` or of `TCheckBox`. The button of the menu is square, as high as the inside of the field; it takes the style `ellipseseditbutton` of the buttons of `TEdit`, and draws its three dots with the color of the text of the style of `TEdit`. A style of the text fields made of shapes, such as `DarkEditStyle` of the demo, has the parts of the style of `TEdit` that the fields use: `background`, `content` for the text, `buttons` for the button of the menu, and the brushes `foreground`, the color of the text and of the dots, and `selection`, with the color `caretcolor` for the caret.

The menu of a filter is a `TPopup`, which takes the style book of the form. `FilterRow.MenuStyleLookup` gives the popup a style of its own, for its background and its border, without changing the other popups of the application; the list of the items inside it then has no background of its own, so the background of the style is seen. When the popup finds no style, as with the styles of the platform of Windows, which have no `popupstyle`, or with a `MenuStyleLookup` that is not in the style book, the list keeps the background and the border of its own style. The items take the style of the items of `TListBox`, or the one named by `FilterRow.MenuItemStyleLookup`: with a dark popup, give them a style with a light text, such as a `TLayout` with a `TText` named `text`. The lines between the groups of items take the color of the text of that style, so they are seen on any background. The calendar of a date filter takes the style of `TCalendar`, or the one named by `FilterRow.CalendarStyleLookup`. A style of the items or of the calendar that is not found leaves the style of `TListBox` or of `TCalendar`.

The footer is added in the same way, aligned to the bottom over the horizontal scroll bar, with a line on its top side; its texts have the font and the color of the text of the grid.

The style of the grid is `S4YGridStyle` when the style book of the form has it, otherwise `gridstyle`, the style of `TGrid`. A style named `S4YGridStyle` therefore changes all the grids of the form without setting their `StyleLookup`, and leaves the `TGrid` and `TStringGrid` controls as they are; `StyleLookup` still gives a grid a style of its own.

A style of the grid in a `TStyleBook` can add these parts, all optional:

| Part | Use |
|---|---|
| `filterrowbackground` | Any control: the background of the filter row; its `Padding` is the space between the editors and the sides of their cells |
| `footerbackground` | Any control: the background of the footer; its `Padding` is a space around the texts of all the cells, besides the `Padding` of the columns |
| `footertext` | A `TText`: the font and the color of the texts of the footer |
| `sortindicator` | A `TText`: the color of the arrows of the order and the font of the positions in the order; without it, the color of the text of the header and a smaller font |
| `filterinvalidtext` | A `TText`: the color of the text of a filter that cannot be read; without it, red |
| `filtermenubutton` | Any control, such as a `TPath`: shown in the middle of the button of the menu, in place of the three dots; each button shows a copy of it |
| `filterbutton` | Any control, such as a `TPath`: shown in the middle of the button of the header, in place of the funnel |

Edit Custom Style, in the menu of the grid in the form designer, copies the style of the grid into the style book together with the parts `filterrowbackground`, `footerbackground` and `filterinvalidtext`, with the values that the grid uses without them: transparent backgrounds, 2 pixels around the editors, none around the texts of the footer, and red for the text that cannot be read. They are hidden in the style designer, and the grid shows the two backgrounds in their places, so a change to their fill, stroke or padding is seen in the grid. The other parts of the table are not copied, because a style that has them changes the grid, for example `footertext` takes the place of the font of the grid in the footer: add them to the copy by hand.

The texts of the footer are placed in their cells as the texts of the cells of the grid: in the cell less the `Padding` of the column (a published property of `TColumn`, 3 pixels on each side by default), so a total is aligned with the values above it. When a style has the part `filterrowbackground` or `footerbackground`, its `Padding` is always used, also when it is 0: a style that adds `filterrowbackground` sets its `Padding` too, for example 2 on each side. Without the part, as in the styles of the platform, the editors are 2 pixels from the sides of their cells, and the texts of the footer have only the `Padding` of the columns. The top and bottom padding of the parts are added to the automatic heights; a `Height` greater than 0 comes first, and the editors and the texts take the space left inside the padding.

A style without the part `background` has no filter row and no footer.

**Style books with more than one platform.** A `TStyleBook` holds a list of styles, one for each platform, and at run time uses only one of them: the one of the platform where the application runs, when the list has it, otherwise the first one (`Default`). A style that is only in another item of the list is not found. The IDE adds an item when a platform is added in the style designer, and also when a control of the form is given a custom style copied from the style of the platform (Edit Custom Style): from then on, on that platform, the application finds only the styles of that item, and the grid, its fields and its menu go back to the style of the platform. Copy their styles into that item too, for example by loading the same `.style` file into it in the style designer. When Edit Custom Style ends with the error "Cannot find style resource", as it can with a style book that holds only styles made of shapes, add the platform in the style designer first, then edit the custom style again.
