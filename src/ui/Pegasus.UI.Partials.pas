unit Pegasus.UI.Partials;

interface

uses
  Pegasus.Engine.Nodes;

type
  IPartialRegistry = interface
  ['{A1B2C3D4-5E6F-7890-ABCD-1234567890EF}']
    function GetNodes(const Name: string): INodeListReader;
    procedure Load(const PartialsDir: string);
  end;

  function PartialRegistry: IPartialRegistry;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.SyncObjs,
  System.Generics.Collections,
  Pegasus.Engine.Builder;

type
  TPartialRegistry = class(TInterfacedObject, IPartialRegistry)
  private
    FPaths: TDictionary<string, string>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create;
    destructor Destroy; override;
    function GetNodes(const Name: string): INodeListReader;
    procedure Load(const PartialsDir: string);
  end;

var
  _PartialRegistry: IPartialRegistry;

{ PartialRegistry }

function PartialRegistry: IPartialRegistry;
begin
  Result := _PartialRegistry;
end;

{ TPartialRegistry }

constructor TPartialRegistry.Create;
begin
  inherited Create;
  FPaths := TDictionary<string, string>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TPartialRegistry.Destroy;
begin
  FPaths.Free;
  FLock.Free;
  inherited;
end;

procedure TPartialRegistry.Load(const PartialsDir: string);
begin
  if not TDirectory.Exists(PartialsDir) then
    Exit;

  FLock.BeginWrite;
  try
    for var F in TDirectory.GetFiles(PartialsDir, '_*.html') do
    begin
      var Name := TPath.GetFileNameWithoutExtension(F).ToLower;
      FPaths.AddOrSetValue(Name, F);
    end;
  finally
    FLock.EndWrite;
  end;
end;

function TPartialRegistry.GetNodes(const Name: string): INodeListReader;
begin
  var FilePath: string;

  FLock.BeginRead;
  try
    if not FPaths.TryGetValue(Name.ToLower, FilePath) then
      Exit(nil);
  finally
    FLock.EndRead;
  end;

  Result := Builder().Build(FilePath);
end;

initialization
  _PartialRegistry := TPartialRegistry.Create;

finalization
  _PartialRegistry := nil;

end.
