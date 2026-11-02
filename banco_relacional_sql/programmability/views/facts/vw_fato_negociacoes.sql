CREATE OR REPLACE VIEW vw_fato_negociacoes AS
    SELECT
        n.negociacao_id,
        TO_CHAR(n.data_inicio, 'yyyymmdd')::INT AS data_id,
        n.pedido_id,
        n.cooperativa_id,
        n.empresa_id,
        ni.material_id,
        n.status_id,
        s.status_atual,
        ni.quantidade_kg,
        ni.preco_unitario,
        ROUND(ni.quantidade_kg * ni.preco_unitario, 2) AS valor_total_negociado,
        pi.preco_unitario AS preco_unitario_original,
        ROUND(ni.preco_unitario - pi.preco_unitario, 2) AS delta_preco_unitario,
        ROUND((ni.preco_unitario - pi.preco_unitario) / NULLIF(pi.preco_unitario, 0) * 100, 2) AS delta_preco_pct,
        n.data_inicio,
        n.data_fechamento,
        ROUND(
            EXTRACT(EPOCH FROM (COALESCE(n.data_fechamento, NOW()) - n.data_inicio)) / 3600, 1
        ) AS tempo_negociacao_horas
    FROM negociacoes n
    INNER JOIN negociacao_itens ni
        ON n.negociacao_id = ni.negociacao_id
    LEFT JOIN pedido_itens pi
        ON pi.pedido_id = n.pedido_id
        AND pi.material_id = ni.material_id
    INNER JOIN status s
        ON s.status_id = n.status_id;