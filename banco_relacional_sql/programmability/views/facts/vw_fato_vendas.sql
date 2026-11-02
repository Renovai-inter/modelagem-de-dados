CREATE OR REPLACE VIEW vw_fato_vendas AS
    SELECT
        p.pedido_id,
        TO_CHAR(p.data_pedido,'yyyymmdd')::INT AS data_id,
        pc.cooperativa_id,
        p.empresa_id,
        i.material_id,
        s.status_id,
        s.status_atual,
        -- se houve negociação fechada com acordo para este material, usa o valor final negociado;
        -- senão, usa a proposta original do pedido (caso de aceite direto, sem negociação)
        COALESCE(ni.quantidade_kg, i.quantidade_kg) AS quantidade_kg,
        COALESCE(ni.preco_unitario, i.preco_unitario) AS preco_unitario,
        COALESCE(ni.quantidade_kg, i.quantidade_kg) * COALESCE(ni.preco_unitario, i.preco_unitario) AS valor_total,
        (n.negociacao_id IS NOT NULL) AS foi_negociado
    FROM pedido_itens i
    INNER JOIN pedidos p ON p.pedido_id = i.pedido_id
    INNER JOIN pedidos_cooperativas pc ON pc.pedido_id = p.pedido_id
    INNER JOIN status s ON s.status_id = pc.status_id
    LEFT JOIN negociacoes n
        ON n.pedido_id = p.pedido_id
        AND n.cooperativa_id = pc.cooperativa_id
        AND n.data_fechamento IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM status sn
            WHERE sn.status_id = n.status_id AND sn.status_atual = 'Acordo fechado'
        )
    LEFT JOIN negociacao_itens ni
        ON ni.negociacao_id = n.negociacao_id
        AND ni.material_id = i.material_id;