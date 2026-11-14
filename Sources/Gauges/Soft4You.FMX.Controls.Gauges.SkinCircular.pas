unit Soft4You.FMX.Controls.Gauges.SkinCircular;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YSkinCircularGauge - circular gauge whose look is made of the parts of its style
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Types,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  Soft4You.FMX.Controls.Gauges;

type
  /// <summary>
  /// A needle of a skin gauge with a value of its own, for example the hands of a clock or the needle of a small dial inside the main one.
  /// </summary>
  /// <remarks>
  /// The needle is the part of the style named PartName, drawn pointing up like the main needle; it moves at once to its value, without animation.
  /// </remarks>
  TS4YSkinGaugeNeedle = class(TCollectionItem)
  public const
    /// <summary>Default value of Max.</summary>
    C_DEFAULT_MAX: Single = 100;
  private
    FMax: Single;
    FMin: Single;
    FPart: TControl;
    FPartName: string;
    FPartRotation: IRotatedControl;
    FPartStyleAngle: Single;
    FPartStyleCenter: TPointF;
    FScale: TArc;
    FScalePart: string;
    FValue: Single;
    FWrap: Boolean;
    procedure DetachPart;
    function GetFraction: Single;
    function MaxStored: Boolean;
    procedure ReleasePart;
    procedure SetMax(const Value: Single);
    procedure SetMin(const Value: Single);
    procedure SetPartName(const Value: string);
    procedure SetScalePart(const Value: string);
    procedure SetValue(const Value: Single);
    procedure SetWrap(const Value: Boolean);
  protected
    /// <summary>Returns PartName, for the editor of the collection.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates a needle from 0 to 100.</summary>
    constructor Create(Collection: TCollection); override;
    /// <summary>Turns the part of the style back to its angle and center of rotation of the style.</summary>
    destructor Destroy; override;

    /// <summary>Copies the settings from another needle.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>Value of the needle at the end of its scale. The default is 100.</summary>
    property Max: Single read FMax write SetMax stored MaxStored nodefault;
    /// <summary>Value of the needle at the start of its scale. The default is 0.</summary>
    property Min: Single read FMin write SetMin;
    /// <summary>
    /// Name (StyleName) of the part of the style that is the needle, for example needleminutes.
    /// </summary>
    /// <remarks>
    /// It must be another part than needle, which shows the Value of the gauge.
    /// </remarks>
    property PartName: string read FPartName write SetPartName;
    /// <summary>
    /// Name (StyleName) of the TArc of the style that gives the angles and the center of rotation of the needle, for example the scale of a small dial.
    /// </summary>
    /// <remarks>
    /// Empty, or when the style has no part with this name, the needle uses the scale of the gauge; without scale, it turns around its own RotationCenter with the angles of the gauge.
    /// </remarks>
    property ScalePart: string read FScalePart write SetScalePart;
    /// <summary>Value shown by the needle.</summary>
    property Value: Single read FValue write SetValue;
    /// <summary>
    /// True makes the value go round the scale: a value past Max starts again from Min, and Max is at the same angle as Min, as the hours of a clock. The default is False: the needle stops at Min and Max.
    /// </summary>
    property Wrap: Boolean read FWrap write SetWrap default False;
  end;

  /// <summary>
  /// The needles of a skin gauge with a value of their own.
  /// </summary>
  TS4YSkinGaugeNeedles = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    function GetItem(const AIndex: Integer): TS4YSkinGaugeNeedle;
    procedure SetItem(const AIndex: Integer; const Value: TS4YSkinGaugeNeedle);
  protected
    /// <summary>Fires OnChange.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the collection of the needles of AOwner.</summary>
    constructor Create(const AOwner: TPersistent);

    /// <summary>The needles, by position.</summary>
    property Items[const AIndex: Integer]: TS4YSkinGaugeNeedle read GetItem write SetItem; default;

    /// <summary>Fires when a needle is added, removed or changed.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  /// <summary>
  /// A circular gauge whose look is made only of the parts of its style, such as a dial and a needle drawn as images or shapes: the gauge turns the needle to the value and writes the value and the caption.
  /// </summary>
  /// <remarks>
  /// The style is S4YSkinCircularGaugeStyle. Its parts are shown as they are, with their own size and position; the gauge changes only these:
  /// needle, any object drawn pointing up, which turns around its center of rotation to the angle of the value;
  /// scale, an optional TArc, usually hidden, which gives the angles of the needle (StartAngle and EndAngle of the arc, a negative EndAngle turning counterclockwise) and, with its center, the center of rotation of the needle;
  /// valuetext and captiontext, TText objects that receive the value and the caption, and are hidden when they are empty;
  /// the parts named in Needles, other needles with values of their own.
  /// Without scale, the needle turns around its own RotationCenter, with the angles StartAngle, SweepAngle and Reversed of the gauge. The RotationAngle of the needle in the style is added to its angle, to correct an image that does not point exactly up.
  /// The default style puts its parts in a TScaledLayout aligned with Fit, so that the whole dial is resized with the gauge and stays round.
  /// </remarks>
  TS4YSkinCircularGauge = class(TS4YCustomGauge)
  public const
    /// <summary>Default value of StartAngle, in degrees: the bottom left.</summary>
    C_DEFAULT_START_ANGLE: Single = -135;
    /// <summary>Default value of SweepAngle, in degrees: an arc open at the bottom.</summary>
    C_DEFAULT_SWEEP_ANGLE: Single = 270;
    /// <summary>Largest value of SweepAngle, in degrees.</summary>
    C_MAX_SWEEP_ANGLE: Single = 360;
  private
    FNeedle: TControl;
    FNeedleRotation: IRotatedControl;
    FNeedles: TS4YSkinGaugeNeedles;
    FNeedleStyleAngle: Single;
    FNeedleStyleCenter: TPointF;
    FReversed: Boolean;
    FScale: TArc;
    FStartAngle: Single;
    FSweepAngle: Single;
    procedure BindNeedles;
    procedure DetachNeedles;
    function GetPartAngle(const AScale: TArc; const AFraction: Single): Single;
    procedure NeedlesChanged(Sender: TObject);
    function NeedlesStored: Boolean;
    procedure SetNeedles(const Value: TS4YSkinGaugeNeedles);
    procedure SetReversed(const Value: Boolean);
    procedure SetStartAngle(const Value: Single);
    procedure SetSweepAngle(const Value: Single);
    function StartAngleStored: Boolean;
    function SweepAngleStored: Boolean;
    procedure UpdateNeedles;
    procedure UpdatePart(const APart: TControl; const ARotation: IRotatedControl; const AStyleAngle: Single;
      const AStyleCenter: TPointF; const AScale: TArc; const AFraction: Single);
    procedure UpdatePartCenter(const APart: TControl; const ARotation: IRotatedControl; const AScale: TArc);
    procedure UpdateText(const AText: TText; const AValue: string);
  protected
    /// <summary>Finds the needles and the scale of the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Turns the needle to the value drawn and writes the value and the caption in the texts of the style.</summary>
    procedure DisplayChanged; override;
    /// <summary>Places the centers of rotation of the needles again, after the parts of the style have been resized.</summary>
    procedure DoRealign; override;
    /// <summary>Draws nothing: the parts of the style are painted as children of the gauge.</summary>
    procedure DrawGauge; override;
    /// <summary>Releases the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control: 160 x 160.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns 0: the gauge has no track of its own.</summary>
    function GetDefaultThickness: Single; override;
  public
    /// <summary>Creates the gauge with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Destroys the gauge and its needles.</summary>
    destructor Destroy; override;
  published
    property Align;
    property Anchors;
    property AnimationDuration;
    property Caption;
    property Cursor;
    property Enabled;
    property Height;
    property HitTest;
    property Margins;
    property Max;
    property Min;
    /// <summary>
    /// Other needles of the style, each with a value of its own, for example the hands of a clock or the needle of a small dial. Empty by default.
    /// </summary>
    /// <remarks>
    /// The part needle always shows Value, with the animation; the needles of the collection move at once to their values.
    /// </remarks>
    property Needles: TS4YSkinGaugeNeedles read FNeedles write SetNeedles stored NeedlesStored;
    property Opacity;
    property Padding;
    property PopupMenu;
    property Position;
    /// <summary>
    /// True makes the needle turn counterclockwise from StartAngle as the value grows. The default is False: clockwise.
    /// </summary>
    /// <remarks>
    /// Used only when the style has no scale part: the scale gives the direction with the sign of its EndAngle.
    /// </remarks>
    property Reversed: Boolean read FReversed write SetReversed default False;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property ShowValue;
    property Size;
    /// <summary>
    /// Angle of the needle at Min, in degrees: 0 is the top of the dial, 90 its right side. The default is -135, the bottom left.
    /// </summary>
    /// <remarks>
    /// Used only when the style has no scale part: the scale gives the angle with its StartAngle.
    /// </remarks>
    property StartAngle: Single read FStartAngle write SetStartAngle stored StartAngleStored nodefault;
    property StyleLookup;
    /// <summary>
    /// Angle covered by the needle from Min to Max, in degrees from StartAngle, from 0 to 360: clockwise, or counterclockwise when Reversed is True. The default is 270.
    /// </summary>
    /// <remarks>
    /// Used only when the style has no scale part: the scale gives the angle with its EndAngle.
    /// </remarks>
    property SweepAngle: Single read FSweepAngle write SetSweepAngle stored SweepAngleStored nodefault;
    property Value;
    property ValueFormat;
    property Visible;
    property Width;

    property OnClick;
    property OnDblClick;
    property OnGetValueText;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  System.SysUtils,
  System.Math;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_NEEDLE = 'needle';
  C_STYLE_SCALE = 'scale';

  // Size of a new gauge.
  C_DEFAULT_SIZE = 160;
  // Angle of FMX for the top of the dial: FMX measures the angles from the right side.
  C_FMX_TOP_ANGLE = -90;

