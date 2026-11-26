unit MobileGalleryMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.Types,
  System.Rtti,
  System.Math,
  System.Messaging,
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.TabControl,
  FMX.Layouts,
  FMX.Objects,
  FMX.Gestures,
  FMX.Grid,
  FMX.Grid.Style,
  FMX.ScrollBox,
  FMX.ActnList,
  FMX.MediaLibrary.Actions,
  Soft4You.FMX.Controls.HTMLEditor,
  Soft4You.FMX.Controls.FlexBox,
  Soft4You.FMX.Controls.BlockScrollBox,
  Soft4You.FMX.Controls.Badge,
  Soft4You.FMX.Controls.Avatar,
  Soft4You.FMX.Controls.Tag,
  Soft4You.FMX.Controls.Tag.Types,
  Soft4You.FMX.Controls.Chip,
  Soft4You.FMX.Controls.ChipGroup,
  Soft4You.FMX.Controls.ChipEdit,
  Soft4You.FMX.Controls.Expander,
  Soft4You.FMX.Controls.StepProgressBar,
  Soft4You.FMX.Controls.Gauges,
  Soft4You.FMX.Controls.Gauges.Linear,
  Soft4You.FMX.Controls.Gauges.Circular,
  Soft4You.FMX.Controls.Gauges.LinearMeter,
  Soft4You.FMX.Controls.Gauges.CircularMeter,
  Soft4You.FMX.Controls.Gauges.SkinCircular,
  Soft4You.FMX.Controls.Gauges.SkinLinear,
  Soft4You.FMX.Controls.Charts,
  Soft4You.FMX.Controls.Charts.Categories,
  Soft4You.FMX.Controls.Charts.Pie,
  Soft4You.FMX.Controls.Charts.Bar,
  Soft4You.FMX.Controls.Charts.Line,
  Soft4You.FMX.Controls.Grid.Types,
  Soft4You.FMX.Controls.Grid,
  Soft4You.FMX.Controls.ColorSelector;

