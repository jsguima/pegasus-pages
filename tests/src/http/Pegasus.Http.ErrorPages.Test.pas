unit Pegasus.Http.ErrorPages.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Pegasus.Http.ErrorPages;

type
  [TestFixture]
  TErrorPages404Test = class
  public
    [Test]
    procedure Deve_retornar_html_padrao_quando_nao_carregado;

    [Test]
    procedure Html_padrao_deve_conter_404;

    [Test]
    procedure Html_padrao_deve_ser_html_valido;

    [Test]
    procedure Deve_usar_template_customizado_quando_disponivel;
  end;

  [TestFixture]
  TErrorPages500Test = class
  public
    [Test]
    procedure Deve_retornar_html_padrao_com_mensagem;

    [Test]
    procedure Deve_escapar_html_na_mensagem;

    [Test]
    procedure Deve_ocultar_mensagem_em_producao;

    [Test]
    procedure Deve_mostrar_mensagem_em_desenvolvimento;

    [Test]
    procedure Deve_usar_template_customizado_com_placeholder;

    [Test]
    procedure Deve_escapar_xss_na_mensagem_de_erro;

    [Test]
    procedure Mensagem_generica_em_producao_nao_deve_vazar_detalhes;
  end;

  [TestFixture]
  TErrorPagesLoadTest = class
  private
    FTempDir: string;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Deve_carregar_404_de_arquivo;

    [Test]
    procedure Deve_carregar_500_de_arquivo;

    [Test]
    procedure Deve_usar_padrao_se_pasta_nao_existe;

    [Test]
    procedure Deve_usar_padrao_se_arquivo_nao_existe;
  end;

implementation

{ TErrorPages404Test }

procedure TErrorPages404Test.Deve_retornar_html_padrao_quando_nao_carregado;
begin
  // Reconfigurar para estado limpo
  ErrorPages.Load('__dir_inexistente__');
  var Html := ErrorPages.Get404;
  Assert.IsNotEmpty(Html);
end;

procedure TErrorPages404Test.Html_padrao_deve_conter_404;
begin
  ErrorPages.Load('__dir_inexistente__');
  var Html := ErrorPages.Get404;
  Assert.Contains(Html, '404');
end;

procedure TErrorPages404Test.Html_padrao_deve_ser_html_valido;
begin
  ErrorPages.Load('__dir_inexistente__');
  var Html := ErrorPages.Get404;
  Assert.Contains(Html, '<!DOCTYPE html>');
  Assert.Contains(Html, '</html>');
end;

procedure TErrorPages404Test.Deve_usar_template_customizado_quando_disponivel;
begin
  var TempDir := TPath.Combine(TPath.GetTempPath, 'pegtest_404_' + TGUID.NewGuid.ToString);
  var ErrorsDir := TPath.Combine(TempDir, '_errors');
  ForceDirectories(ErrorsDir);
  try
    TFile.WriteAllText(TPath.Combine(ErrorsDir, '404.html'), '<h1>Custom 404</h1>');
    ErrorPages.Load(TempDir);
    Assert.AreEqual('<h1>Custom 404</h1>', ErrorPages.Get404);
  finally
    TDirectory.Delete(TempDir, True);
    // Restaurar
    ErrorPages.Load('__dir_inexistente__');
  end;
end;

{ TErrorPages500Test }

procedure TErrorPages500Test.Deve_retornar_html_padrao_com_mensagem;
begin
  ErrorPages.Load('__dir_inexistente__');
  ErrorPages.Configure(False);
  var Html := ErrorPages.Get500('Algo deu errado');
  Assert.Contains(Html, 'Algo deu errado');
end;

procedure TErrorPages500Test.Deve_escapar_html_na_mensagem;
begin
  ErrorPages.Load('__dir_inexistente__');
  ErrorPages.Configure(False);
  var Html := ErrorPages.Get500('<script>alert("xss")</script>');
  Assert.DoesNotContain(Html, '<script>');
  Assert.Contains(Html, '&lt;script&gt;');
end;

procedure TErrorPages500Test.Deve_ocultar_mensagem_em_producao;
begin
  ErrorPages.Load('__dir_inexistente__');
  ErrorPages.Configure(True);
  try
    var Html := ErrorPages.Get500('Database connection failed at 192.168.1.100');
    Assert.DoesNotContain(Html, 'Database');
    Assert.DoesNotContain(Html, '192.168.1.100');
    Assert.Contains(Html, 'unexpected error');
  finally
    ErrorPages.Configure(False);
  end;
