unit Soft4You.FMX.Controls.Avatar;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YAvatar - picture or initials of a person, with status dot and edit button
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
  FMX.MediaLibrary,
  Soft4You.FMX.Controls.Avatar.Types;

type
  /// <summary>
  /// Settings of the ring drawn around a TS4YAvatar.
  /// </summary>
  TS4YAvatarRing = class(TPersistent)
  public const
    /// <summary>Default value of Gap, in pixels.</summary>
    C_DEFAULT_GAP: Single = 2;
    /// <summary>Default value of Thickness, in pixels.</summary>
    C_DEFAULT_THICKNESS: Single = 2;
  private
    FColor: TAlphaColor;
    FGap: Single;
    FThickness: Single;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    procedure DoChange;
    function GapStored: Boolean;
    procedure SetColor(const Value: TAlphaColor);
    procedure SetGap(const Value: Single);
    procedure SetThickness(const Value: Single);
    procedure SetVisible(const Value: Boolean);
    function ThicknessStored: Boolean;
  public
    /// <summary>Creates the settings with the default values: no ring.</summary>
    constructor Create;

    /// <summary>Copies the settings of another TS4YAvatarRing.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when one of the settings changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Color of the ring. The default, Null, takes the color of the style.</summary>
    property Color: TAlphaColor read FColor write SetColor default TAlphaColors.Null;
    /// <summary>Space between the ring and the picture, in pixels. The default is 2.</summary>
    property Gap: Single read FGap write SetGap stored GapStored nodefault;
    /// <summary>Thickness of the ring, in pixels. The default is 2.</summary>
    property Thickness: Single read FThickness write SetThickness stored ThicknessStored nodefault;
    /// <summary>True draws the ring. The default is False.</summary>
    /// <remarks>The ring is drawn inside the bounds of the avatar: the picture becomes smaller by Thickness plus Gap on every side.</remarks>
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

  /// <summary>
  /// Settings of the edit button of a TS4YAvatar, the small round button on its edge that lets the user change the picture.
  /// </summary>
  TS4YAvatarEditButton = class(TPersistent)
  public const
    /// <summary>Default value of Position.</summary>
    C_DEFAULT_POSITION = avcBottomRight;
    /// <summary>Default value of SizeFactor: a third of the avatar.</summary>
    C_DEFAULT_SIZE_FACTOR: Single = 0.33;
    /// <summary>Default value of Visibility.</summary>
    C_DEFAULT_VISIBILITY = ebvNever;
    /// <summary>Smallest value of SizeFactor.</summary>
    C_MIN_SIZE_FACTOR: Single = 0.1;
    /// <summary>Largest value of SizeFactor.</summary>
    C_MAX_SIZE_FACTOR: Single = 0.6;
  private
    FBackgroundColor: TAlphaColor;
    FIconColor: TAlphaColor;
    FImageIndex: TImageIndex;
    FPosition: TS4YAvatarCorner;
    FSizeFactor: Single;
    FVisibility: TS4YAvatarEditButtonVisibility;
    FOnChange: TNotifyEvent;
    procedure DoChange;
    procedure SetBackgroundColor(const Value: TAlphaColor);
    procedure SetIconColor(const Value: TAlphaColor);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetPosition(const Value: TS4YAvatarCorner);
    procedure SetSizeFactor(const Value: Single);
    procedure SetVisibility(const Value: TS4YAvatarEditButtonVisibility);
    function SizeFactorStored: Boolean;
  public
    /// <summary>Creates the settings with the default values: a hidden button.</summary>
    constructor Create;

    /// <summary>Copies the settings of another TS4YAvatarEditButton.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when one of the settings changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Color of the button. The default, Null, takes the color of the style.</summary>
    property BackgroundColor: TAlphaColor read FBackgroundColor write SetBackgroundColor default TAlphaColors.Null;
    /// <summary>Color of the camera icon of the style. The default, Null, takes the color of the style. It has no effect on an image of Images.</summary>
    property IconColor: TAlphaColor read FIconColor write SetIconColor default TAlphaColors.Null;
    /// <summary>Index in the Images of the avatar of the icon of the button. The default, -1, shows the camera icon of the style.</summary>
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    /// <summary>Corner of the avatar where the button is placed. The default is the bottom right one.</summary>
    /// <remarks>When the status dot is in the same corner, the button covers it while it is shown.</remarks>
    property Position: TS4YAvatarCorner read FPosition write SetPosition default C_DEFAULT_POSITION;
    /// <summary>Size of the button as a fraction of the size of the avatar, from 0.1 to 0.6. The default is 0.33.</summary>
    /// <remarks>On Android and iOS the button reacts to the finger in an area of at least 44 x 44 pixels, even when it is drawn smaller.</remarks>
    property SizeFactor: Single read FSizeFactor write SetSizeFactor stored SizeFactorStored nodefault;
    /// <summary>When the button is shown: never (the default), always, or while the mouse is over the avatar.</summary>
    /// <remarks>On Android and iOS, which have no mouse, ebvOnHover shows the button always. In the form designer the button is shown with ebvOnHover too.</remarks>
    property Visibility: TS4YAvatarEditButtonVisibility read FVisibility write SetVisibility default C_DEFAULT_VISIBILITY;
  end;

  /// <summary>
  /// The picture of a person, or the initials of the name on a colored background, with an optional ring, status dot and edit button.
  /// </summary>
  /// <remarks>
  /// The avatar shows Bitmap when it has a picture, else the image ImageIndex of Images, else the initials of Text (or Initials) on a color chosen from the text, so that the same name has always the same color; without picture and text it shows the outline of a person.
  /// The picture fills the shape keeping its proportions: what goes beyond the shape is cut, in the same way on every side.
  /// The edit button, shown according to EditButton.Visibility, fires OnEditClick and executes EditAction: with a TTakePhotoFromCameraAction or a TTakePhotoFromLibraryAction the photo taken becomes the Bitmap of the avatar.
  /// A TS4YBadge placed on the avatar, with Position.AutoPosition at one of its corners, shows a counter of notifications.
  /// The style is S4YAvatarStyle; see the documentation for its parts.
  /// </remarks>
  TS4YAvatar = class(TStyledControl, IGlyph, IFreeNotification)
  public const
    /// <summary>Default value of CornerRadius, in pixels.</summary>
    C_DEFAULT_CORNER_RADIUS: Single = 8;
    /// <summary>Default value of Shape.</summary>
    C_DEFAULT_SHAPE = avsCircle;
    /// <summary>Default value of SizePreset.</summary>
    C_DEFAULT_SIZE_PRESET = avzCustom;
    /// <summary>Default value of StatusPosition.</summary>
    C_DEFAULT_STATUS_POSITION = avcBottomRight;
  private
    FBackgroundColor: TAlphaColor;
    FBitmap: TBitmap;
    FCornerRadius: Single;
    FCoverBitmap: TBitmap;
    FCoverInvalid: Boolean;
    FEditAction: TBasicAction;
    FEditButton: TS4YAvatarEditButton;
    FImageLink: TGlyphImageLink;
    FInitials: string;
    FInitialsColor: TAlphaColor;
    FPhotoRequested: Boolean;
    FPreviousDidFinishTaking: TOnDidFinishTaking;
    FRing: TS4YAvatarRing;
    FShape: TS4YAvatarShape;
    FSizePreset: TS4YAvatarSizePreset;
    FStatus: TS4YAvatarStatus;
    FStatusColor: TAlphaColor;
    FStatusPosition: TS4YAvatarCorner;
    FStyleBackground: TShape;
    FStyleBackgroundColor: TAlphaColor;
    FStyleEditButton: TControl;
    FStyleEditButtonColor: TAlphaColor;
    FStyleEditGlyph: TGlyph;
    FStyleEditIcon: TShape;
    FStyleEditIconColor: TAlphaColor;
    FStyleImage: TRectangle;
    FStylePlaceholder: TControl;
    FStyleRing: TRectangle;
    FStyleRingColor: TAlphaColor;
    FStyleStatus: TShape;
    FStyleStatusColors: array[TS4YAvatarStatus] of TAlphaColor;
    FStyleText: TText;
    FText: string;
    FOnChange: TNotifyEvent;
    FOnEditClick: TNotifyEvent;
    procedure ActionDidFinishTaking(AImage: TBitmap);
    procedure ApplyRadius(const APart: TControl; const ARadius: Single);
    function BackgroundColorOfText: TAlphaColor;
    procedure BitmapChanged(Sender: TObject);
    function CalculateCornerCenter(const ACorner: TS4YAvatarCorner; const ADiameter: Single): TPointF;
    function CalculateImageListSize(const AImages: TCustomImageList; const APixelWidth, APixelHeight: Integer): TSizeF;
    function CalculateInnerRadius: Single;
    function CalculateOuterRect: TRectF;
    function CornerRadiusStored: Boolean;
    procedure EditButtonClick(Sender: TObject);
    procedure EditButtonMouseChanged(Sender: TObject);
    procedure FindStyleColor(const AStyleName: string; const ADefaultColor: TAlphaColor; out AColor: TAlphaColor);
    function GetImageIndex: TImageIndex;
    function GetImageList: TBaseImageList;
    function GetImages: TCustomImageList;
    procedure HookEditAction;
    function IsEditButtonShown: Boolean;
    procedure SetBackgroundColor(const Value: TAlphaColor);
    procedure SetBitmap(const Value: TBitmap);
    procedure SetCornerRadius(const Value: Single);
    procedure SetEditAction(const Value: TBasicAction);
    procedure SetEditButton(const Value: TS4YAvatarEditButton);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageList(const Value: TBaseImageList);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetInitials(const Value: string);
    procedure SetInitialsColor(const Value: TAlphaColor);
    procedure SetRing(const Value: TS4YAvatarRing);
    procedure SetShape(const Value: TS4YAvatarShape);
    procedure SetSizePreset(const Value: TS4YAvatarSizePreset);
    procedure SetStatus(const Value: TS4YAvatarStatus);
    procedure SetStatusColor(const Value: TAlphaColor);
    procedure SetStatusPosition(const Value: TS4YAvatarCorner);
    procedure SetText(const Value: string);
    procedure SettingsChanged(Sender: TObject);
    procedure StyleResourceFreed(AObject: TObject);
    procedure UnhookEditAction;
    procedure UpdateCoverBitmap(const ATargetSize: TSizeF);
    procedure UpdateEditButton(const AOuterRect: TRectF);
    procedure UpdateStatus;
    { IGlyph }
    function IGlyph.GetImages = GetImageList;
    procedure IGlyph.SetImages = SetImageList;
    { IFreeNotification }
    procedure IFreeNotification.FreeNotification = StyleResourceFreed;
  protected
    /// <summary>Finds the parts of the style and applies the settings of the avatar to them.</summary>
    procedure ApplyStyle; override;
    /// <summary>Fires OnChange.</summary>
    procedure DoChange; virtual;
    /// <summary>Fires OnEditClick and executes EditAction.</summary>
    procedure DoEditClick; virtual;
    /// <summary>Shows the edit button when its Visibility is ebvOnHover.</summary>
    procedure DoMouseEnter; override;
    /// <summary>Hides the edit button when its Visibility is ebvOnHover.</summary>
    procedure DoMouseLeave; override;
    /// <summary>Places the parts of the style after the size of the control changes.</summary>
    procedure DoRealign; override;
    /// <summary>Keeps the size of SizePreset when it is not avzCustom.</summary>
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
      var ALastWidth, ALastHeight: Single): Boolean; override;
    /// <summary>Releases the parts of the style found by ApplyStyle.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control: 40 x 40.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns the style of the avatar: the one named by StyleLookup or, when it is empty or not found, the one named S4YAvatarStyle in the style book or in the active style; else the default style linked into the package.</summary>
    function GetStyleObject: TFmxObject; override;
    /// <summary>Called when the image list or the image index change: it refreshes the picture.</summary>
    procedure ImagesChanged; virtual;
    /// <summary>Connects EditAction after loading.</summary>
    procedure Loaded; override;
    /// <summary>Forgets EditAction and Images when they are freed.</summary>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// <summary>Places the parts of the style and gives them the settings of the avatar.</summary>
    procedure UpdateParts; virtual;
  public
    /// <summary>Returns the initials of AName: the first letter of the first word and of the last one, in upper case; one letter for a single word, empty for an empty name.</summary>
    class function InitialsOf(const AName: string): string;

    /// <summary>Creates the avatar with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>Returns the initials shown: Initials when it is not empty, else the initials of Text.</summary>
    function GetDisplayedInitials: string;
    /// <summary>Returns True when the avatar shows a picture: Bitmap, or the image ImageIndex of Images.</summary>
    function HasPicture: Boolean;
  published
    property Align;
    property Anchors;
    /// <summary>Color of the background of the initials. The default, Null, chooses a color from Text, always the same for the same text.</summary>
    property BackgroundColor: TAlphaColor read FBackgroundColor write SetBackgroundColor default TAlphaColors.Null;
    /// <summary>Picture of the person. When it is empty, the avatar shows the image ImageIndex of Images or the initials.</summary>
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    /// <summary>Radius of the corners of the picture when Shape is avsRounded, in pixels. The default is 8.</summary>
    property CornerRadius: Single read FCornerRadius write SetCornerRadius stored CornerRadiusStored nodefault;
    property Cursor;
    /// <summary>
    /// Action executed by the edit button.
    /// </summary>
    /// <remarks>
    /// With a TTakePhotoFromCameraAction or a TTakePhotoFromLibraryAction, the photo taken becomes the Bitmap of the avatar and OnChange fires; the OnDidFinishTaking event of the action still fires. An action of this kind is meant for one avatar: the avatar sets its own handler of OnDidFinishTaking, which calls the one the action had, so the handler of the action must not be changed by code later.
    /// These actions are not supported on Windows: there OnEditClick can open a TOpenDialog.
    /// </remarks>
    property EditAction: TBasicAction read FEditAction write SetEditAction;
    /// <summary>Settings of the edit button, the small round button on the edge of the avatar.</summary>
    property EditButton: TS4YAvatarEditButton read FEditButton write SetEditButton;
    property Enabled;
    property Height;
    property HitTest;
    /// <summary>Index in Images of the picture shown when Bitmap is empty. The default is -1, no image.</summary>
    property ImageIndex: TImageIndex read GetImageIndex write SetImageIndex default -1;
    /// <summary>Image list of the picture (ImageIndex) and of the icon of the edit button (EditButton.ImageIndex).</summary>
    property Images: TCustomImageList read GetImages write SetImages;
    /// <summary>Initials shown without a picture. The default, empty, takes them from Text.</summary>
    property Initials: string read FInitials write SetInitials;
    /// <summary>Color of the initials. The default, Null, chooses white or dark, whichever is easier to read on the background.</summary>
    property InitialsColor: TAlphaColor read FInitialsColor write SetInitialsColor default TAlphaColors.Null;
    property Margins;
    property Opacity;
    property PopupMenu;
    property Position;
    /// <summary>Settings of the ring drawn around the avatar.</summary>
    property Ring: TS4YAvatarRing read FRing write SetRing;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    /// <summary>Shape of the avatar: circle (the default), square with rounded corners, or square.</summary>
    property Shape: TS4YAvatarShape read FShape write SetShape default C_DEFAULT_SHAPE;
    property Size;
    /// <summary>
    /// Size of the avatar chosen among the ready ones: small (32 pixels), medium (40), large (56) or extra large (80). The default, avzCustom, keeps Width and Height.
    /// </summary>
    /// <remarks>
    /// With a value other than avzCustom, Width and Height stay those of the size chosen.
    /// </remarks>
    property SizePreset: TS4YAvatarSizePreset read FSizePreset write SetSizePreset default C_DEFAULT_SIZE_PRESET;
    /// <summary>State of the person, shown by a dot of its color. The default, avtNone, shows no dot.</summary>
    property Status: TS4YAvatarStatus read FStatus write SetStatus default avtNone;
    /// <summary>Color of the status dot. The default, Null, takes the color of the state from the style.</summary>
    property StatusColor: TAlphaColor read FStatusColor write SetStatusColor default TAlphaColors.Null;
    /// <summary>Corner of the avatar where the status dot is placed. The default is the bottom right one.</summary>
    property StatusPosition: TS4YAvatarCorner read FStatusPosition write SetStatusPosition default C_DEFAULT_STATUS_POSITION;
    property StyleLookup;
    property TabOrder;
    property TabStop;
    /// <summary>Name of the person, for example Mario Rossi: it gives the initials and the color of the background.</summary>
    property Text: string read FText write SetText;
    property Visible;
    property Width;

    /// <summary>Fires when the picture changes because of EditAction.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClick;
    property OnDblClick;
    /// <summary>Fires when the user clicks or taps the edit button.</summary>
    property OnEditClick: TNotifyEvent read FOnEditClick write FOnEditClick;
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
  System.Character,
  FMX.Styles,
  FMX.MediaLibrary.Actions;

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
  C_STYLE_AWAY_COLOR = 'awaycolor';
  C_STYLE_BACKGROUND = 'background';
  C_STYLE_BUSY_COLOR = 'busycolor';
  C_STYLE_EDIT_BUTTON = 'editbutton';
  C_STYLE_EDIT_GLYPH = 'editglyph';
  C_STYLE_EDIT_ICON = 'editicon';
  C_STYLE_IMAGE = 'image';
  C_STYLE_OFFLINE_COLOR = 'offlinecolor';
  C_STYLE_ONLINE_COLOR = 'onlinecolor';
  C_STYLE_PLACEHOLDER = 'placeholder';
  C_STYLE_RING = 'ring';
  C_STYLE_RING_COLOR = 'ringcolor';
  C_STYLE_STATUS = 'status';
  C_STYLE_TEXT = 'text';

  // Colors used when the style does not give them.
  C_FALLBACK_AWAY_COLOR: TAlphaColor = $FFFDD835;
  C_FALLBACK_BACKGROUND_COLOR: TAlphaColor = $FFBDBDBD;
  C_FALLBACK_BUSY_COLOR: TAlphaColor = $FFE53935;
  C_FALLBACK_EDIT_BUTTON_COLOR: TAlphaColor = $FF424242;
  C_FALLBACK_EDIT_ICON_COLOR: TAlphaColor = $FFFFFFFF;
  C_FALLBACK_OFFLINE_COLOR: TAlphaColor = $FF9E9E9E;
  C_FALLBACK_ONLINE_COLOR: TAlphaColor = $FF43A047;
  C_FALLBACK_RING_COLOR: TAlphaColor = $FF1E88E5;

  // Colors of the background of the initials, chosen from the text: all of them can hold white
  // initials.
  C_INITIALS_BACKGROUND_COLORS: array[0..11] of TAlphaColor = (
    $FFE53935, $FFD81B60, $FF8E24AA, $FF5E35B1, $FF3949AB, $FF1E88E5,
    $FF0277BD, $FF00897B, $FF2E7D32, $FF558B2F, $FFF4511E, $FF6D4C41);

  // Colors of the initials chosen by the luminance of the background.
  C_DARK_INITIALS_COLOR: TAlphaColor = $FF212121;
  C_LIGHT_INITIALS_COLOR: TAlphaColor = $FFFFFFFF;
  // Relative luminance above which the background is light and the initials are dark.
  C_LIGHT_BACKGROUND_LUMINANCE = 0.5;

  // Size of the initials as a fraction of the height of the picture.
  C_INITIALS_FONT_FACTOR = 0.4;
  // Smallest size of the font of the initials.
  C_MIN_INITIALS_FONT_SIZE = 6;
  // Space around the outline of a person, as a fraction of the size of the picture.
  C_PLACEHOLDER_MARGIN_FACTOR = 0.2;
  // Space around the icon of the edit button, as a fraction of the size of the button.
  C_EDIT_ICON_MARGIN_FACTOR = 0.22;
  // Diameter of the status dot as a fraction of the size of the avatar, and its smallest diameter.
  C_STATUS_SIZE_FACTOR = 0.25;
  C_MIN_STATUS_SIZE = 8;
  // Thickness of the border of the status dot and of the edit button, as a fraction of their
  // diameter, so that the border does not cover a small dot.
  C_STATUS_BORDER_FACTOR = 0.14;
  C_EDIT_BUTTON_BORDER_FACTOR = 0.08;
  // Smallest area that reacts to a finger on Android and iOS, in pixels.
  C_MIN_TOUCH_SIZE = 44;
  // Modulus of the hash of the text, small enough for the arithmetic of Int64.
  C_HASH_MODULUS = 1000003;
  // Multiplier of the hash of the text.
  C_HASH_MULTIPLIER = 31;

  C_SIZE_PRESET_SIZES: array[TS4YAvatarSizePreset] of Single = (0, 32, 40, 56, 80);

  // Size of a new avatar.
  C_DEFAULT_SIZE = 40;

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

