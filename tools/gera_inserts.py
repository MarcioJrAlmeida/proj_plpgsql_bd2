import csv
import io
import os
import re
import sys
import argparse
from urllib.request import urlopen, Request

# ----------------------------
# Configurações padrão (pode mudar por CLI)
# ----------------------------
DEFAULT_URL_FRASES = "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/mj/data/frases_analisadas.csv"
DEFAULT_URL_TREINO = "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/mj/data/treinamento_sentimento.csv"
DEFAULT_OUTFILE = "sql/02_inserts.sql"
BATCH_SIZE = 500

# Ordem das colunas que serão inseridas (DEVEM existir no cabeçalho do CSV)
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

# ----------------------------
# Utils
# ----------------------------
def fetch_text(url: str) -> str:
    req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(req) as r:
        raw = r.read()
    text = raw.decode("utf-8", errors="replace")
    # Falha comum: link HTML (não RAW)
    if "<!DOCTYPE html>" in text or "<html" in text.lower():
        raise ValueError(
            f"Parece que a URL não é RAW do GitHub: {url}\n"
            "Abra o CSV no GitHub, clique em 'Raw' e copie esse link."
        )
    return text

def sniff_delimiter(sample: str) -> str:
    # tenta detectar delimitador automaticamente
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters=[",", ";", "\t"])
        return dialect.delimiter
    except Exception:
        # fallback vírgula
        return ","

def read_csv_dicts(text: str, delimiter: str | None = None) -> list[dict]:
    # normaliza quebras
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    sample = text[:4096]
    delim = delimiter or sniff_delimiter(sample)
    reader = csv.DictReader(io.StringIO(text), delimiter=delim)
    rows = list(reader)
    return rows

def is_nullish(s: str | None) -> bool:
    if s is None:
        return True
    s2 = str(s).strip().lower()
    return s2 in {"", "null", "none", "na", "n/a"}

def as_sql_value(val: str | None) -> str:
    """Converte string do CSV para literal SQL PostgreSQL."""
    if val is None or is_nullish(val):
        return "NULL"
    v = str(val).strip()

    # booleanos comuns
    if v.lower() in {"true", "false"}:
        return v.upper()
    if v in {"0", "1"}:
        return "TRUE" if v == "1" else "FALSE"

    # inteiros / decimais
    if re.fullmatch(r"-?\d+", v):
        return v
    if re.fullmatch(r"-?\d+\.\d+", v):
        return v

    # texto / datas: mantém como string; PostgreSQL interpreta timestamp
    v = v.replace("'", "''")
    return f"'{v}'"

def validate_columns(expected: list[str], rows: list[dict], table: str):
    if not rows:
        print(f"[AVISO] CSV de {table} está vazio.")
        return
    header = list(rows[0].keys())
    missing = [c for c in expected if c not in header]
    if missing:
        raise ValueError(
            f"As colunas {missing} não existem no CSV da tabela {table}.\n"
            f"Cabeçalho encontrado: {header}\n"
            f"Ajuste COLS_* ou o cabeçalho do CSV."
        )

def generate_inserts(table: str, columns: list[str], rows: list[dict]) -> str:
    if not rows:
        return f"-- Nenhuma linha para {table}\n"
    col_list = ", ".join(columns)
    out_lines = []
    batch = []
    for row in rows:
        values = [as_sql_value(row.get(col)) for col in columns]
        batch.append("(" + ", ".join(values) + ")")
        if len(batch) == BATCH_SIZE:
            out_lines.append(
                f"INSERT INTO {table} ({col_list}) VALUES\n  " + ",\n  ".join(batch) + ";\n"
            )
            batch = []
    if batch:
        out_lines.append(
            f"INSERT INTO {table} ({col_list}) VALUES\n  " + ",\n  ".join(batch) + ";\n"
        )
    return "\n".join(out_lines)

# ----------------------------
# Main
# ----------------------------
def main():
    parser = argparse.ArgumentParser(description="Gera INSERTs (PostgreSQL) a partir de CSVs no GitHub.")
    parser.add_argument("--frases-url", default=DEFAULT_URL_FRASES, help="URL RAW do CSV de Frases_Analisadas")
    parser.add_argument("--treino-url", default=DEFAULT_URL_TREINO, help="URL RAW do CSV de Treinamento_Sentimento")
    parser.add_argument("--out", default=DEFAULT_OUTFILE, help="Caminho do arquivo .sql de saída")
    parser.add_argument("--delimiter", default=None, help="Força delimitador do CSV (',' ou ';'). Se omitido, detecta automático.")
    args = parser.parse_args()

    # Lê CSVs
    try:
        txt_frases = fetch_text(args.frases_url)
        txt_treino = fetch_text(args.treino_url)
        frases = read_csv_dicts(txt_frases, delimiter=args.delimiter)
        treino = read_csv_dicts(txt_treino, delimiter=args.delimiter)
    except Exception as e:
        print(f"[ERRO] Falha ao baixar/ler CSVs: {e}", file=sys.stderr)
        sys.exit(1)

    # Valida colunas esperadas
    validate_columns(COLS_FRASES, frases, "Frases_Analisadas")
    validate_columns(COLS_TREINO, treino, "Treinamento_Sentimento")

    # Monta SQL
    parts = []
    parts.append("-- ===============================================")
    parts.append("-- INSERTS AUTOMÁTICOS GERADOS A PARTIR DOS CSVs")
    parts.append("-- Compatível com PostgreSQL 14")
    parts.append("-- ===============================================\n")

    parts.append("-- Tabela: Frases_Analisadas")
    parts.append(generate_inserts("Frases_Analisadas", COLS_FRASES, frases))

    parts.append("-- Tabela: Treinamento_Sentimento")
    parts.append(generate_inserts("Treinamento_Sentimento", COLS_TREINO, treino))

    sql_text = "\n".join(parts).strip() + "\n"

    # Grava arquivo
    out_path = args.out
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(sql_text)

    # Feedback no terminal
    print(f"[OK] Gerado: {out_path}")
    print(f" - Frases_Analisadas: {len(frases)} linhas")
    print(f" - Treinamento_Sentimento: {len(treino)} linhas")

if __name__ == "__main__":
    main()
