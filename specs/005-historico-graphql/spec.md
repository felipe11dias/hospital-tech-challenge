# Feature Specification: F5 — Histórico do paciente via GraphQL

**Feature Branch**: `005-historico-graphql`

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Consultas flexíveis sobre o histórico médico: listar todos os atendimentos de um paciente, apenas os futuros ou apenas os passados, com paginação. Médico e enfermeiro consultam qualquer paciente; o paciente vê apenas as próprias consultas, e a identificação do paciente vem do token. O histórico é mantido por um serviço próprio, que se atualiza a partir dos anúncios do agendamento."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Profissional consulta o histórico de um paciente (Priority: P1)

Um médico ou enfermeiro pede o histórico de um paciente e escolhe o que quer ver: tudo, só o que
ainda vai acontecer, ou só o que já aconteceu. Recebe a lista paginada, com data, hora, status,
nome do médico, motivo e observações clínicas.

**Why this priority**: é o requisito de GraphQL do enunciado ("listar todos os atendimentos de
um paciente ou apenas as futuras") e a razão de existir do serviço de histórico.

**Independent Test**: popular o histórico de um paciente com consultas passadas e futuras e
verificar, em três chamadas, que cada filtro devolve exatamente o subconjunto esperado.

**Acceptance Scenarios**:

1. **Given** um paciente com 3 consultas passadas e 2 futuras, **When** um MÉDICO pede o
   histórico filtrando apenas as futuras, **Then** recebe exatamente as 2 futuras, ordenadas da
   mais próxima para a mais distante.
2. **Given** o mesmo paciente, **When** pede o histórico filtrando apenas as passadas, **Then**
   recebe exatamente as 3 passadas, ordenadas da mais recente para a mais antiga.
3. **Given** o mesmo paciente, **When** pede o histórico sem filtro de período, **Then** recebe
   todas as 5, da mais recente para a mais antiga.
4. **Given** um ENFERMEIRO autenticado, **When** pede o histórico de qualquer paciente, **Then**
   a consulta é permitida.
5. **Given** um paciente com 50 consultas e página de tamanho 20, **When** pede a primeira
   página, **Then** recebe 20 itens, o total 50, o número da página e a indicação de que existe
   próxima página.

---

### User Story 2 - Paciente vê apenas o próprio histórico (Priority: P1)

Um paciente consulta as suas consultas e recebe só as dele. Se tentar pedir o histórico de outra
pessoa, é recusado.

**Why this priority**: é a regra de privacidade mais crítica do sistema; uma falha aqui expõe
dado clínico de terceiro.

**Independent Test**: autenticar um paciente, pedir as próprias consultas (sucesso) e pedir o
histórico de outra identificação de paciente (recusa), sem precisar de nenhum outro perfil.

**Acceptance Scenarios**:

1. **Given** um PACIENTE autenticado, **When** pede as próprias consultas, **Then** recebe
   apenas as consultas vinculadas à identificação de paciente declarada no seu token.
2. **Given** um PACIENTE autenticado, **When** pede o histórico informando a identificação de
   outro paciente, **Then** recebe recusa por falta de autorização e nenhum dado do outro
   paciente.
3. **Given** um PACIENTE autenticado, **When** pede o histórico informando a sua própria
   identificação, **Then** a consulta é permitida.
4. **Given** nenhuma credencial, **When** qualquer consulta de histórico é feita, **Then**
   recebe recusa por falta de autenticação.

---

### User Story 3 - Histórico acompanha o agendamento sozinho (Priority: P1)

O histórico se mantém atualizado reagindo aos anúncios do agendamento: consulta criada aparece,
consulta remarcada aparece com a nova data, consulta cancelada ou realizada aparece com o novo
status. Ninguém precisa copiar dados manualmente, e o histórico não pergunta nada ao
agendamento.

**Why this priority**: sem isso o histórico fica vazio e as User Stories 1 e 2 não têm o que
mostrar.

**Independent Test**: entregar a sequência de anúncios de uma consulta (criada, atualizada,
realizada) e verificar que a cópia de leitura reflete o último estado, com uma única linha por
consulta.

**Acceptance Scenarios**:

1. **Given** um anúncio de consulta criada, **When** o serviço de histórico o processa, **Then**
   a consulta passa a aparecer no histórico do paciente com status AGENDADA.
2. **Given** um anúncio de consulta atualizada com nova data, **When** é processado, **Then** a
   mesma consulta aparece com a nova data — não como uma segunda consulta.
3. **Given** um anúncio de versão menor que a já registrada, **When** é processado, **Then** é
   descartado: dados mais antigos não sobrescrevem dados mais novos.
4. **Given** o mesmo anúncio entregue duas vezes, **When** é processado, **Then** o histórico
   permanece com uma única linha para aquela consulta.
5. **Given** um anúncio de consulta cancelada, **When** é processado, **Then** a consulta
   aparece no histórico com status CANCELADA.

---

### User Story 4 - Consulta de muitos registros não degrada o banco (Priority: P3)

Pedir um campo relacionado (como o nome do médico) para uma lista grande não multiplica o número
de consultas ao banco por item da lista.

**Why this priority**: é boa prática de GraphQL (problema N+1) e ponto de qualidade de código,
mas não bloqueia a entrega funcional.

**Independent Test**: pedir uma lista de 50 atendimentos incluindo o nome do médico e contar as
consultas efetivas ao banco.

**Acceptance Scenarios**:

1. **Given** uma consulta de 50 atendimentos pedindo o nome do médico, **When** executada,
   **Then** o banco recebe 2 consultas, não 51.

### Edge Cases

- O que acontece quando o paciente não tem nenhuma consulta? A resposta é uma lista vazia com
  total 0, não um erro.
- O que acontece com uma consulta marcada exatamente para o instante atual? Conta como passada,
  porque o filtro de futuras usa estritamente "depois de agora".
- O que acontece quando a identificação de paciente pedida não existe? Lista vazia, sem revelar
  se o paciente existe.
- O que acontece quando se pede uma página além do fim? Lista vazia, total correto e indicação
  de que não há próxima página.
- O que acontece quando se pede tamanho de página 0 ou negativo? Erro de validação.
- O que acontece quando um token de PACIENTE chega sem identificação de paciente? A consulta é
  recusada por falta de autorização, não respondida com lista vazia.
- O que acontece com uma consulta cancelada? Continua aparecendo no histórico, com status
  CANCELADA — histórico não apaga fatos.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir consultar o histórico de atendimentos de um paciente,
  filtrando por período: todos, apenas futuros ou apenas passados.
- **FR-002**: O resultado MUST ser paginado, informando os itens da página, o total de
  registros, o número da página e se existe próxima página.
- **FR-003**: Os itens MUST ser ordenados da data e hora mais próxima para a mais distante
  quando o filtro for "futuros", e da mais recente para a mais antiga nos outros dois casos.
- **FR-004**: Cada item MUST trazer identificação da consulta, data e hora, status, nome do
  médico, motivo e observações clínicas.
- **FR-005**: O sistema MUST permitir a usuários de perfil MEDICO e ENFERMEIRO consultar o
  histórico de qualquer paciente.
- **FR-006**: O sistema MUST permitir a usuário de perfil PACIENTE consultar apenas o histórico
  vinculado à identificação de paciente declarada no seu próprio token, recusando por falta de
  autorização qualquer outra identificação.
- **FR-007**: A identificação de paciente usada na decisão de acesso do perfil PACIENTE MUST ser
  lida do token, e MUST NOT ser aceita de argumento do cliente.
- **FR-008**: O sistema MUST oferecer uma consulta dedicada "minhas consultas" para o perfil
  PACIENTE, que não recebe identificação de paciente como argumento.
- **FR-009**: O sistema MUST recusar, por falta de autenticação, qualquer consulta sem token
  válido.
- **FR-010**: O serviço de histórico MUST manter sua própria cópia de leitura dos dados,
  atualizada a partir dos anúncios do serviço de agendamento, sem consultar o agendamento e sem
  ler o banco dele.
- **FR-011**: A atualização da cópia de leitura MUST ser por inserção ou atualização conforme a
  identificação da consulta — uma única linha por consulta, qualquer que seja o número de
  anúncios recebidos.
- **FR-012**: O sistema MUST descartar anúncio cuja versão seja menor ou igual à versão já
  registrada para aquela consulta, para tolerar chegada fora de ordem e entrega repetida.
- **FR-013**: O sistema MUST verificar o token apenas com a chave pública, sem acessar o
  cadastro de usuários do serviço de agendamento.
- **FR-014**: Campos relacionados pedidos para uma lista MUST ser resolvidos em lote, de modo
  que o número de consultas ao banco não cresça com o número de itens da lista.
- **FR-015**: Erros MUST ser devolvidos com código padronizado (requisição inválida, proibido,
  não encontrado) e sem rastro de pilha.

### Key Entities

- **Consulta do histórico**: cópia de leitura de uma consulta, otimizada para exibição.
  Identificação da consulta, identificação do paciente, data e hora, status, nome do médico,
  motivo, observações clínicas e versão do último anúncio aplicado.
- **Período**: filtro fechado com três valores — todas, futuras, passadas.
- **Página de histórico**: resultado paginado — itens, total, página atual e existência de
  próxima página.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O filtro "apenas futuras" devolve exatamente as consultas com data e hora
  posteriores ao instante da consulta, em 100% dos casos de teste.
- **SC-002**: Em 100% das tentativas de um paciente acessar histórico de outro, o acesso é
  recusado e nenhum dado do outro paciente é devolvido.
- **SC-003**: Após a sequência completa de anúncios de uma consulta, o histórico tem exatamente
  1 linha para ela, com o estado do anúncio de maior versão.
- **SC-004**: Uma lista de 50 itens com campo relacionado gera no máximo 2 consultas ao banco.
- **SC-005**: 100% dos critérios de aceite desta spec têm teste automatizado nomeado com o
  código do critério, e todos passam.
- **SC-006**: Uma consulta de histórico com filtro de período responde em menos de 1 segundo
  para um paciente com até 500 atendimentos.

## Assumptions

- O serviço de histórico é o "serviço opcional" do enunciado, implementado como modelo de
  leitura (CQRS leve), conforme ADR-003 do roadmap. O agendamento continua dono das escritas.
- A consistência é eventual: logo após agendar, o histórico pode levar instantes para refletir
  a nova consulta. Isso é aceito e deve estar documentado no README.
- Tamanho de página padrão 20 e período padrão "todas" na consulta por paciente; na consulta
  "minhas consultas", período padrão "futuras".
- O histórico não apaga nem anonimiza registros; retenção e expurgo estão fora do escopo.
- Não há busca textual, filtro por médico, por status ou por intervalo de datas arbitrário:
  apenas os três períodos especificados.

## Out of Scope

- Escrita de qualquer natureza no histórico pela API (ele só é alimentado por anúncios).
- Exportação do histórico (PDF, CSV) e impressão.
- Busca textual e filtros além do período.
- Retenção, expurgo e anonimização de dados clínicos.

## Dependencies

- Depende de F1 (`001-autenticacao`) para a chave pública de verificação do token e para o
  significado dos perfis e da identificação de paciente no token.
- Depende dos anúncios emitidos por F2 (`002-agendar-consulta`) e F3
  (`003-modificar-consulta`); o formato é o contrato de eventos do roadmap.
- O contrato de interface externo (nomes das consultas, do filtro de período e dos campos) é
  herdado do roadmap, seção "Contrato GraphQL do histórico".
