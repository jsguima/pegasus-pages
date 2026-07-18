unit Pegasus.Http.ErrorPages;

interface

type
  IErrorPages = interface
  ['{A3B4C5D6-E7F8-9012-3456-789ABCDEF012}']
    function Get404: string;
    function Get500(const Message: string): string;
    procedure Configure(Production: Boolean);
    procedure Load(const PagesDir: string);
  end;

  function ErrorPages: IErrorPages;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Pegasus.Security.Encoder;

const
  DEFAULT_404 =
    '<!DOCTYPE html><html><head><title>404</title></head><body>' +
    '<h1>404 - Not Found</h1><p>The page you are looking for does not exist.</p>' +
    '</body></html>';

  DEFAULT_500 =
    '<!DOCTYPE html><html><head><title>500</title></head><body>' +
    '<h1>500 - Internal Server Error</h1><p>%s</p>' +
    '</body></html>';

  GENERIC_500_MESSAGE = 'An unexpected error occurred.';

type
  TErrorPages = class(TInterfacedObject, IErrorPages)
  private
    FHtml404: string;
    FHtml500: string;
    FProduction: Boolean;
  public
    function Get404: string;
    function Get500(const Message: string): string;
    procedure Configure(Production: Boolean);
    procedure Load(const PagesDir: string);
  end;

var
  _ErrorPagesInstance: IErrorPages;

{ ErrorPages }

function ErrorPages: IErrorPages;
begin
  Result := _ErrorPagesInstance;
end;

{ TErrorPages }

procedure TErrorPages.Configure(Production: Boolean);
begin
  FProduction := Production;
end;

procedure TErrorPages.Load(const PagesDir: string);
begin
  var ErrorsDir := TPath.Combine(PagesDir, '_errors');

  var File404 := TPath.Combine(ErrorsDir, '404.html');
  var File500 := TPath.Combine(ErrorsDir, '500.html');

  if TFile.Exists(File404) then
    FHtml404 := TFile.ReadAllText(File404, TEncoding.UTF8)
  else
    FHtml404 := '';

  if TFile.Exists(File500) then
    FHtml500 := TFile.ReadAllText(File500, TEncoding.UTF8)
  else
    FHtml500 := '';
end;

function TErrorPages.Get404: string;
begin
  if FHtml404 <> '' then
    Result := FHtml404
  else
    Result := DEFAULT_404;
end;

function TErrorPages.Get500(const Message: string): string;
begin
  var DisplayMessage: string;

  if FProduction then
    DisplayMessage := GENERIC_500_MESSAGE
  else
    DisplayMessage := Message;

  var SafeMessage := TEncoder.Html(DisplayMessage);

  if FHtml500 <> '' then
    Result := FHtml500.Replace('{{message}}', SafeMessage)
  else
    Result := Format(DEFAULT_500, [SafeMessage]);
end;

initialization
  _ErrorPagesInstance := TErrorPages.Create;

finalization
  _ErrorPagesInstance := nil;

end.
