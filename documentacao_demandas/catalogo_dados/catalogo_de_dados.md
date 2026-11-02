# Catálogo Técnico de Metadados e Governança de Dados
**Projeto:** Renovaí — Plataforma de Gestão e Comercialização para Cooperativas de Reciclagem  
**Disciplina:** Modelagem de Dados (2º Ano) — Requisito Extra: Governança de Dados  
**SGBD:** PostgreSQL 16+  
**Normalização:** 3ª Forma Normal (3FN) com otimizações para 5ª Forma Normal  

---

## 1. Visão Geral da Governança e Metadados

Este documento atende formalmente ao requisito de **Governança de Dados (Catálogo de Dados)**, especificando cada tabela física do cluster PostgreSQL, sua finalidade de negócio, tipagem de colunas, restrições de integridade (`PRIMARY KEY`, `FOREIGN KEY`, `CHECK`, `DEFAULT`) e a matriz de níveis de acesso associada aos papéis (Roles DCL) e políticas de segurança em nível de linha (RLS).

---

## 2. Matriz Técnica de Entidades e Atributos

### 2.1. Núcleo Cadastral e Atores (Cooperativas, Empresas, Perfis, Contatos)

| Tabela | Coluna Principal | Tipo | Restrições / Regras de Negócio | Nível de Acesso (RBAC / DCL) |
|---|---|---|---|---|
| `cooperativas` | `cooperativa_id`<br>`nome`<br>`numero_cooperados`<br>`contato_preferencial` | `UUID`<br>`VARCHAR(255)`<br>`INTEGER`<br>`VARCHAR(50)` | PK gerada com `gen_random_uuid()`. `numero_cooperados >= 0` mantido automaticamente via triggers de funcionários. `contato_preferencial` restrito a `('WHATSAPP', 'TELEFONE', 'EMAIL')`. | `SELECT, INSERT, UPDATE` para `api_renovai`. `DELETE` restrito. RLS ativado para gestores da cooperativa. |
| `empresas` | `empresa_id`<br>`nome`<br>`descricao` | `UUID`<br>`VARCHAR(255)`<br>`TEXT` | PK UUID. Representa compradores industriais e parceiros de logística reversa. | `SELECT, INSERT, UPDATE` para `api_renovai`. |
| `perfis` | `perfil_id`<br>`empresa_id`<br>`cooperativa_id`<br>`cnpj` | `UUID`<br>`UUID`<br>`UUID`<br>`VARCHAR(18)` | Relação 1:1 exclusiva via `CHECK ((empresa_id IS NOT NULL AND cooperativa_id IS NULL) OR (empresa_id IS NULL AND cooperativa_id IS NOT NULL))`. `cnpj` validado com máscara e unicidade. | `SELECT, INSERT, UPDATE` para `api_renovai`. |
| `enderecos` | `endereco_id`<br>`cep`<br>`tipo` | `UUID`<br>`VARCHAR(9)`<br>`VARCHAR(20)` | `tipo IN ('Residencial', 'Comercial', 'Coleta')`. Normalização geográfica de cooperativas, empresas e pontos de rota. | `SELECT, INSERT, UPDATE` para `api_renovai`. |
| `telefones` | `telefone_id`<br>`perfil_id`<br>`usuario_id`<br>`ddd`<br>`numero` | `UUID`<br>`UUID`<br>`UUID`<br>`VARCHAR(3)`<br>`VARCHAR(15)` | Relação 1:N com perfis jurídicos ou usuários físicos. `CHECK ((perfil_id IS NOT NULL AND usuario_id IS NULL) OR ...)`. | `SELECT, INSERT, UPDATE` para `api_renovai`. |

---

### 2.2. Acesso, Colaboradores e Segurança de Sessão

