CREATE OR REPLACE FUNCTION resumo_avaliacao()
RETURNS TABLE (
  id_avaliacao             integer,
  media_score              numeric(10,2),
  qtd_respostas            integer,
  sentimento_mais_previsto text,
  modelo_mais_utilizado    text
)
LANGUAGE SQL
AS '
  SELECT
    id_avaliacao,
    media_score,
    qtd_respostas,
    sentimento_mais_previsto,
    modelo_mais_utilizado
  FROM vw_resumo_avaliacao
';