type
  TGalleryCustomer = class
  public
    Amount: Currency;
    City: string;
    // The position in the data: the order of the rows that are the same for all the keys.
    Id: Integer;
    Name: string;
    Orders: Integer;
  end;

  /// <summary>
  /// A gallery of all the controls of the suite for the phones: one page for each family, changed with a swipe.
  /// </summary>
  /// <remarks>
  /// The controls show fixed values, or values moved by timers: only the editor, the filters of the grid and the
  /// expanders are used by hand. The timers of a page run only while the page is shown.
  /// </remarks>
  TMobileGalleryForm = class(TForm)
    ContentLayout: TLayout;
    HeaderLayout: TLayout;
    PageTitleLabel: TLabel;
    SwipeHintLabel: TLabel;
    DotsLayout: TLayout;
    DotsCenterLayout: TLayout;
    GalleryTabControl: TTabControl;
    EditorTab: TTabItem;
    EditorButtonsLayout: TFlowLayout;
    BoldButton: TButton;
    ItalicButton: TButton;
    UnderlineButton: TButton;
    BulletsButton: TButton;
    NumbersButton: TButton;
    TableButton: TButton;
    HTMLEditor: TS4YHTMLEditor;
    LayoutTab: TTabItem;
    LayoutScrollBox: TS4YBlockScrollBox;
    LayoutTitleLabel: TLabel;
    LayoutIntroLabel: TLabel;
    CardsFlexBox: TS4YFlexBox;
    Card1Item: TS4YFlexItem;
    Card1Rectangle: TRectangle;
    Card1Label: TLabel;
    Card2Item: TS4YFlexItem;
    Card2Rectangle: TRectangle;
    Card2Label: TLabel;
    Card3Item: TS4YFlexItem;
    Card3Rectangle: TRectangle;
    Card3Label: TLabel;
    Card4Item: TS4YFlexItem;
    Card4Rectangle: TRectangle;
    Card4Label: TLabel;
    Card5Item: TS4YFlexItem;
    Card5Rectangle: TRectangle;
    Card5Label: TLabel;
    Card6Item: TS4YFlexItem;
    Card6Rectangle: TRectangle;
    Card6Label: TLabel;
    LayoutFooterLabel: TLabel;
    BadgeTab: TTabItem;
    BadgeScrollBox: TVertScrollBox;
    BadgeTitleLabel: TLabel;
    BadgeButtonsLayout: TLayout;
    MessagesButton: TButton;
    MessagesBadge: TS4YBadge;
    CartButton: TButton;
    CartBadge: TS4YBadge;
    ReleaseNotesLabel: TLabel;
    ReleaseNotesBadge: TS4YBadge;
    ExpanderTitleLabel: TLabel;
    OrdersExpander: TS4YExpander;
    PendingOrdersLabel: TLabel;
    ShippedOrdersLabel: TLabel;
    ShippingExpander: TS4YExpander;
    CarrierLabel: TLabel;
    DeliveryLabel: TLabel;
    HistoryExpander: TS4YExpander;
    HistoryLabel: TLabel;
    AvatarTab: TTabItem;
    AvatarScrollBox: TVertScrollBox;
    AvatarTitleLabel: TLabel;
    ProfileLayout: TLayout;
    ProfileAvatar: TS4YAvatar;
    ProfileBadge: TS4YBadge;
    ProfileHintLabel: TLabel;
    ContactsTitleLabel: TLabel;
    ContactsLayout: TFlowLayout;
    AnnaAvatar: TS4YAvatar;
    LucaAvatar: TS4YAvatar;
    GiuliaAvatar: TS4YAvatar;
    PaoloAvatar: TS4YAvatar;
    UnknownAvatar: TS4YAvatar;
    TagsTab: TTabItem;
    TagsScrollBox: TVertScrollBox;
    TagsTitleLabel: TLabel;
    TagsLabel: TLabel;
    TagsLayout: TFlowLayout;
    UrgentTag: TS4YTag;
    DraftTag: TS4YTag;
    DeliveredTag: TS4YTag;
    ReviewTag: TS4YTag;
    FilterChipsLabel: TLabel;
    FilterChipsLayout: TFlowLayout;
    OpenChip: TS4YChip;
    ProgressChip: TS4YChip;
    ClosedChip: TS4YChip;
    ChipsResultLabel: TLabel;
    RecipientChipsLabel: TLabel;
    RecipientChipsLayout: TFlowLayout;
    AnnaRecipientChip: TS4YChip;
    LucaRecipientChip: TS4YChip;
    SingleGroupLabel: TLabel;
    SingleChipGroup: TS4YChipGroup;
    MultipleGroupLabel: TLabel;
    MultipleChipGroup: TS4YChipGroup;
    ChipGroupResultLabel: TLabel;
    RecipientsEditLabel: TLabel;
    RecipientsChipEdit: TS4YChipEdit;
    RecipientsChipEditResultLabel: TLabel;
    StepsTab: TTabItem;
    StepsScrollBox: TVertScrollBox;
    HorizontalStepsLabel: TLabel;
    AnimationBar: TS4YStepProgressBar;
    VerticalStepsLabel: TLabel;
    TrackingBar: TS4YStepProgressBar;
    StepsTimer: TTimer;
    TrackingTimer: TTimer;
    GaugesTab: TTabItem;
    GaugesScrollBox: TVertScrollBox;
    GaugesTitleLabel: TLabel;
    CircularGaugesLayout: TLayout;
    CpuGauge: TS4YCircularGauge;
    SpeedGauge: TS4YCircularGauge;
    StorageGauge: TS4YLinearGauge;
    BatteryGauge: TS4YLinearGauge;
    MetersTitleLabel: TLabel;
    SpeedometerMeter: TS4YCircularMeter;
    TunerMeter: TS4YLinearMeter;
    SkinsTitleLabel: TLabel;
    SkinCircularGauge: TS4YSkinCircularGauge;
    SkinLinearGauge: TS4YSkinLinearGauge;
    GaugesTimer: TTimer;
    ChartsTab: TTabItem;
    ChartsScrollBox: TVertScrollBox;
    PieTitleLabel: TLabel;
    RingPie: TS4YPieChart;
    BarTitleLabel: TLabel;
    SalesBar: TS4YBarChart;
    LineTitleLabel: TLabel;
    VisitsLine: TS4YLineChart;
    ChartsTimer: TTimer;
    GridTab: TTabItem;
    GridHintLabel: TLabel;
    CustomersGrid: TS4YGrid;
    NameColumn: TStringColumn;
    CityColumn: TStringColumn;
    OrdersColumn: TIntegerColumn;
    AmountColumn: TCurrencyColumn;
    ColorsTab: TTabItem;
    ColorsScrollBox: TVertScrollBox;
    ColorsTitleLabel: TLabel;
    ColorsLayout: TLayout;
    DefaultColorSelector: TS4YColorSelector;
    WarmColorSelector: TS4YColorSelector;
    CoolColorSelector: TS4YColorSelector;
    GalleryActionList: TActionList;
    TakePhotoFromLibraryAction: TTakePhotoFromLibraryAction;
    GalleryGestureManager: TGestureManager;
    // Published: the events of the form file are bound to these methods by name.
    procedure BoldButtonClick(Sender: TObject);
    procedure BulletsButtonClick(Sender: TObject);
    procedure ChartsTimerTimer(Sender: TObject);
    procedure ChipCheckedChange(Sender: TObject);
    procedure ChipGroupChange(Sender: TObject);
    procedure CustomersGridFilter(Sender: TObject);
    procedure CustomersGridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
    procedure CustomersGridSort(Sender: TObject);
    procedure FlowLayoutResized(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure GalleryTabControlChange(Sender: TObject);
    procedure GaugesTimerTimer(Sender: TObject);
    procedure HeaderLayoutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure HeaderLayoutMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure ItalicButtonClick(Sender: TObject);
    procedure NumbersButtonClick(Sender: TObject);
    procedure RecipientsChipEditChange(Sender: TObject; const Text: string; Index: Integer);
    procedure RecipientsChipEditValidate(Sender: TObject; const Text: string; var Accept: Boolean;
      var Kind: TS4YTagKind);
    procedure StepsTimerTimer(Sender: TObject);
    procedure TableButtonClick(Sender: TObject);
    procedure TrackingTimerTimer(Sender: TObject);
    procedure UnderlineButtonClick(Sender: TObject);
  private
    FCustomers: TObjectList<TGalleryCustomer>;
    FDots: TArray<TCircle>;
    FHeaderPressed: Boolean;
    FHeaderPressPoint: TPointF;
    FKeyboardMessageId: Integer;
    FPageChangeTime: Cardinal;
    FPhotoPermissionRequested: Boolean;
    FTrackingPause: Integer;
    FVisibleCustomers: TList<TGalleryCustomer>;

    function BuildDocument: string;
    procedure BuildCustomers;
    function CompareCustomers(const ALeft, ARight: TGalleryCustomer; const AColumn: TColumn): Integer;
    procedure CreateDots;
    procedure FitFlowLayout(const ALayout: TFlowLayout);
    procedure FitFlowLayouts;
    procedure RequestPhotoPermission;
    procedure ShowCustomers;
    procedure ShowPage(const AIndex: Integer);
    procedure UpdatePage;
    procedure VirtualKeyboardChanged(const Sender: TObject; const AMessage: TMessage);
  end;

var
  MobileGalleryForm: TMobileGalleryForm;

implementation

{$R *.fmx}

uses
  System.Generics.Defaults,
  System.Permissions;

resourcestring
  S_PAGE_TITLE = '%s  %d / %d';

const
  C_DOCUMENT =
    '<h2>TS4YHTMLEditor</h2>' +
    '<p>Tap here and type. The buttons above change the text: <b>bold</b>, <i>italic</i>, <u>underline</u>.</p>' +
    '<ul><li>A list with bullets</li><li>Second item</li></ul>' +
    '<ol><li>A numbered list</li><li>Second item</li></ol>' +
    '<table border="1" cellpadding="6"><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>' +
    '<h3>A longer text</h3>' +
    '<p>Drag the document with a finger to scroll it: a quick move goes on and slows down, a finger on the ' +
    'editor stops it. A tap puts the caret where the finger is, a double tap selects a word.</p>' +
    '<p>The editor keeps the formatting of the text around the caret: write inside <b>this bold part</b> or ' +
    'inside <i>this italic part</i> and the new letters take the same style.</p>' +
    '<blockquote>A quotation, indented from the text around it.</blockquote>' +
    '<p>Paragraphs, lists and tables can be mixed freely. Enter in the middle of a word splits the paragraph, ' +
    'Backspace at its start joins it to the previous one.</p>' +
    '<ul><li>Bold, italic and underline</li><li>Lists with bullets and numbers</li><li>Tables, also nested</li>' +
    '<li>Images and links</li><li>Undo and redo</li></ul>' +
    '<p>The suggestions and the corrections of the keyboard replace the word before the caret, and go into the ' +
    'document as if they had been typed.</p>';
  C_DOCUMENT_END = '<p>End of the document.</p>';
  C_LONG_PARAGRAPH =
    '<p><b>Paragraph %d.</b> A paragraph of the long part of the document, so that there is something to ' +
    'scroll: drag it up and down with a finger, or give it a quick move and let it slow down.</p>';
  C_LONG_PARAGRAPH_COUNT = 30;
  C_CUSTOMER_COUNT = 60;
  C_FIRST_NAMES: array[0..9] of string = ('Anna', 'Bruno', 'Carla', 'Dario', 'Elena', 'Franco', 'Giulia', 'Luca',
    'Marta', 'Paolo');
  C_LAST_NAMES: array[0..9] of string = ('Rossi', 'Bianchi', 'Ferrari', 'Esposito', 'Romano', 'Colombo', 'Ricci',
    'Marino', 'Greco', 'Bruno');
  C_CITIES: array[0..5] of string = ('Milan', 'Rome', 'Turin', 'Naples', 'Florence', 'Bologna');
  // Permission of Android needed by the action that takes a photo from the gallery.
  C_READ_STORAGE_PERMISSION = 'android.permission.READ_EXTERNAL_STORAGE';
  C_DOT_SIZE = 8;
  C_DOT_SPACING = 8;
  C_DOT_ACTIVE_COLOR: TAlphaColor = $FF1E88E5;
  C_DOT_INACTIVE_COLOR: TAlphaColor = $FFB0BEC5;
  // Horizontal distance, in pixels, of a drag on the header that changes the page.
  C_SWIPE_DISTANCE = 60;
  // Milliseconds after a change of page in which a new change is ignored: on the phones a swipe on the header is
  // both a gesture and a drag.
  C_PAGE_CHANGE_INTERVAL = 600;
  // Percent added to the step of the tracking at each tick of TrackingTimer.
  C_TRACKING_INCREMENT = 2;
  // Ticks of TrackingTimer to wait after a change of step, and at the end of the tracking.
  C_TRACKING_STEP_PAUSE = 4;
  C_TRACKING_END_PAUSE = 10;

procedure TMobileGalleryForm.BoldButtonClick(Sender: TObject);
begin
  HTMLEditor.ToggleBold;
end;

function TMobileGalleryForm.BuildDocument: string;
var
  LBuilder: TStringBuilder;
begin
  // A document longer than the screen, to try the scrolling with a finger
  LBuilder := TStringBuilder.Create(C_DOCUMENT);
  try
    for var I := 1 to C_LONG_PARAGRAPH_COUNT do
      LBuilder.Append(Format(C_LONG_PARAGRAPH, [I]));

    LBuilder.Append(C_DOCUMENT_END);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TMobileGalleryForm.BuildCustomers;
var
  LCustomer: TGalleryCustomer;
begin
  // The same customers at each start.
  RandSeed := 2026;

  for var I := 1 to C_CUSTOMER_COUNT do
  begin
    LCustomer := TGalleryCustomer.Create;
    LCustomer.Id := I;
    LCustomer.Name := C_FIRST_NAMES[Random(Length(C_FIRST_NAMES))] + ' ' + C_LAST_NAMES[Random(Length(C_LAST_NAMES))];
    LCustomer.City := C_CITIES[Random(Length(C_CITIES))];
    LCustomer.Orders := 1 + Random(40);
    LCustomer.Amount := RoundTo(LCustomer.Orders * (20 + Random * 180), -2);
    FCustomers.Add(LCustomer);
  end;
end;

procedure TMobileGalleryForm.BulletsButtonClick(Sender: TObject);
begin
  HTMLEditor.ToggleUnorderedList;
end;

procedure TMobileGalleryForm.ChartsTimerTimer(Sender: TObject);
begin
  // New values at each tick: the charts move from the values drawn to the new ones.
  for var I := 0 to RingPie.Slices.Count - 1 do
    RingPie.Slices[I].Value := 20 + Random(100);

  for var I := 0 to SalesBar.Categories.Count - 1 do
  begin
    SalesBar.Categories[I].Value[0] := 20 + Random(60);
    SalesBar.Categories[I].Value[1] := 20 + Random(60);
  end;

  for var I := 0 to VisitsLine.Categories.Count - 1 do
    VisitsLine.Categories[I].Value[0] := 80 + Random(160);
end;

function TMobileGalleryForm.CompareCustomers(const ALeft, ARight: TGalleryCustomer; const AColumn: TColumn): Integer;
begin
  if AColumn = NameColumn then
    Result := CompareText(ALeft.Name, ARight.Name)
  else if AColumn = CityColumn then
    Result := CompareText(ALeft.City, ARight.City)
  else if AColumn = OrdersColumn then
    Result := CompareValue(ALeft.Orders, ARight.Orders)
  else if AColumn = AmountColumn then
    Result := CompareValue(ALeft.Amount, ARight.Amount)
  else
    Result := 0;
end;

procedure TMobileGalleryForm.CreateDots;
var
  LDot: TCircle;
begin
  // One dot for each page, in a row in the middle of the header.
  SetLength(FDots, GalleryTabControl.TabCount);
  DotsCenterLayout.Width := GalleryTabControl.TabCount * (C_DOT_SIZE + C_DOT_SPACING) - C_DOT_SPACING;

  for var I := 0 to GalleryTabControl.TabCount - 1 do
  begin
    LDot := TCircle.Create(Self);
    LDot.Parent := DotsCenterLayout;
    LDot.HitTest := False;
    LDot.Stroke.Kind := TBrushKind.None;
    LDot.SetBounds(I * (C_DOT_SIZE + C_DOT_SPACING), (DotsCenterLayout.Height - C_DOT_SIZE) / 2, C_DOT_SIZE,
      C_DOT_SIZE);
    FDots[I] := LDot;
  end;
end;

procedure TMobileGalleryForm.ChipCheckedChange(Sender: TObject);
var
  LChip: TS4YChip;
  LSelected: string;
begin
  LSelected := '';

  for LChip in [OpenChip, ProgressChip, ClosedChip] do
  begin
    if LChip.Checked then
    begin
      if LSelected <> '' then
        LSelected := LSelected + ', ';

      LSelected := LSelected + LChip.Text;
    end;
  end;

  if LSelected = '' then
    LSelected := 'none';

  ChipsResultLabel.Text := 'Selected: ' + LSelected;
end;

procedure TMobileGalleryForm.ChipGroupChange(Sender: TObject);
var
  LSelected: string;
begin
  LSelected := string.Join(', ', SingleChipGroup.SelectedItems);

  if LSelected = '' then
    LSelected := 'none';

  ChipGroupResultLabel.Text := 'One: ' + LSelected + '. Several: ' +
    IntToStr(Length(MultipleChipGroup.SelectedItems)) + ' chosen';
end;

procedure TMobileGalleryForm.CustomersGridFilter(Sender: TObject);
begin
  ShowCustomers;
end;

procedure TMobileGalleryForm.CustomersGridGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
var
  LColumn: TColumn;
  LCustomer: TGalleryCustomer;
begin
  // The columns can be moved: the column is found from its index.
  LColumn := CustomersGrid.Columns[ACol];
  LCustomer := FVisibleCustomers[ARow];

  if LColumn = NameColumn then
    Value := LCustomer.Name
  else if LColumn = CityColumn then
    Value := LCustomer.City
  else if LColumn = OrdersColumn then
    Value := LCustomer.Orders
  else if LColumn = AmountColumn then
    Value := TValue.From<Currency>(LCustomer.Amount);
end;

procedure TMobileGalleryForm.CustomersGridSort(Sender: TObject);
begin
  ShowCustomers;
end;

procedure TMobileGalleryForm.FitFlowLayout(const ALayout: TFlowLayout);
var
  LBottom: Single;
  LChild: TControl;
begin
  // A flow layout wraps its controls on more lines but keeps the height it has: the height is brought to the bottom
  // of the lowest control, so that what is below moves with it.
  LBottom := 0;

  for LChild in ALayout.Controls do
  begin
    if LChild.Visible then
      LBottom := Max(LBottom, LChild.Position.Y + LChild.Height + LChild.Margins.Bottom);
  end;

  LBottom := LBottom + ALayout.Padding.Top + ALayout.Padding.Bottom;

  if (LBottom > 0) and not SameValue(LBottom, ALayout.Height) then
    ALayout.Height := LBottom;
end;

procedure TMobileGalleryForm.FitFlowLayouts;
begin
  FitFlowLayout(TagsLayout);
  FitFlowLayout(FilterChipsLayout);
  FitFlowLayout(RecipientChipsLayout);
end;

procedure TMobileGalleryForm.FlowLayoutResized(Sender: TObject);
begin
  // Fires after the controls are placed in the new width
  FitFlowLayout(TFlowLayout(Sender));
end;

procedure TMobileGalleryForm.FormCreate(Sender: TObject);
var
  LCities: TStringList;
begin
  // The gallery always opens on the first page, whichever page was selected when the form was saved.
  GalleryTabControl.TabIndex := 0;
  HTMLEditor.HTML := BuildDocument;
  HistoryExpander.IsExpanded := False;
  FCustomers := TObjectList<TGalleryCustomer>.Create;
  FVisibleCustomers := TList<TGalleryCustomer>.Create;
  BuildCustomers;
  FVisibleCustomers.AddRange(FCustomers);
  // The customers are the same at each start, the values of the timers are not.
  Randomize;

  // The grid shows the data: it is not edited, only filtered and sorted.
  CustomersGrid.Options := CustomersGrid.Options - [TGridOption.Editing];
  CustomersGrid.RowCount := FVisibleCustomers.Count;

  // The cities of the drop-down list of the filter.
  LCities := TStringList.Create;
  try
    LCities.AddStrings(C_CITIES);
    LCities.Sort;
    CustomersGrid.ColumnSettings.FindColumn(CityColumn).FilterItems := LCities;
  finally
    LCities.Free;
  end;

  CreateDots;
  FKeyboardMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TVKStateChangeMessage,
    VirtualKeyboardChanged);
  UpdatePage;
