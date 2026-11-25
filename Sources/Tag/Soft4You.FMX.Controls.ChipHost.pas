unit Soft4You.FMX.Controls.ChipHost;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YCustomChipHost - base of the controls with a style that hold chips
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
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  Soft4You.FMX.Controls.Tag.Types,
  Soft4You.FMX.Controls.Chip,
  Soft4You.FMX.Controls.ChipBox;

type
  TS4YCustomChipHost = class;

  /// <summary>The box of chips inside a TS4YCustomChipHost: it tells the host what happens to its chips, and the host decides.</summary>
  TS4YChipHostBox = class(TS4YCustomChipBox)
  private
    FHost: TS4YCustomChipHost;
  protected
    procedure ChipEntered(const AChip: TS4YChip); override;
    procedure ChipExited(const AChip: TS4YChip); override;
    procedure ChipsSynced; override;
    procedure ConfigureChip(const AChip: TS4YChip; AIndex: Integer); override;
    function CreateChip: TS4YChip; override;
  public
    /// <summary>A click on the free space of the box is told to the host.</summary>
    procedure Click; override;
    /// <summary>The height of the chips.</summary>
    function CurrentChipHeight: Single;
    /// <summary>The size of the font of the chips.</summary>
    function CurrentChipFontSize: Single;
    /// <summary>Scrolls a control of the box into view.</summary>
    procedure ScrollToControl(const AControl: TControl);
    /// <summary>Makes, changes and frees the chips again, so that they match Items and the settings.</summary>
    procedure RefreshChips;

    property AutoSize;
    property Chips;
    property FillControl;
    property FillMinWidth;
    property HorizontalGap;
    property Items;
    property Kind;
    property MaxHeight;
    property OnResized;
    property Variant;
    property VerticalGap;
  end;

  /// <summary>
  /// Base of TS4YChipGroup and TS4YChipEdit: a control with a style that holds a box of chips, one for each text of Items.
  /// </summary>
  /// <remarks>
  /// The style gives the look of the control and, with the part chip, the look of its chips: that part is a TS4YChip, hidden, whose shape, variant, size, font, padding, corner radius and style the control copies to every chip it makes. To change the chips, change that chip of the style, in the style designer; the control does not publish what the style gives.
  /// The other parts of the style are background, the frame, and content, whose margins are the space between the frame and the chips.
  /// With AutoSize True, the default, the height of the control is the one of its lines of chips, up to MaxHeight, and the height that is set is replaced by it; with False the height is the one set, and what does not fit is clipped inside the frame and scrolls.
  /// </remarks>
  TS4YCustomChipHost = class(TStyledControl)
  public const
    /// <summary>Default value of the margins between the frame and the chips: left and right, and above and under, in pixels.</summary>
    C_DEFAULT_INNER_MARGIN_HORIZONTAL = 8;
    C_DEFAULT_INNER_MARGIN_VERTICAL = 4;
  private
    FAutoSize: Boolean;
    FBox: TS4YChipHostBox;
    FResizing: Boolean;
    FStyleBackground: TRectangle;
    procedure BoxResized(Sender: TObject);
    function GetHorizontalGap: Single;
    function GetItems: TStrings;
    function GetKind: TS4YTagKind;
    function GetMaxHeight: Single;
    function GetVerticalGap: Single;
    function IsGapStored(const AGap: Single): Boolean;
    function IsHorizontalGapStored: Boolean;
    function IsMaxHeightStored: Boolean;
    function IsVerticalGapStored: Boolean;
    procedure SetAutoSize(const Value: Boolean);
    procedure SetHorizontalGap(const Value: Single);
    procedure SetItems(const Value: TStrings);
    procedure SetKind(const Value: TS4YTagKind);
    procedure SetMaxHeight(const Value: Single);
    procedure SetVerticalGap(const Value: Single);
  protected
    /// <summary>Takes the parts of the style: the frame, the space inside it and the chip that gives the look of the chips.</summary>
    procedure ApplyStyle; override;
    /// <summary>Called when the box tells that a click reached its free space.</summary>
    procedure BoxClicked; virtual;
    /// <summary>Called when the focus enters (ADelta 1) or leaves (-1) a chip.</summary>
    procedure ChipFocusChanged(const ADelta: Integer); virtual;
    /// <summary>Called when the box has made a chip.</summary>
    procedure ChipCreated(const AChip: TS4YChip); virtual;
    /// <summary>Called when the chips match Items again.</summary>
    procedure ChipsSynced; virtual;
    /// <summary>Called for each chip, after it has the look of the model and its text: a descendant adds its own settings.</summary>
    procedure ConfigureChip(const AChip: TS4YChip; AIndex: Integer); virtual;
    /// <summary>With AutoSize True gives the control the height of its lines of chips, whatever height is set.</summary>
    function DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean; ANewWidth, ANewHeight: Single;
      var ALastWidth, ALastHeight: Single): Boolean; override;
    /// <summary>Lets go of the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>The control starts as wide as 320 pixels and as high as a line of chips with the space around them.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns the style of the control: the one named by StyleLookup or, when it is empty or not found, the one named after the class, in the style book or in the active style; else the default style linked into the package.</summary>
    function GetStyleObject: TFmxObject; override;
    /// <summary>Returns the list of Tab that takes the box of chips, which is not stored.</summary>
    function GetTabListClass: TTabListClass; override;
    /// <summary>Called once the style is applied: a descendant takes its own parts.</summary>
    procedure StyleApplied; virtual;
    /// <summary>Gives the control the height of its box when AutoSize is True.</summary>
    procedure UpdateHeight;

    /// <summary>The box of chips.</summary>
    property Box: TS4YChipHostBox read FBox;
    /// <summary>The frame of the style.</summary>
    property StyleBackground: TRectangle read FStyleBackground;

    /// <summary>When True, the default, the height follows the lines of chips up to MaxHeight.</summary>
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;
    /// <summary>Space between two chips on a line, in pixels. The default is 8.</summary>
    property HorizontalGap: Single read GetHorizontalGap write SetHorizontalGap stored IsHorizontalGapStored nodefault;
    /// <summary>The texts of the chips, in order.</summary>
    property Items: TStrings read GetItems write SetItems;
    /// <summary>Meaning of the chips, which gives them their color. The default is tgkNeutral.</summary>
    property Kind: TS4YTagKind read GetKind write SetKind default tgkNeutral;
    /// <summary>Largest height of the control in pixels, frame included, when AutoSize is True: a longer content scrolls. The default, 0, means no limit.</summary>
    property MaxHeight: Single read GetMaxHeight write SetMaxHeight stored IsMaxHeightStored nodefault;
    /// <summary>Space between two lines of chips, in pixels. The default is 8.</summary>
    property VerticalGap: Single read GetVerticalGap write SetVerticalGap stored IsVerticalGapStored nodefault;
  public
    /// <summary>Creates the control with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  FMX.Styles;

