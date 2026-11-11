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
  /// The fill and the border come from the style, unless Fill or Stroke is changed (see StyledBrushes). Content says what is drawn inside the circle.
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
  /// With HighlightProgress of the control set to True, the part of the line up to the current step uses the completed brush and the rest the pending brush; with False, the whole line uses the pending brush.
  /// </remarks>
  TS4YStepLineSettings = class(TPersistent)
  public const
    /// <summary>Default color of CompletedFill.</summary>
    C_DEFAULT_COMPLETED_COLOR: TAlphaColor = $FF1E88E5;
    /// <summary>Default color of PendingFill.</summary>
    C_DEFAULT_PENDING_COLOR: TAlphaColor = $FFE0E0E0;
    /// <summary>Default value of StyledBrushes: both brushes come from the style.</summary>
    C_DEFAULT_STYLED_BRUSHES: TS4YStepLineStyledBrushes = [slbCompleted, slbPending];
  private
    FCompletedFill: TBrush;
    FPendingFill: TBrush;
    FStyledBrushes: TS4YStepLineStyledBrushes;
    FUpdating: Boolean;
    FOnChange: TNotifyEvent;
    procedure CompletedFillChanged(Sender: TObject);
    procedure DoChange;
    procedure PendingFillChanged(Sender: TObject);
    procedure SetCompletedFill(const Value: TBrush);
    procedure SetPendingFill(const Value: TBrush);
    procedure SetStyledBrushes(const Value: TS4YStepLineStyledBrushes);
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
  end;

  /// <summary>
  /// A progress indicator made of steps along a horizontal or vertical line, for example the phases of an installation.
  /// </summary>
  /// <remarks>
  /// The steps are defined in Steps; CurrentStep, NextStep and PreviousStep say which one is in progress. The steps before the current one are drawn as completed, the ones after it as pending, and a step with Failed = True as failed.
  /// Each step has a marker, a circle by default, and optionally a caption and a description. The look comes from a style with the parts linecompleted, linepending, completedmarker, currentmarker, pendingmarker, failedmarker (shapes: fill and border), completedtext, currenttext, pendingtext, failedtext (texts: font of the number in the marker), completedlabel, currentlabel, pendinglabel, failedlabel and description (texts: font of the caption and of the description).
  /// OnDrawMarker draws a marker in place of the circle. Interactions lets the user change the current step with the mouse or the keyboard.
  /// </remarks>
  TS4YStepProgressBar = class(TStyledControl)
  public const
    /// <summary>Default value of AnimationDuration, in seconds.</summary>
    C_DEFAULT_ANIMATION_DURATION: Single = 0.3;
    /// <summary>Default value of HighlightProgress.</summary>
    C_DEFAULT_HIGHLIGHT_PROGRESS = True;
    /// <summary>Default value of LabelPosition.</summary>
    C_DEFAULT_LABEL_POSITION = slpAfter;
    /// <summary>Default value of LineThickness, in pixels.</summary>
    C_DEFAULT_LINE_THICKNESS: Single = 3;
    /// <summary>Default value of MarkerSize, in pixels.</summary>
    C_DEFAULT_MARKER_SIZE: Single = 28;
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
    FFocusFrameStroke: TStrokeBrush;
    FHandCursorShown: Boolean;
    FHighlightProgress: Boolean;
    FImages: TCustomImageList;
    FInteractions: TS4YStepInteractions;
    FLabelPosition: TS4YStepLabelPosition;
    FLine: TS4YStepLineSettings;
    FLineAnimation: TAnimation;
    FLineThickness: Single;
    FMarkerSize: Single;
    FOrientation: TOrientation;
    FPendingMarker: TS4YStepMarkerSettings;
    FSteps: TS4YStepItems;
    FStyleDescription: TText;
    FStyleFocusFrame: TShape;
    FStyleLabels: array[TS4YStepState] of TText;
    FStyleLineCompleted: TShape;
    FStyleLinePending: TShape;
    FStyleMarkers: array[TS4YStepState] of TShape;
    FStyleMarkerTexts: array[TS4YStepState] of TText;
    FTextLayout: TTextLayout;
    FOnDrawMarker: TS4YStepDrawMarkerEvent;
    FOnStepChanged: TNotifyEvent;
    FOnStepChanging: TS4YStepChangingEvent;
    procedure AnimateProgress(const ATargetProgress: Single);
    function AnimationDurationStored: Boolean;
    function CalculateLabelRect(const AStepIndex, AStepCount: Integer): TRectF;
    function CalculateLineRect(const AFrom, ATo: TPointF): TRectF;
    function CalculateMarkerCenter(const AStepIndex, AStepCount: Integer): TPointF;
    function CalculateMarkerRect(const AStepIndex, AStepCount: Integer): TRectF;
    function ChangeStep(const ANewStep: Integer): Boolean;
    function ClampStep(const AStep: Integer): Integer;
    procedure DrawFocusFrame(const AStepCount: Integer);
    procedure DrawLine(const AStepCount: Integer);
    procedure DrawMarker(const AStepIndex, AStepCount: Integer);
    procedure DrawMarkerContent(const AStepIndex: Integer; const AState: TS4YStepState; const AMarkerRect: TRectF);
    procedure DrawStepLabel(const AStepIndex, AStepCount: Integer);
    function FindStepAt(const APoint: TPointF): Integer;
    function GetContentRect: TRectF;
    function GetLabelHorizontalAlign: TTextAlign;
    function GetLabelVerticalAlign: TTextAlign;
    function GetLineBrush(const ABrush: TS4YStepLineStyledBrush): TBrush;
    function GetMarkerFill(const AState: TS4YStepState): TBrush;
    function GetMarkerSettings(const AState: TS4YStepState): TS4YStepMarkerSettings;
    function GetMarkerStroke(const AState: TS4YStepState): TStrokeBrush;
    function GetStepCount: Integer;
    function GetStepState(const AStepIndex: Integer): TS4YStepState;
    function IsAnimating: Boolean;
    function LineThicknessStored: Boolean;
    function MarkerSizeStored: Boolean;
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
    procedure SetLine(const Value: TS4YStepLineSettings);
    procedure SetLineThickness(const Value: Single);
    procedure SetMarkerSize(const Value: Single);
    procedure SetOrientation(const Value: TOrientation);
    procedure SetPendingMarker(const Value: TS4YStepMarkerSettings);
    procedure SetSteps(const Value: TS4YStepItems);
    procedure SettingsChanged(Sender: TObject);
    procedure StepsChanged;
    procedure UpdateHandCursor(const APoint: TPointF);
  protected
    /// <summary>Finds the parts of the style used to draw the control.</summary>
    procedure ApplyStyle; override;
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
    /// <summary>Releases the parts of the style found by ApplyStyle.</summary>
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
    /// <summary>Side of the line where the captions and the descriptions are shown, or slpNone to hide them. The default is slpAfter: below a horizontal line, on the right of a vertical one.</summary>
    property LabelPosition: TS4YStepLabelPosition read FLabelPosition write SetLabelPosition default C_DEFAULT_LABEL_POSITION;
    /// <summary>Brushes of the line that joins the markers.</summary>
    property Line: TS4YStepLineSettings read FLine write SetLine;
    /// <summary>Thickness of the line, in pixels. The default is 3.</summary>
    property LineThickness: Single read FLineThickness write SetLineThickness stored LineThicknessStored nodefault;
    property Margins;
    /// <summary>Width and height of the markers, in pixels. The default is 28.</summary>
    property MarkerSize: Single read FMarkerSize write SetMarkerSize stored MarkerSizeStored nodefault;
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
    /// <summary>Fires before a marker is drawn: setting Handled to True replaces the circle with what the event draws.</summary>
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
  C_STYLE_LINE_COMPLETED = 'linecompleted';
  C_STYLE_LINE_PENDING = 'linepending';
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

  // Space between a marker and its label, in pixels.
  C_LABEL_SPACING = 6;
  // Space between a marker and the focus frame around it, in pixels.
  C_FOCUS_FRAME_SPACING = 3;
  // Space between the circle of a marker and its image, as a fraction of MarkerSize.
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

