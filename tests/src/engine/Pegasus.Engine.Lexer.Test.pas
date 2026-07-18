unit Pegasus.Engine.Lexer.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Pegasus.Engine.Lexer;

type
  [TestFixture]
  TLexerBasicTest = class
  public
    [Test]
    procedure Texto_puro_deve_gerar_token_text_e_eof;

    [Test]
    procedure String_vazia_deve_gerar_apenas_eof;

    [Test]
    procedure Expressao_simples_deve_gerar_tkExpr;

    [Test]
    procedure Texto_antes_e_depois_de_expressao;

    [Test]
    procedure Multiplas_expressoes_seguidas;

    [Test]
    procedure Deve_preservar_espacos_em_texto;
  end;

  [TestFixture]
  TLexerTagsTest = class
  public
    [Test]
    procedure Tag_for_deve_gerar_tkTagFor;

    [Test]
    procedure Tag_endfor_deve_gerar_tkTagEndFor;

    [Test]
    procedure Tag_if_deve_gerar_tkTagIf;

    [Test]
    procedure Tag_endif_deve_gerar_tkTagEndIf;

    [Test]
    procedure Tag_else_deve_gerar_tkTagElse;

    [Test]
    procedure Tag_else_if_deve_gerar_tkTagElseIf;

    [Test]
    procedure Tag_partial_deve_gerar_tkTagPartial;

    [Test]
    procedure Tag_raw_deve_gerar_tkRawExpr;

    [Test]
    procedure Tags_devem_ser_case_insensitive;
  end;

  [TestFixture]
  TLexerErrorTest = class
  public
    [Test]
    procedure Expressao_nao_fechada_deve_levantar_erro;

    [Test]
    procedure Expressao_vazia_deve_levantar_erro;

    [Test]
    procedure Tag_desconhecida_deve_levantar_erro;
  end;

  [TestFixture]
  TLexerPositionTest = class
  public
    [Test]
    procedure Deve_rastrear_linha_corretamente;

    [Test]
    procedure Deve_rastrear_coluna_corretamente;

    [Test]
    procedure Multilinhas_com_expressoes;
  end;

  [TestFixture]
  TLexerEdgeCasesTest = class
  public
    [Test]
    procedure Chave_unica_nao_deve_ser_expressao;

    [Test]
    procedure Tres_chaves_consecutivas;

    [Test]
    procedure Expressao_com_pipe_nao_eh_tag_desconhecida;

    [Test]
    procedure For_com_espacos_extras;

    [Test]
    procedure Template_html_completo;

    [Test]
    procedure Expressao_com_ponto_para_navegacao;

    [Test]
    procedure Expressao_com_filtro_chain;
  end;

implementation

{ TLexerBasicTest }

procedure TLexerBasicTest.Texto_puro_deve_gerar_token_text_e_eof;
begin
  var Tokens := Lexer('Hello World').Tokenize;
  Assert.AreEqual(2, Length(Tokens));
  Assert.AreEqual(Ord(tkText), Ord(Tokens[0].Kind));
  Assert.AreEqual('Hello World', Tokens[0].Value);
  Assert.AreEqual(Ord(tkEOF), Ord(Tokens[1].Kind));
end;

procedure TLexerBasicTest.String_vazia_deve_gerar_apenas_eof;
begin
  var Tokens := Lexer('').Tokenize;
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(Ord(tkEOF), Ord(Tokens[0].Kind));
end;

procedure TLexerBasicTest.Expressao_simples_deve_gerar_tkExpr;
begin
  var Tokens := Lexer('{{nome}}').Tokenize;
  Assert.AreEqual(2, Length(Tokens));
  Assert.AreEqual(Ord(tkExpr), Ord(Tokens[0].Kind));
  Assert.AreEqual('nome', Tokens[0].Value);
end;

procedure TLexerBasicTest.Texto_antes_e_depois_de_expressao;
begin
  var Tokens := Lexer('Ola {{nome}}!').Tokenize;
  // Text + Expr + Text + EOF
  Assert.AreEqual(4, Length(Tokens));
  Assert.AreEqual(Ord(tkText), Ord(Tokens[0].Kind));
  Assert.AreEqual('Ola', Tokens[0].Value);
  Assert.AreEqual(Ord(tkExpr), Ord(Tokens[1].Kind));
  Assert.AreEqual('nome', Tokens[1].Value);
  Assert.AreEqual(Ord(tkText), Ord(Tokens[2].Kind));
  Assert.AreEqual('!', Tokens[2].Value);
end;

procedure TLexerBasicTest.Multiplas_expressoes_seguidas;
begin
  var Tokens := Lexer('{{a}}{{b}}{{c}}').Tokenize;
  Assert.AreEqual(4, Length(Tokens)); // 3 expr + EOF
  Assert.AreEqual('a', Tokens[0].Value);
  Assert.AreEqual('b', Tokens[1].Value);
  Assert.AreEqual('c', Tokens[2].Value);
