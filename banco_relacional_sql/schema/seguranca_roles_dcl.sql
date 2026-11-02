-- =============================================================================
-- RENOVAÍ — SEGURANÇA DE DADOS NO PostgreSQL (A FORTALEZA MACRO)
-- SCRIPT: DCL — CONTROLE DE ACESSO E PRINCÍPIO DO MENOR PRIVILÉGIO
-- =============================================================================
-- Referência: Aulas de Modelagem de Dados — Segurança de Dados (Instituto J&F)
-- Slides 3, 4, 9 e 10
--
-- REGRA DE OURO (Slide 4):
-- Jamais conecte a aplicação web utilizando o superusuário (postgres).
-- Um vazamento compromete toda a infraestrutura. O backend deve receber
-- apenas os privilégios absolutos para operar, isolando o dano em caso de invasão.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. TABELA DE LOGS DE SEGURANÇA E AUDITORIA ATIVA (Slide 9: Hands-On 1 Avançado)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS log_seguranca_sistema (
    log_id          UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    nivel           VARCHAR(20)     NOT NULL CHECK (nivel IN ('INFO', 'WARN', 'ERROR', 'CRITICAL')),
    categoria       VARCHAR(50)     NOT NULL,
    mensagem        TEXT            NOT NULL,
    usuario_origem  VARCHAR(255),
    ip_origem       INET,
    data_registro   TIMESTAMP       DEFAULT NOW() NOT NULL
);

-- Compatibilidade direta com a nomenclatura do exercício do Slide 9
CREATE TABLE IF NOT EXISTS tb_log_sistema (
    log_id          UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    nivel           VARCHAR(20)     NOT NULL CHECK (nivel IN ('INFO', 'WARN', 'ERROR', 'CRITICAL')),
    categoria       VARCHAR(50)     NOT NULL,
    mensagem        TEXT            NOT NULL,
    data_registro   TIMESTAMP       DEFAULT NOW() NOT NULL
);

-- -----------------------------------------------------------------------------
-- 1. IDENTIDADE DO BACKEND (API REST Spring Boot & API-Redis — Slide 4)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'api_renovai') THEN
        CREATE ROLE api_renovai WITH LOGIN PASSWORD 'RenovaiSecure@2026';
    END IF;
END $$;

-- Concede uso do schema público
GRANT USAGE ON SCHEMA public TO api_renovai;

-- Concede permissões operacionais estritas (o que a aplicação precisa)
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO api_renovai;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO api_renovai;

-- Revoga acessos perigosos em tabelas críticas e imutáveis (isolamento de dano)
REVOKE DELETE ON pedidos FROM api_renovai;
REVOKE DELETE ON movimentacoes_estoques FROM api_renovai;
REVOKE DELETE ON rateios FROM api_renovai;
REVOKE DELETE ON lancamentos_despesas FROM api_renovai;
REVOKE DELETE ON log_seguranca_sistema FROM api_renovai;
REVOKE DELETE ON tb_log_sistema FROM api_renovai;
REVOKE DELETE ON auditoria_usuarios FROM api_renovai;
REVOKE DELETE ON auditoria_pedidos FROM api_renovai;
REVOKE DELETE ON auditoria_movimentacoes_estoques FROM api_renovai;

-- Garante que tabelas criadas no futuro herdem essas permissões automaticamente
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO api_renovai;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO api_renovai;

-- -----------------------------------------------------------------------------
-- 2. ROLE ANALÍTICA (sistema_bi — Slide 9: Hands-On 1 Atividade Básica)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'sistema_bi') THEN
        CREATE ROLE sistema_bi WITH LOGIN PASSWORD 'BiMetrics@2026';
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO sistema_bi;

