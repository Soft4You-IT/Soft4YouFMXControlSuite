unit Soft4You.FMX.Controls.Gauges.Scales;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YLinearMeter, TS4YCircularMeter - graduation, ranges, needle and pointer of the meters
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.UITypes,
  Soft4You.FMX.Controls.Gauges.Types;

type
  /// <summary>
  /// The graduation of a meter: major ticks with their numbers and minor ticks between them, along the track.
  /// </summary>
  /// <remarks>
  /// The descendants add the side of the track where the graduation is drawn.
  /// </remarks>
  TS4YMeterGraduation = class(TPersistent)
  public const
    /// <summary>Default value of LabelFormat: the value without decimals.</summary>
    C_DEFAULT_LABEL_FORMAT = '%.0f';
    /// <summary>Default value of MajorStep: automatic.</summary>
    C_DEFAULT_MAJOR_STEP: Single = 0;
    /// <summary>Default value of MajorTickLength, in pixels.</summary>
    C_DEFAULT_MAJOR_TICK_LENGTH: Single = 8;
    /// <summary>Default value of MinorCount.</summary>
    C_DEFAULT_MINOR_COUNT = 4;
    /// <summary>Default value of MinorTickLength, in pixels.</summary>
    C_DEFAULT_MINOR_TICK_LENGTH: Single = 4;
    /// <summary>Default value of ShowLabels.</summary>
    C_DEFAULT_SHOW_LABELS = True;
    /// <summary>Default value of Visible.</summary>
    C_DEFAULT_VISIBLE = True;
  private
    FLabelFormat: string;
    FMajorStep: Single;
    FMajorTickLength: Single;
    FMinorCount: Integer;
    FMinorTickLength: Single;
    FShowLabels: Boolean;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    function LabelFormatStored: Boolean;
    function MajorStepStored: Boolean;
    function MajorTickLengthStored: Boolean;
    function MinorTickLengthStored: Boolean;
    procedure SetLabelFormat(const Value: string);
    procedure SetMajorStep(const Value: Single);
    procedure SetMajorTickLength(const Value: Single);
    procedure SetMinorCount(const Value: Integer);
    procedure SetMinorTickLength(const Value: Single);
    procedure SetShowLabels(const Value: Boolean);
    procedure SetVisible(const Value: Boolean);
  protected
    /// <summary>Fires OnChange.</summary>
    procedure DoChange;
  public
    /// <summary>Creates a visible graduation with an automatic step.</summary>
    constructor Create; virtual;

    /// <summary>Copies the settings from another graduation.</summary>
    procedure Assign(Source: TPersistent); override;
    /// <summary>Returns the step between the major ticks for the range from AMin to AMax: MajorStep, or with MajorStep = 0 a step of 1, 2, 2.5 or 5 times a power of 10, for about five steps.</summary>
    function CalculateMajorStep(const AMin, AMax: Single): Single;
    /// <summary>Returns the text of the label of AValue, formatted with LabelFormat; a format that does not fit a floating point value is replaced by the default.</summary>
    function FormatLabel(const AValue: Single): string;
    /// <summary>Returns the values of the major ticks from AMin to AMax.</summary>
    function GetMajorValues(const AMin, AMax: Single): TArray<Single>;
    /// <summary>Returns the values of the minor ticks from AMin to AMax, without the ones of the major ticks.</summary>
    function GetMinorValues(const AMin, AMax: Single): TArray<Single>;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Format of the numbers of the major ticks, as for the Format function of Delphi with the value as its only argument. The default is %.0f.</summary>
    property LabelFormat: string read FLabelFormat write SetLabelFormat stored LabelFormatStored;
    /// <summary>Step between the major ticks, in the units of the value. With 0, the default, the step is chosen from the range: 1, 2, 2.5 or 5 times a power of 10, for about five steps.</summary>
    property MajorStep: Single read FMajorStep write SetMajorStep stored MajorStepStored nodefault;
    /// <summary>Length of the major ticks, in pixels. The default is 8.</summary>
    property MajorTickLength: Single read FMajorTickLength write SetMajorTickLength stored MajorTickLengthStored nodefault;
    /// <summary>Number of the minor ticks between two major ticks. The default is 4; 0 draws only the major ticks.</summary>
    property MinorCount: Integer read FMinorCount write SetMinorCount default C_DEFAULT_MINOR_COUNT;
    /// <summary>Length of the minor ticks, in pixels. The default is 4.</summary>
    property MinorTickLength: Single read FMinorTickLength write SetMinorTickLength stored MinorTickLengthStored nodefault;
    /// <summary>True writes the number of each major tick. The default is True.</summary>
    property ShowLabels: Boolean read FShowLabels write SetShowLabels default C_DEFAULT_SHOW_LABELS;
    /// <summary>True draws the graduation. The default is True.</summary>
    property Visible: Boolean read FVisible write SetVisible default C_DEFAULT_VISIBLE;
  end;

  /// <summary>
  /// The graduation of a TS4YCircularMeter, inside or outside the arc.
  /// </summary>
  TS4YCircularMeterGraduation = class(TS4YMeterGraduation)
  public const
    /// <summary>Default value of Position.</summary>
    C_DEFAULT_POSITION = gasInside;
  private
    FPosition: TS4YGaugeArcSide;
    procedure SetPosition(const Value: TS4YGaugeArcSide);
  public
    /// <summary>Creates a visible graduation inside the arc.</summary>
    constructor Create; override;

    /// <summary>Copies the settings from another graduation.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>Side of the arc where the graduation is drawn: inside (the default), towards the center, or outside. Outside, the arc becomes smaller to leave room for it.</summary>
    property Position: TS4YGaugeArcSide read FPosition write SetPosition default C_DEFAULT_POSITION;
  end;

  /// <summary>
  /// The graduation of a TS4YLinearMeter, on one side of the bar.
  /// </summary>
  TS4YLinearMeterGraduation = class(TS4YMeterGraduation)
  public const
    /// <summary>Default value of Position.</summary>
    C_DEFAULT_POSITION = gbsAfter;
  private
    FPosition: TS4YGaugeBarSide;
    procedure SetPosition(const Value: TS4YGaugeBarSide);
  public
    /// <summary>Creates a visible graduation after the bar.</summary>
    constructor Create; override;

    /// <summary>Copies the settings from another graduation.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>Side of the bar where the graduation is drawn: gbsBefore, above a horizontal bar or on the left of a vertical one, or gbsAfter (the default), below or on the right.</summary>
    property Position: TS4YGaugeBarSide read FPosition write SetPosition default C_DEFAULT_POSITION;
  end;

  /// <summary>
  /// The needle of a TS4YCircularMeter: a line from the center of the arc towards the value.
  /// </summary>
  TS4YCircularMeterNeedle = class(TPersistent)
  public const
    /// <summary>Default value of Length, in percent.</summary>
    C_DEFAULT_LENGTH: Single = 90;
    /// <summary>Default value of Visible.</summary>
    C_DEFAULT_VISIBLE = True;
  private
    FLength: Single;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    function LengthStored: Boolean;
    procedure SetLength(const Value: Single);
    procedure SetVisible(const Value: Boolean);
  public
    /// <summary>Creates a visible needle 90 percent long.</summary>
    constructor Create;

    /// <summary>Copies the settings from another needle.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Length of the needle, in percent of the distance from the center to the inner edge of the track, from 0 to 100. The default is 90.</summary>
    property Length: Single read FLength write SetLength stored LengthStored nodefault;
    /// <summary>True draws the needle. The default is True.</summary>
    property Visible: Boolean read FVisible write SetVisible default C_DEFAULT_VISIBLE;
  end;

  /// <summary>
  /// The pointer of a TS4YLinearMeter: a small triangle beside the bar that points at the value.
  /// </summary>
  TS4YLinearMeterPointer = class(TPersistent)
  public const
    /// <summary>Default value of Position.</summary>
    C_DEFAULT_POSITION = gbsBefore;
    /// <summary>Default value of Visible.</summary>
    C_DEFAULT_VISIBLE = False;
  private
    FPosition: TS4YGaugeBarSide;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetPosition(const Value: TS4YGaugeBarSide);
    procedure SetVisible(const Value: Boolean);
  public
    /// <summary>Creates a hidden pointer before the bar.</summary>
    constructor Create;

    /// <summary>Copies the settings from another pointer.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Side of the bar where the pointer is drawn: gbsBefore (the default), above a horizontal bar or on the left of a vertical one, or gbsAfter, below or on the right.</summary>
    property Position: TS4YGaugeBarSide read FPosition write SetPosition default C_DEFAULT_POSITION;
    /// <summary>True draws the pointer. The default is False.</summary>
    property Visible: Boolean read FVisible write SetVisible default C_DEFAULT_VISIBLE;
  end;

  /// <summary>
  /// A range of values of a meter with a color of its own, for example the red zone of a speedometer.
  /// </summary>
  TS4YMeterRange = class(TCollectionItem)
  public const
    /// <summary>Default value of Color.</summary>
    C_DEFAULT_COLOR: TAlphaColor = $FF9E9E9E;
  private
    FColor: TAlphaColor;
    FEndValue: Single;
    FStartValue: Single;
    procedure SetColor(const Value: TAlphaColor);
    procedure SetEndValue(const Value: Single);
    procedure SetStartValue(const Value: Single);
  protected
    /// <summary>Returns the values of the range, for the editor of the collection.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates a gray range from 0 to 0.</summary>
    constructor Create(Collection: TCollection); override;

    /// <summary>Copies the settings from another range.</summary>
    procedure Assign(Source: TPersistent); override;
    /// <summary>Returns True when AValue is in the range, ends included; StartValue and EndValue can be in any order.</summary>
    function Contains(const AValue: Single): Boolean;
    /// <summary>Returns the higher of StartValue and EndValue.</summary>
    function HighValue: Single;
    /// <summary>Returns the lower of StartValue and EndValue.</summary>
    function LowValue: Single;
  published
    /// <summary>Color of the range.</summary>
    property Color: TAlphaColor read FColor write SetColor nodefault;
    /// <summary>Value where the range ends.</summary>
    property EndValue: Single read FEndValue write SetEndValue;
    /// <summary>Value where the range starts.</summary>
    property StartValue: Single read FStartValue write SetStartValue;
  end;

  /// <summary>
  /// The ranges of a meter. A range drawn later covers the ones before it where they overlap.
  /// </summary>
  TS4YMeterRanges = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    function GetItem(const AIndex: Integer): TS4YMeterRange;
    procedure SetItem(const AIndex: Integer; const Value: TS4YMeterRange);
  protected
    /// <summary>Fires OnChange.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the collection of the ranges of AOwner.</summary>
    constructor Create(const AOwner: TPersistent);

    /// <summary>Adds a range from AStartValue to AEndValue with AColor.</summary>
    function Add(const AStartValue, AEndValue: Single; const AColor: TAlphaColor): TS4YMeterRange; overload;
    /// <summary>Returns the range that contains AValue, the last one when they overlap, or nil.</summary>
    function FindRange(const AValue: Single): TS4YMeterRange;

    /// <summary>The ranges, by position.</summary>
    property Items[const AIndex: Integer]: TS4YMeterRange read GetItem write SetItem; default;

    /// <summary>Fires when a range is added, removed or changed.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