const
  C_STYLE_BACKGROUND = 'background';
  C_STYLE_CHIP = 'chip';
  C_STYLE_CONTENT = 'content';

{ TS4YChipHostBox }

procedure TS4YChipHostBox.ChipEntered(const AChip: TS4YChip);
begin
  inherited;

  FHost.ChipFocusChanged(1);
end;

procedure TS4YChipHostBox.ChipExited(const AChip: TS4YChip);
begin
  inherited;

  FHost.ChipFocusChanged(-1);
end;

procedure TS4YChipHostBox.ChipsSynced;
begin
  inherited;

  FHost.ChipsSynced;
end;

procedure TS4YChipHostBox.Click;
begin
  inherited;

  FHost.BoxClicked;
end;

procedure TS4YChipHostBox.ConfigureChip(const AChip: TS4YChip; AIndex: Integer);
begin
  inherited;

  FHost.ConfigureChip(AChip, AIndex);
end;

function TS4YChipHostBox.CreateChip: TS4YChip;
begin
  Result := inherited;
  FHost.ChipCreated(Result);
end;

function TS4YChipHostBox.CurrentChipFontSize: Single;
begin
  Result := GetCurrentChipFontSize;
end;

function TS4YChipHostBox.CurrentChipHeight: Single;
begin
  Result := GetCurrentChipHeight;
