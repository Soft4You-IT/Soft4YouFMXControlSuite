unit Soft4You.FMX.Controls.Tag;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YTag - label that classifies, with an icon or a picture and a close button
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Types,
  System.UITypes,
  System.ImageList,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.Objects,
  FMX.ActnList,
  FMX.ImgList,
  FMX.TextLayout,
  Soft4You.FMX.Controls.Tag.Types;

type
  /// <summary>
  /// Base of TS4YTag and TS4YChip: a short text on a colored background, with an icon or a picture on the left and a close button on the right.
  /// </summary>
  /// <remarks>
  /// All the behavior is here, with protected properties: TS4YTag and TS4YChip publish the ones that make sense for them.
  /// The control is as wide as its content (AutoSize) and as high as its SizePreset says.
  /// The look comes from the style: for a TS4YTag the one named S4YTagStyle, for a TS4YChip S4YChipStyle, in the style book, in the active style or, when they are not found, the one linked into the package. The parts of both styles have the same names: background, image, icon, check, text, close and closeicon, and the colors neutralcolor, primarycolor, successcolor, warningcolor, dangercolor and infocolor.
  /// </remarks>
  TS4YCustomTag = class(TStyledControl, IGlyph, IFreeNotification)
  public const
    /// <summary>Default value of CornerRadius, in pixels.</summary>
    C_DEFAULT_CORNER_RADIUS: Single = 6;
    /// <summary>Default value of Kind.</summary>
    C_DEFAULT_KIND = tgkNeutral;
    /// <summary>Default value of Shape.</summary>
    C_DEFAULT_SHAPE = tgsPill;
    /// <summary>Default value of SizePreset on the desktop; on Android and iOS the default is tgzLarge.</summary>
    C_DEFAULT_SIZE_PRESET = tgzMedium;
    /// <summary>Default value of Variant.</summary>
    C_DEFAULT_VARIANT = tgvTonal;
  private type
    // Sizes of the parts, all of them calculated from the height of the control
    TTagMetrics = record
      ClosePadding: Single;
      CloseSize: Single;
      FontSize: Single;
      Gap: Single;
      Height: Single;
      IconSize: Single;
      Padding: Single;
    end;
  private
    FAutoSize: Boolean;
    FBackgroundColor: TAlphaColor;
    FBitmap: TBitmap;
    FBorderColor: TAlphaColor;
    FClosable: Boolean;
    FCloseHovered: Boolean;
    FCornerRadius: Single;
    FCoverBitmap: TBitmap;
    FCoverInvalid: Boolean;
    FImageLink: TGlyphImageLink;
    FImageRound: Boolean;
    FKind: TS4YTagKind;
    FMaxWidth: Single;
    FShape: TS4YTagShape;
    FSizePreset: TS4YTagSizePreset;
    FStyleBackground: TRectangle;
    FStyleCheck: TShape;
    FStyleClose: TShape;
    FStyleCloseIcon: TShape;
    FStyleIcon: TGlyph;
    FStyleImage: TRectangle;
    FStyleKindColors: array[TS4YTagKind] of TAlphaColor;
    FStyleKindTextColors: array[TS4YTagKind] of TAlphaColor;
    FStyleText: TText;
    FText: string;
    FTextColor: TAlphaColor;
    FTextLayout: TTextLayout;
    FVariant: TS4YTagVariant;
    FOnClose: TS4YTagCloseEvent;
    procedure ApplyRadius(const APart: TControl; const ARadius: Single);
    procedure BitmapChanged(Sender: TObject);
    procedure CalculateColors(out AFillColor, ATextColor, AStrokeColor: TAlphaColor);
    function CalculateContentWidth: Single;
    function CalculateMetrics: TTagMetrics;
    procedure CloseClick(Sender: TObject);
    procedure CloseMouseChanged(Sender: TObject);
    function CornerRadiusStored: Boolean;
    procedure FindStyleColor(const AStyleName: string; const ADefaultColor: TAlphaColor; out AColor: TAlphaColor);
    function GetAccentColor: TAlphaColor;
    function GetImageIndex: TImageIndex;
    function GetImageList: TBaseImageList;
    function GetImages: TCustomImageList;
    function GetKindTextColor(const AAccentColor: TAlphaColor): TAlphaColor;
    function MaxWidthStored: Boolean;
    function MeasureTextWidth(const AFontSize: Single): Single;
    procedure SetAutoSize(const Value: Boolean);
    procedure SetBackgroundColor(const Value: TAlphaColor);
    procedure SetBitmap(const Value: TBitmap);
    procedure SetBorderColor(const Value: TAlphaColor);
    procedure SetClosable(const Value: Boolean);
    procedure SetCornerRadius(const Value: Single);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageList(const Value: TBaseImageList);
    procedure SetImageRound(const Value: Boolean);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetKind(const Value: TS4YTagKind);
    procedure SetMaxWidth(const Value: Single);
    procedure SetShape(const Value: TS4YTagShape);
    procedure SetSizePreset(const Value: TS4YTagSizePreset);
    procedure SetText(const Value: string);
    procedure SetTextColor(const Value: TAlphaColor);
    procedure SetVariant(const Value: TS4YTagVariant);
    procedure StyleResourceFreed(AObject: TObject);
    procedure UpdateCoverBitmap(const ASide: Single);
    { IGlyph }
    function IGlyph.GetImages = GetImageList;
    procedure IGlyph.SetImages = SetImageList;
    { IFreeNotification }
    procedure IFreeNotification.FreeNotification = StyleResourceFreed;
  protected
    /// <summary>Finds the parts of the style and applies the settings of the control to them.</summary>
    procedure ApplyStyle; override;
    /// <summary>Hides the control, unless OnClose says otherwise.</summary>
    procedure DoClose; virtual;
    /// <summary>Puts the close button back to normal.</summary>
    procedure DoMouseLeave; override;
    /// <summary>Places the parts of the style after the size of the control changes.</summary>
    procedure DoRealign; override;
    /// <summary>Gives the control the width of its content when AutoSize is True, and the height of SizePreset.</summary>
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
      var ALastWidth, ALastHeight: Single): Boolean; override;
    /// <summary>Redraws the control with the look of the enabled or disabled state.</summary>
    procedure EnabledChanged; override;
    /// <summary>Releases the parts of the style found by ApplyStyle.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control, with the height of the default size preset.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns the variant that is drawn: Variant for a tag; a chip draws a stronger one when it is checked.</summary>
    function GetEffectiveVariant: TS4YTagVariant; virtual;
    /// <summary>Returns the visual state: always tgtNormal for a tag.</summary>
    function GetState: TS4YTagState; virtual;
    /// <summary>Returns the style of the control: the one named by StyleLookup or, when it is empty or not found, the one named after the class in the style book or in the active style; else the default style linked into the package.</summary>
    function GetStyleObject: TFmxObject; override;
    /// <summary>Called when the image list or the image index change: it refreshes the icon.</summary>
    procedure ImagesChanged; virtual;
    /// <summary>Tells whether the check mark takes the place of the icon: never for a tag.</summary>
    function IsCheckMarkShown: Boolean; virtual;
    /// <summary>Tells whether a focus border is drawn: never for a tag.</summary>
    function IsFocusBorderShown: Boolean; virtual;
    /// <summary>Places the parts of the style after the size is set.</summary>
    procedure Loaded; override;
    /// <summary>At design time gives a new control its name as the text, and follows its renaming while the text is still the name.</summary>
    procedure SetName(const NewName: TComponentName); override;
    /// <summary>Places the parts of the style and gives them the settings of the control.</summary>
    procedure UpdateParts; virtual;
    /// <summary>Sets again the size of the control from its content and its size preset.</summary>
    procedure UpdateSize; virtual;

    /// <summary>When True, the default, the width follows the content: the text, the icon and the close button. When False the width is the one set, and a text that does not fit is cut.</summary>
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;
    /// <summary>Color of the background. The default, Null, takes it from Kind, Variant and the state.</summary>
    property BackgroundColor: TAlphaColor read FBackgroundColor write SetBackgroundColor default TAlphaColors.Null;
    /// <summary>Picture on the left, for example the photo of a person. It wins over the icon of Images.</summary>
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    /// <summary>Color of the border. The default, Null, takes it from Kind and Variant.</summary>
    property BorderColor: TAlphaColor read FBorderColor write SetBorderColor default TAlphaColors.Null;
    /// <summary>When True a close button, a cross, is shown on the right and OnClose fires when it is clicked. The default is False.</summary>
    property Closable: Boolean read FClosable write SetClosable default False;
    /// <summary>Radius of the corners when Shape is tgsRounded, in pixels. The default is 6.</summary>
    property CornerRadius: Single read FCornerRadius write SetCornerRadius stored CornerRadiusStored nodefault;
    /// <summary>Index in Images of the icon on the left. The default is -1, no icon.</summary>
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    /// <summary>When True the Bitmap is drawn round. The default is False: its corners are rounded a little.</summary>
    property ImageRound: Boolean read FImageRound write SetImageRound default False;
    /// <summary>Image list of the icon.</summary>
    property Images: TCustomImageList read GetImages write SetImages;
    /// <summary>Meaning of the control, which gives it its color. The default is tgkNeutral.</summary>
    property Kind: TS4YTagKind read FKind write SetKind default C_DEFAULT_KIND;
    /// <summary>Largest width of the control in pixels when AutoSize is True: a text that would make it wider is cut, with an ellipsis. The default, 0, means no limit.</summary>
    property MaxWidth: Single read FMaxWidth write SetMaxWidth stored MaxWidthStored nodefault;
    /// <summary>Shape of the control: pill (the default), rounded corners or square.</summary>
    property Shape: TS4YTagShape read FShape write SetShape default C_DEFAULT_SHAPE;
    /// <summary>Size chosen among the ready ones: small (24 pixels high), medium (32) or large (40).</summary>
    property SizePreset: TS4YTagSizePreset read FSizePreset write SetSizePreset default C_DEFAULT_SIZE_PRESET;
    /// <summary>Text of the control.</summary>
    property Text: string read FText write SetText;
    /// <summary>Color of the text and the icons. The default, Null, takes it from Kind and Variant.</summary>
    property TextColor: TAlphaColor read FTextColor write SetTextColor default TAlphaColors.Null;
    /// <summary>How the color fills the control: tgvFilled, tgvTonal or tgvOutlined.</summary>
    property Variant: TS4YTagVariant read FVariant write SetVariant default C_DEFAULT_VARIANT;
    /// <summary>Fires when the user clicks the close button; CanClose can stop the control from being hidden.</summary>
    property OnClose: TS4YTagCloseEvent read FOnClose write FOnClose;
  public
    /// <summary>Creates the control with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>Returns True when the control shows a picture on the left: Bitmap, or the image ImageIndex of Images.</summary>
    function HasPicture: Boolean;
  end;

  /// <summary>
  /// A label that classifies, for example Urgent or Draft: a short text on a colored background, with an optional icon or picture and a close button.
  /// </summary>
  /// <remarks>
  /// It does not react to the mouse or to the keyboard, except for its close button: use TS4YChip for something the user chooses.
  /// Kind gives the color, Variant the way it fills the control, Shape and SizePreset the form; the width follows the text.
  /// The style is S4YTagStyle; see the documentation for its parts.
  /// </remarks>
  TS4YTag = class(TS4YCustomTag)
  published
    property Align;
    property Anchors;
    property AutoSize;
    property BackgroundColor;
    property Bitmap;
    property BorderColor;
    property Closable;
    property CornerRadius;
    property Cursor;
    property Enabled;
    property Height;
    property HitTest;
    property ImageIndex;
    property ImageRound;
    property Images;
    property Kind;
    property Margins;
    property MaxWidth;
    property Opacity;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Shape;
    property Size;
    property SizePreset;
    property StyleLookup;
    property Text;
    property TextColor;
    property Variant;
    property Visible;
    property Width;

    property OnClick;
    property OnClose;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  FMX.Styles;

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
  C_STYLE_BACKGROUND = 'background';
  C_STYLE_CHECK = 'check';
  C_STYLE_CLOSE = 'close';
  C_STYLE_CLOSE_ICON = 'closeicon';
  C_STYLE_DANGER_COLOR = 'dangercolor';
  C_STYLE_ICON = 'icon';
  C_STYLE_IMAGE = 'image';
  C_STYLE_INFO_COLOR = 'infocolor';
  C_STYLE_NEUTRAL_COLOR = 'neutralcolor';
  C_STYLE_PRIMARY_COLOR = 'primarycolor';
  C_STYLE_SUCCESS_COLOR = 'successcolor';
  C_STYLE_TEXT = 'text';
  C_STYLE_WARNING_COLOR = 'warningcolor';
  C_STYLE_NEUTRAL_TEXT_COLOR = 'neutraltextcolor';
  C_STYLE_PRIMARY_TEXT_COLOR = 'primarytextcolor';
  C_STYLE_SUCCESS_TEXT_COLOR = 'successtextcolor';
  C_STYLE_WARNING_TEXT_COLOR = 'warningtextcolor';
  C_STYLE_DANGER_TEXT_COLOR = 'dangertextcolor';
  C_STYLE_INFO_TEXT_COLOR = 'infotextcolor';

  // Colors used when the style does not give them.
  C_FALLBACK_KIND_COLORS: array[TS4YTagKind] of TAlphaColor = (
    $FF757575, $FF1E88E5, $FF43A047, $FFFB8C00, $FFE53935, $FF00ACC1);

  // Colors of the text on a filled background, chosen by the luminance of the background.
  C_DARK_TEXT_COLOR: TAlphaColor = $FF212121;
  C_LIGHT_TEXT_COLOR: TAlphaColor = $FFFFFFFF;
  // Relative luminance above which a filled background is light and the text is dark.
  C_LIGHT_BACKGROUND_LUMINANCE = 0.6;

  // Opacity of the background and the text, as fractions, for the tonal and outlined variants and the states.
  C_TONAL_ALPHAS: array[TS4YTagState] of Single = (0.16, 0.24, 0.32);
  C_OUTLINED_ALPHAS: array[TS4YTagState] of Single = (0, 0.08, 0.16);
  // How much black a filled background takes in the states hover and pressed.
  C_FILLED_SHADES: array[TS4YTagState] of Single = (0, 0.1, 0.18);
  // How much black the text of the tonal and outlined variants takes, to be easy to read on a light background.
  C_TEXT_SHADE = 0.35;
  // Opacity of the round background of the close button while the mouse is over it.
  C_CLOSE_HOVER_ALPHA = 0.18;
  // Opacity of a disabled control.
  C_DISABLED_OPACITY = 0.5;

  // Height, font size and the spaces, as fractions of the height of the control.
  C_PADDING_FACTOR = 0.375;
  C_GAP_FACTOR = 0.22;
  C_ICON_FACTOR = 0.55;
  C_CLOSE_FACTOR = 0.6;
  C_CLOSE_PADDING_FACTOR = 0.5;
  // Space around the cross inside the close button, as a fraction of the button.
  C_CLOSE_ICON_MARGIN_FACTOR = 0.22;
  // Space around the check mark inside its box, as a fraction of the box.
  C_CHECK_MARGIN_FACTOR = 0.08;
  // Thickness of the border of the outlined variant and of the focus border.
  C_BORDER_THICKNESS = 1;
  C_FOCUS_THICKNESS = 2;
  // Smallest area that reacts to a finger on Android and iOS, in pixels.
  C_MIN_TOUCH_SIZE = 44;
  // Width and height given to a text while it is measured: large enough for any text.
  C_MEASURE_SIZE = 10000;

