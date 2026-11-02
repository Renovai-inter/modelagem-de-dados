-- =============================================================================
-- RENOVAÍ — SEED DE DADOS DE REFERÊNCIA (CORRIGIDO)
-- =============================================================================

-- ============================================
-- CARGOS
-- ============================================
INSERT INTO cargos (cargo) VALUES
    ('Cooperado'),
    ('Gestor'),
    ('Admin'),
    ('motorista'),
    ('ADMIN_SITE')
ON CONFLICT (cargo) DO NOTHING;

-- ============================================
-- STATUS
-- ============================================
INSERT INTO status (referencia, status_atual) VALUES
    ('PEDIDO',  'Aberto'),
    ('PEDIDO',  'Aceito'),
    ('PEDIDO',  'Recusado'),
    ('PEDIDO',  'Finalizado'),
    ('PEDIDO',  'Em negociação'),
    ('COLETA',  'Pendente'),
    ('COLETA',  'Agendada'),
    ('COLETA',  'Coletado'),
    ('GERAL',   'Cancelado'),
    ('TRIAGEM', 'Em triagem'),
    ('TRIAGEM', 'Concluído'),
    ('NEGOCIACAO', 'Em andamento'),
    ('NEGOCIACAO', 'Acordo fechado'),
    ('NEGOCIACAO', 'Negociação recusada')
ON CONFLICT (referencia, status_atual) DO NOTHING;

-- ============================================
-- TIPOS_RATEIOS
-- ============================================
INSERT INTO tipos_rateios (tipo_rateio, descricao) VALUES
    ('AUTOMATICO', 'Rateio calculado automaticamente pelo sistema, dividindo o valor líquido (vendas - despesas) entre os cooperados ativos.'),
    ('MANUAL',     'Rateio com valores definidos manualmente pelo gestor, fora do cálculo automático.')
ON CONFLICT (tipo_rateio) DO NOTHING;

-- =============================================================================
-- CATEGORIAS_MATERIAIS
-- =============================================================================
INSERT INTO categorias_materiais (nome_categoria)
SELECT cat.nome
FROM (VALUES 
    ('Plástico'),
    ('Papel'),
    ('Metal'),
    ('Vidro')
) AS cat(nome)
WHERE NOT EXISTS (
    SELECT 1 FROM categorias_materiais cm WHERE cm.nome_categoria = cat.nome
);

-- =============================================================================
-- MATERIAIS
-- =============================================================================
INSERT INTO materiais (categoria_id, preco_sugerido, esta_disponivel)
SELECT cm.categoria_id, m.preco, TRUE
FROM categorias_materiais cm
JOIN (VALUES
    ('Plástico', 3.50),
    ('Papel',    1.80),
    ('Metal',    2.20),
    ('Vidro',    4.50)
) AS m(nome_categoria, preco) ON cm.nome_categoria = m.nome_categoria
WHERE NOT EXISTS (
    SELECT 1 FROM materiais mat WHERE mat.categoria_id = cm.categoria_id
);