CREATE OR REPLACE FUNCTION fn_sincronizar_numero_cooperados()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE cooperativas
        SET numero_cooperados = fn_calcular_numero_cooperados(OLD.cooperativa_id)
        WHERE cooperativa_id = OLD.cooperativa_id;
        RETURN OLD;
    END IF;

    -- INSERT ou UPDATE: recalcula a cooperativa atual do funcionário
    UPDATE cooperativas
    SET numero_cooperados = fn_calcular_numero_cooperados(NEW.cooperativa_id)
    WHERE cooperativa_id = NEW.cooperativa_id;

    -- Se o funcionário TROCOU de cooperativa, a antiga também precisa recalcular
    IF TG_OP = 'UPDATE' AND NEW.cooperativa_id IS DISTINCT FROM OLD.cooperativa_id THEN
        UPDATE cooperativas
        SET numero_cooperados = fn_calcular_numero_cooperados(OLD.cooperativa_id)
        WHERE cooperativa_id = OLD.cooperativa_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;