# Constituição do projeto

A constituição deste projeto vive em **[`.specify/memory/constitution.md`](../.specify/memory/constitution.md)**,
que é o caminho canônico lido pelos comandos do Spec Kit (`/speckit-plan`, `/speckit-tasks`,
`/speckit-analyze`) em tempo de execução.

Este arquivo existe apenas como ponteiro, porque o roadmap do projeto cita o caminho
`specs/constitution.md`. Não duplique o conteúdo aqui: um segundo texto de governança
divergiria do primeiro e o Princípio I (Spec-First) deixaria de ter fonte única.

## Índice das especificações

| Código | Funcionalidade | Pasta |
| --- | --- | --- |
| F1 | Autenticação e perfis de acesso | [`001-autenticacao/`](001-autenticacao/spec.md) |
| F2 | Agendar consulta | [`002-agendar-consulta/`](002-agendar-consulta/spec.md) |
| F3 | Modificar consulta | [`003-modificar-consulta/`](003-modificar-consulta/spec.md) |
| F4 | Notificar o paciente | [`004-notificacao/`](004-notificacao/spec.md) |
| F5 | Histórico do paciente via GraphQL | [`005-historico-graphql/`](005-historico-graphql/spec.md) |
| F6 | Operabilidade e entrega | [`006-operabilidade/`](006-operabilidade/spec.md) |

Cada pasta recebe `plan.md` e `tasks.md` no sprint em que a funcionalidade é implementada
(Sprint 1 para F1, Sprint 2 para F2 e F3, Sprint 3 para F4, Sprint 4 para F5, Sprint 6 para F6).
Na Sprint 0 existe apenas `spec.md` e o checklist de qualidade em `checklists/requirements.md`,
conforme o Princípio I da constituição.
