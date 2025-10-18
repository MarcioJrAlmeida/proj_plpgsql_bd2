-- Lista perguntas cujas respostas não foram analisadas pelo modelo de ML
CREATE OR REPLACE VIEW vw_perguntas_sem_analise_ml AS
SELECT
    a.id_avaliacao,
    a.modelo_avaliacao,
    p.id_pergunta,
    p.texto_pergunta,
    COUNT(R.id_resposta) AS total_respostas_sem_analise
FROM
    avaliacao a
JOIN resposta R ON a.id_avaliacao = R.id_avaliacao
JOIN pergunta p ON R.id_pergunta = p.id_pergunta
LEFT JOIN frases_Analisadas fa ON R.id_resposta = fa.id_resposta
WHERE fa.id_resposta IS NULL -- Respostas que não possuem um registro correspondente em Frases_Analisadas
GROUP BY a.id_avaliacao, a.modelo_avaliacao, p.id_pergunta, p.texto_pergunta
ORDER BY total_respostas_sem_analise DESC;
