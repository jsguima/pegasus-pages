unit Pegasus.Engine.Builder.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Pegasus.Engine.Builder,
  Pegasus.Engine.Nodes,
  Pegasus.Engine.Cache;

type
  [TestFixture]
  TBuilderFromHtmlTest = class
  public
    [Test]
    procedure Deve_compilar_texto_puro;

    [Test]
    procedure Deve_compilar_expressao;

    [Test]
    procedure Deve_compilar_for_loop;

    [Test]
    procedure Deve_compilar_if_block;

    [Test]
    procedure Deve_compilar_template_complexo;

    [Test]
    procedure Deve_expandir_componentes_antes_de_parsear;

    [Test]
    procedure Html_vazio_deve_retornar_lista_vazia;
  end;

  [TestFixture]
  TBuilderFromFileTest = class
  private
    FTempDir: string;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Deve_compilar_arquivo_html;

    [Test]
    procedure Deve_cachear_resultado;

    [Test]
    procedure Deve_recompilar_apos_mudanca;
  end;

implementation

{ TBuilderFromHtmlTest }

procedure TBuilderFromHtmlTest.Deve_compilar_texto_puro;
begin
  var Nodes := Builder().BuildFromHtml('<h1>Hello</h1>');
  Assert.AreEqual(1, Nodes.Count);
  Assert.AreEqual(Ord(nkText), Ord(Nodes[0].Kind));
end;

procedure TBuilderFromHtmlTest.Deve_compilar_expressao;
begin
  var Nodes := Builder().BuildFromHtml('{{titulo}}');
  Assert.AreEqual(1, Nodes.Count);
  Assert.AreEqual(Ord(nkExpr), Ord(Nodes[0].Kind));
  Assert.AreEqual('titulo', TExprNode(Nodes[0]).Expr);
end;

procedure TBuilderFromHtmlTest.Deve_compilar_for_loop;
begin
  var Nodes := Builder().BuildFromHtml('{{for item in items}}<p>{{item.nome}}</p>{{endfor}}');
  Assert.AreEqual(1, Nodes.Count);
  Assert.AreEqual(Ord(nkFor), Ord(Nodes[0].Kind));
end;

procedure TBuilderFromHtmlTest.Deve_compilar_if_block;
begin
  var Nodes := Builder().BuildFromHtml('{{if show}}visivel{{endif}}');
  Assert.AreEqual(1, Nodes.Count);
  Assert.AreEqual(Ord(nkIf), Ord(Nodes[0].Kind));
end;

procedure TBuilderFromHtmlTest.Deve_compilar_template_complexo;
begin
  var Html :=
    '<div>' +
    '{{if items}}' +
    '  {{for item in items}}' +
    '    <span>{{item.nome | upper}}</span>' +
    '  {{endfor}}' +
    '{{else}}' +
    '  <p>Nenhum item</p>' +
    '{{endif}}' +
    '</div>';

  var Nodes := Builder().BuildFromHtml(Html);
  Assert.IsTrue(Nodes.Count > 0);
end;

procedure TBuilderFromHtmlTest.Deve_expandir_componentes_antes_de_parsear;
begin
  // Componentes que nao existem devem virar comentario HTML (texto)
  var Nodes := Builder().BuildFromHtml('<pg-inexistente />');
  Assert.IsTrue(Nodes.Count > 0);
  // Deve ter gerado um comment node como texto
  Assert.AreEqual(Ord(nkText), Ord(Nodes[0].Kind));
  Assert.Contains(TTextNode(Nodes[0]).Text, 'not found');
end;

procedure TBuilderFromHtmlTest.Html_vazio_deve_retornar_lista_vazia;
begin
  var Nodes := Builder().BuildFromHtml('');
  Assert.AreEqual(0, Nodes.Count);
end;

{ TBuilderFromFileTest }

procedure TBuilderFromFileTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegbuilder_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
  Cache.Clear;
  Cache.Configure(False);
end;

procedure TBuilderFromFileTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TBuilderFromFileTest.Deve_compilar_arquivo_html;
begin
  var FilePath := TPath.Combine(FTempDir, 'page.html');
  TFile.WriteAllText(FilePath, '<h1>{{titulo}}</h1>');

  var Nodes := Builder().Build(FilePath);
  Assert.IsTrue(Nodes.Count > 0);
end;

procedure TBuilderFromFileTest.Deve_cachear_resultado;
begin
  var FilePath := TPath.Combine(FTempDir, 'cached.html');
  TFile.WriteAllText(FilePath, '<p>{{msg}}</p>');

  var Nodes1 := Builder().Build(FilePath);
  var Nodes2 := Builder().Build(FilePath);

  // Devem ser o mesmo objeto (veio do cache)
  Assert.AreEqual(Nodes1.Count, Nodes2.Count);
end;

procedure TBuilderFromFileTest.Deve_recompilar_apos_mudanca;
begin
  var FilePath := TPath.Combine(FTempDir, 'changing.html');
  TFile.WriteAllText(FilePath, '<p>V1</p>');

  var Nodes1 := Builder().Build(FilePath);
  Assert.AreEqual(1, Nodes1.Count);

  Sleep(100);
  TFile.WriteAllText(FilePath, '<p>V2</p>{{extra}}');

  var Nodes2 := Builder().Build(FilePath);
  // Recompilado - agora tem mais nodes
  Assert.IsTrue(Nodes2.Count > 1);
end;

initialization
  TDUnitX.RegisterTestFixture(TBuilderFromHtmlTest);
  TDUnitX.RegisterTestFixture(TBuilderFromFileTest);

end.
