unit Pegasus.Http.Response;

interface

uses
  System.Classes;

type
  IResponse = interface
  ['{90B56073-3505-4CE4-921C-FB8D9EB5AB9C}']
    function GetContentType: string;
    function GetHeader(const Name: string): string;
    function GetHeaders: TStrings;
    function GetHtml: string;
    function GetStatusCode: Integer;
    function GetStream: TStream;
    function GetStreamFileName: string;
    function IsStream: Boolean;
    procedure AddHeader(const Name, Value: string);
    procedure SendStream(AStream: TStream; const FileName: string);
    procedure SetContentType(const Value: string);
    procedure SetHtml(const Value: string);
    procedure SetStatus(Code: Integer);
  end;

  TResponse = class(TInterfacedObject, IResponse)
  private
    FStatusCode: Integer;
    FHtml: string;
    FContentType: string;
    FStream: TStream;
    FStreamFileName: string;
    FIsStream: Boolean;
    FHeaders: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function GetContentType: string;
    function GetHeader(const Name: string): string;
    function GetHeaders: TStrings;
    function GetHtml: string;
    function GetStatusCode: Integer;
    function GetStream: TStream;
    function GetStreamFileName: string;
    function IsStream: Boolean;
    procedure AddHeader(const Name, Value: string);
    procedure SendStream(Stream: TStream; const FileName: string);
    procedure SetContentType(const Value: string);
    procedure SetHtml(const Value: string);
    procedure SetStatus(Code: Integer);
  end;


implementation

{ TResponse }

constructor TResponse.Create;
begin
  inherited Create;
  FStatusCode := 200;
  FContentType := 'text/html; charset=utf-8';
  FIsStream := False;
  FHeaders := TStringList.Create;
end;

destructor TResponse.Destroy;
begin
  FHeaders.Free;

  if Assigned(FStream) then
    FStream.Free;

  inherited;
end;

procedure TResponse.AddHeader(const Name, Value: string);
begin
  FHeaders.Values[Name] := Value;
end;

function TResponse.GetContentType: string;
begin
  Result := FContentType;
end;

function TResponse.GetHeader(const Name: string): string;
begin
  Result := FHeaders.Values[Name];
end;

function TResponse.GetHeaders: TStrings;
begin
  Result := FHeaders;
end;

function TResponse.GetHtml: string;
begin
  Result := FHtml;
end;

function TResponse.GetStatusCode: Integer;
begin
  Result := FStatusCode;
end;

function TResponse.GetStream: TStream;
begin
  Result := FStream;
end;

function TResponse.GetStreamFileName: string;
begin
  Result := FStreamFileName;
end;

function TResponse.IsStream: Boolean;
begin
  Result := FIsStream;
end;

procedure TResponse.SendStream(Stream: TStream; const FileName: string);
begin
  if Assigned(FStream) and (FStream <> Stream) then
    FStream.Free;

  FStream := Stream;
  FStreamFileName := FileName;
  FIsStream := True;
end;

procedure TResponse.SetContentType(const Value: string);
begin
  FContentType := Value;
end;

procedure TResponse.SetHtml(const Value: string);
begin
  FHtml := Value;
end;

procedure TResponse.SetStatus(Code: Integer);
begin
  FStatusCode := Code;
end;

end.
