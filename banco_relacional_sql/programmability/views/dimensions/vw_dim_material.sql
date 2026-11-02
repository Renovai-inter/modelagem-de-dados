CREATE OR REPLACE VIEW vw_dim_material AS
    SELECT
        m.material_id,
        m.categoria_id,
        m.cooperativa_id,
        m.imagem_url,
        cm.nome_categoria,
        m.preco_sugerido,
        m.esta_disponivel,
        CASE NTILE(3) OVER (ORDER BY m.preco_sugerido)
            WHEN 1 THEN 'baixo valor'
            WHEN 2 THEN 'médio valor'
            WHEN 3 THEN 'alto valor'
        END AS faixa_preco
    FROM materiais m
    INNER JOIN categorias_materiais cm ON cm.categoria_id = m.categoria_id