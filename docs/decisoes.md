# Decisões de Modelagem e Limitações

## 1. Visão Geral

O **Brasileirão Analytics** é um sistema desenvolvido em Haskell para calcular a tabela de classificação de campeonatos de futebol a partir dos resultados das partidas.

O projeto utiliza conceitos de programação funcional, como tipos algébricos, funções de ordem superior e tratamento de erros com `Maybe` e `Either`.

## 2. Decisões de Arquitetura

O sistema está organizado em três camadas:

| Camada | Módulo | Responsabilidade |
|---|---|---|
| 1 — Tipos e Dados | `Tipos.hs` | Representação dos times, partidas e resultados |
| 2 — Classificação | `Classificacao.hs` | Cálculos de classificação e estatísticas |
| 3 — Leitura e Validação | `Leitura.hs` | Interpretação dos dados e tratamento de erros |

Os módulos `Dados.hs` e `Main.hs` são responsáveis, respectivamente, pelos dados de teste e pela execução principal.

**Justificativa:** a separação em módulos facilita a manutenção, os testes e a reutilização das funções.

## 3. Decisões de Modelagem

### 3.1 Representação dos dados

- `Time`: definido como sinônimo de `String`.
- `Resultado`: tipo algébrico com `Vitoria`, `Empate` e `Derrota`.
- `Partida`: record contendo rodada, mandante, visitante e placares.
- `Linha`: record contendo os dados de classificação de cada time.

**Justificativa:** tipos algébricos e records permitem representar os dados com clareza e reduzir erros de manipulação.

### 3.2 Cálculo da classificação

A classificação seguirá o sistema de pontuação:

- Vitória: 3 pontos.
- Empate: 1 ponto.
- Derrota: 0 pontos.

Serão utilizadas funções de ordem superior, como `map`, `filter` e `foldl` ou `foldr`, sem recursão explícita na Camada 2.

**Critérios de desempate:** a definir conforme o regulamento do campeonato selecionado.

**Justificativa:** utilizar funções de ordem superior permite realizar cálculos sobre listas de forma declarativa, conforme os princípios da programação funcional.

### 3.3 Leitura e tratamento de erros

A leitura utilizará `Either` para representar operações que podem falhar e `Maybe` para resultados opcionais.

A conversão de valores numéricos utilizará `readMaybe`, evitando exceções causadas por entradas inválidas.

**Justificativa:** essas abordagens permitem tratar falhas de forma explícita e segura.

## 4. Fonte de Dados

**Campeonato:** Campeonato Brasileiro Série A — 2024.

**Formato:** CSV, com campos separados por ponto e vírgula (`;`).

**Campos:**
- Rodada
- Time mandante
- Gols do mandante
- Gols do visitante
- Time visitante

**Fonte do dataset:** a definir.

Será utilizado um conjunto separado de partidas para garantir a cobertura dos casos de teste obrigatórios.

## 5. Limitações Conhecidas

- O sistema será executado pelo terminal, sem interface gráfica.
- O processamento será voltado a campeonatos de futebol.
- Os dados deverão seguir o formato de entrada estabelecido.
- A aplicação não realizará atualização automática dos resultados pela internet.
- Outras limitações serão documentadas durante o desenvolvimento.

## 6. Ambiente e Dependências

- **Linguagem:** Haskell
- **Compilador:** GHC
- **Ambiente:** execução local
- **Bibliotecas:** biblioteca padrão (`base`)
- **Versionamento:** Git e GitHub

## 7. Histórico de Decisões

| ID | Decisão | Justificativa | Status |
|---|---|---|---|
| D01 | Organizar o sistema em três camadas | Separação de responsabilidades | Definida |
| D02 | Utilizar tipos algébricos e records | Clareza e segurança dos dados | Definida |
| D03 | Utilizar funções de ordem superior | Atender aos princípios funcionais | Definida |
| D04 | Utilizar `Maybe` e `Either` | Tratamento seguro de erros | Definida |
| D05 | Utilizar dados do Brasileirão 2024 | Trabalhar com resultados reais | Planejada |
| D06 | Definir critérios de desempate | Garantir a ordenação correta | Pendente |

---

*Este documento será atualizado conforme as decisões técnicas forem implementadas e validadas pela equipe.*
