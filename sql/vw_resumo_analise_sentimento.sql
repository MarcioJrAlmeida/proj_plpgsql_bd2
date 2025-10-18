-- Contagem de frases classificadas por sentimento e modelo, com o score médio.
CREATE OR REPLACE VIEW vw_resumo_analise_sentimento AS
SELECT 
	modelo_utilizado,
  sentimento_classificado,
  COUNT(id) AS total_frases,
  ROUND(AVG(score), 4) AS score_medio,
  MIN(data_analise) AS primeira_analise,
  MAX(data_analise) AS ultima_analise
From frases_analisadas
GROUP BY modelo_utilizado, sentimento_classificado
ORDER BY modelo_utilizado, total_frases DESC;
