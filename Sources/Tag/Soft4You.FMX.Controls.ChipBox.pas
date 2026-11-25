unit Soft4You.FMX.Controls.ChipBox;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YCustomChipBox - base of the controls that hold a list of chips
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Types,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.Layouts,
  Soft4You.FMX.Controls.Tag.Types,
  Soft4You.FMX.Controls.Chip;

type
  TS4YCustomChipBox = class;

  /// <summary>
  /// List of the controls that Tab goes through, which also takes the chips and the controls that TS4YChipGroup and TS4YChipEdit make themselves.
  /// </summary>
  /// <remarks>
  /// The list of FMX leaves out the controls that are not saved in the form (Stored False), and these are not: they are made by the control, so they would never be reached with Tab. It takes only these controls and not the parts of the style.
  /// </remarks>
  TS4YChipTabList = class(TTabList)
  protected
    function IsAddable(const TabStop: IControl): Boolean; override;
  end;

  /// <summary>Content of TS4YCustomChipBox: it places the children with the wrapping flow instead of the alignment of FMX.</summary>
  TS4YChipBoxContent = class(TScrollContent)
  protected
    function GetTabListClass: TTabListClass; override;
    procedure DoRealign; override;
  end;

  /// <summary>
  /// Base of TS4YChipGroup and TS4YChipEdit: a scroll box that holds a chip for each text of Items, one after the other and on a new line when the width ends.
  /// </summary>
  /// <remarks>
  /// With AutoSize True, the default, the height follows the lines of chips up to MaxHeight; a longer content scrolls vertically, with the mouse wheel and with the finger.
  /// With AutoSize False the height is the one set and the content scrolls when it does not fit.
  /// The chips are made and freed by the control, they are not saved in the form: the texts are in Items.
  /// The arrow keys, Home and End move the focus among the chips; the chip that takes the focus is scrolled into view.
  /// A descendant can give a control that takes the rest of the last line (FillControl), as the text field of TS4YChipEdit does.
  /// </remarks>
  TS4YCustomChipBox = class(TCustomScrollBox, IS4YChipNavigator)
  public const
    /// <summary>Default value of HorizontalGap and VerticalGap, in pixels.</summary>
    C_DEFAULT_GAP: Single = 8;
    /// <summary>Default value of Kind.</summary>
    C_DEFAULT_KIND = tgkNeutral;
    /// <summary>Default value of Shape.</summary>
    C_DEFAULT_SHAPE = tgsPill;
    /// <summary>Default value of SizePreset on the desktop; on Android and iOS the default is tgzLarge.</summary>
    C_DEFAULT_SIZE_PRESET = tgzMedium;
  private
    FArranging: Boolean;
    FAutoSize: Boolean;
    FChipCornerRadius: Single;
    FChipFontApplied: Boolean;
    FChipFontSizeOverride: Single;
    FChipHeight: Single;
    FChipPadding: Single;
    FChipStyledSettings: TStyledSettings;
    FChipStyleLookup: string;
    FChipTextSettings: TTextSettings;
    FChips: TList<TS4YChip>;
    FFillControl: TControl;
    FFillMinWidth: Single;
    FFlowBounds: TRectF;
    FHorizontalGap: Single;
    FItems: TStringList;
    FKind: TS4YTagKind;
    FMaxHeight: Single;
    FShape: TS4YTagShape;
    FSizePreset: TS4YTagSizePreset;
    FSyncing: Boolean;
    FVariant: TS4YTagVariant;
    FVerticalGap: Single;
    procedure CollectFocusTargets(const ATargets: TList<TControl>);
    function FindVerticalNeighbor(const ATargets: TList<TControl>; const ACurrent: TControl; ADown: Boolean): TControl;
    function GetItems: TStrings;
    function ChipHeightStored: Boolean;
    function MaxHeightStored: Boolean;
    procedure ItemsChanged(Sender: TObject);
    procedure SetAutoSize(const Value: Boolean);
    procedure SetChipHeight(const Value: Single);
    procedure SetChipStyleLookup(const Value: string);
    procedure SetFillControl(const Value: TControl);
    procedure SetHorizontalGap(const Value: Single);
    procedure SetItems(const Value: TStrings);
    procedure SetKind(const Value: TS4YTagKind);
    procedure SetMaxHeight(const Value: Single);
    procedure SetShape(const Value: TS4YTagShape);
    procedure SetSizePreset(const Value: TS4YTagSizePreset);
    procedure SetVariant(const Value: TS4YTagVariant);
    procedure SetVerticalGap(const Value: Single);
    function VerticalGapStored: Boolean;
    function HorizontalGapStored: Boolean;
  protected
    /// <summary>Returns the list of Tab that takes the chips.</summary>
    function GetTabListClass: TTabListClass; override;
    /// <summary>Returns the name of the style of a scroll box: the control has none of its own, and the name made from its class would find no style, so the content would not be placed in the area that shows it.</summary>
    function GetDefaultStyleLookupName: string; override;
    /// <summary>Returns the height of the chips: the one of SizePreset, or ChipHeight with tgzCustom.</summary>
    function GetCurrentChipHeight: Single;
    /// <summary>Returns the size of the font of the chips: the one given, or the one that goes with their height.</summary>
    function GetCurrentChipFontSize: Single;
    /// <summary>Takes the look of the chips from a chip, which a style gives as a model: shape, variant, size, font, padding, corner radius and style. With nil the settings stay as they are. Makes the chips again with the new look.</summary>
    procedure ApplyChipTemplate(const ATemplate: TS4YChip);
    /// <summary>Places the chips again once the style, which gives the area that shows the content, is applied: a box that is out of view gets its style when it comes into view.</summary>
    procedure ApplyStyle; override;
    /// <summary>Places the children one after the other, wrapping at the width of the content, and gives the content its height.</summary>
    procedure ArrangeChips;
    /// <summary>Called when the focus moves among the chips with the arrow keys; returns True when the key is handled.</summary>
    function ChipKeyDown(const AChip: TS4YChip; var Key: Word; Shift: TShiftState): Boolean; virtual;
    /// <summary>Called when a chip takes the focus: scrolls it into view.</summary>
    procedure ChipEntered(const AChip: TS4YChip); virtual;
    /// <summary>Called when a chip loses the focus.</summary>
    procedure ChipExited(const AChip: TS4YChip); virtual;
    /// <summary>Called by SyncChips when the chips match Items again; a descendant uses it for what depends on all the chips.</summary>
    procedure ChipsSynced; virtual;
    /// <summary>Gives the chip its text and the settings of the control; a descendant adds its own.</summary>
    procedure ConfigureChip(const AChip: TS4YChip; AIndex: Integer); virtual;
    /// <summary>Places a new child at the end of the flow.</summary>
    procedure ContentAddObject(const AObject: TFmxObject); override;
    /// <summary>Places the other children again.</summary>
    procedure ContentRemoveObject(const AObject: TFmxObject); override;
    /// <summary>Creates a chip, owned by the control and not saved in the form, and puts it in the content.</summary>
    function CreateChip: TS4YChip; virtual;
    /// <summary>Takes a chip out of the control right away and frees it later: the chip can be the one whose event is running.</summary>
    procedure DisposeChip(const AChip: TS4YChip);
    /// <summary>Creates the content that places the children with the wrapping flow.</summary>
    function CreateScrollContent: TScrollContent; override;
    /// <summary>Returns the size of the flow, for the scroll bars.</summary>
    function DoCalcContentBounds: TRectF; override;
    /// <summary>Scrolls the control, which is in the content, into view.</summary>
    procedure ScrollInView(const AControl: TControl);
    /// <summary>Makes the chips of Items once the form is loaded.</summary>
    procedure Loaded; override;
    /// <summary>Makes, changes and frees the chips so that there is one for each text of Items.</summary>
    procedure SyncChips;

    /// <summary>The chips, one for each text of Items, in the same order.</summary>
    property Chips: TList<TS4YChip> read FChips;
    /// <summary>A control of the content that takes the rest of the line where it is, never less than FillMinWidth wide, and that stays after the chips.</summary>
    property FillControl: TControl read FFillControl write SetFillControl;
    /// <summary>The least width of the FillControl, in pixels.</summary>
    property FillMinWidth: Single read FFillMinWidth write FFillMinWidth;

    /// <summary>When True, the default, the height follows the content up to MaxHeight.</summary>
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;
    /// <summary>Height of the chips in pixels when SizePreset is tgzCustom, not less than 16. The default is 32.</summary>
    property ChipHeight: Single read FChipHeight write SetChipHeight stored ChipHeightStored nodefault;
    /// <summary>Name of the style of the chips, to give them a size of font or a space at the sides that differ from the ones of the chips of the rest of the application. The default, empty, is the style S4YChipStyle.</summary>
    property ChipStyleLookup: string read FChipStyleLookup write SetChipStyleLookup;
    /// <summary>Space between two chips on a line, in pixels.</summary>
    property HorizontalGap: Single read FHorizontalGap write SetHorizontalGap stored HorizontalGapStored nodefault;
    /// <summary>The texts of the chips, one for each chip.</summary>
    property Items: TStrings read GetItems write SetItems;
    /// <summary>Meaning of the chips, which gives them their color. The default is tgkNeutral.</summary>
    property Kind: TS4YTagKind read FKind write SetKind default C_DEFAULT_KIND;
    /// <summary>Largest height of the control in pixels when AutoSize is True: a longer content scrolls. The default, 0, means no limit.</summary>
    property MaxHeight: Single read FMaxHeight write SetMaxHeight stored MaxHeightStored nodefault;
    /// <summary>Shape of the chips. The default is tgsPill.</summary>
    property Shape: TS4YTagShape read FShape write SetShape default C_DEFAULT_SHAPE;
    /// <summary>Size of the chips. The default is tgzMedium, tgzLarge on Android and iOS; tgzCustom takes the height from ChipHeight.</summary>
    property SizePreset: TS4YTagSizePreset read FSizePreset write SetSizePreset default C_DEFAULT_SIZE_PRESET;
    /// <summary>How the color fills the chips: filled, tonal or outlined. The default of TS4YCustomChipBox is tgvOutlined.</summary>
    property Variant: TS4YTagVariant read FVariant write SetVariant;
    /// <summary>Space between two lines of chips, in pixels.</summary>
    property VerticalGap: Single read FVerticalGap write SetVerticalGap stored VerticalGapStored nodefault;
  public
    /// <summary>Creates the control with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Destroys the control and its chips.</summary>
    destructor Destroy; override;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  FMX.Edit;

