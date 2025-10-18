--- 18-10-2025 14:58:46 PostgreSQL.2
-- 1) Pesquisar pergunta por id_avaliação (recebe o id_avaliacao)
CREATE OR REPLACE FUNCTION buscar_perguntas_por_avaliacao(p_id_avaliacao INT)
RETURNS TABLE (
    id_pergunta_retorno INTEGER,
    texto_pergunta_retorno VARCHAR,
    tipo_pergunta_retorno VARCHAR,
    data_registro_retorno TIMESTAMP
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        P.id_pergunta,
        P.texto_pergunta,
        P.tipo_pergunta,
        P.data_hr_registro
    FROM
        pergunta P
    JOIN
        Contem C ON P.id_pergunta = C.id_pergunta
    WHERE
        C.id_avaliacao = p_id_avaliacao
    ORDER BY
        P.id_pergunta;
END;
$$ LANGUAGE plpgsql;

-- Retorna as perguntas associadas a essa avaliação, a data e o registro da pergunta.




