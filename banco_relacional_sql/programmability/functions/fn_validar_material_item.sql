CREATE OR REPLACE FUNCTION fn_validar_material_item()
RETURNS TRIGGER AS $$
DECLARE
    v_material_cooperativa_id UUID;
BEGIN
    SELECT cooperativa_id INTO v_material_cooperativa_id
    FROM materiais WHERE material_id = NEW.material_id;

    IF v_material_cooperativa_id IS NOT NULL THEN
        RAISE EXCEPTION 'Material % é específico de uma cooperativa e não pode ser pedido por uma empresa.', NEW.material_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;