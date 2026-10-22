# Analysis: filtering the children in TS4YFlexBox.BuildContext

> Note: historical analysis. Since `TS4YFlexItem` was introduced the flexbox only positions the items (`TS4YFlexBox.IsFlexChild`); the filters described here are still valid for `Visible`, `csLoading` and `csDestroying`, while the check on `Align` is no longer needed because the controls live inside the items.

## The problem in detail

In FMX the visual hierarchy is split into **two distinct levels**:

```
TFmxObject.Children[]      → RAW list of all the children of the FMX object
TControl.Controls[]        → filtered subset: only the direct TControls
```

`Controls[]` is already a filter compared to `Children[]` (it excludes the
`TFmxObject`s that are not a `TControl`), but it is **not enough** for our purpose.
There are at least three categories of children that `Controls[]` includes and
that TS4YFlexBox must NOT lay out:

---

## Category 1 — Style objects (csSubComponent)

The `TStyledControl`s (TButton, TEdit, TPanel, ...) create a tree of "style
objects" at run time and add it as a direct child. These objects have
`csSubComponent` in `ComponentStyle` and/or `StyleName <> ''`.

```
TButton (our flex child)
  └── TRectangle  [style]       ← Controls[0] of the TButton, but also Controls[?] of ours?
```

**In fact**: the style objects are added as children of the TStyledControl itself,
not of our TS4YFlexBox. So `Controls[]` of TS4YFlexBox **does not see them
directly**. This problem only concerns DIRECT children with `csSubComponent` set
by us, which in this case do not exist. ✅ It does not concern us.

---

## Category 2 — TAnimation, TEffect and other TFmxObjects that are not a TControl

When a `TFloatAnimation` or a `TEffect` is added to a child, these objects are
added to `Children[]` of the child, not of the TS4YFlexBox. `Controls[]` already
filters the non-TControls. ✅ It does not concern us.

---

## Category 3 — The REAL problem: children with Align <> alNone

This is the case that matters. FMX manages the children in two ways:

1. **Align = alNone**: free position, managed by us through `SetBounds`
2. **Align <> alNone** (Top, Bottom, Client, ...): position managed by FMX itself
   through its native alignment system

If a child has `Align = TAlignLayout.Client`, FMX positions it. If TS4YFlexBox
then calls `SetBounds` on it, the two systems step on each other's toes and the
control bounces endlessly between the two positions.

**Solution already present in our code:**
```pascal
if Child.Align <> TAlignLayout.None then Continue;
```
This correctly excludes the children "managed by FMX". ✅ Already correct.

---

## Category 4 — The REAL problem #2: ControlsCount vs Children during DoRealign

`ControlsCount` and `Controls[]` return the children **at the time of the call**.
During `DoRealign`, FMX may still be building the tree (for example while loading
the DFM). The risk is iterating over a list that is being modified.

**Fix**: a snapshot of the list of children at the beginning of `BuildContext`,
before any operation that could modify it.

---

## Category 5 — The REAL problem #3: OriginalIndex is not the index in Controls[]

In the current code, `Input.OriginalIndex := I` uses `I` as the index in the loop,
but this index **skips** the filtered children (invisible, Align <> None). So
`OriginalIndex` no longer matches the index in `Controls[]`.

In `ApplyResults` we then do `Controls[R.OriginalIndex]`, which points to the
WRONG control if there are holes in the sequence.

**This is the most insidious and silent bug of the current implementation.**

### Example of the bug:
```
Controls[0] = Button1   (Align=Top    → skipped)
Controls[1] = Button2   (Align=None   → included, OriginalIndex=0 ← WRONG)
Controls[2] = Button3   (invisible    → skipped)
Controls[3] = Button4   (Align=None   → included, OriginalIndex=1 ← WRONG)
```
`ApplyResults` writes to `Controls[0]` (Button1) instead of `Controls[1]`
(Button2).

---

## The fix

The correct solution is to use a **direct reference to the TControl** instead of
the index. We build a parallel array `FlexChildren: TArray<TControl>` that
contains exactly the children that take part in the layout, in the same order as
the `Items` of the `TFlexContext`.

`OriginalIndex` then becomes the index in `FlexChildren[]`, not in `Controls[]`.

```pascal
// BuildContext also returns the participating children
function BuildContext(out FlexChildren: TArray<TControl>): TFlexContext;

// ApplyResults uses the references directly
procedure ApplyResults(const Results: TArray<TFlexItemResult>;
                       const FlexChildren: TArray<TControl>);
```

In `ApplyResults`:
```pascal
// Before (WRONG):
Child := TControl(Controls[R.OriginalIndex]);

// After (CORRECT):
Child := FlexChildren[R.OriginalIndex];
```

`OriginalIndex` is the index in `FlexChildren`, which is a compact array without
holes, built at the same moment and with the same filters as `BuildContext`.

---

## Secondary fix: invisibility during the layout

A child can become invisible *while* we are in `DoRealign` (rare but possible in
animations). We must also defend ourselves against `nil` in the array:

```pascal
if (R.OriginalIndex < 0) or (R.OriginalIndex > High(FlexChildren)) then Continue;
Child := FlexChildren[R.OriginalIndex];
if (Child = nil) or not Child.Visible then Continue;
```

---

## Summary of the filters to apply in BuildContext

A child takes part in the FlexBox layout if and only if:

```pascal
function IsFlexChild(Child: TControl): Boolean;
begin
  Result :=
    Assigned(Child)                              and  // not nil
    Child.Visible                                and  // visible
    (Child.Align = TAlignLayout.None)            and  // not managed by FMX
    not (csDestroying in Child.ComponentState)   and  // not being destroyed
    not (csLoading in Child.ComponentState);          // not loaded yet
end;
```

The `csLoading` check is important: while the DFM is loading, the children are
added one at a time. If `DoRealign` is called while the DFM has not been fully
read yet, some children do not have the correct size yet. The solution is also to
check `csLoading in ComponentState` of the TS4YFlexBox itself:

```pascal
procedure TS4YFlexBox.DoRealign;
begin
  if FInLayout > 0 then Exit;
  if csLoading in ComponentState then Exit;   // ← added
  if csDestroying in ComponentState then Exit; // ← added
  ...
end;
```
