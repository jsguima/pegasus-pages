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
    procedure MapPages(const AContentRoot: string; const Middlewares: TArray<TMiddleware>; Callback: TRouteCallback);
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
    function BuildHandler(const TemplatePath: string; const Layouts: TArray<string>;
      Page: IPage; Verb: TPageVerb; const Middlewares: TArray<TMiddleware>): THandler;
    function ResolveContentRoot(const AOverride: string): string;
  public
    procedure MapPages(const AContentRoot: string;
      const Middlewares: TArray<TMiddleware>; Callback: TRouteCallback);
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
  var SearchDir := ExcludeTrailingPathDelimiter(TPath.GetFullPath(ExePath));

  for var I := 1 to 6 do
  begin
    SearchDir := TPath.GetDirectoryName(SearchDir);

    if SearchDir = '' then
      Break;

    var Candidate: string;

    if AOverride <> '' then
      Candidate := TPath.Combine(SearchDir, AOverride)
    else
      Candidate := TPath.Combine(SearchDir, 'pages');

    if TDirectory.Exists(Candidate) then
      Exit(TPath.GetFullPath(Candidate));
  end;
  {$ENDIF}

  if AOverride <> '' then
    Result := TPath.GetFullPath(AOverride)
  else
    Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'pages');
end;

procedure TMapper.MapPages(const AContentRoot: string;
  const Middlewares: TArray<TMiddleware>; Callback: TRouteCallback);
begin
  var ContentRoot := ResolveContentRoot(AContentRoot);

  var ComponentsDir := TPath.Combine(ContentRoot, 'components');

  if TDirectory.Exists(ComponentsDir) then
    ComponentRegistry.Load(ComponentsDir);

  var PartialsDir := TPath.Combine(ContentRoot, 'partials');

  if TDirectory.Exists(PartialsDir) then
    PartialRegistry.Load(PartialsDir);

  ErrorPages.Load(ContentRoot);

  var Pages := Scanner().Scan(ContentRoot);

  for var Item in Pages do
  begin
    var Page: IPage;

    if PageRegistry.Find(Item.Route, 'GET', Page) then
      Callback(pvGet, Item.Route, BuildHandler(Item.FilePath, Item.Layouts, Page, pvGet, Middlewares));

    if PageRegistry.Find(Item.Route, 'POST', Page) then
      Callback(pvPost, Item.Route, BuildHandler(Item.FilePath, Item.Layouts, Page, pvPost, Middlewares));

    if PageRegistry.Find(Item.Route, 'PUT', Page) then
      Callback(pvPut, Item.Route, BuildHandler(Item.FilePath, Item.Layouts, Page, pvPut, Middlewares));

    if PageRegistry.Find(Item.Route, 'DELETE', Page) then
      Callback(pvDelete, Item.Route, BuildHandler(Item.FilePath, Item.Layouts, Page, pvDelete, Middlewares));

    Builder.Build(Item.FilePath);

    for var Layout in Item.Layouts do
      Builder.Build(Layout);
  end;
end;

procedure TMapper.MapStatic(const AContentRoot: string; Callback: TStaticCallback);

  function ResolveMimeType(const FilePath: string): string;
  begin
    var Ext := ExtractFileExt(FilePath).ToLower;

    if Ext = '.css' then Result := 'text/css; charset=utf-8'
    else if Ext = '.js' then Result := 'application/javascript; charset=utf-8'
    else if Ext = '.html' then Result := 'text/html; charset=utf-8'
    else if Ext = '.json' then Result := 'application/json; charset=utf-8'
    else if Ext = '.png' then Result := 'image/png'
    else if Ext = '.jpg' then Result := 'image/jpeg'
    else if Ext = '.jpeg' then Result := 'image/jpeg'
    else if Ext = '.gif' then Result := 'image/gif'
    else if Ext = '.svg' then Result := 'image/svg+xml'
    else if Ext = '.ico' then Result := 'image/x-icon'
    else if Ext = '.woff' then Result := 'font/woff'
    else if Ext = '.woff2' then Result := 'font/woff2'
    else if Ext = '.ttf' then Result := 'font/ttf'
    else if Ext = '.eot' then Result := 'application/vnd.ms-fontobject'
    else if Ext = '.webp' then Result := 'image/webp'
    else if Ext = '.mp4' then Result := 'video/mp4'
    else if Ext = '.webm' then Result := 'video/webm'
    else if Ext = '.pdf' then Result := 'application/pdf'
    else if Ext = '.xml' then Result := 'application/xml'
    else Result := 'application/octet-stream';
  end;

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

    var MimeType := ResolveMimeType(CanonicalPath);
    Callback(RelPath, CanonicalPath, MimeType);
  end;
end;

procedure ApplyPageResult(PR: TPageResult; Req: IRequest; Res: IResponse;
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

        var IsHtmx := Req.GetHeader('HX-Request') = 'true';
        var LayoutCount := Length(Layouts);

        if IsHtmx and (LayoutCount > 0) then
        begin
          Dec(LayoutCount);

          var HxTitle := PR.Data.Get('hx-title');

          if (not HxTitle.IsEmpty) and (HxTitle.AsString <> '') then
            Html := Html + '<title hx-swap-oob="true">' + HxTitle.AsString + '</title>';
        end;

        for var I := 0 to LayoutCount - 1 do
        begin
          var LayoutNodes := Builder.Build(Layouts[I]);
          var LayoutData := PageDataWithSlot(PR.Data, Html);
          Html := Renderer.Render(LayoutNodes, LayoutData);
        end;

        Res.SetStatus(PR.StatusCode);
        Res.SetHtml(Html);
      end;
    end;
  end;
end;

function WrapMiddleware(Mw: TMiddleware; NextStep: TMiddlewareProc;
  Req: IRequest; Res: IResponse): TMiddlewareProc;
begin
  Result := procedure
  begin
    Mw(Req, Res, NextStep);
  end;
end;

procedure RunPipeline(const Middlewares: TArray<TMiddleware>;
  Req: IRequest; Res: IResponse; CoreAction: TMiddlewareProc);
begin
  var Chain: TMiddlewareProc := CoreAction;

  for var I := High(Middlewares) downto Low(Middlewares) do
    Chain := WrapMiddleware(Middlewares[I], Chain, Req, Res);

  try
    Chain();
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
  const Layouts: TArray<string>; Page: IPage; Verb: TPageVerb;
  const Middlewares: TArray<TMiddleware>): THandler;
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

      ApplyPageResult(PageResult as TPageResult, Req, Res, TemplatePath, Layouts);
    end;

    RunPipeline(Middlewares, Req, Res, CoreAction);
  end;
end;

end.
