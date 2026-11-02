CREATE OR REPLACE FUNCTION fn_validar_material_triagem()
RETURNS TRIGGER AS $$
DECLARE
    v_material_cooperativa_id UUID;
    v_cooperativa_equipe UUID;
BEGIN
    SELECT cooperativa_id INTO v_material_cooperativa_id
    FROM materiais WHERE material_id = NEW.material_id;

    IF v_material_cooperativa_id IS NOT NULL THEN
        SELECT f.cooperativa_id INTO v_cooperativa_equipe
        FROM equipes e
        JOIN funcionarios f ON f.funcionario_id = e.gestor_id
        WHERE e.equipe_id = NEW.equipe_id;

        IF v_material_cooperativa_id <> v_cooperativa_equipe THEN
            RAISE EXCEPTION 'Material % é específico de outra cooperativa.', NEW.material_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;