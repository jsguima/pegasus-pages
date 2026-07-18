unit Pegasus.UI.Components;

interface

type
  IComponentRegistry = interface
  ['{E7A1B2C3-D4E5-F6A7-8901-234567890ABC}']
    function GetPrefixes: TArray<string>;
    function HasPrefixes: Boolean;
    function TryGet(const Name: string; out Template: string): Boolean;
    function TryGetScript(const Name: string; out Script: string): Boolean;
    function TryGetStyle(const Name: string; out Style: string): Boolean;
    procedure Load(const ComponentsDir: string);
    procedure SetAllowedPrefixes(const Prefixes: TArray<string>);
  end;

  IComponentExpander = interface
  ['{F8B2C3D4-E5F6-A7B8-9012-345678901DEF}']
    function Expand(const Html: string): string;
  end;

  function ComponentRegistry: IComponentRegistry;
  function ComponentExpander: IComponentExpander;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.SyncObjs,
  System.Generics.Collections,
  Pegasus.Security.Encoder;

const
  MAX_EXPANSION_DEPTH = 20;
  SCOPE_ATTR = 'data-pg';
  DEFAULT_PREFIX = 'pg';

type
  TComponentRegistry = class(TInterfacedObject, IComponentRegistry)
  private
    FComponents: TDictionary<string, string>;
    FScripts: TDictionary<string, string>;
    FStyles: TDictionary<string, string>;
    FAllowedPrefixes: TList<string>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
    function IsAllowedPrefix(const Prefix: string): Boolean;
    procedure ExtractScript(var Content: string; const Name: string);
    procedure ExtractStyle(var Content: string; const Name: string);
  public
    constructor Create;
    destructor Destroy; override;
    function GetPrefixes: TArray<string>;
    function HasPrefixes: Boolean;
    function TryGet(const Name: string; out Template: string): Boolean;
    function TryGetScript(const Name: string; out Script: string): Boolean;
    function TryGetStyle(const Name: string; out Style: string): Boolean;
    procedure Load(const ComponentsDir: string);
    procedure SetAllowedPrefixes(const Prefixes: TArray<string>);
  end;

  TComponentExpander = class(TInterfacedObject, IComponentExpander)
  private
    FRegistry: IComponentRegistry;
    FNextId: Integer;
    function ApplyAttrs(const Template: string; const Attrs: TDictionary<string, string>): string;
    function ApplyScopeAttr(const Html, Name: string): string;
    function ExpandComponent(const Name, AttrsStr, Slot: string; UsedScripts, UsedStyles: TDictionary<string, string>): string;
    function FindTag(const Html: string; StartPos: Integer; const Prefixes: TArray<string>; out Prefix: string; out TagStart: Integer): Boolean;
    function GenerateId(const Name: string): string;
    function ParseAttrs(const AttrsStr: string): TDictionary<string, string>;
    function ParseTag(const Html: string; const Prefix: string; TagStart: Integer; out FullName, AttrsStr, Slot: string; out TagEnd: Integer): Boolean;
    function ReadKey(const S: string; var I: Integer): string;
    function ReadQuotedValue(const S: string; var I: Integer): string;
    function ScopeStyle(const Css, Name: string): string;
    procedure SkipSpaces(const S: string; var I: Integer);
  public
    constructor Create(Registry: IComponentRegistry);
    function Expand(const Html: string): string;
  end;

var
  _Registry: IComponentRegistry;
  _Expander: IComponentExpander;

{ Public accessors }

function ComponentRegistry: IComponentRegistry;
begin
  Result := _Registry;
end;

function ComponentExpander: IComponentExpander;
begin
  Result := _Expander;
end;

{ TComponentRegistry }

constructor TComponentRegistry.Create;
begin
  inherited Create;
  FComponents := TDictionary<string, string>.Create;
  FScripts := TDictionary<string, string>.Create;
  FStyles := TDictionary<string, string>.Create;
  FAllowedPrefixes := TList<string>.Create;
  FAllowedPrefixes.Add(DEFAULT_PREFIX);
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TComponentRegistry.Destroy;
begin
  FComponents.Free;
  FScripts.Free;
  FStyles.Free;
  FAllowedPrefixes.Free;
  FLock.Free;
  inherited;
end;

