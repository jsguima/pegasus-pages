unit Pegasus.Security.Encoder.Test;

interface

uses
  DUnitX.TestFramework,
  Pegasus.Security.Encoder;

type
  [TestFixture]
  TEncoderHtmlTest = class
  public
    [Test]
    procedure Deve_escapar_ampersand;

    [Test]
    procedure Deve_escapar_menor_e_maior;

    [Test]
    procedure Deve_escapar_aspas_duplas_e_simples;

    [Test]
    procedure Nao_deve_alterar_texto_seguro;

    [Test]
    procedure Deve_escapar_todos_os_caracteres_perigosos_juntos;

    [Test]
    procedure Deve_lidar_com_string_vazia;

    [Test]
    procedure Deve_escapar_multiplos_ampersands_consecutivos;

    [Test]
    procedure Deve_manter_unicode_intacto;

    [Test]
    procedure Deve_resistir_a_double_encoding;

    [Test]
    procedure Deve_escapar_tag_script_completa;

    [Test]
    procedure Deve_escapar_tentativa_de_xss_em_atributo;

    [Test]
    procedure Deve_escapar_evento_onerror;
  end;

  [TestFixture]
  TEncoderAttrTest = class
  public
    [Test]
    procedure Deve_escapar_barra_e_backtick_alem_do_basico;

    [Test]
    procedure Deve_escapar_aspas_em_valor_de_atributo;

    [Test]
    procedure Deve_lidar_com_string_vazia;

    [Test]
    procedure Deve_escapar_payload_javascript_em_href;

    [Test]
    procedure Deve_escapar_template_injection_com_backtick;

    [Test]
    procedure Deve_escapar_path_traversal_com_barras;

    [Test]
    procedure Deve_manter_texto_alfanumerico_intacto;
  end;

  [TestFixture]
  TEncoderJsTest = class
  public
    [Test]
    procedure Deve_escapar_aspas_simples;

    [Test]
    procedure Deve_escapar_aspas_duplas;

    [Test]
    procedure Deve_escapar_barra_invertida;

    [Test]
    procedure Deve_escapar_newlines;

    [Test]
    procedure Deve_escapar_closing_script_tag;

    [Test]
    procedure Deve_lidar_com_string_vazia;

    [Test]
    procedure Deve_escapar_payload_complexo_js;

    [Test]
    procedure Deve_preservar_caracteres_normais;

    [Test]
    procedure Deve_escapar_combinacao_de_cr_lf;

    [Test]
    procedure Deve_escapar_multiplas_barras_invertidas;
  end;

implementation

{ TEncoderHtmlTest }

procedure TEncoderHtmlTest.Deve_escapar_ampersand;
begin
  Assert.AreEqual('&amp;', TEncoder.Html('&'));
end;

procedure TEncoderHtmlTest.Deve_escapar_menor_e_maior;
begin
  Assert.AreEqual('&lt;div&gt;', TEncoder.Html('<div>'));
end;

procedure TEncoderHtmlTest.Deve_escapar_aspas_duplas_e_simples;
begin
  Assert.AreEqual('&quot;hello&quot; &#39;world&#39;', TEncoder.Html('"hello" ''world'''));
end;

procedure TEncoderHtmlTest.Nao_deve_alterar_texto_seguro;
begin
  Assert.AreEqual('Hello World 123', TEncoder.Html('Hello World 123'));
end;

procedure TEncoderHtmlTest.Deve_escapar_todos_os_caracteres_perigosos_juntos;
begin
  var Input := '<script>alert("xss")</script>';
  var Expected := '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;';
  Assert.AreEqual(Expected, TEncoder.Html(Input));
end;

procedure TEncoderHtmlTest.Deve_lidar_com_string_vazia;
begin
  Assert.AreEqual('', TEncoder.Html(''));
end;

procedure TEncoderHtmlTest.Deve_escapar_multiplos_ampersands_consecutivos;
begin
  Assert.AreEqual('&amp;&amp;&amp;', TEncoder.Html('&&&'));
end;