const
  // Style of a TScrollBox
  C_STYLE_NAME = 'scrollboxstyle';

{ TS4YChipTabList }

function TS4YChipTabList.IsAddable(const TabStop: IControl): Boolean;
var
  LObject: TFmxObject;
begin
  LObject := TabStop.GetObject;

  // Only the chips, the text field and the box of chips, which the controls make and do not store. Nothing else:
  // the parts of a style are controls too, FMX puts them in the list while it applies the style and frees them when the
  // style changes, and a list that keeps them holds references to controls that no longer exist.
  Result := not Supports(TabStop, IContent) and
    ((LObject is TS4YChip) or (LObject is TEdit) or (LObject is TS4YCustomChipBox));
end;

{ TS4YChipBoxContent }

function TS4YChipBoxContent.GetTabListClass: TTabListClass;
begin
  Result := TS4YChipTabList;
end;

procedure TS4YChipBoxContent.DoRealign;
begin
  if ScrollBox is TS4YCustomChipBox then
    TS4YCustomChipBox(ScrollBox).ArrangeChips
  else
    inherited;
end;

{ TS4YCustomChipBox }

constructor TS4YCustomChipBox.Create(AOwner: TComponent);
begin
  inherited;

  FChips := TList<TS4YChip>.Create;
  FChipTextSettings := TTextSettings.Create(Self);
  FItems := TStringList.Create;
  FItems.OnChange := ItemsChanged;
  FAutoSize := True;
  FChipHeight := C_TAG_PRESET_HEIGHTS[tgzMedium];
  FChipCornerRadius := TS4YChip.C_DEFAULT_CORNER_RADIUS;
  FFillMinWidth := 80;
  FHorizontalGap := C_DEFAULT_GAP;
  FKind := C_DEFAULT_KIND;
  FShape := C_DEFAULT_SHAPE;
  FVariant := tgvOutlined;
  FVerticalGap := C_DEFAULT_GAP;

  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  FSizePreset := tgzLarge;
  {$ELSE}
  FSizePreset := C_DEFAULT_SIZE_PRESET;
  {$ENDIF}

  Width := 320;
  Height := GetCurrentChipHeight;
