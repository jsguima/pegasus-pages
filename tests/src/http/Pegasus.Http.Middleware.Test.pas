unit Pegasus.Http.Middleware.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Pegasus.Http.Request,
  Pegasus.Http.Response,
  Pegasus.Http.Middleware;

type
  /// Mock de IRequest para testes de middleware
  TMockRequest = class(TInterfacedObject, IRequest)
  private
    FMethod: string;
    FPath: string;
    FCookies: TDictionary<string, string>;
    FHeaders: TDictionary<string, string>;
    FFormParams: TDictionary<string, string>;
  public
    constructor Create(const Method: string = 'GET'; const Path: string = '/');
    destructor Destroy; override;
    procedure SetCookie(const Name, Value: string);
    procedure SetHeader(const Name, Value: string);
    procedure SetFormParam(const Name, Value: string);
    // IRequest
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

  [TestFixture]
  TCsrfMiddlewareTest = class
  public
    [Test]
    procedure GET_deve_gerar_token_e_setar_cookie;

    [Test]
    procedure GET_com_cookie_existente_deve_reutilizar_token;

    [Test]
    procedure POST_sem_token_deve_retornar_403;

    [Test]
    procedure POST_com_token_valido_no_header_deve_passar;

    [Test]
    procedure POST_com_token_valido_no_form_deve_passar;

    [Test]
    procedure POST_com_token_invalido_deve_retornar_403;

    [Test]
    procedure PUT_sem_token_deve_retornar_403;

    [Test]
    procedure DELETE_sem_token_deve_retornar_403;

    [Test]
    procedure GET_nao_deve_validar_token;

    [Test]
    procedure POST_com_token_parcialmente_correto_deve_falhar;
  end;

  [TestFixture]
  TSecureHeadersMiddlewareTest = class
  public
    [Test]
    procedure Deve_adicionar_X_Content_Type_Options;

    [Test]
    procedure Deve_adicionar_X_Frame_Options_DENY;

    [Test]
    procedure Deve_adicionar_Content_Security_Policy;

    [Test]
    procedure Deve_chamar_Next;

    [Test]
    procedure Nao_deve_adicionar_HSTS_em_dev;

    [Test]
    procedure Deve_adicionar_HSTS_em_producao;

    [Test]
    procedure Deve_incluir_font_src_extra_no_CSP;
  end;

  [TestFixture]
  TTimeoutMiddlewareTest = class
  public
    [Test]
    procedure Deve_chamar_Next_normalmente;

    [Test]
    procedure Deve_capturar_ERequestTimeout;

    [Test]
    procedure Deve_retornar_503_em_timeout;
  end;

implementation

{ TMockRequest }

constructor TMockRequest.Create(const Method, Path: string);
begin
  inherited Create;
  FMethod := Method;
  FPath := Path;
  FCookies := TDictionary<string, string>.Create;
  FHeaders := TDictionary<string, string>.Create;
  FFormParams := TDictionary<string, string>.Create;
end;

destructor TMockRequest.Destroy;
begin
  FCookies.Free;
  FHeaders.Free;
  FFormParams.Free;
  inherited;
end;

procedure TMockRequest.SetCookie(const Name, Value: string);
begin
  FCookies.AddOrSetValue(Name, Value);
end;

procedure TMockRequest.SetHeader(const Name, Value: string);
begin
  FHeaders.AddOrSetValue(Name, Value);
end;

procedure TMockRequest.SetFormParam(const Name, Value: string);
begin
  FFormParams.AddOrSetValue(Name, Value);
end;

function TMockRequest.GetContentType: string;
begin
  Result := 'text/html';
end;

function TMockRequest.GetCookie(const Name: string): string;
begin
  if not FCookies.TryGetValue(Name, Result) then
    Result := '';
end;

function TMockRequest.GetFormParam(const Name: string): string;
begin
  if not FFormParams.TryGetValue(Name, Result) then
    Result := '';
end;

function TMockRequest.GetHeader(const Name: string): string;
begin
  if not FHeaders.TryGetValue(Name, Result) then
    Result := '';
end;

function TMockRequest.GetMethod: string;
begin
  Result := FMethod;
end;

function TMockRequest.GetPath: string;
begin
  Result := FPath;
