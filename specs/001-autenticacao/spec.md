# Feature Specification: F1 — Autenticação e perfis de acesso

**Feature Branch**: `001-autenticacao`

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Autenticação com Spring Security e acesso controlado por perfil MÉDICO, ENFERMEIRO e PACIENTE. Usuários com perfil único, senha protegida por hash, carga inicial de usuários de demonstração. O cliente troca credenciais por um token de acesso de curta duração que carrega o perfil e, no caso do paciente, a identificação do próprio paciente."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Profissional obtém credencial de acesso (Priority: P1)

Um médico ou enfermeiro do hospital informa usuário e senha e recebe uma credencial de acesso
temporária. Com ela, passa a conseguir usar as operações do sistema correspondentes ao seu
perfil, sem reenviar a senha em cada chamada.

**Why this priority**: sem credencial não existe nenhuma outra operação do sistema. É a porta
de entrada de todas as demais funcionalidades (F2 a F5) e o primeiro requisito do enunciado.

**Independent Test**: pode ser testada isoladamente autenticando cada um dos três perfis e
verificando que a credencial devolvida identifica o usuário e o perfil corretos. Entrega valor
por si: comprova que o sistema distingue quem é quem.

**Acceptance Scenarios**:

1. **Given** o usuário de demonstração `dr.house` com a senha correta, **When** solicita a
   credencial de acesso informando usuário e senha, **Then** recebe sucesso e uma credencial
   que declara o perfil MEDICO e validade de 1 hora.
2. **Given** o usuário `enf.ana` com a senha correta, **When** solicita a credencial, **Then**
   recebe uma credencial que declara o perfil ENFERMEIRO.
3. **Given** a senha incorreta para um usuário existente, **When** solicita a credencial,
   **Then** o acesso é recusado como não autenticado e nenhuma credencial é devolvida.
4. **Given** um usuário inexistente, **When** solicita a credencial, **Then** o acesso é
   recusado como não autenticado, com a mesma resposta do caso de senha errada — sem revelar se
   o usuário existe.

---

### User Story 2 - Paciente obtém credencial vinculada a si (Priority: P1)

Um paciente informa usuário e senha e recebe uma credencial que, além do perfil PACIENTE,
carrega a identificação do próprio paciente. Essa identificação é a única usada depois para
decidir quais consultas ele pode ver.

**Why this priority**: é a regra que impede um paciente de ler o histórico de outro, o risco de
privacidade mais grave do sistema. Sem ela, F5 não pode ser liberada.

**Independent Test**: autenticar um paciente e verificar que a credencial carrega a sua
identificação de paciente, e que a credencial de um profissional não carrega nenhuma.

**Acceptance Scenarios**:

1. **Given** o usuário `paciente.maria`, de perfil PACIENTE, vinculado a um cadastro de
   paciente, **When** solicita a credencial, **Then** a credencial declara o perfil PACIENTE e
   a identificação do paciente vinculado.
2. **Given** um usuário de perfil MEDICO, **When** solicita a credencial, **Then** a credencial
   não carrega nenhuma identificação de paciente.

---

### User Story 3 - Acesso sem credencial válida é barrado (Priority: P1)

Qualquer tentativa de usar uma operação do sistema sem credencial, com credencial expirada ou
com credencial adulterada é recusada antes de chegar à regra de negócio.

**Why this priority**: é o que transforma a autenticação em controle efetivo. Um sistema que
emite credenciais mas não as exige não protege nada.

**Independent Test**: chamar uma operação protegida em quatro condições (sem credencial,
expirada, adulterada, válida) e verificar que só a última passa.

**Acceptance Scenarios**:

1. **Given** nenhuma credencial na requisição, **When** chama qualquer operação protegida,
   **Then** recebe recusa por falta de autenticação.
2. **Given** uma credencial cuja validade já passou, **When** chama uma operação protegida,
   **Then** recebe recusa por falta de autenticação.
