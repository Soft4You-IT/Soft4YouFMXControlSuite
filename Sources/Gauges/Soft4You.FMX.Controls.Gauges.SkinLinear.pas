unit Soft4You.FMX.Controls.Gauges.SkinLinear;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YSkinLinearGauge - linear gauge whose look is made of the parts of its style
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
  /// A pointer of a skin linear gauge with a value of its own, for example the marks of the lowest and the highest value on a thermometer.
  /// </summary>
  /// <remarks>
  /// The pointer is the part of the style named PartName; it moves at once to its value, without animation.
  /// </remarks>
  TS4YSkinGaugePointer = class(TCollectionItem)
  public const
    /// <summary>Default value of Max.</summary>
    C_DEFAULT_MAX: Single = 100;
  private
    FMax: Single;
    FMin: Single;
    FPart: TControl;
    FPartName: string;
    FPartStylePosition: TPointF;
    FScale: TControl;
    FScalePart: string;
    FValue: Single;
    procedure DetachPart;
    function GetFraction: Single;
    function MaxStored: Boolean;
    procedure ReleasePart;
    procedure SetMax(const Value: Single);
    procedure SetMin(const Value: Single);
    procedure SetPartName(const Value: string);
    procedure SetScalePart(const Value: string);
    procedure SetValue(const Value: Single);
  protected
    /// <summary>Returns PartName, for the editor of the collection.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates a pointer from 0 to 100.</summary>
    constructor Create(Collection: TCollection); override;
    /// <summary>Moves the part of the style back to its position of the style.</summary>
    destructor Destroy; override;

    /// <summary>Copies the settings from another pointer.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>Value of the pointer at the end of its scale. The default is 100.</summary>
    property Max: Single read FMax write SetMax stored MaxStored nodefault;
    /// <summary>Value of the pointer at the start of its scale. The default is 0.</summary>
    property Min: Single read FMin write SetMin;
    /// <summary>
    /// Name (StyleName) of the part of the style that is the pointer, for example pointermax.
    /// </summary>
    /// <remarks>
    /// It must be another part than pointer, which shows the Value of the gauge.
    /// </remarks>
    property PartName: string read FPartName write SetPartName;
    /// <summary>
    /// Name (StyleName) of the part of the style whose rectangle is the scale of the pointer.
    /// </summary>
    /// <remarks>
    /// Empty, or when the style has no part with this name, the pointer uses the scale of the gauge; without scale, the whole gauge.
    /// </remarks>
    property ScalePart: string read FScalePart write SetScalePart;
    /// <summary>Value shown by the pointer, kept between Min and Max.</summary>
    property Value: Single read FValue write SetValue;
  end;

  /// <summary>
  /// The pointers of a skin linear gauge with a value of their own.
  /// </summary>
  TS4YSkinGaugePointers = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    function GetItem(const AIndex: Integer): TS4YSkinGaugePointer;
    procedure SetItem(const AIndex: Integer; const Value: TS4YSkinGaugePointer);
  protected
    /// <summary>Fires OnChange.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the collection of the pointers of AOwner.</summary>
    constructor Create(const AOwner: TPersistent);

    /// <summary>The pointers, by position.</summary>
    property Items[const AIndex: Integer]: TS4YSkinGaugePointer read GetItem write SetItem; default;

    /// <summary>Fires when a pointer is added, removed or changed.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  /// <summary>
  /// A linear gauge whose look is made only of the parts of its style, such as a thermometer or a level drawn as images or shapes: the gauge moves a pointer to the value, uncovers the filled part of an image and writes the value and the caption.
  /// </summary>
  /// <remarks>
  /// The style is S4YSkinLinearGaugeStyle. Its parts are shown as they are, with their own size and position; the gauge changes only these:
  /// scale, an optional part, usually hidden, whose rectangle is the scale from Min to Max; without it, the scale is the whole gauge;
  /// pointer, any object, moved along the scale until its center is on the value, and left where the style puts it across the scale;
  /// reveal, a container whose rectangle is cut, from the side of Min, at the value on the scale: it shows only the filled part of its children, which stay still;
  /// valuetext and captiontext, TText objects that receive the value and the caption, and are hidden when they are empty;
  /// the parts named in Pointers, other pointers with values of their own.
  /// Orientation and Reversed give the direction of the scale, also when the style has a scale part.
  /// The default style puts its parts in a TScaledLayout aligned with Fit, so that the whole bar is resized with the gauge without being stretched.
  /// </remarks>
  TS4YSkinLinearGauge = class(TS4YCustomGauge)
  public const
    /// <summary>Default value of Orientation.</summary>
    C_DEFAULT_ORIENTATION = TOrientation.Horizontal;
  private
    FOrientation: TOrientation;
    FPointer: TControl;
    FPointers: TS4YSkinGaugePointers;
    FPointerStylePosition: TPointF;
    FReveal: TControl;
    FRevealChildPositions: TArray<TPointF>;
    FRevealStyleRect: TRectF;
    FReversed: Boolean;
    FScale: TControl;
    procedure BindPointers;
    procedure DetachPointers;
    function GetScaleRect(const AScale, AParent: TControl; out ARect: TRectF): Boolean;
    function GetValuePoint(const AScale, AParent: TControl; const AFraction: Single; out APoint: TPointF): Boolean;
    procedure PointersChanged(Sender: TObject);
    function PointersStored: Boolean;
    procedure SetOrientation(const Value: TOrientation);
    procedure SetPointers(const Value: TS4YSkinGaugePointers);
    procedure SetReversed(const Value: Boolean);
    procedure UpdateParts;
    procedure UpdatePointer(const APart: TControl; const AStylePosition: TPointF; const AScale: TControl;
      const AFraction: Single);
    procedure UpdateReveal;
    procedure UpdateText(const AText: TText; const AValue: string);
  protected
    /// <summary>Finds the scale, the pointers and the reveal of the style.</summary>
    procedure ApplyStyle; override;
    /// <summary>Moves the pointer and the reveal to the value drawn and writes the value and the caption in the texts of the style.</summary>
    procedure DisplayChanged; override;
    /// <summary>Places the pointers and the reveal again, after the parts of the style have been resized.</summary>
    procedure DoRealign; override;
    /// <summary>Draws nothing: the parts of the style are painted as children of the gauge.</summary>
    procedure DrawGauge; override;
    /// <summary>Releases the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control: 200 x 60.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns 0: the gauge has no track of its own.</summary>
    function GetDefaultThickness: Single; override;
  public
    /// <summary>Creates a horizontal gauge with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Destroys the gauge and its pointers.</summary>
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
    property Opacity;
    /// <summary>
    /// Direction of the scale: Horizontal, from the left to the right, or Vertical, from the bottom to the top. The default is Horizontal.
    /// </summary>
    /// <remarks>
    /// Used also when the style has a scale part, which gives only the position and the length of the scale.
    /// </remarks>
    property Orientation: TOrientation read FOrientation write SetOrientation default C_DEFAULT_ORIENTATION;
    property Padding;
    /// <summary>
    /// Other pointers of the style, each with a value of its own, for example the marks of the lowest and the highest value. Empty by default.
    /// </summary>
    /// <remarks>
    /// The part pointer always shows Value, with the animation; the pointers of the collection move at once to their values.
    /// </remarks>
    property Pointers: TS4YSkinGaugePointers read FPointers write SetPointers stored PointersStored;
    property PopupMenu;
    property Position;
    /// <summary>
    /// True makes the scale start from the other end: from the right for a horizontal gauge, from the top for a vertical one. The default is False.
    /// </summary>
    property Reversed: Boolean read FReversed write SetReversed default False;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property ShowValue;
    property Size;
    property StyleLookup;
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

