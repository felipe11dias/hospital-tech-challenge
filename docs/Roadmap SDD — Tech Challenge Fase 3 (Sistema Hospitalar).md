# Roadmap SDD — Tech Challenge Fase 3 (Sistema Hospitalar)

Nov 19, 2026 · @Felipe

## Visão geral

O projeto entrega um backend hospitalar em **três microsserviços Spring Boot** (agendamento, notificações e histórico), protegidos por Spring Security com perfis MÉDICO, ENFERMEIRO e PACIENTE, com consultas GraphQL e eventos via **RabbitMQ**. O desenvolvimento segue **SDD (Spec-Driven Development)**: nenhuma linha de código é escrita antes da especificação que ela implementa.

### O que o desafio pede

| Requisito do enunciado | Como este roadmap atende | Fase |
| --- | --- | --- |
| Autenticação com Spring Security e acesso por perfil | Login com credenciais (HTTP Basic) que devolve um JWT assinado com RSA; regras por perfil com `@PreAuthorize` | Sprint 1 |
| Médico vê e edita histórico; enfermeiro registra e acessa; paciente vê só as suas | Matriz de permissões (seção Especificações) transformada em testes automatizados | Sprint 1 e 2 |
| GraphQL para histórico (todos os atendimentos ou só os futuros) | Spring for GraphQL com filtro `periodo: TODAS \| FUTURAS \| PASSADAS` | Sprint 2 e 4 |
| Mais de um serviço (agendamento, notificações, histórico opcional) | Três serviços, cada um com seu banco PostgreSQL | Sprint 0 a 4 |
| Assíncrono com RabbitMQ ou Kafka | RabbitMQ: topic exchange, filas duráveis, DLQ, consumidor idempotente | Sprint 3 |
| Documentação, collection Postman, repositório aberto | README completo, OpenAPI/GraphiQL, collection versionada, GitHub público | Sprint 6 |

### O que é SDD, em uma frase por etapa

SDD inverte a ordem habitual: a especificação é a fonte da verdade e o código é a forma de cumpri-la. Cada funcionalidade passa por cinco etapas, cada uma gerando um arquivo versionado no repositório.

1. **Constituição** (`specs/constitution.md`): princípios que valem para o projeto inteiro (stack, padrões de código, regras de segurança, definição de pronto). Escrita uma vez, no Sprint 0.
2. **Specify** (`spec.md`): o QUÊ e o PORQUÊ. Histórias de usuário, regras de negócio e critérios de aceite em Given/When/Then. Sem tecnologia.
3. **Plan** (`plan.md`): o COMO. Contratos (schema GraphQL, eventos, tabelas), classes envolvidas, decisões técnicas.
4. **Tasks** (`tasks.md`): lista ordenada de tarefas pequenas, cada uma ligada a um critério de aceite.
5. **Implement + Validate**: código e testes. Cada critério de aceite vira pelo menos um teste automatizado; a funcionalidade só está pronta quando todos passam.

Você pode fazer isso à mão (Markdown no repositório) ou com uma ferramenta como o GitHub Spec Kit, que automatiza as etapas com um agente de IA. Os nomes dos comandos mudam entre versões; a estrutura de arquivos acima funciona em qualquer caso.

### Como usar este roadmap

- Leia **Especificações** antes de abrir a IDE: ela já traz os critérios de aceite prontos para virar `spec.md`.
- Siga os sprints na ordem. Cada um termina com uma **definição de pronto** verificável.
- As caixas de seleção em cada sprint são suas: marque conforme avança.

## Stack e decisões de arquitetura

