unit Soft4You.FMX.Controls.FlexBox.Item.Tests;

{
  DUnitX tests for the size of TS4YFlexItem: the Align of its content decides
  where the automatic size comes from. With Align = None the content keeps its
  own size and the item takes it; with Align = Top the content follows the item.

  Run with: DUnitX console runner or IDE Test Runner.
}

interface

uses
  DUnitX.TestFramework,
  FMX.Controls,
  FMX.Objects,
  FMX.Types,
  Soft4You.FMX.Controls.FlexBox;

type
  [TestFixture]
  TFlexItemContentAlignTests = class
  private
    // Helper: a flexbox with FitContent in a parent of the given width, with
    // three items of design width 100 and a content of 100 x 30 each
    function CreateFlexBox(AParentWidth: Single; AContentAlign: TAlignLayout;
      out AParent: TRectangle): TS4YFlexBox;

    // Helper: the control at the given index of the flexbox, which is an item
    function ItemAt(const ABox: TS4YFlexBox; AIndex: Integer): TS4YFlexItem;

    // Helper: the content of the item
    function ContentOf(const AItem: TS4YFlexItem): TControl;
  public
    [Test] procedure Test_AlignNone_ItemTakesContentWidth;
    [Test] procedure Test_AlignNone_ItemTakesContentHeight;
    [Test] procedure Test_AlignNone_ItemsDoNotShrinkBelowContent;
    [Test] procedure Test_AlignNone_ExplicitMinWidthLetsItemShrink;
    [Test] procedure Test_AlignTop_ItemsShrinkWithTheFlexBox;
    [Test] procedure Test_AlignTop_ContentFollowsItemWidth;
    [Test] procedure Test_AlignTop_ItemTakesContentHeight;
    [Test] procedure Test_AlignChange_ComputesLayoutAgain;
  end;

implementation

uses
  System.SysUtils,
  System.Types;

const
  TOLERANCE = 0.11;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function TFlexItemContentAlignTests.CreateFlexBox(AParentWidth: Single;
  AContentAlign: TAlignLayout; out AParent: TRectangle): TS4YFlexBox;
var
  LContent: TRectangle;
  LItem: TS4YFlexItem;
begin
  AParent := TRectangle.Create(nil);
  AParent.SetBounds(0, 0, AParentWidth, 200);

  Result := TS4YFlexBox.Create(nil);
  Result.Parent := AParent;
  Result.FitContent := True;

  for var I := 1 to 3 do
  begin
    LItem := TS4YFlexItem.Create(nil);
    LItem.Parent := Result;
    LItem.SetBounds(0, 0, 100, 50);
    LItem.AutoWidth := True;

    LContent := TRectangle.Create(nil);
    LContent.SetBounds(0, 0, 100, 30);
    LContent.Parent := LItem;
    LContent.Align := AContentAlign;
  end;
end;

function TFlexItemContentAlignTests.ItemAt(const ABox: TS4YFlexBox;
  AIndex: Integer): TS4YFlexItem;
begin
  Result := ABox.Controls[AIndex] as TS4YFlexItem;
end;

function TFlexItemContentAlignTests.ContentOf(const AItem: TS4YFlexItem): TControl;
begin
  Result := AItem.Controls[0];
end;

// ===========================================================================
// Content with Align = None
// ===========================================================================

procedure TFlexItemContentAlignTests.Test_AlignNone_ItemTakesContentWidth;

// The content is 100 wide: the item is 100 wide, whatever its design width
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, TAlignLayout.None, LParent);
  try
    ContentOf(ItemAt(LBox, 0)).Width := 70;
    LBox.InvalidateLayout;

    Assert.AreEqual(Single(70), ItemAt(LBox, 0).Width, TOLERANCE, 'item0 width');
    Assert.AreEqual(Single(100), ItemAt(LBox, 1).Width, TOLERANCE, 'item1 width');
  finally
    LParent.Free;
  end;
end;