end;

procedure TS4YChipHostBox.RefreshChips;
begin
  SyncChips;
end;

procedure TS4YChipHostBox.ScrollToControl(const AControl: TControl);
begin
  ScrollInView(AControl);
end;

{ TS4YCustomChipHost }

constructor TS4YCustomChipHost.Create(AOwner: TComponent);
begin
  inherited;

  FAutoSize := True;
  CanFocus := False;
  // What the box holds never goes out of the frame
  ClipChildren := True;

  FBox := TS4YChipHostBox.Create(Self);
  FBox.FHost := Self;
  FBox.Stored := False;
  FBox.Locked := True;
  FBox.Margins.Rect := TRectF.Create(C_DEFAULT_INNER_MARGIN_HORIZONTAL, C_DEFAULT_INNER_MARGIN_VERTICAL,
    C_DEFAULT_INNER_MARGIN_HORIZONTAL, C_DEFAULT_INNER_MARGIN_VERTICAL);
  FBox.Align := TAlignLayout.Top;
  FBox.OnResized := BoxResized;
  FBox.Parent := Self;
end;

procedure TS4YCustomChipHost.ApplyStyle;
var
  LContent: TControl;
  LTemplate: TS4YChip;
begin
  inherited;

  FindStyleResource<TRectangle>(C_STYLE_BACKGROUND, FStyleBackground);

  // The space between the frame and the chips is the margins of the part content of the style
  if FindStyleResource<TControl>(C_STYLE_CONTENT, LContent) then
    FBox.Margins.Rect := LContent.Margins.Rect;

  // The chip of the style is the model of the chips: they take its look. It is read now and not kept, and it never
  // takes the focus.
  if FindStyleResource<TS4YChip>(C_STYLE_CHIP, LTemplate) then
  begin
    LTemplate.CanFocus := False;
    LTemplate.TabStop := False;
    FBox.ApplyChipTemplate(LTemplate);
  end;

  StyleApplied;
  UpdateHeight;
end;

procedure TS4YCustomChipHost.BoxClicked;
begin
end;

procedure TS4YCustomChipHost.BoxResized(Sender: TObject);
begin
  UpdateHeight;
end;

procedure TS4YCustomChipHost.ChipCreated(const AChip: TS4YChip);
begin
end;

procedure TS4YCustomChipHost.ChipFocusChanged(const ADelta: Integer);
begin
end;

procedure TS4YCustomChipHost.ChipsSynced;
begin
end;

procedure TS4YCustomChipHost.ConfigureChip(const AChip: TS4YChip; AIndex: Integer);
begin
end;

function TS4YCustomChipHost.DoSetSize(const ASize: TControlSize; const NewPlatformDefault: Boolean; ANewWidth,
  ANewHeight: Single; var ALastWidth, ALastHeight: Single): Boolean;
begin
  // The first calls come from the constructors of the ancestors, before the box exists
  if FAutoSize and Assigned(FBox) then
    ANewHeight := FBox.Height + FBox.Margins.Top + FBox.Margins.Bottom;

  Result := inherited DoSetSize(ASize, NewPlatformDefault, ANewWidth, ANewHeight, ALastWidth, ALastHeight);
end;

procedure TS4YCustomChipHost.FreeStyle;
begin
  FStyleBackground := nil;

  inherited;
end;

