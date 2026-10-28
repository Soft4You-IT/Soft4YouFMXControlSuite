unit Soft4You.FMX.Controls.FlexBox.Engine;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YFlexBox - CSS FlexBox layout container
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{
  TFlexEngine - Implementation of the CSS FlexBox algorithm (W3C Level 1)
  for FireMonkey (Delphi).

  Spec reference: https://www.w3.org/TR/css-flexbox-1/#layout-algorithm

  This unit is STATELESS and PLATFORM-AGNOSTIC:
  - It does not depend on FMX.Controls or on any visual framework
  - It works exclusively on TFlexContext (input) and TFlexItemResult (output)
  - It can be tested with DUnit/DUnitX without a UI

  Flow of the algorithm (step numbers according to the W3C spec):
    Step 1  - Collecting and sorting the items (order)
    Step 2  - Hypothetical size computation (flex-basis + min/max clamp)
    Step 3  - Determining the lines (nowrap / wrap)
    Step 4  - grow/shrink distribution per line
    Step 5  - Cross size of the items (align-self)
    Step 6  - Cross size of the lines (align-content)
    Step 7  - Main-axis positioning (justify-content + gap)
    Step 8  - Cross-axis positioning (align-items / align-self)
    Step 9  - Writing the results (TFlexItemResult)
}

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  System.Math;

// ---------------------------------------------------------------------------
// Enums - 1:1 mirror of the CSS FlexBox properties
// ---------------------------------------------------------------------------

type
  /// <summary>
  /// Direction of the main axis of the container (CSS flex-direction).
  /// </summary>
  /// <remarks>
  /// fdRow: horizontal, from left to right (the default).
  /// fdRowReverse: horizontal, from right to left.
  /// fdColumn: vertical, from top to bottom.
  /// fdColumnReverse: vertical, from bottom to top.
  /// </remarks>
  TFlexDirection = (
    fdRow,            // default  -> main axis = horizontal, left->right
    fdRowReverse,     //          -> main axis = horizontal, right->left
    fdColumn,         //          -> main axis = vertical,   top->bottom
    fdColumnReverse   //          -> main axis = vertical,   bottom->top
  );

  /// <summary>
  /// Whether the items wrap onto more lines (CSS flex-wrap).
  /// </summary>
  /// <remarks>
  /// fwNoWrap: all the items stay on one line (the default).
  /// fwWrap: the items wrap onto more lines, downwards or rightwards.
  /// fwWrapReverse: the items wrap onto more lines, upwards or leftwards.
  /// </remarks>
  TFlexWrap = (
    fwNoWrap,         // default  -> everything on one line
    fwWrap,           //          -> wrap downwards / rightwards
    fwWrapReverse     //          -> wrap upwards / leftwards
  );

  /// <summary>
  /// Distribution of the items along the main axis (CSS justify-content).
  /// </summary>
  /// <remarks>
  /// jcFlexStart: the items are packed at the start of the line (the default).
  /// jcFlexEnd: packed at the end. jcCenter: packed at the center.
  /// jcSpaceBetween: the free space goes between the items; the first is at the start and the last at the end.
  /// jcSpaceAround: the free space is shared around every item, so the space at the ends is half of the space between two items.
  /// jcSpaceEvenly: the free space is split in equal parts between the items and at both ends.
  /// </remarks>
  TJustifyContent = (
    jcFlexStart,      // default
    jcFlexEnd,
    jcCenter,
    jcSpaceBetween,
    jcSpaceAround,
    jcSpaceEvenly
  );

  /// <summary>
  /// Alignment of the items on the cross axis (CSS align-items).
  /// </summary>
  /// <remarks>
  /// aiStretch: an item with an automatic cross size stretches to the line (the default).
  /// aiFlexStart, aiFlexEnd, aiCenter: the items are aligned at the start, at the end or at the center of the line.
  /// aiBaseline: treated as aiFlexStart.
  /// </remarks>
  TAlignItems = (
    aiStretch,        // default
    aiFlexStart,
    aiFlexEnd,
    aiCenter,
    aiBaseline        // treated as FlexStart in this implementation
  );

  /// <summary>
  /// Alignment of one item on the cross axis, in place of the one of the container (CSS align-self).
  /// </summary>
  /// <remarks>
  /// asAuto: the item uses the TAlignItems value of the container.
  /// The other values mean the same as the matching TAlignItems values.
  /// </remarks>
  TAlignSelf = (
    asAuto,           // inherits from the container (align-items)
    asStretch,
    asFlexStart,
    asFlexEnd,
    asCenter,
    asBaseline
  );

  /// <summary>
  /// Distribution of the lines on the cross axis when the items wrap onto more lines (CSS align-content).
  /// </summary>
  /// <remarks>
  /// acFlexStart: the lines are packed at the start (the default). acFlexEnd: at the end. acCenter: at the center.
  /// acSpaceBetween, acSpaceAround, acSpaceEvenly: the free space is shared between the lines as for TJustifyContent.
  /// acStretch: the lines grow to fill the cross size of the container.
  /// </remarks>
  TAlignContent = (
    acFlexStart,      // default when wrap
    acFlexEnd,
    acCenter,
    acSpaceBetween,
    acSpaceAround,
    acSpaceEvenly,
    acStretch
  );

  /// <summary>
  /// How the flex-basis of an item is read.
  /// </summary>
  /// <remarks>
  /// fbuAuto: the basis is the width or the height of the item.
  /// fbuPixel: the basis is a value in pixels.
  /// fbuPercent: the basis is a percentage of the main size of the container.
  /// </remarks>
  TFlexBasisUnit = (
    fbuAuto,          // uses the Width/Height of the item as basis
    fbuPixel,         // absolute value in pixels
    fbuPercent        // percentage of the main size of the container
  );

  /// <summary>
  /// Main size of an item compared with its flex-basis.
  /// </summary>
  /// <remarks>
  /// fisShrunk: smaller than the basis. fisAtBasis: equal to the basis, within the tolerance. fisGrown: greater than the basis.
  /// </remarks>
  TFlexItemState = (
    fisShrunk,        // smaller than the basis
    fisAtBasis,       // equal to the basis (within the tolerance)
    fisGrown          // greater than the basis
  );

