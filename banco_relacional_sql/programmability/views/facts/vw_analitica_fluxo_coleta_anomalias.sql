-- =============================================================================
-- RENOVAÍ — DATA WAREHOUSE & ANALYTICS
-- VIEW: FLUXO OPERACIONAL DE COLETAS E DETECÇÃO DE ANOMALIAS TEMPORAIS
-- =============================================================================
-- Utiliza Window Functions avançadas para:
-- 1. Deslocamento temporal para trás (LAG) e para frente (LEAD).
-- 2. Cálculo do intervalo de ciclo / ociosidade entre coletas sucessivas.
-- 3. Detecção de anomalias de variação de volume coletado.
-- 4. Running Total (total acumulado no mês corrente via ROWS BETWEEN).
-- =============================================================================

CREATE OR REPLACE VIEW vw_analitica_fluxo_coleta_anomalias AS
SELECT
    c.evento_id AS coleta_id,
    TO_CHAR(c.data_evento, 'yyyymmdd')::INT AS data_id,
    c.data_evento,
    c.cooperado_id,
    u.nome AS nome_cooperado,
    f.cooperativa_id,
    c.tipo_coleta,
    c.quantidade_kg,

    -- 1. Olhar para o Passado: Quantidade da coleta anterior do mesmo cooperado
    LAG(c.quantidade_kg) OVER (
        PARTITION BY c.cooperado_id 
        ORDER BY c.data_evento ASC
    ) AS quantidade_coleta_anterior_kg,

    -- 2. Detecção de Anomalia: Variação absoluta vs evento anterior
    ROUND(
        c.quantidade_kg - LAG(c.quantidade_kg) OVER (
            PARTITION BY c.cooperado_id 
            ORDER BY c.data_evento ASC
        ), 3
    ) AS variacao_vs_anterior_kg,

    -- 3. Olhar para o Futuro: Data da próxima coleta do mesmo cooperado
    LEAD(c.data_evento) OVER (
        PARTITION BY c.cooperado_id 
        ORDER BY c.data_evento ASC
    ) AS proxima_coleta_data,

    -- 4. Intervalo de tempo entre coletas consecutivas (em horas)
    ROUND(
        EXTRACT(EPOCH FROM (
            LEAD(c.data_evento) OVER (PARTITION BY c.cooperado_id ORDER BY c.data_evento ASC) - c.data_evento
        )) / 3600.0, 2
    ) AS intervalo_proxima_coleta_horas,

    -- 5. Motor de Acumulados: Produção acumulada do cooperado no mês corrente (Running Total)
    SUM(c.quantidade_kg) OVER (
        PARTITION BY c.cooperado_id, DATE_TRUNC('month', c.data_evento)
        ORDER BY c.data_evento ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado_mes_cooperado_kg

FROM coletas c
JOIN funcionarios f ON f.funcionario_id = c.cooperado_id
JOIN usuarios u ON u.usuario_id = f.usuario_id;
