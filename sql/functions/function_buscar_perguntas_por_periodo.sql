-- 2) Pesquisar perguntas por período (recebe o número do período)
CREATE OR REPLACE FUNCTION buscar_perguntas_por_periodo(p_periodo INT)
RETURNS TABLE (
    id_pergunta_retorno INTEGER,
    texto_pergunta_retorno VARCHAR,
    tipo_pergunta_retorno VARCHAR,
    id_avaliacao_retorno INTEGER,
    periodo_avaliacao_retorno INTEGER
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        P.id_pergunta,
        P.texto_pergunta,
        P.tipo_pergunta,
        A.id_avaliacao,
        A.periodo
    FROM
        pergunta P
    JOIN
        Contem C ON P.id_pergunta = C.id_pergunta
    JOIN
        avaliacao A ON C.id_avaliacao = A.id_avaliacao
    WHERE
        A.periodo = p_periodo
    ORDER BY
        A.id_avaliacao, P.id_pergunta;
END;
$$ LANGUAGE plpgsql;

--Retorna as perguntas contidas na avaliação do período



