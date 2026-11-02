-- =============================================================================
-- RENOVAÍ — DATA WAREHOUSE & ANALYTICS
-- VIEW: IMPACTO SOCIAL E SAÚDE FINANCEIRA DOS COOPERADOS (ESG & RATEIOS)
-- =============================================================================
-- Utiliza Window Functions avançadas para:
-- 1. Análise comparativa mês contra mês anterior (MoM via LAG).
-- 2. Média Móvel Trimestral (3 meses) para amortecer picos e sazonalidades.
-- 3. Métricas de dispersão (menor, maior e média de renda per capita distribuída).
-- =============================================================================

CREATE OR REPLACE VIEW vw_analitica_saude_financeira_rateio_esg AS
WITH rateios_mensais AS (
    SELECT
        r.cooperativa_id,
        coop.nome AS nome_cooperativa,
        DATE_TRUNC('month', r.mes_referencia)::DATE AS mes_referencia,
        TO_CHAR(DATE_TRUNC('month', r.mes_referencia), 'yyyymm01')::INT AS data_id,
        COUNT(DISTINCT rf.cooperado_id) AS total_cooperados_beneficiados,
        SUM(rf.valor_rateio) AS montante_rateado_total,
        ROUND(AVG(rf.valor_rateio), 2) AS valor_medio_per_capita,
        MIN(rf.valor_rateio) AS menor_rateio,
        MAX(rf.valor_rateio) AS maior_rateio
    FROM rateios r
    JOIN rateios_funcionarios rf ON rf.rateio_id = r.rateio_id
    JOIN cooperativas coop ON coop.cooperativa_id = r.cooperativa_id
    GROUP BY r.cooperativa_id, coop.nome, DATE_TRUNC('month', r.mes_referencia)
)
SELECT
    data_id,
    mes_referencia,
    cooperativa_id,
    nome_cooperativa,
    total_cooperados_beneficiados,
    montante_rateado_total,
    valor_medio_per_capita,
    menor_rateio,
    maior_rateio,

    -- 1. Valor per capita do mês anterior via LAG
    LAG(valor_medio_per_capita) OVER (
        PARTITION BY cooperativa_id 
        ORDER BY mes_referencia ASC
    ) AS valor_per_capita_mes_anterior,

    -- 2. Variação percentual MoM (Month-over-Month) do rendimento per capita
    ROUND(
        (valor_medio_per_capita - LAG(valor_medio_per_capita) OVER (
            PARTITION BY cooperativa_id ORDER BY mes_referencia ASC
        )) / NULLIF(LAG(valor_medio_per_capita) OVER (
            PARTITION BY cooperativa_id ORDER BY mes_referencia ASC
        ), 0) * 100, 2
    ) AS crescimento_mom_renda_pct,

    -- 3. Média Móvel de 3 Meses (Trimestre Móvel) via Frame de Janela deslizante
    ROUND(
        AVG(valor_medio_per_capita) OVER (
            PARTITION BY cooperativa_id 
            ORDER BY mes_referencia ASC 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS media_movel_trimestral_per_capita

FROM rateios_mensais;
