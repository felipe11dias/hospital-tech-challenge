# ADR-005 — Consumidores idempotentes por `eventId`

- **Status**: Aceita
- **Data**: 2026-11-23
- **Decisores**: Felipe Dias Mac Dowell

## Contexto

O RabbitMQ garante entrega **pelo menos uma vez**, não exatamente uma vez. Uma mensagem é
reentregue quando o consumidor cai antes do ack, quando a conexão é perdida no meio do
processamento, ou quando o retry do listener reprocessa após falha parcial. Isso não é falha de
configuração: é a semântica da ferramenta.

O efeito de uma reentrega sem tratamento é visível para o usuário final: o paciente recebe dois
e-mails de confirmação da mesma consulta (F4) ou o histórico ganha duas linhas para o mesmo
atendimento (F5). Em ambos os casos, o avaliador vê o defeito sem precisar ler o código.

## Decisão

Todo evento carrega um `eventId` (UUID) gerado na origem, no momento em que o fato acontece — e
não no momento do envio, para que um reenvio do mesmo fato mantenha o mesmo identificador.

Todo consumidor é **idempotente por `eventId`**:

- O serviço de **notificações** mantém uma tabela `evento_processado` (`eventId` como chave
  primária, instante de processamento). Antes de agir, verifica se o `eventId` já existe; se
  existir, descarta a mensagem sem efeito. A gravação do `eventId` acontece na **mesma
  transação** do efeito, para que não exista estado em que o e-mail saiu e o registro não foi
  gravado.
- O serviço de **histórico** usa idempotência natural: a atualização é por inserção-ou-atualização
  pela identificação da consulta, e eventos com `versao` menor ou igual à registrada são
  descartados. Reaplicar o mesmo evento não muda nada.

## Alternativas consideradas

**Confiar no ack e não tratar duplicidade.** Recusado: contraria a semântica do broker e falha
no critério de aceite de F4 ("dado o mesmo `eventId` entregue duas vezes, só um e-mail é
enviado").

**Deduplicação em memória (cache no processo).** Recusado: perde o estado ao reiniciar o
serviço, e o cenário de demonstração da F4 é exatamente parar e religar o serviço de
notificações.

**Deduplicação no broker (plugin de deduplicação do RabbitMQ).** Recusado: empurra a garantia
para a infraestrutura, exige plugin extra no container e não protege contra reprocessamento
causado pelo retry do próprio listener.

## Consequências

- O paciente nunca recebe e-mail em dobro por causa de reentrega, e o histórico nunca duplica
  uma consulta. São dois critérios de aceite diretamente atendidos (F4 e F5).
- A tabela `evento_processado` cresce indefinidamente. Aceito no escopo; expurgo por idade
  (manter, por exemplo, 90 dias) fica registrado como melhoria, não como requisito.
- Fica obrigatório que o efeito e o registro do `eventId` sejam **atômicos**. Se o e-mail for
  enviado fora da transação, uma falha depois do envio reprocessaria a mensagem e enviaria de
  novo — por isso o envio do lembrete é desacoplado em uma entidade `Lembrete` com status, e não
  feito direto dentro do consumidor.
- Fica obrigatório que o `eventId` seja gerado na origem do fato. Gerar no publicador quebraria a
  idempotência num reenvio.
