CREATE OR REPLACE TRIGGER trg_normalizar_mes_referencia_lancamentos
BEFORE INSERT OR UPDATE OF mes_referencia
ON lancamentos_despesas
FOR EACH ROW
EXECUTE FUNCTION fn_normalizar_mes_referencia();