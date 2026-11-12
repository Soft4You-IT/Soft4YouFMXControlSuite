unit Soft4You.FMX.Controls.StepProgressBar;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YStepProgressBar - progress indicator made of steps along a line
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
  FMX.Graphics,
  FMX.Objects,
  FMX.ImgList,
  FMX.Ani,
  FMX.TextLayout,
  Soft4You.FMX.Controls.StepProgressBar.Types;

type
  TS4YStepProgressBar = class;

  /// <summary>
  /// A step of a TS4YStepProgressBar.
  /// </summary>
  /// <remarks>
  /// The steps are defined by the application, for example the phases of an installation. The state in which a step is drawn comes from its position compared to the current step of the control, or from Failed.
  /// </remarks>
  TS4YStepItem = class(TCollectionItem)
  public const
    /// <summary>Default value of ImageIndex: no image of its own.</summary>
    C_DEFAULT_IMAGE_INDEX = -1;
  private
    FCaption: string;
    FDescription: string;
    FFailed: Boolean;
    FImageIndex: TImageIndex;
    FTag: NativeInt;
    procedure SetCaption(const Value: string);
    procedure SetDescription(const Value: string);
    procedure SetFailed(const Value: Boolean);
    procedure SetImageIndex(const Value: TImageIndex);
  protected
    /// <summary>Returns the caption of the step, shown by the collection editor of the IDE.</summary>
    function GetDisplayName: string; override;
  public
    /// <summary>Creates a step without caption and without image.</summary>
    constructor Create(Collection: TCollection); override;

    /// <summary>Copies all the properties from another TS4YStepItem.</summary>
    procedure Assign(Source: TPersistent); override;
  published
    /// <summary>Text shown next to the marker of the step, on the side given by LabelPosition of the control.</summary>
    property Caption: string read FCaption write SetCaption;
    /// <summary>Second line of text, shown under the caption with the font of the description of the style.</summary>
    property Description: string read FDescription write SetDescription;
    /// <summary>True draws the step in the failed state, whatever its position compared to the current step. The default is False.</summary>
    property Failed: Boolean read FFailed write SetFailed default False;
    /// <summary>Image of the step in the Images list of the control, shown when the marker settings of its state have Content = smcImage and ImageIndex = -1. The default is -1, no image.</summary>
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default C_DEFAULT_IMAGE_INDEX;
    /// <summary>A value free for the application. The control does not use it.</summary>
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  /// <summary>
  /// The steps of a TS4YStepProgressBar.
  /// </summary>
  TS4YStepItems = class(TOwnedCollection)
  private
    [Weak] FProgressBar: TS4YStepProgressBar;
    function GetItem(Index: Integer): TS4YStepItem;
    procedure SetItem(Index: Integer; const Value: TS4YStepItem);
  protected
    /// <summary>Tells the control that a step has been added, removed or changed.</summary>
    procedure Update(Item: TCollectionItem); override;
  public
    /// <summary>Creates the collection of the steps of AProgressBar.</summary>
    constructor Create(const AProgressBar: TS4YStepProgressBar);

    /// <summary>Adds a new step at the end and returns it.</summary>
    function Add: TS4YStepItem;

    /// <summary>The steps, in their order along the line.</summary>
    property Items[Index: Integer]: TS4YStepItem read GetItem write SetItem; default;
  end;

  /// <summary>
  /// How the markers of the steps in one state are drawn.
  /// </summary>
  /// <remarks>
  /// The marker is the part of the style for its state. When that part is a shape, Fill or Stroke can replace its fill and its border (see StyledBrushes); a part made of several objects is drawn as the style defines it. Content says what is drawn inside the marker.
  /// </remarks>
  TS4YStepMarkerSettings = class(TPersistent)
  public const
    /// <summary>Default value of Content.</summary>
    C_DEFAULT_CONTENT = smcNumber;
    /// <summary>Default value of ImageIndex: the image of the step.</summary>
    C_DEFAULT_IMAGE_INDEX = -1;
    /// <summary>Default value of StyledBrushes: both the fill and the border come from the style.</summary>
    C_DEFAULT_STYLED_BRUSHES: TS4YStepMarkerStyledBrushes = [smbFill, smbStroke];
  private
    FContent: TS4YStepMarkerContent;
    FDefaultFillColor: TAlphaColor;
    FDefaultStrokeColor: TAlphaColor;
    FFill: TBrush;
    FImageIndex: TImageIndex;
    FStroke: TStrokeBrush;
    FStyledBrushes: TS4YStepMarkerStyledBrushes;
    FUpdating: Boolean;
    FOnChange: TNotifyEvent;
    procedure DoChange;
    procedure FillChanged(Sender: TObject);
    procedure SetContent(const Value: TS4YStepMarkerContent);
    procedure SetFill(const Value: TBrush);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetStroke(const Value: TStrokeBrush);
    procedure SetStyledBrushes(const Value: TS4YStepMarkerStyledBrushes);
    procedure StrokeChanged(Sender: TObject);
    function StyledBrushesStored: Boolean;
  public
    /// <summary>Creates the settings; ADefaultFillColor and ADefaultStrokeColor are the initial colors of Fill and Stroke.</summary>
    constructor Create(const ADefaultFillColor, ADefaultStrokeColor: TAlphaColor);
    destructor Destroy; override;

    /// <summary>Copies all the settings from another TS4YStepMarkerSettings.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>What is drawn inside the marker: nothing, the number of the step or an image. The default is smcNumber.</summary>
    property Content: TS4YStepMarkerContent read FContent write SetContent default C_DEFAULT_CONTENT;
    /// <summary>Fill of the marker. Changing it makes the markers use it instead of the fill of the style (see StyledBrushes).</summary>
    property Fill: TBrush read FFill write SetFill;
    /// <summary>Image drawn when Content is smcImage, in the Images list of the control. With -1, the default, each step shows its own ImageIndex.</summary>
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default C_DEFAULT_IMAGE_INDEX;
    /// <summary>Border of the marker. Changing it makes the markers use it instead of the border of the style (see StyledBrushes).</summary>
    property Stroke: TStrokeBrush read FStroke write SetStroke;
    /// <summary>
    /// Which brushes of the marker come from the style: the fill (smbFill) and the border (smbStroke). A brush that is not in the set is taken from Fill or Stroke.
    /// </summary>
    /// <remarks>
    /// Changing Fill or Stroke removes the matching brush from the set. Putting a brush back in the set makes the markers read it from the style again.
    /// </remarks>
    // Must stay after Fill and Stroke: while streaming, modifying them switches the matching brush
    // off, so an explicit StyledBrushes stored in the form has to be read last to win.
    property StyledBrushes: TS4YStepMarkerStyledBrushes read FStyledBrushes write SetStyledBrushes stored StyledBrushesStored nodefault;
  end;

  /// <summary>
  /// How the line that joins the markers is drawn.
  /// </summary>
  /// <remarks>
  /// With HighlightProgress of the control set to True, the line up to the current step is drawn with the part linecompleted of the style and the rest with linepending; with False, the whole line uses linepending. When a part is a shape, CompletedFill or PendingFill can replace its fill (see StyledBrushes).
  /// </remarks>
  TS4YStepLineSettings = class(TPersistent)
  public const
    /// <summary>Default color of CompletedFill.</summary>
    C_DEFAULT_COMPLETED_COLOR: TAlphaColor = $FF1E88E5;
    /// <summary>Default color of PendingFill.</summary>
    C_DEFAULT_PENDING_COLOR: TAlphaColor = $FFE0E0E0;
    /// <summary>Default value of StyledBrushes: both brushes come from the style.</summary>
    C_DEFAULT_STYLED_BRUSHES: TS4YStepLineStyledBrushes = [slbCompleted, slbPending];
    /// <summary>Default value of Visible.</summary>
    C_DEFAULT_VISIBLE = True;
  private
    FCompletedFill: TBrush;
    FPendingFill: TBrush;
    FStyledBrushes: TS4YStepLineStyledBrushes;
    FUpdating: Boolean;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    procedure CompletedFillChanged(Sender: TObject);
    procedure DoChange;
    procedure PendingFillChanged(Sender: TObject);
    procedure SetCompletedFill(const Value: TBrush);
    procedure SetPendingFill(const Value: TBrush);
    procedure SetStyledBrushes(const Value: TS4YStepLineStyledBrushes);
    procedure SetVisible(const Value: Boolean);
    function StyledBrushesStored: Boolean;
  public
    /// <summary>Creates the settings with the default colors.</summary>
    constructor Create;
    destructor Destroy; override;

    /// <summary>Copies all the settings from another TS4YStepLineSettings.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when a setting changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Brush of the part of the line already covered by the progress. Changing it makes the line use it instead of the one of the style (see StyledBrushes).</summary>
    property CompletedFill: TBrush read FCompletedFill write SetCompletedFill;
    /// <summary>Brush of the part of the line still to cover. Changing it makes the line use it instead of the one of the style (see StyledBrushes).</summary>
    property PendingFill: TBrush read FPendingFill write SetPendingFill;
    /// <summary>
    /// Which brushes of the line come from the style: the completed part (slbCompleted) and the pending part (slbPending). A brush that is not in the set is taken from CompletedFill or PendingFill.
    /// </summary>
    /// <remarks>
    /// Changing CompletedFill or PendingFill removes the matching brush from the set.
    /// </remarks>
    // Must stay after CompletedFill and PendingFill, for the same reason as in TS4YStepMarkerSettings.
    property StyledBrushes: TS4YStepLineStyledBrushes read FStyledBrushes write SetStyledBrushes stored StyledBrushesStored nodefault;
    /// <summary>
    /// False hides the line: only the markers and the labels are drawn. The default is True.
    /// </summary>
    /// <remarks>
    /// Without the line the change of the current step is not animated, and HighlightProgress, LineSpacing and LineThickness of the control have no effect.
    /// </remarks>
    property Visible: Boolean read FVisible write SetVisible default C_DEFAULT_VISIBLE;
  end;

  /// <summary>
  /// Width and height of the markers of a TS4YStepProgressBar.
  /// </summary>
  /// <remarks>
  /// Width and Height are the sizes on the screen, also when the line is vertical.
  /// </remarks>
  TS4YStepMarkerSize = class(TPersistent)
  public const
    /// <summary>Default value of Width and Height, in pixels.</summary>
    C_DEFAULT_SIZE: Single = 28;
  private
    FHeight: Single;
    FWidth: Single;
    FOnChange: TNotifyEvent;
    procedure DoChange;
    function HeightStored: Boolean;
    procedure SetHeight(const Value: Single);
    procedure SetWidth(const Value: Single);
    function WidthStored: Boolean;
  public
    /// <summary>Creates the size with the default width and height.</summary>
    constructor Create;

    /// <summary>Copies the width and the height from another TS4YStepMarkerSize.</summary>
    procedure Assign(Source: TPersistent); override;

    /// <summary>Fires when the width or the height changes.</summary>
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// <summary>Height of the markers, in pixels. The default is 28.</summary>
    property Height: Single read FHeight write SetHeight stored HeightStored nodefault;
    /// <summary>Width of the markers, in pixels. The default is 28.</summary>
    property Width: Single read FWidth write SetWidth stored WidthStored nodefault;
  end;

  /// <summary>
  /// A progress indicator made of steps along a horizontal or vertical line, for example the phases of an installation.
  /// </summary>
  /// <remarks>
  /// The steps are defined in Steps; CurrentStep, NextStep and PreviousStep say which one is in progress. The steps before the current one are drawn as completed, the ones after it as pending, and a step with Failed = True as failed.
  /// Each step has a marker, an ellipse by default (a circle with the default square size), and optionally a caption and a description. The look comes from a style: its parts linecompleted, linepending, completedmarker, currentmarker, pendingmarker, failedmarker and focusframe can be any graphic object (a shape, a path, a layout with several objects) and are drawn as they are, resized to the stretch of line or to the marker; its texts completedtext, currenttext, pendingtext, failedtext (number in the marker), completedlabel, currentlabel, pendinglabel, failedlabel and description give fonts and colors.
  /// OnDrawMarker and OnDrawLine draw the markers and the line in place of the style. Interactions lets the user change the current step with the mouse or the keyboard.
  /// </remarks>
  TS4YStepProgressBar = class(TStyledControl)
  public const
    /// <summary>Default value of AnimationDuration, in seconds.</summary>
    C_DEFAULT_ANIMATION_DURATION: Single = 0.3;
    /// <summary>Default value of HighlightProgress.</summary>
    C_DEFAULT_HIGHLIGHT_PROGRESS = True;
    /// <summary>Default value of LabelPosition.</summary>
    C_DEFAULT_LABEL_POSITION = slpAfter;
    /// <summary>Default value of LabelSpacing, in pixels.</summary>
    C_DEFAULT_LABEL_SPACING: Single = 6;
    /// <summary>Default value of LineSpacing, in pixels.</summary>
    C_DEFAULT_LINE_SPACING: Single = 0;
    /// <summary>Default value of LineThickness, in pixels.</summary>
    C_DEFAULT_LINE_THICKNESS: Single = 3;
    /// <summary>Default value of MarkerPosition.</summary>
    C_DEFAULT_MARKER_POSITION = smpCenter;
    /// <summary>Default value of Orientation.</summary>
    C_DEFAULT_ORIENTATION = TOrientation.Horizontal;
    /// <summary>Default fill and border color of the completed markers.</summary>
    C_DEFAULT_COMPLETED_COLOR: TAlphaColor = $FF1E88E5;
    /// <summary>Default fill color of the current marker.</summary>
    C_DEFAULT_CURRENT_FILL_COLOR: TAlphaColor = $FFFFFFFF;
    /// <summary>Default border color of the current marker.</summary>
    C_DEFAULT_CURRENT_STROKE_COLOR: TAlphaColor = $FF1E88E5;
    /// <summary>Default fill color of the pending markers.</summary>
    C_DEFAULT_PENDING_FILL_COLOR: TAlphaColor = $FFFFFFFF;
    /// <summary>Default border color of the pending markers.</summary>
    C_DEFAULT_PENDING_STROKE_COLOR: TAlphaColor = $FFBDBDBD;
    /// <summary>Default fill and border color of the failed markers.</summary>
    C_DEFAULT_FAILED_COLOR: TAlphaColor = $FFE53935;
  private
    FAnimationDuration: Single;
    FCompletedMarker: TS4YStepMarkerSettings;
    FCurrentMarker: TS4YStepMarkerSettings;
    FCurrentStep: Integer;
    FCursorBeforeHand: TCursor;
    FDefaultFont: TFont;
    FDisplayedProgress: Single;
    FFailedMarker: TS4YStepMarkerSettings;
    FFocusFramePart: TControl;
    FHandCursorShown: Boolean;
    FHighlightProgress: Boolean;
    FImages: TCustomImageList;
    FInteractions: TS4YStepInteractions;
    FLabelPosition: TS4YStepLabelPosition;
    FLabelSpacing: Single;
    FLine: TS4YStepLineSettings;
    FLineAnimation: TAnimation;
    FLineParts: array[TS4YStepLineStyledBrush] of TControl;
    FLineSpacing: Single;
    FLineThickness: Single;
    FMarkerParts: array[TS4YStepState] of TControl;
    FMarkerPosition: TS4YStepMarkerPosition;
    FMarkerSize: TS4YStepMarkerSize;
    FOrientation: TOrientation;
    FPartsContainer: TControl;
    FPendingMarker: TS4YStepMarkerSettings;
    FSteps: TS4YStepItems;
    FStyleDescription: TText;
    FStyleLabels: array[TS4YStepState] of TText;
    FStyleMarkerTexts: array[TS4YStepState] of TText;
    FTextLayout: TTextLayout;
    FOnDrawLine: TS4YStepDrawLineEvent;
    FOnDrawMarker: TS4YStepDrawMarkerEvent;
    FOnStepChanged: TNotifyEvent;
    FOnStepChanging: TS4YStepChangingEvent;
    procedure AnimateProgress(const ATargetProgress: Single);
    function AnimationDurationStored: Boolean;
    function CalculateLabelRect(const AStepIndex, AStepCount: Integer): TRectF;
    function CalculateLineRect(const AFrom, ATo, ALineCenter: Single): TRectF;
    function CalculateMarkerCenter(const AStepIndex, AStepCount: Integer): TPointF;
    function CalculateMarkerRect(const AStepIndex, AStepCount: Integer): TRectF;
    function CalculateStepCenter(const AStepIndex, AStepCount: Integer): Single;
    procedure CalculateTrack(out ATrackStart, ATrackEnd, AMarkerCenter, ALineCenter: Single);
    function ChangeStep(const ANewStep: Integer): Boolean;
    function ClampStep(const AStep: Integer): Integer;
    function CreatePart(const AStyleName: string; out FromStyle: Boolean): TControl;
    procedure DrawFocusFrame(const AStepCount: Integer);
    procedure DrawLine(const AStepCount: Integer);
    procedure DrawLineStretch(const AFromStep: Integer; const AFrom, ATo, ALineCenter: Single; Completed: Boolean);
    procedure DrawMarker(const AStepIndex, AStepCount: Integer);
    procedure DrawMarkerContent(const AStepIndex: Integer; const AState: TS4YStepState; const AMarkerRect: TRectF);
    procedure DrawPart(const APart: TControl; const ARect: TRectF);
    procedure EnsureParts;
    procedure DrawStepLabel(const AStepIndex, AStepCount: Integer);
    function FindStepAt(const APoint: TPointF): Integer;
    procedure FreeParts;
    function GetContentRect: TRectF;
    function GetLabelHorizontalAlign: TTextAlign;
    function GetLabelVerticalAlign: TTextAlign;
    function GetMarkerAcrossLine: Single;
    function GetMarkerAlongLine: Single;
    function GetMarkerSettings(const AState: TS4YStepState): TS4YStepMarkerSettings;
    function GetStepCount: Integer;
    function GetStepState(const AStepIndex: Integer): TS4YStepState;
    function IsAnimating: Boolean;
    function IsProgressHighlighted: Boolean;
    function LabelSpacingStored: Boolean;
    function LineSpacingStored: Boolean;
    function LineThicknessStored: Boolean;
    function MeasureTextHeight(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string;
      const AWidth: Single): Single;
    procedure PrepareTextLayout(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string;
      const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign; WordWrap: Boolean);
    procedure RenderText(const ATemplate: TText; const ADefaultColor: TAlphaColor; const AText: string;
      const ARect: TRectF; const AHorizontalAlign: TTextAlign);
    procedure SetAnimationDuration(const Value: Single);
    procedure SetCompletedMarker(const Value: TS4YStepMarkerSettings);
    procedure SetCurrentMarker(const Value: TS4YStepMarkerSettings);
    procedure SetCurrentStep(const Value: Integer);
    procedure SetDisplayedProgress(const Value: Single);
    procedure SetFailedMarker(const Value: TS4YStepMarkerSettings);
    procedure SetHighlightProgress(const Value: Boolean);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetInteractions(const Value: TS4YStepInteractions);
    procedure SetLabelPosition(const Value: TS4YStepLabelPosition);
    procedure SetLabelSpacing(const Value: Single);
    procedure SetLine(const Value: TS4YStepLineSettings);
    procedure SetLineSpacing(const Value: Single);
    procedure SetLineThickness(const Value: Single);
    procedure SetMarkerPosition(const Value: TS4YStepMarkerPosition);
    procedure SetMarkerSize(const Value: TS4YStepMarkerSize);
    procedure SetOrientation(const Value: TOrientation);
    procedure SetPendingMarker(const Value: TS4YStepMarkerSettings);
    procedure SetSteps(const Value: TS4YStepItems);
    procedure SettingsChanged(Sender: TObject);
    procedure SizeChanged(Sender: TObject);
    procedure StepsChanged;
    procedure UpdateHandCursor(const APoint: TPointF);
  protected
    /// <summary>Finds the texts of the style and prepares the graphic parts again.</summary>
    procedure ApplyStyle; override;
    /// <summary>Fires OnDrawLine; returns True when the event has drawn the stretch of line.</summary>
    function DoDrawLine(const ACanvas: TCanvas; const ARect: TRectF; const AFromStep: Integer;
      const Completed: Boolean): Boolean; virtual;
    /// <summary>Fires OnDrawMarker; returns True when the event has drawn the marker.</summary>
    function DoDrawMarker(const ACanvas: TCanvas; const ARect: TRectF; const AStepIndex: Integer;
      const AState: TS4YStepState): Boolean; virtual;
    /// <summary>Shows the focus frame when the control receives the focus.</summary>
    procedure DoEnter; override;
    /// <summary>Hides the focus frame when the control loses the focus.</summary>
    procedure DoExit; override;
    /// <summary>Gives back the mouse pointer the control had before the hand of stiHandCursor.</summary>
    procedure DoMouseLeave; override;
    /// <summary>Fires OnStepChanged.</summary>
    procedure DoStepChanged; virtual;
    /// <summary>Fires OnStepChanging; returns False when the event does not allow the change.</summary>
    function DoStepChanging(const ANewStep: Integer): Boolean; virtual;
    /// <summary>Releases the parts of the style.</summary>
    procedure FreeStyle; override;
    /// <summary>Returns the size of a new control: 400 x 64.</summary>
    function GetDefaultSize: TSizeF; override;
    /// <summary>Returns the style of the control: the one named by StyleLookup or, when it is empty, the one named S4YStepProgressBarStyle in the style book or in the active style; else the default style linked into the package.</summary>
    function GetStyleObject: TFmxObject; override;
    /// <summary>Moves the current step with the arrow keys, Home and End when Interactions has stiKeyboard.</summary>
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    /// <summary>Brings CurrentStep into the range of the loaded steps.</summary>
    procedure Loaded; override;
    /// <summary>Makes the clicked step the current one when Interactions has stiClickMarker or stiClickLabel.</summary>
    procedure MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    /// <summary>Shows the hand over the steps that a click can select when Interactions has stiHandCursor.</summary>
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    /// <summary>Forgets Images when the image list is destroyed.</summary>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// <summary>Draws the line, the markers and the labels of the steps.</summary>
    procedure Paint; override;
  public
    /// <summary>Creates the control without steps and with the default settings.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>Makes the next step the current one. Returns False when the current step is already the last one, or when OnStepChanging does not allow the change.</summary>
    function NextStep: Boolean;
    /// <summary>Makes the previous step the current one. Returns False when the current step is already the first one, or when OnStepChanging does not allow the change.</summary>
    function PreviousStep: Boolean;
  published
    property Align;
    property Anchors;
    /// <summary>Duration in seconds of the filling of the line when the current step changes. With 0 the change is immediate. The default is 0.3.</summary>
    property AnimationDuration: Single read FAnimationDuration write SetAnimationDuration stored AnimationDurationStored nodefault;
    /// <summary>How the markers of the steps before the current one are drawn.</summary>
    property CompletedMarker: TS4YStepMarkerSettings read FCompletedMarker write SetCompletedMarker;
    /// <summary>How the marker of the current step is drawn.</summary>
    property CurrentMarker: TS4YStepMarkerSettings read FCurrentMarker write SetCurrentMarker;
    /// <summary>
    /// Index of the step in progress, from 0. The steps before it are drawn as completed and the ones after it as pending.
    /// </summary>
    /// <remarks>
    /// A value out of the range of the steps is brought to the first or the last step. Changing it fires OnStepChanging and OnStepChanged.
    /// </remarks>
    property CurrentStep: Integer read FCurrentStep write SetCurrentStep default 0;
    property Cursor;
    property Enabled;
    /// <summary>How the markers of the steps with Failed = True are drawn.</summary>
    property FailedMarker: TS4YStepMarkerSettings read FFailedMarker write SetFailedMarker;
    property Height;
    /// <summary>True draws the part of the line up to the current step with the completed brush of Line; False draws the whole line with the pending brush. The default is True.</summary>
    property HighlightProgress: Boolean read FHighlightProgress write SetHighlightProgress default C_DEFAULT_HIGHLIGHT_PROGRESS;
    property HitTest;
    /// <summary>Images shown in the markers whose settings have Content = smcImage.</summary>
    property Images: TCustomImageList read FImages write SetImages;
    /// <summary>
    /// The ways in which the user can change the current step: a click on the markers (stiClickMarker) or on the labels (stiClickLabel), the hand pointer over them (stiHandCursor) and the keyboard (stiKeyboard). The default is [], an indicator only.
    /// </summary>
    /// <remarks>
    /// With stiKeyboard the control can receive the focus, and shows it with a frame around the current marker.
    /// </remarks>
    property Interactions: TS4YStepInteractions read FInteractions write SetInteractions default [];
    /// <summary>Side of the markers and the line where the captions and the descriptions are shown, or slpNone to hide them. The default is slpAfter: below a horizontal line, on the right of a vertical one.</summary>
    property LabelPosition: TS4YStepLabelPosition read FLabelPosition write SetLabelPosition default C_DEFAULT_LABEL_POSITION;
    /// <summary>Space between the labels and the markers, or the line when it is beside the markers on the side of the labels, in pixels. The default is 6.</summary>
    property LabelSpacing: Single read FLabelSpacing write SetLabelSpacing stored LabelSpacingStored nodefault;
    /// <summary>Brushes and visibility of the line that joins the markers.</summary>
    property Line: TS4YStepLineSettings read FLine write SetLine;
    /// <summary>
    /// Space between the markers and the line, in pixels. The default is 0.
    /// </summary>
    /// <remarks>
    /// With MarkerPosition = smpCenter it is the space along the line between a marker and the stretches of line that reach it; with the markers beside the line it is the space between the markers and the line.
    /// A negative value makes the line go under the markers or overlap them.
    /// </remarks>
    property LineSpacing: Single read FLineSpacing write SetLineSpacing stored LineSpacingStored nodefault;
    /// <summary>Thickness of the line, in pixels. The default is 3.</summary>
    property LineThickness: Single read FLineThickness write SetLineThickness stored LineThicknessStored nodefault;
    property Margins;
    /// <summary>Where the markers are drawn compared to the line: on it (smpCenter, the default), above or on its left (smpBefore), below or on its right (smpAfter).</summary>
    property MarkerPosition: TS4YStepMarkerPosition read FMarkerPosition write SetMarkerPosition default C_DEFAULT_MARKER_POSITION;
    /// <summary>Width and height of the markers, in pixels. The default is 28 x 28.</summary>
    property MarkerSize: TS4YStepMarkerSize read FMarkerSize write SetMarkerSize;
    property Opacity;
    /// <summary>Direction of the line: horizontal, with the steps from left to right, or vertical, from top to bottom. The default is horizontal.</summary>
    property Orientation: TOrientation read FOrientation write SetOrientation default C_DEFAULT_ORIENTATION;
    property Padding;
    /// <summary>How the markers of the steps after the current one are drawn.</summary>
    property PendingMarker: TS4YStepMarkerSettings read FPendingMarker write SetPendingMarker;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Size;
    /// <summary>The steps, in their order along the line.</summary>
    property Steps: TS4YStepItems read FSteps write SetSteps;
    property StyleLookup;
    property TabOrder;
    property TabStop;
    property Visible;
    property Width;

    property OnClick;
    property OnDblClick;
    /// <summary>Fires before each stretch of the line is drawn: setting Handled to True replaces the part of the style with what the event draws.</summary>
    property OnDrawLine: TS4YStepDrawLineEvent read FOnDrawLine write FOnDrawLine;
    /// <summary>Fires before a marker is drawn: setting Handled to True replaces the part of the style with what the event draws.</summary>
    property OnDrawMarker: TS4YStepDrawMarkerEvent read FOnDrawMarker write FOnDrawMarker;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    /// <summary>Fires after the current step has changed.</summary>
    property OnStepChanged: TNotifyEvent read FOnStepChanged write FOnStepChanged;
    /// <summary>Fires before the current step changes; setting Allow to False keeps the current step.</summary>
    property OnStepChanging: TS4YStepChangingEvent read FOnStepChanging write FOnStepChanging;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  FMX.Styles;

