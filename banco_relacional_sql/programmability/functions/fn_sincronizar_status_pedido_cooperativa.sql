CREATE OR REPLACE FUNCTION fn_sincronizar_status_pedido_cooperativa()
RETURNS TRIGGER AS $$
DECLARE
    v_status_negociacao VARCHAR(50);
    v_status_destino_id UUID;
BEGIN
    SELECT status_atual INTO v_status_negociacao
    FROM status
    WHERE status_id = NEW.status_id;

    SELECT status_id INTO v_status_destino_id
    FROM status
    WHERE referencia = 'PEDIDO'
      AND status_atual = CASE v_status_negociacao
            WHEN 'Em andamento'        THEN 'Em negociação'
            WHEN 'Acordo fechado'      THEN 'Aceito'
            WHEN 'Negociação recusada' THEN 'Recusado'
            ELSE NULL
          END;

    IF v_status_destino_id IS NOT NULL THEN
        UPDATE pedidos_cooperativas
        SET status_id = v_status_destino_id
        WHERE pedido_id = NEW.pedido_id
          AND cooperativa_id = NEW.cooperativa_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;