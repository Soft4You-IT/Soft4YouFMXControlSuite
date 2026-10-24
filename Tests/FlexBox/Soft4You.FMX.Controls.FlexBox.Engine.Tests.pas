unit Soft4You.FMX.Controls.FlexBox.Engine.Tests;

{
  DUnitX tests for TFlexEngine.
  Each test verifies a specific behavior of CSS FlexBox,
  with names that reflect the tested property.

  Run with: DUnitX console runner or IDE Test Runner.
}

interface

uses
  DUnitX.TestFramework,
  Soft4You.FMX.Controls.FlexBox.Engine;

type
  [TestFixture]
  TFlexEngineTests = class
  private
    // Helper: creates an item with natural Width/Height, grow=0, shrink=1, basis=auto
    function MakeItem(W, H: Single;
                      Grow: Single = 0; Shrink: Single = 1;
                      Order: Integer = 0): TFlexItemInput;

    // Helper: checks a rect with 0.1px tolerance
    procedure AssertRect(const R: TFlexItemResult;
                         ExpL, ExpT, ExpW, ExpH: Single;
                         const Msg: string = '');

    // Default context: row, nowrap, flex-start, 400x300
    function DefaultCtx(W: Single = 400; H: Single = 300): TFlexContext;

  public
    // -----------------------------------------------------------------------
    // 1. BASICS - row, no-wrap
    // -----------------------------------------------------------------------
    [Test] procedure Test_Row_ThreeItems_FlexStart;
    [Test] procedure Test_Row_ThreeItems_FlexEnd;
    [Test] procedure Test_Row_ThreeItems_Center;
    [Test] procedure Test_Row_SpaceBetween;
    [Test] procedure Test_Row_SpaceAround;
    [Test] procedure Test_Row_SpaceEvenly;

    // -----------------------------------------------------------------------
    // 2. COLUMN
    // -----------------------------------------------------------------------
    [Test] procedure Test_Column_ThreeItems_FlexStart;
    [Test] procedure Test_Column_JustifyCenter;

    // -----------------------------------------------------------------------
    // 3. FLEX-GROW
    // -----------------------------------------------------------------------
    [Test] procedure Test_Grow_SingleItem_FillsSpace;
    [Test] procedure Test_Grow_TwoItems_EqualGrow;
    [Test] procedure Test_Grow_TwoItems_WeightedGrow;

    // -----------------------------------------------------------------------
    // 4. FLEX-SHRINK
    // -----------------------------------------------------------------------
    [Test] procedure Test_Shrink_ItemsOverflow_ShrinkEqually;
    [Test] procedure Test_Shrink_NoShrink_ItemKeepsSize;

    // -----------------------------------------------------------------------
    // 5. FLEX-BASIS
    // -----------------------------------------------------------------------
    [Test] procedure Test_Basis_Pixel_OverridesNaturalWidth;
    [Test] procedure Test_Basis_Percent_HalfContainer;

    // -----------------------------------------------------------------------
    // 6. ALIGN-ITEMS
    // -----------------------------------------------------------------------
    [Test] procedure Test_AlignItems_Stretch;
    [Test] procedure Test_AlignItems_Center;
    [Test] procedure Test_AlignItems_FlexEnd;

    // -----------------------------------------------------------------------
    // 7. ALIGN-SELF
    // -----------------------------------------------------------------------
    [Test] procedure Test_AlignSelf_OverridesAlignItems;

    // -----------------------------------------------------------------------
    // 8. ORDER
    // -----------------------------------------------------------------------
    [Test] procedure Test_Order_ReordersItems;
    [Test] procedure Test_Order_NegativeFirst;

    // -----------------------------------------------------------------------
    // 9. WRAP
    // -----------------------------------------------------------------------
    [Test] procedure Test_Wrap_ItemsBreakToNextLine;
    [Test] procedure Test_WrapReverse_LinesInverted;

    // -----------------------------------------------------------------------
    // 10. GAP
    // -----------------------------------------------------------------------
    [Test] procedure Test_ColumnGap_ThreeItems;
    [Test] procedure Test_RowGap_TwoLines;

    // -----------------------------------------------------------------------
    // 11. ALIGN-CONTENT
    // -----------------------------------------------------------------------
    [Test] procedure Test_AlignContent_SpaceBetween_TwoLines;
    [Test] procedure Test_AlignContent_Center_TwoLines;

    // -----------------------------------------------------------------------
    // 12. REVERSE
    // -----------------------------------------------------------------------
    [Test] procedure Test_RowReverse_ItemsPositionedRightToLeft;
    [Test] procedure Test_ColumnReverse;

    // -----------------------------------------------------------------------
    // 13. AUTO SIZES AND SINGLE LINE
    // -----------------------------------------------------------------------
    [Test] procedure Test_SingleLine_Default_LineIsTallestItem;
    [Test] procedure Test_SingleLine_FillsContainer_Stretch;
    [Test] procedure Test_SingleLine_FillsContainer_Center;
    [Test] procedure Test_SingleLine_Wrap_LineStaysContentSized;
    [Test] procedure Test_HeightExplicit_NotStretched;
    [Test] procedure Test_Column_AutoWidth_FitsAvailable;
    [Test] procedure Test_Column_ExplicitWidth_NotClamped;
    [Test] procedure Test_Column_SingleLine_FillsWidth;
    [Test] procedure Test_Column_SingleLine_AlignSelfStart_KeepsNatural;

    // -----------------------------------------------------------------------
    // 14. MIN / MAX OF THE SIZES
    // -----------------------------------------------------------------------
    [Test] procedure Test_MaxWidth_ClampsBasis;
    [Test] procedure Test_MinWidth_ClampsBasis;
    [Test] procedure Test_MaxWidth_ExplicitWidthStillClamped;
    [Test] procedure Test_Grow_MaxWidth_RedistributesToOthers;
    [Test] procedure Test_Shrink_MinWidth_RedistributesToOthers;
    [Test] procedure Test_Column_Grow_MaxHeight_RedistributesToOthers;
    [Test] procedure Test_Cross_MaxHeight_LimitsStretch;
    [Test] procedure Test_Cross_MinHeight_RaisesSize;
    [Test] procedure Test_Column_Cross_MaxWidth_LimitsStretch;
    [Test] procedure Test_Wrap_UsesClampedSizeToFillLine;

    // -----------------------------------------------------------------------
    // 15. MEASURE (smallest size that does not crop the items)
    // -----------------------------------------------------------------------
    [Test] procedure Test_Measure_NoItems_IsZero;
    [Test] procedure Test_Measure_Row_NoShrink_SumsSizesGapsAndMargins;
    [Test] procedure Test_Measure_Row_ShrinkableItems_NeedNoWidth;
    [Test] procedure Test_Measure_Row_MinWidth_SumsMinimums;
    [Test] procedure Test_Measure_Row_IgnoresAvailableSizeAndJustify;
    [Test] procedure Test_Measure_RowReverse_SameAsRow;
    [Test] procedure Test_Measure_Row_Wrap_WidestItemAndLinesAtAvailableWidth;
    [Test] procedure Test_Measure_Column_NoShrink_SumsHeightsAndGaps;
    [Test] procedure Test_Measure_Column_ShrinkableItems_KeepNaturalHeight;
    [Test] procedure Test_Measure_Column_Wrap_IsIgnored;
    [Test] procedure Test_Measure_Column_AutoWidth_FitsAvailableWidth;
    [Test] procedure Test_Measure_Column_ExplicitWidth_NeedsItsWidth;
  end;

