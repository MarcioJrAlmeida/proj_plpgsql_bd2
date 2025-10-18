DROP FUNCTION IF EXISTS score_medio_avaliacao(integer);

CREATE OR REPLACE FUNCTION score_medio_avaliacao(p_id_avaliacao integer)
RETURNS numeric(10,2)
LANGUAGE sql
AS $$
  SELECT COALESCE(ROUND(AVG(score)::numeric, 2), 0.00)
  FROM frases_analisadas
  WHERE id_avaliacao = p_id_avaliacao
$$;

-- Calcular e retornar a média dos scores (pontuações) das análises de sentimento geradas 
-- pelos modelos de Machine Learning para uma avaliação específica.