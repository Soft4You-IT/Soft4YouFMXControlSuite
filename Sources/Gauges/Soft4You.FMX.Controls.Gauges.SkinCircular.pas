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
  /// A circular gauge whose look is made only of the parts of its style, such as a dial and a needle drawn as images or shapes: the gauge turns the needle to the value and writes the value and the caption.
  /// </summary>
  /// <remarks>
  /// The style is S4YSkinCircularGaugeStyle. Its parts are shown as they are, with their own size and position; the gauge changes only these:
  /// needle, any object drawn pointing up, which turns around its center of rotation to the angle of the value;
  /// scale, an optional TArc, usually hidden, which gives the angles of the needle (StartAngle and EndAngle of the arc, a negative EndAngle turning counterclockwise) and, with its center, the center of rotation of the needle;
  /// valuetext and captiontext, TText objects that receive the value and the caption, and are hidden when they are empty.
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
    FNeedleStyleAngle: Single;
    FReversed: Boolean;
    FScale: TArc;
    FStartAngle: Single;
    FSweepAngle: Single;
    function GetNeedleAngle: Single;
    procedure SetReversed(const Value: Boolean);
    procedure SetStartAngle(const Value: Single);
    procedure SetSweepAngle(const Value: Single);
    function StartAngleStored: Boolean;
    function SweepAngleStored: Boolean;
    procedure UpdateNeedle;
    procedure UpdateNeedleCenter;
    procedure UpdateText(const AText: TText; const AValue: string);
  protected
    /// <summary>Finds the needle and the scale of the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Turns the needle to the value drawn and writes the value and the caption in the texts of the style.</summary>
    procedure DisplayChanged; override;
    /// <summary>Places the center of rotation of the needle again, after the parts of the style have been resized.</summary>
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

{ TS4YSkinCircularGauge }

constructor TS4YSkinCircularGauge.Create(AOwner: TComponent);
begin
  inherited;

  FStartAngle := C_DEFAULT_START_ANGLE;
  FSweepAngle := C_DEFAULT_SWEEP_ANGLE;
end;

procedure TS4YSkinCircularGauge.ApplyStyle;
begin
  // Found before the inherited method, which shows the value with them.
  FNeedle := nil;
  FNeedleRotation := nil;
  FScale := nil;

  // The angle and the center of rotation of a control are reached through IRotatedControl.
  if FindStyleResource<TControl>(C_STYLE_NEEDLE, FNeedle) and Supports(FNeedle, IRotatedControl, FNeedleRotation) then
    FNeedleStyleAngle := FNeedleRotation.RotationAngle
  else
    FNeedle := nil;

  FindStyleResource<TArc>(C_STYLE_SCALE, FScale);

  inherited;
end;

procedure TS4YSkinCircularGauge.DisplayChanged;
begin
  UpdateNeedle;
  UpdateText(StyleValueText, GetValueText);
  UpdateText(StyleCaptionText, Caption);
end;

procedure TS4YSkinCircularGauge.DoRealign;
begin
  inherited;

  UpdateNeedle;
end;

procedure TS4YSkinCircularGauge.DrawGauge;
begin
  // Nothing: the needle and the texts are parts of the style, painted as children of the gauge.
end;

procedure TS4YSkinCircularGauge.FreeStyle;
begin
  FNeedle := nil;
  FNeedleRotation := nil;
  FScale := nil;

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

function TS4YSkinCircularGauge.GetNeedleAngle: Single;
var
  LFraction: Single;
begin
  // The angle of FMX, from the right side and clockwise, of the value drawn.
  LFraction := GetDisplayedFraction;

  if Assigned(FScale) then
    Exit(FScale.StartAngle + FScale.EndAngle * LFraction);

  if FReversed then
    Result := FStartAngle + C_FMX_TOP_ANGLE - FSweepAngle * LFraction
  else
    Result := FStartAngle + C_FMX_TOP_ANGLE + FSweepAngle * LFraction;
end;

procedure TS4YSkinCircularGauge.SetReversed(const Value: Boolean);
begin
  if FReversed = Value then
    Exit;

  FReversed := Value;
  UpdateNeedle;
end;

procedure TS4YSkinCircularGauge.SetStartAngle(const Value: Single);
begin
  if SameValue(FStartAngle, Value) then
    Exit;

  FStartAngle := Value;
  UpdateNeedle;
end;

procedure TS4YSkinCircularGauge.SetSweepAngle(const Value: Single);
var
  LSweepAngle: Single;
begin
  LSweepAngle := EnsureRange(Value, 0, C_MAX_SWEEP_ANGLE);

  if SameValue(FSweepAngle, LSweepAngle) then
    Exit;

  FSweepAngle := LSweepAngle;
  UpdateNeedle;
end;

function TS4YSkinCircularGauge.StartAngleStored: Boolean;
begin
  Result := not SameValue(FStartAngle, C_DEFAULT_START_ANGLE);
end;

function TS4YSkinCircularGauge.SweepAngleStored: Boolean;
begin
  Result := not SameValue(FSweepAngle, C_DEFAULT_SWEEP_ANGLE);
end;

procedure TS4YSkinCircularGauge.UpdateNeedle;
begin
  if not Assigned(FNeedle) then
    Exit;

  if Assigned(FScale) then
    UpdateNeedleCenter;

  // The needle points up, at the angle -90 of FMX, when its RotationAngle is the one of the style.
  FNeedleRotation.RotationAngle := GetNeedleAngle - C_FMX_TOP_ANGLE + FNeedleStyleAngle;
end;

procedure TS4YSkinCircularGauge.UpdateNeedleCenter;
var
  LCenter: TPointF;
  LParent: TControl;
begin
  LParent := FNeedle.ParentControl;

  if not Assigned(LParent) or (FNeedle.Width <= 0) or (FNeedle.Height <= 0) then
    Exit;

  // The center of the scale in the coordinates of the parent of the needle: directly when they are in
  // the same container, else through the coordinates of the form.
  if FScale.ParentControl = LParent then
    LCenter := FScale.Position.Point + TPointF.Create(FScale.Width / 2, FScale.Height / 2)
  else
    LCenter := LParent.AbsoluteToLocal(FScale.LocalToAbsolute(FScale.LocalRect.CenterPoint));

  // A container not yet laid out, with no size, gives no point.
  if IsNan(LCenter.X) or IsNan(LCenter.Y) or IsInfinite(LCenter.X) or IsInfinite(LCenter.Y) then
    Exit;

  FNeedleRotation.RotationCenter.Point := TPointF.Create((LCenter.X - FNeedle.Position.X) / FNeedle.Width,
    (LCenter.Y - FNeedle.Position.Y) / FNeedle.Height);
end;

procedure TS4YSkinCircularGauge.UpdateText(const AText: TText; const AValue: string);
begin
  if not Assigned(AText) then
    Exit;

  AText.Text := AValue;
  AText.Visible := AValue <> '';
end;

end.
