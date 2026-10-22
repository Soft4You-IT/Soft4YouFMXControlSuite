unit Soft4You.FMX.Controls.FlexBox.Design;

{
  Soft4You.FMX.Controls.FlexBox.Design - Design-time support for TS4YFlexBox
  ===========================================================================

  The per-child properties (flex-grow, flex-shrink, flex-basis, align-self,
  order) are published properties of TS4YFlexItem and are edited in the
  Object Inspector by selecting the item: no dedicated windows are needed.

  This unit only deals with automatic wrapping in the designer:
  when a control that is not a TS4YFlexItem becomes a child of a
  TS4YFlexBox, the component calls TS4YFlexBox.DesignWrapHandler. Here the
  handler creates the TS4YFlexItem with IDesigner.CreateComponent (correct name,
  Structure view, undo) and moves the control into it.

  Wrapping is deferred (TThread.ForceQueue) because the request arrives
  while the designer is still completing the insertion of the control.

  REGISTRATION
  ------------
  RegisterFlexDesignSupport / UnregisterFlexDesignSupport are called by the
  design-time package (see Soft4You.FMX.Controls.FlexBox.Register).
}

interface

procedure RegisterFlexDesignSupport;
procedure UnregisterFlexDesignSupport;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  Winapi.Windows,
  DesignIntf,
  ToolsAPI,
  FMX.Controls,
  Soft4You.FMX.Controls.FlexBox;

type
  // Design notification: keeps track of the open designers
  TFlexDesignNotification = class(TInterfacedObject, IDesignNotification)
  public
    procedure ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent);
    procedure ItemInserted(const ADesigner: IDesigner; AItem: TPersistent);
    procedure ItemsModified(const ADesigner: IDesigner);
    procedure SelectionChanged(const ADesigner: IDesigner;
      const ASelection: IDesignerSelections);
    procedure DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
    procedure DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean);
  end;

  // Pending wrapping request. As a component, it is notified if the
  // flexbox or the control is destroyed before it runs.
  TFlexWrapRequest = class(TComponent)
  strict private
    FFlexBox: TS4YFlexBox;
    FControl: TControl;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(const AFlexBox: TS4YFlexBox; const AControl: TControl); reintroduce;

    property Control: TControl read FControl;
    property FlexBox: TS4YFlexBox read FFlexBox;
  end;

var
  GDesigners: TList<IDesigner>;
  GNotification: IDesignNotification;

  // Controls that already have a wrapping request queued
  GPendingControls: TList<TControl>;

  // True while a wrapping is running: requests arriving at that
  // moment (side effects of the designer) are ignored
  GWrapping: Boolean;

// ===========================================================================
// TFlexWrapRequest
// ===========================================================================

constructor TFlexWrapRequest.Create(const AFlexBox: TS4YFlexBox; const AControl: TControl);
begin
  inherited Create(nil);
  FFlexBox := AFlexBox;
  FControl := AControl;
  FFlexBox.FreeNotification(Self);
  FControl.FreeNotification(Self);
end;

procedure TFlexWrapRequest.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if Operation = opRemove then
  begin
    if AComponent = FFlexBox then
    begin
      FFlexBox := nil;
    end;

    if AComponent = FControl then
    begin
      FControl := nil;
    end;
  end;
end;

// ===========================================================================
// Designer lookup and wrapping
// ===========================================================================

function FindDesigner(const AComponent: TComponent): IDesigner;
var
  LOwner: TComponent;
  LIndex: Integer;
begin
  Result := nil;
  LOwner := AComponent;

  while (Result = nil) and (LOwner <> nil) do
  begin
    for LIndex := 0 to GDesigners.Count - 1 do
    begin
      if GDesigners[LIndex].Root = LOwner then
      begin
        Result := GDesigners[LIndex];
      end;
    end;

    LOwner := LOwner.Owner;
  end;
end;

procedure WrapControlInDesigner(const ARequest: TFlexWrapRequest);
var
  LDesigner: IDesigner;
  LItem: TS4YFlexItem;
  LControl: TControl;
