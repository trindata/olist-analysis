import kagglehub
import shutil
from pathlib import Path

from config.config_paths import PATH_RAW_FILES


def get_files_from_kaggle():
    # Baixa para o cache e registra o caminho dos arquivos baixados
    cache = Path(kagglehub.dataset_download("olistbr/brazilian-ecommerce"))

    # Copia os arquivos CSV do cache para a pasta raw_files
    for arquivo in cache.glob("*.csv"):
        shutil.copy(arquivo, PATH_RAW_FILES / arquivo.name)
        print(f"Arquivo: {arquivo.name}")
        print(f"Path: {PATH_RAW_FILES / arquivo.name}\n")


if __name__ == "__main__":
    get_files_from_kaggle()