| Tabela | Coluna Principal | Tipo | Restrições / Regras de Negócio | Nível de Acesso (RBAC / DCL) |
|---|---|---|---|---|
| `cargos` | `cargo_id`<br>`cargo` | `UUID`<br>`VARCHAR(50)` | Tabela de domínio imutável (`Cooperado`, `Gestor`, `Admin`, `motorista`, `ADMIN_SITE`). `UNIQUE(cargo)`. | Leitura pública para autenticados; escrita reservada a migrações DDL. |
| `usuarios` | `usuario_id`<br>`email`<br>`senha_hash`<br>`esta_ativo` | `UUID`<br>`VARCHAR(255)`<br>`TEXT`<br>`BOOLEAN` | `email` único. `senha_hash` gerado exclusivamente via `pgcrypto` (`gen_salt('bf', 10)`). `esta_ativo DEFAULT TRUE`. | Leitura restrita à camada de autenticação (`fn_autenticar_usuario`). `UPDATE` de credenciais auditado. |
| `funcionarios` | `funcionario_id`<br>`cooperativa_id`<br>`usuario_id`<br>`cargo_id`<br>`cpf`<br>`status_trabalho` | `UUID`<br>`UUID`<br>`UUID`<br>`UUID`<br>`VARCHAR(14)`<br>`VARCHAR(20)` | Vínculo 1:1 de `usuario_id` com colaborador. `status_trabalho IN ('ATIVO', 'AFASTADO', 'INATIVO')`. Gatilhos automáticos atualizam o número de cooperados na cooperativa pai. | `SELECT, INSERT, UPDATE` para `api_renovai`. Cooperado enxerga apenas seu registro (RLS). |

---

### 2.3. Catálogo de Materiais e Estoque

| Tabela | Coluna Principal | Tipo | Restrições / Regras de Negócio | Nível de Acesso (RBAC / DCL) |
|---|---|---|---|---|
| `categorias_materiais` | `categoria_id`<br>`categoria_pai_id`<br>`nome_categoria` | `UUID`<br>`UUID`<br>`VARCHAR(100)` | Auto-relacionamento hierárquico (Árvore de materiais) compatível com CTE Recursiva (`WITH RECURSIVE`). | Leitura irrestrita; escrita controlada por gestores. |
| `materiais` | `material_id`<br>`categoria_id`<br>`cooperativa_id`<br>`preco_sugerido` | `UUID`<br>`UUID`<br>`UUID`<br>`NUMERIC(10,2)` | Se `cooperativa_id IS NULL`, é material genérico da plataforma. Se preenchido, é exclusivo da cooperativa. `preco_sugerido >= 0`. | Leitura pública; inserção parametrizada. |
| `estoques` | `estoque_id`<br>`cooperativa_id`<br>`material_id`<br>`quantidade_kg` | `UUID`<br>`UUID`<br>`UUID`<br>`NUMERIC(12,2)` | `UNIQUE(cooperativa_id, material_id)`. `quantidade_kg >= 0` garantido por trigger e restrição `CHECK`. Atualizado automaticamente por triagens e vendas. | `SELECT, UPDATE` via procedures. Gestores acessam apenas a sua cooperativa. |
| `movimentacoes_estoques` | `movimentacao_id`<br>`estoque_id`<br>`tipo_movimentacao`<br>`quantidade_kg` | `UUID`<br>`UUID`<br>`VARCHAR(20)`<br>`NUMERIC(12,2)` | Livro-razão imutável (`ENTRADA_TRIAGEM`, `SAIDA_VENDA`, `PERDA_REJEITO`). **Inserção permitida apenas via procedures operacionais**. `REVOKE DELETE` absoluto. | Somente `INSERT` e `SELECT`. `DELETE` revogado expressamente para `api_renovai`. |

---

### 2.4. Operações de Coleta, Triagem e Rotas Logísticas

