unit Pegasus.Http.PageResult.Test;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  Pegasus.Http.PageResult,
  Pegasus.Data.Page;

type
  [TestFixture]
  TPageResultRedirectTest = class
  public
    [Test]
    procedure Deve_criar_redirect_com_url;

    [Test]
    procedure Deve_usar_status_302_por_padrao;

    [Test]
    procedure Deve_aceitar_status_301_permanente;

    [Test]
    procedure Kind_deve_ser_prkRedirect;

    [Test]
    procedure Deve_aceitar_url_com_query_string;

    [Test]
    procedure Deve_aceitar_url_relativa;
  end;

  [TestFixture]
  TPageResultJsonTest = class
  public
    [Test]
    procedure Deve_criar_json_response;

    [Test]
    procedure Deve_usar_status_200_por_padrao;

    [Test]
    procedure Deve_aceitar_status_customizado;

    [Test]
    procedure Kind_deve_ser_prkJson;

    [Test]
    procedure Deve_armazenar_body_json_complexo;

    [Test]
    procedure Deve_aceitar_json_array;
  end;

  [TestFixture]
  TPageResultErrorTest = class
  public
    [Test]
    procedure Deve_criar_error_com_status;

    [Test]
    procedure Kind_deve_ser_prkStatus;

    [Test]
    procedure Deve_aceitar_status_403;

    [Test]
    procedure Deve_aceitar_status_503;
  end;

  [TestFixture]
  TPageResultRenderTest = class
  public
    [Test]
    procedure Page_deve_retornar_builder;

    [Test]
    procedure Builder_deve_adicionar_string;

    [Test]
    procedure Builder_deve_adicionar_integer;

    [Test]
    procedure Builder_deve_adicionar_double;

    [Test]
    procedure Builder_deve_adicionar_boolean;

    [Test]
    procedure Builder_deve_adicionar_objeto;

    [Test]
    procedure Builder_deve_adicionar_lista;

    [Test]
    procedure Render_deve_retornar_page_result;

    [Test]
    procedure Kind_deve_ser_prkRender_apos_Page;

    [Test]
    procedure Status_deve_ser_200_apos_Page;

    [Test]
    procedure Deve_permitir_encadear_multiplos_Add;

    [Test]
    procedure Data_deve_conter_valores_adicionados;
  end;

  [TestFixture]
  TPageResultStreamTest = class
  public
    [Test]
    procedure SetStream_deve_retornar_page_result;

    [Test]
    procedure Data_deve_ter_stream_apos_SetStream;
  end;

  [TestFixture]
  TPageResultFluentApiTest = class
  public
    [Test]
    procedure Redirect_deve_ser_fluent;

    [Test]
    procedure Json_deve_ser_fluent;

    [Test]
    procedure Error_deve_ser_fluent;

    [Test]
    procedure Page_Add_deve_ser_fluent;
  end;

implementation

type
  TItem = class
  public
    Nome: string;
  end;

{ TPageResultRedirectTest }

procedure TPageResultRedirectTest.Deve_criar_redirect_com_url;
begin
  var PR := PageResult.Redirect('/dashboard') as TPageResult;
  Assert.AreEqual('/dashboard', PR.RedirectUrl);
end;

procedure TPageResultRedirectTest.Deve_usar_status_302_por_padrao;
begin
  var PR := PageResult.Redirect('/home') as TPageResult;
  Assert.AreEqual(302, PR.StatusCode);
end;

procedure TPageResultRedirectTest.Deve_aceitar_status_301_permanente;
begin
  var PR := PageResult.Redirect('/new-url', 301) as TPageResult;
  Assert.AreEqual(301, PR.StatusCode);
end;

procedure TPageResultRedirectTest.Kind_deve_ser_prkRedirect;
begin
  var PR := PageResult.Redirect('/x') as TPageResult;
  Assert.AreEqual(Ord(prkRedirect), Ord(PR.Kind));
end;

procedure TPageResultRedirectTest.Deve_aceitar_url_com_query_string;
begin
  var PR := PageResult.Redirect('/search?q=delphi&page=2') as TPageResult;
  Assert.AreEqual('/search?q=delphi&page=2', PR.RedirectUrl);
