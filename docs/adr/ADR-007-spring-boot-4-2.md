# ADR-007 — Spring Boot 4.2.0 em vez de 4.0.x

- **Status**: Aceita
- **Data**: 2026-11-23
- **Decisores**: Felipe Dias Mac Dowell

## Contexto

O roadmap do projeto, escrito em 19/11/2026, fixa **Spring Boot 4.0.x** com a seguinte
justificativa declarada: é "a geração com suporte gratuito hoje". Na mesma seção, o roadmap
orienta: "Se alguma biblioteca ainda não suportar o Boot 4 na sua data, fique no 3.5.x".

Ao iniciar a Sprint 0, em 23/11/2026, a consulta ao Spring Initializr mostrou um cenário
diferente do pressuposto pelo roadmap:

- Versão padrão oferecida: **4.2.0.RELEASE** (GA).
- Linha 4.1 em `4.1.3.RELEASE`, também GA.
- Linha 4.0 em `4.0.10.RELEASE` — ou seja, a linha fixada pelo roadmap está no fim do seu ciclo
  de correções gratuitas, enquanto duas gerações mais novas já são GA.

Ficar em 4.0.x cumpriria a **letra** do roadmap e violaria a sua **razão declarada**: o projeto
nasceria sobre uma linha que sai do suporte gratuito em semanas.

## Decisão

O `pom` pai fixa **Spring Boot 4.2.0**, com **Java 21** (LTS, como o roadmap determina).

A diferença prática em relação a 4.0.x é nula para este projeto: a DSL de segurança
(`SecurityFilterChain`, `authorizeHttpRequests`, `oauth2ResourceServer`), o Spring for GraphQL e
o Spring AMQP têm a mesma API nas três linhas da geração 4. O código de referência do roadmap
roda sem alteração.

## Alternativas consideradas

**Ficar em 4.0.10.RELEASE**, seguindo a letra do roadmap. Recusada: entrega um projeto novo
sobre uma linha em fim de suporte, contrariando a justificativa que o próprio roadmap deu para
escolhê-la.

**Voltar para Spring Boot 3.5.x**, exatamente a versão das aulas (Spring Security 6.1). Recusada:
a linha 3.5 deixou de receber correções gratuitas em 30/06/2026. Seria uma escolha defensável
apenas se alguma biblioteca necessária não suportasse o Boot 4 — e não é o caso: todas as
dependências do projeto (Security + OAuth2 Resource Server, GraphQL, AMQP, Flyway, Actuator,
Testcontainers) estão disponíveis para a geração 4 no Initializr.

**Usar 4.1.3.RELEASE**, uma geração intermediária. Recusada por não ter vantagem sobre 4.2.0:
ambas são GA e a mais nova tem o maior horizonte de suporte.

## Consequências

- O projeto começa na geração com o maior horizonte de correções gratuitas, que era a intenção
  declarada do roadmap.
- O roadmap fica, neste ponto, divergente da constituição do projeto. A constituição
  (`.specify/memory/constitution.md`, seção "Stack Obrigatória") prevalece, conforme sua própria
  seção Governance, e este ADR é o registro da divergência.
- Onde o código de referência do roadmap trouxer comentário específico de 3.5
  (`Jackson2JsonMessageConverter` em vez de `JacksonJsonMessageConverter`), vale a variante do
  Boot 4.
- Qualquer nova mudança de versão da stack exige novo ADR, conforme a seção "Stack Obrigatória"
  da constituição.
