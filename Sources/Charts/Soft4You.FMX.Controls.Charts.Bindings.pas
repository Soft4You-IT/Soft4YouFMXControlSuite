unit Soft4You.FMX.Controls.Charts.Bindings;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  Charts - support of the LiveBindings through TLinkGridToDataSource
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  Soft4You.FMX.Controls.Charts;

type
  /// <summary>Class of a chart that can be filled by a TLinkGridToDataSource.</summary>
  TS4YCustomChartClass = class of TS4YCustomChart;

/// <summary>
/// Makes the charts of class AClass usable as the grid of a TLinkGridToDataSource.
/// </summary>
/// <remarks>
/// Called by the units of the charts when they are loaded: the applications do not call it.
/// </remarks>
procedure RegisterChartBindingClass(const AClass: TS4YCustomChartClass);

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Bindings.EvalProtocol,
  System.Bindings.ObjEval,
  Data.Bind.Components,
  Data.Bind.Editors,
  Data.Bind.Grid;

type
  /// <summary>The current row of a chart, as the expressions of a link see it: Caption and Values[N].</summary>
  TS4YChartBindingRow = class
  private
    FBinding: IS4YChartBinding;
    FIndex: Integer;
    function GetCaption: string;
    function GetValues(AColumn: Integer): Single;
    procedure SetCaption(const Value: string);
    procedure SetValues(AColumn: Integer; const Value: Single);
  public
    property Caption: string read GetCaption write SetCaption;
    property Values[AColumn: Integer]: Single read GetValues write SetValues;
  end;

  /// <summary>Grid editor of a chart: creates, walks and removes its rows for a TLinkGridToDataSource.</summary>
  TS4YChartGridEditor = class(TBindGridEditor)
  private
    [Weak] FChart: TS4YCustomChart;
    FRow: TS4YChartBindingRow;
    FUpdateCounter: Integer;
  protected
    function AddItem(Select: Boolean): IScope; override;
    procedure BeginUpdate; override;
    function CanInsertItem: Boolean; override;
    procedure ClearList; override;
    function CurrentIndex: Integer; override;
    function CurrentItem: IScope; override;
    procedure DeleteToEnd; override;
    procedure EndUpdate; override;
    procedure GetColumnIndices(ANames: TStrings); override;
    procedure GetColumnNames(ANames: TStrings); override;
    function GetItemIndex: Integer; override;
    function GetPositionGetter(var AGetter: string; var ABase: Integer): Boolean; override;
    function GetPositionSetter(var ASetter: string; var ABase: Integer): Boolean; override;
    function GetRowCount: Integer; override;
    function GetSelectedText: string; override;
    function InsertItem(Select: Boolean): IScope; override;
    function MoveNext: Boolean; override;
    procedure SetItemIndex(AIndex: Integer); override;
    procedure SetSelectedText(const AValue: string); override;
  public
    constructor Create(const AChart: TS4YCustomChart);
    destructor Destroy; override;
  end;

  /// <summary>Creates the grid editor of the charts.</summary>
  TS4YChartEditorFactory = class(TBindEditorFactory)
  public
    function CreateEditor(AIntf: TGuid; AObject: TObject): IInterface; override;
    function Supports(AIntf: TGuid; AObject: TObject): Boolean; override;
  end;

  /// <summary>Column manager of a chart: turns the columns of a TLinkGridToDataSource into the captions and the values of the chart.</summary>
  TS4YChartColumnManager = class(TInterfacedObject, ILinkGridToDataSourceControlManager)
  private
    FBinding: IS4YChartBinding;
    function Describe(const AIndex: Integer; const ADescription: TCreateColumnDescription): TLinkGridColumnDescription;
  public
    constructor Create(const AChart: TS4YCustomChart);

    { ILinkGridToDataSourceControlManager }
    function AddColumn(AColumn: TBaseLinkGridToDataSourceColumn): Integer; overload;
    function AddColumn(ADataSource: TBaseLinkingBindSource; const AMemberName: string): Integer; overload;
    procedure BeginUpdate;
    function CanAddColumn(AColumn: TBaseLinkGridToDataSourceColumn): Boolean; overload;
    function CanAddColumn(ADataSource: TBaseLinkingBindSource; const AMemberName: string): Boolean; overload;
    procedure ClearColumns;
    function DescribeColumn(AIndex: Integer; AColumn: TBaseLinkGridToDataSourceColumn): TLinkGridColumnDescription;
      overload;
    function DescribeColumn(AIndex: Integer; ADataSource: TBaseLinkingBindSource;
      const AMemberName: string): TLinkGridColumnDescription; overload;
    procedure EndUpdate;
    function GetDefaultColumnWidth: Integer;
    procedure SetDefaultColumnWidth(AWidth: Integer);
    procedure UpdateColumn(AIndex: Integer; AColumn: TBaseLinkGridToDataSourceColumn); overload;
    procedure UpdateColumn(AIndex: Integer; ADataSource: TBaseLinkingBindSource; const AMemberName: string); overload;
  end;

  /// <summary>Tells the LiveBindings which classes of charts can be the grid of a TLinkGridToDataSource.</summary>
  TS4YChartColumnFactory = class(TLinkGridToDataSourceColumnFactory)
  public
    function CreateFactory(AIntf: TGuid; AGrid: TComponent): IInterface; override;
    function GridClasses: TArray<TComponentClass>; override;
    function Supports(AIntf: TGuid; AGrid: TComponent): Boolean; override;
    function UsesUnits: TArray<string>; override;
  end;

