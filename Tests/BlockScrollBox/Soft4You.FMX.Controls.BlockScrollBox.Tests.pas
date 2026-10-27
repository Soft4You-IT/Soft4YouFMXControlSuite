unit Soft4You.FMX.Controls.BlockScrollBox.Tests;

{
  DUnitX tests for TS4YBlockScrollBox: the block flow of the children, the Align
  that the flow keeps, the order by Position.Y and Index, and the flexbox in
  the flow (width: auto, overflow counted for the horizontal scroll bar).

  Run with: DUnitX console runner or IDE Test Runner.
}

interface

uses
  System.Types,
  DUnitX.TestFramework,
  FMX.Objects,
  FMX.Types,
  Soft4You.FMX.Controls.BlockScrollBox,
  Soft4You.FMX.Controls.FlexBox;

type
  [TestFixture]
  TBlockScrollBoxTests = class
  private
    // Helper: a flexbox in the box, with AItemCount items 100 x 30 that do not shrink
    function AddFlexBox(const ABox: TS4YBlockScrollBox; AItemCount: Integer): TS4YFlexBox;

    // Helper: a rectangle in the box
    function AddRectangle(const ABox: TS4YBlockScrollBox; AWidth, AHeight: Single;
      AAlign: TAlignLayout): TRectangle;

    // Helper: a box with Padding 10 whose content is AWidth x 300
    function CreateBox(AWidth: Single): TS4YBlockScrollBox;

    // Helper: the size of the flow, which the scroll bars show
    function FlowBounds(const ABox: TS4YBlockScrollBox): TRectF;

    // Helper: the width of the content of the box changes
    procedure SetContentWidth(const ABox: TS4YBlockScrollBox; AWidth: Single);
  public
    [Test] procedure Test_Children_AreStackedWithPaddingAndMargins;
    [Test] procedure Test_NormalizeAlign_KeepsTheValuesOfTheFlow;
    [Test] procedure Test_Align_IsSetToTheValueOfTheFlow;
    [Test] procedure Test_AlignCenter_IsCentered;
    [Test] procedure Test_AlignRight_IsOnTheRight;
    [Test] procedure Test_AlignNone_GetsTheFlowAnchors;
    [Test] procedure Test_InvisibleChild_IsNotInTheFlow;
    [Test] procedure Test_FlowBounds_WidestChild;
    [Test] procedure Test_NewChild_GoesAtTheEnd;
    [Test] procedure Test_PositionY_MovesTheChildAfterTheSmallerOnes;
    [Test] procedure Test_PositionY_Zero_MovesTheChildFirst;
    [Test] procedure Test_SetBounds_MovesTheChild;
    [Test] procedure Test_PositionX_IsNotKept;
    [Test] procedure Test_Index_ChangesTheOrder;
    [Test] procedure Test_FlexBox_TakesTheGivenWidth;
    [Test] procedure Test_FlexBox_FollowsTheWidthOfTheBox;
    [Test] procedure Test_FlexBox_OverflowCountsForTheScrollBar;
    [Test] procedure Test_FlexBox_ClipChildren_NothingOverflows;
    [Test] procedure Test_FlexBox_MinWidth;
    [Test] procedure Test_FlexBox_AlignTop;
    [Test] procedure Test_FlexBox_HeightMovesTheNextChild;
    [Test] procedure Test_FlexBox_AutoWidthFalse_KeepsItsWidth;
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  FMX.Controls,
  Soft4You.FMX.Controls.FlexBox.Engine;

const
  TOLERANCE = 0.11;

type
  // Access to the content and to the size of the flow
  TBlockScrollBoxAccess = class(TS4YBlockScrollBox);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function TBlockScrollBoxTests.AddFlexBox(const ABox: TS4YBlockScrollBox;
  AItemCount: Integer): TS4YFlexBox;
var
  LContent: TRectangle;
  LItem: TS4YFlexItem;
begin
  Result := TS4YFlexBox.Create(nil);
  Result.Parent := ABox;

  for var I := 1 to AItemCount do
  begin
    LItem := TS4YFlexItem.Create(nil);
    LItem.FlexShrink := 0;
    LItem.Parent := Result;

    LContent := TRectangle.Create(nil);
    LContent.SetBounds(0, 0, 100, 30);
    LContent.Parent := LItem;
  end;

  ABox.ArrangeChildren;
end;

function TBlockScrollBoxTests.AddRectangle(const ABox: TS4YBlockScrollBox; AWidth,
  AHeight: Single; AAlign: TAlignLayout): TRectangle;
begin
  Result := TRectangle.Create(nil);
  Result.SetBounds(0, 0, AWidth, AHeight);
  Result.Align := AAlign;
  Result.Parent := ABox;
end;