procedure TEncoderHtmlTest.Deve_manter_unicode_intacto;
begin
  Assert.AreEqual('Ol'#195#161' Mundo '#226#128#147' '#195#167#195#163'o', TEncoder.Html('Ol'#195#161' Mundo '#226#128#147' '#195#167#195#163'o'));
  // Simplificando: texto UTF-8 sem caracteres perigosos deve permanecer intacto
  Assert.AreEqual('Caf'#233, TEncoder.Html('Caf'#233));
end;

procedure TEncoderHtmlTest.Deve_resistir_a_double_encoding;
begin
  // Se j'a tem &amp; no input, deve escapar novamente
  Assert.AreEqual('&amp;amp;', TEncoder.Html('&amp;'));
end;

procedure TEncoderHtmlTest.Deve_escapar_tag_script_completa;
begin
  var Input := '<script src="evil.js"></script>';
  Assert.Contains(TEncoder.Html(Input), '&lt;script');
  Assert.DoesNotContain(TEncoder.Html(Input), '<script');
end;

procedure TEncoderHtmlTest.Deve_escapar_tentativa_de_xss_em_atributo;
begin
  var Input := '" onmouseover="alert(1)"';
  var Encoded := TEncoder.Html(Input);
  Assert.DoesNotContain(Encoded, '"');
end;

procedure TEncoderHtmlTest.Deve_escapar_evento_onerror;
begin
  var Input := '<img src=x onerror=alert(1)>';
  var Encoded := TEncoder.Html(Input);
  Assert.DoesNotContain(Encoded, '<img');
  Assert.Contains(Encoded, '&lt;img');
end;

{ TEncoderAttrTest }

procedure TEncoderAttrTest.Deve_escapar_barra_e_backtick_alem_do_basico;
begin
  Assert.AreEqual('&#x2F;', TEncoder.Attr('/'));
  Assert.AreEqual('&#96;', TEncoder.Attr('`'));
end;

procedure TEncoderAttrTest.Deve_escapar_aspas_em_valor_de_atributo;
begin
  Assert.AreEqual('&quot;valor&quot;', TEncoder.Attr('"valor"'));
end;

procedure TEncoderAttrTest.Deve_lidar_com_string_vazia;
begin
  Assert.AreEqual('', TEncoder.Attr(''));
end;

procedure TEncoderAttrTest.Deve_escapar_payload_javascript_em_href;
begin
  var Input := 'javascript:alert(`xss`)';
  var Encoded := TEncoder.Attr(Input);
  Assert.DoesNotContain(Encoded, '`');
  Assert.Contains(Encoded, '&#96;');
end;

procedure TEncoderAttrTest.Deve_escapar_template_injection_com_backtick;
begin
  var Input := '`${document.cookie}`';
  var Encoded := TEncoder.Attr(Input);
  Assert.DoesNotContain(Encoded, '`');
end;

procedure TEncoderAttrTest.Deve_escapar_path_traversal_com_barras;
begin
  var Input := '../../../etc/passwd';
  var Encoded := TEncoder.Attr(Input);
  Assert.DoesNotContain(Encoded, '/');
  Assert.Contains(Encoded, '&#x2F;');
end;

procedure TEncoderAttrTest.Deve_manter_texto_alfanumerico_intacto;
begin
  Assert.AreEqual('abc123XYZ', TEncoder.Attr('abc123XYZ'));
end;

{ TEncoderJsTest }

procedure TEncoderJsTest.Deve_escapar_aspas_simples;
begin
  Assert.AreEqual('\''', TEncoder.Js(''''));
end;

procedure TEncoderJsTest.Deve_escapar_aspas_duplas;
begin
  Assert.AreEqual('\"', TEncoder.Js('"'));
end;

procedure TEncoderJsTest.Deve_escapar_barra_invertida;
begin
  Assert.AreEqual('\\', TEncoder.Js('\'));
end;

procedure TEncoderJsTest.Deve_escapar_newlines;
begin
  Assert.AreEqual('\n', TEncoder.Js(#10));
  Assert.AreEqual('\r', TEncoder.Js(#13));
end;

procedure TEncoderJsTest.Deve_escapar_closing_script_tag;
begin
  // Previne quebra de contexto JS dentro de <script>
  Assert.AreEqual('<\/', TEncoder.Js('</'));
end;

procedure TEncoderJsTest.Deve_lidar_com_string_vazia;
begin
  Assert.AreEqual('', TEncoder.Js(''));
end;

procedure TEncoderJsTest.Deve_escapar_payload_complexo_js;
begin
  var Input := 'alert("xss");' + #10 + '</script><script>evil()</script>';
  var Encoded := TEncoder.Js(Input);
  Assert.DoesNotContain(Encoded, #10);
  Assert.DoesNotContain(Encoded, '</');
end;

procedure TEncoderJsTest.Deve_preservar_caracteres_normais;
begin
  Assert.AreEqual('Hello World 123', TEncoder.Js('Hello World 123'));
end;

procedure TEncoderJsTest.Deve_escapar_combinacao_de_cr_lf;
begin
  Assert.AreEqual('\r\n', TEncoder.Js(#13#10));
end;

procedure TEncoderJsTest.Deve_escapar_multiplas_barras_invertidas;
begin
  Assert.AreEqual('\\\\\\', TEncoder.Js('\\\'));
end;

initialization
  TDUnitX.RegisterTestFixture(TEncoderHtmlTest);
  TDUnitX.RegisterTestFixture(TEncoderAttrTest);
  TDUnitX.RegisterTestFixture(TEncoderJsTest);

end.
