# Convenções de Branches e Pull Requests

## 1. Estratégia de Branches

A branch `main` será responsável por armazenar a versão estável e integrada do projeto.

Cada integrante deverá criar uma branch específica para desenvolver sua issue, evitando alterações diretamente na `main`.

### Padrão de nomenclatura

`tipo/numero-descricao`

| Tipo | Finalidade |
|---|---|
| `feat/` | Desenvolvimento de funcionalidades |
| `fix/` | Correção de erros |
| `test/` | Implementação de testes |
| `docs/` | Atualização da documentação |
| `chore/` | Configurações e manutenção |
| `refactor/` | Refatoração do código |

### Branches das issues

| Issue | Branch sugerida |
|---|---|
| #01 | `chore/setup` |
| #02 | `feat/tipos-algebricos` |
| #03 | `feat/dataset-brasileirao` |
| #04 | `feat/classificacao` |
| #05 | `feat/estatisticas` |
| #06 | `feat/leitura-partidas` |
| #07 | `feat/validacao-formatacao` |
| #08 | `test/classificacao` |
| #09 | `test/validacao` |
| #10 | `feat/integracao-main` |
| #11 | `docs/documentacao` |

## 2. Padrão de Commits

Utilizar Conventional Commits:

`tipo(escopo): descricao`

Exemplos:

- `feat(tipos): implementa tipo Partida`
- `feat(classificacao): adiciona calculo de pontos`
- `fix(leitura): corrige validacao de placares`
- `test(validacao): adiciona testes de erros`
- `docs(readme): atualiza instrucoes de execucao`

As mensagens deverão ser escritas em português, preferencialmente sem acentos, utilizando verbos no presente.

## 3. Convenções de Pull Requests

### Título

`[TIPO] #numero - Descrição da alteração`

Exemplos:

- `[FEAT] #02 - Implementar tipos algébricos`
- `[FEAT] #04 - Implementar classificação`
- `[TEST] #08 - Adicionar testes da classificação`
- `[DOCS] #11 - Finalizar documentação`

### Template de Pull Request

```markdown
## Descrição
Descreva brevemente as alterações realizadas.

## Issue relacionada
Closes #XX

## Alterações realizadas
- [ ] Funcionalidade implementada
- [ ] Testes adicionados ou atualizados
- [ ] Documentação atualizada, se necessário

## Checklist
- [ ] O código compila sem erros
- [ ] Não existem avisos de padrões incompletos
- [ ] Os testes relacionados foram executados
- [ ] O código segue os requisitos do projeto
- [ ] A branch está atualizada com a main
```

## 4. Regras para Pull Requests

1. Não realizar commits diretamente na `main`.
2. Criar uma branch específica para cada issue.
3. Realizar commits pequenos e descritivos.
4. Abrir um Pull Request ao concluir a implementação.
5. Vincular a issue utilizando `Closes #numero`.
6. Solicitar a revisão de pelo menos um integrante.
7. Corrigir os problemas identificados antes do merge.
8. Utilizar preferencialmente **Squash and merge**.
9. Excluir a branch remota após o merge.
10. Não realizar o merge de uma funcionalidade com erros de compilação.

## 5. Fluxo de Desenvolvimento

1. Selecionar uma issue disponível, verificando suas dependências.
2. Atualizar a branch `main` local.
3. Criar uma nova branch baseada na `main`.
4. Implementar a funcionalidade.
5. Realizar commits seguindo o padrão estabelecido.
6. Enviar a branch para o GitHub.
7. Abrir um Pull Request para a `main`.
8. Solicitar revisão e aplicar correções.
9. Realizar o merge após aprovação.

## 6. Critérios de Aprovação

Um Pull Request poderá ser aprovado quando:

- A implementação atender aos critérios de aceitação da issue.
- O código estiver organizado e legível.
- O projeto compilar corretamente.
- Os testes relacionados estiverem funcionando.
- Não houver alterações desnecessárias em arquivos de outros módulos.
- Pelo menos um integrante tiver revisado o código.

-
