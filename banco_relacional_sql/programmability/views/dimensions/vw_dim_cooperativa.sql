CREATE OR REPLACE VIEW vw_dim_cooperativa AS
    SELECT
        c.cooperativa_id,
        c.nome AS nome_cooperativa,
        c.descricao,
        p.cnpj,
        p.email,
        e.cep,
        e.cidade,
        c.numero_cooperados,
        c.data_atualizacao,
        c.contato_preferencial,
        fn_calcular_media_avaliacoes(p.perfil_id) AS score
    FROM cooperativas c
    LEFT JOIN perfis p
        ON c.cooperativa_id = p.cooperativa_id
    LEFT JOIN enderecos e
        ON e.endereco_id = p.endereco_id;