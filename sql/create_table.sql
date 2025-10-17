-- ===============================================
-- BANCO: MachineLearningDB
-- Tabelas: Frases_Analisadas e Treinamento_Sentimento
-- ===============================================

-- ===============================================
-- Tabela 1: Frases_Analisadas
-- ===============================================
CREATE TABLE Frases_Analisadas (
    id SERIAL PRIMARY KEY,
    id_avaliacao INTEGER,
    contexto_pergunta VARCHAR(255),
    conteudo_resposta TEXT,
    modelo_utilizado VARCHAR(100),
    sentimento_classificado VARCHAR(20),
    ofensiva BOOLEAN,
    motivo_ofensivo VARCHAR(200),
    score NUMERIC(10,4),
    data_analise TIMESTAMP,
    id_pergunta INTEGER,
    id_resposta INTEGER
);

-- ===============================================
-- Tabela 2: Treinamento_Sentimento
-- ===============================================
CREATE TABLE Treinamento_Sentimento (
    id SERIAL PRIMARY KEY,
    contexto_pergunta TEXT,
    conteudo_resposta TEXT,
    classificada_como_sentimento VARCHAR(20),
    observacao VARCHAR(255),
    data_classificacao TIMESTAMP
);

-- 1) AVALIACAO
DROP TABLE IF EXISTS avaliacao;

CREATE TABLE avaliacao (
    id_avaliacao      INTEGER PRIMARY KEY AUTOINCREMENT,
    periodo           INTEGER,
    data_hr_registro  TIMESTAMP,
    id_diretor        INTEGER,          -- FK no SQL Server (diretor). Tabela não enviada.
    modelo_avaliacao  TEXT,             -- nvarchar(max)
    status_avaliacao  VARCHAR(10),
    data_lancamento   TIMESTAMP
);

-- 2) PERGUNTA
DROP TABLE IF EXISTS pergunta;

CREATE TABLE pergunta (
    id_pergunta       INTEGER PRIMARY KEY AUTOINCREMENT,
    texto_pergunta    VARCHAR(255),
    tipo_pergunta     VARCHAR(50),
    data_hr_registro  TIMESTAMP
);


-- 3) RESPOSTA
DROP TABLE IF EXISTS resposta;

CREATE TABLE resposta (
    id_resposta       INTEGER PRIMARY KEY AUTOINCREMENT,
    conteudo_resposta TEXT,             -- nvarchar(max)
    data_hr_registro  TIMESTAMP,
    id_avaliacao      INTEGER,
    id_pergunta       INTEGER,
    CONSTRAINT fk_resposta_avaliacao
        FOREIGN KEY (id_avaliacao) REFERENCES avaliacao(id_avaliacao),
    CONSTRAINT fk_resposta_pergunta
        FOREIGN KEY (id_pergunta)  REFERENCES pergunta(id_pergunta)
);

-- (Opcional) Índices auxiliares para FKs
CREATE INDEX IF NOT EXISTS ix_resposta_id_avaliacao ON resposta(id_avaliacao);
CREATE INDEX IF NOT EXISTS ix_resposta_id_pergunta  ON resposta(id_pergunta);