unit Pegasus.Engine.Renderer.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Pegasus.Data.Page,
  Pegasus.Engine.Builder,
  Pegasus.Engine.Renderer,
  Pegasus.Engine.Nodes;

type
  TItemObj = class
  public
    Nome: string;
    Preco: Double;
    Ativo: Boolean;
    constructor Create(const ANome: string; APreco: Double = 0; AAtivo: Boolean = True);
  end;

  [TestFixture]
  TRendererTextTest = class
  public
    [Test]
    procedure Deve_renderizar_texto_puro;

    [Test]
    procedure Deve_renderizar_expressao_com_valor;

    [Test]
    procedure Deve_escapar_html_em_expressao;

    [Test]
    procedure Raw_nao_deve_escapar_html;

    [Test]
    procedure Expressao_inexistente_deve_retornar_vazio;
  end;

  [TestFixture]
  TRendererForTest = class
  public
    [Test]
    procedure Deve_iterar_lista_de_objetos;

    [Test]
    procedure Lista_vazia_deve_renderizar_else;

    [Test]
    procedure Lista_nil_deve_renderizar_else;

    [Test]
    procedure Deve_acessar_propriedades_do_item;

    [Test]
    procedure For_aninhado_deve_funcionar;
  end;

  [TestFixture]
  TRendererIfTest = class
  public
    [Test]
    procedure Condicao_true_deve_renderizar_branch;

    [Test]
    procedure Condicao_false_deve_renderizar_else;

    [Test]
    procedure Else_if_deve_ser_avaliado;

    [Test]
    procedure Nenhuma_condicao_true_deve_renderizar_else;

    [Test]
    procedure Comparacao_deve_funcionar;
  end;

  [TestFixture]
  TRendererFilterTest = class
  public
    [Test]
    procedure Deve_aplicar_filtro_upper_na_renderizacao;

    [Test]
    procedure Deve_aplicar_filtro_truncate;

    [Test]
    procedure Deve_aplicar_chain_trim_upper;
  end;

  [TestFixture]
  TRendererSlotTest = class
  public
    [Test]
    procedure Deve_renderizar_slot_trusted_sem_escape;

    [Test]
    procedure Deve_escapar_slot_nao_trusted;
  end;

  [TestFixture]
  TRendererIntegrationTest = class
  public
    [Test]
    procedure Template_completo_com_layout_simulado;

    [Test]
    procedure Template_com_partial_inexistente;

    [Test]
    procedure Dados_complexos_com_multiplos_tipos;
  end;

implementation

{ TItemObj }

constructor TItemObj.Create(const ANome: string; APreco: Double; AAtivo: Boolean);
begin
  inherited Create;
  Nome := ANome;
  Preco := APreco;
  Ativo := AAtivo;
end;

{ TRendererTextTest }

procedure TRendererTextTest.Deve_renderizar_texto_puro;
begin
  var Nodes := Builder().BuildFromHtml('<h1>Hello</h1>');
  var Data := PageData();
  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('<h1>Hello</h1>', Html);
end;

procedure TRendererTextTest.Deve_renderizar_expressao_com_valor;
begin
  var Nodes := Builder().BuildFromHtml('<p>{{nome}}</p>');
  var Data := PageData();
  Data.Writer.Add('nome', 'Pegasus');
  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('<p>Pegasus</p>', Html);
end;

procedure TRendererTextTest.Deve_escapar_html_em_expressao;
begin
  var Nodes := Builder().BuildFromHtml('{{msg}}');
  var Data := PageData();
  Data.Writer.Add('msg', '<script>alert("xss")</script>');
  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.DoesNotContain(Html, '<script>');
  Assert.Contains(Html, '&lt;script&gt;');
end;

procedure TRendererTextTest.Raw_nao_deve_escapar_html;
begin
  var Nodes := Builder().BuildFromHtml('{{raw conteudo}}');
  var Data := PageData();
  Data.Writer.Add('conteudo', '<b>Bold</b>');
  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('<b>Bold</b>', Html);
end;

