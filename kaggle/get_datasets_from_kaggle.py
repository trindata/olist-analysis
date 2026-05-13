import kagglehub
import shutil
from pathlib import Path

from kaggle.config.config_paths import PATH_RAW_FILES


def get_files_from_kaggle():
    """
    Baixa dataset Olist do Kaggle e copia arquivos CSV para pasta local.
    
    Workflow:
        1. Baixa dataset 'olistbr/brazilian-ecommerce' via kagglehub
        2. Arquivos são salvos automaticamente no cache do kagglehub
        3. Copia todos os CSVs do cache para PATH_RAW_FILES
        
    Requisitos:
        - Credenciais Kaggle configuradas em ~/.kaggle/kaggle.json
        - PATH_RAW_FILES definido em config.config_paths
        - Conexão ativa com internet
        
    Outputs:
        Imprime nome e path local de cada arquivo CSV copiado.
        
    Raises:
        FileNotFoundError: Se diretório cache do Kaggle não for encontrado
        PermissionError: Se não houver permissão de escrita em PATH_RAW_FILES
        
    Example:
        >>> get_files_from_kaggle()
        Arquivo: olist_orders_dataset.csv
        Path: /home/user/project/raw_files/olist_orders_dataset.csv
        
        Arquivo: olist_customers_dataset.csv
        Path: /home/user/project/raw_files/olist_customers_dataset.csv
        ...
    """
    # Baixa para o cache e registra o caminho dos arquivos baixados
    cache = Path(kagglehub.dataset_download("olistbr/brazilian-ecommerce"))

    # Copia os arquivos CSV do cache para a pasta raw_files
    for arquivo in cache.glob("*.csv"):
        shutil.copy(arquivo, PATH_RAW_FILES / arquivo.name)
        print(f"Arquivo: {arquivo.name}")
        print(f"Path: {PATH_RAW_FILES / arquivo.name}\n")


if __name__ == "__main__":
    get_files_from_kaggle()