{$IF DEFINED(IOS)}
{$R *.ios.res}
{$ELSEIF DEFINED(MACOS)}
{$R *.mac.res}
{$ELSEIF DEFINED(ANDROID)}
{$R *.android.res}
{$ELSEIF DEFINED(MSWINDOWS)}
{$R *.win.res}
{$ENDIF}

const
  C_STYLE_POINTER = 'pointer';
  C_STYLE_REVEAL = 'reveal';
  C_STYLE_SCALE = 'scale';

  // Size of a new gauge.
  C_DEFAULT_WIDTH = 200;
  C_DEFAULT_HEIGHT = 60;

function IsValidPoint(const APoint: TPointF): Boolean;
begin
  Result := not (IsNan(APoint.X) or IsNan(APoint.Y) or IsInfinite(APoint.X) or IsInfinite(APoint.Y));
end;

{ TS4YSkinGaugePointer }

constructor TS4YSkinGaugePointer.Create(Collection: TCollection);
begin
  inherited;

  FMax := C_DEFAULT_MAX;
end;

destructor TS4YSkinGaugePointer.Destroy;
begin
  ReleasePart;

  inherited;
end;

procedure TS4YSkinGaugePointer.Assign(Source: TPersistent);
var
  LSource: TS4YSkinGaugePointer;
