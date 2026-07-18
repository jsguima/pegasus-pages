unit Pegasus.Engine.Cache.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Pegasus.Engine.Cache,
  Pegasus.Engine.Nodes;

type
  [TestFixture]
  TCacheBasicTest = class
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure GetOrAdd_deve_chamar_factory_na_primeira_vez;

    [Test]
    procedure GetOrAdd_deve_cachear_resultado;

    [Test]
    procedure GetOrAdd_deve_revalidar_se_arquivo_mudou;

    [Test]
    procedure Invalidate_deve_remover_entrada;

    [Test]
    procedure Clear_deve_limpar_tudo;

    [Test]
    procedure TryGet_deve_retornar_false_para_key_inexistente;

    [Test]
    procedure TryGet_deve_retornar_true_apos_Store;
  end;

  [TestFixture]
  TCacheProductionTest = class
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure Em_producao_nao_deve_revalidar;

    [Test]
    procedure Em_dev_deve_revalidar_quando_arquivo_muda;
  end;

  [TestFixture]
  TCacheConcurrencyTest = class
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure Store_e_TryGet_devem_funcionar_sequencialmente;

    [Test]
    procedure Multiplos_GetOrAdd_para_mesmo_arquivo;
  end;

implementation

{ TCacheBasicTest }

procedure TCacheBasicTest.Setup;
begin
  Cache.Clear;
  Cache.Configure(False);
end;

procedure TCacheBasicTest.GetOrAdd_deve_chamar_factory_na_primeira_vez;
begin
  var TempFile := TPath.Combine(TPath.GetTempPath, 'cache_test_' + TGUID.NewGuid.ToString + '.html');
  TFile.WriteAllText(TempFile, '<p>test</p>');
  try
    var FactoryCalled := False;

    Cache.GetOrAdd(TempFile,
      function: INodeListOwner
      begin
        FactoryCalled := True;
        Result := NodeList();
        Result.Writer.Add(TTextNode.Create('test', 1, 1));
      end);

    Assert.IsTrue(FactoryCalled);
  finally
    TFile.Delete(TempFile);
  end;
end;

procedure TCacheBasicTest.GetOrAdd_deve_cachear_resultado;
begin
  var TempFile := TPath.Combine(TPath.GetTempPath, 'cache_test2_' + TGUID.NewGuid.ToString + '.html');
  TFile.WriteAllText(TempFile, '<p>cached</p>');
  try
    var CallCount := 0;

    var Factory: TNodeListFactory :=
      function: INodeListOwner
      begin
        Inc(CallCount);
        Result := NodeList();
        Result.Writer.Add(TTextNode.Create('cached', 1, 1));
      end;

    Cache.GetOrAdd(TempFile, Factory);
    Cache.GetOrAdd(TempFile, Factory);
    Cache.GetOrAdd(TempFile, Factory);

    Assert.AreEqual(1, CallCount, 'Factory deve ser chamada apenas 1 vez');
  finally
    TFile.Delete(TempFile);
  end;
end;

procedure TCacheBasicTest.GetOrAdd_deve_revalidar_se_arquivo_mudou;
begin
  var TempFile := TPath.Combine(TPath.GetTempPath, 'cache_test3_' + TGUID.NewGuid.ToString + '.html');
  TFile.WriteAllText(TempFile, '<p>v1</p>');
  try
    var CallCount := 0;

    var Factory: TNodeListFactory :=
      function: INodeListOwner
      begin
        Inc(CallCount);
        Result := NodeList();
      end;

    Cache.GetOrAdd(TempFile, Factory);
    Assert.AreEqual(1, CallCount);

    // Simular mudanca no arquivo (avancar timestamp)
    Sleep(100);
    TFile.WriteAllText(TempFile, '<p>v2</p>');

    Cache.GetOrAdd(TempFile, Factory);
    Assert.AreEqual(2, CallCount, 'Deve recompilar apos arquivo ser modificado');
  finally
    TFile.Delete(TempFile);
  end;
end;

procedure TCacheBasicTest.Invalidate_deve_remover_entrada;
begin
  var Key := 'test_invalidate_key';
  Cache.Store(Key, NodeList(), Now);

  var Entry: ICacheEntry;
  Assert.IsTrue(Cache.TryGet(Key, Entry));

  Cache.Invalidate(Key);
  Assert.IsFalse(Cache.TryGet(Key, Entry));
end;

