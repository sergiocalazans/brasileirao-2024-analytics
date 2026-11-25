# Decisões de Modelagem e Limitações

Este documento reúne as principais escolhas feitas no desenvolvimento do Brasileirão Analytics. A intenção é explicar como organizamos o código, por que utilizamos determinadas funções do Haskell e quais situações o programa ainda não cobre.

## 1. Organização do projeto

Dividimos o projeto em três camadas, como solicitado no PjBL2.

| Camada              | Arquivo            | Responsabilidade                                                        |
| ------------------- | ------------------ | ----------------------------------------------------------------------- |
| 1 — Tipos e dados   | `Tipos.hs`         | Representar partidas, times e resultados                                |
| 2 — Classificação   | `Classificacao.hs` | Calcular a tabela, os desempates e as estatísticas                      |
| 3 — Leitura e saída | `Leitura.hs`       | Converter o texto de entrada, validar os dados e formatar os resultados |

Além dessas camadas, `Dados.hs` contém o campeonato fictício e as entradas de exemplo. `Main.hs` reúne as funcionalidades e mostra o relatório no terminal.

Procuramos deixar os cálculos fora do `main`. Assim, as funções recebem dados e devolvem resultados sem depender da leitura de arquivos ou da impressão no terminal. Isso também facilita os testes.

## 2. Tipos e representação dos dados

### Tipos algébricos

Usamos `type Time = String` porque é a representação pedida no trabalho. Para os resultados das partidas, criamos o tipo `Resultado` com os construtores `Vitoria`, `Empate` e `Derrota`.

Essa escolha permite representar os três resultados possíveis sem depender de textos como `"V"` ou `"D"`. Também facilita o tratamento de cada caso por casamento de padrões.

### Records

`Partida` e `Linha` foram definidos como _records_. Preferimos essa estrutura porque os nomes dos campos deixam o código mais fácil de ler.

Em uma tupla, seria possível trocar dois valores inteiros sem que o compilador percebesse. Os records ajudam a entender o papel de cada campo, embora não impeçam, sozinhos, toda troca de valores do mesmo tipo.

A `Linha` guarda jogos, vitórias, empates, derrotas, gols pró e gols contra. Pontos, saldo e aproveitamento são calculados pelas funções da Camada 2, evitando manter esses valores duplicados.

### Consultas sobre partidas

`participou` verifica se um time aparece como mandante ou visitante. As funções `golsMarcados` e `golsSofridos` consultam o placar do ponto de vista do clube informado.

Em `resultadoPara`, utilizamos `Maybe Resultado`. Quando o clube participou, a função devolve `Just` com o resultado. Caso contrário, devolve `Nothing`. Consideramos essa resposta mais adequada do que usar uma derrota ou outro valor para indicar ausência de partida.

Para obter a lista de clubes, `times` reúne mandantes e visitantes, remove repetições com `nub` e ordena os nomes com `sort`.

## 3. Cálculos da classificação

### Funções de ordem superior

O enunciado não permite recursão explícita na Camada 2. Por isso, usamos principalmente `map`, `filter`, `foldr`, `sortBy` e composição com `(.)`.

A função `linhaDoTime` primeiro seleciona as partidas de um clube com `filter` e depois acumula os resultados com `foldr`, começando por uma linha zerada.

Escolhemos `foldr` porque funciona bem nesse cálculo, não precisa de dependências adicionais e é simples de acompanhar. Como cada time disputa poucas dezenas de jogos, a diferença prática em relação a outras dobras não é relevante para o projeto.

### Pontos, saldo e aproveitamento

A função `pontos` centraliza a pontuação de cada resultado: três por vitória, um por empate e zero por derrota. `pontosLinha` utiliza essa função para calcular o total do clube.

O saldo é a diferença entre gols marcados e sofridos. Já o aproveitamento considera a proporção de pontos conquistados em relação aos pontos disputados. Utilizamos `fromIntegral` para realizar a divisão com `Double`.