begin
  if Source is TS4YSkinGaugePointer then
  begin
    LSource := TS4YSkinGaugePointer(Source);

    if FPartName <> LSource.PartName then
      ReleasePart;

    FMax := LSource.Max;
    FMin := LSource.Min;
    FPartName := LSource.PartName;
    FScalePart := LSource.ScalePart;
    FValue := LSource.Value;
    Changed(False);
  end
  else
    inherited;
end;

procedure TS4YSkinGaugePointer.DetachPart;
begin
  FPart := nil;
  FScale := nil;
end;

function TS4YSkinGaugePointer.GetDisplayName: string;
begin
  if FPartName <> '' then
    Result := FPartName
  else
    Result := inherited;
end;

function TS4YSkinGaugePointer.GetFraction: Single;
var
  LRange: Single;
begin
  // The position of the value from Min to Max, from 0 to 1.
  LRange := FMax - FMin;

  if LRange = 0 then
    Exit(0);

  Result := EnsureRange((FValue - FMin) / LRange, 0, 1);
end;

function TS4YSkinGaugePointer.MaxStored: Boolean;
begin
  Result := FMax <> C_DEFAULT_MAX;
end;

procedure TS4YSkinGaugePointer.ReleasePart;
begin
  // The part is no longer a pointer of the collection: it goes back where it is in the style.
  if Assigned(FPart) then
    FPart.Position.Point := FPartStylePosition;

  DetachPart;
end;

procedure TS4YSkinGaugePointer.SetMax(const Value: Single);
begin
  if FMax = Value then
    Exit;

  FMax := Value;
  Changed(False);
end;

procedure TS4YSkinGaugePointer.SetMin(const Value: Single);
begin
  if FMin = Value then
    Exit;

  FMin := Value;
  Changed(False);
end;

procedure TS4YSkinGaugePointer.SetPartName(const Value: string);
begin
  if FPartName = Value then
    Exit;

  ReleasePart;
  FPartName := Value;
  Changed(False);
end;

procedure TS4YSkinGaugePointer.SetScalePart(const Value: string);
begin
  if FScalePart = Value then
    Exit;

  FScalePart := Value;
  Changed(False);
end;

procedure TS4YSkinGaugePointer.SetValue(const Value: Single);
begin
  if FValue = Value then
    Exit;

  FValue := Value;
  Changed(False);
end;

{ TS4YSkinGaugePointers }

constructor TS4YSkinGaugePointers.Create(const AOwner: TPersistent);
begin
  inherited Create(AOwner, TS4YSkinGaugePointer);
end;

function TS4YSkinGaugePointers.GetItem(const AIndex: Integer): TS4YSkinGaugePointer;
begin
  Result := TS4YSkinGaugePointer(inherited Items[AIndex]);
end;

procedure TS4YSkinGaugePointers.SetItem(const AIndex: Integer; const Value: TS4YSkinGaugePointer);
begin
  inherited Items[AIndex] := Value;
end;

procedure TS4YSkinGaugePointers.Update(Item: TCollectionItem);
begin
  inherited;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TS4YSkinLinearGauge }

constructor TS4YSkinLinearGauge.Create(AOwner: TComponent);
begin
  inherited;

  FOrientation := C_DEFAULT_ORIENTATION;
  FPointers := TS4YSkinGaugePointers.Create(Self);
  FPointers.OnChange := PointersChanged;
end;

destructor TS4YSkinLinearGauge.Destroy;
begin
  // The parts of the style are freed with the gauge: they are not moved back.
  FPointers.OnChange := nil;
  DetachPointers;
  FreeAndNil(FPointers);

  inherited;
end;

