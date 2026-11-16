unit Soft4You.FMX.Controls.Grid.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YGrid - types of the grid
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Rtti,
  FMX.Controls,
  FMX.Grid;

type
  /// <summary>
  /// An editor of the filter row of TS4YGrid: the control in the cell of a column, where the user writes or chooses the
  /// value of the filter of that column.
  /// </summary>
  /// <remarks>
  /// The grid creates an editor for each column, from the type of the column; an editor of your own, given by
  /// OnCreateFilterEditor, must be a TControl that implements this interface.
  /// </remarks>
  IS4YGridFilterEditor = interface
    ['{6C1F2E0A-3B7D-4E5F-9A21-8D4C7B0E6F13}']
    /// <summary>Returns the value of the filter shown by the editor; an empty value when there is no filter.</summary>
    function GetFilterValue: TValue;
    /// <summary>Shows AValue in the editor; an empty value clears the editor. It does not fire the change.</summary>
    procedure SetFilterValue(const AValue: TValue);
    /// <summary>Sets the event the editor fires when the user changes its value.</summary>
    procedure SetOnFilterValueChange(const AEvent: TNotifyEvent);
    /// <summary>Sets the event the editor fires when the user asks to filter, for example with the Enter key.</summary>
    procedure SetOnFilterSubmit(const AEvent: TNotifyEvent);
  end;

  /// <summary>
  /// How the filter of a column compares the values of the rows with its value.
  /// </summary>
  /// <remarks>
  /// gfoNone: no filter, every row.
  /// gfoContains: the text of the row contains the value; the default of the text columns.
  /// gfoNotContains: the text of the row does not contain the value.
  /// gfoStartsWith: the text of the row starts with the value.
  /// gfoEndsWith: the text of the row ends with the value.
  /// gfoEqual: the value of the row is the value; the default of the other columns.
  /// gfoNotEqual: the value of the row is not the value.
  /// gfoLess: the value of the row is lower than the value.
  /// gfoLessOrEqual: the value of the row is lower than the value, or the value.
  /// gfoGreater: the value of the row is higher than the value.
  /// gfoGreaterOrEqual: the value of the row is higher than the value, or the value.
  /// gfoEmpty: the row has no value; the filter has no value.
  /// gfoNotEmpty: the row has a value; the filter has no value.
  /// The texts are compared without difference between upper and lower case.
  /// </remarks>
  TS4YGridFilterOperator = (
    gfoNone,
    gfoContains,
    gfoNotContains,
    gfoStartsWith,
    gfoEndsWith,
    gfoEqual,
    gfoNotEqual,
    gfoLess,
    gfoLessOrEqual,
    gfoGreater,
    gfoGreaterOrEqual,
    gfoEmpty,
    gfoNotEmpty
  );

  /// <summary>
  /// The kind of value of the filter of a column, from the type of the column: it decides the operators and how the
  /// text of the filter is read.
  /// </summary>
  /// <remarks>
  /// gvkText: a text, a string; any operator but the comparisons.
  /// gvkList: a value of a list, a string, for a column with FilterItems or a TPopupColumn; equal or not equal.
  /// gvkInteger: a whole number, an Int64.
  /// gvkFloat: a number with decimals, a Double.
  /// gvkDate: a date, a TDate, also for a column of date and time.
  /// gvkTime: a time, a TTime.
  /// gvkBoolean: True or False, for a check column.
  /// </remarks>
  TS4YGridFilterValueKind = (
    gvkText,
    gvkList,
    gvkInteger,
    gvkFloat,
    gvkDate,
    gvkTime,
    gvkBoolean
  );

  /// <summary>
  /// A value of the list of the filter of a column, from a line Text=Value of its FilterItems.
  /// </summary>
  TS4YGridFilterItem = record
    /// <summary>The text the user sees and writes, such as Open.</summary>
    Text: string;
    /// <summary>The value the application gets, of the type of the column, such as 1 for an integer column.</summary>
    Value: TValue;
  end;

  /// <summary>
  /// The state of the text of the filter of a column.
  /// </summary>
  /// <remarks>
  /// gfsEmpty: no text, no filter.
  /// gfsIncomplete: an operator without a value, such as "&gt;": no filter yet.
  /// gfsValid: an operator and a value: the filter is applied.
  /// gfsInvalid: a text that cannot be read, such as a number column with "&gt; abc": no filter, the text is shown
  /// with the color of the part filterinvalidtext of the style.
  /// </remarks>
  TS4YGridFilterState = (
    gfsEmpty,
    gfsIncomplete,
    gfsValid,
    gfsInvalid
  );

  /// <summary>
  /// What an item of the menu of the filter of a column does.
  /// </summary>
  /// <remarks>
  /// gmaOperator: writes its operator in the text of the filter, before the value.
  /// gmaValue: writes its value, after the operator: a value of the list of the column.
  /// gmaCalendar: shows a calendar, and writes the date chosen.
  /// gmaToday: writes the date of today.
  /// gmaCurrentTime: writes the current time, to the minute.
  /// gmaClear: clears the filter, as Esc.
  /// gmaSeparator: a line between two groups of items.
  /// gmaCustom: an item of the application, which does what its OnClick does.
  /// </remarks>
  TS4YGridFilterMenuAction = (
    gmaOperator,
    gmaValue,
    gmaCalendar,
    gmaToday,
    gmaCurrentTime,
    gmaClear,
    gmaSeparator,
    gmaCustom
  );

  /// <summary>
  /// What the footer shows under a column.
  /// </summary>
  /// <remarks>
  /// gfkNone: nothing.
  /// gfkSum: the sum of the values of the rows.
  /// gfkAverage: the average of the values of the rows.
  /// gfkCount: the number of rows with a value.
  /// gfkMin: the lowest value, also of a date column.
  /// gfkMax: the highest value, also of a date column.
  /// gfkText: the text FooterText of the settings of the column.
  /// </remarks>
  TS4YGridFooterKind = (
    gfkNone,
    gfkSum,
    gfkAverage,
    gfkCount,
    gfkMin,
    gfkMax,
    gfkText
  );

  /// <summary>
  /// Where the header shows the position of a column in the order, compared to the arrow of its direction.
  /// </summary>
  /// <remarks>
  /// gopBefore: on the left of the arrow.
  /// gopAfter: on the right of the arrow.
  /// </remarks>
  TS4YGridSortOrderPosition = (
    gopBefore,
    gopAfter
  );

  /// <summary>
  /// A key of the order of the rows: a column and its direction.
  /// </summary>
  TS4YGridSortKey = record
    /// <summary>The column the rows are sorted by.</summary>
    Column: TColumn;
    /// <summary>True sorts from the highest value to the lowest.</summary>
    Descending: Boolean;
  end;

  /// <summary>
  /// An event about a column of the grid.
  /// </summary>
  TS4YGridColumnEvent = procedure(Sender: TObject; const AColumn: TColumn) of object;

  /// <summary>
  /// The event that lets the application give the editor of the filter of a column.
  /// </summary>
  /// <remarks>
  /// AEditor is nil: leave it nil for the editor of the grid, or create a TControl that implements
  /// IS4YGridFilterEditor; the grid becomes its parent and frees it.
  /// </remarks>
  TS4YGridCreateFilterEditorEvent = procedure(Sender: TObject; const AColumn: TColumn; var AEditor: TControl) of object;

  /// <summary>
  /// The event that lets the application change the text of the footer under a column.
  /// </summary>
  /// <remarks>
  /// AText is the text the grid calculated from the settings of the column, empty when it has none.
  /// </remarks>
  TS4YGridFooterTextEvent = procedure(Sender: TObject; const AColumn: TColumn; var AText: string) of object;

implementation

end.
