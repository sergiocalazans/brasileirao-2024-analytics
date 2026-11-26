# Contribuição e Organização da Equipe

Este documento descreve como o trabalho foi dividido entre os integrantes, como ele aconteceu na prática e quais regras combinamos para usar o repositório. Os integrantes e seus perfis no GitHub estão listados no [README](../README.md#integrantes).

## 1. Divisão original das tarefas

No início do projeto, dividimos o trabalho nas tarefas abaixo, respeitando a dependência entre elas. As tarefas podiam ser feitas em paralelo, desde que as dependências já estivessem concluídas.

| #   | Responsável | Tarefa                                                | Depende de          |
| --- | ----------- | ----------------------------------------------------- | ------------------- |
| 1   | Sérgio      | Configurar a estrutura inicial do projeto             | —                   |
| 2   | Glaucia     | Implementar tipos algébricos e consultas básicas      | #1                  |
| 3   | Sérgio      | Preparar o dataset do Brasileirão 2024                | #1                  |
| 4   | Nicolly     | Implementar os cálculos da classificação              | #2                  |
| 5   | Sérgio      | Implementar estatísticas e classificação por rodada   | #4                  |
| 6   | Glaucia     | Implementar leitura e conversão de partidas           | #2                  |
| 7   | Nicolly     | Implementar relatório de erros e formatação da tabela | #4 e #6             |
| 8   | Gustavo     | Criar testes da classificação e das estatísticas      | #3, #4 e #5         |
| 9   | Gustavo     | Criar testes de validação e tratamento de erros       | #3, #6 e #7         |
| 10  | Sérgio      | Integrar as camadas e implementar o `Main.hs`         | #3, #5, #7, #8 e #9 |
| 11  | Gustavo     | Finalizar o README e a documentação técnica           | #3, #4, #6 e #10    |

## 2. Como o trabalho aconteceu na prática

Essa divisão serviu de base, mas grande parte do projeto acabou sendo desenvolvida em conjunto, durante as aulas. Escrevemos e testamos o código juntos e, ao final, enviamos o resultado ao repositório de uma só vez (commit `89eb5cf`). Por esse motivo, o histórico tem poucos commits e eles estão concentrados em poucas contas, sem refletir a participação individual de cada integrante.

Depois desse envio, alguns complementos foram feitos separadamente:

- a Glaucia implementou os critérios restantes de desempate (confronto direto e cartões), com seus testes;
- o Sérgio fez a revisão final do código e dos testes;
- a Nicolly e o Gustavo revisaram o README, o `decisoes.md` e este documento conforme o enunciado.

Todos acompanharam as decisões do projeto e conseguem explicar qualquer parte do código.

## 3. Convenções do repositório

### Branches

A branch `main` guarda a versão estável e integrada do projeto. As alterações são feitas em branches separadas e enviadas à `main` por meio de pull requests.

As branches seguem o padrão `tipo/descricao`:

| Tipo        | Finalidade                         |
| ----------- | ---------------------------------- |
| `feat/`     | Desenvolvimento de funcionalidades |
| `fix/`      | Correção de erros                  |
| `test/`     | Implementação de testes            |
| `docs/`     | Atualização da documentação        |
| `chore/`    | Configurações e manutenção         |
| `refactor/` | Refatoração do código              |

Exemplos usados no projeto: `chore/setup`, `fix/revisao-final-pjbl2`, `fix/correcao-final-pjbl2` e `docs/revisao-e-readme-enxuto`.

### Commits

As mensagens de commit seguem o padrão Conventional Commits, em português e com o verbo no presente:

```text
tipo(escopo): descricao
```

Exemplos:

- `chore(setup): criação do arquivo Tipos.hs`
- `fix(classificacao): valida disciplina e corrige interfaces dos testes`
- `docs(readme): atualiza instrucoes de execucao`

### Pull requests

O título do pull request indica o tipo da alteração e, quando houver, o número da issue:

```text
[TIPO] #numero - Descrição da alteração
```

O corpo segue o modelo em [.github/pull_request_template.md](../.github/pull_request_template.md), que pede a descrição das alterações, a issue relacionada e um checklist de compilação e testes.

Combinamos as seguintes regras:

1. Não fazer commits diretamente na `main`.
2. Abrir um pull request para cada conjunto de alterações.
3. Pedir a revisão de pelo menos um integrante antes do merge.
4. Não fazer o merge de código com erros de compilação ou testes falhando.
5. Excluir a branch remota depois do merge.

### Validação antes do merge

Antes de enviar alterações no código para a `main`, é preciso:

- compilar a aplicação e os testes sem avisos, usando `ghc -Wall -Werror -isrc ...`;
- executar `runghc -isrc tests/Testes.hs` e confirmar que todos os testes passaram.

Os comandos completos estão no [README](../README.md#como-executar).

## 4. Como aplicamos essas convenções

As convenções foram usadas principalmente na criação da estrutura do projeto e nas revisões finais (pull requests #12, #13 e #16). Como a maior parte do código foi desenvolvida em sala e enviada de uma só vez, nem todas as tarefas têm uma branch ou um pull request próprio, e alguns commits não seguem exatamente o padrão de mensagens.