implementation

uses System.Math, System.SysUtils;

const
  TOLERANCE = 0.11;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function TFlexEngineTests.MakeItem(W, H, Grow, Shrink: Single;
  Order: Integer): TFlexItemInput;
begin
  Result := TFlexItemInput.Default;
  Result.NaturalWidth   := W;
  Result.NaturalHeight  := H;
  Result.FlexGrow       := Grow;
  Result.FlexShrink     := Shrink;
  Result.Order          := Order;
  Result.OriginalIndex  := 0; // will be set by Calculate
end;

function TFlexEngineTests.DefaultCtx(W, H: Single): TFlexContext;
begin
  Result := TFlexContext.Default;
  Result.AvailableWidth  := W;
  Result.AvailableHeight := H;
end;

procedure TFlexEngineTests.AssertRect(const R: TFlexItemResult;
  ExpL, ExpT, ExpW, ExpH: Single; const Msg: string);
begin
  Assert.IsTrue(Abs(R.Left   - ExpL) <= TOLERANCE, Msg + Format(' Left exp=%.1f got=%.1f',   [ExpL, R.Left]));
  Assert.IsTrue(Abs(R.Top    - ExpT) <= TOLERANCE, Msg + Format(' Top exp=%.1f got=%.1f',    [ExpT, R.Top]));
  Assert.IsTrue(Abs(R.Width  - ExpW) <= TOLERANCE, Msg + Format(' Width exp=%.1f got=%.1f',  [ExpW, R.Width]));
  Assert.IsTrue(Abs(R.Height - ExpH) <= TOLERANCE, Msg + Format(' Height exp=%.1f got=%.1f', [ExpH, R.Height]));
end;

// ===========================================================================
// 1. BASICS
// ===========================================================================

procedure TFlexEngineTests.Test_Row_ThreeItems_FlexStart;

