unit Soft4You.FMX.Controls.FlexBox.AutoSize.Tests;

{
  DUnitX tests for the automatic size of TS4YFlexBox, as width: auto and
  height: auto in CSS: the size is automatic until the user chooses it.

  Run with: DUnitX console runner or IDE Test Runner.
}

interface

uses
  DUnitX.TestFramework,
  FMX.Objects,
  FMX.Types,
  Soft4You.FMX.Controls.FlexBox,
  Soft4You.FMX.Controls.FlexBox.Engine;

type
  [TestFixture]
  TFlexBoxAutoSizeTests = class
  private
    // Helper: a flexbox in the given parent, with items whose content is 100 x 30
    function AddFlexBox(const AParent: TRectangle; AItemCount: Integer): TS4YFlexBox;

    // Helper: a parent of the given size with a flexbox of AItemCount items
    function CreateFlexBox(AParentWidth, AParentHeight: Single; AItemCount: Integer;
      out AParent: TRectangle): TS4YFlexBox;

    // Helper: saved state of the flexbox, in the text format of the form files
    function SaveAsText(const ABox: TS4YFlexBox): string;
  public
    [Test] procedure Test_Defaults_AreAutomatic;
    [Test] procedure Test_Auto_WidthOfParent_HeightOfContent;
    [Test] procedure Test_AutoWidth_FromThePositionToTheRightEdge;
    [Test] procedure Test_AutoWidth_MovingRepeatsTheLayout;
    [Test] procedure Test_AutoWidth_MovingWithSetBoundsRepeatsTheLayout;
    [Test] procedure Test_AutoWidth_RightPaddingAndMargins;
    [Test] procedure Test_AutoWidth_False_MovingKeepsTheWidth;
    [Test] procedure Test_AutoWidth_MinWidthIsAFloor;
    [Test] procedure Test_AutoWidth_GrowsToTheMinimumOfTheItems;
    [Test] procedure Test_SettingWidth_MakesItExplicit;
    [Test] procedure Test_SettingHeight_MakesItExplicit;
    [Test] procedure Test_AutoHeight_FollowsTheContentAtTheChosenWidth;
    [Test] procedure Test_SizeBeforeTheFirstLayout_IsNotAChoice;
    [Test] procedure Test_AlignTop_AutoHeight;
    [Test] procedure Test_AlignTop_ParentResize_IsNotAChoice;
    [Test] procedure Test_AlignTop_StackedFlexBoxes;
    [Test] procedure Test_AlignBottom_AutoHeight;
    [Test] procedure Test_AlignClient_NoAutoSize;
    [Test] procedure Test_AutoSize_False_SurvivesSaveAndLoad;
    [Test] procedure Test_AutoSize_Default_IsNotSaved;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  FMX.Controls;

const
  TOLERANCE = 0.11;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function TFlexBoxAutoSizeTests.AddFlexBox(const AParent: TRectangle;
  AItemCount: Integer): TS4YFlexBox;
var
  LContent: TRectangle;
  LItem: TS4YFlexItem;
begin
  Result := TS4YFlexBox.Create(nil);
  Result.Parent := AParent;

  for var I := 1 to AItemCount do
  begin
    LItem := TS4YFlexItem.Create(nil);
    LItem.Parent := Result;

    LContent := TRectangle.Create(nil);
    LContent.SetBounds(0, 0, 100, 30);
    LContent.Parent := LItem;
  end;
end;

function TFlexBoxAutoSizeTests.CreateFlexBox(AParentWidth, AParentHeight: Single;
  AItemCount: Integer; out AParent: TRectangle): TS4YFlexBox;
begin
  AParent := TRectangle.Create(nil);
  AParent.SetBounds(0, 0, AParentWidth, AParentHeight);
  Result := AddFlexBox(AParent, AItemCount);
end;

function TFlexBoxAutoSizeTests.SaveAsText(const ABox: TS4YFlexBox): string;
var
  LBinary: TMemoryStream;
  LText: TStringStream;
begin
  LBinary := TMemoryStream.Create;
  try
    LText := TStringStream.Create;
    try
      LBinary.WriteComponent(ABox);
      LBinary.Position := 0;
      ObjectBinaryToText(LBinary, LText);
      Result := LText.DataString;
    finally
      LText.Free;
    end;
  finally
    LBinary.Free;
  end;
end;

// ===========================================================================
// Automatic size
// ===========================================================================

procedure TFlexBoxAutoSizeTests.Test_Defaults_AreAutomatic;
var LBox: TS4YFlexBox;
begin
  LBox := TS4YFlexBox.Create(nil);
  try
    Assert.IsTrue(LBox.AutoWidth, 'AutoWidth');
    Assert.IsTrue(LBox.AutoHeight, 'AutoHeight');
  finally
    LBox.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_Auto_WidthOfParent_HeightOfContent;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    Assert.AreEqual(Single(600), LBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(30), LBox.Height, TOLERANCE, 'height');
    Assert.AreEqual(Single(0), LBox.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(0), LBox.Position.Y, TOLERANCE, 'top');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoWidth_FromThePositionToTheRightEdge;

