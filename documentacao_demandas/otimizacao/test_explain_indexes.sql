-- =============================================================================
-- RENOVAÍ — TESTES DE PERFORMANCE COM EXPLAIN E EXPLAIN ANALYZE
-- SCRIPT: pg_dbRenovai/tests/test_explain_indexes.sql
-- =============================================================================
-- Objetivo: Demonstrar e comprovar empiricamente o impacto da criação de
-- índices nas consultas mais frequentes e críticas do sistema Renovaí
-- (Spring API, Mobile, Web React e Agentes IA).
--
-- Como executar no psql:
--   psql -h <host> -U <usuario> -d neondb -f tests/test_explain_indexes.sql
--
-- Instruções de Leitura do Plano:
-- - Seq Scan vs Index Scan / Bitmap Index Scan: Varredura sequencial em toda a tabela
--   versus busca direta e logarítmica via árvore B-Tree.
-- - Cost (custo estimado pelo otimizador): unidade arbitrária proporcional a I/O de disco e CPU.
-- - Buffers (shared hit/read): blocos lidos da memória RAM (hit) vs lidos do disco (read).
-- - Execution Time: Tempo real de execução em milissegundos.
-- =============================================================================

\echo '========================================================================'
\echo 'CASO DE TESTE 1: Histórico de Pedidos e Itens por Cooperativa'
\echo 'Filtro: cooperativa_id | Join: pedidos -> pedidos_cooperativas -> pedido_itens'
\echo 'Ordenação: data_pedido DESC'
\echo 'Índices avaliados: idx_pedidos_cooperativas_coop_status, idx_pedido_itens_pedido_id'
\echo '========================================================================'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    p.pedido_id, 
    p.empresa_id, 
    p.data_pedido, 
    pc.status_id, 
    pi.material_id, 
    pi.quantidade_kg
FROM pedidos p
JOIN pedidos_cooperativas pc ON pc.pedido_id = p.pedido_id
JOIN pedido_itens pi ON pi.pedido_id = p.pedido_id
WHERE pc.cooperativa_id = 'ab87b483-01b2-4db3-8c4f-b67085bfa22d'
ORDER BY p.data_pedido DESC;


\echo '========================================================================'
\echo 'CASO DE TESTE 2: Histórico de Coletas Realizadas por Cooperado'
\echo 'Filtro: cooperado_id | Ordenação: data_evento DESC'
\echo 'Índices avaliados: idx_coletas_cooperado_data (B-Tree Composto com DESC)'
\echo '========================================================================'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    c.evento_id, 
    c.cooperado_id, 
    c.data_evento, 
    c.quantidade_kg, 
    c.tipo_coleta
FROM coletas c
WHERE c.cooperado_id = '3703451a-0869-473d-841c-b61c93b4edaa'
ORDER BY c.data_evento DESC;


\echo '========================================================================'
\echo 'CASO DE TESTE 3: Extrato de Movimentações de Estoque (Livro Razão)'
\echo 'Filtro: estoque_id | Ordenação: data_movimentacao DESC'
\echo 'Índices avaliados: idx_movimentacoes_estoque_data (Elimina o operador de SORT)'
\echo '========================================================================'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    me.movimentacao_id, 
    me.estoque_id, 
    me.quantidade_kg, 
    me.tipo_movimentacao, 
    me.data_movimentacao
FROM movimentacoes_estoques me
WHERE me.estoque_id = 'bb6539db-6280-447e-82cf-c9c2426ea771'
ORDER BY me.data_movimentacao DESC;


\echo '========================================================================'
\echo 'CASO DE TESTE 4: Autenticação e Consulta de Colaborador por Usuário'
\echo 'Filtro: usuario_id na tabela funcionarios'
\echo 'Índices avaliados: idx_funcionarios_usuario_id (Foreign Key B-Tree)'
\echo '========================================================================'

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    f.funcionario_id, 
    f.usuario_id, 
    f.cooperativa_id, 
    f.cargo_id, 
    f.status_funcionario
FROM funcionarios f
WHERE f.usuario_id = 'a8b89607-3ad2-4dc1-9bd8-256ecedae36d';
