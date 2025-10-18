CREATE OR REPLACE FUNCTION trg_treinamento_sentimento_data_hr()
RETURNS TRIGGER AS $$
BEGIN
    -- Preenche a data de classificação no momento da inserção ou atualização
    NEW.data_classificacao := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_update_treinamento_sentimento
BEFORE INSERT OR UPDATE ON Treinamento_Sentimento
FOR EACH ROW
EXECUTE FUNCTION trg_treinamento_sentimento_data_hr();
