CREATE OR REPLACE VIEW vw_fato_triagens AS
    SELECT
        t.evento_id AS triagem_id,
        TO_CHAR(t.data_evento, 'yyyymmdd')::INT AS data_id,
        t.equipe_id,
        t.material_id,
        t.status_id,
        s.status_atual,
        t.coleta_id,
        t.quantidade_kg,
        t.quantidade_rejeito_kg,
        ROUND(
            t.quantidade_rejeito_kg / NULLIF(t.quantidade_kg + t.quantidade_rejeito_kg, 0) * 100, 2
        ) AS taxa_rejeito_pct,
        ROUND(t.quantidade_kg * m.preco_sugerido, 2) AS valor_estimado
    FROM triagens t
    LEFT JOIN status s ON s.status_id = t.status_id
    LEFT JOIN materiais m ON m.material_id = t.material_id
    LEFT JOIN coletas c ON c.evento_id = t.coleta_id;