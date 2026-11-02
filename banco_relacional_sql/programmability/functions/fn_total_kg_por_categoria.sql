CREATE OR REPLACE FUNCTION fn_total_kg_por_categoria(
    p_categoria_id UUID,
    p_data_inicio TIMESTAMP DEFAULT NULL,
    p_data_fim TIMESTAMP DEFAULT NULL
)
RETURNS NUMERIC AS $$
DECLARE
    v_total_kg NUMERIC;
BEGIN
    WITH RECURSIVE arvore_categorias AS (
        SELECT categoria_id
        FROM categorias_materiais
        WHERE categoria_id = p_categoria_id

        UNION ALL

        SELECT c.categoria_id
        FROM categorias_materiais c
        JOIN arvore_categorias a ON c.categoria_pai_id = a.categoria_id
    )
    SELECT COALESCE(SUM(t.quantidade_kg), 0)
    INTO v_total_kg
    FROM arvore_categorias ac
    JOIN materiais m ON m.categoria_id = ac.categoria_id
    JOIN triagens t ON t.material_id = m.material_id
    WHERE (p_data_inicio IS NULL OR t.data_evento >= p_data_inicio)
        AND (p_data_fim IS NULL OR t.data_evento <= p_data_fim);

    RETURN v_total_kg;
END;
$$ LANGUAGE plpgsql;