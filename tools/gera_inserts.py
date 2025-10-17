import csv
import io
import re
import sys
from urllib.request import urlopen

# ------- CONFIGURAÇÃO -------

# Coloque aqui as URLs RAW do GitHub (abra o arquivo no GitHub e clique em "Raw")
URL_FRASES = "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/main/frases_analisadas.csv"
URL_TREINO = "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/main/treinamento_sentimento.csv"

# Ordem das colunas que serão inseridas (precisam bater com o cabeçalho do CSV)
# Dica: deixe de fora a coluna 'id' se quiser usar SERIAL.
COLS_FRASES = [
    "id_avaliacao",
    "contexto_pergunta",
    "conteudo_resposta",
    "modelo_utilizado",
    "sentimento_classificado",
    "ofensiva",
    "motivo_ofensivo",
    "score",
    "data_analise",
    "id_pergunta",
    "id_resposta",
]

COLS_TREINO = [
    "contexto_pergunta",
    "conteudo_resposta",
    "classificada_como_sentimento",
    "observacao",
    "data_classificacao",
]

# Tamanho do lote (quantas linhas por INSERT multi-values)
BATCH_SIZE = 500


# ------- FUNÇÕES UTILITÁRIAS -------

def fetch_csv(url: str) -> list[dict]:
    with urlopen(url) as r:
        raw = r.read().decode("utf-8", errors="replace")
    # garante \n
    raw = raw.replace("\r\n", "\n").replace("\r", "\n")
    reader = csv.DictReader(io.StringIO(raw))
    return list(reader)

def is_nullish(s: str) -> bool:
    if s is None:
        return True
    s2 = s.strip().lower()
    return s2 in {"", "null", "none", "na", "n/a"}

def as_sql_value(val: str) -> str:
    """Converte string do CSV para literal SQL PostgreSQL."""
    if val is None or is_nullish(val):
        return "NULL"

    v = val.strip()

    # booleanos comuns
    if v.lower() in {"true", "false"}:
        return v.upper()
    if v in {"0", "1"}:
        return "TRUE" if v == "1" else "FALSE"

    # números (inteiro/decimal) – só se for puramente numérico (com ponto)
    if re.fullmatch(r"-?\d+", v):
        return v
    if re.fullmatch(r"-?\d+\.\d+", v):
        return v

    # timestamp/data: deixe como string – o PostgreSQL interpreta
    # (ex.: 2025-06-30 12:34:56, 2025-06-30T12:34:56Z, etc.)
    # texto: escapa aspas simples
    v = v.replace("'", "''")
    return f"'{v}'"

def generate_inserts(table: str, columns: list[str], rows: list[dict]) -> str:
    if not rows:
        return f"-- Nenhuma linha para {table}\n"
    col_list = ", ".join(columns)
    out_lines = []
    batch = []
    for i, row in enumerate(rows, 1):
        values = [as_sql_value(row.get(col)) for col in columns]
        batch.append("(" + ", ".join(values) + ")")
        if len(batch) == BATCH_SIZE:
            out_lines.append(f"INSERT INTO {table} ({col_list}) VALUES\n  " + ",\n  ".join(batch) + ";\n")
            batch = []
    if batch:
        out_lines.append(f"INSERT INTO {table} ({col_list}) VALUES\n  " + ",\n  ".join(batch) + ";\n")
    return "\n".join(out_lines)

# ------- GERAÇÃO -------

def main():
    try:
        frases = fetch_csv(URL_FRASES)
        treino = fetch_csv(URL_TREINO)
    except Exception as e:
        print(f"-- ERRO AO BAIXAR CSVs: {e}", file=sys.stderr)
        sys.exit(1)

    # Saída
    print("-- ===============================================")
    print("-- INSERTS AUTOMÁTICOS GERADOS A PARTIR DOS CSVs")
    print("-- ===============================================\n")

    print("-- Tabela: Frases_Analisadas")
    print(generate_inserts("Frases_Analisadas", COLS_FRASES, frases))

    print("-- Tabela: Treinamento_Sentimento")
    print(generate_inserts("Treinamento_Sentimento", COLS_TREINO, treino))

if __name__ == "__main__":
    main() 