CREATE OR REPLACE FUNCTION publicar_avaliacao(
  p_id_avaliacao  integer,
  p_min_score     numeric DEFAULT 0.50,
  p_max_ofensivas numeric DEFAULT 30.00
)
RETURNS void
LANGUAGE plpgsql
AS 
DECLARE
  v_existe           boolean;
  v_status           text;
  v_total_respostas  integer;
  v_total_analises   integer;
  v_ofensivas        integer;
  v_perc_ofensivas   numeric(10,2);
  v_media_score      numeric(10,2);
BEGIN
  SELECT EXISTS(SELECT 1 FROM avaliacao WHERE id_avaliacao = p_id_avaliacao) INTO v_existe;
  IF NOT v_existe THEN
    RAISE EXCEPTION ''Avaliacao % nao existe.'', p_id_avaliacao;
  END IF;

  SELECT COALESCE(status_avaliacao, '''') INTO v_status
  FROM avaliacao WHERE id_avaliacao = p_id_avaliacao;

  IF v_status ILIKE ''fechada'' OR v_status ILIKE ''publicada'' THEN
    RAISE EXCEPTION ''Avaliacao % ja esta %.'', p_id_avaliacao, v_status;
  END IF;

  SELECT COUNT(DISTINCT r.id_resposta) INTO v_total_respostas
  FROM resposta r WHERE r.id_avaliacao = p_id_avaliacao;
  IF v_total_respostas = 0 THEN
    RAISE EXCEPTION ''Avaliacao % nao possui respostas.'', p_id_avaliacao;
  END IF;

  SELECT COUNT(*), SUM(CASE WHEN ofensiva IS TRUE THEN 1 ELSE 0 END)
  INTO v_total_analises, v_ofensivas
  FROM frases_analisadas WHERE id_avaliacao = p_id_avaliacao;
  IF v_total_analises = 0 THEN
    RAISE EXCEPTION ''Avaliacao % nao possui analises de ML.'', p_id_avaliacao;
  END IF;

  v_perc_ofensivas := ROUND(100.0 * v_ofensivas::numeric / NULLIF(v_total_analises,0), 2);
  v_media_score    := score_medio_avaliacao(p_id_avaliacao);

  IF v_media_score < p_min_score THEN
    RAISE EXCEPTION ''Score medio % abaixo do minimo % para avaliacao %.'',
      v_media_score, p_min_score, p_id_avaliacao;
  END IF;

  IF v_perc_ofensivas > p_max_ofensivas THEN
    RAISE EXCEPTION ''Percentual de ofensas % acima do maximo % para avaliacao %.'',
      v_perc_ofensivas || ''%'', p_max_ofensivas || ''%'', p_id_avaliacao;
  END IF;

  UPDATE avaliacao
     SET status_avaliacao = ''publicada'',
         data_lancamento  = COALESCE(data_lancamento, CURRENT_TIMESTAMP)
   WHERE id_avaliacao     = p_id_avaliacao;

  RAISE NOTICE ''Avaliacao % publicada. media_score=%, ofensas=% , respostas=%'',
       p_id_avaliacao, v_media_score, v_perc_ofensivas || ''%'', v_total_respostas;
END;

-- Validar se uma avaliação está pronta para ser publicada, aplicando regras de negócio automáticas.
-- Se as condições forem atendidas, a função atualiza o status da avaliação para 'publicada'.
-- Caso contrário, lança exceções detalhando o problema.
