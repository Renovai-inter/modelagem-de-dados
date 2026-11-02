CREATE OR REPLACE TRIGGER trg_sincronizar_status_pedido_cooperativa
AFTER UPDATE OF status_id ON negociacoes
FOR EACH ROW
WHEN (OLD.status_id IS DISTINCT FROM NEW.status_id)
EXECUTE FUNCTION fn_sincronizar_status_pedido_cooperativa();