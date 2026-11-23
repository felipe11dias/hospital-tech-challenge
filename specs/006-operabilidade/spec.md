# Feature Specification: F6 — Operabilidade e entrega

**Feature Branch**: `006-operabilidade`

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Health checks, métricas, fila de mensagens com problema visível, collection do Postman e README. Um professor clona o repositório, sobe tudo e valida cada requisito em menos de 15 minutos."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Avaliador sobe o sistema inteiro em uma máquina limpa (Priority: P1)

Um avaliador que nunca viu o projeto clona o repositório, segue o README e tem a solução
completa rodando — três serviços, três bancos, broker de mensagens e caixa de e-mail de teste —
sem precisar instalar Java nem Maven na máquina e sem adivinhar nenhum passo.

**Why this priority**: se o avaliador não conseguir subir o sistema, nenhum outro requisito é
avaliável. É o pré-requisito de toda a entrega.

**Independent Test**: em uma máquina sem o projeto, clonar, seguir o README e verificar que os
três serviços respondem como saudáveis. Entrega valor completo por si.

**Acceptance Scenarios**:

1. **Given** uma máquina limpa com apenas Docker instalado, **When** o avaliador clona o
   repositório e executa o comando único documentado no README, **Then** os três serviços, os
   três bancos, o broker e a caixa de e-mail de teste sobem.
2. **Given** o ambiente no ar, **When** o avaliador consulta o estado de saúde de cada serviço,
   **Then** cada um responde que está saudável, incluindo o estado da sua conexão com o banco e
   com o broker.
3. **Given** o README, **When** o avaliador procura os usuários de demonstração e suas senhas,
   **Then** encontra ao menos um usuário por perfil, com a senha, e consegue autenticar com
   eles na primeira tentativa.
4. **Given** o README, **When** o avaliador procura como gerar o par de chaves necessário,
   **Then** encontra o comando exato, e é esse o único passo manual antes de subir o ambiente.

---

### User Story 2 - Avaliador valida cada requisito pela collection (Priority: P1)

O avaliador importa a collection de testes, escolhe o ambiente local e executa as requisições
organizadas por perfil, inclusive os casos que devem falhar. Não precisa montar nenhuma
requisição à mão nem copiar token manualmente.

**Why this priority**: é entregável explícito do enunciado ("incluir collections do Postman") e
o caminho mais rápido para o avaliador comprovar a matriz de permissões.

**Independent Test**: importar collection e ambiente num Postman virgem, rodar a pasta de
autenticação e em seguida as pastas por perfil, verificando que os testes embutidos passam.

**Acceptance Scenarios**:

1. **Given** a collection e o ambiente importados, **When** o avaliador executa a requisição de
   obtenção de token de um perfil, **Then** o token é salvo automaticamente na variável de
   ambiente e as requisições seguintes o usam sem intervenção.
2. **Given** a collection, **When** o avaliador a percorre, **Then** encontra uma pasta por
   perfil (médico, enfermeiro, paciente) e uma pasta de cenários negativos.
3. **Given** a pasta de cenários negativos, **When** executada, **Then** cada requisição
   confirma o erro esperado: sem token, token adulterado e paciente pedindo histórico alheio.
4. **Given** a collection completa, **When** executada do início ao fim em ambiente recém-subido,
   **Then** todos os testes embutidos passam.

---

### User Story 3 - Operador vê o que está acontecendo (Priority: P2)

Quem opera o sistema consegue ver métricas de cada serviço, acompanhar o estado das filas e
identificar mensagens que falharam, e rastrear um evento pelos três serviços pelos logs.

**Why this priority**: é o que permite demonstrar resiliência e diagnosticar falhas na
apresentação; o sistema funciona sem isso, mas não é defensável.

**Independent Test**: provocar uma falha de processamento, localizar a mensagem na área de
mensagens com problema e seguir o mesmo identificador de evento nos logs dos serviços.

**Acceptance Scenarios**:

