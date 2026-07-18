unit Pegasus.Routing.Registry.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Pegasus.Http.Page,
  Pegasus.Http.Request,
  Pegasus.Http.PageResult,
  Pegasus.Routing.Registry;

type
  THomePage = class(TPage)
  public
    function OnGet(Request: IRequest): IPageResult; override;
  end;

  TFormPage = class(TPage)
  public
    function OnGet(Request: IRequest): IPageResult; override;
    function OnPost(Request: IRequest): IPageResult; override;
  end;

  TFullPage = class(TPage)
  public
    function OnGet(Request: IRequest): IPageResult; override;
    function OnPost(Request: IRequest): IPageResult; override;
    function OnPut(Request: IRequest): IPageResult; override;
    function OnDelete(Request: IRequest): IPageResult; override;
  end;

  TStatefulPage = class(TPage)
  public
    FCounter: Integer; // Field = estado! Deve ser rejeitado
    function OnGet(Request: IRequest): IPageResult; override;
  end;

  [TestFixture]
  TPageRegistryAddTest = class
  public
    [Test]
    procedure Deve_registrar_page_com_OnGet;

    [Test]
    procedure Deve_registrar_page_com_OnGet_e_OnPost;

    [Test]
    procedure Deve_registrar_todos_os_verbos;

    [Test]
    procedure Nao_deve_registrar_metodo_nao_sobrescrito;

    [Test]
    procedure Deve_rejeitar_page_com_estado;
  end;

  [TestFixture]
  TPageRegistryFindTest = class
  public
    [Test]
    procedure Deve_encontrar_page_por_rota_e_metodo;

    [Test]
    procedure Deve_retornar_false_para_rota_inexistente;

    [Test]
    procedure Deve_retornar_false_para_metodo_nao_registrado;

    [Test]
    procedure Deve_diferenciar_GET_de_POST;

    [Test]
    procedure Find_deve_ser_case_insensitive_no_metodo;
  end;

  [TestFixture]
  TPageRegistryEdgeCasesTest = class
  public
    [Test]
    procedure Deve_substituir_registro_existente;

    [Test]
    procedure Deve_funcionar_com_rotas_com_parametros;

    [Test]
    procedure Deve_funcionar_com_rota_raiz;
  end;

implementation

{ THomePage }

function THomePage.OnGet(Request: IRequest): IPageResult;
begin
  Result := PageResult.Page().Add('title', 'Home').Render;
end;

{ TFormPage }

function TFormPage.OnGet(Request: IRequest): IPageResult;
begin
  Result := PageResult.Page().Render;
end;

function TFormPage.OnPost(Request: IRequest): IPageResult;
begin
  Result := PageResult.Redirect('/success');
end;

{ TFullPage }

function TFullPage.OnGet(Request: IRequest): IPageResult;
begin
  Result := PageResult.Page().Render;
end;

function TFullPage.OnPost(Request: IRequest): IPageResult;
begin
  Result := PageResult.Json('{"ok":true}');
end;

function TFullPage.OnPut(Request: IRequest): IPageResult;
begin
  Result := PageResult.Json('{"updated":true}');
end;

function TFullPage.OnDelete(Request: IRequest): IPageResult;
begin
  Result := PageResult.Json('{"deleted":true}');
end;

{ TStatefulPage }

function TStatefulPage.OnGet(Request: IRequest): IPageResult;
begin
  Inc(FCounter);
  Result := PageResult.Page().Add('count', FCounter).Render;
end;

{ TPageRegistryAddTest }

procedure TPageRegistryAddTest.Deve_registrar_page_com_OnGet;
begin
  var Page: IPage := THomePage.Create;
  PageRegistry.Add('/home', Page);

  var Found: IPage;
  Assert.IsTrue(PageRegistry.Find('/home', 'GET', Found));
end;

procedure TPageRegistryAddTest.Deve_registrar_page_com_OnGet_e_OnPost;
begin
  var Page: IPage := TFormPage.Create;
  PageRegistry.Add('/form', Page);

  var Found: IPage;
  Assert.IsTrue(PageRegistry.Find('/form', 'GET', Found));
  Assert.IsTrue(PageRegistry.Find('/form', 'POST', Found));
end;

procedure TPageRegistryAddTest.Deve_registrar_todos_os_verbos;
begin
  var Page: IPage := TFullPage.Create;
  PageRegistry.Add('/resource', Page);

  var Found: IPage;
  Assert.IsTrue(PageRegistry.Find('/resource', 'GET', Found));
  Assert.IsTrue(PageRegistry.Find('/resource', 'POST', Found));
  Assert.IsTrue(PageRegistry.Find('/resource', 'PUT', Found));
  Assert.IsTrue(PageRegistry.Find('/resource', 'DELETE', Found));