{$IFDEF MACOS}
{$R *.mac.res}
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R *.win.res}
{$ENDIF}

type
  /// <summary>Animation that moves the end of the completed part of the line towards a step.</summary>
  TS4YStepProgressAnimation = class(TAnimation)
  private
    [Weak] FProgressBar: TS4YStepProgressBar;
    FStartProgress: Single;
    FTargetProgress: Single;
  protected
    procedure ProcessAnimation; override;
  public
    constructor Create(const AProgressBar: TS4YStepProgressBar); reintroduce;

    property StartProgress: Single read FStartProgress write FStartProgress;
    property TargetProgress: Single read FTargetProgress write FTargetProgress;
  end;

const
  C_STYLE_DESCRIPTION = 'description';
  C_STYLE_FOCUS_FRAME = 'focusframe';
  C_STYLE_MARKERS: array[TS4YStepState] of string = ('completedmarker', 'currentmarker', 'pendingmarker', 'failedmarker');
  C_STYLE_MARKER_TEXTS: array[TS4YStepState] of string = ('completedtext', 'currenttext', 'pendingtext', 'failedtext');
  C_STYLE_LABELS: array[TS4YStepState] of string = ('completedlabel', 'currentlabel', 'pendinglabel', 'failedlabel');

  // Colors used when the style has no text part of that name.
  C_DEFAULT_MARKER_TEXT_COLORS: array[TS4YStepState] of TAlphaColor = ($FFFFFFFF, $FF1E88E5, $FF9E9E9E, $FFFFFFFF);
  C_DEFAULT_LABEL_COLORS: array[TS4YStepState] of TAlphaColor = ($FF424242, $FF212121, $FF9E9E9E, $FFE53935);
  C_DEFAULT_DESCRIPTION_COLOR: TAlphaColor = $FF757575;
  // Border of the focus frame used when the style has no focusframe part.
  C_DEFAULT_FOCUS_FRAME_COLOR: TAlphaColor = $FF1E88E5;
  C_DEFAULT_FOCUS_FRAME_THICKNESS = 1.5;
  C_STYLE_LINES: array[TS4YStepLineStyledBrush] of string = ('linecompleted', 'linepending');

  // Space between a marker and the focus frame around it, in pixels.
  C_FOCUS_FRAME_SPACING = 3;
  // Space between the border of a marker and its image, as a fraction of the width and the height of MarkerSize.
  C_MARKER_IMAGE_MARGIN = 0.2;
  // Height given to a text while it is measured: large enough for any label.
  C_MEASURE_HEIGHT = 10000;
  // Steps drawn at design time while Steps is empty, so that the control can be seen and placed.
  C_DESIGN_PREVIEW_STEP_COUNT = 3;
  C_DESIGN_PREVIEW_CURRENT_STEP = 1;

