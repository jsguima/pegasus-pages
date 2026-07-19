unit Page.Contact;

interface

uses
  Pegasus.Http.Page,
  Pegasus.Http.Request,
  Pegasus.Http.PageResult;

type
  TContactPage = class(TPage)
  public
    function OnGet(Request: IRequest): IPageResult; override;
    function OnPost(Request: IRequest): IPageResult; override;
  end;

implementation

uses
  Pegasus.Routing.Registry,
  Pegasus.Http.Middleware;

{ TContactPage }

function TContactPage.OnGet(Request: IRequest): IPageResult;
begin
  Result := PageResult
    .Page
      .Add('header', 'Contact')
      .Add('csrf', GetCsrfToken)
      .Add('HX-Title', 'Contact - Pegasus Pages')
    .Render;
end;

function TContactPage.OnPost(Request: IRequest): IPageResult;
begin
  // In a real app, process the form data here
  Result := PageResult.Redirect('/');
end;

initialization
  PageRegistry.Add('/contact', TContactPage.Create);

end.
