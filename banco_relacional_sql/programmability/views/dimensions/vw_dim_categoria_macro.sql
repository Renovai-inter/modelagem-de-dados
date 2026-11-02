CREATE OR REPLACE VIEW vw_dim_categoria_macro AS
    SELECT
        categoria_id AS categoria_macro_id,
        nome_categoria AS categoria_macro_nome
    FROM categorias_materiais
    WHERE categoria_pai_id IS NULL;