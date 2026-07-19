unit Page.About;

interface

uses
  Pegasus.Http.Page,
  Pegasus.Http.Request,
  Pegasus.Http.PageResult;

type
  TAboutPage = class(TPage)
  public
    function OnGet(Request: IRequest): IPageResult; override;
  end;

implementation

uses
  Pegasus.Routing.Registry;

{ TAboutPage }

function TAboutPage.OnGet(Request: IRequest): IPageResult;
begin
  Result := PageResult
    .Page
      .Add('header', 'About')
      .Add('HX-Title', 'About - Pegasus Pages')
    .Render;
end;

initialization
  PageRegistry.Add('/about', TAboutPage.Create);

end.
