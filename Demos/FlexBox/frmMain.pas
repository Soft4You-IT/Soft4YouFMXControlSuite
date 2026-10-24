unit frmMain;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.Objects,
  FMX.ListBox,
  Soft4You.FMX.Controls.FlexBox, FMX.Layouts, Soft4You.FMX.Controls.FlexBox.ItemBase;

type
  TForm1 = class(TForm)
    LogoLabel: TLabel;
    LogoItem: TS4YFlexItem;
    MenuDashboardButton: TButton;
    MenuDashboardItem: TS4YFlexItem;
    MenuOrdersButton: TButton;
    MenuOrdersItem: TS4YFlexItem;
    MenuCustomersButton: TButton;
    MenuCustomersItem: TS4YFlexItem;
    MenuReportsButton: TButton;
    MenuReportsItem: TS4YFlexItem;
    MenuSettingsButton: TButton;
    MenuSettingsItem: TS4YFlexItem;
    SpacerRectangle: TRectangle;
    SpacerItem: TS4YFlexItem;
    LogoutButton: TButton;
    LogoutItem: TS4YFlexItem;
    SidebarFlexBox: TS4YFlexBox;
    SidebarPanel: TRectangle;
    HeaderTitleLabel: TLabel;
    HeaderTitleItem: TS4YFlexItem;
    HeaderSearchEdit: TEdit;
    HeaderSearchItem: TS4YFlexItem;
    HeaderUserButton: TButton;
    HeaderUserItem: TS4YFlexItem;
    HeaderFlexBox: TS4YFlexBox;
    HeaderPanel: TRectangle;
    KpiRevenueTitleLabel: TLabel;
    KpiRevenueValueLabel: TLabel;
    KpiRevenueDeltaLabel: TLabel;
    KpiRevenueCard: TRectangle;
    KpiRevenueItem: TS4YFlexItem;
    KpiOrdersTitleLabel: TLabel;
    KpiOrdersValueLabel: TLabel;
    KpiOrdersDeltaLabel: TLabel;
    KpiOrdersCard: TRectangle;
    KpiOrdersItem: TS4YFlexItem;
    KpiCustomersTitleLabel: TLabel;
    KpiCustomersValueLabel: TLabel;
    KpiCustomersDeltaLabel: TLabel;
    KpiCustomersCard: TRectangle;
    KpiCustomersItem: TS4YFlexItem;
    KpiConversionTitleLabel: TLabel;
    KpiConversionValueLabel: TLabel;
    KpiConversionDeltaLabel: TLabel;
    KpiConversionCard: TRectangle;
    KpiConversionItem: TS4YFlexItem;
    Bar1Rectangle: TRectangle;
    Bar1Item: TS4YFlexItem;
    Bar2Rectangle: TRectangle;
    Bar2Item: TS4YFlexItem;
    Bar3Rectangle: TRectangle;
    Bar3Item: TS4YFlexItem;
    Bar4Rectangle: TRectangle;
    Bar4Item: TS4YFlexItem;
    Bar5Rectangle: TRectangle;
    Bar5Item: TS4YFlexItem;
    Bar6Rectangle: TRectangle;
    Bar6Item: TS4YFlexItem;
    Bar7Rectangle: TRectangle;
    Bar7Item: TS4YFlexItem;
    Bar8Rectangle: TRectangle;
    Bar8Item: TS4YFlexItem;
    Bar9Rectangle: TRectangle;
    Bar9Item: TS4YFlexItem;
    Bar10Rectangle: TRectangle;
    Bar10Item: TS4YFlexItem;
    Bar11Rectangle: TRectangle;
    Bar11Item: TS4YFlexItem;
    Bar12Rectangle: TRectangle;
    Bar12Item: TS4YFlexItem;
    RevenueFlexBox: TS4YFlexBox;
    RevenueTitleLabel: TLabel;
    RevenueCard: TRectangle;
    RevenueItem: TS4YFlexItem;
    TrafficTitleLabel: TLabel;
    Traffic1Label: TLabel;
    Traffic1Progress: TProgressBar;
    Traffic2Label: TLabel;
    Traffic2Progress: TProgressBar;
    Traffic3Label: TLabel;
    Traffic3Progress: TProgressBar;
    Traffic4Label: TLabel;
    Traffic4Progress: TProgressBar;
    TrafficCard: TRectangle;
    TrafficItem: TS4YFlexItem;
    Order1ListBoxItem: TListBoxItem;
    Order2ListBoxItem: TListBoxItem;
    Order3ListBoxItem: TListBoxItem;
    Order4ListBoxItem: TListBoxItem;
    Order5ListBoxItem: TListBoxItem;
    OrdersListBox: TListBox;
    OrdersTitleLabel: TLabel;
    OrdersCard: TRectangle;
    OrdersItem: TS4YFlexItem;
    TasksTitleLabel: TLabel;
    Task1CheckBox: TCheckBox;
    Task2CheckBox: TCheckBox;
    Task3CheckBox: TCheckBox;
    Task4CheckBox: TCheckBox;
    Task5CheckBox: TCheckBox;
    TasksCard: TRectangle;
    TasksItem: TS4YFlexItem;
    ActivityTitleLabel: TLabel;
    Activity1Label: TLabel;
    Activity2Label: TLabel;
    Activity3Label: TLabel;
    Activity4Label: TLabel;
    Activity5Label: TLabel;
    ActivityCard: TRectangle;
    ActivityItem: TS4YFlexItem;
    MainFlexBox: TS4YFlexBox;
    MainScrollBox: TScrollBox;
    StatusBar1: TStatusBar;
    LabelFormSize: TLabel;
    procedure FormResize(Sender: TObject);
    procedure MainFlexBoxLayoutApplied(Sender: TObject);
    procedure MainFlexBoxLineCountChanged(Sender: TObject; ALineCount, APreviousLineCount: Integer);
  private
    FLineCount: Integer;
    procedure UpdateStatus;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

const
  // Below this form width the sidebar is hidden
  C_SIDEBAR_MIN_CLIENT_WIDTH = 700;

procedure TForm1.FormResize(Sender: TObject);
begin
  SidebarPanel.Visible := ClientWidth >= C_SIDEBAR_MIN_CLIENT_WIDTH;
end;

procedure TForm1.MainFlexBoxLayoutApplied(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TForm1.MainFlexBoxLineCountChanged(Sender: TObject; ALineCount, APreviousLineCount: Integer);
begin
  FLineCount := ALineCount;
end;

procedure TForm1.UpdateStatus;
begin
  LabelFormSize.Text := Format('Form: %d x %d  |  Main: %d x %d  |  Rows: %d  |  Active breakpoints: %d',
    [ClientWidth, ClientHeight, Round(MainFlexBox.Width), Round(MainFlexBox.Height), FLineCount,
    Length(MainFlexBox.ActiveBreakpoints)]);
end;

end.
