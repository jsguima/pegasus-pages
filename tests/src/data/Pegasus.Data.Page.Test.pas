unit Pegasus.Data.Page.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  Pegasus.Data.Page;

type
  TDummyObj = class
  public
    Nome: string;
    Idade: Integer;
  end;

  [TestFixture]
  TPageDataWriterTest = class
  public
    [Test]
    procedure Deve_adicionar_string;

    [Test]
    procedure Deve_adicionar_integer;

    [Test]
    procedure Deve_adicionar_double;

    [Test]
    procedure Deve_adicionar_boolean_true;

    [Test]
    procedure Deve_adicionar_boolean_false;

    [Test]
    procedure Deve_adicionar_objeto;

    [Test]
    procedure Deve_adicionar_lista_de_objetos;

    [Test]
    procedure Deve_sobrescrever_valor_existente_com_mesmo_key;

    [Test]
    procedure Deve_normalizar_key_para_lowercase;

    [Test]
    procedure Deve_liberar_objeto_anterior_ao_sobrescrever;
  end;

  [TestFixture]
  TPageDataReaderTest = class
  public
    [Test]
    procedure Deve_retornar_valor_string;

    [Test]
    procedure Deve_retornar_empty_para_key_inexistente;

    [Test]
    procedure Has_deve_retornar_true_para_key_existente;

    [Test]
    procedure Has_deve_retornar_false_para_key_inexistente;

    [Test]
    procedure Has_deve_ser_case_insensitive;

    [Test]
    procedure Get_deve_ser_case_insensitive;

    [Test]
    procedure Deve_retornar_objeto_adicionado;

    [Test]
    procedure Deve_retornar_lista_como_TValue_de_objeto;
  end;

  [TestFixture]
  TPageDataSlotTest = class
  public
    [Test]
    procedure Slot_padrao_deve_ser_vazio;

    [Test]
    procedure Deve_definir_e_recuperar_slot;

    [Test]
    procedure IsSlotTrusted_padrao_deve_ser_false;

    [Test]
    procedure IsSlotTrusted_deve_refletir_valor_setado;

    [Test]
    procedure Slot_nao_trusted_por_padrao;

    [Test]
    procedure Slot_trusted_quando_explicitamente_marcado;
  end;

  [TestFixture]
  TPageDataStreamTest = class
  public
    [Test]
    procedure HasStream_deve_ser_false_inicialmente;

    [Test]
    procedure Deve_armazenar_stream_com_content_type;

    [Test]
    procedure Deve_armazenar_stream_com_filename;

    [Test]
    procedure GetStream_deve_retornar_stream_e_limpar_referencia;

    [Test]
    procedure Deve_liberar_stream_anterior_ao_setar_novo;
  end;

  [TestFixture]
  TPageDataEdgeCasesTest = class
  public
    [Test]
    procedure Deve_aceitar_key_com_espacos;

    [Test]
    procedure Deve_aceitar_string_vazia_como_valor;

    [Test]
    procedure Deve_aceitar_zero_como_integer;

    [Test]
    procedure Deve_aceitar_zero_como_double;

    [Test]
    procedure Deve_aceitar_double_negativo;

    [Test]
    procedure Deve_aceitar_integer_maximo;

    [Test]
    procedure Deve_aceitar_objeto_nil;

    [Test]
    procedure Interface_Reader_e_Writer_sao_o_mesmo_objeto;
  end;

implementation

{ TPageDataWriterTest }

procedure TPageDataWriterTest.Deve_adicionar_string;
begin
  var Data := PageData();
  Data.Writer.Add('nome', 'Pegasus');
  var V := Data.Reader.Get('nome');
  Assert.AreEqual('Pegasus', V.AsString);
end;

procedure TPageDataWriterTest.Deve_adicionar_integer;
begin
  var Data := PageData();
  Data.Writer.Add('total', 42);
  Assert.AreEqual(42, Data.Reader.Get('total').AsInteger);
end;

