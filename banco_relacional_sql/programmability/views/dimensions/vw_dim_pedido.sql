CREATE OR REPLACE VIEW vw_dim_pedido AS
    WITH metricas_pedido_itens_cte AS (
        SELECT
            pedido_id,
            COUNT(*) AS numero_pedido_itens,
            SUM(quantidade_kg) AS total_kg
        FROM pedido_itens
        GROUP BY pedido_id
    )

    SELECT
        p.pedido_id,
        pc.cooperativa_id,
        s.status_atual AS status,
        p.observacao,
        p.data_pedido,
        p.data_conclusao,
        EXTRACT(DAY FROM (p.data_conclusao - p.data_pedido)) AS prazo_atendimento_dias,
        CASE
            WHEN p.data_conclusao IS NULL THEN 'em aberto'
            WHEN EXTRACT(DAY FROM (p.data_conclusao - p.data_pedido)) <= 3 THEN 'até 3 dias'
            WHEN EXTRACT(DAY FROM (p.data_conclusao - p.data_pedido)) BETWEEN 4 AND 7 THEN '4-7 dias'
            ELSE 'mais de 7 dias'
        END AS faixa_prazo_atendimento,
        i.numero_pedido_itens,
        CASE
            WHEN i.total_kg <= 50  THEN 'Pequeno (até 50kg)'
            WHEN i.total_kg <= 200 THEN 'Médio (51-200kg)'
            ELSE 'Grande (mais de 200kg)'
        END AS faixa_tamanho_pedido
        FROM pedidos p
        LEFT JOIN pedidos_cooperativas pc
            ON p.pedido_id = pc.pedido_id
        LEFT JOIN status s
            ON s.status_id = pc.status_id
        LEFT JOIN metricas_pedido_itens_cte i
            ON p.pedido_id = i.pedido_id;