CREATE OR REPLACE PROCEDURE sp_aceitar_pedido_cooperativa (
    p_pedido_cooperativa_id UUID,
    p_status_aceito_id UUID
)
AS $$
    DECLARE
        v_pedido_id UUID;
        v_cooperativa_id UUID;
        v_status_atual VARCHAR(50);
        v_item RECORD;
        v_estoque_id UUID;
    BEGIN
        SELECT
            pc.pedido_id,
            pc.cooperativa_id,
            s.status_atual
        INTO
            v_pedido_id,
            v_cooperativa_id,
            v_status_atual
        FROM pedidos_cooperativas pc
        JOIN status s ON s.status_id = pc.status_id
        WHERE pc.pedido_cooperativa_id = p_pedido_cooperativa_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'pedido_cooperativa_id % não encontrado.', p_pedido_cooperativa_id;
        END IF;

        IF v_status_atual <> 'Aberto' THEN
            RAISE EXCEPTION 'O pedido_id % já foi aceito ou encerrado (status atual: %).',
                v_pedido_id, v_status_atual;
        END IF;

        IF EXISTS (
            SELECT 1 FROM pedido_itens
            WHERE pedido_id = v_pedido_id AND quantidade_kg IS NULL
        ) THEN
            RAISE EXCEPTION 'O pedido_id % tem item(ns) sem peso definido — não pode ser aceito diretamente, é necessário negociar.',
                v_pedido_id;
        END IF;

        FOR v_item IN
            SELECT material_id, quantidade_kg
            FROM pedido_itens
            WHERE pedido_id = v_pedido_id
        LOOP
            IF NOT fn_verificar_disponibilidade_estoque (
                v_cooperativa_id, v_item.material_id, v_item.quantidade_kg
            ) THEN
                RAISE EXCEPTION 'Estoque insuficiente para o material_id % (necessário: % kg)',
                    v_item.material_id, v_item.quantidade_kg;
            END IF;
        END LOOP;

        FOR v_item IN
            SELECT item_id, material_id, quantidade_kg
            FROM pedido_itens
            WHERE pedido_id = v_pedido_id
        LOOP
            SELECT estoque_id INTO v_estoque_id
            FROM estoques
            WHERE cooperativa_id = v_cooperativa_id
            AND material_id = v_item.material_id;

            INSERT INTO movimentacoes_estoques (estoque_id, quantidade_kg, item_id)
            VALUES (v_estoque_id, -v_item.quantidade_kg, v_item.item_id);
        END LOOP;

        UPDATE pedidos_cooperativas
        SET status_id = p_status_aceito_id
        WHERE pedido_cooperativa_id = p_pedido_cooperativa_id;

        COMMIT;
    END;
$$ LANGUAGE plpgsql;