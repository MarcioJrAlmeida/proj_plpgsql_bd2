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
DEFAULT_URL_FRASES   = "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/mj/data/frases_analisadas.csv"
DEFAULT_URL_TREINO   = "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/mj/data/treinamento_sentimento.csv"
DEFAULT_URL_AVALIACAO= "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/mj/data/avaliacao.csv"
DEFAULT_URL_PERGUNTA = "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/mj/data/pergunta.csv"
DEFAULT_URL_RESPOSTA = "https://raw.githubusercontent.com/MarcioJrAlmeida/proj_plpgsql_bd2/mj/data/resposta.csv"

DEFAULT_OUTFILE = "sql/02_inserts.sql"
BATCH_SIZE = 500

# ----------------------------
# Colunas esperadas (sem ID, para deixar autoincremento no DB)
# ----------------------------
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

COLS_AVALIACAO = [
    "periodo",
    "data_hr_registro",
    "id_diretor",          # no SQL Server era idDiretor
    "modelo_avaliacao",
    "status_avaliacao",
    "data_lancamento",
]

COLS_PERGUNTA = [
    "texto_pergunta",
    "tipo_pergunta",
    "data_hr_registro",
]

COLS_RESPOSTA = [
    "conteudo_resposta",
    "data_hr_registro",
    "id_avaliacao",        # no SQL Server era idAvaliacao
    "id_pergunta",
]

# ----------------------------
# Mapeamentos de aliases para aceitar cabeçalho vindo do SQL Server
# ----------------------------
ALIASES_AVALIACAO = {
    "iddiretor": "id_diretor",
}
ALIASES_RESPOSTA = {
    "idavaliacao": "id_avaliacao",
}
# (pergunta e frases/treino normalmente já estão adequadas)

# ----------------------------
# Utils
# ----------------------------
def fetch_text(url: str) -> str:
    req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(req) as r:
        raw = r.read()
    text = raw.decode("utf-8", errors="replace")
    if "<!DOCTYPE html>" in text or "<html" in text.lower():
        raise ValueError(
            f"Parece que a URL não é RAW do GitHub: {url}\n"
            "Abra o CSV no GitHub, clique em 'Raw' e copie esse link."
        )
    return text

def sniff_delimiter(sample: str) -> str:
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters=[",", ";", "\t"])
        return dialect.delimiter
    except Exception:
        return ","

def read_csv_dicts(text: str, delimiter: str | None = None) -> list[dict]:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    sample = text[:4096]
    delim = delimiter or sniff_delimiter(sample)
    reader = csv.DictReader(io.StringIO(text), delimiter=delim)
    rows = list(reader)
    return rows

def normalize_header_key(k: str) -> str:
    """
    Normaliza nome de coluna para comparação/mapeamento.
    Ex.: 'idDiretor' -> 'iddiretor', 'id_avaliacao' -> 'idavaliacao'
    """
    if k is None:
        return ""
    s = str(k).strip()
    # remove underscores e baixa para comparar
    return s.replace("_", "").lower()

def remap_rows_aliases(rows: list[dict], alias_map: dict[str, str]) -> list[dict]:
    """
    Recebe um alias_map com chaves normalizadas (sem '_' e lower) e valores target (snake_case).
    Ex.: {'iddiretor': 'id_diretor'}
    Para cada linha, se existir a chave-alias, move o valor para a coluna de destino.
    """
    if not rows:
        return rows
    # constrói mapa normalizado do cabeçalho atual -> chave real
    header_keys = list(rows[0].keys())
    norm_to_real = {normalize_header_key(k): k for k in header_keys}

    updated = []
    for row in rows:
        row2 = dict(row)  # copia
        for alias_norm, target_col in alias_map.items():
            if target_col in row2 and not is_nullish(row2.get(target_col)):
                continue  # já existe com valor
            real_key = norm_to_real.get(alias_norm)
            if real_key and real_key in row2 and not is_nullish(row2.get(real_key)):
                row2[target_col] = row2.get(real_key)
        updated.append(row2)
    return updated

def is_nullish(s: str | None) -> bool:
    if s is None:
        return True
    s2 = str(s).strip().lower()
    return s2 in {"", "null", "none", "na", "n/a"}