end;

procedure TPageRegistryAddTest.Nao_deve_registrar_metodo_nao_sobrescrito;
begin
  var Page: IPage := THomePage.Create;
  PageRegistry.Add('/only-get', Page);

  var Found: IPage;
  Assert.IsTrue(PageRegistry.Find('/only-get', 'GET', Found));
  Assert.IsFalse(PageRegistry.Find('/only-get', 'POST', Found));
  Assert.IsFalse(PageRegistry.Find('/only-get', 'PUT', Found));
  Assert.IsFalse(PageRegistry.Find('/only-get', 'DELETE', Found));
end;

procedure TPageRegistryAddTest.Deve_rejeitar_page_com_estado;
begin
  var Page: IPage := TStatefulPage.Create;
  Assert.WillRaise(
    procedure begin PageRegistry.Add('/stateful', Page); end,
    EPageWithStateNotAllowed);
end;

{ TPageRegistryFindTest }

procedure TPageRegistryFindTest.Deve_encontrar_page_por_rota_e_metodo;
begin
  var Page: IPage := THomePage.Create;
  PageRegistry.Add('/findme', Page);

  var Found: IPage;
  Assert.IsTrue(PageRegistry.Find('/findme', 'GET', Found));
  Assert.IsNotNull(Found);
end;

procedure TPageRegistryFindTest.Deve_retornar_false_para_rota_inexistente;
begin
  var Found: IPage;
  Assert.IsFalse(PageRegistry.Find('/nao-existe-xyz-123', 'GET', Found));
end;

procedure TPageRegistryFindTest.Deve_retornar_false_para_metodo_nao_registrado;
begin
  var Page: IPage := THomePage.Create;
  PageRegistry.Add('/get-only-page', Page);

  var Found: IPage;
  Assert.IsFalse(PageRegistry.Find('/get-only-page', 'DELETE', Found));
end;

procedure TPageRegistryFindTest.Deve_diferenciar_GET_de_POST;
begin
  var Page: IPage := TFormPage.Create;
  PageRegistry.Add('/form-diff', Page);

  var GetPage, PostPage: IPage;
  PageRegistry.Find('/form-diff', 'GET', GetPage);
  PageRegistry.Find('/form-diff', 'POST', PostPage);

  // Ambos apontam para a mesma instancia
  Assert.IsNotNull(GetPage);
  Assert.IsNotNull(PostPage);
end;

procedure TPageRegistryFindTest.Find_deve_ser_case_insensitive_no_metodo;
begin
  var Page: IPage := THomePage.Create;
  PageRegistry.Add('/case-test', Page);

  var Found: IPage;
  // Find usa UpperCase internamente
  Assert.IsTrue(PageRegistry.Find('/case-test', 'get', Found));
  Assert.IsTrue(PageRegistry.Find('/case-test', 'Get', Found));
  Assert.IsTrue(PageRegistry.Find('/case-test', 'GET', Found));
end;

{ TPageRegistryEdgeCasesTest }

procedure TPageRegistryEdgeCasesTest.Deve_substituir_registro_existente;
begin
  var Page1: IPage := THomePage.Create;
  var Page2: IPage := TFormPage.Create;

  PageRegistry.Add('/replace-test', Page1);
  PageRegistry.Add('/replace-test', Page2);

  var Found: IPage;
  Assert.IsTrue(PageRegistry.Find('/replace-test', 'GET', Found));
  // Agora tambem deve ter POST (do FormPage)
  Assert.IsTrue(PageRegistry.Find('/replace-test', 'POST', Found));
end;

procedure TPageRegistryEdgeCasesTest.Deve_funcionar_com_rotas_com_parametros;
begin
  var Page: IPage := THomePage.Create;
  PageRegistry.Add('/users/:id', Page);

  var Found: IPage;
  Assert.IsTrue(PageRegistry.Find('/users/:id', 'GET', Found));
end;

procedure TPageRegistryEdgeCasesTest.Deve_funcionar_com_rota_raiz;
begin
  var Page: IPage := THomePage.Create;
  PageRegistry.Add('/', Page);

  var Found: IPage;
  Assert.IsTrue(PageRegistry.Find('/', 'GET', Found));
end;

initialization
  TDUnitX.RegisterTestFixture(TPageRegistryAddTest);
  TDUnitX.RegisterTestFixture(TPageRegistryFindTest);
  TDUnitX.RegisterTestFixture(TPageRegistryEdgeCasesTest);

end.
