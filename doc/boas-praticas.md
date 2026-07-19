# Boas Práticas

## Formatação de Código

### Declaração de variáveis inline

Declare variáveis inline (sem bloco `var` separado), uma por linha:

```pascal
// Correto
var Dir := ExtractFilePath(FilePath);
var RelPath := LDir.Substring(PagesDir.Length);

// Incorreto
var
  LDir, LRelPath: string;
```

### Ordenação de métodos na declaração da classe

Na declaração (`type`), constructor e destructor vêm primeiro, seguidos de functions em ordem alfabética e depois procedures em ordem alfabética:

```pascal
  public
    constructor Create;
    destructor Destroy; override;
    class function Expand(const ATemplate: string): string;
    class procedure Load(const AComponentsDir: string);
```

Isso vale pra qualquer escopo de visibilidade (`private`, `protected`, `public`). A implementação não precisa seguir a mesma ordem — fica na ordem que faz sentido pro fluxo de leitura.

### Linha em branco após declaração de variável

Pular uma linha em branco entre uma declaração de variável inline e um `if`, `for`, `while`, `case`, `try` subsequente.

**Não pular** se a próxima linha for outra declaração de `var` ou se for usar a variável imediatamente (atribuição, chamada).

```pascal
// Correto — var seguida de if: pula linha
var Condominio := FRepository.FindById(Id);

if not Assigned(Condominio) then
  raise Exception.Create('Não encontrado');

// Correto — vars consecutivas: não pula
var Mes := StrToIntDef(Parts[0], 1);
var Ano := StrToIntDef(Parts[1], 2026);
var DataInicial := EncodeDate(Ano, Mes, 1);

// Correto — var seguida de atribuição a outra coisa: pula linha
var Service := TMyService.Create;

Result := Service.Execute(Params);

// Correto — var usada diretamente na linha seguinte: não pula
var Service := TMyService.Create;
Service.Execute(Params);

// Incorreto — falta linha antes do if
var Condominio := FRepository.FindById(Id);
if not Assigned(Condominio) then
  raise Exception.Create('Não encontrado');

// Incorreto — linha desnecessária entre vars
var Mes := StrToIntDef(Parts[0], 1);

var Ano := StrToIntDef(Parts[1], 2026);
```


## Encoding (UTF-8 com BOM)

### Regra geral

Todo arquivo `.pas` criado ou editado deve ser convertido para UTF-8 com BOM. Porém, o script de conversão deve ser aplicado **apenas nos arquivos efetivamente modificados**, nunca em batch sobre todo o diretório.

### Por que não rodar em batch

Rodar o script de BOM em todos os `.pas` de `src/` e `tests/` altera o conteúdo binário de arquivos que não foram tocados, gerando ruído no `git diff` e potencialmente quebrando blame/history sem necessidade.

### Como aplicar corretamente

Listar explicitamente apenas os arquivos editados na sessão:

```python
files = [
    r'src\Pegasus.Pages.pas',
    r'src\routing\Pegasus.Routing.Scanner.pas',
    # ... apenas os que foram editados
]

for p in files:
    c = open(p, 'rb').read()
    open(p, 'wb').write(b'\xef\xbb\xbf' + c.replace(b'\xef\xbb\xbf', b''))
```

Ou rodar o one-liner da convenção do projeto passando cada arquivo individualmente.

### Nunca converter

Arquivos em `modules/` nunca devem ser convertidos (são dependências externas).