// flex-direction: row; justify-content: flex-start (default)
// Container: 300px wide. Items: 50, 80, 60px wide.
// Expected: 0, 50, 130
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.Items := [MakeItem(50,40), MakeItem(80,40), MakeItem(60,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 50, 40, 'item0');
  AssertRect(R[1],  50, 0, 80, 40, 'item1');
  AssertRect(R[2], 130, 0, 60, 40, 'item2');
end;

procedure TFlexEngineTests.Test_Row_ThreeItems_FlexEnd;

// flex-end: items at the right
// Container 300, items 50+80+60=190, free=110 -> start at 110
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.JustifyContent := jcFlexEnd;
  Ctx.Items := [MakeItem(50,40), MakeItem(80,40), MakeItem(60,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0], 110, 0, 50, 40, 'item0');
  AssertRect(R[1], 160, 0, 80, 40, 'item1');
  AssertRect(R[2], 240, 0, 60, 40, 'item2');
end;

procedure TFlexEngineTests.Test_Row_ThreeItems_Center;

// Center: free=110, spaceBefore=55
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.JustifyContent := jcCenter;
  Ctx.Items := [MakeItem(50,40), MakeItem(80,40), MakeItem(60,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],  55, 0, 50, 40, 'item0');
  AssertRect(R[1], 105, 0, 80, 40, 'item1');
  AssertRect(R[2], 185, 0, 60, 40, 'item2');
end;

procedure TFlexEngineTests.Test_Row_SpaceBetween;

// Container 300, items 50+80+60=190, free=110, spacePer=55
// Positions: 0, 105, 240
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.JustifyContent := jcSpaceBetween;
  Ctx.Items := [MakeItem(50,40), MakeItem(80,40), MakeItem(60,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 50, 40, 'item0');
  AssertRect(R[1], 105, 0, 80, 40, 'item1');
  AssertRect(R[2], 240, 0, 60, 40, 'item2');
end;

procedure TFlexEngineTests.Test_Row_SpaceAround;

// free=110, spacePer=110/3~36.67, spaceBefore=18.33
// Positions: 18.33, 105, 221.67
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.JustifyContent := jcSpaceAround;
  Ctx.Items := [MakeItem(50,40), MakeItem(80,40), MakeItem(60,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],  18.3, 0, 50, 40, 'item0');
  AssertRect(R[1], 105,   0, 80, 40, 'item1');
  AssertRect(R[2], 221.7, 0, 60, 40, 'item2');
end;

procedure TFlexEngineTests.Test_Row_SpaceEvenly;

// free=110, spacePer=110/4=27.5
// Positions: 27.5, 27.5+50+27.5=105, 105+80+27.5=212.5
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.JustifyContent := jcSpaceEvenly;
  Ctx.Items := [MakeItem(50,40), MakeItem(80,40), MakeItem(60,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],  27.5, 0, 50, 40, 'item0');
  AssertRect(R[1], 105.0, 0, 80, 40, 'item1');
  AssertRect(R[2], 212.5, 0, 60, 40, 'item2');
end;

// ===========================================================================
// 2. COLUMN
// ===========================================================================

procedure TFlexEngineTests.Test_Column_ThreeItems_FlexStart;
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(100, 300);
  Ctx.Direction := fdColumn;
  Ctx.Items := [MakeItem(60,50), MakeItem(60,80), MakeItem(60,60)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0], 0,   0, 60, 50, 'item0');
  AssertRect(R[1], 0,  50, 60, 80, 'item1');
  AssertRect(R[2], 0, 130, 60, 60, 'item2');
end;

procedure TFlexEngineTests.Test_Column_JustifyCenter;

// Container H=300, items H=50+80+60=190, free=110, spaceBefore=55
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(100, 300);
  Ctx.Direction      := fdColumn;
  Ctx.JustifyContent := jcCenter;
  Ctx.Items := [MakeItem(60,50), MakeItem(60,80), MakeItem(60,60)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0], 0,  55, 60, 50, 'item0');
  AssertRect(R[1], 0, 105, 60, 80, 'item1');
  AssertRect(R[2], 0, 185, 60, 60, 'item2');
end;

// ===========================================================================
// 3. FLEX-GROW
// ===========================================================================

procedure TFlexEngineTests.Test_Grow_SingleItem_FillsSpace;

// 1 item 50px wide, grow=1, container=300 -> item should be 300
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.Items := [MakeItem(50, 40, {Grow=}1)];
  Ctx.Items[0].OriginalIndex := 0;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0], 0, 0, 300, 40, 'grow1');
end;

procedure TFlexEngineTests.Test_Grow_TwoItems_EqualGrow;

// 2 items 50px, grow=1 each. Free=200, each gets +100 -> 150
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.Items := [MakeItem(50,40,1), MakeItem(50,40,1)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 150, 40, 'item0');
  AssertRect(R[1], 150, 0, 150, 40, 'item1');
end;

procedure TFlexEngineTests.Test_Grow_TwoItems_WeightedGrow;

// Item0 grow=1, Item1 grow=2. Free=300-60-60=180. Item0 gets 60, Item1 gets 120.
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.Items := [MakeItem(60,40,1), MakeItem(60,40,2)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 120, 40, 'item0');  // 60+60
  AssertRect(R[1], 120, 0, 180, 40, 'item1');  // 60+120
end;

// ===========================================================================
// 4. FLEX-SHRINK
// ===========================================================================

procedure TFlexEngineTests.Test_Shrink_ItemsOverflow_ShrinkEqually;

// Container=200. Items: 150+150=300. Overflow=100.
// Both shrink=1 (default), factor=150 each -> each shrinks by 50 -> 100
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(200, 100);
  Ctx.Items := [MakeItem(150,40,0,1), MakeItem(150,40,0,1)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 100, 40, 'item0');
  AssertRect(R[1], 100, 0, 100, 40, 'item1');
end;

procedure TFlexEngineTests.Test_Shrink_NoShrink_ItemKeepsSize;

// Item0 shrink=0 -> keeps 150. Item1 shrink=1 -> absorbs all overflow -> 50
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(200, 100);
  Ctx.Items := [MakeItem(150,40,0,0), MakeItem(150,40,0,1)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Width - 150) <= TOLERANCE, 'item0 no-shrink');
  Assert.IsTrue(R[1].Width < 150, 'item1 shrunk');
end;

// ===========================================================================
// 5. FLEX-BASIS
// ===========================================================================

procedure TFlexEngineTests.Test_Basis_Pixel_OverridesNaturalWidth;

// NaturalWidth=50, FlexBasis=120px -> item should be 120
var Ctx: TFlexContext; Item: TFlexItemInput; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Item := MakeItem(50, 40);
  Item.FlexBasis     := 120;
  Item.FlexBasisUnit := fbuPixel;
  Item.OriginalIndex := 0;
  Ctx.Items := [Item];

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Width - 120) <= TOLERANCE, 'basis pixel');
end;

procedure TFlexEngineTests.Test_Basis_Percent_HalfContainer;

