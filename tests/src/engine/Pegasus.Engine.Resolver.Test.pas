unit Pegasus.Engine.Resolver.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Pegasus.Data.Page,
  Pegasus.Engine.Resolver;

type
  [TestFixture]
  TResolverValueTest = class
  public
    [Test]
    procedure Deve_resolver_string_simples;

    [Test]
    procedure Deve_resolver_integer;

    [Test]
    procedure Deve_resolver_double;

    [Test]
    procedure Deve_resolver_boolean_true;

    [Test]
    procedure Deve_resolver_boolean_false;

    [Test]
    procedure Deve_retornar_vazio_para_key_inexistente;

    [Test]
    procedure Deve_resolver_propriedade_de_objeto;

    [Test]
    procedure Deve_resolver_navegacao_profunda;

    [Test]
    procedure Deve_resolver_slot;
  end;

  [TestFixture]
  TResolverConditionTest = class
  public
    [Test]
    procedure Boolean_true_deve_ser_truthy;

    [Test]
    procedure Boolean_false_deve_ser_falsy;

    [Test]
    procedure String_vazia_deve_ser_falsy;

    [Test]
    procedure Comparacao_igual_string;

    [Test]
    procedure Comparacao_diferente;

    [Test]
    procedure Comparacao_menor_numerico;

    [Test]
    procedure Comparacao_maior_numerico;

    [Test]
    procedure Comparacao_menor_igual;

    [Test]
    procedure Comparacao_maior_igual;

    [Test]
    procedure Comparacao_com_literal_string;

    [Test]
    procedure Valor_1_deve_ser_truthy;

    [Test]
    procedure Valor_0_deve_ser_falsy;
  end;

  [TestFixture]
  TResolverListTest = class
  public
    [Test]
    procedure Deve_resolver_lista_de_objetos;

    [Test]
    procedure Deve_retornar_nil_para_key_inexistente;

    [Test]
    procedure Deve_retornar_nil_para_valor_nao_lista;
  end;

  [TestFixture]
  TResolverFilterTest = class
  public
    [Test]
    procedure Deve_aplicar_filtro_upper;

    [Test]
    procedure Deve_aplicar_filtro_lower;

    [Test]
    procedure Deve_aplicar_chain_de_filtros;

    [Test]
    procedure Sem_filtro_deve_retornar_valor_puro;

    [Test]
    procedure Filtro_inexistente_deve_retornar_valor_puro;
  end;

  [TestFixture]
  TResolverItemContextTest = class
  public
    [Test]
    procedure Deve_resolver_field_de_item_com_dot_notation;

    [Test]
    procedure Deve_resolver_navegacao_em_item;

    [Test]
    procedure Deve_resolver_property_simples_de_item;

    [Test]
    procedure Deve_resolver_property_aninhada_de_item;
  end;

implementation

type
  TPessoa = class
  public
    Nome: string;
    Idade: Integer;
    Ativo: Boolean;
    Salario: Double;
  end;

  TEndereco = class
  public
    Cidade: string;
    Estado: string;
  end;

  TCliente = class
  public
    Nome: string;
    Endereco: TEndereco;
    destructor Destroy; override;
  end;

{ TCliente }

destructor TCliente.Destroy;
begin
  Endereco.Free;
  inherited;
end;

{ TResolverValueTest }

procedure TResolverValueTest.Deve_resolver_string_simples;
begin
  var Data := PageData();
  Data.Writer.Add('titulo', 'Pegasus');
  Assert.AreEqual('Pegasus', Resolver.ResolveValue('titulo', Data.Reader, nil));
end;

procedure TResolverValueTest.Deve_resolver_integer;
begin
  var Data := PageData();
  Data.Writer.Add('total', 42);
  Assert.AreEqual('42', Resolver.ResolveValue('total', Data.Reader, nil));
end;

procedure TResolverValueTest.Deve_resolver_double;
begin
  var Data := PageData();
  Data.Writer.Add('preco', 19.5);
  var Result := Resolver.ResolveValue('preco', Data.Reader, nil);
  Assert.IsNotEmpty(Result);
end;

procedure TResolverValueTest.Deve_resolver_boolean_true;
begin
  var Data := PageData();
  Data.Writer.Add('ativo', True);
  Assert.AreEqual('True', Resolver.ResolveValue('ativo', Data.Reader, nil));
end;

procedure TResolverValueTest.Deve_resolver_boolean_false;
begin
  var Data := PageData();
  Data.Writer.Add('ativo', False);
  Assert.AreEqual('False', Resolver.ResolveValue('ativo', Data.Reader, nil));
end;

procedure TResolverValueTest.Deve_retornar_vazio_para_key_inexistente;
begin
  var Data := PageData();
  Assert.AreEqual('', Resolver.ResolveValue('fantasma', Data.Reader, nil));
end;