procedure TPageDataWriterTest.Deve_adicionar_double;
begin
  var Data := PageData();
  Data.Writer.Add('preco', 19.99);
  Assert.AreEqual(Double(19.99), Data.Reader.Get('preco').AsExtended, 0.001);
end;

procedure TPageDataWriterTest.Deve_adicionar_boolean_true;
begin
  var Data := PageData();
  Data.Writer.Add('ativo', True);
  Assert.IsTrue(Data.Reader.Get('ativo').AsBoolean);
end;

procedure TPageDataWriterTest.Deve_adicionar_boolean_false;
begin
  var Data := PageData();
  Data.Writer.Add('ativo', False);
  Assert.IsFalse(Data.Reader.Get('ativo').AsBoolean);
end;

procedure TPageDataWriterTest.Deve_adicionar_objeto;
begin
  var Data := PageData();
  var Obj := TDummyObj.Create;
  Obj.Nome := 'Test';
  Data.Writer.Add('item', Obj);

  var V := Data.Reader.Get('item');
  Assert.IsTrue(V.IsObject);
  Assert.AreEqual('Test', TDummyObj(V.AsObject).Nome);
end;

procedure TPageDataWriterTest.Deve_adicionar_lista_de_objetos;
begin
  var Data := PageData();
  var Lista := TObjectList<TObject>.Create(True);
  var Obj := TDummyObj.Create;
  Obj.Nome := 'Item1';
  Lista.Add(Obj);
  Data.Writer.Add('items', Lista);

  var V := Data.Reader.Get('items');
  Assert.IsTrue(V.IsObject);
  Assert.IsTrue(V.AsObject is TObjectList<TObject>);
  Assert.AreEqual(1, TObjectList<TObject>(V.AsObject).Count);
end;

procedure TPageDataWriterTest.Deve_sobrescrever_valor_existente_com_mesmo_key;
begin
  var Data := PageData();
  Data.Writer.Add('key', 'valor1');
  Data.Writer.Add('key', 'valor2');
  Assert.AreEqual('valor2', Data.Reader.Get('key').AsString);
end;

procedure TPageDataWriterTest.Deve_normalizar_key_para_lowercase;
begin
  var Data := PageData();
  Data.Writer.Add('NOME', 'Upper');
  Assert.AreEqual('Upper', Data.Reader.Get('nome').AsString);
end;

procedure TPageDataWriterTest.Deve_liberar_objeto_anterior_ao_sobrescrever;
begin
  var Data := PageData();
  var Obj1 := TDummyObj.Create;
  Obj1.Nome := 'Primeiro';
  Data.Writer.Add('item', Obj1);

  var Obj2 := TDummyObj.Create;
  Obj2.Nome := 'Segundo';
  Data.Writer.Add('item', Obj2);

  // Se nao liberou Obj1, haveria leak - FastMM5 capturaria
  Assert.AreEqual('Segundo', TDummyObj(Data.Reader.Get('item').AsObject).Nome);
end;

{ TPageDataReaderTest }

procedure TPageDataReaderTest.Deve_retornar_valor_string;
begin
  var Data := PageData();
  Data.Writer.Add('msg', 'hello');
  Assert.AreEqual('hello', Data.Reader.Get('msg').AsString);
end;

procedure TPageDataReaderTest.Deve_retornar_empty_para_key_inexistente;
begin
  var Data := PageData();
  var V := Data.Reader.Get('naoexiste');
  Assert.IsTrue(V.IsEmpty);
end;

procedure TPageDataReaderTest.Has_deve_retornar_true_para_key_existente;
begin
  var Data := PageData();
  Data.Writer.Add('x', 'y');
  Assert.IsTrue(Data.Reader.Has('x'));
end;

procedure TPageDataReaderTest.Has_deve_retornar_false_para_key_inexistente;
begin
  var Data := PageData();
  Assert.IsFalse(Data.Reader.Has('fantasma'));
end;

procedure TPageDataReaderTest.Has_deve_ser_case_insensitive;
begin
  var Data := PageData();
  Data.Writer.Add('Nome', 'valor');
  Assert.IsTrue(Data.Reader.Has('nome'));
  Assert.IsTrue(Data.Reader.Has('NOME'));
  Assert.IsTrue(Data.Reader.Has('Nome'));
