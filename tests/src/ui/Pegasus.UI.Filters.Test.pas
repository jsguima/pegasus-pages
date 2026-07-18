unit Pegasus.UI.Filters.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Pegasus.UI.Filters;

type
  [TestFixture]
  TFiltersTextTest = class
  public
    [Test]
    procedure Upper_deve_converter_para_maiusculo;

    [Test]
    procedure Lower_deve_converter_para_minusculo;

    [Test]
    procedure Trim_deve_remover_espacos;

    [Test]
    procedure Truncate_deve_cortar_e_adicionar_reticencias;

    [Test]
    procedure Truncate_nao_deve_cortar_se_menor_que_limite;

    [Test]
    procedure Truncate_com_argumento_customizado;

    [Test]
    procedure Default_deve_substituir_string_vazia;

    [Test]
    procedure Default_nao_deve_substituir_string_preenchida;

    [Test]
    procedure Default_deve_substituir_espacos_em_branco;
  end;

  [TestFixture]
  TFiltersNumberTest = class
  public
    [Test]
    procedure Currency_deve_formatar_valor;

    [Test]
    procedure Currency_com_prefix_deve_adicionar_simbolo;

    [Test]
    procedure Currency_negativo_deve_ter_sinal;

    [Test]
    procedure Currency_invalido_deve_retornar_original;

    [Test]
    procedure Decimal_deve_trocar_ponto_por_virgula;

    [Test]
    procedure Number_deve_formatar_com_casas_decimais;

    [Test]
    procedure Number_com_argumento_de_casas;

    [Test]
    procedure Number_invalido_deve_retornar_original;
  end;

  [TestFixture]
  TFiltersConditionalTest = class
  public
    [Test]
    procedure Iif_maior_que_zero_deve_retornar_true_value;

    [Test]
    procedure Iif_menor_que_zero_deve_retornar_false_value;

    [Test]
    procedure Iif_igual_deve_funcionar;

    [Test]
    procedure Iif_menor_igual_deve_funcionar;

    [Test]
    procedure Iif_maior_igual_deve_funcionar;

    [Test]
    procedure Iif_diferente_deve_funcionar;

    [Test]
    procedure Iif_com_argumentos_insuficientes_retorna_vazio;
  end;

  [TestFixture]
  TFiltersDateTest = class
  public
    [Test]
    procedure Date_deve_formatar_com_padrao;

    [Test]
    procedure Date_com_formato_customizado;

    [Test]
    procedure Date_invalido_deve_retornar_original;
  end;

  [TestFixture]
  TFiltersSecurityTest = class
  public
    [Test]
    procedure Url_deve_bloquear_javascript_protocol;

    [Test]
    procedure Url_deve_bloquear_data_protocol;

    [Test]
    procedure Url_deve_bloquear_vbscript;

    [Test]
    procedure Url_deve_permitir_http;

    [Test]
    procedure Url_deve_permitir_relativa;

    [Test]
    procedure Url_deve_decodificar_antes_de_validar;

    [Test]
    procedure Url_deve_bloquear_javascript_com_encoding_duplo;

    [Test]
    procedure Url_deve_bloquear_file_protocol;

    [Test]
    procedure Attr_deve_escapar_caracteres_perigosos;

    [Test]
    procedure Js_deve_escapar_para_contexto_javascript;
  end;

  [TestFixture]
  TFiltersChainTest = class
  public
    [Test]
    procedure Deve_aplicar_multiplos_filtros_em_sequencia;

    [Test]
    procedure Filtro_inexistente_deve_retornar_valor_sem_alterar;

    [Test]
    procedure Chain_vazio_deve_retornar_valor;

    [Test]
    procedure Chain_com_espacos_deve_funcionar;
  end;

implementation

{ TFiltersTextTest }

procedure TFiltersTextTest.Upper_deve_converter_para_maiusculo;
begin
  Assert.AreEqual('HELLO', Filters.Apply('hello', 'upper'));
end;

procedure TFiltersTextTest.Lower_deve_converter_para_minusculo;
begin
  Assert.AreEqual('hello', Filters.Apply('HELLO', 'lower'));
end;

procedure TFiltersTextTest.Trim_deve_remover_espacos;
begin
  Assert.AreEqual('hello', Filters.Apply('  hello  ', 'trim'));
end;

procedure TFiltersTextTest.Truncate_deve_cortar_e_adicionar_reticencias;
begin
  Assert.AreEqual('Hello...', Filters.Apply('Hello World', 'truncate:''5'''));
end;

