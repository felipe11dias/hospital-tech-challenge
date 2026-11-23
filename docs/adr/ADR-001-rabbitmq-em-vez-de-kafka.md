# ADR-001 — RabbitMQ em vez de Kafka

- **Status**: Aceita
- **Data**: 2026-11-23
- **Decisores**: Felipe Dias Mac Dowell

## Contexto

O enunciado da Fase 3 exige comunicação assíncrona entre o serviço de agendamento e o de
notificações, e permite RabbitMQ **ou** Kafka. Os dois foram estudados nas aulas de Mensageria
(aulas 2 e 3 para Kafka, 4 e 5 para RabbitMQ), então a escolha não é por falta de conhecimento
de uma das ferramentas e precisa ser justificada pela natureza do problema.

O fluxo real do sistema é: "uma consulta foi criada, avise o paciente". É um comando de negócio
de baixo volume (dezenas a centenas de mensagens por dia num hospital de demonstração), em que
importa confirmação por mensagem, reenvio da que falhou e um lugar para isolar a que não pode
ser processada.

## Decisão

Usamos **RabbitMQ 4** com Spring AMQP, em uma topic exchange durável `hospital.consultas`, com
uma fila por consumidor (`notificacao.consultas` e `historico.consultas`), filas duráveis,
mensagens persistentes e dead-letter exchange `hospital.consultas.dlx`.

## Alternativas consideradas

**Apache Kafka.** Recusado para este problema. Kafka é a escolha certa para alto volume,
reprocessamento de histórico a partir de offsets e streaming contínuo — nada disso é requisito
aqui. Em troca, traria tópicos particionados, grupos de consumidores e gestão de offsets para
resolver um problema que são quatro tipos de evento e dois consumidores. Seria infraestrutura
maior que o problema, e a demonstração da fila de mensagens com problema (exigida pela F4)
precisaria ser construída à mão, porque Kafka não tem DLQ nativa.

**Chamada síncrona entre os serviços (REST ou gRPC).** Recusada: acoplaria a disponibilidade do
agendamento à do serviço de notificações, que é exatamente o que o enunciado pede para evitar.

## Consequências

- Ganhamos nativamente: ack por mensagem, retry com backoff, dead-letter queue e roteamento por
  routing key — tudo o que os critérios de aceite da F4 exigem.
- O painel de administração do RabbitMQ (porta 15672) serve como prova visual das filas e da
  DLQ na apresentação, atendendo F6 sem ferramenta extra.
- Perdemos a capacidade de reprocessar o histórico de eventos: uma mensagem consumida não pode
  ser lida de novo. Por isso o serviço de histórico mantém a própria cópia de leitura
  (ADR-003), em vez de reconstruir estado relendo o log.
- Fica obrigatório: toda fila e toda mensagem duráveis, e todo consumidor idempotente
  (ADR-005), porque o RabbitMQ garante entrega "pelo menos uma vez".
