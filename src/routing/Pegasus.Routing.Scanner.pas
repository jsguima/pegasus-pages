unit Pegasus.Routing.Scanner;

interface

uses
  System.IOUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SysUtils;

type
  TScannedPage = record
    Route: string;
    FilePath: string;
    Layouts: TArray<string>;
  end;

  IScanner = interface
  ['{A57CBDC2-EA2F-4B06-A764-8329FAB9F9C4}']
    function Scan(const PagesDir: string): TArray<TScannedPage>;
  end;

  TScanner = class(TInterfacedObject, IScanner)
  private
    function BuildRoutes(const PagesDir, FilePath: string): TArray<string>;
    function CollectLayouts(const PagesDir, PageFile: string): TArray<string>;
    function CountParams(const Route: string): Integer;
    function IsGroup(const Part: string): Boolean;
    function IsOptionalParam(const Part: string): Boolean;
    function NormalizePart(const Part: string): string;
    procedure SortByParamCount(var Pages: TArray<TScannedPage>);
  public
    class function New(): IScanner;
    function Scan(const PagesDir: string): TArray<TScannedPage>;
  end;

implementation

{ TScanner }

class function TScanner.New: IScanner;
begin
  Result := TScanner.Create;
end;

function TScanner.Scan(const PagesDir: string): TArray<TScannedPage>;
begin
  Result := [];

  if not TDirectory.Exists(PagesDir) then
    Exit;

  var SafeRoot := TPath.GetFullPath(PagesDir).TrimRight(['\', '/']) + '\';
  var RouteIndex := TDictionary<string, Boolean>.Create;

  try
    for var HtmlFile in TDirectory.GetFiles(PagesDir, 'page.html', TSearchOption.soAllDirectories) do
    begin
      var CanonicalPath := TPath.GetFullPath(HtmlFile);

      if not CanonicalPath.StartsWith(SafeRoot, True) then
        Continue;

      var Routes := BuildRoutes(PagesDir, HtmlFile);
      var Layouts := CollectLayouts(PagesDir, HtmlFile);

      for var Route in Routes do
      begin
        if not RouteIndex.ContainsKey(Route) then
        begin
          RouteIndex.Add(Route, True);

          var Page: TScannedPage;
          Page.Route := Route;
          Page.FilePath := HtmlFile;
          Page.Layouts := Layouts;
          Result := Result + [Page];
        end;
      end;
    end;
  finally
    RouteIndex.Free;
  end;

  SortByParamCount(Result);
end;

function TScanner.BuildRoutes(const PagesDir, FilePath: string): TArray<string>;
begin
  var RelDir := TPath
    .GetDirectoryName(FilePath)
    .Substring(PagesDir.Length)
    .TrimLeft(['\', '/'])
    .Replace('\', '/');

  var Parts: TArray<string> := [];
  var OptionalIndex := -1;

  if RelDir <> '' then
  begin
    for var Part in RelDir.Split(['/']) do
    begin
      if Part.StartsWith('_') then
      begin
        Result := [];
        Exit;
      end;

      if IsGroup(Part) then
        Continue;

      if IsOptionalParam(Part) then
        OptionalIndex := Length(Parts);

      Parts := Parts + [NormalizePart(Part)];
    end;
  end;

  if Length(Parts) = 0 then
  begin
    Result := ['/'];
    Exit;
  end;

  var FullRoute := '/' + string.Join('/', Parts);

  if OptionalIndex < 0 then
  begin
    Result := [FullRoute];
    Exit;
  end;

  var WithoutOptional: TArray<string> := [];

  for var I := 0 to Length(Parts) - 1 do
    if I <> OptionalIndex then
      WithoutOptional := WithoutOptional + [Parts[I]];

  var ShortRoute: string;

  if Length(WithoutOptional) = 0 then
    ShortRoute := '/'
  else
    ShortRoute := '/' + string.Join('/', WithoutOptional);

  Result := [ShortRoute, FullRoute];
end;

function TScanner.IsGroup(const Part: string): Boolean;
begin
  Result := Part.StartsWith('(') and Part.EndsWith(')');
end;

function TScanner.IsOptionalParam(const Part: string): Boolean;
begin
  Result := Part.StartsWith('[[') and Part.EndsWith(']]');
end;

function TScanner.NormalizePart(const Part: string): string;
begin
  if Part.StartsWith('[[') and Part.EndsWith(']]') then
    Result := ':' + Part.Substring(2, Part.Length - 4)
  else
    if Part.StartsWith('[') and Part.EndsWith(']') then
      Result := ':' + Part.Substring(1, Part.Length - 2)
    else
      Result := Part;
end;

function TScanner.CollectLayouts(const PagesDir, PageFile: string): TArray<string>;
begin
  Result := [];

  var Dir := TPath.GetDirectoryName(PageFile);
  var Root := ExcludeTrailingPathDelimiter(PagesDir);

  while not SameText(ExcludeTrailingPathDelimiter(Dir), Root) do
  begin
    var LayoutFile := TPath.Combine(Dir, '_layout.html');

    if TFile.Exists(LayoutFile) then
      Result := Result + [LayoutFile];

    Dir := TPath.GetDirectoryName(ExcludeTrailingPathDelimiter(Dir));
  end;
end;

procedure TScanner.SortByParamCount(var Pages: TArray<TScannedPage>);
begin
  if Length(Pages) < 2 then
    Exit;

  TArray.Sort<TScannedPage>(Pages,
    TComparer<TScannedPage>.Construct(
      function(const Left, Right: TScannedPage): Integer
      begin
        Result := CountParams(Left.Route) - CountParams(Right.Route);
      end
    )
  );
end;

function TScanner.CountParams(const Route: string): Integer;
begin
  Result := 0;

  for var Part in Route.Split(['/']) do
    if Part.StartsWith(':') then
      Inc(Result);
end;

end.
