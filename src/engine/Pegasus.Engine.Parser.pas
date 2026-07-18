unit Pegasus.Engine.Parser;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Pegasus.Engine.Lexer,
  Pegasus.Engine.Nodes;

type
  EParserError = class(Exception)
  public
    constructor Create(const Msg: string; Line, Col: Integer);
  end;

  IParser = interface
  ['{8B4C5D6E-F7A8-9012-BCDE-F34567890123}']
    function Parse: INodeListOwner;
  end;

  TParser = class(TInterfacedObject, IParser)
  private
    FTokens: TArray<TToken>;
    FPos: Integer;
    constructor Create(const Tokens: TArray<TToken>);
    function Consume: TToken;
    function Current: TToken;
    function IsEOF: Boolean;
    function IsStopToken(const StopKinds: TArray<TTokenKind>): Boolean;
    function ParseFor: TForNode;
    function ParseIf: TIfNode;
    procedure ParseBlock(Target: TObjectList<TNode>; const StopKinds: TArray<TTokenKind>);
  public
    function Parse: INodeListOwner;
  end;

  function Parser(const Tokens: TArray<TToken>): IParser;

implementation

{ EParserError }

constructor EParserError.Create(const Msg: string; Line, Col: Integer);
begin
  inherited Create(Format('%s at line %d, col %d', [Msg, Line, Col]));
end;

{ Parser }

function Parser(const Tokens: TArray<TToken>): IParser;
begin
  Result := TParser.Create(Tokens);
end;

{ TParser }

constructor TParser.Create(const Tokens: TArray<TToken>);
begin
  inherited Create;
  FTokens := Tokens;
  FPos := 0;
end;

function TParser.Current: TToken;
begin
  Result := FTokens[FPos];
end;

function TParser.Consume: TToken;
begin
  Result := FTokens[FPos];

  if not IsEOF then
    Inc(FPos);
end;

function TParser.IsEOF: Boolean;
begin
  Result := (FPos >= Length(FTokens)) or (FTokens[FPos].Kind = tkEOF);
end;

function TParser.IsStopToken(const StopKinds: TArray<TTokenKind>): Boolean;
begin
  for var K in StopKinds do
    if Current.Kind = K then
      Exit(True);

  Result := False;
end;

procedure TParser.ParseBlock(Target: TObjectList<TNode>; const StopKinds: TArray<TTokenKind>);
begin
  while not IsEOF and not IsStopToken(StopKinds) do
  begin
    var T := Current;

    case T.Kind of
      tkText:
        begin
          Consume;
          Target.Add(TTextNode.Create(T.Value, T.Line, T.Col));
        end;

      tkExpr:
        begin
          Consume;
          Target.Add(TExprNode.Create(T.Value, T.Line, T.Col));
        end;

      tkRawExpr:
        begin
          Consume;
          Target.Add(TRawExprNode.Create(T.Value, T.Line, T.Col));
        end;

      tkTagPartial:
        begin
          Consume;
          Target.Add(TPartialNode.Create(T.Value, T.Line, T.Col));
        end;

      tkTagFor:
        Target.Add(ParseFor);

      tkTagIf:
        Target.Add(ParseIf);

      tkTagEndFor:
        raise EParserError.Create('Unexpected "endfor" without matching "for"', T.Line, T.Col);

      tkTagEndIf:
        raise EParserError.Create('Unexpected "endif" without matching "if"', T.Line, T.Col);

      tkTagElse, tkTagElseIf:
        raise EParserError.Create('Unexpected "else" without matching "if"', T.Line, T.Col);
    else
      Consume;
    end;
  end;
end;

function TParser.ParseFor: TForNode;
begin
  var T := Consume;
  var Parts := T.Value.Split([' ']);

  if (Length(Parts) < 3) or (Parts[1].ToLower <> 'in') then
    raise EParserError.Create(
      Format('Invalid "for" syntax: expected "for item in list", got "for %s"', [T.Value]), T.Line, T.Col);

  Result := TForNode.Create(Parts[0], Parts[2], T.Line, T.Col);

  try
    ParseBlock(Result.Children, [tkTagEndFor, tkTagElse]);

    if (not IsEOF) and (Current.Kind = tkTagElse) then
    begin
      Consume;
      ParseBlock(Result.ElseChildren, [tkTagEndFor]);
    end;

    if IsEOF then
      raise EParserError.Create('"for" block not closed with "endfor"', T.Line, T.Col);

    Consume;
  except
    Result.Free;
    raise;
  end;
end;

function TParser.ParseIf: TIfNode;
begin
  var T := Consume;

  Result := TIfNode.Create(T.Line, T.Col);

  try
    var Branch := TIfBranch.Create(T.Value);
    Result.Branches.Add(Branch);

    ParseBlock(Branch.Children, [tkTagEndIf, tkTagElse, tkTagElseIf]);

    while (not IsEOF) and (Current.Kind = tkTagElseIf) do
    begin
      var ElseIfToken := Consume;
      var ElseIfBranch := TIfBranch.Create(ElseIfToken.Value);
      Result.Branches.Add(ElseIfBranch);

      ParseBlock(ElseIfBranch.Children, [tkTagEndIf, tkTagElse, tkTagElseIf]);
    end;

    if (not IsEOF) and (Current.Kind = tkTagElse) then
    begin
      Consume;
      ParseBlock(Result.ElseChildren, [tkTagEndIf]);
    end;

    if IsEOF then
      raise EParserError.Create('"if" block not closed with "endif"', T.Line, T.Col);

    Consume;
  except
    Result.Free;
    raise;
  end;
end;

function TParser.Parse: INodeListOwner;
begin
  var Owner := NodeList();
  var Writer := Owner.Writer;

  var TempList := TObjectList<TNode>.Create(False);

  try
    ParseBlock(TempList, []);

    for var Node in TempList do
      Writer.Add(Node);
  except
    for var Node in TempList do
      Node.Free;

    TempList.Free;

    raise;
  end;

  TempList.Free;
  Result := Owner;
end;

end.
