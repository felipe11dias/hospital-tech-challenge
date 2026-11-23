# Feature Specification: F2 — Agendar consulta

**Feature Branch**: `002-agendar-consulta`

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Médicos e enfermeiros registram novas consultas informando paciente, médico, data e hora e motivo. A consulta nasce com status AGENDADA. A data precisa ser futura, o médico não pode ter duas consultas no mesmo horário e paciente não agenda. Cada consulta criada anuncia o fato para o resto do sistema."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enfermeiro agenda uma consulta (Priority: P1)

Um enfermeiro na recepção registra uma consulta para um paciente já cadastrado, escolhendo o
médico, a data e a hora, e informando o motivo. A consulta passa a existir com status AGENDADA
e o sistema anuncia o agendamento para que o paciente seja avisado e o histórico atualizado.

**Why this priority**: é a operação central do sistema; sem ela não há consulta para notificar,
modificar ou consultar no histórico.

**Independent Test**: autenticar um enfermeiro, agendar uma consulta e verificar que ela existe
com status AGENDADA e que o anúncio de criação foi emitido. Entrega valor completo por si.

**Acceptance Scenarios**:

1. **Given** um ENFERMEIRO autenticado e um paciente e um médico existentes, **When** agenda
   uma consulta para uma data e hora futuras, **Then** a consulta é criada com status AGENDADA,
   com os dados informados, e um anúncio de "consulta criada" é emitido.
2. **Given** um MÉDICO autenticado, **When** agenda uma consulta válida, **Then** a consulta é
   criada da mesma forma.
3. **Given** uma consulta recém-criada, **When** ela é consultada pelo seu identificador,
   **Then** devolve paciente, médico, data e hora, status AGENDADA, motivo e versão 1.

---

### User Story 2 - Agendamento inválido é recusado sem efeito colateral (Priority: P1)

Quando os dados do agendamento violam uma regra, nada é gravado e nada é anunciado: a tentativa
falha por inteiro, com uma mensagem que diz qual regra foi violada.

**Why this priority**: um agendamento inválido que grava pela metade ou que anuncia um fato
inexistente gera e-mail errado ao paciente e histórico sujo — dano maior que a falha em si.

**Independent Test**: tentar agendar com data passada, com conflito de horário e com paciente
ou médico inexistentes, verificando em cada caso que a base não mudou e que nenhum anúncio foi
emitido.

**Acceptance Scenarios**:

1. **Given** um ENFERMEIRO autenticado, **When** tenta agendar para uma data e hora já
   passadas, **Then** recebe erro de validação com a mensagem "dataHora deve ser futura",
   nenhuma consulta é criada e nenhum anúncio é emitido.
2. **Given** um médico que já tem uma consulta AGENDADA às 14:30 de uma data, **When** alguém
   tenta agendar outra consulta para o mesmo médico no mesmo horário, **Then** recebe erro de
   conflito de agenda, nada é gravado e nenhum anúncio é emitido.
3. **Given** um identificador de paciente que não existe, **When** tenta agendar, **Then**
   recebe erro de recurso não encontrado e nada é gravado.
4. **Given** um identificador de médico que não existe, **When** tenta agendar, **Then** recebe
   erro de recurso não encontrado e nada é gravado.

---

### User Story 3 - Paciente não agenda (Priority: P2)

Um paciente autenticado não consegue criar consultas: o agendamento é ato do hospital, não do
paciente.

**Why this priority**: regra de autorização explícita no enunciado. Depende de F1 estar pronta,
mas é a fronteira que impede o paciente de criar dados.

**Independent Test**: autenticar um paciente, tentar agendar e verificar a recusa por falta de
autorização, com a base inalterada.

**Acceptance Scenarios**:

1. **Given** um PACIENTE autenticado, **When** tenta agendar uma consulta, **Then** recebe
   recusa por falta de autorização e nenhuma consulta é criada.
2. **Given** nenhuma credencial, **When** tenta agendar, **Then** recebe recusa por falta de
   autenticação.

### Edge Cases

- O que acontece quando o médico já tem consulta no horário, mas ela está CANCELADA? O
  agendamento é permitido: consulta cancelada não ocupa a agenda.
- O que acontece com uma consulta no mesmo horário para o mesmo paciente com outro médico? É
  permitida neste escopo; a regra de conflito é da agenda do médico.
- O que acontece quando o motivo não é informado? É aceito: o motivo é opcional.
- O que acontece quando o motivo excede 500 caracteres? É recusado como erro de validação.
- O que acontece com uma data e hora exatamente igual ao instante atual? É tratada como não
  futura e recusada.