function IsMobilePlatform: Boolean;
begin
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function LuminanceOf(const AColor: TAlphaColor): Single;
var
  LColor: TAlphaColorRec;
begin
  // Perceived brightness, from 0 (black) to 1 (white).
  LColor := TAlphaColorRec(AColor);
  Result := (0.299 * LColor.R + 0.587 * LColor.G + 0.114 * LColor.B) / 255;
end;

// The color with another opacity: AAlpha is a fraction from 0 to 1 of the full opacity
function WithAlpha(const AColor: TAlphaColor; const AAlpha: Single): TAlphaColor;
var
  LColor: TAlphaColorRec;
begin
  LColor := TAlphaColorRec(AColor);
  LColor.A := Round(255 * System.Math.Max(0, System.Math.Min(1, AAlpha)));
  Result := TAlphaColor(LColor);
end;

// The color moved towards black by a fraction
function ShadeOf(const AColor: TAlphaColor; const AAmount: Single): TAlphaColor;
var
  LColor: TAlphaColorRec;
begin
  LColor := TAlphaColorRec(AColor);
  LColor.R := Round(LColor.R * (1 - AAmount));
  LColor.G := Round(LColor.G * (1 - AAmount));
  LColor.B := Round(LColor.B * (1 - AAmount));
  Result := TAlphaColor(LColor);
