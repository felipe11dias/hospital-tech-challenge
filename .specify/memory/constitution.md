<!--
SYNC IMPACT REPORT — material de revisão humana, remover antes do merge definitivo
Mudança de versão: (template não preenchido) → 1.0.0
Tipo de bump: ratificação inicial (nenhuma governança anterior existia)

Princípios definidos (template → projeto):
- [PRINCIPLE_1_NAME] → I. Spec-First (NÃO NEGOCIÁVEL)
- [PRINCIPLE_2_NAME] → II. Rastreabilidade Critério→Teste (NÃO NEGOCIÁVEL)
- [PRINCIPLE_3_NAME] → III. Segurança por Padrão
- [PRINCIPLE_4_NAME] → IV. Autonomia de Serviço e Dados
- [PRINCIPLE_5_NAME] → V. Mensageria Confiável
- (novo)             → VI. Fronteiras de Camada e Clean Code
- (novo)             → VII. Operabilidade e Reprodutibilidade

Seções adicionadas:
- [SECTION_2_NAME] → Stack Obrigatória
- [SECTION_3_NAME] → Fluxo de Desenvolvimento e Definição de Pronto
- Governance → preenchida com procedimento de emenda, política de versionamento e revisão por sprint

Seções removidas: nenhuma
Placeholders remanescentes: nenhum
TODOs diferidos: nenhum