end;

procedure TPageDataReaderTest.Get_deve_ser_case_insensitive;
begin
  var Data := PageData();
  Data.Writer.Add('Titulo', 'PegasusPages');
  Assert.AreEqual('PegasusPages', Data.Reader.Get('titulo').AsString);
  Assert.AreEqual('PegasusPages', Data.Reader.Get('TITULO').AsString);
end;

procedure TPageDataReaderTest.Deve_retornar_objeto_adicionado;
begin
  var Data := PageData();
  var Obj := TDummyObj.Create;
  Obj.Idade := 25;
  Data.Writer.Add('pessoa', Obj);

  var V := Data.Reader.Get('pessoa');
  Assert.AreEqual(25, TDummyObj(V.AsObject).Idade);
end;

procedure TPageDataReaderTest.Deve_retornar_lista_como_TValue_de_objeto;
begin
  var Data := PageData();
  var Lista := TObjectList<TObject>.Create(True);

  for var I := 1 to 3 do
  begin
    var Obj := TDummyObj.Create;
    Obj.Nome := 'Item' + I.ToString;
    Lista.Add(Obj);
  end;

  Data.Writer.Add('lista', Lista);
  var V := Data.Reader.Get('lista');
  Assert.AreEqual(3, TObjectList<TObject>(V.AsObject).Count);
end;

{ TPageDataSlotTest }

procedure TPageDataSlotTest.Slot_padrao_deve_ser_vazio;
begin
  var Data := PageData();
  Assert.AreEqual('', Data.Reader.GetSlot);
end;

procedure TPageDataSlotTest.Deve_definir_e_recuperar_slot;
begin
  var Data := PageData();
  Data.Writer.SetSlot('<div>Content</div>');
  Assert.AreEqual('<div>Content</div>', Data.Reader.GetSlot);
end;

procedure TPageDataSlotTest.IsSlotTrusted_padrao_deve_ser_false;
begin
  var Data := PageData();
  Assert.IsFalse(Data.Reader.IsSlotTrusted);
end;

procedure TPageDataSlotTest.IsSlotTrusted_deve_refletir_valor_setado;
begin
  var Data := PageData();
  Data.Writer.SetSlot('html', True);
  Assert.IsTrue(Data.Reader.IsSlotTrusted);
end;

procedure TPageDataSlotTest.Slot_nao_trusted_por_padrao;
begin
  var Data := PageData();
  Data.Writer.SetSlot('<script>evil</script>');
  Assert.IsFalse(Data.Reader.IsSlotTrusted);
end;

procedure TPageDataSlotTest.Slot_trusted_quando_explicitamente_marcado;
begin
  var Data := PageData();
  Data.Writer.SetSlot('<p>Safe rendered HTML</p>', True);
  Assert.IsTrue(Data.Reader.IsSlotTrusted);
  Assert.AreEqual('<p>Safe rendered HTML</p>', Data.Reader.GetSlot);
end;

{ TPageDataStreamTest }

procedure TPageDataStreamTest.HasStream_deve_ser_false_inicialmente;
begin
  var Data := PageData();
  Assert.IsFalse(Data.Reader.HasStream);
end;

procedure TPageDataStreamTest.Deve_armazenar_stream_com_content_type;
begin
  var Data := PageData();
  var Stream := TMemoryStream.Create;
  Data.Writer.SetStream(Stream, 'application/pdf');
  Assert.IsTrue(Data.Reader.HasStream);
  Assert.AreEqual('application/pdf', Data.Reader.GetStreamContentType);
  // Limpar - GetStream transfere ownership
  Data.Reader.GetStream.Free;
end;

procedure TPageDataStreamTest.Deve_armazenar_stream_com_filename;
begin
  var Data := PageData();
  var Stream := TMemoryStream.Create;
  Data.Writer.SetStream(Stream, 'application/pdf', 'relatorio.pdf');
  Assert.AreEqual('relatorio.pdf', Data.Reader.GetStreamFileName);
  Data.Reader.GetStream.Free;