// Container=400, FlexBasis=50% -> item should be 200
var Ctx: TFlexContext; Item: TFlexItemInput; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(400, 100);
  Item := MakeItem(50, 40);
  Item.FlexBasis     := 50;
  Item.FlexBasisUnit := fbuPercent;
  Item.OriginalIndex := 0;
  Ctx.Items := [Item];

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Width - 200) <= TOLERANCE, 'basis 50%');
end;

// ===========================================================================
// 6. ALIGN-ITEMS
// ===========================================================================

procedure TFlexEngineTests.Test_AlignItems_Stretch;

// Items with different heights, align-items=stretch -> all stretch to line height
// Line cross = max natural = 80. All items should be 80 tall.
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.AlignItems := aiStretch;
  Ctx.Items := [MakeItem(80,40), MakeItem(80,80), MakeItem(80,30)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Height - 80) <= TOLERANCE, 'item0 stretch');
  Assert.IsTrue(Abs(R[1].Height - 80) <= TOLERANCE, 'item1 stretch');
  Assert.IsTrue(Abs(R[2].Height - 80) <= TOLERANCE, 'item2 stretch');
end;

procedure TFlexEngineTests.Test_AlignItems_Center;

// Line height=80 (max). Item0 h=40 -> top=(80-40)/2=20
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.AlignItems := aiCenter;
  Ctx.Items := [MakeItem(80,40), MakeItem(80,80)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Top - 20) <= TOLERANCE, 'item0 center top');
  Assert.IsTrue(Abs(R[1].Top -  0) <= TOLERANCE, 'item1 center top');
end;

procedure TFlexEngineTests.Test_AlignItems_FlexEnd;

// Line height=80. Item0 h=40 -> top=40. Item1 h=80 -> top=0.
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.AlignItems := aiFlexEnd;
  Ctx.Items := [MakeItem(80,40), MakeItem(80,80)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Top - 40) <= TOLERANCE, 'item0 flex-end top');
  Assert.IsTrue(Abs(R[1].Top -  0) <= TOLERANCE, 'item1 flex-end top');
end;

// ===========================================================================
// 7. ALIGN-SELF
// ===========================================================================

procedure TFlexEngineTests.Test_AlignSelf_OverridesAlignItems;

// Container align-items=flex-start. Item1 align-self=flex-end.
// Line height=80. Item1 h=40 -> top should be 40.
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.AlignItems := aiFlexStart;
  Ctx.Items := [MakeItem(80,80), MakeItem(80,40)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[1].OriginalIndex := 1;
  Ctx.Items[1].AlignSelf := asFlexEnd;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Top -  0) <= TOLERANCE, 'item0 flex-start');
  Assert.IsTrue(Abs(R[1].Top - 40) <= TOLERANCE, 'item1 align-self flex-end');
end;

// ===========================================================================
// 8. ORDER
// ===========================================================================

procedure TFlexEngineTests.Test_Order_ReordersItems;

// Item0 order=2, Item1 order=1, Item2 order=0
// Visual order: Item2, Item1, Item0 -> Left positions: 0, 50, 130
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.Items := [MakeItem(80,40,0,1,2),   // OriginalIndex 0, order=2
                MakeItem(50,40,0,1,1),   // OriginalIndex 1, order=1
                MakeItem(50,40,0,1,0)];  // OriginalIndex 2, order=0

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);

  // Item2 (order=0) must be the first visually -> Left=0
  Assert.IsTrue(Abs(R[2].Left -   0) <= TOLERANCE, 'item2 first (order=0)');
  Assert.IsTrue(Abs(R[1].Left -  50) <= TOLERANCE, 'item1 second (order=1)');
  Assert.IsTrue(Abs(R[0].Left - 100) <= TOLERANCE, 'item0 third (order=2)');
end;

procedure TFlexEngineTests.Test_Order_NegativeFirst;

// Item0 order=0, Item1 order=-1 -> Item1 first
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.Items := [MakeItem(60,40,0,1, 0),
                MakeItem(60,40,0,1,-1)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[1].Left -  0) <= TOLERANCE, 'item1 first (order=-1)');
  Assert.IsTrue(Abs(R[0].Left - 60) <= TOLERANCE, 'item0 second (order=0)');
end;

// ===========================================================================
// 9. WRAP
// ===========================================================================

procedure TFlexEngineTests.Test_Wrap_ItemsBreakToNextLine;

// Container=200. Items: 120, 120 -> wrap -> 2 lines.
// Line 0: item0 at (0,0). Line 1: item1 at (0, lineHeight)
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(200, 300);
  Ctx.Wrap := fwWrap;
  Ctx.AlignItems := aiFlexStart; // no stretch
  Ctx.Items := [MakeItem(120,50), MakeItem(120,60)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Left -   0) <= TOLERANCE, 'item0 left');
  Assert.IsTrue(Abs(R[0].Top  -   0) <= TOLERANCE, 'item0 top');
  Assert.IsTrue(Abs(R[1].Left -   0) <= TOLERANCE, 'item1 left (new line)');
  Assert.IsTrue(R[1].Top > 0, 'item1 on second line');
end;

procedure TFlexEngineTests.Test_WrapReverse_LinesInverted;

// Same as above but wrap-reverse: second line should be above first
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(200, 300);
  Ctx.Wrap := fwWrapReverse;
  Ctx.AlignItems := aiFlexStart;
  Ctx.Items := [MakeItem(120,50), MakeItem(120,60)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);

  // With wrap-reverse the order of the lines is reversed
  Assert.IsTrue(R[0].Top > R[1].Top, 'wrap-reverse: item0 below item1');
end;

// ===========================================================================
// 10. GAP
// ===========================================================================

procedure TFlexEngineTests.Test_ColumnGap_ThreeItems;

