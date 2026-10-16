unit ColorSelectionFrm;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Edit,
  FMX.Layouts,
  FMX.Controls.Presentation,
  FMX.Colors;

type
  TColorSelection = class(TForm)
    csColorSelector: TColorPanel;
    Panel1: TPanel;
    btnOk: TButton;
    btnCancel: TButton;
    Layout1: TLayout;
    edHTMLColor: TEdit;
    Label1: TLabel;
    boxColorPreview: TColorBox;
    Layout2: TLayout;
    procedure csColorSelectorChange(Sender: TObject);
    procedure edHTMLColorChange(Sender: TObject);
  private
    FSelectingColor: Boolean;
    function GetSelectedColor: TAlphaColor;
    procedure SetSelectedColor(const Value: TAlphaColor);
  public
    class function Execute(var AColor: TAlphacolor): boolean;

    constructor Create(AOwner: TComponent); override;

    property SelectedColor: TAlphaColor read GetSelectedColor write SetSelectedColor;
  end;

var
  ColorSelection: TColorSelection;

implementation

uses
  System.StrUtils,
  Soft4You.HTML.Colors;

{$R *.fmx}

constructor TColorSelection.Create(AOwner: TComponent);
begin
  inherited;

  csColorSelector.SetFocus;
end;

procedure TColorSelection.csColorSelectorChange(Sender: TObject);
begin
  if FSelectingColor then
    exit;

  FSelectingColor := True;

  try
    edHTMLColor.Text := AlphaColorToHTMLHex(csColorSelector.Color);
  finally
    FSelectingColor := False;
  end;
end;

procedure TColorSelection.edHTMLColorChange(Sender: TObject);
var
  LColor: TAlphaColor;
begin
  if FSelectingColor then
    exit;

  FSelectingColor := True;

  try
    if HTMLColorToAlphaColor(edHTMLColor.Text, LColor) then
      csColorSelector.Color := LColor;
  finally
    FSelectingColor := False;
  end;
end;

class function TColorSelection.Execute(var AColor: TAlphacolor): boolean;
var
  LDialog: TColorSelection;
begin
  LDialog := TColorSelection.Create(nil);

  try
    LDialog.SelectedColor := AColor;

    Result := LDialog.ShowModal = mrOk;

    AColor := LDialog.SelectedColor;
  finally
    LDialog.Free;
  end;
end;

function TColorSelection.GetSelectedColor: TAlphaColor;
begin
  Result := csColorSelector.Color;
end;

procedure TColorSelection.SetSelectedColor(const Value: TAlphaColor);
begin
  csColorSelector.Color := Value;
end;

end.
