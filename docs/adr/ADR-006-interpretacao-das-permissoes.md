# ADR-006 — Interpretação das permissões do enunciado

- **Status**: Aceita
- **Data**: 2026-11-23
- **Decisores**: Felipe Dias Mac Dowell

## Contexto

O enunciado descreve os níveis de acesso em três linhas:

> - Médicos: podem visualizar e editar o histórico de consultas.
> - Enfermeiros: podem registrar consultas e acessar o histórico.
> - Pacientes: podem visualizar apenas as suas consultas.

Essas frases deixam duas ambiguidades que mudam o comportamento do sistema e, portanto, os
testes:

1. **O que é "editar o histórico"?** Pode significar (a) alterar dados da consulta — data,
   médico, cancelamento — ou (b) registrar o resultado clínico do atendimento: observações e
   marcação de realizada.
2. **Enfermeiro pode alterar uma consulta já criada?** O enunciado diz que ele "registra
   consultas", o que literalmente só cobre a criação. Mas o próprio enunciado pede, em outro
   ponto, que "médicos e enfermeiros poderão registrar novas consultas e modificar consultas
   existentes".

Sem uma decisão explícita, os dois perfis ficariam indistinguíveis ou o enfermeiro ficaria
impedido de remarcar — o que contradiria a seção de GraphQL do próprio enunciado.

## Decisão

Adotamos a seguinte leitura, declarada no README e transformada na matriz de permissões de F1:

- **"Editar o histórico" = registrar observações clínicas e marcar a consulta como REALIZADA.**
  É ato clínico e é **exclusivo do MÉDICO**.
- **"Modificar consultas" = remarcar, trocar o médico responsável e cancelar.** É ato
  administrativo e vale para **MÉDICO e ENFERMEIRO**, conforme a seção de GraphQL do enunciado.
- **"Acessar o histórico"** (visualizar) vale para MÉDICO e ENFERMEIRO, para qualquer paciente.
- **PACIENTE** apenas visualiza, e apenas as consultas vinculadas ao seu próprio
  `pacienteId` — lido do token, nunca de argumento do cliente.
- **PACIENTE não cria nem altera nada.**

## Alternativas consideradas

**Interpretação literal estrita**: enfermeiro só cria, nunca altera. Recusada porque contradiz
a seção "Serviço de Agendamento" do enunciado, que atribui a modificação a médicos **e**
enfermeiros.

**Interpretação ampla**: "editar o histórico" inclui alterar qualquer campo, inclusive
observações clínicas, para médico e enfermeiro. Recusada porque apagaria a distinção entre os
dois perfis que o enunciado faz questão de estabelecer — e um sistema em que MEDICO e
ENFERMEIRO fazem exatamente o mesmo falharia no critério "níveis de acesso".

## Consequências

- Médico e enfermeiro passam a ter uma diferença concreta e testável: apenas o médico registra
  atendimento. Esse é o teste `F3_CA3_enfermeiroNaoRegistraAtendimento`.
- Observação clínica é escrita uma única vez, junto da marcação de realizada (F3, Assumptions):
  não existe "editar observação depois", o que mantém a leitura coerente com o conceito de
  registro clínico.
- Esta interpretação **precisa** estar no README (F6, FR-010). O avaliador pode ter outra
  leitura do enunciado; o que não pode acontecer é ele não saber qual foi a nossa.
- A matriz de permissões de F1 passa a ser a fonte única dessa decisão, e cada uma de suas
  linhas vira um teste automatizado (F1, SC-002).
