-- =============================================================================
-- RENOVAÍ — SCHEMA PostgreSQL
-- SCRIPT: ÍNDICES DE PERFORMANCE (B-Tree, Compostos e Parciais)
-- =============================================================================
-- Este arquivo cria índices estratégicos em Foreign Keys (chaves estrangeiras),
-- colunas de alta cardinalidade e pares de filtro/ordenação frequentemente
-- acessados pelas aplicações cliente (Spring API, Frontend React, Mobile e IA).
--
-- Padrões adotados:
-- 1. B-Tree padrão para buscas por igualdade (=), IN e JOINs de Foreign Keys.
-- 2. Índices compostos com ordenação pré-computada (ex: cooperativa_id + data DESC)
--    para eliminar operadores caros de SORT (quicksort) em consultas temporais.
-- 3. Índices parciais (WHERE) para tabelas com flags de status ativo, reduzindo
--    o tamanho em disco e o custo de manutenção em operações DML.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. IDENTIDADE, AUTENTICAÇÃO E CONTATOS
-- -----------------------------------------------------------------------------
-- Telefones associados a perfis corporativos e usuários
CREATE INDEX IF NOT EXISTS idx_telefones_perfil_id 
    ON telefones (perfil_id);

CREATE INDEX IF NOT EXISTS idx_telefones_usuario_id 
    ON telefones (usuario_id);

-- Perfis: FK para endereços
CREATE INDEX IF NOT EXISTS idx_perfis_endereco_id 
    ON perfis (endereco_id);

-- Usuários: Filtro rápido de usuários ativos (índice parcial)
CREATE INDEX IF NOT EXISTS idx_usuarios_ativos 
    ON usuarios (usuario_id) 
    WHERE esta_ativo = TRUE;

-- -----------------------------------------------------------------------------
-- 2. RECURSOS HUMANOS E ESTRUTURA ORGANIZACIONAL (Funcionários e Equipes)
-- -----------------------------------------------------------------------------
-- Busca de colaborador por usuário logado (Spring Auth / Mobile session)
CREATE INDEX IF NOT EXISTS idx_funcionarios_usuario_id 
    ON funcionarios (usuario_id);

-- Listagem de funcionários por cooperativa
CREATE INDEX IF NOT EXISTS idx_funcionarios_cooperativa_id 
    ON funcionarios (cooperativa_id);

-- Filtro de cargos e hierarquias
CREATE INDEX IF NOT EXISTS idx_funcionarios_cargo_id 
    ON funcionarios (cargo_id);

-- Índice composto para listagem de cooperados ativos por cooperativa
CREATE INDEX IF NOT EXISTS idx_funcionarios_coop_status 
    ON funcionarios (cooperativa_id, status_funcionario);

-- Equipes geridas por determinado gestor
CREATE INDEX IF NOT EXISTS idx_equipes_gestor_id 
    ON equipes (gestor_id);

-- Lookup inverso de equipes de um cooperado específico
CREATE INDEX IF NOT EXISTS idx_equipes_cooperados_cooperado_id 
    ON equipes_cooperados (cooperado_id);

-- -----------------------------------------------------------------------------
-- 3. PEDIDOS, ITENS E NEGOCIAÇÕES (Fluxo Comercial Empresa <-> Cooperativa)
-- -----------------------------------------------------------------------------
-- Pedidos realizados por uma empresa, ordenados pelos mais recentes
CREATE INDEX IF NOT EXISTS idx_pedidos_empresa_data 
    ON pedidos (empresa_id, data_pedido DESC);

-- Ordenação global de pedidos por data
CREATE INDEX IF NOT EXISTS idx_pedidos_data_pedido 
    ON pedidos (data_pedido DESC);

-- Pedidos vinculados a uma cooperativa filtrados por status do pedido
CREATE INDEX IF NOT EXISTS idx_pedidos_cooperativas_coop_status 
    ON pedidos_cooperativas (cooperativa_id, status_id);

-- Lookup de pedidos por status (ex: listar todos os pedidos pendentes)
CREATE INDEX IF NOT EXISTS idx_pedidos_cooperativas_status_id 
    ON pedidos_cooperativas (status_id);

-- JOIN crítico: itens de um pedido específico
CREATE INDEX IF NOT EXISTS idx_pedido_itens_pedido_id 
    ON pedido_itens (pedido_id);

-- Agrupamentos e relatórios por material comercializado
CREATE INDEX IF NOT EXISTS idx_pedido_itens_material_id 
    ON pedido_itens (material_id);

-- Negociações filtradas por cooperativa
CREATE INDEX IF NOT EXISTS idx_negociacoes_cooperativa_id 
    ON negociacoes (cooperativa_id);

-- Negociações filtradas por empresa compradora
CREATE INDEX IF NOT EXISTS idx_negociacoes_empresa_id 
    ON negociacoes (empresa_id);

-- Negociações por status
CREATE INDEX IF NOT EXISTS idx_negociacoes_status_id 
    ON negociacoes (status_id);

-- Itens vinculados a uma negociação
CREATE INDEX IF NOT EXISTS idx_negociacao_itens_material_id 
    ON negociacao_itens (material_id);

-- Chat/Timeline de mensagens em negociações ordenadas cronologicamente
CREATE INDEX IF NOT EXISTS idx_negociacao_mensagens_timeline 
    ON negociacao_mensagens (negociacao_id, data_envio ASC);

CREATE INDEX IF NOT EXISTS idx_negociacao_mensagens_remetente 
    ON negociacao_mensagens (remetente_id);

-- Avaliações recebidas por um perfil ordenadas da mais recente para a mais antiga
CREATE INDEX IF NOT EXISTS idx_avaliacoes_avaliado_data 
    ON avaliacoes (avaliado_id, data_avaliacao DESC);

