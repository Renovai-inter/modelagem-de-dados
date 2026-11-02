CREATE OR REPLACE TRIGGER trg_sincronizar_saldo_estoque
AFTER INSERT ON movimentacoes_estoques
FOR EACH ROW
EXECUTE FUNCTION fn_sincronizar_saldo_estoque();