Desvio consciente do roadmap: o roadmap (19/11/2026) fixa Spring Boot 4.0.x; esta constituição
fixa 4.2.0, o GA vigente em 23/11/2026, preservando a intenção declarada no roadmap ("a geração
com suporte gratuito hoje"). Registrado em docs/adr/ADR-007.
-->

# Sistema Hospitalar — Tech Challenge Fase 3 · Constituição

Backend hospitalar em três microsserviços Spring Boot (agendamento, notificações e histórico),
com autenticação e autorização por perfil, consultas GraphQL e integração assíncrona por
RabbitMQ. O desenvolvimento segue Spec-Driven Development (SDD): a especificação é a fonte da
verdade e o código é a forma de cumpri-la.

## Core Principles

### I. Spec-First (NÃO NEGOCIÁVEL)

Nenhuma linha de código de produção pode ser escrita antes de existir, no repositório, a
`spec.md` que ela implementa. `plan.md` e `tasks.md` da funcionalidade MUST estar versionados
antes do primeiro commit de implementação dessa funcionalidade. Toda mudança de comportamento
MUST começar pela alteração da spec correspondente; corrigir o código e deixar a spec defasada
é violação. Specs vivem em `specs/NNN-nome/`, e mudanças de spec ficam registradas no histórico
do Git, nunca apagadas.

Racional: em SDD a spec é o contrato que o avaliador lê para conferir o sistema. Se o código
anda na frente, perde-se a única fonte verificável de intenção.

### II. Rastreabilidade Critério→Teste (NÃO NEGOCIÁVEL)

Todo critério de aceite de toda spec MUST ter ao menos um teste automatizado cujo nome carregue
o código do critério, no formato `F<n>_CA<m>_descricaoCurta` (exemplo:
`F2_CA3_conflitoDeHorarioRetornaErro`). Um critério sem teste correspondente bloqueia o fim da
sprint. `mvn verify` verde é condição de pronto, não opcional: build vermelho não entrega.

Racional: o nome do teste é o índice que liga a spec à prova. Quem lê a spec encontra o teste
sem procurar.

### III. Segurança por Padrão

Todo endpoint e toda operação GraphQL são autenticados por padrão; a liberação é explícita e
limitada a `/actuator/health` e ao GraphiQL em perfil local. Senhas MUST ser persistidas apenas
como hash BCrypt — nenhuma senha em texto puro, em nenhuma migração, fixture ou teste. O JWT é
RS256 e a chave privada MUST vir de variável de ambiente ou volume, nunca do repositório.
Autorização MUST ser declarada por `@PreAuthorize` na operação, refletindo a matriz de
permissões da spec F1. O `pacienteId` usado em qualquer consulta de paciente MUST ser derivado
do claim do token, nunca de argumento enviado pelo cliente. Nenhum segredo (senha, chave, token)
pode ser versionado; `*.pem` e `.env` ficam no `.gitignore`.

### IV. Autonomia de Serviço e Dados

Cada serviço MUST ter seu próprio banco PostgreSQL, com schema evoluído exclusivamente por
migrações Flyway. Nenhum serviço pode ler ou escrever tabela de outro serviço, nem compartilhar
conexão de banco. A integração entre serviços MUST acontecer somente por eventos RabbitMQ. O
contrato de evento MUST ser duplicado como `record` dentro de cada serviço; compartilhar um JAR
de modelo é proibido, porque acoplaria o ciclo de release dos serviços.

Racional: autonomia de dados é o que torna os três serviços microsserviços de fato, e não um
monólito distribuído.

### V. Mensageria Confiável

Eventos MUST ser publicados somente após o commit da transação que os originou
(`@TransactionalEventListener(phase = AFTER_COMMIT)`): nunca se anuncia um fato que não foi
gravado. Exchange, filas e mensagens MUST ser duráveis. Todo evento carrega `eventId` (UUID) e
todo consumidor MUST ser idempotente por `eventId`, porque a entrega é "pelo menos uma vez".
Falha de processamento MUST sofrer retry com backoff e, esgotado o retry, ir para a DLQ sem
reenfileirar na fila principal. A indisponibilidade de um consumidor MUST NOT afetar o produtor.

### VI. Fronteiras de Camada e Clean Code

Controller (REST ou GraphQL) não contém regra de negócio: apenas valida entrada, autoriza e
delega. Regra de negócio mora exclusivamente em `service`. Entidade JPA MUST NOT cruzar a borda
da API — a resposta é sempre um DTO `record` montado dentro da transação. Dependências MUST ser
injetadas por construtor (sem `@Autowired` em campo). Nomes do domínio em português
(`Consulta`, `agendarConsulta`, `motivo`); nomes de infraestrutura e de artefatos técnicos em
inglês (`repository`, `config`, `SecurityConfig`). Erros GraphQL MUST usar os códigos
padronizados `BAD_REQUEST`, `FORBIDDEN` e `NOT_FOUND`, com mensagem de negócio e sem stack
trace na resposta.

### VII. Operabilidade e Reprodutibilidade

`docker compose up` MUST subir a solução inteira em máquina limpa, sem passo manual além de
gerar o par de chaves RSA documentado no README. Cada serviço MUST expor `/actuator/health` e
`/actuator/prometheus`. Logs MUST carregar `consultaId` e `eventId` no MDC, para rastrear um
evento pelos três serviços. Toda decisão de arquitetura MUST ser registrada como ADR numerado
em `docs/adr/`; decisão sem ADR é decisão não tomada.

## Stack Obrigatória

| Camada | Tecnologia fixada |
| --- | --- |
| Linguagem e build | Java 21 (LTS), Maven multi-módulo com `pom` pai |
| Framework | Spring Boot 4.2.0 (Web, Validation, Data JPA, Actuator) |
| Segurança | Spring Security + OAuth2 Resource Server (JWT RS256) + BCrypt |
| API de consulta | Spring for GraphQL, schema-first, GraphiQL em local |
| Mensageria | Spring AMQP com RabbitMQ 4 (topic exchange, filas duráveis, DLQ) |
| Banco | PostgreSQL 16, um banco por serviço, migrações Flyway |
| Resiliência | Resilience4j (Retry, CircuitBreaker) |
| Observabilidade | Actuator + Micrometer Prometheus |
| E-mail de teste | Mailpit (SMTP falso com caixa de entrada web) |
| Testes | JUnit 5, Mockito, AssertJ, spring-security-test, `HttpGraphQlTester`, Testcontainers |
| Infra local | Docker Compose (3 serviços, 3 bancos, RabbitMQ, Mailpit) |

Qualquer desvio desta tabela — troca de versão, de biblioteca ou de banco — MUST ser registrado
como ADR antes de ser implementado.

## Fluxo de Desenvolvimento e Definição de Pronto

O ciclo de cada funcionalidade segue os comandos do Spec Kit nesta ordem:

`/speckit-constitution` → `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` →
`/speckit-tasks` → `/speckit-implement` → `/speckit-analyze`

Regras do fluxo:

- Um commit por tarefa do `tasks.md`, com mensagem que cite o identificador da tarefa.
- `/speckit-clarify` MUST ser executado sempre que a spec contiver marcador
  `[NEEDS CLARIFICATION]`; nenhum plano é gerado sobre spec com pergunta aberta.
- `/speckit-analyze` MUST rodar antes de fechar a sprint, para checar consistência entre
  `spec.md`, `plan.md` e `tasks.md`.

**Definição de pronto** (todas as condições, sem exceção):

1. Todos os critérios de aceite da spec têm teste automatizado nomeado conforme o Princípio II,
   e `mvn verify` está verde.
2. `spec.md`, `plan.md` e `tasks.md` da funcionalidade estão versionados e consistentes.
3. Toda decisão de arquitetura tomada no caminho tem ADR em `docs/adr/`.
4. O README reflete o estado atual (como rodar, endpoints, usuários de demonstração).
5. Nenhum segredo foi versionado (`git grep` por chave privada e senha em texto puro limpo).

## Governance

Esta constituição prevalece sobre qualquer outra prática, convenção pessoal ou sugestão de
ferramenta. Em conflito entre esta constituição e um plano, uma task ou um hábito de código, a
constituição ganha e o outro artefato MUST ser corrigido.

**Procedimento de emenda.** Uma emenda MUST: (a) ser proposta por escrito no próprio arquivo,
(b) receber bump de versão semântico, (c) registrar data e (d) ser descrita no Sync Impact
Report no topo do arquivo.

**Política de versionamento.** MAJOR para remoção ou redefinição incompatível de princípio ou
de governança; MINOR para novo princípio ou seção, ou ampliação material de orientação; PATCH
para esclarecimento, redação ou correção sem efeito semântico.

**Revisão de conformidade.** A cada fim de sprint, a definição de pronto do sprint MUST ser
conferida contra esta constituição, princípio por princípio. Violação encontrada em revisão
bloqueia o fechamento do sprint até ser corrigida ou explicitamente emendada aqui.

**Version**: 1.0.0 | **Ratified**: 2026-11-23 | **Last Amended**: 2026-11-23
