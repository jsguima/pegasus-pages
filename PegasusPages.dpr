program PegasusPages;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Pegasus.Pages in 'src\pegasus\Pegasus.Pages.pas',
  Pegasus.Http.Callback in 'src\pegasus\http\Pegasus.Http.Callback.pas',
  Pegasus.Http.ErrorPages in 'src\pegasus\http\Pegasus.Http.ErrorPages.pas',
  Pegasus.Http.Middleware in 'src\pegasus\http\Pegasus.Http.Middleware.pas',
  Pegasus.Http.Page in 'src\pegasus\http\Pegasus.Http.Page.pas',
  Pegasus.Http.PageResult in 'src\pegasus\http\Pegasus.Http.PageResult.pas',
  Pegasus.Http.Request in 'src\pegasus\http\Pegasus.Http.Request.pas',
  Pegasus.Http.Response in 'src\pegasus\http\Pegasus.Http.Response.pas',
  Pegasus.Engine.Builder in 'src\pegasus\engine\Pegasus.Engine.Builder.pas',
  Pegasus.Engine.Cache in 'src\pegasus\engine\Pegasus.Engine.Cache.pas',
  Pegasus.Engine.Lexer in 'src\pegasus\engine\Pegasus.Engine.Lexer.pas',
  Pegasus.Engine.Nodes in 'src\pegasus\engine\Pegasus.Engine.Nodes.pas',
  Pegasus.Engine.Parser in 'src\pegasus\engine\Pegasus.Engine.Parser.pas',
  Pegasus.Engine.Renderer in 'src\pegasus\engine\Pegasus.Engine.Renderer.pas',
  Pegasus.Engine.Resolver in 'src\pegasus\engine\Pegasus.Engine.Resolver.pas',
  Pegasus.UI.Components in 'src\pegasus\ui\Pegasus.UI.Components.pas',
  Pegasus.UI.Filters in 'src\pegasus\ui\Pegasus.UI.Filters.pas',
  Pegasus.UI.Partials in 'src\pegasus\ui\Pegasus.UI.Partials.pas',
  Pegasus.Routing.Mapper in 'src\pegasus\routing\Pegasus.Routing.Mapper.pas',
  Pegasus.Routing.Registry in 'src\pegasus\routing\Pegasus.Routing.Registry.pas',
  Pegasus.Routing.Scanner in 'src\pegasus\routing\Pegasus.Routing.Scanner.pas',
  Pegasus.Security.Encoder in 'src\pegasus\security\Pegasus.Security.Encoder.pas',
  Pegasus.Security.SecureRandom in 'src\pegasus\security\Pegasus.Security.SecureRandom.pas',
  Pegasus.Data.Page in 'src\pegasus\data\Pegasus.Data.Page.pas',
  Pegasus.Data.RttiCache in 'src\pegasus\data\Pegasus.Data.RttiCache.pas';

begin
  // This project is for library compilation/validation only.
  // See samples/horse/ for a working usage example.
end.
