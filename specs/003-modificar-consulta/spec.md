# Feature Specification: F3 — Modificar consulta

**Feature Branch**: `003-modificar-consulta`

**Created**: 2026-11-23

**Status**: Draft

**Input**: São três mudanças possíveis sobre uma consulta existente: remarcar (nova data e hora ou outro médico), cancelar, e registrar o atendimento (observações clínicas e marcação de realizada). Remarcar e cancelar são de médico e enfermeiro; registrar atendimento é só do médico. Cada mudança anuncia o fato para o resto do sistema e incrementa a versão da consulta.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enfermeiro remarca uma consulta (Priority: P1)

Um enfermeiro muda a data e a hora de uma consulta AGENDADA, ou troca o médico responsável. A
consulta passa a valer com os novos dados, sua versão aumenta e o sistema anuncia a alteração
para que o paciente seja reavisado e o histórico corrigido.

**Why this priority**: remarcação é o caso de uso mais frequente depois do agendamento, e é o
que o enunciado chama de "modificar consultas existentes".

**Independent Test**: criar uma consulta, remarcá-la como enfermeiro e verificar a nova data, a
versão incrementada e o anúncio de alteração emitido.

**Acceptance Scenarios**:

1. **Given** uma consulta com status AGENDADA, **When** um ENFERMEIRO a remarca para outra data
   e hora futuras, **Then** a data e a hora mudam, a versão é incrementada e um anúncio de
   "consulta atualizada" é emitido.
2. **Given** uma consulta AGENDADA, **When** um ENFERMEIRO troca o médico responsável por outro
   existente, **Then** o médico muda, a versão é incrementada e o anúncio de alteração é
   emitido.
3. **Given** uma consulta AGENDADA, **When** um MÉDICO a remarca, **Then** o resultado é o
   mesmo da remarcação por enfermeiro.
4. **Given** uma remarcação para um horário em que o novo médico já tem consulta não cancelada,
   **When** a remarcação é tentada, **Then** recebe erro de conflito de agenda e nada muda.
5. **Given** uma remarcação para data e hora no passado, **When** é tentada, **Then** recebe
   erro de validação e nada muda.

---

### User Story 2 - Médico registra o atendimento (Priority: P1)

Depois de atender, o médico registra as observações clínicas e marca a consulta como REALIZADA.
Essa é a leitura que o projeto dá a "médico pode editar o histórico".

**Why this priority**: é o requisito que diferencia o perfil MÉDICO do ENFERMEIRO no enunciado;
sem ele, os dois perfis seriam equivalentes.

**Independent Test**: criar uma consulta, registrar o atendimento como médico e verificar
status REALIZADA, observações gravadas e anúncio emitido; repetir como enfermeiro e verificar a
recusa.

**Acceptance Scenarios**:

1. **Given** uma consulta AGENDADA e um MÉDICO autenticado, **When** registra o atendimento com
   observações clínicas, **Then** a consulta passa a REALIZADA, as observações ficam gravadas,
   a versão é incrementada e um anúncio de "consulta realizada" é emitido.
2. **Given** um ENFERMEIRO autenticado, **When** tenta registrar o atendimento, **Then** recebe
   recusa por falta de autorização e nada muda.
3. **Given** um PACIENTE autenticado, **When** tenta registrar o atendimento, **Then** recebe
   recusa por falta de autorização.
4. **Given** um registro de atendimento com observações vazias, **When** é tentado, **Then**
   recebe erro de validação: observação é obrigatória para marcar realizada.

---

### User Story 3 - Cancelamento (Priority: P2)

Médico ou enfermeiro cancela uma consulta, opcionalmente informando o motivo. A consulta deixa
de ocupar a agenda do médico e o lembrete pendente do paciente é descartado.

**Why this priority**: necessário para fechar o ciclo de vida da consulta e para liberar agenda,
mas o sistema já entrega valor sem ele.

**Independent Test**: cancelar uma consulta AGENDADA e verificar status CANCELADA, anúncio de
cancelamento emitido e horário do médico novamente disponível.

**Acceptance Scenarios**:

1. **Given** uma consulta AGENDADA, **When** um ENFERMEIRO a cancela informando o motivo,
   **Then** a consulta passa a CANCELADA, o motivo do cancelamento é registrado, a versão é
   incrementada e um anúncio de "consulta cancelada" é emitido.
2. **Given** uma consulta CANCELADA, **When** alguém tenta agendar outra para o mesmo médico no
   mesmo horário, **Then** o agendamento é permitido.
3. **Given** um PACIENTE autenticado, **When** tenta cancelar, **Then** recebe recusa por falta
   de autorização.

---

### User Story 4 - Transições inválidas e edição concorrente são barradas (Priority: P2)

Consulta já CANCELADA ou já REALIZADA não aceita mais mudanças, e duas pessoas editando a mesma
consulta ao mesmo tempo não sobrescrevem silenciosamente uma à outra.

**Why this priority**: protege a integridade do histórico clínico, que é a informação mais
sensível do sistema.

**Independent Test**: tentar cada transição proibida e verificar a recusa; executar duas edições
a partir da mesma versão e verificar que a segunda falha.

**Acceptance Scenarios**:

1. **Given** uma consulta CANCELADA, **When** alguém tenta remarcá-la, **Then** recebe erro de
   regra de negócio e nada muda.
2. **Given** uma consulta REALIZADA, **When** alguém tenta remarcá-la ou cancelá-la, **Then**
   recebe erro de regra de negócio e nada muda.
