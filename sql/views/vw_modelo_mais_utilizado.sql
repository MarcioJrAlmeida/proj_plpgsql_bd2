CREATE OR REPLACE VIEW vw_modelos_mais_usados AS
SELECT
  modelo_utilizado,
  COUNT(*)                       AS qtd_uso,
  ROUND(AVG(score)::numeric, 2)  AS media_score
FROM frases_analisadas
GROUP BY modelo_utilizado
ORDER BY qtd_uso DESC;