CREATE OR REPLACE FUNCTION fn_calcular_total_liquido(
    p_cooperativa_id UUID,
    p_data_inicio TIMESTAMP,
    p_data_fim TIMESTAMP
)
RETURNS NUMERIC AS $$
DECLARE
    v_bruto NUMERIC;
    v_despesas NUMERIC;
BEGIN
    SELECT fn_calcular_total_acumulado(p_cooperativa_id, p_data_inicio, p_data_fim)
    INTO v_bruto;

    SELECT COALESCE(SUM(ld.valor), 0) INTO v_despesas
    FROM lancamentos_despesas ld
    JOIN despesas d ON d.despesa_id = ld.despesa_id
    WHERE d.cooperativa_id = p_cooperativa_id
        AND ld.mes_referencia BETWEEN p_data_inicio AND p_data_fim;

    RETURN GREATEST(v_bruto - v_despesas, 0);  -- nunca fica negativo
END;
$$ LANGUAGE plpgsql;