end;

constructor TS4YCustomTag.Create(AOwner: TComponent);
begin
  inherited;

  FAutoSize := True;
  FBackgroundColor := TAlphaColors.Null;
  FBorderColor := TAlphaColors.Null;
  FCornerRadius := C_DEFAULT_CORNER_RADIUS;
  FKind := C_DEFAULT_KIND;
  FShape := C_DEFAULT_SHAPE;
  FTextColor := TAlphaColors.Null;
  FVariant := C_DEFAULT_VARIANT;
  FCoverInvalid := True;

  if IsMobilePlatform then
    FSizePreset := tgzLarge
  else
    FSizePreset := C_DEFAULT_SIZE_PRESET;

  FBitmap := TBitmap.Create;
  FBitmap.OnChange := BitmapChanged;
  FImageLink := TGlyphImageLink.Create(Self);
  FTextLayout := TTextLayoutManager.DefaultTextLayout.Create;
  UpdateSize;
end;

destructor TS4YCustomTag.Destroy;
begin
  FreeAndNil(FTextLayout);
  FreeAndNil(FImageLink);
  FreeAndNil(FCoverBitmap);
  FreeAndNil(FBitmap);

  inherited;
end;

procedure TS4YCustomTag.ApplyRadius(const APart: TControl; const ARadius: Single);
begin
  if APart is TRectangle then
  begin
    TRectangle(APart).XRadius := ARadius;
    TRectangle(APart).YRadius := ARadius;
    TRectangle(APart).Corners := AllCorners;
    TRectangle(APart).CornerType := TCornerType.Round;
  end;
