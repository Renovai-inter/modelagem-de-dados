CREATE OR REPLACE VIEW vw_dim_equipe AS
    WITH equipes_cooperados_cte AS (
        SELECT equipe_id, COUNT(*) AS numero_cooperados
        FROM equipes_cooperados
        GROUP BY equipe_id
    )
    SELECT
        e.equipe_id,
        e.gestor_id,
        f.cooperativa_id,
        e.nome,
        e.descricao,
        e.data_criacao,
        e.esta_ativa,
        ec.numero_cooperados
    FROM equipes e
    INNER JOIN funcionarios f ON f.funcionario_id = e.gestor_id
    LEFT JOIN equipes_cooperados_cte ec ON e.equipe_id = ec.equipe_id;