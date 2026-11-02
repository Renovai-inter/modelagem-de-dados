CREATE OR REPLACE FUNCTION fn_sincronizar_saldo_estoque()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE estoques
    SET quantidade_kg = quantidade_kg + NEW.quantidade_kg,
        data_atualizacao = NOW()
    WHERE estoque_id = NEW.estoque_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;