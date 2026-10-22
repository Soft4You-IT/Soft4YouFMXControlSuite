program S4YFlexBoxTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  Soft4You.FMX.Controls.FlexBox.Engine in '..\..\Sources\FlexBox\Soft4You.FMX.Controls.FlexBox.Engine.pas',
  Soft4You.FMX.Controls.FlexBox.Engine.Tests in 'Soft4You.FMX.Controls.FlexBox.Engine.Tests.pas';

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