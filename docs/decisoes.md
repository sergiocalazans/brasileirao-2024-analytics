# Decisões de Modelagem e Limitações

## 1. Visão geral

O **Brasileirão Analytics** é um programa em Haskell que calcula a tabela de classificação de um
campeonato de futebol a partir dos resultados das partidas. Ele usa as ideias centrais da
programação funcional:

- **tipos algébricos** para modelar o domínio;
- **funções de ordem superior** para calcular a tabela, sem recursão explícita;
- **`Maybe` e `Either`** para tratar a ausência de resultado e os erros de entrada sem exceções.

Este documento explica **por que** cada decisão foi tomada e lista, ao final, as **limitações
conhecidas** do sistema.

## 2. Arquitetura

| Camada | Módulo | Responsabilidade |
|---|---|---|
| 1. Tipos e dados | `Tipos.hs` | Tipos do domínio e consultas sobre uma partida |
| 2. Classificação | `Classificacao.hs` | Linha de cada time, ordenação, desempates e estatísticas |
| 3. Leitura e saída | `Leitura.hs` | Texto → partidas (com validação), erros e formatação |
| (dados) | `Dados.hs` | Campeonato de teste e entradas de exemplo, como `String` |
| (casca de IO) | `Main.hs` | Obtém o texto e imprime o relatório |

As dependências seguem as camadas (`Tipos` ← `Classificacao` ← `Leitura` ← `Main`), sem ciclos.

**Núcleo puro e casca de IO.** `main` é a única função com IO do programa. O relatório inteiro é
montado pela função pura `demonstracao :: String -> String -> String`, e `main` apenas decide de
onde vem o texto e o imprime. Assim, qualquer parte do programa pode ser testada sem IO, tanto em
`tests/Testes.hs` quanto no GHCi.

**Origem dos dados.** O playground não tem entrada pelo teclado e o enunciado proíbe `getLine`.
Por isso, os dados ficam no código, em `Dados.hs`. Como opção para o GHC local, `main` aceita o
caminho de um arquivo como argumento. Essa leitura usa `try` (de `Control.Exception`, que faz
parte da `base`): se o arquivo não existir ou não puder ser lido, a falha vira uma mensagem, e
não uma exceção. `evaluate` força a leitura completa ainda dentro do `try`, porque `readFile` é
preguiçoso e um erro poderia aparecer depois, já fora da proteção.

## 3. Camada 1: tipos

| Decisão | Justificativa |
|---|---|
| `type Time = String` | Exigido pelo enunciado. Deixa as assinaturas mais legíveis (`Time -> Partida -> Bool`). |
| `Resultado` como tipo soma (`Vitoria \| Empate \| Derrota`) | Fecha o conjunto de valores possíveis. Um `"v"` minúsculo compilaria como `String`, mas não como `Resultado`, e com `-Wall` o compilador avisa se algum caso ficar sem tratamento (`pontos` e `resultadoDoPlacar` tratam todos). |
| `Partida` e `Linha` como *records* | Cada número tem nome. Numa tupla `(Int, String, Int, Int, String)`, trocar os gols do mandante com os do visitante compilaria sem aviso. |
| `Linha` guarda **apenas contagens** (jogos, V, E, D, gols pró e contra) | Pontos, saldo e aproveitamento são **funções** da Camada 2, e não campos. Assim, uma linha nunca fica com pontos que não batem com as vitórias e os empates: esse estado inválido simplesmente não pode ser representado. |
| `resultadoPara` devolve `Maybe Resultado` | A ausência de resultado (o time não jogou) faz parte do tipo, e quem chama precisa tratá-la. Não existe um valor "falso" como `Derrota` para representá-la. |
| `golsMarcados` e `golsSofridos` devolvem 0 para quem não jogou | 0 é o elemento neutro da soma. Usadas dentro de uma dobra, essas funções nunca alteram a linha de um time que não jogou. A distinção entre "não jogou" e "não marcou" fica com `participou` e `resultadoPara`. |
| `resultadoPara` usa `compare` sobre os gols | `case compare marcados sofridos of GT/EQ/LT` cobre os três casos sem `if` encadeados, e o compilador confere que todos foram tratados. |
| `times = sort . nub . concatMap ...` | É uma composição simples: junta mandantes e visitantes, remove repetições e ordena. Não usa `map head . group`, porque `head` é parcial (e gera aviso no GHC ≥ 9.8). |

