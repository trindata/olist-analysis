from __future__ import annotations

import pandas as pd
from google.cloud import bigquery
from google.oauth2 import service_account

from bigquery_management.modelo_bigquery import BigQueryConfig
    
# =============================================================================
# Enviar dado dados ao BigQuery
# =============================================================================

def validar_df_para_bigquery(df: pd.DataFrame) -> None:
    """
    Validações mínimas antes do envio.

    Regras:
    - não pode estar vazio
    - não pode ter colunas duplicadas
    """
    if df.empty:
        raise ValueError(
            "DataFrame vazio: envio cancelado para evitar sobrescrita indevida."
        )

    if df.columns.duplicated().any():
        duplicadas = sorted(set(df.columns[df.columns.duplicated()].tolist()))
        raise ValueError(
            f"DF com colunas duplicadas (não pode enviar): {duplicadas}"
        )


def criar_client_bigquery(table: BigQueryConfig) -> bigquery.Client:
    credentials = service_account.Credentials.from_service_account_file(
        str(table.credentials_json_path)
    )

    return bigquery.Client(
        project=table.project_id,
        credentials=credentials,
        location=table.location,
    )


def submeter_bigquery(
    df: pd.DataFrame,
    table: BigQueryConfig,
) -> str:
    
    try: 
        validar_df_para_bigquery(df)

        client = criar_client_bigquery(table)

        job_config = bigquery.LoadJobConfig(
            write_disposition=table.write_disposition
        )

        job = client.load_table_from_dataframe(
            df,
            table.full_table_id,
            job_config=job_config,
        )
        job.result()
        
        print(f"Dados submetidos com sucesso para: {table.full_table_id}")
    
        return True
    
    except Exception as e:
        print(f"Erro ao submeter dados para {table.full_table_id}: {e}")
        return False


# =============================================================================
# Obter dados e manipular dados do BigQuery
# =============================================================================

def consultar_bigquery(
    query: str,
    *,
    table: BigQueryConfig,
) -> pd.DataFrame:
    client = criar_client_bigquery(table)

    job = client.query(query)
    resultado = job.result()

    return resultado.to_dataframe()