begin
  // The control must still be a direct child of the flexbox
  if (ARequest.FlexBox <> nil) and (ARequest.Control <> nil) and
    (ARequest.Control.Parent = ARequest.FlexBox) then
  begin
    LDesigner := FindDesigner(ARequest.FlexBox);

    if LDesigner <> nil then
    begin
      LControl := ARequest.Control;
      GWrapping := True;
      try
        LItem := LDesigner.CreateComponent(TS4YFlexItem, ARequest.FlexBox, 0, 0, 0, 0) as TS4YFlexItem;
        try
          ARequest.FlexBox.WrapInItem(LControl, LItem);
          LDesigner.Modified;
          LDesigner.SelectComponent(LControl);
        except
          on E: EInvalidOperation do
          begin
            // The control stays in the flexbox without an item (it is not laid out):
            // better than a blocking error during the drop. The unused item
            // is deleted.
            if LItem.ControlsCount = 0 then
            begin
              LItem.Free;
            end;
          end;
        end;
      finally
        GWrapping := False;
      end;
    end;
  end;
end;

procedure HandleDesignWrap(const AFlexBox: TS4YFlexBox; const AControl: TControl);
var
  LRequest: TFlexWrapRequest;
begin
  if not GWrapping and (GPendingControls.IndexOf(AControl) < 0) then
  begin
    GPendingControls.Add(AControl);
    LRequest := TFlexWrapRequest.Create(AFlexBox, AControl);
    TThread.ForceQueue(nil,
      procedure
      begin
        try
          if LRequest.Control <> nil then
          begin
            GPendingControls.Remove(LRequest.Control);
          end;

          WrapControlInDesigner(LRequest);
        finally
          LRequest.Free;
        end;
      end);
  end;
end;

// ===========================================================================
// TFlexDesignNotification
// ===========================================================================

procedure TFlexDesignNotification.DesignerOpened(const ADesigner: IDesigner;
  AResurrecting: Boolean);
begin
  if GDesigners.IndexOf(ADesigner) < 0 then
  begin
    GDesigners.Add(ADesigner);
  end;
end;

procedure TFlexDesignNotification.DesignerClosed(const ADesigner: IDesigner;
  AGoingDormant: Boolean);
begin
  GDesigners.Remove(ADesigner);
end;

procedure TFlexDesignNotification.ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent);
begin
end;

procedure TFlexDesignNotification.ItemInserted(const ADesigner: IDesigner; AItem: TPersistent);
begin
end;

procedure TFlexDesignNotification.ItemsModified(const ADesigner: IDesigner);
begin
end;

procedure TFlexDesignNotification.SelectionChanged(const ADesigner: IDesigner;
  const ASelection: IDesignerSelections);
begin
end;

// ===========================================================================
// Registration
// ===========================================================================

procedure RegisterFlexDesignSupport;
begin
  if GNotification = nil then
  begin
    GNotification := TFlexDesignNotification.Create;
    RegisterDesignNotification(GNotification);
    TS4YFlexBox.DesignWrapHandler := HandleDesignWrap;
  end;
end;

procedure UnregisterFlexDesignSupport;
begin
  TS4YFlexBox.DesignWrapHandler := nil;

  if GNotification <> nil then
  begin
    UnregisterDesignNotification(GNotification);
    GNotification := nil;
  end;
end;

// ===========================================================================
// IDE splash screen
// ===========================================================================

const
  C_FLEXBOX_VERSION = '1.0';

procedure RegisterSplash;
begin
  // The bitmap resource name must match the one in the .res
  // (FlexBoxDesign.rc), the same one used for the palette icon.
  SplashScreenServices.AddPluginBitmap(
    'TS4YFlexBox ' + C_FLEXBOX_VERSION + ' - CSS FlexBox for FireMonkey',
    LoadBitmap(HInstance, 'TS4YFLEXBOX'),
    False,
    'Freeware',
    '');
end;

initialization
  GDesigners := TList<IDesigner>.Create;
  GPendingControls := TList<TControl>.Create;
  RegisterSplash;

finalization
  UnregisterFlexDesignSupport;
  GPendingControls.Free;
  GDesigners.Free;

end.