function TS4YCustomChipHost.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(320, C_TAG_PRESET_HEIGHTS[tgzMedium] + 2 * C_DEFAULT_INNER_MARGIN_VERTICAL);
end;

function TS4YCustomChipHost.GetHorizontalGap: Single;
begin
  Result := FBox.HorizontalGap;
end;

function TS4YCustomChipHost.GetItems: TStrings;
begin
  Result := FBox.Items;
end;

function TS4YCustomChipHost.GetKind: TS4YTagKind;
begin
  Result := FBox.Kind;
end;

function TS4YCustomChipHost.GetMaxHeight: Single;
begin
  // The box counts its own height, the space of the frame around it is added
  if FBox.MaxHeight > 0 then
    Result := FBox.MaxHeight + FBox.Margins.Top + FBox.Margins.Bottom
  else
    Result := 0;
end;

function TS4YCustomChipHost.GetStyleObject: TFmxObject;
begin
  Result := LookupStyleObject(Self, GetStyleContext, Scene, StyleLookup, GetDefaultStyleLookupName, '', True);

  // The style linked into the package is used when no other style is found.
  if not Assigned(Result) then
    Result := TStyleStreaming.LoadFromResource(HInstance, GetDefaultStyleLookupName, RT_RCDATA);
end;

function TS4YCustomChipHost.GetTabListClass: TTabListClass;
begin
  Result := TS4YChipTabList;
end;

function TS4YCustomChipHost.GetVerticalGap: Single;
begin
  Result := FBox.VerticalGap;
end;

function TS4YCustomChipHost.IsGapStored(const AGap: Single): Boolean;
begin
  Result := not SameValue(AGap, TS4YCustomChipBox.C_DEFAULT_GAP);
end;

function TS4YCustomChipHost.IsHorizontalGapStored: Boolean;
begin
  Result := IsGapStored(FBox.HorizontalGap);
end;

function TS4YCustomChipHost.IsMaxHeightStored: Boolean;
begin
  Result := FBox.MaxHeight <> 0;
end;

function TS4YCustomChipHost.IsVerticalGapStored: Boolean;
begin
  Result := IsGapStored(FBox.VerticalGap);
end;

procedure TS4YCustomChipHost.SetAutoSize(const Value: Boolean);
begin
  if FAutoSize = Value then
    Exit;

  FAutoSize := Value;
  FBox.AutoSize := Value;

  if FAutoSize then
    FBox.Align := TAlignLayout.Top
  else
    FBox.Align := TAlignLayout.Client;

  UpdateHeight;
end;

procedure TS4YCustomChipHost.SetHorizontalGap(const Value: Single);
begin
  FBox.HorizontalGap := Value;
end;

procedure TS4YCustomChipHost.SetItems(const Value: TStrings);
begin
  FBox.Items.Assign(Value);
end;

procedure TS4YCustomChipHost.SetKind(const Value: TS4YTagKind);
begin
  FBox.Kind := Value;
end;

procedure TS4YCustomChipHost.SetMaxHeight(const Value: Single);
begin
  if Value > 0 then
    FBox.MaxHeight := Max(1, Value - FBox.Margins.Top - FBox.Margins.Bottom)
  else
    FBox.MaxHeight := 0;
end;

procedure TS4YCustomChipHost.SetVerticalGap(const Value: Single);
begin
  FBox.VerticalGap := Value;
end;

procedure TS4YCustomChipHost.StyleApplied;
begin
end;

procedure TS4YCustomChipHost.UpdateHeight;
var
  LHeight: Single;
begin
  if FResizing or not FAutoSize or not Assigned(FBox) then
    Exit;

  FResizing := True;
  try
    LHeight := FBox.Height + FBox.Margins.Top + FBox.Margins.Bottom;

    if not SameValue(Height, LHeight, 0.01) then
      SetBounds(Position.X, Position.Y, Width, LHeight);
  finally
    FResizing := False;
  end;
end;

end.