end;

destructor TS4YCustomChipBox.Destroy;
begin
  inherited;
  // After inherited: the destruction of the chips, which the control owns, may still remove them
  FreeAndNil(FChips);
  FreeAndNil(FChipTextSettings);
  FreeAndNil(FItems);
end;

procedure TS4YCustomChipBox.ApplyChipTemplate(const ATemplate: TS4YChip);
begin
  if Assigned(ATemplate) then
  begin
    FVariant := ATemplate.Variant;
    FShape := ATemplate.Shape;
    FSizePreset := ATemplate.SizePreset;
    FChipHeight := ATemplate.Height;
    FChipFontApplied := True;
    FChipTextSettings.Assign(ATemplate.TextSettings);
    FChipStyledSettings := ATemplate.StyledSettings;

    // The size of the model is the one of the chips, unless the model leaves it to its style
    if TStyledSetting.Size in ATemplate.StyledSettings then
      FChipFontSizeOverride := 0
    else
      FChipFontSizeOverride := ATemplate.TextSettings.Font.Size;

    FChipPadding := ATemplate.HorizontalPadding;
    FChipCornerRadius := ATemplate.CornerRadius;
    FChipStyleLookup := ATemplate.StyleLookup;
  end;

  SyncChips;
end;

procedure TS4YCustomChipBox.ApplyStyle;
begin
  inherited;

  // The style gives the area that shows the content: the lines wrap at its width
  ArrangeChips;
