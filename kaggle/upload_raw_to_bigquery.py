import pandas as pd

from bigquery_management.funcoes_gestao_bigquery import submeter_bigquery

from config.config_paths import PATH_RAW_FILES
from config.config_raw_tables_olist import TABLES
from config.config_bigquery_raw import BQ_TABLE_MAP


def upload_to_bigquery():
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