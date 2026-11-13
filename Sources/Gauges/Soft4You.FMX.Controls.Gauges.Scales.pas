unit Soft4You.FMX.Controls.Gauges.Scales;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YLinearMeter, TS4YCircularMeter - graduation of the meters
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
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

end.