{ TS4YSkinGaugeNeedle }

constructor TS4YSkinGaugeNeedle.Create(Collection: TCollection);
begin
  inherited;

  FMax := C_DEFAULT_MAX;
end;

destructor TS4YSkinGaugeNeedle.Destroy;
begin
  ReleasePart;

  inherited;
end;

procedure TS4YSkinGaugeNeedle.Assign(Source: TPersistent);
var
  LSource: TS4YSkinGaugeNeedle;
begin
  if Source is TS4YSkinGaugeNeedle then
  begin
    LSource := TS4YSkinGaugeNeedle(Source);

    if FPartName <> LSource.PartName then
      ReleasePart;

    FMax := LSource.Max;
    FMin := LSource.Min;
    FPartName := LSource.PartName;
    FScalePart := LSource.ScalePart;
    FValue := LSource.Value;
    FWrap := LSource.Wrap;
    Changed(False);
  end
  else
    inherited;
end;

procedure TS4YSkinGaugeNeedle.DetachPart;
begin
  FPart := nil;
  FPartRotation := nil;
  FScale := nil;
end;

function TS4YSkinGaugeNeedle.GetDisplayName: string;
begin
  if FPartName <> '' then
    Result := FPartName
  else
    Result := inherited;
end;

function TS4YSkinGaugeNeedle.GetFraction: Single;
var
  LRange: Single;
