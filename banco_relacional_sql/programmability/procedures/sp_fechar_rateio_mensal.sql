CREATE OR REPLACE PROCEDURE sp_fechar_rateio_mensal (
    p_cooperativa_id UUID,
    p_gestor_id UUID,
    p_mes_referencia TIMESTAMP
)
AS $$
    DECLARE
        v_tipo_rateio_id UUID;
        v_valor_individual NUMERIC;
        v_rateio_id UUID;
        v_funcionario_id UUID;
    BEGIN
        SELECT tipo_rateio_id INTO v_tipo_rateio_id
        FROM tipos_rateios
        WHERE tipo_rateio = 'AUTOMATICO';

        SELECT fn_calcular_rateio_automatico (
            p_cooperativa_id,
            p_mes_referencia
        )
        INTO v_valor_individual;

        INSERT INTO rateios (
            cooperativa_id,
            gestor_id,
            tipo_rateio_id,
            mes_referencia
        )
        VALUES (
            p_cooperativa_id,
            p_gestor_id,
            v_tipo_rateio_id,
            p_mes_referencia
        )
        RETURNING rateio_id into v_rateio_id;

        FOR v_funcionario_id IN
            SELECT funcionario_id
            FROM funcionarios
            WHERE cooperativa_id = p_cooperativa_id
                AND esta_ativo = TRUE
        LOOP
            IF v_valor_individual > 0 THEN
                INSERT INTO rateios_funcionarios (
                    rateio_id,
                    cooperado_id,
                    valor_rateio
                )
                VALUES (
                    v_rateio_id,
                    v_funcionario_id,
                    v_valor_individual
                );
            END IF;
        END LOOP;

        COMMIT;
    END;
$$ LANGUAGE plpgsql;