unit Pegasus.Routing.Mapper;

interface

uses
  Pegasus.Http.Callback,
  Pegasus.Http.Page,
  Pegasus.Http.Request,
  Pegasus.Http.Response,
  Pegasus.Http.Middleware,
  Pegasus.Routing.Scanner,
  Pegasus.Routing.Registry,
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows;

type
  IMapper = interface
  ['{15C5C781-F3AA-4AEF-84D8-455BDBA069BB}']
    procedure MapPages(const AContentRoot: string; Callback: TRouteCallback);
    procedure MapStatic(const AContentRoot: string; Callback: TStaticCallback);
  end;

  function Mapper(): IMapper;

implementation

uses
  Pegasus.Engine.Builder,
  Pegasus.UI.Components,
  Pegasus.Data.Page,
  Pegasus.Http.ErrorPages,
  Pegasus.Http.PageResult,
  Pegasus.UI.Partials,
  Pegasus.Engine.Renderer;

type
  TMapper = class(TInterfacedObject, IMapper)
  private
    function BuildHandler(const TemplatePath: string; const Layouts: TArray<string>; Page: IPage; Verb: TPageVerb): THandler;
    function ResolveContentRoot(const AOverride: string): string;
  public
    procedure MapPages(const AContentRoot: string; Callback: TRouteCallback);
    procedure MapStatic(const AContentRoot: string; Callback: TStaticCallback);
  end;

{ Public accessors }
function Mapper(): IMapper;
begin
  Result := TMapper.Create;
end;

{ TMapper }

function TMapper.ResolveContentRoot(const AOverride: string): string;
begin
  if (AOverride <> '') and TDirectory.Exists(AOverride) then
    Exit(TPath.GetFullPath(AOverride));

  {$IFDEF DEBUG}
  var ExePath := ExtractFilePath(ParamStr(0));
  var ProjectRoot := TPath.GetFullPath(TPath.Combine(ExePath, '..\..'));
  var DevPath := TPath.Combine(ProjectRoot, 'pages');

  if TDirectory.Exists(DevPath) then
    Exit(DevPath);
  {$ENDIF}

  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'pages');
end;

procedure TMapper.MapPages(const AContentRoot: string; Callback: TRouteCallback);
begin
  var ContentRoot := ResolveContentRoot(AContentRoot);

  var ComponentsDir := TPath.Combine(ContentRoot, 'components');

  if TDirectory.Exists(ComponentsDir) then
    ComponentRegistry.Load(ComponentsDir);

  var PartialsDir := TPath.Combine(ContentRoot, 'partials');

  if TDirectory.Exists(PartialsDir) then
    PartialRegistry.Load(PartialsDir);

  ErrorPages.Load(ContentRoot);

  var Pages := TScanner.New().Scan(ContentRoot);

  for var Item in Pages do
  begin
    var Page: IPage;

    if PageRegistry.Find(Item.Route, 'GET', Page) then
      Callback(pvGet, Item.Route, BuildHandler(Item.FilePath, Item.Layouts, Page, pvGet));

    if PageRegistry.Find(Item.Route, 'POST', Page) then
      Callback(pvPost, Item.Route, BuildHandler(Item.FilePath, Item.Layouts, Page, pvPost));

    if PageRegistry.Find(Item.Route, 'PUT', Page) then
      Callback(pvPut, Item.Route, BuildHandler(Item.FilePath, Item.Layouts, Page, pvPut));

    if PageRegistry.Find(Item.Route, 'DELETE', Page) then
      Callback(pvDelete, Item.Route, BuildHandler(Item.FilePath, Item.Layouts, Page, pvDelete));

    Builder.Build(Item.FilePath);

    for var Layout in Item.Layouts do
      Builder.Build(Layout);
  end;
end;

