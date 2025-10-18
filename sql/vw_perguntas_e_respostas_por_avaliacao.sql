CREATE OR REPLACE VIEW vw_perguntas_e_respostas_por_avaliacao AS
select A.id_avaliacao, P.texto_pergunta, R.conteudo_resposta
FROM pergunta P
JOIN resposta R ON R.id_pergunta = P.id_pergunta
JOIN avaliacao A ON A.id_avaliacao = R.id_avaliacao
GROUP BY A.id_avaliacao, P.id_pergunta, R.id_resposta
ORDER BY A.id_avaliacao, P.texto_pergunta, R.conteudo_resposta;