// ---------------------------------------------------------------------------
// TFlexItemInput - input data for each child
// ---------------------------------------------------------------------------

type
  /// <summary>
  /// Input data of one item for the layout.
  /// </summary>
  TFlexItemInput = record
    /// <summary>Natural width of the control.</summary>
    NaturalWidth  : Single;
    /// <summary>Natural height of the control.</summary>
    NaturalHeight : Single;

    /// <summary>True when the width is automatic, not explicitly chosen (like width: auto in CSS). Stretch on the cross axis applies only to an automatic size; in a column an automatic width fits the available width (fit-content).</summary>
    WidthAuto     : Boolean;
    /// <summary>True when the height is automatic, not explicitly chosen (like height: auto in CSS).</summary>
    HeightAuto    : Boolean;

    /// <summary>Smallest width, in pixels. 0 means no limit.</summary>
    MinWidth      : Single;
    /// <summary>Largest width, in pixels. 0 means no limit.</summary>
    MaxWidth      : Single;
    /// <summary>Smallest height, in pixels. 0 means no limit.</summary>
    MinHeight     : Single;
    /// <summary>Largest height, in pixels. 0 means no limit.</summary>
    MaxHeight     : Single;
    /// <summary>Automatic smallest width, in pixels: the width of the content of the item (like min-width: auto in CSS). It stops the shrinking on the main axis, and only while MinWidth is 0. 0 means no automatic minimum.</summary>
    AutoMinWidth  : Single;
    /// <summary>Automatic smallest height, in pixels: the height of the content of the item (like min-height: auto in CSS). It stops the shrinking on the main axis, and only while MinHeight is 0. 0 means no automatic minimum.</summary>
    AutoMinHeight : Single;

    /// <summary>Left margin, in pixels.</summary>
    MarginLeft    : Single;
    /// <summary>Top margin, in pixels.</summary>
    MarginTop     : Single;
    /// <summary>Right margin, in pixels.</summary>
    MarginRight   : Single;
    /// <summary>Bottom margin, in pixels.</summary>
    MarginBottom  : Single;

    /// <summary>How much of the free space the item takes (CSS flex-grow). The default is 0.</summary>
    FlexGrow      : Single;
    /// <summary>How much the item shrinks when the space is not enough (CSS flex-shrink). The default is 1.</summary>
    FlexShrink    : Single;
    /// <summary>Value of the flex-basis; FlexBasisUnit says how to read it.</summary>
    FlexBasis     : Single;
    /// <summary>How FlexBasis is read.</summary>
    FlexBasisUnit : TFlexBasisUnit;
    /// <summary>Alignment of the item on the cross axis. The default is asAuto.</summary>
    AlignSelf     : TAlignSelf;
    /// <summary>Position of the item in the order of the layout (CSS order). The default is 0.</summary>
    Order         : Integer;

    /// <summary>Index of the item in the array of the children. The results are returned in this order, whatever the sorting by Order.</summary>
    OriginalIndex : Integer;

    /// <summary>Returns an input with the default values: no limits, FlexGrow 0, FlexShrink 1, automatic basis, automatic width and height.</summary>
    class function Default: TFlexItemInput; static;
  end;

// ---------------------------------------------------------------------------
// TFlexContext - everything that describes the container
// ---------------------------------------------------------------------------

  /// <summary>
  /// The container and its items: everything the layout needs.
  /// </summary>
  TFlexContext = record
    /// <summary>Available inner width of the container, with the Padding already subtracted.</summary>
    AvailableWidth  : Single;
    /// <summary>Available inner height of the container, with the Padding already subtracted.</summary>
    AvailableHeight : Single;

    /// <summary>Direction of the main axis.</summary>
    Direction       : TFlexDirection;
    /// <summary>Whether the items wrap onto more lines.</summary>
    Wrap            : TFlexWrap;
    /// <summary>Distribution of the items along the main axis.</summary>
    JustifyContent  : TJustifyContent;
    /// <summary>Alignment of the items on the cross axis.</summary>
    AlignItems      : TAlignItems;
    /// <summary>Distribution of the lines on the cross axis.</summary>
    AlignContent    : TAlignContent;
    /// <summary>Space between the items of a line, in pixels.</summary>
    ColumnGap       : Single;
    /// <summary>Space between the lines, in pixels.</summary>
    RowGap          : Single;

    /// <summary>True: with Wrap = fwNoWrap the only line takes the whole cross size of the container (as in CSS). False, the default: the line is as high as the tallest item.</summary>
    SingleLineFillsContainer : Boolean;

    /// <summary>The items to lay out.</summary>
    Items           : TArray<TFlexItemInput>;

    /// <summary>Returns a context with the default values: fdRow, fwNoWrap, jcFlexStart, aiStretch, acFlexStart, no gaps and no items.</summary>
    class function Default: TFlexContext; static;
  end;

// ---------------------------------------------------------------------------
// TFlexItemResult - rectangle computed for each child
//   Coordinates are RELATIVE to the top-left corner of the available area
//   of the container (padding excluded). TS4YFlexBox will translate them into FMX coordinates.
// ---------------------------------------------------------------------------

  /// <summary>
  /// The rectangle computed for one item.
  /// </summary>
  /// <remarks>
  /// The coordinates are relative to the top left corner of the available area of the container, with the Padding excluded.
  /// </remarks>
  TFlexItemResult = record
    /// <summary>Index of the item in the array of the children (OriginalIndex of its input).</summary>
    OriginalIndex : Integer;
    /// <summary>Left edge of the item.</summary>
    Left          : Single;
    /// <summary>Top edge of the item.</summary>
    Top           : Single;
    /// <summary>Width of the item.</summary>
    Width         : Single;
    /// <summary>Height of the item.</summary>
    Height        : Single;
    /// <summary>Main size of the item before the free space is distributed: the resolved flex-basis.</summary>
    BaseMain      : Single;
    /// <summary>Index of the line of the item, in visual order.</summary>
    LineIndex     : Integer;
  end;