// Container=300, items 50px each, gap=20 -> used=50+20+50+20+50=190, free=110
// Positions (flex-start): 0, 70, 140
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.ColumnGap := 20;
  Ctx.Items := [MakeItem(50,40), MakeItem(50,40), MakeItem(50,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 50, 40, 'item0');
  AssertRect(R[1],  70, 0, 50, 40, 'item1');
  AssertRect(R[2], 140, 0, 50, 40, 'item2');
end;

procedure TFlexEngineTests.Test_RowGap_TwoLines;

// Container=200, items 120px each, wrap, rowGap=15
// Line0 at top=0, Line1 at top=lineHeight+15
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(200, 300);
  Ctx.Wrap   := fwWrap;
  Ctx.RowGap := 15;
  Ctx.AlignItems := aiFlexStart;
  Ctx.Items := [MakeItem(120,50), MakeItem(120,60)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[1].Top - (50 + 15)) <= TOLERANCE, 'row-gap between lines');
end;

// ===========================================================================
// 11. ALIGN-CONTENT
// ===========================================================================

procedure TFlexEngineTests.Test_AlignContent_SpaceBetween_TwoLines;

// Container H=300. Two lines, crossSizes=50+60=110. Free=190.
// space-between: line0 at 0, line1 at 240.
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(200, 300);
  Ctx.Wrap         := fwWrap;
  Ctx.AlignContent := acSpaceBetween;
  Ctx.AlignItems   := aiFlexStart;
  Ctx.Items := [MakeItem(120,50), MakeItem(120,60)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Top -   0) <= TOLERANCE, 'line0 at top');
  Assert.IsTrue(Abs(R[1].Top - 240) <= TOLERANCE, 'line1 at bottom');
end;

procedure TFlexEngineTests.Test_AlignContent_Center_TwoLines;

// Container H=300. Lines crossSizes=50+60=110. Free=190. spaceBefore=95.
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(200, 300);
  Ctx.Wrap         := fwWrap;
  Ctx.AlignContent := acCenter;
  Ctx.AlignItems   := aiFlexStart;
  Ctx.Items := [MakeItem(120,50), MakeItem(120,60)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Top -  95) <= TOLERANCE, 'line0 centered');
  Assert.IsTrue(Abs(R[1].Top - 145) <= TOLERANCE, 'line1 centered');
end;

// ===========================================================================
// 12. REVERSE
// ===========================================================================

procedure TFlexEngineTests.Test_RowReverse_ItemsPositionedRightToLeft;

// Container=300, items 50+80+60=190.
// row-reverse: item0 rightmost at left=240, item2 leftmost at left=0
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 100);
  Ctx.Direction := fdRowReverse;
  Ctx.Items := [MakeItem(50,40), MakeItem(80,40), MakeItem(60,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);

  // In row-reverse: item0 visually on the right -> higher Left
  Assert.IsTrue(R[0].Left > R[1].Left, 'item0 more right than item1');
  Assert.IsTrue(R[1].Left > R[2].Left, 'item1 more right than item2');
end;

procedure TFlexEngineTests.Test_ColumnReverse;

// Container H=300, items 50+80+60=190.
// column-reverse: item0 at bottom, item2 at top
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(100, 300);
  Ctx.Direction := fdColumnReverse;
  Ctx.Items := [MakeItem(60,50), MakeItem(60,80), MakeItem(60,60)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);

  // column-reverse: item0 visually at the bottom -> higher Top
  Assert.IsTrue(R[0].Top > R[1].Top, 'item0 lower than item1');
  Assert.IsTrue(R[1].Top > R[2].Top, 'item1 lower than item2');
end;

// ===========================================================================
// 13. AUTO SIZES AND SINGLE LINE
// ===========================================================================

procedure TFlexEngineTests.Test_SingleLine_Default_LineIsTallestItem;

// Without SingleLineFillsContainer the line is as tall as the tallest (80)
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.Items := [MakeItem(80,40), MakeItem(80,80)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Height - 80) <= TOLERANCE, 'item0 height');
  Assert.IsTrue(Abs(R[1].Height - 80) <= TOLERANCE, 'item1 height');
end;

procedure TFlexEngineTests.Test_SingleLine_FillsContainer_Stretch;

// With the option, the line takes the whole height of the container (200)
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.SingleLineFillsContainer := True;
  Ctx.Items := [MakeItem(80,40), MakeItem(80,80)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Height - 200) <= TOLERANCE, 'item0 height');
  Assert.IsTrue(Abs(R[1].Height - 200) <= TOLERANCE, 'item1 height');
end;

procedure TFlexEngineTests.Test_SingleLine_FillsContainer_Center;

// Line = 200: item0 h=40 -> top=80, item1 h=80 -> top=60
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.SingleLineFillsContainer := True;
  Ctx.AlignItems := aiCenter;
  Ctx.Items := [MakeItem(80,40), MakeItem(80,80)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Top - 80) <= TOLERANCE, 'item0 center top');
  Assert.IsTrue(Abs(R[1].Top - 60) <= TOLERANCE, 'item1 center top');
end;

procedure TFlexEngineTests.Test_SingleLine_Wrap_LineStaysContentSized;

// With fwWrap the line stays as tall as the tallest (80), even with the option
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.SingleLineFillsContainer := True;
  Ctx.Wrap := fwWrap;
  Ctx.Items := [MakeItem(80,40), MakeItem(80,80)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Height - 80) <= TOLERANCE, 'item0 height');
  Assert.IsTrue(Abs(R[1].Height - 80) <= TOLERANCE, 'item1 height');