{ TS4YAvatarRing }

constructor TS4YAvatarRing.Create;
begin
  inherited Create;

  FColor := TAlphaColors.Null;
  FGap := C_DEFAULT_GAP;
  FThickness := C_DEFAULT_THICKNESS;
  FVisible := False;
end;

procedure TS4YAvatarRing.Assign(Source: TPersistent);
var
  LSource: TS4YAvatarRing;
begin
  if not (Source is TS4YAvatarRing) then
  begin
    inherited;
    Exit;
  end;

  LSource := TS4YAvatarRing(Source);
  FColor := LSource.Color;
  FGap := LSource.Gap;
  FThickness := LSource.Thickness;
  FVisible := LSource.Visible;
  DoChange;
end;

procedure TS4YAvatarRing.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TS4YAvatarRing.GapStored: Boolean;
begin
  Result := not SameValue(FGap, C_DEFAULT_GAP);
end;

procedure TS4YAvatarRing.SetColor(const Value: TAlphaColor);
begin
  if FColor = Value then
    Exit;

  FColor := Value;
  DoChange;
end;

procedure TS4YAvatarRing.SetGap(const Value: Single);
begin
  if SameValue(FGap, System.Math.Max(0, Value)) then
    Exit;

  FGap := System.Math.Max(0, Value);
  DoChange;
