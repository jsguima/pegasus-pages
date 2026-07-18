unit Pegasus.Security.Encoder;

interface

type
  TEncoder = class
  public
    class function Attr(const Value: string): string;
    class function Html(const Value: string): string;
    class function Js(const Value: string): string;
  end;

implementation

uses
  System.SysUtils;

class function TEncoder.Html(const Value: string): string;
begin
  Result := Value
    .Replace('&', '&amp;')
    .Replace('<', '&lt;')
    .Replace('>', '&gt;')
    .Replace('"', '&quot;')
    .Replace('''', '&#39;');
end;

class function TEncoder.Attr(const Value: string): string;
begin
  Result := Value
    .Replace('&', '&amp;')
    .Replace('<', '&lt;')
    .Replace('>', '&gt;')
    .Replace('"', '&quot;')
    .Replace('''', '&#39;')
    .Replace('/', '&#x2F;')
    .Replace('`', '&#96;');
end;

class function TEncoder.Js(const Value: string): string;
begin
  Result := Value
    .Replace('\', '\\')
    .Replace('''', '\''')
    .Replace('"', '\"')
    .Replace('`', '\`')
    .Replace(#10, '\n')
    .Replace(#13, '\r')
    .Replace(#$2028, '\u2028')
    .Replace(#$2029, '\u2029')
    .Replace('</', '<\/');
end;

end.