end;

procedure TFlexEngineTests.Test_HeightExplicit_NotStretched;

// Explicit height: the item does not stretch (item0 stays 40), the auto one does
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.Items := [MakeItem(80,40), MakeItem(80,80)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  Ctx.Items[0].HeightAuto := False;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Height - 40) <= TOLERANCE, 'item0 explicit height');
  Assert.IsTrue(Abs(R[1].Height - 80) <= TOLERANCE, 'item1 auto height');
end;

procedure TFlexEngineTests.Test_Column_AutoWidth_FitsAvailable;

// Column, container 100 wide, auto item with natural width 150 -> 100
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(100, 300);
  Ctx.Direction := fdColumn;
  Ctx.Items := [MakeItem(150,50)];
  Ctx.Items[0].OriginalIndex := 0;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Width - 100) <= TOLERANCE, 'fit-content');
end;

procedure TFlexEngineTests.Test_Column_ExplicitWidth_NotClamped;

// Explicit width: it stays 150 even if the container is 100
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(100, 300);
  Ctx.Direction := fdColumn;
  Ctx.Items := [MakeItem(150,50)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[0].WidthAuto := False;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Width - 150) <= TOLERANCE, 'explicit width');
end;

procedure TFlexEngineTests.Test_Column_SingleLine_FillsWidth;

// Column, single line with the option: natural item 60 stretches to 100
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(100, 300);
  Ctx.Direction := fdColumn;
  Ctx.SingleLineFillsContainer := True;
  Ctx.Items := [MakeItem(60,50)];
  Ctx.Items[0].OriginalIndex := 0;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Width - 100) <= TOLERANCE, 'stretch to container width');
end;

procedure TFlexEngineTests.Test_Column_SingleLine_AlignSelfStart_KeepsNatural;
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(100, 300);
  Ctx.Direction := fdColumn;
  Ctx.SingleLineFillsContainer := True;
  Ctx.Items := [MakeItem(60,50)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[0].AlignSelf := asFlexStart;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Width - 60) <= TOLERANCE, 'natural width');
  Assert.IsTrue(Abs(R[0].Left - 0) <= TOLERANCE, 'left');
end;

procedure TFlexEngineTests.Test_MaxWidth_ClampsBasis;

// Basis 300 with MaxWidth 200: the size is 200
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(400, 100);
  Ctx.Items := [MakeItem(300,40)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[0].MaxWidth := 200;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0], 0, 0, 200, 40, 'clamped to max');
end;

procedure TFlexEngineTests.Test_MinWidth_ClampsBasis;

// Basis 50 with MinWidth 120: the size is 120
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(400, 100);
  Ctx.Items := [MakeItem(50,40)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[0].MinWidth := 120;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0], 0, 0, 120, 40, 'raised to min');
end;

procedure TFlexEngineTests.Test_MaxWidth_ExplicitWidthStillClamped;

// As in CSS, max-width beats an explicit width
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(400, 100);
  Ctx.Items := [MakeItem(300,40)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[0].WidthAuto := False;
  Ctx.Items[0].MaxWidth := 200;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0], 0, 0, 200, 40, 'explicit width clamped');
end;

procedure TFlexEngineTests.Test_Grow_MaxWidth_RedistributesToOthers;

// 2 items of 100, grow=1, container 400: without limits 200 + 200. The first is limited
// to 150: the space it cannot take goes to the second (250).
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(400, 100);
  Ctx.Items := [MakeItem(100,40,1), MakeItem(100,40,1)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  Ctx.Items[0].MaxWidth := 150;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 150, 40, 'item0 at max');
  AssertRect(R[1], 150, 0, 250, 40, 'item1 takes the rest');
end;

procedure TFlexEngineTests.Test_Shrink_MinWidth_RedistributesToOthers;

// 2 items of 300, shrink=1, container 400: without limits 200 + 200. The first does not
// go below 250: the second gives up the rest (150).
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(400, 100);
  Ctx.Items := [MakeItem(300,40), MakeItem(300,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  Ctx.Items[0].MinWidth := 250;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 250, 40, 'item0 at min');
  AssertRect(R[1], 250, 0, 150, 40, 'item1 shrinks more');
end;

procedure TFlexEngineTests.Test_Column_Grow_MaxHeight_RedistributesToOthers;

// Column 400 tall, 2 items 100 tall with grow=1: the first is limited to 150
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(100, 400);
  Ctx.Direction := fdColumn;
  Ctx.Items := [MakeItem(50,100,1), MakeItem(50,100,1)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].OriginalIndex := I;

  Ctx.Items[0].MaxHeight := 150;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Height - 150) <= TOLERANCE, 'item0 height');
  Assert.IsTrue(Abs(R[1].Height - 250) <= TOLERANCE, 'item1 height');
  Assert.IsTrue(Abs(R[1].Top - 150) <= TOLERANCE, 'item1 top');
end;

procedure TFlexEngineTests.Test_Cross_MaxHeight_LimitsStretch;

// Row 300 tall, auto height, stretch: with MaxHeight 100 the item does not go beyond
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(400, 300);
  Ctx.SingleLineFillsContainer := True;
  Ctx.Items := [MakeItem(100,40)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[0].MaxHeight := 100;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Height - 100) <= TOLERANCE, 'height');
end;

procedure TFlexEngineTests.Test_Cross_MinHeight_RaisesSize;

// Natural height 50 aligned at the top, MinHeight 80: the item is 80 tall
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(400, 300);
  Ctx.AlignItems := aiFlexStart;
  Ctx.Items := [MakeItem(100,50)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[0].MinHeight := 80;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Height - 80) <= TOLERANCE, 'height');
