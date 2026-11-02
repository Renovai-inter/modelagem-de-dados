CREATE OR REPLACE FUNCTION fn_verificar_disponibilidade_estoque (
    p_cooperativa_id UUID,
    p_material_id UUID,
    p_quantidade_kg NUMERIC
)
RETURNS BOOLEAN AS $$
    DECLARE
        v_saldo_atual NUMERIC;
    BEGIN
        SELECT quantidade_kg INTO v_saldo_atual
        FROM estoques e
        WHERE e.cooperativa_id = p_cooperativa_id
            AND e.material_id = p_material_id;

        IF v_saldo_atual IS NULL
            THEN RETURN FALSE;
        END IF;

        RETURN v_saldo_atual >= p_quantidade_kg;
    END;
$$ LANGUAGE plpgsql;