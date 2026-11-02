-- =============================================================================
-- RENOVAÍ — DATA WAREHOUSE & ANALYTICS
-- VIEW: GESTÃO DE ESTOQUE, COBERTURA FÍSICA E ANÁLISE DE GIRO
-- =============================================================================
-- Utiliza Window Functions avançadas para:
-- 1. Pódio de materiais por volume em estoque (DENSE_RANK).
-- 2. Percentual de representatividade no estoque físico total da cooperativa (SUM OVER).
-- 3. Segmentação em tercis de criticidade de armazenagem (NTILE(3)).
-- =============================================================================

CREATE OR REPLACE VIEW vw_analitica_estoque_cobertura_giro AS
WITH metricas_saida AS (
    SELECT
        e.cooperativa_id,
        coop.nome AS nome_cooperativa,
        e.material_id,
        mat.nome_categoria AS nome_material,
        e.quantidade_kg AS saldo_atual_kg,
        COALESCE(SUM(ABS(me.quantidade_kg)) FILTER (WHERE me.tipo_movimentacao = 'SAIDA'), 0) AS total_saidas_historico_kg,
        COALESCE(COUNT(me.movimentacao_id) FILTER (WHERE me.tipo_movimentacao = 'SAIDA'), 0) AS total_despachos
    FROM estoques e
    JOIN cooperativas coop ON coop.cooperativa_id = e.cooperativa_id
    JOIN vw_dim_material mat ON mat.material_id = e.material_id
    LEFT JOIN movimentacoes_estoques me ON me.estoque_id = e.estoque_id
    GROUP BY e.cooperativa_id, coop.nome, e.material_id, mat.nome_categoria, e.quantidade_kg
)
SELECT
    cooperativa_id,
    nome_cooperativa,
    material_id,
    nome_material,
    saldo_atual_kg,
    total_saidas_historico_kg,
    total_despachos,

    -- 1. Ranking de volume estocado dentro da cooperativa
    DENSE_RANK() OVER (
        PARTITION BY cooperativa_id 
        ORDER BY saldo_atual_kg DESC
    ) AS ranking_volume_estocado,

    -- 2. Percentual do peso deste material no estoque físico total da cooperativa
    ROUND(
        saldo_atual_kg / NULLIF(SUM(saldo_atual_kg) OVER (PARTITION BY cooperativa_id), 0) * 100, 2
    ) AS share_estoque_cooperativa_pct,

    -- 3. Fatiamento em 3 faixas de criticidade de armazenamento via NTILE
    NTILE(3) OVER (
        PARTITION BY cooperativa_id 
        ORDER BY saldo_atual_kg DESC
    ) AS faixa_criticidade_estoque,

    CASE NTILE(3) OVER (PARTITION BY cooperativa_id ORDER BY saldo_atual_kg DESC)
        WHEN 1 THEN 'Alto Volume / Atenção a Espaço Físico'
        WHEN 2 THEN 'Volume Moderado'
        ELSE 'Baixo Volume / Risco de Desabastecimento'
    END AS status_capacidade_armazenamento

FROM metricas_saida;