-- Leitura exclusiva em views analíticas (Data Marts, Dimensões e Fatos)
GRANT SELECT ON vw_dim_categoria_macro TO sistema_bi;
GRANT SELECT ON vw_dim_cooperativa TO sistema_bi;
GRANT SELECT ON vw_dim_empresa TO sistema_bi;
GRANT SELECT ON vw_dim_equipe TO sistema_bi;
GRANT SELECT ON vw_dim_material TO sistema_bi;
GRANT SELECT ON vw_dim_pedido TO sistema_bi;
GRANT SELECT ON vw_dim_subcategoria TO sistema_bi;
GRANT SELECT ON vw_dim_tempo TO sistema_bi;
GRANT SELECT ON vw_fato_metricas_mensais TO sistema_bi;
GRANT SELECT ON vw_fato_movimentacoes_estoque TO sistema_bi;
GRANT SELECT ON vw_fato_rendimento_coleta_triagem TO sistema_bi;
GRANT SELECT ON vw_fato_triagens TO sistema_bi;
GRANT SELECT ON vw_fato_vendas TO sistema_bi;
GRANT SELECT ON vw_fato_negociacoes TO sistema_bi;
GRANT SELECT ON vw_fato_avaliacoes TO sistema_bi;
GRANT SELECT ON vw_fato_ranking_cooperativas_materiais TO sistema_bi;
GRANT SELECT ON vw_fato_dau TO sistema_bi;
GRANT SELECT ON metricas_dau TO sistema_bi;

-- Novas views analíticas com Window Functions avançadas
GRANT SELECT ON vw_analitica_desempenho_equipes_triagem TO sistema_bi;
GRANT SELECT ON vw_analitica_fluxo_coleta_anomalias TO sistema_bi;
GRANT SELECT ON vw_analitica_curva_abc_materiais TO sistema_bi;
GRANT SELECT ON vw_analitica_segmentacao_empresas_rfv TO sistema_bi;
GRANT SELECT ON vw_analitica_saude_financeira_rateio_esg TO sistema_bi;
GRANT SELECT ON vw_analitica_estoque_cobertura_giro TO sistema_bi;

-- -----------------------------------------------------------------------------
-- 3. PERMISSÕES A NÍVEL DE COLUNA (analista_perfil — Slide 9: Hands-On 1 Intermediária 1)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'analista_perfil') THEN
        CREATE ROLE analista_perfil WITH LOGIN PASSWORD 'Analista@2026';
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO analista_perfil;

-- O analista pode consultar apenas nome, email e datas, mas NÃO pode visualizar
-- dados sensíveis como CPF, senha em texto, senha_hash ou tokens de redefinição!
GRANT SELECT (usuario_id, nome, email, data_nascimento, data_criacao, esta_ativo) 
ON usuarios TO analista_perfil;

-- -----------------------------------------------------------------------------
-- 4. ROLE DE GRUPO COM HERANÇA (grupo_operacional — Slide 9: Hands-On 1 Super Desafio)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'grupo_operacional') THEN
        CREATE ROLE grupo_operacional NOLOGIN;
    END IF;
END $$;

-- Concede privilégios operacionais ao grupo
GRANT SELECT, INSERT ON coletas TO grupo_operacional;
GRANT SELECT, INSERT ON triagens TO grupo_operacional;
GRANT SELECT ON estoques TO grupo_operacional;
GRANT SELECT ON rotas TO grupo_operacional;

-- Adiciona sistema_bi como membro do grupo operacional para herdar privilégios
GRANT grupo_operacional TO sistema_bi;

-- -----------------------------------------------------------------------------
-- 5. AUDITOR CORPORATIVO COM BYPASSRLS (Slide 10: Hands-On 2 Avançada)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'auditor_corporativo') THEN
        CREATE ROLE auditor_corporativo WITH LOGIN PASSWORD 'Audit@2026' BYPASSRLS;
    ELSE
        ALTER ROLE auditor_corporativo WITH BYPASSRLS;
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO auditor_corporativo;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor_corporativo;

-- Concede as roles criadas ao usuário atual da sessão administrativa
DO $$
BEGIN
    EXECUTE format('GRANT api_renovai, sistema_bi, analista_perfil, auditor_corporativo TO %I;', CURRENT_USER);
END $$;
