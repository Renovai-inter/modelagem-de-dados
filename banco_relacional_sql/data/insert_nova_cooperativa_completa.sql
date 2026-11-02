-- =============================================================================
-- RENOVAÍ — SCRIPT SQL: CARGA COMPLETA PONTA A PONTA DE UMA NOVA COOPERATIVA
-- =============================================================================
-- Este script realiza o insert completo de uma nova cooperativa com todos os
-- campos preenchidos (inclusive nullables), respeitando triggers, FKs, restrições
-- de integridade (CHECKs) e regras de negócio:
--
-- 1.  Endereço e Perfil 1:1 da Cooperativa (com telefone e CNPJ)
-- 2.  Empresas Parceiras (endereços, perfis, telefones, favoritos e interesses)
-- 3.  Materiais Genéricos e Material Exclusivo da Cooperativa
-- 4.  Estoques Iniciais da Cooperativa
-- 5.  52 Funcionários (1 Gestor, 2 Motoristas, 1 Admin e 48 Cooperados)
--     - Telefones individuais para cada um
--     - Histórico de admissão, status ATIVO/AFASTADO/INATIVO
--     - Sincronização automática de numero_cooperados via trigger
-- 6.  3 Equipes operacionais com vinculação de cooperados (equipes_cooperados)
-- 7.  3 Rotas logísticas com 12 Pontos de Coleta (rotas_enderecos)
-- 8.  105 Coletas ao longo de 2026 até hoje (01/11/2026) e agendadas para o futuro
-- 9.  230 Triagens (mais de um material triado para cada coleta realizada)
-- 10. Movimentações de estoque de entrada automáticas para cada triagem
-- 11. 70 Pedidos vinculados (52 Aceitos, 10 Recusados, 5 Em Negociação, 3 Abertos)
-- 12. Itens de Pedido e saídas de estoque para pedidos aceitos
-- 13. Negociações completas (itens de negociação e mensagens de chat)
-- 14. Avaliações mútuas entre empresas parceiras e a cooperativa
-- 15. Despesas e 50 lançamentos mensais de despesas (Janeiro a Outubro de 2026)
-- 16. Rateios mensais (10 rateios) e 510 distribuições em rateios_funcionarios
-- 17. Monitoramento de atividade diária de usuários (DAU)
-- =============================================================================

DO $$
DECLARE
    -- Variáveis de aleatoriedade para garantir unicidade em re-execuções
    v_rnd_prefix_cpf VARCHAR(3) := to_char(100 + floor(random() * 899)::int, 'FM000');
    v_rnd_mid_cpf    VARCHAR(3) := to_char(100 + floor(random() * 899)::int, 'FM000');
    v_rnd_hash       VARCHAR(6) := substring(replace(gen_random_uuid()::text, '-', ''), 1, 6);

    -- Cargos
    v_cargo_cooperado_id   UUID;
    v_cargo_gestor_id      UUID;
    v_cargo_motorista_id   UUID;
    v_cargo_admin_id       UUID;
    
    -- Status
    v_status_ped_aberto_id     UUID;
    v_status_ped_aceito_id     UUID;
    v_status_ped_recusado_id   UUID;
    v_status_ped_negociacao_id UUID;
    v_status_ped_finalizado_id UUID;
    
    v_status_col_pendente_id UUID;
    v_status_col_agendada_id UUID;
    v_status_col_coletado_id UUID;
    
    v_status_tria_em_andamento_id UUID;
    v_status_tria_concluido_id    UUID;
    
    v_status_neg_andamento_id UUID;
    v_status_neg_fechado_id   UUID;
    v_status_neg_recusado_id  UUID;
    
    v_tipo_rateio_auto_id UUID;
    
    -- Nova Cooperativa
    v_coop_id              UUID := gen_random_uuid();
    v_end_coop_id          UUID := gen_random_uuid();
    v_perfil_coop_id       UUID := gen_random_uuid();
    v_tel_coop_id          UUID := gen_random_uuid();
    
    -- Gestor, Motoristas e Admin
    v_gestor_usr_id        UUID := gen_random_uuid();
    v_gestor_func_id       UUID := gen_random_uuid();
    v_motorista1_usr_id    UUID := gen_random_uuid();
    v_motorista1_func_id   UUID := gen_random_uuid();
    v_motorista2_usr_id    UUID := gen_random_uuid();
    v_motorista2_func_id   UUID := gen_random_uuid();
    v_admin_usr_id         UUID := gen_random_uuid();
    v_admin_func_id        UUID := gen_random_uuid();
    
    -- Equipes
    v_equipe_alfa_id       UUID := gen_random_uuid();
    v_equipe_beta_id       UUID := gen_random_uuid();
    v_equipe_gama_id       UUID := gen_random_uuid();
    v_equipes_ids          UUID[];
    
    -- Rotas
    v_rota1_id             UUID := gen_random_uuid();
    v_rota2_id             UUID := gen_random_uuid();
    v_rota3_id             UUID := gen_random_uuid();
    v_rotas_ids            UUID[];
    
    -- Empresas parceiras
    v_empresa1_id          UUID := gen_random_uuid();
    v_empresa2_id          UUID := gen_random_uuid();
    v_empresa3_id          UUID := gen_random_uuid();
    v_empresa4_id          UUID := gen_random_uuid();
    v_empresas_ids         UUID[];
    v_perfis_empresas_ids  UUID[];
    
    -- Materiais e estoques
    v_mat_genericos_ids    UUID[] := ARRAY[]::UUID[];
    v_mat_especifico_id    UUID := gen_random_uuid();
    v_cat_plastico_id      UUID;
    v_cat_papel_id         UUID;
    v_cat_metal_id         UUID;
    v_cat_vidro_id         UUID;
    
    -- Coleções e variáveis de iteração
    v_cooperados_ativos_ids UUID[] := ARRAY[]::UUID[];
    v_coletores_ids         UUID[] := ARRAY[]::UUID[];
    
    i INTEGER;
    c INTEGER;
    p INTEGER;
    m INTEGER;
    d INTEGER;
    r INTEGER;
    
    v_uid UUID;
    v_fid UUID;
    v_end_id UUID;
    v_perf_id UUID;
    v_tel_id UUID;
    
    v_coleta_id UUID;
    v_data_coleta TIMESTAMP;
    v_status_coleta UUID;
    v_coletor_id UUID;
    v_rota_escolhida UUID;
    v_tipo_col VARCHAR(30);
    v_qtd_col NUMERIC(10,3);
    
    v_triagem_id UUID;
    v_mat_triagem UUID;
    v_qtd_triada NUMERIC(10,3);
    v_qtd_rejeito NUMERIC(10,3);
    v_est_id UUID;
    
    v_pedido_id UUID;
    v_data_pedido TIMESTAMP;
    v_data_conclusao TIMESTAMP;
    v_emp_id UUID;
    v_emp_perf_id UUID;
    v_status_ped UUID;
    v_item1_id UUID;
    v_item2_id UUID;
    v_qtd_item1 NUMERIC(10,3);
    v_qtd_item2 NUMERIC(10,3);
    v_preco1 NUMERIC(10,2);
    v_preco2 NUMERIC(10,2);
    v_neg_id UUID;
    
    v_despesa_id UUID;
    v_despesa_ids UUID[] := ARRAY[]::UUID[];
    v_mes_ref DATE;
    v_rateio_id UUID;
    
    -- Nomes verossímeis para cooperados
    v_nomes_cooperados TEXT[] := ARRAY[
        'Ana Paula Souza', 'Bruno Henrique Alves', 'Camila Cristina Dias', 'Daniel Oliveira Ramos',
        'Eliana Maria Santos', 'Fabio Junior Pereira', 'Gabriela Ribeiro Silva', 'Hugo Leonardo Martins',
        'Isabela Ferreira Lima', 'Joao Vitor Rocha', 'Katia Cilene Barbosa', 'Lucas Gabriel Costa',
        'Mariana Freitas Cardoso', 'Nelson Tadeu Moreira', 'Otavio Augusto Mendes', 'Patricia Helena Castro',
        'Renato Augusto Carvalho', 'Sandra Regina Duarte', 'Thiago Henrique Nunes', 'Valeria Aparecida Pires',
        'Wagner Luis Santana', 'Aline Caroline Azevedo', 'Caio Vinicius Teixeira', 'Debora Tatiana Campos',
        'Edson Wanderley Barros', 'Fatima Conceicao Moraes', 'Gilberto Gilmar Peixoto', 'Helena Maria Brandao',
        'Igor Matheus Viana', 'Juliana Cristina Farias', 'Leandro Marcio Guedes', 'Monica Sueli Macedo',
        'Nilson Roberto Batista', 'Orlando Cesar Rezende', 'Priscila Renata Cunha', 'Ricardo Alexandre Antunes',
        'Silvia Leticia Guimaraes', 'Tania Mara Prado', 'Ubiratan Jose Silveira', 'Vanessa Roberta Toledo',
        'Wilson Roberto Bueno', 'Zuleica Maria Figueira', 'Arthur Felipe Vasconcelos', 'Beatriz Eduarda Porto',
        'Cristiano Ronaldo Neves', 'Daniele Cristina Miranda', 'Elias Manoel Nogueira', 'Flavia Alessandra Borges'
    ];
