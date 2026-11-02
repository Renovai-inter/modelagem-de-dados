CREATE OR REPLACE VIEW vw_fato_metricas_mensais AS
    WITH coletas_cte AS (
        SELECT
            f.cooperativa_id,
            DATE_TRUNC('month', c.data_evento)::date AS mes,
            COUNT(*) AS total_coletas,
            SUM(c.quantidade_kg) AS total_coletado_kg
        FROM coletas c
        JOIN funcionarios f
            ON f.funcionario_id = c.cooperado_id
        GROUP BY f.cooperativa_id, DATE_TRUNC('month', c.data_evento)
    ),

    triagens_cte AS (
        SELECT
            f.cooperativa_id,
            DATE_TRUNC('month', t.data_evento)::date AS mes,
            COUNT(*) AS total_triagens,
            SUM(t.quantidade_kg) AS total_triado_kg,
            SUM(t.quantidade_rejeito_kg) AS total_rejeito_kg
        FROM triagens t
        JOIN equipes e
            ON e.equipe_id = t.equipe_id
        JOIN funcionarios f
            ON f.funcionario_id = e.gestor_id
        GROUP BY f.cooperativa_id, DATE_TRUNC('month', t.data_evento)
    ),

    pedidos_cte AS (
        SELECT
            e.cooperativa_id,
            DATE_TRUNC('month', p.data_pedido)::date AS mes,
            COUNT(DISTINCT p.pedido_id) AS total_pedidos,
            -- ABS: toda saída de estoque por venda é registrada como negativa.
            SUM(ABS(me.quantidade_kg)) AS total_pedido_kg,
            SUM(ROUND(ABS(me.quantidade_kg) * i.preco_unitario, 2)) AS valor_bruto_total
        FROM movimentacoes_estoques me
        JOIN pedido_itens i
            ON i.item_id = me.item_id
        JOIN pedidos p
            ON p.pedido_id = i.pedido_id
        JOIN estoques e
            ON e.estoque_id = me.estoque_id
        WHERE me.item_id IS NOT NULL
        GROUP BY e.cooperativa_id, DATE_TRUNC('month', p.data_pedido)
    ),

    despesas_cte AS (
        SELECT
            d.cooperativa_id,
            DATE_TRUNC('month', ld.mes_referencia)::date AS mes,
            SUM(ld.valor) FILTER (WHERE d.tipo_despesa = 'FIXA') AS despesas_fixas,
            SUM(ld.valor) FILTER (WHERE d.tipo_despesa = 'VARIAVEL') AS despesas_variaveis,
            SUM(ld.valor) AS despesas_total
        FROM lancamentos_despesas ld
        JOIN despesas d
            ON d.despesa_id = ld.despesa_id
        GROUP BY d.cooperativa_id, DATE_TRUNC('month', ld.mes_referencia)
    ),

    rateio_cte AS (
        SELECT
            r.cooperativa_id,
            DATE_TRUNC('month', r.mes_referencia)::date AS mes,
            SUM(rf.valor_rateio) AS rateio_total,
            COUNT(DISTINCT rf.cooperado_id) AS numero_cooperados_rateados
        FROM rateios r
        JOIN rateios_funcionarios rf
            ON rf.rateio_id = r.rateio_id
        GROUP BY r.cooperativa_id, DATE_TRUNC('month', r.mes_referencia)
    )

    SELECT
        COALESCE(
            c.cooperativa_id, t.cooperativa_id,
            p.cooperativa_id, d.cooperativa_id,
            r.cooperativa_id
        ) AS cooperativa_id,
        COALESCE(
            TO_CHAR(c.mes, 'yyyymmdd')::INT, TO_CHAR(t.mes, 'yyyymmdd')::INT,
            TO_CHAR(p.mes, 'yyyymmdd')::INT, TO_CHAR(d.mes, 'yyyymmdd')::INT,
            TO_CHAR(r.mes, 'yyyymmdd')::INT
        ) AS data_id,
        COALESCE(c.total_coletas, 0)      AS total_coletas,
        COALESCE(c.total_coletado_kg, 0)  AS total_coletado_kg,
        COALESCE(t.total_triagens, 0)     AS total_triagens,
        COALESCE(t.total_triado_kg, 0)    AS total_triado_kg,
        COALESCE(t.total_rejeito_kg, 0)   AS total_rejeito_kg,
        COALESCE(p.total_pedidos, 0)      AS total_pedidos,
        COALESCE(p.total_pedido_kg, 0)    AS total_pedido_kg,
        COALESCE(p.valor_bruto_total, 0)  AS valor_bruto_total,
        COALESCE(d.despesas_fixas, 0)     AS total_despesas_fixas,
        COALESCE(d.despesas_variaveis, 0) AS total_despesas_variaveis,
        COALESCE(d.despesas_total, 0)     AS despesas_total,
        COALESCE(p.valor_bruto_total, 0) - COALESCE(d.despesas_total, 0) AS valor_liquido_sem_rateio,
        COALESCE(r.rateio_total, 0)       AS rateio_total,
        COALESCE(p.valor_bruto_total, 0) - COALESCE(d.despesas_total, 0) - COALESCE(r.rateio_total, 0) AS liquidez_final,
        COALESCE(r.numero_cooperados_rateados, 0) AS numero_cooperados_rateados
    FROM coletas_cte c
    FULL OUTER JOIN triagens_cte t
        ON t.cooperativa_id = c.cooperativa_id
        AND t.mes = c.mes
    FULL OUTER JOIN pedidos_cte p
        ON p.cooperativa_id = COALESCE(c.cooperativa_id, t.cooperativa_id)
        AND p.mes = COALESCE(c.mes, t.mes)
    FULL OUTER JOIN despesas_cte d
        ON d.cooperativa_id = COALESCE(c.cooperativa_id, t.cooperativa_id, p.cooperativa_id)
        AND d.mes = COALESCE(c.mes, t.mes, p.mes)
    FULL OUTER JOIN rateio_cte r
        ON r.cooperativa_id = COALESCE(c.cooperativa_id, t.cooperativa_id, p.cooperativa_id, d.cooperativa_id)
        AND r.mes = COALESCE(c.mes, t.mes, p.mes, d.mes);