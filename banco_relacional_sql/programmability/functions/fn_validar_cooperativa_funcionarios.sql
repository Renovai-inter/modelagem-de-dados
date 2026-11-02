CREATE OR REPLACE FUNCTION fn_validar_cooperativa_funcionario()
RETURNS TRIGGER AS $$
DECLARE
    v_cooperativa_funcionario UUID;
    v_cooperativa_equipe UUID;
BEGIN
    SELECT cooperativa_id INTO v_cooperativa_funcionario
    FROM funcionarios WHERE funcionario_id = NEW.cooperado_id;

    SELECT f.cooperativa_id INTO v_cooperativa_equipe
    FROM equipes e
    INNER JOIN funcionarios f ON f.funcionario_id = e.gestor_id
    WHERE e.equipe_id = NEW.equipe_id;

    IF v_cooperativa_funcionario <> v_cooperativa_equipe THEN
        RAISE EXCEPTION 'Cooperado pertence a uma cooperativa diferente da equipe.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;