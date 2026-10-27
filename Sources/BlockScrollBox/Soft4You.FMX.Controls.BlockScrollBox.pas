unit Soft4You.FMX.Controls.BlockScrollBox;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YBlockScrollBox - scroll box with the CSS block flow
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{
  Soft4You.FMX.Controls.BlockScrollBox - scroll box with the CSS block flow
  ==========================================================================

  PROTOTYPE: the flow, the Align of the children, the order by Position.Y and
  the children with their own rules (IS4YBlockFlowChild).

  BLOCK FLOW
  ----------
  As display: block in CSS, the children are stacked from the top in the order
  of the children, each one under the previous one (Padding of the box plus
  Margins of the child; the vertical margins are added, they do not collapse).
  The box decides the position and the width, the child its height.

  ALIGN OF THE CHILDREN
  ---------------------
  The Align of a child does not align it: it tells the flow how to treat it.
  Only the values that have a meaning in the CSS model are kept, the others are
  set to the nearest one (NormalizeAlign):
    None   : own width, on the left (a width set in CSS)
    Top    : fills the width, own height (width: auto)
    Center : own width, centered (margin: 0 auto)
    Right  : own width, on the right (margin-left: auto)
  A child wider than the box is on the left, as a block with auto margins in
  CSS, and the horizontal scroll bar shows the rest.
  CHILDREN WITH THEIR OWN RULES
  -----------------------------
  A child that implements IS4YBlockFlowChild (the flexbox) and has an automatic
  width (GetFlowAutoWidth) is width: auto in CSS, with Align = None too: the
  flow gives it the available width with SetFlowBounds, never more, and the
  child sets its height. What its content overflows (GetFlowOverflowWidth)
  counts for the horizontal scroll bar, as the scrollable overflow in CSS.
  The content of the box implements IS4YBlockFlowContainer: the child knows it
  is in the flow without knowing the class of the box.

  The Anchors of the children do not count in the flow. A child with Align =
  None gets Anchors = [akTop]: with the default anchors FMX does not tell the
  parent that the child was moved with SetBounds (TControl.RequestAlign), which
  is how the designer moves it.

  ORDER OF THE CHILDREN
  ---------------------
  A new child goes at the end (as appendChild). A Position.Y set later, at
  design time or in code, moves the child after all the children whose Y is
  smaller; then the flow gives it its Y again. Position.X is not kept. In code
  the order can also be changed with Index.

  The children live in the content of the scroll box (TScrollContent): the
  content of the box (TS4YBlockScrollContent) calls ArrangeChildren instead of
  the alignment of FMX, and DoCalcContentBounds gives the size of the flow to
  the scroll bars.
}

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Types,
  FMX.Controls,
  FMX.Layouts,
  FMX.Types,
  Soft4You.FMX.Controls.BlockScrollBox.Abstracts;

type
  TS4YBlockScrollBox = class;

  /// <summary>Content of TS4YBlockScrollBox: it places the children with the block flow instead of the alignment of FMX.</summary>
  TS4YBlockScrollContent = class(TScrollContent, IS4YBlockFlowContainer)
  protected
    procedure DoRealign; override;
  end;

  /// <summary>Scroll box that stacks its children as blocks of the CSS flow (display: block): it decides their position and width, each child its height.</summary>
  TS4YBlockScrollBox = class(TScrollBox)
  private
    FArranging: Boolean;
    FFlowBounds: TRectF;
    FFlowTops: TDictionary<TControl, Single>;

    function IsFlowChild(const AControl: TControl): Boolean;
    procedure MoveMovedChildren;
    procedure MoveChildByTop(const AChild: TControl; ATop: Single);
    procedure NormalizeAligns;
    procedure PlaceChildren;
  protected
    procedure ContentAddObject(const AObject: TFmxObject); override;
    procedure ContentRemoveObject(const AObject: TFmxObject); override;
    function CreateScrollContent: TScrollContent; override;
    function DoCalcContentBounds: TRectF; override;
  public
    /// <summary>The Align that the flow keeps for a child: None, Top, Center or Right.</summary>
    class function NormalizeAlign(AAlign: TAlignLayout): TAlignLayout; static;

    /// <summary>Creates the box without children.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Destroys the box.</summary>
    destructor Destroy; override;

    /// <summary>Places the children with the block flow. The content calls it at every alignment.</summary>
    procedure ArrangeChildren;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  System.UITypes;