const
  // Number of steps the automatic step aims at, and the steps, as fractions of a power of 10.
  C_TARGET_STEPS = 5;
  C_NICE_STEPS: array[0..4] of Single = (1, 2, 2.5, 5, 10);
  // Tolerance on the positions of the ticks, against the rounding of floating point numbers.
  C_EPSILON = 1E-4;
  // Largest number of ticks drawn, against a step too small for the range.
  C_MAX_TICKS = 1000;

{ TS4YMeterGraduation }

constructor TS4YMeterGraduation.Create;
begin
  inherited Create;

  FLabelFormat := C_DEFAULT_LABEL_FORMAT;
  FMajorStep := C_DEFAULT_MAJOR_STEP;
  FMajorTickLength := C_DEFAULT_MAJOR_TICK_LENGTH;
  FMinorCount := C_DEFAULT_MINOR_COUNT;
  FMinorTickLength := C_DEFAULT_MINOR_TICK_LENGTH;
  FShowLabels := C_DEFAULT_SHOW_LABELS;
  FVisible := C_DEFAULT_VISIBLE;
end;

procedure TS4YMeterGraduation.Assign(Source: TPersistent);
var
  LSource: TS4YMeterGraduation;
begin
  if Source is TS4YMeterGraduation then
  begin
    LSource := TS4YMeterGraduation(Source);
    FLabelFormat := LSource.LabelFormat;
    FMajorStep := LSource.MajorStep;
    FMajorTickLength := LSource.MajorTickLength;
    FMinorCount := LSource.MinorCount;
    FMinorTickLength := LSource.MinorTickLength;
    FShowLabels := LSource.ShowLabels;
    FVisible := LSource.Visible;
    DoChange;
  end
  else
    inherited;
