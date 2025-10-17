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