{ TS4YStepProgressBar }

constructor TS4YStepProgressBar.Create(AOwner: TComponent);
begin
  inherited;

  FAnimationDuration := C_DEFAULT_ANIMATION_DURATION;
  FHighlightProgress := C_DEFAULT_HIGHLIGHT_PROGRESS;
  FLabelPosition := C_DEFAULT_LABEL_POSITION;
  FLineThickness := C_DEFAULT_LINE_THICKNESS;
  FMarkerSize := C_DEFAULT_MARKER_SIZE;
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

  FFocusFrameStroke := TStrokeBrush.Create(TBrushKind.Solid, C_DEFAULT_FOCUS_FRAME_COLOR);
  FFocusFrameStroke.Thickness := C_DEFAULT_FOCUS_FRAME_THICKNESS;
  FFocusFrameStroke.Dash := TStrokeDash.Dot;

  FDefaultFont := TFont.Create;
  FTextLayout := TTextLayoutManager.DefaultTextLayout.Create;
end;

destructor TS4YStepProgressBar.Destroy;
begin
  // Freed first, so that a running animation cannot touch the settings released below.
  FreeAndNil(FLineAnimation);
  FreeAndNil(FTextLayout);
  FreeAndNil(FDefaultFont);
  FreeAndNil(FFocusFrameStroke);
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

  FindStyleResource<TShape>(C_STYLE_LINE_COMPLETED, FStyleLineCompleted);
  FindStyleResource<TShape>(C_STYLE_LINE_PENDING, FStyleLinePending);
  FindStyleResource<TText>(C_STYLE_DESCRIPTION, FStyleDescription);
  FindStyleResource<TShape>(C_STYLE_FOCUS_FRAME, FStyleFocusFrame);

  for var LState := Low(TS4YStepState) to High(TS4YStepState) do
  begin
    FindStyleResource<TShape>(C_STYLE_MARKERS[LState], FStyleMarkers[LState]);
    FindStyleResource<TText>(C_STYLE_MARKER_TEXTS[LState], FStyleMarkerTexts[LState]);
    FindStyleResource<TText>(C_STYLE_LABELS[LState], FStyleLabels[LState]);
  end;

  Repaint;