end;

procedure TS4YCustomTag.ApplyStyle;
begin
  inherited;

  FindStyleResource<TRectangle>(C_STYLE_BACKGROUND, FStyleBackground);
  FindStyleResource<TRectangle>(C_STYLE_IMAGE, FStyleImage);
  FindStyleResource<TGlyph>(C_STYLE_ICON, FStyleIcon);
  FindStyleResource<TShape>(C_STYLE_CHECK, FStyleCheck);
  FindStyleResource<TText>(C_STYLE_TEXT, FStyleText);
  FindStyleResource<TShape>(C_STYLE_CLOSE, FStyleClose);
  FindStyleResource<TShape>(C_STYLE_CLOSE_ICON, FStyleCloseIcon);

  // The parts that carry handlers tell when they are freed: a reference to a freed part never stays.
  if Assigned(FStyleClose) then
  begin
    FStyleClose.AddFreeNotify(Self);
    FStyleClose.HitTest := True;
    FStyleClose.Cursor := crHandPoint;
    FStyleClose.OnClick := CloseClick;
    FStyleClose.OnMouseEnter := CloseMouseChanged;
    FStyleClose.OnMouseLeave := CloseMouseChanged;
  end;

  if Assigned(FStyleIcon) then
  begin
    FStyleIcon.AddFreeNotify(Self);
    // The visibility of the icon is decided by the control, and a click on it goes to the control.
    // HitTest is set here: TGlyph publishes it only from Delphi 13, so the style cannot set it.
    FStyleIcon.AutoHide := False;
    FStyleIcon.HitTest := False;
  end;

  if Assigned(FStyleText) then
  begin
    FStyleText.HitTest := False;
    FStyleText.TextSettings.HorzAlign := TTextAlign.Leading;
    FStyleText.TextSettings.VertAlign := TTextAlign.Center;
    FStyleText.TextSettings.WordWrap := False;
    FStyleText.TextSettings.Trimming := TTextTrimming.Character;
  end;

  // The colors of the style are kept, so that the settings of the control can always go back to them.
  FindStyleColor(C_STYLE_NEUTRAL_COLOR, C_FALLBACK_KIND_COLORS[tgkNeutral], FStyleKindColors[tgkNeutral]);
  FindStyleColor(C_STYLE_PRIMARY_COLOR, C_FALLBACK_KIND_COLORS[tgkPrimary], FStyleKindColors[tgkPrimary]);
  FindStyleColor(C_STYLE_SUCCESS_COLOR, C_FALLBACK_KIND_COLORS[tgkSuccess], FStyleKindColors[tgkSuccess]);
  FindStyleColor(C_STYLE_WARNING_COLOR, C_FALLBACK_KIND_COLORS[tgkWarning], FStyleKindColors[tgkWarning]);
  FindStyleColor(C_STYLE_DANGER_COLOR, C_FALLBACK_KIND_COLORS[tgkDanger], FStyleKindColors[tgkDanger]);
  FindStyleColor(C_STYLE_INFO_COLOR, C_FALLBACK_KIND_COLORS[tgkInfo], FStyleKindColors[tgkInfo]);

  // The colors of the text of the tonal and outlined variants are optional: a style that does not give
  // them gets the color of the kind made darker, so that a dark style can give lighter ones.
  FindStyleColor(C_STYLE_NEUTRAL_TEXT_COLOR, TAlphaColors.Null, FStyleKindTextColors[tgkNeutral]);
  FindStyleColor(C_STYLE_PRIMARY_TEXT_COLOR, TAlphaColors.Null, FStyleKindTextColors[tgkPrimary]);
  FindStyleColor(C_STYLE_SUCCESS_TEXT_COLOR, TAlphaColors.Null, FStyleKindTextColors[tgkSuccess]);
  FindStyleColor(C_STYLE_WARNING_TEXT_COLOR, TAlphaColors.Null, FStyleKindTextColors[tgkWarning]);
  FindStyleColor(C_STYLE_DANGER_TEXT_COLOR, TAlphaColors.Null, FStyleKindTextColors[tgkDanger]);
  FindStyleColor(C_STYLE_INFO_TEXT_COLOR, TAlphaColors.Null, FStyleKindTextColors[tgkInfo]);

  // The picture is prepared again for the new part, and the width depends on the font of the style.
  FCoverInvalid := True;
  UpdateSize;
  UpdateParts;
end;

procedure TS4YCustomTag.BitmapChanged(Sender: TObject);
begin
  FCoverInvalid := True;
  UpdateSize;
  UpdateParts;
end;

procedure TS4YCustomTag.CalculateColors(out AFillColor, ATextColor, AStrokeColor: TAlphaColor);
var
  LAccentColor: TAlphaColor;
  LState: TS4YTagState;
