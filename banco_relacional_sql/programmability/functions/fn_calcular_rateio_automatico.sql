CREATE OR REPLACE FUNCTION fn_calcular_rateio_automatico (
    p_cooperativa_id UUID,
    p_mes_referencia TIMESTAMP
)
RETURNS NUMERIC AS $$
    DECLARE
        v_data_inicio TIMESTAMP;
        v_data_fim TIMESTAMP;
        v_valor_total NUMERIC;
        v_valor_individual NUMERIC := NULL;
    BEGIN
        SELECT
            DATE_TRUNC('month', p_mes_referencia),
            DATE_TRUNC('month', p_mes_referencia) + INTERVAL '1 month - 1 day'
        INTO
            v_data_inicio,
            v_data_fim;

        SELECT fn_calcular_total_liquido (
            p_cooperativa_id,
            v_data_inicio,
            v_data_fim
        ) INTO v_valor_total;

        SELECT ROUND((v_valor_total / numero_cooperados), 2) INTO v_valor_individual
        FROM cooperativas c
        WHERE c.cooperativa_id = p_cooperativa_id
            AND numero_cooperados > 0;

        RETURN COALESCE(v_valor_individual, 0);
    END;
$$ LANGUAGE plpgsql;