// ---------------------------------------------------------------------------
// TFlexContentSize - smallest size that does not crop the items
// ---------------------------------------------------------------------------

  /// <summary>
  /// The size of a container whose width is limited and whose height follows the content, so that none of its items is cropped.
  /// </summary>
  /// <remarks>
  /// The Padding of the container is not included, like in TFlexContext.
  /// </remarks>
  TFlexContentSize = record
    /// <summary>Smallest width at which no item is cropped, in pixels.</summary>
    Width  : Single;
    /// <summary>Height that the content needs at the width of the container (the greater of AvailableWidth and Width), in pixels.</summary>
    Height : Single;
  end;

// ---------------------------------------------------------------------------
// TFlexEngine
// ---------------------------------------------------------------------------

  /// <summary>
  /// The CSS flexbox algorithm (W3C Level 1). It is stateless and does not depend on FireMonkey controls.
  /// </summary>
  TFlexEngine = class
  public
    /// <summary>Computes the layout of the items of a context. It returns an array with the same length as Context.Items, sorted by OriginalIndex (not by Order).</summary>
    class function Calculate(const Context: TFlexContext): TArray<TFlexItemResult>;

    /// <summary>Computes the size of a container whose width is limited by AvailableWidth and whose height follows the content (CSS height: auto). AvailableHeight is not used. In a row the items shrink as far as their FlexShrink, MinWidth and MinHeight allow: Width is the sum of the items of a line (the widest item when they wrap) and Height is that of the lines at the width of the container. In a column the items do not shrink and do not wrap: Height is the sum of their heights and Width is the widest item, where an automatic width fits AvailableWidth. A percentage basis counts as the natural size. FlexGrow is not taken into account.</summary>
    class function Measure(const Context: TFlexContext): TFlexContentSize;

  private
    // - Internal types -

    type
      // Working representation of a single item during the computation
      TWorkItem = record
        Input          : TFlexItemInput;
        FlexBase          : Single;  // resolved flex-basis, without min/max clamp
        HypotheticalMain  : Single;  // resolved flex-basis + min/max clamp
        HypotheticalCross : Single;  // natural cross size
        CrossAuto      : Boolean;    // auto cross size (subject to stretch)
        FrozenMain     : Single;     // final main size after grow/shrink
        FrozenCross    : Single;     // final cross size
        Frozen         : Boolean;    // item frozen in the grow/shrink loop
        // Final position (main and cross axis, relative to the start of the line)
        MainPos        : Single;
        CrossPos       : Single;
      end;

      // A "flex line" is the set of items on a row/column
      TFlexLine = record
        Items          : TArray<Integer>;  // indices into FWorkItems
        MainSize       : Single;           // sum of FrozenMain + gap
        CrossSize      : Single;           // height/width of the line
        CrossPos       : Single;           // cross position of the line
      end;

    // - Private methods of the computation -
    class function  IsRow(Dir: TFlexDirection): Boolean; static; inline;
    class function  IsReverse(Dir: TFlexDirection): Boolean; static; inline;

    // Step 2: resolves flex-basis -> HypotheticalMain
    class function  ResolveBasis(const Item: TFlexItemInput;
                      MainAvailable: Single): Single; static;

    // Step 3: partitions the work items into lines
    class procedure BuildLines(var WItems: TArray<TWorkItem>;
                      const Ctx: TFlexContext; MainAvailable: Single;
                      out Lines: TArray<TFlexLine>); static;

    // Step 4: distributes grow or shrink for a single line
    class procedure ResolveFlexibility(var WItems: TArray<TWorkItem>;
                      var Line: TFlexLine; MainAvailable: Single;
                      ColumnGap: Single); static;

    // Step 5: computes the cross size of each item (stretch or natural)
    class procedure ResolveItemCrossSize(var WItems: TArray<TWorkItem>;
                      var Line: TFlexLine; CrossAvailable: Single;
                      ContainerAlignItems: TAlignItems); static;

    // Step 6: computes the cross size of each line and distributes with align-content
    class procedure ResolveLineCrossSizes(var Lines: TArray<TFlexLine>;
                      CrossAvailable: Single; RowGap: Single;
                      AlignContent: TAlignContent); static;

    // Step 7: main-axis positioning (justify-content + gap)
    class procedure PositionMainAxis(var WItems: TArray<TWorkItem>;
                      var Line: TFlexLine; MainAvailable: Single;
                      ColumnGap: Single; JustifyContent: TJustifyContent;
                      Reverse: Boolean); static;

    // Step 8: cross-axis positioning per item (align-items / align-self)
    class procedure PositionCrossAxis(var WItems: TArray<TWorkItem>;
                      var Line: TFlexLine;
                      ContainerAlignItems: TAlignItems); static;

    // Largest end (position + size + trailing margin) of the results on one axis
    class function  MeasureExtent(const Context: TFlexContext;
                      const Results: TArray<TFlexItemResult>;
                      HorizontalAxis: Boolean): Single; static;

    // Utility: clamp with min/max (0 = disabled)
    class function  ClampSize(Value, MinVal, MaxVal: Single): Single; static; inline;
  end;

// ---------------------------------------------------------------------------

implementation

// ===========================================================================
// TFlexItemInput
// ===========================================================================

class function TFlexItemInput.Default: TFlexItemInput;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.FlexGrow      := 0;
  Result.FlexShrink    := 1;
  Result.FlexBasis     := 0;
  Result.FlexBasisUnit := fbuAuto;
  Result.AlignSelf     := asAuto;
  Result.Order         := 0;
  Result.MaxWidth      := 0;  // 0 = no limit
  Result.MaxHeight     := 0;
  Result.WidthAuto     := True;
  Result.HeightAuto    := True;
end;

// ===========================================================================
// TFlexContext
// ===========================================================================

class function TFlexContext.Default: TFlexContext;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Direction      := fdRow;
  Result.Wrap           := fwNoWrap;
  Result.JustifyContent := jcFlexStart;
  Result.AlignItems     := aiStretch;
  Result.AlignContent   := acFlexStart;
  Result.ColumnGap      := 0;
  Result.RowGap         := 0;