{ TS4YStepProgressAnimation }

constructor TS4YStepProgressAnimation.Create(const AProgressBar: TS4YStepProgressBar);
begin
  inherited Create(AProgressBar);

  FProgressBar := AProgressBar;
end;

procedure TS4YStepProgressAnimation.ProcessAnimation;
begin
  if Assigned(FProgressBar) then
    FProgressBar.SetDisplayedProgress(FStartProgress + (FTargetProgress - FStartProgress) * NormalizedTime);
end;

{ TS4YStepItem }

constructor TS4YStepItem.Create(Collection: TCollection);
begin
  inherited;

  FImageIndex := C_DEFAULT_IMAGE_INDEX;
end;

procedure TS4YStepItem.Assign(Source: TPersistent);
var
  LSource: TS4YStepItem;
begin
  if Source is TS4YStepItem then
  begin
    LSource := TS4YStepItem(Source);
    FCaption := LSource.Caption;
    FDescription := LSource.Description;
    FFailed := LSource.Failed;
    FImageIndex := LSource.ImageIndex;
    FTag := LSource.Tag;
    Changed(False);
  end
  else
    inherited;
end;

function TS4YStepItem.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else
    Result := inherited GetDisplayName;
end;

procedure TS4YStepItem.SetCaption(const Value: string);
begin
  if FCaption = Value then
    Exit;

  FCaption := Value;
  Changed(False);
