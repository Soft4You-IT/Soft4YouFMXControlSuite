unit Soft4You.FMX.Controls.FlexBox.Streaming.Tests;

{
  DUnitX tests for the saving and loading of TS4YFlexItem, the way the form
  designer does it: a property is written to the form file only when its
  value is not the default one.

  Run with: DUnitX console runner or IDE Test Runner.
}

interface

uses
  DUnitX.TestFramework,
  Soft4You.FMX.Controls.FlexBox;

type
  [TestFixture]
  TFlexItemStreamingTests = class
  private
    // Helper: creates an item with a content control inside the flexbox
    function CreateItem(const ABox: TS4YFlexBox): TS4YFlexItem;

    // Helper: loads a new item from the saved state of another one
    function LoadCopy(const AItem: TS4YFlexItem): TS4YFlexItem;

    // Helper: saved state of an item, in the text format of the form files
    function SaveAsText(const AItem: TS4YFlexItem): string;
  public
    [Test] procedure Test_FlexShrink_Zero_SurvivesSaveAndLoad;
    [Test] procedure Test_FlexShrink_Default_IsNotSaved;
    [Test] procedure Test_FitContent_Default_IsTrue;
    [Test] procedure Test_FitContent_False_SurvivesSaveAndLoad;
    [Test] procedure Test_FitContent_Default_IsNotSaved;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  FMX.Objects;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function TFlexItemStreamingTests.CreateItem(const ABox: TS4YFlexBox): TS4YFlexItem;
var
  LContent: TRectangle;
begin
  Result := TS4YFlexItem.Create(nil);
  Result.Name := 'Item';
  Result.Parent := ABox;

  LContent := TRectangle.Create(nil);
  LContent.Name := 'Content';
  LContent.Parent := Result;
end;

function TFlexItemStreamingTests.SaveAsText(const AItem: TS4YFlexItem): string;
var
  LBinary: TMemoryStream;
  LText: TStringStream;
begin
  LBinary := TMemoryStream.Create;
  try
    LText := TStringStream.Create;
    try
      LBinary.WriteComponent(AItem);
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

function TFlexItemStreamingTests.LoadCopy(const AItem: TS4YFlexItem): TS4YFlexItem;
var
  LBinary: TMemoryStream;
begin
  LBinary := TMemoryStream.Create;
  try
    LBinary.WriteComponent(AItem);
    LBinary.Position := 0;
    Result := TS4YFlexItem.Create(nil);
    LBinary.ReadComponent(Result);
  finally
    LBinary.Free;
  end;
end;

// ===========================================================================
// FlexShrink
// ===========================================================================

procedure TFlexItemStreamingTests.Test_FlexShrink_Zero_SurvivesSaveAndLoad;

// The streaming of Delphi does not write a float that is 0 unless the property
// declares its default: a FlexShrink of 0 must not come back as 1
var LBox: TS4YFlexBox; LItem, LLoaded: TS4YFlexItem;
begin
  LBox := TS4YFlexBox.Create(nil);
  try
    LItem := CreateItem(LBox);
    LItem.FlexShrink := 0;

    LLoaded := LoadCopy(LItem);
    try
      Assert.AreEqual(Single(0), LLoaded.FlexShrink, 'FlexShrink');
    finally
      LLoaded.Free;
    end;
  finally
    LBox.Free;
  end;
end;

procedure TFlexItemStreamingTests.Test_FlexShrink_Default_IsNotSaved;
var LBox: TS4YFlexBox; LItem: TS4YFlexItem;
begin
  LBox := TS4YFlexBox.Create(nil);
  try
    LItem := CreateItem(LBox);

    Assert.AreEqual(0, Pos('FlexShrink', SaveAsText(LItem)), 'FlexShrink in the saved state');
  finally
    LBox.Free;
  end;
end;

// ===========================================================================
// FitContent
// ===========================================================================

procedure TFlexItemStreamingTests.Test_FitContent_Default_IsTrue;
var LItem: TS4YFlexItem;
begin
  LItem := TS4YFlexItem.Create(nil);
  try
    Assert.IsTrue(LItem.FitContent, 'FitContent');
  finally
    LItem.Free;
  end;
end;

procedure TFlexItemStreamingTests.Test_FitContent_False_SurvivesSaveAndLoad;
var LBox: TS4YFlexBox; LItem, LLoaded: TS4YFlexItem;
begin
  LBox := TS4YFlexBox.Create(nil);
  try
    LItem := CreateItem(LBox);
    LItem.FitContent := False;

    LLoaded := LoadCopy(LItem);
    try
      Assert.IsFalse(LLoaded.FitContent, 'FitContent');
    finally
      LLoaded.Free;
    end;
  finally
    LBox.Free;
  end;
end;

procedure TFlexItemStreamingTests.Test_FitContent_Default_IsNotSaved;
var LBox: TS4YFlexBox; LItem: TS4YFlexItem;
begin
  LBox := TS4YFlexBox.Create(nil);
  try
    LItem := CreateItem(LBox);

    Assert.AreEqual(0, Pos('FitContent', SaveAsText(LItem)), 'FitContent in the saved state');
  finally
    LBox.Free;
  end;
end;

initialization
  RegisterClasses([TS4YFlexItem, TRectangle]);
  TDUnitX.RegisterTestFixture(TFlexItemStreamingTests);

end.
