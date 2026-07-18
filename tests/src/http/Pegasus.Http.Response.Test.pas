unit Pegasus.Http.Response.Test;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  Pegasus.Http.Response;

type
  [TestFixture]
  TResponseDefaultsTest = class
  public
    [Test]
    procedure Status_padrao_deve_ser_200;

    [Test]
    procedure ContentType_padrao_deve_ser_html_utf8;

    [Test]
    procedure IsStream_padrao_deve_ser_false;

    [Test]
    procedure Html_padrao_deve_ser_vazio;

    [Test]
    procedure Headers_padrao_deve_estar_vazio;
  end;

  [TestFixture]
  TResponseStatusTest = class
  public
    [Test]
    procedure Deve_setar_status_404;

    [Test]
    procedure Deve_setar_status_500;

    [Test]
    procedure Deve_setar_status_301;

    [Test]
    procedure Deve_setar_status_204_no_content;

    [Test]
    procedure Deve_permitir_sobrescrever_status;
  end;

  [TestFixture]
  TResponseHtmlTest = class
  public
    [Test]
    procedure Deve_setar_e_recuperar_html;

    [Test]
    procedure Deve_aceitar_html_vazio;

    [Test]
    procedure Deve_aceitar_html_grande;

    [Test]
    procedure Deve_sobrescrever_html_anterior;
  end;

  [TestFixture]
  TResponseHeadersTest = class
  public
    [Test]
    procedure Deve_adicionar_header;

    [Test]
    procedure Deve_recuperar_header_por_nome;

    [Test]
    procedure Deve_retornar_vazio_para_header_inexistente;

    [Test]
    procedure Deve_sobrescrever_header_existente;

    [Test]
    procedure Deve_contar_headers_adicionados;

    [Test]
    procedure Deve_adicionar_multiplos_headers_diferentes;

    [Test]
    procedure Headers_devem_persistir_na_lista;
  end;

  [TestFixture]
  TResponseContentTypeTest = class
  public
    [Test]
    procedure Deve_alterar_content_type;

    [Test]
    procedure Deve_aceitar_json;

    [Test]
    procedure Deve_aceitar_plain_text;
  end;

  [TestFixture]
  TResponseStreamTest = class
  public
    [Test]
    procedure Deve_enviar_stream;

    [Test]
    procedure IsStream_deve_ser_true_apos_SendStream;

    [Test]
    procedure Deve_armazenar_filename;

    [Test]
    procedure Deve_liberar_stream_anterior_ao_enviar_novo;

    [Test]
    procedure GetStream_deve_retornar_stream_enviado;

    [Test]
    procedure GetStreamFileName_deve_retornar_nome;
  end;

implementation

{ TResponseDefaultsTest }

procedure TResponseDefaultsTest.Status_padrao_deve_ser_200;
begin
  var Res: IResponse := TResponse.Create;
  Assert.AreEqual(200, Res.GetStatusCode);
end;

procedure TResponseDefaultsTest.ContentType_padrao_deve_ser_html_utf8;
begin
  var Res: IResponse := TResponse.Create;
  Assert.AreEqual('text/html; charset=utf-8', Res.GetContentType);
end;

procedure TResponseDefaultsTest.IsStream_padrao_deve_ser_false;
begin
  var Res: IResponse := TResponse.Create;
  Assert.IsFalse(Res.IsStream);
end;

procedure TResponseDefaultsTest.Html_padrao_deve_ser_vazio;
begin
  var Res: IResponse := TResponse.Create;
  Assert.AreEqual('', Res.GetHtml);
end;

procedure TResponseDefaultsTest.Headers_padrao_deve_estar_vazio;
begin
  var Res: IResponse := TResponse.Create;
  Assert.AreEqual(0, Res.GetHeaders.Count);
end;

{ TResponseStatusTest }

procedure TResponseStatusTest.Deve_setar_status_404;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetStatus(404);
  Assert.AreEqual(404, Res.GetStatusCode);
end;

procedure TResponseStatusTest.Deve_setar_status_500;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetStatus(500);
  Assert.AreEqual(500, Res.GetStatusCode);
end;

procedure TResponseStatusTest.Deve_setar_status_301;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetStatus(301);
  Assert.AreEqual(301, Res.GetStatusCode);
end;

procedure TResponseStatusTest.Deve_setar_status_204_no_content;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetStatus(204);
  Assert.AreEqual(204, Res.GetStatusCode);
end;

procedure TResponseStatusTest.Deve_permitir_sobrescrever_status;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetStatus(404);
  Res.SetStatus(200);
  Assert.AreEqual(200, Res.GetStatusCode);
end;

{ TResponseHtmlTest }

procedure TResponseHtmlTest.Deve_setar_e_recuperar_html;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetHtml('<h1>Hello</h1>');
  Assert.AreEqual('<h1>Hello</h1>', Res.GetHtml);
end;

procedure TResponseHtmlTest.Deve_aceitar_html_vazio;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetHtml('');
  Assert.AreEqual('', Res.GetHtml);
end;

procedure TResponseHtmlTest.Deve_aceitar_html_grande;
begin
  var Res: IResponse := TResponse.Create;
  var BigHtml := StringOfChar('X', 100000);
  Res.SetHtml(BigHtml);
  Assert.AreEqual(100000, Res.GetHtml.Length);
end;

procedure TResponseHtmlTest.Deve_sobrescrever_html_anterior;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetHtml('<p>Primeiro</p>');
  Res.SetHtml('<p>Segundo</p>');
  Assert.AreEqual('<p>Segundo</p>', Res.GetHtml);