3. **Given** uma credencial cujo conteúdo foi alterado após a emissão, **When** chama uma
   operação protegida, **Then** recebe recusa por falta de autenticação.
4. **Given** uma credencial válida e dentro da validade, **When** chama uma operação permitida
   ao seu perfil, **Then** a operação é executada.

---

### User Story 4 - Perfil limita o que cada um faz (Priority: P2)

Cada perfil só consegue executar as ações previstas para ele. Um paciente autenticado não
consegue agendar; um enfermeiro autenticado não consegue registrar observações clínicas.

**Why this priority**: depende das operações de F2 a F5 existirem para ser verificável de ponta
a ponta, mas a decisão de autorização pertence a esta spec.

**Independent Test**: para cada linha da matriz de permissões, chamar a operação com cada um
dos três perfis e conferir permissão ou recusa por falta de autorização.

**Acceptance Scenarios**:

1. **Given** um PACIENTE autenticado, **When** tenta agendar uma consulta, **Then** recebe
   recusa por falta de autorização (e não por falta de autenticação).
2. **Given** um ENFERMEIRO autenticado, **When** tenta registrar observações clínicas de uma
   consulta, **Then** recebe recusa por falta de autorização.
3. **Given** um MÉDICO autenticado, **When** registra observações clínicas, **Then** a operação
   é permitida.

### Edge Cases

- O que acontece quando o mesmo usuário solicita duas credenciais seguidas? Ambas são válidas
  até expirarem; não há invalidação da anterior (não há revogação neste escopo).
- O que acontece quando um usuário de perfil PACIENTE não está vinculado a nenhum cadastro de
  paciente? A emissão da credencial falha com erro de dados inconsistentes, porque uma
  credencial de paciente sem identificação de paciente não pode ser usada em nenhuma consulta.
- O que acontece se a chave usada para assinar a credencial não estiver disponível no ambiente?
  O serviço não inicia, em vez de iniciar emitindo credenciais não verificáveis.
- O que acontece com uma credencial emitida por este sistema apresentada ao serviço de
  histórico? É aceita, porque os dois serviços confiam na mesma chave de verificação.
- O que acontece com uma credencial assinada por outra chave? É recusada em ambos os serviços.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST manter um cadastro de usuários em que cada usuário tem exatamente
  um perfil, dentre MEDICO, ENFERMEIRO e PACIENTE.
- **FR-002**: O sistema MUST armazenar senhas apenas como hash de senha com sal (BCrypt),
  nunca em texto puro, incluindo nas cargas iniciais de demonstração.
- **FR-003**: O sistema MUST oferecer uma operação de troca de credenciais (usuário e senha)
  por um token de acesso, aceitando as credenciais no esquema de autenticação básica.
- **FR-004**: O token MUST declarar o identificador do usuário, o seu perfil e o instante de
  expiração, com validade de 1 hora a partir da emissão.
- **FR-005**: Quando o usuário tem perfil PACIENTE, o token MUST declarar a identificação do
  cadastro de paciente vinculado; para os outros perfis, MUST NOT declarar nenhuma.
- **FR-006**: O token MUST ser assinado com chave privada RSA e verificável apenas com a chave
  pública correspondente; a chave privada MUST ser fornecida por variável de ambiente ou volume
  e MUST NOT estar no repositório.
- **FR-007**: O sistema MUST recusar, como não autenticada, toda requisição a operação
  protegida que não apresente token, apresente token expirado ou apresente token cuja
  assinatura não confira.
- **FR-008**: O sistema MUST autorizar cada operação segundo a matriz de permissões abaixo,
  recusando por falta de autorização (e não por falta de autenticação) o usuário autenticado
  cujo perfil não permita a ação.
- **FR-009**: O sistema MUST recusar a emissão de credencial com a mesma resposta para senha
  incorreta e usuário inexistente, sem indicar qual dos dois ocorreu.
- **FR-010**: O sistema MUST carregar, na inicialização do ambiente de demonstração, ao menos
  um usuário de cada perfil, com senhas documentadas no README.
