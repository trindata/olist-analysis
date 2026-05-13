from kaggle.get_datasets_from_kaggle import get_files_from_kaggle
from kaggle.upload_raw_to_bigquery import upload_to_bigquery

if __name__ == "__main__":
    """Executa o processo completo de obtenção dos arquivos do Kaggle e upload para BigQuery."""
    get_files_from_kaggle()
    upload_to_bigquery()