end;

procedure TMobileGalleryForm.FormDestroy(Sender: TObject);
begin
  TMessageManager.DefaultManager.Unsubscribe(TVKStateChangeMessage, FKeyboardMessageId);
  FVisibleCustomers.Free;
  FCustomers.Free;
end;

procedure TMobileGalleryForm.FormGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  // A swipe towards the left shows the next page, towards the right the previous one. On Windows the gestures
  // arrive only on the computers with a touch screen: the drag on the header works everywhere.
  case EventInfo.GestureID of
    sgiLeft:
      begin
        ShowPage(GalleryTabControl.TabIndex + 1);
        Handled := True;
      end;
    sgiRight:
      begin
        ShowPage(GalleryTabControl.TabIndex - 1);
        Handled := True;
      end;
  end;
end;

procedure TMobileGalleryForm.GalleryTabControlChange(Sender: TObject);
begin
  UpdatePage;
end;

procedure TMobileGalleryForm.GaugesTimerTimer(Sender: TObject);
begin
  // Random values: the gauges move from the value drawn to the new one.
  CpuGauge.Value := Random(101);
  SpeedGauge.Value := EnsureRange(SpeedGauge.Value + Random(81) - 40, SpeedGauge.Min, SpeedGauge.Max);
  StorageGauge.Value := 20 + Random(60);
  BatteryGauge.Value := 30 + Random(70);
  SpeedometerMeter.Value := EnsureRange(SpeedometerMeter.Value + Random(81) - 40, SpeedometerMeter.Min,
    SpeedometerMeter.Max);
  TunerMeter.Value := Random(61) - 30;
  SkinCircularGauge.Value := Random(101);
  SkinLinearGauge.Value := Random(101);