3. **Given** uma consulta CANCELADA, **When** um MÉDICO tenta registrar o atendimento, **Then**
   recebe erro de regra de negócio.
4. **Given** duas edições da mesma consulta iniciadas a partir da mesma versão, **When** ambas
   são submetidas, **Then** a primeira é aplicada e a segunda falha por conflito de versão, sem
   sobrescrever a primeira.

### Edge Cases

- O que acontece quando a remarcação informa a mesma data e hora atual da consulta? É aceita
  como mudança sem efeito, a versão incrementa e o anúncio é emitido (o consumidor é
  idempotente por identificador de anúncio, não por conteúdo).
- O que acontece quando a remarcação não informa nenhum campo? É recusada como erro de
  validação: ao menos um campo deve mudar.
- O que acontece quando se troca o médico de uma consulta cuja data já passou mas que ainda
  está AGENDADA? É recusada pela mesma regra de data futura.
- O que acontece quando o identificador da consulta não existe? Erro de recurso não encontrado.
- O que acontece com observações clínicas já registradas, quando o médico registra atendimento
  de novo? A segunda tentativa é recusada, porque a consulta já está REALIZADA — observação
  clínica não é reescrita neste escopo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir a MEDICO e ENFERMEIRO alterar a data e hora e/ou o médico
  responsável de uma consulta com status AGENDADA.
- **FR-002**: O sistema MUST permitir a MEDICO e ENFERMEIRO cancelar uma consulta com status
  AGENDADA, com motivo opcional.
- **FR-003**: O sistema MUST permitir somente a MEDICO registrar observações clínicas e marcar
  a consulta como REALIZADA.
- **FR-004**: O sistema MUST recusar, por falta de autorização, qualquer uma destas operações
  tentada por usuário de perfil PACIENTE.
- **FR-005**: O sistema MUST aplicar à remarcação as mesmas regras de F2: data estritamente
  futura e ausência de conflito na agenda do médico de destino.
- **FR-006**: O sistema MUST recusar, com erro de regra de negócio, qualquer alteração sobre
  consulta com status CANCELADA ou REALIZADA.
- **FR-007**: O sistema MUST exigir observações clínicas não vazias para marcar uma consulta
  como REALIZADA.
- **FR-008**: Toda alteração aceita MUST incrementar a versão da consulta.
- **FR-009**: O sistema MUST detectar edição concorrente por controle otimista de versão e
  recusar a segunda alteração, sem perder a primeira.
- **FR-010**: Toda alteração aceita MUST emitir exatamente um anúncio após a gravação ser
  confirmada, com o tipo correspondente: atualizada, cancelada ou realizada.
- **FR-011**: Nenhuma alteração recusada MUST emitir anúncio nem alterar a base.
- **FR-012**: O sistema MUST recusar, com erro de recurso não encontrado, operação sobre
  consulta inexistente ou com médico de destino inexistente.
- **FR-013**: As transições de status permitidas MUST ser exatamente: AGENDADA → AGENDADA
  (remarcação), AGENDADA → CANCELADA, AGENDADA → REALIZADA. Nenhuma outra.

### Key Entities

- **Consulta**: a mesma de F2, agora com ciclo de vida. Ganha observações clínicas, motivo de
  cancelamento e versão que muda a cada alteração.
- **Status da consulta**: AGENDADA, CANCELADA, REALIZADA — estados mutuamente exclusivos, com as
  transições fixadas em FR-013.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos critérios de aceite desta spec têm teste automatizado nomeado com o
  código do critério, e todos passam.
- **SC-002**: 100% das transições de status proibidas são recusadas, sem alterar a base.
- **SC-003**: Em teste de edição concorrente, a alteração perdida é sempre a segunda, e ela
  falha de forma explícita — nunca silenciosamente.
- **SC-004**: Para toda alteração aceita existe exatamente um anúncio do tipo correto; para
  toda alteração recusada, nenhum.
- **SC-005**: A distinção entre MEDICO e ENFERMEIRO no registro de atendimento é verificada por
  teste em ambos os perfis.

## Assumptions

- Interpretação das permissões do enunciado (registrada como ADR-006): "editar o histórico"
  significa registrar observações clínicas e marcar a consulta como realizada, e é exclusivo do
  MÉDICO; "modificar consultas" (data, médico, cancelamento) vale para MÉDICO e ENFERMEIRO. O
  enunciado não detalha, então esta leitura está documentada no README.
- Uma consulta CANCELADA é estado final: não existe "reativar". Reagendar é criar uma consulta
  nova.
- Observação clínica é escrita uma única vez, junto com a marcação de realizada. Corrigir
  observação depois está fora do escopo.
- O conflito de versão é informado ao cliente como erro, para que ele recarregue e tente de
  novo; não há resolução automática de conflito.

## Out of Scope

- Correção ou histórico de alterações das observações clínicas (trilha de auditoria completa).
- Reativação de consulta cancelada.
- Notificação ao paciente (é F4) e atualização da cópia de leitura do histórico (é F5): esta
  spec termina no anúncio emitido.

## Dependencies

- Depende de F1 (`001-autenticacao`) para perfil e autorização, e de F2
  (`002-agendar-consulta`) para a existência da consulta e das regras RN1 e RN2.
- Os anúncios emitidos aqui são consumidos por F4 (`004-notificacao`) e F5
  (`005-historico-graphql`); o formato é o contrato de eventos do roadmap.
