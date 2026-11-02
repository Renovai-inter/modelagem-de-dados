-- =============================================================================
-- RENOVAÍ — DATA WAREHOUSE & ANALYTICS
-- VIEW: CURVA ABC DE FATURAMENTO POR MATERIAL RECICLÁVEL
-- =============================================================================
-- Utiliza Window Functions avançadas para:
-- 1. Faturamento cumulativo progressivo (Running Sum).
-- 2. Percentual acumulado da receita total (Princípio de Pareto / Curva ABC 80-15-5).
-- 3. Segmentação em 3 baldes (NTILE(3)).
-- =============================================================================

CREATE OR REPLACE VIEW vw_analitica_curva_abc_materiais AS
WITH receita_materiais AS (
    SELECT
        v.cooperativa_id,
        v.material_id,
        m.nome_categoria AS nome_material,
        SUM(v.quantidade_kg) AS volume_total_kg,
        SUM(v.valor_total)   AS faturamento_total
    FROM vw_fato_vendas v
    JOIN vw_dim_material m ON m.material_id = v.material_id
    GROUP BY v.cooperativa_id, v.material_id, m.nome_categoria
),
analise_cumulativa AS (
    SELECT
        cooperativa_id,
        material_id,
        nome_material,
        volume_total_kg,
        faturamento_total,
        
        -- Participação percentual no faturamento global da cooperativa
        ROUND(
            faturamento_total / NULLIF(SUM(faturamento_total) OVER (PARTITION BY cooperativa_id), 0) * 100, 2
        ) AS share_receita_pct,

        -- Percentual acumulado da receita (Curva de Pareto)
        ROUND(
            SUM(faturamento_total) OVER (
                PARTITION BY cooperativa_id 
                ORDER BY faturamento_total DESC 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) / NULLIF(SUM(faturamento_total) OVER (PARTITION BY cooperativa_id), 0) * 100, 2
        ) AS share_acumulado_pct,

        -- Fatiamento NTILE em 3 tercis simétricos de faturamento
        NTILE(3) OVER (
            PARTITION BY cooperativa_id 
            ORDER BY faturamento_total DESC
        ) AS balde_ntile
    FROM receita_materiais
)
SELECT
    cooperativa_id,
    material_id,
    nome_material,
    volume_total_kg,
    faturamento_total,
    share_receita_pct,
    share_acumulado_pct,
    balde_ntile,
    CASE
        WHEN share_acumulado_pct <= 80.0 THEN 'Classe A (Alto Impacto / 80%)'
        WHEN share_acumulado_pct <= 95.0 THEN 'Classe B (Médio Impacto / 15%)'
        ELSE 'Classe C (Baixo Impacto / 5%)'
    END AS classificacao_abc
FROM analise_cumulativa;
