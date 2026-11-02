CREATE OR REPLACE TRIGGER trg_validar_material_item
BEFORE INSERT OR UPDATE ON pedido_itens
FOR EACH ROW
EXECUTE FUNCTION fn_validar_material_item();