end;

function TS4YMeterGraduation.CalculateMajorStep(const AMin, AMax: Single): Single;
var
  LMagnitude: Single;
  LNiceIndex: Integer;
  LRange: Single;
  LRawStep: Single;
begin
  LRange := AMax - AMin;

  if LRange <= 0 then
    Exit(1);

  // A step too small would draw more ticks than the gauge can show: it is made larger.
  if FMajorStep > 0 then
    Exit(Max(FMajorStep, LRange / C_MAX_TICKS));

  LRawStep := LRange / C_TARGET_STEPS;
  LMagnitude := Power(10, Floor(Log10(LRawStep)));
  LNiceIndex := 0;

  while (LNiceIndex < High(C_NICE_STEPS)) and (C_NICE_STEPS[LNiceIndex] * LMagnitude < LRawStep - C_EPSILON) do
    Inc(LNiceIndex);

  Result := C_NICE_STEPS[LNiceIndex] * LMagnitude;
end;

procedure TS4YMeterGraduation.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TS4YMeterGraduation.FormatLabel(const AValue: Single): string;
begin
  try
    Result := Format(FLabelFormat, [AValue]);
  except
    on EConvertError do
      Result := Format(C_DEFAULT_LABEL_FORMAT, [AValue]);
  end;
end;

