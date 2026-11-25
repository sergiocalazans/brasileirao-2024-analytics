# Brasileirão Analytics: PjBL2, Tabela de Classificação em Haskell

Este programa calcula a tabela de classificação de um campeonato de futebol a partir dos
resultados das partidas, recebidos como texto. Ele responde perguntas como *"quem lidera depois
da 3ª rodada?"* e *"como um empate em pontos é desempatado?"*, mostra estatísticas do campeonato e
rejeita entradas com erros de digitação com uma mensagem útil, sem nunca encerrar com exceção.

> **Ambientes verificados:** GHC **9.10.3** no Windows 11 e no Ubuntu **26.04.1 LTS**, via WSL 2.
> Para reproduzir a validação pré-merge, use o Ubuntu/WSL; a instalação nativa do Windows precisa de reparo.
> O playground (play.haskell.org) **não** foi usado. O projeto depende só da biblioteca `base`.

## Integrantes

| Nome | GitHub |
|---|---|
| Sérgio | [sergiocalazans](https://github.com/sergiocalazans) |
| Glaucia | Não informado |
| Nicolly | [ly-ubimyy](https://github.com/ly-ubimyy) |
| Gustavo | Não informado |

## Estrutura do projeto

```text
projeto/
├── src/
│   ├── Tipos.hs          Camada 1: tipos algébricos e consultas básicas
│   ├── Classificacao.hs  Camada 2: classificação e estatísticas (ordem superior)
│   ├── Leitura.hs        Camada 3: leitura com Maybe/Either, validação e formatação
│   ├── Dados.hs          campeonato de teste e entradas de exemplo, como String
│   └── Main.hs           demonstração das três camadas (o único ponto com IO)
├── tests/
│   └── Testes.hs         86 testes com resultado esperado
├── data/
│   ├── brasileirao-2024.csv  380 partidas reais da Série A 2024
│   ├── campeonato-teste.csv  campeonato controlado exigido pela issue #03
│   └── teste.txt             arquivo original da equipe, preservado
├── docs/
│   ├── decisoes.md       decisões de modelagem e limitações conhecidas
│   └── contribuicao.md   convenções de branches, commits e pull requests
└── README.md
```

As dependências entre os módulos seguem as camadas:
`Tipos` ← `Classificacao` ← `Leitura` ← `Main`. `Dados` é independente (só contém textos).

## Como executar

Todos os comandos devem ser executados **na raiz do projeto**. A opção `-isrc` diz ao GHC onde
estão os módulos.

### 1. Sem compilar (`runghc`)

```powershell
runghc -isrc src/Main.hs
```

```powershell
runghc -isrc src/Main.hs data/campeonato-teste.csv
```

```powershell
runghc -isrc tests/Testes.hs
```

- O primeiro comando usa o campeonato embutido em `src/Dados.hs`.
- O segundo lê os dados de um arquivo. Pode ser qualquer arquivo no formato abaixo. Se ele não
  existir, o programa avisa e continua normalmente.
- O terceiro roda os testes. O resultado esperado termina com `86 de 86 testes passaram.`, e o
  código de saída é 1 se algum teste falhar.

Para consultar os resultados reais, use `runghc -isrc src/Main.hs data/brasileirao-2024.csv`.

### 2. No GHCi

```powershell
ghci -isrc src/Main.hs
```

```text
ghci> :main                        -- demonstração com os dados embutidos
ghci> :main data/teste.txt         -- demonstração lendo o arquivo
ghci> :module + Tipos Classificacao Leitura Dados
ghci> fmap (map time . classificacao . ateRodada 3) (lerCampeonato dadosCampeonato)
Right ["Palmeiras","Botafogo","Fortaleza","Internacional","Flamengo","Cruzeiro"]
ghci> todosOsErros "1;Bahia;dois;0;Vasco"
[NumeroInvalido 1 "dois"]
ghci> putStr (either mensagemErro tabelaFormatada (classificacao <$> lerCampeonato dadosCampeonato))
```

Para rodar os testes no GHCi, use `ghci -isrc tests/Testes.hs` e depois `:main`.

### 3. Compilando (com todos os avisos ligados)

```powershell
New-Item -ItemType Directory -Force build
```

```powershell
ghc -Wall -isrc -outputdir build/obj-app -o build/tabela src/Main.hs
```

```powershell
ghc -Wall -isrc -outputdir build/obj-testes -o build/testes tests/Testes.hs
```

Depois execute `.\build\tabela.exe` e `.\build\testes.exe` no Windows, ou `./build/tabela` e
`./build/testes` no Linux e no macOS. O código compila **sem nenhum aviso** com `-Wall`. Ele foi
conferido também com `-Werror -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns
-Wpartial-fields -Wredundant-constraints`.

### Validação pré-merge no Ubuntu/WSL

Na revisão de 25/11/2026, a aplicação e os testes compilaram sem avisos com GHC 9.10.3,
no Ubuntu 26.04.1 LTS (x86_64), via WSL 2. Na raiz do projeto, execute:

```bash
mkdir -p build
ghc -Wall -Werror -isrc src/Main.hs -o build/brasileirao
ghc -Wall -Werror -isrc -outputdir build/obj-testes tests/Testes.hs -o build/testes
./build/testes
./build/brasileirao data/campeonato-teste.csv
./build/brasileirao data/brasileirao-2024.csv
```

Os 86 testes passaram no executável e com `runghc -isrc tests/Testes.hs`. Foram verificados
também dez cenários de execução: dados embutidos, CSV controlado, arquivo original, CSV real,
arquivo vazio, entrada inválida, arquivo inexistente, diretório, bytes inválidos e nomes acentuados.

No Windows nativo, o comando normal ainda falha por arquivos ausentes na instalação do Clang
(`x86intrin.h`). A revisão anterior usou uma cópia temporária do cache do GHCup; esse caminho
não é requisito de execução. Use o WSL validado acima ou repare a instalação nativa antes da
apresentação. A revisão pré-merge não alterou a instalação do compilador. Docker, macOS e
playground não foram testados nesta revisão.

## Formato da entrada

Cada linha descreve uma partida, com os campos separados por ponto e vírgula. Linhas em branco e
linhas que começam com `#` são ignoradas, mas contam na numeração das mensagens de erro.

```text
# rodada;mandante;gols mandante;gols visitante;visitante
1;Botafogo;1;2;Palmeiras
1;Flamengo;0;0;Cruzeiro
```

Espaços em volta dos campos (e o `\r` de arquivos do Windows) são removidos. Os números precisam
ser inteiros decimais (`3`, `-1`). Entradas como `dois`, `2a`, `3.0`, `+3`, `(3)`, `0x10` ou
números que não cabem em um `Int` geram um `Erro`, e nunca uma exceção.

## O que o programa mostra

O `main` demonstra as três camadas, em sequência:

1. **Camada 1:** os times do campeonato (`times`) e o resultado de cada um rodada a rodada
   (`resultadoPara`);
2. **Camada 2:** a tabela final, com a explicação de cada empate em pontos;
3. **Camada 2:** a tabela após a rodada intermediária (rodada 3), que tem outro líder;
4. **Camada 2:** as estatísticas (total de gols, média por partida e maior goleada);
5. **Robustez:** um campeonato sem partidas, em que tudo continua funcionando;
6. **Camada 3:** o tratamento de uma entrada com erros, com o primeiro erro (`lerCampeonato`) e o
   relatório completo (`todosOsErros`).

Trecho da saída:

```text
Camada 2 - Classificacao final
------------------------------
  Pos  Time           Pts   J   V   E   D   GP   GC   SG    Aprov
    1  Botafogo        10   5   3   1   1   10    5   +5   66,67%
    2  Palmeiras        9   5   3   0   2    8    5   +3   60,00%
    3  Fortaleza        7   5   2   1   2    5    7   -2   46,67%
    4  Flamengo         7   5   1   4   0    8    6   +2   46,67%
    5  Internacional    4   5   1   1   3    7   11   -4   26,67%
    6  Cruzeiro         4   5   1   1   3    5    9   -4   26,67%
  * Fortaleza fica a frente de Flamengo (ambos com 7 pontos): desempate por vitorias
  * Internacional fica a frente de Cruzeiro (ambos com 4 pontos): desempate por gols marcados

Camada 3 - Tratamento de uma entrada com erros
----------------------------------------------
  lerCampeonato para no primeiro erro:
    Linha 3: "dois" nao e um numero inteiro
  todosOsErros lista todos os problemas (7):
    - Linha 3: "dois" nao e um numero inteiro
    - Linha 4: esperados 5 campos separados por ';', encontrados 4
    - Linha 5: o placar nao pode ter gols negativos
    - Linha 6: Cruzeiro nao pode jogar contra si mesmo
    - Linha 7: rodada 0 invalida (deve ser 1 ou mais)
    - Linha 8: nome de time em branco
    - Rodada 2: Flamengo esta escalado em mais de uma partida
```

A saída usa apenas caracteres ASCII, sem acentos, para aparecer igual em qualquer console. O
motivo está em [docs/decisoes.md](docs/decisoes.md).

## Dados reais e critérios de desempate

O arquivo `data/brasileirao-2024.csv` contém 380 partidas, 20 times e 38 rodadas. A fonte é
[Brasileirão Dataset](https://github.com/leeofernandes1980/brasileirao-dataset/blob/de69fdc5fa0f2b88c20d0a28fe2b769bdff197b9/dashboard/public/data/json/partidas_resumo.json),
que identifica os registros de 2024 como provenientes do Sofascore. Consulta: 25/11/2026.
O JSON foi filtrado por `temporada == 2024`, ordenado por rodada e identificador da partida e
convertido para as cinco colunas exigidas, separadas por `;`. Os nomes e placares foram preservados;
datas, estádio, identificador e demais campos foram descartados. O cabeçalho começa com `#`.
O CSV legado da fonte termina antes de 2024 e não foi usado para gerar o arquivo entregue.

A tabela final foi conferida com a [CBF](https://www.cbf.com.br/futebol-brasileiro/tabelas/campeonato-brasileiro/serie-a/2024):
Botafogo com 79 pontos; 929 gols no campeonato. O teste compara as 20 linhas completas.
Jogos adiados permanecem na rodada original; a tabela parcial representa rodadas, não datas.

A ordenação usa pontos, vitórias, saldo, gols pró e confronto direto. Este último só é aplicado
quando há exatamente dois clubes empatados em pontos e um jogo em cada mando, pelo placar
agregado. Cartões e sorteio não estão no formato de entrada: persistindo o empate, usa-se a ordem
alfabética. Essa adaptação não equivale ao regulamento integral da CBF e precisa ser aceita na
avaliação acadêmica. Ela não altera a classificação final do dataset de 2024.

## Campeonato de teste

O campeonato fica em [src/Dados.hs](src/Dados.hs), [data/campeonato-teste.csv](data/campeonato-teste.csv)
e no arquivo original [data/teste.txt](data/teste.txt). É um
campeonato fictício com seis clubes da Série A 2024, em turno único de 5 rodadas (15 partidas), em
que nenhum time joga duas vezes na mesma rodada. Os placares foram escolhidos para cobrir os
casos de borda:

| Caso exigido ou de borda | Onde aparece |
|---|---|
| Empate em 0 x 0 | Flamengo 0 x 0 Cruzeiro (rodada 1) |
| Vitória por 3 ou mais gols | Palmeiras 4 x 0 Cruzeiro e Botafogo 3 x 0 Fortaleza |
| Empate em pontos decidido por **vitórias** | Fortaleza e Flamengo com 7 pontos. Fortaleza fica à frente com 2 vitórias contra 1, mesmo com saldo pior |
| Empate em pontos, vitórias e saldo, decidido por **gols marcados** | Internacional e Cruzeiro com 4 pontos, 1 vitória e saldo -4. Internacional marcou 7 gols, e Cruzeiro, 5 |
| Empate decidido por **saldo** | Após a rodada 3: Palmeiras (+4) e Botafogo (+2), ambos com 6 pontos e 2 vitórias |
| Tabela intermediária diferente da final | Palmeiras lidera após a rodada 3, e Botafogo é o campeão |
| Outros | Time invicto (Flamengo), vitórias fora de casa, empates com gols (2 x 2 e 3 x 3) |

## Testes

São 86 testes em [tests/Testes.hs](tests/Testes.hs). Cada um compara o valor obtido com o esperado,
conferido à mão, e os testes são separados por camada:

- **Camada 1 (13 testes):** `resultadoPara` para o mandante, o visitante e um time que não jogou
  (que dá `Nothing`) e para o 0 x 0; `participou`; `golsMarcados` e `golsSofridos`; `times` sem
  repetição e em ordem alfabética, inclusive sem partidas; e a verificação de que o campeonato de
  teste atende aos mínimos (6 times, 5 rodadas, ninguém repetido na rodada, um 0 x 0 e uma
  goleada).
- **Camada 2 (29 testes):** `pontos`, `linhaDoTime`, `pontosLinha`, `saldo` e `aproveitamento`
  (inclusive de quem não jogou); a classificação completa conferida à mão; os três desempates,
  cada um com o critério que decidiu (`criterioDecisivo`); o critério alfabético; a
  classificação de `ateRodada 3`, diferente da final; e `maiorGoleada` e `mediaGols`, com a
  lista vazia (`Nothing`) e com empate na diferença de gols; confronto direto, exclusão desse
  critério em empate triplo e independência da ordem de entrada.
- **Camada 3 (37 testes):** `separar`; `lerPartida` válida, com espaços e `\r`; `lerCampeonato`
  sobre a entrada válida (`Right` com as 15 partidas), sobre um texto só com comentários e sobre
  o texto vazio; **um teste para cada construtor de `Erro`**, além dos formatos numéricos
  traiçoeiros (`2a`, `(3)`, `0x10` e um número que estoura `Int`); `todosOsErros` com 7 linhas
  inválidas e múltiplos problemas na mesma linha; escalações repetidas com placar inválido;
  integração do parser com a classificação; a coerência entre `lerCampeonato` e `todosOsErros`; as mensagens de erro; e a
  formatação da tabela, inclusive a tabela vazia.

- **Arquivos CSV (7 testes):** equivalência dos dados controlados, estrutura do dataset real,
  ausência de erros, tabela final completa comparada com a CBF, gols e classificação parcial.

Os testes de arquivos devem ser executados na raiz do projeto.

## Onde está cada requisito

| Requisito do enunciado | Onde está |
|---|---|
| `Time`, `Resultado`, `Partida`, `Linha` | [src/Tipos.hs](src/Tipos.hs) |
| `participou`, `resultadoPara`, `times` | [src/Tipos.hs](src/Tipos.hs) |
| Campeonato de teste (6 times, 5 rodadas, 0 x 0, goleada, empate em pontos) | [src/Dados.hs](src/Dados.hs) |
| `pontos`, `linhaDoTime` (com `foldr`), `pontosLinha`, `saldo`, `aproveitamento` | [src/Classificacao.hs](src/Classificacao.hs) |
| `classificacao` com `sortBy`, `comparing`, `Down` e `<>` | `criterios` e `compararLinhas` em [src/Classificacao.hs](src/Classificacao.hs) |
| `ateRodada`, `maiorGoleada`, `mediaGols` (totais, com `Maybe`) | [src/Classificacao.hs](src/Classificacao.hs) |
| `map`, `filter`, dobra e `(.)` na Camada 2, sem recursão explícita | [src/Classificacao.hs](src/Classificacao.hs) |
| `data Erro` (5 construtores exigidos + 2 extras) | [src/Leitura.hs](src/Leitura.hs) |
| `separar`, `lerPartida` (`do` em `Either`), `lerCampeonato` (`traverse`), `todosOsErros` | [src/Leitura.hs](src/Leitura.hs) |
| `readMaybe` em vez de `read`; `Maybe` como mônada (`>>=`) e functor (`<$>`, `maybe`) | `lerInteiro` em [src/Leitura.hs](src/Leitura.hs) |
| `tabelaFormatada` | [src/Leitura.hs](src/Leitura.hs) |
| `main` como única função com IO, com os dados no código | [src/Main.hs](src/Main.hs) |
| Testes obrigatórios das três camadas | [tests/Testes.hs](tests/Testes.hs) |
| Decisões de modelagem e limitações | [docs/decisoes.md](docs/decisoes.md) |
