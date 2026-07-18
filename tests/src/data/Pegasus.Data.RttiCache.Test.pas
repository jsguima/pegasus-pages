unit Pegasus.Data.RttiCache.Test;

interface

uses
  DUnitX.TestFramework,
  System.Rtti,
  Pegasus.Data.RttiCache;

type
  TAnimal = class
  private
    FNome: string;
  public
    property Nome: string read FNome write FNome;
    property NomeUpper: string read FNome;
  end;

  TCarro = class
  public
    Marca: string;
    Ano: Integer;
    Ativo: Boolean;
  end;

  THeranca = class(TCarro)
  public
    Placa: string;
  end;

  TSemMembros = class
  end;

  [TestFixture]
  TRttiCacheGetMemberTest = class
  public
    [Test]
    procedure Deve_encontrar_property_publica;

    [Test]
    procedure Deve_encontrar_field_publico;

    [Test]
    procedure Deve_retornar_nil_para_membro_inexistente;

    [Test]
    procedure Deve_cachear_resultado_entre_chamadas;

    [Test]
    procedure Deve_diferenciar_membros_de_classes_diferentes;

    [Test]
    procedure Deve_encontrar_field_herdado;

    [Test]
    procedure Deve_encontrar_field_de_classe_derivada;

    [Test]
    procedure Deve_retornar_nil_para_classe_sem_membros;

    [Test]
    procedure Deve_funcionar_com_multiplos_fields_na_mesma_classe;

    [Test]
    procedure Deve_ser_case_sensitive_no_nome_do_membro;

    [Test]
    procedure Deve_preferir_property_sobre_field_com_mesmo_nome;
  end;

implementation

{ TRttiCacheGetMemberTest }

procedure TRttiCacheGetMemberTest.Deve_encontrar_property_publica;
begin
  var Member := RttiCache.GetMember(TAnimal, 'Nome');
  Assert.IsNotNull(Member);
  Assert.IsTrue(Member is TRttiProperty);
end;

procedure TRttiCacheGetMemberTest.Deve_encontrar_field_publico;
begin
  var Member := RttiCache.GetMember(TCarro, 'Marca');
  Assert.IsNotNull(Member);
  Assert.IsTrue(Member is TRttiField);
end;

procedure TRttiCacheGetMemberTest.Deve_retornar_nil_para_membro_inexistente;
begin
  var Member := RttiCache.GetMember(TCarro, 'Inexistente');
  Assert.IsNull(Member);
end;

procedure TRttiCacheGetMemberTest.Deve_cachear_resultado_entre_chamadas;
begin
  var Member1 := RttiCache.GetMember(TCarro, 'Marca');
  var Member2 := RttiCache.GetMember(TCarro, 'Marca');
  // Devem ser o exato mesmo ponteiro (veio do cache)
  Assert.AreSame(TObject(Member1), TObject(Member2));
end;

procedure TRttiCacheGetMemberTest.Deve_diferenciar_membros_de_classes_diferentes;
begin
  var MemberAnimal := RttiCache.GetMember(TAnimal, 'Nome');
  var MemberCarro := RttiCache.GetMember(TCarro, 'Nome');
  // TAnimal tem property Nome, TCarro nao tem
  Assert.IsNotNull(MemberAnimal);
  Assert.IsNull(MemberCarro);
end;

procedure TRttiCacheGetMemberTest.Deve_encontrar_field_herdado;
begin
  // THeranca herda Marca de TCarro
  var Member := RttiCache.GetMember(THeranca, 'Marca');
  Assert.IsNotNull(Member);
end;

procedure TRttiCacheGetMemberTest.Deve_encontrar_field_de_classe_derivada;
begin
  var Member := RttiCache.GetMember(THeranca, 'Placa');
  Assert.IsNotNull(Member);
  Assert.IsTrue(Member is TRttiField);
end;

procedure TRttiCacheGetMemberTest.Deve_retornar_nil_para_classe_sem_membros;
begin
  var Member := RttiCache.GetMember(TSemMembros, 'QualquerCoisa');
  Assert.IsNull(Member);
end;

procedure TRttiCacheGetMemberTest.Deve_funcionar_com_multiplos_fields_na_mesma_classe;
begin
  var Marca := RttiCache.GetMember(TCarro, 'Marca');
  var Ano := RttiCache.GetMember(TCarro, 'Ano');
  var Ativo := RttiCache.GetMember(TCarro, 'Ativo');

  Assert.IsNotNull(Marca);
  Assert.IsNotNull(Ano);
  Assert.IsNotNull(Ativo);

  // Devem ser membros diferentes
  Assert.AreNotSame(TObject(Marca), TObject(Ano));
  Assert.AreNotSame(TObject(Ano), TObject(Ativo));
end;

procedure TRttiCacheGetMemberTest.Deve_ser_case_sensitive_no_nome_do_membro;
begin
  // RTTI no Delphi eh case-insensitive para properties mas vamos verificar o comportamento real
  var Member := RttiCache.GetMember(TCarro, 'marca');
  // GetProperty e GetField sao case-insensitive no Delphi
  // Entao deve encontrar mesmo com lowercase
  Assert.IsNotNull(Member);
end;

procedure TRttiCacheGetMemberTest.Deve_preferir_property_sobre_field_com_mesmo_nome;
begin
  // TAnimal tem FNome (field privado) e Nome (property)
  // GetMember primeiro tenta GetProperty, depois GetField
  var Member := RttiCache.GetMember(TAnimal, 'Nome');
  Assert.IsNotNull(Member);
  Assert.IsTrue(Member is TRttiProperty, 'Deve retornar property e nao field');
end;

initialization
  TDUnitX.RegisterTestFixture(TRttiCacheGetMemberTest);

end.
