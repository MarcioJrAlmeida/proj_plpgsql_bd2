-- View Resumo Avaliação
CREATE OR REPLACE VIEW vw_resumo_avaliacao AS
WITH base AS (
  SELECT
    a.id_avaliacao,
    p.id_pergunta,
    r.id_resposta,
    fa.score,
    fa.sentimento_classificado,
    fa.modelo_utilizado
  FROM avaliacao a
  JOIN contem    c ON a.id_avaliacao = c.id_avaliacao
  JOIN pergunta  p ON c.id_pergunta  = p.id_pergunta
  JOIN resposta  r ON r.id_avaliacao = a.id_avaliacao
                  AND r.id_pergunta  = p.id_pergunta
  JOIN frases_analisadas fa
       ON fa.id_avaliacao = a.id_avaliacao
      AND fa.id_pergunta  = p.id_pergunta
      AND fa.id_resposta  = r.id_resposta
  WHERE p.tipo_pergunta = 'Aberta'
),
agg AS (
  SELECT
    id_avaliacao,
    ROUND(AVG(score)::numeric, 2) AS media_score,
    COUNT(DISTINCT id_resposta)   AS qtd_respostas
  FROM base
  GROUP BY id_avaliacao
),
senti AS (
  SELECT
    id_avaliacao,
    sentimento_classificado,
    ROW_NUMBER() OVER (
      PARTITION BY id_avaliacao
      ORDER BY COUNT(*) DESC, sentimento_classificado
    ) AS rn
  FROM base
  GROUP BY id_avaliacao, sentimento_classificado
),
model AS (
  SELECT
    id_avaliacao,
    modelo_utilizado,
    ROW_NUMBER() OVER (
      PARTITION BY id_avaliacao
      ORDER BY COUNT(*) DESC, modelo_utilizado
    ) AS rn
  FROM base
  GROUP BY id_avaliacao, modelo_utilizado
)
SELECT
  agg.id_avaliacao,
  agg.media_score,
  agg.qtd_respostas,
  senti.sentimento_classificado AS sentimento_mais_previsto,
  model.modelo_utilizado        AS modelo_mais_utilizado
FROM agg
LEFT JOIN senti ON senti.id_avaliacao = agg.id_avaliacao AND senti.rn = 1
LEFT JOIN model ON model.id_avaliacao = agg.id_avaliacao AND model.rn = 1
ORDER BY agg.id_avaliacao;

-- Gerar um resumo consolidado das avaliações, apresentando indicadores gerais de desempenho, 
-- sentimento predominante e modelo de Machine Learning mais utilizado nas análises.