end;

procedure TS4YAvatarRing.SetThickness(const Value: Single);
begin
  if SameValue(FThickness, System.Math.Max(0, Value)) then
    Exit;

  FThickness := System.Math.Max(0, Value);
  DoChange;
end;

procedure TS4YAvatarRing.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;
  DoChange;
end;

function TS4YAvatarRing.ThicknessStored: Boolean;
begin
  Result := not SameValue(FThickness, C_DEFAULT_THICKNESS);
end;

{ TS4YAvatarEditButton }

constructor TS4YAvatarEditButton.Create;
begin
  inherited Create;

  FBackgroundColor := TAlphaColors.Null;
  FIconColor := TAlphaColors.Null;
  FImageIndex := -1;
  FPosition := C_DEFAULT_POSITION;
  FSizeFactor := C_DEFAULT_SIZE_FACTOR;
  FVisibility := C_DEFAULT_VISIBILITY;
end;

procedure TS4YAvatarEditButton.Assign(Source: TPersistent);
var
  LSource: TS4YAvatarEditButton;
begin
  if not (Source is TS4YAvatarEditButton) then
  begin
    inherited;
    Exit;
  end;

  LSource := TS4YAvatarEditButton(Source);
  FBackgroundColor := LSource.BackgroundColor;
  FIconColor := LSource.IconColor;
  FImageIndex := LSource.ImageIndex;
  FPosition := LSource.Position;
  FSizeFactor := LSource.SizeFactor;
  FVisibility := LSource.Visibility;
  DoChange;