Quando um time não disputou partidas, `aproveitamento` retorna zero, evitando a divisão por zero.

### Ordenação e desempates

A classificação é ordenada com `sortBy`, usando `comparing`, `Down` e a combinação de valores `Ordering` com `<>`.

A ordem aplicada pela função obrigatória `classificacao` é:

1. Pontos;
2. Vitórias;
3. Saldo de gols;
4. Gols marcados;
5. Confronto direto, quando aplicável;
6. Ordem alfabética para apresentação, caso o empate continue.

A ordem alfabética **não faz parte dos critérios oficiais de desempate da CBF**. Ela foi mantida para que a tabela tenha uma ordem estável quando os dados de entrada não permitem decidir todas as posições.

O confronto direto só é considerado quando existem exatamente dois clubes empatados em pontos e os dois jogos entre eles, um em cada mando. Nesse caso, utilizamos o resultado agregado. Quando há três ou mais clubes empatados em pontos, o confronto direto não é aplicado.

Organizamos os critérios em listas de comparações nomeadas. Isso permite usar a mesma lógica para ordenar a tabela e explicar qual critério decidiu a posição de um clube.

### Cartões e sorteio

Acrescentamos uma funcionalidade complementar para tratar cartões disciplinares, sem alterar a assinatura obrigatória:

```haskell
classificacao :: [Partida] -> [Linha]
```

A função `classificacaoComDisciplina` recebe também uma lista de `RegistroCartoes`, contendo rodada, clube, cartões vermelhos e amarelos. Ela permite comparar primeiro o número de cartões vermelhos e depois o de amarelos, quando os critérios anteriores não resolvem o empate.

Nessa parte, utilizamos `Maybe Int` para distinguir duas situações:

- `Just 0`: existe um registro válido informando zero cartões;
- `Nothing`: não há informação suficiente ou algum registro é inválido.

Os registros são verificados quanto a números negativos, rodadas inválidas, nomes vazios, duplicações e estouro da soma. Para comparar os clubes por cartões, exigimos dados de todas as partidas relevantes para o grupo empatado. Essa verificação evita comparações inconsistentes entre alguns clubes do grupo.

Em tabelas parciais, só entram cartões das rodadas presentes na lista de partidas. Portanto, não utilizamos cartões de jogos futuros.

O tipo `StatusDesempate` identifica se houve um critério decisivo, se o confronto direto está incompleto, se faltam dados disciplinares ou se o empate depende de sorteio. **Não realizamos um sorteio nem inventamos seu resultado.**

Essa funcionalidade é usada nos testes e pode ser chamada diretamente em Haskell. O `main` continua utilizando o CSV de cinco campos e a função `classificacao`. Não foi incluída uma base real de cartões por rodada, e os registros disciplinares dos testes são fictícios. A classificação final calculada para 2024 corresponde à tabela divulgada pela CBF, mas isso não significa que todos os critérios oficiais possam ser reproduzidos com qualquer conjunto de dados.

### Listas vazias e estatísticas

`maiorGoleada` e `mediaGols` retornam `Maybe` porque não existe maior goleada nem média de gols quando a lista está vazia.

Em `maiorGoleada`, utilizamos um `foldr` iniciado com `Nothing`. Quando duas partidas têm a mesma diferença de gols, a função mantém a primeira da lista.

`mediaGols []` devolve `Nothing`, evitando divisão por zero. Para consultar uma tabela intermediária, utilizamos `ateRodada` antes de chamar `classificacao`.

## 4. Leitura e validação

### Entrada e separação dos campos

Cada partida é descrita por cinco campos separados por ponto e vírgula. A função `separar` utiliza `foldr` para dividir a linha e preservar campos vazios.

Ignoramos linhas em branco e comentários iniciados por `#`. Os espaços nas extremidades dos campos também são removidos, inclusive o caractere `\r`, comum em arquivos do Windows.

