unit Pegasus.Security.SecureRandom.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Pegasus.Security.SecureRandom;

type
  [TestFixture]
  TSecureRandomTest = class
  public
    [Test]
    procedure GetBytes_deve_retornar_tamanho_correto;

    [Test]
    procedure GetBytes_com_zero_deve_retornar_nil;

    [Test]
    procedure GetBytes_com_negativo_deve_retornar_nil;

    [Test]
    procedure GetBytes_deve_gerar_bytes_diferentes_a_cada_chamada;

    [Test]
    procedure HexToken_deve_ter_comprimento_correto;

    [Test]
    procedure HexToken_deve_conter_apenas_hex_valido;

    [Test]
    procedure HexToken_deve_ser_unico_a_cada_geracao;

    [Test]
    procedure HexToken_padrao_deve_ter_64_caracteres;

    [Test]
    procedure HexToken_deve_ser_lowercase;

    [Test]
    procedure GetBytes_grande_deve_funcionar;

    [Test]
    procedure HexToken_com_1_byte_deve_ter_2_caracteres;

    [Test]
    procedure Multiplas_chamadas_rapidas_nunca_devem_colidir;
  end;

implementation

{ TSecureRandomTest }

procedure TSecureRandomTest.GetBytes_deve_retornar_tamanho_correto;
begin
  var Bytes := TSecureRandom.GetBytes(16);
  Assert.AreEqual(16, Length(Bytes));
end;

procedure TSecureRandomTest.GetBytes_com_zero_deve_retornar_nil;
begin
  var Bytes := TSecureRandom.GetBytes(0);
  Assert.IsTrue(Bytes = nil);
end;

procedure TSecureRandomTest.GetBytes_com_negativo_deve_retornar_nil;
begin
  var Bytes := TSecureRandom.GetBytes(-5);
  Assert.IsTrue(Bytes = nil);
end;

procedure TSecureRandomTest.GetBytes_deve_gerar_bytes_diferentes_a_cada_chamada;
begin
  var A := TSecureRandom.GetBytes(32);
  var B := TSecureRandom.GetBytes(32);

  // Probabilidade astronomicamente baixa de serem iguais
  var Igual := True;
  for var I := 0 to High(A) do
    if A[I] <> B[I] then
    begin
      Igual := False;
      Break;
    end;

  Assert.IsFalse(Igual, 'Duas chamadas consecutivas geraram bytes identicos - impossivel estatisticamente');
end;

procedure TSecureRandomTest.HexToken_deve_ter_comprimento_correto;
begin
  // 16 bytes = 32 chars hex
  var Token := TSecureRandom.HexToken(16);
  Assert.AreEqual(32, Token.Length);
end;

procedure TSecureRandomTest.HexToken_deve_conter_apenas_hex_valido;
begin
  var Token := TSecureRandom.HexToken(32);

  for var C in Token do
    Assert.IsTrue(CharInSet(C, ['0'..'9', 'a'..'f']),
      Format('Caractere invalido encontrado: "%s"', [C]));
end;

procedure TSecureRandomTest.HexToken_deve_ser_unico_a_cada_geracao;
begin
  var Token1 := TSecureRandom.HexToken(32);
  var Token2 := TSecureRandom.HexToken(32);
  Assert.AreNotEqual(Token1, Token2);
end;

procedure TSecureRandomTest.HexToken_padrao_deve_ter_64_caracteres;
begin
  // Default = 32 bytes = 64 hex chars
  var Token := TSecureRandom.HexToken;
  Assert.AreEqual(64, Token.Length);
end;

procedure TSecureRandomTest.HexToken_deve_ser_lowercase;
begin
  var Token := TSecureRandom.HexToken(32);
  Assert.AreEqual(Token, Token.ToLower, 'Token deve ser lowercase');
end;

procedure TSecureRandomTest.GetBytes_grande_deve_funcionar;
begin
  // Testar com buffer grande (1KB)
  var Bytes := TSecureRandom.GetBytes(1024);
  Assert.AreEqual(1024, Length(Bytes));

  // Verificar que nao e' tudo zero (entropia minima)
  var TodosZero := True;
  for var B in Bytes do
    if B <> 0 then
    begin
      TodosZero := False;
      Break;
    end;

  Assert.IsFalse(TodosZero, 'Buffer de 1KB nao deve ser todo zeros');
end;

procedure TSecureRandomTest.HexToken_com_1_byte_deve_ter_2_caracteres;
begin
  var Token := TSecureRandom.HexToken(1);
  Assert.AreEqual(2, Token.Length);
end;

procedure TSecureRandomTest.Multiplas_chamadas_rapidas_nunca_devem_colidir;
begin
  // Gerar 100 tokens e garantir unicidade total
  var Tokens: TArray<string>;
  SetLength(Tokens, 100);

  for var I := 0 to 99 do
    Tokens[I] := TSecureRandom.HexToken(16);

  for var I := 0 to 98 do
    for var J := I + 1 to 99 do
      Assert.AreNotEqual(Tokens[I], Tokens[J],
        Format('Colisao detectada entre indices %d e %d', [I, J]));
end;

initialization
  TDUnitX.RegisterTestFixture(TSecureRandomTest);

end.