function TBlockScrollBoxTests.CreateBox(AWidth: Single): TS4YBlockScrollBox;
begin
  Result := TS4YBlockScrollBox.Create(nil);
  Result.Padding.Rect := TRectF.Create(10, 10, 10, 10);
  SetContentWidth(Result, AWidth);
end;

function TBlockScrollBoxTests.FlowBounds(const ABox: TS4YBlockScrollBox): TRectF;
begin
  Result := TBlockScrollBoxAccess(ABox).DoCalcContentBounds;
end;

procedure TBlockScrollBoxTests.SetContentWidth(const ABox: TS4YBlockScrollBox; AWidth: Single);
begin
  // Without a form the box does not size its content: the test does it
  TBlockScrollBoxAccess(ABox).Content.SetBounds(0, 0, AWidth, 300);
  ABox.ArrangeChildren;
end;

// ===========================================================================
// Block flow
// ===========================================================================

procedure TBlockScrollBoxTests.Test_Children_AreStackedWithPaddingAndMargins;
var LBox: TS4YBlockScrollBox; LFirst, LSecond: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LFirst := AddRectangle(LBox, 100, 40, TAlignLayout.None);
    LSecond := AddRectangle(LBox, 100, 30, TAlignLayout.Top);
    LSecond.Margins.Rect := TRectF.Create(5, 5, 5, 5);
    LBox.ArrangeChildren;

    Assert.AreEqual(Single(10), LFirst.Position.X, TOLERANCE, 'first left');
    Assert.AreEqual(Single(10), LFirst.Position.Y, TOLERANCE, 'first top');
    Assert.AreEqual(Single(100), LFirst.Width, TOLERANCE, 'first width');
    Assert.AreEqual(Single(15), LSecond.Position.X, TOLERANCE, 'second left');
    Assert.AreEqual(Single(55), LSecond.Position.Y, TOLERANCE, 'second top');
    Assert.AreEqual(Single(370), LSecond.Width, TOLERANCE, 'second width');
    Assert.AreEqual(Single(100), FlowBounds(LBox).Height, TOLERANCE, 'height of the flow');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_NormalizeAlign_KeepsTheValuesOfTheFlow;
begin
  Assert.AreEqual(TAlignLayout.None, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.None), 'None');
  Assert.AreEqual(TAlignLayout.None, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.Left), 'Left');
  Assert.AreEqual(TAlignLayout.None, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.Scale), 'Scale');
  Assert.AreEqual(TAlignLayout.Top, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.Top), 'Top');
  Assert.AreEqual(TAlignLayout.Top, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.Client), 'Client');
  Assert.AreEqual(TAlignLayout.Top, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.Bottom), 'Bottom');
  Assert.AreEqual(TAlignLayout.Center, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.Center), 'Center');
  Assert.AreEqual(TAlignLayout.Center, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.HorzCenter), 'HorzCenter');
  Assert.AreEqual(TAlignLayout.Right, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.Right), 'Right');
  Assert.AreEqual(TAlignLayout.Right, TS4YBlockScrollBox.NormalizeAlign(TAlignLayout.FitRight), 'FitRight');
end;

procedure TBlockScrollBoxTests.Test_Align_IsSetToTheValueOfTheFlow;
var LBox: TS4YBlockScrollBox; LChild: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LChild := AddRectangle(LBox, 100, 30, TAlignLayout.Client);

    Assert.AreEqual(TAlignLayout.Top, LChild.Align, 'Client on add');

    LChild.Align := TAlignLayout.Left;
    LBox.ArrangeChildren;

    Assert.AreEqual(TAlignLayout.None, LChild.Align, 'Left changed later');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_AlignCenter_IsCentered;
var LBox: TS4YBlockScrollBox; LChild: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LChild := AddRectangle(LBox, 100, 30, TAlignLayout.Center);

    Assert.AreEqual(Single(150), LChild.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(100), LChild.Width, TOLERANCE, 'width');

    // Wider than the box: on the left, as a block with auto margins in CSS
    LChild.Width := 600;
    LBox.ArrangeChildren;

    Assert.AreEqual(Single(10), LChild.Position.X, TOLERANCE, 'left when wider');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_AlignRight_IsOnTheRight;
var LBox: TS4YBlockScrollBox; LChild: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LChild := AddRectangle(LBox, 100, 30, TAlignLayout.Right);

    Assert.AreEqual(Single(290), LChild.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(100), LChild.Width, TOLERANCE, 'width');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_AlignNone_GetsTheFlowAnchors;

// With the default anchors FMX does not tell the parent that the child moved
var LBox: TS4YBlockScrollBox; LChild: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LChild := AddRectangle(LBox, 100, 30, TAlignLayout.None);

    Assert.IsTrue(LChild.Anchors = [TAnchorKind.akTop], 'anchors');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_InvisibleChild_IsNotInTheFlow;