| Tabela | Coluna Principal | Tipo | Restrições / Regras de Negócio | Nível de Acesso (RBAC / DCL) |
|---|---|---|---|---|
| `equipes` | `equipe_id`<br>`cooperativa_id`<br>`nome` | `UUID`<br>`UUID`<br>`VARCHAR(100)` | Agrupamento de cooperados para rotas e triagem de materiais. | Gestão restrita à cooperativa proprietária. |
| `equipes_cooperados` | `equipe_id`<br>`cooperado_id` | `UUID`<br>`UUID` | Associação N:N entre equipes e colaboradores cooperados ativos. | Gestão operacional cooperativa. |
| `rotas` | `rota_id`<br>`cooperativa_id`<br>`nome` | `UUID`<br>`UUID`<br>`VARCHAR(100)` | Planejamento logístico de veículos e equipes de coleta seletiva. | Operação logística. |
| `rotas_enderecos` | `rota_id`<br>`endereco_id`<br>`ordem_visita` | `UUID`<br>`UUID`<br>`INTEGER` | N:N com ordem sequencial dos pontos de parada (`ordem_visita > 0`). | Leitura por motoristas e gestores. |
| `coletas` | `coleta_id`<br>`cooperativa_id`<br>`cooperado_id`<br>`status_id`<br>`peso_bruto_kg` | `UUID`<br>`UUID`<br>`UUID`<br>`UUID`<br>`NUMERIC(10,2)` | Registro de pesagem em campo. RLS ativa: o cooperado enxerga apenas suas coletas; o gestor enxerga todas da cooperativa. | `SELECT, INSERT, UPDATE` com políticas de RLS híbridas. |
| `triagens` | `triagem_id`<br>`coleta_id`<br>`material_id`<br>`quantidade_kg`<br>`peso_rejeito_kg` | `UUID`<br>`UUID`<br>`UUID`<br>`NUMERIC(10,2)`<br>`NUMERIC(10,2)` | **Preenchimento exclusivo via `CALL sp_registrar_movimentacao_triagem(...)`**. Gera movimentação de entrada no estoque e validação de tara/rejeito. | Escrita via procedure; leitura para BI e auditoria. |

---

### 2.5. Comercialização, Negociação e Avaliações

| Tabela | Coluna Principal | Tipo | Restrições / Regras de Negócio | Nível de Acesso (RBAC / DCL) |
|---|---|---|---|---|
| `pedidos` | `pedido_id`<br>`empresa_id`<br>`status_id`<br>`valor_total` | `UUID`<br>`UUID`<br>`UUID`<br>`NUMERIC(12,2)` | Solicitação de compra industrial. `REVOKE DELETE` aplicado para preservação contábil. | `SELECT, INSERT, UPDATE` para `api_renovai`. |
| `pedido_itens` | `item_id`<br>`pedido_id`<br>`material_id`<br>`quantidade_kg` | `UUID`<br>`UUID`<br>`UUID`<br>`NUMERIC(10,2)` | Linhas de pedidos. `quantidade_kg > 0` e validação contra materiais genéricos. | Inserção associada ao pedido. |
| `pedidos_cooperativas` | `pedido_id`<br>`cooperativa_id`<br>`data_atendimento` | `UUID`<br>`UUID`<br>`TIMESTAMP` | Vínculo N:N de direcionamento de demandas com base em capacidade de estoque. | Atualizado via `CALL sp_aceitar_pedido_cooperativa`. |
| `negociacoes` | `negociacao_id`<br>`pedido_id`<br>`cooperativa_id`<br>`status_id` | `UUID`<br>`UUID`<br>`UUID`<br>`UUID` | Canal de acordo customizado para pedidos complexos ou descontos por volume. | Restrito às duas partes envolvidas. |
| `negociacao_itens` | `negociacao_item_id`<br>`negociacao_id`<br>`preco_ofertado` | `UUID`<br>`UUID`<br>`NUMERIC(10,2)` | Itens negociados com preços e prazos acordados. | Restrito às partes. |
| `negociacao_mensagens` | `mensagem_id`<br>`negociacao_id`<br>`remetente_usuario_id`<br>`texto` | `UUID`<br>`UUID`<br>`UUID`<br>`TEXT` | Registro de mensagens e contrapropostas em tempo real. | Acesso estrito por sessão do usuário. |
| `avaliacoes` | `avaliacao_id`<br>`avaliador_id`<br>`avaliado_id`<br>`nota` | `UUID`<br>`UUID`<br>`UUID`<br>`SMALLINT` | Sistema de reputação 360º. `CHECK (nota BETWEEN 1 AND 5)` e `CHECK (avaliador_id != avaliado_id)`. | Inserção única por transação/relação comercial. |

---

### 2.6. Saúde Financeira, Rateio ESG e Despesas Operacionais

