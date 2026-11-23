# ADR-003 — Histórico como modelo de leitura (CQRS leve)

- **Status**: Aceita
- **Data**: 2026-11-23
- **Decisores**: Felipe Dias Mac Dowell

## Contexto

O enunciado lista o serviço de histórico como **opcional** e pede que ele "armazene o histórico
de consultas e disponibilize dados via GraphQL". O serviço de agendamento já é dono das
consultas e já tem os dados. A pergunta é: o histórico lê os dados do agendamento, ou mantém a
própria cópia?

O Princípio IV da constituição proíbe um serviço ler a tabela de outro. Ler via chamada
síncrona ao agendamento resolveria a proibição de banco, mas acoplaria a disponibilidade da
consulta de histórico à disponibilidade do agendamento.

## Decisão

O histórico é um **modelo de leitura** (CQRS leve). O agendamento continua dono de todas as
escritas; o histórico consome os mesmos eventos publicados na exchange `hospital.consultas` e
mantém uma tabela própria (`consulta_historico`), otimizada para as consultas GraphQL de F5.

A atualização é por inserção-ou-atualização pela identificação da consulta, e eventos com
`versao` menor ou igual à já registrada são descartados — o que torna a atualização tolerante a
chegada fora de ordem e a entrega repetida.

## Alternativas consideradas

**Não implementar o serviço de histórico** (ele é opcional) e expor a consulta GraphQL no
próprio agendamento. Recusado: deixaria de demonstrar consistência eventual e perderia um
critério de avaliação ("separação em mais de um serviço") que o enunciado valoriza.

**Histórico consultando o agendamento por REST ou gRPC a cada consulta.** Recusado: o histórico
ficaria indisponível junto com o agendamento, e cada consulta GraphQL geraria chamadas de rede
em cascata — o oposto do que o GraphQL deveria resolver.

**Histórico lendo direto o banco do agendamento.** Recusado por violar o Princípio IV: dois
serviços acoplados pelo schema do banco não são microsserviços, são um monólito distribuído com
duas implantações.

## Consequências

- O histórico responde consultas mesmo com o agendamento fora do ar, e sua modelagem pode ser
  desnormalizada (nome do médico gravado junto da consulta), o que simplifica o GraphQL.
- A consistência passa a ser **eventual**: logo após agendar, o histórico pode demorar instantes
  para refletir a nova consulta. Isso está declarado em F5 (Assumptions) e deve constar no
  README, porque o avaliador vai perceber.
- Os dados ficam duplicados de propósito. O agendamento é a fonte da verdade; o histórico é
  descartável e reconstruível (reprocessando eventos, se houver reenvio).
- Fica obrigatório que o evento carregue tudo o que o histórico precisa exibir
  (event-carried state transfer): identificação e nome do médico, dados do paciente, status e
  observações. Sem isso, o histórico precisaria perguntar de volta.
- O campo `versao` no evento passa a ser requisito de contrato, não um extra.
