CREATE OR REPLACE VIEW vw_modelos_mais_usados AS
SELECT
  modelo_utilizado,
  COUNT(*)                       AS qtd_uso,
  ROUND(AVG(score)::numeric, 2)  AS media_score
FROM frases_analisadas
GROUP BY modelo_utilizado
ORDER BY qtd_uso DESC;

-- Apresentar um ranking dos modelos de Machine Learning utilizados nas análises de sentimento, 
-- mostrando quantas vezes cada modelo foi aplicado e qual foi o desempenho médio (score) obtido 
-- em suas classificações.