end;

procedure TMobileGalleryForm.HeaderLayoutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
begin
  FHeaderPressed := Button = TMouseButton.mbLeft;
  FHeaderPressPoint := TPointF.Create(X, Y);
end;

procedure TMobileGalleryForm.HeaderLayoutMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Single);
var
  LDistance: Single;
begin
  if not FHeaderPressed then
    Exit;

  FHeaderPressed := False;
  LDistance := X - FHeaderPressPoint.X;

  // A drag more horizontal than vertical: towards the left the next page, towards the right the previous one.
  if (Abs(LDistance) >= C_SWIPE_DISTANCE) and (Abs(Y - FHeaderPressPoint.Y) < Abs(LDistance)) then
  begin
    if LDistance < 0 then
      ShowPage(GalleryTabControl.TabIndex + 1)
    else
      ShowPage(GalleryTabControl.TabIndex - 1);
  end;
end;

procedure TMobileGalleryForm.ItalicButtonClick(Sender: TObject);
begin
  HTMLEditor.ToggleItalic;
end;

procedure TMobileGalleryForm.NumbersButtonClick(Sender: TObject);
begin
  HTMLEditor.ToggleOrderedList;
end;

procedure TMobileGalleryForm.RecipientsChipEditChange(Sender: TObject; const Text: string; Index: Integer);
begin
  RecipientsChipEditResultLabel.Text := IntToStr(RecipientsChipEdit.Items.Count) + ' recipients, the last change: ' + Text;