procedure TComponentRegistry.SetAllowedPrefixes(const Prefixes: TArray<string>);
begin
  FLock.BeginWrite;
  try
    FAllowedPrefixes.Clear;

    for var P in Prefixes do
      if not FAllowedPrefixes.Contains(P.ToLower) then
        FAllowedPrefixes.Add(P.ToLower);
  finally
    FLock.EndWrite;
  end;
end;

function TComponentRegistry.IsAllowedPrefix(const Prefix: string): Boolean;
begin
  Result := FAllowedPrefixes.Contains(Prefix.ToLower);
end;

procedure TComponentRegistry.ExtractScript(var Content: string; const Name: string);
begin
  var StartTag := '<script>';
  var EndTag := '</script>';
  var ScriptStart := Content.IndexOf(StartTag);

  if ScriptStart < 0 then
    Exit;

  var ScriptEnd := Content.IndexOf(EndTag, ScriptStart);

  if ScriptEnd < 0 then
    Exit;

  var Script := Content.Substring(
    ScriptStart + Length(StartTag),
    ScriptEnd - ScriptStart - Length(StartTag)
  ).Trim;

  FScripts.AddOrSetValue(Name, Script);
  Content := Content.Substring(0, ScriptStart) + Content.Substring(ScriptEnd + Length(EndTag));
end;

procedure TComponentRegistry.ExtractStyle(var Content: string; const Name: string);
begin
  var EndTag := '</style>';
  var StyleStart := Content.IndexOf('<style');

  if StyleStart < 0 then
    Exit;

  var TagClose := Content.IndexOf('>', StyleStart);

  if TagClose < 0 then
    Exit;

  var StyleEnd := Content.IndexOf(EndTag, TagClose);

  if StyleEnd < 0 then
    Exit;

  var Css := Content.Substring(
    TagClose + 1,
    StyleEnd - TagClose - 1
  ).Trim;

  FStyles.AddOrSetValue(Name, Css);
  Content := Content.Substring(0, StyleStart) + Content.Substring(StyleEnd + Length(EndTag));
end;

procedure TComponentRegistry.Load(const ComponentsDir: string);
begin
  if not TDirectory.Exists(ComponentsDir) then
    Exit;

  FLock.BeginWrite;
  try
    for var F in TDirectory.GetFiles(ComponentsDir, '*.html') do
    begin
      var Name := TPath.GetFileNameWithoutExtension(F).ToLower;
      var DashPos := Name.IndexOf('-');

      if DashPos < 0 then
        Continue;

      var Prefix := Name.Substring(0, DashPos);

      if not IsAllowedPrefix(Prefix) then
        Continue;

      var Content := TFile.ReadAllText(F, TEncoding.UTF8);

      ExtractScript(Content, Name);
      ExtractStyle(Content, Name);
      FComponents.AddOrSetValue(Name, Content.Trim);
    end;
  finally
    FLock.EndWrite;
  end;
end;

function TComponentRegistry.TryGet(const Name: string; out Template: string): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FComponents.TryGetValue(Name.ToLower, Template);
  finally
    FLock.EndRead;
  end;
end;

function TComponentRegistry.TryGetScript(const Name: string; out Script: string): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FScripts.TryGetValue(Name.ToLower, Script);
  finally
    FLock.EndRead;
  end;
end;

function TComponentRegistry.TryGetStyle(const Name: string; out Style: string): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FStyles.TryGetValue(Name.ToLower, Style);
  finally
    FLock.EndRead;
  end;
end;

function TComponentRegistry.GetPrefixes: TArray<string>;
begin
  FLock.BeginRead;
  try
    Result := FAllowedPrefixes.ToArray;
  finally
    FLock.EndRead;
  end;
end;

function TComponentRegistry.HasPrefixes: Boolean;
begin
  FLock.BeginRead;
  try
    Result := FAllowedPrefixes.Count > 0;
  finally
    FLock.EndRead;
  end;
end;

{ TComponentExpander }

constructor TComponentExpander.Create(Registry: IComponentRegistry);
begin
  inherited Create;
  FRegistry := Registry;
  FNextId := 0;
end;

function TComponentExpander.GenerateId(const Name: string): string;
begin
  Result := Name + '-' + TInterlocked.Increment(FNextId).ToString;
end;

procedure TComponentExpander.SkipSpaces(const S: string; var I: Integer);
begin
  while (I < S.Length) and (S.Chars[I] = ' ') do
    Inc(I);
end;