begin
  LAccentColor := GetAccentColor;
  LState := GetState;
  AStrokeColor := TAlphaColors.Null;

  case GetEffectiveVariant of
    tgvFilled:
      begin
        AFillColor := ShadeOf(LAccentColor, C_FILLED_SHADES[LState]);

        if LuminanceOf(LAccentColor) > C_LIGHT_BACKGROUND_LUMINANCE then
          ATextColor := C_DARK_TEXT_COLOR
        else
          ATextColor := C_LIGHT_TEXT_COLOR;
      end;
    tgvTonal:
      begin
        AFillColor := WithAlpha(LAccentColor, C_TONAL_ALPHAS[LState]);
        ATextColor := GetKindTextColor(LAccentColor);
      end;
  else
    begin
      AFillColor := WithAlpha(LAccentColor, C_OUTLINED_ALPHAS[LState]);
      ATextColor := GetKindTextColor(LAccentColor);
      AStrokeColor := LAccentColor;
    end;
  end;

  // The colors of the properties replace the calculated ones; a state still shades a background
  // that was set.
  if FBackgroundColor <> TAlphaColors.Null then
    AFillColor := ShadeOf(FBackgroundColor, C_FILLED_SHADES[LState]);

  if FTextColor <> TAlphaColors.Null then
    ATextColor := FTextColor;

  if FBorderColor <> TAlphaColors.Null then
    AStrokeColor := FBorderColor;
end;

function TS4YCustomTag.CalculateContentWidth: Single;
var
  LMetrics: TTagMetrics;
begin
  LMetrics := CalculateMetrics;
  Result := LMetrics.Padding;

  if IsCheckMarkShown or HasPicture then
    Result := Result + LMetrics.IconSize + LMetrics.Gap;

  Result := Result + Ceil(MeasureTextWidth(LMetrics.FontSize));

  if FClosable then
    Result := Result + LMetrics.Gap + LMetrics.CloseSize + LMetrics.ClosePadding
  else
    Result := Result + LMetrics.Padding;

  if FMaxWidth > 0 then
    Result := System.Math.Min(Result, FMaxWidth);

  Result := System.Math.Max(Result, LMetrics.Height);
end;

function TS4YCustomTag.CalculateMetrics: TTagMetrics;
begin
  Result.Height := C_TAG_PRESET_HEIGHTS[FSizePreset];
  Result.FontSize := C_TAG_PRESET_FONT_SIZES[FSizePreset];
  Result.Padding := Result.Height * C_PADDING_FACTOR;
  Result.Gap := Result.Height * C_GAP_FACTOR;
  Result.IconSize := Result.Height * C_ICON_FACTOR;
  Result.CloseSize := Result.Height * C_CLOSE_FACTOR;
  Result.ClosePadding := Result.Padding * C_CLOSE_PADDING_FACTOR;
end;

procedure TS4YCustomTag.CloseClick(Sender: TObject);
begin
  DoClose;
end;

procedure TS4YCustomTag.CloseMouseChanged(Sender: TObject);
begin
  if Assigned(FStyleClose) then
    FCloseHovered := FStyleClose.IsMouseOver
  else
    FCloseHovered := False;

  UpdateParts;
end;

function TS4YCustomTag.CornerRadiusStored: Boolean;
begin
  Result := not SameValue(FCornerRadius, C_DEFAULT_CORNER_RADIUS);
end;

procedure TS4YCustomTag.DoClose;
var
  LCanClose: Boolean;
begin
  LCanClose := True;

  if Assigned(FOnClose) then
    FOnClose(Self, LCanClose);

  if LCanClose then
    Visible := False;
end;

procedure TS4YCustomTag.DoMouseLeave;
begin
  inherited;

  // The mouse can have moved from the control onto the close button, which is inside it.
  FCloseHovered := Assigned(FStyleClose) and FStyleClose.IsMouseOver;
  UpdateParts;
end;

procedure TS4YCustomTag.DoRealign;
begin
  inherited;

  UpdateParts;
end;

function TS4YCustomTag.DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean; ANewWidth,
  ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean;
begin
  // The first calls come from the constructor of the ancestors, before the fields exist.
  if Assigned(FTextLayout) then
  begin
    ANewHeight := C_TAG_PRESET_HEIGHTS[FSizePreset];

    if FAutoSize then
      ANewWidth := CalculateContentWidth;
  end;

  Result := inherited DoSetSize(ASize, NewPlatformDefault, ANewWidth, ANewHeight, ALastWidth, ALastHeight);
end;

procedure TS4YCustomTag.EnabledChanged;
begin
  inherited;

  UpdateParts;
end;

procedure TS4YCustomTag.FindStyleColor(const AStyleName: string; const ADefaultColor: TAlphaColor;
  out AColor: TAlphaColor);
var
  LColorObject: TColorObject;
begin
  if FindStyleResource<TColorObject>(AStyleName, LColorObject) then
    AColor := LColorObject.Color
  else
    AColor := ADefaultColor;
end;

procedure TS4YCustomTag.FreeStyle;
begin
  if Assigned(FStyleClose) then
  begin
    FStyleClose.RemoveFreeNotify(Self);
    FStyleClose.OnClick := nil;
    FStyleClose.OnMouseEnter := nil;
    FStyleClose.OnMouseLeave := nil;
    FStyleClose := nil;
  end;

  if Assigned(FStyleIcon) then
  begin
    FStyleIcon.RemoveFreeNotify(Self);
    FStyleIcon.ImageIndex := -1;
    FStyleIcon.Images := nil;
    FStyleIcon := nil;
  end;

  FStyleBackground := nil;
  FStyleCheck := nil;
  FStyleCloseIcon := nil;
  FStyleImage := nil;
  FStyleText := nil;
  FCloseHovered := False;

  inherited;
end;

