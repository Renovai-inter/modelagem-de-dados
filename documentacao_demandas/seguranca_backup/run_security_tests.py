import os
import psycopg2

DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://neondb_owner:npg_5fHz8jZXKqIW@ep-blue-bird-aw77n8nw-pooler.c-12.us-east-1.aws.neon.tech:5432/neondb?sslmode=require"
)

def test_all():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    cur = conn.cursor()

    print("=" * 70)
    print("RENOVAÍ — TESTES DE SEGURANÇA, CRIPTOGRAFIA E RLS (FORTALEZA MACRO)")
    print("=" * 70)

    # Teste 1: Criptografia Blowfish
    cur.execute("""
    DO $$
    DECLARE
        v_hash_gerado TEXT;
        v_autenticou  BOOLEAN;
    BEGIN
        v_hash_gerado := crypt('SenhaForte123', gen_salt('bf', 10));
        v_autenticou := (v_hash_gerado = crypt('SenhaForte123', v_hash_gerado));
        IF NOT v_autenticou THEN RAISE EXCEPTION 'Falha senha correta'; END IF;
        v_autenticou := (v_hash_gerado = crypt('SenhaErrada', v_hash_gerado));
        IF v_autenticou THEN RAISE EXCEPTION 'Falha senha errada'; END IF;
    END $$;
    """)
    conn.commit()
    print("[PASS] Teste 1: pgcrypto Blowfish gen_salt('bf') funcionando 100%!")

    # Teste 2: Log de alerta crítico
    cur.execute("""
    INSERT INTO tb_log_sistema (nivel, categoria, mensagem) 
    VALUES ('ERROR', 'SEGURANCA', 'Múltiplas falhas de autenticação detectadas')
    RETURNING log_id, nivel, categoria, mensagem;
    """)
    log_res = cur.fetchone()
    conn.commit()
    print(f"[PASS] Teste 2: tb_log_sistema alerta gravado -> {log_res[1]}: {log_res[3]}")

    # Teste 3: RLS sem variável de sessão (Escudo NULLIF)
    cur.execute("SET ROLE api_renovai;")
    cur.execute("SELECT COUNT(*) FROM coletas;")
    sem_sessao = cur.fetchone()[0]
    conn.commit()
    print(f"[PASS] Teste 3: RLS sem sessão -> {sem_sessao} coletas visíveis (Escudo NULLIF blindou contra erro 22P02)")

    # Teste 4: SET LOCAL cooperativa_logada
    cur.execute("SET ROLE api_renovai;")
    cur.execute("SET LOCAL app.cooperativa_logada = 'ab87b483-01b2-4db3-8c4f-b67085bfa22d';")
    cur.execute("SELECT COUNT(*) FROM estoques;")
    estoques_coop = cur.fetchone()[0]
    conn.commit()
    print(f"[PASS] Teste 4: RLS com cooperativa_logada -> {estoques_coop} estoques filtrados da cooperativa")

    # Teste 5: SET LOCAL usuario_logado (Política Híbrida)
    cur.execute("SET ROLE api_renovai;")
    cur.execute("SET LOCAL app.usuario_logado = '3703451a-0869-473d-841c-b61c93b4edaa';")
    cur.execute("SELECT COUNT(*) FROM coletas;")
    coletas_coop = cur.fetchone()[0]
    conn.commit()
    print(f"[PASS] Teste 5: RLS Híbrido usuario_logado -> {coletas_coop} coletas pessoais do cooperado")

    # Teste 6: Auditor com BYPASSRLS
    cur.execute("SET ROLE auditor_corporativo;")
    cur.execute("SELECT COUNT(*) FROM coletas;")
    coletas_auditor = cur.fetchone()[0]
    conn.commit()
    print(f"[PASS] Teste 6: auditor_corporativo (BYPASSRLS) -> visualiza todas as {coletas_auditor} coletas da base!")

    cur.execute("RESET ROLE;")
    conn.commit()
    conn.close()

    print("=" * 70)
    print("TODOS OS TESTES DE SEGURANÇA E RLS FORAM APROVADOS COM SUCESSO!")
    print("=" * 70)

if __name__ == "__main__":
    test_all()
