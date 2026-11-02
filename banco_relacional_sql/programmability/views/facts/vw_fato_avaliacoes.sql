CREATE OR REPLACE VIEW vw_fato_avaliacoes AS
    SELECT
        a.avaliacao_id,
        TO_CHAR(a.data_avaliacao, 'yyyymmdd')::INT AS data_id,
        a.pedido_id,
        a.nota,
        pf_avr.cooperativa_id AS avaliador_cooperativa_id,
        pf_avr.empresa_id     AS avaliador_empresa_id,
        pf_avd.cooperativa_id AS avaliado_cooperativa_id,
        pf_avd.empresa_id     AS avaliado_empresa_id
    FROM avaliacoes a
    JOIN perfis pf_avr ON pf_avr.perfil_id = a.avaliador_id
    JOIN perfis pf_avd ON pf_avd.perfil_id = a.avaliado_id;