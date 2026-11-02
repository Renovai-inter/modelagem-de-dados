CREATE OR REPLACE VIEW vw_dim_empresa AS
    SELECT
        em.empresa_id,
        em.nome AS nome_empresa,
        em.descricao,
        p.cnpj,
        p.email,
        en.cep,
        en.cidade,
        p.data_criacao AS data_cadastro,
        fn_calcular_media_avaliacoes(p.perfil_id) AS score
    FROM empresas em
    LEFT JOIN perfis p
        ON em.empresa_id = p.empresa_id
    LEFT JOIN enderecos en
        ON en.endereco_id = p.endereco_id;