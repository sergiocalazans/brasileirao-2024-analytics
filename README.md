# Brasileirão Analytics — Tabela de Classificação em Haskell

O Brasileirão Analytics é um projeto da disciplina de Programação Lógica e Funcional. O programa recebe os resultados de partidas de futebol, calcula a classificação dos times e apresenta estatísticas do campeonato.

O trabalho foi dividido em três camadas: tipos e dados, cálculos da classificação e leitura com validação. Além do campeonato de teste, utilizamos os resultados da Série A de 2024 para conferir os cálculos com uma tabela real.

## Integrantes

| Integrante | GitHub                                              |
| ---------- | --------------------------------------------------- |
| Sérgio     | [sergiocalazans](https://github.com/sergiocalazans) |
| Glaucia    | [Glaucia05](https://github.com/Glaucia05)           |
| Nicolly    | [ly-ubimyy](https://github.com/ly-ubimyy)           |
| Gustavo    | [GMizuguti](https://github.com/GMizuguti)           |

## Organização dos arquivos

```text
projeto/
├── src/
│   ├── Tipos.hs
│   ├── Classificacao.hs
│   ├── Leitura.hs
│   ├── Dados.hs
│   └── Main.hs
├── tests/
│   └── Testes.hs
├── data/
│   ├── brasileirao-2024.csv
│   ├── campeonato-teste.csv
│   └── teste.txt
├── docs/
│   ├── decisoes.md
│   └── contribuicao.md
└── README.md
```

Cada módulo tem uma responsabilidade:

| Arquivo            | Responsabilidade                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------------------- |
| `Tipos.hs`         | Define os tipos `Time`, `Resultado`, `Partida` e `Linha`, além das consultas básicas sobre as partidas. |
| `Classificacao.hs` | Calcula pontos, classificação, desempates e estatísticas usando funções de ordem superior.              |
| `Leitura.hs`       | Lê e valida os dados, informa erros e formata a tabela para exibição.                                   |
| `Dados.hs`         | Guarda o campeonato de teste e exemplos de entradas válidas e inválidas.                                |
| `Main.hs`          | Reúne as funcionalidades e apresenta a demonstração do projeto.                                         |
| `Testes.hs`        | Executa os testes das três camadas e dos arquivos CSV.                                                  |

## Como executar

Utilizamos o **GHC 9.10.3**, com validação no **Ubuntu 26.04.1 LTS pelo WSL 2**. O projeto usa apenas a biblioteca padrão `base`.

Execute os comandos na raiz do repositório.

### Execução direta

```bash
runghc -isrc src/Main.hs
```

Esse comando utiliza o campeonato definido em `Dados.hs`. Para ler um arquivo, informe o caminho:

```bash
runghc -isrc src/Main.hs data/campeonato-teste.csv
runghc -isrc src/Main.hs data/brasileirao-2024.csv
```

Os testes também podem ser executados diretamente:

```bash
runghc -isrc tests/Testes.hs
```

### Compilação

No Linux ou WSL:

```bash
mkdir -p build

ghc -fforce-recomp -Wall -Werror -isrc \
  -outputdir build/obj-app \
  src/Main.hs -o build/brasileirao

ghc -fforce-recomp -Wall -Werror -isrc \
  -outputdir build/obj-testes \
  tests/Testes.hs -o build/testes

./build/testes
./build/brasileirao data/brasileirao-2024.csv
```

A opção `-isrc` indica onde estão os módulos. `-Wall` habilita os avisos do compilador e `-Werror` trata esses avisos como erros. A recompilação completa (`-fforce-recomp`) evita o reaproveitamento de arquivos de compilação antigos.

No Windows, os executáveis gerados possuem a extensão `.exe`. A instalação nativa utilizada durante o desenvolvimento apresentou problemas com o Clang; por isso, a validação final foi realizada no WSL. Não foi feita uma validação equivalente no playground online.

### Usando o GHCi

```bash
ghci -isrc src/Main.hs
```

Dentro do GHCi:

```haskell
:main
:main data/teste.txt
:module + Tipos Classificacao Leitura Dados
fmap (map time . classificacao . ateRodada 3) (lerCampeonato dadosCampeonato)
```

## Formato dos dados

As partidas são informadas em texto, com cinco campos separados por ponto e vírgula:

```text
# rodada;mandante;gols mandante;gols visitante;visitante
1;Botafogo;1;2;Palmeiras
1;Flamengo;0;0;Cruzeiro
```

O programa ignora linhas vazias e comentários iniciados por `#`. Também remove espaços nas extremidades dos campos.

Se encontrar um dado inválido, como um placar escrito por extenso, um número negativo ou um time escalado duas vezes na mesma rodada, o programa apresenta uma mensagem com a linha ou rodada do problema.

## O que o programa apresenta

A execução demonstra as três camadas na ordem prevista no trabalho:

1. **Tipos e consultas:** lista os times e os resultados de cada um.
2. **Classificação:** apresenta a tabela final e explica os desempates em pontos.
3. **Tabela intermediária:** mostra a situação do campeonato após parte das rodadas.
4. **Estatísticas:** calcula o total e a média de gols e identifica a maior goleada.
5. **Tratamento de erros:** demonstra a leitura de um campeonato vazio e de uma entrada inválida.

A tabela contém posição, time, pontos, jogos, vitórias, empates, derrotas, gols pró, gols contra, saldo e aproveitamento.

## Campeonatos utilizados

### Campeonato de teste

Criamos um campeonato fictício com seis times, cinco rodadas e quinze partidas. Ele está em `src/Dados.hs` e em `data/campeonato-teste.csv`. O arquivo `data/teste.txt` contém a mesma entrada e foi mantido para comparação.

Os resultados foram escolhidos para atender aos casos exigidos pelo enunciado e facilitar a conferência dos cálculos:

| Situação                      | Exemplo                                                                                |
| ----------------------------- | -------------------------------------------------------------------------------------- |
| Empate em 0 a 0               | Flamengo 0 x 0 Cruzeiro, rodada 1                                                      |
| Vitória por três ou mais gols | Palmeiras 4 x 0 Cruzeiro                                                               |
| Desempate por vitórias        | Fortaleza e Flamengo terminam com 7 pontos, mas o Fortaleza tem mais vitórias          |
| Desempate por gols marcados   | Internacional fica à frente do Cruzeiro após empatarem em pontos, vitórias e saldo     |
| Desempate por saldo           | Após a rodada 3, Palmeiras e Botafogo têm 6 pontos e 2 vitórias, mas saldos diferentes |
| Mudança na liderança          | Palmeiras lidera na rodada 3; Botafogo termina em primeiro                             |

### Brasileirão 2024

O arquivo `data/brasileirao-2024.csv` reúne **380 partidas, 20 clubes e 38 rodadas** da Série A de 2024.

Os resultados foram obtidos do projeto [Brasileirão Dataset](https://github.com/leeofernandes1980/brasileirao-dataset/blob/de69fdc5fa0f2b88c20d0a28fe2b769bdff197b9/dashboard/public/data/json/partidas_resumo.json), que identifica seus registros de 2024 como provenientes do Sofascore (consulta em 25/11/2026). Selecionamos a temporada de 2024, ordenamos as partidas por rodada e identificador e mantivemos apenas os cinco campos necessários.

Comparamos a classificação final calculada com a [tabela divulgada pela CBF](https://www.cbf.com.br/futebol-brasileiro/tabelas/campeonato-brasileiro/serie-a/2024). O resultado inclui o Botafogo com 79 pontos e um total de 929 gols no campeonato.

A tabela parcial considera o número da rodada, e não a data em que cada jogo aconteceu. Assim, partidas adiadas permanecem na rodada à qual pertencem.

## Classificação e desempates

A função obrigatória `classificacao :: [Partida] -> [Linha]` ordena os times por:

1. Pontos;
2. Número de vitórias;
3. Saldo de gols;
4. Gols marcados;
5. Confronto direto, quando aplicável.

O confronto direto considera os dois jogos entre os clubes e só é usado quando exatamente dois times estão empatados em pontos. Quando há três ou mais clubes nessa situação, o critério não é aplicado.

Se todos os critérios disponíveis continuarem iguais, a função usa a ordem alfabética para apresentar a tabela de maneira estável. **Essa ordem não é um critério oficial da CBF.**

Como complemento, criamos `classificacaoComDisciplina`, que recebe registros de cartões por clube e rodada. Ela pode usar o menor número de cartões vermelhos e depois amarelos, desde que existam dados válidos para todos os clubes envolvidos no desempate. A ausência de registros é tratada como informação indisponível, e não como zero cartões. O sistema também identifica situações que dependem de sorteio, mas não realiza o sorteio.

Essa extensão é testada separadamente. O `main` continua usando a função obrigatória `classificacao` e o CSV original de cinco campos. Não incluímos uma base real de cartões por rodada, pois os dados dos testes disciplinares são fictícios. Portanto, o programa **não reproduz todos os critérios do regulamento oficial em qualquer situação**, embora a classificação final calculada para 2024 coincida com a da CBF.

As justificativas para essas escolhas estão em [docs/decisoes.md](docs/decisoes.md).

## Testes

O arquivo [tests/Testes.hs](tests/Testes.hs) reúne **119 testes**, divididos da seguinte forma:

| Grupo                   |  Testes | O que foi verificado                                                                |
| ----------------------- | ------: | ----------------------------------------------------------------------------------- |
| Camada 1                |      14 | Tipos, resultados das partidas, consultas e campeonato de teste                     |
| Camada 2                |      29 | Pontuação, classificação, estatísticas, desempates e listas vazias                  |
| Camada 3                |      37 | Leitura, conversões, construtores de `Erro`, relatório de erros e formatação        |
| Desempates e disciplina |      31 | Confronto direto, cartões válidos ou ausentes, dados incompletos e sorteio pendente |
| Integração dos arquivos |       8 | Leitura dos CSVs, classificação real e resultados esperados                         |
| **Total**               | **119** |                                                                                     |

Na validação registrada em 25/11/2026, os **119 testes passaram** tanto no executável compilado quanto com `runghc`. Também foram verificados **dez cenários de integração**, incluindo arquivos válidos, vazios, inválidos, inexistentes, nomes acentuados e bytes inválidos.

Para executar novamente:

```bash
runghc -isrc tests/Testes.hs
```

O resultado esperado termina com:

```text
119 de 119 testes passaram.
```

Se algum teste falhar, o programa de testes retorna um código de saída diferente de zero.

## Relação com os requisitos do PjBL2

| Requisito                                                     | Implementação          |
| ------------------------------------------------------------- | ---------------------- |
| Tipos algébricos e records                                    | `src/Tipos.hs`         |
| Consultas sobre partidas                                      | `src/Tipos.hs`         |
| Campeonato com seis times e cinco rodadas                     | `src/Dados.hs`         |
| Classificação, estatísticas e funções de ordem superior       | `src/Classificacao.hs` |
| Leitura com `Maybe`, `Either`, `do`, `traverse` e `readMaybe` | `src/Leitura.hs`       |
| Relatório completo de erros e tabela formatada                | `src/Leitura.hs`       |
| Demonstração das três camadas                                 | `src/Main.hs`          |
| Testes com resultados esperados                               | `tests/Testes.hs`      |
| Justificativas e limitações                                   | `docs/decisoes.md`     |

## Limitações conhecidas

- A classificação principal não recebe cartões disciplinares. Por isso, em empates não resolvidos pelos resultados das partidas, a ordem alfabética é usada somente para exibição.
- Os nomes dos times são comparados exatamente como aparecem no arquivo. Diferenças de maiúsculas, minúsculas ou acentos podem representar times diferentes.
- O programa não exige rodadas consecutivas nem verifica se todos os clubes jogaram o mesmo número de vezes.
- Os times que ainda não disputaram partidas não aparecem na tabela intermediária.
- Os dados de entrada devem ser salvos em UTF-8 sem BOM ou ASCII. A saída do programa foi mantida em ASCII para evitar problemas de codificação observados no console Windows usado no desenvolvimento.
- O arquivo inteiro é carregado na memória antes da análise. Essa escolha atende ao volume do projeto, mas não foi pensada para bases muito maiores.

Outras decisões de implementação estão explicadas em [docs/decisoes.md](docs/decisoes.md).

## Referências

- [CBF — Campeonato Brasileiro Série A 2024](https://www.cbf.com.br/futebol-brasileiro/tabelas/campeonato-brasileiro/serie-a/2024)
- [Brasileirão Dataset — dados das partidas de 2024](https://github.com/leeofernandes1980/brasileirao-dataset/blob/de69fdc5fa0f2b88c20d0a28fe2b769bdff197b9/dashboard/public/data/json/partidas_resumo.json)
- [GHC — Glasgow Haskell Compiler](https://www.haskell.org/ghc/)