end;

// ===========================================================================
// TFlexEngine - utility
// ===========================================================================

class function TFlexEngine.IsRow(Dir: TFlexDirection): Boolean;
begin
  Result := Dir in [fdRow, fdRowReverse];
end;

class function TFlexEngine.IsReverse(Dir: TFlexDirection): Boolean;
begin
  Result := Dir in [fdRowReverse, fdColumnReverse];
end;

class function TFlexEngine.ClampSize(Value, MinVal, MaxVal: Single): Single;
begin
  Result := Value;

  if MinVal > 0 then
    Result := Max(Result, MinVal);

  if MaxVal > 0 then
    Result := Min(Result, MaxVal);
end;

// ===========================================================================
// Step 2 - flex-basis resolution
// ===========================================================================

class function TFlexEngine.ResolveBasis(const Item: TFlexItemInput;
  MainAvailable: Single): Single;
var
  Natural: Single;
begin
  // Natural size on the main axis
  Natural := Item.NaturalWidth; // will be corrected by the caller if column

  case Item.FlexBasisUnit of
    fbuAuto:
      // 'auto' -> use the natural size of the item
      Result := Natural;

    fbuPixel:
      Result := Item.FlexBasis;

    fbuPercent:
      begin
        if MainAvailable > 0 then
          Result := MainAvailable * (Item.FlexBasis / 100.0)
        else
          Result := Natural; // fallback if the container is undefined
      end;
  else
    Result := Natural;
  end;
end;

// ===========================================================================
// Step 3 - Building the lines
// ===========================================================================

class procedure TFlexEngine.BuildLines(var WItems: TArray<TWorkItem>;
  const Ctx: TFlexContext; MainAvailable: Single; out Lines: TArray<TFlexLine>);
var
  LineList   : TList<TFlexLine>;
  CurrentLine: TFlexLine;
  UsedMain   : Single;
  I          : Integer;
  ItemMain   : Single;
  GapCount   : Integer;
begin
  LineList := TList<TFlexLine>.Create;
  try
    SetLength(CurrentLine.Items, 0);
    CurrentLine.MainSize  := 0;
    CurrentLine.CrossSize := 0;
    CurrentLine.CrossPos  := 0;
    UsedMain := 0;

    for I := 0 to High(WItems) do
    begin
      // Space taken by the item (size + margins on the main axis)
      if IsRow(Ctx.Direction) then
        ItemMain := WItems[I].HypotheticalMain
                    + WItems[I].Input.MarginLeft
                    + WItems[I].Input.MarginRight
      else
        ItemMain := WItems[I].HypotheticalMain
                    + WItems[I].Input.MarginTop
                    + WItems[I].Input.MarginBottom;

      // Gap to add if it is not the first item of the line
      GapCount := Length(CurrentLine.Items);

      if (Ctx.Wrap <> fwNoWrap) and (Length(CurrentLine.Items) > 0) and
         (UsedMain + Ctx.ColumnGap + ItemMain > MainAvailable + 0.001) then
      begin
        // Close the current line and open a new one
        LineList.Add(CurrentLine);
        SetLength(CurrentLine.Items, 0);
        CurrentLine.MainSize := 0;
        UsedMain := 0;
        GapCount := 0;
      end;

      // Add the item to the current line
      SetLength(CurrentLine.Items, Length(CurrentLine.Items) + 1);
      CurrentLine.Items[High(CurrentLine.Items)] := I;

      if GapCount > 0 then
        UsedMain := UsedMain + Ctx.ColumnGap;

      UsedMain := UsedMain + ItemMain;
    end;

    // Add the last line
    if Length(CurrentLine.Items) > 0 then
      LineList.Add(CurrentLine);

    Lines := LineList.ToArray;
  finally
    LineList.Free;
  end;
end;

// ===========================================================================
// Step 4 - Grow / shrink distribution
//   Implements the iterative W3C algorithm, section 9.7
// ===========================================================================

class procedure TFlexEngine.ResolveFlexibility(var WItems: TArray<TWorkItem>;
  var Line: TFlexLine; MainAvailable: Single; ColumnGap: Single);
var
  I, Idx      : Integer;
  TotalBase   : Single;
  FreeSpace   : Single;
  Growing     : Boolean;
  TotalFactor : Single;
  Target      : Single;
  Clamped     : Single;
  TotalViolation: Single;
  MaxIter     : Integer;
  AllFrozen   : Boolean;
  GapTotal    : Single;
  Violations  : TArray<Single>;
