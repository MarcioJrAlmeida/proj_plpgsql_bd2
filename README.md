# 🧠 Projeto BD II — Machine Learning de Sentimentos e Ofensas

Este repositório faz parte do projeto da disciplina **Banco de Dados II (IFPE)**.  
O objetivo é **evoluir um banco de dados já existente** (do projeto de Machine Learning aplicado à Engenharia de Software) para uma **versão com código PL/pgSQL**, incluindo funções, triggers, visões e regras de negócio no **PostgreSQL 14**.

---

## 🎯 Propósito do Repositório

O banco de dados foi originalmente utilizado no projeto de **análise de sentimentos e ofensas em respostas de formulários**, com duas tabelas principais:

- **`Frases_Analisadas`** → armazena o resultado das análises automáticas de sentimentos e ofensas.
- **`Treinamento_Sentimento`** → armazena exemplos rotulados manualmente, utilizados para re-treinar o modelo de Machine Learning.

O presente repositório foi estruturado para atender aos seguintes objetivos:

1. Disponibilizar o **esquema do banco de dados** (`CREATE TABLE`) compatível com PostgreSQL 14.
2. Fornecer um **script gerador de INSERTs automáticos** a partir dos arquivos CSV hospedados no próprio GitHub.
3. Servir como base para as próximas etapas do projeto, onde serão criadas:
   - **6 funções PL/pgSQL** (com tipos de retorno variados);
   - **Triggers** (para auditoria, validação e automação de campos);
   - **Visões (Views)** com relatórios analíticos;
   - Estruturas condicionais e tratamento de exceções.

---

## 🗂️ Estrutura do Repositório

```bash
bd2-ml-sentimento/
├─ data/
│  ├─ frases_analizadas.csv
│  └─ treinamento_sentimento.csv
│
├─ sql/
│  ├─ 01_schema_postgres.sql    # Criação das tabelas (DDL)
│  └─ 02_inserts.sql            # Script de inserts (gerado automaticamente)
│
├─ tools/
│  └─ gera_inserts.py           # Script Python para gerar os INSERTs
│
└─ README.md
```
## ⚙️ Como Funciona o gera_inserts.py

O arquivo tools/gera_inserts.py automatiza a criação de instruções SQL INSERT a partir dos CSVs disponíveis no GitHub.
Isso é útil porque o ambiente do SQLiteOnline não permite o uso direto de comandos como \COPY.

### 🔍 O que o script faz

1. Lê os CSVs diretamente a partir das URLs “raw” do GitHub.
2. Trata automaticamente valores nulos, booleanos e datas.
3. Gera blocos de INSERTs em formato compatível com PostgreSQL 14.
4. Cria os inserts em lotes de até 500 linhas por comando (para performance).
5. Imprime o resultado no terminal (você pode redirecionar para um arquivo .sql).

## 🚀 Como Usar

### 1️⃣ — Configure as URLs dos CSVs

No início do arquivo gera_inserts.py, substitua as URLs pelos links “raw” dos seus arquivos CSV no GitHub:
```bash
URL_FRASES = "https://raw.githubusercontent.com/<usuario>/<repo>/<branch>/data/frases_analizadas.csv"
URL_TREINO = "https://raw.githubusercontent.com/<usuario>/<repo>/<branch>/data/treinamento_sentimento.csv"
```
#### 💡 Dica: no GitHub, abra o CSV → clique em “Raw” → copie o link.

### 2️⃣ — Execute o script

No terminal, dentro da pasta do projeto:
```bash
python tools/gera_inserts.py > sql/02_inserts.sql
```
Isso vai gerar um arquivo sql/02_inserts.sql com todos os INSERT INTO ... VALUES ...;.

### 3️⃣ — Execute no SQLiteOnline (modo PostgreSQL 14)

1. Acesse: https://sqliteonline.com/
2. No canto superior esquerdo, escolha o banco PostgreSQL 14.
3. Copie e execute primeiro o script:
```
sql/01_schema_postgres.sql
```
(criação das tabelas)
4. Em seguida, cole o conteúdo de:
```
sql/02_inserts.sql
```
(inserção dos dados)