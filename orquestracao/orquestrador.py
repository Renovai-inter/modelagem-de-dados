"""
Orquestrador de Setup, Carga e Catalogação — Renovaí (Modelagem de Dados - 2º Ano)
Executa a estruturação completa do banco relacional via banco_relacional_sql/init.sql,
a carga sequencial de testes de volume via carga_volume_renovai.ipynb,
e a catalogação técnica de metadados no schema via documentacao_demandas/catalogo_dados/catalogacao_dbRenovai.ipynb.
"""

import json
import os
import sys
from pathlib import Path
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

# -----------------------------------------------------------------------------
# 1. Configuração e Conexão
# -----------------------------------------------------------------------------
CURRENT_DIR = Path(__file__).resolve().parent
REPO_ROOT = CURRENT_DIR.parent if CURRENT_DIR.name == "orquestracao" else CURRENT_DIR

# Busca .env prioritariamente na raiz do repositório
ENV_LOCATIONS = [
    REPO_ROOT / ".env",
    CURRENT_DIR / ".env",
    REPO_ROOT.parent / ".env",
    REPO_ROOT.parent / "povoador" / ".env",
]

env_loaded = False
for env_path in ENV_LOCATIONS:
    if env_path.is_file():
        load_dotenv(dotenv_path=env_path)
        env_loaded = True
        break

if not env_loaded:
    load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS") or os.getenv("DB_PASSWORD", "postgres")
DB_SSLMODE = os.getenv("DB_SSLMODE", "prefer")

# Normaliza variáveis de ambiente para processos e rotinas filhas
os.environ["DB_HOST"] = DB_HOST
os.environ["DB_PORT"] = str(DB_PORT)
os.environ["DB_NAME"] = DB_NAME
os.environ["DB_USER"] = DB_USER
os.environ["DB_PASS"] = DB_PASS
os.environ["DB_PASSWORD"] = DB_PASS
os.environ["DB_SSLMODE"] = DB_SSLMODE


def get_connection():
    """Abre e retorna a conexão principal com o PostgreSQL."""
    return psycopg2.connect(
        host=DB_HOST,
        port=int(DB_PORT),
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        sslmode=DB_SSLMODE,
    )


# -----------------------------------------------------------------------------
# 2. Execução do Schema (banco_relacional_sql)
# -----------------------------------------------------------------------------
def parse_and_validate_init_sql(init_sql_path: Path):
    r"""Interpreta os meta-comandos \i do init.sql e valida a existência dos arquivos."""
    if not init_sql_path.is_file():
        raise FileNotFoundError(f"Arquivo principal init.sql não encontrado: {init_sql_path}")

    base_dir = init_sql_path.parent
    sql_files = []

    with open(init_sql_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, start=1):
            clean = line.strip()
            if clean.startswith(r"\i"):
                parts = clean.split(maxsplit=1)
                if len(parts) < 2:
                    continue
                rel_path = parts[1].strip().strip("'\"")
                target_file = (base_dir / rel_path).resolve()
                if not target_file.is_file():
                    raise FileNotFoundError(
                        f"Arquivo referenciado em init.sql ausente: {target_file} (linha {line_num})"
                    )
                sql_files.append((rel_path, target_file))

    return sql_files


def execute_schema(conn, init_sql_path: Path):
    """Executa a criação de tabelas, constraints, procedures, views e seeds em transação segura."""
    print("\n" + "=" * 60)
    print("ETAPA 1: Execução do Schema Relacional (banco_relacional_sql)")
    print("=" * 60)

    sql_files = parse_and_validate_init_sql(init_sql_path)
    print(f"Total de {len(sql_files)} scripts mapeados e validados a partir de {init_sql_path.name}.")

    conn.autocommit = False
    cur = conn.cursor()

    try:
        for idx, (rel_path, file_path) in enumerate(sql_files, start=1):
            print(f"[{idx:02d}/{len(sql_files):02d}] Executando: {rel_path} ...", end=" ", flush=True)
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            if content.strip():
                cur.execute(content)
            print("OK")
        conn.commit()
        print("-> Schema, estruturas avançadas e dados de referência comitados com sucesso.")
    except Exception as e:
        conn.rollback()
        print(f"\n[ERRO] Falha durante a criação do schema. ROLLBACK executado: {e}")
        raise
    finally:
        cur.close()