def as_sql_value(val: str | None) -> str:
    if val is None or is_nullish(val):
        return "NULL"
    v = str(val).strip()

    if v.lower() in {"true", "false"}:
        return v.upper()
    if v in {"0", "1"}:
        return "TRUE" if v == "1" else "FALSE"

    if re.fullmatch(r"-?\d+", v):
        return v
    if re.fullmatch(r"-?\d+\.\d+", v):
        return v

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
    parser.add_argument("--frases-url",    default=DEFAULT_URL_FRASES,    help="URL RAW do CSV de Frases_Analisadas")
    parser.add_argument("--treino-url",    default=DEFAULT_URL_TREINO,    help="URL RAW do CSV de Treinamento_Sentimento")
    parser.add_argument("--avaliacao-url", default=DEFAULT_URL_AVALIACAO, help="URL RAW do CSV de Avaliacao")
    parser.add_argument("--pergunta-url",  default=DEFAULT_URL_PERGUNTA,  help="URL RAW do CSV de Pergunta")
    parser.add_argument("--resposta-url",  default=DEFAULT_URL_RESPOSTA,  help="URL RAW do CSV de Resposta")
    parser.add_argument("--out",           default=DEFAULT_OUTFILE,       help="Caminho do arquivo .sql de saída")
    parser.add_argument("--delimiter",     default=None,                  help="Força delimitador do CSV (',' ou ';'). Se omitido, detecta automático.")
    args = parser.parse_args()

    # Lê CSVs
    try:
        txt_frases    = fetch_text(args.frases_url)
        txt_treino    = fetch_text(args.treino_url)
        txt_avaliacao = fetch_text(args.avaliacao_url)
        txt_pergunta  = fetch_text(args.pergunta_url)
        txt_resposta  = fetch_text(args.resposta_url)

        frases    = read_csv_dicts(txt_frases,    delimiter=args.delimiter)
        treino    = read_csv_dicts(txt_treino,    delimiter=args.delimiter)
        avaliacao = read_csv_dicts(txt_avaliacao, delimiter=args.delimiter)
        pergunta  = read_csv_dicts(txt_pergunta,  delimiter=args.delimiter)
        resposta  = read_csv_dicts(txt_resposta,  delimiter=args.delimiter)

        # aplica aliases (aceita cabeçalhos camelCase do SQL Server)
        avaliacao = remap_rows_aliases(avaliacao, ALIASES_AVALIACAO)
        resposta  = remap_rows_aliases(resposta,  ALIASES_RESPOSTA)

    except Exception as e:
        print(f"[ERRO] Falha ao baixar/ler CSVs: {e}", file=sys.stderr)
        sys.exit(1)

    # Valida colunas esperadas
    validate_columns(COLS_FRASES,    frases,    "Frases_Analisadas")
    validate_columns(COLS_TREINO,    treino,    "Treinamento_Sentimento")
    validate_columns(COLS_AVALIACAO, avaliacao, "Avaliacao")
    validate_columns(COLS_PERGUNTA,  pergunta,  "Pergunta")
    validate_columns(COLS_RESPOSTA,  resposta,  "Resposta")

    # Monta SQL
    parts = []
    parts.append("-- ===============================================")
    parts.append("-- INSERTS AUTOMÁTICOS GERADOS A PARTIR DOS CSVs")
    parts.append("-- Compatível com PostgreSQL 14 (funciona no SQLiteOnline também)")
    parts.append("-- ===============================================\n")

    parts.append("-- Tabela: Avaliacao")
    parts.append(generate_inserts("avaliacao", COLS_AVALIACAO, avaliacao))

    parts.append("-- Tabela: Pergunta")
    parts.append(generate_inserts("pergunta", COLS_PERGUNTA, pergunta))

    parts.append("-- Tabela: Resposta")
    parts.append(generate_inserts("resposta", COLS_RESPOSTA, resposta))

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
    print(f" - Avaliacao: {len(avaliacao)} linhas")
    print(f" - Pergunta : {len(pergunta)} linhas")
    print(f" - Resposta : {len(resposta)} linhas")
    print(f" - Frases   : {len(frases)} linhas")
    print(f" - Treino   : {len(treino)} linhas")

if __name__ == "__main__":
    main()