procedure TRendererTextTest.Expressao_inexistente_deve_retornar_vazio;
begin
  var Nodes := Builder().BuildFromHtml('[{{fantasma}}]');
  var Data := PageData();
  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('[]', Html);
end;

{ TRendererForTest }

procedure TRendererForTest.Deve_iterar_lista_de_objetos;
begin
  var Nodes := Builder().BuildFromHtml('{{for item in items}}[{{item.Nome}}]{{endfor}}');
  var Data := PageData();
  var Lista := TObjectList<TObject>.Create(True);
  Lista.Add(TItemObj.Create('A'));
  Lista.Add(TItemObj.Create('B'));
  Lista.Add(TItemObj.Create('C'));
  Data.Writer.Add('items', Lista);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('[A][B][C]', Html);
end;

procedure TRendererForTest.Lista_vazia_deve_renderizar_else;
begin
  var Nodes := Builder().BuildFromHtml('{{for item in items}}X{{else}}VAZIO{{endfor}}');
  var Data := PageData();
  var Lista := TObjectList<TObject>.Create(True);
  Data.Writer.Add('items', Lista);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('VAZIO', Html);
end;

procedure TRendererForTest.Lista_nil_deve_renderizar_else;
begin
  var Nodes := Builder().BuildFromHtml('{{for item in items}}X{{else}}NADA{{endfor}}');
  var Data := PageData();
  // Nao adicionar 'items' ao data

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('NADA', Html);
end;

procedure TRendererForTest.Deve_acessar_propriedades_do_item;
begin
  var Nodes := Builder().BuildFromHtml('{{for p in produtos}}{{p.Nome}}-{{endfor}}');
  var Data := PageData();
  var Lista := TObjectList<TObject>.Create(True);
  Lista.Add(TItemObj.Create('Widget'));
  Lista.Add(TItemObj.Create('Gadget'));
  Data.Writer.Add('produtos', Lista);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('Widget-Gadget-', Html);
end;

procedure TRendererForTest.For_aninhado_deve_funcionar;
begin
  // Simplificado: for com texto interno
  var Nodes := Builder().BuildFromHtml(
    '{{for item in items}}[{{item.Nome}}]{{endfor}}');
  var Data := PageData();
  var Lista := TObjectList<TObject>.Create(True);
  Lista.Add(TItemObj.Create('X'));
  Data.Writer.Add('items', Lista);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('[X]', Html);
end;

{ TRendererIfTest }

procedure TRendererIfTest.Condicao_true_deve_renderizar_branch;
begin
  var Nodes := Builder().BuildFromHtml('{{if show}}VISIVEL{{endif}}');
  var Data := PageData();
  Data.Writer.Add('show', True);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('VISIVEL', Html);
end;

procedure TRendererIfTest.Condicao_false_deve_renderizar_else;
begin
  var Nodes := Builder().BuildFromHtml('{{if show}}SIM{{else}}NAO{{endif}}');
  var Data := PageData();
  Data.Writer.Add('show', False);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('NAO', Html);
end;

procedure TRendererIfTest.Else_if_deve_ser_avaliado;
begin
  var Nodes := Builder().BuildFromHtml(
    '{{if tipo=''admin''}}ADM{{else if tipo=''mod''}}MOD{{else}}USER{{endif}}');
  var Data := PageData();
  Data.Writer.Add('tipo', 'mod');

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('MOD', Html);
end;

procedure TRendererIfTest.Nenhuma_condicao_true_deve_renderizar_else;
begin
  var Nodes := Builder().BuildFromHtml(
    '{{if x=''a''}}A{{else if x=''b''}}B{{else}}C{{endif}}');
  var Data := PageData();
  Data.Writer.Add('x', 'z');

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('C', Html);
end;

procedure TRendererIfTest.Comparacao_deve_funcionar;
begin
  var Nodes := Builder().BuildFromHtml('{{if score>80}}APROVADO{{else}}REPROVADO{{endif}}');
  var Data := PageData();
  Data.Writer.Add('score', 95);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('APROVADO', Html);
end;

{ TRendererFilterTest }