end;

procedure TS4YCustomChipBox.ArrangeChips;
var
  LBottom: Single;
  LChild: TControl;
  LDesiredHeight: Single;
  LLeft: Single;
  LLineHeight: Single;
  LRight: Single;
  LViewWidth: Single;
  LWidth: Single;
  LX: Single;
  LY: Single;
begin
  if FArranging or (Content = nil) or (ComponentState * [csLoading, csDestroying] <> []) then
    Exit;

  FArranging := True;
  try
    // The width of the area that shows the content, which is the one the lines wrap at: the width of the content
    // itself would not get narrower when the control does
    if Assigned(ContentLayout) then
      LViewWidth := ContentLayout.Width
    else
      LViewWidth := Width;

    LLeft := Padding.Left;
    LRight := Max(LViewWidth, 1) - Padding.Right;
    LX := LLeft;
    LY := Padding.Top;
    LLineHeight := 0;

    for var LIndex := 0 to Content.ControlsCount - 1 do
    begin
      LChild := Content.Controls[LIndex];

      if LChild.Visible and not Supports(LChild, IDesignerControl) then
      begin
        LWidth := LChild.Width;

        if LChild = FFillControl then
        begin
          // The control takes the rest of the line; with less than its least width it goes to a new line
          if (LX > LLeft) and (LRight - LX - LChild.Margins.Left - LChild.Margins.Right < FFillMinWidth) then
          begin
            LX := LLeft;
            LY := LY + LLineHeight + FVerticalGap;
            LLineHeight := 0;
          end;

          LWidth := Max(1, LRight - LX - LChild.Margins.Left - LChild.Margins.Right);
        end
        else if (LX > LLeft) and (LX + LChild.Margins.Left + LWidth + LChild.Margins.Right > LRight + 0.01) then
        begin
          LX := LLeft;
          LY := LY + LLineHeight + FVerticalGap;
          LLineHeight := 0;
        end;

        if not (SameValue(LChild.Position.X, LX + LChild.Margins.Left, 0.001) and
          SameValue(LChild.Position.Y, LY + LChild.Margins.Top, 0.001) and SameValue(LChild.Width, LWidth, 0.001)) then
          LChild.SetBounds(LX + LChild.Margins.Left, LY + LChild.Margins.Top, LWidth, LChild.Height);

        LX := LX + LChild.Margins.Left + LWidth + LChild.Margins.Right + FHorizontalGap;
        LLineHeight := Max(LLineHeight, LChild.Margins.Top + LChild.Height + LChild.Margins.Bottom);
      end;
    end;

    LBottom := LY + LLineHeight + Padding.Bottom;
    FFlowBounds := TRectF.Create(0, 0, Max(LViewWidth, 0), LBottom);

    if FAutoSize then
    begin
      // The control is as high as its lines, never less than one chip and never more than MaxHeight
      LDesiredHeight := Max(LBottom, GetCurrentChipHeight + Padding.Top + Padding.Bottom);

      if FMaxHeight > 0 then
        LDesiredHeight := Min(LDesiredHeight, FMaxHeight);

      if not SameValue(Height, LDesiredHeight, 0.01) then
        SetBounds(Position.X, Position.Y, Width, LDesiredHeight);
    end;
  finally
    FArranging := False;
  end;

  // The size of the flow changes the scroll bars
  if not InInternalAlign then
    RealignContent;