begin
  // Initialize all items as non-frozen with FrozenMain = HypotheticalMain
  for I := 0 to High(Line.Items) do
  begin
    Idx := Line.Items[I];
    WItems[Idx].Frozen     := False;
    WItems[Idx].FrozenMain := WItems[Idx].HypotheticalMain;
  end;

  // Total gap on the line
  GapTotal := ColumnGap * Max(0, Length(Line.Items) - 1);

  // Total main space used by the items (hypothetical size + margins)
  TotalBase := 0;

  for I := 0 to High(Line.Items) do
  begin
    Idx := Line.Items[I];
    TotalBase := TotalBase + WItems[Idx].HypotheticalMain
                           + WItems[Idx].Input.MarginLeft
                           + WItems[Idx].Input.MarginRight;
  end;

  Growing := MainAvailable - GapTotal - TotalBase >= 0;

  // Freeze the items that do not participate: zero factor, or whose min/max
  // limit already goes in the opposite direction (W3C 9.7, point 3)
  for I := 0 to High(Line.Items) do
  begin
    Idx := Line.Items[I];

    if Growing then
    begin
      if (WItems[Idx].Input.FlexGrow <= 0) or
         (WItems[Idx].FlexBase > WItems[Idx].HypotheticalMain) then
        WItems[Idx].Frozen := True;
    end
    else
    begin
      if (WItems[Idx].Input.FlexShrink <= 0) or
         (WItems[Idx].FlexBase < WItems[Idx].HypotheticalMain) then
        WItems[Idx].Frozen := True;
    end;
  end;

  SetLength(Violations, Length(Line.Items));

  // Iterative W3C loop: the space is distributed among the unfrozen items,
  // min/max are applied and the violations are frozen (max 100 iterations for safety)
  MaxIter := 100;

  repeat
    Dec(MaxIter);

    // Free space = available - gap - margins - (frozen: final size,
    // unfrozen: flex base)
    FreeSpace := MainAvailable - GapTotal;

    for I := 0 to High(Line.Items) do
    begin
      Idx := Line.Items[I];
      FreeSpace := FreeSpace - WItems[Idx].Input.MarginLeft
                             - WItems[Idx].Input.MarginRight;
      if WItems[Idx].Frozen then
        FreeSpace := FreeSpace - WItems[Idx].FrozenMain
      else
        FreeSpace := FreeSpace - WItems[Idx].FlexBase;
    end;

    // Sum of the factors of the non-frozen items
    TotalFactor := 0;

    for I := 0 to High(Line.Items) do
    begin
      Idx := Line.Items[I];

      if not WItems[Idx].Frozen then
      begin
        if Growing then
          TotalFactor := TotalFactor + WItems[Idx].Input.FlexGrow
        else
          TotalFactor := TotalFactor + WItems[Idx].Input.FlexShrink
                                     * WItems[Idx].FlexBase;
      end;
    end;

    if TotalFactor <= 0 then
    begin
      // nothing to distribute: the non-frozen items stay at the hypothetical size
      for I := 0 to High(Line.Items) do
      begin
        Idx := Line.Items[I];

        if not WItems[Idx].Frozen then
        begin
          WItems[Idx].FrozenMain := WItems[Idx].HypotheticalMain;
          WItems[Idx].Frozen := True;
        end;
      end;

      AllFrozen := True;
    end
    else
    begin
      // Target size of each non-frozen item, limited to min/max
      TotalViolation := 0;

      for I := 0 to High(Line.Items) do
      begin
        Idx := Line.Items[I];
        Violations[I] := 0;

        if not WItems[Idx].Frozen then
        begin
          if Growing then
            Target := WItems[Idx].FlexBase
                      + FreeSpace * WItems[Idx].Input.FlexGrow / TotalFactor
          else
            Target := WItems[Idx].FlexBase
                      + FreeSpace * (WItems[Idx].Input.FlexShrink * WItems[Idx].FlexBase)
                        / TotalFactor;

          Target  := Max(0, Target);
          Clamped := ClampSize(Target, WItems[Idx].Input.MinWidth,
                               WItems[Idx].Input.MaxWidth);
          WItems[Idx].FrozenMain := Clamped;
          Violations[I] := Clamped - Target;
          TotalViolation := TotalViolation + Violations[I];
        end;
      end;

      // Total violation > 0: the items below the minimum are frozen; < 0: those
      // above the maximum; 0: all are frozen. The rest is redistributed.
      for I := 0 to High(Line.Items) do
      begin
        Idx := Line.Items[I];

        if not WItems[Idx].Frozen then
        begin
          if (TotalViolation = 0) or
             ((TotalViolation > 0) and (Violations[I] > 0)) or
             ((TotalViolation < 0) and (Violations[I] < 0)) then
            WItems[Idx].Frozen := True;
        end;
      end;

      AllFrozen := True;
      I := 0;

      while AllFrozen and (I <= High(Line.Items)) do
      begin
        AllFrozen := WItems[Line.Items[I]].Frozen;
        Inc(I);
      end;
    end;
  until AllFrozen or (MaxIter <= 0);

  // Make sure all final values are >= 0
  for I := 0 to High(Line.Items) do
  begin
    Idx := Line.Items[I];
    WItems[Idx].FrozenMain := Max(0, WItems[Idx].FrozenMain);
  end;
end;

// ===========================================================================
// Step 5 - Cross size of the items
// ===========================================================================

class procedure TFlexEngine.ResolveItemCrossSize(var WItems: TArray<TWorkItem>;
  var Line: TFlexLine; CrossAvailable: Single;
  ContainerAlignItems: TAlignItems);
var
  I, Idx    : Integer;
  EffAlign  : TAlignItems;
  CrossNat  : Single;
begin
  for I := 0 to High(Line.Items) do
  begin
    Idx := Line.Items[I];

    // Resolve the effective align (align-self overrides align-items)
    case WItems[Idx].Input.AlignSelf of
      asStretch   : EffAlign := aiStretch;
      asFlexStart, asBaseline : EffAlign := aiFlexStart;
      asFlexEnd   : EffAlign := aiFlexEnd;
      asCenter    : EffAlign := aiCenter;
    else
      EffAlign := ContainerAlignItems; // asAuto
    end;

    CrossNat := WItems[Idx].HypotheticalCross;

    // stretch: fills the line (minus the cross margins), only if the cross size
    // is auto
    if (EffAlign = aiStretch) and WItems[Idx].CrossAuto then
      WItems[Idx].FrozenCross := CrossAvailable
                                 - WItems[Idx].Input.MarginTop
                                 - WItems[Idx].Input.MarginBottom
    else
      WItems[Idx].FrozenCross := CrossNat;

    // Clamp cross min/max
    WItems[Idx].FrozenCross := ClampSize(
      WItems[Idx].FrozenCross,
      WItems[Idx].Input.MinHeight,
      WItems[Idx].Input.MaxHeight
    );
    WItems[Idx].FrozenCross := Max(0, WItems[Idx].FrozenCross);
  end;
end;

// ===========================================================================
// Step 6 - Cross size of the lines + align-content
// ===========================================================================

class procedure TFlexEngine.ResolveLineCrossSizes(var Lines: TArray<TFlexLine>;
  CrossAvailable: Single; RowGap: Single; AlignContent: TAlignContent);
var
  I          : Integer;
  TotalCross : Single;
  FreeSpace  : Single;
  GapTotal   : Single;
  SpacePer   : Single;
  SpaceBefore: Single;
  Current    : Single;
  N          : Integer;