end;

procedure TPageResultRedirectTest.Deve_aceitar_url_relativa;
begin
  var PR := PageResult.Redirect('../parent') as TPageResult;
  Assert.AreEqual('../parent', PR.RedirectUrl);
end;

{ TPageResultJsonTest }

procedure TPageResultJsonTest.Deve_criar_json_response;
begin
  var PR := PageResult.Json('{"ok":true}') as TPageResult;
  Assert.AreEqual('{"ok":true}', PR.Body);
end;

procedure TPageResultJsonTest.Deve_usar_status_200_por_padrao;
begin
  var PR := PageResult.Json('{}') as TPageResult;
  Assert.AreEqual(200, PR.StatusCode);
end;

procedure TPageResultJsonTest.Deve_aceitar_status_customizado;
begin
  var PR := PageResult.Json('{"error":"not found"}', 404) as TPageResult;
  Assert.AreEqual(404, PR.StatusCode);
end;

procedure TPageResultJsonTest.Kind_deve_ser_prkJson;
begin
  var PR := PageResult.Json('[]') as TPageResult;
  Assert.AreEqual(Ord(prkJson), Ord(PR.Kind));
end;

procedure TPageResultJsonTest.Deve_armazenar_body_json_complexo;
begin
  var Body := '{"users":[{"id":1,"name":"Ana"},{"id":2,"name":"Bob"}]}';
  var PR := PageResult.Json(Body) as TPageResult;
  Assert.AreEqual(Body, PR.Body);
end;

procedure TPageResultJsonTest.Deve_aceitar_json_array;
begin
  var PR := PageResult.Json('[1,2,3]') as TPageResult;
  Assert.AreEqual('[1,2,3]', PR.Body);
end;

{ TPageResultErrorTest }

procedure TPageResultErrorTest.Deve_criar_error_com_status;
begin
  var PR := PageResult.Error('Not Found', 404) as TPageResult;
  Assert.AreEqual(404, PR.StatusCode);
end;

procedure TPageResultErrorTest.Kind_deve_ser_prkStatus;
begin
  var PR := PageResult.Error('Erro', 500) as TPageResult;
  Assert.AreEqual(Ord(prkStatus), Ord(PR.Kind));
end;

procedure TPageResultErrorTest.Deve_aceitar_status_403;
begin
  var PR := PageResult.Error('Forbidden', 403) as TPageResult;
  Assert.AreEqual(403, PR.StatusCode);
end;

procedure TPageResultErrorTest.Deve_aceitar_status_503;
begin
  var PR := PageResult.Error('Service Unavailable', 503) as TPageResult;
  Assert.AreEqual(503, PR.StatusCode);
end;

{ TPageResultRenderTest }

procedure TPageResultRenderTest.Page_deve_retornar_builder;
begin
  var Builder := PageResult.Page();
  Assert.IsNotNull(Builder);
end;

procedure TPageResultRenderTest.Builder_deve_adicionar_string;
begin
  var PR := PageResult.Page().Add('titulo', 'Home').Render as TPageResult;
  var V := PR.Data.Get('titulo');
  Assert.AreEqual('Home', V.AsString);
end;

procedure TPageResultRenderTest.Builder_deve_adicionar_integer;
begin
  var PR := PageResult.Page().Add('count', 42).Render as TPageResult;
  Assert.AreEqual(42, PR.Data.Get('count').AsInteger);
end;

procedure TPageResultRenderTest.Builder_deve_adicionar_double;
begin
  var PR := PageResult.Page().Add('preco', 9.99).Render as TPageResult;
  Assert.AreEqual(Double(9.99), PR.Data.Get('preco').AsExtended, 0.001);
end;

procedure TPageResultRenderTest.Builder_deve_adicionar_boolean;
begin
  var PR := PageResult.Page().Add('logado', True).Render as TPageResult;
  Assert.IsTrue(PR.Data.Get('logado').AsBoolean);
end;

procedure TPageResultRenderTest.Builder_deve_adicionar_objeto;
begin
  var Obj := TItem.Create;
  Obj.Nome := 'Widget';
  var PR := PageResult.Page().Add('item', Obj).Render as TPageResult;
  var V := PR.Data.Get('item');
  Assert.AreEqual('Widget', TItem(V.AsObject).Nome);
