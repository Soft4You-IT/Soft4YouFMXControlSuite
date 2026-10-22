unit PlaceholderFrm;

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
  FMX.Controls.Presentation,
  FMX.Edit;

type
  TfrmPlaceholder = class(TForm)
    edDisplayedName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edPlaceholderName: TEdit;
    btnCancel: TButton;
    btnOk: TButton;
  private
    function GetDisplayedName: string;
    function GetPlaceholderName: string;
    procedure SetDisplayedName(const Value: string);
    procedure SetPlaceholderName(const Value: string);
  public
    class function Execute(var ADisplayedName, APlaceholderName: string): boolean;

    property DisplayedName: string read GetDisplayedName write SetDisplayedName;
    property PlaceholderName: string read GetPlaceholderName write SetPlaceholderName;
  end;

var
  frmPlaceholder: TfrmPlaceholder;

implementation

{$R *.fmx}

{ TfrmPlaceholder }

class function TfrmPlaceholder.Execute(var ADisplayedName, APlaceholderName: string): boolean;
var
  LDialog: TfrmPlaceholder;
begin
  LDialog := TfrmPlaceholder.Create(nil);

  try
    LDialog.DisplayedName := ADisplayedName;
    LDialog.PlaceholderName := APlaceholderName;

    if LDialog.ShowModal = mrOk then
    begin
      ADisplayedName := LDialog.DisplayedName;
      APlaceholderName := LDialog.PlaceholderName;
    end;
  finally
    LDialog.Free;
  end;
end;

function TfrmPlaceholder.GetDisplayedName: string;
begin
  Result := edDisplayedName.Text;
end;

function TfrmPlaceholder.GetPlaceholderName: string;
begin
  Result := edPlaceholderName.Text;
end;

procedure TfrmPlaceholder.SetDisplayedName(const Value: string);
begin
  edDisplayedName.Text := Value;
end;

procedure TfrmPlaceholder.SetPlaceholderName(const Value: string);
begin
  edPlaceholderName.Text := Value;
end;

end.