end;

procedure TS4YStepItem.SetDescription(const Value: string);
begin
  if FDescription = Value then
    Exit;

  FDescription := Value;
  Changed(False);
end;

procedure TS4YStepItem.SetFailed(const Value: Boolean);
begin
  if FFailed = Value then
    Exit;

  FFailed := Value;
  Changed(False);
end;

procedure TS4YStepItem.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex = Value then
    Exit;

  FImageIndex := Value;
  Changed(False);
end;

{ TS4YStepItems }

constructor TS4YStepItems.Create(const AProgressBar: TS4YStepProgressBar);
begin
  inherited Create(AProgressBar, TS4YStepItem);

  FProgressBar := AProgressBar;
end;

function TS4YStepItems.Add: TS4YStepItem;
begin
  Result := TS4YStepItem(inherited Add);
end;

function TS4YStepItems.GetItem(Index: Integer): TS4YStepItem;
begin
  Result := TS4YStepItem(inherited GetItem(Index));
end;

procedure TS4YStepItems.SetItem(Index: Integer; const Value: TS4YStepItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TS4YStepItems.Update(Item: TCollectionItem);
begin
  inherited;

  if Assigned(FProgressBar) then
    FProgressBar.StepsChanged;
end;

{ TS4YStepMarkerSettings }

constructor TS4YStepMarkerSettings.Create(const ADefaultFillColor, ADefaultStrokeColor: TAlphaColor);
begin
  inherited Create;

  FDefaultFillColor := ADefaultFillColor;
  FDefaultStrokeColor := ADefaultStrokeColor;
  FContent := C_DEFAULT_CONTENT;
  FImageIndex := C_DEFAULT_IMAGE_INDEX;
  FFill := TBrush.Create(TBrushKind.Solid, ADefaultFillColor);
  FStroke := TStrokeBrush.Create(TBrushKind.Solid, ADefaultStrokeColor);
  FStyledBrushes := C_DEFAULT_STYLED_BRUSHES;

  // Assigned only now: the initial values above are not a customization of the brushes.
  FFill.OnChanged := FillChanged;
  FStroke.OnChanged := StrokeChanged;
end;

destructor TS4YStepMarkerSettings.Destroy;
begin
  FFill.Free;
  FStroke.Free;

  inherited;
end;

procedure TS4YStepMarkerSettings.Assign(Source: TPersistent);
var
  LSource: TS4YStepMarkerSettings;
begin
  if Source is TS4YStepMarkerSettings then
  begin
    LSource := TS4YStepMarkerSettings(Source);
    FUpdating := True;
    try
      FContent := LSource.Content;
      FImageIndex := LSource.ImageIndex;
      FFill.Assign(LSource.Fill);
      FStroke.Assign(LSource.Stroke);
      FStyledBrushes := LSource.StyledBrushes;
    finally
      FUpdating := False;
    end;

    DoChange;
  end
  else
    inherited;
end;

procedure TS4YStepMarkerSettings.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YStepMarkerSettings.FillChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  // Any change of Fill means a fill of its own is wanted instead of the style's one.
  Exclude(FStyledBrushes, smbFill);
  DoChange;
end;

procedure TS4YStepMarkerSettings.SetContent(const Value: TS4YStepMarkerContent);
begin
  if FContent = Value then
    Exit;

  FContent := Value;
  DoChange;
end;

procedure TS4YStepMarkerSettings.SetFill(const Value: TBrush);
begin
  FFill.Assign(Value);
end;

procedure TS4YStepMarkerSettings.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex = Value then
    Exit;

  FImageIndex := Value;
  DoChange;
end;

procedure TS4YStepMarkerSettings.SetStroke(const Value: TStrokeBrush);
begin
  FStroke.Assign(Value);
end;

procedure TS4YStepMarkerSettings.SetStyledBrushes(const Value: TS4YStepMarkerStyledBrushes);
begin
  if FStyledBrushes = Value then
    Exit;

  FStyledBrushes := Value;
  DoChange;
end;

procedure TS4YStepMarkerSettings.StrokeChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  Exclude(FStyledBrushes, smbStroke);
  DoChange;
end;

function TS4YStepMarkerSettings.StyledBrushesStored: Boolean;
var
  LImplied: TS4YStepMarkerStyledBrushes;
begin
  // Streaming Fill/Stroke already switches the matching brush off by itself, so StyledBrushes is
  // only worth storing when it says something different from what that alone would give.
  LImplied := C_DEFAULT_STYLED_BRUSHES;

  if (FFill.Kind <> TBrushKind.Solid) or (FFill.Color <> FDefaultFillColor) then
    Exclude(LImplied, smbFill);

  if (FStroke.Kind <> TBrushKind.Solid) or
    (FStroke.Color <> FDefaultStrokeColor) or
    (FStroke.Thickness <> 1) or
    (FStroke.Dash <> TStrokeDash.Solid) or
    (FStroke.Cap <> TStrokeCap.Flat) or
    (FStroke.Join <> TStrokeJoin.Miter) then
    Exclude(LImplied, smbStroke);

  Result := FStyledBrushes <> LImplied;
end;

{ TS4YStepLineSettings }

constructor TS4YStepLineSettings.Create;
begin
  inherited Create;

  FCompletedFill := TBrush.Create(TBrushKind.Solid, C_DEFAULT_COMPLETED_COLOR);
  FPendingFill := TBrush.Create(TBrushKind.Solid, C_DEFAULT_PENDING_COLOR);
  FStyledBrushes := C_DEFAULT_STYLED_BRUSHES;
  FVisible := C_DEFAULT_VISIBLE;

  // Assigned only now: the initial values above are not a customization of the brushes.
  FCompletedFill.OnChanged := CompletedFillChanged;
  FPendingFill.OnChanged := PendingFillChanged;
end;

destructor TS4YStepLineSettings.Destroy;
begin
  FCompletedFill.Free;
  FPendingFill.Free;

  inherited;
end;

procedure TS4YStepLineSettings.Assign(Source: TPersistent);
var
  LSource: TS4YStepLineSettings;
begin
  if Source is TS4YStepLineSettings then
  begin
    LSource := TS4YStepLineSettings(Source);
    FUpdating := True;
    try
      FCompletedFill.Assign(LSource.CompletedFill);
      FPendingFill.Assign(LSource.PendingFill);
      FStyledBrushes := LSource.StyledBrushes;
      FVisible := LSource.Visible;
    finally
      FUpdating := False;
    end;

    DoChange;
  end
  else
    inherited;
end;

procedure TS4YStepLineSettings.CompletedFillChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  Exclude(FStyledBrushes, slbCompleted);
  DoChange;
end;

procedure TS4YStepLineSettings.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TS4YStepLineSettings.PendingFillChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  Exclude(FStyledBrushes, slbPending);
  DoChange;
end;

procedure TS4YStepLineSettings.SetCompletedFill(const Value: TBrush);
begin
  FCompletedFill.Assign(Value);
end;

procedure TS4YStepLineSettings.SetPendingFill(const Value: TBrush);
begin
  FPendingFill.Assign(Value);
end;

procedure TS4YStepLineSettings.SetStyledBrushes(const Value: TS4YStepLineStyledBrushes);
begin
  if FStyledBrushes = Value then
    Exit;

  FStyledBrushes := Value;
  DoChange;
end;

procedure TS4YStepLineSettings.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then
    Exit;

  FVisible := Value;
  DoChange;
end;

function TS4YStepLineSettings.StyledBrushesStored: Boolean;
var
  LImplied: TS4YStepLineStyledBrushes;
begin
  LImplied := C_DEFAULT_STYLED_BRUSHES;

  if (FCompletedFill.Kind <> TBrushKind.Solid) or (FCompletedFill.Color <> C_DEFAULT_COMPLETED_COLOR) then
    Exclude(LImplied, slbCompleted);

  if (FPendingFill.Kind <> TBrushKind.Solid) or (FPendingFill.Color <> C_DEFAULT_PENDING_COLOR) then
    Exclude(LImplied, slbPending);

  Result := FStyledBrushes <> LImplied;
end;

{ TS4YStepMarkerSize }

constructor TS4YStepMarkerSize.Create;
begin
  inherited Create;

  FHeight := C_DEFAULT_SIZE;
  FWidth := C_DEFAULT_SIZE;
end;

procedure TS4YStepMarkerSize.Assign(Source: TPersistent);
begin
  if Source is TS4YStepMarkerSize then
  begin
    FHeight := TS4YStepMarkerSize(Source).Height;
    FWidth := TS4YStepMarkerSize(Source).Width;
    DoChange;
  end
  else
    inherited;
end;

procedure TS4YStepMarkerSize.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TS4YStepMarkerSize.HeightStored: Boolean;
begin
  Result := not SameValue(FHeight, C_DEFAULT_SIZE);
end;

procedure TS4YStepMarkerSize.SetHeight(const Value: Single);
begin
  if SameValue(FHeight, Value) then
    Exit;

  FHeight := Max(0, Value);
  DoChange;
end;

procedure TS4YStepMarkerSize.SetWidth(const Value: Single);
begin
  if SameValue(FWidth, Value) then
    Exit;

  FWidth := Max(0, Value);
  DoChange;
end;

function TS4YStepMarkerSize.WidthStored: Boolean;
begin
  Result := not SameValue(FWidth, C_DEFAULT_SIZE);
end;

{ TS4YStepProgressBar }

constructor TS4YStepProgressBar.Create(AOwner: TComponent);
begin
  inherited;

  FAnimationDuration := C_DEFAULT_ANIMATION_DURATION;
  FHighlightProgress := C_DEFAULT_HIGHLIGHT_PROGRESS;
  FLabelPosition := C_DEFAULT_LABEL_POSITION;
  FLabelSpacing := C_DEFAULT_LABEL_SPACING;
  FLineSpacing := C_DEFAULT_LINE_SPACING;
  FLineThickness := C_DEFAULT_LINE_THICKNESS;
  FMarkerPosition := C_DEFAULT_MARKER_POSITION;
  FOrientation := C_DEFAULT_ORIENTATION;
  FInteractions := [];
  FCurrentStep := 0;
  FDisplayedProgress := 0;

  FSteps := TS4YStepItems.Create(Self);

  FCompletedMarker := TS4YStepMarkerSettings.Create(C_DEFAULT_COMPLETED_COLOR, C_DEFAULT_COMPLETED_COLOR);
  FCurrentMarker := TS4YStepMarkerSettings.Create(C_DEFAULT_CURRENT_FILL_COLOR, C_DEFAULT_CURRENT_STROKE_COLOR);
  FPendingMarker := TS4YStepMarkerSettings.Create(C_DEFAULT_PENDING_FILL_COLOR, C_DEFAULT_PENDING_STROKE_COLOR);
  FFailedMarker := TS4YStepMarkerSettings.Create(C_DEFAULT_FAILED_COLOR, C_DEFAULT_FAILED_COLOR);
  FCompletedMarker.OnChange := SettingsChanged;
  FCurrentMarker.OnChange := SettingsChanged;
  FPendingMarker.OnChange := SettingsChanged;
  FFailedMarker.OnChange := SettingsChanged;

  FLine := TS4YStepLineSettings.Create;
  FLine.OnChange := SettingsChanged;

  FMarkerSize := TS4YStepMarkerSize.Create;
  FMarkerSize.OnChange := SizeChanged;

  FDefaultFont := TFont.Create;
  FTextLayout := TTextLayoutManager.DefaultTextLayout.Create;

  // Holds the copies of the graphic parts of the style. It is a child of the control, so that the
  // parts belong to its scene and their own children are painted; it is invisible, so that resizing
  // a part does not ask for a repaint. Without owner and not stored, it is not part of the form.
  FPartsContainer := TControl.Create(nil);
  FPartsContainer.Stored := False;
  FPartsContainer.Visible := False;
  FPartsContainer.HitTest := False;
  FPartsContainer.Locked := True;
  FPartsContainer.Parent := Self;
end;

destructor TS4YStepProgressBar.Destroy;
begin
  // Freed first, so that a running animation cannot touch the settings released below.
  FreeAndNil(FLineAnimation);
  FreeParts;
  FreeAndNil(FPartsContainer);
  FreeAndNil(FTextLayout);
  FreeAndNil(FDefaultFont);
  FreeAndNil(FMarkerSize);
  FreeAndNil(FLine);
  FreeAndNil(FCompletedMarker);
  FreeAndNil(FCurrentMarker);
  FreeAndNil(FPendingMarker);
  FreeAndNil(FFailedMarker);
  FreeAndNil(FSteps);

  inherited;
end;

procedure TS4YStepProgressBar.AnimateProgress(const ATargetProgress: Single);
var
  LAnimation: TS4YStepProgressAnimation;
begin
  if not Assigned(FLineAnimation) then
  begin
    LAnimation := TS4YStepProgressAnimation.Create(Self);
    LAnimation.Stored := False;
    LAnimation.Interpolation := TInterpolationType.Sinusoidal;
    LAnimation.AnimationType := TAnimationType.InOut;
    LAnimation.Parent := Self;
    FLineAnimation := LAnimation;
  end
  else
    LAnimation := TS4YStepProgressAnimation(FLineAnimation);

  // A change during an animation starts from where the line is now.
  LAnimation.StopAtCurrent;
  LAnimation.StartProgress := FDisplayedProgress;
  LAnimation.TargetProgress := ATargetProgress;
  LAnimation.Duration := FAnimationDuration;
  LAnimation.Start;
end;

function TS4YStepProgressBar.AnimationDurationStored: Boolean;
begin
  Result := not SameValue(FAnimationDuration, C_DEFAULT_ANIMATION_DURATION);
end;

procedure TS4YStepProgressBar.ApplyStyle;
begin
  inherited;

  FindStyleResource<TText>(C_STYLE_DESCRIPTION, FStyleDescription);

  for var LState := Low(TS4YStepState) to High(TS4YStepState) do
  begin
    FindStyleResource<TText>(C_STYLE_MARKER_TEXTS[LState], FStyleMarkerTexts[LState]);
    FindStyleResource<TText>(C_STYLE_LABELS[LState], FStyleLabels[LState]);
  end;

  // The graphic parts are copied from the new style the next time the control paints.
  FreeParts;
  Repaint;
end;

function TS4YStepProgressBar.CalculateLabelRect(const AStepIndex, AStepCount: Integer): TRectF;
var
  LContentRect: TRectF;
  LStepCenter: Single;
  LHalfCell: Single;
  LTrackStart: Single;
  LTrackEnd: Single;
  LMarkerCenter: Single;
  LLineCenter: Single;
begin
  LContentRect := GetContentRect;
  LStepCenter := CalculateStepCenter(AStepIndex, AStepCount);
  CalculateTrack(LTrackStart, LTrackEnd, LMarkerCenter, LLineCenter);

  // Along the line the label has the cell of its step; across it, the space beyond the track.
  if FOrientation = TOrientation.Horizontal then
  begin
    LHalfCell := LContentRect.Width / AStepCount / 2;
    Result.Left := LStepCenter - LHalfCell;
    Result.Right := LStepCenter + LHalfCell;

    if FLabelPosition = slpBefore then
    begin
      Result.Top := LContentRect.Top;
      Result.Bottom := LTrackStart - FLabelSpacing;
    end
    else
    begin
      Result.Top := LTrackEnd + FLabelSpacing;
      Result.Bottom := LContentRect.Bottom;
    end;
  end
  else
  begin
    LHalfCell := LContentRect.Height / AStepCount / 2;
    Result.Top := LStepCenter - LHalfCell;
    Result.Bottom := LStepCenter + LHalfCell;

    if FLabelPosition = slpBefore then
    begin
      Result.Left := LContentRect.Left;
      Result.Right := LTrackStart - FLabelSpacing;
    end
    else
    begin
      Result.Left := LTrackEnd + FLabelSpacing;
      Result.Right := LContentRect.Right;
    end;
  end;
end;

function TS4YStepProgressBar.CalculateLineRect(const AFrom, ATo, ALineCenter: Single): TRectF;
var
  LHalfThickness: Single;
begin
  LHalfThickness := FLineThickness / 2;

  if FOrientation = TOrientation.Horizontal then
    Result := TRectF.Create(AFrom, ALineCenter - LHalfThickness, ATo, ALineCenter + LHalfThickness)
  else
    Result := TRectF.Create(ALineCenter - LHalfThickness, AFrom, ALineCenter + LHalfThickness, ATo);
end;

function TS4YStepProgressBar.CalculateMarkerCenter(const AStepIndex, AStepCount: Integer): TPointF;
var
  LStepCenter: Single;
  LTrackStart: Single;
  LTrackEnd: Single;
  LMarkerCenter: Single;
  LLineCenter: Single;
begin
  LStepCenter := CalculateStepCenter(AStepIndex, AStepCount);
  CalculateTrack(LTrackStart, LTrackEnd, LMarkerCenter, LLineCenter);

  if FOrientation = TOrientation.Horizontal then
    Result := TPointF.Create(LStepCenter, LMarkerCenter)
  else
    Result := TPointF.Create(LMarkerCenter, LStepCenter);
end;

function TS4YStepProgressBar.CalculateMarkerRect(const AStepIndex, AStepCount: Integer): TRectF;
var
  LCenter: TPointF;
  LHalfWidth: Single;
  LHalfHeight: Single;
begin
  LCenter := CalculateMarkerCenter(AStepIndex, AStepCount);
  LHalfWidth := FMarkerSize.Width / 2;
  LHalfHeight := FMarkerSize.Height / 2;
  Result := TRectF.Create(LCenter.X - LHalfWidth, LCenter.Y - LHalfHeight, LCenter.X + LHalfWidth, LCenter.Y + LHalfHeight);
end;

function TS4YStepProgressBar.CalculateStepCenter(const AStepIndex, AStepCount: Integer): Single;
var
  LContentRect: TRectF;
begin
  // Position along the line: the center of the cell of the step, all the cells of the same size.
  LContentRect := GetContentRect;

  if FOrientation = TOrientation.Horizontal then
    Result := LContentRect.Left + (AStepIndex + 0.5) * LContentRect.Width / AStepCount
  else
    Result := LContentRect.Top + (AStepIndex + 0.5) * LContentRect.Height / AStepCount;
end;

procedure TS4YStepProgressBar.CalculateTrack(out ATrackStart, ATrackEnd, AMarkerCenter, ALineCenter: Single);
var
  LContentRect: TRectF;
  LContentStart: Single;
  LContentEnd: Single;
  LMarkerSize: Single;
  LLineSize: Single;
  LTrackSize: Single;
begin
  // The track is the band across the line that holds the markers and the line; the positions are
  // across the line: Y for a horizontal line, X for a vertical one.
  LContentRect := GetContentRect;

  if FOrientation = TOrientation.Horizontal then
  begin
    LContentStart := LContentRect.Top;
    LContentEnd := LContentRect.Bottom;
  end
  else
  begin
    LContentStart := LContentRect.Left;
    LContentEnd := LContentRect.Right;
  end;

  LMarkerSize := GetMarkerAcrossLine;
  LLineSize := 0;

  if FLine.Visible then
    LLineSize := FLineThickness;

  if FMarkerPosition = smpCenter then
    LTrackSize := Max(LMarkerSize, LLineSize)
  else if FLine.Visible then
    LTrackSize := LMarkerSize + FLineSpacing + LLineSize
  else
    LTrackSize := LMarkerSize;

  // The track is on the side opposite to the labels, or in the middle without labels.
  case FLabelPosition of
    slpBefore:
      ATrackStart := LContentEnd - LTrackSize;
    slpAfter:
      ATrackStart := LContentStart;
  else
    ATrackStart := (LContentStart + LContentEnd - LTrackSize) / 2;
  end;

  ATrackEnd := ATrackStart + LTrackSize;

  case FMarkerPosition of
    smpBefore:
    begin
      AMarkerCenter := ATrackStart + LMarkerSize / 2;
      ALineCenter := ATrackEnd - LLineSize / 2;
    end;
    smpAfter:
    begin
      AMarkerCenter := ATrackEnd - LMarkerSize / 2;
      ALineCenter := ATrackStart + LLineSize / 2;
    end;
  else
    AMarkerCenter := ATrackStart + LTrackSize / 2;
    ALineCenter := AMarkerCenter;
  end;
end;

function TS4YStepProgressBar.ChangeStep(const ANewStep: Integer): Boolean;
var
  LNewStep: Integer;
begin
  LNewStep := ClampStep(ANewStep);

  if LNewStep = FCurrentStep then
    Exit(False);

  if not DoStepChanging(LNewStep) then
    Exit(False);

  FCurrentStep := LNewStep;

  if IsProgressHighlighted and (FAnimationDuration > 0) and not (csDesigning in ComponentState) then
    AnimateProgress(FCurrentStep)
  else
  begin
    if IsAnimating then
      FLineAnimation.StopAtCurrent;

    SetDisplayedProgress(FCurrentStep);
  end;

  DoStepChanged;
  Result := True;
end;

function TS4YStepProgressBar.ClampStep(const AStep: Integer): Integer;
begin
  Result := Max(0, Min(AStep, FSteps.Count - 1));
end;

function TS4YStepProgressBar.CreatePart(const AStyleName: string; out FromStyle: Boolean): TControl;
var
  LStylePart: TControl;
  LStylePartStored: Boolean;
begin
  Result := nil;
  FromStyle := FindStyleResource<TControl>(AStyleName, LStylePart);

  if not FromStyle then
    Exit;

  // A copy, so that it can be resized and recolored without touching the style. FMX marks the
  // objects of an applied style as not stored, and Clone copies through streaming: the part has to
  // be stored while it is copied, or the copy would lose its children.
  LStylePartStored := LStylePart.Stored;
  LStylePart.Stored := True;
  try
    Result := TControl(LStylePart.Clone(nil));
  finally
    LStylePart.Stored := LStylePartStored;
  end;

  // Clone reads the copy as stored, so the copy and its children with a StyleName are added to the
  // global list of the styles of FMX: setting Stored to False removes them from it, like the parts
  // copied by FMX itself.
  Result.Stored := False;
  Result.Visible := True;
  Result.Parent := FPartsContainer;
end;

function TS4YStepProgressBar.DoDrawLine(const ACanvas: TCanvas; const ARect: TRectF; const AFromStep: Integer;
  const Completed: Boolean): Boolean;
begin
  Result := False;

  if Assigned(FOnDrawLine) then
    FOnDrawLine(Self, ACanvas, ARect, AFromStep, Completed, Result);
end;

function TS4YStepProgressBar.DoDrawMarker(const ACanvas: TCanvas; const ARect: TRectF; const AStepIndex: Integer;
  const AState: TS4YStepState): Boolean;
begin
  Result := False;

  if Assigned(FOnDrawMarker) then
    FOnDrawMarker(Self, ACanvas, ARect, AStepIndex, AState, Result);
end;

procedure TS4YStepProgressBar.DoEnter;
begin
  inherited;

  Repaint;
end;

procedure TS4YStepProgressBar.DoExit;
begin
  inherited;

  Repaint;
end;

procedure TS4YStepProgressBar.DoMouseLeave;
begin
  inherited;

  UpdateHandCursor(TPointF.Create(-1, -1));
end;

procedure TS4YStepProgressBar.DoStepChanged;
begin
  if Assigned(FOnStepChanged) then
    FOnStepChanged(Self);
end;

function TS4YStepProgressBar.DoStepChanging(const ANewStep: Integer): Boolean;
begin
  Result := True;

  if Assigned(FOnStepChanging) then
    FOnStepChanging(Self, ANewStep, Result);
end;

procedure TS4YStepProgressBar.DrawFocusFrame(const AStepCount: Integer);
var
  LFrameRect: TRectF;
begin
  if not (stiKeyboard in FInteractions) or not IsFocused or (FSteps.Count = 0) then
    Exit;

  LFrameRect := CalculateMarkerRect(FCurrentStep, AStepCount);
  LFrameRect.Inflate(C_FOCUS_FRAME_SPACING, C_FOCUS_FRAME_SPACING);
  DrawPart(FFocusFramePart, LFrameRect);
end;

procedure TS4YStepProgressBar.DrawLine(const AStepCount: Integer);
var
  LFrom: Single;
  LTo: Single;
  LSplit: Single;
  LProgress: Single;
  LMarkerGap: Single;
  LTrackStart: Single;
  LTrackEnd: Single;
  LMarkerCenter: Single;
  LLineCenter: Single;
begin
  if not FLine.Visible then
    Exit;

  if FSteps.Count = 0 then
    LProgress := C_DESIGN_PREVIEW_CURRENT_STEP
  else
    LProgress := EnsureRange(FDisplayedProgress, 0, AStepCount - 1);

  if not FHighlightProgress then
    LProgress := 0;

  CalculateTrack(LTrackStart, LTrackEnd, LMarkerCenter, LLineCenter);

  // On the line, the stretches stop at the markers, LineSpacing away; beside the line, they join
  // the centers of the steps, so that the line is continuous.
  if FMarkerPosition = smpCenter then
    LMarkerGap := GetMarkerAlongLine / 2 + FLineSpacing
  else
    LMarkerGap := 0;

  // One stretch between each pair of steps, so that a style part repeats along the line.
  for var LFromStep := 0 to AStepCount - 2 do
  begin
    LFrom := CalculateStepCenter(LFromStep, AStepCount) + LMarkerGap;
    LTo := CalculateStepCenter(LFromStep + 1, AStepCount) - LMarkerGap;

    if LFromStep + 1 <= LProgress then
      DrawLineStretch(LFromStep, LFrom, LTo, LLineCenter, True)
    else if LFromStep >= LProgress then
      DrawLineStretch(LFromStep, LFrom, LTo, LLineCenter, False)
    else
    begin
      // The stretch the line is filling while it moves to the new current step
      LSplit := LFrom + (LTo - LFrom) * (LProgress - LFromStep);
      DrawLineStretch(LFromStep, LFrom, LSplit, LLineCenter, True);
      DrawLineStretch(LFromStep, LSplit, LTo, LLineCenter, False);
    end;
  end;
end;

procedure TS4YStepProgressBar.DrawLineStretch(const AFromStep: Integer; const AFrom, ATo, ALineCenter: Single;
  Completed: Boolean);
var
  LStretchRect: TRectF;
begin
  // Markers larger than the space between the steps leave no room for the stretch.
  if ATo <= AFrom then
    Exit;

  LStretchRect := CalculateLineRect(AFrom, ATo, ALineCenter);

  if (LStretchRect.Width <= 0) or (LStretchRect.Height <= 0) then
    Exit;

  if DoDrawLine(Canvas, LStretchRect, AFromStep, Completed) then
    Exit;

  if Completed then
    DrawPart(FLineParts[slbCompleted], LStretchRect)
  else
    DrawPart(FLineParts[slbPending], LStretchRect);
end;

procedure TS4YStepProgressBar.DrawMarker(const AStepIndex, AStepCount: Integer);
var
  LMarkerRect: TRectF;
  LState: TS4YStepState;
begin
  LMarkerRect := CalculateMarkerRect(AStepIndex, AStepCount);
  LState := GetStepState(AStepIndex);

  if DoDrawMarker(Canvas, LMarkerRect, AStepIndex, LState) then
    Exit;

  DrawPart(FMarkerParts[LState], LMarkerRect);
  DrawMarkerContent(AStepIndex, LState, LMarkerRect);
end;

procedure TS4YStepProgressBar.DrawMarkerContent(const AStepIndex: Integer; const AState: TS4YStepState;
  const AMarkerRect: TRectF);
var
  LSettings: TS4YStepMarkerSettings;
  LImageIndex: Integer;
  LImageRect: TRectF;
begin
  LSettings := GetMarkerSettings(AState);

  case LSettings.Content of
    smcNumber:
    begin
      PrepareTextLayout(FStyleMarkerTexts[AState], C_DEFAULT_MARKER_TEXT_COLORS[AState], IntToStr(AStepIndex + 1),
        AMarkerRect, TTextAlign.Center, TTextAlign.Center, False);
      FTextLayout.RenderLayout(Canvas);
    end;
    smcImage:
    begin
      LImageIndex := LSettings.ImageIndex;

      if (LImageIndex < 0) and (AStepIndex < FSteps.Count) then
        LImageIndex := FSteps[AStepIndex].ImageIndex;

      if Assigned(FImages) and (LImageIndex >= 0) then
      begin
        LImageRect := AMarkerRect;
        LImageRect.Inflate(-FMarkerSize.Width * C_MARKER_IMAGE_MARGIN, -FMarkerSize.Height * C_MARKER_IMAGE_MARGIN);
        FImages.Draw(Canvas, LImageRect, LImageIndex, AbsoluteOpacity);
      end;
    end;
  end;
end;

procedure TS4YStepProgressBar.DrawPart(const APart: TControl; const ARect: TRectF);
begin
  if not Assigned(APart) or (ARect.Width < 1) or (ARect.Height < 1) then
    Exit;

  // The part gets the size of the area, so that its borders keep their thickness instead of
  // being scaled; PaintTo with the control as parent draws it in the coordinates of the control.
  APart.SetBounds(0, 0, ARect.Width, ARect.Height);
  APart.PaintTo(Canvas, ARect, Self);
  Canvas.SetMatrix(AbsoluteMatrix);
end;

procedure TS4YStepProgressBar.DrawStepLabel(const AStepIndex, AStepCount: Integer);
var
  LCaption: string;
  LDescription: string;
  LLabelRect: TRectF;
  LState: TS4YStepState;
  LCaptionHeight: Single;
  LDescriptionHeight: Single;
  LTop: Single;
begin
  if (FLabelPosition = slpNone) or (AStepIndex >= FSteps.Count) then
    Exit;

  LCaption := FSteps[AStepIndex].Caption;
  LDescription := FSteps[AStepIndex].Description;

  if (LCaption = '') and (LDescription = '') then
    Exit;

  LLabelRect := CalculateLabelRect(AStepIndex, AStepCount);

  if (LLabelRect.Width <= 0) or (LLabelRect.Height <= 0) then
    Exit;

  LState := GetStepState(AStepIndex);
  LCaptionHeight := MeasureTextHeight(FStyleLabels[LState], C_DEFAULT_LABEL_COLORS[LState], LCaption, LLabelRect.Width);
  LDescriptionHeight := MeasureTextHeight(FStyleDescription, C_DEFAULT_DESCRIPTION_COLOR, LDescription,
    LLabelRect.Width);

  // The caption and the description are one block, aligned towards the marker.
  case GetLabelVerticalAlign of
    TTextAlign.Leading:
      LTop := LLabelRect.Top;
    TTextAlign.Trailing:
      LTop := LLabelRect.Bottom - LCaptionHeight - LDescriptionHeight;
  else
    LTop := LLabelRect.Top + (LLabelRect.Height - LCaptionHeight - LDescriptionHeight) / 2;
  end;

  RenderText(FStyleLabels[LState], C_DEFAULT_LABEL_COLORS[LState], LCaption,
    TRectF.Create(LLabelRect.Left, LTop, LLabelRect.Right, LTop + LCaptionHeight), GetLabelHorizontalAlign);
  LTop := LTop + LCaptionHeight;
  RenderText(FStyleDescription, C_DEFAULT_DESCRIPTION_COLOR, LDescription,
    TRectF.Create(LLabelRect.Left, LTop, LLabelRect.Right, LTop + LDescriptionHeight), GetLabelHorizontalAlign);
end;

procedure TS4YStepProgressBar.EnsureParts;
var
  LFromStyle: Boolean;
  LSettings: TS4YStepMarkerSettings;
  LShape: TShape;
begin
  if Assigned(FMarkerParts[sstCompleted]) then
    Exit;

  for var LState := Low(TS4YStepState) to High(TS4YStepState) do
  begin
    LSettings := GetMarkerSettings(LState);
    FMarkerParts[LState] := CreatePart(C_STYLE_MARKERS[LState], LFromStyle);

    if not LFromStyle then
    begin
      FMarkerParts[LState] := TEllipse.Create(nil);
      FMarkerParts[LState].Parent := FPartsContainer;
    end;

    // The properties replace the brushes of a shape; a part made of several objects stays as it is.
    if FMarkerParts[LState] is TShape then
    begin
      LShape := TShape(FMarkerParts[LState]);

      if not LFromStyle or not (smbFill in LSettings.StyledBrushes) then
        LShape.Fill.Assign(LSettings.Fill);

      if not LFromStyle or not (smbStroke in LSettings.StyledBrushes) then
        LShape.Stroke.Assign(LSettings.Stroke);
    end;
  end;

  for var LLine := Low(TS4YStepLineStyledBrush) to High(TS4YStepLineStyledBrush) do
  begin
    FLineParts[LLine] := CreatePart(C_STYLE_LINES[LLine], LFromStyle);

    if not LFromStyle then
    begin
      LShape := TRectangle.Create(nil);
      LShape.Stroke.Kind := TBrushKind.None;
      LShape.Parent := FPartsContainer;
      FLineParts[LLine] := LShape;
    end;

    if (FLineParts[LLine] is TShape) and (not LFromStyle or not (LLine in FLine.StyledBrushes)) then
    begin
      if LLine = slbCompleted then
        TShape(FLineParts[LLine]).Fill.Assign(FLine.CompletedFill)
      else
        TShape(FLineParts[LLine]).Fill.Assign(FLine.PendingFill);
    end;
  end;

  FFocusFramePart := CreatePart(C_STYLE_FOCUS_FRAME, LFromStyle);

  if not LFromStyle then
  begin
    LShape := TEllipse.Create(nil);
    LShape.Fill.Kind := TBrushKind.None;
    LShape.Stroke.Color := C_DEFAULT_FOCUS_FRAME_COLOR;
    LShape.Stroke.Thickness := C_DEFAULT_FOCUS_FRAME_THICKNESS;
    LShape.Stroke.Dash := TStrokeDash.Dot;
    LShape.Parent := FPartsContainer;
    FFocusFramePart := LShape;
  end;
end;

function TS4YStepProgressBar.FindStepAt(const APoint: TPointF): Integer;
var
  LIndex: Integer;
  LStepCount: Integer;
begin
  Result := -1;
  LStepCount := FSteps.Count;
  LIndex := 0;

  // Only the parts that a click can select: the markers, the labels or both.
  while (Result < 0) and (LIndex < LStepCount) do
  begin
    if ((stiClickMarker in FInteractions) and CalculateMarkerRect(LIndex, LStepCount).Contains(APoint)) or
      ((stiClickLabel in FInteractions) and (FLabelPosition <> slpNone) and
      CalculateLabelRect(LIndex, LStepCount).Contains(APoint)) then
      Result := LIndex;

    Inc(LIndex);
  end;
end;

procedure TS4YStepProgressBar.FreeParts;
begin
  for var LState := Low(TS4YStepState) to High(TS4YStepState) do
    FreeAndNil(FMarkerParts[LState]);

  for var LLine := Low(TS4YStepLineStyledBrush) to High(TS4YStepLineStyledBrush) do
    FreeAndNil(FLineParts[LLine]);

  FreeAndNil(FFocusFramePart);
end;

procedure TS4YStepProgressBar.FreeStyle;
begin
  FreeParts;
  FStyleDescription := nil;

  for var LState := Low(TS4YStepState) to High(TS4YStepState) do
  begin
    FStyleMarkerTexts[LState] := nil;
    FStyleLabels[LState] := nil;
  end;

  inherited;
end;

function TS4YStepProgressBar.GetContentRect: TRectF;
begin
  Result := TRectF.Create(Padding.Left, Padding.Top, Width - Padding.Right, Height - Padding.Bottom);
end;

function TS4YStepProgressBar.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(400, 64);
end;

function TS4YStepProgressBar.GetLabelHorizontalAlign: TTextAlign;
begin
  if FOrientation = TOrientation.Horizontal then
    Result := TTextAlign.Center
  else if FLabelPosition = slpBefore then
    Result := TTextAlign.Trailing
  else
    Result := TTextAlign.Leading;
end;

function TS4YStepProgressBar.GetLabelVerticalAlign: TTextAlign;
begin
  if FOrientation = TOrientation.Vertical then
    Result := TTextAlign.Center
  else if FLabelPosition = slpBefore then
    Result := TTextAlign.Trailing
  else
    Result := TTextAlign.Leading;
end;

function TS4YStepProgressBar.GetMarkerAcrossLine: Single;
begin
  if FOrientation = TOrientation.Horizontal then
    Result := FMarkerSize.Height
  else
    Result := FMarkerSize.Width;
end;

function TS4YStepProgressBar.GetMarkerAlongLine: Single;
begin
  if FOrientation = TOrientation.Horizontal then
    Result := FMarkerSize.Width
  else
    Result := FMarkerSize.Height;
end;

function TS4YStepProgressBar.GetMarkerSettings(const AState: TS4YStepState): TS4YStepMarkerSettings;
begin
  case AState of
    sstCompleted:
      Result := FCompletedMarker;
    sstCurrent:
      Result := FCurrentMarker;
    sstFailed:
      Result := FFailedMarker;
  else
    Result := FPendingMarker;
  end;
end;

function TS4YStepProgressBar.GetStepCount: Integer;
begin
  Result := FSteps.Count;

  if (Result = 0) and (csDesigning in ComponentState) then
    Result := C_DESIGN_PREVIEW_STEP_COUNT;
end;

function TS4YStepProgressBar.GetStepState(const AStepIndex: Integer): TS4YStepState;
var
  LCurrentStep: Integer;
begin
  if (AStepIndex < FSteps.Count) and FSteps[AStepIndex].Failed then
    Exit(sstFailed);

  if FSteps.Count = 0 then
    LCurrentStep := C_DESIGN_PREVIEW_CURRENT_STEP
  else
    LCurrentStep := FCurrentStep;

  // While the line fills, a step becomes completed only when the line reaches it.
  if AStepIndex = LCurrentStep then
    Result := sstCurrent
  else if (AStepIndex < LCurrentStep) and ((FSteps.Count = 0) or not IsProgressHighlighted or
    (AStepIndex <= FDisplayedProgress)) then
    Result := sstCompleted
  else
    Result := sstPending;
end;

function TS4YStepProgressBar.GetStyleObject: TFmxObject;
begin
  // Without StyleLookup only the style named after the class is searched, in the style book and
  // in the active style: the search of FMX would also take the style of the parent class.
  if StyleLookup <> '' then
    Result := inherited GetStyleObject
  else
    Result := LookupStyleObject(Self, GetStyleContext, Scene, '', GetDefaultStyleLookupName, '', True);

  // The style linked into the package is used when no other style is found.
  if not Assigned(Result) then
    Result := TStyleStreaming.LoadFromResource(HInstance, GetDefaultStyleLookupName, RT_RCDATA);
end;

function TS4YStepProgressBar.IsAnimating: Boolean;
begin
  Result := Assigned(FLineAnimation) and FLineAnimation.Running;
end;

function TS4YStepProgressBar.IsProgressHighlighted: Boolean;
begin
  // The progress is shown by the line: without it there is nothing to highlight or to animate.
  Result := FHighlightProgress and FLine.Visible;
end;

procedure TS4YStepProgressBar.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  inherited;

  if not (stiKeyboard in FInteractions) or (FSteps.Count = 0) then
    Exit;

  case Key of
    vkLeft, vkUp:
    begin
      PreviousStep;
      Key := 0;
    end;
    vkRight, vkDown:
    begin
      NextStep;
      Key := 0;
    end;
    vkHome:
    begin
      ChangeStep(0);
      Key := 0;
    end;
    vkEnd:
    begin
      ChangeStep(FSteps.Count - 1);
      Key := 0;
    end;
  end;
end;

function TS4YStepProgressBar.LabelSpacingStored: Boolean;
begin
  Result := not SameValue(FLabelSpacing, C_DEFAULT_LABEL_SPACING);
end;

function TS4YStepProgressBar.LineSpacingStored: Boolean;
begin
  Result := not SameValue(FLineSpacing, C_DEFAULT_LINE_SPACING);
end;

function TS4YStepProgressBar.LineThicknessStored: Boolean;
begin
  Result := not SameValue(FLineThickness, C_DEFAULT_LINE_THICKNESS);
end;

procedure TS4YStepProgressBar.Loaded;
begin
  inherited;

  // CurrentStep is read before Steps: it can be checked only now.
  FCurrentStep := ClampStep(FCurrentStep);
  FDisplayedProgress := FCurrentStep;
end;

function TS4YStepProgressBar.MeasureTextHeight(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string; const AWidth: Single): Single;
begin
  if AText = '' then
    Exit(0);

  PrepareTextLayout(ATemplate, ADefaultColor, AText, TRectF.Create(0, 0, AWidth, C_MEASURE_HEIGHT),
    TTextAlign.Leading, TTextAlign.Leading, True);
  Result := FTextLayout.TextHeight;
end;

procedure TS4YStepProgressBar.MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LStepIndex: Integer;
begin
  inherited;

  if Button <> TMouseButton.mbLeft then
    Exit;

  LStepIndex := FindStepAt(TPointF.Create(X, Y));

  if LStepIndex >= 0 then
    ChangeStep(LStepIndex);
end;

procedure TS4YStepProgressBar.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited;

  UpdateHandCursor(TPointF.Create(X, Y));
end;

function TS4YStepProgressBar.NextStep: Boolean;
begin
  if FCurrentStep >= FSteps.Count - 1 then
    Exit(False);

  Result := ChangeStep(FCurrentStep + 1);
end;

procedure TS4YStepProgressBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) and (AComponent = FImages) then
  begin
    FImages := nil;
    Repaint;
  end;