A stack usa Java 21 e Spring Boot 4.0.x, a geração com suporte gratuito hoje: o [Spring Boot 4.0 saiu em novembro de 2025](https://spring.io/blog/2025/11/20/spring-boot-4-0-0-available-now/), e o 3.5 [deixou de receber correções gratuitas em 30/06/2026](https://www.herodevs.com/blog-posts/spring-boot-4-0-breaking-changes-migration-guide). As aulas usam Spring Security 6.1; o Spring Boot 4 traz o Security 7, com a mesma DSL de lambdas (`SecurityFilterChain`, `authorizeHttpRequests`). Se alguma biblioteca ainda não suportar o Boot 4 na sua data, fique no 3.5.x: o código das aulas roda sem mudanças.

| Camada | Escolha | Por quê (aula de origem) |
| --- | --- | --- |
| Linguagem e build | Java 21, Maven multi-módulo | LTS usado nas aulas; um `pom` pai com versões centralizadas |
| Framework | Spring Boot 4.0.x (Web, Validation, Data JPA, Actuator) | Padrão do curso; o enunciado avalia “práticas com Spring Boot” |
| Segurança | Spring Security + OAuth2 Resource Server (JWT RS256) + BCrypt | Segurança aulas 1 a 3: filtros, JWT com par de chaves, hash de senha |
| API de consulta | Spring for GraphQL (schema-first, GraphiQL, `@BatchMapping`) | gRPC/GraphQL aulas 3 e 4: SDL, resolvers, DataLoader contra N+1 |
| Mensageria | RabbitMQ 4 com Spring AMQP | Mensageria aulas 4 e 5: topic exchange, ack, DLQ |
| Banco | PostgreSQL 16, um banco por serviço, migrações Flyway | Distribuídos aula 1: cada microsserviço é dono dos seus dados |
| Resiliência | Resilience4j (Retry, CircuitBreaker) ou `@Retryable` do Spring 7 | Distribuídos aulas 2 e 3 |
| Observabilidade | Actuator + Micrometer Prometheus; Grafana opcional | Distribuídos aula 4 |
| E-mail de teste | Mailpit (SMTP falso com caixa de entrada web) | Permite demonstrar o lembrete sem enviar e-mail real |
| Testes | JUnit 5, spring-security-test, `HttpGraphQlTester`, Testcontainers | Segurança aula 5: testes de autenticação e autorização |
| Infra local | Docker Compose (3 serviços, 3 bancos, RabbitMQ, Mailpit) | Um `docker compose up` sobe tudo para o professor |

### Registros de decisão (ADRs)

Cada decisão abaixo vira um arquivo curto em `docs/adr/`. Avaliadores valorizam ver o porquê das escolhas.

**ADR-001 — RabbitMQ em vez de Kafka.** O fluxo é um comando de negócio (“avise o paciente”) com baixo volume, onde importam confirmação por mensagem (ack), reenvio e fila de mensagens mortas. RabbitMQ entrega isso nativamente, com roteamento por routing key. Kafka seria a escolha para alto volume, reprocessamento de histórico (offsets) e streaming; aqui seria infraestrutura maior que o problema.

**ADR-002 — JWT stateless emitido pelo agendamento.** O cliente troca usuário e senha (HTTP Basic, o que cumpre o “autenticação básica” do enunciado) por um JWT assinado com chave privada RSA. O serviço de histórico valida o token só com a chave pública, sem consultar o banco de usuários. Claims: `sub` (username), `roles`, `pacienteId` (só para PACIENTE), `exp` de 1 hora.

**ADR-003 — Histórico como modelo de leitura (CQRS leve).** O agendamento é dono das escritas. O histórico consome os mesmos eventos e mantém uma cópia otimizada para consulta via GraphQL. Isso cumpre o serviço opcional e mostra consistência eventual na prática.

**ADR-004 — Publicar após o commit.** O evento sai num `@TransactionalEventListener(phase = AFTER_COMMIT)`, para nunca anunciar uma consulta que não foi gravada. Evolução opcional: padrão Transactional Outbox, que também cobre a queda do broker entre o commit e o envio.

**ADR-005 — Consumidores idempotentes.** Todo evento tem `eventId` (UUID). Cada consumidor grava os IDs processados e ignora repetições, porque o RabbitMQ garante entrega “pelo menos uma vez”.

**ADR-006 — Interpretação das permissões.** “Editar histórico” significa registrar observações clínicas e marcar a consulta como realizada: só MÉDICO. “Modificar consultas” (data, médico, cancelamento) vale para MÉDICO e ENFERMEIRO. Registre essa leitura no README, porque o enunciado não detalha.

## Arquitetura

O agendamento é o único serviço que escreve consultas; ele publica um evento a cada mudança, e os outros dois reagem sem saber que ele existe. Se notificações ou histórico caírem, o agendamento continua funcionando e as mensagens esperam na fila.

&#91;embedded content: arquitetura · 3 serviços, 1 broker, 1 SMTP de teste\]

O cliente fala com dois serviços: escreve no agendamento e lê o histórico, sempre com o mesmo JWT. O RabbitMQ entrega cada evento a duas filas independentes, uma por consumidor.

### Fluxo de ponta a ponta: agendar uma consulta

1. O enfermeiro chama `POST /auth/token` com usuário e senha (HTTP Basic) e recebe um JWT com `roles=[ENFERMEIRO]`.
2. Envia a mutation `agendarConsulta` ao agendamento com `Authorization: Bearer <token>`.
3. O filtro JWT valida assinatura e expiração; `@PreAuthorize` confere o perfil.
4. O `ConsultaService` valida as regras, grava no PostgreSQL e dispara um evento interno.
5. Após o commit, o publicador envia `consulta.criada` para a exchange `hospital.consultas`.
6. A exchange roteia cópias para `notificacao.consultas` e `historico.consultas`.
7. O serviço de notificações confere o `eventId`, envia a confirmação e agenda o lembrete; o histórico grava a cópia de leitura.
8. Um `@Scheduled` envia o lembrete 24 horas antes da consulta.

### Estrutura do repositório

```text
hospital-tech-challenge/
├── pom.xml                       # pom pai: versões e módulos
├── docker-compose.yml
├── README.md
├── specs/
│   ├── constitution.md
│   ├── 001-autenticacao/        # spec.md, plan.md, tasks.md
│   ├── 002-agendar-consulta/
│   ├── 003-modificar-consulta/
│   ├── 004-notificacao/
│   ├── 005-historico-graphql/
│   └── 006-operabilidade/
├── docs/adr/                     # ADR-001 ... ADR-006
├── postman/                      # collection + ambiente
├── agendamento-service/
│   └── src/main/java/br/com/fiap/hospital/agendamento/
│       ├── config/               # SecurityConfig, RabbitConfig, GraphQlConfig
│       ├── security/             # TokenController, UserDetailsService
│       ├── graphql/              # controllers GraphQL, inputs, tratamento de erros
│       ├── domain/               # Consulta, Paciente, Medico, Usuario, enums
│       ├── service/              # ConsultaService (regras de negócio)
│       ├── repository/
│       └── messaging/            # ConsultaEvent, ConsultaEventPublisher
├── notificacao-service/          # config, messaging, domain (Lembrete), service, scheduler
└── historico-service/            # config, security, messaging, graphql, domain, repository
```

Cada serviço tem `src/main/resources/db/migration` (Flyway) e `src/main/resources/graphql` quando expõe GraphQL. O contrato do evento (`ConsultaEvent`) é duplicado como `record` em cada serviço, de propósito: compartilhar um JAR de modelo acoplaria as versões dos serviços.

## Especificações

São seis specs de funcionalidade (F1 a F6) mais os requisitos não funcionais; cada uma vira uma pasta `specs/00N-nome/` com `spec.md`, `plan.md` e `tasks.md`. Os critérios de aceite abaixo já estão no formato que vira teste.

### Matriz de permissões

| Ação | MÉDICO | ENFERMEIRO | PACIENTE | Sem login |
| --- | --- | --- | --- | --- |
| Obter token (`POST /auth/token`) | sim | sim | sim | 401 |
| Agendar consulta (`agendarConsulta`) | sim | sim | não (403) | 401 |
| Remarcar ou trocar médico (`atualizarConsulta`) | sim | sim | não | 401 |
| Cancelar consulta (`cancelarConsulta`) | sim | sim | não | 401 |
| Registrar observações e marcar realizada (`registrarAtendimento`) | sim | não (403) | não | 401 |
| Ver histórico de qualquer paciente (`historicoPaciente`) | sim | sim | só o próprio `pacienteId` | 401 |
| Ver as próprias consultas (`minhasConsultas`) | não se aplica | não se aplica | sim | 401 |

Regra-chave para o PACIENTE: o `pacienteId` vem do token, nunca de um argumento enviado pelo cliente. Se ele pedir o histórico de outro ID, a resposta é erro `FORBIDDEN`.

### Requisitos funcionais

- **F1 Autenticação e perfis.** Usuários com perfil único (MEDICO, ENFERMEIRO, PACIENTE), senha em BCrypt, carga inicial de usuários de demonstração via Flyway.
- **F2 Agendar consulta.** Informar paciente, médico, data e hora, motivo. Status inicial AGENDADA.
- **F3 Modificar consulta.** Remarcar, trocar médico, cancelar; o médico também registra observações e marca REALIZADA.
- **F4 Notificar paciente.** Ao criar ou editar: confirmação imediata. Lembrete automático 24 horas antes da consulta.
- **F5 Histórico via GraphQL.** Listar todos os atendimentos de um paciente, só os futuros ou só os passados, com paginação.
- **F6 Operabilidade.** Health checks, métricas, DLQ visível, collection Postman, README.

### Critérios de aceite (Given/When/Then)

**F1 Autenticação**

- *Dado* o usuário `dr.house` com senha correta, *quando* chama `POST /auth/token` com HTTP Basic, *então* recebe 200 e um JWT com `roles=[MEDICO]` e expiração de 1 hora.
- *Dado* senha errada, *quando* pede o token, *então* recebe 401 e nenhum token.
- *Dado* uma requisição GraphQL sem token ou com token expirado ou adulterado, *então* recebe 401.
- *Dado* o banco de usuários, *então* nenhuma senha está em texto puro (todas começam com `$2a$` ou `$2b$`).

**F2 Agendar consulta**

- *Dado* um ENFERMEIRO autenticado, *quando* executa `agendarConsulta` com paciente e médico existentes e data futura, *então* a consulta é criada com status AGENDADA e um evento `consulta.criada` é publicado.
- *Dado* data no passado, *então* erro de validação `BAD_REQUEST` com a mensagem “dataHora deve ser futura” e nada é publicado.
- *Dado* que o médico já tem consulta no mesmo horário, *então* erro de conflito e nada é gravado.
- *Dado* um PACIENTE autenticado, *quando* tenta agendar, *então* erro `FORBIDDEN`.

**F3 Modificar consulta**

- *Dado* uma consulta AGENDADA, *quando* um ENFERMEIRO remarca, *então* a data muda, a versão incrementa e sai `consulta.atualizada`.
- *Dado* uma consulta CANCELADA ou REALIZADA, *quando* alguém tenta remarcar, *então* erro de regra de negócio.
- *Dado* um ENFERMEIRO, *quando* tenta `registrarAtendimento`, *então* `FORBIDDEN`; *dado* um MÉDICO, a consulta vira REALIZADA com as observações.
- *Dado* duas edições simultâneas, *então* a segunda falha por bloqueio otimista (`@Version`).

**F4 Notificação**

- *Dado* um evento `consulta.criada`, *quando* o serviço de notificações o consome, *então* envia confirmação ao e-mail do paciente e agenda um lembrete para 24 horas antes.
- *Dado* um `consulta.atualizada` com nova data, *então* o lembrete pendente é recalculado; *dado* `consulta.cancelada`, o lembrete é cancelado.
- *Dado* o mesmo `eventId` entregue duas vezes, *então* só um e-mail é enviado.
- *Dado* uma mensagem malformada ou um erro após 3 tentativas, *então* ela vai para `notificacao.consultas.dlq` e a fila principal segue andando.
- *Dado* o serviço de notificações parado, *quando* consultas são criadas, *então* o agendamento continua respondendo e as mensagens são processadas quando ele volta.

**F5 Histórico GraphQL**

- *Dado* um paciente com 3 consultas passadas e 2 futuras, *quando* um MÉDICO consulta `historicoPaciente(periodo: FUTURAS)`, *então* recebe exatamente as 2 futuras, ordenadas da mais próxima para a mais distante.
- *Dado* um PACIENTE, *quando* chama `minhasConsultas`, *então* recebe só as consultas do `pacienteId` do seu token.
- *Dado* uma consulta de 50 atendimentos pedindo o nome do médico, *então* o banco recebe 2 queries, não 51 (`@BatchMapping`).

### Requisitos não funcionais

| Código | Requisito | Como verificar |
| --- | --- | --- |
| RNF1 | Senhas só em BCrypt; chave privada JWT fora do repositório (variável de ambiente ou volume) | Revisão de código e `git grep` por “BEGIN PRIVATE KEY” |
| RNF2 | Serviços sobem com `docker compose up` em uma máquina limpa | Teste manual antes da entrega |
| RNF3 | Mensagens e filas duráveis; nenhuma perda se o RabbitMQ reiniciar | Reiniciar o container com mensagens na fila |
| RNF4 | Cada serviço expõe `/actuator/health` e `/actuator/prometheus` | Collection Postman |
| RNF5 | Erros GraphQL com código padronizado (`BAD_REQUEST`, `FORBIDDEN`, `NOT_FOUND`) e sem stack trace | Testes de integração |
| RNF6 | Nenhum alerta Alto no OWASP ZAP baseline | Relatório anexado ao README |

### Contrato GraphQL do agendamento (`schema.graphqls`)

```graphql
type Query {
  consulta(id: ID!): Consulta
}

type Mutation {
  agendarConsulta(input: AgendarConsultaInput!): Consulta!
  atualizarConsulta(id: ID!, input: AtualizarConsultaInput!): Consulta!
  cancelarConsulta(id: ID!, motivo: String): Consulta!
  registrarAtendimento(id: ID!, observacoes: String!): Consulta!
}

input AgendarConsultaInput {
  pacienteId: ID!
  medicoId: ID!
  dataHora: DateTime!
  motivo: String
}

input AtualizarConsultaInput {
  medicoId: ID
  dataHora: DateTime
  motivo: String
}

type Consulta {
  id: ID!
  paciente: Paciente!
  medico: Medico!
  dataHora: DateTime!
  status: StatusConsulta!
  motivo: String
  observacoes: String
  versao: Int!
}

enum StatusConsulta { AGENDADA CANCELADA REALIZADA }
scalar DateTime
```

### Contrato GraphQL do histórico

```graphql
type Query {
  historicoPaciente(pacienteId: ID!, periodo: Periodo = TODAS,
                    pagina: Int = 0, tamanho: Int = 20): PaginaHistorico!
  minhasConsultas(periodo: Periodo = FUTURAS): [ConsultaHistorico!]!
}

enum Periodo { TODAS FUTURAS PASSADAS }

type PaginaHistorico {
  itens: [ConsultaHistorico!]!
  total: Int!
  pagina: Int!
  temProxima: Boolean!
}

type ConsultaHistorico {
  consultaId: ID!
  dataHora: DateTime!
  status: String!
  medicoNome: String!
  motivo: String
  observacoes: String
}
```

### Contrato de eventos (RabbitMQ)

| Item | Valor |
| --- | --- |
| Exchange | `hospital.consultas` (topic, durável) |
| Routing keys | `consulta.criada`, `consulta.atualizada`, `consulta.cancelada`, `consulta.realizada` |
| Fila de notificações | `notificacao.consultas`, binding `consulta.*`, dead-letter para `notificacao.consultas.dlq` |
| Fila do histórico | `historico.consultas`, binding `consulta.#`, dead-letter para `historico.consultas.dlq` |
| Dead-letter exchange | `hospital.consultas.dlx` (direct) |
| Formato | JSON, `contentType=application/json`, mensagem persistente |

```json
{
  "eventId": "5b0d6f3e-8a51-4f7b-9f0e-2a1c7d9e4b10",
  "tipo": "CONSULTA_CRIADA",
  "ocorridoEm": "2026-11-19T18:00:00Z",
  "consultaId": "9f1c...",
  "versao": 1,
  "pacienteId": "3a7e...",
  "pacienteNome": "Maria Souza",
  "pacienteEmail": "maria@exemplo.com",
  "medicoNome": "Dr. Gregory House",
  "dataHora": "2026-11-25T14:30:00-03:00",
  "status": "AGENDADA",
  "motivo": "Retorno"
}
```

O evento carrega os dados que os consumidores precisam (“event-carried state transfer”), para que notificações e histórico não precisem chamar o agendamento de volta. O campo `versao` permite ao histórico ignorar eventos que cheguem fora de ordem.

### Modelo de `spec.md` (exemplo da F2)

```markdown
# F2 — Agendar consulta

## Contexto
Enfermeiros e médicos registram consultas para pacientes cadastrados.

## História
Como ENFERMEIRO, quero agendar uma consulta para um paciente,
para que ele seja atendido e avisado automaticamente.

## Regras de negócio
- RN1: dataHora deve ser futura.
- RN2: um médico não pode ter duas consultas no mesmo horário.
- RN3: PACIENTE não agenda.

## Critérios de aceite
- CA1: Dado ... Quando ... Então ...

## Fora do escopo
- Pagamento, convênio, agenda de salas.

## Questões em aberto
- Duração padrão da consulta (assumido: 30 minutos).
```

## Roadmap por fases

Sete sprints levam do repositório vazio à entrega; cada um começa pela spec e termina numa definição de pronto que um teste ou uma demonstração comprova. Ajuste a duração ao seu prazo: os sprints 1 a 3 são o caminho crítico (segurança, agendamento, mensageria) e cobrem os requisitos obrigatórios.

&#91;embedded content: roadmap · 7 sprints, caminho crítico em destaque\]

### Sprint 0 — Fundação e specs

Objetivo: repositório, infraestrutura local e todas as specs escritas antes do primeiro `@Service`.

- [x] Criar repositório público no GitHub com `README.md`, `.gitignore` (inclui `*.pem`) e licença
- [x] Escrever `specs/constitution.md`: Java 21, Spring Boot 4, camadas, nomes em português para domínio, testes obrigatórios por critério de aceite
- [x] Escrever `spec.md` de F1 a F6 a partir da seção Especificações
- [x] Gerar os três projetos no Spring Initializr dentro de um `pom` pai multi-módulo
- [x] `docker-compose.yml` com 3 PostgreSQL, RabbitMQ (`rabbitmq:4-management`) e Mailpit
- [x] Registrar ADR-001 a ADR-006 em `docs/adr/`
- [x] Opcional: GitHub Actions rodando `mvn verify` a cada push

Pronto quando: `docker compose up` sobe a infraestrutura, os três serviços iniciam vazios e respondem em `/actuator/health`.

### Sprint 1 — Segurança (F1)

Objetivo: ninguém entra sem token, e cada perfil só faz o que a matriz permite.

- [ ] `plan.md` e `tasks.md` de F1
- [ ] Entidades `Usuario` e `Perfil` (enum MEDICO, ENFERMEIRO, PACIENTE); `Paciente` e `Medico` ligados ao usuário
- [ ] Migração Flyway com usuários de demonstração e senhas em BCrypt
- [ ] `UserDetailsService` lendo do banco (como o `CustomUserDetailsService` da aula 1)
- [ ] Gerar par de chaves RSA com OpenSSL (aula 2) e carregar por variável de ambiente
- [ ] `POST /auth/token` com HTTP Basic devolvendo JWT (`roles`, `pacienteId`, `exp`)
- [ ] `SecurityFilterChain` stateless com OAuth2 Resource Server e `@EnableMethodSecurity`
- [ ] Testes: token válido, senha errada, token adulterado, token expirado, endpoint sem token

Pronto quando: todos os critérios de F1 passam em teste automatizado.

### Sprint 2 — Agendamento com GraphQL (F2, F3)

Objetivo: médicos e enfermeiros criam e alteram consultas pelo GraphiQL, respeitando as regras.

- [ ] `schema.graphqls` conforme o contrato; `spring.graphql.graphiql.enabled=true`
- [ ] Entidade `Consulta` com `@Version`; repositório com busca de conflito de horário
- [ ] `ConsultaService` com as regras RN1 a RN3 e as transições de status
- [ ] `ConsultaGraphQlController` com `@MutationMapping`, `@QueryMapping` e `@PreAuthorize` por operação
- [ ] `DataFetcherExceptionResolverAdapter` traduzindo exceções em `BAD_REQUEST`, `FORBIDDEN`, `NOT_FOUND`
- [ ] Testes com `HttpGraphQlTester` cobrindo F2 e F3, um por perfil

Pronto quando: a matriz de permissões inteira está coberta por testes verdes.

### Sprint 3 — Mensageria e notificações (F4)

Objetivo: criar ou editar uma consulta gera um e-mail visível no Mailpit, sem acoplar os serviços.

- [ ] Declarar exchange, filas, bindings e DLQ como `@Bean` (`TopicExchange`, `QueueBuilder.durable().deadLetterExchange(...)`)
- [ ] `Jackson2JsonMessageConverter` (ou o conversor JSON da sua versão do Spring AMQP) nos dois lados
- [ ] Publicador no agendamento via `@TransactionalEventListener(AFTER_COMMIT)`
- [ ] Consumidor `@RabbitListener` no serviço de notificações com tabela `evento_processado` (idempotência)
- [ ] Retry do listener: 3 tentativas com backoff; depois rejeitar sem reenfileirar, indo para a DLQ
- [ ] Entidade `Lembrete` (consultaId, email, enviarEm, status) e `@Scheduled` a cada minuto enviando os vencidos
- [ ] Envio via `JavaMailSender` para o Mailpit
- [ ] Testes com Testcontainers (RabbitMQ): evento consumido, duplicado ignorado, malformado na DLQ

Pronto quando: a demonstração “agendar, ver confirmação no Mailpit, parar o serviço, agendar de novo, religar e ver o segundo e-mail chegar” funciona.

### Sprint 4 — Serviço de histórico (F5)

Objetivo: consultas flexíveis sobre o histórico, inclusive “só as futuras”.

- [ ] Consumidor de `historico.consultas` gravando `ConsultaHistorico` (upsert por `consultaId`, ignorando `versao` menor)
- [ ] Resource Server validando o JWT com a chave pública
- [ ] Queries `historicoPaciente` e `minhasConsultas` com filtro `Periodo` e paginação
- [ ] Regra do PACIENTE: `pacienteId` do token, comparação obrigatória
- [ ] `@BatchMapping` onde houver campo relacionado, com teste que conta queries

Pronto quando: os critérios de F5 passam e a consulta “só futuras” responde no GraphiQL.

### Sprint 5 — Resiliência e observabilidade

Objetivo: o sistema degrada com controle quando algo falha, e você consegue ver o que acontece.

- [ ] Circuit breaker e retry no envio de e-mail (Resilience4j ou `@Retryable`), com fallback que mantém o lembrete PENDENTE
- [ ] Timeout configurado no SMTP
- [ ] Actuator com `health`, `info`, `metrics`, `prometheus`; health do RabbitMQ e do banco
- [ ] Logs em JSON com `consultaId` e `eventId` no MDC, para rastrear um evento pelos três serviços
- [ ] Opcional: Prometheus e Grafana no compose com um painel de latência p95 e mensagens na DLQ
- [ ] Opcional: Spring Cloud Gateway na frente dos serviços (aula 4 de Segurança)

Pronto quando: derrubar o Mailpit não derruba o serviço de notificações, e os lembretes saem quando ele volta.

### Sprint 6 — Qualidade e entrega

Objetivo: um professor clona o repositório, sobe tudo e valida cada requisito em menos de 15 minutos.

- [ ] Collection Postman com variáveis de ambiente, uma pasta por perfil e scripts que salvam o token
- [ ] README: arquitetura (diagrama), como rodar, usuários de teste, endpoints, exemplos GraphQL, decisões
- [ ] OWASP ZAP baseline contra o agendamento; corrigir alertas Altos e anexar relatório
- [ ] Revisão final contra o checklist da seção Testes e entregáveis
- [ ] Tag `v1.0.0` no repositório

Pronto quando: um clone novo em outra máquina roda de ponta a ponta seguindo só o README.

## Trechos de código de referência

Os trechos abaixo são o esqueleto das partes que mais dão trabalho; o restante (entidades, repositórios, DTOs) segue o padrão das aulas. Estão escritos para Spring Boot 4; onde a versão 3.5 muda algo, há um comentário.

### 1. Segurança do agendamento: Basic para obter o token, JWT para o resto

Duas cadeias de filtros: a primeira só atende `/auth/token` e aceita HTTP Basic; a segunda protege o resto com JWT. As chaves vêm de arquivos PEM indicados por variável de ambiente.

```java
@ConfigurationProperties(prefix = "jwt")
public record RsaKeyProperties(RSAPublicKey publicKey, RSAPrivateKey privateKey) {}

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@EnableConfigurationProperties(RsaKeyProperties.class)
public class SecurityConfig {

    @Bean
    @Order(1)
    SecurityFilterChain tokenChain(HttpSecurity http) throws Exception {
        http.securityMatcher("/auth/token")
            .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
            .httpBasic(Customizer.withDefaults())
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        return http.build();
    }

    @Bean
    @Order(2)
    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health", "/graphiql/**").permitAll()
                .anyRequest().authenticated())
            .oauth2ResourceServer(o -> o.jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthConverter())))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        return http.build();
    }

    @Bean
    JwtAuthenticationConverter jwtAuthConverter() {
        var authorities = new JwtGrantedAuthoritiesConverter();
        authorities.setAuthoritiesClaimName("roles");
        authorities.setAuthorityPrefix("ROLE_");
        var converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(authorities);
        return converter;
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    JwtEncoder jwtEncoder(RsaKeyProperties keys) {
        JWK jwk = new RSAKey.Builder(keys.publicKey()).privateKey(keys.privateKey()).build();
        return new NimbusJwtEncoder(new ImmutableJWKSet<>(new JWKSet(jwk)));
    }

    @Bean
    JwtDecoder jwtDecoder(RsaKeyProperties keys) {
        return NimbusJwtDecoder.withPublicKey(keys.publicKey()).build();
    }
}
```

```yaml
jwt:
  public-key: ${JWT_PUBLIC_KEY:classpath:certs/public.pem}
  private-key: ${JWT_PRIVATE_KEY:file:./certs/private.pem}   # nunca commitar
```

A chave privada precisa estar em PKCS#8 (`BEGIN PRIVATE KEY`). O OpenSSL 3 já gera assim; em versões antigas, converta com `openssl pkcs8 -topk8 -nocrypt -in private_key.pem -out private.pem`.

### 2. Emissão do token

```java
@RestController
@RequestMapping("/auth")
public class TokenController {

    private final JwtEncoder jwtEncoder;
    private final UsuarioRepository usuarioRepository;

    public TokenController(JwtEncoder jwtEncoder, UsuarioRepository usuarioRepository) {
        this.jwtEncoder = jwtEncoder;
        this.usuarioRepository = usuarioRepository;
    }

    @PostMapping("/token")
    public TokenResponse token(Authentication authentication) {
        Instant agora = Instant.now();
        List<String> roles = authentication.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)
            .map(a -> a.replace("ROLE_", ""))
            .toList();

        JwtClaimsSet.Builder claims = JwtClaimsSet.builder()
            .issuer("agendamento-service")
            .issuedAt(agora)
            .expiresAt(agora.plus(1, ChronoUnit.HOURS))
            .subject(authentication.getName())
            .claim("roles", roles);

        usuarioRepository.findByUsername(authentication.getName())
            .map(Usuario::getPacienteId)
            .ifPresent(id -> claims.claim("pacienteId", id.toString()));

        String token = jwtEncoder.encode(JwtEncoderParameters.from(claims.build())).getTokenValue();
        return new TokenResponse(token, "Bearer", 3600);
    }
}
```

### 3. Mutations GraphQL com autorização por método

```java
@Controller
public class ConsultaGraphQlController {

    private final ConsultaService consultaService;

    public ConsultaGraphQlController(ConsultaService consultaService) {
        this.consultaService = consultaService;
    }

    @MutationMapping
    @PreAuthorize("hasAnyRole('MEDICO','ENFERMEIRO')")
    public ConsultaView agendarConsulta(@Argument @Valid AgendarConsultaInput input,
                                        Authentication autor) {
        return consultaService.agendar(input, autor.getName());
    }

    @MutationMapping
    @PreAuthorize("hasAnyRole('MEDICO','ENFERMEIRO')")
    public ConsultaView atualizarConsulta(@Argument UUID id, @Argument AtualizarConsultaInput input) {
        return consultaService.atualizar(id, input);
    }

    @MutationMapping
    @PreAuthorize("hasRole('MEDICO')")
    public ConsultaView registrarAtendimento(@Argument UUID id, @Argument String observacoes) {
        return consultaService.registrarAtendimento(id, observacoes);
    }
}

public record AgendarConsultaInput(
    @NotNull UUID pacienteId,
    @NotNull UUID medicoId,
    @NotNull @Future OffsetDateTime dataHora,
    @Size(max = 500) String motivo) {}

@Configuration
class GraphQlConfig {
    @Bean
    RuntimeWiringConfigurer scalars() {
        return wiring -> wiring.scalar(ExtendedScalars.DateTime); // graphql-java-extended-scalars
    }
}
```

Devolva um DTO (`ConsultaView`) montado dentro da transação, nunca a entidade JPA: evita `LazyInitializationException` e vazamento de campos internos. O Spring for GraphQL já traduz `AccessDeniedException` em `FORBIDDEN`; para as suas exceções de negócio:

```java
@Component
public class GraphQlExceptionHandler extends DataFetcherExceptionResolverAdapter {
    @Override
    protected GraphQLError resolveToSingleError(Throwable ex, DataFetchingEnvironment env) {
        ErrorType tipo = switch (ex) {
            case RegraNegocioException e -> ErrorType.BAD_REQUEST;
            case RecursoNaoEncontradoException e -> ErrorType.NOT_FOUND;
            default -> null;
        };
        return tipo == null ? null
            : GraphqlErrorBuilder.newError(env).errorType(tipo).message(ex.getMessage()).build();
    }
}
```

### 4. Publicando o evento só depois do commit

```java
@Service
public class ConsultaService {
    // ...
    @Transactional
    public ConsultaView agendar(AgendarConsultaInput input, String autor) {
        validarConflitoDeHorario(input.medicoId(), input.dataHora());
        Consulta consulta = consultaRepository.save(Consulta.nova(input, autor));
        eventos.publishEvent(ConsultaEvent.de(TipoEvento.CONSULTA_CRIADA, consulta));
        return ConsultaView.de(consulta);
    }
}

@Component
public class ConsultaEventPublisher {
    private final RabbitTemplate rabbitTemplate;

    public ConsultaEventPublisher(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void publicar(ConsultaEvent evento) {
        rabbitTemplate.convertAndSend("hospital.consultas", evento.routingKey(), evento);
    }
}
```

### 5. Filas, DLQ e retry no serviço de notificações

```java
@Configuration
public class RabbitConfig {

    @Bean TopicExchange consultasExchange() {
        return ExchangeBuilder.topicExchange("hospital.consultas").durable(true).build();
    }

    @Bean DirectExchange deadLetterExchange() {
        return ExchangeBuilder.directExchange("hospital.consultas.dlx").durable(true).build();
    }

    @Bean Queue notificacaoQueue() {
        return QueueBuilder.durable("notificacao.consultas")
            .deadLetterExchange("hospital.consultas.dlx")
            .deadLetterRoutingKey("notificacao.consultas.dlq")
            .build();
    }

    @Bean Queue notificacaoDlq() {
        return QueueBuilder.durable("notificacao.consultas.dlq").build();
    }

    @Bean Binding notificacaoBinding(Queue notificacaoQueue, TopicExchange consultasExchange) {
        return BindingBuilder.bind(notificacaoQueue).to(consultasExchange).with("consulta.*");
    }

    @Bean Binding dlqBinding(Queue notificacaoDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(notificacaoDlq).to(deadLetterExchange).with("notificacao.consultas.dlq");
    }

    @Bean MessageConverter jsonConverter() {
        return new JacksonJsonMessageConverter(); // Spring Boot 3.5: Jackson2JsonMessageConverter
    }
}
```

```yaml
spring:
  rabbitmq:
    listener:
      simple:
        default-requeue-rejected: false   # rejeitada vai para a DLQ, não volta para a fila
        retry:
          enabled: true
          max-attempts: 3
          initial-interval: 1s
          multiplier: 2
```

### 6. Consumidor idempotente e lembrete agendado

```java
@Component
public class ConsultaEventListener {

    private final EventoProcessadoRepository processados;
    private final LembreteService lembretes;

    public ConsultaEventListener(EventoProcessadoRepository processados, LembreteService lembretes) {
        this.processados = processados;
        this.lembretes = lembretes;
    }

    @RabbitListener(queues = "notificacao.consultas")
    @Transactional
    public void onEvento(ConsultaEvent evento) {
        if (processados.existsById(evento.eventId())) {
            return; // entrega duplicada: ignora
        }
        switch (evento.tipo()) {
            case CONSULTA_CRIADA, CONSULTA_ATUALIZADA -> lembretes.confirmarEAgendar(evento);
            case CONSULTA_CANCELADA -> lembretes.cancelar(evento.consultaId());
            case CONSULTA_REALIZADA -> { }
        }
        processados.save(new EventoProcessado(evento.eventId(), Instant.now()));
    }
}

@Component
public class LembreteScheduler {
    // @EnableScheduling na classe principal
    @Scheduled(fixedDelayString = "PT1M")
    @Transactional
    public void enviarVencidos() {
        lembreteRepository.findByStatusAndEnviarEmBefore(StatusLembrete.PENDENTE, Instant.now())
            .forEach(lembrete -> {
                emailService.enviarLembrete(lembrete);  // com retry + circuit breaker
                lembrete.marcarEnviado();
            });
    }
}
```

### 7. Histórico: paciente só vê o próprio

```java
@Controller
public class HistoricoGraphQlController {

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    public PaginaHistorico historicoPaciente(@Argument UUID pacienteId, @Argument Periodo periodo,
                                             @Argument int pagina, @Argument int tamanho,
                                             @AuthenticationPrincipal Jwt jwt) {
        acessoPaciente.verificar(jwt, pacienteId);
        return historicoService.buscar(pacienteId, periodo, PageRequest.of(pagina, tamanho));
    }

    @QueryMapping
    @PreAuthorize("hasRole('PACIENTE')")
    public List<ConsultaHistorico> minhasConsultas(@Argument Periodo periodo,
                                                   @AuthenticationPrincipal Jwt jwt) {
        UUID pacienteId = UUID.fromString(jwt.getClaimAsString("pacienteId"));
        return historicoService.buscar(pacienteId, periodo, Pageable.unpaged()).itens();
    }
}

@Component
public class AcessoPaciente {
    public void verificar(Jwt jwt, UUID pacienteId) {
        List<String> roles = jwt.getClaimAsStringList("roles");
        if (roles.contains("MEDICO") || roles.contains("ENFERMEIRO")) {
            return;
        }
        if (!pacienteId.toString().equals(jwt.getClaimAsString("pacienteId"))) {
            throw new AccessDeniedException("Paciente só acessa o próprio histórico");
        }
    }
}
```

```java
// HistoricoService.buscar: o filtro do enunciado ("todas" ou "só as futuras")
Page<ConsultaHistorico> pagina = switch (periodo) {
    case FUTURAS -> repo.findByPacienteIdAndDataHoraAfterOrderByDataHoraAsc(pacienteId, agora, pageable);
    case PASSADAS -> repo.findByPacienteIdAndDataHoraBeforeOrderByDataHoraDesc(pacienteId, agora, pageable);
    case TODAS -> repo.findByPacienteIdOrderByDataHoraDesc(pacienteId, pageable);
};
```

### 8. Docker Compose (trecho)

```yaml
services:
  rabbitmq:
    image: rabbitmq:4-management
    ports: ["5672:5672", "15672:15672"]
  mailpit:
    image: axllent/mailpit
    ports: ["1025:1025", "8025:8025"]
  db-agendamento:
    image: postgres:16
    environment:
      POSTGRES_DB: agendamento
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD:-app}
  agendamento-service:
    build: ./agendamento-service
    ports: ["8081:8080"]
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db-agendamento:5432/agendamento
      SPRING_RABBITMQ_HOST: rabbitmq
      JWT_PRIVATE_KEY: file:/run/secrets/jwt_private
    depends_on: [db-agendamento, rabbitmq]
  # notificacao-service (8082), historico-service (8083) e seus bancos seguem o mesmo padrão
```

## Testes, entregáveis e checklist final

A regra do SDD aqui é simples: cada critério de aceite tem pelo menos um teste com o código dele no nome (por exemplo `F2_CA3_conflitoDeHorarioRetornaErro`). Assim o professor lê a spec e encontra o teste que a prova.

### Pirâmide de testes

| Tipo | Ferramenta | O que cobre |
| --- | --- | --- |
| Unitário | JUnit 5 + Mockito + AssertJ | Regras do `ConsultaService` (data futura, conflito, transições de status), cálculo do `enviarEm` do lembrete |
| Segurança | spring-security-test (`httpBasic`, `jwt()` do MockMvc) | Matriz de permissões inteira: uma linha da tabela, um teste por perfil |
| GraphQL | `HttpGraphQlTester` com `@SpringBootTest` | Mutations e queries, códigos de erro, filtro FUTURAS |
| Integração com banco | Testcontainers PostgreSQL + Flyway | Repositórios, `@Version`, migrações |
| Integração com broker | Testcontainers RabbitMQ + Awaitility | Evento publicado após commit, consumo, duplicado ignorado, DLQ |
| Segurança dinâmica | OWASP ZAP baseline (Docker) | Cabeçalhos, exposição de erros, configurações inseguras |

Exemplo de teste de permissão:

```java
@Test
void F3_CA3_enfermeiroNaoRegistraAtendimento() {
    graphQlTester
        .mutate().headers(h -> h.setBearerAuth(tokenDe("enf.ana"))).build()
        .document("""
            mutation { registrarAtendimento(id: "%s", observacoes: "ok") { id } }
            """.formatted(consultaId))
        .execute()
        .errors()
        .expect(e -> e.getErrorType() == ErrorType.FORBIDDEN);
}
```

### Collection Postman

- Ambiente com `baseAgendamento`, `baseHistorico`, `token`.
- Pasta “0. Autenticação”: um `POST /auth/token` por perfil; o script de teste salva o token: `pm.environment.set("token", pm.response.json().accessToken)`.
- Pastas “1. Médico”, “2. Enfermeiro”, “3. Paciente” com as requisições GraphQL (o Postman tem corpo do tipo GraphQL) e testes que conferem status e código de erro esperado.
- Pasta “4. Cenários negativos”: sem token, token adulterado, paciente pedindo histórico alheio.
- Exporte para `postman/hospital.postman_collection.json` e o ambiente para `postman/local.postman_environment.json`.

### Roteiro do README

1. O que é o sistema e quais requisitos atende (tabela da Visão geral).
2. Diagrama de arquitetura e fluxo de eventos.
3. Como rodar: pré-requisitos, gerar chaves, `docker compose up --build`, portas.
4. Usuários de demonstração com senha e perfil.
5. Endpoints: REST (`/auth/token`, actuator) e GraphQL (link para o GraphiQL, exemplos de query e mutation).
6. Mensageria: exchange, filas, DLQ, como ver no painel do RabbitMQ (porta 15672) e os e-mails no Mailpit (porta 8025).
7. Decisões (link para os ADRs) e interpretação das permissões.
8. Como rodar os testes e onde está o relatório do ZAP.

### Checklist de entrega por critério de avaliação

**Funcionalidade**

- [ ] Os três perfis autenticam e recebem token
- [ ] Cada linha da matriz de permissões se comporta como especificado
- [ ] GraphQL lista todos os atendimentos e só os futuros
- [ ] Criar ou editar consulta gera mensagem no RabbitMQ e e-mail no Mailpit
- [ ] Lembrete automático sai 24 horas antes

**Qualidade do código**

- [ ] Pacotes por responsabilidade, nomes consistentes, sem lógica de negócio em controller
- [ ] Injeção por construtor, DTOs como `record`, entidades fora da API
- [ ] Nenhuma senha ou chave privada no repositório
- [ ] `mvn verify` verde

**Documentação**

- [ ] README cobre os 8 tópicos do roteiro acima
- [ ] Specs (`specs/`) e ADRs (`docs/adr/`) no repositório

**Collections**

- [ ] Collection e ambiente Postman exportados e testados do zero

**Repositório**

- [ ] Público, com histórico de commits legível (um commit por tarefa do `tasks.md` ajuda)
- [ ] Clone limpo roda seguindo só o README
