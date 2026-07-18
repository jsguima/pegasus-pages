unit Pegasus.UI.Components.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Pegasus.UI.Components;

type
  [TestFixture]
  TComponentRegistryTest = class
  private
    FTempDir: string;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Deve_carregar_componente_com_prefixo_valido;

    [Test]
    procedure Deve_ignorar_componente_sem_dash;

    [Test]
    procedure Deve_ignorar_componente_com_prefixo_nao_permitido;

    [Test]
    procedure TryGet_deve_retornar_true_para_componente_existente;

    [Test]
    procedure TryGet_deve_retornar_false_para_inexistente;

    [Test]
    procedure Deve_extrair_script_do_componente;

    [Test]
    procedure Deve_extrair_style_do_componente;

    [Test]
    procedure HasPrefixes_deve_retornar_true;

    [Test]
    procedure SetAllowedPrefixes_deve_atualizar_prefixos;

    [Test]
    procedure GetPrefixes_deve_retornar_lista;
  end;

  [TestFixture]
  TComponentExpanderTest = class
  private
    FTempDir: string;
    procedure LoadComponent(const Name, Content: string);
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Deve_expandir_componente_self_closing;

    [Test]
    procedure Deve_expandir_componente_com_slot;

    [Test]
    procedure Deve_substituir_atributos;

    [Test]
    procedure Deve_gerar_id_unico;

    [Test]
    procedure Componente_inexistente_deve_virar_comentario;

    [Test]
    procedure Deve_expandir_componentes_aninhados;

    [Test]
    procedure Deve_limitar_profundidade_de_expansao;

    [Test]
    procedure Deve_adicionar_scoped_styles;

    [Test]
    procedure Deve_adicionar_scripts;

    [Test]
    procedure Html_sem_componente_deve_retornar_inalterado;

    [Test]
    procedure Deve_escapar_atributos_para_seguranca;
  end;

implementation

{ TComponentRegistryTest }

procedure TComponentRegistryTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegcomp_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
end;

procedure TComponentRegistryTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TComponentRegistryTest.Deve_carregar_componente_com_prefixo_valido;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, 'pg-button.html'), '<button>{{slot}}</button>');
  ComponentRegistry.SetAllowedPrefixes(['pg']);
  ComponentRegistry.Load(FTempDir);

  var Template: string;
  Assert.IsTrue(ComponentRegistry.TryGet('pg-button', Template));
  Assert.Contains(Template, '<button>');
end;

procedure TComponentRegistryTest.Deve_ignorar_componente_sem_dash;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, 'button.html'), '<button/>');
  ComponentRegistry.SetAllowedPrefixes(['pg']);
  ComponentRegistry.Load(FTempDir);

  var Template: string;
  Assert.IsFalse(ComponentRegistry.TryGet('button', Template));
end;

procedure TComponentRegistryTest.Deve_ignorar_componente_com_prefixo_nao_permitido;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, 'xx-card.html'), '<div class="card"/>');
  ComponentRegistry.SetAllowedPrefixes(['pg']);
  ComponentRegistry.Load(FTempDir);

  var Template: string;
  Assert.IsFalse(ComponentRegistry.TryGet('xx-card', Template));
end;

procedure TComponentRegistryTest.TryGet_deve_retornar_true_para_componente_existente;
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, 'pg-alert.html'), '<div class="alert">{{slot}}</div>');
  ComponentRegistry.SetAllowedPrefixes(['pg']);
  ComponentRegistry.Load(FTempDir);

  var Template: string;
  Assert.IsTrue(ComponentRegistry.TryGet('pg-alert', Template));
end;

procedure TComponentRegistryTest.TryGet_deve_retornar_false_para_inexistente;
begin
  var Template: string;
  Assert.IsFalse(ComponentRegistry.TryGet('pg-fantasma-xyz', Template));
end;

procedure TComponentRegistryTest.Deve_extrair_script_do_componente;
begin
  var Content := '<div>{{slot}}</div><script>console.log("hello");</script>';
  TFile.WriteAllText(TPath.Combine(FTempDir, 'pg-widget.html'), Content);
  ComponentRegistry.SetAllowedPrefixes(['pg']);
  ComponentRegistry.Load(FTempDir);

  var Script: string;
  Assert.IsTrue(ComponentRegistry.TryGetScript('pg-widget', Script));
  Assert.Contains(Script, 'console.log');
end;

procedure TComponentRegistryTest.Deve_extrair_style_do_componente;
begin
  var Content := '<div>{{slot}}</div><style>.btn { color: red; }</style>';
  TFile.WriteAllText(TPath.Combine(FTempDir, 'pg-styled.html'), Content);
  ComponentRegistry.SetAllowedPrefixes(['pg']);
  ComponentRegistry.Load(FTempDir);

  var Style: string;
  Assert.IsTrue(ComponentRegistry.TryGetStyle('pg-styled', Style));
  Assert.Contains(Style, 'color: red');
end;

procedure TComponentRegistryTest.HasPrefixes_deve_retornar_true;
begin
  ComponentRegistry.SetAllowedPrefixes(['pg', 'app']);
  Assert.IsTrue(ComponentRegistry.HasPrefixes);
end;

