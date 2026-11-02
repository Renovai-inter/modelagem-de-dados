-- =============================================================================
-- RENOVAÍ — SEGURANÇA DE DADOS NO PostgreSQL (A FORTALEZA MACRO)
-- SCRIPT: CRIPTOGRAFIA EM REPOUSO (pgcrypto) & ROW-LEVEL SECURITY (RLS)
-- =============================================================================
-- Referência: Aulas de Modelagem de Dados — Segurança de Dados (Instituto J&F)
-- Slides 5, 6, 7 e 10
--
-- TÓPICOS IMPLEMENTADOS:
-- 1. Extensão pgcrypto para criptografia irreversível de senhas via Blowfish (gen_salt('bf')).
-- 2. Solução do Paradoxo da API através de variáveis de sessão (current_setting).
-- 3. O Escudo NULLIF: blindagem contra erro 22P02 caso a variável de sessão chegue vazia.
-- 4. Políticas de Leitura (FOR SELECT USING) e Escrita (FOR INSERT WITH CHECK).
-- 5. Política Híbrida: o cooperado vê apenas as suas coletas, OU o gestor vê todas
--    as coletas da sua cooperativa.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CAMADA 6: CRIPTOGRAFIA EM REPOUSO (pgcrypto + Blowfish)
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Função utilitária para geração de hash seguro com Blowfish
CREATE OR REPLACE FUNCTION fn_gerar_hash_senha(p_senha TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE STRICT
AS $$
    SELECT crypt(p_senha, gen_salt('bf', 10));
$$;

-- Função de validação segura de credenciais do usuário
CREATE OR REPLACE FUNCTION fn_autenticar_usuario(p_email TEXT, p_senha TEXT)
RETURNS TABLE (
    usuario_id UUID,
    nome VARCHAR,
    email VARCHAR,
    autenticado BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT 
        u.usuario_id,
        u.nome,
        u.email,
        (u.senha_hash = crypt(p_senha, u.senha_hash)) AS autenticado
    FROM usuarios u
    WHERE u.email = p_email
      AND u.esta_ativo = TRUE;
$$;

-- -----------------------------------------------------------------------------
-- 2. CAMADA 5: O PARADOXO DA API E ROW-LEVEL SECURITY (RLS)
-- -----------------------------------------------------------------------------
-- Problema: A API conecta no banco usando um único usuário técnico (api_renovai).
-- Como o PostgreSQL sabe qual cooperativa ou cooperado está realizando a requisição?
-- Solução: O backend injeta variáveis de sessão no canal JDBC/conexão:
--   SET LOCAL app.cooperativa_logada = '<UUID_DA_COOPERATIVA>';
--   SET LOCAL app.usuario_logado     = '<UUID_DO_FUNCIONARIO_OU_USUARIO>';
--
-- O RLS avalia dinamicamente cada linha e aplica um filtro invisível.
-- O "Escudo NULLIF": O segundo argumento 'true' e a função NULLIF() blindam
-- a query contra erro 22P02 se a variável não foi definida ou estiver vazia.
-- -----------------------------------------------------------------------------

-- Habilitação do RLS nas tabelas-chave
ALTER TABLE coletas ENABLE ROW LEVEL SECURITY;
ALTER TABLE estoques ENABLE ROW LEVEL SECURITY;
ALTER TABLE rateios ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos_cooperativas ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- TABELA: coletas (Política Híbrida — Slide 10: Super Desafio)
-- -----------------------------------------------------------------------------
-- Regra de Leitura:
-- 1. Se for um cooperado autenticado (app.usuario_logado), ele enxerga APENAS suas próprias coletas.
-- 2. Se for a cooperativa/gestor (app.cooperativa_logada), ele enxerga TODAS as coletas da cooperativa.
DROP POLICY IF EXISTS p_coletas_leitura_hibrida ON coletas;
CREATE POLICY p_coletas_leitura_hibrida ON coletas
FOR SELECT
USING (
    -- Cenário A: O próprio cooperado consultando seu histórico de campo
    cooperado_id = NULLIF(current_setting('app.usuario_logado', true), '')::UUID
    OR
    -- Cenário B: Gestão da cooperativa consultando toda a produção da unidade
    cooperado_id IN (
        SELECT f.funcionario_id 
        FROM funcionarios f 
        WHERE f.cooperativa_id = NULLIF(current_setting('app.cooperativa_logada', true), '')::UUID
    )
);

-- Regra de Inserção: Impede que um cooperado registre coleta em nome de outro (blindagem de fraude)
DROP POLICY IF EXISTS p_coletas_impedir_fraude_insert ON coletas;
CREATE POLICY p_coletas_impedir_fraude_insert ON coletas
FOR INSERT
WITH CHECK (
    cooperado_id = NULLIF(current_setting('app.usuario_logado', true), '')::UUID
    OR
    cooperado_id IN (
        SELECT f.funcionario_id 
        FROM funcionarios f 
        WHERE f.cooperativa_id = NULLIF(current_setting('app.cooperativa_logada', true), '')::UUID
    )
);

-- -----------------------------------------------------------------------------
-- TABELA: estoques (Isolamento Estrito por Cooperativa)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS p_estoques_cooperativa_select ON estoques;
CREATE POLICY p_estoques_cooperativa_select ON estoques
FOR SELECT
USING (
    cooperativa_id = NULLIF(current_setting('app.cooperativa_logada', true), '')::UUID
);

DROP POLICY IF EXISTS p_estoques_cooperativa_mod ON estoques;
CREATE POLICY p_estoques_cooperativa_mod ON estoques
FOR ALL
USING (
    cooperativa_id = NULLIF(current_setting('app.cooperativa_logada', true), '')::UUID
)
WITH CHECK (
    cooperativa_id = NULLIF(current_setting('app.cooperativa_logada', true), '')::UUID
);

-- -----------------------------------------------------------------------------
-- TABELA: rateios (Isolamento Financeiro da Cooperativa)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS p_rateios_cooperativa_select ON rateios;
CREATE POLICY p_rateios_cooperativa_select ON rateios
FOR SELECT
USING (
    cooperativa_id = NULLIF(current_setting('app.cooperativa_logada', true), '')::UUID
);

DROP POLICY IF EXISTS p_rateios_cooperativa_insert ON rateios;
CREATE POLICY p_rateios_cooperativa_insert ON rateios
FOR INSERT
WITH CHECK (
    cooperativa_id = NULLIF(current_setting('app.cooperativa_logada', true), '')::UUID
);

-- -----------------------------------------------------------------------------
-- TABELA: pedidos_cooperativas (Visualização de Pedidos B2B por Cooperativa)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS p_pedidos_coop_select ON pedidos_cooperativas;
CREATE POLICY p_pedidos_coop_select ON pedidos_cooperativas
FOR SELECT
USING (
    cooperativa_id = NULLIF(current_setting('app.cooperativa_logada', true), '')::UUID
);