procedure TFiltersTextTest.Truncate_nao_deve_cortar_se_menor_que_limite;
begin
  Assert.AreEqual('Hi', Filters.Apply('Hi', 'truncate:''50'''));
end;

procedure TFiltersTextTest.Truncate_com_argumento_customizado;
begin
  Assert.AreEqual('abc...', Filters.Apply('abcdefgh', 'truncate:''3'''));
end;

procedure TFiltersTextTest.Default_deve_substituir_string_vazia;
begin
  Assert.AreEqual('N/A', Filters.Apply('', 'default:''N/A'''));
end;

procedure TFiltersTextTest.Default_nao_deve_substituir_string_preenchida;
begin
  Assert.AreEqual('valor', Filters.Apply('valor', 'default:''N/A'''));
end;

procedure TFiltersTextTest.Default_deve_substituir_espacos_em_branco;
begin
  Assert.AreEqual('fallback', Filters.Apply('   ', 'default:''fallback'''));
end;

{ TFiltersNumberTest }

procedure TFiltersNumberTest.Currency_deve_formatar_valor;
begin
  var Result := Filters.Apply('1234.56', 'currency');
  // Deve ter separador de milhar e casas decimais
  Assert.IsNotEmpty(Result);
  Assert.AreNotEqual('1234.56', Result); // Deve ter sido formatado
end;

procedure TFiltersNumberTest.Currency_com_prefix_deve_adicionar_simbolo;
begin
  var Result := Filters.Apply('100.00', 'currency:''prefix''');
  // Deve ter simbolo de moeda
  Assert.IsNotEmpty(Result);
end;

procedure TFiltersNumberTest.Currency_negativo_deve_ter_sinal;
begin
  var Result := Filters.Apply('-50.00', 'currency');
  Assert.Contains(Result, '-');
end;

procedure TFiltersNumberTest.Currency_invalido_deve_retornar_original;
begin
  Assert.AreEqual('abc', Filters.Apply('abc', 'currency'));
end;

procedure TFiltersNumberTest.Decimal_deve_trocar_ponto_por_virgula;
begin
  Assert.AreEqual('10,50', Filters.Apply('10.50', 'decimal'));
end;

procedure TFiltersNumberTest.Number_deve_formatar_com_casas_decimais;
begin
  var Result := Filters.Apply('3.14159', 'number:''2''');
  // Usa o DecimalSeparator do sistema (virgula no BR)
  var DS := FormatSettings.DecimalSeparator;
  Assert.AreEqual('3' + DS + '14', Result);
end;

procedure TFiltersNumberTest.Number_com_argumento_de_casas;
begin
  var Result := Filters.Apply('3.14159', 'number:''3''');
  var DS := FormatSettings.DecimalSeparator;
  Assert.AreEqual('3' + DS + '142', Result);
end;

procedure TFiltersNumberTest.Number_invalido_deve_retornar_original;
begin
  Assert.AreEqual('texto', Filters.Apply('texto', 'number'));
end;

{ TFiltersConditionalTest }

procedure TFiltersConditionalTest.Iif_maior_que_zero_deve_retornar_true_value;
begin
  Assert.AreEqual('positivo', Filters.Apply('5', 'iif:''>0,positivo,negativo'''));
end;

procedure TFiltersConditionalTest.Iif_menor_que_zero_deve_retornar_false_value;
begin
  Assert.AreEqual('negativo', Filters.Apply('-3', 'iif:''>0,positivo,negativo'''));
end;

procedure TFiltersConditionalTest.Iif_igual_deve_funcionar;
begin
  Assert.AreEqual('zero', Filters.Apply('0', 'iif:''=0,zero,outro'''));
end;

procedure TFiltersConditionalTest.Iif_menor_igual_deve_funcionar;
begin
  Assert.AreEqual('ok', Filters.Apply('10', 'iif:''<=10,ok,nok'''));
end;

procedure TFiltersConditionalTest.Iif_maior_igual_deve_funcionar;
begin
  Assert.AreEqual('aprovado', Filters.Apply('7', 'iif:''>=7,aprovado,reprovado'''));
end;

procedure TFiltersConditionalTest.Iif_diferente_deve_funcionar;
begin
  Assert.AreEqual('sim', Filters.Apply('5', 'iif:''<>0,sim,nao'''));
end;

procedure TFiltersConditionalTest.Iif_com_argumentos_insuficientes_retorna_vazio;
begin
  Assert.AreEqual('', Filters.Apply('5', 'iif:''>0,apenas_um'''));
end;

{ TFiltersDateTest }

