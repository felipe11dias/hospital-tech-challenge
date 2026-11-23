# Relatório da Sprint 0 — Fundação e specs

**Projeto:** Sistema Hospitalar — Tech Challenge Fase 3 (POSTECH)
**Data de execução:** 23/11/2026
**Objetivo da sprint (roadmap):** repositório, infraestrutura local e todas as specs escritas
antes do primeiro `@Service`.
**Definição de pronto (roadmap):** `docker compose up` sobe a infraestrutura, os três serviços
iniciam vazios e respondem em `/actuator/health`.

---

## 1. Resumo executivo

A Sprint 0 fecha com os sete itens do roadmap entregues: constituição, seis specs, três projetos
Spring Boot num build multi-módulo, `docker-compose.yml` com toda a infraestrutura, sete ADRs
(seis previstos mais um registrando um desvio) e integração contínua rodando `mvn verify`.

Duas decisões foram tomadas no caminho e estão justificadas na seção
[Decisões tomadas](#5-decisões-tomadas-durante-a-sprint): **Spring Boot 4.2.0** em vez do 4.0.x
que o roadmap fixava, e um **esqueleto de `SecurityConfig`** necessário para que o health check
responda sem antecipar a F1.

| Entregável do roadmap | Estado | Onde está |
| --- | --- | --- |
| Repositório com README, `.gitignore` (inclui `*.pem`) e licença | feito | [`README.md`](../../README.md), [`.gitignore`](../../.gitignore), [`LICENSE`](../../LICENSE) |
| `constitution.md` | feito | [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) v1.0.0 |
| `spec.md` de F1 a F6 | feito | [`specs/`](../../specs/constitution.md) — 6 pastas |
| Três projetos no Spring Initializr em `pom` pai multi-módulo | feito | [`pom.xml`](../../pom.xml) + 3 módulos |
| `docker-compose.yml` (3 PostgreSQL, RabbitMQ, Mailpit) | feito | [`docker-compose.yml`](../../docker-compose.yml) |
| ADR-001 a ADR-006 | feito (+ ADR-007) | [`docs/adr/`](../adr/README.md) |
| Opcional: GitHub Actions com `mvn verify` | feito | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |

---

## 2. Passo a passo do que foi feito

### Passo 1 — Leitura das fontes antes de escrever qualquer coisa

Antes de criar arquivo, três fontes foram lidas por inteiro, porque em SDD a spec não pode ser
inventada:

| Fonte | O que foi extraído |
| --- | --- |
| [`docs/desafio/ADJT - BB - Tech Challenge - Fase 3 (1).pdf`](../desafio/) (5 páginas) | Os quatro requisitos do sistema e os cinco fatores de avaliação, nas palavras do enunciado |
| [`docs/Roadmap SDD...`](<../Roadmap SDD — Tech Challenge Fase 3 (Sistema Hospitalar).md>) (886 linhas) | Stack, arquitetura, matriz de permissões, critérios de aceite por funcionalidade, contratos GraphQL e de eventos, as 7 sprints |
| [`docs/aulas/`](../aulas/) (20 PDFs) | Origem técnica de cada escolha: Segurança (aulas 1 a 5), Mensageria (1 a 5), Distribuídos (1 a 4), gRPC/GraphQL (1 a 4) |

Ponto que mudou o rumo da sprint: o enunciado permite **RabbitMQ ou Kafka**, e as aulas cobrem
os dois. Isso tornou obrigatório justificar a escolha por escrito — virou o ADR-001.

### Passo 2 — Inventário do ambiente

Verificação do que a máquina tem, para decidir como a definição de pronto seria alcançada:

| Ferramenta | Resultado |
| --- | --- |
| Docker / Docker Compose | 29.6.1 / v5.2.0 — disponível |
| Java | **ausente** no PATH |
| Maven | **ausente** no PATH |

A ausência de Java e Maven na máquina não bloqueou a sprint: ela **determinou o desenho do
build**. O [`Dockerfile`](../../Dockerfile) compila os três módulos dentro da imagem, o que
atende diretamente o FR-001 da F6 ("sem exigir Java ou Maven na máquina do avaliador") e é o que
torna a definição de pronto verificável em máquina limpa.

Também foi consultado o metadata do Spring Initializr (`https://start.spring.io/metadata/client`)
para saber quais versões estavam efetivamente disponíveis — o que revelou a divergência com o
roadmap tratada no ADR-007.

### Passo 3 — Constituição (`/speckit-constitution`)

A skill `speckit-constitution` foi invocada com o prompt
[P0](../sdd/prompts-spec-kit.md#p0--constituição). O fluxo seguido foi o que a própria skill
define:

1. Resolução do template ativo via
   `.specify/scripts/powershell/resolve-template.ps1 constitution-template -Json`.
2. Verificação de hooks em `.specify/extensions.yml` — arquivo inexistente, nenhum hook.
3. Preenchimento de **todos** os placeholders `[ALL_CAPS]` do template.
4. Sync Impact Report como comentário HTML no topo do arquivo.
5. Validação: zero tokens entre colchetes remanescentes, datas em ISO, princípios redigidos em
   MUST/MUST NOT.

Resultado: **v1.0.0**, ratificada em 2026-11-23, com sete princípios (o template trazia cinco;
a skill respeita a quantidade pedida no prompt):

| # | Princípio | O que ele bloqueia na prática |
| --- | --- | --- |
| I | Spec-First (não negociável) | código de produção sem spec versionada |
| II | Rastreabilidade Critério→Teste (não negociável) | critério de aceite sem teste nomeado `F<n>_CA<m>_...`; `mvn verify` vermelho |
| III | Segurança por Padrão | senha fora do BCrypt, chave privada versionada, `pacienteId` vindo do cliente |
| IV | Autonomia de Serviço e Dados | um serviço lendo tabela de outro; JAR de modelo compartilhado |
| V | Mensageria Confiável | publicar antes do commit; consumidor não idempotente; fila sem DLQ |
| VI | Fronteiras de Camada e Clean Code | regra de negócio em controller; entidade JPA na borda da API |
| VII | Operabilidade e Reprodutibilidade | decisão de arquitetura sem ADR; serviço sem health e métricas |

Mais duas seções obrigatórias: **Stack Obrigatória** (desvio exige ADR) e **Fluxo de
Desenvolvimento e Definição de Pronto** (ordem dos comandos, um commit por tarefa, cinco
condições de pronto).

O roadmap citava o caminho `specs/constitution.md`, mas o Spec Kit lê
`.specify/memory/constitution.md` em tempo de execução. Para não criar duas fontes de governança
divergentes, o conteúdo ficou no caminho canônico e
[`specs/constitution.md`](../../specs/constitution.md) é um **ponteiro** com o índice das specs.

### Passo 4 — As seis especificações (`/speckit-specify`)

As pastas foram criadas pelo script oficial do Spec Kit, uma invocação por feature:

```powershell
.specify\scripts\powershell\create-new-feature.ps1 -Json -ShortName autenticacao "Autenticacao com Spring Security e acesso por perfil MEDICO ENFERMEIRO PACIENTE"
```

O script resolveu a numeração sequencial (`feature_numbering: "sequential"` em
`.specify/init-options.json`), criou a pasta, gravou o `spec.md` a partir do template resolvido e
atualizou `.specify/feature.json`. Resultado:

```text
specs/001-autenticacao/        specs/004-notificacao/
specs/002-agendar-consulta/    specs/005-historico-graphql/
specs/003-modificar-consulta/  specs/006-operabilidade/
```

O conteúdo de cada `spec.md` foi então escrito seguindo o contrato de `/speckit-specify`:
preencher a estrutura do template, manter a ordem das seções, descrever **o quê** e **por quê**
sem decidir o **como**, e validar contra o checklist de qualidade. Os prompts correspondentes
estão registrados em [`docs/sdd/prompts-spec-kit.md`](../sdd/prompts-spec-kit.md) (P1 a P6), cada
um capaz de regerar individualmente a sua spec.

| Spec | Histórias | Critérios de aceite | Requisitos funcionais |
| --- | --- | --- | --- |
| [F1 Autenticação](../../specs/001-autenticacao/spec.md) | 4 | 13 | 12 + matriz de permissões |
| [F2 Agendar consulta](../../specs/002-agendar-consulta/spec.md) | 3 | 9 | 12 + RN1 a RN3 |
| [F3 Modificar consulta](../../specs/003-modificar-consulta/spec.md) | 4 | 15 | 13 |
| [F4 Notificar paciente](../../specs/004-notificacao/spec.md) | 4 | 16 | 14 |
| [F5 Histórico GraphQL](../../specs/005-historico-graphql/spec.md) | 4 | 15 | 15 |
| [F6 Operabilidade](../../specs/006-operabilidade/spec.md) | 4 | 16 | 14 |

Cada spec tem também `checklists/requirements.md`, o checklist de qualidade que o
`/speckit-specify` exige. Todos os 16 itens passaram na primeira iteração nas seis specs, com
**zero marcadores `[NEEDS CLARIFICATION]` pendentes** — porque cada ambiguidade do enunciado foi
resolvida por padrão explícito e registrada na seção `Assumptions` da própria spec, em vez de
ficar como pergunta aberta que travaria o `/speckit-plan`.

Decisões de redação que vale registrar:

- **Linguagem de negócio, não técnica.** As specs falam em "anúncio", "credencial de acesso" e
  "área de mensagens com problema", não em "evento RabbitMQ", "JWT" e "DLQ". Os nomes técnicos
  pertencem ao `plan.md`. Onde o enunciado nomeia a tecnologia (GraphQL, Postman), o nome
  aparece, porque aí ele é requisito e não escolha.
- **Critérios de aceite no formato Given/When/Then**, prontos para virar nome de teste conforme
  o Princípio II.
- **Seções `Out of Scope` e `Dependencies`** acrescentadas ao template onde faziam diferença, o
  que o template permite.

### Passo 5 — Registros de decisão (ADR)

Sete ADRs em [`docs/adr/`](../adr/README.md), cada um com contexto, decisão, alternativas
consideradas e consequências — incluindo o que a decisão **custa**, não só o que ela resolve:

| ADR | Decisão | Consequência assumida |
| --- | --- | --- |
| [001](../adr/ADR-001-rabbitmq-em-vez-de-kafka.md) | RabbitMQ em vez de Kafka | sem reprocessamento de histórico por offset — por isso o histórico mantém cópia própria |
| [002](../adr/ADR-002-jwt-stateless-emitido-pelo-agendamento.md) | JWT RS256 emitido pelo agendamento | sem revogação: token vazado vale até expirar (1 h) |
| [003](../adr/ADR-003-historico-como-modelo-de-leitura.md) | Histórico como modelo de leitura (CQRS leve) | consistência eventual, que precisa estar no README |
| [004](../adr/ADR-004-publicar-apos-o-commit.md) | Publicar o evento só após o commit | janela de perda se o processo morrer entre commit e envio |
| [005](../adr/ADR-005-consumidores-idempotentes.md) | Consumidores idempotentes por `eventId` | tabela `evento_processado` cresce indefinidamente |
| [006](../adr/ADR-006-interpretacao-das-permissoes.md) | Interpretação das permissões do enunciado | leitura precisa estar declarada no README |
| [007](../adr/ADR-007-spring-boot-4-2.md) | Spring Boot 4.2.0 em vez de 4.0.x | roadmap e constituição divergem neste ponto; a constituição prevalece |

O ADR-004 merece destaque porque é o único que escolhe entre dois tipos de falha: publicar antes
do commit arrisca **anunciar o que não existe**; publicar depois arrisca **não anunciar o que
existe**. O projeto escolhe a segunda, e o ADR diz isso em uma frase: "é melhor não avisar do que
avisar errado".

### Passo 6 — Scaffold: três projetos num build multi-módulo

Os três projetos foram gerados pela API do Spring Initializr, como o roadmap manda:

```powershell
curl -sS https://start.spring.io/starter.zip -d type=maven-project -d language=java -d bootVersion=4.2.0 -d groupId=br.com.fiap.hospital -d artifactId=agendamento-service -d packageName=br.com.fiap.hospital.agendamento -d javaVersion=21 -d dependencies=web,validation,data-jpa,postgresql,flyway,security,oauth2-resource-server,graphql,rabbitmq,actuator,prometheus,testcontainers -o agendamento-service.zip
```

Dependências por serviço:

| Serviço | Dependências do Initializr |
| --- | --- |
| `agendamento-service` | web, validation, data-jpa, postgresql, flyway, security, oauth2-resource-server, graphql, rabbitmq, actuator, prometheus, testcontainers |
| `notificacao-service` | web, validation, data-jpa, postgresql, flyway, rabbitmq, **mail**, actuator, prometheus, **cloud-resilience4j**, testcontainers |
| `historico-service` | igual ao agendamento (também é Resource Server e expõe GraphQL) |

Os projetos saem do Initializr como três builds independentes, cada um com
`spring-boot-starter-parent` como pai. Para virar um build multi-módulo:

- **[`pom.xml`](../../pom.xml) na raiz**: `packaging` pom, os três módulos, `java.version` 21,
  BOM do Spring Cloud, versões de `graphql-java-extended-scalars` (24.0) e `awaitility` (4.3.0)
  em `dependencyManagement`, e `surefire` configurado para reconhecer os padrões de nome de
  teste que o Princípio II exige.
- **Cada `pom.xml` filho** reescrito para ter o pom da raiz como pai (`relativePath ../pom.xml`),
  sem repetir versão nem `java.version`.
- **Maven wrapper movido para a raiz** (`mvnw`, `mvnw.cmd`, `.mvn/`) — um só para o build inteiro,
  em vez de três cópias.

Todos os artefatos citados foram conferidos no Maven Central antes de serem fixados
(`spring-boot-starter-webmvc` 4.2.0, `spring-cloud-dependencies` 2026.0.0,
`graphql-java-extended-scalars` 24.0, `awaitility` 4.3.0 — todos HTTP 200), em vez de confiar na
memória sobre nomes de artefato: a geração 4 do Spring Boot **renomeou os starters**
(`spring-boot-starter-web` → `spring-boot-starter-webmvc`, e cada starter ganhou um par `-test`).

Configuração de runtime acrescentada em cada serviço (Sprint 0 não implementa funcionalidade, só
o necessário para o serviço subir e ser observável):

| Arquivo | Conteúdo |
| --- | --- |
| `application.yml` | datasource, Flyway, RabbitMQ e mail por variável de ambiente com default local; `ddl-auto: validate` (o schema é do Flyway); Actuator expondo `health,info,metrics,prometheus`; padrão de log com `consultaId` e `eventId` no MDC |
| `db/migration/V1__baseline.sql` | baseline do Flyway que **não cria tabela** — comentário listando em que sprint cada tabela entra |
| `graphql/schema.graphqls` | campo `ping` mínimo, porque o Spring for GraphQL não inicia sem schema; o contrato real entra nas Sprints 2 e 4 |
| `TestcontainersConfiguration.java` | imagens fixadas em `postgres:16` e `rabbitmq:4-management` (o Initializr gera `:latest`, que a constituição não permite) |

### Passo 7 — Infraestrutura local e integração contínua

**[`Dockerfile`](../../Dockerfile)** — um único arquivo com um `target` por serviço, em vez de
três Dockerfiles. Os três módulos compartilham o pom pai e quase todas as dependências; com
targets, o BuildKit reaproveita o estágio `build` e o download do Maven acontece uma vez, não
três. Os poms são copiados antes do código-fonte, para que alterar código não invalide a camada
de dependências. O runtime roda como usuário sem privilégio.

**[`docker-compose.yml`](../../docker-compose.yml)** — oito serviços:

| Grupo | Serviços |
| --- | --- |
| Bancos (um por serviço, Princípio IV) | `db-agendamento` (5433), `db-notificacao` (5434), `db-historico` (5435), todos `postgres:16` com `pg_isready` como health check |
| Mensageria | `rabbitmq:4-management` (5672 / painel 15672) com `rabbitmq-diagnostics` como health check |
| E-mail de teste | `axllent/mailpit` (SMTP 1025 / caixa de entrada 8025) |
| Aplicação | `agendamento-service` (8081), `notificacao-service` (8082), `historico-service` (8083) |

Os serviços de aplicação usam `depends_on` com `condition: service_healthy`, para não iniciar
antes de banco e broker estarem de fato prontos. A pasta `./certs` entra por volume somente-leitura.

**Segredos** — [`.gitignore`](../../.gitignore) bloqueia `*.pem`, `*.key`, `*.jks`, `.env` e a
pasta `certs/` inteira (exceto o `.gitkeep`). [`.env.example`](../../.env.example) documenta as
variáveis sem conter segredo. [`.dockerignore`](../../.dockerignore) mantém chaves, docs e specs
fora do contexto de build.

**[`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)** — roda `./mvnw -B -ntp verify` a
cada push e PR, com JDK 21 e cache do Maven, publica os relatórios do surefire e tem um passo
extra que falha o build se `git grep` encontrar chave privada em arquivo versionado. É o
Princípio III virando porta automática.

**Par de chaves RSA** — os comandos do README foram executados de verdade para conferir que
funcionam e que o OpenSSL 3.5.7 já gera PKCS#8 (`BEGIN PRIVATE KEY`), formato que o
`NimbusJwtDecoder` exige. As chaves ficaram em `certs/`, fora do versionamento.

---

## 3. Prompts usados na concepção do Spec Kit

Os prompts estão registrados por inteiro, com justificativa, em
**[`docs/sdd/prompts-spec-kit.md`](../sdd/prompts-spec-kit.md)**. Resumo:

| Prompt | Comando | Gerou |
| --- | --- | --- |
| P0 | `/speckit-constitution` | `.specify/memory/constitution.md` v1.0.0, 7 princípios + 2 seções |
| P1 | `/speckit-specify` | `specs/001-autenticacao/` |
| P2 | `/speckit-specify` | `specs/002-agendar-consulta/` |
| P3 | `/speckit-specify` | `specs/003-modificar-consulta/` |
| P4 | `/speckit-specify` | `specs/004-notificacao/` |
| P5 | `/speckit-specify` | `specs/005-historico-graphql/` |
| P6 | `/speckit-specify` | `specs/006-operabilidade/` |

O mesmo arquivo traz os **modelos de prompt** para `/speckit-plan` e `/speckit-tasks`, que são os
comandos das Sprints 1 a 6, já com as restrições da constituição embutidas — para que o plano não
nasça contrariando a governança.

### O que faz um prompt de spec funcionar, neste projeto

Seis elementos, nesta ordem de importância:

1. **Ator e ação em linguagem de negócio.** "Médicos e enfermeiros registram novas consultas",
   não "criar o endpoint de agendamento".
2. **Regras numeradas** (RN1, RN2, RN3), que viram requisitos funcionais rastreáveis.
3. **Comportamento no caminho infeliz.** Sem isso a spec só descreve o caminho feliz e os testes
   negativos não existem. Exemplo: "quando a regra é violada, nada é gravado e nada é anunciado".
4. **Fronteira de escopo explícita** ("fora do escopo: pagamento, convênio, agenda de salas"),
   que impede o modelo de inventar requisito.
5. **Padrão para o que o enunciado não diz** ("duração padrão assumida em 30 minutos"), que evita
   um `[NEEDS CLARIFICATION]` capaz de travar o `/speckit-plan`.
6. **Idioma**, porque o domínio é nomeado em português por decisão da constituição.

E o que **não** entra: nome de classe, de anotação, de biblioteca ou de tabela — isso é `plan.md`.
Se o prompt gerar mais de três dúvidas reais, a feature está mal delimitada e deve ser quebrada:
o `/speckit-specify` aceita no máximo três marcadores de clarificação.

---

## 4. Verificação da definição de pronto

> **Pronto quando (roadmap): `docker compose up` sobe a infraestrutura, os três serviços iniciam
> vazios e respondem em `/actuator/health`.** — verificado de ponta a ponta em 23/11/2026.

### 4.1 O ambiente subiu

O Docker Desktop estava com o engine Linux parado; foi iniciado e o daemon 29.6.1 (OSType
`linux`) ficou disponível. Em seguida:

```powershell
docker compose up -d --build
```

Saiu com **exit code 0**, compilando os três módulos dentro da imagem (o reactor Maven carregou
`hospital-tech-challenge [pom]` + os três `[jar]`, confirmando que o build multi-módulo está
correto). Os oito containers subiram:

| Container | Estado |
| --- | --- |
| `hospital-db-agendamento` | running (healthy) |
| `hospital-db-notificacao` | running (healthy) |
| `hospital-db-historico` | running (healthy) |
| `hospital-rabbitmq` | running (healthy) |
| `hospital-mailpit` | running (healthy) |
| `hospital-agendamento` | running |
| `hospital-notificacao` | running |
| `hospital-historico` | running |

O `depends_on` com `condition: service_healthy` funcionou como desenhado: os serviços esperaram
banco e broker ficarem prontos antes de iniciar.

### 4.2 Os três health checks respondem

Todos **HTTP 200** com `status: UP`:

| Serviço | Porta | Status geral | Componentes |
| --- | --- | --- | --- |
| agendamento-service | 8081 | **UP** | `db` UP (PostgreSQL), `rabbit` UP (4.4.1), `diskSpace`, `ping`, `ssl`, `livenessState`, `readinessState` |
| notificacao-service | 8082 | **UP** | `db` UP, `rabbit` UP (4.4.1), **`mail` UP (`mailpit:1025`)**, `diskSpace`, `ping`, `ssl`, `refreshScope`, liveness/readiness |
| historico-service | 8083 | **UP** | `db` UP, `rabbit` UP (4.4.1), `diskSpace`, `ping`, `ssl`, liveness/readiness |

Isso confirma mais do que a definição de pronto pedia: cada serviço não só responde, como
**enxerga suas dependências reais** — o banco próprio, o broker e, no caso do notificações, o
SMTP de teste.

Um ajuste nasceu desta verificação: o `notificacao-service` reportava
`discoveryComposite: UNKNOWN`. O starter do Resilience4j arrasta o Spring Cloud Commons, que
registra contribuidores de health de *service discovery* — recurso que este projeto não usa,
porque os serviços se falam por evento e não por descoberta.

A primeira tentativa de desligar usou `management.health.discovery.enabled: false` e **não
funcionou**: o contribuidor é do Spring Cloud, não do Actuator. A propriedade correta é
`spring.cloud.discovery.client.composite-indicator.enabled: false` (com
`health-indicator.enabled: false` no mesmo bloco). Depois do ajuste, o health do 8082 mostra
apenas componentes reais:

```
status geral: UP
  db UP · diskSpace UP · livenessState UP · mail UP · ping UP
  rabbit UP · readinessState UP · refreshScope UP · ssl UP
```

### 4.3 Métricas e informações expostas

| Endpoint | 8081 | 8082 | 8083 |
| --- | --- | --- | --- |
| `/actuator/prometheus` | 200 | 200 | 200 |
| `/actuator/info` | 200 | 200 | 200 |

### 4.4 Os serviços iniciaram de fato vazios

Conferido direto no banco de cada serviço:

| Banco | Histórico do Flyway | Tabelas de domínio |
| --- | --- | --- |
| `agendamento` | `1 \| baseline \| success=t` | **0** |
| `notificacao` | `1 \| baseline \| success=t` | **0** |
| `historico` | `1 \| baseline \| success=t` | **0** |

É exatamente o estado que a Sprint 0 exige: a linha de base do Flyway aplicada em cada serviço, e
nenhuma tabela de domínio criada antes da spec que a define (Princípio I).

### 4.5 Segurança por padrão já valendo

Teste adicional, para provar que o esqueleto de `SecurityConfig` não deixou nada aberto:

| Requisição | Resultado | Esperado |
| --- | --- | --- |
| `POST /graphql` sem credencial em 8081 | **401** | 401 |
| `POST /graphql` sem credencial em 8083 | **401** | 401 |
| `GET /actuator/health` sem credencial (3 serviços) | **200** | 200 |

O Princípio III ("tudo autenticado por padrão, liberação explícita e limitada") está em vigor
desde o primeiro commit, e não a partir da Sprint 1.

### 4.6 Geração de chaves conforme o README

Os comandos documentados foram executados de verdade, com OpenSSL 3.5.7:

```
certs/private.pem  →  -----BEGIN PRIVATE KEY-----   (PKCS#8, formato que o NimbusJwtDecoder exige)
certs/public.pem   →  -----BEGIN PUBLIC KEY-----
```

Ambos confirmados como **ignorados** pelo Git (`git check-ignore`), com a pasta `certs/`
preservada no clone por meio do `.gitkeep`. Isso exigiu uma correção no `.gitignore`: a regra
original era `certs/` com `!certs/.gitkeep`, combinação que **não funciona** — o Git não desce em
diretório excluído, então a negação nunca seria avaliada e a pasta desapareceria do clone. A
regra correta é `certs/*` com `!certs/.gitkeep`.

---

## 5. Decisões tomadas durante a sprint

### 5.1 Spring Boot 4.2.0 em vez de 4.0.x (ADR-007)

O roadmap, escrito em 19/11/2026, fixa Spring Boot 4.0.x com a justificativa declarada de ser "a
geração com suporte gratuito hoje". Quatro dias depois, a consulta ao Initializr mostrou 4.2.0
como GA padrão, 4.1.3 também GA, e a linha 4.0 em `4.0.10` — isto é, no fim do ciclo de correções
gratuitas.

Ficar em 4.0.x cumpriria a letra do roadmap e violaria a sua razão. A decisão foi seguir a razão,
com a divergência registrada no [ADR-007](../adr/ADR-007-spring-boot-4-2.md) e a versão fixada na
seção "Stack Obrigatória" da constituição, que prevalece sobre o roadmap por sua própria seção
`Governance`. O custo prático é nulo: a DSL de segurança, o Spring for GraphQL e o Spring AMQP têm
a mesma API nas três linhas da geração 4, e o código de referência do roadmap roda sem alteração.

Efeito colateral que valeu a pena documentar: a geração 4 renomeou os starters
(`spring-boot-starter-web` → `spring-boot-starter-webmvc`, `-flyway`, `-rabbitmq`,
`-security-oauth2-resource-server`, e um par `-test` por starter). Quem copiar um `pom` da
internet escrito para o Boot 3 vai falhar; por isso cada artefato foi conferido no Maven Central.

### 5.2 Esqueleto de `SecurityConfig` no Sprint 0

**O problema.** Com `spring-boot-starter-security` no classpath e nenhuma configuração, o Spring
Security protege **tudo** por padrão, inclusive `/actuator/health`. O serviço subiria exigindo o
login gerado automaticamente, e a definição de pronto da Sprint 0 ("os três serviços respondem em
`/actuator/health`") ficaria impossível de cumprir.

**As opções.** (a) Desabilitar a autoconfiguração de segurança por propriedade — simples, mas
deixaria o serviço aberto, contrariando o Princípio III. (b) Antecipar a F1 — proibido pelo
Princípio I. (c) Uma configuração mínima que libera explicitamente `/actuator/health`,
`/actuator/info`, `/actuator/prometheus` e `/graphiql/**`, e exige autenticação em todo o resto.

**A escolha.** A opção (c), em `config/SecurityConfig.java` nos dois serviços que têm o starter
de segurança. Ela **não** implementa a F1: não emite token, não lê usuário do banco e não conhece
perfil. Ela faz valer o Princípio III ("tudo autenticado por padrão, liberação explícita e
limitada a `/actuator/health` e ao GraphiQL") desde o primeiro commit. O Javadoc da classe diz
isso e aponta a spec que a substituirá por duas cadeias de filtros na Sprint 1.

**Por que não é violação do Princípio I.** O princípio proíbe código **de produção** sem spec. A
liberação do health check é exigência da própria constituição (Princípio VII) e da spec F6
(FR-002), não uma antecipação de regra de negócio. Mesmo assim fica registrado aqui, porque é a
decisão mais discutível da sprint.

### 5.3 Schema GraphQL e baseline do Flyway de propósito vazios

Dois pontos onde o "serviço sobe vazio" exigiu um arquivo mínimo em vez de nenhum:

- **`schema.graphqls`**: o Spring for GraphQL não inicia sem pelo menos um schema. Os serviços
  de agendamento e histórico ganharam um `type Query { ping: String }` com comentário dizendo qual
  contrato o substitui e em qual sprint.
- **`V1__baseline.sql`**: estabelece a linha de base do Flyway sem criar tabela, e lista no
  comentário em que sprint cada tabela entra. Assim o Flyway tem histórico desde o primeiro
  commit, e nenhuma tabela nasce antes da sua spec.

---

## 6. Pendências e riscos para as próximas sprints

| Item | Natureza | Onde é tratado |
| --- | --- | --- |
| `plan.md` e `tasks.md` de F1 a F6 | planejado: a Sprint 0 só produz `spec.md`, por desenho do roadmap | Sprints 1 a 6, com os modelos de prompt já prontos |
| Senhas dos usuários de demonstração ausentes do README | planejado: a carga Flyway é da F1 | Sprint 1 |
| Collection Postman | planejado: é entregável da F6 | Sprint 6 |
| Relatório OWASP ZAP | planejado: é entregável da F6 | Sprint 6 |
| `mvn verify` ainda não executado localmente | risco real: a máquina não tem Java nem Maven; o build foi validado **dentro do Docker**, e a CI o cobrirá no primeiro push | validado na CI |
| `./mvnw` na CI vai baixar o Maven 3.10.1 na primeira execução | consequência de `distributionType=only-script` no wrapper gerado | esperado, com cache de Maven configurado |
| Linha 4.0 do Spring Boot mencionada no roadmap | roadmap e constituição divergem | ADR-007; a constituição prevalece |

---

## 7. Como conferir esta sprint

```powershell
docker compose up -d --build
```

```powershell
curl http://localhost:8081/actuator/health; curl http://localhost:8082/actuator/health; curl http://localhost:8083/actuator/health
```

Para ver a governança e as specs:

```powershell
code .specify/memory/constitution.md specs/ docs/adr/
```

Para derrubar e limpar os volumes:

```powershell
docker compose down -v
```