# -----------------------------------------------------------------------------
# 3. Execução do Povoador (carga_inicial_povoamento)
# -----------------------------------------------------------------------------
def execute_povoador(conn, notebook_path: Path):
    """Executa a rotina de carga em lote do notebook com autocommit para suportar procedures."""
    print("\n" + "=" * 60)
    print("ETAPA 2: Execução da Carga de Volume (carga_inicial_povoamento)")
    print("=" * 60)

    if not notebook_path.is_file():
        raise FileNotFoundError(f"Notebook de povoamento não encontrado: {notebook_path}")

    # Requer autocommit=True pois as procedures transacionais realizam COMMIT interno
    conn.autocommit = True
    cur = conn.cursor()

    with open(notebook_path, "r", encoding="utf-8") as f:
        nb_data = json.load(f)

    cells = nb_data.get("cells", [])
    code_cells = [c for c in cells if c.get("cell_type") == "code"]
    print(f"Iniciando execução sequencial de {len(code_cells)} blocos de código do notebook...")

    # Escopo compartilhado para estado cumulativo entre as células
    scope = {
        "conn": conn,
        "cur": cur,
        "__name__": "__main__",
    }

    for idx, cell in enumerate(code_cells, start=1):
        raw_source = "".join(cell.get("source", []))
        if not raw_source.strip():
            continue

        filtered_lines = [
            line for line in raw_source.splitlines()
            if not line.strip().startswith(("%", "!"))
        ]
        cleaned_source = "\n".join(filtered_lines)

        # Reutiliza conexão já autenticada e configurada
        if "psycopg2.connect" in cleaned_source:
            scope["conn"] = conn
            scope["cur"] = cur
            psycopg2.extras.register_uuid()
            print(f"[{idx:02d}/{len(code_cells):02d}] Conexão ativa vinculada à rotina de carga.")
            continue

        # Evita encerramento prematuro antes das próximas etapas
        if "cur.close()" in cleaned_source and "conn.close()" in cleaned_source:
            print(f"[{idx:02d}/{len(code_cells):02d}] Fechamento de conexão reservado para o término do orquestrador.")
            continue

        try:
            exec(cleaned_source, scope)
            first_line = raw_source.strip().splitlines()[0][:45]
            print(f"[{idx:02d}/{len(code_cells):02d}] Concluído: {first_line}")
        except Exception as e:
            print(f"\n[ERRO] Falha no bloco de código {idx} do povoador: {e}")
            raise

    print("-> Povoamento de volume concluído com sucesso.")
    return cur


# -----------------------------------------------------------------------------
# 4. Execução da Catalogação de Metadados (documentacao_demandas)
# -----------------------------------------------------------------------------
def execute_catalogacao(conn, notebook_path: Path):
    """Executa a rotina de catalogação técnica persistindo em public.catalogo_metadados_tabelas."""
    print("\n" + "=" * 60)
    print("ETAPA 3: Catalogação de Metadados no Banco (catalogacao_dbRenovai.ipynb)")
    print("=" * 60)

    if not notebook_path.is_file():
        raise FileNotFoundError(f"Notebook de catalogação ausente: {notebook_path}")

    conn.autocommit = True
    cur = conn.cursor()

    with open(notebook_path, "r", encoding="utf-8") as f:
        nb_data = json.load(f)

    code_cells = [c for c in nb_data.get("cells", []) if c.get("cell_type") == "code"]
    print(f"Iniciando catalogação técnica ({len(code_cells)} blocos de código)...")

    scope = {
        "conn": conn,
        "cur": cur,
        "__name__": "__main__",
    }

    for idx, cell in enumerate(code_cells, start=1):
        raw_source = "".join(cell.get("source", []))
        if not raw_source.strip():
            continue

        filtered_lines = [
            line for line in raw_source.splitlines()
            if not line.strip().startswith(("%", "!"))
        ]
        cleaned_source = "\n".join(filtered_lines)

        try:
            exec(cleaned_source, scope)
            first_line = raw_source.strip().splitlines()[0][:45]
            print(f"[{idx:02d}/{len(code_cells):02d}] Concluído: {first_line}")
        except Exception as e:
            print(f"\n[ERRO] Falha no bloco {idx} da catalogação: {e}")
            raise

    # Confirmação da gravação no schema PostgreSQL
    cur.execute("SELECT COUNT(*) FROM public.catalogo_metadados_tabelas")
    total_cat = cur.fetchone()[0]
    print(f"-> Catalogação finalizada: {total_cat} entidades registradas em public.catalogo_metadados_tabelas.")
    return cur


