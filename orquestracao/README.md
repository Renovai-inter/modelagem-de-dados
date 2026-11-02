# Renovaí — Modelagem de Dados e Engenharia de Dados
**Projeto Interdisciplinar — 2º Ano | Instituto J&F Germinatech**  
**Repositório Oficial:** `modelagem-de-dados`  
**SGBD Principal:** PostgreSQL 16+  
**Status do Pipeline:** Estável e 100% Automatizado  

---

## 1. Visão Geral do Projeto

O **Renovaí** é uma plataforma tecnológica de impacto socioambiental voltada para a gestão, rastreabilidade e comercialização de materiais recicláveis em cooperativas e indústrias parceiras.

Este repositório consolida todo o ecossistema de **Modelagem de Dados Relacional**, **Camada Analítica de Business Intelligence (Data Mart)**, **Governança**, **Otimização de Consultas**, **Disaster Recovery**, **Automação de Carga Massiva de Volume** e **Catalogação Técnica de Metadados**.

---

## 2. Estrutura Profissional de Diretórios

As configurações de ambiente e dependências foram centralizadas na raiz do repositório (`.env.example` e `requirements.txt`), mantendo as subpastas puras e focadas em suas respectivas responsabilidades:

```
modelagem-de-dados/
├── .env.example                    # Modelo unificado de variáveis de ambiente para conexão
├── requirements.txt                # Dependências Python centralizadas do repositório
├── LICENSE                         # Licença MIT do projeto
├── README.md                       # Documentação mestre do repositório
│
├── banco_relacional_sql/           # [1] Scripts SQL de criação de objetos relacionais
│   ├── init.sql                    # Script mestre de inicialização ordenada (61 scripts)
│   ├── schema/                     # DDL normalizado (3FN/5FN), PKs, FKs, Índices e Segurança
│   │   ├── tables.sql              # 31 tabelas normalizadas com UUIDs, CHECKs e DEFAULTs
│   │   ├── foreign_keys.sql        # Relacionamentos e cardinalidades (1:1, 1:N, N:N)
│   │   ├── indexes.sql             # 49 índices de performance (B-Tree composto e parciais)
│   │   ├── auditoria_logs.sql      # Estruturas para triggers de auditoria universal
│   │   ├── metricas_dau.sql        # Tabela e views analíticas de monitoramento DAU
│   │   ├── seguranca_roles_dcl.sql # Controle de acesso DCL e Princípio do Menor Privilégio
│   │   └── seguranca_rls.sql       # Row-Level Security e criptografia de senhas (pgcrypto)
│   ├── programmability/            # Lógica procedural e camada analítica de BI
│   │   ├── functions/              # 18 funções PL/pgSQL (validações, regras e CTE Recursiva)
│   │   ├── procedures/             # 4 stored procedures com controle transacional
│   │   ├── triggers/               # 9 triggers de integridade, auditoria e sincronização
│   │   └── views/                  # Data Mart dimensional em Star Schema
│   │       ├── dimensions/         # 8 views de dimensão (vw_dim_*)
│   │       └── facts/              # 14 views de fato com CTEs e Window Functions (vw_fato_*)
│   └── data/                       # Cargas iniciais de domínio e dados de referência
│       ├── seed_dados_referencia.sql
│       └── insert_nova_cooperativa_completa.sql
│
├── carga_volume_renovai.ipynb  # Notebook com geração sintética (>500 registros)
│
├── documentacao_demandas/          # [3] Evidências e documentações para nota máxima (10,0)
│   ├── matriz_requisitos_disciplina.md # Rastreabilidade detalhada das demandas do edital
│   ├── catalogo_dados/             # Governança: Catálogo técnico de metadados
│   │   ├── catalogo_de_dados.md    # Metadados das 31 tabelas em Markdown e matriz RBAC
│   │   ├── catalogacao_dbRenovai.ipynb # Notebook de catalogação no schema do PostgreSQL
│   │   └── meta_tabelas.json       # Dicionário estruturado de metadados das tabelas
│   ├── otimizacao/                 # Otimização com EXPLAIN ANALYZE e índices
│   │   ├── otimizacao_explain_analyze.md # Relatório técnico de desempenho empírico
│   │   ├── test_explain_indexes.sql     # Casos de teste de planos de execução
│   │   └── benchmark_indexes.py         # Script de medição de tempo e buffers
│   ├── seguranca_backup/           # Governança, RLS, pgcrypto e Disaster Recovery
│   │   ├── seguranca_e_disaster_recovery.md # Documentação das 7 camadas da Fortaleza Macro
│   │   ├── backup.ps1 / backup.sh          # Scripts automatizados de backup lógico
│   │   ├── restaurar.ps1 / restaurar.sh    # Scripts automatizados de restauração pós-desastre
│   │   ├── test_seguranca_rls.sql          # Testes SQL de RLS e NULLIF
│   │   └── run_security_tests.py           # Suite de testes automatizados de segurança
│   └── testes_bi/                  # Validação das views analíticas dimensionais
│       └── test_views_analiticas.py
│
└── orquestracao/                   # [4] Pipeline unificado de execução ponta a ponta
    ├── orquestrador.py             # Script Python executável (Setup DDL + Carga + Catálogo + Validação)
    ├── orquestrador.ipynb          # Versão Jupyter Notebook interativa
    └── README.md                   # Guia de execução do orquestrador
```

---

## 3. Matriz de Atendimento às Solicitações da Disciplina