- O que acontece quando o anúncio não consegue ser entregue ao restante do sistema após a
  consulta já estar gravada? A consulta permanece gravada e a entrega é retentada; a resposta
  ao usuário não falha por causa disso.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir a usuários de perfil MEDICO e ENFERMEIRO criar uma
  consulta informando paciente, médico, data e hora, e opcionalmente o motivo.
- **FR-002**: O sistema MUST recusar a criação de consulta por usuário de perfil PACIENTE, com
  erro de falta de autorização.
- **FR-003**: A consulta criada MUST nascer com status AGENDADA e versão inicial 1.
- **FR-004**: O sistema MUST recusar, com erro de validação, data e hora que não sejam
  estritamente futuras em relação ao instante da requisição (RN1).
- **FR-005**: O sistema MUST recusar, com erro de conflito, a criação de consulta para um
  médico que já tenha outra consulta não cancelada no mesmo instante (RN2).
- **FR-006**: O sistema MUST recusar, com erro de recurso não encontrado, a criação de consulta
  cujo paciente ou médico informado não exista.
- **FR-007**: O sistema MUST recusar, com erro de validação, motivo com mais de 500 caracteres.
- **FR-008**: Quando qualquer regra for violada, o sistema MUST NOT persistir nada e MUST NOT
  emitir nenhum anúncio.
- **FR-009**: Após a consulta estar efetivamente gravada, o sistema MUST emitir exatamente um
  anúncio de "consulta criada", contendo identificador único do anúncio, identificador e versão
  da consulta, dados do paciente (identificação, nome e e-mail), nome do médico, data e hora,
  status e motivo.
- **FR-010**: O anúncio MUST NOT ser emitido antes da gravação ser confirmada, para nunca
  anunciar uma consulta que não existe.
- **FR-011**: O sistema MUST permitir consultar uma consulta pelo seu identificador, devolvendo
  os dados do paciente e do médico, sem expor dados internos de persistência.
- **FR-012**: O sistema MUST registrar quem criou a consulta (usuário autenticado), para
  auditoria.

### Regras de negócio

- **RN1**: `dataHora` deve ser futura.
- **RN2**: um médico não pode ter duas consultas não canceladas no mesmo horário.
- **RN3**: PACIENTE não agenda.

### Key Entities

- **Consulta**: encontro marcado entre um paciente e um médico. Data e hora, status (AGENDADA,
  CANCELADA, REALIZADA), motivo, observações clínicas (preenchidas só em F3), versão para
  controle de edição concorrente, autor da criação.
- **Paciente**: pessoa atendida (definido em F1). Fornece nome e e-mail usados no anúncio.
- **Médico**: profissional com agenda (definido em F1). É o dono do horário disputado pela RN2.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um enfermeiro autenticado conclui um agendamento válido em uma única operação,
  sem passo intermediário.
- **SC-002**: 100% dos critérios de aceite desta spec têm teste automatizado nomeado com o
  código do critério, e todos passam.
- **SC-003**: Em 100% das tentativas inválidas (data passada, conflito, paciente ou médico
  inexistente), a contagem de consultas na base permanece inalterada e nenhum anúncio é
  emitido.
- **SC-004**: Para toda consulta criada com sucesso, existe exatamente um anúncio de criação —
  nunca zero, nunca dois.
- **SC-005**: A mensagem de erro devolvida identifica a regra violada e não contém rastro de
  pilha nem detalhe interno de implementação.

## Assumptions

- Duração padrão da consulta assumida em 30 minutos, mas o conflito de agenda (RN2) é avaliado
  por igualdade exata de instante, não por sobreposição de intervalo: é a leitura mais simples
  que atende o enunciado. Tratar sobreposição parcial fica fora do escopo.
- Consulta CANCELADA libera o horário do médico; REALIZADA (passada) não entra em conflito com
  horário futuro.
- Paciente e médico são cadastros pré-existentes, criados por carga inicial em F1; cadastrá-los
  pela API está fora do escopo.
- O fuso de referência é o do servidor, e as datas e horas trafegam com deslocamento de fuso
  explícito para evitar ambiguidade.
- Não há agenda de salas, convênio, pagamento, duração variável nem reserva de equipamento.

## Out of Scope

- Pagamento, convênio e cobrança.
- Agenda de salas e de equipamentos.
- Remarcação, cancelamento e registro de atendimento (são F3).
- Envio do e-mail ao paciente (é F4): esta spec termina no anúncio emitido.

## Dependencies

- Depende de F1 (`001-autenticacao`) para identidade e perfil do usuário que agenda.
- O formato do anúncio (nomes dos campos, chave de roteamento) é herdado do contrato de eventos
  do roadmap, seção "Contrato de eventos"; F4 e F5 são os consumidores desse anúncio.
