CREATE OR REPLACE VIEW vw_dim_subcategoria AS
    SELECT
        categoria_id AS subcategoria_id,
        nome_categoria AS subcategoria_nome,
        categoria_pai_id AS categoria_macro_id
    FROM categorias_materiais
    WHERE categoria_pai_id IS NOT NULL;