procedure TS4YSkinLinearGauge.ApplyStyle;
begin
  // Found before the inherited method, which shows the value with them.
  FPointer := nil;
  FReveal := nil;
  FScale := nil;
  FRevealChildPositions := nil;

  FindStyleResource<TControl>(C_STYLE_SCALE, FScale);

  if FindStyleResource<TControl>(C_STYLE_POINTER, FPointer) then
    FPointerStylePosition := FPointer.Position.Point;

  // The children of the reveal are moved against its cut, so that they stay still.
  if FindStyleResource<TControl>(C_STYLE_REVEAL, FReveal) then
  begin
    FReveal.ClipChildren := True;
    FRevealStyleRect := TRectF.Create(FReveal.Position.Point, FReveal.Width, FReveal.Height);
    SetLength(FRevealChildPositions, FReveal.ControlsCount);

    for var I := 0 to FReveal.ControlsCount - 1 do
      FRevealChildPositions[I] := FReveal.Controls[I].Position.Point;
  end;

  BindPointers;

  inherited;
end;

procedure TS4YSkinLinearGauge.BindPointers;
var
  LPointer: TS4YSkinGaugePointer;
begin
  for var I := 0 to FPointers.Count - 1 do
  begin
    LPointer := FPointers[I];

    // A part already found keeps the position it had in the style.
    if not Assigned(LPointer.FPart) and (LPointer.PartName <> '') and
      FindStyleResource<TControl>(LPointer.PartName, LPointer.FPart) then
      LPointer.FPartStylePosition := LPointer.FPart.Position.Point;

    LPointer.FScale := nil;

    if (LPointer.ScalePart = '') or not FindStyleResource<TControl>(LPointer.ScalePart, LPointer.FScale) then
      LPointer.FScale := FScale;
  end;
end;

procedure TS4YSkinLinearGauge.DetachPointers;
begin
  if not Assigned(FPointers) then
    Exit;

  for var I := 0 to FPointers.Count - 1 do
    FPointers[I].DetachPart;
end;

procedure TS4YSkinLinearGauge.DisplayChanged;
begin
  UpdateParts;
  UpdateText(StyleValueText, GetValueText);
  UpdateText(StyleCaptionText, Caption);
end;

procedure TS4YSkinLinearGauge.DoRealign;
begin
  inherited;

  UpdateParts;
end;

procedure TS4YSkinLinearGauge.DrawGauge;
begin
  // Nothing: the pointers, the reveal and the texts are parts of the style, painted as children of the gauge.
end;

procedure TS4YSkinLinearGauge.FreeStyle;
begin
  FPointer := nil;
  FReveal := nil;
  FScale := nil;
  FRevealChildPositions := nil;
  DetachPointers;

  inherited;
end;

function TS4YSkinLinearGauge.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_WIDTH, C_DEFAULT_HEIGHT);
end;

function TS4YSkinLinearGauge.GetDefaultThickness: Single;
begin
  Result := 0;
end;

function TS4YSkinLinearGauge.GetScaleRect(const AScale, AParent: TControl; out ARect: TRectF): Boolean;
var
  LSource: TControl;
  LTopLeft: TPointF;
  LBottomRight: TPointF;
begin
  // The rectangle of the scale, or of the whole gauge without scale, in the coordinates of AParent: directly
  // when they are in the same container, else through the coordinates of the form.
  if Assigned(AScale) and (AScale.ParentControl = AParent) then
  begin
    ARect := TRectF.Create(AScale.Position.Point, AScale.Width, AScale.Height);
    Exit(True);
  end;

  if Assigned(AScale) then
    LSource := AScale
  else
    LSource := Self;

  LTopLeft := AParent.AbsoluteToLocal(LSource.LocalToAbsolute(TPointF.Zero));
  LBottomRight := AParent.AbsoluteToLocal(LSource.LocalToAbsolute(TPointF.Create(LSource.Width, LSource.Height)));
  ARect := TRectF.Create(LTopLeft, LBottomRight);
  ARect.NormalizeRect;

  // A container not yet laid out, with no size, gives no rectangle.
  Result := IsValidPoint(LTopLeft) and IsValidPoint(LBottomRight);
end;

function TS4YSkinLinearGauge.GetValuePoint(const AScale, AParent: TControl; const AFraction: Single;
  out APoint: TPointF): Boolean;
var
  LRect: TRectF;