// The position is not changed: the width is the space up to the right edge of the parent
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LParent := TRectangle.Create(nil);
  try
    LParent.SetBounds(0, 0, 600, 300);
    LBox := TS4YFlexBox.Create(nil);
    LBox.Position.Point := TPointF.Create(100, 40);
    LBox.Parent := LParent;
    LBox.InvalidateLayout;

    Assert.AreEqual(Single(100), LBox.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(40), LBox.Position.Y, TOLERANCE, 'top');
    Assert.AreEqual(Single(500), LBox.Width, TOLERANCE, 'width');
    Assert.IsTrue(LBox.AutoWidth, 'AutoWidth');
    Assert.IsTrue(LBox.AutoHeight, 'AutoHeight');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoWidth_MovingRepeatsTheLayout;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Position.Point := TPointF.Create(100, 40);

    Assert.AreEqual(Single(100), LBox.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(40), LBox.Position.Y, TOLERANCE, 'top');
    Assert.AreEqual(Single(500), LBox.Width, TOLERANCE, 'width at 100');

    LBox.Position.X := 200;

    Assert.AreEqual(Single(400), LBox.Width, TOLERANCE, 'width at 200');
    Assert.IsTrue(LBox.AutoWidth, 'AutoWidth');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoWidth_MovingWithSetBoundsRepeatsTheLayout;

// The designer moves a control with SetBounds, which does not let the layout run
// while the position changes
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.SetBounds(200, 40, LBox.Width, LBox.Height);

    Assert.AreEqual(Single(200), LBox.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(40), LBox.Position.Y, TOLERANCE, 'top');
    Assert.AreEqual(Single(400), LBox.Width, TOLERANCE, 'width');
    Assert.IsTrue(LBox.AutoWidth, 'AutoWidth');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoWidth_RightPaddingAndMargins;

// The Padding.Right of the parent and the Margins.Right of the flexbox are taken
// away; the left ones do not count, the position is that of the user
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LParent.Padding.Rect := TRectF.Create(30, 5, 10, 0);
    LBox.Margins.Rect := TRectF.Create(7, 3, 4, 0);
    LBox.Position.X := 20;

    Assert.AreEqual(Single(20), LBox.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(0), LBox.Position.Y, TOLERANCE, 'top');
    Assert.AreEqual(Single(566), LBox.Width, TOLERANCE, 'width');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoWidth_False_MovingKeepsTheWidth;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Width := 300;
    LBox.Position.Point := TPointF.Create(50, 40);

    Assert.AreEqual(Single(50), LBox.Position.X, TOLERANCE, 'left');
    Assert.AreEqual(Single(40), LBox.Position.Y, TOLERANCE, 'top');
    Assert.AreEqual(Single(300), LBox.Width, TOLERANCE, 'width');
    Assert.IsFalse(LBox.AutoWidth, 'AutoWidth');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoWidth_MinWidthIsAFloor;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.MinWidth := 800;

    Assert.AreEqual(Single(800), LBox.Width, TOLERANCE, 'width');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoWidth_GrowsToTheMinimumOfTheItems;

// 3 * 100 in a parent 150 wide: the items do not shrink below their content
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(150, 300, 3, LParent);
  try
    Assert.AreEqual(Single(300), LBox.Width, TOLERANCE, 'width');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_SettingWidth_MakesItExplicit;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Width := 300;
    LParent.Width := 700;
    LBox.InvalidateLayout;

    Assert.IsFalse(LBox.AutoWidth, 'AutoWidth');
    Assert.IsTrue(LBox.AutoHeight, 'AutoHeight');
    Assert.AreEqual(Single(300), LBox.Width, TOLERANCE, 'width');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_SettingHeight_MakesItExplicit;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Height := 100;
    LBox.InvalidateLayout;

    Assert.IsFalse(LBox.AutoHeight, 'AutoHeight');
    Assert.IsTrue(LBox.AutoWidth, 'AutoWidth');
    Assert.AreEqual(Single(100), LBox.Height, TOLERANCE, 'height');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoHeight_FollowsTheContentAtTheChosenWidth;

// Width 250 with Wrap: 2 items per line, 3 items -> 2 lines of 30
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 3, LParent);
  try
    LBox.Wrap := fwWrap;
    LBox.Width := 250;

    Assert.IsFalse(LBox.AutoWidth, 'AutoWidth');
    Assert.AreEqual(Single(250), LBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(60), LBox.Height, TOLERANCE, 'height');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_SizeBeforeTheFirstLayout_IsNotAChoice;