function TS4YCustomTag.GetAccentColor: TAlphaColor;
begin
  Result := FStyleKindColors[FKind];

  if Result = TAlphaColors.Null then
    Result := C_FALLBACK_KIND_COLORS[FKind];
end;

function TS4YCustomTag.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_TAG_PRESET_HEIGHTS[C_DEFAULT_SIZE_PRESET] * 3, C_TAG_PRESET_HEIGHTS[C_DEFAULT_SIZE_PRESET]);
end;

function TS4YCustomTag.GetEffectiveVariant: TS4YTagVariant;
begin
  Result := FVariant;
end;

function TS4YCustomTag.GetKindTextColor(const AAccentColor: TAlphaColor): TAlphaColor;
begin
  // The text color of the style for the kind; without one, the color of the kind made darker
  Result := FStyleKindTextColors[FKind];

  if Result = TAlphaColors.Null then
    Result := ShadeOf(AAccentColor, C_TEXT_SHADE);
end;

function TS4YCustomTag.GetImageIndex: TImageIndex;
begin
  Result := FImageLink.ImageIndex;
end;

function TS4YCustomTag.GetImageList: TBaseImageList;
begin
  Result := FImageLink.Images;
end;

function TS4YCustomTag.GetImages: TCustomImageList;
begin
  Result := TCustomImageList(FImageLink.Images);
end;

function TS4YCustomTag.GetState: TS4YTagState;
begin
  Result := tgtNormal;
end;

function TS4YCustomTag.GetStyleObject: TFmxObject;
begin
  // The style named by StyleLookup or, when it is empty, the one named after the class, in the
  // style book or in the active style; never the style of the parent class.
  Result := LookupStyleObject(Self, GetStyleContext, Scene, StyleLookup, GetDefaultStyleLookupName, '', True);

  // The style linked into the package is used when no other style is found.
  if not Assigned(Result) then
    Result := TStyleStreaming.LoadFromResource(HInstance, GetDefaultStyleLookupName, RT_RCDATA);
end;

function TS4YCustomTag.HasPicture: Boolean;
var
  LImages: TCustomImageList;
begin
  if not FBitmap.IsEmpty then
    Exit(True);

  LImages := GetImages;
  Result := Assigned(LImages) and LImages.BitmapExists(FImageLink.ImageIndex);
end;

procedure TS4YCustomTag.ImagesChanged;
begin
  UpdateSize;
  UpdateParts;
end;

function TS4YCustomTag.IsCheckMarkShown: Boolean;
begin
  Result := False;
end;

function TS4YCustomTag.IsFocusBorderShown: Boolean;
begin
  Result := False;
end;

procedure TS4YCustomTag.Loaded;
begin
  inherited;

  UpdateSize;
  UpdateParts;
end;

function TS4YCustomTag.MaxWidthStored: Boolean;
begin
  Result := FMaxWidth <> 0;
end;

function TS4YCustomTag.MeasureTextWidth(const AFontSize: Single): Single;
begin
  Result := 0;

  if (FText = '') or not Assigned(FTextLayout) then
    Exit;

  FTextLayout.BeginUpdate;
  try
    if Assigned(FStyleText) then
      FTextLayout.Font.Assign(FStyleText.TextSettings.Font);

    FTextLayout.Font.Size := AFontSize;
    FTextLayout.Text := FText;
    FTextLayout.TopLeft := TPointF.Create(0, 0);
    FTextLayout.MaxSize := TPointF.Create(C_MEASURE_SIZE, C_MEASURE_SIZE);
    FTextLayout.WordWrap := False;
    FTextLayout.Trimming := TTextTrimming.None;
  finally
    FTextLayout.EndUpdate;
  end;

  Result := FTextLayout.TextWidth;
end;

procedure TS4YCustomTag.SetAutoSize(const Value: Boolean);
begin
  if FAutoSize = Value then
    Exit;

  FAutoSize := Value;
  UpdateSize;
end;

procedure TS4YCustomTag.SetBackgroundColor(const Value: TAlphaColor);
begin
  if FBackgroundColor = Value then
    Exit;

  FBackgroundColor := Value;
  UpdateParts;
end;

procedure TS4YCustomTag.SetBitmap(const Value: TBitmap);
begin
  FBitmap.Assign(Value);
end;

procedure TS4YCustomTag.SetBorderColor(const Value: TAlphaColor);
begin
  if FBorderColor = Value then
    Exit;

  FBorderColor := Value;
  UpdateParts;
end;

procedure TS4YCustomTag.SetClosable(const Value: Boolean);
begin
  if FClosable = Value then
    Exit;

  FClosable := Value;
  UpdateSize;
  UpdateParts;
end;

procedure TS4YCustomTag.SetCornerRadius(const Value: Single);
begin
  if SameValue(FCornerRadius, Value) then
    Exit;

  FCornerRadius := Value;
  UpdateParts;
end;

procedure TS4YCustomTag.SetImageIndex(const Value: TImageIndex);
begin
  FImageLink.ImageIndex := Value;
end;

procedure TS4YCustomTag.SetImageList(const Value: TBaseImageList);
begin
  FImageLink.Images := Value;
end;

procedure TS4YCustomTag.SetImageRound(const Value: Boolean);
begin
  if FImageRound = Value then
    Exit;

  FImageRound := Value;
  UpdateParts;
end;

procedure TS4YCustomTag.SetImages(const Value: TCustomImageList);
begin
  FImageLink.Images := Value;
end;

procedure TS4YCustomTag.SetKind(const Value: TS4YTagKind);
begin
  if FKind = Value then
    Exit;

  FKind := Value;
  UpdateParts;
end;

procedure TS4YCustomTag.SetMaxWidth(const Value: Single);
begin
  if SameValue(FMaxWidth, Value) then
    Exit;

  FMaxWidth := System.Math.Max(0, Value);
  UpdateSize;
  UpdateParts;
end;

procedure TS4YCustomTag.SetName(const NewName: TComponentName);
var
  LOldName: string;
