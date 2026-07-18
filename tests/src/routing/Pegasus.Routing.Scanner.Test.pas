unit Pegasus.Routing.Scanner.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Pegasus.Routing.Scanner;

type
  [TestFixture]
  TScannerBasicTest = class
  private
    FTempDir: string;
    procedure CreatePage(const RelPath: string);
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Diretorio_inexistente_deve_retornar_vazio;

    [Test]
    procedure Raiz_deve_gerar_rota_barra;

    [Test]
    procedure Subpasta_deve_gerar_rota_com_segmento;

    [Test]
    procedure Multiplas_pastas_devem_gerar_multiplas_rotas;

    [Test]
    procedure Deve_ignorar_pasta_com_underscore;
  end;

  [TestFixture]
  TScannerParamsTest = class
  private
    FTempDir: string;
    procedure CreatePage(const RelPath: string);
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Param_com_colchetes_deve_gerar_rota_dinamica;

    [Test]
    procedure Param_opcional_deve_gerar_duas_rotas;

    [Test]
    procedure Rotas_estaticas_devem_vir_antes_de_dinamicas;
  end;

  [TestFixture]
  TScannerGroupTest = class
  private
    FTempDir: string;
    procedure CreatePage(const RelPath: string);
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Grupo_com_parenteses_deve_ser_ignorado_na_rota;

    [Test]
    procedure Grupo_nao_deve_adicionar_segmento;
  end;

  [TestFixture]
  TScannerLayoutTest = class
  private
    FTempDir: string;
    procedure CreatePage(const RelPath: string);
    procedure CreateLayout(const RelDir: string);
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Deve_coletar_layout_da_pasta_atual;

    [Test]
    procedure Deve_coletar_layouts_ancestrais;

    [Test]
    procedure Sem_layout_deve_retornar_array_vazio;
  end;

  [TestFixture]
  TScannerEdgeCasesTest = class
  private
    FTempDir: string;
    procedure CreatePage(const RelPath: string);
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Rotas_duplicadas_nao_devem_ser_registradas_duas_vezes;

    [Test]
    procedure Nomes_com_hifen_devem_funcionar;

    [Test]
    procedure Profundidade_grande_deve_funcionar;
  end;

implementation

{ Helpers }

procedure TScannerBasicTest.CreatePage(const RelPath: string);
begin
  var FullDir := TPath.Combine(FTempDir, RelPath);
  ForceDirectories(FullDir);
  TFile.WriteAllText(TPath.Combine(FullDir, 'page.html'), '<p>page</p>');
end;

procedure TScannerParamsTest.CreatePage(const RelPath: string);
begin
  var FullDir := TPath.Combine(FTempDir, RelPath);
  ForceDirectories(FullDir);
  TFile.WriteAllText(TPath.Combine(FullDir, 'page.html'), '<p>page</p>');
end;

procedure TScannerGroupTest.CreatePage(const RelPath: string);
begin
  var FullDir := TPath.Combine(FTempDir, RelPath);
  ForceDirectories(FullDir);
  TFile.WriteAllText(TPath.Combine(FullDir, 'page.html'), '<p>page</p>');
end;

procedure TScannerLayoutTest.CreatePage(const RelPath: string);
begin
  var FullDir := TPath.Combine(FTempDir, RelPath);
  ForceDirectories(FullDir);
  TFile.WriteAllText(TPath.Combine(FullDir, 'page.html'), '<p>page</p>');
end;

procedure TScannerLayoutTest.CreateLayout(const RelDir: string);
begin
  var FullDir := TPath.Combine(FTempDir, RelDir);
  ForceDirectories(FullDir);
  TFile.WriteAllText(TPath.Combine(FullDir, '_layout.html'), '<html>{{slot}}</html>');
end;

procedure TScannerEdgeCasesTest.CreatePage(const RelPath: string);
begin
  var FullDir := TPath.Combine(FTempDir, RelPath);
  ForceDirectories(FullDir);
  TFile.WriteAllText(TPath.Combine(FullDir, 'page.html'), '<p>page</p>');
end;

{ TScannerBasicTest }

procedure TScannerBasicTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegscan_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
end;

procedure TScannerBasicTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TScannerBasicTest.Diretorio_inexistente_deve_retornar_vazio;
begin
  var Pages := TScanner.New().Scan(TPath.Combine(FTempDir, 'nao_existe'));
  Assert.AreEqual(0, Length(Pages));
end;

procedure TScannerBasicTest.Raiz_deve_gerar_rota_barra;
begin
  // page.html direto na raiz = rota /
  TFile.WriteAllText(TPath.Combine(FTempDir, 'page.html'), '<p>root</p>');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual('/', Pages[0].Route);
end;

procedure TScannerBasicTest.Subpasta_deve_gerar_rota_com_segmento;
begin
  CreatePage('about');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual('/about', Pages[0].Route);
