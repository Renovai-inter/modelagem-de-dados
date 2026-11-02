CREATE OR REPLACE PROCEDURE sp_registrar_movimentacao_triagem (
    p_equipe_id UUID,
    p_coleta_id UUID,
    p_material_id UUID,
    p_status_id UUID,
    p_quantidade_kg NUMERIC,
    p_quantidade_rejeito_kg NUMERIC DEFAULT NULL,
    p_data_triagem TIMESTAMP DEFAULT NOW()
)
AS $$
    DECLARE
        v_quantidade_rejeito_kg NUMERIC;
        v_cooperativa_id UUID;
        v_estoque_id UUID;
        v_triagem_id UUID;
    BEGIN
        SELECT
            COALESCE(p_quantidade_rejeito_kg, fn_calcular_quantidade_rejeito_kg(p_quantidade_kg, p_coleta_id))
        INTO v_quantidade_rejeito_kg;

        SELECT f.cooperativa_id INTO v_cooperativa_id
        FROM equipes e
        INNER JOIN funcionarios f ON f.funcionario_id = e.gestor_id
        WHERE e.equipe_id = p_equipe_id;

        -- verificar pré-existência da combinação cooperativa_id + material_id (UNIQUE)
        INSERT INTO estoques (cooperativa_id, material_id, quantidade_kg)
        VALUES (v_cooperativa_id, p_material_id, 0)
        ON CONFLICT (cooperativa_id, material_id) DO NOTHING;

        SELECT estoque_id INTO v_estoque_id
        FROM estoques
        WHERE cooperativa_id = v_cooperativa_id
        AND material_id = p_material_id;


        INSERT INTO triagens (
            equipe_id,
            coleta_id,
            material_id,
            status_id,
            quantidade_kg,
            quantidade_rejeito_kg,
            data_evento
        )
        VALUES (
            p_equipe_id,
            p_coleta_id,
            p_material_id,
            p_status_id,
            p_quantidade_kg,
            v_quantidade_rejeito_kg,
            p_data_triagem
        )
        RETURNING evento_id INTO v_triagem_id;

        INSERT INTO movimentacoes_estoques (
            estoque_id,
            triagem_id,
            quantidade_kg
        )
        VALUES (
            v_estoque_id,
            v_triagem_id,
            p_quantidade_kg
        );

        COMMIT;
    END;
$$ LANGUAGE plpgsql;