-- =============================================================================
-- RENOVAÍ — SCHEMA PostgreSQL
-- SCRIPT: TABELAS
-- =============================================================================

CREATE TABLE IF NOT EXISTS enderecos (
    endereco_id     UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    cep             VARCHAR(9),
    logradouro      VARCHAR(255),
    numero          VARCHAR(20),
    complemento     VARCHAR(255),
    bairro          VARCHAR(100),
    cidade          VARCHAR(100),
    tipo            VARCHAR(20)     CHECK (tipo IN ('Residencial', 'Comercial', 'Coleta'))
);

CREATE TABLE IF NOT EXISTS categorias_materiais (
    categoria_id        UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    categoria_pai_id    UUID,
    nome_categoria      VARCHAR(100)    NOT NULL
);

CREATE TABLE IF NOT EXISTS materiais (
    material_id     UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    categoria_id    UUID            NOT NULL,
    cooperativa_id  UUID,
    imagem_url      TEXT,
    preco_sugerido  NUMERIC(10, 2)  CHECK (preco_sugerido IS NULL OR preco_sugerido >= 0),
    esta_disponivel BOOLEAN         DEFAULT TRUE NOT NULL
);

CREATE TABLE IF NOT EXISTS cooperativas (
    cooperativa_id          UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    nome                    VARCHAR(255)    NOT NULL,
    imagem_url              TEXT,
    descricao               TEXT,
    contato_preferencial    VARCHAR(50)     CHECK(contato_preferencial IN ('WHATSAPP', 'TELEFONE', 'EMAIL')),
    horario_funcionamento   VARCHAR(100),
    numero_cooperados       INTEGER         DEFAULT 0 NOT NULL CHECK (numero_cooperados >= 0),
    data_atualizacao        TIMESTAMP       DEFAULT NOW()

);

CREATE TABLE IF NOT EXISTS empresas (
    empresa_id  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    nome        VARCHAR(255)    NOT NULL,
    imagem_url  TEXT,
    descricao   TEXT
);

CREATE TABLE IF NOT EXISTS empresa_materiais_interesses (
    empresa_material_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id          UUID NOT NULL,
    categoria_id        UUID NOT NULL,

    CONSTRAINT uq_empresa_categoria UNIQUE (empresa_id, categoria_id)
);

CREATE TABLE IF NOT EXISTS empresa_cooperativas_favoritas (
    favorito_id    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id     UUID NOT NULL,
    cooperativa_id UUID NOT NULL,
    data_criacao   TIMESTAMP DEFAULT NOW() NOT NULL,

    CONSTRAINT uq_favorito UNIQUE (empresa_id, cooperativa_id)
);