end;

procedure TMobileGalleryForm.RecipientsChipEditValidate(Sender: TObject; const Text: string; var Accept: Boolean;
  var Kind: TS4YTagKind);
begin
  // A text that does not look like an address is accepted but shown as a danger
  if (Pos('@', Text) < 2) or (Pos('.', Text, Pos('@', Text)) = 0) then
    Kind := tgkDanger;
end;

procedure TMobileGalleryForm.RequestPhotoPermission;
begin
  // On Android the action that takes a photo from the gallery needs the permission to read the storage, which is
  // asked to the user while the application runs: it is asked once, when the page of the avatar is shown.
  if FPhotoPermissionRequested then
    Exit;

  FPhotoPermissionRequested := True;
  {$IFDEF ANDROID}
  PermissionsService.RequestPermissions([C_READ_STORAGE_PERMISSION],
    procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      // Nothing: without the permission the camera button of the avatar shows the error of the action.
    end);
  {$ENDIF}
end;

procedure TMobileGalleryForm.ShowCustomers;
begin
  // The customers that pass the filters...
  FVisibleCustomers.Clear;

  for var LCustomer in FCustomers do
  begin
    if CustomersGrid.FilterMatches(NameColumn, LCustomer.Name) and
      CustomersGrid.FilterMatches(CityColumn, LCustomer.City) and
      CustomersGrid.FilterMatches(OrdersColumn, LCustomer.Orders) and
      CustomersGrid.FilterMatches(AmountColumn, TValue.From<Currency>(LCustomer.Amount)) then
      FVisibleCustomers.Add(LCustomer);
  end;

  // ...in the order of the keys, then in the order of the data.
  FVisibleCustomers.Sort(TComparer<TGalleryCustomer>.Construct(
    function(const ALeft, ARight: TGalleryCustomer): Integer
    var
      LIndex: Integer;
    begin
      Result := 0;
      LIndex := 0;

      while (Result = 0) and (LIndex < CustomersGrid.SortCount) do
      begin
        Result := CompareCustomers(ALeft, ARight, CustomersGrid.SortColumn[LIndex]);

        if CustomersGrid.SortDescending[LIndex] then
          Result := -Result;

        Inc(LIndex);
      end;

      if Result = 0 then
        Result := CompareValue(ALeft.Id, ARight.Id);
    end));

  // The grid keeps the values it has shown: the rows are now other customers.
  CustomersGrid.Model.ClearCache;
  CustomersGrid.RowCount := FVisibleCustomers.Count;
  CustomersGrid.Repaint;
  CustomersGrid.UpdateFooter;
