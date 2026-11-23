# ADR-004 — Publicar o evento somente após o commit

- **Status**: Aceita
- **Data**: 2026-11-23
- **Decisores**: Felipe Dias Mac Dowell

## Contexto

O serviço de agendamento grava a consulta no PostgreSQL e publica um evento no RabbitMQ. São
dois recursos distintos, sem transação distribuída entre eles. A ordem das duas operações decide
qual falha é possível:

- Publicar **antes** do commit: se a transação for revertida (conflito de agenda detectado
  tarde, erro de banco, bloqueio otimista), o evento já saiu. O paciente recebe e-mail de uma
  consulta que não existe e o histórico grava um atendimento fantasma.
- Publicar **depois** do commit: se o broker estiver fora do ar entre o commit e o envio, a
  consulta existe mas o evento não sai. O paciente não é avisado, mas nada falso é afirmado.

Os critérios de aceite de F2 e F3 são explícitos: quando uma regra é violada, "nada é gravado e
nenhum anúncio é emitido".

## Decisão

O evento é publicado em um `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)`.
O service de negócio apenas dispara um evento de aplicação dentro da transação; o publicador
AMQP só age depois que o commit foi confirmado.

Entre as duas falhas possíveis, escolhemos conscientemente a de **perda** em vez da de
**mentira**: é melhor não avisar do que avisar errado.

## Alternativas consideradas

**Publicar dentro da transação, direto no service.** Recusado: produz evento de consulta
revertida, violando frontalmente os critérios de aceite de F2 e F3.

**Transactional Outbox.** A evolução correta: o evento é gravado numa tabela na mesma transação
da consulta e um processo separado a drena para o broker, o que elimina também a janela entre o
commit e o envio. Recusado **nesta fase** por custo: exige tabela de outbox, processo de drenagem,
controle de concorrência entre réplicas e testes próprios, para fechar uma janela de milissegundos
num sistema de demonstração. Fica registrado como evolução planejada.

**Transação distribuída (XA) entre PostgreSQL e RabbitMQ.** Recusado: complexidade e custo de
desempenho desproporcionais, e desencorajado pela própria documentação do Spring para este tipo
de fluxo.

## Consequências

- Nenhum evento jamais descreve uma consulta que não está gravada. É isso que torna os critérios
  de aceite de F2 e F3 verificáveis.
- Resta uma janela de perda: se o processo morrer ou o broker estiver indisponível exatamente
  entre o commit e a publicação, a consulta fica sem evento. Consequência aceita e documentada;
  nesse caso o paciente não recebe confirmação e o histórico não registra a consulta.
- Fica obrigatório que a regra de negócio e as validações rodem **antes** do commit, e não no
  publicador: o publicador não decide nada, só envia.
- O teste "evento publicado após commit" (F2) precisa de um cenário de rollback explícito para
  provar que nada foi publicado — não basta testar o caminho feliz.
