unit BlockScrollBoxDemoMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Objects,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.EditBox,
  FMX.SpinBox,
  FMX.Layouts,
  Soft4You.FMX.Controls.FlexBox,
  Soft4You.FMX.Controls.BlockScrollBox;

type
  TBlockScrollBoxDemoForm = class(TForm)
    PageBox: TS4YBlockScrollBox;
    TitleLabel: TLabel;
    IntroLabel: TLabel;
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
    CenterButton: TButton;
    RightLabel: TLabel;
    WideRectangle: TRectangle;
    WideLabel: TLabel;
    FooterLabel: TLabel;
    SettingsPanel: TPanel;
    WrapCheckBox: TCheckBox;
    ClipChildrenCheckBox: TCheckBox;
    MinWidthLabel: TLabel;
    MinWidthSpinBox: TSpinBox;
    AddBlockButton: TButton;
    FooterToTopButton: TButton;
    FooterToEndButton: TButton;
    procedure AddBlockButtonClick(Sender: TObject);
    procedure ClipChildrenCheckBoxChange(Sender: TObject);
    procedure FooterToEndButtonClick(Sender: TObject);
    procedure FooterToTopButtonClick(Sender: TObject);
    procedure MinWidthSpinBoxChange(Sender: TObject);
    procedure WrapCheckBoxChange(Sender: TObject);
  private
    FBlockCount: Integer;
  end;

var
  BlockScrollBoxDemoForm: TBlockScrollBoxDemoForm;

implementation

uses
  Soft4You.FMX.Controls.FlexBox.Engine;

{$R *.fmx}

const
  // A Position.Y greater than that of every block moves a block to the end
  C_END_OF_FLOW = 100000;

procedure TBlockScrollBoxDemoForm.AddBlockButtonClick(Sender: TObject);
var
  LBlock: TRectangle;
  LLabel: TLabel;
begin
  Inc(FBlockCount);
  LBlock := TRectangle.Create(Self);
  LBlock.Align := TAlignLayout.Top;
  LBlock.Height := 40;
  LBlock.Margins.Top := 12;
  LBlock.Fill.Color := $FFFEF3C7;
  LBlock.Stroke.Color := $FFF59E0B;
  LLabel := TLabel.Create(Self);
  LLabel.Align := TAlignLayout.Client;
  LLabel.TextSettings.HorzAlign := TTextAlign.Center;
  LLabel.Text := Format('Block %d, added at the end of the flow', [FBlockCount]);
  LLabel.Parent := LBlock;
  // A new child goes at the end, wherever it is
  LBlock.Parent := PageBox;
end;

procedure TBlockScrollBoxDemoForm.ClipChildrenCheckBoxChange(Sender: TObject);
begin
  CardsFlexBox.ClipChildren := ClipChildrenCheckBox.IsChecked;
  // ClipChildren does not start a layout: the flow reads the overflow again
  PageBox.ArrangeChildren;
end;

procedure TBlockScrollBoxDemoForm.FooterToEndButtonClick(Sender: TObject);
begin
  FooterLabel.Position.Y := C_END_OF_FLOW;
end;

procedure TBlockScrollBoxDemoForm.FooterToTopButtonClick(Sender: TObject);
begin
  // A new Position.Y is a place in the order: before all the blocks
  FooterLabel.Position.Y := 0;
end;

procedure TBlockScrollBoxDemoForm.MinWidthSpinBoxChange(Sender: TObject);
begin
  CardsFlexBox.MinWidth := MinWidthSpinBox.Value;
end;

procedure TBlockScrollBoxDemoForm.WrapCheckBoxChange(Sender: TObject);
begin
  if WrapCheckBox.IsChecked then
  begin
    CardsFlexBox.Wrap := fwWrap;
  end
  else
  begin
    CardsFlexBox.Wrap := fwNoWrap;
  end;
end;

end.
