# ADR-002 — JWT stateless emitido pelo agendamento

- **Status**: Aceita
- **Data**: 2026-11-23
- **Decisores**: Felipe Dias Mac Dowell

## Contexto

O enunciado pede "autenticação básica para garantir que cada tipo de usuário tenha acesso
controlado às funcionalidades". Ao mesmo tempo, dois serviços distintos (agendamento e
histórico) precisam reconhecer o mesmo usuário e o mesmo perfil, e o serviço de histórico não
tem — nem deve ter — acesso ao cadastro de usuários, por causa do Princípio IV da constituição
(autonomia de dados).

Autenticação básica pura em todas as chamadas resolveria o primeiro requisito, mas faria a senha
trafegar em cada requisição e exigiria que o histórico consultasse o banco de usuários do
agendamento a cada chamada.

## Decisão

O serviço de **agendamento** é o emissor de credenciais. O cliente troca usuário e senha, via
HTTP Basic, em `POST /auth/token` por um **JWT assinado com chave privada RSA (RS256)**. Todas
as demais operações, nos dois serviços, usam `Authorization: Bearer <token>`.

Claims do token:

| Claim | Conteúdo | Observação |
| --- | --- | --- |
| `sub` | nome de usuário | identifica quem agiu, para auditoria |
| `roles` | lista com um único perfil | `MEDICO`, `ENFERMEIRO` ou `PACIENTE` |
| `pacienteId` | identificação do paciente | presente **somente** para perfil PACIENTE |
| `exp` | expiração | 1 hora após a emissão |
| `iss` | `agendamento-service` | emissor |

O serviço de **histórico** valida o token apenas com a **chave pública**, sem consultar banco
de usuários. A chave privada é fornecida por variável de ambiente ou volume e nunca é
versionada.

## Alternativas consideradas

**HTTP Basic em todas as chamadas.** Recusado: senha em cada requisição, e o histórico
precisaria consultar o cadastro de usuários do agendamento — violação direta do Princípio IV.

**JWT simétrico (HS256) com segredo compartilhado.** Recusado: o segredo teria de existir nos
dois serviços, e quem pode validar passaria a poder emitir. Com RSA, o histórico só consegue
verificar.

**Servidor de autorização dedicado (OAuth2 completo) ou Keycloak.** Recusado por
desproporcionalidade: acrescentaria um quarto serviço e um fluxo de consentimento a um sistema
de três serviços e três perfis fixos. A aula 2 de Segurança mostra o caminho; não é requisito
do enunciado.

## Consequências

- O requisito "autenticação básica" do enunciado é cumprido literalmente, na única operação em
  que a senha precisa aparecer.
- O histórico fica stateless e independente: funciona mesmo se o banco de usuários estiver fora
  do ar, porque só precisa da chave pública.
- Não há revogação de token. Um token vazado vale até expirar (1 hora). Aceito para o escopo;
  lista de revogação ficaria fora de proporção aqui.
- A geração do par de chaves RSA passa a ser pré-requisito documentado para subir o ambiente
  (F6, FR-001 e User Story 1), e o serviço de agendamento deve falhar ao iniciar sem a chave,
  em vez de emitir tokens não verificáveis.
- O claim `pacienteId` torna-se a única fonte de verdade sobre qual paciente o usuário pode ver
  (F5, FR-007); argumento vindo do cliente nunca substitui esse claim.