procedure TMapper.MapStatic(const AContentRoot: string; Callback: TStaticCallback);
begin
  var ContentRoot := ResolveContentRoot(AContentRoot);
  var StaticDir := TPath.GetFullPath(TPath.Combine(ContentRoot, 'static'));

  if not TDirectory.Exists(StaticDir) then
    Exit;

  var SafeRoot := StaticDir.TrimRight(['\', '/']) + '\';

  for var F in TDirectory.GetFiles(StaticDir, '*', TSearchOption.soAllDirectories) do
  begin
    var CanonicalPath := TPath.GetFullPath(F);

    if not CanonicalPath.StartsWith(SafeRoot, True) then
      Continue;

    var RelPath := CanonicalPath.Substring(SafeRoot.Length - 1).Replace('\', '/');

    if not RelPath.StartsWith('/') then
      RelPath := '/' + RelPath;

    Callback(RelPath, CanonicalPath);
  end;
end;

procedure ApplyPageResult(PR: TPageResult; Res: IResponse;
  const TemplatePath: string; const Layouts: TArray<string>);
begin
  case PR.Kind of
    prkRedirect:
    begin
      Res.SetStatus(PR.StatusCode);
      Res.AddHeader('Location', PR.RedirectUrl);
    end;

    prkJson:
    begin
      Res.SetStatus(PR.StatusCode);
      Res.SetContentType('application/json; charset=utf-8');
      Res.SetHtml(PR.Body);
    end;

    prkStatus:
    begin
      Res.SetStatus(PR.StatusCode);
      Res.SetHtml(PR.Body);
    end;

    prkRender:
    begin
      if PR.Data.HasStream then
      begin
        Res.SendStream(PR.Data.GetStream, PR.Data.GetStreamFileName);
        Res.SetContentType(PR.Data.GetStreamContentType);
      end
      else
      begin
        var Nodes := Builder.Build(TemplatePath);
        var Html := Renderer.Render(Nodes, PR.Data);

        for var Layout in Layouts do
        begin
          var LayoutNodes := Builder.Build(Layout);
          var LayoutData := PageData();
          LayoutData.Writer.SetSlot(Html, True);
          Html := Renderer.Render(LayoutNodes, LayoutData.Reader);
        end;

        Res.SetStatus(PR.StatusCode);
        Res.SetHtml(Html);
      end;
    end;
  end;
end;

procedure RunPipeline(Req: IRequest; Res: IResponse; CoreAction: TMiddlewareProc);
begin
  var WithCsrf: TMiddlewareProc := procedure
  begin
    TMiddlewares.Csrf()(Req, Res, CoreAction);
  end;

  var WithHeaders: TMiddlewareProc := procedure
  begin
    TMiddlewares.SecureHeaders()(Req, Res, WithCsrf);
  end;

  try
    TMiddlewares.Timeout()(Req, Res, WithHeaders);
  except
    on E: ERequestTimeout do
    begin
      Res.SetStatus(503);
      Res.SetHtml(ErrorPages.Get500('Request processing timeout exceeded'));
    end;
    on E: Exception do
    begin
      Res.SetStatus(500);
      Res.SetHtml(ErrorPages.Get500(E.Message));
    end;
  end;
end;

function TMapper.BuildHandler(const TemplatePath: string;
  const Layouts: TArray<string>; Page: IPage; Verb: TPageVerb): THandler;
begin
  Result := function(Req: IRequest): IResponse
  var
    Res: IResponse;
    CoreAction: TMiddlewareProc;
  begin
    Res := TResponse.Create;
    Result := Res;

    CoreAction := procedure
    begin
      var PageResult: IPageResult;

      case Verb of
        pvGet: PageResult := Page.OnGet(Req);
        pvPost: PageResult := Page.OnPost(Req);
        pvPut: PageResult := Page.OnPut(Req);
        pvDelete: PageResult := Page.OnDelete(Req);
      end;

      if PageResult = nil then
      begin
        Res.SetStatus(405);
        Res.SetHtml('Method Not Allowed');
        Exit;
      end;

      ApplyPageResult(PageResult as TPageResult, Res, TemplatePath, Layouts);
    end;

    RunPipeline(Req, Res, CoreAction);
  end;
end;

end.
