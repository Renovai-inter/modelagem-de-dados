import os
import psycopg2

DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://neondb_owner:npg_5fHz8jZXKqIW@ep-blue-bird-aw77n8nw-pooler.c-12.us-east-1.aws.neon.tech:5432/neondb?sslmode=require"
)

VIEWS = [
    ("vw_analitica_desempenho_equipes_triagem", r"c:\Users\rafaeltakematsu-ieg\RENOVAI\pg_dbRenovai\programmability\views\facts\vw_analitica_desempenho_equipes_triagem.sql"),
    ("vw_analitica_fluxo_coleta_anomalias", r"c:\Users\rafaeltakematsu-ieg\RENOVAI\pg_dbRenovai\programmability\views\facts\vw_analitica_fluxo_coleta_anomalias.sql"),
    ("vw_analitica_curva_abc_materiais", r"c:\Users\rafaeltakematsu-ieg\RENOVAI\pg_dbRenovai\programmability\views\facts\vw_analitica_curva_abc_materiais.sql"),
    ("vw_analitica_segmentacao_empresas_rfv", r"c:\Users\rafaeltakematsu-ieg\RENOVAI\pg_dbRenovai\programmability\views\facts\vw_analitica_segmentacao_empresas_rfv.sql"),
    ("vw_analitica_saude_financeira_rateio_esg", r"c:\Users\rafaeltakematsu-ieg\RENOVAI\pg_dbRenovai\programmability\views\facts\vw_analitica_saude_financeira_rateio_esg.sql"),
    ("vw_analitica_estoque_cobertura_giro", r"c:\Users\rafaeltakematsu-ieg\RENOVAI\pg_dbRenovai\programmability\views\facts\vw_analitica_estoque_cobertura_giro.sql"),
]

def test_views():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cur = conn.cursor()

    print("=" * 80)
    print("RENOVAÍ — TESTES DAS NOVAS VIEWS ANALÍTICAS COM WINDOW FUNCTIONS")
    print("=" * 80)

    # 1. Compilação de cada view
    for name, path in VIEWS:
        with open(path, "r", encoding="utf-8") as f:
            sql = f.read()
        cur.execute(sql)
        print(f"[OK] View compilada com sucesso: {name}")

    # 2. Aplicação das permissões para sistema_bi
    with open(r"c:\Users\rafaeltakematsu-ieg\RENOVAI\pg_dbRenovai\schema\seguranca_roles_dcl.sql", "r", encoding="utf-8") as f:
        dcl_sql = f.read()
    cur.execute(dcl_sql)
    print("[OK] Permissões DCL aplicadas com sucesso para sistema_bi!")

    # 3. Execução de amostragem de dados em cada view
    print("\n--- AMOSTRAGEM DE DADOS E VALIDAÇÃO DOS RESULTADOS ---")
    for name, _ in VIEWS:
        cur.execute(f"SELECT * FROM {name} LIMIT 3;")
        cols = [desc[0] for desc in cur.description]
        rows = cur.fetchall()
        print(f"\n>>> View: {name} (Colunas: {len(cols)})")
        print(f"    Colunas: {', '.join(cols[:6])}...")
        for r in rows:
            print(f"    Exemplo: {r[:5]}")

    # 4. Validação de acesso com a role sistema_bi
    print("\n--- TESTE DE CONTROLE DE ACESSO (ROLE sistema_bi) ---")
    cur.execute("SET ROLE sistema_bi;")
    for name, _ in VIEWS:
        cur.execute(f"SELECT COUNT(*) FROM {name};")
        count = cur.fetchone()[0]
        print(f"[PERMISSÃO OK] sistema_bi consultou {name} -> {count} linhas retornadas")
    cur.execute("RESET ROLE;")

    conn.close()
    print("\n" * 1 + "=" * 80)
    print("TODAS AS VIEWS ANALÍTICAS FORAM VALIDADAS E HOMOLOGADAS COM SUCESSO!")
    print("=" * 80)

if __name__ == "__main__":
    test_views()