end;

procedure TPageResultRenderTest.Builder_deve_adicionar_lista;
begin
  var Lista := TObjectList<TObject>.Create(True);
  Lista.Add(TItem.Create);
  Lista.Add(TItem.Create);
  var PR := PageResult.Page().Add('items', Lista).Render as TPageResult;
  var V := PR.Data.Get('items');
  Assert.AreEqual(2, TObjectList<TObject>(V.AsObject).Count);
end;

procedure TPageResultRenderTest.Render_deve_retornar_page_result;
begin
  var PR := PageResult.Page().Add('x', 'y').Render;
  Assert.IsNotNull(PR);
end;

procedure TPageResultRenderTest.Kind_deve_ser_prkRender_apos_Page;
begin
  var PR := PageResult.Page().Render as TPageResult;
  Assert.AreEqual(Ord(prkRender), Ord(PR.Kind));
end;

procedure TPageResultRenderTest.Status_deve_ser_200_apos_Page;
begin
  var PR := PageResult.Page().Render as TPageResult;
  Assert.AreEqual(200, PR.StatusCode);
end;

procedure TPageResultRenderTest.Deve_permitir_encadear_multiplos_Add;
begin
  var PR := PageResult.Page()
    .Add('a', 'x')
    .Add('b', 1)
    .Add('c', True)
    .Render as TPageResult;

  Assert.AreEqual('x', PR.Data.Get('a').AsString);
  Assert.AreEqual(1, PR.Data.Get('b').AsInteger);
  Assert.IsTrue(PR.Data.Get('c').AsBoolean);
end;

procedure TPageResultRenderTest.Data_deve_conter_valores_adicionados;
begin
  var PR := PageResult.Page()
    .Add('nome', 'Pegasus')
    .Add('versao', 1)
    .Render as TPageResult;

  Assert.IsTrue(PR.Data.Has('nome'));
  Assert.IsTrue(PR.Data.Has('versao'));
end;

{ TPageResultStreamTest }

procedure TPageResultStreamTest.SetStream_deve_retornar_page_result;
begin
  var Stream := TMemoryStream.Create;
  var PR := PageResult.Page().SetStream(Stream, 'application/pdf', 'doc.pdf');
  Assert.IsNotNull(PR);
end;

procedure TPageResultStreamTest.Data_deve_ter_stream_apos_SetStream;
begin
  var Stream := TMemoryStream.Create;
  var PR := PageResult.Page().SetStream(Stream, 'image/png', 'foto.png') as TPageResult;
  Assert.IsTrue(PR.Data.HasStream);
  Assert.AreEqual('image/png', PR.Data.GetStreamContentType);
  Assert.AreEqual('foto.png', PR.Data.GetStreamFileName);
  PR.Data.GetStream.Free;
end;

{ TPageResultFluentApiTest }

procedure TPageResultFluentApiTest.Redirect_deve_ser_fluent;
begin
  var PR := PageResult.Redirect('/x');
  // Nao deve ser nil, validando fluent API
  Assert.IsNotNull(PR);
end;

procedure TPageResultFluentApiTest.Json_deve_ser_fluent;
begin
  var PR := PageResult.Json('{}');
  Assert.IsNotNull(PR);
end;

procedure TPageResultFluentApiTest.Error_deve_ser_fluent;
begin
  var PR := PageResult.Error('x', 500);
  Assert.IsNotNull(PR);
end;

procedure TPageResultFluentApiTest.Page_Add_deve_ser_fluent;
begin
  var Builder := PageResult.Page().Add('a', 'b').Add('c', 1);
  Assert.IsNotNull(Builder);
end;

initialization
  TDUnitX.RegisterTestFixture(TPageResultRedirectTest);
  TDUnitX.RegisterTestFixture(TPageResultJsonTest);
  TDUnitX.RegisterTestFixture(TPageResultErrorTest);
  TDUnitX.RegisterTestFixture(TPageResultRenderTest);
  TDUnitX.RegisterTestFixture(TPageResultStreamTest);
  TDUnitX.RegisterTestFixture(TPageResultFluentApiTest);

end.
