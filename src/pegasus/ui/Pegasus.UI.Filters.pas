unit Pegasus.UI.Filters;

interface

type
  TFilterFunc = reference to function(const Value, Args: string): string;

  IFilters = interface
  ['{D1E2F3A4-B5C6-7890-1234-ABCDEF567890}']
    function Apply(const Value, Filter: string): string;
    function ApplyChain(const Value, Chain: string): string;
  end;

  function Filters: IFilters;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  System.Generics.Collections,
  Pegasus.Security.Encoder;

type
  TFilters = class(TInterfacedObject, IFilters)
  private
    FRegistry: TDictionary<string, TFilterFunc>;
    FLocale: TFormatSettings;
    procedure RegisterConditionalFilters;
    procedure RegisterDateFilters;
    procedure RegisterNumberFilters;
    procedure RegisterSecurityFilters;
    procedure RegisterTextFilters;
  public
    constructor Create;
    destructor Destroy; override;
    function Apply(const Value, Filter: string): string;
    function ApplyChain(const Value, Chain: string): string;
    procedure Register(const Name: string; Func: TFilterFunc);
  end;

var
  _FiltersInstance: IFilters;

{ Filters }

function Filters: IFilters;
begin
  Result := _FiltersInstance;
end;

{ TFilters }

constructor TFilters.Create;
begin
  inherited Create;
  FRegistry := TDictionary<string, TFilterFunc>.Create;
  FLocale := TFormatSettings.Create;
  RegisterTextFilters;
  RegisterNumberFilters;
  RegisterConditionalFilters;
  RegisterDateFilters;
  RegisterSecurityFilters;
end;

destructor TFilters.Destroy;
begin
  FRegistry.Free;
  inherited;
end;

procedure TFilters.Register(const Name: string; Func: TFilterFunc);
begin
  FRegistry.AddOrSetValue(Name.ToLower.Trim, Func);
end;