BEGIN
    RAISE NOTICE '========================================================================';
    RAISE NOTICE 'INICIANDO CARGA COMPLETA DA NOVA COOPERATIVA NO RENOVAÍ';
    RAISE NOTICE '========================================================================';

    -- -------------------------------------------------------------------------
    -- 1. ASSEGURAR DADOS DE REFERÊNCIA (IDEMPOTENTE)
    -- -------------------------------------------------------------------------
    INSERT INTO cargos (cargo) VALUES ('Cooperado'), ('Gestor'), ('Admin'), ('motorista')
    ON CONFLICT (cargo) DO NOTHING;
    
    SELECT cargo_id INTO v_cargo_cooperado_id FROM cargos WHERE LOWER(cargo) = 'cooperado' LIMIT 1;
    SELECT cargo_id INTO v_cargo_gestor_id    FROM cargos WHERE LOWER(cargo) = 'gestor' LIMIT 1;
    SELECT cargo_id INTO v_cargo_motorista_id FROM cargos WHERE LOWER(cargo) = 'motorista' LIMIT 1;
    SELECT cargo_id INTO v_cargo_admin_id     FROM cargos WHERE LOWER(cargo) = 'admin' LIMIT 1;
    
    SELECT status_id INTO v_status_ped_aberto_id     FROM status WHERE referencia = 'PEDIDO' AND status_atual = 'Aberto';
    SELECT status_id INTO v_status_ped_aceito_id     FROM status WHERE referencia = 'PEDIDO' AND status_atual = 'Aceito';
    SELECT status_id INTO v_status_ped_recusado_id   FROM status WHERE referencia = 'PEDIDO' AND status_atual = 'Recusado';
    SELECT status_id INTO v_status_ped_negociacao_id FROM status WHERE referencia = 'PEDIDO' AND status_atual = 'Em negociação';
    SELECT status_id INTO v_status_ped_finalizado_id FROM status WHERE referencia = 'PEDIDO' AND status_atual = 'Finalizado';
    
    SELECT status_id INTO v_status_col_pendente_id FROM status WHERE referencia = 'COLETA' AND status_atual = 'Pendente';
    SELECT status_id INTO v_status_col_agendada_id FROM status WHERE referencia = 'COLETA' AND status_atual = 'Agendada';
    SELECT status_id INTO v_status_col_coletado_id FROM status WHERE referencia = 'COLETA' AND status_atual = 'Coletado';
    
    SELECT status_id INTO v_status_tria_em_andamento_id FROM status WHERE referencia = 'TRIAGEM' AND status_atual = 'Em triagem';
    SELECT status_id INTO v_status_tria_concluido_id    FROM status WHERE referencia = 'TRIAGEM' AND status_atual = 'Concluído';
    
    SELECT status_id INTO v_status_neg_andamento_id FROM status WHERE referencia = 'NEGOCIACAO' AND status_atual = 'Em andamento';
    SELECT status_id INTO v_status_neg_fechado_id   FROM status WHERE referencia = 'NEGOCIACAO' AND status_atual = 'Acordo fechado';
    SELECT status_id INTO v_status_neg_recusado_id  FROM status WHERE referencia = 'NEGOCIACAO' AND status_atual = 'Negociação recusada';
    
    SELECT tipo_rateio_id INTO v_tipo_rateio_auto_id FROM tipos_rateios WHERE tipo_rateio = 'AUTOMATICO' LIMIT 1;
    
    SELECT categoria_id INTO v_cat_plastico_id FROM categorias_materiais WHERE nome_categoria = 'Plástico' LIMIT 1;
    SELECT categoria_id INTO v_cat_papel_id    FROM categorias_materiais WHERE nome_categoria = 'Papel' LIMIT 1;
    SELECT categoria_id INTO v_cat_metal_id    FROM categorias_materiais WHERE nome_categoria = 'Metal' LIMIT 1;
    SELECT categoria_id INTO v_cat_vidro_id    FROM categorias_materiais WHERE nome_categoria = 'Vidro' LIMIT 1;
    
    -- Obter 5 materiais genéricos para pedidos e triagens (cooperativa_id IS NULL)
    SELECT ARRAY_AGG(material_id) INTO v_mat_genericos_ids
    FROM (
        SELECT material_id FROM materiais WHERE cooperativa_id IS NULL ORDER BY material_id LIMIT 5
    ) sub;
    
    IF array_length(v_mat_genericos_ids, 1) IS NULL OR array_length(v_mat_genericos_ids, 1) < 5 THEN
        INSERT INTO materiais (categoria_id, cooperativa_id, imagem_url, preco_sugerido, esta_disponivel)
        VALUES 
            (COALESCE(v_cat_plastico_id, gen_random_uuid()), NULL, 'https://storage.renovai.com.br/materiais/pet.jpg', 3.50, TRUE),
            (COALESCE(v_cat_papel_id, gen_random_uuid()), NULL, 'https://storage.renovai.com.br/materiais/papelao.jpg', 1.80, TRUE),
            (COALESCE(v_cat_metal_id, gen_random_uuid()), NULL, 'https://storage.renovai.com.br/materiais/aluminio.jpg', 5.50, TRUE),
            (COALESCE(v_cat_vidro_id, gen_random_uuid()), NULL, 'https://storage.renovai.com.br/materiais/vidro.jpg', 2.20, TRUE),
            (COALESCE(v_cat_plastico_id, gen_random_uuid()), NULL, 'https://storage.renovai.com.br/materiais/pead.jpg', 4.10, TRUE);
            
        SELECT ARRAY_AGG(material_id) INTO v_mat_genericos_ids
        FROM (SELECT material_id FROM materiais WHERE cooperativa_id IS NULL ORDER BY material_id LIMIT 5) sub;
    END IF;

    -- -------------------------------------------------------------------------
    -- 2. NOVA COOPERATIVA (COM TODOS OS CAMPOS PREENCHIDOS)
    -- -------------------------------------------------------------------------
    INSERT INTO enderecos (endereco_id, cep, logradouro, numero, complemento, bairro, cidade, tipo)
    VALUES (
        v_end_coop_id, '03107-002', 'Avenida Presidente Wilson', '1800', 
        'Galpão Operacional 3 e Pátio B', 'Mooca', 'São Paulo', 'Comercial'
    );
    
    INSERT INTO cooperativas (
        cooperativa_id, nome, imagem_url, descricao, contato_preferencial, 
        horario_funcionamento, numero_cooperados, data_atualizacao
    ) VALUES (
        v_coop_id, 
        'Cooperativa Renova Circular Brasil ' || v_rnd_hash, 
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80',
        'Cooperativa modelo de gestão compartilhada, logística reversa e valorização socioambiental de catadores e cooperados na Região Metropolitana de São Paulo.',
        'WHATSAPP',
        'Segunda a Sexta das 07:00 às 17:30 e Sábados das 08:00 às 13:00',
        0, -- Mantido automaticamente pela trigger trg_sincronizar_numero_cooperados
        '2026-01-02 08:00:00'
    );
    
    INSERT INTO perfis (
        perfil_id, empresa_id, cooperativa_id, endereco_id, email, cnpj, 
        senha_hash, token_redefinicao, data_criacao, data_token_expiracao, esta_ativo
    ) VALUES (
        v_perfil_coop_id, NULL, v_coop_id, v_end_coop_id,
        'contato@renovacircular_' || v_rnd_hash || '.coop.br',
        to_char(10 + floor(random()*80)::int, 'FM00') || '.' || to_char(100 + floor(random()*899)::int, 'FM000') || '.' || to_char(100 + floor(random()*899)::int, 'FM000') || '/0001-' || to_char(10 + floor(random()*89)::int, 'FM00'),
        '$2b$12$K8yP.Y6/qP6qjX20zFp1he4F9O6b5N1P.5Q5w3dZ0m1.8zY4w6K1e',
        'tok_reset_coop_' || v_rnd_hash,
        '2025-11-20 09:00:00',
        '2026-12-31 23:59:59',
        TRUE
    );
    
    INSERT INTO telefones (telefone_id, perfil_id, usuario_id, ddd, telefone)
    VALUES (v_tel_coop_id, v_perfil_coop_id, NULL, '11', '99876-' || to_char(1000 + floor(random()*8999)::int, 'FM0000'));
    
    -- Material exclusivo da cooperativa
    INSERT INTO materiais (material_id, categoria_id, cooperativa_id, imagem_url, preco_sugerido, esta_disponivel)
    VALUES (
        v_mat_especifico_id, COALESCE(v_cat_plastico_id, v_mat_genericos_ids[1]), v_coop_id,
        'https://storage.renovai.com.br/materiais/pp_moido_renova.jpg', 4.80, TRUE
    );

    -- Saldo inicial de estoques da cooperativa
    FOR i IN 1..5 LOOP
        INSERT INTO estoques (estoque_id, cooperativa_id, material_id, quantidade_kg, data_atualizacao)
        VALUES (gen_random_uuid(), v_coop_id, v_mat_genericos_ids[i], 5000.000, '2026-01-02 08:00:00');
    END LOOP;
    
    INSERT INTO estoques (estoque_id, cooperativa_id, material_id, quantidade_kg, data_atualizacao)
    VALUES (gen_random_uuid(), v_coop_id, v_mat_especifico_id, 3000.000, '2026-01-02 08:00:00');

    -- -------------------------------------------------------------------------
    -- 3. EMPRESAS PARCEIRAS, PERFIS E INTERESSES
    -- -------------------------------------------------------------------------
    FOR i IN 1..4 LOOP
        v_emp_id := gen_random_uuid();
        v_end_id := gen_random_uuid();
        v_perf_id := gen_random_uuid();
        v_tel_id := gen_random_uuid();
        
        INSERT INTO enderecos (endereco_id, cep, logradouro, numero, complemento, bairro, cidade, tipo)
        VALUES (
            v_end_id, '04571-0' || to_char(10 + i, 'FM00'), 
            CASE i 
                WHEN 1 THEN 'Rua dos Polímeros Reciclados'
                WHEN 2 THEN 'Avenida das Indústrias Metalúrgicas'
                WHEN 3 THEN 'Alameda da Celulose e Embalagens'
                ELSE 'Rodovia dos Vidros Sustentáveis'
            END,
            to_char(100 * i + 45, 'FM9999'), 'Complexo Industrial ' || i, 'Distrito Industrial', 'São Paulo', 'Comercial'
        );
        
        INSERT INTO empresas (empresa_id, nome, imagem_url, descricao)
        VALUES (
            v_emp_id,
            CASE i
                WHEN 1 THEN 'EcoPolímeros Indústria de Embalagens Sustentáveis S.A. ' || v_rnd_hash
                WHEN 2 THEN 'Siderúrgica Alumínio Paulista Ltda ' || v_rnd_hash
                WHEN 3 THEN 'BioCelulose & Embalagens Kraft S.A. ' || v_rnd_hash
                ELSE 'Vidros Sustentáveis do Brasil S.A. ' || v_rnd_hash
            END,
            'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=800&q=80',
            'Empresa compradora de matérias-primas secundárias com metas de ESG e rastreabilidade ambiental.'
        );
        
        INSERT INTO perfis (
            perfil_id, empresa_id, cooperativa_id, endereco_id, email, cnpj, 
            senha_hash, token_redefinicao, data_criacao, data_token_expiracao, esta_ativo
        ) VALUES (
            v_perf_id, v_emp_id, NULL, v_end_id,
            'compras.empresa' || i || '_' || v_rnd_hash || '@industria.com.br',
            to_char(10 + floor(random()*80)::int, 'FM00') || '.' || to_char(100 + floor(random()*899)::int, 'FM000') || '.' || to_char(100 + floor(random()*899)::int, 'FM000') || '/0001-' || to_char(10 + floor(random()*89)::int, 'FM00'),
            '$2b$12$K8yP.Y6/qP6qjX20zFp1he4F9O6b5N1P.5Q5w3dZ0m1.8zY4w6K1e',
            'tok_empresa_reset_' || i || '_' || v_rnd_hash,
            '2025-11-25 10:00:00',
            '2026-12-31 23:59:59',
            TRUE
        );
        
        INSERT INTO telefones (telefone_id, perfil_id, usuario_id, ddd, telefone)
        VALUES (v_tel_id, v_perf_id, NULL, '11', '98' || to_char(1000 + i * 111, 'FM9999') || '-100' || i);
        
        INSERT INTO empresa_cooperativas_favoritas (favorito_id, empresa_id, cooperativa_id, data_criacao)
        VALUES (gen_random_uuid(), v_emp_id, v_coop_id, '2026-01-10 14:00:00');
        
        IF v_cat_plastico_id IS NOT NULL THEN
            INSERT INTO empresa_materiais_interesses (empresa_material_id, empresa_id, categoria_id)
            VALUES (gen_random_uuid(), v_emp_id, v_cat_plastico_id) ON CONFLICT DO NOTHING;
        END IF;
        
        v_empresas_ids := array_append(v_empresas_ids, v_emp_id);
        v_perfis_empresas_ids := array_append(v_perfis_empresas_ids, v_perf_id);
    END LOOP;

    -- -------------------------------------------------------------------------
    -- 4. FUNCIONÁRIOS (52 NO TOTAL: GESTOR, 2 MOTORISTAS, ADMIN, 48 COOPERADOS)
    -- -------------------------------------------------------------------------
    
    -- 4.1 Gestor
    INSERT INTO usuarios (
        usuario_id, nome, email, cpf, senha, senha_hash, token_redefinicao, 
        imagem_url, data_nascimento, ultimo_acesso, data_criacao, data_atualizacao, data_token_expiracao, esta_ativo
    ) VALUES (
        v_gestor_usr_id, 'Carlos Eduardo Menezes Silva', 
        'carlos.gestor_' || v_rnd_hash || '@renovacircular.coop.br',
        v_rnd_prefix_cpf || '.' || v_rnd_mid_cpf || '.101-01',
        'GestorSeguro@2026', '$2b$12$K8yP.Y6/qP6qjX20zFp1he4F9O6b5N1P.5Q5w3dZ0m1.8zY4w6K1e',
        'tok_gestor_pwd_' || v_rnd_hash, 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
        '1982-05-14', '2026-10-31 18:30:00', '2025-12-01 08:00:00', '2026-10-01 10:00:00', '2026-12-31 23:59:59', TRUE
    );
    INSERT INTO telefones (telefone_id, perfil_id, usuario_id, ddd, telefone)
    VALUES (gen_random_uuid(), NULL, v_gestor_usr_id, '11', '98701-' || to_char(1000 + floor(random()*8999)::int, 'FM0000'));
    INSERT INTO funcionarios (funcionario_id, usuario_id, cooperativa_id, cargo_id, data_admissao, status_funcionario)
    VALUES (v_gestor_func_id, v_gestor_usr_id, v_coop_id, v_cargo_gestor_id, '2026-01-02 08:00:00', 'ATIVO');
    v_cooperados_ativos_ids := array_append(v_cooperados_ativos_ids, v_gestor_func_id);

    -- 4.2 Motorista 1
    INSERT INTO usuarios (
        usuario_id, nome, email, cpf, senha, senha_hash, token_redefinicao, 
        imagem_url, data_nascimento, ultimo_acesso, data_criacao, data_atualizacao, data_token_expiracao, esta_ativo
    ) VALUES (
        v_motorista1_usr_id, 'Antônio Marcos Ferreira', 
        'antonio.mot1_' || v_rnd_hash || '@renovacircular.coop.br',
        v_rnd_prefix_cpf || '.' || v_rnd_mid_cpf || '.102-02',
        'Motorista@2026', '$2b$12$K8yP.Y6/qP6qjX20zFp1he4F9O6b5N1P.5Q5w3dZ0m1.8zY4w6K1e',
        'tok_mot1_pwd_' || v_rnd_hash, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
        '1986-09-21', '2026-10-31 17:15:00', '2025-12-05 08:00:00', '2026-09-15 11:00:00', '2026-12-31 23:59:59', TRUE
    );
    INSERT INTO telefones (telefone_id, perfil_id, usuario_id, ddd, telefone)
    VALUES (gen_random_uuid(), NULL, v_motorista1_usr_id, '11', '98702-' || to_char(1000 + floor(random()*8999)::int, 'FM0000'));
    INSERT INTO funcionarios (funcionario_id, usuario_id, cooperativa_id, cargo_id, data_admissao, status_funcionario)
    VALUES (v_motorista1_func_id, v_motorista1_usr_id, v_coop_id, v_cargo_motorista_id, '2026-01-02 08:00:00', 'ATIVO');
    v_coletores_ids := array_append(v_coletores_ids, v_motorista1_func_id);
    v_cooperados_ativos_ids := array_append(v_cooperados_ativos_ids, v_motorista1_func_id);

    -- 4.3 Motorista 2
    INSERT INTO usuarios (
        usuario_id, nome, email, cpf, senha, senha_hash, token_redefinicao, 
        imagem_url, data_nascimento, ultimo_acesso, data_criacao, data_atualizacao, data_token_expiracao, esta_ativo
    ) VALUES (
        v_motorista2_usr_id, 'Benedito da Silva Santos', 
        'benedito.mot2_' || v_rnd_hash || '@renovacircular.coop.br',
        v_rnd_prefix_cpf || '.' || v_rnd_mid_cpf || '.103-03',
        'Motorista@2026', '$2b$12$K8yP.Y6/qP6qjX20zFp1he4F9O6b5N1P.5Q5w3dZ0m1.8zY4w6K1e',
        'tok_mot2_pwd_' || v_rnd_hash, 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
        '1989-11-03', '2026-10-31 16:45:00', '2025-12-10 08:00:00', '2026-09-20 14:00:00', '2026-12-31 23:59:59', TRUE
    );
    INSERT INTO telefones (telefone_id, perfil_id, usuario_id, ddd, telefone)
    VALUES (gen_random_uuid(), NULL, v_motorista2_usr_id, '11', '98703-' || to_char(1000 + floor(random()*8999)::int, 'FM0000'));
    INSERT INTO funcionarios (funcionario_id, usuario_id, cooperativa_id, cargo_id, data_admissao, status_funcionario)
    VALUES (v_motorista2_func_id, v_motorista2_usr_id, v_coop_id, v_cargo_motorista_id, '2026-01-02 08:00:00', 'ATIVO');
    v_coletores_ids := array_append(v_coletores_ids, v_motorista2_func_id);
    v_cooperados_ativos_ids := array_append(v_cooperados_ativos_ids, v_motorista2_func_id);

    -- 4.4 Admin Operacional
    INSERT INTO usuarios (
        usuario_id, nome, email, cpf, senha, senha_hash, token_redefinicao, 
        imagem_url, data_nascimento, ultimo_acesso, data_criacao, data_atualizacao, data_token_expiracao, esta_ativo
    ) VALUES (
        v_admin_usr_id, 'Fernanda Rodrigues Lima', 
        'fernanda.admin_' || v_rnd_hash || '@renovacircular.coop.br',
        v_rnd_prefix_cpf || '.' || v_rnd_mid_cpf || '.104-04',
        'Admin@2026', '$2b$12$K8yP.Y6/qP6qjX20zFp1he4F9O6b5N1P.5Q5w3dZ0m1.8zY4w6K1e',
        'tok_admin_pwd_' || v_rnd_hash, 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
        '1991-07-28', '2026-10-31 17:50:00', '2025-12-12 08:00:00', '2026-10-10 15:00:00', '2026-12-31 23:59:59', TRUE
    );
    INSERT INTO telefones (telefone_id, perfil_id, usuario_id, ddd, telefone)
    VALUES (gen_random_uuid(), NULL, v_admin_usr_id, '11', '98704-' || to_char(1000 + floor(random()*8999)::int, 'FM0000'));
    INSERT INTO funcionarios (funcionario_id, usuario_id, cooperativa_id, cargo_id, data_admissao, status_funcionario)
    VALUES (v_admin_func_id, v_admin_usr_id, v_coop_id, v_cargo_admin_id, '2026-01-02 08:00:00', 'ATIVO');
    v_cooperados_ativos_ids := array_append(v_cooperados_ativos_ids, v_admin_func_id);

    -- 4.5 48 Cooperados
    FOR i IN 1..48 LOOP
        v_uid := gen_random_uuid();
        v_fid := gen_random_uuid();
        
        INSERT INTO usuarios (
            usuario_id, nome, email, cpf, senha, senha_hash, token_redefinicao, 
            imagem_url, data_nascimento, ultimo_acesso, data_criacao, data_atualizacao, data_token_expiracao, esta_ativo
        ) VALUES (
            v_uid, v_nomes_cooperados[i],
            'coop_' || i || '_' || v_rnd_hash || '@renovacircular.coop.br',
            v_rnd_prefix_cpf || '.' || v_rnd_mid_cpf || '.' || to_char(200 + i, 'FM000') || '-' || to_char(10 + (i % 89), 'FM00'),
            'CoopPass@' || (2020 + (i % 6)),
            '$2b$12$K8yP.Y6/qP6qjX20zFp1he4F9O6b5N1P.5Q5w3dZ0m1.8zY4w6K1e',
            'tok_reset_coop_' || i || '_' || v_rnd_hash,
            'https://images.unsplash.com/photo-' || (1500000000000 + i * 12345)::text || '?auto=format&fit=crop&w=400&q=80',
            '1975-01-01'::DATE + ((i * 211) % 8500) * INTERVAL '1 day',
            '2026-10-31 16:00:00'::TIMESTAMP - ((i * 3) % 48) * INTERVAL '1 hour',
            '2025-12-15 08:00:00',
            '2026-10-01 09:00:00',
            '2026-12-31 23:59:59',
            TRUE
        );
        
        INSERT INTO telefones (telefone_id, perfil_id, usuario_id, ddd, telefone)
        VALUES (gen_random_uuid(), NULL, v_uid, '11', '9' || to_char(7000 + i * 13, 'FM0000') || '-' || to_char(1000 + i * 29, 'FM0000'));
        
        INSERT INTO funcionarios (
            funcionario_id, usuario_id, cooperativa_id, cargo_id, 
            data_admissao, data_desligamento, status_funcionario
        ) VALUES (
            v_fid, v_uid, v_coop_id, v_cargo_cooperado_id,
            '2026-01-02 08:00:00',
            CASE WHEN i = 48 THEN '2026-08-31 17:00:00'::TIMESTAMP ELSE NULL END,
            CASE 
                WHEN i = 47 THEN 'AFASTADO'
                WHEN i = 48 THEN 'INATIVO'
                ELSE 'ATIVO'
            END
        );
        
        IF i <= 46 THEN
            v_cooperados_ativos_ids := array_append(v_cooperados_ativos_ids, v_fid);
            v_coletores_ids := array_append(v_coletores_ids, v_fid);
        ELSIF i = 47 THEN
            v_cooperados_ativos_ids := array_append(v_cooperados_ativos_ids, v_fid);
        END IF;
    END LOOP;

    -- -------------------------------------------------------------------------
    -- 5. EQUIPES E VINCULAÇÃO DE COOPERADOS
    -- -------------------------------------------------------------------------
    INSERT INTO equipes (equipe_id, gestor_id, nome, descricao, data_criacao, esta_ativa)
    VALUES 
        (v_equipe_alfa_id, v_gestor_func_id, 'Equipe Alfa - Triagem de Plásticos e Polímeros', 'Responsável pela triagem fina de PET, PEAD, PP e filmes flexíveis.', '2026-01-03 08:00:00', TRUE),
        (v_equipe_beta_id, v_gestor_func_id, 'Equipe Beta - Triagem de Metais e Vidros', 'Responsável pela separação magnética de ferrosos, prensagem de latinhas e vidros.', '2026-01-03 08:00:00', TRUE),
        (v_equipe_gama_id, v_gestor_func_id, 'Equipe Gama - Triagem de Papéis e Celulose', 'Responsável pela classificação de papelão ondulado, papel branco e kraft.', '2026-01-03 08:00:00', TRUE);
        
    v_equipes_ids := ARRAY[v_equipe_alfa_id, v_equipe_beta_id, v_equipe_gama_id];
    
    FOR i IN 1..array_length(v_cooperados_ativos_ids, 1) LOOP
        INSERT INTO equipes_cooperados (equipe_cooperado_id, equipe_id, cooperado_id)
        VALUES (
            gen_random_uuid(), 
            v_equipes_ids[1 + ((i - 1) % 3)],
            v_cooperados_ativos_ids[i]
        );
    END LOOP;

    -- -------------------------------------------------------------------------
    -- 6. ROTAS E PONTOS DE COLETA (ROTAS_ENDERECOS)
    -- -------------------------------------------------------------------------
    INSERT INTO rotas (rota_id, cooperativa_id, nome, esta_ativa)
    VALUES 
        (v_rota1_id, v_coop_id, 'Rota 01 - Eixo Comercial Faria Lima / Berrini / Vila Olímpia', TRUE),
        (v_rota2_id, v_coop_id, 'Rota 02 - Ecopontos e Condomínios Residenciais Zona Sul', TRUE),
        (v_rota3_id, v_coop_id, 'Rota 03 - Polo Industrial Jurubatuba / Santo Amaro', TRUE);
        
    v_rotas_ids := ARRAY[v_rota1_id, v_rota2_id, v_rota3_id];
    
    FOR r IN 1..3 LOOP
        FOR p IN 1..4 LOOP
            v_end_id := gen_random_uuid();
            INSERT INTO enderecos (endereco_id, cep, logradouro, numero, complemento, bairro, cidade, tipo)
            VALUES (
                v_end_id, '045' || to_char(10 + r, 'FM00') || '-' || to_char(100 + p * 20, 'FM000'),
                'Avenida das Nações Unidas', to_char(2000 + r * 500 + p * 80, 'FM99999'),
                'Ponto Operacional ' || p, 'Vila Cordeiro', 'São Paulo', 'Coleta'
            );
            
            INSERT INTO rotas_enderecos (rota_endereco_id, rota_id, endereco_id, nome_local, tipo_local, ordem)
            VALUES (
                gen_random_uuid(), v_rotas_ids[r], v_end_id,
                'Ponto de Coleta ' || p || ' - Rota ' || r, 'Ponto de Coleta Seletiva', p
            );
        END LOOP;
    END LOOP;

    -- -------------------------------------------------------------------------
    -- 7. 105 COLETAS (95 EM 2026 ATÉ HOJE E 10 FUTURAS AGENDADAS) E TRIAGENS
    -- -------------------------------------------------------------------------
    FOR c IN 1..105 LOOP
        v_coleta_id := gen_random_uuid();
        
        IF c <= 92 THEN
            -- Coletadas ao longo de 2026 até o final de Outubro
            v_status_coleta := v_status_col_coletado_id;
            v_data_coleta := '2026-01-08 08:30:00'::TIMESTAMP + ((c - 1) * INTERVAL '3 days 4 hours');
            v_tipo_col := CASE WHEN (c % 7 = 0) THEN 'ENTREGA' ELSE 'EXTERNA' END;
            v_rota_escolhida := CASE WHEN v_tipo_col = 'EXTERNA' THEN v_rotas_ids[1 + (c % 3)] ELSE NULL END;
            v_coletor_id := v_coletores_ids[1 + (c % array_length(v_coletores_ids, 1))];
            v_qtd_col := round(180.000 + ((c * 47) % 650)::numeric + ((c * 13 % 1000)::numeric / 1000.0), 3);
        ELSIF c <= 95 THEN
            -- Pendentes (recente: 28/10, 30/10, 01/11/2026)
            v_status_coleta := v_status_col_pendente_id;
            v_data_coleta := '2026-10-28 09:00:00'::TIMESTAMP + ((c - 93) * INTERVAL '2 days');
            v_tipo_col := 'EXTERNA';
            v_rota_escolhida := v_rotas_ids[1 + (c % 3)];
            v_coletor_id := v_coletores_ids[1 + (c % array_length(v_coletores_ids, 1))];
            v_qtd_col := round(320.000 + (c * 25)::numeric, 3);
        ELSE
            -- Futuras agendadas (04/11/2026 a 18/12/2026)
            v_status_coleta := v_status_col_agendada_id;
            v_data_coleta := '2026-11-04 08:00:00'::TIMESTAMP + ((c - 96) * INTERVAL '4 days 6 hours');
            v_tipo_col := 'EXTERNA';
            v_rota_escolhida := v_rotas_ids[1 + (c % 3)];
            v_coletor_id := v_coletores_ids[1 + (c % array_length(v_coletores_ids, 1))];
            v_qtd_col := round(250.000 + ((c * 33) % 400)::numeric, 3);
        END IF;

        INSERT INTO coletas (
            evento_id, data_evento, status_id, cooperado_id, rota_id, 
            imagem_url, tipo_coleta, quantidade_kg
        ) VALUES (
            v_coleta_id, v_data_coleta, v_status_coleta, v_coletor_id, v_rota_escolhida,
            'https://storage.renovai.com.br/coletas/2026/pesagem_coleta_' || c || '.jpg',
            v_tipo_col, v_qtd_col
        );

        -- Triagens de mais de um material para cada coleta realizada
        IF c <= 92 THEN
            -- Triagem 1: Plástico/PET
            v_triagem_id := gen_random_uuid();
            v_mat_triagem := v_mat_genericos_ids[1];
            v_qtd_triada := round(v_qtd_col * 0.48, 3);
            v_qtd_rejeito := round(v_qtd_col * 0.04, 3);
            
            INSERT INTO triagens (
                evento_id, data_evento, status_id, equipe_id, coleta_id, material_id, 
                imagem_url, quantidade_kg, quantidade_rejeito_kg
            ) VALUES (
                v_triagem_id, v_data_coleta + INTERVAL '3 hours', v_status_tria_concluido_id,
                v_equipes_ids[1], v_coleta_id, v_mat_triagem,
                'https://storage.renovai.com.br/triagens/2026/lote_pet_' || c || '.jpg',
                v_qtd_triada, v_qtd_rejeito
            );
            
            SELECT estoque_id INTO v_est_id FROM estoques WHERE cooperativa_id = v_coop_id AND material_id = v_mat_triagem LIMIT 1;
            INSERT INTO movimentacoes_estoques (movimentacao_id, estoque_id, triagem_id, item_id, quantidade_kg, data_movimentacao)
            VALUES (gen_random_uuid(), v_est_id, v_triagem_id, NULL, v_qtd_triada, v_data_coleta + INTERVAL '3 hours');
            
            -- Triagem 2: Papelão
            v_triagem_id := gen_random_uuid();
            v_mat_triagem := v_mat_genericos_ids[2];
            v_qtd_triada := round(v_qtd_col * 0.38, 3);
            v_qtd_rejeito := round(v_qtd_col * 0.03, 3);
            
            INSERT INTO triagens (
                evento_id, data_evento, status_id, equipe_id, coleta_id, material_id, 
                imagem_url, quantidade_kg, quantidade_rejeito_kg
            ) VALUES (
                v_triagem_id, v_data_coleta + INTERVAL '4 hours', v_status_tria_concluido_id,
                v_equipes_ids[3], v_coleta_id, v_mat_triagem,
                'https://storage.renovai.com.br/triagens/2026/lote_papelao_' || c || '.jpg',
                v_qtd_triada, v_qtd_rejeito
            );
            
            SELECT estoque_id INTO v_est_id FROM estoques WHERE cooperativa_id = v_coop_id AND material_id = v_mat_triagem LIMIT 1;
            INSERT INTO movimentacoes_estoques (movimentacao_id, estoque_id, triagem_id, item_id, quantidade_kg, data_movimentacao)
            VALUES (gen_random_uuid(), v_est_id, v_triagem_id, NULL, v_qtd_triada, v_data_coleta + INTERVAL '4 hours');

            -- Triagem 3: Alumínio (coletas pares)
            IF c % 2 = 0 THEN
                v_triagem_id := gen_random_uuid();
                v_mat_triagem := v_mat_genericos_ids[3];
                v_qtd_triada := round(v_qtd_col * 0.07, 3);
                v_qtd_rejeito := round(v_qtd_col * 0.01, 3);
                
                INSERT INTO triagens (
                    evento_id, data_evento, status_id, equipe_id, coleta_id, material_id, 
                    imagem_url, quantidade_kg, quantidade_rejeito_kg
                ) VALUES (
                    v_triagem_id, v_data_coleta + INTERVAL '5 hours', v_status_tria_concluido_id,
                    v_equipes_ids[2], v_coleta_id, v_mat_triagem,
                    'https://storage.renovai.com.br/triagens/2026/lote_aluminio_' || c || '.jpg',
                    v_qtd_triada, v_qtd_rejeito
                );
                
                SELECT estoque_id INTO v_est_id FROM estoques WHERE cooperativa_id = v_coop_id AND material_id = v_mat_triagem LIMIT 1;
                INSERT INTO movimentacoes_estoques (movimentacao_id, estoque_id, triagem_id, item_id, quantidade_kg, data_movimentacao)
                VALUES (gen_random_uuid(), v_est_id, v_triagem_id, NULL, v_qtd_triada, v_data_coleta + INTERVAL '5 hours');
            END IF;
        END IF;
    END LOOP;

    -- -------------------------------------------------------------------------
    -- 8. 70 PEDIDOS NO TOTAL (52 ACEITOS, 10 RECUSADOS, 5 EM NEGOCIAÇÃO, 3 ABERTOS)
    -- -------------------------------------------------------------------------
    FOR p IN 1..70 LOOP
        v_pedido_id := gen_random_uuid();
        v_emp_id := v_empresas_ids[1 + (p % 4)];
        v_emp_perf_id := v_perfis_empresas_ids[1 + (p % 4)];
        v_data_pedido := '2026-01-15 10:00:00'::TIMESTAMP + ((p - 1) * INTERVAL '3 days 18 hours');
        
        IF p <= 52 THEN
            -- Aceitos (maioria)
            v_status_ped := v_status_ped_aceito_id;
            v_data_conclusao := v_data_pedido + INTERVAL '4 days 6 hours';
        ELSIF p <= 62 THEN
            -- Recusados (alguns)
            v_status_ped := v_status_ped_recusado_id;
            v_data_conclusao := v_data_pedido + INTERVAL '2 days 10 hours';
        ELSIF p <= 67 THEN
            -- Em negociação
            v_status_ped := v_status_ped_negociacao_id;
            v_data_conclusao := NULL;
        ELSE
            -- Abertos
            v_status_ped := v_status_ped_aberto_id;
            v_data_conclusao := NULL;
        END IF;

        INSERT INTO pedidos (pedido_id, empresa_id, observacao, data_pedido, data_conclusao)
        VALUES (
            v_pedido_id, v_emp_id,
            CASE (p % 5)
                WHEN 0 THEN 'Fornecimento mensal programado de fardos de PET cristal e PEAD para linha de embalagens.'
                WHEN 1 THEN 'Demanda urgente de papelão ondulado de alta densidade prensado para reciclagem.'
                WHEN 2 THEN 'Lote de latinhas de alumínio compactadas com pureza garantida superior a 96%.'
                WHEN 3 THEN 'Compra de sucata mista classificada com certificação e laudo de rastreabilidade ESG.'
                ELSE 'Aquisição contínua de polímeros recuperados pós-consumo para formulação de resinas industriais.'
            END,
            v_data_pedido, v_data_conclusao
        );

        -- Itens do Pedido (Materiais Genéricos com cooperativa_id IS NULL)
        v_item1_id := gen_random_uuid();
        v_item2_id := gen_random_uuid();
        v_qtd_item1 := round(100.000 + ((p * 17) % 250)::numeric, 3);
        v_qtd_item2 := round(80.000 + ((p * 23) % 200)::numeric, 3);
        v_preco1 := round(2.80 + ((p % 15)::numeric * 0.15), 2);
        v_preco2 := round(1.90 + ((p % 10)::numeric * 0.20), 2);

        INSERT INTO pedido_itens (item_id, pedido_id, material_id, quantidade_kg, preco_unitario)
        VALUES 
            (v_item1_id, v_pedido_id, v_mat_genericos_ids[1 + (p % 3)], v_qtd_item1, v_preco1),
            (v_item2_id, v_pedido_id, v_mat_genericos_ids[4 + (p % 2)], v_qtd_item2, v_preco2);

        -- Vínculo Pedido x Cooperativa
        INSERT INTO pedidos_cooperativas (pedido_cooperativa_id, pedido_id, cooperativa_id, status_id)
        VALUES (gen_random_uuid(), v_pedido_id, v_coop_id, v_status_ped);

        -- Pedidos Aceitos: Movimentação de Saída de Estoque, Negociações e Avaliações
        IF p <= 52 THEN
            -- Saída Estoque Item 1
            SELECT estoque_id INTO v_est_id FROM estoques WHERE cooperativa_id = v_coop_id AND material_id = v_mat_genericos_ids[1 + (p % 3)] LIMIT 1;
            INSERT INTO movimentacoes_estoques (movimentacao_id, estoque_id, triagem_id, item_id, quantidade_kg, data_movimentacao)
            VALUES (gen_random_uuid(), v_est_id, NULL, v_item1_id, -v_qtd_item1, v_data_conclusao);

            -- Saída Estoque Item 2
            SELECT estoque_id INTO v_est_id FROM estoques WHERE cooperativa_id = v_coop_id AND material_id = v_mat_genericos_ids[4 + (p % 2)] LIMIT 1;
            INSERT INTO movimentacoes_estoques (movimentacao_id, estoque_id, triagem_id, item_id, quantidade_kg, data_movimentacao)
            VALUES (gen_random_uuid(), v_est_id, NULL, v_item2_id, -v_qtd_item2, v_data_conclusao);

            -- Negociação fechada para parte dos pedidos aceitos
            IF p <= 20 THEN
                v_neg_id := gen_random_uuid();
                INSERT INTO negociacoes (negociacao_id, pedido_id, cooperativa_id, empresa_id, status_id, valor_total, data_inicio, data_fechamento)
                VALUES (v_neg_id, v_pedido_id, v_coop_id, v_emp_id, v_status_neg_fechado_id, (v_qtd_item1 * v_preco1) + (v_qtd_item2 * v_preco2), v_data_pedido, v_data_conclusao);
                
                INSERT INTO negociacao_itens (negociacao_item_id, negociacao_id, material_id, quantidade_kg, preco_unitario)
                VALUES (gen_random_uuid(), v_neg_id, v_mat_genericos_ids[1 + (p % 3)], v_qtd_item1, v_preco1);
                
                INSERT INTO negociacao_mensagens (mensagem_id, negociacao_id, remetente_id, mensagem, tipo_mensagem, data_envio)
                VALUES 
                    (gen_random_uuid(), v_neg_id, v_emp_perf_id, 'Solicitamos cotação com entrega para esta semana.', 'TEXTO', v_data_pedido + INTERVAL '1 hour'),
                    (gen_random_uuid(), v_neg_id, v_perfil_coop_id, 'Conseguimos fornecer os fardos prensados com pureza comprovada. Proposta alinhada.', 'CONTRAPROPOSTA', v_data_pedido + INTERVAL '5 hours'),
                    (gen_random_uuid(), v_neg_id, v_emp_perf_id, 'Acordo fechado! Emitindo ordem de compra.', 'TEXTO', v_data_pedido + INTERVAL '8 hours');
            END IF;

            -- Avaliações mútuas
            INSERT INTO avaliacoes (avaliacao_id, avaliador_id, avaliado_id, pedido_id, nota, comentario, data_avaliacao)
            VALUES 
                (gen_random_uuid(), v_emp_perf_id, v_perfil_coop_id, v_pedido_id, 5, 'Excelente pureza dos fardos e compromisso de entrega. Parceria exemplar.', v_data_conclusao + INTERVAL '1 day'),
                (gen_random_uuid(), v_perfil_coop_id, v_emp_perf_id, v_pedido_id, 5, 'Empresa parceira com processo de descarga ágil e faturamento rigorosamente em dia.', v_data_conclusao + INTERVAL '1 day');

        ELSIF p <= 62 THEN
            -- Pedidos Recusados com Negociação Recusada
            v_neg_id := gen_random_uuid();
            INSERT INTO negociacoes (negociacao_id, pedido_id, cooperativa_id, empresa_id, status_id, valor_total, data_inicio, data_fechamento)
            VALUES (v_neg_id, v_pedido_id, v_coop_id, v_emp_id, v_status_neg_recusado_id, (v_qtd_item1 * v_preco1) + (v_qtd_item2 * v_preco2), v_data_pedido, v_data_conclusao);
            
            INSERT INTO negociacao_mensagens (mensagem_id, negociacao_id, remetente_id, mensagem, tipo_mensagem, data_envio)
            VALUES 
                (gen_random_uuid(), v_neg_id, v_emp_perf_id, 'Precisamos de um desconto de 25% para viabilizar a compra deste lote.', 'CONTRAPROPOSTA', v_data_pedido + INTERVAL '2 hours'),
                (gen_random_uuid(), v_neg_id, v_perfil_coop_id, 'Infelizmente o valor solicitado não cobre o custo operacional de triagem e logística. Negociação encerrada.', 'TEXTO', v_data_conclusao);

        ELSIF p <= 67 THEN
            -- Pedidos Em Negociação Ativa
            v_neg_id := gen_random_uuid();
            INSERT INTO negociacoes (negociacao_id, pedido_id, cooperativa_id, empresa_id, status_id, valor_total, data_inicio, data_fechamento)
            VALUES (v_neg_id, v_pedido_id, v_coop_id, v_emp_id, v_status_neg_andamento_id, (v_qtd_item1 * v_preco1) + (v_qtd_item2 * v_preco2), v_data_pedido, NULL);
            
            INSERT INTO negociacao_mensagens (mensagem_id, negociacao_id, remetente_id, mensagem, tipo_mensagem, data_envio)
            VALUES 
                (gen_random_uuid(), v_neg_id, v_emp_perf_id, 'Aguardamos confirmação de data para carregamento do lote no galpão.', 'TEXTO', v_data_pedido + INTERVAL '3 hours'),
                (gen_random_uuid(), v_neg_id, v_perfil_coop_id, 'Estamos concluindo a prensagem do lote na prensa primária. Retornaremos com o laudo de pesagem.', 'TEXTO', v_data_pedido + INTERVAL '6 hours');
        END IF;
    END LOOP;

    -- -------------------------------------------------------------------------
    -- 9. DESPESAS E LANÇAMENTOS MENSAIS (JANEIRO A OUTUBRO DE 2026)
    -- -------------------------------------------------------------------------
    FOR d IN 1..5 LOOP
        v_despesa_id := gen_random_uuid();
        INSERT INTO despesas (despesa_id, cooperativa_id, nome, tipo_despesa, esta_ativa)
        VALUES (
            v_despesa_id, v_coop_id,
            CASE d
                WHEN 1 THEN 'Locação do Galpão Operacional e Pátio Mooca'
                WHEN 2 THEN 'Energia Elétrica Trifásica das Prensas e Esteiras'
                WHEN 3 THEN 'Combustível e Manutenção Preventiva dos Caminhões'
                WHEN 4 THEN 'Aquisição de EPIs, Fardamentos e Luvas Kevlar'
                ELSE 'Assessoria Contábil, Segurança do Trabalho e Laudos PGRS'
            END,
            CASE WHEN d IN (1, 4, 5) THEN 'FIXA' ELSE 'VARIAVEL' END,
            TRUE
        );
        v_despesa_ids := array_append(v_despesa_ids, v_despesa_id);
        
        FOR m IN 1..10 LOOP
            v_mes_ref := ('2026-' || to_char(m, 'FM00') || '-01')::DATE;
            INSERT INTO lancamentos_despesas (lancamento_id, despesa_id, valor, mes_referencia, data_lancamento)
            VALUES (
                gen_random_uuid(), v_despesa_id,
                CASE d
                    WHEN 1 THEN 8500.00
                    WHEN 2 THEN 3200.00 + (m * 85)::numeric
                    WHEN 3 THEN 4100.00 + (m * 120)::numeric
                    WHEN 4 THEN 1800.00
                    ELSE 2200.00
                END,
                v_mes_ref,
                (v_mes_ref + INTERVAL '24 days 14:00:00')::TIMESTAMP
            );
        END LOOP;
    END LOOP;

    -- -------------------------------------------------------------------------
    -- 10. RATEIOS MENSAIS E RATEIOS_FUNCIONARIOS (JAN A OUT 2026)
    -- -------------------------------------------------------------------------
    FOR m IN 1..10 LOOP
        v_mes_ref := ('2026-' || to_char(m, 'FM00') || '-01')::DATE;
        v_rateio_id := gen_random_uuid();
        
        INSERT INTO rateios (rateio_id, cooperativa_id, gestor_id, tipo_rateio_id, mes_referencia, data_rateio)
        VALUES (
            v_rateio_id, v_coop_id, v_gestor_func_id, v_tipo_rateio_auto_id,
            v_mes_ref, (v_mes_ref + INTERVAL '1 month - 1 day 17:00:00')::TIMESTAMP
        );
        
        -- Distribuir para cada cooperado ativo
        FOR i IN 1..array_length(v_cooperados_ativos_ids, 1) LOOP
            INSERT INTO rateios_funcionarios (rateio_funcionario_id, rateio_id, cooperado_id, valor_rateio)
            VALUES (
                gen_random_uuid(), v_rateio_id, v_cooperados_ativos_ids[i],
                round(2850.00 + ((m * 45)::numeric) + ((i * 11 % 100)::numeric), 2)
            );
        END LOOP;
    END LOOP;

    -- -------------------------------------------------------------------------
    -- 11. ATIVIDADE DIÁRIA DE USUÁRIOS (DAU)
    -- -------------------------------------------------------------------------
    FOR m IN 1..10 LOOP
        FOR d IN 1..5 LOOP
            INSERT INTO atividade_usuarios_diaria (atividade_id, data_acesso, tipo_usuario, funcionario_id, empresa_id, criado_em)
            VALUES (
                gen_random_uuid(),
                ('2026-' || to_char(m, 'FM00') || '-' || to_char(d * 5, 'FM00'))::DATE,
                'COOPERADO', v_cooperados_ativos_ids[1 + (d % array_length(v_cooperados_ativos_ids, 1))], NULL,
                ('2026-' || to_char(m, 'FM00') || '-' || to_char(d * 5, 'FM00') || ' 08:30:00')::TIMESTAMP
            ) ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;

    RAISE NOTICE '========================================================================';
    RAISE NOTICE 'CARGA FINALIZADA COM TOTAL SUCESSO!';
    RAISE NOTICE 'Cooperativa ID: %', v_coop_id;
    RAISE NOTICE 'Gestor Funcionario ID: %', v_gestor_func_id;
    RAISE NOTICE 'Total Funcionários: 52 (Gestor: 1, Motoristas: 2, Admin: 1, Cooperados: 48)';
    RAISE NOTICE 'Total Coletas: 105 (92 Coletadas, 3 Pendentes, 10 Agendadas Futuras)';
    RAISE NOTICE 'Total Triagens: 230 (Múltiplos materiais para cada coleta realizada)';
    RAISE NOTICE 'Total Pedidos: 70 (52 Aceitos, 10 Recusados, 5 Em Negociação, 3 Abertos)';
    RAISE NOTICE 'Total Despesas: 5 | Lançamentos de Despesas: 50';
    RAISE NOTICE 'Total Rateios: 10 | Rateios por Funcionário: 510';
    RAISE NOTICE '========================================================================';

END $$;
