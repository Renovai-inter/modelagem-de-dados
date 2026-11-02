-- =============================================================================
-- RENOVAÍ — SCHEMA PostgreSQL
-- SCRIPT: CHAVES ESTRANGEIRAS (Relacionamentos)
-- =============================================================================

-- Categoria pai autorreferenciada
ALTER TABLE categorias_materiais
    ADD CONSTRAINT fk_categorias_pai FOREIGN KEY (categoria_pai_id) REFERENCES categorias_materiais(categoria_id);

-- Materiais -> Categorias, cooperativa
ALTER TABLE materiais
    ADD CONSTRAINT fk_materiais_categorias FOREIGN KEY (categoria_id) REFERENCES categorias_materiais(categoria_id),
    ADD CONSTRAINT fk_materiais_cooperativa FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id);

-- Empresa Materiais Interesse -> Empresas, Categorias Materiais
ALTER TABLE empresa_materiais_interesses
    ADD CONSTRAINT fk_empresa_materiais_interesses_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    ADD CONSTRAINT fk_empresa_materiais_interesses_material FOREIGN KEY (categoria_id) REFERENCES categorias_materiais(categoria_id);

-- Empresa Cooperativas Favoritas -> Empresas, Cooperativas
ALTER TABLE empresa_cooperativas_favoritas
    ADD CONSTRAINT fk_empresa_cooperativas_favoritas_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    ADD CONSTRAINT fk_empresa_cooperativas_favoritas_cooperativa FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id);

-- Perfis -> Empresas, Cooperativas e Endereços
ALTER TABLE perfis
    ADD CONSTRAINT fk_perfis_empresas FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    ADD CONSTRAINT fk_perfis_cooperativas FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id),
    ADD CONSTRAINT fk_perfis_enderecos FOREIGN KEY (endereco_id) REFERENCES enderecos(endereco_id);

-- Funcionarios -> Usuarios, Cooperativas e Cargos
ALTER TABLE funcionarios
    ADD CONSTRAINT fk_funcionarios_usuarios FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    ADD CONSTRAINT fk_funcionarios_cooperativas FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id),
    ADD CONSTRAINT fk_funcionarios_cargos FOREIGN KEY (cargo_id) REFERENCES cargos(cargo_id);

-- Telefones -> Perfis e Usuarios
ALTER TABLE telefones
    ADD CONSTRAINT fk_telefones_perfis FOREIGN KEY (perfil_id) REFERENCES perfis(perfil_id),
    ADD CONSTRAINT fk_telefones_usuarios FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id);

-- Equipes -> Cooperativas e Funcionarios (Gestor)
ALTER TABLE equipes
    ADD CONSTRAINT fk_equipes_gestores FOREIGN KEY (gestor_id) REFERENCES funcionarios(funcionario_id);

-- Equipe Cooperados -> Equipes e Funcionarios
ALTER TABLE equipes_cooperados
    ADD CONSTRAINT fk_equipes_cooperados_equipes FOREIGN KEY (equipe_id) REFERENCES equipes(equipe_id),
    ADD CONSTRAINT fk_equipes_cooperados_funcionarios FOREIGN KEY (cooperado_id) REFERENCES funcionarios(funcionario_id);

-- Pedidos -> Empresas
ALTER TABLE pedidos
    ADD CONSTRAINT fk_pedidos_empresas FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id);

-- pedido_itens -> Pedidos e Materiais
ALTER TABLE pedido_itens
    ADD CONSTRAINT fk_pedido_itens_pedidos FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id),
    ADD CONSTRAINT fk_pedido_itens_materiais FOREIGN KEY (material_id) REFERENCES materiais(material_id);

-- Pedidos Cooperativas -> Pedidos, Cooperativas e Status
ALTER TABLE pedidos_cooperativas
    ADD CONSTRAINT fk_pedidos_coop_pedidos FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id),
    ADD CONSTRAINT fk_pedidos_coop_cooperativas FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id),
    ADD CONSTRAINT fk_pedidos_coop_status FOREIGN KEY (status_id) REFERENCES status(status_id);

-- Negociações -> Pedidos, Cooperativas, Empresas, Status
ALTER TABLE negociacoes
    ADD CONSTRAINT fk_negociacoes_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id),
    ADD CONSTRAINT fk_negociacoes_cooperativa FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id),
    ADD CONSTRAINT fk_negociacoes_empresa FOREIGN KEY (empresa_id) REFERENCES empresas(empresa_id),
    ADD CONSTRAINT fk_negociacoes_status FOREIGN KEY (status_id) REFERENCES status(status_id);

-- Negociação Itens -> Negociações, Materiais
ALTER TABLE negociacao_itens
    ADD CONSTRAINT fk_negociacao_itens_negociacao FOREIGN KEY (negociacao_id) REFERENCES negociacoes(negociacao_id),
    ADD CONSTRAINT fk_negociacao_itens_material FOREIGN KEY (material_id) REFERENCES materiais(material_id);