end;

procedure TS4YStepProgressBar.Paint;
var
  LStepCount: Integer;
begin
  inherited;

  LStepCount := GetStepCount;

  if LStepCount = 0 then
    Exit;

  EnsureParts;
  DrawLine(LStepCount);

  for var LIndex := 0 to LStepCount - 1 do
  begin
    DrawMarker(LIndex, LStepCount);
    DrawStepLabel(LIndex, LStepCount);
  end;

  DrawFocusFrame(LStepCount);
end;

procedure TS4YStepProgressBar.PrepareTextLayout(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string; const ARect: TRectF; const AHorizontalAlign, AVerticalAlign: TTextAlign; WordWrap: Boolean);
begin
  FTextLayout.BeginUpdate;
  try
    if Assigned(ATemplate) then
    begin
      FTextLayout.Font.Assign(ATemplate.TextSettings.Font);
      FTextLayout.Color := ATemplate.TextSettings.FontColor;
    end
    else
    begin
      FTextLayout.Font.Assign(FDefaultFont);
      FTextLayout.Color := ADefaultColor;
    end;

    FTextLayout.Text := AText;
    FTextLayout.TopLeft := ARect.TopLeft;
    FTextLayout.MaxSize := TPointF.Create(ARect.Width, ARect.Height);
    FTextLayout.HorizontalAlign := AHorizontalAlign;
    FTextLayout.VerticalAlign := AVerticalAlign;
    FTextLayout.WordWrap := WordWrap;
    FTextLayout.Trimming := TTextTrimming.None;
    FTextLayout.Opacity := AbsoluteOpacity;
  finally
    FTextLayout.EndUpdate;
  end;