procedure TFiltersDateTest.Date_deve_formatar_com_padrao;
begin
  // TDateTime como float string
  var DateVal := FloatToStr(EncodeDate(2024, 3, 15), TFormatSettings.Invariant);
  var Result := Filters.Apply(DateVal, 'date');
  Assert.IsNotEmpty(Result);
  // Padrao eh dd/mm/yyyy
  Assert.Contains(Result, '15');
end;

procedure TFiltersDateTest.Date_com_formato_customizado;
begin
  var DateVal := FloatToStr(EncodeDate(2024, 12, 25), TFormatSettings.Invariant);
  var Result := Filters.Apply(DateVal, 'date:''yyyy-mm-dd''');
  Assert.AreEqual('2024-12-25', Result);
end;

procedure TFiltersDateTest.Date_invalido_deve_retornar_original;
begin
  Assert.AreEqual('nao-eh-data', Filters.Apply('nao-eh-data', 'date'));
end;

{ TFiltersSecurityTest }

procedure TFiltersSecurityTest.Url_deve_bloquear_javascript_protocol;
begin
  Assert.AreEqual('#blocked', Filters.Apply('javascript:alert(1)', 'url'));
end;

procedure TFiltersSecurityTest.Url_deve_bloquear_data_protocol;
begin
  Assert.AreEqual('#blocked', Filters.Apply('data:text/html,<script>evil</script>', 'url'));
end;

procedure TFiltersSecurityTest.Url_deve_bloquear_vbscript;
begin
  Assert.AreEqual('#blocked', Filters.Apply('vbscript:MsgBox("xss")', 'url'));
end;

procedure TFiltersSecurityTest.Url_deve_permitir_http;
begin
  var Url := 'https://example.com/page?q=1';
  Assert.AreEqual(Url, Filters.Apply(Url, 'url'));
end;

procedure TFiltersSecurityTest.Url_deve_permitir_relativa;
begin
  Assert.AreEqual('/home', Filters.Apply('/home', 'url'));
end;

procedure TFiltersSecurityTest.Url_deve_decodificar_antes_de_validar;
begin
  // javascript: encoded
  Assert.AreEqual('#blocked', Filters.Apply('javascript%3Aalert(1)', 'url'));
end;

procedure TFiltersSecurityTest.Url_deve_bloquear_javascript_com_encoding_duplo;
begin
  // Double-encoded javascript:
  Assert.AreEqual('#blocked', Filters.Apply('javascript%253Aalert(1)', 'url'));
end;

procedure TFiltersSecurityTest.Url_deve_bloquear_file_protocol;
begin
  Assert.AreEqual('#blocked', Filters.Apply('file:///etc/passwd', 'url'));
end;

procedure TFiltersSecurityTest.Attr_deve_escapar_caracteres_perigosos;
begin
  var Result := Filters.Apply('" onmouseover="alert(1)"', 'attr');
  Assert.DoesNotContain(Result, '"');
end;

procedure TFiltersSecurityTest.Js_deve_escapar_para_contexto_javascript;
begin
  var Result := Filters.Apply('alert("xss")', 'js');
  // As aspas devem ser escapadas com barra invertida
  Assert.Contains(Result, '\"');
  // Nao deve conter aspas nao-escapadas (sem \ antes)
  Assert.AreEqual('alert(\"xss\")', Result);
end;

{ TFiltersChainTest }

procedure TFiltersChainTest.Deve_aplicar_multiplos_filtros_em_sequencia;
begin
  Assert.AreEqual('HELLO', Filters.ApplyChain('  hello  ', 'trim | upper'));
end;

procedure TFiltersChainTest.Filtro_inexistente_deve_retornar_valor_sem_alterar;
begin
  Assert.AreEqual('abc', Filters.ApplyChain('abc', 'filtroFake'));
end;

procedure TFiltersChainTest.Chain_vazio_deve_retornar_valor;
begin
  Assert.AreEqual('valor', Filters.ApplyChain('valor', ''));
end;

procedure TFiltersChainTest.Chain_com_espacos_deve_funcionar;
begin
  Assert.AreEqual('HELLO', Filters.ApplyChain('hello', '  upper  '));
end;

initialization
  TDUnitX.RegisterTestFixture(TFiltersTextTest);
  TDUnitX.RegisterTestFixture(TFiltersNumberTest);
  TDUnitX.RegisterTestFixture(TFiltersConditionalTest);
  TDUnitX.RegisterTestFixture(TFiltersDateTest);
  TDUnitX.RegisterTestFixture(TFiltersSecurityTest);
  TDUnitX.RegisterTestFixture(TFiltersChainTest);

end.