end;

function TS4YStepProgressBar.CalculateLabelRect(const AStepIndex, AStepCount: Integer): TRectF;
var
  LContentRect: TRectF;
  LCenter: TPointF;
  LHalfCell: Single;
  LHalfMarker: Single;
begin
  LContentRect := GetContentRect;
  LCenter := CalculateMarkerCenter(AStepIndex, AStepCount);
  LHalfMarker := FMarkerSize / 2;

  if FOrientation = TOrientation.Horizontal then
  begin
    LHalfCell := LContentRect.Width / AStepCount / 2;
    Result.Left := LCenter.X - LHalfCell;
    Result.Right := LCenter.X + LHalfCell;

    if FLabelPosition = slpBefore then
    begin
      Result.Top := LContentRect.Top;
      Result.Bottom := LCenter.Y - LHalfMarker - C_LABEL_SPACING;
    end
    else
    begin
      Result.Top := LCenter.Y + LHalfMarker + C_LABEL_SPACING;
      Result.Bottom := LContentRect.Bottom;
    end;
  end
  else
  begin
    LHalfCell := LContentRect.Height / AStepCount / 2;
    Result.Top := LCenter.Y - LHalfCell;
    Result.Bottom := LCenter.Y + LHalfCell;

    if FLabelPosition = slpBefore then
    begin
      Result.Left := LContentRect.Left;
      Result.Right := LCenter.X - LHalfMarker - C_LABEL_SPACING;
    end
    else
    begin
      Result.Left := LCenter.X + LHalfMarker + C_LABEL_SPACING;
      Result.Right := LContentRect.Right;
    end;
  end;
end;

function TS4YStepProgressBar.CalculateLineRect(const AFrom, ATo: TPointF): TRectF;
var
  LHalfThickness: Single;
begin
  LHalfThickness := FLineThickness / 2;

  if FOrientation = TOrientation.Horizontal then
    Result := TRectF.Create(Min(AFrom.X, ATo.X), AFrom.Y - LHalfThickness, Max(AFrom.X, ATo.X), AFrom.Y + LHalfThickness)
  else
    Result := TRectF.Create(AFrom.X - LHalfThickness, Min(AFrom.Y, ATo.Y), AFrom.X + LHalfThickness, Max(AFrom.Y, ATo.Y));
