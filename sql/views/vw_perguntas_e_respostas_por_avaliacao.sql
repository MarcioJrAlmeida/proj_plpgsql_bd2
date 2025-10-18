-- View Perguntas e Respostas por Avaliação
CREATE OR REPLACE VIEW vw_perguntas_e_respostas_por_avaliacao AS
SELECT 
    A.id_avaliacao, 
    P.texto_pergunta, 
    R.conteudo_resposta
FROM avaliacao A
JOIN contem C ON C.id_avaliacao = A.id_avaliacao
JOIN pergunta P ON P.id_pergunta = C.id_pergunta
JOIN resposta R ON R.id_pergunta = P.id_pergunta
GROUP BY A.id_avaliacao, P.id_pergunta, R.id_resposta
ORDER BY A.id_avaliacao, P.texto_pergunta, R.conteudo_resposta;

-- Apresentar, de forma consolidada, todas as perguntas e suas respectivas respostas 
-- relacionadas a cada avaliação registrada no sistema.
-- Essa visão facilita a análise dos conteúdos respondidos em cada avaliação, permitindo 
-- uma leitura direta das interações realizadas entre avaliador e avaliado.