procedure TCacheBasicTest.Clear_deve_limpar_tudo;
begin
  Cache.Store('a', NodeList(), Now);
  Cache.Store('b', NodeList(), Now);
  Cache.Clear;

  var Entry: ICacheEntry;
  Assert.IsFalse(Cache.TryGet('a', Entry));
  Assert.IsFalse(Cache.TryGet('b', Entry));
end;

procedure TCacheBasicTest.TryGet_deve_retornar_false_para_key_inexistente;
begin
  var Entry: ICacheEntry;
  Assert.IsFalse(Cache.TryGet('nao_existe_xyz', Entry));
end;

procedure TCacheBasicTest.TryGet_deve_retornar_true_apos_Store;
begin
  var Nodes := NodeList();
  Nodes.Writer.Add(TTextNode.Create('stored', 1, 1));
  Cache.Store('meu_template', Nodes, Now);

  var Entry: ICacheEntry;
  Assert.IsTrue(Cache.TryGet('meu_template', Entry));
  Assert.AreEqual(1, Entry.Nodes.Count);
end;

{ TCacheProductionTest }

procedure TCacheProductionTest.Setup;
begin
  Cache.Clear;
end;

procedure TCacheProductionTest.TearDown;
begin
  Cache.Configure(False);
end;

procedure TCacheProductionTest.Em_producao_nao_deve_revalidar;
begin
  var TempFile := TPath.Combine(TPath.GetTempPath, 'cache_prod_' + TGUID.NewGuid.ToString + '.html');
  TFile.WriteAllText(TempFile, '<p>original</p>');
  try
    Cache.Configure(True);
    var CallCount := 0;

    var Factory: TNodeListFactory :=
      function: INodeListOwner
      begin
        Inc(CallCount);
        Result := NodeList();
      end;

    Cache.GetOrAdd(TempFile, Factory);

    // Modificar arquivo
    Sleep(100);
    TFile.WriteAllText(TempFile, '<p>changed</p>');

    Cache.GetOrAdd(TempFile, Factory);
    Assert.AreEqual(1, CallCount, 'Em producao, nao deve recompilar');
  finally
    TFile.Delete(TempFile);
  end;
end;

procedure TCacheProductionTest.Em_dev_deve_revalidar_quando_arquivo_muda;
begin
  var TempFile := TPath.Combine(TPath.GetTempPath, 'cache_dev_' + TGUID.NewGuid.ToString + '.html');
  TFile.WriteAllText(TempFile, '<p>v1</p>');
  try
    Cache.Configure(False);
    var CallCount := 0;

    var Factory: TNodeListFactory :=
      function: INodeListOwner
      begin
        Inc(CallCount);
        Result := NodeList();
      end;

    Cache.GetOrAdd(TempFile, Factory);

    Sleep(100);
    TFile.WriteAllText(TempFile, '<p>v2</p>');

    Cache.GetOrAdd(TempFile, Factory);
    Assert.AreEqual(2, CallCount);
  finally
    TFile.Delete(TempFile);
  end;
end;

{ TCacheConcurrencyTest }

procedure TCacheConcurrencyTest.Setup;
begin
  Cache.Clear;
  Cache.Configure(False);
end;

procedure TCacheConcurrencyTest.Store_e_TryGet_devem_funcionar_sequencialmente;
begin
  for var I := 1 to 50 do
  begin
    var Key := 'key_' + I.ToString;
    Cache.Store(Key, NodeList(), Now);
  end;

  for var I := 1 to 50 do
  begin
    var Key := 'key_' + I.ToString;
    var Entry: ICacheEntry;
    Assert.IsTrue(Cache.TryGet(Key, Entry), 'Falhou para key: ' + Key);
  end;
end;

procedure TCacheConcurrencyTest.Multiplos_GetOrAdd_para_mesmo_arquivo;
begin
  var TempFile := TPath.Combine(TPath.GetTempPath, 'cache_multi_' + TGUID.NewGuid.ToString + '.html');
  TFile.WriteAllText(TempFile, '<p>multi</p>');
  try
    var CallCount := 0;

    var Factory: TNodeListFactory :=
      function: INodeListOwner
      begin
        Inc(CallCount);
        Result := NodeList();
      end;

    // Chamar varias vezes
    for var I := 1 to 10 do
      Cache.GetOrAdd(TempFile, Factory);

    Assert.AreEqual(1, CallCount);
  finally
    TFile.Delete(TempFile);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCacheBasicTest);
  TDUnitX.RegisterTestFixture(TCacheProductionTest);
  TDUnitX.RegisterTestFixture(TCacheConcurrencyTest);

end.