function TComponentExpander.ReadKey(const S: string; var I: Integer): string;
begin
  var Start := I;

  while (I < S.Length) and (S.Chars[I] <> '=') and (S.Chars[I] <> ' ') do
    Inc(I);

  Result := S.Substring(Start, I - Start);
end;

function TComponentExpander.ReadQuotedValue(const S: string; var I: Integer): string;
begin
  Result := '';

  if (I >= S.Length) or (S.Chars[I] <> '"') then
    Exit;

  Inc(I);
  var Start := I;

  while (I < S.Length) and (S.Chars[I] <> '"') do
    Inc(I);

  Result := S.Substring(Start, I - Start);

  if I < S.Length then
    Inc(I);
end;

function TComponentExpander.ParseAttrs(const AttrsStr: string): TDictionary<string, string>;
begin
  Result := TDictionary<string, string>.Create;
  var I := 0;

  while I < AttrsStr.Length do
  begin
    SkipSpaces(AttrsStr, I);

    if I >= AttrsStr.Length then
      Break;

    var Key := ReadKey(AttrsStr, I);

    if (I < AttrsStr.Length) and (AttrsStr.Chars[I] = '=') then
    begin
      Inc(I);
      Result.AddOrSetValue(Key.ToLower, ReadQuotedValue(AttrsStr, I));
    end
    else
      Result.AddOrSetValue(Key.ToLower, '');
  end;
end;

function TComponentExpander.ApplyAttrs(const Template: string;
  const Attrs: TDictionary<string, string>): string;
begin
  Result := Template;

  for var Pair in Attrs do
  begin
    if Pair.Value.Contains('{{') then
      Result := Result.Replace('{{' + Pair.Key + '}}', Pair.Value)
    else
      Result := Result.Replace('{{' + Pair.Key + '}}', TEncoder.Attr(Pair.Value));
  end;
end;

function TComponentExpander.ApplyScopeAttr(const Html, Name: string): string;
begin
  Result := Html;

  var TagOpen := Result.IndexOf('<');

  if TagOpen < 0 then
    Exit;

  var TagClose := Result.IndexOf('>', TagOpen);

  if TagClose < 0 then
    Exit;

  if Result.Chars[TagClose - 1] = '/' then
    Result := Result.Substring(0, TagClose - 1)
      + ' ' + SCOPE_ATTR + '="' + Name + '" />'
      + Result.Substring(TagClose + 1)
  else
    Result := Result.Substring(0, TagClose)
      + ' ' + SCOPE_ATTR + '="' + Name + '">'
      + Result.Substring(TagClose + 1);
end;

