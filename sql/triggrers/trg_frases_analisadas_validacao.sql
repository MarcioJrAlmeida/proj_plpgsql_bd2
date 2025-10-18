-- A função 'trg_frases_analisadas_validacao' é executada ANTES de qualquer INSERT ou UPDATE.
-- Ela checa as condições de negócio e, se alguma falhar, utiliza 'RAISE EXCEPTION' para 
-- abortar a operação e informar o erro.
-- Se as validações passarem, a função retorna 'NEW', permitindo a continuação da operação, 
-- após possivelmente preencher o campo 'data_analise' e limpar 'motivo_ofensivo' (se ofensiva=FALSE).

CREATE OR REPLACE FUNCTION trg_frases_analisadas_validacao()
RETURNS TRIGGER AS $$
BEGIN
    -- Validação do Sentimento Classificado
    IF NEW.sentimento_classificado IS NULL OR NEW.sentimento_classificado NOT IN ('Positivo', 'Negativo', 'Neutro', 'Indefinido') THEN
        RAISE EXCEPTION 'O campo "sentimento_classificado" deve ser um dos valores: Positivo, Negativo, Neutro ou Indefinido.';
    END IF;

    -- Validação de Frase Ofensiva
    IF NEW.ofensiva IS TRUE THEN
        IF NEW.motivo_ofensivo IS NULL OR TRIM(NEW.motivo_ofensivo) = '' THEN
            RAISE EXCEPTION 'O campo "motivo_ofensivo" é obrigatório quando a frase é classificada como ofensiva.';
        END IF;
    ELSE
        -- Garante que o motivo_ofensivo seja NULL/vazio se não for ofensiva
        NEW.motivo_ofensivo := NULL;
    END IF;

    -- Validação do Score
    IF NEW.score IS NULL OR NEW.score < 0.0 OR NEW.score > 1.0 THEN
        RAISE EXCEPTION 'O campo "score" deve ser um valor entre 0.0 e 1.0.';
    END IF;

    -- Preenchimento da Data de Análise (se não fornecida)
    IF NEW.data_analise IS NULL THEN
        NEW.data_analise := NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_update_frases_analisadas
BEFORE INSERT OR UPDATE ON Frases_Analisadas
FOR EACH ROW
EXECUTE FUNCTION trg_frases_analisadas_validacao();
