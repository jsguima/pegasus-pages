unit Pegasus.Engine.Lexer;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TTokenKind = (
    tkText,
    tkExpr,
    tkRawExpr,
    tkTagFor,
    tkTagEndFor,
    tkTagIf,
    tkTagElseIf,
    tkTagElse,
    tkTagEndIf,
    tkTagPartial,
    tkEOF
  );

  TToken = record
    Kind: TTokenKind;
    Value: string;
    Line: Integer;
    Col: Integer;
  end;

  ELexerError = class(Exception)
  public
    constructor Create(const Msg: string; Line, Col: Integer);
  end;

  ILexer = interface
  ['{7A3B4C5D-E6F7-8901-ABCD-EF2345678901}']
    function Tokenize: TArray<TToken>;
  end;

  TLexer = class(TInterfacedObject, ILexer)
  private
    FSource: string;
    FPos: Integer;
    FLine: Integer;
    FCol: Integer;
    constructor Create(const Source: string);
    function ClassifyTag(const Content: string; Line, Col: Integer): TToken;
    function Current: Char;
    function IsEOF: Boolean;
    function IsUnknownTag(const FirstWord: string; const Parts: TArray<string>): Boolean;
    function MakeToken(Kind: TTokenKind; const Value: string; Line, Col: Integer): TToken;
    function Peek(Offset: Integer): Char;
    function ReadExpression: TToken;
    function ReadText: TToken;
    function ReadUntil(const Marker: string): string;
    procedure Advance;
    procedure SkipTo(const Marker: string);
  public
    function Tokenize: TArray<TToken>;
  end;

  function Lexer(const Source: string): ILexer;

implementation

{ ELexerError }

constructor ELexerError.Create(const Msg: string; Line, Col: Integer);
begin
  inherited Create(Format('%s at line %d, col %d', [Msg, Line, Col]));
end;

{ Lexer }

function Lexer(const Source: string): ILexer;
begin
  Result := TLexer.Create(Source);
end;

{ TLexer }

constructor TLexer.Create(const Source: string);
begin
  inherited Create;
  FSource := Source;
  FPos := 1;
  FLine := 1;
  FCol := 1;
end;

function TLexer.Current: Char;
begin
  if FPos <= Length(FSource) then
    Result := FSource[FPos]
  else
    Result := #0;
end;

function TLexer.Peek(Offset: Integer): Char;
begin
  var P := FPos + Offset;

  if P <= Length(FSource) then
    Result := FSource[P]
  else
    Result := #0;
end;

function TLexer.IsEOF: Boolean;
begin
  Result := FPos > Length(FSource);
end;

procedure TLexer.Advance;
begin
  if IsEOF then
    Exit;

  if Current = #10 then
  begin
    Inc(FLine);
    FCol := 1;
  end
  else
    Inc(FCol);

  Inc(FPos);
end;

function TLexer.ReadUntil(const Marker: string): string;
begin
  var Start := FPos;

  while not IsEOF do
  begin
    if FSource.Substring(FPos - 1, Length(Marker)) = Marker then
    begin
      Result := Copy(FSource, Start, FPos - Start);
      Exit;
    end;

    Advance;
  end;

  Result := Copy(FSource, Start, FPos - Start);
end;

procedure TLexer.SkipTo(const Marker: string);
begin
  var MarkerLen := Length(Marker);

  while not IsEOF do
  begin
    if FSource.Substring(FPos - 1, MarkerLen) = Marker then
    begin
      for var I := 1 to MarkerLen do
        Advance;

      Exit;
    end;

    Advance;
  end;
end;

function TLexer.MakeToken(Kind: TTokenKind; const Value: string; Line, Col: Integer): TToken;
begin
  Result.Kind := Kind;
  Result.Value := Value.Trim;
  Result.Line := Line;
  Result.Col := Col;
end;

function TLexer.IsUnknownTag(const FirstWord: string; const Parts: TArray<string>): Boolean;
begin
  if (Length(Parts) <= 1) or (FirstWord = '') or not CharInSet(FirstWord[1], ['a'..'z']) then
    Exit(False);

  var KnownKeywords: TArray<string> := ['for', 'endfor', 'if', 'endif', 'else', 'partial', 'raw'];

  for var Keyword in KnownKeywords do
    if FirstWord = Keyword then
      Exit(False);

  for var Part in Parts do
    if Part = '|' then
      Exit(False);

  Result := True;
end;

function TLexer.ClassifyTag(const Content: string; Line, Col: Integer): TToken;
begin
  var Lower := Content.Trim.ToLower;
  var Trimmed := Content.Trim;

  if Trimmed = '' then
    raise ELexerError.Create('Empty expression {{}}', Line, Col);

  if Lower.StartsWith('for ') then
    Result := MakeToken(tkTagFor, Trimmed.Substring(4), Line, Col)
  else if Lower = 'endfor' then
    Result := MakeToken(tkTagEndFor, '', Line, Col)
  else if Lower.StartsWith('if ') then
    Result := MakeToken(tkTagIf, Trimmed.Substring(3), Line, Col)
  else if Lower = 'endif' then
    Result := MakeToken(tkTagEndIf, '', Line, Col)
  else if Lower.StartsWith('else if ') then
    Result := MakeToken(tkTagElseIf, Trimmed.Substring(8), Line, Col)
  else if Lower = 'else' then
    Result := MakeToken(tkTagElse, '', Line, Col)
  else if Lower.StartsWith('partial ') then
    Result := MakeToken(tkTagPartial, Trimmed.Substring(8), Line, Col)
  else if Lower.StartsWith('raw ') then
    Result := MakeToken(tkRawExpr, Trimmed.Substring(4), Line, Col)
  else
  begin
    var Parts := Trimmed.Split([' ']);
    var FirstWord := Parts[0].ToLower;

    if IsUnknownTag(FirstWord, Parts) then
      raise ELexerError.Create(Format('Unknown tag "%s"', [FirstWord]), Line, Col);

    Result := MakeToken(tkExpr, Trimmed, Line, Col);
  end;
end;

function TLexer.ReadExpression: TToken;
begin
  var Line := FLine;
  var Col := FCol;

  Advance;
  Advance;

  var Content := ReadUntil('}}');

  if IsEOF then
    raise ELexerError.Create('Unclosed expression "{{" without "}}"', Line, Col);

  SkipTo('}}');

  Result := ClassifyTag(Content.Trim, Line, Col);
end;

function TLexer.ReadText: TToken;
begin
  var Line := FLine;
  var Col := FCol;
  var Start := FPos;

  while not IsEOF do
  begin
    if (Current = '{') and (Peek(1) = '{') then
      Break;

    Advance;
  end;

  var Text := Copy(FSource, Start, FPos - Start);

  Result := MakeToken(tkText, Text, Line, Col);
end;

function TLexer.Tokenize: TArray<TToken>;
begin
  var Tokens := TList<TToken>.Create;

  try
    while not IsEOF do
    begin
      if (Current = '{') and (Peek(1) = '{') then
        Tokens.Add(ReadExpression)
      else
      begin
        var Token := ReadText;

        if Token.Value <> '' then
          Tokens.Add(Token);
      end;
    end;

    Tokens.Add(MakeToken(tkEOF, '', FLine, FCol));
    Result := Tokens.ToArray;
  finally
    Tokens.Free;
  end;
end;

end.