var LBox: TS4YBlockScrollBox; LFirst, LSecond: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LFirst := AddRectangle(LBox, 100, 40, TAlignLayout.None);
    LSecond := AddRectangle(LBox, 100, 30, TAlignLayout.None);
    LFirst.Visible := False;
    LBox.ArrangeChildren;

    Assert.AreEqual(Single(10), LSecond.Position.Y, TOLERANCE, 'top of the second');
    Assert.AreEqual(Single(50), FlowBounds(LBox).Height, TOLERANCE, 'height of the flow');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_FlowBounds_WidestChild;
var LBox: TS4YBlockScrollBox;
begin
  LBox := CreateBox(400);
  try
    AddRectangle(LBox, 100, 30, TAlignLayout.Top);
    AddRectangle(LBox, 600, 30, TAlignLayout.None);
    LBox.ArrangeChildren;

    Assert.AreEqual(Single(620), FlowBounds(LBox).Width, TOLERANCE, 'width of the flow');

    // A child that fills the width has no width of its own to keep
    SetContentWidth(LBox, 800);

    Assert.AreEqual(Single(800), FlowBounds(LBox).Width, TOLERANCE, 'width of the flow at 800');
  finally
    LBox.Free;
  end;
end;

// ===========================================================================
// Order of the children
// ===========================================================================

procedure TBlockScrollBoxTests.Test_NewChild_GoesAtTheEnd;
var LBox: TS4YBlockScrollBox; LFirst, LNew: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LFirst := AddRectangle(LBox, 100, 40, TAlignLayout.None);
    LNew := AddRectangle(LBox, 50, 10, TAlignLayout.None);

    Assert.AreEqual(Single(10), LFirst.Position.Y, TOLERANCE, 'top of the first');
    Assert.AreEqual(Single(50), LNew.Position.Y, TOLERANCE, 'top of the new one');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_PositionY_MovesTheChildAfterTheSmallerOnes;
var LBox: TS4YBlockScrollBox; LFirst, LSecond, LThird: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LFirst := AddRectangle(LBox, 100, 40, TAlignLayout.None);
    LSecond := AddRectangle(LBox, 100, 30, TAlignLayout.None);
    LThird := AddRectangle(LBox, 100, 20, TAlignLayout.None);

    // After the second (top 50), before the third (top 80)
    LFirst.Position.Y := 61;

    Assert.AreEqual(Single(10), LSecond.Position.Y, TOLERANCE, 'second');
    Assert.AreEqual(Single(40), LFirst.Position.Y, TOLERANCE, 'first');
    Assert.AreEqual(Single(80), LThird.Position.Y, TOLERANCE, 'third');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_PositionY_Zero_MovesTheChildFirst;
var LBox: TS4YBlockScrollBox; LFirst, LSecond: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LFirst := AddRectangle(LBox, 100, 40, TAlignLayout.None);
    LSecond := AddRectangle(LBox, 100, 30, TAlignLayout.None);
    LSecond.Position.Y := 0;

    Assert.AreEqual(Single(10), LSecond.Position.Y, TOLERANCE, 'second');
    Assert.AreEqual(Single(40), LFirst.Position.Y, TOLERANCE, 'first');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_SetBounds_MovesTheChild;

// The designer moves a control with SetBounds
var LBox: TS4YBlockScrollBox; LFirst, LSecond: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LFirst := AddRectangle(LBox, 100, 40, TAlignLayout.None);
    LSecond := AddRectangle(LBox, 100, 30, TAlignLayout.None);
    LFirst.SetBounds(0, 1000, 100, 40);

    Assert.AreEqual(Single(10), LSecond.Position.Y, TOLERANCE, 'second');
    Assert.AreEqual(Single(40), LFirst.Position.Y, TOLERANCE, 'first');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_PositionX_IsNotKept;
var LBox: TS4YBlockScrollBox; LChild: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LChild := AddRectangle(LBox, 100, 40, TAlignLayout.None);
    LChild.Position.X := 200;

    Assert.AreEqual(Single(10), LChild.Position.X, TOLERANCE, 'left');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_Index_ChangesTheOrder;
var LBox: TS4YBlockScrollBox; LFirst, LSecond: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LFirst := AddRectangle(LBox, 100, 40, TAlignLayout.None);
    LSecond := AddRectangle(LBox, 100, 30, TAlignLayout.None);
    LSecond.Index := 0;

    Assert.AreEqual(Single(10), LSecond.Position.Y, TOLERANCE, 'second');
    Assert.AreEqual(Single(40), LFirst.Position.Y, TOLERANCE, 'first');
  finally
    LBox.Free;
  end;
end;

// ===========================================================================
// Flexbox in the flow
// ===========================================================================