function TS4YMeterGraduation.GetMajorValues(const AMin, AMax: Single): TArray<Single>;
var
  LStep: Single;
  LIndex: Integer;
  LLast: Integer;
begin
  Result := nil;
  LStep := CalculateMajorStep(AMin, AMax);
  LIndex := Ceil(AMin / LStep - C_EPSILON);
  LLast := Floor(AMax / LStep + C_EPSILON);

  while LIndex <= LLast do
  begin
    Result := Result + [LIndex * LStep];
    Inc(LIndex);
  end;
end;

function TS4YMeterGraduation.GetMinorValues(const AMin, AMax: Single): TArray<Single>;
var
  LIndex: Integer;
  LLast: Integer;
  LMinorStep: Single;
begin
  Result := nil;

  if FMinorCount <= 0 then
    Exit;

  LMinorStep := CalculateMajorStep(AMin, AMax) / (FMinorCount + 1);

  if (AMax - AMin) / LMinorStep > C_MAX_TICKS then
    Exit;

  LIndex := Ceil(AMin / LMinorStep - C_EPSILON);
  LLast := Floor(AMax / LMinorStep + C_EPSILON);

  // Every (MinorCount + 1)-th minor tick falls on a major tick, which is drawn instead.
  while LIndex <= LLast do
  begin
    if LIndex mod (FMinorCount + 1) <> 0 then
      Result := Result + [LIndex * LMinorStep];

    Inc(LIndex);
  end;
end;

function TS4YMeterGraduation.LabelFormatStored: Boolean;
begin
  Result := FLabelFormat <> C_DEFAULT_LABEL_FORMAT;
end;

