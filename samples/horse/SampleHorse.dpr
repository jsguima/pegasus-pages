program SampleHorse;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  Horse,
  Horse.Callback,
  Pegasus.Pages,
  Pegasus.Http.Callback,
  Pegasus.Http.Page,
  Pegasus.Http.Request,
  Pegasus.Http.PageResult,
  Pegasus.Http.Middleware,
  Pegasus.Adapters.Horse in 'src\adapter\Pegasus.Adapters.Horse.pas',
  Page.Home in 'src\pages\Page.Home.pas',
  Page.About in 'src\pages\about\Page.About.pas',
  Page.Contact in 'src\pages\contact\Page.Contact.pas';

procedure Start;
begin
  PegasusPages()
    .ContentRoot('src\pages')
    .UseMiddleware(TMiddlewares.SecureHeaders(nil, ['https://cdn.jsdelivr.net']))
    .UseMiddleware(TMiddlewares.Csrf())
    .UseMiddleware(TMiddlewares.Timeout())
    .MapStatic(
      procedure(const Route, FilePath, ContentType: string)
      begin
        Writeln('Static: ', Route, ' -> ', FilePath);
        THorse.Get(Route,
          procedure(Req: THorseRequest; Res: THorseResponse)
          begin
            Res.RawWebResponse.ContentType := ContentType;
            Res.Send(TFile.ReadAllText(FilePath, TEncoding.UTF8));
          end
        );
      end
    )
    .MapPages(
      procedure(Verb: TPageVerb; const Route: string; Handler: THandler)
      begin
        var Callback: THorseCallbackRequestResponse :=
          procedure(Req: THorseRequest; Res: THorseResponse)
          begin
            var Response := Handler(THorseRequestAdapter.New(Req));

            for var I := 0 to Response.GetHeaders.Count - 1 do
              Res.AddHeader(Response.GetHeaders.Names[I], Response.GetHeaders.ValueFromIndex[I]);

            if Response.IsStream then
              Res.SendFile(Response.GetStream, Response.GetStreamFileName)
            else
              Res.Status(Response.GetStatusCode).Send(Response.GetHtml);
          end;

        case Verb of
          pvGet: THorse.Get(Route, Callback);
          pvPost: THorse.Post(Route, Callback);
          pvPut: THorse.Put(Route, Callback);
          pvDelete: THorse.Delete(Route, Callback);
        end;
      end
    );

  THorse.Listen(9000, procedure
  begin
    Writeln(Format('Server running on %s:%d', [THorse.Host, THorse.Port]));
  end);
end;

begin
  try
    Start;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Writeln('Press ENTER to exit...');
      ReadLn;
    end;
  end;
end.