procedure TFlexItemContentAlignTests.Test_AlignNone_ItemTakesContentHeight;

// The item is 50 high by design; the content is 30 high
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, TAlignLayout.None, LParent);
  try
    Assert.AreEqual(Single(30), ItemAt(LBox, 0).Height, TOLERANCE, 'item height');
  finally
    LParent.Free;
  end;
end;

procedure TFlexItemContentAlignTests.Test_AlignNone_ItemsDoNotShrinkBelowContent;

// 3 * 100 = 300 in a parent 150 wide: the items keep their content width and the
// flexbox grows beyond the parent, as min-width: auto in CSS
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(150, TAlignLayout.None, LParent);
  try
    Assert.AreEqual(Single(300), LBox.Width, TOLERANCE, 'flexbox width');
    Assert.AreEqual(Single(100), ItemAt(LBox, 0).Width, TOLERANCE, 'item0 width');
    Assert.AreEqual(Single(100), ItemAt(LBox, 2).Width, TOLERANCE, 'item2 width');
  finally
    LParent.Free;
  end;
end;

procedure TFlexItemContentAlignTests.Test_AlignNone_ExplicitMinWidthLetsItemShrink;

// MinWidth > 0 replaces the automatic minimum: with 1 the items shrink to
// the parent and the flexbox does not grow
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(150, TAlignLayout.None, LParent);
  try
    for var I := 0 to 2 do
      ItemAt(LBox, I).SizeConstraints.MinWidth := 1;

    LBox.InvalidateLayout;

    Assert.AreEqual(Single(150), LBox.Width, TOLERANCE, 'flexbox width');
    Assert.AreEqual(Single(50), ItemAt(LBox, 0).Width, TOLERANCE, 'item0 width');
  finally
    LParent.Free;
  end;
end;

// ===========================================================================
// Content with Align = Top
// ===========================================================================

procedure TFlexItemContentAlignTests.Test_AlignTop_ItemsShrinkWithTheFlexBox;

// The items have a design width of 100 and no minimum: 3 * 100 shrink to 50
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(150, TAlignLayout.Top, LParent);
  try
    Assert.AreEqual(Single(150), LBox.Width, TOLERANCE, 'flexbox width');
    Assert.AreEqual(Single(50), ItemAt(LBox, 0).Width, TOLERANCE, 'item0 width');
  finally
    LParent.Free;
  end;
end;

procedure TFlexItemContentAlignTests.Test_AlignTop_ContentFollowsItemWidth;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(150, TAlignLayout.Top, LParent);
  try
    Assert.AreEqual(ItemAt(LBox, 0).Width, ContentOf(ItemAt(LBox, 0)).Width, TOLERANCE,
      'content width');
  finally
    LParent.Free;
  end;
end;

procedure TFlexItemContentAlignTests.Test_AlignTop_ItemTakesContentHeight;
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(600, TAlignLayout.Top, LParent);
  try
    Assert.AreEqual(Single(30), ItemAt(LBox, 0).Height, TOLERANCE, 'item height');
  finally
    LParent.Free;
  end;
end;

// ===========================================================================
// Change of Align
// ===========================================================================

procedure TFlexItemContentAlignTests.Test_AlignChange_ComputesLayoutAgain;

// With Align = None the flexbox is 300 wide; once the contents follow their items
// (Align = Top) the items can shrink and the flexbox goes back to the parent
var LBox: TS4YFlexBox; LParent: TRectangle;
begin
  LBox := CreateFlexBox(150, TAlignLayout.None, LParent);
  try
    Assert.AreEqual(Single(300), LBox.Width, TOLERANCE, 'flexbox width with Align = None');

    for var I := 0 to 2 do
      ContentOf(ItemAt(LBox, I)).Align := TAlignLayout.Top;

    Assert.AreEqual(Single(150), LBox.Width, TOLERANCE, 'flexbox width with Align = Top');
  finally
    LParent.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFlexItemContentAlignTests);

end.
