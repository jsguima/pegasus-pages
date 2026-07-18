unit Pegasus.Http.PageResult;

interface

uses
  System.Classes,
  System.Generics.Collections,
  Pegasus.Data.Page;

type
  TPageResultKind = (prkRender, prkRedirect, prkJson, prkStatus);

  IPageResultBuilder = interface;

  IPageResult = interface
  ['{B2C3D4E5-F6A7-8901-BCDE-F23456789012}']
    function Error(const Message: string; Status: Integer): IPageResult;
    function Json(const Body: string; Status: Integer = 200): IPageResult;
    function Page(): IPageResultBuilder;
    function Redirect(const Url: string; Status: Integer = 302): IPageResult;
  end;

  IPageResultBuilder = interface
  ['{478A4E9E-F18E-41FF-8260-9F059DD8EF47}']
    function Add(const Key: string; const Value: string): IPageResultBuilder; overload;
    function Add(const Key: string; Value: Integer): IPageResultBuilder; overload;
    function Add(const Key: string; Value: Double): IPageResultBuilder; overload;
    function Add(const Key: string; Value: Boolean): IPageResultBuilder; overload;
    function Add(const Key: string; Value: TObject): IPageResultBuilder; overload;
    function Add(const Key: string; Value: TObjectList<TObject>): IPageResultBuilder; overload;
    function Render: IPageResult;
    function SetStream(AStream: TStream; const ContentType: string; const FileName: string = ''): IPageResult;
  end;

  TPageResult = class(TInterfacedObject, IPageResult)
  private
    FKind: TPageResultKind;
    FPageData: IPageData;
    FBuilder: IPageResultBuilder;
    FRedirectUrl: string;
    FStatusCode: Integer;
    FBody: string;
    FMessage: string;
    constructor Create; reintroduce;
    function GetPageDataReader: IPageDataReader;
  public
    function Error(const Message: string; Status: Integer): IPageResult;
    function Json(const Body: string; Status: Integer = 200): IPageResult;
    function Page(): IPageResultBuilder;
    function Redirect(const Url: string; Status: Integer = 302): IPageResult;

    property Kind: TPageResultKind read FKind;
    property Body: string read FBody;
    property RedirectUrl: string read FRedirectUrl;
    property StatusCode: Integer read FStatusCode;
    property Data: IPageDataReader read GetPageDataReader;
  end;

  TPageResultBuilder = class(TInterfacedObject, IPageResultBuilder)
  private
    FData: IPageDataWriter;
    [weak] FPageResult: IPageResult;
    constructor Create(Data: IPageDataWriter; const PageResult: IPageResult); reintroduce;
  public
    function Add(const Key: string; const Value: string): IPageResultBuilder; overload;
    function Add(const Key: string; Value: Integer): IPageResultBuilder; overload;
    function Add(const Key: string; Value: Double): IPageResultBuilder; overload;
    function Add(const Key: string; Value: Boolean): IPageResultBuilder; overload;
    function Add(const Key: string; Value: TObject): IPageResultBuilder; overload;
    function Add(const Key: string; Value: TObjectList<TObject>): IPageResultBuilder; overload;
    function Render: IPageResult;
    function SetStream(AStream: TStream; const ContentType: string; const FileName: string = ''): IPageResult;
  end;

  function PageResult: IPageResult;
  function PageResultBuilder(Data: IPageDataWriter; const PageResult: IPageResult): IPageResultBuilder;

implementation

{ PageResult }

function PageResult: IPageResult;
begin
  Result := TPageResult.Create();
end;

{ PageResultBuilder }

function PageResultBuilder(Data: IPageDataWriter; const PageResult: IPageResult): IPageResultBuilder;
begin
  Result := TPageResultBuilder.Create(Data, PageResult);
end;

{ TPageResult }

constructor TPageResult.Create;
begin
  inherited Create;
  FPageData := PageData();
  FBuilder := PageResultBuilder(FPageData.Writer, Self);
end;

function TPageResult.Page: IPageResultBuilder;
begin
  FKind := prkRender;
  FStatusCode := 200;
  Result := FBuilder;
end;

function TPageResult.Redirect(const Url: string; Status: Integer): IPageResult;
begin
  FKind := prkRedirect;
  FRedirectUrl := Url;
  FStatusCode := Status;
  Result := Self;
end;

function TPageResult.Json(const Body: string; Status: Integer): IPageResult;
begin
  FKind := prkJson;
  FBody := Body;
  FStatusCode := Status;
  Result := Self;
end;

function TPageResult.Error(const Message: string; Status: Integer): IPageResult;
begin
  FKind := prkStatus;
  FMessage := Message;
  FStatusCode := Status;
  Result := Self;
end;

function TPageResult.GetPageDataReader: IPageDataReader;
begin
  Result := FPageData.Reader();
end;


{ TPageResultBuilder }

constructor TPageResultBuilder.Create(Data: IPageDataWriter; const PageResult: IPageResult);
begin
  inherited Create;
  FData := Data;
  FPageResult := PageResult;
end;

function TPageResultBuilder.Add(const Key: string; Value: Double): IPageResultBuilder;
begin
  FData.Add(Key, Value);
  Result := Self;
end;

function TPageResultBuilder.Add(const Key: string; Value: Integer): IPageResultBuilder;
begin
  FData.Add(Key, Value);
  Result := Self;
end;

function TPageResultBuilder.Add(const Key, Value: string): IPageResultBuilder;
begin
  FData.Add(Key, Value);
  Result := Self;
end;

function TPageResultBuilder.Add(const Key: string; Value: TObjectList<TObject>): IPageResultBuilder;
begin
  FData.Add(Key, Value);
  Result := Self;
end;

function TPageResultBuilder.Add(const Key: string; Value: TObject): IPageResultBuilder;
begin
  FData.Add(Key, Value);
  Result := Self;
end;

function TPageResultBuilder.Add(const Key: string; Value: Boolean): IPageResultBuilder;
begin
  FData.Add(Key, Value);
  Result := Self;
end;

function TPageResultBuilder.Render: IPageResult;
begin
  Result := FPageResult;
end;

function TPageResultBuilder.SetStream(AStream: TStream; const ContentType, FileName: string): IPageResult;
begin
  FData.SetStream(AStream, ContentType, FileName);
  Result := FPageResult;
end;

end.
