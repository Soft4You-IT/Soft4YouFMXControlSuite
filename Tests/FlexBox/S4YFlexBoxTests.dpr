program S4YFlexBoxTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  Soft4You.FMX.Controls.FlexBox.Engine in '..\..\Sources\FlexBox\Soft4You.FMX.Controls.FlexBox.Engine.pas',
  Soft4You.FMX.Controls.FlexBox.Engine.Tests in 'Soft4You.FMX.Controls.FlexBox.Engine.Tests.pas',
  Soft4You.FMX.Controls.FlexBox.Breakpoints in '..\..\Sources\FlexBox\Soft4You.FMX.Controls.FlexBox.Breakpoints.pas',
  Soft4You.FMX.Controls.FlexBox.ItemBase in '..\..\Sources\FlexBox\Soft4You.FMX.Controls.FlexBox.ItemBase.pas',
  Soft4You.FMX.Controls.FlexBox.SizeConstraints in '..\..\Sources\FlexBox\Soft4You.FMX.Controls.FlexBox.SizeConstraints.pas',
  Soft4You.FMX.Controls.FlexBox.Strings in '..\..\Sources\FlexBox\Soft4You.FMX.Controls.FlexBox.Strings.pas',
  Soft4You.FMX.Controls.FlexBox.Types in '..\..\Sources\FlexBox\Soft4You.FMX.Controls.FlexBox.Types.pas',
  Soft4You.FMX.Controls.FlexBox in '..\..\Sources\FlexBox\Soft4You.FMX.Controls.FlexBox.pas',
  Soft4You.FMX.Controls.FlexBox.Streaming.Tests in 'Soft4You.FMX.Controls.FlexBox.Streaming.Tests.pas',
  Soft4You.FMX.Controls.FlexBox.Item.Tests in 'Soft4You.FMX.Controls.FlexBox.Item.Tests.pas',
  Soft4You.FMX.Controls.FlexBox.AutoSize.Tests in 'Soft4You.FMX.Controls.FlexBox.AutoSize.Tests.pas';

var
  LRunner: ITestRunner;
  LResults: IRunResults;
  LLogger: ITestLogger;
begin
  try
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LLogger := TDUnitXConsoleLogger.Create(True);
    LRunner.AddLogger(LLogger);
    LRunner.FailsOnNoAsserts := False;
    LResults := LRunner.Execute;

    if not LResults.AllPassed then
    begin
      System.ExitCode := EXIT_ERRORS;
    end;

    // Keeps the window open when the tests run from the IDE
    if DebugHook <> 0 then
    begin
      System.Write('Done. Press Enter to exit.');
      System.Readln;
    end;
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;
end.