CREATE INDEX IF NOT EXISTS idx_avaliacoes_avaliador_id 
    ON avaliacoes (avaliador_id);

CREATE INDEX IF NOT EXISTS idx_avaliacoes_pedido_id 
    ON avaliacoes (pedido_id);

-- -----------------------------------------------------------------------------
-- 4. OPERAÇÕES DE CAMPO E RECICLAGEM (Coletas e Triagens)
-- -----------------------------------------------------------------------------
-- Histórico de coletas realizadas por um cooperado ordenadas por data
CREATE INDEX IF NOT EXISTS idx_coletas_cooperado_data 
    ON coletas (cooperado_id, data_evento DESC);

-- Linha do tempo geral de coletas para dashboards analíticos
CREATE INDEX IF NOT EXISTS idx_coletas_data_evento 
    ON coletas (data_evento DESC);

-- Coletas realizadas em uma rota específica
CREATE INDEX IF NOT EXISTS idx_coletas_rota_id 
    ON coletas (rota_id);

-- Histórico de triagens por tipo de material reciclado
CREATE INDEX IF NOT EXISTS idx_triagens_material_data 
    ON triagens (material_id, data_evento DESC);

-- Produtividade de triagem por equipe operacional
CREATE INDEX IF NOT EXISTS idx_triagens_equipe_data 
    ON triagens (equipe_id, data_evento DESC);

-- Rastreabilidade: triagens geradas a partir de determinada coleta
CREATE INDEX IF NOT EXISTS idx_triagens_coleta_id 
    ON triagens (coleta_id);

CREATE INDEX IF NOT EXISTS idx_triagens_data_evento 
    ON triagens (data_evento DESC);

-- -----------------------------------------------------------------------------
-- 5. GESTÃO DE ESTOQUE E LIVRO RAZÃO (Movimentações)
-- -----------------------------------------------------------------------------
-- Busca de estoque pelo material (complementa a unique key cooperativa_id + material_id)
CREATE INDEX IF NOT EXISTS idx_estoques_material_id 
    ON estoques (material_id);

-- Extrato de movimentações por estoque ordenado do mais recente para auditoria de saldo
CREATE INDEX IF NOT EXISTS idx_movimentacoes_estoque_data 
    ON movimentacoes_estoques (estoque_id, data_movimentacao DESC);

-- Rastreabilidade de movimentação para o evento de triagem
CREATE INDEX IF NOT EXISTS idx_movimentacoes_triagem_id 
    ON movimentacoes_estoques (triagem_id);

-- Rastreabilidade de movimentação para o item do pedido atendido
CREATE INDEX IF NOT EXISTS idx_movimentacoes_item_id 
    ON movimentacoes_estoques (item_id);

CREATE INDEX IF NOT EXISTS idx_movimentacoes_data 
    ON movimentacoes_estoques (data_movimentacao DESC);

-- -----------------------------------------------------------------------------
-- 6. FINANCEIRO E COOPERATIVISMO (Rateios e Despesas)
-- -----------------------------------------------------------------------------
-- Rateios geridos por determinado gestor
CREATE INDEX IF NOT EXISTS idx_rateios_gestor_id 
    ON rateios (gestor_id);

CREATE INDEX IF NOT EXISTS idx_rateios_tipo_rateio_id 
    ON rateios (tipo_rateio_id);

-- Extrato individual de pagamentos de rateio para um cooperado específico
CREATE INDEX IF NOT EXISTS idx_rateios_func_cooperado 
    ON rateios_funcionarios (cooperado_id);

-- Despesas cadastradas por cooperativa
CREATE INDEX IF NOT EXISTS idx_despesas_cooperativa_id 
    ON despesas (cooperativa_id);

-- Lançamentos contábeis de despesas filtrados por competência mensal
CREATE INDEX IF NOT EXISTS idx_lancamentos_despesas_mes 
    ON lancamentos_despesas (mes_referencia);

-- -----------------------------------------------------------------------------
-- 7. LOGÍSTICA E RELACIONAMENTOS (Rotas e Preferências)
-- -----------------------------------------------------------------------------
-- Rotas ativas por cooperativa (índice parcial)
CREATE INDEX IF NOT EXISTS idx_rotas_cooperativa_ativa 
    ON rotas (cooperativa_id) 
    WHERE esta_ativa = TRUE;

-- Sequência ordenada de paradas e endereços de uma rota de coleta
CREATE INDEX IF NOT EXISTS idx_rotas_enderecos_rota_ordem 
    ON rotas_enderecos (rota_id, ordem ASC);

CREATE INDEX IF NOT EXISTS idx_rotas_enderecos_endereco_id 
    ON rotas_enderecos (endereco_id);

-- Categorias de materiais de interesse por categoria
CREATE INDEX IF NOT EXISTS idx_empresa_mat_interesses_cat 
    ON empresa_materiais_interesses (categoria_id);

-- Cooperativas favoritadas por empresas
CREATE INDEX IF NOT EXISTS idx_empresa_coop_fav_coop 
    ON empresa_cooperativas_favoritas (cooperativa_id);

-- -----------------------------------------------------------------------------
-- 8. ANALYTICS E MONITORAMENTO (DAU / Atividade Diária)
-- -----------------------------------------------------------------------------
-- Índices para agregação e cálculo rápido de métricas DAU por cooperado e empresa
CREATE INDEX IF NOT EXISTS idx_dau_data_funcionario 
    ON atividade_usuarios_diaria (data_acesso, funcionario_id);

CREATE INDEX IF NOT EXISTS idx_dau_data_empresa 
    ON atividade_usuarios_diaria (data_acesso, empresa_id);