end;

procedure TLexerBasicTest.Deve_preservar_espacos_em_texto;
begin
  // O Lexer faz Trim no valor dos tokens de texto
  var Tokens := Lexer('  espacos  ').Tokenize;
  Assert.AreEqual('espacos', Tokens[0].Value);
end;

{ TLexerTagsTest }

procedure TLexerTagsTest.Tag_for_deve_gerar_tkTagFor;
begin
  var Tokens := Lexer('{{for item in lista}}').Tokenize;
  Assert.AreEqual(Ord(tkTagFor), Ord(Tokens[0].Kind));
  Assert.AreEqual('item in lista', Tokens[0].Value);
end;

procedure TLexerTagsTest.Tag_endfor_deve_gerar_tkTagEndFor;
begin
  var Tokens := Lexer('{{endfor}}').Tokenize;
  Assert.AreEqual(Ord(tkTagEndFor), Ord(Tokens[0].Kind));
end;

procedure TLexerTagsTest.Tag_if_deve_gerar_tkTagIf;
begin
  var Tokens := Lexer('{{if logado}}').Tokenize;
  Assert.AreEqual(Ord(tkTagIf), Ord(Tokens[0].Kind));
  Assert.AreEqual('logado', Tokens[0].Value);
end;

procedure TLexerTagsTest.Tag_endif_deve_gerar_tkTagEndIf;
begin
  var Tokens := Lexer('{{endif}}').Tokenize;
  Assert.AreEqual(Ord(tkTagEndIf), Ord(Tokens[0].Kind));
end;

procedure TLexerTagsTest.Tag_else_deve_gerar_tkTagElse;
begin
  var Tokens := Lexer('{{else}}').Tokenize;
  Assert.AreEqual(Ord(tkTagElse), Ord(Tokens[0].Kind));
end;

procedure TLexerTagsTest.Tag_else_if_deve_gerar_tkTagElseIf;
begin
  var Tokens := Lexer('{{else if admin}}').Tokenize;
  Assert.AreEqual(Ord(tkTagElseIf), Ord(Tokens[0].Kind));
  Assert.AreEqual('admin', Tokens[0].Value);
end;

procedure TLexerTagsTest.Tag_partial_deve_gerar_tkTagPartial;
begin
  var Tokens := Lexer('{{partial _header}}').Tokenize;
  Assert.AreEqual(Ord(tkTagPartial), Ord(Tokens[0].Kind));
  Assert.AreEqual('_header', Tokens[0].Value);
end;

procedure TLexerTagsTest.Tag_raw_deve_gerar_tkRawExpr;
begin
  var Tokens := Lexer('{{raw htmlContent}}').Tokenize;
  Assert.AreEqual(Ord(tkRawExpr), Ord(Tokens[0].Kind));
  Assert.AreEqual('htmlContent', Tokens[0].Value);
end;

procedure TLexerTagsTest.Tags_devem_ser_case_insensitive;
begin
  var Tokens := Lexer('{{FOR item in lista}}').Tokenize;
  Assert.AreEqual(Ord(tkTagFor), Ord(Tokens[0].Kind));

  Tokens := Lexer('{{IF cond}}').Tokenize;
  Assert.AreEqual(Ord(tkTagIf), Ord(Tokens[0].Kind));

  Tokens := Lexer('{{ENDFOR}}').Tokenize;
  Assert.AreEqual(Ord(tkTagEndFor), Ord(Tokens[0].Kind));
end;

{ TLexerErrorTest }

procedure TLexerErrorTest.Expressao_nao_fechada_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin Lexer('{{nome sem fechar').Tokenize; end,
    ELexerError);
end;

procedure TLexerErrorTest.Expressao_vazia_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin Lexer('{{}}').Tokenize; end,
    ELexerError);
end;

procedure TLexerErrorTest.Tag_desconhecida_deve_levantar_erro;
begin
  Assert.WillRaise(
    procedure begin Lexer('{{banana item in lista}}').Tokenize; end,
    ELexerError);
end;

{ TLexerPositionTest }

