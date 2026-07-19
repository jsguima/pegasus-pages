unit Pegasus.Engine.Cache;

interface

uses
  Pegasus.Engine.Nodes;

type
  TNodeListFactory = reference to function: INodeListOwner;

  ICacheEntry = interface
  ['{D308B046-5C76-4083-A0F2-E68F2258867A}']
    function GetLastModified: TDateTime;
    function GetNodesReader: INodeListReader;
    property LastModified: TDateTime read GetLastModified;
    property Nodes: INodeListReader read GetNodesReader;
  end;

  ICache = interface
  ['{CA645B03-995F-4426-B768-B8386B73476D}']
    function GetOrAdd(const FilePath: string; Factory: TNodeListFactory): INodeListReader;
    function TryGet(const Key: string; out Entry: ICacheEntry): Boolean;
    procedure Clear;
    procedure Configure(Production: Boolean);
    procedure Invalidate(const Key: string);
    procedure Store(const Key: string; Nodes: INodeListOwner; LastModified: TDateTime);
  end;

  function Cache: ICache;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  System.SyncObjs;

type
  TCacheEntry = class(TInterfacedObject, ICacheEntry)
  private
    FNodes: INodeListOwner;
    FLastModified: TDateTime;
    function GetLastModified: TDateTime;
    function GetNodesReader: INodeListReader;
  public
    constructor Create(Nodes: INodeListOwner; LastModified: TDateTime);
  end;

  TCache = class(TInterfacedObject, ICache)
  private
    FEntries: TDictionary<string, ICacheEntry>;
    FLock: TCriticalSection;
    FProduction: Boolean;
    constructor Create; reintroduce;
    function InsertOrGet(const Key, FilePath: string; NewNodes: INodeListOwner): INodeListReader;
    function IsStale(const FilePath: string; Entry: ICacheEntry): Boolean;
    function TryFetch(const Key: string; out Entry: ICacheEntry; out Production: Boolean): Boolean;
    procedure RetireIfSame(const Key: string; Expected: ICacheEntry);
  public
    destructor Destroy; override;
    function GetOrAdd(const FilePath: string; Factory: TNodeListFactory): INodeListReader;
    function TryGet(const Key: string; out Entry: ICacheEntry): Boolean;
    procedure Clear;
    procedure Configure(Production: Boolean);
    procedure Invalidate(const Key: string);
    procedure Store(const Key: string; Nodes: INodeListOwner; LastModified: TDateTime);
  end;

var
  _CacheInstance: ICache;

{ Public accessor }

function Cache: ICache;
begin
  Result := _CacheInstance;
end;

{ TCacheEntry }

constructor TCacheEntry.Create(Nodes: INodeListOwner; LastModified: TDateTime);
begin
  inherited Create;
  FNodes := Nodes;
  FLastModified := LastModified;
end;

function TCacheEntry.GetNodesReader: INodeListReader;
begin
  Result := FNodes.Reader;
end;

function TCacheEntry.GetLastModified: TDateTime;
begin
  Result := FLastModified;
end;

{ TCache }

constructor TCache.Create;
begin
  inherited Create;
  FEntries := TDictionary<string, ICacheEntry>.Create;
  FLock := TCriticalSection.Create;
  FProduction := False;
end;

destructor TCache.Destroy;
begin
  FEntries.Free;
  FLock.Free;
  inherited;
end;

procedure TCache.Configure(Production: Boolean);
begin
  FLock.Enter;
  try
    FProduction := Production;
  finally
    FLock.Leave;
  end;
end;

function TCache.IsStale(const FilePath: string; Entry: ICacheEntry): Boolean;
begin
  if not TFile.Exists(FilePath) then
    Exit(True);

  Result := TFile.GetLastWriteTime(FilePath) > Entry.LastModified;
end;

procedure TCache.Store(const Key: string; Nodes: INodeListOwner; LastModified: TDateTime);
begin
  FLock.Enter;
  try
    FEntries.AddOrSetValue(Key.ToLower, TCacheEntry.Create(Nodes, LastModified));
  finally
    FLock.Leave;
  end;
end;

function TCache.TryGet(const Key: string; out Entry: ICacheEntry): Boolean;
begin
  FLock.Enter;
  try
    Result := FEntries.TryGetValue(Key.ToLower, Entry);
  finally
    FLock.Leave;
  end;
end;

function TCache.TryFetch(const Key: string; out Entry: ICacheEntry; out Production: Boolean): Boolean;
begin
  FLock.Enter;
  try
    Production := FProduction;
    Result := FEntries.TryGetValue(Key, Entry);
  finally
    FLock.Leave;
  end;
end;

procedure TCache.RetireIfSame(const Key: string; Expected: ICacheEntry);
begin
  FLock.Enter;
  try
    var Current: ICacheEntry;

    if FEntries.TryGetValue(Key, Current) and (Current = Expected) then
      FEntries.Remove(Key);
  finally
    FLock.Leave;
  end;
end;

function TCache.InsertOrGet(const Key, FilePath: string; NewNodes: INodeListOwner): INodeListReader;
begin
  FLock.Enter;
  try
    var Existing: ICacheEntry;

    if FEntries.TryGetValue(Key, Existing) then
      Exit(Existing.Nodes);

    var LastMod: TDateTime;

    if TFile.Exists(FilePath) then
      LastMod := TFile.GetLastWriteTime(FilePath)
    else
      LastMod := Now;

    FEntries.Add(Key, TCacheEntry.Create(NewNodes, LastMod));
    Result := NewNodes.Reader;
  finally
    FLock.Leave;
  end;
end;

function TCache.GetOrAdd(const FilePath: string; Factory: TNodeListFactory): INodeListReader;
begin
  var Key := FilePath.ToLower;
  var CachedEntry: ICacheEntry := nil;
  var Production: Boolean;

  if TryFetch(Key, CachedEntry, Production) then
  begin
    if Production or not IsStale(FilePath, CachedEntry) then
      Exit(CachedEntry.Nodes);

    RetireIfSame(Key, CachedEntry);
  end;

  var NewNodes := Factory();

  Result := InsertOrGet(Key, FilePath, NewNodes);
end;

procedure TCache.Invalidate(const Key: string);
begin
  FLock.Enter;
  try
    FEntries.Remove(Key.ToLower);
  finally
    FLock.Leave;
  end;
end;

procedure TCache.Clear;
begin
  FLock.Enter;
  try
    FEntries.Clear;
  finally
    FLock.Leave;
  end;
end;

initialization
  _CacheInstance := TCache.Create;

finalization
  _CacheInstance := nil;

end.
