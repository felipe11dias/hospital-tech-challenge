# Prompts do Spec Kit — registro e padrão do projeto

Este arquivo guarda os prompts usados para conceber o Spec Kit deste projeto e o padrão para os
próximos. Ele existe por dois motivos:

1. **Reprodutibilidade.** Qualquer pessoa pode reexecutar um comando do Spec Kit e chegar a um
   artefato equivalente, em vez de depender do histórico de uma conversa.
2. **Auditoria.** Em SDD, o prompt é o insumo da spec, e a spec é o contrato do código. Guardar
   o prompt é guardar a origem da decisão.

Ordem canônica do fluxo, fixada na constituição:

```
/speckit-constitution → /speckit-specify → /speckit-clarify → /speckit-plan
→ /speckit-tasks → /speckit-implement → /speckit-analyze
```

---

## O que já foi executado (Sprint 0)

| Prompt | Comando | Saída |
| --- | --- | --- |
| [P0](#p0--constituição) | `/speckit-constitution` | `.specify/memory/constitution.md` v1.0.0 |
| [P1](#p1--f1-autenticação) | `/speckit-specify` | `specs/001-autenticacao/` |
| [P2](#p2--f2-agendar-consulta) | `/speckit-specify` | `specs/002-agendar-consulta/` |
| [P3](#p3--f3-modificar-consulta) | `/speckit-specify` | `specs/003-modificar-consulta/` |
| [P4](#p4--f4-notificar-o-paciente) | `/speckit-specify` | `specs/004-notificacao/` |
| [P5](#p5--f5-histórico-via-graphql) | `/speckit-specify` | `specs/005-historico-graphql/` |
| [P6](#p6--f6-operabilidade-e-entrega) | `/speckit-specify` | `specs/006-operabilidade/` |

> **Nota de método.** O P0 foi executado invocando a skill `speckit-constitution`. As seis specs
> foram criadas com o script oficial do Spec Kit
> (`.specify/scripts/powershell/create-new-feature.ps1 -ShortName <nome> "<descrição>"`), que é
> o que gera a numeração sequencial, a pasta e o `spec.md` a partir do template resolvido; o
> conteúdo foi então escrito seguindo o contrato de `/speckit-specify` (preencher o template,
> validar contra o checklist de qualidade em `checklists/requirements.md`, zero marcadores
> `[NEEDS CLARIFICATION]` pendentes). Cada prompt abaixo é o que reproduz individualmente a sua
> spec, caso ela precise ser regerada.

---

## P0 — Constituição

**Comando:** `/speckit-constitution`

```text
Crie a constituição do projeto "Sistema Hospitalar — Tech Challenge Fase 3" (backend em
microsserviços, SDD obrigatório). Use como fonte o enunciado em docs/desafio/ e o roadmap em
"docs/Roadmap SDD — Tech Challenge Fase 3 (Sistema Hospitalar).md". Idioma: português do Brasil.
Ratificação: 2026-11-23. Versão inicial 1.0.0.

Sete princípios NÃO NEGOCIÁVEIS:
1. Spec-First (NÃO NEGOCIÁVEL): nenhuma linha de código de produção antes de spec.md aprovada;
   plan.md e tasks.md antes do primeiro commit de implementação; mudança de comportamento exige
   mudança de spec primeiro.
2. Rastreabilidade Critério→Teste (NÃO NEGOCIÁVEL): todo critério de aceite tem ao menos um
   teste automatizado cujo nome carrega o código do critério (ex.:
   F2_CA3_conflitoDeHorarioRetornaErro). mvn verify verde é condição de pronto.
3. Segurança por Padrão: tudo autenticado por padrão; senhas somente em BCrypt; JWT RS256 com
   chave privada fora do repositório (variável de ambiente/volume); autorização por
   @PreAuthorize conforme a matriz de permissões; pacienteId sempre derivado do token, nunca de
   argumento do cliente; nenhum segredo versionado.
4. Autonomia de Serviço e Dados: um banco PostgreSQL por serviço, migrações Flyway; nenhum
   serviço lê a tabela de outro; integração somente por eventos RabbitMQ; contrato de evento
   duplicado como record em cada serviço, nunca JAR compartilhado.
5. Mensageria Confiável: publicação só após commit (@TransactionalEventListener AFTER_COMMIT);
   exchange, filas e mensagens duráveis; consumidor idempotente por eventId; retry com backoff
   e DLQ; falha de consumidor nunca derruba o produtor.
6. Fronteiras de Camada e Clean Code: controller não tem regra de negócio; regra de negócio só
   em service; entidade JPA nunca cruza a borda da API (sempre DTO record); injeção por
   construtor; domínio nomeado em português, infraestrutura em inglês; erros GraphQL
   padronizados (BAD_REQUEST, FORBIDDEN, NOT_FOUND) e sem stack trace.
7. Operabilidade e Reprodutibilidade: `docker compose up` sobe tudo em máquina limpa; cada
   serviço expõe /actuator/health e /actuator/prometheus; logs com consultaId e eventId no MDC;
   toda decisão de arquitetura registrada como ADR em docs/adr/.

Seção adicional "Stack Obrigatória": Java 21, Maven multi-módulo, Spring Boot 4.2.0, Spring
Security + OAuth2 Resource Server (JWT RS256) + BCrypt, Spring for GraphQL schema-first, Spring
AMQP com RabbitMQ 4, PostgreSQL 16 + Flyway, Resilience4j, Actuator + Micrometer Prometheus,
Mailpit como SMTP de teste, JUnit 5 + spring-security-test + HttpGraphQlTester + Testcontainers,
Docker Compose. Desvio da stack exige ADR.

Seção adicional "Fluxo de Desenvolvimento e Definição de Pronto": ordem
/speckit-constitution → /speckit-specify → /speckit-clarify → /speckit-plan → /speckit-tasks →
/speckit-implement → /speckit-analyze; um commit por tarefa do tasks.md; definição de pronto =
critérios de aceite em teste verde + spec/plan/tasks versionados + ADR quando houver decisão +
README atualizado.

Governança: a constituição prevalece sobre qualquer outra prática; emenda exige bump semântico,
data e registro no Sync Impact Report; revisão de conformidade a cada fim de sprint.
```

**Por que o prompt é assim.** O `/speckit-constitution` preenche um template de placeholders. Se
o prompt disser apenas "crie uma constituição para um projeto Spring Boot", o resultado é um
texto genérico que não decide nada e não bloqueia nada. Três escolhas tornam este prompt útil:

- **Princípios numerados e redigidos como regra**, não como valor. "Senhas somente em BCrypt" é
  verificável; "priorizar segurança" não é.
- **Número de princípios explícito (sete)**, porque o template vem com cinco e a skill respeita
  a quantidade pedida.
- **Seções adicionais nomeadas** ("Stack Obrigatória", "Fluxo de Desenvolvimento e Definição de
  Pronto"), porque os placeholders `[SECTION_2_NAME]` e `[SECTION_3_NAME]` ficariam genéricos
  sem isso.

---

## P1 — F1 Autenticação

**Comando:** `/speckit-specify`
**Short name:** `autenticacao`

```text
Autenticação com Spring Security e acesso controlado por perfil MÉDICO, ENFERMEIRO e PACIENTE.
Usuários com perfil único, senha protegida por hash, carga inicial de usuários de demonstração.
O cliente troca credenciais por um token de acesso de curta duração que carrega o perfil e, no
caso do paciente, a identificação do próprio paciente. Toda operação do sistema exige esse
token; sem token, token expirado ou token adulterado o acesso é negado antes da regra de
negócio. A identificação do paciente usada em qualquer decisão de acesso vem do token, nunca de
argumento enviado pelo cliente. Inclua a matriz de permissões completa (obter token, agendar,
remarcar, cancelar, registrar atendimento, ver histórico de qualquer paciente, ver as próprias
consultas) cruzada com os três perfis e com o caso sem credencial, usando como fonte a seção
"Matriz de permissões" do roadmap. Senha errada e usuário inexistente devem ter a mesma
resposta. Escreva em português do Brasil.
```

---

## P2 — F2 Agendar consulta

**Comando:** `/speckit-specify`
**Short name:** `agendar-consulta`

```text
Médicos e enfermeiros registram novas consultas informando paciente, médico, data e hora e
motivo. A consulta nasce com status AGENDADA e versão 1. Regras: RN1 a data e hora deve ser
estritamente futura; RN2 um médico não pode ter duas consultas não canceladas no mesmo horário;
RN3 paciente não agenda. Quando qualquer regra é violada, nada é gravado e nada é anunciado.
Depois de a consulta estar gravada, o sistema emite exatamente um anúncio de "consulta criada"
contendo identificador do anúncio, identificador e versão da consulta, dados do paciente
(identificação, nome e e-mail), nome do médico, data e hora, status e motivo — e nunca antes do
commit. Motivo é opcional e limitado a 500 caracteres. Consulta cancelada libera o horário do
médico. Fora do escopo: pagamento, convênio, agenda de salas, notificação ao paciente e
atualização do histórico. Escreva em português do Brasil.
```

---

## P3 — F3 Modificar consulta

**Comando:** `/speckit-specify`
**Short name:** `modificar-consulta`

```text
São três mudanças possíveis sobre uma consulta existente: remarcar (nova data e hora ou outro
médico), cancelar com motivo opcional, e registrar o atendimento (observações clínicas
obrigatórias e marcação de REALIZADA). Remarcar e cancelar são de MÉDICO e ENFERMEIRO; registrar
atendimento é só do MÉDICO — essa é a interpretação que o projeto dá a "médico pode editar o
histórico", registrada no ADR-006. Paciente não faz nenhuma das três. A remarcação obedece às
mesmas regras da F2 (data futura e sem conflito na agenda do médico de destino). Consulta
CANCELADA ou REALIZADA não aceita mais nenhuma mudança. As transições permitidas são exatamente
AGENDADA→AGENDADA, AGENDADA→CANCELADA e AGENDADA→REALIZADA. Toda alteração aceita incrementa a
versão e emite exatamente um anúncio do tipo correspondente, após o commit; alteração recusada
não emite nada e não altera a base. Duas edições simultâneas a partir da mesma versão: a segunda
falha por bloqueio otimista, sem sobrescrever a primeira. Escreva em português do Brasil.
```

---

## P4 — F4 Notificar o paciente

**Comando:** `/speckit-specify`
**Short name:** `notificacao`

```text
Ao criar ou editar uma consulta, o paciente recebe uma confirmação imediata por e-mail com data,
hora e nome do médico. Além disso, um lembrete automático é enviado 24 horas antes da consulta;
se a consulta estiver a menos de 24 horas, o lembrete é agendado para agora, não para um
instante no passado. Consulta remarcada recalcula o lembrete pendente; consulta cancelada
cancela o lembrete. Existe no máximo um lembrete pendente por consulta, e cada lembrete é
enviado no máximo uma vez. O serviço de notificações reage aos anúncios do agendamento sem que o
agendamento saiba que ele existe, e precisa aguentar receber o mesmo anúncio duas vezes sem
mandar dois e-mails (idempotência pelo identificador do anúncio, registrada de forma durável).
Falha de processamento sofre até 3 tentativas com espera crescente; esgotadas, a mensagem vai
para a fila de mensagens mortas sem voltar para a fila principal e sem travá-la. Com o serviço
de notificações parado, o agendamento continua respondendo e as mensagens esperam. Com o
servidor de e-mail fora do ar, o lembrete fica pendente e o serviço não cai. Paciente sem e-mail
cadastrado: registra a impossibilidade e marca o anúncio como processado, sem tratar como falha
de infraestrutura. O canal é e-mail, demonstrado contra um SMTP de teste com caixa de entrada
web. Escreva em português do Brasil.
```

---

## P5 — F5 Histórico via GraphQL

**Comando:** `/speckit-specify`
**Short name:** `historico-graphql`

```text
Consultas flexíveis sobre o histórico médico via GraphQL: listar todos os atendimentos de um
paciente, apenas os futuros ou apenas os passados, com paginação informando itens, total,
página e se existe próxima. Futuros vêm ordenados do mais próximo para o mais distante; os
outros dois casos, do mais recente para o mais antigo. Cada item traz identificação da consulta,
data e hora, status, nome do médico, motivo e observações clínicas. MÉDICO e ENFERMEIRO
consultam qualquer paciente; o PACIENTE vê apenas as consultas vinculadas à identificação de
paciente do seu próprio token, e pedir outra identificação é recusado por falta de autorização —
a identificação vem sempre do token, nunca de argumento do cliente. Existe também uma consulta
dedicada "minhas consultas" para o perfil PACIENTE, que não recebe identificação como argumento.
O histórico é um serviço próprio que mantém a própria cópia de leitura, atualizada a partir dos
anúncios do agendamento, sem consultar o agendamento e sem ler o banco dele: inserção ou
atualização por identificação da consulta, uma linha por consulta, descartando anúncio com
versão menor ou igual à registrada. Ele verifica o token apenas com a chave pública. Campos
relacionados pedidos para uma lista são resolvidos em lote, de modo que uma lista de 50 itens
gere no máximo 2 consultas ao banco. Consulta cancelada continua aparecendo no histórico.
Escreva em português do Brasil.
```

---

## P6 — F6 Operabilidade e entrega

**Comando:** `/speckit-specify`
**Short name:** `operabilidade`

```text
Operabilidade e entrega: um avaliador que nunca viu o projeto clona o repositório, sobe tudo e
valida cada requisito do enunciado em menos de 15 minutos. Um único comando documentado sobe a
solução completa em máquina limpa com apenas Docker instalado — sem exigir Java ou Maven na
máquina dele. Cada serviço expõe estado de saúde refletindo banco e broker, e métricas em
formato padrão de coleta. A fila de mensagens mortas é inspecionável pelo painel do broker. Os
logs carregam identificação da consulta e do evento, para rastrear um fluxo pelos três serviços.
O repositório traz collection e ambiente de teste exportados, com uma pasta por perfil e uma
pasta de cenários negativos (sem token, token adulterado, paciente pedindo histórico alheio), e
a collection salva o token automaticamente e verifica status e código de erro. O README cobre
oito tópicos: o que é o sistema e quais requisitos atende; arquitetura e fluxo de eventos; como
rodar (pré-requisitos, geração de chaves, comando único, portas); usuários de demonstração com
senha e perfil; endpoints e exemplos; mensageria (exchange, filas, DLQ, painéis); decisões de
arquitetura e interpretação das permissões; como rodar os testes e onde está o relatório de
segurança. Cada decisão de arquitetura tem registro numerado com contexto, decisão e
consequência, e a interpretação das permissões está declarada no README. Uma varredura
automatizada de segurança roda contra o agendamento, o relatório é anexado e nenhum alerta alto
fica em aberto. Nenhum segredo versionado em nenhum ponto do histórico, e `mvn verify` roda a
cada envio de código com resultado visível. Escreva em português do Brasil.
```

---

## Padrão para os próximos prompts

### O que todo prompt de `/speckit-specify` deste projeto precisa ter

| Elemento | Por que | Exemplo |
| --- | --- | --- |
| **Ator e ação, em linguagem de negócio** | A spec descreve o quê e o porquê; o como é do `plan.md` | "Médicos e enfermeiros registram novas consultas" |
| **Regras numeradas (RN)** | Viram requisitos funcionais rastreáveis | "RN2: um médico não pode ter duas consultas no mesmo horário" |
| **Comportamento no caminho infeliz** | Sem isso, a spec só descreve o caminho feliz e os testes negativos somem | "Quando a regra é violada, nada é gravado e nada é anunciado" |
| **Fronteira de escopo explícita** | Evita que o modelo invente requisito | "Fora do escopo: pagamento, convênio, agenda de salas" |
| **Padrão para o que o enunciado não diz** | Evita marcador `[NEEDS CLARIFICATION]` que travaria o fluxo | "Duração padrão assumida em 30 minutos" |
| **Idioma** | O domínio é nomeado em português (Princípio VI) | "Escreva em português do Brasil" |

### O que **não** colocar

- Nome de classe, de biblioteca, de anotação ou de tabela. Isso é `plan.md`.
- Mais de três dúvidas reais: o `/speckit-specify` limita a 3 marcadores
  `[NEEDS CLARIFICATION]`. Se houver mais, o prompt está mal delimitado — quebre a feature.

### `/speckit-plan` (Sprints 1 a 6)

```text
Gere o plano de implementação da <F#>, lendo a spec em specs/<NNN-nome>/spec.md e obedecendo
à constituição em .specify/memory/constitution.md.

Restrições que o plano NÃO pode contrariar:
- Stack fixada na seção "Stack Obrigatória" da constituição (Java 21, Spring Boot 4.2.0,
  PostgreSQL 16 + Flyway, RabbitMQ 4 via Spring AMQP, Spring for GraphQL schema-first).
- Camadas: controller sem regra de negócio, regra só em service, entidade JPA nunca na borda da
  API (DTO record), injeção por construtor.
- Um banco por serviço; nenhum serviço lê tabela de outro; integração somente por evento.
- Cada critério de aceite da spec precisa aparecer no plano com o teste que o prova e o nome
  desse teste no formato F<n>_CA<m>_descricaoCurta.

Entregue: estrutura de pacotes afetada, migrações Flyway necessárias, contratos (schema GraphQL
ou endpoint REST), pontos de autorização, estratégia de teste por nível da pirâmide e decisões
que exigem novo ADR.
```

### `/speckit-tasks` (Sprints 1 a 6)

```text
Gere o tasks.md da <F#> a partir de specs/<NNN-nome>/spec.md e specs/<NNN-nome>/plan.md.

Cada tarefa deve: ser pequena o suficiente para um commit, ter identificador (T001, T002, ...),
declarar os arquivos que toca, declarar de quais tarefas depende, e — quando implementa um
critério de aceite — citar o código do critério e o nome do teste que o prova.
Inclua as tarefas de teste como tarefas próprias, não como subitem de uma tarefa de código.
A última tarefa de cada funcionalidade é atualizar o README e, se houver decisão nova, o ADR.
```

### `/speckit-clarify`

Rodar **sempre** que a spec contiver marcador `[NEEDS CLARIFICATION]`. Nenhum plano é gerado
sobre spec com pergunta aberta (constituição, "Regras do fluxo").

### `/speckit-analyze`

Rodar antes de fechar cada sprint, para conferir consistência entre `spec.md`, `plan.md` e
`tasks.md`.
