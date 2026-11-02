#!/usr/bin/env bash
# =============================================================================
# RENOVAÍ — DISASTER RECOVERY: SCRIPT DE RESTAURAÇÃO (psql)
# =============================================================================
# Referência: Aulas de Modelagem de Dados — Segurança de Dados (Instituto J&F)
# Slide 8: Cenário de Recuperação pós DROP TABLE acidental
# =============================================================================

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Uso: $0 <caminho_do_arquivo_sql_de_backup>"
    echo "Exemplo: $0 ./backups/backup_coletas_20261031_120000.sql"
    exit 1
fi

ARQUIVO_BACKUP="$1"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-bd_renovai}"
DB_USER="${DB_USER:-postgres}"

if [ ! -f "${ARQUIVO_BACKUP}" ]; then
    echo "[ERRO] Arquivo de backup não encontrado: ${ARQUIVO_BACKUP}"
    exit 1
fi

echo "=========================================================================="
echo "RENOVAÍ — INICIANDO RESTAURAÇÃO DE DESASTRE (psql)"
echo "Arquivo de Entrada: ${ARQUIVO_BACKUP}"
echo "Destino: ${DB_NAME} em ${DB_HOST}:${DB_PORT}"
echo "=========================================================================="

psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" \
     -v ON_ERROR_STOP=1 \
     -f "${ARQUIVO_BACKUP}"

echo "=========================================================================="
echo "RESTAURAÇÃO CONCLUÍDA COM SUCESSO!"
echo "=========================================================================="