end;

procedure TFlexEngineTests.Test_Column_Cross_MaxWidth_LimitsStretch;

// Column 200 wide, auto width (stretch): with MaxWidth 120 the item is 120 wide
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(200, 300);
  Ctx.Direction := fdColumn;
  Ctx.SingleLineFillsContainer := True;
  Ctx.Items := [MakeItem(60,50)];
  Ctx.Items[0].OriginalIndex := 0;
  Ctx.Items[0].MaxWidth := 120;

  R := TFlexEngine.Calculate(Ctx);
  Assert.IsTrue(Abs(R[0].Width - 120) <= TOLERANCE, 'width');
end;

procedure TFlexEngineTests.Test_Wrap_UsesClampedSizeToFillLine;

// Row with wrap 300 wide: 2 items of 200 with MaxWidth 100 stay on the same line
var Ctx: TFlexContext; R: TArray<TFlexItemResult>;
begin
  Ctx := DefaultCtx(300, 200);
  Ctx.Wrap := fwWrap;
  Ctx.Items := [MakeItem(200,40), MakeItem(200,40)];

  for var I := 0 to High(Ctx.Items) do
  begin
    Ctx.Items[I].OriginalIndex := I;
    Ctx.Items[I].MaxWidth := 100;
  end;

  R := TFlexEngine.Calculate(Ctx);
  AssertRect(R[0],   0, 0, 100, 40, 'item0');
  AssertRect(R[1], 100, 0, 100, 40, 'item1 same line');
end;

// ===========================================================================
// 15. MEASURE
// ===========================================================================

procedure TFlexEngineTests.Test_Measure_NoItems_IsZero;
var LSize: TFlexContentSize;
begin
  LSize := TFlexEngine.Measure(DefaultCtx(400, 300));
  Assert.AreEqual(Single(0), LSize.Width, TOLERANCE, 'width');
  Assert.AreEqual(Single(0), LSize.Height, TOLERANCE, 'height');
end;

procedure TFlexEngineTests.Test_Measure_Row_NoShrink_SumsSizesGapsAndMargins;

// Three items of 100 x 40 that do not shrink, ColumnGap 10, right margin 5 on the last
// Width = 300 + 2 * 10 + 5 = 325; height = 40
var Ctx: TFlexContext; LSize: TFlexContentSize;
begin
  Ctx := DefaultCtx(50, 20);
  Ctx.ColumnGap := 10;
  Ctx.Items := [MakeItem(100,40,0,0), MakeItem(100,40,0,0), MakeItem(100,40,0,0)];
  Ctx.Items[2].MarginRight := 5;

  LSize := TFlexEngine.Measure(Ctx);
  Assert.AreEqual(Single(325), LSize.Width, TOLERANCE, 'width');
  Assert.AreEqual(Single(40), LSize.Height, TOLERANCE, 'height');
end;

procedure TFlexEngineTests.Test_Measure_Row_ShrinkableItems_NeedNoWidth;

// Items that shrink without a minimum never crop: no width is needed
var Ctx: TFlexContext; LSize: TFlexContentSize;
begin
  Ctx := DefaultCtx(50, 20);
  Ctx.Items := [MakeItem(100,40), MakeItem(100,40), MakeItem(100,40)];

  LSize := TFlexEngine.Measure(Ctx);
  Assert.AreEqual(Single(0), LSize.Width, TOLERANCE, 'width');
  Assert.AreEqual(Single(40), LSize.Height, TOLERANCE, 'height');
end;

procedure TFlexEngineTests.Test_Measure_Row_MinWidth_SumsMinimums;

// Three items that shrink down to MinWidth 80, ColumnGap 10: 3 * 80 + 2 * 10 = 260
var Ctx: TFlexContext; LSize: TFlexContentSize;
begin
  Ctx := DefaultCtx(50, 20);
  Ctx.ColumnGap := 10;
  Ctx.Items := [MakeItem(100,40), MakeItem(100,40), MakeItem(100,40)];

  for var I := 0 to High(Ctx.Items) do
    Ctx.Items[I].MinWidth := 80;

  LSize := TFlexEngine.Measure(Ctx);
  Assert.AreEqual(Single(260), LSize.Width, TOLERANCE, 'width');
end;

procedure TFlexEngineTests.Test_Measure_Row_IgnoresAvailableSizeAndJustify;

// The result does not grow with the available size and does not depend on how
// the free space is distributed
var Ctx: TFlexContext; LSmall, LLarge: TFlexContentSize;
begin
  Ctx := DefaultCtx(100, 100);
  Ctx.Items := [MakeItem(100,40,1,0), MakeItem(100,40,1,0)];
  LSmall := TFlexEngine.Measure(Ctx);

  Ctx := DefaultCtx(1000, 800);
  Ctx.JustifyContent := jcSpaceBetween;
  Ctx.AlignContent := acStretch;
  Ctx.Items := [MakeItem(100,40,1,0), MakeItem(100,40,1,0)];
  LLarge := TFlexEngine.Measure(Ctx);

  Assert.AreEqual(Single(200), LSmall.Width, TOLERANCE, 'small width');
  Assert.AreEqual(LSmall.Width, LLarge.Width, TOLERANCE, 'width');
  Assert.AreEqual(LSmall.Height, LLarge.Height, TOLERANCE, 'height');
end;