begin
  LOldName := Name;
  inherited;

  // As a label does: a control dropped on a form shows its name until a text is written.
  if (csDesigning in ComponentState) and not (csLoading in ComponentState) and
    ((FText = '') or (FText = LOldName)) then
    Text := NewName;
end;

procedure TS4YCustomTag.SetShape(const Value: TS4YTagShape);
begin
  if FShape = Value then
    Exit;

  FShape := Value;
  UpdateParts;
end;

procedure TS4YCustomTag.SetSizePreset(const Value: TS4YTagSizePreset);
begin
  if FSizePreset = Value then
    Exit;

  FSizePreset := Value;
  FCoverInvalid := True;
  UpdateSize;
  UpdateParts;
end;

procedure TS4YCustomTag.SetText(const Value: string);
begin
  if FText = Value then
    Exit;

  FText := Value;
  UpdateSize;
  UpdateParts;
end;

procedure TS4YCustomTag.SetTextColor(const Value: TAlphaColor);
begin
  if FTextColor = Value then
    Exit;

  FTextColor := Value;
  UpdateParts;
end;

procedure TS4YCustomTag.SetVariant(const Value: TS4YTagVariant);
begin
  if FVariant = Value then
    Exit;

  FVariant := Value;
  UpdateParts;
end;

procedure TS4YCustomTag.StyleResourceFreed(AObject: TObject);
begin
  // Reached only when a part of the style is freed outside FreeStyle.
  if AObject = FStyleClose then
    FStyleClose := nil;

  if AObject = FStyleIcon then
    FStyleIcon := nil;
end;

procedure TS4YCustomTag.UpdateCoverBitmap(const ASide: Single);
var
  LPixels: Integer;
  LScale: Single;
  LSide: Single;
  LSourceRect: TRectF;
begin
  if Assigned(Scene) then
    LScale := Scene.GetSceneScale
  else
    LScale := 1;

  LPixels := Ceil(ASide * LScale);

  if LPixels < 1 then
    Exit;

  // The picture is prepared again only when it or the size changes.
  if not FCoverInvalid and Assigned(FCoverBitmap) and (FCoverBitmap.Width = LPixels) then
    Exit;

  FCoverInvalid := False;

  if FBitmap.IsEmpty then
  begin
    FreeAndNil(FCoverBitmap);
    Exit;
  end;

  // The largest square of the picture, in its middle: the picture fills the square and what goes
  // beyond it is cut on both sides.
  LSide := System.Math.Min(FBitmap.Width, FBitmap.Height);
  LSourceRect := TRectF.Create(0, 0, LSide, LSide);
  LSourceRect.Offset((FBitmap.Width - LSide) / 2, (FBitmap.Height - LSide) / 2);

  if not Assigned(FCoverBitmap) then
    FCoverBitmap := TBitmap.Create;

  FCoverBitmap.SetSize(LPixels, LPixels);

  if FCoverBitmap.Canvas.BeginScene then
  begin
    try
      FCoverBitmap.Canvas.Clear(TAlphaColors.Null);
      FCoverBitmap.Canvas.DrawBitmap(FBitmap, LSourceRect, TRectF.Create(0, 0, LPixels, LPixels), 1, False);
    finally
      FCoverBitmap.Canvas.EndScene;
    end;
  end;
end;

procedure TS4YCustomTag.UpdateParts;
var
  LBackgroundRadius: Single;
  LBackgroundRect: TRectF;
  LBorderThickness: Single;
  LCloseLeft: Single;
  LExpansion: Single;
  LFillColor: TAlphaColor;
  LHasPicture: Boolean;
  LIconRect: TRectF;
  LImages: TCustomImageList;
  LLeft: Single;
  LMargin: Single;
  LMetrics: TTagMetrics;
  LRight: Single;
  LStrokeColor: TAlphaColor;
  LTextColor: TAlphaColor;
  LUseGlyph: Boolean;