| Categoria | Requisito Formal | Status | Evidência / Arquivo no Repositório |
|---|---|:---:|---|
| **Mínimo (7,0)** | Banco Normalizado até 3FN/5FN | **Atendido** | 31 tabelas estruturadas sem anomalias em [`banco_relacional_sql/schema/tables.sql`](banco_relacional_sql/schema/tables.sql). |
| **Mínimo (7,0)** | Relacionamentos PK, FK e Cardinalidades (1:1, 1:N, N:N) | **Atendido** | Mapeamento explícito e restrições CHECK em [`banco_relacional_sql/schema/foreign_keys.sql`](banco_relacional_sql/schema/foreign_keys.sql). |
| **Mínimo (7,0)** | Massa de Dados: pelo menos 500 registros verossímeis | **Atendido** | Carga volumosa de milhares de linhas geradas via `Faker` (pt_BR) em [`carga_volume_renovai.ipynb`](carga_volume_renovai.ipynb). |
| **Mínimo (7,0)** | Integração RPA / Movimentação automatizada com integridade | **Atendido** | Orquestrador transacional em [`orquestracao/orquestrador.py`](orquestracao/orquestrador.py). |
| **Mínimo (7,0)** | Camada de BI (Data Mart): Star Schema / Snowflake | **Atendido** | 8 Views Dimensão e 14 Views Fato em [`banco_relacional_sql/programmability/views/`](banco_relacional_sql/programmability/views/). |
| **Mínimo (7,0)** | Transformação (ETL no SQL) com CTEs e Window Functions | **Atendido** | CTEs e Window Functions (`DENSE_RANK()`, `SUM() OVER ()`) em views analíticas como [`vw_fato_metricas_mensais.sql`](banco_relacional_sql/programmability/views/facts/vw_fato_metricas_mensais.sql). |
| **Mínimo (7,0)** | Mínimo de 2 Functions e 2 Procedures | **Atendido** | **18 Functions** e **4 Stored Procedures** críticas em [`banco_relacional_sql/programmability/`](banco_relacional_sql/programmability/). |
| **Mínimo (7,0)** | Triggers de Auditoria (NEW, OLD, TG_OP, CURRENT_USER) | **Atendido** | Trigger universal e logs JSON em [`banco_relacional_sql/schema/auditoria_logs.sql`](banco_relacional_sql/schema/auditoria_logs.sql). |
| **Mínimo (7,0)** | Otimização com EXPLAIN ANALYZE e Índices SQL | **Atendido** | Malha de 49 índices em [`indexes.sql`](banco_relacional_sql/schema/indexes.sql) e relatório em [`documentacao_demandas/otimizacao/`](documentacao_demandas/otimizacao/). |
| **Extra (10,0)** | Catálogo Técnico de Metadados no Banco e em Markdown | **Atendido** | Tabela técnica `catalogo_metadados_tabelas` no PostgreSQL via [`catalogacao_dbRenovai.ipynb`](documentacao_demandas/catalogo_dados/catalogacao_dbRenovai.ipynb) e [`catalogo_de_dados.md`](documentacao_demandas/catalogo_dados/catalogo_de_dados.md). |
| **Extra (10,0)** | Procedimentos de Segurança, Backup e Recuperação de Falhas | **Atendido** | Disaster recovery e scripts de backup/restore em [`documentacao_demandas/seguranca_backup/`](documentacao_demandas/seguranca_backup/). |
| **Extra (10,0)** | Monitoramento de Acessos DAU no PostgreSQL | **Atendido** | Tabela e métricas automatizadas em [`banco_relacional_sql/schema/metricas_dau.sql`](banco_relacional_sql/schema/metricas_dau.sql). |
| **Extra (10,0)** | Estruturas Avançadas (CTE Recursiva) | **Atendido** | Árvore recursiva de materiais com `WITH RECURSIVE` em [`fn_total_kg_por_categoria.sql`](banco_relacional_sql/programmability/functions/fn_total_kg_por_categoria.sql). |

---

## 4. Inicialização Rápida em 1 Comando

Para executar o pipeline completo na raiz do repositório:

```bash
# 1. Instalar as dependências do projeto
pip install -r requirements.txt

# 2. Configurar o arquivo de variáveis de ambiente
cp .env.example .env

# 3. Executar o orquestrador completo
python orquestracao/orquestrador.py
```

Também é possível acompanhar a execução graficamente abrindo [`orquestracao/orquestrador.ipynb`](orquestracao/orquestrador.ipynb).

---

# Módulo de Orquestração — Renovaí

Este diretório contém os orquestradores que automatizam todo o ciclo de vida do banco relacional Renovaí:
1. **Estruturação DDL** (`banco_relacional_sql/init.sql`)
2. **Carga Massiva de Dados** (`carga_volume_renovai.ipynb`)
3. **Catalogação Técnica de Metadados** (`documentacao_demandas/catalogo_dados/catalogacao_dbRenovai.ipynb`)
4. **Validação Pós-Carga e Governança**

---

## Arquivos do Módulo

- **`orquestrador.py`**: Script executável em linha de comando (CLI).
- **`orquestrador.ipynb`**: Notebook Jupyter interativo com visualizações e logs de cada etapa.

---

## Como Executar

As dependências (`requirements.txt`) e variáveis de ambiente (`.env.example`) estão centralizadas na raiz do repositório.

A partir da raiz de `modelagem-de-dados/`:
```bash
# 1. Instalar dependências
pip install -r requirements.txt

# 2. Configurar variáveis de ambiente
cp .env.example .env

# 3. Executar o orquestrador
python orquestracao/orquestrador.py
```

Ou execute interativamente abrindo `orquestracao/orquestrador.ipynb` e clicando em **Run All**.
