-- =============================================================================
-- RENOVAÍ — SCRIPT DE INICIALIZAÇÃO DO BANCO DE DADOS
-- =============================================================================

\echo '--> 1. Criando tabelas e schema...'
\i schema/tables.sql
\i schema/auditoria_logs.sql
\i schema/metricas_dau.sql

\echo '--> 2. Aplicando foreign keys...'
\i schema/foreign_keys.sql

\echo '--> 2.1. Criando índices de performance...'
\i schema/indexes.sql

\echo '--> 3. Criando funções...'
\i programmability/functions/fn_auditoria_universal.sql
\i programmability/functions/fn_calcular_media_avaliacoes.sql
\i programmability/functions/fn_calcular_numero_cooperados.sql
\i programmability/functions/fn_calcular_quantidade_rejeito_kg.sql
\i programmability/functions/fn_calcular_rateio_automatico.sql
\i programmability/functions/fn_calcular_total_acumulado.sql
\i programmability/functions/fn_calcular_total_liquido.sql
\i programmability/functions/fn_normalizar_mes_referencia.sql
\i programmability/functions/fn_sincronizar_numero_cooperados.sql
\i programmability/functions/fn_sincronizar_saldo_estoque.sql
\i programmability/functions/fn_sincronizar_status_pedido_cooperativa.sql
\i programmability/functions/fn_total_kg_por_categoria.sql
\i programmability/functions/fn_validar_cooperativa_funcionarios.sql
\i programmability/functions/fn_validar_material_estoque.sql
\i programmability/functions/fn_validar_material_item.sql
\i programmability/functions/fn_validar_material_triagem.sql
\i programmability/functions/fn_verificar_disponibilidade_estoque.sql

\echo '--> 4. Criando stored procedures...'
\i programmability/procedures/sp_aceitar_pedido_cooperativa.sql
\i programmability/procedures/sp_fechar_rateio_mensal.sql
\i programmability/procedures/sp_registrar_movimentacao_triagem.sql
\i programmability/procedures/sp_fechar_negociacao.sql

\echo '--> 5. Criando triggers...'
\i programmability/triggers/trg_auditoria_universal.sql
\i programmability/triggers/trg_normalizar_mes_referencia.sql
\i programmability/triggers/trg_sincronizar_numero_cooperados.sql
\i programmability/triggers/trg_sincronizar_saldo_estoque.sql
\i programmability/triggers/trg_sincronizar_status_pedido_cooperativa.sql
\i programmability/triggers/trg_validar_cooperativa_funcionario.sql
\i programmability/triggers/trg_validar_material_estoque.sql
\i programmability/triggers/trg_validar_material_item.sql
\i programmability/triggers/trg_validar_material_triagem.sql

\echo '--> 6. Criando views...'
\i programmability/views/dimensions/vw_dim_categoria_macro.sql
\i programmability/views/dimensions/vw_dim_cooperativa.sql
\i programmability/views/dimensions/vw_dim_empresa.sql
\i programmability/views/dimensions/vw_dim_equipe.sql
\i programmability/views/dimensions/vw_dim_material.sql
\i programmability/views/dimensions/vw_dim_pedido.sql
\i programmability/views/dimensions/vw_dim_subcategoria.sql
\i programmability/views/dimensions/vw_dim_tempo.sql
\i programmability/views/facts/vw_fato_metricas_mensais.sql
\i programmability/views/facts/vw_fato_movimentacoes_estoque.sql
\i programmability/views/facts/vw_fato_rendimento_coleta_triagem.sql
\i programmability/views/facts/vw_fato_triagens.sql
\i programmability/views/facts/vw_fato_vendas.sql
\i programmability/views/facts/vw_fato_negociacoes.sql
\i programmability/views/facts/vw_fato_avaliacoes.sql
\i programmability/views/facts/vw_fato_ranking_cooperativas_materiais.sql
\i programmability/views/facts/vw_analitica_desempenho_equipes_triagem.sql
\i programmability/views/facts/vw_analitica_fluxo_coleta_anomalias.sql
\i programmability/views/facts/vw_analitica_curva_abc_materiais.sql
\i programmability/views/facts/vw_analitica_segmentacao_empresas_rfv.sql
\i programmability/views/facts/vw_analitica_saude_financeira_rateio_esg.sql
\i programmability/views/facts/vw_analitica_estoque_cobertura_giro.sql

\echo '--> 6.1. Aplicando DCL, Roles e Controle de Acesso...'
\i schema/seguranca_roles_dcl.sql

\echo '--> 6.2. Ativando Criptografia (pgcrypto) e Row-Level Security (RLS)...'
\i schema/seguranca_rls.sql

\echo '--> 7. Inserindo dados iniciais...'
\i data/seed_dados_referencia.sql
\i data/insert_nova_cooperativa_completa.sql

\echo '--> BANCO DE DADOS INICIALIZADO COM SUCESSO!'