end;

procedure TS4YAvatarEditButton.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YAvatarEditButton.SetBackgroundColor(const Value: TAlphaColor);
begin
  if FBackgroundColor = Value then
    Exit;

  FBackgroundColor := Value;
  DoChange;
end;

procedure TS4YAvatarEditButton.SetIconColor(const Value: TAlphaColor);
begin
  if FIconColor = Value then
    Exit;

  FIconColor := Value;
  DoChange;
end;

procedure TS4YAvatarEditButton.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex = Value then
    Exit;

  FImageIndex := Value;
  DoChange;
end;

procedure TS4YAvatarEditButton.SetPosition(const Value: TS4YAvatarCorner);
begin
  if FPosition = Value then
    Exit;

  FPosition := Value;
  DoChange;
end;

procedure TS4YAvatarEditButton.SetSizeFactor(const Value: Single);
var
  LSizeFactor: Single;
begin
  LSizeFactor := EnsureRange(Value, C_MIN_SIZE_FACTOR, C_MAX_SIZE_FACTOR);

  if SameValue(FSizeFactor, LSizeFactor) then
    Exit;

  FSizeFactor := LSizeFactor;
  DoChange;
end;

procedure TS4YAvatarEditButton.SetVisibility(const Value: TS4YAvatarEditButtonVisibility);
begin
  if FVisibility = Value then
    Exit;

  FVisibility := Value;
  DoChange;
end;

function TS4YAvatarEditButton.SizeFactorStored: Boolean;
begin
  Result := not SameValue(FSizeFactor, C_DEFAULT_SIZE_FACTOR);
end;

{ TS4YAvatar }

class function TS4YAvatar.InitialsOf(const AName: string): string;
var
  LWords: TArray<string>;

  function FirstLetter(const AWord: string): string;
  begin
    // A letter out of the basic plane takes two characters.
    if (Length(AWord) > 1) and AWord.Chars[0].IsHighSurrogate then
      Result := Copy(AWord, 1, 2)
    else
      Result := Copy(AWord, 1, 1);
  end;

begin
  LWords := AName.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);

  if Length(LWords) = 0 then
    Exit('');

  Result := FirstLetter(LWords[0]);

  if Length(LWords) > 1 then
    Result := Result + FirstLetter(LWords[High(LWords)]);

  Result := Result.ToUpper;
end;

constructor TS4YAvatar.Create(AOwner: TComponent);
begin
  inherited;

  FBackgroundColor := TAlphaColors.Null;
  FCornerRadius := C_DEFAULT_CORNER_RADIUS;
  FInitialsColor := TAlphaColors.Null;
  FShape := C_DEFAULT_SHAPE;
  FSizePreset := C_DEFAULT_SIZE_PRESET;
  FStatus := avtNone;
  FStatusColor := TAlphaColors.Null;
  FStatusPosition := C_DEFAULT_STATUS_POSITION;
  FCoverInvalid := True;

  FBitmap := TBitmap.Create;
  FBitmap.OnChange := BitmapChanged;
  FImageLink := TGlyphImageLink.Create(Self);
  FRing := TS4YAvatarRing.Create;
  FRing.OnChange := SettingsChanged;
  FEditButton := TS4YAvatarEditButton.Create;
  FEditButton.OnChange := SettingsChanged;
end;

destructor TS4YAvatar.Destroy;
begin
  UnhookEditAction;
  FreeAndNil(FEditButton);
  FreeAndNil(FRing);
  FreeAndNil(FImageLink);
  FreeAndNil(FCoverBitmap);
  FreeAndNil(FBitmap);

  inherited;
end;

procedure TS4YAvatar.ActionDidFinishTaking(AImage: TBitmap);
begin
  // Only the photo asked by this avatar: the action can also be executed elsewhere.
  if FPhotoRequested then
  begin
    FPhotoRequested := False;
    FBitmap.Assign(AImage);
    DoChange;
  end;

  if Assigned(FPreviousDidFinishTaking) then
    FPreviousDidFinishTaking(AImage);
end;

procedure TS4YAvatar.ApplyRadius(const APart: TControl; const ARadius: Single);
begin
  if APart is TRectangle then
  begin
    TRectangle(APart).XRadius := ARadius;
    TRectangle(APart).YRadius := ARadius;
    TRectangle(APart).Corners := AllCorners;
    TRectangle(APart).CornerType := TCornerType.Round;
  end;
end;

procedure TS4YAvatar.ApplyStyle;
var
  LStatusColor: TAlphaColor;
