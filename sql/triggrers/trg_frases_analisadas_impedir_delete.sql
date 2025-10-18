-- A função 'trg_frases_analisadas_impedir_delete' é executada ANTES da deleção.
-- Ela utiliza 'RAISE EXCEPTION' para bloquear a operação de DELETE, mantendo 
-- todos os registros de análises.

CREATE OR REPLACE FUNCTION trg_frases_analisadas_impedir_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'A exclusão de registros da tabela "Frases_Analisadas" não é permitida.';
END;
$$ LANGUAGE plpgsql;

-- Criação da Trigger 1.2
CREATE TRIGGER before_delete_frases_analisadas
BEFORE DELETE ON Frases_Analisadas
FOR EACH ROW
EXECUTE FUNCTION trg_frases_analisadas_impedir_delete();