end;

procedure TMobileGalleryForm.ShowPage(const AIndex: Integer);
begin
  // The first and the last page are the ends: the swipe does not go round.
  if (AIndex < 0) or (AIndex >= GalleryTabControl.TabCount) or (AIndex = GalleryTabControl.TabIndex) then
    Exit;

  if TThread.GetTickCount - FPageChangeTime < C_PAGE_CHANGE_INTERVAL then
    Exit;

  FPageChangeTime := TThread.GetTickCount;

  if AIndex > GalleryTabControl.TabIndex then
    GalleryTabControl.SetActiveTabWithTransition(GalleryTabControl.Tabs[AIndex], TTabTransition.Slide,
      TTabTransitionDirection.Normal)
  else
    GalleryTabControl.SetActiveTabWithTransition(GalleryTabControl.Tabs[AIndex], TTabTransition.Slide,
      TTabTransitionDirection.Reversed);
end;

procedure TMobileGalleryForm.StepsTimerTimer(Sender: TObject);
begin
  // After the last step the progress starts again from the first one.
  if not AnimationBar.NextStep then
    AnimationBar.CurrentStep := 0;
end;

procedure TMobileGalleryForm.TableButtonClick(Sender: TObject);
begin
  HTMLEditor.InsertTable;
end;

procedure TMobileGalleryForm.TrackingTimerTimer(Sender: TObject);
var
  LLastStep: Integer;
