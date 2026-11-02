CREATE OR REPLACE FUNCTION fn_calcular_media_avaliacoes (
    p_perfil_id UUID
)
RETURNS NUMERIC AS $$
    DECLARE
        v_media NUMERIC;
    BEGIN
        SELECT ROUND(AVG(nota), 2) INTO v_media
        FROM avaliacoes
        WHERE avaliado_id = p_perfil_id;

        RETURN COALESCE(v_media, 0);
    END;
$$ LANGUAGE plpgsql;