## 4. Camada 2: classificação com ordem superior

**Sem recursão explícita.** Toda a camada usa `map`, `filter`, `foldr`, `zip`, `sortBy` e
composição. Por exemplo:

- `ateRodada n = filter ((<= n) . rodada)`;
- `ultimaRodada = foldr (max . rodada) 0`;
- `totalDeGols = sum . map golsDaPartida`.

**`linhaDoTime`: `filter` + `foldr`.** A função primeiro filtra as partidas do time e depois soma
uma a uma, com `somarPartida`, a partir de `linhaVazia`. Sobre a escolha da dobra:

- Somar as contribuições de cada partida é associativo e comutativo, então a ordem da dobra não
  muda o resultado.
- Escolhemos `foldr` porque está no `Prelude` de todas as versões do GHC e combina com a leitura
  natural: "a linha é a soma desta partida com a linha do resto".
- `foldl` (preguiçoso) acumularia *thunks* sem nenhuma vantagem.
- `foldl'` exigiria `import Data.List (foldl')`. A partir do GHC 9.10, `foldl'` passou a vir no
  `Prelude`, então esse import mudaria de necessário (GHC antigo) para redundante (GHC novo).
- Para um campeonato (no máximo 38 jogos por time), a diferença de desempenho é desprezível.

**Pontuação centralizada.** `pontosLinha` e `aproveitamento` usam `pontos Vitoria` em vez do
número 3 escrito direto. Para mudar a regra de pontuação, basta alterar `pontos`.

**`aproveitamento`.** A função devolve o percentual (0 a 100) dos pontos disputados. A conversão
`fromIntegral` é feita antes da divisão com `(/)`: dividir com `div` truncaria o resultado, e
`(/)` não aceita `Int`. Quando `jogos == 0`, o resultado é 0, o que evita a divisão por zero.

**Critérios de desempate (adaptação do Brasileirão).** A ordem é:

1. pontos;
2. vitórias;
3. saldo de gols;
4. gols marcados;
5. confronto direto, quando aplicável;
6. ordem alfabética como último recurso determinístico.

- Os critérios ficam numa **única lista nomeada**, `criterios :: [(String, Linha -> Linha ->
  Ordering)]`, que é a fonte única de verdade.
- `compararLinhas a b = foldr (\(_, compara) resto -> compara a b <> resto) EQ criterios`
  aplica os critérios em ordem e junta os resultados com `<>`. O resultado é o mesmo de
  `comparing (Down . pontosLinha) <> comparing (Down . vitorias) <> ...`.
  - `Ordering` é um `Monoid`: `LT <> _ = LT`, `GT <> _ = GT` e `EQ <> y = y`. Por isso, o
    primeiro critério diferente de `EQ` decide, e os seguintes nem são avaliados.
  - `Down` inverte a ordem, porque quem tem **mais** fica acima.
  - Preferimos combinar valores `Ordering`, e não funções (`mconcat (map snd criterios)`),
    porque a dobra explícita é mais fácil de explicar, linha a linha.
- A ordenação usa uma única chamada a `sortBy`. `criteriosDoCampeonato` acrescenta o confronto
  direto aos critérios existentes, antes da ordem alfabética. Encadear vários `sortBy` seria frágil.
- `criterioDecisivo` compara linhas isoladas; `criterioDecisivoCampeonato` usa as partidas e os
  mesmos critérios da classificação para explicar a saída.
