import pandas as pd

from bigquery.funcoes_gestao_bigquery import submeter_bigquery

from kaggle.config.config_paths import PATH_RAW_FILES
from kaggle.config.config_raw_tables_olist import TABLES
from kaggle.config.config_bigquery_raw import BQ_TABLE_MAP


def upload_to_bigquery():
    """
    Carrega arquivos CSV do Olist para tabelas raw no BigQuery.
    
    Para cada tabela definida em TABLES:
        1. Lê CSV com encoding específico
        2. Exibe shape e lista de colunas
        3. Submete DataFrame para BigQuery usando configuração mapeada
        
    Requisitos:
        - Arquivos CSV em PATH_RAW_FILES (executar get_files_from_kaggle() antes)
        - Service account configurada em GOOGLE_CREDENTIALS (.env)
        - Datasets e tabelas já criados no BigQuery
        
    Outputs:
        Imprime shape e colunas de cada tabela antes do upload.
        
    Raises:
        FileNotFoundError: Se arquivo CSV não existir em PATH_RAW_FILES
        UnicodeDecodeError: Se encoding especificado estiver incorreto
        google.api_core.exceptions.GoogleAPIError: Erros de autenticação ou upload BigQuery
    """
    for nome, (arquivo, encoding) in TABLES.items():
        # Lê o arquivo CSV para obter informações sobre colunas e linhas
        df = pd.read_csv(PATH_RAW_FILES / arquivo, encoding=encoding)

        # Exibe o nome do arquivo, número de linhas, colunas e os nomes das colunas
        print(f"\n{nome}: {df.shape[0]} linhas, {df.shape[1]} colunas")
        print(f"Colunas:")
        for coluna in df.columns:
            print(f" - {coluna}")

        # Submete cada DataFrame para o BigQuery usando a configuração mapeada
        submeter_bigquery(
            df=df,
            table=BQ_TABLE_MAP[nome],
        )


if __name__ == "__main__":
    upload_to_bigquery()