CREATE OR REPLACE FUNCTION fn_normalizar_mes_referencia()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.mes_referencia IS NOT NULL THEN
        NEW.mes_referencia := DATE_TRUNC('month', NEW.mes_referencia)::DATE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;