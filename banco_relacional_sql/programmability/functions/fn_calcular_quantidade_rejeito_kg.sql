CREATE OR REPLACE FUNCTION fn_calcular_quantidade_rejeito_kg (
    p_triagem_quantidade_kg NUMERIC,
    p_coleta_id UUID
)
RETURNS NUMERIC AS $$
    DECLARE
        v_total_coletado NUMERIC := 0;
        v_total_ja_triado NUMERIC := 0;
        v_restante NUMERIC := 0;
        v_rejeito_kg NUMERIC := 0;
    BEGIN
        SELECT COALESCE(quantidade_kg, 0) INTO v_total_coletado
        FROM coletas WHERE evento_id = p_coleta_id;

        SELECT COALESCE(SUM(quantidade_kg), 0) INTO v_total_ja_triado
        FROM triagens WHERE coleta_id = p_coleta_id;

        v_restante := GREATEST(v_total_coletado - v_total_ja_triado, 0);
        v_rejeito_kg := GREATEST(v_restante - p_triagem_quantidade_kg, 0);

        RETURN ROUND(v_rejeito_kg, 2);
    END;
$$ LANGUAGE plpgsql;