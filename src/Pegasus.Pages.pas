unit Pegasus.Pages;

interface

uses
  Pegasus.Http.Callback,
  Pegasus.Http.Middleware;

type
  IPegasusPages = interface
  ['{9FC26205-DB51-4EDE-8DDF-584284DE971A}']
    function ContentRoot(const APath: string): IPegasusPages;
    function MapPages(Callback: TRouteCallback): IPegasusPages;
    function MapStatic(Callback: TStaticCallback): IPegasusPages;
    function UseComponentPrefix(const Prefixes: array of string): IPegasusPages;
    function UseMiddleware(Middleware: TMiddleware): IPegasusPages;
  end;

  function PegasusPages(): IPegasusPages;

implementation

uses
  Pegasus.Routing.Mapper,
  Pegasus.UI.Components;

type
  TPegasusPages = class(TInterfacedObject, IPegasusPages)
  private
    FContentRoot: string;
    FMiddlewares: TArray<TMiddleware>;
  public
    function ContentRoot(const APath: string): IPegasusPages;
    function MapPages(Callback: TRouteCallback): IPegasusPages;
    function MapStatic(Callback: TStaticCallback): IPegasusPages;
    function UseComponentPrefix(const Prefixes: array of string): IPegasusPages;
    function UseMiddleware(Middleware: TMiddleware): IPegasusPages;
  end;

{ Public accessor }

function PegasusPages(): IPegasusPages;
begin
  Result := TPegasusPages.Create;
end;

{ TPegasusPages }

function TPegasusPages.ContentRoot(const APath: string): IPegasusPages;
begin
  FContentRoot := APath;
  Result := Self;
end;

function TPegasusPages.UseMiddleware(Middleware: TMiddleware): IPegasusPages;
begin
  FMiddlewares := FMiddlewares + [Middleware];
  Result := Self;
end;

function TPegasusPages.UseComponentPrefix(const Prefixes: array of string): IPegasusPages;
begin
  var Arr: TArray<string>;
  SetLength(Arr, Length(Prefixes));

  for var I := 0 to High(Prefixes) do
    Arr[I] := Prefixes[I];

  ComponentRegistry.SetAllowedPrefixes(Arr);
  Result := Self;
end;

function TPegasusPages.MapPages(Callback: TRouteCallback): IPegasusPages;
begin
  Mapper.MapPages(FContentRoot, FMiddlewares, Callback);
  Result := Self;
end;

function TPegasusPages.MapStatic(Callback: TStaticCallback): IPegasusPages;
begin
  Mapper.MapStatic(FContentRoot, Callback);
  Result := Self;
end;

end.
