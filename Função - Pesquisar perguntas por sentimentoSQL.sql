--- 18-10-2025 15:00:11 PostgreSQL.4
-- 3) Pesquisar perguntas por sentimento (recebe a classificação de sentimento, neutro, positvo ou negativo)
CREATE OR REPLACE FUNCTION buscar_frases_por_sentimento(
    p_sentimento VARCHAR,
    p_id_pergunta INTEGER DEFAULT NULL
)
RETURNS TABLE (
    id_resposta_retorno INTEGER,
    conteudo_resposta_retorno TEXT,
    contexto_pergunta_retorno VARCHAR,
    sentimento_classificado_retorno VARCHAR,
    score_retorno NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        FA.id_resposta,
        FA.conteudo_resposta,
        FA.contexto_pergunta,
        FA.sentimento_classificado,
        FA.score
    FROM
        Frases_Analisadas FA
    WHERE
        FA.sentimento_classificado = p_sentimento
        AND (p_id_pergunta IS NULL OR FA.id_pergunta = p_id_pergunta)
    ORDER BY
        FA.data_analise DESC, FA.score DESC;
END;
$$ LANGUAGE plpgsql;