function TS4YMeterGraduation.MajorStepStored: Boolean;
begin
  // Compared exactly: SameValue would take a very small step for 0.
  Result := FMajorStep <> C_DEFAULT_MAJOR_STEP;
end;

function TS4YMeterGraduation.MajorTickLengthStored: Boolean;
begin
  Result := not SameValue(FMajorTickLength, C_DEFAULT_MAJOR_TICK_LENGTH);
end;

function TS4YMeterGraduation.MinorTickLengthStored: Boolean;
begin
  Result := not SameValue(FMinorTickLength, C_DEFAULT_MINOR_TICK_LENGTH);
end;

procedure TS4YMeterGraduation.SetLabelFormat(const Value: string);
begin
  if FLabelFormat = Value then
    Exit;

  FLabelFormat := Value;
  DoChange;
end;

procedure TS4YMeterGraduation.SetMajorStep(const Value: Single);
begin
  // Compared exactly: SameValue would take a very small step for 0.
  if FMajorStep = Value then
    Exit;

  FMajorStep := Max(0, Value);
  DoChange;
end;

procedure TS4YMeterGraduation.SetMajorTickLength(const Value: Single);
begin
  if SameValue(FMajorTickLength, Value) then
    Exit;

  FMajorTickLength := Max(0, Value);
  DoChange;
end;

procedure TS4YMeterGraduation.SetMinorCount(const Value: Integer);
begin
  if FMinorCount = Value then
    Exit;

  FMinorCount := Max(0, Value);
  DoChange;
end;

procedure TS4YMeterGraduation.SetMinorTickLength(const Value: Single);
begin
  if SameValue(FMinorTickLength, Value) then
    Exit;

  FMinorTickLength := Max(0, Value);
  DoChange;
end;

procedure TS4YMeterGraduation.SetShowLabels(const Value: Boolean);
begin
  if FShowLabels = Value then
    Exit;

  FShowLabels := Value;
  DoChange;
end;

procedure TS4YMeterGraduation.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;
  DoChange;
end;

{ TS4YCircularMeterGraduation }

constructor TS4YCircularMeterGraduation.Create;
begin
  inherited;

  FPosition := C_DEFAULT_POSITION;
end;

procedure TS4YCircularMeterGraduation.Assign(Source: TPersistent);
begin
  if Source is TS4YCircularMeterGraduation then
    FPosition := TS4YCircularMeterGraduation(Source).Position;

  inherited;
end;

procedure TS4YCircularMeterGraduation.SetPosition(const Value: TS4YGaugeArcSide);
begin
  if FPosition = Value then
    Exit;

  FPosition := Value;
  DoChange;
end;

{ TS4YLinearMeterGraduation }

constructor TS4YLinearMeterGraduation.Create;
begin
  inherited;

  FPosition := C_DEFAULT_POSITION;
end;

procedure TS4YLinearMeterGraduation.Assign(Source: TPersistent);
begin
  if Source is TS4YLinearMeterGraduation then
    FPosition := TS4YLinearMeterGraduation(Source).Position;

  inherited;
end;

procedure TS4YLinearMeterGraduation.SetPosition(const Value: TS4YGaugeBarSide);
begin
  if FPosition = Value then
    Exit;

  FPosition := Value;
  DoChange;
end;

{ TS4YCircularMeterNeedle }

constructor TS4YCircularMeterNeedle.Create;
begin
  inherited Create;

  FLength := C_DEFAULT_LENGTH;
  FVisible := C_DEFAULT_VISIBLE;
end;

procedure TS4YCircularMeterNeedle.Assign(Source: TPersistent);
var
  LSource: TS4YCircularMeterNeedle;
begin
  if not (Source is TS4YCircularMeterNeedle) then
  begin
    inherited;
    Exit;
  end;

  LSource := TS4YCircularMeterNeedle(Source);
  FLength := LSource.Length;
  FVisible := LSource.Visible;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TS4YCircularMeterNeedle.LengthStored: Boolean;
begin
  Result := not SameValue(FLength, C_DEFAULT_LENGTH);
end;