function TFilters.Apply(const Value, Filter: string): string;
begin
  var Parts := Filter.Split([':'], 2);
  var Name := Parts[0].Trim.ToLower;
  var Args := '';

  if Length(Parts) > 1 then
    Args := Parts[1].Trim.DeQuotedString('''');

  var Func: TFilterFunc;

  if FRegistry.TryGetValue(Name, Func) then
    Result := Func(Value, Args)
  else
    Result := Value;
end;

function TFilters.ApplyChain(const Value, Chain: string): string;
begin
  Result := Value;
  var FilterParts := Chain.Split(['|']);

  for var F in FilterParts do
  begin
    var Trimmed := F.Trim;

    if Trimmed <> '' then
      Result := Apply(Result, Trimmed);
  end;
end;

procedure TFilters.RegisterTextFilters;
begin
  Register('upper', function(const Value, Args: string): string
  begin
    Result := Value.ToUpper;
  end);

  Register('lower', function(const Value, Args: string): string
  begin
    Result := Value.ToLower;
  end);

  Register('trim', function(const Value, Args: string): string
  begin
    Result := Value.Trim;
  end);

  Register('truncate', function(const Value, Args: string): string
  begin
    var Len := StrToIntDef(Args, 50);

    if Value.Length > Len then
      Result := Value.Substring(0, Len) + '...'
    else
      Result := Value;
  end);

  Register('default', function(const Value, Args: string): string
  begin
    if Value.Trim = '' then
      Result := Args
    else
      Result := Value;
  end);
end;

procedure TFilters.RegisterNumberFilters;
begin
  var Locale := FLocale;

  Register('currency', function(const Value, Args: string): string
  begin
    try
      var FS := TFormatSettings.Invariant;
      var Cleaned := Value.Replace(',', '.');
      var Val := StrToFloat(Cleaned, FS);
      var Formatted: string;

      if Val < 0 then
        Formatted := '-' + FormatFloat('#,##0.00', Abs(Val), Locale)
      else
        Formatted := FormatFloat('#,##0.00', Val, Locale);

      if Args.ToLower = 'prefix' then
        Result := Locale.CurrencyString + ' ' + Formatted
      else
        Result := Formatted;
    except
      Result := Value;
    end;
  end);

  Register('decimal', function(const Value, Args: string): string
  begin
    Result := Value.Replace('.', ',');
  end);

  Register('number', function(const Value, Args: string): string
  begin
    var Decimals := 2;

    if Args <> '' then
      Decimals := StrToIntDef(Args, 2);

    try
      var FS := TFormatSettings.Invariant;
      Result := FormatFloat('0.' + StringOfChar('0', Decimals), StrToFloat(Value, FS));
    except
      Result := Value;
    end;
  end);
end;

procedure TFilters.RegisterConditionalFilters;
begin
  Register('iif', function(const Value, Args: string): string
  begin
    var ArgParts := Args.Split([',']);

    if Length(ArgParts) < 3 then
    begin
      Result := '';
      Exit;
    end;

    var Condition := ArgParts[0].Trim;
    var TrueVal := ArgParts[1].Trim;
    var FalseVal := ArgParts[2].Trim;

    var FS := TFormatSettings.Invariant;
    var NumVal := StrToFloatDef(Value.Replace(',', '.'), 0, FS);
    var CondMet := False;

    if Condition.StartsWith('<=') then
      CondMet := NumVal <= StrToFloatDef(Condition.Substring(2), 0, FS)
    else if Condition.StartsWith('>=') then
      CondMet := NumVal >= StrToFloatDef(Condition.Substring(2), 0, FS)
    else if Condition.StartsWith('<>') then
      CondMet := Abs(NumVal - StrToFloatDef(Condition.Substring(2), 0, FS)) >= 0.0001
    else if Condition.StartsWith('<') then
      CondMet := NumVal < StrToFloatDef(Condition.Substring(1), 0, FS)
    else if Condition.StartsWith('>') then
      CondMet := NumVal > StrToFloatDef(Condition.Substring(1), 0, FS)
    else if Condition.StartsWith('=') then
      CondMet := Abs(NumVal - StrToFloatDef(Condition.Substring(1), 0, FS)) < 0.0001;

    if CondMet then
      Result := TrueVal
    else
      Result := FalseVal;
  end);
end;

procedure TFilters.RegisterDateFilters;
begin
  Register('date', function(const Value, Args: string): string
  begin
    var Fmt := Args;

    if Fmt = '' then
      Fmt := 'dd/mm/yyyy';

    try
      var FS := TFormatSettings.Invariant;
      Result := FormatDateTime(Fmt, StrToFloat(Value, FS));
    except
      Result := Value;
    end;
  end);
end;

procedure TFilters.RegisterSecurityFilters;
begin
  Register('url', function(const Value, Args: string): string
  const
    MaxDecodeIterations = 5;
  begin
    var Decoded := Value;

    for var I := 1 to MaxDecodeIterations do
    begin
      var Previous := Decoded;
      Decoded := TNetEncoding.URL.Decode(Decoded);

      if Decoded = Previous then
        Break;
    end;

    var Lower := Decoded.ToLower.Trim;
    Lower := Lower.Replace(#0, '').Replace(#9, '').Replace(#10, '').Replace(#13, '');

    if Lower.StartsWith('javascript:') or
       Lower.StartsWith('data:') or
       Lower.StartsWith('vbscript:') or
       Lower.StartsWith('file:') then
      Result := '#blocked'
    else
      Result := Value;
  end);

  Register('attr', function(const Value, Args: string): string
  begin
    Result := TEncoder.Attr(Value);
  end);

  Register('js', function(const Value, Args: string): string
  begin
    Result := TEncoder.Js(Value);
  end);
end;

initialization
  _FiltersInstance := TFilters.Create;

finalization
  _FiltersInstance := nil;

end.
