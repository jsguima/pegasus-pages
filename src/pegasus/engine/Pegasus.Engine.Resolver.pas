unit Pegasus.Engine.Resolver;

interface

uses
  System.Rtti,
  System.Generics.Collections,
  Pegasus.Data.Page;

type
  IResolver = interface
  ['{E5F6A7B8-C9D0-1234-5678-9ABCDEF01234}']
    function ResolveCondition(const Expr: string; Data: IPageDataReader; Item: TObject): Boolean;
    function ResolveFilter(const Expr: string; Data: IPageDataReader; Item: TObject): string;
    function ResolveList(const Expr: string; Data: IPageDataReader; Item: TObject): TObjectList<TObject>;
    function ResolveValue(const Expr: string; Data: IPageDataReader; Item: TObject): string;
  end;

  function Resolver: IResolver;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  Pegasus.UI.Filters,
  Pegasus.Data.RttiCache;

type
  TResolver = class(TInterfacedObject, IResolver)
  private
    FLocale: TFormatSettings;
    FDateFormat: string;
    function CompareValues(const Left, Right, Op: string): Boolean;
    function ExtractOperator(const Expr: string; out Op, LeftExpr, RightExpr: string): Boolean;
    function FormatValue(const Value: TValue): string;
    function NavigatePath(Obj: TObject; const Path: string; out Value: TValue): Boolean;
    function ResolveSide(const Side: string; Data: IPageDataReader; Item: TObject): string;
  public
    constructor Create;
    function ResolveCondition(const Expr: string; Data: IPageDataReader; Item: TObject): Boolean;
    function ResolveFilter(const Expr: string; Data: IPageDataReader; Item: TObject): string;
    function ResolveList(const Expr: string; Data: IPageDataReader; Item: TObject): TObjectList<TObject>;
    function ResolveValue(const Expr: string; Data: IPageDataReader; Item: TObject): string;
  end;

var
  _ResolverInstance: IResolver;

{ Resolver }

function Resolver: IResolver;
begin
  Result := _ResolverInstance;
end;

{ TResolver }

constructor TResolver.Create;
begin
  inherited Create;
  FLocale := TFormatSettings.Create;
  FDateFormat := FLocale.ShortDateFormat;
end;

function TResolver.NavigatePath(Obj: TObject; const Path: string; out Value: TValue): Boolean;
begin
  Result := False;

  if not Assigned(Obj) then
    Exit;

  var Parts := Path.Split(['.']);
  var Current := TValue.From<TObject>(Obj);

  for var Part in Parts do
  begin
    if Current.IsEmpty or not Current.IsObject or (Current.AsObject = nil) then
      Exit;

    var Member := RttiCache.GetMember(Current.AsObject.ClassType, Part);

    if not Assigned(Member) then
      Exit;

    if Member is TRttiProperty then
      Current := TRttiProperty(Member).GetValue(Current.AsObject)
    else
      Current := TRttiField(Member).GetValue(Current.AsObject);
  end;

  Value := Current;
  Result := True;
end;

function TResolver.FormatValue(const Value: TValue): string;
begin
  case Value.Kind of
    tkFloat:
      begin
        if Value.TypeInfo = TypeInfo(TDateTime) then
          Result := FormatDateTime(FDateFormat, Value.AsExtended)
        else
          Result := FormatFloat('0.##', Value.AsExtended, FLocale);
      end;

    tkInteger, tkInt64:
      Result := Value.AsOrdinal.ToString;

    tkEnumeration:
      if Value.TypeInfo = TypeInfo(Boolean) then
        Result := BoolToStr(Value.AsBoolean, True)
      else
        Result := Value.ToString;
  else
    Result := Value.ToString;
  end;
end;

function TResolver.ExtractOperator(const Expr: string; out Op, LeftExpr, RightExpr: string): Boolean;
const
  Operators: array[0..5] of string = ('<=', '>=', '<>', '<', '>', '=');
