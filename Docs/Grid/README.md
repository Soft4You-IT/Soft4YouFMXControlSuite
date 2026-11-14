# TS4YGrid for FireMonkey

A grid with a **filter row** under the header: an editor for each column, where the user writes the value to look for in that column. The editor comes from the type of the column: a text box for a text column, a box that accepts only numbers for an integer, decimal or currency column, a date picker for a date column, a check box with three states for a check column.

`TS4YGrid` is a `TGrid`: the cells get their values from `OnGetValue` or from the LiveBindings, as in a `TGrid`, and every property, column and event of `TGrid` is there. The grid **does not filter the data itself**: it keeps the filter values and tells the application when to filter, with `OnFilter`; the application filters its own data, for example a list of objects or a `TDataSet`, and sets `RowCount` again.

The filter row takes the look of the style of the grid, from the platform or from a `TStyleBook`: it is added to that style, not drawn with a style of its own.

Unit: `Soft4You.FMX.Controls.Grid`, in `Sources\Grid`.

## Installation

The grid is part of the Soft4You FMX Control Suite. It is built into the runtime package `Soft4You.FMX.Controls.Suite`, and its registration into the design-time package `SuiteD`: see the README in the root of the repository. It appears in the Tool Palette page **Soft4You FMX Controls Suite**.

Add the folder `Sources\Grid` to the Delphi library path to compile your own projects with the units.

## Files

| File | Content |
|---|---|
| `Sources\Grid\Soft4You.FMX.Controls.Grid.pas` | `TS4YGrid`, its model `TS4YGridModel`, the settings of the filter row (`TS4YGridFilterRow`) and of the columns (`TS4YGridColumnSetting`, `TS4YGridColumnSettings`) |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.Style.pas` | `TS4YStyledGrid`, the presentation that adds the filter row to the style of the grid, and `TS4YGridBand`, the row itself |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.FilterEditors.pas` | The editors of the filter row: `TS4YGridTextFilterEditor`, `TS4YGridNumberFilterEditor`, `TS4YGridDateFilterEditor`, `TS4YGridCheckFilterEditor` |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.Types.pas` | The interface of the editors `IS4YGridFilterEditor` and the event types |
| `Sources\Grid\Soft4You.FMX.Controls.Grid.Register.pas` | Registration in the Tool Palette (design time) |
| `Graphics\Grid\TS4YGrid.svg`, `TS4YGrid.bmp`, `GridDesign.rc` | Icon of the Tool Palette (vector master and 24x24 bitmap) and the resource script that links it |

## Filter row

| Property | Default | Meaning |
|---|---|---|
| `FilterRow.Visible` | `False` | Shows the filter row under the header |
| `FilterRow.Height` | 0 | Height of the row, in pixels; 0 is automatic: the height of the editors, at least the height of the rows of the grid |
| `FilterRow.ClearOnHide` | `False` | Clears the filters when the row is hidden, and fires `OnFilter`, so the application shows all its data again; `False` keeps them, and shows them again with the row |

The row follows the columns: an editor has the width of its column, moves with it when the columns are moved or scrolled horizontally, and is hidden with it. The cells of the grid start under the row.

### Editors

| Type of the column | Editor | Value of the filter |
|---|---|---|
| `TIntegerColumn` | Text box that accepts only digits and the minus sign | `Int64` |
| `TFloatColumn`, `TCurrencyColumn` | Text box that accepts only digits, the minus sign and the decimal separator | `Double` |
| `TDateColumn` | Date picker with the button that clears the date | `TDate` |
| `TCheckColumn` | Check box with three states: any row (shown faded), checked rows, unchecked rows; a click passes to the next state | `Boolean` |
| Any other column, such as `TStringColumn` | Text box | `string` |

Every editor has an **empty** state, which means no filter for that column: no text, a text that is not yet a number (such as a minus sign alone), no date, the faded check box.

To give a column an editor of your own, handle `OnCreateFilterEditor` and create a `TControl` that implements `IS4YGridFilterEditor`, the interface of the unit `Soft4You.FMX.Controls.Grid.Types`: the grid becomes its parent and frees it. The editors of the unit `Soft4You.FMX.Controls.Grid.FilterEditors` can be used as models, or as base classes.

### Settings of the columns

`ColumnSettings` is a collection, saved in the form, with the settings of the grid for some of its columns; a column without an item has the default settings.

| Property | Default | Meaning |
|---|---|---|
| `Column` | | The column of the grid the item is for |
| `Filterable` | `True` | Shows the editor of the column in the filter row |

## Filter values

| Member | Meaning |
|---|---|
| `FilterValue[AColumn]` | The filter value of a column, a `TValue` of the type of the column; empty when the column has no filter. Setting it shows the value in the editor |
| `IsFiltered` | True when at least one column has a filter |
| `ClearFilters` | Clears the filters of all the columns |
| `Filter` | Fires `OnFilter` |

| Event | Fires |
|---|---|
| `OnFilterChanged(Sender, AColumn)` | When the filter value of a column changes, in its editor or by code |
| `OnFilter(Sender)` | When the application must filter its data: Enter in an editor, a click on a check box of the row, a call to `Filter`, the row hidden with `ClearOnHide` |
| `OnCreateFilterEditor(Sender, AColumn, var AEditor)` | When the grid creates the editor of a column: an editor of your own instead of the one of the grid |

The meaning of a value is decided by the application: for a text it is usually "contains", for a number or a date "equal". Typing in an editor fires `OnFilterChanged` at each change, but `OnFilter` only with Enter, so the data are not filtered again at each key.

## Example

A list of objects shown with `OnGetValue`, filtered by the application:

```pascal
procedure TMainForm.GridFilter(Sender: TObject);
var
  LName: TValue;
begin
  LName := Grid.FilterValue[NameColumn];
  FVisible.Clear;

  for var LCustomer in FCustomers do
    if LName.IsEmpty or LCustomer.Name.Contains(LName.AsString) then
      FVisible.Add(LCustomer);

  Grid.RowCount := FVisible.Count;
  Grid.Repaint;
end;

procedure TMainForm.GridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
begin
  if ACol = NameColumn.Index then
    Value := FVisible[ARow].Name;
end;
```

## Styles

The filter row is added to the style of the grid when the style is applied: to the part `background`, aligned to the top after the header, so the part `content` with the cells starts under it. The row draws a line on its bottom side with the brush `linefill` of the style, the brush of the lines of the grid, and its editors take the styles of `TEdit`, `TDateEdit` and `TCheckBox`.

A style of the grid in a `TStyleBook` can add a part `filterrowbackground`, any control: it becomes the background of the filter row. A style without the part `background` has no filter row.
