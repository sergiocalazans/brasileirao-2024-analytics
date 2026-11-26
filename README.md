# Brasileirão Analytics

Este projeto foi desenvolvido para o PjBL 2 da disciplina de **Programação Lógica e Funcional da PUCPR**. O programa lê os resultados de partidas de futebol, calcula a tabela de classificação e apresenta algumas estatísticas do campeonato. Todo o código foi escrito em Haskell, sem recursão explícita na camada de cálculo.

Os times são ordenados por pontos, vitórias, saldo de gols, gols marcados e confronto direto. O programa pode usar um campeonato de teste, definido no próprio código, ou ler os resultados de um arquivo, como os da Série A de 2024.

**Ambiente utilizado:** GHC instalado localmente (o playground online não foi utilizado). O projeto foi testado com o GHC 9.10.3, no Ubuntu pelo WSL 2, e com o GHC 9.4.7, no Linux. Apenas a biblioteca padrão `base` é utilizada.

## Integrantes

| Integrante | GitHub                                              |
| ---------- | --------------------------------------------------- |
| Sérgio     | [sergiocalazans](https://github.com/sergiocalazans) |
| Glaucia    | [Glaucia05](https://github.com/Glaucia05)           |
| Nicolly    | [ly-ubimyy](https://github.com/ly-ubimyy)           |
| Gustavo    | [GMizuguti](https://github.com/GMizuguti)           |

A divisão das tarefas e a forma como o trabalho foi realizado estão descritas em [docs/contribuicao.md](docs/contribuicao.md).

## Como executar

Todos os comandos devem ser executados na raiz do repositório.

```bash
# Executa com o campeonato de teste definido em src/Dados.hs
runghc -isrc src/Main.hs

# Executa a partir de um arquivo
runghc -isrc src/Main.hs data/campeonato-teste.csv
runghc -isrc src/Main.hs data/brasileirao-2024.csv

# Executa os testes
runghc -isrc tests/Testes.hs
```

### Compilação

```bash
mkdir -p build
ghc -Wall -Werror -isrc -outputdir build/app    src/Main.hs     -o build/brasileirao
ghc -Wall -Werror -isrc -outputdir build/testes tests/Testes.hs -o build/testes

./build/testes
./build/brasileirao data/brasileirao-2024.csv
```

No Windows, os executáveis são gerados com a extensão `.exe`. Caso ocorra algum erro inesperado ao trocar de ambiente, recomendamos apagar a pasta `build/` ou compilar com a opção `-fforce-recomp`.

### Uso no GHCi

```bash
ghci -isrc src/Main.hs
```

Dentro do GHCi:

```haskell
:main data/teste.txt
:module + Tipos Classificacao Leitura Dados
-- Lista os times na ordem da classificação após a rodada 3
fmap (map time . classificacao . ateRodada 3) (lerCampeonato dadosCampeonato)
```

## Exemplo de saída

```text
Camada 2 - Classificacao final
  Pos  Time           Pts   J   V   E   D   GP   GC   SG    Aprov
    1  Botafogo        10   5   3   1   1   10    5   +5   66,67%
    2  Palmeiras        9   5   3   0   2    8    5   +3   60,00%
    3  Fortaleza        7   5   2   1   2    5    7   -2   46,67%
    4  Flamengo         7   5   1   4   0    8    6   +2   46,67%
    5  Internacional    4   5   1   1   3    7   11   -4   26,67%
    6  Cruzeiro         4   5   1   1   3    5    9   -4   26,67%
  * Fortaleza fica a frente de Flamengo (ambos com 7 pontos): desempate por vitorias
  * Internacional fica a frente de Cruzeiro (ambos com 4 pontos): desempate por gols marcados
```

Ao ser executado, o programa apresenta, nesta ordem:

1. os times e os resultados de cada um;
2. a classificação final;
3. a classificação após a rodada 3;
4. as estatísticas do campeonato (total de gols, média e maior goleada);
5. o comportamento com um campeonato vazio;
6. o tratamento de uma entrada com erros, mostrando o primeiro erro e o relatório completo.

## Formato dos dados

Cada linha representa uma partida, com cinco campos separados por ponto e vírgula. Linhas em branco e linhas iniciadas por `#` são ignoradas.

```text
# rodada;mandante;gols mandante;gols visitante;visitante
1;Botafogo;1;2;Palmeiras
1;Flamengo;0;0;Cruzeiro
```

Uma entrada inválida nunca encerra o programa com erro. Nesses casos, o programa informa a linha ou a rodada do problema, como em `Linha 3: "dois" nao e um numero inteiro`.

## Estrutura do projeto

```text
├── src/
│   ├── Tipos.hs          Camada 1: tipos e consultas sobre as partidas
│   ├── Classificacao.hs  Camada 2: pontuação, classificação, desempates e estatísticas
│   ├── Leitura.hs        Camada 3: leitura, validação, erros e formatação
│   ├── Dados.hs          campeonato de teste e entradas de exemplo
│   └── Main.hs           demonstração das três camadas (único módulo com IO)
├── tests/
│   └── Testes.hs         testes com resultados esperados
├── data/
│   ├── campeonato-teste.csv   o mesmo campeonato de Dados.hs, em arquivo
│   ├── teste.txt              cópia do arquivo anterior, usada no teste de leitura de .txt
│   └── brasileirao-2024.csv   resultados da Série A de 2024 (380 partidas)
├── docs/
│   ├── decisoes.md       decisões de modelagem e limitações conhecidas
│   └── contribuicao.md   divisão das tarefas e convenções do repositório
├── .github/
│   └── pull_request_template.md
├── LICENSE
└── README.md
```

## Testes

```bash
runghc -isrc tests/Testes.hs
```

A execução deve terminar com a mensagem `119 de 119 testes passaram.` Caso algum teste falhe, o programa encerra com código de saída 1.

A tabela abaixo indica qual teste atende a cada caso obrigatório da Seção 7 do enunciado:

| Caso obrigatório                                              | Teste correspondente                                               |
| ------------------------------------------------------------- | ------------------------------------------------------------------ |
| `resultadoPara` do mandante, do visitante e de quem não jogou | `resultadoPara o mandante...`, `...o visitante...`, `...e Nothing` |
| `times` sem repetição                                         | `times do campeonato de teste: sem repeticao...`                   |
| Classificação completa conferida à mão                        | `classificacao completa do campeonato de teste`                    |
| Empate em pontos decidido por um critério                     | `Fortaleza x Flamengo (7 pts): decide o numero de vitorias`        |
| `ateRodada 3` diferente da classificação final                | `a tabela da rodada 3 e diferente da final`                        |
| `maiorGoleada []` e `mediaGols []`                            | `maiorGoleada [] e Nothing`, `mediaGols [] e Nothing`              |
| `lerCampeonato` com entrada válida devolvendo `Right`         | `lerCampeonato sobre a entrada valida devolve Right...`            |
| Um teste para cada construtor de `Erro`                       | grupo "Camada 3"                                                   |
| `todosOsErros` com três ou mais linhas inválidas              | `todosOsErros lista os 7 erros da entrada com erros`               |

## Requisitos do PjBL 2

| Requisito                                                    | Arquivo                |
| ------------------------------------------------------------ | ---------------------- |
| Tipos algébricos, records e consultas                        | `src/Tipos.hs`         |
| Campeonato de teste com 6 times e 5 rodadas                  | `src/Dados.hs`         |
| Classificação com `map`, `filter`, `foldr`, `(.)` e `sortBy` | `src/Classificacao.hs` |
| `Either` com `do`, `traverse`, `readMaybe` e `todosOsErros`  | `src/Leitura.hs`       |
| Demonstração das três camadas                                | `src/Main.hs`          |
| Testes                                                       | `tests/Testes.hs`      |
| Decisões de modelagem e limitações                           | `docs/decisoes.md`     |

## Documentação

- [docs/decisoes.md](docs/decisoes.md): decisões de modelagem, critérios de desempate, origem dos dados de 2024, organização dos testes e limitações conhecidas.
- [docs/contribuicao.md](docs/contribuicao.md): divisão das tarefas entre os integrantes e convenções de branches, commits e pull requests.