begin
  Result := False;

  for var O in Operators do
  begin
    var InQuote := False;
    var I := 0;

    while I < Expr.Length do
    begin
      if Expr.Chars[I] = '''' then
      begin
        InQuote := not InQuote;
        Inc(I);
        Continue;
      end;

      if InQuote then
      begin
        Inc(I);
        Continue;
      end;

      if (I > 0) and (Expr.Substring(I, O.Length) = O) then
      begin
        Op := O;
        LeftExpr := Expr.Substring(0, I).Trim;
        RightExpr := Expr.Substring(I + O.Length).Trim;
        Exit(True);
      end;

      Inc(I);
    end;
  end;
end;

function TResolver.CompareValues(const Left, Right, Op: string): Boolean;

  function TryParseNumber(const S: string; out N: Double): Boolean;
  begin
    var FS := TFormatSettings.Invariant;

    if TryStrToFloat(S, N, FS) then
      Exit(True);

    var Cleaned := S.Replace('.', '').Replace(',', '.');
    Result := TryStrToFloat(Cleaned, N, FS);
  end;

begin
  var LNum, RNum: Double;

  if TryParseNumber(Left, LNum) and TryParseNumber(Right, RNum) then
  begin
    if Op = '<' then Exit(LNum < RNum);
    if Op = '>' then Exit(LNum > RNum);
    if Op = '<=' then Exit(LNum <= RNum);
    if Op = '>=' then Exit(LNum >= RNum);
    if Op = '=' then Exit(Abs(LNum - RNum) < 0.0001);
    if Op = '<>' then Exit(Abs(LNum - RNum) >= 0.0001);
  end;

  if Op = '=' then Exit(Left = Right);
  if Op = '<>' then Exit(Left <> Right);
  if Op = '<' then Exit(Left < Right);
  if Op = '>' then Exit(Left > Right);
  if Op = '<=' then Exit(Left <= Right);
  if Op = '>=' then Exit(Left >= Right);

  Result := False;
end;

function TResolver.ResolveSide(const Side: string; Data: IPageDataReader; Item: TObject): string;
begin
  if Side.StartsWith('''') and Side.EndsWith('''') then
    Exit(Side.Substring(1, Side.Length - 2));

  if (Side <> '') and CharInSet(Side[1], ['0'..'9', '-']) then
    Exit(Side);

  Result := ResolveValue(Side, Data, Item);
end;

function TResolver.ResolveValue(const Expr: string; Data: IPageDataReader; Item: TObject): string;
begin
  if Expr.ToLower = 'slot' then
  begin
    var SlotValue := Data.GetSlot;

    if SlotValue <> '' then
      Exit(SlotValue);
  end;

  if Expr.Contains('.') and Assigned(Item) then
  begin
    var Value: TValue;

    if NavigatePath(Item, Expr.Substring(Expr.IndexOf('.') + 1), Value) then
      Exit(FormatValue(Value));
  end;

  if Expr.Contains('.') then
  begin
    var Parts := Expr.Split(['.'], 2);
    var Obj := Data.Get(Parts[0]);

    if (not Obj.IsEmpty) and Obj.IsObject then
    begin
      var Value: TValue;

      if NavigatePath(Obj.AsObject, Parts[1], Value) then
        Exit(FormatValue(Value));
    end;
  end;

  var V := Data.Get(Expr);

  if not V.IsEmpty then
    Exit(FormatValue(V));

  Result := '';
end;

function TResolver.ResolveCondition(const Expr: string; Data: IPageDataReader; Item: TObject): Boolean;
begin
  var Op, LeftExpr, RightExpr: string;

  if ExtractOperator(Expr, Op, LeftExpr, RightExpr) then
  begin
    var Left := ResolveSide(LeftExpr, Data, Item);
    var Right := ResolveSide(RightExpr, Data, Item);
    Exit(CompareValues(Left, Right, Op));
  end;

  var V := Data.Get(Expr);

  if not V.IsEmpty then
  begin
    if V.TypeInfo = TypeInfo(Boolean) then
      Exit(V.AsBoolean);

    var Str := FormatValue(V);

    Exit((Str = 'True') or (Str = '1'));
  end;

  var Resolved := ResolveValue(Expr, Data, Item);

  Result := (Resolved = 'True') or (Resolved = '1');
end;

function TResolver.ResolveList(const Expr: string; Data: IPageDataReader; Item: TObject): TObjectList<TObject>;
begin
  Result := nil;

  if Expr.Contains('.') and Assigned(Item) then
  begin
    var Value: TValue;

    if NavigatePath(Item, Expr.Substring(Expr.IndexOf('.') + 1), Value) then
    begin
      if (not Value.IsEmpty) and Value.IsObject and (Value.AsObject is TObjectList<TObject>) then
        Result := TObjectList<TObject>(Value.AsObject);

      Exit;
    end;
  end;

  var V := Data.Get(Expr);

  if (not V.IsEmpty) and V.IsObject and (V.AsObject is TObjectList<TObject>) then
    Result := TObjectList<TObject>(V.AsObject);
end;

function TResolver.ResolveFilter(const Expr: string; Data: IPageDataReader; Item: TObject): string;
begin
  var Parts := Expr.Split(['|'], 2);
  var ExprPart := Parts[0].Trim;
  var Value := ResolveValue(ExprPart, Data, Item);

  if Length(Parts) > 1 then
    Value := Filters.ApplyChain(Value, Parts[1]);

  Result := Value;
end;

initialization
  _ResolverInstance := TResolver.Create;

finalization
  _ResolverInstance := nil;

end.
