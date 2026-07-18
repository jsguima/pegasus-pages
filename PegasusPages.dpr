program PegasusPages;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Pegasus.Pages in 'src\Pegasus.Pages.pas',
  Pegasus.Http.Callback in 'src\http\Pegasus.Http.Callback.pas',
  Pegasus.Http.ErrorPages in 'src\http\Pegasus.Http.ErrorPages.pas',
  Pegasus.Http.Middleware in 'src\http\Pegasus.Http.Middleware.pas',
  Pegasus.Http.Page in 'src\http\Pegasus.Http.Page.pas',
  Pegasus.Http.PageResult in 'src\http\Pegasus.Http.PageResult.pas',
  Pegasus.Http.Request in 'src\http\Pegasus.Http.Request.pas',
  Pegasus.Http.Response in 'src\http\Pegasus.Http.Response.pas',
  Pegasus.Engine.Builder in 'src\engine\Pegasus.Engine.Builder.pas',
  Pegasus.Engine.Cache in 'src\engine\Pegasus.Engine.Cache.pas',
  Pegasus.Engine.Lexer in 'src\engine\Pegasus.Engine.Lexer.pas',
  Pegasus.Engine.Nodes in 'src\engine\Pegasus.Engine.Nodes.pas',
  Pegasus.Engine.Parser in 'src\engine\Pegasus.Engine.Parser.pas',
  Pegasus.Engine.Renderer in 'src\engine\Pegasus.Engine.Renderer.pas',
  Pegasus.Engine.Resolver in 'src\engine\Pegasus.Engine.Resolver.pas',
  Pegasus.UI.Components in 'src\ui\Pegasus.UI.Components.pas',
  Pegasus.UI.Filters in 'src\ui\Pegasus.UI.Filters.pas',
  Pegasus.UI.Partials in 'src\ui\Pegasus.UI.Partials.pas',
  Pegasus.Routing.Mapper in 'src\routing\Pegasus.Routing.Mapper.pas',
  Pegasus.Routing.Registry in 'src\routing\Pegasus.Routing.Registry.pas',
  Pegasus.Routing.Scanner in 'src\routing\Pegasus.Routing.Scanner.pas',
  Pegasus.Security.Encoder in 'src\security\Pegasus.Security.Encoder.pas',
  Pegasus.Security.SecureRandom in 'src\security\Pegasus.Security.SecureRandom.pas',
  Pegasus.Data.Page in 'src\data\Pegasus.Data.Page.pas',
  Pegasus.Data.RttiCache in 'src\data\Pegasus.Data.RttiCache.pas';

begin
  // This project is for library compilation/validation only.
  // See samples/horse/ for a working usage example.
end.
