CREATE OR REPLACE TRIGGER trg_validar_material_estoque
BEFORE INSERT OR UPDATE ON estoques
FOR EACH ROW
EXECUTE FUNCTION fn_validar_material_estoque();