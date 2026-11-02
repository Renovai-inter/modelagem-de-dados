"""
Renovaí — Testes Automatizados de Performance (EXPLAIN ANALYZE)
Arquivo: pg_dbRenovai/tests/benchmark_indexes.py
"""
import os
import psycopg2

DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://neondb_owner:npg_5fHz8jZXKqIW@ep-blue-bird-aw77n8nw-pooler.c-12.us-east-1.aws.neon.tech:5432/neondb?sslmode=require"
)

QUERIES = [
    {
        "nome": "Consulta 1: Pedidos + Itens por Cooperativa (JOIN Triplo)",
        "sql": """
            EXPLAIN (ANALYZE, BUFFERS)
            SELECT p.pedido_id, p.empresa_id, p.data_pedido, pc.status_id, pi.material_id, pi.quantidade_kg
            FROM pedidos p
            JOIN pedidos_cooperativas pc ON pc.pedido_id = p.pedido_id
            JOIN pedido_itens pi ON pi.pedido_id = p.pedido_id
            WHERE pc.cooperativa_id = 'ab87b483-01b2-4db3-8c4f-b67085bfa22d'
            ORDER BY p.data_pedido DESC;
        """,
        "indexes": ["idx_pedidos_cooperativas_coop_status", "idx_pedido_itens_pedido_id", "idx_pedidos_data_pedido"]
    },
    {
        "nome": "Consulta 2: Coletas por Cooperado com Ordenação Temporal",
        "sql": """
            EXPLAIN (ANALYZE, BUFFERS)
            SELECT c.evento_id, c.cooperado_id, c.data_evento, c.quantidade_kg, c.tipo_coleta
            FROM coletas c
            WHERE c.cooperado_id = '3703451a-0869-473d-841c-b61c93b4edaa'
            ORDER BY c.data_evento DESC;
        """,
        "indexes": ["idx_coletas_cooperado_data"]
    },
    {
        "nome": "Consulta 3: Extrato de Movimentações de Estoque (Livro Razão)",
        "sql": """
            EXPLAIN (ANALYZE, BUFFERS)
            SELECT me.movimentacao_id, me.estoque_id, me.quantidade_kg, me.tipo_movimentacao, me.data_movimentacao
            FROM movimentacoes_estoques me
            WHERE me.estoque_id = 'bb6539db-6280-447e-82cf-c9c2426ea771'
            ORDER BY me.data_movimentacao DESC;
        """,
        "indexes": ["idx_movimentacoes_estoque_data"]
    },
    {
        "nome": "Consulta 4: Autenticação / Busca de Funcionário por Usuário ID",
        "sql": """
            EXPLAIN (ANALYZE, BUFFERS)
            SELECT f.funcionario_id, f.usuario_id, f.cooperativa_id, f.cargo_id, f.status_funcionario
            FROM funcionarios f
            WHERE f.usuario_id = 'a8b89607-3ad2-4dc1-9bd8-256ecedae36d';
        """,
        "indexes": ["idx_funcionarios_usuario_id"]
    }
]

def run_benchmark():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cur = conn.cursor()

    print("=" * 80)
    print("RENOVAÍ — BENCHMARK EMPÍRICO DE PERFORMANCE (EXPLAIN ANALYZE)")
    print("=" * 80)

    for q in QUERIES:
        print(f"\n>>> {q['nome']}")
        print(f"Índices testados: {', '.join(q['indexes'])}")
        
        # 1. Medição SEM índices (forçando seq scan e desabilitando index scan na sessão)
        cur.execute("SET enable_indexscan = off;")
        cur.execute("SET enable_bitmapscan = off;")
        cur.execute("SET enable_indexonlyscan = off;")
        cur.execute(q["sql"])
        plan_no_index = [row[0] for row in cur.fetchall()]
        
        exec_time_no_idx = 0.0
        cost_no_idx = "N/A"
        for line in plan_no_index:
            if "Execution Time:" in line:
                exec_time_no_idx = float(line.split(":")[1].replace("ms", "").strip())
            if "cost=" in line and cost_no_idx == "N/A":
                cost_no_idx = line.split("cost=")[1].split(" ")[0]

        # 2. Medição COM índices (padrão do otimizador de consultas)
        cur.execute("SET enable_indexscan = on;")
        cur.execute("SET enable_bitmapscan = on;")
        cur.execute("SET enable_indexonlyscan = on;")
        cur.execute(q["sql"])
        plan_with_index = [row[0] for row in cur.fetchall()]
        
        exec_time_with_idx = 0.0
        cost_with_idx = "N/A"
        for line in plan_with_index:
            if "Execution Time:" in line:
                exec_time_with_idx = float(line.split(":")[1].replace("ms", "").strip())
            if "cost=" in line and cost_with_idx == "N/A":
                cost_with_idx = line.split("cost=")[1].split(" ")[0]

        speedup = (exec_time_no_idx / exec_time_with_idx) if exec_time_with_idx > 0 else 1.0
        reducao = ((exec_time_no_idx - exec_time_with_idx) / exec_time_no_idx * 100) if exec_time_no_idx > 0 else 0.0

        print(f"  [SEM ÍNDICE] Custo Estimado: {cost_no_idx:<15} | Tempo Execução: {exec_time_no_idx:.3f} ms")
        print(f"  [COM ÍNDICE] Custo Estimado: {cost_with_idx:<15} | Tempo Execução: {exec_time_with_idx:.3f} ms")
        print(f"  ==> Ganho de Desempenho: {speedup:.1f}x mais rápido ({reducao:.1f}% de redução de latência)")

    conn.close()
    print("\n" + "=" * 80)
    print("Benchmark concluído com sucesso!")
    print("=" * 80)

if __name__ == "__main__":
    run_benchmark()