1. **Given** o ambiente no ar, **When** as métricas de um serviço são consultadas, **Then** são
   expostas em formato padrão de coleta (Prometheus), incluindo métricas de requisições e de
   consumo de mensagens.
2. **Given** uma mensagem que falhou em todas as tentativas, **When** o avaliador abre o painel
   de administração do broker, **Then** encontra a mensagem na fila de mensagens mortas, com a
   fila principal vazia e funcionando.
3. **Given** uma consulta agendada, **When** os logs dos três serviços são inspecionados,
   **Then** a identificação da consulta e a identificação do evento aparecem nas três pontas,
   permitindo rastrear o fluxo.
4. **Given** o banco ou o broker indisponível, **When** o estado de saúde do serviço é
   consultado, **Then** ele reporta não saudável, apontando o componente com problema.

---

### User Story 4 - Entrega auditável (Priority: P2)

Quem avalia encontra, no próprio repositório, o porquê de cada decisão de arquitetura, as
especificações que guiaram o código e o relatório da verificação de segurança.

**Why this priority**: sustenta os critérios "qualidade do código" e "documentação do projeto"
do enunciado, e é o que diferencia uma entrega SDD de uma entrega comum.

**Independent Test**: percorrer o repositório procurando especificações, registros de decisão e
relatório de segurança, sem precisar de nenhuma explicação externa.

**Acceptance Scenarios**:

1. **Given** o repositório clonado, **When** o avaliador procura as especificações, **Then**
   encontra uma pasta por funcionalidade, com especificação, plano e tarefas.
2. **Given** o repositório, **When** o avaliador procura as decisões de arquitetura, **Then**
   encontra um registro numerado por decisão, cada um com contexto, decisão e consequência.
3. **Given** o repositório, **When** o avaliador procura a interpretação das permissões adotada
   pelo projeto, **Then** encontra-a declarada explicitamente no README.
4. **Given** uma verificação de segurança automatizada executada contra o serviço de
   agendamento, **When** o relatório é consultado, **Then** não há alerta de severidade alta em
   aberto, e o relatório está anexado ao repositório.
5. **Given** o repositório, **When** o histórico de commits é inspecionado, **Then** as
   mensagens permitem identificar a que tarefa de qual especificação cada commit corresponde.

### Edge Cases

- O que acontece quando a porta de um serviço já está em uso na máquina do avaliador? O README
  documenta as portas usadas e como alterá-las por variável de ambiente.
- O que acontece quando o avaliador sobe o ambiente sem gerar as chaves? O serviço de
  agendamento falha ao iniciar com mensagem explícita sobre a chave ausente, em vez de iniciar
  emitindo tokens não verificáveis.
- O que acontece quando o banco demora mais que o serviço para ficar pronto? O serviço espera e
  só reporta saudável quando a conexão estiver de fato disponível.
- O que acontece quando o avaliador roda a collection duas vezes? As requisições continuam
  passando: nenhuma depende de estado criado fora dela própria.
- O que acontece se a verificação de segurança apontar alerta médio ou baixo? Fica registrado no
  relatório com justificativa; só alerta alto bloqueia a entrega.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Um único comando documentado MUST subir a solução completa em máquina limpa com
  apenas Docker instalado — sem exigir Java ou Maven na máquina do avaliador.
- **FR-002**: Cada serviço MUST expor um endereço de verificação de saúde que reflita o estado
  das suas dependências (banco e, quando aplicável, broker).
- **FR-003**: Cada serviço MUST expor métricas em formato padrão de coleta, incluindo métricas
  de requisições e de consumo de mensagens.
- **FR-004**: A fila de mensagens com problema (mensagens mortas) MUST ser inspecionável pelo
  painel de administração do broker, com acesso documentado no README.
- **FR-005**: Os logs MUST carregar a identificação da consulta e a identificação do evento, de
  modo que um fluxo possa ser rastreado pelos três serviços.
