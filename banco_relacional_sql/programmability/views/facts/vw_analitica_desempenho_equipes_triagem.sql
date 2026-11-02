-- =============================================================================
-- RENOVAÍ — DATA WAREHOUSE & ANALYTICS
-- VIEW: DESEMPENHO E EFICIÊNCIA DE EQUIPES OPERACIONAIS DE TRIAGEM
-- =============================================================================
-- Utiliza Window Functions avançadas para:
-- 1. Pódio e ranqueamento sem empates punitivos (DENSE_RANK).
-- 2. Comparativo contra a média estática da cooperativa sem achatar linhas (AVG OVER PARTITION).
-- 3. Identificação de desvios percentuais e benchmarks de qualidade de rejeito.
-- =============================================================================

CREATE OR REPLACE VIEW vw_analitica_desempenho_equipes_triagem AS
WITH agregacao_equipes AS (
    SELECT
        e.equipe_id,
        e.nome AS nome_equipe,
        f.cooperativa_id,
        coop.nome AS nome_cooperativa,
        DATE_TRUNC('month', t.data_evento)::DATE AS mes_referencia,
        TO_CHAR(DATE_TRUNC('month', t.data_evento), 'yyyymm01')::INT AS data_id,
        COUNT(DISTINCT t.evento_id) AS total_lotes_triados,
        SUM(t.quantidade_kg) AS total_liquido_kg,
        SUM(t.quantidade_rejeito_kg) AS total_rejeito_kg,
        ROUND(
            SUM(t.quantidade_rejeito_kg) / NULLIF(SUM(t.quantidade_kg + t.quantidade_rejeito_kg), 0) * 100, 2
        ) AS taxa_rejeito_equipe_pct
    FROM triagens t
    JOIN equipes e ON e.equipe_id = t.equipe_id
    JOIN funcionarios f ON f.funcionario_id = e.gestor_id
    JOIN cooperativas coop ON coop.cooperativa_id = f.cooperativa_id
    GROUP BY
        e.equipe_id,
        e.nome,
        f.cooperativa_id,
        coop.nome,
        DATE_TRUNC('month', t.data_evento)
)
SELECT
    data_id,
    mes_referencia,
    cooperativa_id,
    nome_cooperativa,
    equipe_id,
    nome_equipe,
    total_lotes_triados,
    total_liquido_kg,
    total_rejeito_kg,
    taxa_rejeito_equipe_pct,

    -- 1. Ranking de Produtividade dentro da cooperativa no mês (DENSE_RANK)
    DENSE_RANK() OVER (
        PARTITION BY cooperativa_id, mes_referencia 
        ORDER BY total_liquido_kg DESC
    ) AS ranking_produtividade,

    -- 2. Média global da cooperativa no mesmo período (Sem achatar linhas originais)
    ROUND(
        AVG(total_liquido_kg) OVER (PARTITION BY cooperativa_id, mes_referencia), 2
    ) AS media_cooperativa_kg,

    -- 3. Desvio relativo percentual em relação à média da cooperativa
    ROUND(
        (total_liquido_kg - AVG(total_liquido_kg) OVER (PARTITION BY cooperativa_id, mes_referencia))
        / NULLIF(AVG(total_liquido_kg) OVER (PARTITION BY cooperativa_id, mes_referencia), 0) * 100, 2
    ) AS desvio_vs_media_coop_pct,

    -- 4. Benchmark de qualidade: diferença na taxa de rejeito contra a média geral da cooperativa
    ROUND(
        taxa_rejeito_equipe_pct - AVG(taxa_rejeito_equipe_pct) OVER (PARTITION BY cooperativa_id, mes_referencia), 2
    ) AS delta_taxa_rejeito_pct

FROM agregacao_equipes;
