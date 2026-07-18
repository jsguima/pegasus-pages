unit Pegasus.Engine.Parser.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Pegasus.Engine.Lexer,
  Pegasus.Engine.Parser,
  Pegasus.Engine.Nodes;

type
  [TestFixture]
  TParserBasicTest = class
  public
    [Test]
    procedure Texto_puro_deve_gerar_TextNode;

    [Test]
    procedure Expressao_deve_gerar_ExprNode;

    [Test]
    procedure Raw_deve_gerar_RawExprNode;

    [Test]
    procedure Partial_deve_gerar_PartialNode;

    [Test]
    procedure Multiplos_nodes_em_sequencia;
  end;

  [TestFixture]
  TParserForTest = class
  public
    [Test]
    procedure For_basico_deve_criar_ForNode;

    [Test]
    procedure For_deve_ter_varname_e_listname;

    [Test]
    procedure For_com_children;

    [Test]
    procedure For_com_else;

    [Test]
    procedure For_sem_endfor_deve_levantar_erro;

    [Test]
    procedure For_sintaxe_invalida_deve_levantar_erro;

    [Test]
    procedure For_aninhado;
  end;

  [TestFixture]
  TParserIfTest = class
  public
    [Test]
    procedure If_basico_deve_criar_IfNode;

    [Test]
    procedure If_com_else;

    [Test]
    procedure If_com_else_if;

    [Test]
    procedure If_sem_endif_deve_levantar_erro;

    [Test]
    procedure If_aninhado;

    [Test]
    procedure If_com_multiplos_else_if;
  end;

  [TestFixture]
  TParserErrorTest = class
  public
    [Test]
    procedure EndFor_sem_for_deve_levantar_erro;

    [Test]
    procedure EndIf_sem_if_deve_levantar_erro;

    [Test]
    procedure Else_sem_if_deve_levantar_erro;
  end;

  [TestFixture]
  TParserComplexTest = class
  public
    [Test]
    procedure Template_completo_com_if_for_e_expressoes;

    [Test]
    procedure For_dentro_de_if;

    [Test]
    procedure If_dentro_de_for;
  end;

implementation

function ParseSource(const Source: string): INodeListOwner;
begin
  var Tokens := Lexer(Source).Tokenize;
  Result := Parser(Tokens).Parse;
end;

{ TParserBasicTest }

procedure TParserBasicTest.Texto_puro_deve_gerar_TextNode;
begin
  var Owner := ParseSource('Hello');
  var Reader := Owner.Reader;
  Assert.AreEqual(1, Reader.Count);
  Assert.AreEqual(Ord(nkText), Ord(Reader[0].Kind));
  Assert.AreEqual('Hello', TTextNode(Reader[0]).Text);
end;

procedure TParserBasicTest.Expressao_deve_gerar_ExprNode;
begin
  var Owner := ParseSource('{{titulo}}');
  var Reader := Owner.Reader;
  Assert.AreEqual(1, Reader.Count);
  Assert.AreEqual(Ord(nkExpr), Ord(Reader[0].Kind));
  Assert.AreEqual('titulo', TExprNode(Reader[0]).Expr);
end;

procedure TParserBasicTest.Raw_deve_gerar_RawExprNode;
begin
  var Owner := ParseSource('{{raw conteudo}}');
  var Reader := Owner.Reader;
  Assert.AreEqual(1, Reader.Count);
  Assert.AreEqual(Ord(nkRawExpr), Ord(Reader[0].Kind));
  Assert.AreEqual('conteudo', TRawExprNode(Reader[0]).Expr);
end;

procedure TParserBasicTest.Partial_deve_gerar_PartialNode;
begin
  var Owner := ParseSource('{{partial _footer}}');
  var Reader := Owner.Reader;
  Assert.AreEqual(1, Reader.Count);
  Assert.AreEqual(Ord(nkPartial), Ord(Reader[0].Kind));
  Assert.AreEqual('_footer', TPartialNode(Reader[0]).PartialName);
end;

procedure TParserBasicTest.Multiplos_nodes_em_sequencia;
begin
  var Owner := ParseSource('<h1>{{titulo}}</h1>');
  var Reader := Owner.Reader;
  Assert.AreEqual(3, Reader.Count);
  Assert.AreEqual(Ord(nkText), Ord(Reader[0].Kind));
  Assert.AreEqual(Ord(nkExpr), Ord(Reader[1].Kind));
  Assert.AreEqual(Ord(nkText), Ord(Reader[2].Kind));
end;

{ TParserForTest }

procedure TParserForTest.For_basico_deve_criar_ForNode;
begin
  var Owner := ParseSource('{{for item in lista}}{{item.nome}}{{endfor}}');
  var Reader := Owner.Reader;
  Assert.AreEqual(1, Reader.Count);
  Assert.AreEqual(Ord(nkFor), Ord(Reader[0].Kind));
end;

procedure TParserForTest.For_deve_ter_varname_e_listname;
begin
  var Owner := ParseSource('{{for produto in produtos}}x{{endfor}}');
  var ForNode := TForNode(Owner.Reader[0]);
  Assert.AreEqual('produto', ForNode.VarName);
  Assert.AreEqual('produtos', ForNode.ListName);
end;

procedure TParserForTest.For_com_children;
begin
  var Owner := ParseSource('{{for x in items}}<li>{{x.nome}}</li>{{endfor}}');
  var ForNode := TForNode(Owner.Reader[0]);
  Assert.IsTrue(ForNode.Children.Count > 0);
end;