- **FR-006**: O repositório MUST conter uma collection de testes exportada e um ambiente
  exportado, com uma pasta por perfil e uma pasta de cenários negativos.
- **FR-007**: A collection MUST salvar o token automaticamente após a autenticação, sem
  intervenção manual, e MUST conter verificações automáticas de status e de código de erro.
- **FR-008**: O README MUST cobrir: o que é o sistema e quais requisitos atende; arquitetura e
  fluxo de eventos; como rodar (pré-requisitos, geração de chaves, comando único, portas);
  usuários de demonstração com senha e perfil; endpoints e exemplos de consulta; mensageria
  (exchange, filas, fila de mensagens mortas, painéis); decisões de arquitetura e interpretação
  das permissões; como rodar os testes e onde está o relatório de segurança.
- **FR-009**: Cada decisão de arquitetura MUST estar registrada como documento numerado com
  contexto, decisão e consequência.
- **FR-010**: A interpretação adotada para as permissões do enunciado MUST estar declarada
  explicitamente no README.
- **FR-011**: Uma verificação de segurança automatizada MUST ser executada contra o serviço de
  agendamento, o relatório MUST ser anexado ao repositório e nenhum alerta de severidade alta
  MUST permanecer em aberto.
- **FR-012**: O repositório MUST ser público e seu histórico de commits MUST permitir associar
  cada commit à tarefa e à especificação correspondentes.
- **FR-013**: Nenhum segredo (senha em texto puro, chave privada, token) MUST estar versionado,
  em nenhum ponto do histórico.
- **FR-014**: A verificação automatizada do projeto (`mvn verify`) MUST rodar a cada envio de
  código, e o resultado MUST ser visível no repositório.

### Key Entities

Não se aplica: esta funcionalidade não introduz entidades de domínio.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um avaliador que nunca viu o projeto sobe o ambiente e valida todos os requisitos
  do enunciado em menos de 15 minutos, usando apenas o README e a collection.
- **SC-002**: Em uma máquina limpa, o comando único documentado leva os três serviços a
  reportarem saúde sem nenhuma intervenção além da geração das chaves.
- **SC-003**: 100% das requisições da collection passam suas verificações automáticas em
  ambiente recém-subido.
- **SC-004**: O README cobre os 8 tópicos de FR-008, verificável por conferência item a item.
- **SC-005**: Zero alertas de severidade alta em aberto no relatório da verificação de
  segurança.
- **SC-006**: Zero segredos encontrados por busca automatizada em todo o histórico do
  repositório.
- **SC-007**: Toda decisão de arquitetura mencionada no README tem o registro numerado
  correspondente no repositório.

## Assumptions

- O avaliador tem Docker e Docker Compose instalados; Java e Maven não são pré-requisitos,
  porque a compilação acontece dentro da imagem.
- A geração do par de chaves RSA é o único passo manual aceito antes de subir o ambiente, porque
  a chave privada não pode ser versionada (Princípio III da constituição).
- A verificação dinâmica de segurança é feita com a varredura de linha de base do OWASP ZAP,
  conforme a aula 5 de segurança.
- Painel de métricas (Prometheus e Grafana) e gateway na frente dos serviços são desejáveis mas
  opcionais; a exposição das métricas em formato padrão é obrigatória.
- A collection é do Postman, formato aceito pelo enunciado ("Postman ou similar").
- A integração contínua roda em GitHub Actions, por ser o provedor do repositório.

## Out of Scope

- Implantação em nuvem, Kubernetes e provisionamento de infraestrutura real.
- Alertas, plantão e definição de indicadores de serviço (SLO).
- Rastreamento distribuído completo (apenas correlação por log está no escopo).
- Testes de carga e dimensionamento de capacidade.

## Dependencies

- Depende de F1 a F5 estarem implementadas para que a collection, o README e a verificação de
  segurança tenham o que cobrir.
- Depende da constituição do projeto (`.specify/memory/constitution.md`), Princípio VII, que
  fixa as exigências de operabilidade e reprodutibilidade.
