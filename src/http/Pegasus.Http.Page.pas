unit Pegasus.Http.Page;

interface

uses
  Pegasus.Http.Request,
  Pegasus.Http.PageResult,
  System.SysUtils;

type
  IPage = interface
  ['{BFE6D085-4D22-4162-B44D-2227FD9BAF81}']
    function OnDelete(Request: IRequest): IPageResult;
    function OnGet(Request: IRequest): IPageResult;
    function OnPost(Request: IRequest): IPageResult;
    function OnPut(Request: IRequest): IPageResult;
  end;

  TPage = class(TInterfacedObject, IPage)
  public
    function OnDelete(Request: IRequest): IPageResult; virtual;
    function OnGet(Request: IRequest): IPageResult; virtual;
    function OnPost(Request: IRequest): IPageResult; virtual;
    function OnPut(Request: IRequest): IPageResult; virtual;
  end;

implementation

{ TPage }

function TPage.OnDelete(Request: IRequest): IPageResult;
begin
  raise ENotImplemented.Create('OnDelete not implemented');
end;

function TPage.OnGet(Request: IRequest): IPageResult;
begin
  raise ENotImplemented.Create('OnGet not implemented');
end;

function TPage.OnPost(Request: IRequest): IPageResult;
begin
  raise ENotImplemented.Create('OnPost not implemented');
end;

function TPage.OnPut(Request: IRequest): IPageResult;
begin
  raise ENotImplemented.Create('OnPut not implemented');
end;

end.
