unit ExpanderDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.EditBox,
  FMX.SpinBox,
  FMX.Layouts,
  Soft4You.FMX.Controls.Expander;

type
  TExpanderDemoForm = class(TForm)
    ExpandersLayout: TLayout;
    OrdersExpander: TS4YExpander;
    PendingOrdersLabel: TLabel;
    ShowShippedCheckBox: TCheckBox;
    RefreshButton: TButton;
    ShippingExpander: TS4YExpander;
    ShippingLabel: TLabel;
    ShippingDetailsLabel: TLabel;
    HistoryExpander: TS4YExpander;
    HistoryLabel: TLabel;
    SettingsPanel: TPanel;
    AnimatedCheckBox: TCheckBox;
    ClickOnHeaderCheckBox: TCheckBox;
    BadgeVisibleCheckBox: TCheckBox;
    BadgeValueLabel: TLabel;
    BadgeValueSpinBox: TSpinBox;
    DurationLabel: TLabel;
    DurationSpinBox: TSpinBox;
    ExpandAllButton: TButton;
    CollapseAllButton: TButton;
    procedure AnimatedCheckBoxChange(Sender: TObject);
    procedure BadgeValueSpinBoxChange(Sender: TObject);
    procedure BadgeVisibleCheckBoxChange(Sender: TObject);
    procedure ClickOnHeaderCheckBoxChange(Sender: TObject);
    procedure CollapseAllButtonClick(Sender: TObject);
    procedure DurationSpinBoxChange(Sender: TObject);
    procedure ExpandAllButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RefreshButtonClick(Sender: TObject);
  private
    procedure SetAllExpanded(Expanded: Boolean);
  end;

var
  ExpanderDemoForm: TExpanderDemoForm;

implementation

{$R *.fmx}

procedure TExpanderDemoForm.AnimatedCheckBoxChange(Sender: TObject);
begin
  OrdersExpander.Animated := AnimatedCheckBox.IsChecked;
  ShippingExpander.Animated := AnimatedCheckBox.IsChecked;
  HistoryExpander.Animated := AnimatedCheckBox.IsChecked;
end;

procedure TExpanderDemoForm.BadgeValueSpinBoxChange(Sender: TObject);
begin
  OrdersExpander.BadgeSettings.CurrentValue := Round(BadgeValueSpinBox.Value);
end;

procedure TExpanderDemoForm.BadgeVisibleCheckBoxChange(Sender: TObject);
begin
  OrdersExpander.BadgeSettings.Visible := BadgeVisibleCheckBox.IsChecked;
end;

procedure TExpanderDemoForm.ClickOnHeaderCheckBoxChange(Sender: TObject);
begin
  OrdersExpander.ClickOnHeader := ClickOnHeaderCheckBox.IsChecked;
  ShippingExpander.ClickOnHeader := ClickOnHeaderCheckBox.IsChecked;
  HistoryExpander.ClickOnHeader := ClickOnHeaderCheckBox.IsChecked;
end;

procedure TExpanderDemoForm.CollapseAllButtonClick(Sender: TObject);
begin
  SetAllExpanded(False);
end;

procedure TExpanderDemoForm.DurationSpinBoxChange(Sender: TObject);
begin
  OrdersExpander.AnimationDuration := DurationSpinBox.Value;
  ShippingExpander.AnimationDuration := DurationSpinBox.Value;
  HistoryExpander.AnimationDuration := DurationSpinBox.Value;
end;

procedure TExpanderDemoForm.ExpandAllButtonClick(Sender: TObject);
begin
  SetAllExpanded(True);
end;

procedure TExpanderDemoForm.FormCreate(Sender: TObject);
begin
  // The history starts collapsed: only its header is visible until the user opens it
  HistoryExpander.IsExpanded := False;
end;

procedure TExpanderDemoForm.RefreshButtonClick(Sender: TObject);
begin
  // The counter of the badge follows the application data
  BadgeValueSpinBox.Value := BadgeValueSpinBox.Value + 1;
end;

procedure TExpanderDemoForm.SetAllExpanded(Expanded: Boolean);
begin
  OrdersExpander.IsExpanded := Expanded;
  ShippingExpander.IsExpanded := Expanded;
  HistoryExpander.IsExpanded := Expanded;
end;

end.