begin
  inherited;

  FindStyleResource<TShape>(C_STYLE_BACKGROUND, FStyleBackground);
  FindStyleResource<TRectangle>(C_STYLE_IMAGE, FStyleImage);
  FindStyleResource<TText>(C_STYLE_TEXT, FStyleText);
  FindStyleResource<TControl>(C_STYLE_PLACEHOLDER, FStylePlaceholder);
  FindStyleResource<TRectangle>(C_STYLE_RING, FStyleRing);
  FindStyleResource<TShape>(C_STYLE_STATUS, FStyleStatus);
  FindStyleResource<TControl>(C_STYLE_EDIT_BUTTON, FStyleEditButton);
  FindStyleResource<TShape>(C_STYLE_EDIT_ICON, FStyleEditIcon);
  FindStyleResource<TGlyph>(C_STYLE_EDIT_GLYPH, FStyleEditGlyph);

  // The parts tell when they are freed: a reference to a freed part never stays.
  if Assigned(FStyleEditButton) then
  begin
    FStyleEditButton.AddFreeNotify(Self);
    FStyleEditButton.HitTest := True;
    FStyleEditButton.Cursor := crHandPoint;
    FStyleEditButton.OnClick := EditButtonClick;
    FStyleEditButton.OnMouseEnter := EditButtonMouseChanged;
    FStyleEditButton.OnMouseLeave := EditButtonMouseChanged;
  end;

  if Assigned(FStyleEditGlyph) then
  begin
    FStyleEditGlyph.AddFreeNotify(Self);
    // The visibility of the glyph is decided by the avatar.
    FStyleEditGlyph.AutoHide := False;
    // The click on the icon goes to the button. Set here: TGlyph publishes HitTest only from Delphi 13,
    // so the style cannot set it.
    FStyleEditGlyph.HitTest := False;
  end;

  // The colors of the style are kept, so that a property set back to Null takes them again.
  if Assigned(FStyleBackground) then
    FStyleBackgroundColor := FStyleBackground.Fill.Color
  else
    FStyleBackgroundColor := C_FALLBACK_BACKGROUND_COLOR;

  if FStyleEditButton is TShape then
    FStyleEditButtonColor := TShape(FStyleEditButton).Fill.Color
  else
    FStyleEditButtonColor := C_FALLBACK_EDIT_BUTTON_COLOR;

  if Assigned(FStyleEditIcon) then
    FStyleEditIconColor := FStyleEditIcon.Fill.Color
  else
    FStyleEditIconColor := C_FALLBACK_EDIT_ICON_COLOR;

  if Assigned(FStyleRing) then
    LStatusColor := FStyleRing.Stroke.Color
  else
    LStatusColor := C_FALLBACK_RING_COLOR;

  FindStyleColor(C_STYLE_RING_COLOR, LStatusColor, FStyleRingColor);
  FindStyleColor(C_STYLE_ONLINE_COLOR, C_FALLBACK_ONLINE_COLOR, FStyleStatusColors[avtOnline]);
  FindStyleColor(C_STYLE_AWAY_COLOR, C_FALLBACK_AWAY_COLOR, FStyleStatusColors[avtAway]);
  FindStyleColor(C_STYLE_BUSY_COLOR, C_FALLBACK_BUSY_COLOR, FStyleStatusColors[avtBusy]);
  FindStyleColor(C_STYLE_OFFLINE_COLOR, C_FALLBACK_OFFLINE_COLOR, FStyleStatusColors[avtOffline]);
  FStyleStatusColors[avtNone] := TAlphaColors.Null;

  // The picture is prepared again for the new part.
  FCoverInvalid := True;
  UpdateParts;
end;

function TS4YAvatar.BackgroundColorOfText: TAlphaColor;
var
  LHash: Int64;
  LText: string;
begin
  // A hash of the text, computed in the same way on every platform, so that the same name has
  // always the same color.
  LText := FText.Trim.ToUpper;
  LHash := 0;

  for var I := 1 to Length(LText) do
    LHash := (LHash * C_HASH_MULTIPLIER + Ord(LText[I])) mod C_HASH_MODULUS;

  Result := C_INITIALS_BACKGROUND_COLORS[LHash mod Length(C_INITIALS_BACKGROUND_COLORS)];
end;

procedure TS4YAvatar.BitmapChanged(Sender: TObject);
begin
  FCoverInvalid := True;
  UpdateParts;
end;

function TS4YAvatar.CalculateCornerCenter(const ACorner: TS4YAvatarCorner; const ADiameter: Single): TPointF;
var
  LInset: Single;
  LOuterRadius: Single;
  LOuterRect: TRectF;
begin
  LOuterRect := CalculateOuterRect;

  // The point of the rounded corner at 45 degrees, but never closer to the edge than the radius of
  // the dot, so that the dot stays inside the avatar.
  case FShape of
    avsCircle:
      LOuterRadius := LOuterRect.Width / 2;
    avsRounded:
      begin
        LOuterRadius := CalculateInnerRadius;

        if FRing.Visible then
          LOuterRadius := LOuterRadius + FRing.Thickness + FRing.Gap;
      end;
  else
    LOuterRadius := 0;
  end;

  LInset := System.Math.Max(ADiameter / 2, LOuterRadius * (1 - Sqrt(0.5)));

  case ACorner of
    avcTopLeft:
      Result := TPointF.Create(LOuterRect.Left + LInset, LOuterRect.Top + LInset);
    avcTopRight:
      Result := TPointF.Create(LOuterRect.Right - LInset, LOuterRect.Top + LInset);
    avcBottomLeft:
      Result := TPointF.Create(LOuterRect.Left + LInset, LOuterRect.Bottom - LInset);
  else
    Result := TPointF.Create(LOuterRect.Right - LInset, LOuterRect.Bottom - LInset);
  end;
end;

function TS4YAvatar.CalculateImageListSize(const AImages: TCustomImageList; const APixelWidth,
  APixelHeight: Integer): TSizeF;
var
  LDestination: TCustomDestinationItem;
  LLayerSize: TSizeF;
  LScale: Single;
begin
  Result := TSizeF.Create(APixelWidth, APixelHeight);

  // An image list fits the image in the size asked, leaving empty bands when the proportions
  // differ: the size asked has the proportions of the image, large enough to cover the target.
  if FImageLink.ImageIndex >= AImages.Destination.Count then
    Exit;

  LDestination := AImages.Destination[FImageLink.ImageIndex];

  if LDestination.Layers.Count = 0 then
    Exit;

  LLayerSize := LDestination.Layers[0].SourceRect.Rect.Size;

  if (LLayerSize.Width <= 0) or (LLayerSize.Height <= 0) then
    Exit;

  LScale := System.Math.Max(APixelWidth / LLayerSize.Width, APixelHeight / LLayerSize.Height);
  Result := TSizeF.Create(Ceil(LLayerSize.Width * LScale), Ceil(LLayerSize.Height * LScale));
end;

function TS4YAvatar.CalculateInnerRadius: Single;
var
  LInnerSize: Single;
  LOuterRect: TRectF;
begin
  LOuterRect := CalculateOuterRect;
  LInnerSize := System.Math.Min(LOuterRect.Width, LOuterRect.Height);

  if FRing.Visible then
    LInnerSize := LInnerSize - 2 * (FRing.Thickness + FRing.Gap);

  LInnerSize := System.Math.Max(0, LInnerSize);

  case FShape of
    avsCircle:
      Result := LInnerSize / 2;
    avsRounded:
      Result := System.Math.Min(FCornerRadius, LInnerSize / 2);
  else
    Result := 0;
  end;
end;

function TS4YAvatar.CalculateOuterRect: TRectF;
var
  LBounds: TRectF;
  LSide: Single;
begin
  // The parts are placed in the root of the style, which covers the control.
  if Assigned(ResourceControl) then
    LBounds := ResourceControl.LocalRect
  else
    LBounds := LocalRect;

  // A circle stays round in a control that is not square: it is centered in it.
  if FShape = avsCircle then
  begin
    LSide := System.Math.Min(LBounds.Width, LBounds.Height);
    Result := TRectF.Create(0, 0, LSide, LSide);
    Result.Offset(LBounds.Left + (LBounds.Width - LSide) / 2, LBounds.Top + (LBounds.Height - LSide) / 2);
  end
  else
    Result := LBounds;
end;

function TS4YAvatar.CornerRadiusStored: Boolean;
begin
  Result := not SameValue(FCornerRadius, C_DEFAULT_CORNER_RADIUS);
end;