procedure TFlexEngineTests.Test_Measure_RowReverse_SameAsRow;
var Ctx: TFlexContext; LRow, LReverse: TFlexContentSize;
begin
  Ctx := DefaultCtx(50, 20);
  Ctx.Items := [MakeItem(100,40,0,0), MakeItem(60,30,0,0)];
  LRow := TFlexEngine.Measure(Ctx);

  Ctx.Direction := fdRowReverse;
  LReverse := TFlexEngine.Measure(Ctx);

  Assert.AreEqual(Single(160), LReverse.Width, TOLERANCE, 'width');
  Assert.AreEqual(LRow.Width, LReverse.Width, TOLERANCE, 'same width');
  Assert.AreEqual(LRow.Height, LReverse.Height, TOLERANCE, 'same height');
end;

procedure TFlexEngineTests.Test_Measure_Row_Wrap_WidestItemAndLinesAtAvailableWidth;

// Wrap, items of 100, 150 and 80 that do not shrink, height 40, RowGap 5
// Width = the widest item (150). Height depends on the width that the container has:
//   available 400: one line -> 40
//   available 200: 100 | 150 | 80 on three lines -> 3 * 40 + 2 * 5 = 130
var Ctx: TFlexContext; LWide, LNarrow: TFlexContentSize;
begin
  Ctx := DefaultCtx(400, 100);
  Ctx.Wrap := fwWrap;
  Ctx.RowGap := 5;
  Ctx.Items := [MakeItem(100,40,0,0), MakeItem(150,40,0,0), MakeItem(80,40,0,0)];
  LWide := TFlexEngine.Measure(Ctx);

  Ctx.AvailableWidth := 200;
  LNarrow := TFlexEngine.Measure(Ctx);

  Assert.AreEqual(Single(150), LWide.Width, TOLERANCE, 'wide: width');
  Assert.AreEqual(Single(40), LWide.Height, TOLERANCE, 'wide: height');
  Assert.AreEqual(Single(150), LNarrow.Width, TOLERANCE, 'narrow: width');
  Assert.AreEqual(Single(130), LNarrow.Height, TOLERANCE, 'narrow: height');
end;

procedure TFlexEngineTests.Test_Measure_Column_NoShrink_SumsHeightsAndGaps;

// Column, three items of 50 x 30 that do not shrink, RowGap and ColumnGap 10
// Height = 3 * 30 + 2 * 10 = 110; width = 50
var Ctx: TFlexContext; LSize: TFlexContentSize;
begin
  Ctx := DefaultCtx(100, 20);
  Ctx.Direction := fdColumn;
  Ctx.ColumnGap := 10;
  Ctx.RowGap := 10;
  Ctx.Items := [MakeItem(50,30,0,0), MakeItem(50,30,0,0), MakeItem(50,30,0,0)];

  LSize := TFlexEngine.Measure(Ctx);
  Assert.AreEqual(Single(110), LSize.Height, TOLERANCE, 'height');
  Assert.AreEqual(Single(50), LSize.Width, TOLERANCE, 'width');
end;

procedure TFlexEngineTests.Test_Measure_Column_ShrinkableItems_KeepNaturalHeight;

// The height of a column is not limited: the items do not shrink to the height
// that the context happens to have
var Ctx: TFlexContext; LSize: TFlexContentSize;
begin
  Ctx := DefaultCtx(100, 20);
  Ctx.Direction := fdColumn;
  Ctx.Items := [MakeItem(50,30), MakeItem(50,30), MakeItem(50,30)];

  LSize := TFlexEngine.Measure(Ctx);
  Assert.AreEqual(Single(90), LSize.Height, TOLERANCE, 'height');
end;

procedure TFlexEngineTests.Test_Measure_Column_Wrap_IsIgnored;

// With a height that follows the content there is nothing to wrap against
var Ctx: TFlexContext; LSize: TFlexContentSize;
begin
  Ctx := DefaultCtx(200, 50);
  Ctx.Direction := fdColumn;
  Ctx.Wrap := fwWrap;
  Ctx.Items := [MakeItem(50,30), MakeItem(50,30), MakeItem(50,30)];

  LSize := TFlexEngine.Measure(Ctx);
  Assert.AreEqual(Single(90), LSize.Height, TOLERANCE, 'height');
  Assert.AreEqual(Single(50), LSize.Width, TOLERANCE, 'width');
end;

procedure TFlexEngineTests.Test_Measure_Column_AutoWidth_FitsAvailableWidth;

// An automatic width in a column fits the available width, so it never needs
// more room than that
var Ctx: TFlexContext; LSize: TFlexContentSize;
begin
  Ctx := DefaultCtx(80, 400);
  Ctx.Direction := fdColumn;
  Ctx.Items := [MakeItem(120,30), MakeItem(60,30)];

  LSize := TFlexEngine.Measure(Ctx);
  Assert.AreEqual(Single(80), LSize.Width, TOLERANCE, 'width');
end;

procedure TFlexEngineTests.Test_Measure_Column_ExplicitWidth_NeedsItsWidth;

// An explicit width is not reduced: the container needs room for it
var Ctx: TFlexContext; LSize: TFlexContentSize;
begin
  Ctx := DefaultCtx(80, 400);
  Ctx.Direction := fdColumn;
  Ctx.Items := [MakeItem(120,30), MakeItem(60,30)];
  Ctx.Items[0].WidthAuto := False;

  LSize := TFlexEngine.Measure(Ctx);
  Assert.AreEqual(Single(120), LSize.Width, TOLERANCE, 'width');
end;

initialization
  TDUnitX.RegisterTestFixture(TFlexEngineTests);

end.
