-- A função é executada ANTES de INSERT/UPDATE.
-- Garante que o campo 'classificada_como_sentimento' seja um valor aceitável.

CREATE OR REPLACE FUNCTION trg_treinamento_sentimento_validacao()
RETURNS TRIGGER AS $$
BEGIN
    -- Validação do Sentimento Classificado
    IF NEW.classificada_como_sentimento IS NULL OR NEW.classificada_como_sentimento NOT IN ('Positivo', 'Negativo', 'Neutro', 'A ser revisado') THEN
        RAISE EXCEPTION 'O campo "classificada_como_sentimento" deve ser um dos valores: Positivo, Negativo, Neutro ou A ser revisado.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_update_treinamento_validacao
BEFORE INSERT OR UPDATE ON Treinamento_Sentimento
FOR EACH ROW
EXECUTE FUNCTION trg_treinamento_sentimento_validacao();
