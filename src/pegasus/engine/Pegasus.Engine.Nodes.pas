unit Pegasus.Engine.Nodes;

interface

uses
  System.Generics.Collections;

type
  TNodeKind = (
    nkText,     // HTML puro
    nkExpr,     // {{ expr }} — com HTML encode
    nkRawExpr,  // {{raw expr}} — sem encode
    nkFor,      // {{for item in lista}} ... {{endfor}}
    nkIf,       // {{if cond}} ... {{else}} ... {{endif}}
    nkPartial   // {{partial "nome"}}
  );

  TNode = class
  public
    Kind: TNodeKind;
    Line: Integer;
    Col: Integer;
  end;

  TTextNode = class(TNode)
  public
    Text: string;
    constructor Create(const Text: string; Line, Col: Integer);
  end;

  TExprNode = class(TNode)
  public
    Expr: string;
    constructor Create(const Expr: string; Line, Col: Integer);
  end;

  TRawExprNode = class(TNode)
  public
    Expr: string;
    constructor Create(const Expr: string; Line, Col: Integer);
  end;

  TForNode = class(TNode)
  public
    VarName: string;
    ListName: string;
    Children: TObjectList<TNode>;
    ElseChildren: TObjectList<TNode>;
    constructor Create(const VarName, ListName: string; Line, Col: Integer);
    destructor Destroy; override;
  end;

  TIfBranch = class
  public
    Expr: string;
    Children: TObjectList<TNode>;
    constructor Create(const Expr: string);
    destructor Destroy; override;
  end;

  TIfNode = class(TNode)
  public
    Branches: TObjectList<TIfBranch>;
    ElseChildren: TObjectList<TNode>;
    constructor Create(Line, Col: Integer);
    destructor Destroy; override;
  end;

  TPartialNode = class(TNode)
  public
    PartialName: string;
    constructor Create(const PartialName: string; Line, Col: Integer);
  end;

  TNodeListEnumerator = record
  private
    FList: TObjectList<TNode>;
    FIndex: Integer;
  public
    constructor Create(List: TObjectList<TNode>);
    function GetCurrent: TNode;
    function MoveNext: Boolean;
    property Current: TNode read GetCurrent;
  end;

  INodeListReader = interface
  ['{D1E2F3A4-B5C6-7890-ABCD-EF1234567890}']
    function GetCount: Integer;
    function GetEnumerator: TNodeListEnumerator;
    function GetItem(Index: Integer): TNode;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TNode read GetItem; default;
  end;

  INodeListWriter = interface
  ['{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}']
    procedure Add(Node: TNode);
    procedure Clear;
  end;

  INodeListOwner = interface
  ['{F1A2B3C4-D5E6-7890-FEDC-BA0987654321}']
    function Reader: INodeListReader;
    function Writer: INodeListWriter;
  end;

  TNodeList = class(TInterfacedObject, INodeListOwner, INodeListReader, INodeListWriter)
  private
    FList: TObjectList<TNode>;
    constructor Create;
  public
    destructor Destroy; override;
    function GetCount: Integer;
    function GetEnumerator: TNodeListEnumerator;
    function GetItem(Index: Integer): TNode;
    function Reader: INodeListReader;
    function Writer: INodeListWriter;
    procedure Add(Node: TNode);
    procedure Clear;
  end;

  function NodeList(): INodeListOwner;

implementation

{ NodeList }

function NodeList(): INodeListOwner;
begin
  Result := TNodeList.Create();
end;

{ TTextNode }

constructor TTextNode.Create(const Text: string; Line, Col: Integer);
begin
  Kind := nkText;
  Self.Text := Text;
  Self.Line := Line;
  Self.Col := Col;
end;

{ TExprNode }

constructor TExprNode.Create(const Expr: string; Line, Col: Integer);
begin
  Kind := nkExpr;
  Self.Expr := Expr;
  Self.Line := Line;
  Self.Col := Col;
end;

{ TRawExprNode }

constructor TRawExprNode.Create(const Expr: string; Line, Col: Integer);
begin
  Kind := nkRawExpr;
  Self.Expr := Expr;
  Self.Line := Line;
  Self.Col := Col;
end;

{ TForNode }

constructor TForNode.Create(const VarName, ListName: string; Line, Col: Integer);
begin
  Kind := nkFor;
  Self.VarName := VarName;
  Self.ListName := ListName;
  Self.Line := Line;
  Self.Col := Col;
  Children := TObjectList<TNode>.Create(True);
  ElseChildren := TObjectList<TNode>.Create(True);
end;

destructor TForNode.Destroy;
begin
  Children.Free;
  ElseChildren.Free;
  inherited;
end;

{ TIfBranch }

constructor TIfBranch.Create(const Expr: string);
begin
  Self.Expr := Expr;
  Children := TObjectList<TNode>.Create(True);
end;

destructor TIfBranch.Destroy;
begin
  Children.Free;
  inherited;
end;

{ TIfNode }

constructor TIfNode.Create(Line, Col: Integer);
begin
  Kind := nkIf;
  Self.Line := Line;
  Self.Col := Col;
  Branches := TObjectList<TIfBranch>.Create(True);
  ElseChildren := TObjectList<TNode>.Create(True);
end;

destructor TIfNode.Destroy;
begin
  Branches.Free;
  ElseChildren.Free;
  inherited;
end;

{ TPartialNode }

constructor TPartialNode.Create(const PartialName: string; Line, Col: Integer);
begin
  Kind := nkPartial;
  Self.PartialName := PartialName;
  Self.Line := Line;
  Self.Col := Col;
end;

{ TNodeListEnumerator }

constructor TNodeListEnumerator.Create(List: TObjectList<TNode>);
begin
  FList := List;
  FIndex := -1;
end;

function TNodeListEnumerator.GetCurrent: TNode;
begin
  Result := FList[FIndex];
end;

function TNodeListEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FList.Count;
end;

{ TNodeList }

constructor TNodeList.Create;
begin
  inherited Create;
  FList := TObjectList<TNode>.Create(True);
end;

destructor TNodeList.Destroy;
begin
  FList.Free;
  inherited;
end;

function TNodeList.Reader: INodeListReader;
begin
  Result := Self;
end;

function TNodeList.Writer: INodeListWriter;
begin
  Result := Self;
end;

function TNodeList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TNodeList.GetItem(Index: Integer): TNode;
begin
  Result := FList[Index];
end;

function TNodeList.GetEnumerator: TNodeListEnumerator;
begin
  Result := TNodeListEnumerator.Create(FList);
end;

procedure TNodeList.Add(Node: TNode);
begin
  FList.Add(Node);
end;

procedure TNodeList.Clear;
begin
  FList.Clear;
end;

end.