Mantemos a numeração original das linhas para que os erros indiquem a posição correta no arquivo, mesmo quando existem comentários ou linhas vazias.

### Conversão de números

A função `lerInteiro` utiliza `readMaybe`, e não `read`, para evitar exceções em entradas como `dois` ou `2a`.

Antes da conversão, verificamos se o texto contém somente algarismos, com sinal negativo opcional. A leitura é feita como `Integer` e só depois convertida para `Int`, desde que o número esteja dentro do intervalo permitido.

Essa validação também impede que formatos como `(3)` ou `0x10`, que podem ser aceitos como literais Haskell, sejam tratados como placares válidos.

Mantivemos o sinal negativo na leitura para que valores como `-1` sejam reconhecidos e possam gerar mensagens específicas de placar ou rodada inválida.

### `Either` e relatório de erros

`lerPartida` utiliza um bloco `do` com `Either`. Cada validação pode devolver `Left Erro`, interrompendo o processamento da linha no primeiro problema.

`lerCampeonato` utiliza `traverse` para processar as partidas e depois confere se algum clube aparece mais de uma vez na mesma rodada.

Criamos também `todosOsErros`, porque o trabalho exige um relatório completo. Diferentemente de `lerCampeonato`, essa função reúne os problemas independentes encontrados no texto. Assim, uma mesma linha pode apresentar, por exemplo, um número inválido e um confronto do time contra ele próprio.

Os construtores obrigatórios de `Erro` são:

- `CamposInvalidos`;
- `NumeroInvalido`;
- `PlacarNegativo`;
- `MesmoTime`;
- `TimeRepetidoNaRodada`.

Acrescentamos `RodadaInvalida` e `TimeVazio` para dar mensagens mais específicas nesses casos.

### Formatação

`tabelaFormatada` produz as colunas exigidas pelo enunciado e também apresenta gols pró, gols contra e aproveitamento. As colunas são descritas por título, largura e função de formatação, o que facilita mudanças na apresentação.

As mensagens impressas pelo programa foram mantidas em ASCII. Durante o desenvolvimento, encontramos um problema de codificação no console Windows, que não conseguia imprimir alguns caracteres acentuados. Essa decisão evita o problema nesse ambiente, embora os comentários e a documentação continuem escritos normalmente em português.

## 5. Campeonatos usados nos testes

### Campeonato controlado

Criamos um campeonato com seis clubes da Série A 2024, cinco rodadas e quinze partidas, organizado em turno único pelo método do círculo.

Escolhemos os placares para testar situações específicas:

- Um empate de 0 a 0 e vitórias com diferença de pelo menos três gols;
- Fortaleza e Flamengo empatados em pontos, com a posição decidida por vitórias;
- Internacional e Cruzeiro empatados em pontos, vitórias e saldo, com decisão pelos gols marcados;
- Palmeiras e Botafogo empatados após a terceira rodada, com decisão pelo saldo;
- Uma liderança intermediária diferente da classificação final.

O mesmo campeonato foi mantido em `Dados.hs`, `data/campeonato-teste.csv` e `data/teste.txt`. Com isso, conseguimos comparar a leitura dos arquivos com os valores definidos no código.

### Dados reais

Também utilizamos as 380 partidas do Brasileirão Série A 2024, registradas em `data/brasileirao-2024.csv`. A origem e a transformação dos dados estão indicadas no README.

Os testes verificam as partidas, a quantidade de clubes e rodadas, os gols marcados e as vinte linhas da classificação final, comparadas com a tabela publicada pela CBF.

## 6. Testes e ambiente de execução

Os **119 testes** estão organizados em cinco grupos: Camada 1 (14), Camada 2 (29), Camada 3 (37), desempates e disciplina (31) e integração dos arquivos (8).

Os testes cobrem as funções obrigatórias, os desempates, os construtores de `Erro`, entradas inválidas, listas vazias e os dois campeonatos utilizados no projeto.

