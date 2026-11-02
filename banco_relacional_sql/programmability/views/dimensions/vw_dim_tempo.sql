CREATE OR REPLACE VIEW vw_dim_tempo AS
    WITH series_data AS (
        SELECT gs::date AS data FROM GENERATE_SERIES (
            DATE '2025-01-01',
            DATE '2026-12-31',
            INTERVAL '1 day'
        ) AS gs
    )

    SELECT
        TO_CHAR(data,'yyyymmdd')::INT AS data_id,
        data AS data_referencia,
        EXTRACT(YEAR FROM data) AS ano,
        EXTRACT(QUARTER FROM data) AS trimestre,
        EXTRACT(MONTH FROM data) AS mes,
        TO_CHAR(data,'FMmonth') AS mes_nome,
        EXTRACT(WEEK FROM data) AS semana,
        EXTRACT(DAY FROM data) AS dia,
        EXTRACT(DOW FROM data) + 1 AS dia_da_semana,
        TO_CHAR(data,'FMDay') AS dia_nome,
        DATE_TRUNC('week', data)::date AS inicio_semana,
        DATE_TRUNC('month', data)::date AS inicio_mes,
        DATE_TRUNC('quarter',data)::DATE AS inicio_trimestre,
        DATE_TRUNC('YEAR',data)::DATE AS inicio_ano,
        (DATE_TRUNC('WEEK',data) +INTERVAL '1 WEEK - 1 day')::DATE AS fim_semana,
        (DATE_TRUNC('MONTH',data) +INTERVAL '1 MONTH - 1 day')::DATE AS fim_mes,
        (DATE_TRUNC('quarter',data) +INTERVAL '3 MONTH - 1 day')::DATE AS fim_trimestre,
        (DATE_TRUNC('YEAR',data)::DATE +INTERVAL '1 YEAR - 1 day')::DATE AS fim_ano,
        CASE
            WHEN (EXTRACT(DOW FROM data) + 1 IN (1,7)) THEN TRUE
            ELSE FALSE
        END AS eh_fim_de_semana
    FROM series_data;