- Conforme o [art. 15 do regulamento da CBF de 2024](https://www.netvasco.com.br/news/noticias16/arquivos/20240229-212757-2-rec--brasileiro-serie-a-2024.pdf),
  o confronto direto só é usado quando exatamente dois clubes empatam em pontos. O programa
  exige um jogo de ida e um de volta e compara o saldo agregado desses jogos. Com três ou mais
  clubes empatados em pontos, o critério é ignorado, evitando uma comparação não transitiva.
- Cartões e sorteio continuam fora do modelo; usa-se ordem alfabética quando o empate persiste.
  A fidelidade integral ao regulamento depende de dados adicionais ou de aprovação dessa adaptação.

**Funções totais.** Nenhuma função da camada quebra com a lista vazia:

- `maiorGoleada` é um `foldr` que começa em `Nothing`. Ela não usa `maximumBy` nem `foldr1`, e
  em caso de empate fica a primeira partida da lista.
- `mediaGols` trata `[]` por casamento de padrão e devolve `Nothing`.
- `empatesEmPontos` usa `zip tabela (drop 1 tabela)` em vez de `tail`.
- A largura da coluna de nomes em `tabelaFormatada` é um `foldr` com valor inicial, e não um
  `maximum`.

**Tabela parcial.** `classificacao (ateRodada n partidas)` mostra a tabela em qualquer momento do
campeonato, reaproveitando as mesmas funções.

## 5. Camada 3: leitura, validação e saída

**`Erro` com sete construtores.** São os cinco exigidos (`CamposInvalidos`, `NumeroInvalido`,
`PlacarNegativo`, `MesmoTime`, `TimeRepetidoNaRodada`) mais dois:

- `RodadaInvalida`, para rodada 0 ou negativa;
- `TimeVazio`, para um nome em branco. Sem ele, a linha `1;;2;0;` seria aceita com um time de
  nome `""`, ou acusada como `MesmoTime`, o que confundiria o usuário.

Cada construtor carrega a **linha** do problema. A exceção é `TimeRepetidoNaRodada`, que carrega
a **rodada** e o time, porque essa verificação acontece depois da leitura, sobre a lista de
partidas. Os construtores também guardam um detalhe útil: quantos campos a linha tinha, ou qual
texto não era número. `mensagemErro` transforma cada erro em uma frase que diz onde está o
problema.

**`lerPartida`: um `case` e um bloco `do`.** O `case` só confere a quantidade de campos. As
validações são encadeadas pela notação `do` na mônada `Either`, e o primeiro `Left` interrompe o
resto. A ordem é:

1. converter os números;
2. ler os nomes;
3. conferir se a rodada é maior ou igual a 1;
4. conferir se o placar não é negativo;
5. conferir se mandante e visitante são times diferentes.

Não há `case` aninhados (a "escadinha" citada nas armadilhas).

**`lerInteiro`: conversão sem exceções.** A conversão é uma cadeia na mônada `Maybe`, ligada por
`>>=`, e `maybe` transforma o `Nothing` em `Left`:

```haskell
soAlgarismos texto >>= readMaybe >>= cabeEmInt
```

- **`soAlgarismos`:** só aceita algarismos, com um `-` opcional. Durante os testes, descobrimos
  que `readMaybe` sozinho aceita `"(3)"` e `"0x10"`, que são sintaxe de literais do Haskell.
- **`readMaybe`:** converte para `Integer`, que não estoura. Nunca é usado `read`, que lançaria
  `Prelude.read: no parse`.
- **`cabeEmInt`:** confere se o valor cabe em um `Int`. Também descobrimos que
  `readMaybe "99999999999999999999" :: Maybe Int` "dá a volta" e devolve um número qualquer. Agora
  esse texto vira `NumeroInvalido`.
- O sinal negativo passa por `soAlgarismos` de propósito: assim, `-1` vira `PlacarNegativo` ou
  `RodadaInvalida`, uma mensagem mais precisa que "não é um número".

**`lerCampeonato`: `traverse` e verificação das rodadas.**

- `traverse (uncurry lerPartida)` aplica a leitura a todas as linhas dentro de `Either` e para
  no primeiro erro.
- Depois, `verificarRodadas` confere se algum time foi escalado duas vezes na mesma rodada.
- A numeração das linhas conta **todas** as linhas do texto, inclusive comentários e linhas em
  branco, para que "Linha 7" seja a linha 7 do arquivo.

**`todosOsErros`: relatório completo.**

- `errosDaLinha` verifica independentemente os campos, usando `lefts` e `rights` para reunir
  erros numéricos e conferir os valores que puderam ser lidos. Assim, uma linha pode gerar
  `NumeroInvalido`, `PlacarNegativo` e `MesmoTime` ao mesmo tempo.
- `escalacoesDaLinha` usa rodadas válidas e nomes conhecidos mesmo quando o placar está errado.
  Um time aparece uma única vez por partida; jogar contra si mesmo gera `MesmoTime`.
- Primeiro vêm os erros de linha, em ordem de leitura; depois, os erros de escalação. Campos
  em quantidade errada geram `CamposInvalidos`, pois não há como associá-los com segurança.
- `lerCampeonato` mantém a interrupção no primeiro erro via `traverse`. A lista completa tem
  finalidade diferente e pode detectar uma infração de rodada mesmo em linhas inválidas.

**`separar` com `foldr`.** A dobra guarda o campo em construção e os campos já completos.
`separar` preserva campos vazios (`separar ';' "a;;b" == ["a","","b"]`), o que permite detectar
`CamposInvalidos` e `TimeVazio`. Os campos são depois limpos de espaços nas pontas, inclusive o
`\r` de arquivos do Windows.

**`tabelaFormatada`: colunas descritas como dados.** Cada coluna é descrita por título, largura e
função que calcula o valor. Acrescentar uma coluna é acrescentar uma linha em `colunas`. Além das
colunas pedidas (posição, time, pontos, J, V, E, D e saldo), a tabela mostra gols pró, gols contra
e aproveitamento, que tornam visível o motivo de cada desempate.

**Saída somente em ASCII.** As mensagens e os nomes do campeonato de teste não têm acentos:

- No computador usado no desenvolvimento, o GHC usa **CP437** como codificação local, e essa
  codificação nem tem a letra `ã`.
- Um teste com `putStrLn "São Paulo"` derrubou o programa com
  `<stdout>: commitBuffer: invalid argument (cannot encode character '\227')`. Isso violaria a
  regra de que nada pode encerrar o programa com exceção.
- Com saída ASCII, o programa imprime corretamente em qualquer console, no Windows, no Linux e no
  playground.
- Os comentários do código têm acentos normalmente, porque o GHC sempre lê o código-fonte como
  UTF-8.

## 6. Campeonato de teste

A issue #03 prevê dois conjuntos separados: resultados reais da Série A 2024 e um campeonato
controlado para testes. O enunciado exige pelo menos seis times e cinco rodadas, mas não exige
um turno fechado. O dataset real está em `data/brasileirao-2024.csv`; a fonte e a transformação
estão documentadas no README. Nenhum resultado fictício foi incluído nesse arquivo.

Para permitir a conferência à mão e exercitar os desempates, a equipe montou um
**campeonato fictício com seis clubes da Série A 2024** (Botafogo,
Palmeiras, Fortaleza, Flamengo, Internacional e Cruzeiro), em turno único de 5 rodadas gerado pelo
método do círculo. A tabela de mandos foi equilibrada: cada time joga 2 ou 3 vezes em casa.

Os placares foram escolhidos para exercitar cada critério de desempate:

- **Vitórias decidem:** Fortaleza (2 V) fica à frente do Flamengo (1 V), embora o Flamengo esteja
  invicto e tenha saldo melhor (+2 contra -2). Isso prova que vitórias vêm antes do saldo.
- **Gols marcados decidem:** Internacional e Cruzeiro empatam em pontos, vitórias e saldo (-4). O
  Internacional fica à frente com 7 gols contra 5, ao contrário da ordem alfabética. Isso prova
  que o critério alfabético não é o que decide.
- **Saldo decide:** após a rodada 3, Palmeiras (+4) e Botafogo (+2) têm 6 pontos e 2 vitórias.
  O líder da rodada 3 (Palmeiras) não é o campeão (Botafogo).

O mesmo campeonato está em `Dados.hs` (como `String`), `data/campeonato-teste.csv` e
`data/teste.txt`. Os testes comparam as partidas lidas dos três formatos.

## 7. Como cada armadilha do enunciado foi evitada

| Armadilha | Como foi evitada |
|---|---|
| Partida como tupla | `Partida` e `Linha` são *records* com campos nomeados. |
| Resultado como `String` ou `Int` | `Resultado` é um tipo soma. Compila sem avisos de padrões incompletos com `-Wall`. |
| `head`, `maximum` ou `foldr1` em lista possivelmente vazia | Nenhuma função parcial em `src/`. `maiorGoleada` e `mediaGols` devolvem `Maybe`; `empatesEmPontos` usa `drop 1`; a largura da tabela é um `foldr` com valor inicial. |
| Aproveitamento com `div` ou `/` entre `Int` | `fromIntegral` antes de `(/)`, e 0 para quem não jogou. |
| Ordenar só por pontos ou encadear vários `sortBy` | Um único `sortBy compararLinhas`, com os critérios combinados por `<>`. |
| Recursão explícita no lugar de `map`, `filter` ou dobra | Não há recursão explícita em nenhum módulo do projeto. |
| `read` para converter o placar | `readMaybe` em `Integer`, depois de validar os algarismos e antes de conferir o limite de `Int`. |
| `case` aninhados sobre `Either` | `do` na mônada `Either` em `lerPartida` e `lerCampeonato`; `traverse` para a lista. |
| `getLine` no `main` | Os dados ficam em `Dados.hs`. O arquivo é opcional e lido com `try`. |
| Campeonato vazio | `lerCampeonato` de um texto vazio ou só com comentários devolve `Right []`. A tabela, as estatísticas e a formatação respondem sem erro, como mostram a seção "Robustez" da saída e os testes. |

Todas as entradas inválidas testadas viraram `Left` com a linha ou a rodada do problema. Os testes
incluíram arquivo inexistente, diretório, arquivo vazio, bytes aleatórios, quebras de linha CRLF,
campos vazios, separador sobrando, `+3`, `3.0`, `(3)`, `0x10` e números enormes.

## 8. Limitações conhecidas

1. **Desempate adaptado.** Confronto direto está implementado para dois clubes empatados em
   pontos, com ida e volta disponíveis. Cartões e sorteio não fazem parte dos dados; a ordem
   alfabética é o recurso final. A classificação real de 2024 não depende dessa substituição.
2. **Nomes de times são comparados exatamente.** `Flamengo` e `flamengo` são times diferentes. Só
   os espaços das pontas são removidos; não há normalização de maiúsculas, acentos ou espaços
   internos.
3. **Primeiro erro ou relatório completo.** `lerPartida` informa o primeiro erro. `todosOsErros`
   acumula problemas independentes; uma regra que depende de um campo ilegível não é inferida.
4. **A escalação repetida indica a rodada, e não as linhas.** `todosOsErros` considera nomes
   conhecidos e rodadas válidas, inclusive quando o placar da linha está errado.
5. **A estrutura do campeonato não é validada.** O programa não verifica se as rodadas são
   consecutivas, se todos os times jogam em todas as rodadas ou quantas vezes dois times se
   enfrentam. O returno é permitido, mas um terceiro jogo entre os mesmos times também seria.
6. **O campo `jogos` de `Linha` é redundante** (igual a V + E + D), mas foi exigido pelo
   enunciado. A consistência é garantida porque, no programa, uma `Linha` só é construída por
   `linhaVazia` e `somarPartida`. O construtor continua exportado, porque os testes precisam dele.
7. **A validação só vale para dados lidos de texto.** O construtor `Partida` é exportado, então
   o código pode criar uma partida inválida (com gols negativos, por exemplo) sem passar por
   `lerPartida`.
8. **A tabela parcial mostra só os times que já jogaram.** Um time que só estreia depois da rodada
   `n` não aparece em `classificacao (ateRodada n ...)`.
9. **Eficiência.** `nub` (em `times` e nos erros de rodada) e `inits` são O(n²), e a dobra não é
   estrita. Para um campeonato real (380 partidas), isso é instantâneo, mas o código não foi
   pensado para milhões de linhas.
10. **Acentos e codificação.** A saída é ASCII (veja a seção 5). Nomes com acento lidos de um
    arquivo são aceitos e processados, mas podem aparecer com caracteres trocados num console
    Windows que não use UTF-8. Um arquivo salvo **com BOM** tem a primeira linha recusada
    (`CamposInvalidos` se o primeiro registro for um comentário, ou `NumeroInvalido` se for
    uma partida), porque o BOM fica grudado no primeiro campo. O arquivo deve ser salvo
    como UTF-8 sem BOM ou ASCII.
11. **O arquivo é lido inteiro na memória** antes do processamento. Isso é necessário para que
    os erros de leitura sejam capturados pelo `try`.
12. **Detalhes numéricos.** Zeros à esquerda são aceitos (`007` vale 7), e o sinal `+` não é
    aceito. `formatarDecimal` usa `round`, que arredonda para o par mais próximo
    (`0.125` → `0,12`). Isso só afeta a exibição, nunca os cálculos.

## 9. Ambiente e dependências

- **Linguagem:** Haskell 2010, sem extensões.
- **Compilador:** GHC 9.10.3 local, instalado via GHCup (Windows 11). O playground não foi usado.
- **Bibliotecas:** apenas a `base`:
  - `Data.List`, `Data.Char`, `Data.Maybe`, `Data.Either`, `Data.Ord` e `Text.Read`, nas camadas;
  - `System.Environment` e `Control.Exception`, só no `main`, para a leitura opcional de arquivo;
  - `System.Exit`, só nos testes, para o código de saída.
- **Avisos:** nenhum, com `-Wall`. O código também passa por
  `-Werror -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns -Wpartial-fields
  -Wredundant-constraints -Wmissing-export-lists`.
- **Validação local da revisão:** 86 testes aprovados no executável compilado. A instalação
  ativa do Clang estava incompleta; o README registra as opções usadas para aproveitar a cópia
  completa do cache, sem alterar o ambiente.
- **Versionamento:** Git e GitHub. As convenções estão em `docs/contribuicao.md`.

## 10. Histórico de decisões

| ID | Decisão | Justificativa | Status |
|---|---|---|---|
| D01 | Organizar o sistema em três camadas (módulos) | Separação de responsabilidades e testes por camada | Implementada |
| D02 | Tipos algébricos e *records*; `Linha` só com contagens | Clareza; pontos e saldo nunca ficam inconsistentes | Implementada |
| D03 | Funções de ordem superior, sem recursão explícita | Requisito da Camada 2; os padrões de recursão têm nome | Implementada |
| D04 | `Maybe` e `Either` para ausência e erros | Funções totais, sem exceções | Implementada |
| D05 | Dataset real separado do campeonato controlado da equipe | Atender à issue #03 e preservar os testes conferidos à mão | Implementada |
| D06 | Pontos, vitórias, saldo, gols pró, confronto direto e ordem alfabética | Aplicar os critérios disponíveis; cartões e sorteio permanecem como limitação | Implementada com adaptação |
| D07 | `foldr` em `linhaDoTime` | No `Prelude` de toda versão do GHC; soma associativa | Implementada |
| D08 | `Erro` com `RodadaInvalida` e `TimeVazio`, além dos 5 exigidos | Mensagens precisas para rodada ≤ 0 e nome em branco | Implementada |
| D09 | Validação numérica estrita (algarismos, `Integer` e limite de `Int`) | `readMaybe` sozinho aceitava `(3)` e `0x10` e estourava `Int` | Implementada |
| D10 | Saída somente em ASCII | A codificação CP437 derrubava o programa ao imprimir `ã` | Implementada |
| D11 | Leitura opcional de arquivo pelo `main`, com `try` | Usar `data/teste.txt` sem violar a regra de nenhuma exceção | Implementada |
| D12 | Lista `criterios` nomeada e `criterioDecisivo` | Fonte única dos critérios; explica cada desempate | Implementada |
