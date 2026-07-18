unit Page.Home;

interface

uses
  Pegasus.Http.Page,
  Pegasus.Http.Request,
  Pegasus.Http.PageResult;

type
  THomePage = class(TPage)
  public
    function OnGet(Request: IRequest): IPageResult; override;
  end;

implementation

uses
  Pegasus.Routing.Registry;

{ THomePage }

function THomePage.OnGet(Request: IRequest): IPageResult;
begin
  Result := PageResult
    .Page
      .Add('title', 'Welcome')
      .Add('message', 'Hello from Pegasus Pages!')
    .Render;
end;

initialization
  PageRegistry.Add('/', THomePage.Create);

end.
