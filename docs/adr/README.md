# Registros de decisão de arquitetura (ADR)

Cada decisão de arquitetura deste projeto é registrada num arquivo numerado, com contexto,
decisão e consequência. O Princípio VII da [constituição](../../.specify/memory/constitution.md)
é explícito: decisão sem ADR é decisão não tomada.

| ADR | Decisão | Status |
| --- | --- | --- |
| [ADR-001](ADR-001-rabbitmq-em-vez-de-kafka.md) | RabbitMQ em vez de Kafka | Aceita |
| [ADR-002](ADR-002-jwt-stateless-emitido-pelo-agendamento.md) | JWT stateless emitido pelo agendamento | Aceita |
| [ADR-003](ADR-003-historico-como-modelo-de-leitura.md) | Histórico como modelo de leitura (CQRS leve) | Aceita |
| [ADR-004](ADR-004-publicar-apos-o-commit.md) | Publicar o evento somente após o commit | Aceita |
| [ADR-005](ADR-005-consumidores-idempotentes.md) | Consumidores idempotentes por `eventId` | Aceita |
| [ADR-006](ADR-006-interpretacao-das-permissoes.md) | Interpretação das permissões do enunciado | Aceita |
| [ADR-007](ADR-007-spring-boot-4-2.md) | Spring Boot 4.2.0 em vez de 4.0.x | Aceita |

## Formato

Todo ADR segue a mesma estrutura:

```markdown
# ADR-NNN — Título em uma linha

- **Status**: Proposta | Aceita | Substituída por ADR-MMM
- **Data**: AAAA-MM-DD
- **Decisores**: quem decidiu

## Contexto
O que forçou a decisão: restrição, requisito do enunciado ou problema observado.

## Decisão
O que foi decidido, na voz ativa e no presente.

## Alternativas consideradas
O que mais estava na mesa e por que foi recusado.

## Consequências
O que fica mais fácil, o que fica mais difícil e o que passa a ser obrigatório por causa disso.
```

Um ADR nunca é editado para mudar a decisão: ele é marcado como substituído e um novo ADR é
escrito. O histórico das decisões é parte da entrega.