begin
  if FTrackingPause > 0 then
  begin
    Dec(FTrackingPause);
    Exit;
  end;

  // The line fills from the current step towards the next one; at 100 percent the next step begins.
  LLastStep := TrackingBar.Steps.Count - 1;

  if TrackingBar.CurrentStep >= LLastStep then
  begin
    TrackingBar.CurrentStep := 0;
    FTrackingPause := C_TRACKING_STEP_PAUSE;
  end
  else if TrackingBar.StepProgress >= TS4YStepProgressBar.C_MAX_STEP_PROGRESS then
  begin
    TrackingBar.NextStep;
    FTrackingPause := C_TRACKING_STEP_PAUSE;

    if TrackingBar.CurrentStep >= LLastStep then
      FTrackingPause := C_TRACKING_END_PAUSE;
  end
  else
    TrackingBar.StepProgress := TrackingBar.StepProgress + C_TRACKING_INCREMENT;
end;

procedure TMobileGalleryForm.UnderlineButtonClick(Sender: TObject);
begin
  HTMLEditor.ToggleUnderline;
end;

procedure TMobileGalleryForm.UpdatePage;
var
  LTab: TTabItem;
begin
  LTab := GalleryTabControl.ActiveTab;

  if not Assigned(LTab) then
    Exit;

  PageTitleLabel.Text := Format(S_PAGE_TITLE, [LTab.Text, LTab.Index + 1, GalleryTabControl.TabCount]);

  for var I := 0 to Length(FDots) - 1 do
  begin
    if I = LTab.Index then
      FDots[I].Fill.Color := C_DOT_ACTIVE_COLOR
    else
      FDots[I].Fill.Color := C_DOT_INACTIVE_COLOR;
  end;

  // The timers of a page run only while the page is shown.
  StepsTimer.Enabled := LTab = StepsTab;
  TrackingTimer.Enabled := LTab = StepsTab;
  GaugesTimer.Enabled := LTab = GaugesTab;
  ChartsTimer.Enabled := LTab = ChartsTab;

  if LTab = AvatarTab then
    RequestPhotoPermission;

  // The tags and the chips take their width from the style, which is applied when the page is shown: the lines of the
  // flow layouts are known only after that.
  if LTab = TagsTab then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        FitFlowLayouts;
      end);
  end;
end;

procedure TMobileGalleryForm.VirtualKeyboardChanged(const Sender: TObject; const AMessage: TMessage);
var
  LMessage: TVKStateChangeMessage;
begin
  // The pages end above the virtual keyboard, so that the text written stays in sight.
  LMessage := TVKStateChangeMessage(AMessage);

  if LMessage.KeyboardVisible then
    ContentLayout.Margins.Bottom := LMessage.KeyboardBounds.Height
  else
    ContentLayout.Margins.Bottom := 0;
end;

end.