function TComponentExpander.ScopeStyle(const Css, Name: string): string;
begin
  Result := '';
  var Scope := '[' + SCOPE_ATTR + '="' + Name + '"]';
  var Lines := Css.Split([#10, #13#10]);

  for var Line in Lines do
  begin
    var Trimmed := Line.Trim;

    if Trimmed = '' then
      Continue;

    var BracePos := Trimmed.IndexOf('{');

    if BracePos > 0 then
    begin
      var Selector := Trimmed.Substring(0, BracePos).Trim;
      var Rest := Trimmed.Substring(BracePos);

      Result := Result + Scope + ' ' + Selector + ' ' + Rest + sLineBreak;
    end
    else
      Result := Result + Trimmed + sLineBreak;
  end;
end;

function TComponentExpander.FindTag(const Html: string; StartPos: Integer;
  const Prefixes: TArray<string>; out Prefix: string; out TagStart: Integer): Boolean;
begin
  Result := False;
  TagStart := MaxInt;

  for var P in Prefixes do
  begin
    var Tag := '<' + P + '-';
    var Pos := Html.IndexOf(Tag, StartPos);

    if (Pos >= 0) and (Pos < TagStart) then
    begin
      TagStart := Pos;
      Prefix := P;
      Result := True;
    end;
  end;
end;

function TComponentExpander.ParseTag(const Html: string; const Prefix: string;
  TagStart: Integer; out FullName, AttrsStr, Slot: string; out TagEnd: Integer): Boolean;
begin
  Result := False;

  var OpenTag := '<' + Prefix + '-';
  var PrefixLen := Length(OpenTag);
  var CloseAngle := Html.IndexOf('>', TagStart);

  if CloseAngle < 0 then
    Exit;

  var SelfClosing := Html.Chars[CloseAngle - 1] = '/';
  var TagContent := Html.Substring(TagStart + PrefixLen, CloseAngle - TagStart - PrefixLen);

  if SelfClosing then
    TagContent := TagContent.Substring(0, TagContent.Length - 1).Trim;

  var SpacePos := TagContent.IndexOf(' ');

  if SpacePos > 0 then
  begin
    FullName := Prefix + '-' + TagContent.Substring(0, SpacePos);
    AttrsStr := TagContent.Substring(SpacePos + 1).Trim;
  end
  else
  begin
    FullName := Prefix + '-' + TagContent.Trim;
    AttrsStr := '';
  end;

  Slot := '';
  TagEnd := CloseAngle + 1;

  if not SelfClosing then
  begin
    var CompName := FullName.Substring(Length(Prefix) + 1);
    var EndTag := '</' + Prefix + '-' + CompName + '>';
    var ClosePos := Html.IndexOf(EndTag, CloseAngle);

    if ClosePos < 0 then
      Exit;

    Slot := Html.Substring(CloseAngle + 1, ClosePos - CloseAngle - 1);
    TagEnd := ClosePos + EndTag.Length;
  end;

  Result := True;
end;

function TComponentExpander.ExpandComponent(const Name, AttrsStr, Slot: string;
  UsedScripts, UsedStyles: TDictionary<string, string>): string;
begin
  if not FRegistry.TryGet(Name, Result) then
  begin
    Result := '<!-- component "' + Name + '" not found -->';
    Exit;
  end;

  var Attrs := ParseAttrs(AttrsStr);
  try
    Result := Result.Replace('{{id}}', GenerateId(Name));
    Result := Result.Replace('{{slot}}', Slot);
    Result := ApplyAttrs(Result, Attrs);

    var Key := Name.ToLower;
    var Style: string;

    if FRegistry.TryGetStyle(Key, Style) then
    begin
      Result := ApplyScopeAttr(Result, Key);

      if not UsedStyles.ContainsKey(Key) then
        UsedStyles.AddOrSetValue(Key, ScopeStyle(Style, Key));
    end;

    var Script: string;

    if FRegistry.TryGetScript(Key, Script) and not UsedScripts.ContainsKey(Key) then
      UsedScripts.AddOrSetValue(Key, Script);
  finally
    Attrs.Free;
  end;
end;

function TComponentExpander.Expand(const Html: string): string;
begin
  Result := Html;

  if not FRegistry.HasPrefixes then
    Exit;

  var Prefixes := FRegistry.GetPrefixes;
  var UsedScripts := TDictionary<string, string>.Create;
  var UsedStyles := TDictionary<string, string>.Create;

  try
    var Changed := True;
    var Depth := 0;

    while Changed and (Depth < MAX_EXPANSION_DEPTH) do
    begin
      Inc(Depth);
      Changed := False;
      var SearchPos := 0;

      while True do
      begin
        var Prefix: string;
        var TagStart: Integer;

        if not FindTag(Result, SearchPos, Prefixes, Prefix, TagStart) then
          Break;

        var FullName, AttrsStr, Slot: string;
        var TagEnd: Integer;

        if not ParseTag(Result, Prefix, TagStart, FullName, AttrsStr, Slot, TagEnd) then
        begin
          SearchPos := TagStart + 1;
          Continue;
        end;

        var Expanded := ExpandComponent(FullName, AttrsStr, Slot, UsedScripts, UsedStyles);

        Result := Result.Substring(0, TagStart) + Expanded + Result.Substring(TagEnd);
        SearchPos := TagStart + Expanded.Length;
        Changed := True;
      end;
    end;

    if Changed then
      Result := Result + '<!-- warning: max component expansion depth ('
        + MAX_EXPANSION_DEPTH.ToString + ') reached -->';

    if UsedStyles.Count > 0 then
    begin
      Result := Result + '<style>' + sLineBreak;

      for var Style in UsedStyles.Values do
        Result := Result + Style;

      Result := Result + '</style>' + sLineBreak;
    end;

    for var Script in UsedScripts.Values do
      Result := Result + '<script>' + Script + '</script>' + sLineBreak;
  finally
    UsedScripts.Free;
    UsedStyles.Free;
  end;
end;

initialization
  _Registry := TComponentRegistry.Create;
  _Expander := TComponentExpander.Create(_Registry);

finalization
  _Expander := nil;
  _Registry := nil;

end.
