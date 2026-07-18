unit Pegasus.Data.RttiCache;

interface

uses
  System.Rtti;

type
  IRttiCache = interface
  ['{C4D5E6F7-A8B9-0123-4567-890ABCDEF012}']
    function GetMember(AClass: TClass; const MemberName: string): TRttiMember;
  end;

  function RttiCache: IRttiCache;

implementation

uses
  System.Generics.Collections,
  System.SyncObjs;

type
  TRttiCache = class(TInterfacedObject, IRttiCache)
  private
    FCtx: TRttiContext;
    FEntries: TDictionary<string, TRttiMember>;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function GetMember(AClass: TClass; const MemberName: string): TRttiMember;
  end;

var
  _RttiCacheInstance: IRttiCache;

{ RttiCache }

function RttiCache: IRttiCache;
begin
  Result := _RttiCacheInstance;
end;

{ TRttiCache }

constructor TRttiCache.Create;
begin
  inherited Create;
  FCtx := TRttiContext.Create;
  FEntries := TDictionary<string, TRttiMember>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TRttiCache.Destroy;
begin
  FEntries.Free;
  FLock.Free;
  FCtx.Free;
  inherited;
end;

function TRttiCache.GetMember(AClass: TClass; const MemberName: string): TRttiMember;
begin
  var Key := AClass.ClassName + '.' + MemberName;

  FLock.Enter;
  try
    if FEntries.TryGetValue(Key, Result) then
      Exit;

    var RttiType := FCtx.GetType(AClass);

    Result := RttiType.GetProperty(MemberName);

    if not Assigned(Result) then
      Result := RttiType.GetField(MemberName);

    FEntries.Add(Key, Result);
  finally
    FLock.Leave;
  end;
end;

initialization
  _RttiCacheInstance := TRttiCache.Create;

finalization
  _RttiCacheInstance := nil;

end.