procedure TParserForTest.For_com_else;
begin
  var Owner := ParseSource('{{for x in items}}{{x}}{{else}}<p>Vazio</p>{{endfor}}');
  var ForNode := TForNode(Owner.Reader[0]);
  Assert.IsTrue(ForNode.Children.Count > 0);
  Assert.IsTrue(ForNode.ElseChildren.Count > 0);
  Assert.AreEqual(Ord(nkText), Ord(ForNode.ElseChildren[0].Kind));
end;

procedure TParserForTest.For_sem_endfor_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin ParseSource('{{for item in lista}}sem fechar'); end,
    EParserError);
end;

procedure TParserForTest.For_sintaxe_invalida_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin ParseSource('{{for item}}x{{endfor}}'); end,
    EParserError);
end;

procedure TParserForTest.For_aninhado;
begin
  var Source := '{{for cat in categorias}}{{for item in cat.items}}{{item}}{{endfor}}{{endfor}}';
  var Owner := ParseSource(Source);
  var OuterFor := TForNode(Owner.Reader[0]);
  Assert.AreEqual('cat', OuterFor.VarName);
  // Primeiro child deve ser outro ForNode
  Assert.AreEqual(Ord(nkFor), Ord(OuterFor.Children[0].Kind));
  var InnerFor := TForNode(OuterFor.Children[0]);
  Assert.AreEqual('item', InnerFor.VarName);
end;

{ TParserIfTest }

procedure TParserIfTest.If_basico_deve_criar_IfNode;
begin
  var Owner := ParseSource('{{if logado}}<p>Ola</p>{{endif}}');
  var Reader := Owner.Reader;
  Assert.AreEqual(1, Reader.Count);
  Assert.AreEqual(Ord(nkIf), Ord(Reader[0].Kind));
end;

procedure TParserIfTest.If_com_else;
begin
  var Owner := ParseSource('{{if auth}}OK{{else}}Login{{endif}}');
  var IfNode := TIfNode(Owner.Reader[0]);
  Assert.AreEqual(1, IfNode.Branches.Count);
  Assert.IsTrue(IfNode.ElseChildren.Count > 0);
end;

procedure TParserIfTest.If_com_else_if;
begin
  var Owner := ParseSource('{{if admin}}A{{else if mod}}M{{else}}U{{endif}}');
  var IfNode := TIfNode(Owner.Reader[0]);
  Assert.AreEqual(2, IfNode.Branches.Count); // if + else if
  Assert.AreEqual('admin', IfNode.Branches[0].Expr);
  Assert.AreEqual('mod', IfNode.Branches[1].Expr);
  Assert.IsTrue(IfNode.ElseChildren.Count > 0);
end;

procedure TParserIfTest.If_sem_endif_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin ParseSource('{{if x}}conteudo sem fechar'); end,
    EParserError);
end;

procedure TParserIfTest.If_aninhado;
begin
  var Source := '{{if a}}{{if b}}inner{{endif}}{{endif}}';
  var Owner := ParseSource(Source);
  var OuterIf := TIfNode(Owner.Reader[0]);
  Assert.AreEqual(1, OuterIf.Branches.Count);
  // Dentro do primeiro branch deve haver um IfNode
  var InnerNode := OuterIf.Branches[0].Children[0];
  Assert.AreEqual(Ord(nkIf), Ord(InnerNode.Kind));
end;

procedure TParserIfTest.If_com_multiplos_else_if;
begin
  var Source := '{{if x=''a''}}A{{else if x=''b''}}B{{else if x=''c''}}C{{else}}D{{endif}}';
  var Owner := ParseSource(Source);
  var IfNode := TIfNode(Owner.Reader[0]);
  Assert.AreEqual(3, IfNode.Branches.Count);
  Assert.IsTrue(IfNode.ElseChildren.Count > 0);
end;

{ TParserErrorTest }

procedure TParserErrorTest.EndFor_sem_for_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin ParseSource('{{endfor}}'); end,
    EParserError);
end;

procedure TParserErrorTest.EndIf_sem_if_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin ParseSource('{{endif}}'); end,
    EParserError);
end;

procedure TParserErrorTest.Else_sem_if_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin ParseSource('{{else}}'); end,
    EParserError);
end;

{ TParserComplexTest }

procedure TParserComplexTest.Template_completo_com_if_for_e_expressoes;
begin
  var Source :=
    '<h1>{{titulo}}</h1>' +
    '{{if items}}' +
    '{{for item in items}}<p>{{item.nome}}</p>{{endfor}}' +
    '{{else}}' +
    '<p>Sem items</p>' +
    '{{endif}}';

  var Owner := ParseSource(Source);
  var Reader := Owner.Reader;
  // h1 text + expr + /h1 text + IfNode = nodes variados
  Assert.IsTrue(Reader.Count >= 3);
end;

procedure TParserComplexTest.For_dentro_de_if;
begin
  var Source := '{{if hasItems}}{{for item in items}}{{item}}{{endfor}}{{endif}}';
  var Owner := ParseSource(Source);
  var IfNode := TIfNode(Owner.Reader[0]);
  Assert.AreEqual(Ord(nkFor), Ord(IfNode.Branches[0].Children[0].Kind));
end;

procedure TParserComplexTest.If_dentro_de_for;
begin
  var Source := '{{for item in items}}{{if item.ativo}}{{item.nome}}{{endif}}{{endfor}}';
  var Owner := ParseSource(Source);
  var ForNode := TForNode(Owner.Reader[0]);
  Assert.AreEqual(Ord(nkIf), Ord(ForNode.Children[0].Kind));
end;

initialization
  TDUnitX.RegisterTestFixture(TParserBasicTest);
  TDUnitX.RegisterTestFixture(TParserForTest);
  TDUnitX.RegisterTestFixture(TParserIfTest);
  TDUnitX.RegisterTestFixture(TParserErrorTest);
  TDUnitX.RegisterTestFixture(TParserComplexTest);

end.
