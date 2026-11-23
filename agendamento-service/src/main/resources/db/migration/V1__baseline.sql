-- agendamento-service — baseline do Flyway (Sprint 0).
--
-- Esta migracao existe para estabelecer a linha de base do schema sem criar nenhuma
-- tabela: na Sprint 0 os servicos sobem vazios, por exigencia do Principio I da
-- constituicao (nenhum codigo de producao antes da spec que o implementa).
--
-- As tabelas de dominio entram nas migracoes das suas proprias sprints:
--   V2 — usuario, perfil, paciente, medico (F1, Sprint 1)
--   V3 — consulta (F2/F3, Sprint 2)

SELECT 1;