const
  // Expressions of the row seen by the link: the caption, and the values of a column.
  C_CAPTION_EXPRESSION = 'Caption';
  C_VALUES_EXPRESSION = 'Values[%d]';
  // Property of the chart that the link keeps in step with the current record.
  C_POSITION_EXPRESSION = 'ItemIndex';
  // Name of the column of the captions, for the editors of the IDE.
  C_CAPTION_COLUMN_NAME = 'Caption';
  // Width asked by the link for the columns: a chart has no columns to size.
  C_DEFAULT_COLUMN_WIDTH = 64;
  C_NO_ROW = -1;
  C_UNIT_NAME = 'Soft4You.FMX.Controls.Charts.Bindings';

var
  GChartClasses: TList<TComponentClass>;

procedure RegisterChartBindingClass(const AClass: TS4YCustomChartClass);
begin
  if not GChartClasses.Contains(AClass) then
    GChartClasses.Add(AClass);
end;

{ TS4YChartBindingRow }

function TS4YChartBindingRow.GetCaption: string;
begin
  Result := FBinding.BindingGetCaption(FIndex);
end;

function TS4YChartBindingRow.GetValues(AColumn: Integer): Single;
begin
  Result := FBinding.BindingGetValue(FIndex, AColumn);
end;

procedure TS4YChartBindingRow.SetCaption(const Value: string);
begin
  if FIndex > C_NO_ROW then
    FBinding.BindingSetCaption(FIndex, Value);
end;

procedure TS4YChartBindingRow.SetValues(AColumn: Integer; const Value: Single);
begin
  if FIndex > C_NO_ROW then
    FBinding.BindingSetValue(FIndex, AColumn, Value);
end;

{ TS4YChartGridEditor }

constructor TS4YChartGridEditor.Create(const AChart: TS4YCustomChart);
begin
  inherited Create;

  FChart := AChart;
  FRow := TS4YChartBindingRow.Create;
  FRow.FBinding := AChart;
  FRow.FIndex := C_NO_ROW;
end;

destructor TS4YChartGridEditor.Destroy;
begin
  FRow.Free;

  inherited;
end;

function TS4YChartGridEditor.AddItem(Select: Boolean): IScope;
begin
  FRow.FIndex := FRow.FBinding.BindingAddRow;

  if Select then
    FChart.ItemIndex := FRow.FIndex;

  Result := WrapObject(FRow);
end;

procedure TS4YChartGridEditor.BeginUpdate;
begin
  Inc(FUpdateCounter);
  FRow.FBinding.BindingBeginUpdate;

  if FUpdateCounter = 1 then
    FRow.FIndex := C_NO_ROW;
end;

function TS4YChartGridEditor.CanInsertItem: Boolean;
begin
  Result := False;
end;

procedure TS4YChartGridEditor.ClearList;
begin
  FRow.FIndex := C_NO_ROW;
  FRow.FBinding.BindingClearRows;
end;

function TS4YChartGridEditor.CurrentIndex: Integer;
begin
  if FRow.FIndex = C_NO_ROW then
    FRow.FIndex := FChart.ItemIndex;

  Result := FRow.FIndex;
end;

