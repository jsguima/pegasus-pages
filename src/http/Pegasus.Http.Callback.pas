unit Pegasus.Http.Callback;

interface

uses
  Pegasus.Http.Request,
  Pegasus.Http.Response;

type
  TPageVerb = (pvGet, pvPost, pvPut, pvDelete);
  THandler = reference to function(Req: IRequest): IResponse;
  TRouteCallback = reference to procedure(Verb: TPageVerb; const Route: string; Handler: THandler);
  TStaticCallback = reference to procedure(const Route, FilePath, ContentType: string);

implementation

end.