begin
  if not Assigned(ResourceControl) or (csLoading in ComponentState) then
    Exit;

  LMetrics := CalculateMetrics;
  CalculateColors(LFillColor, LTextColor, LStrokeColor);
  LHasPicture := not FBitmap.IsEmpty;
  LImages := GetImages;
  LUseGlyph := not LHasPicture and Assigned(FStyleIcon) and Assigned(LImages) and
    LImages.BitmapExists(FImageLink.ImageIndex);

  if IsFocusBorderShown then
  begin
    LStrokeColor := GetAccentColor;
    LBorderThickness := C_FOCUS_THICKNESS;
  end
  else
    LBorderThickness := C_BORDER_THICKNESS;

  if Enabled then
    ResourceControl.Opacity := 1
  else
    ResourceControl.Opacity := C_DISABLED_OPACITY;

  // The background fills the control; its border is drawn half inside and half outside the
  // rectangle, so the rectangle is made smaller to keep the border inside the control.
  LBackgroundRect := TRectF.Create(0, 0, Width, Height);
  LBackgroundRect.Inflate(-LBorderThickness / 2, -LBorderThickness / 2);

  case FShape of
    tgsPill:
      LBackgroundRadius := Height / 2;
    tgsRounded:
      LBackgroundRadius := System.Math.Min(FCornerRadius, Height / 2);
  else
    LBackgroundRadius := 0;
  end;

  if Assigned(FStyleBackground) then
  begin
    FStyleBackground.SetBounds(LBackgroundRect.Left, LBackgroundRect.Top, LBackgroundRect.Width,
      LBackgroundRect.Height);
    FStyleBackground.Fill.Kind := TBrushKind.Solid;
    FStyleBackground.Fill.Color := LFillColor;
    ApplyRadius(FStyleBackground, LBackgroundRadius);

    if LStrokeColor = TAlphaColors.Null then
      FStyleBackground.Stroke.Kind := TBrushKind.None
    else
    begin
      FStyleBackground.Stroke.Kind := TBrushKind.Solid;
      FStyleBackground.Stroke.Color := LStrokeColor;
      FStyleBackground.Stroke.Thickness := LBorderThickness;
    end;
  end;

  // The icon, the picture or the check mark, in the box on the left.
  LLeft := LMetrics.Padding;
  LIconRect := TRectF.Create(LLeft, (Height - LMetrics.IconSize) / 2, LLeft + LMetrics.IconSize,
    (Height + LMetrics.IconSize) / 2);

  if Assigned(FStyleCheck) then
  begin
    FStyleCheck.Visible := IsCheckMarkShown;
    LMargin := LMetrics.IconSize * C_CHECK_MARGIN_FACTOR;
    FStyleCheck.SetBounds(LIconRect.Left + LMargin, LIconRect.Top + LMargin,
      LMetrics.IconSize - 2 * LMargin, LMetrics.IconSize - 2 * LMargin);
    FStyleCheck.Fill.Color := LTextColor;
  end;

  if Assigned(FStyleImage) then
  begin
    FStyleImage.Visible := LHasPicture and not IsCheckMarkShown;
    FStyleImage.SetBounds(LIconRect.Left, LIconRect.Top, LIconRect.Width, LIconRect.Height);

    if FImageRound then
      ApplyRadius(FStyleImage, LMetrics.IconSize / 2)
    else
      ApplyRadius(FStyleImage, LMetrics.IconSize * C_ICON_FACTOR / 2);

    if FStyleImage.Visible then
    begin
      UpdateCoverBitmap(LMetrics.IconSize);

      if Assigned(FCoverBitmap) then
      begin
        FStyleImage.Fill.Kind := TBrushKind.Bitmap;
        FStyleImage.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
        FStyleImage.Fill.Bitmap.Bitmap.Assign(FCoverBitmap);
      end;
    end
    else
    begin
      // The copy of the picture is not kept while it is not shown.
      FreeAndNil(FCoverBitmap);
      FCoverInvalid := True;
      FStyleImage.Fill.Bitmap.Bitmap.SetSize(0, 0);
    end;
  end;

  if Assigned(FStyleIcon) then
  begin
    FStyleIcon.Images := LImages;
    FStyleIcon.ImageIndex := FImageLink.ImageIndex;
    FStyleIcon.Visible := LUseGlyph and not IsCheckMarkShown;
    FStyleIcon.SetBounds(LIconRect.Left, LIconRect.Top, LIconRect.Width, LIconRect.Height);
  end;

  if IsCheckMarkShown or LHasPicture or LUseGlyph then
    LLeft := LLeft + LMetrics.IconSize + LMetrics.Gap;

  // The close button on the right.
  LRight := Width - LMetrics.Padding;

  if Assigned(FStyleClose) then
  begin
    FStyleClose.Visible := FClosable;

    if FClosable then
    begin
      LCloseLeft := Width - LMetrics.ClosePadding - LMetrics.CloseSize;
      LRight := LCloseLeft - LMetrics.Gap;
      FStyleClose.SetBounds(LCloseLeft, (Height - LMetrics.CloseSize) / 2, LMetrics.CloseSize, LMetrics.CloseSize);
      FStyleClose.Stroke.Kind := TBrushKind.None;
      FStyleClose.Fill.Kind := TBrushKind.Solid;

      if FCloseHovered and not IsMobilePlatform then
        FStyleClose.Fill.Color := WithAlpha(LTextColor, C_CLOSE_HOVER_ALPHA)
      else
        FStyleClose.Fill.Color := TAlphaColors.Null;

      // A finger needs a larger area than the button drawn.
      if IsMobilePlatform then
      begin
        LExpansion := System.Math.Max(0, (C_MIN_TOUCH_SIZE - LMetrics.CloseSize) / 2);
        FStyleClose.TouchTargetExpansion.Rect := TRectF.Create(LExpansion, LExpansion, LExpansion, LExpansion);
      end;

      if Assigned(FStyleCloseIcon) then
      begin
        LMargin := LMetrics.CloseSize * C_CLOSE_ICON_MARGIN_FACTOR;
        FStyleCloseIcon.SetBounds(LMargin, LMargin, LMetrics.CloseSize - 2 * LMargin,
          LMetrics.CloseSize - 2 * LMargin);
        FStyleCloseIcon.Fill.Color := LTextColor;
      end;
    end;
  end
  else if FClosable then
    LRight := Width - LMetrics.Padding - LMetrics.CloseSize - LMetrics.Gap;

  if Assigned(FStyleText) then
  begin
    FStyleText.Visible := FText <> '';
    FStyleText.SetBounds(LLeft, 0, System.Math.Max(0, LRight - LLeft), Height);
    FStyleText.Text := FText;
    FStyleText.TextSettings.Font.Size := LMetrics.FontSize;
    FStyleText.TextSettings.FontColor := LTextColor;
  end;

  Repaint;
end;

procedure TS4YCustomTag.UpdateSize;
var
  LAlignRoot: IAlignRoot;
  LOldHeight: Single;
  LOldWidth: Single;
  LWidth: Single;
begin
  // Nothing to do while the control is being created or loaded: Loaded sets the size.
  if not Assigned(FTextLayout) or (csLoading in ComponentState) then
    Exit;

  if FAutoSize then
    LWidth := CalculateContentWidth
  else
    LWidth := Width;

  LOldWidth := Width;
  LOldHeight := Height;
  SetBounds(Position.X, Position.Y, LWidth, C_TAG_PRESET_HEIGHTS[FSizePreset]);

  // A parent that places its children, such as a flow layout, is told only about the controls
  // that have an Align: the others have to ask it to place them again, or they overlap.
  if (not SameValue(LOldWidth, Width) or not SameValue(LOldHeight, Height)) and
    Supports(Parent, IAlignRoot, LAlignRoot) then
    LAlignRoot.Realign;
end;

end.
