unit Pegasus.Routing.Registry;

interface

uses
  Pegasus.Http.Page,
  System.SysUtils;

type
  EPageWithStateNotAllowed = class(Exception);

  IPageRegistry = interface
  ['{F95B9B45-70E1-4814-AE64-9EAF006FB044}']
    function Find(const Route, Method: string; out Page: IPage): Boolean;
    procedure Add(const Route: string; Page: IPage);
  end;

  function PageRegistry(): IPageRegistry;

implementation

uses
  System.Generics.Collections,
  System.SyncObjs,
  System.Rtti;

type
  TPageRegistry = class(TInterfacedObject, IPageRegistry)
  private
    FPages: TDictionary<string, IPage>;
    FLock: TCriticalSection;
    constructor Create; reintroduce;
    procedure ValidatePageIsStateless(Page: IPage);
  public
    destructor Destroy; override;
    function Find(const Route, Method: string; out Page: IPage): Boolean;
    procedure Add(const Route: string; Page: IPage);
  end;

var
  _PageRegistryInstance: IPageRegistry;

{ Public accessor }

function PageRegistry(): IPageRegistry;
begin
  Result := _PageRegistryInstance;
end;

{ TPageRegistry }

constructor TPageRegistry.Create;
begin
  inherited;
  FPages := TDictionary<string, IPage>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TPageRegistry.Destroy;
begin
  FLock.Free;
  FPages.Free;
  inherited;
end;

procedure TPageRegistry.Add(const Route: string; Page: IPage);
begin
  ValidatePageIsStateless(Page);

  var Obj := Page as TObject;
  var RttiContext := TRttiContext.Create;

  try
    var RttiType := RttiContext.GetType(Obj.ClassType);
    var BaseType := RttiContext.GetType(TPage);

    var MethodNames := TArray<string>.Create('OnGet', 'OnPost', 'OnPut', 'OnDelete');

    for var I := 0 to Length(MethodNames) - 1 do
    begin
      var Method := RttiType.GetMethod(MethodNames[I]);
      var BaseMethod := BaseType.GetMethod(MethodNames[I]);

      if Assigned(Method) and Assigned(BaseMethod) then
      begin
        if Method.CodeAddress <> BaseMethod.CodeAddress then
        begin
          var Key := Route + '|' + UpperCase(MethodNames[I].Substring(2));

          FLock.Enter;
          try
            FPages.AddOrSetValue(Key, Page);
          finally
            FLock.Leave;
          end;
        end;
      end;
    end;
  finally
    RttiContext.Free;
  end;
end;

procedure TPageRegistry.ValidatePageIsStateless(Page: IPage);
begin
  var Obj := Page as TObject;
  var RttiContext := TRttiContext.Create;

  try
    var RttiType := RttiContext.GetType(Obj.ClassType);
    var BasePageType := RttiContext.GetType(TPage);
    var InterfacedObjType := RttiContext.GetType(TInterfacedObject);

    var AllFields := RttiType.GetFields;

    for var Field in AllFields do
    begin
      if Field.Parent = BasePageType then
        Continue;

      if Field.Parent = InterfacedObjType then
        Continue;

      var ClassName := Obj.ClassName;
      var FieldName := Field.Name;

      raise EPageWithStateNotAllowed.CreateFmt(
        'PageModel "%s" contains field "%s". PageModels must be stateless. ' +
        'Declare variables as local within methods, not as class fields.',
        [ClassName, FieldName]);
    end;
  finally
    RttiContext.Free;
  end;
end;

function TPageRegistry.Find(const Route, Method: string; out Page: IPage): Boolean;
begin
  FLock.Enter;
  try
    var Key := Route + '|' + UpperCase(Method);
    Result := FPages.TryGetValue(Key, Page);
  finally
    FLock.Leave;
  end;
end;

initialization
  _PageRegistryInstance := TPageRegistry.Create;

finalization
  _PageRegistryInstance := nil;

end.
