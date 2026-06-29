from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Optional, Literal
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

WriteDisposition = Literal["WRITE_TRUNCATE", "WRITE_APPEND", "WRITE_EMPTY"]

CREDENCIAIS = Path(os.environ["GOOGLE_CREDENTIALS"])

if not CREDENCIAIS.exists():
    raise FileNotFoundError(f"Credencial BigQuery não encontrada em: {CREDENCIAIS}")

@dataclass(frozen=True)
class BigQueryConfig:
    project_id: str
    dataset: str
    table: str
    credentials_json_path: Path = CREDENCIAIS
    location: Optional[str] = "US"
    write_disposition: WriteDisposition = "WRITE_TRUNCATE"

    @property
    def full_table_id(self) -> str:
        return f"{self.project_id}.{self.dataset}.{self.table}"