end;

procedure TS4YCustomChipBox.ChipEntered(const AChip: TS4YChip);
begin
  ScrollInView(AChip);
end;

procedure TS4YCustomChipBox.ChipExited(const AChip: TS4YChip);
begin
end;

function TS4YCustomChipBox.ChipKeyDown(const AChip: TS4YChip; var Key: Word; Shift: TShiftState): Boolean;
var
  LIndex: Integer;
  LTarget: TControl;
  LTargets: TList<TControl>;
begin
  Result := False;
  LTargets := TList<TControl>.Create;
  try
    CollectFocusTargets(LTargets);
    LIndex := LTargets.IndexOf(AChip);

    if LIndex < 0 then
      Exit;

    LTarget := nil;

    case Key of
      vkLeft:
        if LIndex > 0 then
          LTarget := LTargets[LIndex - 1];
      vkRight:
        if LIndex < LTargets.Count - 1 then
          LTarget := LTargets[LIndex + 1];
      vkHome:
        LTarget := LTargets[0];
      vkEnd:
        LTarget := LTargets[LTargets.Count - 1];
      vkUp:
        LTarget := FindVerticalNeighbor(LTargets, AChip, False);
      vkDown:
        LTarget := FindVerticalNeighbor(LTargets, AChip, True);
    end;

    // The key is handled even at the first and the last control: it does not scroll or move elsewhere
    Result := True;

    if Assigned(LTarget) and (LTarget <> AChip) then
      LTarget.SetFocus;
  finally
    LTargets.Free;
  end;
end;

procedure TS4YCustomChipBox.CollectFocusTargets(const ATargets: TList<TControl>);
var
  LChild: TControl;
begin
  for var LIndex := 0 to Content.ControlsCount - 1 do
  begin
    LChild := Content.Controls[LIndex];

    if LChild.Visible and LChild.Enabled and LChild.CanFocus and not Supports(LChild, IDesignerControl) then
      ATargets.Add(LChild);
  end;
end;

procedure TS4YCustomChipBox.ChipsSynced;
begin
end;

procedure TS4YCustomChipBox.ConfigureChip(const AChip: TS4YChip; AIndex: Integer);
begin
  AChip.Text := FItems[AIndex];
  AChip.Kind := FKind;
  AChip.Variant := FVariant;
  AChip.Shape := FShape;
  AChip.SizePreset := FSizePreset;
  AChip.StyleLookup := FChipStyleLookup;

  if FChipFontApplied then
  begin
    AChip.TextSettings.Assign(FChipTextSettings);
    AChip.StyledSettings := FChipStyledSettings;
    AChip.FontSizeOverride := FChipFontSizeOverride;
  end;

  AChip.HorizontalPadding := FChipPadding;
  AChip.CornerRadius := FChipCornerRadius;

  if FSizePreset = tgzCustom then
    AChip.Height := FChipHeight;
end;

procedure TS4YCustomChipBox.ContentAddObject(const AObject: TFmxObject);
begin
  inherited;

  // A new child goes at the end of the flow right away
  ArrangeChips;
end;

procedure TS4YCustomChipBox.ContentRemoveObject(const AObject: TFmxObject);
begin
  inherited;

  if AObject = FFillControl then
    FFillControl := nil;

  ArrangeChips;
