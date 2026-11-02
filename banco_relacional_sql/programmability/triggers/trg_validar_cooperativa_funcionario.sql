CREATE OR REPLACE TRIGGER trg_validar_cooperativa_funcionario
BEFORE INSERT OR UPDATE ON equipes_cooperados
FOR EACH ROW
EXECUTE FUNCTION fn_validar_cooperativa_funcionario();