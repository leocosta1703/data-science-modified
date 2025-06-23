#!/bin/bash

# --- Configurações Iniciais ---
PROJECT_ID="demos-419316"             # Substitua pelo ID do seu projeto no GCP

DATASET_ID="ds_glosas"             # Substitua pelo ID do seu dataset no BigQuery (ex: meu_dataset)

TABLE_ID_BRASINDICE="referencia_brasindice"              # Nome da nova tabela que será criada
TABLE_ID_GLOSA_PRECIFICACAO="base_glosas_precificacao_medicamentos"
TABLE_ID_GLOSA_CODIFICACAO="base_glosas_codificacao_medicamentos"
TABLE_ID_RESULTADO_ANALISE="resultado_analise"
TABLE_ID_REGRAS_CONTRATUAIS="regras_contratuais"

BUCKET_NAME="demos-leocosta"           # Nome do seu bucket no GCS (ex: meu-bucket-dados)

FILE_NAME_1="Brasindice 1031 (23-10-2023) Arquivo Consulta.csv"             # Nome do seu arquivo CSV no bucket
FILE_NAME_2="Brasindice 1034 (05-12-2023) Arquivo Consulta 1.csv"
FILE_NAME_3="Glosas precificação.csv"
FILE_NAME_4="Glosas codificação.csv"
FILE_NAME_5="Regras Contratuais.csv"

# Caminho completo do arquivo CSV no GCS
GCS_URI_BRASINDICE_1="gs://${BUCKET_NAME}/${FILE_NAME_1}"
GCS_URI_BRASINDICE_2="gs://${BUCKET_NAME}/${FILE_NAME_2}"
GCS_URI_GLOSA_PRECIFICACAO="gs://${BUCKET_NAME}/${FILE_NAME_3}"
GCS_URI_GLOSA_CODIFICACAO="gs://${BUCKET_NAME}/${FILE_NAME_4}"
GCS_URI_REGRAS_CONTRATUAIS="gs://${BUCKET_NAME}/${FILE_NAME_5}"

# --- Carregando o CSV para o BigQuery ---
echo "Iniciando o carregamento do arquivo CSV do GCS para o BigQuery..."
echo "Projeto: ${PROJECT_ID}"
echo "Dataset: ${DATASET_ID}"

echo "Criando tabela resultado_analise"
bq mk --table --schema ./resultado_analise_schema.json ${DATASET_ID}.${TABLE_ID_RESULTADO_ANALISE}

# Comando bq load
echo "Tabela: ${TABLE_ID_REGRAS_CONTRATUAIS}"
echo "URI do GCS: ${GCS_URI_REGRAS_CONTRATUAIS}"
bq --project_id="${PROJECT_ID}" load \
    --source_format=CSV \
    --field_delimiter=";" \
    "${DATASET_ID}.${TABLE_ID_REGRAS_CONTRATUAIS}" \
    "${GCS_URI_REGRAS_CONTRATUAIS}" \
    ./regras_contratuais_schema.json

echo "Tabela: ${TABLE_ID_BRASINDICE}"
echo "URI do GCS: ${GCS_URI_BRASINDICE_1}"
bq --project_id="${PROJECT_ID}" load \
    --source_format=CSV \
    --autodetect \
    --field_delimiter=";" \
    "${DATASET_ID}.${TABLE_ID_BRASINDICE}" \
    "${GCS_URI_BRASINDICE_1}"


echo "URI do GCS: ${GCS_URI_BRASINDICE_2}"
bq --project_id="${PROJECT_ID}" load \
    --source_format=CSV \
    --autodetect \
    --field_delimiter=";" \
    "${DATASET_ID}.${TABLE_ID_BRASINDICE}" \
    "${GCS_URI_BRASINDICE_2}"


echo "Tabela: ${TABLE_ID_GLOSA_PRECIFICACAO}"
echo "URI do GCS: ${GCS_URI_GLOSA_PRECIFICACAO}"
bq --project_id="${PROJECT_ID}" load \
    --source_format=CSV \
    --autodetect \
    "${DATASET_ID}.${TABLE_ID_GLOSA_PRECIFICACAO}" \
    "${GCS_URI_GLOSA_PRECIFICACAO}"


echo "Tabela: ${TABLE_ID_GLOSA_CODIFICACAO}"
echo "URI do GCS: ${GCS_URI_GLOSA_CODIFICACAO}"
bq --project_id="${PROJECT_ID}" load \
    --source_format=CSV \
    --autodetect \
    "${DATASET_ID}.${TABLE_ID_GLOSA_CODIFICACAO}" \
    "${GCS_URI_GLOSA_CODIFICACAO}"

# --- PASSO 1: Adicionar as colunas (Execute apenas se as colunas não existirem) ---
echo "Adicionando coluna Inicio_Periodo..."
bq query --use_legacy_sql=false \
  "ALTER TABLE ${PROJECT_ID}.${DATASET_ID}.${TABLE_ID_BRASINDICE} ADD COLUMN Inicio_Periodo DATE;"

echo "Adicionando coluna Fim_Periodo..."
bq query --use_legacy_sql=false \
  "ALTER TABLE ${PROJECT_ID}.${DATASET_ID}.${TABLE_ID_BRASINDICE} ADD COLUMN Fim_Periodo DATE;"

# --- PASSO 2: Atualizar os valores das colunas ---
echo "Atualizando os valores de Inicio_Periodo e Fim_Periodo..."
bq query --use_legacy_sql=false \
  "UPDATE \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID_BRASINDICE}\`
   SET
     Inicio_Periodo = CASE
       WHEN MSG = 1031 THEN DATE('2023-10-23')
       WHEN MSG = 1034 THEN DATE('2023-12-05')
       ELSE NULL
     END,
     Fim_Periodo = CASE
       WHEN MSG = 1031 THEN DATE('2023-10-30')
       WHEN MSG = 1034 THEN DATE('2023-12-20')
       ELSE NULL
     END
   WHERE
     MSG IN (1031, 1034);"

echo "Script de atualização concluído."

# Verificando o status do comando
if [ $? -eq 0 ]; then
    echo "Carregamento concluído com sucesso! A tabela '${TABLE_ID_BRASINDICE}' foi criada/atualizada no BigQuery."
else
    echo "Erro durante o carregamento do CSV. Verifique as mensagens de erro acima."
    exit 1 # Sai com código de erro
fi
