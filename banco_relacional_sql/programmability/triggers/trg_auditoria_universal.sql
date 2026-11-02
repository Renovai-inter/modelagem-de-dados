-- =============================================================================
-- RENOVAÍ — TRIGGERS DE AUDITORIA UNIVERSAL
-- =============================================================================

-- 1. USUÁRIOS E PERFIS
CREATE OR REPLACE TRIGGER trg_auditoria_cooperativas
AFTER INSERT OR UPDATE OR DELETE ON cooperativas
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_empresas
AFTER INSERT OR UPDATE OR DELETE ON empresas
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_usuarios
AFTER INSERT OR UPDATE OR DELETE ON usuarios
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_perfis
AFTER INSERT OR UPDATE OR DELETE ON perfis
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_funcionarios
AFTER INSERT OR UPDATE OR DELETE ON funcionarios
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_telefones
AFTER INSERT OR UPDATE OR DELETE ON telefones
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_empresa_materiais_interesses
AFTER INSERT OR UPDATE OR DELETE ON empresa_materiais_interesses
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_empresa_cooperativas_favoritas
AFTER INSERT OR UPDATE OR DELETE ON empresa_cooperativas_favoritas
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

-- 2. LOGÍSTICA, PEDIDOS E ESTOQUE
CREATE OR REPLACE TRIGGER trg_auditoria_categorias_materiais
AFTER INSERT OR UPDATE OR DELETE ON categorias_materiais
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_materiais
AFTER INSERT OR UPDATE OR DELETE ON materiais
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_pedidos
AFTER INSERT OR UPDATE OR DELETE ON pedidos
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_pedido_itens
AFTER INSERT OR UPDATE OR DELETE ON pedido_itens
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_negociacoes
AFTER INSERT OR UPDATE OR DELETE ON negociacoes
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_negociacao_itens
AFTER INSERT OR UPDATE OR DELETE ON negociacao_itens
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_negociacao_mensagens
AFTER INSERT OR UPDATE OR DELETE ON negociacao_mensagens
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_triagens
AFTER INSERT OR UPDATE OR DELETE ON triagens
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_estoques
AFTER INSERT OR UPDATE OR DELETE ON estoques
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_despesas
AFTER INSERT OR UPDATE OR DELETE ON despesas
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_lancamentos_despesas
AFTER INSERT OR UPDATE OR DELETE ON lancamentos_despesas
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_movimentacoes_estoques
AFTER INSERT OR UPDATE OR DELETE ON movimentacoes_estoques
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_rotas
AFTER INSERT OR UPDATE OR DELETE ON rotas
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_rotas_enderecos
AFTER INSERT OR UPDATE OR DELETE ON rotas_enderecos
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

-- 3. FINANCEIRO E QUALIDADE
CREATE OR REPLACE TRIGGER trg_auditoria_rateios
AFTER INSERT OR UPDATE OR DELETE ON rateios
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();

CREATE OR REPLACE TRIGGER trg_auditoria_avaliacoes
AFTER INSERT OR UPDATE OR DELETE ON avaliacoes
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_universal();