| Tabela | Coluna Principal | Tipo | Restrições / Regras de Negócio | Nível de Acesso (RBAC / DCL) |
|---|---|---|---|---|
| `despesas` | `despesa_id`<br>`cooperativa_id`<br>`nome` | `UUID`<br>`UUID`<br>`VARCHAR(100)` | Plano de contas operacional da cooperativa (energia, água, combustíveis, manutenção). | Gestor da cooperativa. |
| `lancamentos_despesas` | `lancamento_id`<br>`despesa_id`<br>`valor`<br>`mes_referencia` | `UUID`<br>`UUID`<br>`NUMERIC(12,2)`<br>`DATE` | Custos mensais da cooperativa. Normalizado automaticamente para o 1º dia do mês via trigger. | `SELECT, INSERT, UPDATE`. `DELETE` revogado. |
| `tipos_rateios` | `tipo_rateio_id`<br>`tipo_rateio` | `UUID`<br>`VARCHAR(50)` | `AUTOMATICO` ou `MANUAL`. Tabela de domínio de conformidade contábil cooperativista. | Somente leitura. |
| `rateios` | `rateio_id`<br>`cooperativa_id`<br>`mes_referencia`<br>`valor_liquido` | `UUID`<br>`UUID`<br>`DATE`<br>`NUMERIC(12,2)` | **Calculado e fechado exclusivamente por `CALL sp_fechar_rateio_mensal(...)`**. Subtrai custos de vendas com rateio proporcional. | Imutável após fechamento mensal. |
| `rateios_funcionarios` | `rateio_funcionario_id`<br>`rateio_id`<br>`funcionario_id`<br>`valor_recebido` | `UUID`<br>`UUID`<br>`UUID`<br>`NUMERIC(12,2)` | Linhas de extrato individual para cada cooperado ativo. RLS ativo para visualização individual de ganhos. | RLS: cooperado vê somente o seu valor. |

---

### 2.7. Auditoria Completa, Segurança e Telemetria (DAU)

| Tabela | Coluna Principal | Tipo | Restrições / Regras de Negócio | Nível de Acesso (RBAC / DCL) |
|---|---|---|---|---|
| `auditoria_universal` | `auditoria_id`<br>`tabela_origem`<br>`operacao`<br>`dados_antigos`<br>`dados_novos`<br>`usuario_origem` | `UUID`<br>`VARCHAR(50)`<br>`VARCHAR(10)`<br>`JSONB`<br>`JSONB`<br>`VARCHAR(100)` | Trilha de auditoria universal para conformidade LGPD e integridade de dados (captura `TG_OP`, `NEW`, `OLD`, `CURRENT_USER`). | Somente `SELECT` para auditores autorizados (`BYPASSRLS`). Escrita exclusiva via trigger. |
| `log_seguranca_sistema` | `log_id`<br>`nivel`<br>`categoria`<br>`mensagem`<br>`ip_origem` | `UUID`<br>`VARCHAR(20)`<br>`VARCHAR(50)`<br>`TEXT`<br>`INET` | Alertas de segurança e anomalias de transação (`INFO`, `WARN`, `ERROR`, `CRITICAL`). | Somente leitura de auditoria e inserção de logs. |
| `metricas_dau` | `metrica_id`<br>`usuario_id`<br>`data_acesso`<br>`plataforma` | `UUID`<br>`UUID`<br>`DATE`<br>`VARCHAR(20)` | Registro automatizado de Daily Active Users para acompanhamento de engajamento do aplicativo mobile e web. | Inserção diária por telemetria; leitura gerencial. |

---

## 3. Matriz de Privilégios DCL (Princípio do Menor Privilégio)

Conforme a **Camada 5 da Fortaleza Macro**, o acesso da aplicação web e dos clientes externos é segregado por perfis de banco:

| Papel / Role PostgreSQL | Finalidade | Permissões Permitidas | Operações Revogadas Expressamente |
|---|---|---|---|
| `postgres` (Superusuário) | Manutenção exclusiva do cluster, migrações DDL e backups administrativos. | Controle total (`ALL PRIVILEGES`). | Conexões de aplicações web via porta externa. |
| `api_renovai` (Backend API) | Conta de serviço para APIs Spring Boot e microserviços de IA. | `SELECT, INSERT, UPDATE` em tabelas operacionais; execução de procedures. | `DELETE` em `pedidos`, `movimentacoes_estoques`, `rateios`, `lancamentos_despesas`, `auditoria_universal`. |
| `auditor_seguranca` | Inspeção de conformidade, trilhas de auditoria e conciliação financeira. | `SELECT` com privilégio `BYPASSRLS`. | Qualquer operação de `INSERT`, `UPDATE` ou `DELETE`. |