end;

function TS4YStepProgressBar.PreviousStep: Boolean;
begin
  if FCurrentStep <= 0 then
    Exit(False);

  Result := ChangeStep(FCurrentStep - 1);
end;

procedure TS4YStepProgressBar.RenderText(const ATemplate: TText; const ADefaultColor: TAlphaColor;
  const AText: string; const ARect: TRectF; const AHorizontalAlign: TTextAlign);
begin
  if AText = '' then
    Exit;

  PrepareTextLayout(ATemplate, ADefaultColor, AText, ARect, AHorizontalAlign, TTextAlign.Leading, True);
  FTextLayout.RenderLayout(Canvas);
end;

procedure TS4YStepProgressBar.SetAnimationDuration(const Value: Single);
begin
  FAnimationDuration := Max(0, Value);
end;

procedure TS4YStepProgressBar.SetCompletedMarker(const Value: TS4YStepMarkerSettings);
begin
  FCompletedMarker.Assign(Value);
end;

procedure TS4YStepProgressBar.SetCurrentMarker(const Value: TS4YStepMarkerSettings);
begin
  FCurrentMarker.Assign(Value);
end;

procedure TS4YStepProgressBar.SetCurrentStep(const Value: Integer);
begin
  // While loading, the steps may not be read yet: Loaded checks the value.
  if csLoading in ComponentState then
  begin
    FCurrentStep := Value;
    Exit;
  end;

  ChangeStep(Value);