begin
  // Compute the cross size of each line = max(FrozenCross + margins) of the items
  // (already computed in ResolveItemCrossSize, here we only update Line.CrossSize
  //  if it has not been set yet)
  // In this phase we assume Line.CrossSize is already the max FrozenCross
  // of the items of the line - it is set in Calculate().

  N := Length(Lines);

  if N = 0 then
    Exit;

  GapTotal := RowGap * Max(0, N - 1);
  TotalCross := GapTotal;

  for I := 0 to N - 1 do
    TotalCross := TotalCross + Lines[I].CrossSize;

  FreeSpace := CrossAvailable - TotalCross;

  // Distribution according to align-content
  SpacePer    := 0;
  SpaceBefore := 0;

  case AlignContent of
    acFlexStart:    SpaceBefore := 0;
    acFlexEnd:      SpaceBefore := FreeSpace;
    acCenter:       SpaceBefore := FreeSpace / 2;
    acSpaceBetween: if N > 1 then SpacePer := FreeSpace / (N - 1);
    acSpaceAround:  begin SpacePer := FreeSpace / N; SpaceBefore := SpacePer / 2; end;
    acSpaceEvenly:  begin SpacePer := FreeSpace / (N + 1); SpaceBefore := SpacePer; end;
    acStretch:
      begin
        // Distributes the free space equally between the lines
        if N > 0 then
        begin
          SpacePer := FreeSpace / N;

          for I := 0 to N - 1 do
            Lines[I].CrossSize := Lines[I].CrossSize + SpacePer;
        end;

        SpaceBefore := 0;
        SpacePer    := 0;
      end;
  end;

  // Assign the cross position to each line
  Current := SpaceBefore;

  for I := 0 to N - 1 do
  begin
    Lines[I].CrossPos := Current;
    Current := Current + Lines[I].CrossSize;
    if I < N - 1 then
      Current := Current + RowGap + SpacePer;
  end;
end;

// ===========================================================================
// Step 7 - Main-axis positioning (justify-content + gap)
// ===========================================================================

class procedure TFlexEngine.PositionMainAxis(var WItems: TArray<TWorkItem>;
  var Line: TFlexLine; MainAvailable: Single; ColumnGap: Single;
  JustifyContent: TJustifyContent; Reverse: Boolean);
var
  I, Idx     : Integer;
  TotalUsed  : Single;
  FreeSpace  : Single;
  GapTotal   : Single;
  SpacePer   : Single;
  SpaceBefore: Single;
  Current    : Single;
  N          : Integer;
begin
  N := Length(Line.Items);

  if N = 0 then
    Exit;

  GapTotal := ColumnGap * Max(0, N - 1);

  TotalUsed := GapTotal;

  for I := 0 to N - 1 do
  begin
    Idx := Line.Items[I];
    TotalUsed := TotalUsed + WItems[Idx].FrozenMain
                           + WItems[Idx].Input.MarginLeft
                           + WItems[Idx].Input.MarginRight;
  end;

  FreeSpace   := MainAvailable - TotalUsed;
  SpacePer    := 0;
  SpaceBefore := 0;

  case JustifyContent of
    jcFlexStart:    SpaceBefore := 0;
    jcFlexEnd:      SpaceBefore := FreeSpace;
    jcCenter:       SpaceBefore := FreeSpace / 2;
    jcSpaceBetween: if N > 1 then SpacePer := FreeSpace / (N - 1);
    jcSpaceAround:  begin SpacePer := FreeSpace / N; SpaceBefore := SpacePer / 2; end;
    jcSpaceEvenly:  begin SpacePer := FreeSpace / (N + 1); SpaceBefore := SpacePer; end;
  end;

  SpaceBefore := Max(0, SpaceBefore);

  // Position the items in the correct order (or reversed if Reverse)
  Current := SpaceBefore;

  if not Reverse then
  begin
    for I := 0 to N - 1 do
    begin
      Idx := Line.Items[I];
      WItems[Idx].MainPos := Current + WItems[Idx].Input.MarginLeft;
      Current := Current + WItems[Idx].Input.MarginLeft
                         + WItems[Idx].FrozenMain
                         + WItems[Idx].Input.MarginRight;
      if I < N - 1 then
        Current := Current + ColumnGap + SpacePer;
    end;
  end
  else
  begin
    // row-reverse / column-reverse: start from the end
    Current := SpaceBefore;

    for I := 0 to N - 1 do
    begin
      Idx := Line.Items[I];
      WItems[Idx].MainPos := MainAvailable - Current
                             - WItems[Idx].Input.MarginRight
                             - WItems[Idx].FrozenMain;
      Current := Current + WItems[Idx].Input.MarginRight
                         + WItems[Idx].FrozenMain
                         + WItems[Idx].Input.MarginLeft;
      if I < N - 1 then
        Current := Current + ColumnGap + SpacePer;
    end;
  end;
end;

// ===========================================================================
// Step 8 - Cross-axis positioning per item
// ===========================================================================

class procedure TFlexEngine.PositionCrossAxis(var WItems: TArray<TWorkItem>;
  var Line: TFlexLine; ContainerAlignItems: TAlignItems);
var
  I, Idx    : Integer;
  EffAlign  : TAlignItems;
  FreeSpace : Single;
begin
  for I := 0 to High(Line.Items) do
  begin
    Idx := Line.Items[I];

    case WItems[Idx].Input.AlignSelf of
      asStretch   : EffAlign := aiStretch;
      asFlexStart, asBaseline : EffAlign := aiFlexStart;
      asFlexEnd   : EffAlign := aiFlexEnd;
      asCenter    : EffAlign := aiCenter;
    else
      EffAlign := ContainerAlignItems;
    end;

    FreeSpace := Line.CrossSize - WItems[Idx].FrozenCross
                                - WItems[Idx].Input.MarginTop
                                - WItems[Idx].Input.MarginBottom;

    case EffAlign of
      aiFlexStart, aiBaseline:
        WItems[Idx].CrossPos := Line.CrossPos + WItems[Idx].Input.MarginTop;

      aiFlexEnd:
        WItems[Idx].CrossPos := Line.CrossPos + Line.CrossSize
                                - WItems[Idx].FrozenCross
                                - WItems[Idx].Input.MarginBottom;

      aiCenter:
        WItems[Idx].CrossPos := Line.CrossPos
                                + WItems[Idx].Input.MarginTop
                                + Max(0, FreeSpace) / 2;

      aiStretch:
        WItems[Idx].CrossPos := Line.CrossPos + WItems[Idx].Input.MarginTop;
    end;
  end;
