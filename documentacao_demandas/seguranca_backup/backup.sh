#!/usr/bin/env bash
# =============================================================================
# RENOVAÍ — DISASTER RECOVERY: SCRIPT DE BACKUP LÓGICO (pg_dump)
# =============================================================================
# Referência: Aulas de Modelagem de Dados — Segurança de Dados (Instituto J&F)
# Slide 8 e Slide 10 (Hands-On 2: Intermediária 2)
# =============================================================================

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-bd_renovai}"
DB_USER="${DB_USER:-postgres}"
DATA_HORA=$(date +'%Y%m%d_%H%M%S')
OUTPUT_DIR="./backups"

mkdir -p "${OUTPUT_DIR}"

echo "=========================================================================="
echo "RENOVAÍ — INICIANDO ROTINA DE BACKUP LÓGICO"
echo "Data/Hora: ${DATA_HORA}"
echo "Banco de Dados Alvo: ${DB_NAME} em ${DB_HOST}:${DB_PORT}"
echo "=========================================================================="

# -----------------------------------------------------------------------------
# 1. BACKUP APENAS DA ESTRUTURA (DDL / Schema-Only) — Slide 10 (Hands-On 2)
# -----------------------------------------------------------------------------
echo "--> 1. Gerando backup DDL (esquema sem dados reais)..."
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
        -s \
        -f "${OUTPUT_DIR}/renovai_schema_ddl_${DATA_HORA}.sql"
echo "    [OK] Arquivo gerado: ${OUTPUT_DIR}/renovai_schema_ddl_${DATA_HORA}.sql"

# -----------------------------------------------------------------------------
# 2. BACKUP DE TABELA ISOLADA (coletas) — Slide 8
# -----------------------------------------------------------------------------
echo "--> 2. Gerando backup pontual da tabela crítica 'coletas'..."
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
        -t coletas \
        -f "${OUTPUT_DIR}/backup_coletas_${DATA_HORA}.sql"
echo "    [OK] Arquivo gerado: ${OUTPUT_DIR}/backup_coletas_${DATA_HORA}.sql"

# -----------------------------------------------------------------------------
# 3. BACKUP COMPLETO (Schema + Dados de Todas as Tabelas)
# -----------------------------------------------------------------------------
echo "--> 3. Gerando backup completo da base de dados..."
pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
        -f "${OUTPUT_DIR}/renovai_completo_${DATA_HORA}.sql"
echo "    [OK] Arquivo gerado: ${OUTPUT_DIR}/renovai_completo_${DATA_HORA}.sql"

echo "=========================================================================="
echo "ROTINA DE BACKUP FINALIZADA COM SUCESSO!"
echo "=========================================================================="
