unit Pegasus.Http.Middleware;

interface

uses
  System.SysUtils,
  Pegasus.Http.Request,
  Pegasus.Http.Response;

type
  ERequestTimeout = class(Exception);

  TMiddlewareProc = reference to procedure;
  TMiddleware = reference to procedure(Req: IRequest; Res: IResponse; Next: TMiddlewareProc);

  TMiddlewares = class
  public
    class function Csrf: TMiddleware;
    class function SecureHeaders(const ExtraFontSrc: TArray<string> = nil;
      const ExtraScriptSrc: TArray<string> = nil): TMiddleware;
    class function Timeout(TimeoutMs: Integer = 5000): TMiddleware;
  end;

function GetCsrfToken: string;
procedure CheckTimeout;
procedure ConfigureEnvironment(Production: Boolean);

implementation

uses
  System.Diagnostics,
  Pegasus.Security.SecureRandom;

function ConstantTimeEquals(const A, B: string): Boolean;
begin
  var Diff := Length(A) xor Length(B);
  var MaxLen := Length(A);

  if Length(B) > MaxLen then
    MaxLen := Length(B);

  for var I := 1 to MaxLen do
  begin
    if (I <= Length(A)) and (I <= Length(B)) then
      Diff := Diff or (Ord(A[I]) xor Ord(B[I]))
    else
      Diff := Diff or 1;
  end;

  Result := Diff = 0;
end;

threadvar
  _CsrfToken: string;
  _DeadlineMs: Int64;
  _CheckCounter: Integer;

var
  _Production: Boolean = False;

function GetCsrfToken: string;
begin
  Result := _CsrfToken;
end;

procedure CheckTimeout;
begin
  if _DeadlineMs = 0 then
    Exit;

  Inc(_CheckCounter);

  if (_CheckCounter and 63) <> 0 then
    Exit;

  if TStopwatch.GetTimeStamp > _DeadlineMs then
    raise ERequestTimeout.Create('Request processing timeout exceeded');
end;

procedure ConfigureEnvironment(Production: Boolean);
begin
  _Production := Production;
end;

{ TMiddlewares }

class function TMiddlewares.Csrf: TMiddleware;
begin
  Result :=
    procedure(Req: IRequest; Res: IResponse; Next: TMiddlewareProc)
    begin
      _CsrfToken := '';

      var CookieToken := Req.GetCookie('_csrf');

      if CookieToken = '' then
      begin
        CookieToken := TSecureRandom.HexToken(32);

        var CookieValue := '_csrf=' + CookieToken + '; Path=/; HttpOnly; SameSite=Strict';

        if _Production then
          CookieValue := CookieValue + '; Secure';

        Res.AddHeader('Set-Cookie', CookieValue);
      end;

      _CsrfToken := CookieToken;

      var Method := Req.GetMethod.ToUpper;

      if (Method = 'POST') or (Method = 'PUT') or (Method = 'DELETE') then
      begin
        var SubmittedToken := Req.GetHeader('X-CSRF-Token');

        if SubmittedToken = '' then
          SubmittedToken := Req.GetFormParam('_csrf');

        if (SubmittedToken = '') or (not ConstantTimeEquals(CookieToken, SubmittedToken)) then
        begin
          Res.SetStatus(403);
          Res.SetHtml('Invalid or missing CSRF token');
          Exit;
        end;
      end;

      Next;
    end;
end;

class function TMiddlewares.SecureHeaders(const ExtraFontSrc: TArray<string>;
  const ExtraScriptSrc: TArray<string>): TMiddleware;
var
  FontSrc, ScriptSrc: string;
begin
  FontSrc := '''self''';

  if ExtraFontSrc <> nil then
    for var Src in ExtraFontSrc do
      FontSrc := FontSrc + ' ' + Src;

  ScriptSrc := '''self''';

  if ExtraScriptSrc <> nil then
    for var Src in ExtraScriptSrc do
      ScriptSrc := ScriptSrc + ' ' + Src;

  var CspValue := 'default-src ''self''; script-src ' + ScriptSrc +
    '; style-src ''self'' ''unsafe-inline''; ' +
    'img-src ''self'' data:; font-src ' + FontSrc + '; frame-ancestors ''none''';

  Result :=
    procedure(Req: IRequest; Res: IResponse; Next: TMiddlewareProc)
    begin
      Res.AddHeader('X-Content-Type-Options', 'nosniff');
      Res.AddHeader('X-Frame-Options', 'DENY');
      Res.AddHeader('Content-Security-Policy', CspValue);

      if _Production then
        Res.AddHeader('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');

      Next;
    end;
end;

class function TMiddlewares.Timeout(TimeoutMs: Integer): TMiddleware;
begin
  Result :=
    procedure(Req: IRequest; Res: IResponse; Next: TMiddlewareProc)
    begin
      _DeadlineMs := TStopwatch.GetTimeStamp +
        (Int64(TimeoutMs) * TStopwatch.Frequency div 1000);
      _CheckCounter := 0;

      try
        Next;
      except
        on E: ERequestTimeout do
        begin
          Res.SetStatus(503);
          Res.SetHtml('Request timeout');
        end;
      end;
    end;
end;

end.