end;

// ===========================================================================
// Calculate - entry point
// ===========================================================================

class function TFlexEngine.Calculate(const Context: TFlexContext): TArray<TFlexItemResult>;
var
  WItems     : TArray<TWorkItem>;
  SortedIdx  : TArray<Integer>;
  Lines      : TArray<TFlexLine>;
  I, J, Idx  : Integer;
  Row        : Boolean;
  Rev        : Boolean;
  MainAvail  : Single;
  CrossAvail : Single;
  MaxCross   : Single;
  Results    : TArray<TFlexItemResult>;
  LineOfItem : TArray<Integer>;
  SingleLine : Boolean;
begin
  Result := nil;

  if Length(Context.Items) = 0 then
    Exit;

  Row        := IsRow(Context.Direction);
  Rev        := IsReverse(Context.Direction);
  MainAvail  := IfThen(Row, Context.AvailableWidth,  Context.AvailableHeight);
  CrossAvail := IfThen(Row, Context.AvailableHeight, Context.AvailableWidth);
  SingleLine := Context.SingleLineFillsContainer and (Context.Wrap = fwNoWrap) and
    (CrossAvail > 0);

  // - Step 1: sort by Order (stable: keeps source order on ties) -
  SetLength(SortedIdx, Length(Context.Items));

  for I := 0 to High(SortedIdx) do
    SortedIdx[I] := I;

  TArray.Sort<Integer>(SortedIdx, TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      Result := Context.Items[A].Order - Context.Items[B].Order;

      // TArray.Sort is not stable: on equal Order the source order applies
      if Result = 0 then
        Result := A - B;
    end
  ));

  // - Step 2: build the work items, resolve the basis -
  SetLength(WItems, Length(Context.Items));

  for I := 0 to High(SortedIdx) do
  begin
    Idx := SortedIdx[I];
    WItems[I].Input := Context.Items[Idx];
    WItems[I].Input.OriginalIndex := Idx; // preserve the original index

    // Resolve the basis on the main axis
    if Row then
    begin
      WItems[I].HypotheticalMain  := ResolveBasis(Context.Items[Idx], MainAvail);
      WItems[I].HypotheticalCross := Context.Items[Idx].NaturalHeight;
      WItems[I].CrossAuto := Context.Items[Idx].HeightAuto;

      // For column: main and cross are swapped
      if WItems[I].Input.FlexBasisUnit = fbuAuto then
        WItems[I].HypotheticalMain := Context.Items[Idx].NaturalWidth;
    end
    else
    begin
      // For column: the basis applies to the height (main axis = vertical)
      WItems[I].Input.NaturalWidth  := Context.Items[Idx].NaturalHeight;
      WItems[I].Input.NaturalHeight := Context.Items[Idx].NaturalWidth;

      // Also swap min/max
      WItems[I].Input.MinWidth  := Context.Items[Idx].MinHeight;
      WItems[I].Input.MaxWidth  := Context.Items[Idx].MaxHeight;
      WItems[I].Input.MinHeight := Context.Items[Idx].MinWidth;
      WItems[I].Input.MaxHeight := Context.Items[Idx].MaxWidth;

      // Also swap margins
      WItems[I].Input.MarginLeft   := Context.Items[Idx].MarginTop;
      WItems[I].Input.MarginRight  := Context.Items[Idx].MarginBottom;
      WItems[I].Input.MarginTop    := Context.Items[Idx].MarginLeft;
      WItems[I].Input.MarginBottom := Context.Items[Idx].MarginRight;

      WItems[I].HypotheticalMain  := ResolveBasis(WItems[I].Input, MainAvail);
      WItems[I].HypotheticalCross := Context.Items[Idx].NaturalWidth;
      WItems[I].CrossAuto := Context.Items[Idx].WidthAuto;

      // Auto width in a column: fit-content, not beyond the available width
      if Context.Items[Idx].WidthAuto and (CrossAvail > 0) then
      begin
        WItems[I].HypotheticalCross := Min(WItems[I].HypotheticalCross,
          Max(0, CrossAvail - Context.Items[Idx].MarginLeft - Context.Items[Idx].MarginRight));
      end;
    end;

    // Automatic minimum (CSS min-width: auto): on the main axis only, an item does
    // not shrink below its content unless MinWidth is set (0 = auto)
    if WItems[I].Input.MinWidth <= 0 then
    begin
      if Row then
        WItems[I].Input.MinWidth := Context.Items[Idx].AutoMinWidth
      else
        WItems[I].Input.MinWidth := Context.Items[Idx].AutoMinHeight;

      if WItems[I].Input.MaxWidth > 0 then
        WItems[I].Input.MinWidth := Min(WItems[I].Input.MinWidth, WItems[I].Input.MaxWidth);
    end;

    WItems[I].FlexBase := WItems[I].HypotheticalMain;
    WItems[I].HypotheticalMain := ClampSize(
      WItems[I].HypotheticalMain,
      WItems[I].Input.MinWidth,
      WItems[I].Input.MaxWidth
    );
    WItems[I].FrozenMain  := WItems[I].HypotheticalMain;
    WItems[I].FrozenCross := WItems[I].HypotheticalCross;
    WItems[I].Frozen      := False;
    WItems[I].MainPos     := 0;
    WItems[I].CrossPos    := 0;
  end;

  // - Step 3: build the lines -
  BuildLines(WItems, Context, MainAvail, Lines);

  // - Step 4 + 5: for each line, resolve main and cross -
  for I := 0 to High(Lines) do
  begin
    ResolveFlexibility(WItems, Lines[I], MainAvail, Context.ColumnGap);

    // Compute the cross size of the line = max FrozenCross + cross margins of the items
    MaxCross := 0;

    for J := 0 to High(Lines[I].Items) do
    begin
      Idx := Lines[I].Items[J];
      MaxCross := Max(MaxCross,
        WItems[Idx].FrozenCross
        + WItems[Idx].Input.MarginTop
        + WItems[Idx].Input.MarginBottom
      );
    end;

    Lines[I].CrossSize := MaxCross;

    // Single line: it takes the whole cross size of the container
    if SingleLine then
    begin
      Lines[I].CrossSize := CrossAvail;
    end;

    // Step 5: cross size of the items (stretch if needed)
    ResolveItemCrossSize(WItems, Lines[I], Lines[I].CrossSize, Context.AlignItems);

    // Recompute the CrossSize of the line after stretch
    MaxCross := 0;

    for J := 0 to High(Lines[I].Items) do
    begin
      Idx := Lines[I].Items[J];
      MaxCross := Max(MaxCross,
        WItems[Idx].FrozenCross
        + WItems[Idx].Input.MarginTop
        + WItems[Idx].Input.MarginBottom
      );
    end;

    if not SingleLine then
    begin
      Lines[I].CrossSize := MaxCross;
    end;
  end;

  // - Step 6: distribute the lines on the cross axis (align-content) -
  // wrap-reverse: reverse the order of the lines
  if Context.Wrap = fwWrapReverse then
  begin
    for I := 0 to (High(Lines) div 2) do
    begin
      var Tmp := Lines[I];
      Lines[I] := Lines[High(Lines) - I];
      Lines[High(Lines) - I] := Tmp;
    end;
  end;

  ResolveLineCrossSizes(Lines, CrossAvail, Context.RowGap, Context.AlignContent);

  // - Step 7 + 8: positioning for each line -
  for I := 0 to High(Lines) do
  begin
    PositionMainAxis(WItems, Lines[I], MainAvail, Context.ColumnGap,
                     Context.JustifyContent, Rev);
    PositionCrossAxis(WItems, Lines[I], Context.AlignItems);
  end;

  // Line index of each item (visual order, after any reversal)
  SetLength(LineOfItem, Length(WItems));

  for I := 0 to High(Lines) do
  begin
    for J := 0 to High(Lines[I].Items) do
    begin
      LineOfItem[Lines[I].Items[J]] := I;
    end;
  end;

  // - Step 9: build the results in the original order -
  SetLength(Results, Length(WItems));

  for I := 0 to High(WItems) do
  begin
    Idx := WItems[I].Input.OriginalIndex;
    Results[Idx].OriginalIndex := Idx;
    Results[Idx].BaseMain := WItems[I].HypotheticalMain;
    Results[Idx].LineIndex := LineOfItem[I];

    if Row then
    begin
      // direction = row: MainPos -> Left, CrossPos -> Top
      Results[Idx].Left   := WItems[I].MainPos;
      Results[Idx].Top    := WItems[I].CrossPos;
      Results[Idx].Width  := WItems[I].FrozenMain;
      Results[Idx].Height := WItems[I].FrozenCross;
    end
    else
    begin
      // direction = column: MainPos -> Top, CrossPos -> Left
      Results[Idx].Left   := WItems[I].CrossPos;
      Results[Idx].Top    := WItems[I].MainPos;
      Results[Idx].Width  := WItems[I].FrozenCross;
      Results[Idx].Height := WItems[I].FrozenMain;
    end;
  end;

  Result := Results;
