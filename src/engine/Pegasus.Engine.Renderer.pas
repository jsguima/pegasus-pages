unit Pegasus.Engine.Renderer;

interface

uses
  Pegasus.Data.Page,
  Pegasus.Engine.Nodes;

type
  IRenderer = interface
  ['{F1A2B3C4-D5E6-7890-ABCD-EF1234567890}']
    function Render(Nodes: INodeListReader; Data: IPageDataReader): string;
  end;

  function Renderer: IRenderer;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Pegasus.Security.Encoder,
  Pegasus.Http.Middleware,
  Pegasus.UI.Partials,
  Pegasus.Engine.Resolver;

type
  TRenderer = class(TInterfacedObject, IRenderer)
  private
    procedure RenderFor(Node: TForNode; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
    procedure RenderIf(Node: TIfNode; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
    procedure RenderList(Nodes: TObjectList<TNode>; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
    procedure RenderNode(Node: TNode; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
    procedure RenderNodes(Nodes: INodeListReader; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
    procedure RenderPartial(Node: TPartialNode; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
  public
    function Render(Nodes: INodeListReader; Data: IPageDataReader): string;
  end;

var
  _RendererInstance: IRenderer;

{ Renderer }

function Renderer: IRenderer;
begin
  Result := _RendererInstance;
end;

{ TRenderer }

procedure TRenderer.RenderNode(Node: TNode; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
begin
  CheckTimeout;

  case Node.Kind of
    nkText:
      SB.Append(TTextNode(Node).Text);

    nkExpr:
    begin
      var Expr := TExprNode(Node).Expr;

      if Expr.ToLower = 'slot' then
      begin
        var SlotValue := Resolver.ResolveFilter(Expr, Data, Item);

        if Data.IsSlotTrusted then
          SB.Append(SlotValue)
        else
          SB.Append(TEncoder.Html(SlotValue));
      end
      else
        SB.Append(TEncoder.Html(Resolver.ResolveFilter(Expr, Data, Item)));
    end;

    nkRawExpr:
      SB.Append(Resolver.ResolveFilter(TRawExprNode(Node).Expr, Data, Item));

    nkFor:
      RenderFor(TForNode(Node), Data, Item, SB);

    nkIf:
      RenderIf(TIfNode(Node), Data, Item, SB);

    nkPartial:
      RenderPartial(TPartialNode(Node), Data, Item, SB);
  end;
end;

procedure TRenderer.RenderNodes(Nodes: INodeListReader; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
begin
  for var Node in Nodes do
    RenderNode(Node, Data, Item, SB);
end;

procedure TRenderer.RenderList(Nodes: TObjectList<TNode>; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
begin
  for var Node in Nodes do
    RenderNode(Node, Data, Item, SB);
end;

procedure TRenderer.RenderFor(Node: TForNode; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
begin
  var Lista := Resolver.ResolveList(Node.ListName, Data, Item);

  if (not Assigned(Lista)) or (Lista.Count = 0) then
  begin
    RenderList(Node.ElseChildren, Data, Item, SB);
    Exit;
  end;

  for var ListItem in Lista do
    RenderList(Node.Children, Data, ListItem, SB);
end;

procedure TRenderer.RenderIf(Node: TIfNode; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
begin
  for var I := 0 to Node.Branches.Count - 1 do
  begin
    var Branch := Node.Branches[I];

    if Resolver.ResolveCondition(Branch.Expr, Data, Item) then
    begin
      RenderList(Branch.Children, Data, Item, SB);
      Exit;
    end;
  end;

  RenderList(Node.ElseChildren, Data, Item, SB);
end;

procedure TRenderer.RenderPartial(Node: TPartialNode; Data: IPageDataReader; Item: TObject; SB: TStringBuilder);
begin
  var Nodes := PartialRegistry.GetNodes(Node.PartialName);

  if not Assigned(Nodes) then
  begin
    SB.Append('<!-- partial "' + Node.PartialName + '" not found -->');
    Exit;
  end;

  RenderNodes(Nodes, Data, Item, SB);
end;

function TRenderer.Render(Nodes: INodeListReader; Data: IPageDataReader): string;
begin
  var SB := TStringBuilder.Create;

  try
    RenderNodes(Nodes, Data, nil, SB);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

initialization
  _RendererInstance := TRenderer.Create;

finalization
  _RendererInstance := nil;

end.
