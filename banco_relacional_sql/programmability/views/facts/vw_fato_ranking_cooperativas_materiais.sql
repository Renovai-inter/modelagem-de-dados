-- =============================================================================
-- RENOVAÍ — DATA WAREHOUSE & ANALYTICS
-- VIEW: FATO RANKING DE COOPERATIVAS E MATERIAIS
-- =============================================================================
-- Utiliza Window Functions avançadas (DENSE_RANK, LAG, SUM OVER) para:
-- 1. Classificar o desempenho produtivo das cooperativas por mês e categoria de material.
-- 2. Calcular o market share (%) de cada cooperativa na triagem de cada resíduo.
-- 3. Comparar a evolução mensal (mês corrente vs mês anterior via LAG) de volume triado.
-- =============================================================================

CREATE OR REPLACE VIEW vw_fato_ranking_cooperativas_materiais AS
WITH triagens_mensais AS (
    SELECT
        DATE_TRUNC('month', t.data_evento)::DATE AS mes_referencia,
        m.cooperativa_id,
        coop.nome AS nome_cooperativa,
        t.material_id,
        cat.nome_categoria AS categoria_material,
        SUM(t.quantidade_kg) AS total_triado_kg,
        SUM(t.quantidade_rejeito_kg) AS total_rejeito_kg,
        COUNT(DISTINCT t.evento_id) AS total_operacoes_triagem
    FROM triagens t
    JOIN materiais m ON m.material_id = t.material_id
    JOIN cooperativas coop ON coop.cooperativa_id = m.cooperativa_id
    JOIN categorias_materiais cat ON cat.categoria_id = m.categoria_id
    GROUP BY
        DATE_TRUNC('month', t.data_evento)::DATE,
        m.cooperativa_id,
        coop.nome,
        t.material_id,
        cat.nome_categoria
)
SELECT
    tm.mes_referencia,
    tm.cooperativa_id,
    tm.nome_cooperativa,
    tm.material_id,
    tm.categoria_material,
    tm.total_triado_kg,
    tm.total_rejeito_kg,
    tm.total_operacoes_triagem,

    -- 1. Ranking de cooperativas por volume do material no mês
    DENSE_RANK() OVER (
        PARTITION BY tm.mes_referencia, tm.material_id 
        ORDER BY tm.total_triado_kg DESC
    ) AS ranking_material_mes,

    -- 2. Ranking geral da cooperativa no mês (somatório de todos os materiais)
    DENSE_RANK() OVER (
        PARTITION BY tm.mes_referencia 
        ORDER BY tm.total_triado_kg DESC
    ) AS ranking_volume_mes,

    -- 3. Participação relativa (%) da cooperativa no total triado daquele material no mês
    ROUND(
        tm.total_triado_kg / NULLIF(
            SUM(tm.total_triado_kg) OVER (PARTITION BY tm.mes_referencia, tm.material_id), 0
        ) * 100, 2
    ) AS share_material_mes_pct,

    -- 4. Análise temporal: volume triado no mês anterior para cálculo de crescimento (MoM)
    LAG(tm.total_triado_kg, 1) OVER (
        PARTITION BY tm.cooperativa_id, tm.material_id 
        ORDER BY tm.mes_referencia ASC
    ) AS volume_mes_anterior_kg,

    -- 5. Variação percentual mês a mês
    ROUND(
        (tm.total_triado_kg - LAG(tm.total_triado_kg, 1) OVER (
            PARTITION BY tm.cooperativa_id, tm.material_id 
            ORDER BY tm.mes_referencia ASC
        )) / NULLIF(LAG(tm.total_triado_kg, 1) OVER (
            PARTITION BY tm.cooperativa_id, tm.material_id 
            ORDER BY tm.mes_referencia ASC
        ), 0) * 100, 2
    ) AS variacao_mom_pct

FROM triagens_mensais tm;
