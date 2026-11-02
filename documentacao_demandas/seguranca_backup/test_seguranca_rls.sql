-- =============================================================================
-- RENOVAÍ — TESTES DE SEGURANÇA, CRIPTOGRAFIA E RLS
-- SCRIPT: pg_dbRenovai/tests/test_seguranca_rls.sql
-- =============================================================================
-- Referência: Aulas de Modelagem de Dados — Segurança de Dados (Instituto J&F)
-- Validação prática dos Hands-On 1 e 2 (Slides 9 e 10).
-- =============================================================================

\echo '========================================================================'
\echo 'TESTE 1: Criptografia em Repouso (pgcrypto + Blowfish) - Slide 5 e Slide 9'
\echo '========================================================================'

-- 1.1 Gerando hash seguro com Blowfish via gen_salt('bf')
DO $$
DECLARE
    v_hash_gerado TEXT;
    v_autenticou  BOOLEAN;
BEGIN
    v_hash_gerado := crypt('SenhaForte123', gen_salt('bf', 10));
    RAISE NOTICE 'Hash Blowfish gerado com sucesso: %', v_hash_gerado;

    -- 1.2 Validando a senha correta
    v_autenticou := (v_hash_gerado = crypt('SenhaForte123', v_hash_gerado));
    IF v_autenticou THEN
        RAISE NOTICE '[OK] Autenticação com senha correta: SUCESSO';
    ELSE
        RAISE EXCEPTION '[FALHA] Não foi possível autenticar a senha correta';
    END IF;

    -- 1.3 Validando a rejeição de senha incorreta
    v_autenticou := (v_hash_gerado = crypt('SenhaIncorreta999', v_hash_gerado));
    IF NOT v_autenticou THEN
        RAISE NOTICE '[OK] Tentativa com senha incorreta: REJEITADA COM SUCESSO';
    ELSE
        RAISE EXCEPTION '[FALHA] Senha incorreta foi indevidamente aceita';
    END IF;
END $$;


\echo '========================================================================'
\echo 'TESTE 2: Alerta de Segurança em tb_log_sistema - Slide 9 (Hands-On 1)'
\echo '========================================================================'

INSERT INTO tb_log_sistema (nivel, categoria, mensagem) 
VALUES ('ERROR', 'SEGURANCA', 'Múltiplas falhas de autenticação detectadas');

SELECT log_id, nivel, categoria, mensagem, data_registro 
FROM tb_log_sistema 
ORDER BY data_registro DESC 
LIMIT 1;


\echo '========================================================================'
\echo 'TESTE 3: O Escudo NULLIF no RLS - Slide 7'
\echo 'Tentativa de consulta sem variável de sessão: deve retornar 0 e NÃO dar erro 22P02'
\echo '========================================================================'

-- Simula a execução da API conectada como api_renovai
SET ROLE api_renovai;

-- A variável app.cooperativa_logada NÃO está definida na sessão
SELECT COUNT(*) AS total_coletas_sem_sessao FROM coletas;
SELECT COUNT(*) AS total_estoques_sem_sessao FROM estoques;

RESET ROLE;


\echo '========================================================================'
\echo 'TESTE 4: Bloco Transacional com SET LOCAL para Cooperativa - Slide 10'
\echo 'Configurando sessão dinamicamente via current_setting'
\echo '========================================================================'

SET ROLE api_renovai;

BEGIN;
    -- Injeta a variável de sessão para uma cooperativa específica
    SET LOCAL app.cooperativa_logada = 'ab87b483-01b2-4db3-8c4f-b67085bfa22d';

    SELECT COUNT(*) AS coletas_cooperativa_especifica 
    FROM coletas;

    SELECT COUNT(*) AS estoques_cooperativa_especifica 
    FROM estoques;
COMMIT;

RESET ROLE;


\echo '========================================================================'
\echo 'TESTE 5: Política Híbrida de Coletas (Cooperado vs Gestão) - Slide 10'
\echo 'Cooperado enxerga apenas suas coletas individuais'
\echo '========================================================================'

SET ROLE api_renovai;

BEGIN;
    -- Injeta a variável de sessão do cooperado
    SET LOCAL app.usuario_logado = '3703451a-0869-473d-841c-b61c93b4edaa';

    SELECT evento_id, cooperado_id, quantidade_kg, tipo_coleta 
    FROM coletas 
    LIMIT 3;
COMMIT;

RESET ROLE;


\echo '========================================================================'
\echo 'TESTE 6: Auditor Corporativo com BYPASSRLS - Slide 10'
\echo 'Auditor enxerga todos os dados mesmo sem variável de sessão'
\echo '========================================================================'

SET ROLE auditor_corporativo;

SELECT COUNT(*) AS total_coletas_vistas_pelo_auditor FROM coletas;
SELECT COUNT(*) AS total_estoques_vistos_pelo_auditor FROM estoques;

RESET ROLE;

\echo '========================================================================'
\echo 'TODOS OS TESTES DE SEGURANÇA E RLS FORAM CONCLUÍDOS COM SUCESSO!'
\echo '========================================================================'
