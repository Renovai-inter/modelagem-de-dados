-- =============================================================================
-- RENOVAÍ — DATA WAREHOUSE & ANALYTICS
-- VIEW: SEGMENTAÇÃO DE CLIENTES INDUSTRIAIS B2B (RFV & QUINTIS NTILE)
-- =============================================================================
-- Utiliza Window Functions avançadas para:
-- 1. Pódio das empresas parceiras por faturamento total (DENSE_RANK).
-- 2. Segmentação em 5 faixas homogêneas de valor (NTILE(5) - Quintis).
-- 3. Participação percentual de cada indústria na receita global da plataforma.
-- =============================================================================

CREATE OR REPLACE VIEW vw_analitica_segmentacao_empresas_rfv AS
WITH empresas_compras AS (
    SELECT
        p.empresa_id,
        emp.nome AS nome_empresa,
        COUNT(DISTINCT p.pedido_id) AS total_pedidos_concluidos,
        SUM(v.quantidade_kg) AS volume_total_comprado_kg,
        SUM(v.valor_total)   AS faturamento_total_gerado,
        MAX(p.data_pedido)   AS data_ultimo_pedido
    FROM pedidos p
    JOIN empresas emp ON emp.empresa_id = p.empresa_id
    JOIN vw_fato_vendas v ON v.pedido_id = p.pedido_id
    GROUP BY p.empresa_id, emp.nome
)
SELECT
    empresa_id,
    nome_empresa,
    total_pedidos_concluidos,
    volume_total_comprado_kg,
    faturamento_total_gerado,
    data_ultimo_pedido,
    CURRENT_DATE - data_ultimo_pedido::DATE AS recencia_dias,

    -- 1. Pódio das maiores indústrias compradoras
    DENSE_RANK() OVER (
        ORDER BY faturamento_total_gerado DESC
    ) AS ranking_faturamento,

    -- 2. Segmentação em 5 Baldes de Relevância (Quintis de Pareto via NTILE)
    NTILE(5) OVER (
        ORDER BY faturamento_total_gerado DESC
    ) AS quintil_faturamento,

    -- 3. Classificação Estratégica de Carteira
    CASE NTILE(5) OVER (ORDER BY faturamento_total_gerado DESC)
        WHEN 1 THEN 'Tier 1 - Parceiro Estratégico (Top 20%)'
        WHEN 2 THEN 'Tier 2 - Grande Comprador'
        WHEN 3 THEN 'Tier 3 - Comprador Recorrente'
        WHEN 4 THEN 'Tier 4 - Comprador Ocasional'
        ELSE 'Tier 5 - Baixo Volume'
    END AS faixa_cliente,

    -- 4. Participação relativa no faturamento global da plataforma
    ROUND(
        faturamento_total_gerado / NULLIF(SUM(faturamento_total_gerado) OVER (), 0) * 100, 2
    ) AS share_global_faturamento_pct

FROM empresas_compras;