procedure TS4YAvatar.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YAvatar.DoEditClick;
begin
  if Assigned(FOnEditClick) then
    FOnEditClick(Self);

  if not Assigned(FEditAction) then
    Exit;

  // A photo action gets the avatar as its target, so that on a tablet its window opens beside it.
  if FEditAction is TCustomTakePhotoAction then
  begin
    FPhotoRequested := True;
    FEditAction.ExecuteTarget(Self);
  end
  else
    FEditAction.Execute;
end;

procedure TS4YAvatar.DoMouseEnter;
begin
  inherited;

  if FEditButton.Visibility = ebvOnHover then
    UpdateParts;
end;

procedure TS4YAvatar.DoMouseLeave;
begin
  inherited;

  if FEditButton.Visibility = ebvOnHover then
    UpdateParts;
end;

procedure TS4YAvatar.DoRealign;
begin
  inherited;

  UpdateParts;
end;

function TS4YAvatar.DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean; ANewWidth,
  ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean;
begin
  if FSizePreset <> avzCustom then
  begin
    ANewWidth := C_SIZE_PRESET_SIZES[FSizePreset];
    ANewHeight := C_SIZE_PRESET_SIZES[FSizePreset];
  end;

  Result := inherited DoSetSize(ASize, NewPlatformDefault, ANewWidth, ANewHeight, ALastWidth, ALastHeight);
end;

procedure TS4YAvatar.EditButtonClick(Sender: TObject);
begin
  DoEditClick;
end;

procedure TS4YAvatar.EditButtonMouseChanged(Sender: TObject);
begin
  if FEditButton.Visibility = ebvOnHover then
    UpdateParts;
end;

procedure TS4YAvatar.FindStyleColor(const AStyleName: string; const ADefaultColor: TAlphaColor;
  out AColor: TAlphaColor);
var
  LColorObject: TColorObject;
begin
  if FindStyleResource<TColorObject>(AStyleName, LColorObject) then
    AColor := LColorObject.Color
  else
    AColor := ADefaultColor;
end;

procedure TS4YAvatar.FreeStyle;
begin
  if Assigned(FStyleEditButton) then
  begin
    FStyleEditButton.RemoveFreeNotify(Self);
    FStyleEditButton.OnClick := nil;
    FStyleEditButton.OnMouseEnter := nil;
    FStyleEditButton.OnMouseLeave := nil;
    FStyleEditButton := nil;
  end;

  if Assigned(FStyleEditGlyph) then
  begin
    FStyleEditGlyph.RemoveFreeNotify(Self);
    FStyleEditGlyph.ImageIndex := -1;
    FStyleEditGlyph.Images := nil;
    FStyleEditGlyph := nil;
  end;

  FStyleBackground := nil;
  FStyleImage := nil;
  FStyleText := nil;
  FStylePlaceholder := nil;
  FStyleRing := nil;
  FStyleStatus := nil;
  FStyleEditIcon := nil;

  inherited;
end;

function TS4YAvatar.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(C_DEFAULT_SIZE, C_DEFAULT_SIZE);
end;

function TS4YAvatar.GetDisplayedInitials: string;
begin
  if FInitials <> '' then
    Result := FInitials
  else
    Result := InitialsOf(FText);
end;

function TS4YAvatar.GetImageIndex: TImageIndex;
begin
  Result := FImageLink.ImageIndex;
end;

function TS4YAvatar.GetImageList: TBaseImageList;
begin
  Result := FImageLink.Images;
end;

function TS4YAvatar.GetImages: TCustomImageList;
begin
  Result := TCustomImageList(FImageLink.Images);
end;

function TS4YAvatar.GetStyleObject: TFmxObject;
begin
  // The style named by StyleLookup or, when it is empty, the one named after the class, in the
  // style book or in the active style; never the style of the parent class.
  Result := LookupStyleObject(Self, GetStyleContext, Scene, StyleLookup, GetDefaultStyleLookupName, '', True);

  // The style linked into the package is used when no other style is found.
  if not Assigned(Result) then
    Result := TStyleStreaming.LoadFromResource(HInstance, GetDefaultStyleLookupName, RT_RCDATA);
end;

function TS4YAvatar.HasPicture: Boolean;
var
  LImages: TCustomImageList;
begin
  if not FBitmap.IsEmpty then
    Exit(True);

  LImages := GetImages;
  Result := Assigned(LImages) and LImages.BitmapExists(FImageLink.ImageIndex);
end;

procedure TS4YAvatar.HookEditAction;
begin
  // At design time the event of the action belongs to the form being designed: it is not touched.
  if not (FEditAction is TCustomTakePhotoAction) or (csDesigning in ComponentState) or
    (csLoading in ComponentState) then
    Exit;

  FPreviousDidFinishTaking := TCustomTakePhotoAction(FEditAction).OnDidFinishTaking;
  TCustomTakePhotoAction(FEditAction).OnDidFinishTaking := ActionDidFinishTaking;
end;

procedure TS4YAvatar.ImagesChanged;
begin
  FCoverInvalid := True;
  UpdateParts;
end;

function TS4YAvatar.IsEditButtonShown: Boolean;
begin
  case FEditButton.Visibility of
    ebvAlways:
      Result := True;
    ebvOnHover:
      Result := IsMobilePlatform or (csDesigning in ComponentState) or IsMouseOver or
        (Assigned(FStyleEditButton) and FStyleEditButton.IsMouseOver);
  else
    Result := False;
  end;
end;

procedure TS4YAvatar.Loaded;
begin
  inherited;

  HookEditAction;
  UpdateParts;
end;

procedure TS4YAvatar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) and (AComponent = FEditAction) then
  begin
    // The action is being freed: its event is not given back.
    FEditAction := nil;
    FPreviousDidFinishTaking := nil;
    FPhotoRequested := False;
  end;
end;

procedure TS4YAvatar.SetBackgroundColor(const Value: TAlphaColor);
begin
  if FBackgroundColor = Value then
    Exit;

  FBackgroundColor := Value;
  UpdateParts;
end;

procedure TS4YAvatar.SetBitmap(const Value: TBitmap);
begin
  FBitmap.Assign(Value);
end;

procedure TS4YAvatar.SetCornerRadius(const Value: Single);
begin
  if SameValue(FCornerRadius, System.Math.Max(0, Value)) then
    Exit;

  FCornerRadius := System.Math.Max(0, Value);
  UpdateParts;
end;

procedure TS4YAvatar.SetEditAction(const Value: TBasicAction);
begin
  if FEditAction = Value then
    Exit;

  UnhookEditAction;

  if Assigned(FEditAction) then
    FEditAction.RemoveFreeNotification(Self);

  FEditAction := Value;

  if Assigned(FEditAction) then
    FEditAction.FreeNotification(Self);

  HookEditAction;
end;

procedure TS4YAvatar.SetEditButton(const Value: TS4YAvatarEditButton);
begin
  FEditButton.Assign(Value);
end;

procedure TS4YAvatar.SetImageIndex(const Value: TImageIndex);
begin
  FImageLink.ImageIndex := Value;
end;

procedure TS4YAvatar.SetImageList(const Value: TBaseImageList);
begin
  FImageLink.Images := Value;
end;

procedure TS4YAvatar.SetImages(const Value: TCustomImageList);
begin
  FImageLink.Images := Value;
end;

procedure TS4YAvatar.SetInitials(const Value: string);
begin
  if FInitials = Value then
    Exit;

  FInitials := Value;
  UpdateParts;