# -----------------------------------------------------------------------------
# 5. Validação Pós-Carga
# -----------------------------------------------------------------------------
def validate_database(cur):
    """Efetua contagens de linhas e validações de integridade nas tabelas principais e de catálogo."""
    print("\n" + "=" * 60)
    print("ETAPA 4: Validação Pós-Carga e Governança (SELECT COUNT)")
    print("=" * 60)

    tabelas = [
        "cargos", "status", "tipos_rateios", "enderecos", "categorias_materiais",
        "materiais", "cooperativas", "empresas", "perfis", "usuarios",
        "funcionarios", "telefones", "equipes", "equipes_cooperados", "pedidos",
        "pedido_itens", "pedidos_cooperativas", "negociacoes", "avaliacoes",
        "coletas", "triagens", "estoques", "movimentacoes_estoques", "despesas",
        "lancamentos_despesas", "rotas", "rotas_enderecos", "rateios",
        "rateios_funcionarios", "empresa_materiais_interesses", "empresa_cooperativas_favoritas",
        "catalogo_metadados_tabelas"
    ]

    total_linhas = 0
    print(f"{'Tabela':<35} | {'Registros':>10}")
    print("-" * 48)

    for tab in tabelas:
        try:
            cur.execute(f"SELECT COUNT(*) FROM {tab}")
            cnt = cur.fetchone()[0]
            total_linhas += cnt
            print(f"{tab:<35} | {cnt:>10d}")
        except Exception as e:
            print(f"{tab:<35} | [ERRO: {e}]")

    print("-" * 48)
    print(f"{'TOTAL GERAL DE LINHAS':<35} | {total_linhas:>10d}")

    # Checagens adicionais de regras de negócio
    cur.execute("SELECT COUNT(*) FROM estoques WHERE quantidade_kg < 0")
    print(f"\nIntegridade - Estoques negativos (< 0 kg): {cur.fetchone()[0]} (esperado: 0)")

    cur.execute("SELECT COUNT(*) FROM avaliacoes WHERE avaliador_id = avaliado_id")
    print(f"Integridade - Avaliações com avaliador = avaliado: {cur.fetchone()[0]} (esperado: 0)")

    cur.execute("SELECT COUNT(*) FROM public.catalogo_metadados_tabelas")
    print(f"Governança - Metadados de entidades catalogados: {cur.fetchone()[0]}")


# -----------------------------------------------------------------------------
# Fluxo Principal
# -----------------------------------------------------------------------------
def main():
    """Ponto de entrada que orquestra setup de schema, carga, catalogação e validação."""
    print("=" * 60)
    print("RENOVAÍ — ORQUESTRADOR COMPLETO (MODELAGEM DE DADOS)")
    print(f"Banco Alvo: {DB_HOST}:{DB_PORT}/{DB_NAME} (Usuário: {DB_USER})")
    print("=" * 60)

    init_sql_path = REPO_ROOT / "banco_relacional_sql" / "init.sql"
    povoador_path = REPO_ROOT / "carga_volume_renovai.ipynb"
    catalog_path = REPO_ROOT / "documentacao_demandas" / "catalogo_dados" / "catalogacao_dbRenovai.ipynb"

    conn = None
    try:
        conn = get_connection()
        print("Conexão estabelecida com sucesso.")

        # 1. Estruturação do Banco
        execute_schema(conn, init_sql_path)

        # 2. Povoamento de Dados
        cur = execute_povoador(conn, povoador_path)

        # 3. Catalogação de Metadados
        cur = execute_catalogacao(conn, catalog_path)

        # 4. Validação das Tabelas e Governança
        validate_database(cur)

        print("\n" + "=" * 60)
        print("ORQUESTRAÇÃO COMPLETA CONCLUÍDA COM SUCESSO!")
        print("=" * 60)

    except Exception as err:
        print(f"\n[FALHA NA ORQUESTRAÇÃO]: {err}")
        sys.exit(1)
    finally:
        if conn and not conn.closed:
            conn.close()
            print("Conexão encerrada com segurança.")


if __name__ == "__main__":
    main()