begin
  // The position of the value from Min to Max, from 0 to 1.
  LRange := FMax - FMin;

  if LRange = 0 then
    Exit(0);

  Result := (FValue - FMin) / LRange;

  if FWrap then
    Result := Result - Floor(Result)
  else
    Result := EnsureRange(Result, 0, 1);
end;

function TS4YSkinGaugeNeedle.MaxStored: Boolean;
begin
  Result := FMax <> C_DEFAULT_MAX;
end;

procedure TS4YSkinGaugeNeedle.ReleasePart;
begin
  // The part is no longer a needle of the collection: it goes back as it is in the style.
  if Assigned(FPartRotation) then
  begin
    FPartRotation.RotationAngle := FPartStyleAngle;
    FPartRotation.RotationCenter.Point := FPartStyleCenter;
  end;

  DetachPart;
end;

procedure TS4YSkinGaugeNeedle.SetMax(const Value: Single);
begin
  if FMax = Value then
    Exit;

  FMax := Value;
  Changed(False);
end;

procedure TS4YSkinGaugeNeedle.SetMin(const Value: Single);
begin
  if FMin = Value then
    Exit;

  FMin := Value;
  Changed(False);
end;

procedure TS4YSkinGaugeNeedle.SetPartName(const Value: string);
begin
  if FPartName = Value then
    Exit;

  ReleasePart;
  FPartName := Value;
  Changed(False);
end;

procedure TS4YSkinGaugeNeedle.SetScalePart(const Value: string);
begin
  if FScalePart = Value then
    Exit;

  FScalePart := Value;
  Changed(False);
end;

procedure TS4YSkinGaugeNeedle.SetValue(const Value: Single);
begin
  if FValue = Value then
    Exit;

  FValue := Value;
  Changed(False);
end;

procedure TS4YSkinGaugeNeedle.SetWrap(const Value: Boolean);
begin
  if FWrap = Value then
    Exit;

  FWrap := Value;
  Changed(False);
end;

{ TS4YSkinGaugeNeedles }

constructor TS4YSkinGaugeNeedles.Create(const AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YSkinGaugeNeedle);
end;

function TS4YSkinGaugeNeedles.GetItem(const AIndex: Integer): TS4YSkinGaugeNeedle;
begin
  Result := TS4YSkinGaugeNeedle(inherited Items[AIndex]);
