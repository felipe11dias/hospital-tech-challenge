# Feature Specification: F4 — Notificar o paciente

**Feature Branch**: `004-notificacao`

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Ao criar ou editar uma consulta, o paciente recebe uma confirmação imediata por e-mail. Além disso, um lembrete automático é enviado 24 horas antes da consulta. O serviço de notificações reage aos anúncios do agendamento, sem que o agendamento saiba que ele existe, e aguenta receber o mesmo anúncio duas vezes sem mandar dois e-mails."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Paciente recebe confirmação imediata (Priority: P1)

Assim que uma consulta é agendada, o paciente recebe um e-mail de confirmação com a data, a
hora e o nome do médico. O mesmo acontece quando a consulta é remarcada.

**Why this priority**: é o requisito explícito do enunciado ("o serviço de notificações
processa essa mensagem e envia um lembrete ao paciente") e a prova visível de que a comunicação
assíncrona funciona.

**Independent Test**: agendar uma consulta e verificar, na caixa de entrada de teste, que
chegou um e-mail para o endereço do paciente com os dados da consulta.

**Acceptance Scenarios**:

1. **Given** um anúncio de "consulta criada", **When** o serviço de notificações o processa,
   **Then** um e-mail de confirmação é enviado ao endereço do paciente, com data, hora e nome
   do médico, e um lembrete é agendado para 24 horas antes da consulta.
2. **Given** um anúncio de "consulta atualizada" com nova data, **When** é processado, **Then**
   um novo e-mail de confirmação é enviado e o lembrete pendente é recalculado para 24 horas
   antes da nova data.
3. **Given** um anúncio de "consulta cancelada", **When** é processado, **Then** o lembrete
   pendente daquela consulta é cancelado e deixa de ser enviado.

---

### User Story 2 - Lembrete automático 24 horas antes (Priority: P1)

O paciente recebe um lembrete da consulta 24 horas antes do horário marcado, sem que ninguém
precise disparar nada manualmente.

**Why this priority**: é o objetivo de negócio declarado no enunciado — "garantir a presença dos
pacientes nas consultas".

**Independent Test**: criar uma consulta cujo instante de lembrete já esteja vencido e verificar
que o lembrete é enviado no próximo ciclo de verificação, uma única vez.

**Acceptance Scenarios**:

1. **Given** um lembrete pendente cujo instante de envio já passou, **When** o ciclo de
   verificação roda, **Then** o lembrete é enviado ao paciente e marcado como enviado.
2. **Given** um lembrete já enviado, **When** o ciclo de verificação roda de novo, **Then** ele
   não é reenviado.
3. **Given** uma consulta agendada para dentro de menos de 24 horas, **When** o anúncio é
   processado, **Then** o lembrete é agendado para envio imediato, não para um instante no
   passado que nunca dispararia.
4. **Given** um lembrete cuja consulta foi cancelada, **When** o ciclo de verificação roda,
   **Then** ele não é enviado.

---

### User Story 3 - Entrega repetida não gera e-mail repetido (Priority: P1)

A infraestrutura de mensagens pode entregar o mesmo anúncio mais de uma vez. O paciente não
pode receber dois e-mails por causa disso.

**Why this priority**: entrega "pelo menos uma vez" é característica da infraestrutura
escolhida; sem tratamento, o sistema gera spam ao paciente — falha visível ao avaliador.

**Independent Test**: entregar duas vezes o mesmo anúncio (mesmo identificador) e verificar que
só um e-mail saiu e só um lembrete foi agendado.

**Acceptance Scenarios**:

1. **Given** um anúncio com um identificador que já foi processado, **When** é entregue de
   novo, **Then** é ignorado: nenhum e-mail adicional é enviado e nenhum lembrete duplicado é
   agendado.
2. **Given** dois anúncios distintos da mesma consulta (criação e atualização), **When** ambos
   são processados, **Then** ambos produzem efeito, porque têm identificadores diferentes.

---

### User Story 4 - Falha de notificação não derruba o agendamento (Priority: P2)

Se o serviço de notificações estiver fora do ar, o hospital continua agendando consultas. Os
anúncios esperam e são processados quando o serviço voltar. Anúncio que não consegue ser
processado de jeito nenhum vai para uma área de mensagens com problema, sem travar a fila.

**Why this priority**: é o ganho de desacoplamento que justifica a comunicação assíncrona do
enunciado; demonstrável em uma parada e religamento do serviço.

**Independent Test**: parar o serviço de notificações, agendar consultas, religar e verificar
que os e-mails pendentes chegam; separadamente, entregar uma mensagem malformada e verificar
que ela termina na área de mensagens com problema sem bloquear as seguintes.

**Acceptance Scenarios**:

1. **Given** o serviço de notificações parado, **When** consultas são agendadas, **Then** o
   agendamento continua respondendo normalmente e os anúncios ficam retidos.
2. **Given** anúncios retidos, **When** o serviço de notificações volta, **Then** todos são
   processados e os e-mails correspondentes são enviados.
3. **Given** uma mensagem malformada, **When** é entregue, **Then** após o número máximo de
   tentativas ela é desviada para a área de mensagens com problema e a fila principal continua
   processando as mensagens seguintes.
4. **Given** uma falha temporária no envio de e-mail, **When** o processamento é tentado,
   **Then** há até 3 tentativas com espera crescente antes de desistir.
5. **Given** o servidor de e-mail indisponível, **When** um lembrete vence, **Then** ele
   permanece pendente e é enviado quando o servidor voltar, sem que o serviço de notificações
   pare de funcionar.

### Edge Cases

- O que acontece quando o paciente não tem e-mail cadastrado? O anúncio é marcado como
  processado e o envio é registrado como não aplicável, sem ir para a área de mensagens com
  problema (não é erro de infraestrutura).
- O que acontece quando um anúncio de atualização chega antes do de criação? O lembrete é criado
  a partir do anúncio de atualização; o de criação, se chegar depois com versão menor, não
  rebaixa os dados.
- O que acontece quando a consulta é remarcada duas vezes em sequência? Vale a data do anúncio
  de maior versão; só um lembrete pendente existe por consulta.
- O que acontece com um anúncio de "consulta realizada"? É marcado como processado e não gera
  e-mail nem lembrete.
- O que acontece quando o ciclo de verificação roda e não há lembrete vencido? Nada é enviado e
  nada é registrado como erro.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O serviço de notificações MUST reagir aos anúncios de consulta criada, atualizada,
  cancelada e realizada, sem que o serviço de agendamento o conheça ou dependa dele.
- **FR-002**: Ao processar um anúncio de consulta criada ou atualizada, o sistema MUST enviar um
  e-mail de confirmação ao endereço do paciente, contendo data, hora e nome do médico.
- **FR-003**: Ao processar um anúncio de consulta criada ou atualizada, o sistema MUST manter
  exatamente um lembrete pendente por consulta, com instante de envio 24 horas antes da data e
  hora da consulta.
- **FR-004**: Quando a consulta estiver a menos de 24 horas, o instante de envio do lembrete
  MUST ser o momento atual, e não um instante passado.
- **FR-005**: Ao processar um anúncio de consulta cancelada, o sistema MUST cancelar o lembrete
  pendente daquela consulta.
- **FR-006**: O sistema MUST verificar periodicamente (a cada minuto) os lembretes pendentes com
  instante de envio vencido e enviá-los, marcando cada um como enviado após o envio.
- **FR-007**: Cada lembrete MUST ser enviado no máximo uma vez.
- **FR-008**: O sistema MUST ignorar anúncio cujo identificador já foi processado, registrando
  os identificadores já processados de forma durável (idempotência).
- **FR-009**: O sistema MUST tentar o processamento de uma mensagem até 3 vezes, com espera
  crescente entre as tentativas, antes de desistir.
- **FR-010**: Mensagem que esgote as tentativas ou que seja malformada MUST ser desviada para
  uma área de mensagens com problema (fila de mensagens mortas), sem retornar à fila principal
  e sem bloquear o processamento das demais.
- **FR-011**: A indisponibilidade do serviço de notificações MUST NOT afetar a disponibilidade
  do serviço de agendamento; os anúncios MUST ficar retidos de forma durável e ser processados
  quando o serviço voltar.
- **FR-012**: A indisponibilidade do servidor de e-mail MUST NOT derrubar o serviço de
  notificações: o lembrete permanece pendente e é tentado de novo depois.
- **FR-013**: Quando o paciente não tiver endereço de e-mail, o sistema MUST registrar a
  impossibilidade de envio e marcar o anúncio como processado, sem tratá-lo como falha de
  infraestrutura.
- **FR-014**: Anúncios de consulta realizada MUST ser marcados como processados sem gerar e-mail
  nem lembrete.

### Key Entities

- **Lembrete**: intenção de avisar um paciente sobre uma consulta. Identificação da consulta,
  endereço de e-mail do destinatário, instante de envio, status (PENDENTE, ENVIADO, CANCELADO).
  No máximo um PENDENTE por consulta.
- **Anúncio processado**: registro durável de que um anúncio, identificado unicamente, já teve
  efeito. Existe só para garantir que entrega repetida não produza efeito repetido.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Agendar uma consulta resulta em e-mail visível na caixa de entrada de teste em
  menos de 10 segundos, sem ação manual.
- **SC-002**: Entregar o mesmo anúncio duas vezes resulta em exatamente 1 e-mail enviado e 1
  lembrete agendado.
- **SC-003**: Com o serviço de notificações parado, 100% dos agendamentos continuam sendo
  aceitos pelo serviço de agendamento; ao religar, 100% dos e-mails pendentes são enviados.
- **SC-004**: 100% das mensagens malformadas terminam na área de mensagens com problema, e a
  fila principal nunca fica parada por causa delas.
- **SC-005**: Nenhum lembrete é enviado mais de uma vez, verificado por contagem de envios por
  identificação de consulta.
- **SC-006**: 100% dos critérios de aceite desta spec têm teste automatizado nomeado com o
  código do critério, e todos passam.

## Assumptions

- O lembrete é enviado 24 horas antes, conforme o roadmap; o enunciado só pede "lembretes
  automáticos sobre consultas futuras".
- A verificação de lembretes vencidos roda a cada minuto: granularidade suficiente para o
  cenário e barata de demonstrar.
- O canal de notificação é e-mail. SMS, push e WhatsApp estão fora do escopo.
- O envio é demonstrado contra um servidor SMTP de teste com caixa de entrada web (Mailpit),
  para não enviar e-mail real ao avaliar o projeto.
- O conteúdo do e-mail é texto simples, sem modelo HTML nem internacionalização.
- O serviço de notificações não consulta o serviço de agendamento: todos os dados de que precisa
  vêm dentro do próprio anúncio.
- Um único processo de notificações roda por vez; concorrência entre réplicas no envio de
  lembretes está fora do escopo.

## Out of Scope

- Preferência de canal ou de horário por paciente, e descadastramento de notificações.
- Confirmação de presença pelo paciente a partir do e-mail.
- Modelo HTML, anexos e múltiplos idiomas.
- Painel de acompanhamento de envios (a visibilidade da área de mensagens com problema é F6).

## Dependencies

- Depende dos anúncios emitidos por F2 (`002-agendar-consulta`) e F3
  (`003-modificar-consulta`); o formato é o contrato de eventos do roadmap.
- O serviço de agendamento MUST NOT depender deste serviço em nenhuma direção.