end;

procedure TS4YStepProgressBar.SetDisplayedProgress(const Value: Single);
begin
  if csDestroying in ComponentState then
    Exit;

  FDisplayedProgress := Value;
  Repaint;
end;

procedure TS4YStepProgressBar.SetFailedMarker(const Value: TS4YStepMarkerSettings);
begin
  FFailedMarker.Assign(Value);
end;

procedure TS4YStepProgressBar.SetHighlightProgress(const Value: Boolean);
begin
  if FHighlightProgress = Value then
    Exit;

  FHighlightProgress := Value;

  if IsAnimating then
    FLineAnimation.StopAtCurrent;

  SetDisplayedProgress(FCurrentStep);
end;

procedure TS4YStepProgressBar.SetImages(const Value: TCustomImageList);
begin
  if FImages = Value then
    Exit;

  if Assigned(FImages) then
    FImages.RemoveFreeNotification(Self);

  FImages := Value;

  if Assigned(FImages) then
    FImages.FreeNotification(Self);

  Repaint;
end;

procedure TS4YStepProgressBar.SetInteractions(const Value: TS4YStepInteractions);
begin
  if FInteractions = Value then
    Exit;

  FInteractions := Value;
  CanFocus := stiKeyboard in FInteractions;

  if not (stiHandCursor in FInteractions) then
    UpdateHandCursor(TPointF.Create(-1, -1));

  Repaint;
