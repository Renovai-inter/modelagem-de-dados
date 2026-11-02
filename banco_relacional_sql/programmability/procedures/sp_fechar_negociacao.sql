CREATE OR REPLACE PROCEDURE sp_fechar_negociacao (
    p_negociacao_id UUID,
    p_aceito BOOLEAN
)
AS $$
    DECLARE
        v_cooperativa_id UUID;
        v_status_atual VARCHAR(50);
        v_item RECORD;
        v_estoque_id UUID;
        v_status_final_id UUID;
    BEGIN
        SELECT
            n.cooperativa_id,
            s.status_atual
        INTO
            v_cooperativa_id,
            v_status_atual
        FROM negociacoes n
        INNER JOIN status s ON s.status_id = n.status_id
        WHERE n.negociacao_id = p_negociacao_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'negociacao_id % não encontrada.', p_negociacao_id;
        END IF;

        IF v_status_atual <> 'Em andamento' THEN
            RAISE EXCEPTION 'A negociação % já foi encerrada (status atual: %).',
                p_negociacao_id, v_status_atual;
        END IF;

        IF p_aceito THEN
            -- todo item precisa estar com peso e preço definidos para fechar o acordo
            IF EXISTS (
                SELECT 1 FROM negociacao_itens
                WHERE negociacao_id = p_negociacao_id
                  AND (quantidade_kg IS NULL OR preco_unitario IS NULL)
            ) THEN
                RAISE EXCEPTION 'Não é possível fechar a negociação % com itens sem peso ou preço definidos.',
                    p_negociacao_id;
            END IF;

            FOR v_item IN
                SELECT material_id, quantidade_kg
                FROM negociacao_itens
                WHERE negociacao_id = p_negociacao_id
            LOOP
                IF NOT fn_verificar_disponibilidade_estoque (
                    v_cooperativa_id, v_item.material_id, v_item.quantidade_kg
                ) THEN
                    RAISE EXCEPTION 'Estoque insuficiente para o material_id % (necessário: % kg)',
                        v_item.material_id, v_item.quantidade_kg;
                END IF;
            END LOOP;

            FOR v_item IN
                SELECT material_id, quantidade_kg
                FROM negociacao_itens
                WHERE negociacao_id = p_negociacao_id
            LOOP
                SELECT estoque_id INTO v_estoque_id
                FROM estoques
                WHERE cooperativa_id = v_cooperativa_id
                AND material_id = v_item.material_id;

                -- movimentação de saída referencia a negociação por meio do pedido original;
                -- não há item_id de pedido_itens aqui pois o peso final foi fechado na negociação
                INSERT INTO movimentacoes_estoques (estoque_id, quantidade_kg, item_id)
                SELECT v_estoque_id, -v_item.quantidade_kg, pi.item_id
                FROM negociacoes n
                JOIN pedido_itens pi
                    ON pi.pedido_id = n.pedido_id
                    AND pi.material_id = v_item.material_id
                WHERE n.negociacao_id = p_negociacao_id;
            END LOOP;

            SELECT status_id INTO v_status_final_id
            FROM status WHERE referencia = 'NEGOCIACAO' AND status_atual = 'Acordo fechado';
        ELSE
            SELECT status_id INTO v_status_final_id
            FROM status WHERE referencia = 'NEGOCIACAO' AND status_atual = 'Negociação recusada';
        END IF;

        UPDATE negociacoes
        SET status_id = v_status_final_id,
            data_fechamento = NOW()
        WHERE negociacao_id = p_negociacao_id;

        COMMIT;
    END;
$$ LANGUAGE plpgsql;