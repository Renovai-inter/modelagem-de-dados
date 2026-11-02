CREATE OR REPLACE FUNCTION fn_validar_material_estoque()
RETURNS TRIGGER AS $$
DECLARE
    v_material_cooperativa_id UUID;
BEGIN
    SELECT cooperativa_id INTO v_material_cooperativa_id
    FROM materiais
    WHERE material_id = NEW.material_id;

    IF v_material_cooperativa_id IS NOT NULL AND v_material_cooperativa_id <> NEW.cooperativa_id THEN
        RAISE EXCEPTION 'Material % é específico de outra cooperativa.', NEW.material_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;