from kaggle.get_datasets_from_kaggle import get_files_from_kaggle
from kaggle.upload_raw_to_bigquery import upload_to_bigquery

if __name__ == "__main__":
    get_files_from_kaggle()
    upload_to_bigquery()