end;

procedure TScannerBasicTest.Multiplas_pastas_devem_gerar_multiplas_rotas;
begin
  CreatePage('about');
  CreatePage('contact');
  CreatePage('blog');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(3, Length(Pages));
end;

procedure TScannerBasicTest.Deve_ignorar_pasta_com_underscore;
begin
  CreatePage('_hidden');
  CreatePage('visible');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual('/visible', Pages[0].Route);
end;

{ TScannerParamsTest }

procedure TScannerParamsTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegscanp_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
end;

procedure TScannerParamsTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TScannerParamsTest.Param_com_colchetes_deve_gerar_rota_dinamica;
begin
  CreatePage('users\[id]');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual('/users/:id', Pages[0].Route);
end;

procedure TScannerParamsTest.Param_opcional_deve_gerar_duas_rotas;
begin
  CreatePage('blog\[[page]]');
  var Pages := TScanner.New().Scan(FTempDir);
  // Deve gerar /blog e /blog/:page
  Assert.AreEqual(2, Length(Pages));

  var HasShort := False;
  var HasLong := False;
  for var P in Pages do
  begin
    if P.Route = '/blog' then HasShort := True;
    if P.Route = '/blog/:page' then HasLong := True;
  end;

  Assert.IsTrue(HasShort, 'Deve ter rota /blog');
  Assert.IsTrue(HasLong, 'Deve ter rota /blog/:page');
end;

procedure TScannerParamsTest.Rotas_estaticas_devem_vir_antes_de_dinamicas;
begin
  CreatePage('users\[id]');
  CreatePage('users\profile');
  var Pages := TScanner.New().Scan(FTempDir);

  // A rota estatica /users/profile deve vir antes de /users/:id
  Assert.AreEqual(2, Length(Pages));
  Assert.AreEqual('/users/profile', Pages[0].Route);
  Assert.AreEqual('/users/:id', Pages[1].Route);
end;

{ TScannerGroupTest }

procedure TScannerGroupTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegscang_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
end;

procedure TScannerGroupTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TScannerGroupTest.Grupo_com_parenteses_deve_ser_ignorado_na_rota;
begin
  CreatePage('(auth)\login');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual('/login', Pages[0].Route);
end;

procedure TScannerGroupTest.Grupo_nao_deve_adicionar_segmento;
begin
  CreatePage('(admin)\dashboard');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual('/dashboard', Pages[0].Route);
end;

{ TScannerLayoutTest }

procedure TScannerLayoutTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegscanl_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
end;

procedure TScannerLayoutTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TScannerLayoutTest.Deve_coletar_layout_da_pasta_atual;
begin
  CreatePage('dashboard');
  CreateLayout('dashboard');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual(1, Length(Pages[0].Layouts));
end;

procedure TScannerLayoutTest.Deve_coletar_layouts_ancestrais;
begin
  CreatePage('admin\users');
  CreateLayout('admin\users'); // layout mais proximo
  CreateLayout('admin');        // layout pai
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual(2, Length(Pages[0].Layouts));
end;

procedure TScannerLayoutTest.Sem_layout_deve_retornar_array_vazio;
begin
  CreatePage('simple');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual(0, Length(Pages[0].Layouts));
end;

{ TScannerEdgeCasesTest }

procedure TScannerEdgeCasesTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegscane_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
end;

procedure TScannerEdgeCasesTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TScannerEdgeCasesTest.Rotas_duplicadas_nao_devem_ser_registradas_duas_vezes;
begin
  // Param opcional gera 2 rotas - mas se ja existe, nao duplica
  CreatePage('blog');
  var Pages := TScanner.New().Scan(FTempDir);
  // Apenas 1 rota
  var RouteCount := 0;
  for var P in Pages do
    if P.Route = '/blog' then
      Inc(RouteCount);
  Assert.AreEqual(1, RouteCount);
end;

procedure TScannerEdgeCasesTest.Nomes_com_hifen_devem_funcionar;
begin
  CreatePage('about-us');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual('/about-us', Pages[0].Route);
end;

procedure TScannerEdgeCasesTest.Profundidade_grande_deve_funcionar;
begin
  CreatePage('a\b\c\d\e');
  var Pages := TScanner.New().Scan(FTempDir);
  Assert.AreEqual(1, Length(Pages));
  Assert.AreEqual('/a/b/c/d/e', Pages[0].Route);
end;

initialization
  TDUnitX.RegisterTestFixture(TScannerBasicTest);
  TDUnitX.RegisterTestFixture(TScannerParamsTest);
  TDUnitX.RegisterTestFixture(TScannerGroupTest);
  TDUnitX.RegisterTestFixture(TScannerLayoutTest);
  TDUnitX.RegisterTestFixture(TScannerEdgeCasesTest);

end.