begin
  // The point of the value on the middle line of the scale, in the coordinates of AParent.
  Result := Assigned(AParent) and GetScaleRect(AScale, AParent, LRect);

  if not Result then
    Exit;

  APoint := LRect.CenterPoint;

  if FOrientation = TOrientation.Horizontal then
  begin
    if FReversed then
      APoint.X := LRect.Right - LRect.Width * AFraction
    else
      APoint.X := LRect.Left + LRect.Width * AFraction;
  end
  else
  begin
    if FReversed then
      APoint.Y := LRect.Top + LRect.Height * AFraction
    else
      APoint.Y := LRect.Bottom - LRect.Height * AFraction;
  end;
end;

procedure TS4YSkinLinearGauge.PointersChanged(Sender: TObject);
begin
  BindPointers;
  UpdateParts;
end;

function TS4YSkinLinearGauge.PointersStored: Boolean;
begin
  // An empty collection is not written to the form.
  Result := FPointers.Count > 0;
end;

procedure TS4YSkinLinearGauge.SetOrientation(const Value: TOrientation);
begin
  if FOrientation = Value then
    Exit;

  FOrientation := Value;
  UpdateParts;
end;

procedure TS4YSkinLinearGauge.SetPointers(const Value: TS4YSkinGaugePointers);
begin
  FPointers.Assign(Value);
end;

procedure TS4YSkinLinearGauge.SetReversed(const Value: Boolean);
begin
  if FReversed = Value then
    Exit;

  FReversed := Value;
  UpdateParts;
end;

procedure TS4YSkinLinearGauge.UpdateParts;
var
  LPointer: TS4YSkinGaugePointer;
begin
  if Assigned(FPointer) then
    UpdatePointer(FPointer, FPointerStylePosition, FScale, GetDisplayedFraction);

  if Assigned(FReveal) then
    UpdateReveal;

  // The collection does not exist yet while the inherited constructor runs.
  if not Assigned(FPointers) then
    Exit;

  for var I := 0 to FPointers.Count - 1 do
  begin
    LPointer := FPointers[I];

    if Assigned(LPointer.FPart) then
      UpdatePointer(LPointer.FPart, LPointer.FPartStylePosition, LPointer.FScale, LPointer.GetFraction);
  end;
end;

procedure TS4YSkinLinearGauge.UpdatePointer(const APart: TControl; const AStylePosition: TPointF;
  const AScale: TControl; const AFraction: Single);
var
  LPoint: TPointF;
begin
  if not GetValuePoint(AScale, APart.ParentControl, AFraction, LPoint) then
    Exit;

  // Along the scale the center goes on the value; across it the pointer stays where the style puts it.
  if FOrientation = TOrientation.Horizontal then
    APart.Position.Point := TPointF.Create(LPoint.X - APart.Width / 2, AStylePosition.Y)
  else
    APart.Position.Point := TPointF.Create(AStylePosition.X, LPoint.Y - APart.Height / 2);
end;

procedure TS4YSkinLinearGauge.UpdateReveal;
var
  LPoint: TPointF;
  LRect: TRectF;
  LOffset: TPointF;
begin
  if not GetValuePoint(FScale, FReveal.ParentControl, GetDisplayedFraction, LPoint) then
    Exit;

  // The rectangle of the style, cut at the value from the side of Min.
  LRect := FRevealStyleRect;

  if FOrientation = TOrientation.Horizontal then
  begin
    if FReversed then
      LRect.Left := EnsureRange(LPoint.X, LRect.Left, LRect.Right)
    else
      LRect.Right := EnsureRange(LPoint.X, LRect.Left, LRect.Right);
  end
  else
  begin
    if FReversed then
      LRect.Bottom := EnsureRange(LPoint.Y, LRect.Top, LRect.Bottom)
    else
      LRect.Top := EnsureRange(LPoint.Y, LRect.Top, LRect.Bottom);
  end;

  FReveal.SetBounds(LRect.Left, LRect.Top, LRect.Width, LRect.Height);
  LOffset := LRect.TopLeft - FRevealStyleRect.TopLeft;

  for var I := 0 to System.Math.Min(FReveal.ControlsCount, Length(FRevealChildPositions)) - 1 do
    FReveal.Controls[I].Position.Point := FRevealChildPositions[I] - LOffset;
end;

procedure TS4YSkinLinearGauge.UpdateText(const AText: TText; const AValue: string);
begin
  if not Assigned(AText) then
    Exit;

  AText.Text := AValue;
  AText.Visible := AValue <> '';
end;

end.