end;

// ===========================================================================
// Measure - smallest size that does not crop the items
// ===========================================================================

class function TFlexEngine.MeasureExtent(const Context: TFlexContext;
  const Results: TArray<TFlexItemResult>; HorizontalAxis: Boolean): Single;
var
  LIndex: Integer;
begin
  Result := 0;

  for LIndex := 0 to High(Results) do
  begin
    if HorizontalAxis then
    begin
      Result := Max(Result, Results[LIndex].Left + Results[LIndex].Width +
        Context.Items[Results[LIndex].OriginalIndex].MarginRight);
    end
    else
    begin
      Result := Max(Result, Results[LIndex].Top + Results[LIndex].Height +
        Context.Items[Results[LIndex].OriginalIndex].MarginBottom);
    end;
  end;
end;

class function TFlexEngine.Measure(const Context: TFlexContext): TFlexContentSize;
var
  LCrossSize: Single;
  LIndex: Integer;
  LMinimumMain: Single;
  LProbe: TFlexContext;
  LResults: TArray<TFlexItemResult>;
begin
  Result.Width := 0;
  Result.Height := 0;

  if Length(Context.Items) = 0 then
    Exit;

  // The probes ignore how the free space is distributed: only the sizes count
  LProbe := Context;
  LProbe.JustifyContent := jcFlexStart;
  LProbe.AlignContent := acFlexStart;
  LProbe.SingleLineFillsContainer := False;

  if IsRow(Context.Direction) then
  begin
    LProbe.Direction := fdRow;

    // Width: with no space the items shrink as far as they can
    LProbe.AvailableWidth := 0;
    LProbe.AvailableHeight := 0;
    LResults := Calculate(LProbe);
    LMinimumMain := MeasureExtent(Context, LResults, True);

    // Height: the lines are those of the width that the container has
    LProbe.AvailableWidth := Max(LMinimumMain, Context.AvailableWidth);
    LResults := Calculate(LProbe);
    LCrossSize := MeasureExtent(Context, LResults, False);

    Result.Width := LMinimumMain;
    Result.Height := LCrossSize;
  end
  else
  begin
    LProbe.Direction := fdColumn;

    // The height is not limited: the items keep their size and never wrap
    LProbe.Wrap := fwNoWrap;
    LProbe.AvailableHeight := 0;

    for LIndex := 0 to High(LProbe.Items) do
      LProbe.Items[LIndex].FlexShrink := 0;

    LResults := Calculate(LProbe);
    Result.Height := MeasureExtent(Context, LResults, False);
    Result.Width := MeasureExtent(Context, LResults, True);
  end;
end;

end.