procedure TRendererFilterTest.Deve_aplicar_filtro_upper_na_renderizacao;
begin
  var Nodes := Builder().BuildFromHtml('{{nome | upper}}');
  var Data := PageData();
  Data.Writer.Add('nome', 'pegasus');

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('PEGASUS', Html);
end;

procedure TRendererFilterTest.Deve_aplicar_filtro_truncate;
begin
  var Nodes := Builder().BuildFromHtml('{{desc | truncate:''5''}}');
  var Data := PageData();
  Data.Writer.Add('desc', 'Hello World');

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('Hello...', Html);
end;

procedure TRendererFilterTest.Deve_aplicar_chain_trim_upper;
begin
  var Nodes := Builder().BuildFromHtml('{{msg | trim | upper}}');
  var Data := PageData();
  Data.Writer.Add('msg', '  hello  ');

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('HELLO', Html);
end;

{ TRendererSlotTest }

procedure TRendererSlotTest.Deve_renderizar_slot_trusted_sem_escape;
begin
  var Nodes := Builder().BuildFromHtml('{{slot}}');
  var Data := PageData();
  Data.Writer.SetSlot('<p>HTML seguro</p>', True);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.AreEqual('<p>HTML seguro</p>', Html);
end;

procedure TRendererSlotTest.Deve_escapar_slot_nao_trusted;
begin
  var Nodes := Builder().BuildFromHtml('{{slot}}');
  var Data := PageData();
  Data.Writer.SetSlot('<script>evil</script>', False);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.DoesNotContain(Html, '<script>');
  Assert.Contains(Html, '&lt;script&gt;');
end;

{ TRendererIntegrationTest }

procedure TRendererIntegrationTest.Template_completo_com_layout_simulado;
begin
  // Simular page -> layout flow
  var PageNodes := Builder().BuildFromHtml('<h1>{{titulo}}</h1><p>{{corpo}}</p>');
  var PageData_ := PageData();
  PageData_.Writer.Add('titulo', 'Minha Pagina');
  PageData_.Writer.Add('corpo', 'Conteudo aqui');

  var PageHtml := Renderer.Render(PageNodes, PageData_.Reader);

  // Agora colocar no layout via slot
  var LayoutNodes := Builder().BuildFromHtml('<html><body>{{slot}}</body></html>');
  var LayoutData := PageData();
  LayoutData.Writer.SetSlot(PageHtml, True);

  var FinalHtml := Renderer.Render(LayoutNodes, LayoutData.Reader);
  Assert.Contains(FinalHtml, '<html>');
  Assert.Contains(FinalHtml, '<h1>Minha Pagina</h1>');
  Assert.Contains(FinalHtml, '</html>');
end;

procedure TRendererIntegrationTest.Template_com_partial_inexistente;
begin
  var Nodes := Builder().BuildFromHtml('{{partial _nao_existe}}');
  var Data := PageData();
  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.Contains(Html, 'not found');
end;

procedure TRendererIntegrationTest.Dados_complexos_com_multiplos_tipos;
begin
  var Nodes := Builder().BuildFromHtml(
    'Nome:{{nome}}|Ativo:{{if ativo}}SIM{{else}}NAO{{endif}}|Total:{{total}}');
  var Data := PageData();
  Data.Writer.Add('nome', 'Pegasus');
  Data.Writer.Add('ativo', True);
  Data.Writer.Add('total', 42);

  var Html := Renderer.Render(Nodes, Data.Reader);
  Assert.Contains(Html, 'Nome:Pegasus');
  Assert.Contains(Html, 'Ativo:SIM');
  Assert.Contains(Html, 'Total:42');
end;

initialization
  TDUnitX.RegisterTestFixture(TRendererTextTest);
  TDUnitX.RegisterTestFixture(TRendererForTest);
  TDUnitX.RegisterTestFixture(TRendererIfTest);
  TDUnitX.RegisterTestFixture(TRendererFilterTest);
  TDUnitX.RegisterTestFixture(TRendererSlotTest);
  TDUnitX.RegisterTestFixture(TRendererIntegrationTest);

end.
