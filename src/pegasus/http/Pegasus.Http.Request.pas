unit Pegasus.Http.Request;

interface

type
  IRequest = interface
  ['{F66C0D83-A6D4-4246-ACD9-B755791ABCCE}']
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

end.