end;

{ TResponseHeadersTest }

procedure TResponseHeadersTest.Deve_adicionar_header;
begin
  var Res: IResponse := TResponse.Create;
  Res.AddHeader('X-Custom', 'valor');
  Assert.AreEqual('valor', Res.GetHeader('X-Custom'));
end;

procedure TResponseHeadersTest.Deve_recuperar_header_por_nome;
begin
  var Res: IResponse := TResponse.Create;
  Res.AddHeader('Content-Language', 'pt-BR');
  Assert.AreEqual('pt-BR', Res.GetHeader('Content-Language'));
end;

procedure TResponseHeadersTest.Deve_retornar_vazio_para_header_inexistente;
begin
  var Res: IResponse := TResponse.Create;
  Assert.AreEqual('', Res.GetHeader('X-Nao-Existe'));
end;

procedure TResponseHeadersTest.Deve_sobrescrever_header_existente;
begin
  var Res: IResponse := TResponse.Create;
  Res.AddHeader('X-Token', 'abc');
  Res.AddHeader('X-Token', 'xyz');
  Assert.AreEqual('xyz', Res.GetHeader('X-Token'));
end;

procedure TResponseHeadersTest.Deve_contar_headers_adicionados;
begin
  var Res: IResponse := TResponse.Create;
  Res.AddHeader('A', '1');
  Res.AddHeader('B', '2');
  Res.AddHeader('C', '3');
  Assert.AreEqual(3, Res.GetHeaders.Count);
end;

procedure TResponseHeadersTest.Deve_adicionar_multiplos_headers_diferentes;
begin
  var Res: IResponse := TResponse.Create;
  Res.AddHeader('X-Frame-Options', 'DENY');
  Res.AddHeader('X-Content-Type-Options', 'nosniff');
  Assert.AreEqual('DENY', Res.GetHeader('X-Frame-Options'));
  Assert.AreEqual('nosniff', Res.GetHeader('X-Content-Type-Options'));
end;

procedure TResponseHeadersTest.Headers_devem_persistir_na_lista;
begin
  var Res: IResponse := TResponse.Create;
  Res.AddHeader('Location', '/home');
  var Headers := Res.GetHeaders;
  Assert.IsTrue(Headers.Count > 0);
  Assert.AreEqual('/home', Headers.Values['Location']);
end;

{ TResponseContentTypeTest }

procedure TResponseContentTypeTest.Deve_alterar_content_type;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetContentType('application/json');
  Assert.AreEqual('application/json', Res.GetContentType);
end;

procedure TResponseContentTypeTest.Deve_aceitar_json;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetContentType('application/json; charset=utf-8');
  Assert.AreEqual('application/json; charset=utf-8', Res.GetContentType);
end;

procedure TResponseContentTypeTest.Deve_aceitar_plain_text;
begin
  var Res: IResponse := TResponse.Create;
  Res.SetContentType('text/plain');
  Assert.AreEqual('text/plain', Res.GetContentType);
end;

{ TResponseStreamTest }

procedure TResponseStreamTest.Deve_enviar_stream;
begin
  var Res: IResponse := TResponse.Create;
  var Stream := TMemoryStream.Create;
  Res.SendStream(Stream, 'file.txt');
  Assert.IsTrue(Res.IsStream);
end;

procedure TResponseStreamTest.IsStream_deve_ser_true_apos_SendStream;
begin
  var Res: IResponse := TResponse.Create;
  Assert.IsFalse(Res.IsStream);
  Res.SendStream(TMemoryStream.Create, '');
  Assert.IsTrue(Res.IsStream);
end;

procedure TResponseStreamTest.Deve_armazenar_filename;
begin
  var Res: IResponse := TResponse.Create;
  Res.SendStream(TMemoryStream.Create, 'relatorio.pdf');
  Assert.AreEqual('relatorio.pdf', Res.GetStreamFileName);
end;

procedure TResponseStreamTest.Deve_liberar_stream_anterior_ao_enviar_novo;
begin
  var Res: IResponse := TResponse.Create;
  var Stream1 := TMemoryStream.Create;
  Res.SendStream(Stream1, 'a.txt');

  var Stream2 := TMemoryStream.Create;
  Res.SendStream(Stream2, 'b.txt');

  // Stream1 deve ter sido liberado - sem leak
  Assert.AreEqual('b.txt', Res.GetStreamFileName);
  Assert.AreSame(Stream2, Res.GetStream);
end;

procedure TResponseStreamTest.GetStream_deve_retornar_stream_enviado;
begin
  var Res: IResponse := TResponse.Create;
  var Stream := TMemoryStream.Create;
  Res.SendStream(Stream, 'data.bin');
  Assert.AreSame(Stream, Res.GetStream);
end;

procedure TResponseStreamTest.GetStreamFileName_deve_retornar_nome;
begin
  var Res: IResponse := TResponse.Create;
  Res.SendStream(TMemoryStream.Create, 'export.csv');
  Assert.AreEqual('export.csv', Res.GetStreamFileName);
end;

initialization
  TDUnitX.RegisterTestFixture(TResponseDefaultsTest);
  TDUnitX.RegisterTestFixture(TResponseStatusTest);
  TDUnitX.RegisterTestFixture(TResponseHtmlTest);
  TDUnitX.RegisterTestFixture(TResponseHeadersTest);
  TDUnitX.RegisterTestFixture(TResponseContentTypeTest);
  TDUnitX.RegisterTestFixture(TResponseStreamTest);

end.
