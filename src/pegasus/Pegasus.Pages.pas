unit Pegasus.Pages;

interface

uses
  Pegasus.Http.Callback,
  Pegasus.Routing.Mapper;

type
  IPegasusPages = interface
  ['{9FC26205-DB51-4EDE-8DDF-584284DE971A}']
    function ContentRoot(const APath: string): IPegasusPages;
    function MapPages(Callback: TRouteCallback): IPegasusPages;
    function MapStatic(Callback: TStaticCallback): IPegasusPages;
    function UseComponentPrefix(const Prefixes: array of string): IPegasusPages;
  end;

  TPegasusPages = class(TInterfacedObject, IPegasusPages)
  private
    FContentRoot: string;
  public
    class function New(): IPegasusPages;
    function ContentRoot(const APath: string): IPegasusPages;
    function MapPages(Callback: TRouteCallback): IPegasusPages;
    function MapStatic(Callback: TStaticCallback): IPegasusPages;
    function UseComponentPrefix(const Prefixes: array of string): IPegasusPages;
  end;

implementation

uses
  Pegasus.UI.Components;

{ TPegasusPages }

class function TPegasusPages.New: IPegasusPages;
begin
  Result := TPegasusPages.Create;
end;

function TPegasusPages.ContentRoot(const APath: string): IPegasusPages;
begin
  FContentRoot := APath;
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
  Mapper.MapPages(FContentRoot, Callback);
  Result := Self;
end;

function TPegasusPages.MapStatic(Callback: TStaticCallback): IPegasusPages;
begin
  Mapper.MapStatic(FContentRoot, Callback);
  Result := Self;
end;

end.
