CREATE OR REPLACE FUNCTION fn_calcular_total_acumulado (
    p_cooperativa_id UUID,
    p_data_inicio TIMESTAMP,
    p_data_fim TIMESTAMP
)
RETURNS NUMERIC AS $$
    DECLARE
        v_valor_total NUMERIC;
    BEGIN
        SELECT
            SUM(i.quantidade_kg * i.preco_unitario) INTO v_valor_total
        FROM pedido_itens i
        INNER JOIN pedidos p ON i.pedido_id = p.pedido_id
        INNER JOIN pedidos_cooperativas pc ON i.pedido_id = pc.pedido_id
        WHERE pc.cooperativa_id = p_cooperativa_id
            AND p.data_conclusao BETWEEN p_data_inicio AND p_data_fim;

        RETURN COALESCE(v_valor_total, 0);
    END;
$$ LANGUAGE plpgsql;