end;

procedure TS4YAvatar.SetInitialsColor(const Value: TAlphaColor);
begin
  if FInitialsColor = Value then
    Exit;

  FInitialsColor := Value;
  UpdateParts;
end;

procedure TS4YAvatar.SetRing(const Value: TS4YAvatarRing);
begin
  FRing.Assign(Value);
end;

procedure TS4YAvatar.SetShape(const Value: TS4YAvatarShape);
begin
  if FShape = Value then
    Exit;

  FShape := Value;
  FCoverInvalid := True;
  UpdateParts;
end;

procedure TS4YAvatar.SetSizePreset(const Value: TS4YAvatarSizePreset);
begin
  if FSizePreset = Value then
    Exit;

  FSizePreset := Value;

  // DoSetSize replaces the size with the one of the preset.
  if FSizePreset <> avzCustom then
    SetBounds(Position.X, Position.Y, C_SIZE_PRESET_SIZES[FSizePreset], C_SIZE_PRESET_SIZES[FSizePreset]);
end;

procedure TS4YAvatar.SetStatus(const Value: TS4YAvatarStatus);
begin
  if FStatus = Value then
    Exit;

  FStatus := Value;
  UpdateParts;
end;

procedure TS4YAvatar.SetStatusColor(const Value: TAlphaColor);
begin
  if FStatusColor = Value then
    Exit;

  FStatusColor := Value;
  UpdateParts;
end;

procedure TS4YAvatar.SetStatusPosition(const Value: TS4YAvatarCorner);
begin
  if FStatusPosition = Value then
    Exit;

  FStatusPosition := Value;
  UpdateParts;
end;

procedure TS4YAvatar.SetText(const Value: string);
begin
  if FText = Value then
    Exit;

  FText := Value;
  UpdateParts;
end;

procedure TS4YAvatar.SettingsChanged(Sender: TObject);
begin
  FCoverInvalid := True;
  UpdateParts;
end;

procedure TS4YAvatar.StyleResourceFreed(AObject: TObject);
begin
  // Reached only when a part of the style is freed outside FreeStyle.
  if AObject = FStyleEditButton then
    FStyleEditButton := nil;

  if AObject = FStyleEditGlyph then
    FStyleEditGlyph := nil;
end;

procedure TS4YAvatar.UnhookEditAction;
begin
  if not (FEditAction is TCustomTakePhotoAction) or (csDesigning in ComponentState) then
    Exit;

  // The event is given back only when it is still the one of the avatar.
  if TMethod(TCustomTakePhotoAction(FEditAction).OnDidFinishTaking).Data = Pointer(Self) then
    TCustomTakePhotoAction(FEditAction).OnDidFinishTaking := FPreviousDidFinishTaking;

  FPreviousDidFinishTaking := nil;
  FPhotoRequested := False;
end;

procedure TS4YAvatar.UpdateCoverBitmap(const ATargetSize: TSizeF);
var
  LImages: TCustomImageList;
  LPixelHeight: Integer;
  LPixelWidth: Integer;
  LScale: Single;
  LSource: TBitmap;
  LSourceRect: TRectF;
  LTargetRatio: Single;
begin
  if Assigned(Scene) then
    LScale := Scene.GetSceneScale
  else
    LScale := 1;

  LPixelWidth := Ceil(ATargetSize.Width * LScale);
  LPixelHeight := Ceil(ATargetSize.Height * LScale);

  if (LPixelWidth < 1) or (LPixelHeight < 1) then
    Exit;

  // The picture is prepared again only when it or the size changes.
  if not FCoverInvalid and Assigned(FCoverBitmap) and (FCoverBitmap.Width = LPixelWidth) and
    (FCoverBitmap.Height = LPixelHeight) then
    Exit;

  FCoverInvalid := False;
  LImages := GetImages;

  if not FBitmap.IsEmpty then
    LSource := FBitmap
  else if Assigned(LImages) and LImages.BitmapExists(FImageLink.ImageIndex) then
    LSource := LImages.Bitmap(CalculateImageListSize(LImages, LPixelWidth, LPixelHeight), FImageLink.ImageIndex)
  else
    LSource := nil;

  if not Assigned(LSource) or LSource.IsEmpty then
  begin
    FreeAndNil(FCoverBitmap);
    Exit;
  end;

  // The largest part of the picture with the proportions of the target, in its middle: the picture
  // fills the shape and what goes beyond it is cut on both sides.
  LTargetRatio := LPixelWidth / LPixelHeight;

  if LSource.Width / LSource.Height > LTargetRatio then
  begin
    LSourceRect := TRectF.Create(0, 0, LSource.Height * LTargetRatio, LSource.Height);
    LSourceRect.Offset((LSource.Width - LSourceRect.Width) / 2, 0);
  end
  else
  begin
    LSourceRect := TRectF.Create(0, 0, LSource.Width, LSource.Width / LTargetRatio);
    LSourceRect.Offset(0, (LSource.Height - LSourceRect.Height) / 2);
  end;

  if not Assigned(FCoverBitmap) then
    FCoverBitmap := TBitmap.Create;

  FCoverBitmap.SetSize(LPixelWidth, LPixelHeight);

  if FCoverBitmap.Canvas.BeginScene then
  begin
    try
      FCoverBitmap.Canvas.Clear(TAlphaColors.Null);
      FCoverBitmap.Canvas.DrawBitmap(LSource, LSourceRect, TRectF.Create(0, 0, LPixelWidth, LPixelHeight), 1,
        False);
    finally
      FCoverBitmap.Canvas.EndScene;
    end;
  end;
end;

procedure TS4YAvatar.UpdateEditButton(const AOuterRect: TRectF);
var
  LCenter: TPointF;
  LDiameter: Single;
  LExpansion: Single;
  LIconMargin: Single;
  LIconSize: Single;
  LImages: TCustomImageList;
  LUseGlyph: Boolean;
begin
  if not Assigned(FStyleEditButton) then
    Exit;

  // With ebvOnHover the button stays in place, transparent, while the mouse is not over the
  // avatar: so it can still receive the mouse, which moves from the avatar onto it.
  FStyleEditButton.Visible := FEditButton.Visibility <> ebvNever;

  if IsEditButtonShown then
    FStyleEditButton.Opacity := 1
  else
    FStyleEditButton.Opacity := 0;

  if not FStyleEditButton.Visible then
    Exit;

  LDiameter := System.Math.Min(AOuterRect.Width, AOuterRect.Height) * FEditButton.SizeFactor;
  LCenter := CalculateCornerCenter(FEditButton.Position, LDiameter);
  FStyleEditButton.SetBounds(LCenter.X - LDiameter / 2, LCenter.Y - LDiameter / 2, LDiameter, LDiameter);
  LIconMargin := LDiameter * C_EDIT_ICON_MARGIN_FACTOR;
  LIconSize := System.Math.Max(0, LDiameter - 2 * LIconMargin);

  if Assigned(FStyleEditIcon) then
    FStyleEditIcon.SetBounds(LIconMargin, LIconMargin, LIconSize, LIconSize);

  if Assigned(FStyleEditGlyph) then
    FStyleEditGlyph.SetBounds(LIconMargin, LIconMargin, LIconSize, LIconSize);

  // A finger needs a larger area than the button drawn.
  if IsMobilePlatform then
  begin
    LExpansion := System.Math.Max(0, (C_MIN_TOUCH_SIZE - LDiameter) / 2);
    FStyleEditButton.TouchTargetExpansion.Rect := TRectF.Create(LExpansion, LExpansion, LExpansion, LExpansion);
  end;

  if FStyleEditButton is TShape then
  begin
    if FEditButton.BackgroundColor <> TAlphaColors.Null then
      TShape(FStyleEditButton).Fill.Color := FEditButton.BackgroundColor
    else
      TShape(FStyleEditButton).Fill.Color := FStyleEditButtonColor;

    TShape(FStyleEditButton).Stroke.Thickness := LDiameter * C_EDIT_BUTTON_BORDER_FACTOR;
  end;

  LImages := GetImages;
  LUseGlyph := Assigned(FStyleEditGlyph) and Assigned(LImages) and LImages.BitmapExists(FEditButton.ImageIndex);

  if Assigned(FStyleEditGlyph) then
  begin
    FStyleEditGlyph.Images := LImages;
    FStyleEditGlyph.ImageIndex := FEditButton.ImageIndex;
    FStyleEditGlyph.Visible := LUseGlyph;
  end;

  if Assigned(FStyleEditIcon) then
  begin
    FStyleEditIcon.Visible := not LUseGlyph;

    if FEditButton.IconColor <> TAlphaColors.Null then
      FStyleEditIcon.Fill.Color := FEditButton.IconColor
    else
      FStyleEditIcon.Fill.Color := FStyleEditIconColor;
  end;
