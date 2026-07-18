unit Pegasus.Http.Page.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Pegasus.Http.Page,
  Pegasus.Http.Request,
  Pegasus.Http.PageResult;

type
  [TestFixture]
  TPageBaseTest = class
  public
    [Test]
    procedure OnGet_padrao_deve_levantar_ENotImplemented;

    [Test]
    procedure OnPost_padrao_deve_levantar_ENotImplemented;

    [Test]
    procedure OnPut_padrao_deve_levantar_ENotImplemented;

    [Test]
    procedure OnDelete_padrao_deve_levantar_ENotImplemented;

    [Test]
    procedure Deve_implementar_interface_IPage;

    [Test]
    procedure Classe_derivada_pode_sobrescrever_OnGet;

    [Test]
    procedure Classe_derivada_pode_sobrescrever_OnPost;
  end;

implementation

uses
  System.Generics.Collections;

type
  TMockReq = class(TInterfacedObject, IRequest)
  public
    function GetContentType: string;
    function GetCookie(const Name: string): string;
    function GetFormParam(const Name: string): string;
    function GetHeader(const Name: string): string;
    function GetMethod: string;
    function GetPath: string;
    function GetQueryParam(const Name: string): string;
    function GetRawBody: string;
    function GetRouteParam(const Name: string): string;
    procedure SetRouteParam(const Name, Value: string);
  end;

  TMyPage = class(TPage)
  public
    function OnGet(Request: IRequest): IPageResult; override;
    function OnPost(Request: IRequest): IPageResult; override;
  end;

{ TMockReq }

function TMockReq.GetContentType: string; begin Result := ''; end;
function TMockReq.GetCookie(const Name: string): string; begin Result := ''; end;
function TMockReq.GetFormParam(const Name: string): string; begin Result := ''; end;
function TMockReq.GetHeader(const Name: string): string; begin Result := ''; end;
function TMockReq.GetMethod: string; begin Result := 'GET'; end;
function TMockReq.GetPath: string; begin Result := '/'; end;
function TMockReq.GetQueryParam(const Name: string): string; begin Result := ''; end;
function TMockReq.GetRawBody: string; begin Result := ''; end;
function TMockReq.GetRouteParam(const Name: string): string; begin Result := ''; end;
procedure TMockReq.SetRouteParam(const Name, Value: string); begin end;

{ TMyPage }

function TMyPage.OnGet(Request: IRequest): IPageResult;
begin
  Result := PageResult.Page().Add('msg', 'Hello').Render;
end;

function TMyPage.OnPost(Request: IRequest): IPageResult;
begin
  Result := PageResult.Redirect('/success');
end;

{ TPageBaseTest }

procedure TPageBaseTest.OnGet_padrao_deve_levantar_ENotImplemented;
begin
  var Page := TPage.Create;
  try
    Assert.WillRaise(
      procedure begin Page.OnGet(TMockReq.Create); end,
      ENotImplemented);
  finally
    Page.Free;
  end;
end;

procedure TPageBaseTest.OnPost_padrao_deve_levantar_ENotImplemented;
begin
  var Page := TPage.Create;
  try
    Assert.WillRaise(
      procedure begin Page.OnPost(TMockReq.Create); end,
      ENotImplemented);
  finally
    Page.Free;
  end;
end;

procedure TPageBaseTest.OnPut_padrao_deve_levantar_ENotImplemented;
begin
  var Page := TPage.Create;
  try
    Assert.WillRaise(
      procedure begin Page.OnPut(TMockReq.Create); end,
      ENotImplemented);
  finally
    Page.Free;
  end;
end;

procedure TPageBaseTest.OnDelete_padrao_deve_levantar_ENotImplemented;
begin
  var Page := TPage.Create;
  try
    Assert.WillRaise(
      procedure begin Page.OnDelete(TMockReq.Create); end,
      ENotImplemented);
  finally
    Page.Free;
  end;
end;

procedure TPageBaseTest.Deve_implementar_interface_IPage;
begin
  var Page: IPage := TPage.Create;
  Assert.IsNotNull(Page);
end;

procedure TPageBaseTest.Classe_derivada_pode_sobrescrever_OnGet;
begin
  var Page: IPage := TMyPage.Create;
  var Result := Page.OnGet(TMockReq.Create);
  Assert.IsNotNull(Result);
  var PR := Result as TPageResult;
  Assert.AreEqual(Ord(prkRender), Ord(PR.Kind));
end;

procedure TPageBaseTest.Classe_derivada_pode_sobrescrever_OnPost;
begin
  var Page: IPage := TMyPage.Create;
  var Result := Page.OnPost(TMockReq.Create);
  Assert.IsNotNull(Result);
  var PR := Result as TPageResult;
  Assert.AreEqual(Ord(prkRedirect), Ord(PR.Kind));
  Assert.AreEqual('/success', PR.RedirectUrl);
end;

initialization
  TDUnitX.RegisterTestFixture(TPageBaseTest);

end.