end;

procedure TS4YSkinGaugeNeedles.SetItem(const AIndex: Integer; const Value: TS4YSkinGaugeNeedle);
begin
  inherited Items[AIndex] := Value;
end;

procedure TS4YSkinGaugeNeedles.Update(Item: TCollectionItem);
begin
  inherited;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TS4YSkinCircularGauge }

constructor TS4YSkinCircularGauge.Create(AOwner: TComponent);
begin
  inherited;

  FStartAngle := C_DEFAULT_START_ANGLE;
  FSweepAngle := C_DEFAULT_SWEEP_ANGLE;
  FNeedles := TS4YSkinGaugeNeedles.Create(Self);
  FNeedles.OnChange := NeedlesChanged;
end;

destructor TS4YSkinCircularGauge.Destroy;
begin
  // The parts of the style are freed with the gauge: they are not turned back.
  FNeedles.OnChange := nil;
  DetachNeedles;
  FreeAndNil(FNeedles);

  inherited;
end;

procedure TS4YSkinCircularGauge.ApplyStyle;
begin
  // Found before the inherited method, which shows the value with them.
  FNeedle := nil;
  FNeedleRotation := nil;
  FScale := nil;

  // The angle and the center of rotation of a control are reached through IRotatedControl.
  if FindStyleResource<TControl>(C_STYLE_NEEDLE, FNeedle) and Supports(FNeedle, IRotatedControl, FNeedleRotation) then
  begin
    FNeedleStyleAngle := FNeedleRotation.RotationAngle;
    FNeedleStyleCenter := FNeedleRotation.RotationCenter.Point;
  end
  else
    FNeedle := nil;

  FindStyleResource<TArc>(C_STYLE_SCALE, FScale);
  BindNeedles;

  inherited;
end;

procedure TS4YSkinCircularGauge.BindNeedles;
var
  LNeedle: TS4YSkinGaugeNeedle;
begin
  for var I := 0 to FNeedles.Count - 1 do
  begin
    LNeedle := FNeedles[I];

    // A part already found keeps the angle and the center it had in the style.
    if not Assigned(LNeedle.FPart) and (LNeedle.PartName <> '') and
      FindStyleResource<TControl>(LNeedle.PartName, LNeedle.FPart) then
    begin
      if Supports(LNeedle.FPart, IRotatedControl, LNeedle.FPartRotation) then
      begin
        LNeedle.FPartStyleAngle := LNeedle.FPartRotation.RotationAngle;
        LNeedle.FPartStyleCenter := LNeedle.FPartRotation.RotationCenter.Point;
      end
      else
        LNeedle.FPart := nil;
    end;

    LNeedle.FScale := nil;

    if (LNeedle.ScalePart = '') or not FindStyleResource<TArc>(LNeedle.ScalePart, LNeedle.FScale) then
      LNeedle.FScale := FScale;
  end;
end;

procedure TS4YSkinCircularGauge.DetachNeedles;
begin
  if not Assigned(FNeedles) then
    Exit;

  for var I := 0 to FNeedles.Count - 1 do
    FNeedles[I].DetachPart;
end;

procedure TS4YSkinCircularGauge.DisplayChanged;
begin
  UpdateNeedles;
  UpdateText(StyleValueText, GetValueText);
  UpdateText(StyleCaptionText, Caption);
end;

procedure TS4YSkinCircularGauge.DoRealign;
begin
  inherited;

  UpdateNeedles;
end;

procedure TS4YSkinCircularGauge.DrawGauge;
begin
  // Nothing: the needles and the texts are parts of the style, painted as children of the gauge.
end;

procedure TS4YSkinCircularGauge.FreeStyle;
begin
  FNeedle := nil;
  FNeedleRotation := nil;
  FScale := nil;
  DetachNeedles;

  inherited;
end;

function TS4YSkinCircularGauge.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_SIZE, C_DEFAULT_SIZE);
end;

function TS4YSkinCircularGauge.GetDefaultThickness: Single;
begin
  Result := 0;
end;

function TS4YSkinCircularGauge.GetPartAngle(const AScale: TArc; const AFraction: Single): Single;
begin
  // The angle of FMX, from the right side and clockwise, of the fraction of the scale.
  if Assigned(AScale) then
    Exit(AScale.StartAngle + AScale.EndAngle * AFraction);

  if FReversed then
    Result := FStartAngle + C_FMX_TOP_ANGLE - FSweepAngle * AFraction
  else
    Result := FStartAngle + C_FMX_TOP_ANGLE + FSweepAngle * AFraction;
end;