end;

function TS4YStepProgressBar.CalculateMarkerCenter(const AStepIndex, AStepCount: Integer): TPointF;
var
  LContentRect: TRectF;
  LCellSize: Single;
  LCrossPosition: Single;
begin
  LContentRect := GetContentRect;

  if FOrientation = TOrientation.Horizontal then
  begin
    LCellSize := LContentRect.Width / AStepCount;

    case FLabelPosition of
      slpBefore:
        LCrossPosition := LContentRect.Bottom - FMarkerSize / 2;
      slpAfter:
        LCrossPosition := LContentRect.Top + FMarkerSize / 2;
    else
      LCrossPosition := LContentRect.CenterPoint.Y;
    end;

    Result := TPointF.Create(LContentRect.Left + (AStepIndex + 0.5) * LCellSize, LCrossPosition);
  end
  else
  begin
    LCellSize := LContentRect.Height / AStepCount;

    case FLabelPosition of
      slpBefore:
        LCrossPosition := LContentRect.Right - FMarkerSize / 2;
      slpAfter:
        LCrossPosition := LContentRect.Left + FMarkerSize / 2;
    else
      LCrossPosition := LContentRect.CenterPoint.X;
    end;

    Result := TPointF.Create(LCrossPosition, LContentRect.Top + (AStepIndex + 0.5) * LCellSize);
  end;
end;

function TS4YStepProgressBar.CalculateMarkerRect(const AStepIndex, AStepCount: Integer): TRectF;
var
  LCenter: TPointF;
  LHalfMarker: Single;
begin
  LCenter := CalculateMarkerCenter(AStepIndex, AStepCount);
  LHalfMarker := FMarkerSize / 2;
  Result := TRectF.Create(LCenter.X - LHalfMarker, LCenter.Y - LHalfMarker, LCenter.X + LHalfMarker, LCenter.Y + LHalfMarker);
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

  if FHighlightProgress and (FAnimationDuration > 0) and not (csDesigning in ComponentState) then
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
  LStroke: TStrokeBrush;
begin
  if not (stiKeyboard in FInteractions) or not IsFocused or (FSteps.Count = 0) then
    Exit;

  if Assigned(FStyleFocusFrame) then
    LStroke := FStyleFocusFrame.Stroke
  else
    LStroke := FFocusFrameStroke;

  LFrameRect := CalculateMarkerRect(FCurrentStep, AStepCount);
  LFrameRect.Inflate(C_FOCUS_FRAME_SPACING, C_FOCUS_FRAME_SPACING);
  Canvas.DrawEllipse(LFrameRect, AbsoluteOpacity, LStroke);
end;

procedure TS4YStepProgressBar.DrawLine(const AStepCount: Integer);
var
  LFirstCenter: TPointF;
  LLastCenter: TPointF;
  LProgressPoint: TPointF;
  LProgress: Single;
begin
  if AStepCount < 2 then
    Exit;

  LFirstCenter := CalculateMarkerCenter(0, AStepCount);
  LLastCenter := CalculateMarkerCenter(AStepCount - 1, AStepCount);

  if not FHighlightProgress then
  begin
    Canvas.FillRect(CalculateLineRect(LFirstCenter, LLastCenter), 0, 0, AllCorners, AbsoluteOpacity,
      GetLineBrush(slbPending));
    Exit;
  end;

  if FSteps.Count = 0 then
    LProgress := C_DESIGN_PREVIEW_CURRENT_STEP
  else
    LProgress := EnsureRange(FDisplayedProgress, 0, AStepCount - 1);

  LProgressPoint := LFirstCenter + (LLastCenter - LFirstCenter) * (LProgress / (AStepCount - 1));
  Canvas.FillRect(CalculateLineRect(LProgressPoint, LLastCenter), 0, 0, AllCorners, AbsoluteOpacity,
    GetLineBrush(slbPending));

  if LProgress > 0 then
    Canvas.FillRect(CalculateLineRect(LFirstCenter, LProgressPoint), 0, 0, AllCorners, AbsoluteOpacity,
      GetLineBrush(slbCompleted));
