CREATE OR REPLACE FUNCTION fn_auditoria_universal()
RETURNS TRIGGER AS $$
DECLARE
    v_tabela_auditoria TEXT := 'auditoria_' || TG_TABLE_NAME;
    v_query            TEXT;
    v_dados_antigos    JSONB := NULL;
    v_dados_novos      JSONB := NULL;
    v_atualizados      TEXT[] := ARRAY[]::TEXT[];
    
    v_nome_pk          TEXT;
    v_registro_id      UUID;
BEGIN
    SELECT a.attname INTO v_nome_pk
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
    WHERE i.indrelid = TG_RELID AND i.indisprimary;

    IF (TG_OP = 'INSERT') THEN
        v_dados_novos := to_jsonb(NEW);
        v_registro_id := (v_dados_novos ->> v_nome_pk)::UUID;
        
    ELSIF (TG_OP = 'DELETE') THEN
        v_dados_antigos := to_jsonb(OLD);
        v_registro_id   := (v_dados_antigos ->> v_nome_pk)::UUID;
        
    ELSIF (TG_OP = 'UPDATE') THEN
        v_dados_antigos := to_jsonb(OLD);
        v_dados_novos   := to_jsonb(NEW);
        v_registro_id   := (v_dados_novos ->> v_nome_pk)::UUID;

        SELECT array_agg(co2.key)
        INTO v_atualizados
        FROM jsonb_each_text(v_dados_antigos) co1
        JOIN jsonb_each_text(v_dados_novos) co2 ON co1.key = co2.key
        WHERE co1.value IS DISTINCT FROM co2.value;
    END IF;

    v_query := 'INSERT INTO ' || quote_ident(v_tabela_auditoria) || ' (
                    registro_id, operacao, dados_antigos, dados_novos, campos_atualizados, usuario_execucao
                ) VALUES ($1, $2, $3, $4, $5, $6)';

    EXECUTE v_query USING v_registro_id, TG_OP, v_dados_antigos, v_dados_novos, v_atualizados, CURRENT_USER;

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;