CREATE TABLE IF NOT EXISTS perfis (
    perfil_id            UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id           UUID            UNIQUE,
    cooperativa_id       UUID            UNIQUE,
    endereco_id          UUID,
    email                VARCHAR(255)    NOT NULL UNIQUE,
    cnpj                 VARCHAR(18)     NOT NULL UNIQUE,
    senha_hash           VARCHAR(255),
    token_redefinicao    VARCHAR(255),
    data_criacao         TIMESTAMP       DEFAULT NOW() NOT NULL,
    data_token_expiracao TIMESTAMP,
    esta_ativo           BOOLEAN         DEFAULT TRUE NOT NULL,

    CONSTRAINT chk_perfis_tipo CHECK (
        (empresa_id IS NOT NULL AND cooperativa_id IS NULL)
        OR (empresa_id IS NULL AND cooperativa_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS usuarios (
    usuario_id           UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    nome                 VARCHAR(255)    NOT NULL,
    email                VARCHAR(255)    NOT NULL UNIQUE,
    cpf                  VARCHAR(14)     NOT NULL UNIQUE,
    senha                VARCHAR(128),
    senha_hash           VARCHAR(255)    NOT NULL,
    token_redefinicao    VARCHAR(255),
    imagem_url           TEXT,
    data_nascimento      DATE,
    ultimo_acesso        TIMESTAMP,
    data_criacao         TIMESTAMP       DEFAULT NOW(),
    data_atualizacao     TIMESTAMP       DEFAULT NOW(),
    data_token_expiracao TIMESTAMP,
    esta_ativo           BOOLEAN         DEFAULT TRUE,

    CONSTRAINT chk_data_nascimento CHECK (
        data_nascimento < CURRENT_DATE
    )
);

CREATE TABLE IF NOT EXISTS cargos (
    cargo_id    UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    cargo       VARCHAR(50)     NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS status (
    status_id        UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    referencia       VARCHAR(50),
    status_atual     VARCHAR(50)     NOT NULL,
    data_atualizacao TIMESTAMP       DEFAULT NOW() NOT NULL,

    CONSTRAINT uq_status_referencia_atual UNIQUE (referencia, status_atual)
);

CREATE TABLE IF NOT EXISTS funcionarios (
    funcionario_id     UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    usuario_id         UUID            NOT NULL,
    cooperativa_id     UUID,
    cargo_id           UUID            NOT NULL,
    data_admissao      TIMESTAMP       DEFAULT NOW() NOT NULL,
    data_desligamento  TIMESTAMP,
    status_funcionario VARCHAR(20)     DEFAULT 'ATIVO' CHECK (status_funcionario IN ('ATIVO', 'AFASTADO', 'INATIVO')),    
    esta_ativo         BOOLEAN GENERATED ALWAYS AS (status_funcionario IN ('ATIVO', 'AFASTADO')) STORED,
    esta_afastado      BOOLEAN GENERATED ALWAYS AS (status_funcionario = 'AFASTADO') STORED
);

CREATE TABLE IF NOT EXISTS telefones (
    telefone_id UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    perfil_id   UUID,
    usuario_id  UUID,
    ddd         VARCHAR(3),
    telefone    VARCHAR(20)     NOT NULL,

    CONSTRAINT chk_telefones_dono CHECK (
        (perfil_id IS NOT NULL AND usuario_id IS NULL)
        OR (perfil_id IS NULL AND usuario_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS equipes (
    equipe_id       UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    gestor_id       UUID            NOT NULL,
    nome            VARCHAR(255),
    descricao       TEXT,
    data_criacao    TIMESTAMP       DEFAULT NOW() NOT NULL,
    esta_ativa      BOOLEAN         DEFAULT TRUE NOT NULL
);

CREATE TABLE IF NOT EXISTS equipes_cooperados (
    equipe_cooperado_id UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
    equipe_id           UUID         NOT NULL,
    cooperado_id        UUID         NOT NULL,

    CONSTRAINT uq_equipe_cooperado UNIQUE (equipe_id, cooperado_id)
);

CREATE TABLE IF NOT EXISTS pedidos (
    pedido_id       UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id      UUID            NOT NULL,
    observacao      TEXT,
    data_pedido     TIMESTAMP       DEFAULT NOW() NOT NULL,
    data_conclusao  TIMESTAMP,

    CONSTRAINT chk_pedidos_datas CHECK (data_conclusao IS NULL OR data_conclusao >= data_pedido)
);

CREATE TABLE IF NOT EXISTS pedido_itens (
    item_id         UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    pedido_id       UUID            NOT NULL,
    material_id     UUID            NOT NULL,
    quantidade_kg   NUMERIC(10, 3)  CHECK (quantidade_kg IS NULL OR quantidade_kg > 0),
    preco_unitario  NUMERIC(10, 2)  NOT NULL CHECK (preco_unitario >= 0)
);

CREATE TABLE IF NOT EXISTS pedidos_cooperativas (
    pedido_cooperativa_id   UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
    pedido_id               UUID         NOT NULL,
    cooperativa_id          UUID         NOT NULL,
    status_id               UUID         NOT NULL,

    CONSTRAINT uq_pedido_cooperativa UNIQUE (pedido_id, cooperativa_id)
);

CREATE TABLE IF NOT EXISTS negociacoes (
    negociacao_id    UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    pedido_id        UUID        NOT NULL,
    cooperativa_id   UUID        NOT NULL,
    empresa_id       UUID        NOT NULL,
    status_id        UUID        NOT NULL,
    valor_total      NUMERIC(10,2),
    data_inicio      TIMESTAMP   DEFAULT NOW() NOT NULL,
    data_fechamento  TIMESTAMP,
    
    CONSTRAINT uq_pedido_cooperativa_negociacao UNIQUE (pedido_id, cooperativa_id)
);

CREATE TABLE IF NOT EXISTS negociacao_itens (
    negociacao_item_id UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    negociacao_id      UUID            NOT NULL,
    material_id        UUID            NOT NULL,
    quantidade_kg      NUMERIC(10, 3)  CHECK (quantidade_kg IS NULL OR quantidade_kg > 0),
    preco_unitario     NUMERIC(10, 2)  NOT NULL CHECK (preco_unitario >= 0),

    CONSTRAINT uq_negociacao_item_material UNIQUE (negociacao_id, material_id)
);

CREATE TABLE IF NOT EXISTS negociacao_mensagens (
    mensagem_id     UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    negociacao_id   UUID        NOT NULL,
    remetente_id    UUID        NOT NULL,
    mensagem        TEXT        NOT NULL,
    tipo_mensagem   VARCHAR(20) DEFAULT 'TEXTO' CHECK (tipo_mensagem IN ('TEXTO', 'CONTRAPROPOSTA', 'SISTEMA')),
    data_envio      TIMESTAMP   DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS avaliacoes (
    avaliacao_id    UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    avaliador_id    UUID            NOT NULL,
    avaliado_id     UUID            NOT NULL,
    pedido_id       UUID            NOT NULL,
    nota            INTEGER         CHECK (nota IS NULL OR nota BETWEEN 1 AND 5),
    comentario      TEXT,
    data_avaliacao  TIMESTAMP       DEFAULT NOW() NOT NULL,
    atualizado_em   TIMESTAMP       DEFAULT NOW(),

    CONSTRAINT chk_avaliacoes_perfis_diferentes CHECK (
        avaliador_id <> avaliado_id
    )
);

CREATE TABLE IF NOT EXISTS eventos_operacionais (
    evento_id    UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    data_evento  TIMESTAMP       DEFAULT NOW() NOT NULL,
    status_id    UUID,

    CONSTRAINT chk_evento_abstrato CHECK (FALSE) NO INHERIT
);

CREATE TABLE IF NOT EXISTS coletas (
    cooperado_id    UUID            NOT NULL,
    rota_id         UUID,
    imagem_url      TEXT,
    tipo_coleta     VARCHAR(30)     CHECK (tipo_coleta IN ('EXTERNA', 'ENTREGA')),
    quantidade_kg   NUMERIC(10, 3)  NOT NULL CHECK (quantidade_kg > 0),

    PRIMARY KEY (evento_id)
) INHERITS (eventos_operacionais);

CREATE TABLE IF NOT EXISTS estoques (
    estoque_id       UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    cooperativa_id   UUID            NOT NULL,
    material_id      UUID            NOT NULL,
    quantidade_kg    NUMERIC(10, 3)  DEFAULT 0 NOT NULL CHECK (quantidade_kg >= 0),
    data_atualizacao TIMESTAMP       DEFAULT NOW() NOT NULL,

    CONSTRAINT uq_cooperativa_material UNIQUE (cooperativa_id, material_id)
);

CREATE TABLE IF NOT EXISTS triagens (
    equipe_id               UUID            NOT NULL,
    coleta_id               UUID            NOT NULL,
    material_id             UUID            NOT NULL,
    imagem_url              TEXT,
    quantidade_kg           NUMERIC(10, 3)  NOT NULL CHECK (quantidade_kg > 0),
    quantidade_rejeito_kg   NUMERIC(10, 3)  DEFAULT 0 CHECK (quantidade_rejeito_kg >= 0),

    PRIMARY KEY (evento_id)
) INHERITS (eventos_operacionais);

CREATE TABLE IF NOT EXISTS movimentacoes_estoques (
    movimentacao_id   UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    estoque_id        UUID            NOT NULL,
    triagem_id        UUID,
    item_id           UUID,
    quantidade_kg     NUMERIC(10, 3)  NOT NULL CHECK (quantidade_kg <> 0),
    tipo_movimentacao VARCHAR(10)     GENERATED ALWAYS AS (
        CASE WHEN quantidade_kg > 0 THEN 'ENTRADA' ELSE 'SAIDA' END
    ) STORED,
    data_movimentacao TIMESTAMP       DEFAULT NOW() NOT NULL,

    CONSTRAINT chk_movimentacao_origem CHECK (
        (triagem_id IS NOT NULL AND item_id IS NULL)
        OR (triagem_id IS NULL AND item_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS tipos_rateios (
    tipo_rateio_id  UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    tipo_rateio     VARCHAR(255)    NOT NULL UNIQUE,
    descricao       TEXT
);

CREATE TABLE IF NOT EXISTS rateios (
    rateio_id       UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    cooperativa_id  UUID            NOT NULL,
    gestor_id       UUID            NOT NULL,
    tipo_rateio_id  UUID,
    mes_referencia  DATE            NOT NULL,
    data_rateio     TIMESTAMP       DEFAULT NOW() NOT NULL,

    CONSTRAINT uq_rateio_cooperativa_mes UNIQUE (cooperativa_id, mes_referencia)
);

CREATE TABLE IF NOT EXISTS rateios_funcionarios (
    rateio_funcionario_id   UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    rateio_id               UUID            NOT NULL,
    cooperado_id            UUID            NOT NULL,
    valor_rateio            NUMERIC(10, 2)  NOT NULL CHECK (valor_rateio > 0),

    CONSTRAINT uq_rateio_cooperado UNIQUE (rateio_id, cooperado_id)
);

CREATE TABLE IF NOT EXISTS despesas (
    despesa_id      UUID                 DEFAULT gen_random_uuid() PRIMARY KEY,
    cooperativa_id  UUID                 NOT NULL,
    nome            VARCHAR(255)         NOT NULL,
    tipo_despesa    VARCHAR(10)          NOT NULL CHECK (tipo_despesa IN ('FIXA', 'VARIAVEL')),
    esta_ativa      BOOLEAN              DEFAULT TRUE NOT NULL
);

CREATE TABLE IF NOT EXISTS lancamentos_despesas (
    lancamento_id       UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    despesa_id          UUID            NOT NULL,
    valor               NUMERIC(10, 2)  NOT NULL CHECK (valor >= 0),
    mes_referencia      DATE            NOT NULL,
    data_lancamento     TIMESTAMP       DEFAULT NOW() NOT NULL,
    
    UNIQUE (despesa_id, mes_referencia)
);

CREATE TABLE IF NOT EXISTS rotas (
    rota_id             UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    cooperativa_id      UUID            NOT NULL,
    nome                VARCHAR(255)    NOT NULL,
    esta_ativa          BOOLEAN         DEFAULT TRUE NOT NULL
);

CREATE TABLE rotas_enderecos (
    rota_endereco_id    UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
    rota_id             UUID            NOT NULL,
    endereco_id         UUID            NOT NULL,
    nome_local          VARCHAR(255)    NOT NULL,
    tipo_local          VARCHAR(50),
    ordem               INTEGER         NOT NULL DEFAULT 1
);