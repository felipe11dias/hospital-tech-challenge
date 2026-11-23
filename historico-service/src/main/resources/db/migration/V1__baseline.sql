-- historico-service — baseline do Flyway (Sprint 0).
--
-- Esta migracao existe para estabelecer a linha de base do schema sem criar nenhuma
-- tabela: na Sprint 0 os servicos sobem vazios, por exigencia do Principio I da
-- constituicao (nenhum codigo de producao antes da spec que o implementa).
--
-- As tabelas de dominio entram nas migracoes das suas proprias sprints:
--   V2 — consulta_historico (F5, Sprint 4)

SELECT 1;
