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

-- Retornar um resumo consolidado das avaliações, agrupando informações analíticas sobre desempenho 
-- e sentimento, a partir da view vw_resumo_avaliacao.
-- Em outras palavras, essa função serve como porta de acesso simplificada à visão vw_resumo_avaliacao,
-- permitindo consultar diretamente as métricas resumidas sem precisar escrever a query completa da 
-- view.