const
  // Anchors of a child with Align = None: different from the default ones, so
  // that FMX realigns the parent when the child is moved with SetBounds
  C_FLOW_ANCHORS = [TAnchorKind.akTop];
  // A difference of position below this is not a move of the user
  C_POSITION_TOLERANCE = 0.5;

{ TS4YBlockScrollContent }

procedure TS4YBlockScrollContent.DoRealign;
begin
  if ScrollBox is TS4YBlockScrollBox then
  begin
    TS4YBlockScrollBox(ScrollBox).ArrangeChildren;
  end
  else
  begin
    inherited;
  end;
end;

{ TS4YBlockScrollBox }

class function TS4YBlockScrollBox.NormalizeAlign(AAlign: TAlignLayout): TAlignLayout;
begin
  case AAlign of
    TAlignLayout.Top, TAlignLayout.Client, TAlignLayout.Contents, TAlignLayout.Bottom,
    TAlignLayout.MostTop, TAlignLayout.MostBottom, TAlignLayout.VertCenter,
    TAlignLayout.Horizontal:
      Result := TAlignLayout.Top;
    TAlignLayout.Center, TAlignLayout.HorzCenter:
      Result := TAlignLayout.Center;
    TAlignLayout.Right, TAlignLayout.MostRight, TAlignLayout.FitRight:
      Result := TAlignLayout.Right;
  else
    Result := TAlignLayout.None;
  end;
end;

constructor TS4YBlockScrollBox.Create(AOwner: TComponent);
begin
  inherited;
  FFlowTops := TDictionary<TControl, Single>.Create;
end;

destructor TS4YBlockScrollBox.Destroy;
begin
  inherited;
  // After inherited: the destruction of the children may still remove them
  FreeAndNil(FFlowTops);
end;

function TS4YBlockScrollBox.CreateScrollContent: TScrollContent;
begin
  Result := TS4YBlockScrollContent.Create(Self);
end;

procedure TS4YBlockScrollBox.ContentAddObject(const AObject: TFmxObject);
begin
  inherited;
  // A new child goes at the end of the flow right away
  ArrangeChildren;
end;

procedure TS4YBlockScrollBox.ContentRemoveObject(const AObject: TFmxObject);
begin
  inherited;

  if (FFlowTops <> nil) and (AObject is TControl) then
  begin
    FFlowTops.Remove(TControl(AObject));
  end;
end;

function TS4YBlockScrollBox.IsFlowChild(const AControl: TControl): Boolean;
begin
  Result := AControl.Visible and not Supports(AControl, IDesignerControl);
end;

procedure TS4YBlockScrollBox.ArrangeChildren;
begin
  if FArranging or (Content = nil) or
    (ComponentState * [csLoading, csDestroying] <> []) then
  begin
    Exit;
  end;

  FArranging := True;
  try
    NormalizeAligns;
    MoveMovedChildren;
    PlaceChildren;
  finally
    FArranging := False;
  end;

  // The size of the flow changes the scroll bars; inside the alignment of the
  // scroll box the bounds are read right after
  if not InInternalAlign then
  begin
    RealignContent;
  end;
end;

procedure TS4YBlockScrollBox.NormalizeAligns;
var
  LAlign: TAlignLayout;
  LChild: TControl;
begin
  for var I := 0 to Content.ControlsCount - 1 do
  begin
    LChild := Content.Controls[I];
    LAlign := NormalizeAlign(LChild.Align);

    if LChild.Align <> LAlign then
    begin
      LChild.Align := LAlign;
    end;

    if (LAlign = TAlignLayout.None) and (LChild.Anchors <> C_FLOW_ANCHORS) then
    begin
      LChild.Anchors := C_FLOW_ANCHORS;
    end;
  end;
end;

procedure TS4YBlockScrollBox.MoveMovedChildren;
var
  LChild: TControl;
  LFlowTop: Single;
  LMovedChild: TControl;
begin
  // A child whose Y is no longer the one given by the flow was moved by the
  // user: one at a time, because every move changes the order
  repeat
    LMovedChild := nil;

    for var I := 0 to Content.ControlsCount - 1 do
    begin
      LChild := Content.Controls[I];

      if (LMovedChild = nil) and FFlowTops.TryGetValue(LChild, LFlowTop) and
        (Abs(LChild.Position.Y - LFlowTop) > C_POSITION_TOLERANCE) then
      begin
        LMovedChild := LChild;
      end;
    end;

    if LMovedChild <> nil then
    begin
      MoveChildByTop(LMovedChild, LMovedChild.Position.Y);
      // The new place is decided: the flow gives the child its Y again
      FFlowTops.Remove(LMovedChild);
    end;
  until LMovedChild = nil;