end;

function TMockRequest.GetQueryParam(const Name: string): string;
begin
  Result := '';
end;

function TMockRequest.GetRawBody: string;
begin
  Result := '';
end;

function TMockRequest.GetRouteParam(const Name: string): string;
begin
  Result := '';
end;

procedure TMockRequest.SetRouteParam(const Name, Value: string);
begin
  // no-op
end;

{ TCsrfMiddlewareTest }

procedure TCsrfMiddlewareTest.GET_deve_gerar_token_e_setar_cookie;
begin
  var Req: IRequest := TMockRequest.Create('GET', '/');
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  ConfigureEnvironment(False);
  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsTrue(NextCalled);
  // Deve ter Set-Cookie header com _csrf
  var SetCookie := Res.GetHeader('Set-Cookie');
  Assert.Contains(SetCookie, '_csrf=');
  Assert.Contains(SetCookie, 'HttpOnly');
  Assert.Contains(SetCookie, 'SameSite=Strict');
end;

procedure TCsrfMiddlewareTest.GET_com_cookie_existente_deve_reutilizar_token;
begin
  var MockReq := TMockRequest.Create('GET', '/');
  MockReq.SetCookie('_csrf', 'existing-token-value');
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin end);

  // Nao deve setar novo cookie pois ja existe
  var SetCookie := Res.GetHeader('Set-Cookie');
  Assert.AreEqual('', SetCookie);
end;

procedure TCsrfMiddlewareTest.POST_sem_token_deve_retornar_403;
begin
  // Primeiro GET para gerar cookie
  var MockReq := TMockRequest.Create('POST', '/submit');
  MockReq.SetCookie('_csrf', 'token123');
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsFalse(NextCalled);
  Assert.AreEqual(403, Res.GetStatusCode);
end;

procedure TCsrfMiddlewareTest.POST_com_token_valido_no_header_deve_passar;
begin
  var Token := 'my-secret-csrf-token';
  var MockReq := TMockRequest.Create('POST', '/submit');
  MockReq.SetCookie('_csrf', Token);
  MockReq.SetHeader('X-CSRF-Token', Token);
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsTrue(NextCalled);
  Assert.AreEqual(200, Res.GetStatusCode);
end;

procedure TCsrfMiddlewareTest.POST_com_token_valido_no_form_deve_passar;
begin
  var Token := 'form-csrf-token';
  var MockReq := TMockRequest.Create('POST', '/submit');
  MockReq.SetCookie('_csrf', Token);
  MockReq.SetFormParam('_csrf', Token);
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsTrue(NextCalled);
end;

procedure TCsrfMiddlewareTest.POST_com_token_invalido_deve_retornar_403;
begin
  var MockReq := TMockRequest.Create('POST', '/submit');
  MockReq.SetCookie('_csrf', 'real-token');
  MockReq.SetHeader('X-CSRF-Token', 'wrong-token');
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsFalse(NextCalled);
  Assert.AreEqual(403, Res.GetStatusCode);
end;

procedure TCsrfMiddlewareTest.PUT_sem_token_deve_retornar_403;
begin
  var MockReq := TMockRequest.Create('PUT', '/resource/1');
  MockReq.SetCookie('_csrf', 'token');
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsFalse(NextCalled);
  Assert.AreEqual(403, Res.GetStatusCode);
end;

procedure TCsrfMiddlewareTest.DELETE_sem_token_deve_retornar_403;
begin
  var MockReq := TMockRequest.Create('DELETE', '/resource/1');
  MockReq.SetCookie('_csrf', 'token');
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsFalse(NextCalled);
  Assert.AreEqual(403, Res.GetStatusCode);
end;

procedure TCsrfMiddlewareTest.GET_nao_deve_validar_token;
begin
  var MockReq := TMockRequest.Create('GET', '/page');
  MockReq.SetCookie('_csrf', 'token');
  // Sem header X-CSRF-Token - deve passar mesmo assim (GET)
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsTrue(NextCalled);
end;