procedure TResolverValueTest.Deve_resolver_propriedade_de_objeto;
begin
  var Data := PageData();
  var P := TPessoa.Create;
  P.Nome := 'Maria';
  Data.Writer.Add('pessoa', P);
  Assert.AreEqual('Maria', Resolver.ResolveValue('pessoa.Nome', Data.Reader, nil));
end;

procedure TResolverValueTest.Deve_resolver_navegacao_profunda;
begin
  var Data := PageData();
  var C := TCliente.Create;
  C.Nome := 'Joao';
  C.Endereco := TEndereco.Create;
  C.Endereco.Cidade := 'Curitiba';
  try
    // Navegacao profunda funciona via item context (como no for loop)
    Assert.AreEqual('Curitiba', Resolver.ResolveValue('item.Endereco.Cidade', Data.Reader, C));
  finally
    C.Free;
  end;
end;

procedure TResolverValueTest.Deve_resolver_slot;
begin
  var Data := PageData();
  Data.Writer.SetSlot('Conteudo do slot');
  Assert.AreEqual('Conteudo do slot', Resolver.ResolveValue('slot', Data.Reader, nil));
end;

{ TResolverConditionTest }

procedure TResolverConditionTest.Boolean_true_deve_ser_truthy;
begin
  var Data := PageData();
  Data.Writer.Add('logado', True);
  Assert.IsTrue(Resolver.ResolveCondition('logado', Data.Reader, nil));
end;

procedure TResolverConditionTest.Boolean_false_deve_ser_falsy;
begin
  var Data := PageData();
  Data.Writer.Add('logado', False);
  Assert.IsFalse(Resolver.ResolveCondition('logado', Data.Reader, nil));
end;

procedure TResolverConditionTest.String_vazia_deve_ser_falsy;
begin
  var Data := PageData();
  Data.Writer.Add('nome', '');
  // Valor vazio -> ResolveValue retorna '' -> nao eh 'True' nem '1'
  Assert.IsFalse(Resolver.ResolveCondition('nome', Data.Reader, nil));
end;

procedure TResolverConditionTest.Comparacao_igual_string;
begin
  var Data := PageData();
  Data.Writer.Add('status', 'ativo');
  Assert.IsTrue(Resolver.ResolveCondition('status=''ativo''', Data.Reader, nil));
end;

procedure TResolverConditionTest.Comparacao_diferente;
begin
  var Data := PageData();
  Data.Writer.Add('tipo', 'admin');
  Assert.IsTrue(Resolver.ResolveCondition('tipo<>''user''', Data.Reader, nil));
end;

procedure TResolverConditionTest.Comparacao_menor_numerico;
begin
  var Data := PageData();
  Data.Writer.Add('idade', 17);
  Assert.IsTrue(Resolver.ResolveCondition('idade<18', Data.Reader, nil));
end;

procedure TResolverConditionTest.Comparacao_maior_numerico;
begin
  var Data := PageData();
  Data.Writer.Add('score', 85);
  Assert.IsTrue(Resolver.ResolveCondition('score>50', Data.Reader, nil));
end;

procedure TResolverConditionTest.Comparacao_menor_igual;
begin
  var Data := PageData();
  Data.Writer.Add('qtd', 10);
  Assert.IsTrue(Resolver.ResolveCondition('qtd<=10', Data.Reader, nil));
end;

procedure TResolverConditionTest.Comparacao_maior_igual;
begin
  var Data := PageData();
  Data.Writer.Add('nota', 7);
  Assert.IsTrue(Resolver.ResolveCondition('nota>=7', Data.Reader, nil));
end;

procedure TResolverConditionTest.Comparacao_com_literal_string;
begin
  var Data := PageData();
  Data.Writer.Add('cor', 'azul');
  Assert.IsTrue(Resolver.ResolveCondition('cor=''azul''', Data.Reader, nil));
  Assert.IsFalse(Resolver.ResolveCondition('cor=''verde''', Data.Reader, nil));
end;

procedure TResolverConditionTest.Valor_1_deve_ser_truthy;
begin
  var Data := PageData();
  Data.Writer.Add('flag', 1);
  Assert.IsTrue(Resolver.ResolveCondition('flag', Data.Reader, nil));
end;

procedure TResolverConditionTest.Valor_0_deve_ser_falsy;
begin
  var Data := PageData();
  Data.Writer.Add('flag', 0);
  Assert.IsFalse(Resolver.ResolveCondition('flag', Data.Reader, nil));
end;

{ TResolverListTest }

procedure TResolverListTest.Deve_resolver_lista_de_objetos;
begin
  var Data := PageData();
  var Lista := TObjectList<TObject>.Create(True);
  Lista.Add(TPessoa.Create);
  Lista.Add(TPessoa.Create);
  Data.Writer.Add('items', Lista);

  var Resolved := Resolver.ResolveList('items', Data.Reader, nil);
  Assert.IsNotNull(Resolved);
  Assert.AreEqual(2, Resolved.Count);
end;