procedure TBlockScrollBoxTests.Test_FlexBox_TakesTheGivenWidth;
var LBox: TS4YBlockScrollBox; LFlexBox: TS4YFlexBox;
begin
  LBox := CreateBox(400);
  try
    LFlexBox := AddFlexBox(LBox, 2);

    Assert.AreEqual(Single(10), LFlexBox.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(10), LFlexBox.Position.Y, TOLERANCE, 'top');
    Assert.AreEqual(Single(380), LFlexBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(30), LFlexBox.Height, TOLERANCE, 'height');
    Assert.IsTrue(LFlexBox.AutoWidth, 'AutoWidth');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_FlexBox_FollowsTheWidthOfTheBox;
var LBox: TS4YBlockScrollBox; LFlexBox: TS4YFlexBox;
begin
  LBox := CreateBox(400);
  try
    LFlexBox := AddFlexBox(LBox, 2);
    SetContentWidth(LBox, 600);

    Assert.AreEqual(Single(580), LFlexBox.Width, TOLERANCE, 'width');
    Assert.IsTrue(LFlexBox.AutoWidth, 'AutoWidth');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_FlexBox_OverflowCountsForTheScrollBar;

// width: auto in CSS: the flexbox does not grow, its items overflow
var LBox: TS4YBlockScrollBox; LFlexBox: TS4YFlexBox;
begin
  LBox := CreateBox(400);
  try
    LFlexBox := AddFlexBox(LBox, 5);

    Assert.AreEqual(Single(380), LFlexBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(520), FlowBounds(LBox).Width, TOLERANCE, 'width of the flow');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_FlexBox_ClipChildren_NothingOverflows;

// As overflow: hidden in CSS
var LBox: TS4YBlockScrollBox; LFlexBox: TS4YFlexBox;
begin
  LBox := CreateBox(400);
  try
    LFlexBox := AddFlexBox(LBox, 5);
    LFlexBox.ClipChildren := True;
    LBox.ArrangeChildren;

    Assert.AreEqual(Single(400), FlowBounds(LBox).Width, TOLERANCE, 'width of the flow');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_FlexBox_MinWidth;
var LBox: TS4YBlockScrollBox; LFlexBox: TS4YFlexBox;
begin
  LBox := CreateBox(400);
  try
    LFlexBox := AddFlexBox(LBox, 5);
    LFlexBox.MinWidth := 700;
    LBox.ArrangeChildren;

    Assert.AreEqual(Single(700), LFlexBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(720), FlowBounds(LBox).Width, TOLERANCE, 'width of the flow');
    Assert.IsTrue(LFlexBox.AutoWidth, 'AutoWidth');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_FlexBox_AlignTop;
var LBox: TS4YBlockScrollBox; LFlexBox: TS4YFlexBox;
begin
  LBox := CreateBox(400);
  try
    LFlexBox := AddFlexBox(LBox, 5);
    LFlexBox.Align := TAlignLayout.Top;
    LBox.ArrangeChildren;

    Assert.AreEqual(Single(380), LFlexBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(520), FlowBounds(LBox).Width, TOLERANCE, 'width of the flow');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_FlexBox_HeightMovesTheNextChild;
var LBox: TS4YBlockScrollBox; LFlexBox: TS4YFlexBox; LNext: TRectangle;
begin
  LBox := CreateBox(400);
  try
    LFlexBox := AddFlexBox(LBox, 5);
    LNext := AddRectangle(LBox, 50, 20, TAlignLayout.None);

    Assert.AreEqual(Single(40), LNext.Position.Y, TOLERANCE, 'next on one line');

    // Three items in a line of 380: two lines
    LFlexBox.Wrap := fwWrap;

    Assert.AreEqual(Single(60), LFlexBox.Height, TOLERANCE, 'height');
    Assert.AreEqual(Single(70), LNext.Position.Y, TOLERANCE, 'next on two lines');
    Assert.AreEqual(Single(400), FlowBounds(LBox).Width, TOLERANCE, 'width of the flow');
  finally
    LBox.Free;
  end;
end;

procedure TBlockScrollBoxTests.Test_FlexBox_AutoWidthFalse_KeepsItsWidth;
var LBox: TS4YBlockScrollBox; LFlexBox: TS4YFlexBox;
begin
  LBox := CreateBox(400);
  try
    LFlexBox := AddFlexBox(LBox, 5);
    LFlexBox.AutoWidth := False;
    LFlexBox.Width := 200;
    LBox.ArrangeChildren;

    Assert.AreEqual(Single(200), LFlexBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(10), LFlexBox.Position.X, TOLERANCE, 'left');
    // What overflows counts also with an explicit width
    Assert.AreEqual(Single(520), FlowBounds(LBox).Width, TOLERANCE, 'width of the flow');
  finally
    LBox.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TBlockScrollBoxTests);

end.
