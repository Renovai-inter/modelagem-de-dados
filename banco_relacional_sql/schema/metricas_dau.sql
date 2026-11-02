-- =============================================================================
-- RENOVAÍ — MONITORAMENTO DE ATIVIDADE DE USUÁRIOS E DAU (PostgreSQL)
-- SCRIPT: TABELAS, VIEWS E PROCEDURES DE DAU (Daily Active Users)
-- =============================================================================

CREATE TABLE IF NOT EXISTS atividade_usuarios_diaria (
    atividade_id   UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
    data_acesso    DATE         NOT NULL,
    tipo_usuario   VARCHAR(20)  NOT NULL CHECK (tipo_usuario IN ('COOPERADO', 'EMPRESA')),
    funcionario_id UUID,
    empresa_id     UUID,
    criado_em      TIMESTAMP    DEFAULT NOW() NOT NULL,

    CONSTRAINT chk_atividade_entidade CHECK (
        (tipo_usuario = 'COOPERADO' AND funcionario_id IS NOT NULL AND empresa_id IS NULL)
        OR (tipo_usuario = 'EMPRESA' AND empresa_id IS NOT NULL AND funcionario_id IS NULL)
    ),
    CONSTRAINT uq_atividade_usuario_dia UNIQUE (data_acesso, tipo_usuario, funcionario_id, empresa_id)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_atividade_funcionario'
    ) THEN
        ALTER TABLE atividade_usuarios_diaria
            ADD CONSTRAINT fk_atividade_funcionario
            FOREIGN KEY (funcionario_id) REFERENCES funcionarios(funcionario_id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_atividade_empresa'
    ) THEN
        ALTER TABLE atividade_usuarios_diaria
            ADD CONSTRAINT fk_atividade_empresa
            FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id) ON DELETE CASCADE;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS metricas_dau (
    data_referencia         DATE         PRIMARY KEY,
    total_cooperados_ativos INTEGER      NOT NULL DEFAULT 0 CHECK (total_cooperados_ativos >= 0),
    total_empresas_ativas   INTEGER      NOT NULL DEFAULT 0 CHECK (total_empresas_ativas >= 0),
    total_usuarios_ativos   INTEGER      NOT NULL DEFAULT 0 CHECK (total_usuarios_ativos >= 0),
    atualizado_em           TIMESTAMP    DEFAULT NOW() NOT NULL
);

CREATE OR REPLACE PROCEDURE sp_calcular_dau_diario(p_data DATE DEFAULT CURRENT_DATE)
AS $$
BEGIN
    INSERT INTO metricas_dau (
        data_referencia,
        total_cooperados_ativos,
        total_empresas_ativas,
        total_usuarios_ativos,
        atualizado_em
    )
    SELECT
        p_data,
        COUNT(DISTINCT funcionario_id) FILTER (WHERE tipo_usuario = 'COOPERADO'),
        COUNT(DISTINCT empresa_id)     FILTER (WHERE tipo_usuario = 'EMPRESA'),
        COUNT(DISTINCT COALESCE(funcionario_id, empresa_id)),
        NOW()
    FROM atividade_usuarios_diaria
    WHERE data_acesso = p_data
    ON CONFLICT (data_referencia) DO UPDATE
    SET total_cooperados_ativos = EXCLUDED.total_cooperados_ativos,
        total_empresas_ativas   = EXCLUDED.total_empresas_ativas,
        total_usuarios_ativos   = EXCLUDED.total_usuarios_ativos,
        atualizado_em           = NOW();

    COMMIT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW vw_fato_dau AS
SELECT
    TO_CHAR(d.data_referencia, 'yyyymmdd')::INT AS data_id,
    d.data_referencia,
    d.total_cooperados_ativos,
    d.total_empresas_ativas,
    d.total_usuarios_ativos,
    ROUND(
        AVG(d.total_usuarios_ativos) OVER (
            ORDER BY d.data_referencia
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS media_movel_7d_dau,
    d.atualizado_em
FROM metricas_dau d;