end;

function TS4YCustomChipBox.CreateChip: TS4YChip;
begin
  Result := TS4YChip.Create(Self);
  Result.Stored := False;
  Result.Locked := True;
  Result.Parent := Self;
end;

procedure TS4YCustomChipBox.DisposeChip(const AChip: TS4YChip);
begin
  // The chip leaves the control now, so that the lines are right at once, but it is freed after its own event ends
  // (a chip is removed from its own OnClose when the user closes it).
  AChip.Visible := False;
  RemoveComponent(AChip);
  AChip.Parent := nil;
  TThread.ForceQueue(nil,
    procedure
    begin
      AChip.Free;
    end);
end;

function TS4YCustomChipBox.CreateScrollContent: TScrollContent;
begin
  Result := TS4YChipBoxContent.Create(Self);
end;

function TS4YCustomChipBox.DoCalcContentBounds: TRectF;
begin
  Result := FFlowBounds;
end;

function TS4YCustomChipBox.FindVerticalNeighbor(const ATargets: TList<TControl>; const ACurrent: TControl;
  ADown: Boolean): TControl;
const
  C_ROW_TOLERANCE = 1;
var
  LBestDistanceX: Single;
  LBestDistanceY: Single;
  LDistanceX: Single;
  LDistanceY: Single;
  LTarget: TControl;
begin
  // The nearest line above or under, and on it the control whose middle is the nearest to the middle of the current one
  Result := nil;
  LBestDistanceX := MaxSingle;
  LBestDistanceY := MaxSingle;

  for LTarget in ATargets do
  begin
    if ADown then
      LDistanceY := LTarget.Position.Y - ACurrent.Position.Y
    else
      LDistanceY := ACurrent.Position.Y - LTarget.Position.Y;

    if LDistanceY > C_ROW_TOLERANCE then
    begin
      LDistanceX := Abs((LTarget.Position.X + LTarget.Width / 2) - (ACurrent.Position.X + ACurrent.Width / 2));

      if (LDistanceY < LBestDistanceY - C_ROW_TOLERANCE) or
        ((Abs(LDistanceY - LBestDistanceY) <= C_ROW_TOLERANCE) and (LDistanceX < LBestDistanceX)) then
      begin
        Result := LTarget;
        LBestDistanceX := LDistanceX;
        LBestDistanceY := LDistanceY;
      end;
    end;
  end;
end;

function TS4YCustomChipBox.HorizontalGapStored: Boolean;
begin
  Result := not SameValue(FHorizontalGap, C_DEFAULT_GAP);
end;

function TS4YCustomChipBox.GetTabListClass: TTabListClass;
begin
  Result := TS4YChipTabList;
end;

function TS4YCustomChipBox.GetDefaultStyleLookupName: string;
begin
  Result := C_STYLE_NAME;
end;

function TS4YCustomChipBox.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TS4YCustomChipBox.ItemsChanged(Sender: TObject);
begin
  SyncChips;
end;

procedure TS4YCustomChipBox.Loaded;
begin
  inherited;

  SyncChips;
end;

function TS4YCustomChipBox.ChipHeightStored: Boolean;
begin
  Result := not SameValue(FChipHeight, C_TAG_PRESET_HEIGHTS[tgzMedium]);
end;

function TS4YCustomChipBox.GetCurrentChipFontSize: Single;
begin
  if FChipFontSizeOverride > 0 then
    Result := FChipFontSizeOverride
  else
    Result := TagFontSizeOf(GetCurrentChipHeight);
end;

function TS4YCustomChipBox.GetCurrentChipHeight: Single;
begin
  Result := TagHeightOf(FSizePreset, FChipHeight);
end;

function TS4YCustomChipBox.MaxHeightStored: Boolean;
begin
  Result := FMaxHeight <> 0;
end;

procedure TS4YCustomChipBox.ScrollInView(const AControl: TControl);
var
  LViewHeight: Single;
  LViewTop: Single;
