unit Pegasus.Adapters.Horse;

interface

uses
  Horse,
  System.Generics.Collections,
  Pegasus.Http.Request;

type
  THorseRequestAdapter = class(TInterfacedObject, IRequest)
  private
    FRequest: THorseRequest;
    FRouteParams: TDictionary<string, string>;
    constructor Create(Request: THorseRequest);
  public
    class function New(Request: THorseRequest): IRequest;
    destructor Destroy; override;
    function GetContentType: string;
    function GetCookie(const Name: string): string;
    function GetFormParam(const Name: string): string;
    function GetHeader(const Name: string): string;
    function GetMethod: string;
    function GetPath: string;
    function GetQueryParam(const Name: string): string;
    function GetRawBody: string;
    function GetRouteParam(const Name: string): string;
    procedure SetRouteParam(const Name, Value: string);
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding;

constructor THorseRequestAdapter.Create(Request: THorseRequest);
begin
  inherited Create;

  FRequest := Request;
  FRouteParams := TDictionary<string, string>.Create;

  for var Pair in Request.Params.Dictionary do
    FRouteParams.AddOrSetValue(Pair.Key.ToLower, Pair.Value);
end;

destructor THorseRequestAdapter.Destroy;
begin
  FRouteParams.Free;
  inherited;
end;

class function THorseRequestAdapter.New(Request: THorseRequest): IRequest;
begin
  Result := THorseRequestAdapter.Create(Request);
end;

function THorseRequestAdapter.GetQueryParam(const Name: string): string;
begin
  Result := FRequest.Query.Field(Name).AsString;
end;

function THorseRequestAdapter.GetFormParam(const Name: string): string;
begin
  var Fields := FRequest.RawWebRequest.ContentFields;

  for var I := 0 to Fields.Count - 1 do
  begin
    var Pair := Fields[I];
    var EqPos := Pair.IndexOf('=');

    if EqPos > 0 then
    begin
      var Key := Pair.Substring(0, EqPos);

      if SameText(Key, Name) then
      begin
        var RawValue := Pair.Substring(EqPos + 1);
        Result := TNetEncoding.URL.Decode(RawValue);
        Exit;
      end;
    end;
  end;

  Result := '';
end;

function THorseRequestAdapter.GetRouteParam(const Name: string): string;
begin
  if not FRouteParams.TryGetValue(Name.ToLower, Result) then
    Result := '';
end;

procedure THorseRequestAdapter.SetRouteParam(const Name, Value: string);
begin
  FRouteParams.AddOrSetValue(Name.ToLower, Value);
end;

function THorseRequestAdapter.GetHeader(const Name: string): string;
begin
  Result := FRequest.Headers[Name];
end;

function THorseRequestAdapter.GetContentType: string;
begin
  Result := GetHeader('Content-Type');
end;

function THorseRequestAdapter.GetCookie(const Name: string): string;
begin
  Result := FRequest.Cookie[Name];
end;

function THorseRequestAdapter.GetRawBody: string;
begin
  Result := FRequest.Body;
end;

function THorseRequestAdapter.GetMethod: string;
begin
  Result := FRequest.RawWebRequest.Method;
end;

function THorseRequestAdapter.GetPath: string;
begin
  Result := FRequest.PathInfo;
end;

end.