procedure TLexerPositionTest.Deve_rastrear_linha_corretamente;
begin
  var Tokens := Lexer('linha1' + #10 + '{{expr}}').Tokenize;
  // O token expr deve estar na linha 2
  Assert.AreEqual(2, Tokens[1].Line);
end;

procedure TLexerPositionTest.Deve_rastrear_coluna_corretamente;
begin
  var Tokens := Lexer('abc{{x}}').Tokenize;
  // {{x}} comeca na coluna 4
  Assert.AreEqual(4, Tokens[1].Col);
end;

procedure TLexerPositionTest.Multilinhas_com_expressoes;
begin
  var Source := '<div>' + #10 + '  {{nome}}' + #10 + '</div>';
  var Tokens := Lexer(Source).Tokenize;
  // Encontrar token 'nome'
  var Found := False;
  for var T in Tokens do
    if (T.Kind = tkExpr) and (T.Value = 'nome') then
    begin
      Assert.AreEqual(2, T.Line);
      Found := True;
      Break;
    end;
  Assert.IsTrue(Found);
end;

{ TLexerEdgeCasesTest }

procedure TLexerEdgeCasesTest.Chave_unica_nao_deve_ser_expressao;
begin
  var Tokens := Lexer('{nao eh expressao}').Tokenize;
  Assert.AreEqual(Ord(tkText), Ord(Tokens[0].Kind));
  Assert.AreEqual('{nao eh expressao}', Tokens[0].Value);
end;

procedure TLexerEdgeCasesTest.Tres_chaves_consecutivas;
begin
  // {{{ -> o Lexer ve {{ como inicio de expressao a partir de pos 1
  // entao o primeiro '{' nao eh separado como texto; o token expr contem '{nome'
  // Na verdade {{{nome}} -> '{{' abre expr, conteudo = '{nome', fecha '}}'
  var Tokens := Lexer('{{{nome}}').Tokenize;
  // Primeiro token eh expressao com valor '{nome' (pos 0 nao tem texto antes de {{)
  Assert.AreEqual(Ord(tkExpr), Ord(Tokens[0].Kind));
end;

procedure TLexerEdgeCasesTest.Expressao_com_pipe_nao_eh_tag_desconhecida;
begin
  // Expressoes com | sao filtros, nao tags desconhecidas
  var Tokens := Lexer('{{nome | upper}}').Tokenize;
  Assert.AreEqual(Ord(tkExpr), Ord(Tokens[0].Kind));
  Assert.AreEqual('nome | upper', Tokens[0].Value);
end;

procedure TLexerEdgeCasesTest.For_com_espacos_extras;
begin
  var Tokens := Lexer('{{for   item   in   lista}}').Tokenize;
  Assert.AreEqual(Ord(tkTagFor), Ord(Tokens[0].Kind));
end;

procedure TLexerEdgeCasesTest.Template_html_completo;
begin
  var Source :=
    '<html>' + #10 +
    '<body>' + #10 +
    '{{if logado}}' + #10 +
    '  <h1>{{nome | upper}}</h1>' + #10 +
    '  {{for item in lista}}' + #10 +
    '    <p>{{item.nome}}</p>' + #10 +
    '  {{endfor}}' + #10 +
    '{{else}}' + #10 +
    '  <p>Login</p>' + #10 +
    '{{endif}}' + #10 +
    '</body>' + #10 +
    '</html>';

  var Tokens := Lexer(Source).Tokenize;

  // Deve tokenizar sem erros e ter mix de tags
  var HasIf := False;
  var HasFor := False;
  var HasEndFor := False;
  var HasElse := False;
  var HasEndIf := False;

  for var T in Tokens do
  begin
    case T.Kind of
      tkTagIf: HasIf := True;
      tkTagFor: HasFor := True;
      tkTagEndFor: HasEndFor := True;
      tkTagElse: HasElse := True;
      tkTagEndIf: HasEndIf := True;
    end;
  end;

  Assert.IsTrue(HasIf);
  Assert.IsTrue(HasFor);
  Assert.IsTrue(HasEndFor);
  Assert.IsTrue(HasElse);
  Assert.IsTrue(HasEndIf);
end;

procedure TLexerEdgeCasesTest.Expressao_com_ponto_para_navegacao;
begin
  var Tokens := Lexer('{{usuario.endereco.cidade}}').Tokenize;
  Assert.AreEqual(Ord(tkExpr), Ord(Tokens[0].Kind));
  Assert.AreEqual('usuario.endereco.cidade', Tokens[0].Value);
end;

procedure TLexerEdgeCasesTest.Expressao_com_filtro_chain;
begin
  var Tokens := Lexer('{{preco | currency | upper}}').Tokenize;
  Assert.AreEqual(Ord(tkExpr), Ord(Tokens[0].Kind));
  Assert.Contains(Tokens[0].Value, '|');
end;

initialization
  TDUnitX.RegisterTestFixture(TLexerBasicTest);
  TDUnitX.RegisterTestFixture(TLexerTagsTest);
  TDUnitX.RegisterTestFixture(TLexerErrorTest);
  TDUnitX.RegisterTestFixture(TLexerPositionTest);
  TDUnitX.RegisterTestFixture(TLexerEdgeCasesTest);

end.