end;

procedure TS4YBlockScrollBox.MoveChildByTop(const AChild: TControl; ATop: Single);
var
  LChild: TControl;
  LFirst: TControl;
  LFlowTop: Single;
  LPrevious: TControl;
begin
  // The child goes after all the other children whose Y in the flow is smaller
  LFirst := nil;
  LPrevious := nil;

  for var I := 0 to Content.ControlsCount - 1 do
  begin
    LChild := Content.Controls[I];

    if (LChild <> AChild) and FFlowTops.TryGetValue(LChild, LFlowTop) then
    begin
      if LFirst = nil then
      begin
        LFirst := LChild;
      end;

      if LFlowTop < ATop then
      begin
        LPrevious := LChild;
      end;
    end;
  end;

  if LPrevious <> nil then
  begin
    // Index counts the child itself: after its removal the following ones go back by one
    if AChild.Index < LPrevious.Index then
    begin
      AChild.Index := LPrevious.Index;
    end
    else
    begin
      AChild.Index := LPrevious.Index + 1;
    end;
  end
  else if (LFirst <> nil) and (AChild.Index > LFirst.Index) then
  begin
    // Before all the others (a child already before them stays where it is)
    AChild.Index := LFirst.Index;
  end;
end;

procedure TS4YBlockScrollBox.PlaceChildren;
var
  LAvailableWidth: Single;
  LChild: TControl;
  LContentWidth: Single;
  LFlowChild: IS4YBlockFlowChild;
  LLeft: Single;
  LNeededWidth: Single;
  LOuterWidth: Single;
  LTop: Single;
  LWidth: Single;
begin
  LAvailableWidth := Max(0, Content.Width - Padding.Left - Padding.Right);
  LNeededWidth := 0;
  LTop := Padding.Top;

  for var I := 0 to Content.ControlsCount - 1 do
  begin
    LChild := Content.Controls[I];

    if IsFlowChild(LChild) then
    begin
      LTop := LTop + LChild.Margins.Top;
      LOuterWidth := Max(0, LAvailableWidth - LChild.Margins.Left - LChild.Margins.Right);
      LLeft := Padding.Left + LChild.Margins.Left;
      FFlowTops.AddOrSetValue(LChild, LTop);

      if Supports(LChild, IS4YBlockFlowChild, LFlowChild) and LFlowChild.GetFlowAutoWidth then
      begin
        // width: auto: the available width, never more; the child sets its height
        LFlowChild.SetFlowBounds(LLeft, LTop, LOuterWidth);
        LContentWidth := LFlowChild.GetFlowOverflowWidth;
      end
      else
      begin
        LWidth := LChild.Width;

        case LChild.Align of
          TAlignLayout.Top:
            LWidth := LOuterWidth;
          TAlignLayout.Center:
            LLeft := LLeft + Max(0, (LOuterWidth - LWidth) / 2);
          TAlignLayout.Right:
            LLeft := LLeft + Max(0, LOuterWidth - LWidth);
        end;

        if not (SameValue(LChild.Position.X, LLeft, 0.001) and SameValue(LChild.Position.Y, LTop, 0.001) and
          SameValue(LChild.Width, LWidth, 0.001)) then
        begin
          LChild.SetBounds(LLeft, LTop, LWidth, LChild.Height);
        end;

        LContentWidth := LWidth;

        if LFlowChild <> nil then
        begin
          LContentWidth := LFlowChild.GetFlowOverflowWidth;
        end;
      end;

      // A child that fills the width has no width of its own to keep, but what
      // its content overflows counts
      if (LChild.Align <> TAlignLayout.Top) or (LFlowChild <> nil) then
      begin
        LNeededWidth := Max(LNeededWidth, LLeft + LContentWidth + LChild.Margins.Right + Padding.Right);
      end;

      LTop := LTop + LChild.Height + LChild.Margins.Bottom;
    end
    else
    begin
      FFlowTops.Remove(LChild);
    end;
  end;

  FFlowBounds := TRectF.Create(0, 0, Max(Content.Width, LNeededWidth), LTop + Padding.Bottom);
end;

function TS4YBlockScrollBox.DoCalcContentBounds: TRectF;
begin
  Result := FFlowBounds;
end;

end.