// The size given before the flexbox has a parent is not a choice of the user
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LParent := TRectangle.Create(nil);
  try
    LParent.SetBounds(0, 0, 600, 300);
    LBox := TS4YFlexBox.Create(nil);
    LBox.SetBounds(0, 0, 400, 200);
    LBox.Parent := LParent;

    Assert.IsTrue(LBox.AutoWidth, 'AutoWidth');
    Assert.IsTrue(LBox.AutoHeight, 'AutoHeight');
    Assert.AreEqual(Single(600), LBox.Width, TOLERANCE, 'width');
  finally
    LParent.Free;
  end;
end;

// ===========================================================================
// Align = Top / Bottom / Client
// ===========================================================================

procedure TFlexBoxAutoSizeTests.Test_AlignTop_AutoHeight;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Align := TAlignLayout.Top;

    Assert.AreEqual(Single(600), LBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(30), LBox.Height, TOLERANCE, 'height');
    Assert.IsTrue(LBox.AutoHeight, 'AutoHeight');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AlignTop_ParentResize_IsNotAChoice;

// The parent gives the width to a flexbox aligned at the top: it is not a choice of the user
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Align := TAlignLayout.Top;
    LParent.Width := 400;

    Assert.AreEqual(Single(400), LBox.Width, TOLERANCE, 'width');
    Assert.IsTrue(LBox.AutoWidth, 'AutoWidth');
    Assert.IsTrue(LBox.AutoHeight, 'AutoHeight');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AlignTop_StackedFlexBoxes;

// Two flexboxes at the top, one under the other, each with the height of its content
var LFirst, LSecond: TS4YFlexBox; LParent: TRectangle;
begin
  LFirst := CreateFlexBox(600, 300, 2, LParent);
  try
    LSecond := AddFlexBox(LParent, 2);
    LFirst.Align := TAlignLayout.Top;
    LSecond.Align := TAlignLayout.Top;

    Assert.AreEqual(Single(30), LFirst.Height, TOLERANCE, 'first height');
    Assert.AreEqual(Single(30), LSecond.Height, TOLERANCE, 'second height');
    Assert.AreEqual(Single(0), LFirst.Position.Y, TOLERANCE, 'first top');
    Assert.AreEqual(Single(30), LSecond.Position.Y, TOLERANCE, 'second top');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AlignBottom_AutoHeight;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Align := TAlignLayout.Bottom;

    Assert.AreEqual(Single(30), LBox.Height, TOLERANCE, 'height');
    Assert.AreEqual(Single(270), LBox.Position.Y, TOLERANCE, 'top');
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AlignClient_NoAutoSize;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Align := TAlignLayout.Client;

    Assert.AreEqual(Single(600), LBox.Width, TOLERANCE, 'width');
    Assert.AreEqual(Single(300), LBox.Height, TOLERANCE, 'height');
  finally
    LParent.Free;
  end;
end;

// ===========================================================================
// Saving and loading
// ===========================================================================

procedure TFlexBoxAutoSizeTests.Test_AutoSize_False_SurvivesSaveAndLoad;
var
  LBinary: TMemoryStream;
  LBox, LLoaded: TS4YFlexBox;
  LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LBox.Width := 300;
    LBox.Height := 100;

    LBinary := TMemoryStream.Create;
    try
      LBinary.WriteComponent(LBox);
      LBinary.Position := 0;
      LLoaded := TS4YFlexBox.Create(nil);
      try
        LBinary.ReadComponent(LLoaded);

        Assert.IsFalse(LLoaded.AutoWidth, 'AutoWidth');
        Assert.IsFalse(LLoaded.AutoHeight, 'AutoHeight');
        Assert.AreEqual(Single(300), LLoaded.Width, TOLERANCE, 'width');
        Assert.AreEqual(Single(100), LLoaded.Height, TOLERANCE, 'height');
      finally
        LLoaded.Free;
      end;
    finally
      LBinary.Free;
    end;
  finally
    LParent.Free;
  end;
end;

procedure TFlexBoxAutoSizeTests.Test_AutoSize_Default_IsNotSaved;
var LBox: TS4YFlexBox; LParent: TRectangle; LText: string;
begin
  LBox := CreateFlexBox(600, 300, 2, LParent);
  try
    LText := SaveAsText(LBox);

    Assert.AreEqual(0, Pos('AutoWidth', LText), 'AutoWidth in the saved state');
    Assert.AreEqual(0, Pos('AutoHeight', LText), 'AutoHeight in the saved state');
  finally
    LParent.Free;
  end;
end;

initialization
  RegisterClasses([TS4YFlexBox, TS4YFlexItem, TRectangle]);
  TDUnitX.RegisterTestFixture(TFlexBoxAutoSizeTests);

end.