end;

procedure TS4YStepProgressBar.DrawMarker(const AStepIndex, AStepCount: Integer);
var
  LMarkerRect: TRectF;
  LStrokeRect: TRectF;
  LState: TS4YStepState;
  LStroke: TStrokeBrush;
begin
  LMarkerRect := CalculateMarkerRect(AStepIndex, AStepCount);
  LState := GetStepState(AStepIndex);

  if DoDrawMarker(Canvas, LMarkerRect, AStepIndex, LState) then
    Exit;

  Canvas.FillEllipse(LMarkerRect, AbsoluteOpacity, GetMarkerFill(LState));
  LStroke := GetMarkerStroke(LState);

  // The border is drawn inside the marker, so that MarkerSize is its whole size.
  if (LStroke.Kind <> TBrushKind.None) and (LStroke.Thickness > 0) then
  begin
    LStrokeRect := LMarkerRect;
    LStrokeRect.Inflate(-LStroke.Thickness / 2, -LStroke.Thickness / 2);
    Canvas.DrawEllipse(LStrokeRect, AbsoluteOpacity, LStroke);
  end;

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
        LImageRect.Inflate(-FMarkerSize * C_MARKER_IMAGE_MARGIN, -FMarkerSize * C_MARKER_IMAGE_MARGIN);
        FImages.Draw(Canvas, LImageRect, LImageIndex, AbsoluteOpacity);
      end;
    end;
  end;
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

procedure TS4YStepProgressBar.FreeStyle;
begin
  FStyleLineCompleted := nil;
  FStyleLinePending := nil;
  FStyleDescription := nil;
  FStyleFocusFrame := nil;

  for var LState := Low(TS4YStepState) to High(TS4YStepState) do
  begin
    FStyleMarkers[LState] := nil;
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

function TS4YStepProgressBar.GetLineBrush(const ABrush: TS4YStepLineStyledBrush): TBrush;
begin
  if ABrush = slbCompleted then
  begin
    if (slbCompleted in FLine.StyledBrushes) and Assigned(FStyleLineCompleted) then
      Result := FStyleLineCompleted.Fill
    else
      Result := FLine.CompletedFill;
  end
  else
  begin
    if (slbPending in FLine.StyledBrushes) and Assigned(FStyleLinePending) then
      Result := FStyleLinePending.Fill
    else
      Result := FLine.PendingFill;
  end;
end;

function TS4YStepProgressBar.GetMarkerFill(const AState: TS4YStepState): TBrush;
var
  LSettings: TS4YStepMarkerSettings;
begin
  LSettings := GetMarkerSettings(AState);

  if (smbFill in LSettings.StyledBrushes) and Assigned(FStyleMarkers[AState]) then
    Result := FStyleMarkers[AState].Fill
  else
    Result := LSettings.Fill;
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

function TS4YStepProgressBar.GetMarkerStroke(const AState: TS4YStepState): TStrokeBrush;
var
  LSettings: TS4YStepMarkerSettings;
begin
  LSettings := GetMarkerSettings(AState);

  if (smbStroke in LSettings.StyledBrushes) and Assigned(FStyleMarkers[AState]) then
    Result := FStyleMarkers[AState].Stroke
  else
    Result := LSettings.Stroke;
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
  else if (AStepIndex < LCurrentStep) and ((FSteps.Count = 0) or not FHighlightProgress or
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

function TS4YStepProgressBar.MarkerSizeStored: Boolean;
begin
  Result := not SameValue(FMarkerSize, C_DEFAULT_MARKER_SIZE);
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

procedure TS4YStepProgressBar.SetLine(const Value: TS4YStepLineSettings);
begin
  FLine.Assign(Value);
end;

procedure TS4YStepProgressBar.SetLineThickness(const Value: Single);
begin
  if SameValue(FLineThickness, Value) then
    Exit;

  FLineThickness := Max(0, Value);
  Repaint;
end;

procedure TS4YStepProgressBar.SetMarkerSize(const Value: Single);
begin
  if SameValue(FMarkerSize, Value) then
    Exit;

  FMarkerSize := Max(0, Value);
  Repaint;
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
