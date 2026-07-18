program PegasusPagesTest;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,

  // Security
  Pegasus.Security.Encoder.Test in 'src\security\Pegasus.Security.Encoder.Test.pas',
  Pegasus.Security.SecureRandom.Test in 'src\security\Pegasus.Security.SecureRandom.Test.pas',

  // Data
  Pegasus.Data.Page.Test in 'src\data\Pegasus.Data.Page.Test.pas',
  Pegasus.Data.RttiCache.Test in 'src\data\Pegasus.Data.RttiCache.Test.pas',

  // Http
  Pegasus.Http.Response.Test in 'src\http\Pegasus.Http.Response.Test.pas',
  Pegasus.Http.PageResult.Test in 'src\http\Pegasus.Http.PageResult.Test.pas',
  Pegasus.Http.Middleware.Test in 'src\http\Pegasus.Http.Middleware.Test.pas',
  Pegasus.Http.ErrorPages.Test in 'src\http\Pegasus.Http.ErrorPages.Test.pas',
  Pegasus.Http.Page.Test in 'src\http\Pegasus.Http.Page.Test.pas',

  // Engine
  Pegasus.Engine.Lexer.Test in 'src\engine\Pegasus.Engine.Lexer.Test.pas',
  Pegasus.Engine.Parser.Test in 'src\engine\Pegasus.Engine.Parser.Test.pas',
  Pegasus.Engine.Resolver.Test in 'src\engine\Pegasus.Engine.Resolver.Test.pas',
  Pegasus.Engine.Cache.Test in 'src\engine\Pegasus.Engine.Cache.Test.pas',
  Pegasus.Engine.Builder.Test in 'src\engine\Pegasus.Engine.Builder.Test.pas',
  Pegasus.Engine.Renderer.Test in 'src\engine\Pegasus.Engine.Renderer.Test.pas',

  // UI
  Pegasus.UI.Filters.Test in 'src\ui\Pegasus.UI.Filters.Test.pas',
  Pegasus.UI.Components.Test in 'src\ui\Pegasus.UI.Components.Test.pas',
  Pegasus.UI.Partials.Test in 'src\ui\Pegasus.UI.Partials.Test.pas',

  // Routing
  Pegasus.Routing.Scanner.Test in 'src\routing\Pegasus.Routing.Scanner.Test.pas',
  Pegasus.Routing.Registry.Test in 'src\routing\Pegasus.Routing.Registry.Test.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    System.Write('Done.. press <Enter> key to quit.');
    System.Readln;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
