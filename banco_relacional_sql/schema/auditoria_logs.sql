-- =============================================================================
-- RENOVAÍ — SCHEMA PostgreSQL
-- SCRIPT: TABELAS (Auditoria e Logs)
-- =============================================================================

CREATE TABLE IF NOT EXISTS auditoria_categorias_materiais (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do usuário afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_materiais (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do usuário afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_cooperativas (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do usuário afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_empresas (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do usuário afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_usuarios (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do usuário afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_perfis (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do perfil afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_funcionarios (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do funcionário afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_telefones (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do contato afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_empresa_materiais_interesses (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do material_interesse afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_empresa_cooperativas_favoritas (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da cooperativa_favorita afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

-- 2. AUDITORIA DE LOGÍSTICA, PEDIDOS E ESTOQUE
CREATE TABLE IF NOT EXISTS auditoria_pedidos (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do pedido afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_pedido_itens (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do item afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_negociacoes (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da negpciacao afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_negociacao_itens (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do item afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_negociacao_mensagens (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da mensagem afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_triagens (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da triagem afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_estoques (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do registro de estoque afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_movimentacoes_estoques (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da movimentação afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_despesas (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da despesa afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_lancamentos_despesas (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do lançamento afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_rotas (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da rota afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_rotas_enderecos (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da rota_endereco afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

-- 3. AUDITORIA FINANCEIRA E DE QUALIDADE
CREATE TABLE IF NOT EXISTS auditoria_rateios (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID do rateio afetado
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS auditoria_avaliacoes (
    auditoria_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registro_id        UUID NOT NULL, -- ID da avaliação afetada
    operacao           VARCHAR(50) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    dados_antigos      JSONB,
    dados_novos        JSONB,
    campos_atualizados TEXT[],
    usuario_execucao   VARCHAR(255),
    data_alteracao     TIMESTAMP DEFAULT NOW() NOT NULL
);