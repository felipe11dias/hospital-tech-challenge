# Sistema Hospitalar — Tech Challenge Fase 3

Backend hospitalar em **três microsserviços Spring Boot** (agendamento, notificações e
histórico), com autenticação e autorização por perfil, consultas GraphQL e integração assíncrona
por RabbitMQ.

O projeto é desenvolvido por **SDD (Spec-Driven Development)**: nenhuma linha de código de
produção é escrita antes da especificação que ela implementa. A governança está em
[`.specify/memory/constitution.md`](.specify/memory/constitution.md) e as especificações em
[`specs/`](specs/constitution.md).

> **Estado atual: Sprint 0 concluída.** A fundação está no lugar (specs, ADRs, infraestrutura
> local, build multi-módulo, CI) e os três serviços sobem vazios respondendo em
> `/actuator/health`. As funcionalidades F1 a F6 são implementadas nas Sprints 1 a 6, cada uma
> a partir da sua spec. A seção [Estado por sprint](#estado-por-sprint) diz exatamente o que já
> existe.

## 1. O que é o sistema e quais requisitos atende

| Requisito do enunciado | Como este projeto atende | Spec | Sprint |
| --- | --- | --- | --- |
| Autenticação com Spring Security e acesso por perfil | Login por HTTP Basic que devolve JWT RS256; autorização por perfil em cada operação | [F1](specs/001-autenticacao/spec.md) | 1 |
| Médico vê e edita histórico; enfermeiro registra e acessa; paciente vê só as suas | Matriz de permissões transformada em testes automatizados | [F1](specs/001-autenticacao/spec.md), [F3](specs/003-modificar-consulta/spec.md) | 1 e 2 |
| GraphQL para histórico (todos os atendimentos ou só os futuros) | Spring for GraphQL com filtro `periodo: TODAS \| FUTURAS \| PASSADAS` | [F5](specs/005-historico-graphql/spec.md) | 2 e 4 |
| Mais de um serviço (agendamento, notificações, histórico opcional) | Três serviços, cada um com seu banco PostgreSQL | todas | 0 a 4 |
| Assíncrono com RabbitMQ ou Kafka | RabbitMQ: topic exchange, filas duráveis, DLQ, consumidor idempotente | [F4](specs/004-notificacao/spec.md) | 3 |
| Documentação, collection Postman, repositório aberto | README, OpenAPI/GraphiQL, collection versionada, GitHub público | [F6](specs/006-operabilidade/spec.md) | 6 |

## 2. Arquitetura

O **agendamento** é o único serviço que escreve consultas. A cada mudança ele publica um evento,
e os outros dois reagem sem saber que ele existe. Se notificações ou histórico caírem, o
agendamento continua funcionando e as mensagens esperam na fila.

```
                    ┌──────────────────────┐
   JWT (escreve)    │  agendamento-service │  :8081   ── db-agendamento (:5433)
  ────────────────► │  GraphQL + /auth/token│
                    └──────────┬───────────┘
                               │ publica apos o commit
                               ▼
                 exchange  hospital.consultas  (topic, duravel)
                      │                           │
         consulta.*   │                           │  consulta.#
                      ▼                           ▼
        ┌──────────────────────┐      ┌──────────────────────┐
        │ notificacao.consultas│      │ historico.consultas  │
        └──────────┬───────────┘      └──────────┬───────────┘
                   ▼                             ▼
        notificacao-service :8082      historico-service :8083
        db-notificacao (:5434)         db-historico (:5435)
                   │                             ▲
                   ▼                             │ JWT (le)
              Mailpit :8025            ◄─────────┘
         (caixa de entrada de teste)

        DLQ: hospital.consultas.dlx → notificacao.consultas.dlq
                                    → historico.consultas.dlq
```

### Fluxo de ponta a ponta: agendar uma consulta

1. O enfermeiro chama `POST /auth/token` com usuário e senha (HTTP Basic) e recebe um JWT com
   `roles=[ENFERMEIRO]`.
2. Envia a mutation `agendarConsulta` ao agendamento com `Authorization: Bearer <token>`.
3. O filtro valida assinatura e expiração; a autorização confere o perfil.
4. O serviço valida as regras de negócio, grava no PostgreSQL e dispara um evento interno.
5. **Após o commit**, o publicador envia `consulta.criada` para a exchange `hospital.consultas`.
6. A exchange roteia cópias para `notificacao.consultas` e `historico.consultas`.
7. Notificações confere o `eventId`, envia a confirmação e agenda o lembrete; o histórico grava
   a cópia de leitura.
8. Um agendador envia o lembrete 24 horas antes da consulta.

## 3. Como rodar

### Pré-requisitos

- **Docker** e **Docker Compose**. Java e Maven **não** são necessários: a compilação acontece
  dentro da imagem (ver [`Dockerfile`](Dockerfile)).
- Para rodar os testes fora do Docker: JDK 21 (o Maven vem pelo wrapper `./mvnw`).

### Gerar o par de chaves RSA

É o único passo manual antes de subir o ambiente. A chave privada **não pode** ser versionada
(Princípio III da constituição), por isso ela não vem no repositório.

```powershell
openssl genrsa -out certs/private.pem 2048
```

```powershell
openssl rsa -in certs/private.pem -pubout -out certs/public.pem
```

A chave privada precisa estar em PKCS#8 (cabeçalho `BEGIN PRIVATE KEY`). O OpenSSL 3 já gera
assim; em versões antigas, converta:

```powershell
openssl pkcs8 -topk8 -nocrypt -in certs/private.pem -out certs/private.pem
```

### Subir tudo

```powershell
docker compose up --build
```

A primeira execução compila os três módulos dentro da imagem e leva alguns minutos. Nas
seguintes, o cache do Maven já está na camada.

### Portas

| Serviço | Porta | Endereço |
| --- | --- | --- |
| agendamento-service | 8081 | http://localhost:8081/actuator/health |
| notificacao-service | 8082 | http://localhost:8082/actuator/health |
| historico-service | 8083 | http://localhost:8083/actuator/health |
| RabbitMQ (painel) | 15672 | http://localhost:15672 (guest / guest) |
| Mailpit (caixa de entrada) | 8025 | http://localhost:8025 |
| PostgreSQL agendamento | 5433 | — |
| PostgreSQL notificação | 5434 | — |
| PostgreSQL histórico | 5435 | — |

Para mudar usuário e senha do banco ou do broker, copie [`.env.example`](.env.example) para
`.env` e ajuste. Para mudar as portas publicadas, altere o lado esquerdo dos mapeamentos em
[`docker-compose.yml`](docker-compose.yml).

### Derrubar

```powershell
docker compose down -v
```

## 4. Usuários de demonstração

Entram na **Sprint 1**, com a migração Flyway da F1 (senhas em BCrypt, carga inicial). A tabela
abaixo é o contrato definido na spec e será preenchida com as senhas quando a migração existir.

| Usuário | Perfil | Senha |
| --- | --- | --- |
| `dr.house` | MEDICO | definida na Sprint 1 |
| `enf.ana` | ENFERMEIRO | definida na Sprint 1 |
| `paciente.maria` | PACIENTE | definida na Sprint 1 |

## 5. Endpoints

**Disponíveis agora (Sprint 0)** — em cada um dos três serviços:

| Endpoint | O que faz |
| --- | --- |
| `GET /actuator/health` | estado do serviço, do banco e do RabbitMQ |
| `GET /actuator/info` | identificação do serviço |
| `GET /actuator/prometheus` | métricas em formato de coleta |

**A partir da Sprint 1 e 2:**

| Endpoint | Serviço | Spec |
| --- | --- | --- |
| `POST /auth/token` (HTTP Basic → JWT) | agendamento | [F1](specs/001-autenticacao/spec.md) |
| `/graphql` + GraphiQL em `/graphiql` | agendamento | [F2](specs/002-agendar-consulta/spec.md), [F3](specs/003-modificar-consulta/spec.md) |
| `/graphql` + GraphiQL em `/graphiql` | histórico | [F5](specs/005-historico-graphql/spec.md) |

Os contratos GraphQL completos (mutations `agendarConsulta`, `atualizarConsulta`,
`cancelarConsulta`, `registrarAtendimento`; queries `historicoPaciente`, `minhasConsultas`)
estão nas specs correspondentes e no
[roadmap](<docs/Roadmap SDD — Tech Challenge Fase 3 (Sistema Hospitalar).md>).

## 6. Mensageria

| Item | Valor |
| --- | --- |
| Exchange | `hospital.consultas` (topic, durável) |
| Routing keys | `consulta.criada`, `consulta.atualizada`, `consulta.cancelada`, `consulta.realizada` |
| Fila de notificações | `notificacao.consultas`, binding `consulta.*`, DLQ `notificacao.consultas.dlq` |
| Fila do histórico | `historico.consultas`, binding `consulta.#`, DLQ `historico.consultas.dlq` |
| Dead-letter exchange | `hospital.consultas.dlx` (direct) |
| Formato | JSON, mensagem persistente |

As filas são declaradas na **Sprint 3**. Para acompanhar:

- **Filas, bindings e DLQ**: painel do RabbitMQ em http://localhost:15672 (guest / guest).
- **E-mails enviados**: caixa de entrada do Mailpit em http://localhost:8025.

## 7. Decisões e interpretação das permissões

Cada decisão de arquitetura tem um registro em [`docs/adr/`](docs/adr/README.md):

| ADR | Decisão |
| --- | --- |
| [ADR-001](docs/adr/ADR-001-rabbitmq-em-vez-de-kafka.md) | RabbitMQ em vez de Kafka |
| [ADR-002](docs/adr/ADR-002-jwt-stateless-emitido-pelo-agendamento.md) | JWT stateless emitido pelo agendamento |
| [ADR-003](docs/adr/ADR-003-historico-como-modelo-de-leitura.md) | Histórico como modelo de leitura (CQRS leve) |
| [ADR-004](docs/adr/ADR-004-publicar-apos-o-commit.md) | Publicar o evento somente após o commit |
| [ADR-005](docs/adr/ADR-005-consumidores-idempotentes.md) | Consumidores idempotentes por `eventId` |
| [ADR-006](docs/adr/ADR-006-interpretacao-das-permissoes.md) | Interpretação das permissões do enunciado |
| [ADR-007](docs/adr/ADR-007-spring-boot-4-2.md) | Spring Boot 4.2.0 em vez de 4.0.x |

### Interpretação das permissões (importante para a avaliação)

O enunciado diz que médicos "podem visualizar e editar o histórico" e enfermeiros "podem
registrar consultas e acessar o histórico", sem detalhar o que é editar. Este projeto adota a
seguinte leitura, detalhada em [ADR-006](docs/adr/ADR-006-interpretacao-das-permissoes.md):

- **Editar o histórico** = registrar observações clínicas e marcar a consulta como REALIZADA.
  **Exclusivo do MÉDICO.**
- **Modificar consultas** = remarcar, trocar o médico e cancelar. **MÉDICO e ENFERMEIRO**,
  conforme a seção de GraphQL do próprio enunciado.
- **PACIENTE** apenas visualiza, e apenas as consultas vinculadas ao seu próprio `pacienteId`,
  lido do token — nunca de argumento enviado pelo cliente.

A matriz completa está em [F1](specs/001-autenticacao/spec.md#matriz-de-permissões).

## 8. Testes

```powershell
./mvnw verify
```

Os testes de integração usam Testcontainers, portanto o Docker precisa estar rodando. A mesma
verificação roda na integração contínua a cada push
([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

**Regra de rastreabilidade** (Princípio II da constituição): cada critério de aceite tem ao
menos um teste cujo nome carrega o código do critério, no formato
`F<n>_CA<m>_descricaoCurta` — por exemplo `F2_CA3_conflitoDeHorarioRetornaErro`. Quem lê a spec
encontra o teste que a prova.

O relatório da varredura OWASP ZAP baseline entra na **Sprint 6**, em `docs/security/`.

## Estado por sprint

| Sprint | Objetivo | Estado |
| --- | --- | --- |
| 0 | Fundação: specs, ADRs, infra local, build multi-módulo, CI | **concluída** |
| 1 | Segurança (F1): JWT, perfis, usuários em BCrypt | pendente |
| 2 | Agendamento com GraphQL (F2, F3) | pendente |
| 3 | Mensageria e notificações (F4) | pendente |
| 4 | Serviço de histórico (F5) | pendente |
| 5 | Resiliência e observabilidade | pendente |
| 6 | Qualidade e entrega (F6) | pendente |

O relatório detalhado do que foi feito na Sprint 0, incluindo os prompts usados no Spec Kit,
está em [`docs/sprints/sprint-0-relatorio.md`](docs/sprints/sprint-0-relatorio.md).

## Estrutura do repositório

```text
hospital-tech-challenge/
├── pom.xml                      # pom pai: versões e módulos
├── Dockerfile                   # build único, um target por serviço
├── docker-compose.yml           # 3 serviços, 3 bancos, RabbitMQ, Mailpit
├── .specify/memory/constitution.md   # governança do projeto (SDD)
├── specs/                       # F1 a F6: spec.md + checklists
├── docs/
│   ├── adr/                     # ADR-001 ... ADR-007
│   ├── aulas/                   # material de apoio das aulas
│   ├── desafio/                 # enunciado da Fase 3
│   └── sprints/                 # relatórios por sprint
├── agendamento-service/
├── notificacao-service/
└── historico-service/
```

## Licença

[MIT](LICENSE).