-- Negociação Mensagens -> Negociações, Perfis
ALTER TABLE negociacao_mensagens
    ADD CONSTRAINT fk_negociacao_mensagens_negociacao FOREIGN KEY (negociacao_id) REFERENCES negociacoes(negociacao_id),
    ADD CONSTRAINT fk_negociacao_mensagens_remetente FOREIGN KEY (remetente_id) REFERENCES perfis(perfil_id);

-- Avaliacoes -> Perfis (Avaliador, Avaliado) e Pedidos
ALTER TABLE avaliacoes
    ADD CONSTRAINT fk_avaliacoes_avaliador FOREIGN KEY (avaliador_id) REFERENCES perfis(perfil_id),
    ADD CONSTRAINT fk_avaliacoes_avaliado FOREIGN KEY (avaliado_id) REFERENCES perfis(perfil_id),
    ADD CONSTRAINT fk_avaliacoes_pedidos FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id);

-- Eventos Operacionais -> Status
ALTER TABLE eventos_operacionais
    ADD CONSTRAINT fk_eventos_status FOREIGN KEY (status_id) REFERENCES status(status_id);

-- Coletas (Herdada) -> Funcionarios (Cooperados), Rotas
-- Nota: Chaves estrangeiras que apontam de tabelas filhas para tabelas externas do sistema
-- devem ser criadas explicitamente na tabela filha no PostgreSQL.
ALTER TABLE coletas
    ADD CONSTRAINT fk_coletas_cooperados FOREIGN KEY (cooperado_id) REFERENCES funcionarios(funcionario_id),
    ADD CONSTRAINT fk_coletas_status FOREIGN KEY (status_id) REFERENCES status(status_id),
    ADD CONSTRAINT fk_coletas_rotas FOREIGN KEY (rota_id) REFERENCES rotas(rota_id);

-- Estoques -> Cooperativas e Materiais
ALTER TABLE estoques
    ADD CONSTRAINT fk_estoques_cooperativas FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id),
    ADD CONSTRAINT fk_estoques_materiais FOREIGN KEY (material_id) REFERENCES materiais(material_id);

-- Triagens (Herdada) -> Equipes, Coletas, Materiais e Status
ALTER TABLE triagens
    ADD CONSTRAINT fk_triagens_equipes FOREIGN KEY (equipe_id) REFERENCES equipes(equipe_id),
    -- Aponta para a PK herdada na tabela filha 'coletas'
    ADD CONSTRAINT fk_triagens_coletas FOREIGN KEY (coleta_id) REFERENCES coletas(evento_id),
    ADD CONSTRAINT fk_triagens_materiais FOREIGN KEY (material_id) REFERENCES materiais(material_id),
    ADD CONSTRAINT fk_triagens_status FOREIGN KEY (status_id) REFERENCES status(status_id);

-- Movimentacoes Estoques -> Estoques, Triagens e pedido_itens
ALTER TABLE movimentacoes_estoques
    ADD CONSTRAINT fk_movimentacoes_estoques FOREIGN KEY (estoque_id) REFERENCES estoques(estoque_id),
    ADD CONSTRAINT fk_movimentacoes_triagens FOREIGN KEY (triagem_id) REFERENCES triagens(evento_id),
    ADD CONSTRAINT fk_movimentacoes_pedido_itens FOREIGN KEY (item_id) REFERENCES pedido_itens(item_id);

-- Rateios -> Funcionarios (Gestor) e Tipos de Rateio
ALTER TABLE rateios
    ADD CONSTRAINT fk_rateios_gestores FOREIGN KEY (gestor_id) REFERENCES funcionarios(funcionario_id),
    ADD CONSTRAINT fk_rateios_tipos FOREIGN KEY (tipo_rateio_id) REFERENCES tipos_rateios(tipo_rateio_id);

-- Rateios Funcionarios -> Rateios e Funcionarios (Cooperados)
ALTER TABLE rateios_funcionarios
    ADD CONSTRAINT fk_rateios_func_rateios FOREIGN KEY (rateio_id) REFERENCES rateios(rateio_id),
    ADD CONSTRAINT fk_rateios_func_cooperados FOREIGN KEY (cooperado_id) REFERENCES funcionarios(funcionario_id);

-- Despesas -> Cooperativas
ALTER TABLE despesas
    ADD CONSTRAINT fk_despesas_cooperativa FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id);

-- Lançamentos Despesas -> Despesas
ALTER TABLE lancamentos_despesas
    ADD CONSTRAINT fk_lancamentos_despesas_despesa FOREIGN KEY (despesa_id) REFERENCES despesas(despesa_id);

-- Rotas -> Cooperativas
ALTER TABLE rotas
    ADD CONSTRAINT fk_rotas_cooperativa FOREIGN KEY (cooperativa_id) REFERENCES cooperativas(cooperativa_id);

-- Rotas Enderecos -> Rotas, Enderecos
ALTER TABLE rotas_enderecos
    ADD CONSTRAINT fk_rotas_enderecos_rota FOREIGN KEY (rota_id) REFERENCES rotas(rota_id),
    ADD CONSTRAINT fk_rotas_enderecos_endereco FOREIGN KEY (endereco_id) REFERENCES enderecos(endereco_id);