function TS4YChartGridEditor.CurrentItem: IScope;
begin
  // The record changed outside a fill of the list is the current one of the chart.
  if FRow.FIndex = C_NO_ROW then
    FRow.FIndex := FChart.ItemIndex;

  Result := WrapObject(FRow);
end;

procedure TS4YChartGridEditor.DeleteToEnd;
begin
  if FRow.FIndex = C_NO_ROW then
    ClearList
  else
    FRow.FBinding.BindingDeleteRowsFrom(FRow.FIndex);
end;

procedure TS4YChartGridEditor.EndUpdate;
begin
  Dec(FUpdateCounter);

  if FUpdateCounter = 0 then
    FRow.FIndex := C_NO_ROW;

  FRow.FBinding.BindingEndUpdate;
end;

procedure TS4YChartGridEditor.GetColumnIndices(ANames: TStrings);
begin
  ANames.Add('0');
end;

procedure TS4YChartGridEditor.GetColumnNames(ANames: TStrings);
begin
  ANames.Add(C_CAPTION_COLUMN_NAME);
end;

function TS4YChartGridEditor.GetItemIndex: Integer;
begin
  Result := FChart.ItemIndex;
end;

function TS4YChartGridEditor.GetPositionGetter(var AGetter: string; var ABase: Integer): Boolean;
begin
  AGetter := C_POSITION_EXPRESSION;
  ABase := 0;
  Result := True;
end;

function TS4YChartGridEditor.GetPositionSetter(var ASetter: string; var ABase: Integer): Boolean;
begin
  ASetter := C_POSITION_EXPRESSION;
  ABase := 0;
  Result := True;
end;

function TS4YChartGridEditor.GetRowCount: Integer;
begin
  Result := FRow.FBinding.BindingGetRowCount;
end;

function TS4YChartGridEditor.GetSelectedText: string;
begin
  // A chart is read-only: the link never reads text back from it.
  Result := '';
end;

function TS4YChartGridEditor.InsertItem(Select: Boolean): IScope;
begin
  Result := nil;
end;

function TS4YChartGridEditor.MoveNext: Boolean;
begin
  if FRow.FBinding.BindingGetRowCount = 0 then
    Exit(False);

  if FRow.FIndex = C_NO_ROW then
    FRow.FIndex := 0
  else
    FRow.FIndex := FRow.FIndex + 1;

  Result := FRow.FIndex < FRow.FBinding.BindingGetRowCount;
end;

procedure TS4YChartGridEditor.SetItemIndex(AIndex: Integer);
begin
  FChart.ItemIndex := AIndex;
end;

procedure TS4YChartGridEditor.SetSelectedText(const AValue: string);
begin
  // A chart is read-only: nothing to write back.
end;

{ TS4YChartEditorFactory }

function TS4YChartEditorFactory.CreateEditor(AIntf: TGuid; AObject: TObject): IInterface;
begin
  Result := TS4YChartGridEditor.Create(TS4YCustomChart(AObject));
end;

function TS4YChartEditorFactory.Supports(AIntf: TGuid; AObject: TObject): Boolean;
begin
  Result := ((AIntf = IBindListEditorCommon) or (AIntf = IBindListEditor)) and (AObject is TS4YCustomChart);
end;

{ TS4YChartColumnManager }

constructor TS4YChartColumnManager.Create(const AChart: TS4YCustomChart);
begin
  inherited Create;

  FBinding := AChart;
end;

function TS4YChartColumnManager.AddColumn(AColumn: TBaseLinkGridToDataSourceColumn): Integer;
var
  LDescription: TCreateColumnDescription;
begin
  LDescription := TCreateColumnDescription.Create(AColumn as TLinkGridToDataSourceColumn);
  Result := FBinding.BindingAddLinkColumn(LDescription.Header);
end;

function TS4YChartColumnManager.AddColumn(ADataSource: TBaseLinkingBindSource; const AMemberName: string): Integer;
var
  LDescription: TCreateColumnDescription;
begin
  LDescription := TCreateColumnDescription.Create(ADataSource, AMemberName);
  Result := FBinding.BindingAddLinkColumn(LDescription.Header);
end;

procedure TS4YChartColumnManager.BeginUpdate;
begin
  // The chart is redrawn once, at the end of the fill of the rows.
end;

function TS4YChartColumnManager.CanAddColumn(AColumn: TBaseLinkGridToDataSourceColumn): Boolean;
begin
  Result := True;
