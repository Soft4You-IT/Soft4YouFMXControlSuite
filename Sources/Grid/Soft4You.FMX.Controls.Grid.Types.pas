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