end;

procedure TErrorPages500Test.Deve_mostrar_mensagem_em_desenvolvimento;
begin
  ErrorPages.Load('__dir_inexistente__');
  ErrorPages.Configure(False);
  var Html := ErrorPages.Get500('NullReferenceException');
  Assert.Contains(Html, 'NullReferenceException');
end;

procedure TErrorPages500Test.Deve_usar_template_customizado_com_placeholder;
begin
  var TempDir := TPath.Combine(TPath.GetTempPath, 'pegtest_500_' + TGUID.NewGuid.ToString);
  var ErrorsDir := TPath.Combine(TempDir, '_errors');
  ForceDirectories(ErrorsDir);
  try
    TFile.WriteAllText(TPath.Combine(ErrorsDir, '500.html'),
      '<div class="error">{{message}}</div>');
    ErrorPages.Load(TempDir);
    ErrorPages.Configure(False);
    var Html := ErrorPages.Get500('Custom error');
    Assert.Contains(Html, 'Custom error');
    Assert.Contains(Html, '<div class="error">');
  finally
    TDirectory.Delete(TempDir, True);
    ErrorPages.Load('__dir_inexistente__');
  end;
end;

procedure TErrorPages500Test.Deve_escapar_xss_na_mensagem_de_erro;
begin
  ErrorPages.Load('__dir_inexistente__');
  ErrorPages.Configure(False);
  var Html := ErrorPages.Get500('" onmouseover="alert(1)" x="');
  // As aspas devem ser escapadas para &quot;
  Assert.DoesNotContain(Html, '" onmouseover="');
  Assert.Contains(Html, '&quot;');
end;

procedure TErrorPages500Test.Mensagem_generica_em_producao_nao_deve_vazar_detalhes;
begin
  ErrorPages.Configure(True);
  try
    var Html := ErrorPages.Get500('SELECT * FROM users WHERE password = ''admin''');
    Assert.DoesNotContain(Html, 'SELECT');
    Assert.DoesNotContain(Html, 'password');
    Assert.DoesNotContain(Html, 'admin');
  finally
    ErrorPages.Configure(False);
  end;
end;

{ TErrorPagesLoadTest }

procedure TErrorPagesLoadTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegtest_load_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
end;

procedure TErrorPagesLoadTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
  ErrorPages.Load('__dir_inexistente__');
end;

procedure TErrorPagesLoadTest.Deve_carregar_404_de_arquivo;
begin
  var ErrorsDir := TPath.Combine(FTempDir, '_errors');
  ForceDirectories(ErrorsDir);
  TFile.WriteAllText(TPath.Combine(ErrorsDir, '404.html'), '<p>Pagina nao encontrada</p>');
  ErrorPages.Load(FTempDir);
  Assert.AreEqual('<p>Pagina nao encontrada</p>', ErrorPages.Get404);
end;

procedure TErrorPagesLoadTest.Deve_carregar_500_de_arquivo;
begin
  var ErrorsDir := TPath.Combine(FTempDir, '_errors');
  ForceDirectories(ErrorsDir);
  TFile.WriteAllText(TPath.Combine(ErrorsDir, '500.html'), '<p>Erro: {{message}}</p>');
  ErrorPages.Load(FTempDir);
  ErrorPages.Configure(False);
  var Html := ErrorPages.Get500('falha total');
  Assert.Contains(Html, 'falha total');
end;

procedure TErrorPagesLoadTest.Deve_usar_padrao_se_pasta_nao_existe;
begin
  ErrorPages.Load(TPath.Combine(FTempDir, 'nao_existe'));
  var Html := ErrorPages.Get404;
  Assert.Contains(Html, '404');
end;

procedure TErrorPagesLoadTest.Deve_usar_padrao_se_arquivo_nao_existe;
begin
  // Pasta _errors existe mas sem arquivos
  var ErrorsDir := TPath.Combine(FTempDir, '_errors');
  ForceDirectories(ErrorsDir);
  ErrorPages.Load(FTempDir);
  Assert.Contains(ErrorPages.Get404, '404');
end;

initialization
  TDUnitX.RegisterTestFixture(TErrorPages404Test);
  TDUnitX.RegisterTestFixture(TErrorPages500Test);
  TDUnitX.RegisterTestFixture(TErrorPagesLoadTest);

end.