begin
  // The scroll box does not scroll a control into view by itself
  if (Content = nil) or (AControl.Parent <> Content) then
    Exit;

  LViewTop := ViewportPosition.Y;
  LViewHeight := ClientHeight;

  if AControl.Position.Y - AControl.Margins.Top < LViewTop then
    ViewportPosition := PointF(ViewportPosition.X, Max(0, AControl.Position.Y - AControl.Margins.Top - Padding.Top))
  else if AControl.Position.Y + AControl.Height + AControl.Margins.Bottom > LViewTop + LViewHeight then
    ViewportPosition := PointF(ViewportPosition.X,
      AControl.Position.Y + AControl.Height + AControl.Margins.Bottom + Padding.Bottom - LViewHeight);
end;

procedure TS4YCustomChipBox.SetAutoSize(const Value: Boolean);
begin
  if FAutoSize = Value then
    Exit;

  FAutoSize := Value;
  ArrangeChips;
end;

procedure TS4YCustomChipBox.SetChipHeight(const Value: Single);
begin
  if SameValue(FChipHeight, Value) then
    Exit;

  FChipHeight := Value;

  if FSizePreset = tgzCustom then
    SyncChips;
end;

procedure TS4YCustomChipBox.SetChipStyleLookup(const Value: string);
begin
  if FChipStyleLookup = Value then
    Exit;

  FChipStyleLookup := Value;
  SyncChips;
end;

procedure TS4YCustomChipBox.SetFillControl(const Value: TControl);
begin
  FFillControl := Value;
  ArrangeChips;
end;

procedure TS4YCustomChipBox.SetHorizontalGap(const Value: Single);
begin
  if SameValue(FHorizontalGap, Value) then
    Exit;

  FHorizontalGap := Max(0, Value);
  ArrangeChips;
end;

procedure TS4YCustomChipBox.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TS4YCustomChipBox.SetKind(const Value: TS4YTagKind);
begin
  if FKind = Value then
    Exit;

  FKind := Value;
  SyncChips;
end;

procedure TS4YCustomChipBox.SetMaxHeight(const Value: Single);
begin
  if SameValue(FMaxHeight, Value) then
    Exit;

  FMaxHeight := Max(0, Value);
  ArrangeChips;
end;

procedure TS4YCustomChipBox.SetShape(const Value: TS4YTagShape);
begin
  if FShape = Value then
    Exit;

  FShape := Value;
  SyncChips;
end;

procedure TS4YCustomChipBox.SetSizePreset(const Value: TS4YTagSizePreset);
begin
  if FSizePreset = Value then
    Exit;

  FSizePreset := Value;
  SyncChips;
end;

procedure TS4YCustomChipBox.SetVariant(const Value: TS4YTagVariant);
begin
  if FVariant = Value then
    Exit;

  FVariant := Value;
  SyncChips;
end;

procedure TS4YCustomChipBox.SetVerticalGap(const Value: Single);
begin
  if SameValue(FVerticalGap, Value) then
    Exit;

  FVerticalGap := Max(0, Value);
  ArrangeChips;
end;

procedure TS4YCustomChipBox.SyncChips;
var
  LChip: TS4YChip;
begin
  if FSyncing or (FChips = nil) or (FItems = nil) or (csDestroying in ComponentState) then
    Exit;

  FSyncing := True;
  try
    for var LIndex := 0 to FItems.Count - 1 do
    begin
      if LIndex < FChips.Count then
      begin
        LChip := FChips[LIndex];
      end
      else
      begin
        LChip := CreateChip;
        FChips.Add(LChip);
      end;

      ConfigureChip(LChip, LIndex);
    end;

    while FChips.Count > FItems.Count do
    begin
      LChip := FChips[FChips.Count - 1];
      FChips.Delete(FChips.Count - 1);
      DisposeChip(LChip);
    end;

    // The control that takes the rest of the line stays after the chips, also for Tab
    if Assigned(FFillControl) then
    begin
      FFillControl.BringToFront;
      FFillControl.TabOrder := FChips.Count;
    end;
  finally
    FSyncing := False;
  end;

  ChipsSynced;
  ArrangeChips;
end;

function TS4YCustomChipBox.VerticalGapStored: Boolean;
begin
  Result := not SameValue(FVerticalGap, C_DEFAULT_GAP);
end;

end.