procedure TS4YCircularMeterNeedle.SetLength(const Value: Single);
begin
  if SameValue(FLength, Value) then
    Exit;

  FLength := EnsureRange(Value, 0, 100);

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YCircularMeterNeedle.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TS4YLinearMeterPointer }

constructor TS4YLinearMeterPointer.Create;
begin
  inherited Create;

  FPosition := C_DEFAULT_POSITION;
  FVisible := C_DEFAULT_VISIBLE;
end;

procedure TS4YLinearMeterPointer.Assign(Source: TPersistent);
var
  LSource: TS4YLinearMeterPointer;
begin
  if not (Source is TS4YLinearMeterPointer) then
  begin
    inherited;
    Exit;
  end;

  LSource := TS4YLinearMeterPointer(Source);
  FPosition := LSource.Position;
  FVisible := LSource.Visible;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YLinearMeterPointer.SetPosition(const Value: TS4YGaugeBarSide);
begin
  if FPosition = Value then
    Exit;

  FPosition := Value;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YLinearMeterPointer.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TS4YMeterRange }

constructor TS4YMeterRange.Create(Collection: TCollection);
begin
  inherited;

  FColor := C_DEFAULT_COLOR;
end;

procedure TS4YMeterRange.Assign(Source: TPersistent);
var
  LSource: TS4YMeterRange;
begin
  if Source is TS4YMeterRange then
  begin
    LSource := TS4YMeterRange(Source);
    FColor := LSource.Color;
    FEndValue := LSource.EndValue;
    FStartValue := LSource.StartValue;
    Changed(False);
  end
  else
    inherited;
end;

function TS4YMeterRange.Contains(const AValue: Single): Boolean;
begin
  Result := (AValue >= LowValue) and (AValue <= HighValue);
end;

function TS4YMeterRange.GetDisplayName: string;
begin
  Result := FormatFloat('0.##', FStartValue) + ' - ' + FormatFloat('0.##', FEndValue);
end;

function TS4YMeterRange.HighValue: Single;
begin
  Result := Max(FStartValue, FEndValue);
end;

function TS4YMeterRange.LowValue: Single;
begin
  Result := Min(FStartValue, FEndValue);
end;

procedure TS4YMeterRange.SetColor(const Value: TAlphaColor);
begin
  if FColor = Value then
    Exit;

  FColor := Value;
  Changed(False);
end;

procedure TS4YMeterRange.SetEndValue(const Value: Single);
begin
  if FEndValue = Value then
    Exit;

  FEndValue := Value;
  Changed(False);
end;

procedure TS4YMeterRange.SetStartValue(const Value: Single);
begin
  if FStartValue = Value then
    Exit;

  FStartValue := Value;
  Changed(False);
end;

{ TS4YMeterRanges }

constructor TS4YMeterRanges.Create(const AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YMeterRange);
end;

function TS4YMeterRanges.Add(const AStartValue, AEndValue: Single; const AColor: TAlphaColor): TS4YMeterRange;
begin
  BeginUpdate;
  try
    Result := TS4YMeterRange(inherited Add);
    Result.StartValue := AStartValue;
    Result.EndValue := AEndValue;
    Result.Color := AColor;
  finally
    EndUpdate;
  end;
end;

function TS4YMeterRanges.FindRange(const AValue: Single): TS4YMeterRange;
var
  LIndex: Integer;
begin
  // From the last one: where the ranges overlap, the last one is the one drawn on top.
  Result := nil;
  LIndex := Count - 1;

  while not Assigned(Result) and (LIndex >= 0) do
  begin
    if Items[LIndex].Contains(AValue) then
      Result := Items[LIndex];

    Dec(LIndex);
  end;
end;

function TS4YMeterRanges.GetItem(const AIndex: Integer): TS4YMeterRange;
begin
  Result := TS4YMeterRange(inherited Items[AIndex]);
end;

procedure TS4YMeterRanges.SetItem(const AIndex: Integer; const Value: TS4YMeterRange);
begin
  inherited Items[AIndex] := Value;
end;

procedure TS4YMeterRanges.Update(Item: TCollectionItem);
begin
  inherited;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

end.