procedure TS4YSkinCircularGauge.NeedlesChanged(Sender: TObject);
begin
  BindNeedles;
  UpdateNeedles;
end;

function TS4YSkinCircularGauge.NeedlesStored: Boolean;
begin
  // An empty collection is not written to the form.
  Result := FNeedles.Count > 0;
end;

procedure TS4YSkinCircularGauge.SetNeedles(const Value: TS4YSkinGaugeNeedles);
begin
  FNeedles.Assign(Value);
end;

procedure TS4YSkinCircularGauge.SetReversed(const Value: Boolean);
begin
  if FReversed = Value then
    Exit;

  FReversed := Value;
  UpdateNeedles;
end;

procedure TS4YSkinCircularGauge.SetStartAngle(const Value: Single);
begin
  if SameValue(FStartAngle, Value) then
    Exit;

  FStartAngle := Value;
  UpdateNeedles;
end;

procedure TS4YSkinCircularGauge.SetSweepAngle(const Value: Single);
var
  LSweepAngle: Single;
begin
  LSweepAngle := EnsureRange(Value, 0, C_MAX_SWEEP_ANGLE);

  if SameValue(FSweepAngle, LSweepAngle) then
    Exit;

  FSweepAngle := LSweepAngle;
  UpdateNeedles;
end;

function TS4YSkinCircularGauge.StartAngleStored: Boolean;
begin
  Result := not SameValue(FStartAngle, C_DEFAULT_START_ANGLE);
end;

function TS4YSkinCircularGauge.SweepAngleStored: Boolean;
begin
  Result := not SameValue(FSweepAngle, C_DEFAULT_SWEEP_ANGLE);
end;

procedure TS4YSkinCircularGauge.UpdateNeedles;
var
  LNeedle: TS4YSkinGaugeNeedle;
begin
  if Assigned(FNeedle) then
    UpdatePart(FNeedle, FNeedleRotation, FNeedleStyleAngle, FNeedleStyleCenter, FScale, GetDisplayedFraction);

  // The collection does not exist yet while the inherited constructor runs.
  if not Assigned(FNeedles) then
    Exit;

  for var I := 0 to FNeedles.Count - 1 do
  begin
    LNeedle := FNeedles[I];

    if Assigned(LNeedle.FPart) then
      UpdatePart(LNeedle.FPart, LNeedle.FPartRotation, LNeedle.FPartStyleAngle, LNeedle.FPartStyleCenter,
        LNeedle.FScale, LNeedle.GetFraction);
  end;
end;

procedure TS4YSkinCircularGauge.UpdatePart(const APart: TControl; const ARotation: IRotatedControl;
  const AStyleAngle: Single; const AStyleCenter: TPointF; const AScale: TArc; const AFraction: Single);
begin
  if Assigned(AScale) then
    UpdatePartCenter(APart, ARotation, AScale)
  else
    ARotation.RotationCenter.Point := AStyleCenter;

  // The needle points up, at the angle -90 of FMX, when its RotationAngle is the one of the style.
  ARotation.RotationAngle := GetPartAngle(AScale, AFraction) - C_FMX_TOP_ANGLE + AStyleAngle;
end;

procedure TS4YSkinCircularGauge.UpdatePartCenter(const APart: TControl; const ARotation: IRotatedControl;
  const AScale: TArc);
var
  LCenter: TPointF;
  LParent: TControl;
begin
  LParent := APart.ParentControl;

  if not Assigned(LParent) or (APart.Width <= 0) or (APart.Height <= 0) then
    Exit;

  // The center of the scale in the coordinates of the parent of the needle: directly when they are in
  // the same container, else through the coordinates of the form.
  if AScale.ParentControl = LParent then
    LCenter := AScale.Position.Point + TPointF.Create(AScale.Width / 2, AScale.Height / 2)
  else
    LCenter := LParent.AbsoluteToLocal(AScale.LocalToAbsolute(AScale.LocalRect.CenterPoint));

  // A container not yet laid out, with no size, gives no point.
  if IsNan(LCenter.X) or IsNan(LCenter.Y) or IsInfinite(LCenter.X) or IsInfinite(LCenter.Y) then
    Exit;

  ARotation.RotationCenter.Point := TPointF.Create((LCenter.X - APart.Position.X) / APart.Width,
    (LCenter.Y - APart.Position.Y) / APart.Height);
end;

procedure TS4YSkinCircularGauge.UpdateText(const AText: TText; const AValue: string);
begin
  if not Assigned(AText) then
    Exit;

  AText.Text := AValue;
  AText.Visible := AValue <> '';
end;

end.
