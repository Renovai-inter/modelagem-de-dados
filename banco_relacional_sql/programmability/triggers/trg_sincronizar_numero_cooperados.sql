CREATE OR REPLACE TRIGGER trg_sincronizar_numero_cooperados
AFTER INSERT OR UPDATE OR DELETE ON funcionarios
FOR EACH ROW
EXECUTE FUNCTION fn_sincronizar_numero_cooperados();