end;

procedure TPageDataStreamTest.GetStream_deve_retornar_stream_e_limpar_referencia;
begin
  var Data := PageData();
  var Stream := TMemoryStream.Create;
  Data.Writer.SetStream(Stream, 'text/plain');

  var Returned := Data.Reader.GetStream;
  Assert.AreSame(Stream, Returned);
  // Apos GetStream, HasStream deve ser false
  Assert.IsFalse(Data.Reader.HasStream);
  Returned.Free;
end;

procedure TPageDataStreamTest.Deve_liberar_stream_anterior_ao_setar_novo;
begin
  var Data := PageData();
  var Stream1 := TMemoryStream.Create;
  Data.Writer.SetStream(Stream1, 'text/plain');

  var Stream2 := TMemoryStream.Create;
  Data.Writer.SetStream(Stream2, 'image/png');

  // Stream1 deve ter sido liberado internamente
  Assert.AreEqual('image/png', Data.Reader.GetStreamContentType);
  Data.Reader.GetStream.Free;
end;

{ TPageDataEdgeCasesTest }

procedure TPageDataEdgeCasesTest.Deve_aceitar_key_com_espacos;
begin
  var Data := PageData();
  Data.Writer.Add('minha chave', 'valor');
  Assert.AreEqual('valor', Data.Reader.Get('minha chave').AsString);
end;

procedure TPageDataEdgeCasesTest.Deve_aceitar_string_vazia_como_valor;
begin
  var Data := PageData();
  Data.Writer.Add('vazio', '');
  Assert.AreEqual('', Data.Reader.Get('vazio').AsString);
  Assert.IsTrue(Data.Reader.Has('vazio'));
end;

procedure TPageDataEdgeCasesTest.Deve_aceitar_zero_como_integer;
begin
  var Data := PageData();
  Data.Writer.Add('zero', 0);
  Assert.AreEqual(0, Data.Reader.Get('zero').AsInteger);
end;

procedure TPageDataEdgeCasesTest.Deve_aceitar_zero_como_double;
begin
  var Data := PageData();
  Data.Writer.Add('zero', Double(0.0));
  Assert.AreEqual(Double(0.0), Data.Reader.Get('zero').AsExtended, 0.0001);
end;

procedure TPageDataEdgeCasesTest.Deve_aceitar_double_negativo;
begin
  var Data := PageData();
  Data.Writer.Add('neg', -99.5);
  Assert.AreEqual(Double(-99.5), Data.Reader.Get('neg').AsExtended, 0.001);
end;

procedure TPageDataEdgeCasesTest.Deve_aceitar_integer_maximo;
begin
  var Data := PageData();
  Data.Writer.Add('max', MaxInt);
  Assert.AreEqual(MaxInt, Data.Reader.Get('max').AsInteger);
end;

procedure TPageDataEdgeCasesTest.Deve_aceitar_objeto_nil;
begin
  var Data := PageData();
  Data.Writer.Add('nulo', TObject(nil));
  var V := Data.Reader.Get('nulo');
  Assert.IsTrue(V.IsObject);
  Assert.IsNull(V.AsObject);
end;

procedure TPageDataEdgeCasesTest.Interface_Reader_e_Writer_sao_o_mesmo_objeto;
begin
  var Data := PageData();
  Data.Writer.Add('x', 'y');
  // Reader deve enxergar imediatamente o que Writer escreveu (mesmo TPageData)
  Assert.IsTrue(Data.Reader.Has('x'));
end;

initialization
  TDUnitX.RegisterTestFixture(TPageDataWriterTest);
  TDUnitX.RegisterTestFixture(TPageDataReaderTest);
  TDUnitX.RegisterTestFixture(TPageDataSlotTest);
  TDUnitX.RegisterTestFixture(TPageDataStreamTest);
  TDUnitX.RegisterTestFixture(TPageDataEdgeCasesTest);

end.