procedure TResolverListTest.Deve_retornar_nil_para_key_inexistente;
begin
  var Data := PageData();
  var Resolved := Resolver.ResolveList('fantasma', Data.Reader, nil);
  Assert.IsNull(Resolved);
end;

procedure TResolverListTest.Deve_retornar_nil_para_valor_nao_lista;
begin
  var Data := PageData();
  Data.Writer.Add('nome', 'texto');
  var Resolved := Resolver.ResolveList('nome', Data.Reader, nil);
  Assert.IsNull(Resolved);
end;

{ TResolverFilterTest }

procedure TResolverFilterTest.Deve_aplicar_filtro_upper;
begin
  var Data := PageData();
  Data.Writer.Add('nome', 'maria');
  Assert.AreEqual('MARIA', Resolver.ResolveFilter('nome | upper', Data.Reader, nil));
end;

procedure TResolverFilterTest.Deve_aplicar_filtro_lower;
begin
  var Data := PageData();
  Data.Writer.Add('nome', 'JOAO');
  Assert.AreEqual('joao', Resolver.ResolveFilter('nome | lower', Data.Reader, nil));
end;

procedure TResolverFilterTest.Deve_aplicar_chain_de_filtros;
begin
  var Data := PageData();
  Data.Writer.Add('msg', '  Hello World  ');
  Assert.AreEqual('HELLO WORLD', Resolver.ResolveFilter('msg | trim | upper', Data.Reader, nil));
end;

procedure TResolverFilterTest.Sem_filtro_deve_retornar_valor_puro;
begin
  var Data := PageData();
  Data.Writer.Add('x', 'abc');
  Assert.AreEqual('abc', Resolver.ResolveFilter('x', Data.Reader, nil));
end;

procedure TResolverFilterTest.Filtro_inexistente_deve_retornar_valor_puro;
begin
  var Data := PageData();
  Data.Writer.Add('x', 'abc');
  Assert.AreEqual('abc', Resolver.ResolveFilter('x | filtroFake', Data.Reader, nil));
end;

{ TResolverItemContextTest }

procedure TResolverItemContextTest.Deve_resolver_field_de_item_com_dot_notation;
begin
  var Data := PageData();
  var Pessoa := TPessoa.Create;
  Pessoa.Nome := 'Carlos';
  Pessoa.Idade := 30;
  try
    // item.Nome -> navega no item passado como contexto (field publico)
    Assert.AreEqual('Carlos', Resolver.ResolveValue('item.Nome', Data.Reader, Pessoa));
    Assert.AreEqual('30', Resolver.ResolveValue('item.Idade', Data.Reader, Pessoa));
  finally
    Pessoa.Free;
  end;
end;

procedure TResolverItemContextTest.Deve_resolver_navegacao_em_item;
begin
  var Data := PageData();
  var Cliente := TCliente.Create;
  Cliente.Nome := 'Ana';
  Cliente.Endereco := TEndereco.Create;
  Cliente.Endereco.Cidade := 'SP';
  try
    Assert.AreEqual('SP', Resolver.ResolveValue('item.Endereco.Cidade', Data.Reader, Cliente));
  finally
    Cliente.Free;
  end;
end;

{ TResolverPropertyTest - testa navegacao com public properties }

type
  TProduto = class
  private
    FNome: string;
    FPreco: Double;
  public
    property Nome: string read FNome write FNome;
    property Preco: Double read FPreco write FPreco;
  end;

  TCategoria = class
  private
    FTitulo: string;
    FProduto: TProduto;
  public
    property Titulo: string read FTitulo write FTitulo;
    property Produto: TProduto read FProduto write FProduto;
    destructor Destroy; override;
  end;

destructor TCategoria.Destroy;
begin
  FProduto.Free;
  inherited;
end;

procedure TResolverItemContextTest.Deve_resolver_property_simples_de_item;
begin
  var Data := PageData();
  var Prod := TProduto.Create;
  Prod.Nome := 'Widget';
  try
    Assert.AreEqual('Widget', Resolver.ResolveValue('item.Nome', Data.Reader, Prod));
  finally
    Prod.Free;
  end;
end;

procedure TResolverItemContextTest.Deve_resolver_property_aninhada_de_item;
begin
  var Data := PageData();
  var Cat := TCategoria.Create;
  Cat.Titulo := 'Eletronicos';
  Cat.Produto := TProduto.Create;
  Cat.Produto.Nome := 'Notebook';
  try
    Assert.AreEqual('Notebook', Resolver.ResolveValue('item.Produto.Nome', Data.Reader, Cat));
  finally
    Cat.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TResolverValueTest);
  TDUnitX.RegisterTestFixture(TResolverConditionTest);
  TDUnitX.RegisterTestFixture(TResolverListTest);
  TDUnitX.RegisterTestFixture(TResolverFilterTest);
  TDUnitX.RegisterTestFixture(TResolverItemContextTest);

end.
