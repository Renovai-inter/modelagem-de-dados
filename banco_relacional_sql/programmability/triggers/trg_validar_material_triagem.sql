CREATE OR REPLACE TRIGGER trg_validar_material_triagem
BEFORE INSERT OR UPDATE ON triagens
FOR EACH ROW
EXECUTE FUNCTION fn_validar_material_triagem();