end;

procedure TS4YAvatar.UpdateParts;
var
  LBackgroundColor: TAlphaColor;
  LHasPicture: Boolean;
  LInitials: string;
  LInnerRadius: Single;
  LInnerRect: TRectF;
  LInset: Single;
  LMargin: Single;
  LOuterRect: TRectF;
  LRingRect: TRectF;
begin
  if not Assigned(ResourceControl) or (csLoading in ComponentState) then
    Exit;

  LOuterRect := CalculateOuterRect;

  if FRing.Visible then
    LInset := FRing.Thickness + FRing.Gap
  else
    LInset := 0;

  LInnerRect := LOuterRect;
  LInnerRect.Inflate(-LInset, -LInset);
  LInnerRadius := CalculateInnerRadius;
  LHasPicture := HasPicture;
  LInitials := GetDisplayedInitials;

  // The background of the initials: the color of the property, else one chosen from the text, else
  // the neutral one of the style behind the outline of a person.
  if FBackgroundColor <> TAlphaColors.Null then
    LBackgroundColor := FBackgroundColor
  else if LInitials <> '' then
    LBackgroundColor := BackgroundColorOfText
  else
    LBackgroundColor := FStyleBackgroundColor;

  if Assigned(FStyleBackground) then
  begin
    FStyleBackground.Visible := not LHasPicture;
    FStyleBackground.SetBounds(LInnerRect.Left, LInnerRect.Top, LInnerRect.Width, LInnerRect.Height);
    FStyleBackground.Fill.Color := LBackgroundColor;
    ApplyRadius(FStyleBackground, LInnerRadius);
  end;

  if Assigned(FStyleImage) then
  begin
    FStyleImage.Visible := LHasPicture;
    FStyleImage.SetBounds(LInnerRect.Left, LInnerRect.Top, LInnerRect.Width, LInnerRect.Height);
    ApplyRadius(FStyleImage, LInnerRadius);

    if LHasPicture then
    begin
      UpdateCoverBitmap(LInnerRect.Size);

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
      FStyleImage.Fill.Bitmap.Bitmap.SetSize(0, 0);
    end;
  end;

  if Assigned(FStyleText) then
  begin
    FStyleText.Visible := not LHasPicture and (LInitials <> '');
    FStyleText.SetBounds(LInnerRect.Left, LInnerRect.Top, LInnerRect.Width, LInnerRect.Height);
    FStyleText.Text := LInitials;
    FStyleText.Font.Size := System.Math.Max(C_MIN_INITIALS_FONT_SIZE, LInnerRect.Height * C_INITIALS_FONT_FACTOR);

    if FInitialsColor <> TAlphaColors.Null then
      FStyleText.TextSettings.FontColor := FInitialsColor
    else if LuminanceOf(LBackgroundColor) > C_LIGHT_BACKGROUND_LUMINANCE then
      FStyleText.TextSettings.FontColor := C_DARK_INITIALS_COLOR
    else
      FStyleText.TextSettings.FontColor := C_LIGHT_INITIALS_COLOR;
  end;

  if Assigned(FStylePlaceholder) then
  begin
    FStylePlaceholder.Visible := not LHasPicture and (LInitials = '');
    LMargin := LInnerRect.Width * C_PLACEHOLDER_MARGIN_FACTOR;
    FStylePlaceholder.SetBounds(LInnerRect.Left + LMargin, LInnerRect.Top + LMargin,
      System.Math.Max(0, LInnerRect.Width - 2 * LMargin), System.Math.Max(0, LInnerRect.Height - 2 * LMargin));
  end;

  if Assigned(FStyleRing) then
  begin
    FStyleRing.Visible := FRing.Visible and (FRing.Thickness > 0);
    // The border is drawn on the edge of the rectangle, half inside and half outside it.
    LRingRect := LOuterRect;
    LRingRect.Inflate(-FRing.Thickness / 2, -FRing.Thickness / 2);
    FStyleRing.SetBounds(LRingRect.Left, LRingRect.Top, LRingRect.Width, LRingRect.Height);
    FStyleRing.Fill.Kind := TBrushKind.None;
    FStyleRing.Stroke.Kind := TBrushKind.Solid;
    FStyleRing.Stroke.Thickness := FRing.Thickness;

    if FRing.Color <> TAlphaColors.Null then
      FStyleRing.Stroke.Color := FRing.Color
    else
      FStyleRing.Stroke.Color := FStyleRingColor;

    if FShape = avsSquare then
      ApplyRadius(FStyleRing, 0)
    else
      ApplyRadius(FStyleRing, LInnerRadius + FRing.Gap + FRing.Thickness / 2);
  end;

  UpdateEditButton(LOuterRect);
  UpdateStatus;
  Repaint;
end;

procedure TS4YAvatar.UpdateStatus;
var
  LCenter: TPointF;
  LDiameter: Single;
  LOuterRect: TRectF;
begin
  if not Assigned(FStyleStatus) then
    Exit;

  // The edit button wins over the dot in the same corner, while it is shown.
  FStyleStatus.Visible := (FStatus <> avtNone) and
    not ((FEditButton.Position = FStatusPosition) and IsEditButtonShown);

  if not FStyleStatus.Visible then
    Exit;

  LOuterRect := CalculateOuterRect;
  LDiameter := System.Math.Max(C_MIN_STATUS_SIZE,
    System.Math.Min(LOuterRect.Width, LOuterRect.Height) * C_STATUS_SIZE_FACTOR);
  LCenter := CalculateCornerCenter(FStatusPosition, LDiameter);
  FStyleStatus.SetBounds(LCenter.X - LDiameter / 2, LCenter.Y - LDiameter / 2, LDiameter, LDiameter);
  FStyleStatus.Stroke.Thickness := LDiameter * C_STATUS_BORDER_FACTOR;

  if FStatusColor <> TAlphaColors.Null then
    FStyleStatus.Fill.Color := FStatusColor
  else
    FStyleStatus.Fill.Color := FStyleStatusColors[FStatus];
end;

end.