end;

function TS4YChartColumnManager.CanAddColumn(ADataSource: TBaseLinkingBindSource;
  const AMemberName: string): Boolean;
begin
  Result := True;
end;

procedure TS4YChartColumnManager.ClearColumns;
begin
  FBinding.BindingClearLinkColumns;
end;

function TS4YChartColumnManager.Describe(const AIndex: Integer;
  const ADescription: TCreateColumnDescription): TLinkGridColumnDescription;
var
  LControlExpression: string;
  LFormatExpressions: TArray<TLinkGridColumnExpressionPair>;
begin
  // The first column gives the captions of the rows, the next ones the values of the columns 0, 1 and so on.
  if AIndex = 0 then
    LControlExpression := C_CAPTION_EXPRESSION
  else
    LControlExpression := Format(C_VALUES_EXPRESSION, [AIndex - 1]);

  LFormatExpressions := [TLinkGridColumnExpressionPair.Create(LControlExpression, ADescription.MemberGetter, False)];
  Result := TLinkGridColumnDescription.Create(nil, '', AIndex, '', ADescription.MemberName, '', [],
    LFormatExpressions, []);
end;

function TS4YChartColumnManager.DescribeColumn(AIndex: Integer;
  AColumn: TBaseLinkGridToDataSourceColumn): TLinkGridColumnDescription;
begin
  Result := Describe(AIndex, TCreateColumnDescription.Create(AColumn as TLinkGridToDataSourceColumn));
end;

function TS4YChartColumnManager.DescribeColumn(AIndex: Integer; ADataSource: TBaseLinkingBindSource;
  const AMemberName: string): TLinkGridColumnDescription;
begin
  Result := Describe(AIndex, TCreateColumnDescription.Create(ADataSource, AMemberName));
end;

procedure TS4YChartColumnManager.EndUpdate;
begin
  // See BeginUpdate.
end;

function TS4YChartColumnManager.GetDefaultColumnWidth: Integer;
begin
  Result := C_DEFAULT_COLUMN_WIDTH;
end;

procedure TS4YChartColumnManager.SetDefaultColumnWidth(AWidth: Integer);
begin
  // A chart has no columns to size.
end;

procedure TS4YChartColumnManager.UpdateColumn(AIndex: Integer; AColumn: TBaseLinkGridToDataSourceColumn);
var
  LDescription: TCreateColumnDescription;
begin
  LDescription := TCreateColumnDescription.Create(AColumn as TLinkGridToDataSourceColumn);
  FBinding.BindingUpdateLinkColumn(AIndex, LDescription.Header);
end;

procedure TS4YChartColumnManager.UpdateColumn(AIndex: Integer; ADataSource: TBaseLinkingBindSource;
  const AMemberName: string);
var
  LDescription: TCreateColumnDescription;
begin
  LDescription := TCreateColumnDescription.Create(ADataSource, AMemberName);
  FBinding.BindingUpdateLinkColumn(AIndex, LDescription.Header);
end;

{ TS4YChartColumnFactory }

function TS4YChartColumnFactory.CreateFactory(AIntf: TGuid; AGrid: TComponent): IInterface;
begin
  Result := TS4YChartColumnManager.Create(AGrid as TS4YCustomChart);
end;

function TS4YChartColumnFactory.GridClasses: TArray<TComponentClass>;
begin
  Result := GChartClasses.ToArray;
end;

function TS4YChartColumnFactory.Supports(AIntf: TGuid; AGrid: TComponent): Boolean;
begin
  Result := (AIntf = ILinkGridToDataSourceControlManager) and (AGrid is TS4YCustomChart);
end;

function TS4YChartColumnFactory.UsesUnits: TArray<string>;
begin
  // Added by the IDE to the form that links a chart: it registers the support of the charts.
  Result := [C_UNIT_NAME];
end;

initialization
  GChartClasses := TList<TComponentClass>.Create;
  RegisterBindEditorFactory([TS4YChartEditorFactory]);
  RegisterLinkGridToDataSourceColumnFactory([TS4YChartColumnFactory]);

finalization
  UnregisterLinkGridToDataSourceColumnFactory([TS4YChartColumnFactory]);
  UnregisterBindEditorFactory([TS4YChartEditorFactory]);
  FreeAndNil(GChartClasses);

end.
