unit Pegasus.Security.SecureRandom;

interface

uses
  System.SysUtils;

type
  TSecureRandom = class
  public
    class function GetBytes(Count: Integer): TBytes;
    class function HexToken(ByteLength: Integer = 32): string;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows
  {$ENDIF}
  {$IFDEF POSIX}
  , Posix.Unistd
  , Posix.SysStat
  , Posix.Fcntl
  {$ENDIF};

{$IFDEF MSWINDOWS}
const
  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;

function BCryptGenRandom(hAlgorithm: THandle; pbBuffer: PByte;
  cbBuffer: ULONG; dwFlags: ULONG): LONG; stdcall;
  external 'bcrypt.dll' name 'BCryptGenRandom';
{$ENDIF}

class function TSecureRandom.GetBytes(Count: Integer): TBytes;
{$IFDEF MSWINDOWS}
var
  Status: LONG;
begin
  if Count <= 0 then
    Exit(nil);

  SetLength(Result, Count);

  Status := BCryptGenRandom(0, @Result[0], Count, BCRYPT_USE_SYSTEM_PREFERRED_RNG);

  if Status <> 0 then
    raise Exception.CreateFmt('BCryptGenRandom failed with status 0x%x', [Status]);
end;
{$ENDIF}
{$IFDEF POSIX}
var
  Fd: Integer;
  BytesRead, Total: Integer;
begin
  if Count <= 0 then
    Exit(nil);

  SetLength(Result, Count);

  Fd := Posix.Fcntl.__open('/dev/urandom', O_RDONLY);

  if Fd < 0 then
    raise Exception.Create('Failed to open /dev/urandom');

  try
    Total := 0;

    while Total < Count do
    begin
      BytesRead := Posix.Unistd.__read(Fd, Result[Total], Count - Total);

      if BytesRead <= 0 then
        raise Exception.Create('Failed to read from /dev/urandom');

      Inc(Total, BytesRead);
    end;
  finally
    Posix.Unistd.__close(Fd);
  end;
end;
{$ENDIF}

class function TSecureRandom.HexToken(ByteLength: Integer): string;
var
  Bytes: TBytes;
  I: Integer;
  SB: TStringBuilder;
begin
  Bytes := GetBytes(ByteLength);

  SB := TStringBuilder.Create(ByteLength * 2);
  try
    for I := 0 to Length(Bytes) - 1 do
      SB.Append(LowerCase(IntToHex(Bytes[I], 2)));

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