procedure TCsrfMiddlewareTest.POST_com_token_parcialmente_correto_deve_falhar;
begin
  var MockReq := TMockRequest.Create('POST', '/submit');
  MockReq.SetCookie('_csrf', 'abcdefgh');
  MockReq.SetHeader('X-CSRF-Token', 'abcdefgX'); // Ultimo char diferente
  var Req: IRequest := MockReq;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Csrf()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsFalse(NextCalled, 'Token parcialmente correto nao deve passar');
  Assert.AreEqual(403, Res.GetStatusCode);
end;

{ TSecureHeadersMiddlewareTest }

procedure TSecureHeadersMiddlewareTest.Deve_adicionar_X_Content_Type_Options;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;

  ConfigureEnvironment(False);
  TMiddlewares.SecureHeaders()(Req, Res,
    procedure begin end);

  Assert.AreEqual('nosniff', Res.GetHeader('X-Content-Type-Options'));
end;

procedure TSecureHeadersMiddlewareTest.Deve_adicionar_X_Frame_Options_DENY;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;

  TMiddlewares.SecureHeaders()(Req, Res,
    procedure begin end);

  Assert.AreEqual('DENY', Res.GetHeader('X-Frame-Options'));
end;

procedure TSecureHeadersMiddlewareTest.Deve_adicionar_Content_Security_Policy;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;

  TMiddlewares.SecureHeaders()(Req, Res,
    procedure begin end);

  var CSP := Res.GetHeader('Content-Security-Policy');
  Assert.Contains(CSP, 'default-src');
  Assert.Contains(CSP, 'script-src');
  Assert.Contains(CSP, 'frame-ancestors ''none''');
end;

procedure TSecureHeadersMiddlewareTest.Deve_chamar_Next;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.SecureHeaders()(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsTrue(NextCalled);
end;

procedure TSecureHeadersMiddlewareTest.Nao_deve_adicionar_HSTS_em_dev;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;

  ConfigureEnvironment(False);
  TMiddlewares.SecureHeaders()(Req, Res,
    procedure begin end);

  Assert.AreEqual('', Res.GetHeader('Strict-Transport-Security'));
end;

procedure TSecureHeadersMiddlewareTest.Deve_adicionar_HSTS_em_producao;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;

  ConfigureEnvironment(True);
  try
    TMiddlewares.SecureHeaders()(Req, Res,
      procedure begin end);

    var HSTS := Res.GetHeader('Strict-Transport-Security');
    Assert.Contains(HSTS, 'max-age=');
    Assert.Contains(HSTS, 'includeSubDomains');
  finally
    ConfigureEnvironment(False);
  end;
end;

procedure TSecureHeadersMiddlewareTest.Deve_incluir_font_src_extra_no_CSP;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;

  TMiddlewares.SecureHeaders(['https://fonts.googleapis.com'])(Req, Res,
    procedure begin end);

  var CSP := Res.GetHeader('Content-Security-Policy');
  Assert.Contains(CSP, 'https://fonts.googleapis.com');
end;

{ TTimeoutMiddlewareTest }

procedure TTimeoutMiddlewareTest.Deve_chamar_Next_normalmente;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;
  var NextCalled := False;

  TMiddlewares.Timeout(5000)(Req, Res,
    procedure begin NextCalled := True; end);

  Assert.IsTrue(NextCalled);
  Assert.AreEqual(200, Res.GetStatusCode);
end;

procedure TTimeoutMiddlewareTest.Deve_capturar_ERequestTimeout;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;

  TMiddlewares.Timeout(5000)(Req, Res,
    procedure
    begin
      raise ERequestTimeout.Create('Timeout simulado');
    end);

  Assert.AreEqual(503, Res.GetStatusCode);
end;

procedure TTimeoutMiddlewareTest.Deve_retornar_503_em_timeout;
begin
  var Req: IRequest := TMockRequest.Create;
  var Res: IResponse := TResponse.Create;

  TMiddlewares.Timeout(5000)(Req, Res,
    procedure
    begin
      raise ERequestTimeout.Create('timeout');
    end);

  Assert.AreEqual(503, Res.GetStatusCode);
  Assert.Contains(Res.GetHtml, 'timeout');
end;

initialization
  TDUnitX.RegisterTestFixture(TCsrfMiddlewareTest);
  TDUnitX.RegisterTestFixture(TSecureHeadersMiddlewareTest);
  TDUnitX.RegisterTestFixture(TTimeoutMiddlewareTest);

end.
