unit Pegasus.UI.Partials.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Pegasus.UI.Partials,
  Pegasus.Engine.Nodes,
  Pegasus.Engine.Cache;

type
  [TestFixture]
  TPartialRegistryLoadTest = class
  private
    FTempDir: string;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Deve_carregar_partials_com_underscore;

    [Test]
    procedure Deve_ignorar_arquivos_sem_underscore;

    [Test]
    procedure Deve_retornar_nil_para_partial_inexistente;

    [Test]
    procedure Deve_retornar_nodes_para_partial_existente;

    [Test]
    procedure Deve_normalizar_nome_para_lowercase;

    [Test]
    procedure Deve_lidar_com_diretorio_inexistente;

    [Test]
    procedure Deve_carregar_multiplos_partials;
  end;

  [TestFixture]
  TPartialRegistryGetNodesTest = class
  private
    FTempDir: string;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Deve_compilar_e_retornar_nodes;

    [Test]
    procedure Partial_com_expressao_deve_ter_ExprNode;

    [Test]
    procedure Partial_com_html_puro_deve_ter_TextNode;
  end;

implementation

{ TPartialRegistryLoadTest }

procedure TPartialRegistryLoadTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegpartial_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
  Cache.Clear;
end;

procedure TPartialRegistryLoadTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TPartialRegistryLoadTest.Deve_carregar_partials_com_underscore;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, '_header.html'), '<header>H</header>');
  PartialRegistry.Load(FTempDir);

  var Nodes := PartialRegistry.GetNodes('_header');
  Assert.IsNotNull(Nodes);
end;

procedure TPartialRegistryLoadTest.Deve_ignorar_arquivos_sem_underscore;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, 'normal.html'), '<p>normal</p>');
  PartialRegistry.Load(FTempDir);

  var Nodes := PartialRegistry.GetNodes('normal');
  Assert.IsNull(Nodes);
end;

procedure TPartialRegistryLoadTest.Deve_retornar_nil_para_partial_inexistente;
begin
  var Nodes := PartialRegistry.GetNodes('_fantasma_xyz');
  Assert.IsNull(Nodes);
end;

procedure TPartialRegistryLoadTest.Deve_retornar_nodes_para_partial_existente;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, '_footer.html'), '<footer>F</footer>');
  PartialRegistry.Load(FTempDir);

  var Nodes := PartialRegistry.GetNodes('_footer');
  Assert.IsNotNull(Nodes);
  Assert.IsTrue(Nodes.Count > 0);
end;

procedure TPartialRegistryLoadTest.Deve_normalizar_nome_para_lowercase;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, '_NavBar.html'), '<nav>Nav</nav>');
  PartialRegistry.Load(FTempDir);

  // Arquivo _NavBar.html fica como _navbar no registry
  var Nodes := PartialRegistry.GetNodes('_navbar');
  Assert.IsNotNull(Nodes);
end;

procedure TPartialRegistryLoadTest.Deve_lidar_com_diretorio_inexistente;
begin
  // Nao deve levantar exception
  PartialRegistry.Load(TPath.Combine(FTempDir, 'nao_existe'));
  Assert.Pass;
end;

procedure TPartialRegistryLoadTest.Deve_carregar_multiplos_partials;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, '_head.html'), '<head/>');
  TFile.WriteAllText(TPath.Combine(FTempDir, '_foot.html'), '<foot/>');
  TFile.WriteAllText(TPath.Combine(FTempDir, '_side.html'), '<side/>');
  PartialRegistry.Load(FTempDir);

  Assert.IsNotNull(PartialRegistry.GetNodes('_head'));
  Assert.IsNotNull(PartialRegistry.GetNodes('_foot'));
  Assert.IsNotNull(PartialRegistry.GetNodes('_side'));
end;

{ TPartialRegistryGetNodesTest }

procedure TPartialRegistryGetNodesTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegpartial2_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
  Cache.Clear;
end;

procedure TPartialRegistryGetNodesTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TPartialRegistryGetNodesTest.Deve_compilar_e_retornar_nodes;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, '_card.html'), '<div class="card">{{titulo}}</div>');
  PartialRegistry.Load(FTempDir);

  var Nodes := PartialRegistry.GetNodes('_card');
  Assert.IsNotNull(Nodes);
  Assert.IsTrue(Nodes.Count > 0);
end;

procedure TPartialRegistryGetNodesTest.Partial_com_expressao_deve_ter_ExprNode;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, '_greet.html'), '{{nome}}');
  PartialRegistry.Load(FTempDir);

  var Nodes := PartialRegistry.GetNodes('_greet');
  Assert.IsNotNull(Nodes);
  Assert.AreEqual(1, Nodes.Count);
  Assert.AreEqual(Ord(nkExpr), Ord(Nodes[0].Kind));
end;

procedure TPartialRegistryGetNodesTest.Partial_com_html_puro_deve_ter_TextNode;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, '_static.html'), '<hr />');
  PartialRegistry.Load(FTempDir);

  var Nodes := PartialRegistry.GetNodes('_static');
  Assert.IsNotNull(Nodes);
  Assert.AreEqual(1, Nodes.Count);
  Assert.AreEqual(Ord(nkText), Ord(Nodes[0].Kind));
end;

initialization
  TDUnitX.RegisterTestFixture(TPartialRegistryLoadTest);
  TDUnitX.RegisterTestFixture(TPartialRegistryGetNodesTest);

end.