procedure TComponentRegistryTest.SetAllowedPrefixes_deve_atualizar_prefixos;
begin
  ComponentRegistry.SetAllowedPrefixes(['custom', 'ui']);
  var Prefixes := ComponentRegistry.GetPrefixes;
  Assert.AreEqual(2, Length(Prefixes));
  // Restaurar
  ComponentRegistry.SetAllowedPrefixes(['pg']);
end;

procedure TComponentRegistryTest.GetPrefixes_deve_retornar_lista;
begin
  ComponentRegistry.SetAllowedPrefixes(['pg']);
  var Prefixes := ComponentRegistry.GetPrefixes;
  Assert.IsTrue(Length(Prefixes) > 0);
  Assert.AreEqual('pg', Prefixes[0]);
end;

{ TComponentExpanderTest }

procedure TComponentExpanderTest.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'pegexpand_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
  ComponentRegistry.SetAllowedPrefixes(['pg']);
end;

procedure TComponentExpanderTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TComponentExpanderTest.LoadComponent(const Name, Content: string);
begin
  TFile.WriteAllText(TPath.Combine(FTempDir, Name + '.html'), Content);
  ComponentRegistry.Load(FTempDir);
end;

procedure TComponentExpanderTest.Deve_expandir_componente_self_closing;
begin
  LoadComponent('pg-hr', '<hr class="divider" />');
  var Result := ComponentExpander.Expand('<pg-hr />');
  Assert.Contains(Result, 'divider');
end;

procedure TComponentExpanderTest.Deve_expandir_componente_com_slot;
begin
  LoadComponent('pg-card', '<div class="card">{{slot}}</div>');
  var Result := ComponentExpander.Expand('<pg-card>Conteudo Aqui</pg-card>');
  Assert.Contains(Result, 'Conteudo Aqui');
  Assert.Contains(Result, 'class="card"');
end;

procedure TComponentExpanderTest.Deve_substituir_atributos;
begin
  LoadComponent('pg-btn', '<button class="{{variant}}">{{slot}}</button>');
  var Result := ComponentExpander.Expand('<pg-btn variant="primary">Clique</pg-btn>');
  Assert.Contains(Result, 'primary');
  Assert.Contains(Result, 'Clique');
end;

procedure TComponentExpanderTest.Deve_gerar_id_unico;
begin
  LoadComponent('pg-tab', '<div id="{{id}}">{{slot}}</div>');
  var Result := ComponentExpander.Expand('<pg-tab>A</pg-tab><pg-tab>B</pg-tab>');
  // Cada instancia deve ter um id diferente
  Assert.Contains(Result, 'pg-tab-');
end;

procedure TComponentExpanderTest.Componente_inexistente_deve_virar_comentario;
begin
  var Result := ComponentExpander.Expand('<pg-xyz123 />');
  Assert.Contains(Result, 'not found');
end;

procedure TComponentExpanderTest.Deve_expandir_componentes_aninhados;
begin
  LoadComponent('pg-outer', '<section>{{slot}}</section>');
  LoadComponent('pg-inner', '<span>INNER</span>');
  var Result := ComponentExpander.Expand('<pg-outer><pg-inner /></pg-outer>');
  Assert.Contains(Result, '<section>');
  Assert.Contains(Result, 'INNER');
end;

procedure TComponentExpanderTest.Deve_limitar_profundidade_de_expansao;
begin
  // Componente auto-referenciado (recursao infinita)
  LoadComponent('pg-loop', '<div><pg-loop /></div>');
  var Result := ComponentExpander.Expand('<pg-loop />');
  Assert.Contains(Result, 'max component expansion depth');
end;

procedure TComponentExpanderTest.Deve_adicionar_scoped_styles;
begin
  var Content := '<div>content</div><style>.box { border: 1px solid; }</style>';
  LoadComponent('pg-box', Content);
  var Result := ComponentExpander.Expand('<pg-box />');
  Assert.Contains(Result, '<style>');
  Assert.Contains(Result, 'data-pg');
end;

procedure TComponentExpanderTest.Deve_adicionar_scripts;
begin
  var Content := '<div>widget</div><script>initWidget();</script>';
  LoadComponent('pg-wdg', Content);
  var Result := ComponentExpander.Expand('<pg-wdg />');
  Assert.Contains(Result, '<script>');
  Assert.Contains(Result, 'initWidget');
end;

procedure TComponentExpanderTest.Html_sem_componente_deve_retornar_inalterado;
begin
  var Html := '<div><p>Normal HTML</p></div>';
  var Result := ComponentExpander.Expand(Html);
  Assert.AreEqual(Html, Result);
end;

procedure TComponentExpanderTest.Deve_escapar_atributos_para_seguranca;
begin
  LoadComponent('pg-link', '<a href="{{url}}">{{slot}}</a>');
  // Attr com aspas deve ser escapado pelo Expand
  var Result := ComponentExpander.Expand('<pg-link url="/safe">Link</pg-link>');
  Assert.Contains(Result, 'href=');
  Assert.DoesNotContain(Result, '{{url}}');
end;

initialization
  TDUnitX.RegisterTestFixture(TComponentRegistryTest);
  TDUnitX.RegisterTestFixture(TComponentExpanderTest);

end.
