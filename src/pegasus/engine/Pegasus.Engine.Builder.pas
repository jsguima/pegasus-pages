unit Pegasus.Engine.Builder;

interface

uses
  Pegasus.Engine.Nodes;

type
  IBuilder = interface
  ['{B35FAF48-7FC8-4842-886F-04BD09F1B7C8}']
    function Build(const FilePath: string): INodeListReader;
    function BuildFromHtml(const Html: string): INodeListReader;
  end;

  TBuilder = class(TInterfacedObject, IBuilder)
  public
    function Build(const FilePath: string): INodeListReader;
    function BuildFromHtml(const Html: string): INodeListReader;
  end;

  function Builder(): IBuilder;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Pegasus.Engine.Cache,
  Pegasus.UI.Components,
  Pegasus.Engine.Lexer,
  Pegasus.Engine.Parser;

{ Builder }
function Builder(): IBuilder;
begin
  Result := TBuilder.Create;
end;

{ TBuilder }

function TBuilder.BuildFromHtml(const Html: string): INodeListReader;
begin
  var Expanded := ComponentExpander.Expand(Html);
  var Tokens := Lexer(Expanded).Tokenize;
  Result := Parser(Tokens).Parse.Reader;
end;

function TBuilder.Build(const FilePath: string): INodeListReader;
begin
  Result := Cache.GetOrAdd(FilePath,
    function: INodeListOwner
    begin
      var Html := TFile.ReadAllText(FilePath, TEncoding.UTF8);
      var Expanded := ComponentExpander.Expand(Html);
      var Tokens := Lexer(Expanded).Tokenize;
      Result := Parser(Tokens).Parse;
    end);
end;

end.
