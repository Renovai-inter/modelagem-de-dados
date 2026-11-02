CREATE OR REPLACE FUNCTION fn_calcular_numero_cooperados (
    p_cooperativa_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_numero_cooperados INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_numero_cooperados
    FROM funcionarios f
    WHERE f.cooperativa_id = p_cooperativa_id
        AND f.esta_ativo = TRUE;

    RETURN v_numero_cooperados;
END;
$$ LANGUAGE plpgsql;