Na revisão de 25/11/2026, a aplicação e os testes foram compilados com **GHC 9.10.3 no Ubuntu 26.04.1 LTS (WSL 2)**, usando `-Wall -Werror`. Os 119 testes foram aprovados, assim como dez cenários de integração. Esses são os resultados registrados na revisão; os comandos para reproduzi-los estão no README.

Na instalação nativa do Windows, encontramos problemas com o Clang. Também ocorreu uma falha ao reaproveitar arquivos de compilação antigos, resolvida com `-fforce-recomp`. Por isso, recomendamos recompilar os módulos ao alternar entre ambientes.

O projeto utiliza apenas a biblioteca `base`, com módulos como `Data.List`, `Data.Maybe`, `Data.Either`, `Data.Ord`, `Data.Char` e `Text.Read`. O `main` também usa `System.Environment` e `Control.Exception` para a leitura opcional de arquivos; os testes utilizam `System.Exit`.

## 7. Limitações conhecidas

1. **Desempate:** os arquivos de partidas não possuem cartões nem resultados de sorteio. A classificação principal apresenta empates restantes em ordem alfabética, sem afirmar que essa é a posição oficial.
2. **Nomes dos times:** `Flamengo` e `flamengo` são interpretados como nomes diferentes. A leitura remove apenas espaços nas extremidades.
3. **Estrutura das rodadas:** não verificamos se as rodadas são consecutivas, se todos os clubes disputam o mesmo número de jogos ou se dois clubes se enfrentam mais vezes do que deveriam.
4. **Tabela intermediária:** clubes que ainda não disputaram partidas não aparecem na classificação parcial.
5. **Validação:** as verificações de placar e escalação são aplicadas ao texto lido. Como o construtor `Partida` é exportado, outro módulo ainda pode criar valores inválidos diretamente.
6. **Relatório de erros:** `lerCampeonato` para no primeiro erro, enquanto `todosOsErros` identifica problemas independentes. Nem toda verificação pode ser feita quando um campo necessário é ilegível.
7. **Codificação:** a saída usa ASCII. Arquivos UTF-8 com BOM não são tratados automaticamente; nomes acentuados podem aparecer incorretamente em consoles Windows sem configuração adequada.
8. **Memória e desempenho:** o programa lê todo o arquivo antes de processá-lo. `nub` e `inits` também não são escolhas voltadas a bases com milhões de registros, embora atendam ao tamanho deste trabalho.
9. **Representação:** o campo `jogos` de `Linha` repete uma informação que poderia ser obtida por vitórias, empates e derrotas. Foi mantido porque aparece no enunciado.
10. **Valores numéricos:** zeros à esquerda são aceitos, mas o sinal `+` não. `formatarDecimal` utiliza o arredondamento de `round`, que afeta apenas a exibição.

## 8. Resumo das decisões

| Decisão                                        | Motivo                                                                 |
| ---------------------------------------------- | ---------------------------------------------------------------------- |
| Divisão em três camadas                        | Separar tipos, cálculos e validação, conforme o enunciado              |
| Records e tipos algébricos                     | Tornar os dados e os resultados mais claros                            |
| `Maybe` e `Either`                             | Tratar ausência de informação e erros sem valores artificiais          |
| `filter`, `map` e `foldr`                      | Trabalhar com listas sem recursão explícita                            |
| `sortBy`, `comparing`, `Down` e `<>`           | Aplicar critérios de classificação em ordem                            |
| Campeonato controlado e dataset real separados | Facilitar a conferência manual e a validação com resultados publicados |
| Cartões como extensão opcional                 | Preservar a assinatura obrigatória e não inventar dados disciplinares  |
| Validação numérica com `readMaybe` e `Integer` | Evitar exceções e estouro de `Int`                                     |
| Saída ASCII                                    | Evitar falhas de codificação observadas no console                     |
| Leitura opcional de arquivo                    | Permitir execução com `Dados.hs` e com CSV no GHC local                |
