CREATE OR REPLACE VIEW vw_fato_rendimento_coleta_triagem AS
    SELECT
        c.evento_id AS coleta_id,
        c.tipo_coleta,
        c.quantidade_kg AS quantidade_bruta_kg,
        COALESCE(SUM(t.quantidade_kg), 0) AS quantidade_liquida_triada_kg,
        COALESCE(SUM(t.quantidade_rejeito_kg), 0) AS quantidade_rejeito_kg,
        ROUND(
            COALESCE(SUM(t.quantidade_kg), 0) / NULLIF(c.quantidade_kg, 0) * 100, 2
        ) AS taxa_aproveitamento_pct
    FROM coletas c
    LEFT JOIN triagens t
        ON t.coleta_id = c.evento_id
    GROUP BY c.evento_id, c.tipo_coleta, c.quantidade_kg;