unit Pegasus.Data.Page;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Classes,
  System.Generics.Collections;

type
  IPageDataReader = interface
  ['{B8A3CE92-58ED-4465-A2DC-5DCE4B8DE326}']
    function Get(const Key: string): TValue;
    function GetSlot: string;
    function GetStream: TStream;
    function GetStreamContentType: string;
    function GetStreamFileName: string;
    function Has(const Key: string): Boolean;
    function HasStream: Boolean;
    function IsSlotTrusted: Boolean;
  end;

  IPageDataWriter = interface
  ['{544F18F8-5565-4200-9553-655741738D88}']
    procedure Add(const Key: string; const Value: string); overload;
    procedure Add(const Key: string; Value: Integer); overload;
    procedure Add(const Key: string; Value: Double); overload;
    procedure Add(const Key: string; Value: Boolean); overload;
    procedure Add(const Key: string; Value: TObject); overload;
    procedure Add(const Key: string; Value: TObjectList<TObject>); overload;
    procedure SetSlot(const Value: string; Trusted: Boolean = False);
    procedure SetStream(AStream: TStream; const ContentType: string; const FileName: string = '');
  end;

  IPageData = interface
  ['{4419D31F-1749-47E0-B12B-D5A7B0167117}']
    function Reader: IPageDataReader;
    function Writer: IPageDataWriter;
  end;

  TPageData = class(TInterfacedObject, IPageData, IPageDataReader, IPageDataWriter)
  private
    FSlot: string;
    FSlotTrusted: Boolean;
    FStream: TStream;
    FStreamContentType: string;
    FStreamFileName: string;
    FValues: TDictionary<string, TValue>;
    constructor Create;
    function NormalizeKey(const Key: string): string;
    function WrapList(const Items: TObjectList<TObject>): TValue;
    procedure FreeExistingObject(const Key: string);
  public
    destructor Destroy; override;
    function Get(const Key: string): TValue;
    function GetSlot: string;
    function GetStream: TStream;
    function GetStreamContentType: string;
    function GetStreamFileName: string;
    function Has(const Key: string): Boolean;
    function HasStream: Boolean;
    function IsSlotTrusted: Boolean;
    function Reader: IPageDataReader;
    function Writer: IPageDataWriter;
    procedure Add(const Key: string; const Value: string); overload;
    procedure Add(const Key: string; Value: Integer); overload;
    procedure Add(const Key: string; Value: Double); overload;
    procedure Add(const Key: string; Value: Boolean); overload;
    procedure Add(const Key: string; Value: TObject); overload;
    procedure Add(const Key: string; Value: TObjectList<TObject>); overload;
    procedure SetSlot(const Value: string; Trusted: Boolean = False);
    procedure SetStream(AStream: TStream; const ContentType: string; const FileName: string = '');
  end;

  function PageData(): IPageData;

implementation

{ PageData }

function PageData(): IPageData;
begin
  Result := TPageData.Create;
end;

{ TPageData }

constructor TPageData.Create;
begin
  inherited Create;
  FValues := TDictionary<string, TValue>.Create;
end;

destructor TPageData.Destroy;
begin
  for var Pair in FValues do
  begin
    if (not Pair.Value.IsEmpty) and Pair.Value.IsObject and (Pair.Value.AsObject <> nil) then
      Pair.Value.AsObject.Free;
  end;

  FValues.Free;

  if Assigned(FStream) then
    FStream.Free;

  inherited;
end;

function TPageData.NormalizeKey(const Key: string): string;
begin
  Result := Key.ToLower;
end;

function TPageData.Reader: IPageDataReader;
begin
  Result := Self;
end;

function TPageData.WrapList(const Items: TObjectList<TObject>): TValue;
begin
  Result := TValue.From<TObject>(Items);
end;

procedure TPageData.FreeExistingObject(const Key: string);
begin
  var Existing: TValue;

  if FValues.TryGetValue(Key, Existing) then
    if (not Existing.IsEmpty) and Existing.IsObject and (Existing.AsObject <> nil) then
      Existing.AsObject.Free;
end;

function TPageData.Writer: IPageDataWriter;
begin
  Result := Self;
end;

function TPageData.Get(const Key: string): TValue;
begin
  if not FValues.TryGetValue(NormalizeKey(Key), Result) then
    Result := TValue.Empty;
end;

function TPageData.Has(const Key: string): Boolean;
begin
  Result := FValues.ContainsKey(NormalizeKey(Key));
end;

procedure TPageData.Add(const Key: string; const Value: string);
begin
  FValues.AddOrSetValue(NormalizeKey(Key), TValue.From<string>(Value));
end;

procedure TPageData.Add(const Key: string; Value: Integer);
begin
  FValues.AddOrSetValue(NormalizeKey(Key), TValue.From<Integer>(Value));
end;

procedure TPageData.Add(const Key: string; Value: Double);
begin
  FValues.AddOrSetValue(NormalizeKey(Key), TValue.From<Double>(Value));
end;

procedure TPageData.Add(const Key: string; Value: Boolean);
begin
  FValues.AddOrSetValue(NormalizeKey(Key), TValue.From<Boolean>(Value));
end;

procedure TPageData.Add(const Key: string; Value: TObject);
begin
  var NKey := NormalizeKey(Key);
  FreeExistingObject(NKey);
  FValues.AddOrSetValue(NKey, TValue.From<TObject>(Value));
end;

procedure TPageData.Add(const Key: string; Value: TObjectList<TObject>);
begin
  var NKey := NormalizeKey(Key);
  FreeExistingObject(NKey);
  FValues.AddOrSetValue(NKey, WrapList(Value));
end;

procedure TPageData.SetStream(AStream: TStream; const ContentType: string; const FileName: string);
begin
  if Assigned(FStream) and (FStream <> AStream) then
    FStream.Free;

  FStream := AStream;
  FStreamContentType := ContentType;
  FStreamFileName := FileName;
end;

function TPageData.HasStream: Boolean;
begin
  Result := Assigned(FStream);
end;

function TPageData.GetStream: TStream;
begin
  Result := FStream;
  FStream := nil;
end;

function TPageData.GetStreamContentType: string;
begin
  Result := FStreamContentType;
end;

function TPageData.GetStreamFileName: string;
begin
  Result := FStreamFileName;
end;

procedure TPageData.SetSlot(const Value: string; Trusted: Boolean);
begin
  FSlot := Value;
  FSlotTrusted := Trusted;
end;

function TPageData.IsSlotTrusted: Boolean;
begin
  Result := FSlotTrusted;
end;

function TPageData.GetSlot: string;
begin
  Result := FSlot;
end;

end.