- **FR-011**: Os serviços que apenas consomem o token (histórico) MUST verificá-lo somente com
  a chave pública, sem consultar o cadastro de usuários.
- **FR-012**: A identificação de paciente usada em qualquer decisão de acesso MUST ser lida do
  token, e MUST NOT ser aceita como argumento vindo do cliente.

### Matriz de permissões

| Ação | MEDICO | ENFERMEIRO | PACIENTE | Sem credencial |
| --- | --- | --- | --- | --- |
| Obter token de acesso | permitido | permitido | permitido | não autenticado |
| Agendar consulta | permitido | permitido | não autorizado | não autenticado |
| Remarcar consulta ou trocar o médico | permitido | permitido | não autorizado | não autenticado |
| Cancelar consulta | permitido | permitido | não autorizado | não autenticado |
| Registrar observações e marcar realizada | permitido | não autorizado | não autorizado | não autenticado |
| Ver histórico de qualquer paciente | permitido | permitido | só o próprio | não autenticado |
| Ver as próprias consultas | não se aplica | não se aplica | permitido | não autenticado |

### Key Entities

- **Usuário**: quem acessa o sistema. Identificador de login único, hash de senha, perfil
  único, vínculo opcional com um cadastro de paciente.
- **Perfil**: papel do usuário no hospital. Valores fechados: MEDICO, ENFERMEIRO, PACIENTE.
- **Paciente**: pessoa atendida. Nome e e-mail de contato; é o alvo das consultas e das
  notificações. Um usuário de perfil PACIENTE aponta para exatamente um Paciente.
- **Médico**: profissional que atende. Nome e especialidade; é quem tem agenda.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Os três perfis de demonstração obtêm credencial de acesso na primeira tentativa,
  usando apenas as instruções do README, em menos de 2 minutos após o ambiente subir.
- **SC-002**: 100% das linhas da matriz de permissões têm teste automatizado, e todos passam.
- **SC-003**: Nenhuma senha aparece em texto puro em nenhum artefato do repositório nem em
  nenhuma tabela do banco (verificação automatizada: todo hash começa com `$2a$` ou `$2b$`).
- **SC-004**: Nenhuma chave privada está versionada no repositório (verificação por busca em
  todo o histórico).
- **SC-005**: Credencial expirada, ausente ou adulterada é recusada em 100% das tentativas,
  sem nunca chegar à regra de negócio.

## Assumptions

- Perfil único por usuário: o enunciado descreve três tipos de usuário sem mencionar acúmulo de
  papéis; um usuário com dois perfis fica fora do escopo.
- Validade de 1 hora para o token, sem mecanismo de renovação nem de revogação: suficiente para
  a demonstração e para o uso via collection de testes.
- O cadastro de usuários é dono do serviço de agendamento; é ele quem emite as credenciais. O
  serviço de histórico apenas as verifica.
- "Autenticação básica", pedida pelo enunciado, é atendida na operação de troca de credenciais;
  as demais operações usam o token, para não trafegar senha em cada chamada.
- Usuários de demonstração são criados por migração de banco, não por cadastro em tempo de
  execução: autocadastro está fora do escopo.
- Não há recuperação de senha, bloqueio por tentativas nem autenticação em dois fatores neste
  escopo.

## Dependencies

- O contrato de interface externo (nome da operação de token, formato da resposta e nomes dos
  campos declarados no token) é herdado do roadmap do projeto e está registrado em
  `docs/Roadmap SDD — Tech Challenge Fase 3 (Sistema Hospitalar).md`, seção "Registros de
  decisão" (ADR-002) — esta spec descreve o comportamento, não o formato.
- As operações citadas na matriz de permissões são especificadas em F2 (`002-agendar-consulta`),
  F3 (`003-modificar-consulta`) e F5 (`005-historico-graphql`); a User Story 4 só pode ser
  testada de ponta a ponta quando elas existirem.