end;

procedure TS4YStepProgressBar.SetLabelPosition(const Value: TS4YStepLabelPosition);
begin
  if FLabelPosition = Value then
    Exit;

  FLabelPosition := Value;
  Repaint;
end;

procedure TS4YStepProgressBar.SetLabelSpacing(const Value: Single);
begin
  if SameValue(FLabelSpacing, Value) then
    Exit;

  FLabelSpacing := Value;
  Repaint;
end;

procedure TS4YStepProgressBar.SetLine(const Value: TS4YStepLineSettings);
begin
  FLine.Assign(Value);
end;

procedure TS4YStepProgressBar.SetLineSpacing(const Value: Single);
begin
  if SameValue(FLineSpacing, Value) then
    Exit;

  FLineSpacing := Value;
  Repaint;
end;

procedure TS4YStepProgressBar.SetLineThickness(const Value: Single);
begin
  if SameValue(FLineThickness, Value) then
    Exit;

  FLineThickness := Max(0, Value);
  Repaint;
end;

procedure TS4YStepProgressBar.SetMarkerPosition(const Value: TS4YStepMarkerPosition);
begin
  if FMarkerPosition = Value then
    Exit;

  FMarkerPosition := Value;
  Repaint;
end;

procedure TS4YStepProgressBar.SetMarkerSize(const Value: TS4YStepMarkerSize);
begin
  FMarkerSize.Assign(Value);
end;

procedure TS4YStepProgressBar.SetOrientation(const Value: TOrientation);
begin
  if FOrientation = Value then
    Exit;

  FOrientation := Value;
  Repaint;
end;

procedure TS4YStepProgressBar.SetPendingMarker(const Value: TS4YStepMarkerSettings);
begin
  FPendingMarker.Assign(Value);
end;

procedure TS4YStepProgressBar.SetSteps(const Value: TS4YStepItems);
begin
  FSteps.Assign(Value);
end;

procedure TS4YStepProgressBar.SettingsChanged(Sender: TObject);
begin
  // Without the line there is no filling to show: the current step is drawn at once.
  if (Sender = FLine) and not FLine.Visible then
  begin
    if IsAnimating then
      FLineAnimation.StopAtCurrent;

    FDisplayedProgress := FCurrentStep;
  end;

  // The brushes of the properties are applied to the parts when they are prepared again.
  FreeParts;
  Repaint;
end;

procedure TS4YStepProgressBar.SizeChanged(Sender: TObject);
begin
  Repaint;
end;

procedure TS4YStepProgressBar.StepsChanged;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;

  // Steps removed from the end may leave the current step out of range.
  FCurrentStep := ClampStep(FCurrentStep);

  if IsAnimating then
    Repaint
  else
    SetDisplayedProgress(FCurrentStep);
end;

procedure TS4YStepProgressBar.UpdateHandCursor(const APoint: TPointF);
var
  LOverStep: Boolean;
begin
  LOverStep := (stiHandCursor in FInteractions) and (FindStepAt(APoint) >= 0);

  if LOverStep = FHandCursorShown then
    Exit;

  // The cursor of the control is replaced only while the mouse is over a step, and then given back.
  if LOverStep then
  begin
    FCursorBeforeHand := Cursor;
    Cursor := crHandPoint;
  end
  else
    Cursor := FCursorBeforeHand;

  FHandCursorShown := LOverStep;
end;

initialization
  RegisterFmxClasses([TS4YStepProgressBar]);

end.
