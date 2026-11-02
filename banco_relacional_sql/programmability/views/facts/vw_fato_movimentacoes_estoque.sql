CREATE VIEW vw_fato_movimentacoes_estoque AS
    SELECT
        me.movimentacao_id,
        TO_CHAR(me.data_movimentacao,'yyyymmdd')::INT AS data_id,
        e.cooperativa_id,
        e.material_id,
        me.tipo_movimentacao,
        me.quantidade_kg,
        SUM(me.quantidade_kg) OVER (
            PARTITION BY e.cooperativa_id, e.material_id
            ORDER BY me.data_movimentacao
        ) AS saldo_acumulado_kg
    FROM movimentacoes_estoques me
    INNER JOIN estoques e ON e.estoque_id = me.estoque_id;