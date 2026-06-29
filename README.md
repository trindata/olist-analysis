![dbt](https://img.shields.io/badge/dbt-FF694B?logo=dbt&logoColor=white)
![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?logo=googlebigquery&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Looker](https://img.shields.io/badge/Looker-4285F4?logo=looker&logoColor=white)

# olist-funnel-analysis

Pipeline analítica de ponta a ponta sobre o [Brazilian E-Commerce Public Dataset da Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), construída com Python, dbt e BigQuery. O projeto aplica práticas de Analytics Engineering para responder perguntas reais de negócio sobre performance operacional, comercial e de vendedores em um marketplace brasileiro.

---

## Índice

- [Quick Start](#quick-start)
- [Perguntas de negócio](#perguntas-de-negócio)
- [Dashboard](#dashboard)
- [Arquitetura](#arquitetura)
- [Lineage](#lineage)
- [Setup Completo](#setup-completo)
  - [1. Ambiente Python](#1-ambiente-python)
  - [2. Dataset Kaggle](#2-dataset-kaggle)
  - [3. Credenciais BigQuery](#3-credenciais-bigquery)
  - [4. Variáveis de Ambiente](#4-variáveis-de-ambiente)
  - [5. Configuração dbt](#5-configuração-dbt)
- [Como Rodar](#como-rodar)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Camadas dbt](#camadas-dbt)
- [Testes](#testes)
- [Decisões Técnicas](#decisões-técnicas)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Stack](#stack)
- [Contato](#contato)

---

## Quick Start

```bash
# 1. Clonar repositório
git clone https://github.com/trindata/olist-funnel-analysis.git
cd olist-funnel-analysis

# 2. Ambiente virtual + dependências
python -m venv .venv
.venv\Scripts\Activate.ps1          # Windows PowerShell
# source .venv/bin/activate          # Linux/Mac
pip install -r requirements.txt

# 3. Configurar credenciais (veja Setup Completo)
cp .env.example .env
# editar .env com GCP_PROJECT_ID, GOOGLE_CREDENTIALS, etc.

# 4. Carregar variáveis na sessão (uma vez por terminal)
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*)$') {
        Set-Item -Path "env:$($Matches[1])" -Value $Matches[2]
    }
}
# Linux/Mac: set -a && . ./.env && set +a

# 5. Rodar pipeline
python -m kaggle.runner_get_upload   # ingestão Kaggle → BigQuery raw
dbt deps                             # instala dbt_utils
dbt build                            # run + test de todos os modelos
```

Continue lendo para o setup detalhado.

---

## Perguntas de negócio

| #   | Pergunta                                                 | Mart                        |
| --- | -------------------------------------------------------- | --------------------------- |
| 1   | A Olist entrega no prazo? Onde estão os atrasos?         | `fct_orders`                |
| 2   | Quais categorias têm maior receita e melhor satisfação?  | `mart_category_performance` |
| 3   | Quais vendedores entregam melhor experiência ao cliente? | `mart_seller_performance`   |

---

## Dashboard

[Acessar no Looker Studio](https://datastudio.google.com/reporting/dfd5c732-95a3-4204-adfd-dbb5db8cac5d)

### Visualizações

**Overview Operacional**
![Dashboard Operacional](assets/dash_entregas.png)

**Performance por Categoria**
![Performance Categoria](assets/dash_comercial.png)

**Análise de Vendedores**
![Análise Vendedores](assets/dash_vendedores.png)

### Principais Insights

Análise do dataset Olist (set/2016 a out/2018):

1. **Atrasos concentrados em categorias pesadas**: 28% dos pedidos de móveis atrasam vs 12% média geral
2. **Sellers SP têm review score 0.4 pontos maior** que média nacional
3. **Freight ratio acima de 20% correlaciona com review score <3**: cliente penaliza frete caro

---

## Arquitetura

```
Kaggle API
    │
    ▼
Python (pandas + kagglehub)
    │  ingestão via API, tratamento de encoding, upload pro BQ
    ▼
BigQuery — dataset raw
    │
    ▼
dbt Core (CLI)
    ├── staging       → 9 views   (rename, cast, limpeza)
    ├── intermediate  → 3 views   (joins, cálculos de domínio)
    └── marts         → 3 tables  (agregações finais)
    │
    ▼
Looker Studio
```

---

## Lineage

![Lineage](assets/lineage_v2.png)

---

## Setup Completo

### Pré-requisitos

- **Python 3.12+** (desenvolvido e testado com 3.12.6)
- **Google Cloud Platform** com projeto criado
- **Conta Kaggle** (opcional — só se for usar o download automatizado)

---

### 1. Ambiente Python

#### Com pyenv (recomendado)

```bash
pyenv install 3.12.6
pyenv local 3.12.6
python -m venv .venv
```

#### Sem pyenv

```bash
python --version  # deve ser 3.12+
python -m venv .venv
```

#### Ativar ambiente virtual

**Linux/Mac:**

```bash
source .venv/bin/activate
```

**Windows PowerShell:**

```powershell
.venv\Scripts\Activate.ps1
```

**Windows CMD:**

```cmd
.venv\Scripts\activate.bat
```

#### Atualizar ferramentas base

```bash
python -m pip install --upgrade pip setuptools wheel
```

#### Instalar dependências do projeto

```bash
pip install -r requirements.txt
```

O `requirements.txt` já inclui `dbt-core` e `dbt-bigquery` — não precisa instalar separadamente.

#### Validar ambiente

```bash
python -c "import sys; print(sys.executable)"
dbt --version
```

O `sys.executable` tem que apontar pra `.venv\Scripts\python.exe` (ou `.venv/bin/python`). O `dbt --version` precisa mostrar `Core: 1.11.x` e o adapter `bigquery`. Se aparecer mensagem de "dbt Cloud CLI", outra instalação está vencendo no PATH — veja [Troubleshooting](#troubleshooting).

---

### 2. Dataset Kaggle

O projeto precisa dos CSVs do dataset [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Duas opções:

#### Opção A — Download manual (mais simples)

1. Acesse a [página do dataset no Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Clique em **Download** (canto superior direito)
3. Extraia o ZIP e mova os CSVs para `kaggle/raw_files/`

Pronto, pode pular pro próximo passo.

#### Opção B — Download via API (automatizado)

O projeto inclui o script `kaggle/get_datasets_from_kaggle.py`, que usa `kagglehub` para baixar o dataset automaticamente. Útil pra rodar o pipeline de ponta a ponta sem passos manuais (ou em CI/CD).

Pra isso, configure credenciais Kaggle. O `kagglehub` aceita três formas:

- Arquivo `~/.kaggle/access_token` (token novo, formato `KGAT_...`)
- Arquivo `~/.kaggle/kaggle.json` (formato legacy, com `username` e `key`)
- Variável de ambiente `KAGGLE_API_TOKEN` (útil pra CI/CD)

Para gerar um token novo, acesse [kaggle.com/settings](https://www.kaggle.com/settings) → aba **API Tokens** → **Generate New Token**:

![Geração de token Kaggle](assets/kaggle_token.png)

> O token só aparece uma vez. Se perder, gere outro.

Consulte a [documentação do kagglehub](https://github.com/Kaggle/kagglehub) para detalhes de configuração no seu SO.

---

### 3. Credenciais BigQuery

O pipeline faz upload dos dados para BigQuery, e o dbt lê/escreve nele. Você precisa de um projeto GCP e uma service account.

#### Criar service account

1. Acesse [Google Cloud Console](https://console.cloud.google.com)
2. Navegue: **IAM & Admin** → **Service Accounts**
3. Clique **Create Service Account**
4. Nome: `olist-pipeline-sa` (ou qualquer nome)
5. Roles: **BigQuery Data Editor** + **BigQuery Job User**
6. Clique **Create and Continue** → **Done**

![Criação de conta de serviço no Google Cloud](assets/google_conta_servico.png)

> A role `BigQuery Job User` é necessária pro dbt executar queries (não só inserir dados).

#### Gerar chave JSON

1. Clique na service account criada
2. Aba **Keys** → **Add Key** → **Create New Key**
3. Tipo: **JSON**
4. Baixe o arquivo JSON

![Criação das chaves de acesso Google Cloud](assets/google_keys.png)

#### Mover chave para pasta segura

Crie a pasta `secrets/` na raiz do projeto e mova o JSON baixado pra lá. Sugiro renomear pra um nome genérico como `bigquery_service_account.json`.

> A pasta `secrets/` já está no `.gitignore` — a chave nunca vai pro repositório. O path `secrets/bigquery_service_account.json` é o valor esperado pela variável `GOOGLE_CREDENTIALS` no `.env`.

#### Criar dataset raw no BigQuery

No [BigQuery Studio](https://console.cloud.google.com/bigquery), abra um editor de query e execute:

```sql
CREATE SCHEMA `seu-project-id.raw`;
```

Substitua `seu-project-id` pelo ID do seu projeto GCP (canto superior esquerdo do console).

> Os datasets `dbt_dev_staging`, `dbt_dev_intermediate` e `dbt_dev_marts` serão criados automaticamente pelo dbt no primeiro `dbt run` — a service account já tem permissão pra isso.

---

### 4. Variáveis de Ambiente

Copie o template `.env.example` como `.env`:

```bash
cp .env.example .env             # Linux/Mac
# Copy-Item .env.example .env    # Windows PowerShell
```

Edite com os valores do seu projeto. Conteúdo mínimo:

```bash
# ID do projeto GCP (canto superior esquerdo do console)
GCP_PROJECT_ID=seu-project-id

# Localização dos datasets BigQuery (US, EU, southamerica-east1, etc.)
GCP_LOCATION=US

# Path pro JSON da service account
GOOGLE_CREDENTIALS=secrets/bigquery_service_account.json

# Onde o dbt vai procurar o profiles.yml (versionado no projeto)
DBT_PROFILES_DIR=./dbt
```

> O pipeline Python carrega o `.env` automaticamente via `python-dotenv`. Para o **dbt CLI**, as variáveis precisam estar exportadas na sessão do terminal — veja a próxima seção.

---

### 5. Configuração dbt

O projeto usa **dbt Core via CLI**. O `profiles.yml` está versionado em `dbt/profiles.yml` — todas as credenciais são lidas via env vars, então o arquivo é seguro pra commitar.

#### profiles.yml (já incluído no repo)

```yaml
olist_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: "{{ env_var('GCP_PROJECT_ID') }}"
      dataset: dbt_dev
      threads: 4
      timeout_seconds: 300
      location: "{{ env_var('GCP_LOCATION', 'US') }}"
      keyfile: "{{ env_var('GOOGLE_CREDENTIALS') }}"
      priority: interactive
```

#### Carregar variáveis de ambiente na sessão

O dbt CLI lê variáveis do ambiente do shell, não do arquivo `.env`. A cada nova sessão de terminal, exporte as variáveis antes de rodar comandos dbt.

**Windows PowerShell:**

```powershell
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*)$') {
        Set-Item -Path "env:$($Matches[1])" -Value $Matches[2]
    }
}
```

**Linux/Mac (bash/zsh):**

```bash
set -a && . ./.env && set +a
```

Pra confirmar que carregou:

```powershell
echo $env:GCP_PROJECT_ID     # PowerShell
# echo $GCP_PROJECT_ID         # Linux/Mac
```

Tem que devolver o ID do seu projeto GCP. Se vier vazio, o `.env` não foi lido — confira se você está na raiz do projeto e se o arquivo existe.

#### Testar conexão

```bash
dbt debug
```

Output esperado (trecho):

```
Connection test: [OK connection ok]
All checks passed!
```

---

## Como Rodar

O pipeline tem quatro etapas, executadas em sequência a partir da raiz do projeto. As três primeiras são preparação (uma vez por sessão); a quarta é o que você roda repetidamente conforme itera nos modelos.

### 1. Ativar o ambiente virtual

```powershell
.venv\Scripts\Activate.ps1          # Windows PowerShell
# source .venv/bin/activate          # Linux/Mac
```

O prompt deve passar a ter o prefixo `(.venv)`.

### 2. Carregar variáveis de ambiente na sessão

```powershell
# PowerShell
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*)$') {
        Set-Item -Path "env:$($Matches[1])" -Value $Matches[2]
    }
}
```

```bash
# Linux/Mac
set -a && . ./.env && set +a
```

Esse passo é necessário **uma vez por sessão**. Depois disso, `dbt debug`, `dbt build` etc. funcionam direto.

### 3. Ingestão: Kaggle → BigQuery raw

```bash
python -m kaggle.runner_get_upload
```

O `-m` faz o Python tratar `kaggle` como pacote a partir da raiz do projeto (preserva os imports relativos entre `kaggle/`, `kaggle/bigquery/` e `kaggle/config/`). Não rode o script direto via `python kaggle/runner_get_upload.py` — quebra os imports.

O script imprime shape e colunas de cada tabela antes do upload. Demora 1–3 minutos dependendo da conexão e só precisa rodar **uma vez** (ou quando o dataset Olist for atualizado). As tabelas no `raw` ficam idempotentes — rodar de novo sobrescreve.

### 4. Transformação: dbt

Com o `raw` populado, o dbt cuida das três camadas (staging → intermediate → marts), seguindo o lineage e rodando os testes ao final.

```bash
dbt deps     # instala dbt_utils (uma vez por projeto, ou quando packages.yml mudar)
dbt build    # run + test (15 modelos, 71 testes)
```

`dbt build` é o comando consolidado: executa `dbt run` (materializa modelos) e `dbt test` (valida) na ordem correta do DAG, parando upstream se algum teste fundamental falhar. Resultado esperado de uma rodada limpa:

```
Finished running 3 table models, 71 data tests, 12 view models in 1m24s
Done. PASS=86 WARN=0 ERROR=0 SKIP=0 NO-OP=0 TOTAL=86
```

O que foi materializado no BigQuery após a primeira execução completa:

| Dataset                | Objetos                                                                         |
| ---------------------- | ------------------------------------------------------------------------------- |
| `dbt_dev_staging`      | 9 views (uma por tabela raw)                                                    |
| `dbt_dev_intermediate` | 3 views (joins e cálculos reutilizáveis)                                        |
| `dbt_dev_marts`        | 3 tables (`fct_orders`, `mart_category_performance`, `mart_seller_performance`) |

O prefixo `dbt_dev_` vem do `target: dev` no `profiles.yml` combinado com o `+schema:` de cada camada no `dbt_project.yml`. Pra promover a produção no futuro, basta criar um `target: prod` que troque o prefixo.

### Rodando de novo

- **Mesma sessão de terminal**: só `dbt build` (passos 1 e 2 já valem).
- **Novo terminal**: passos 1, 2 e 4 (pula a ingestão se o `raw` já está populado).
- **Dataset Olist mudou**: refaz a ingestão (passo 3) e depois `dbt build`.

### Comandos dbt Úteis

```bash
# Rodar só staging (e tudo upstream)
dbt run --select staging

# Rodar só marts (e tudo upstream que estiver desatualizado)
dbt build --select +marts

# Rodar testes
dbt test                       # todos os testes
dbt test --select staging      # só staging
dbt test --select marts        # só marts

# Gerar e servir documentação local
dbt docs generate
dbt docs serve                 # abre em localhost:8080
```

---

## Estrutura do Repositório

```
olist-funnel-analysis/
├── assets/                          # Screenshots, lineage, diagramas
├── dbt/                             # Configuração dbt
│   └── profiles.yml                 # Profile versionado (usa env vars)
├── kaggle/                          # Pipeline de ingestão
│   ├── bigquery/                    # Cliente e validações BigQuery
│   │   ├── funcoes_gestao_bigquery.py
│   │   └── modelo_bigquery.py
│   ├── config/                      # Configurações de paths e tabelas
│   │   ├── config_bigquery_raw.py
│   │   ├── config_paths.py
│   │   └── config_raw_tables_olist.py
│   ├── get_datasets_from_kaggle.py  # Download do Kaggle
│   ├── upload_raw_to_bigquery.py    # Upload para BigQuery
│   └── runner_get_upload.py         # Orquestrador
├── models/                          # Modelos dbt
│   ├── staging/olist/               # 9 views (1:1 com raw)
│   ├── intermediate/                # 3 views (joins, cálculos)
│   └── marts/
│       ├── commercial/              # mart_category_performance, mart_seller_performance
│       └── operational/             # fct_orders
├── secrets/                         # Credenciais (não versionado)
│   └── bigquery_service_account-example.json
├── .env                             # Variáveis de ambiente (não versionado)
├── .env.example                     # Template de configuração
├── dbt_project.yml                  # Configuração dbt
├── packages.yml                     # Dependências dbt (dbt_utils)
├── requirements.txt                 # Dependências Python (inclui dbt-core e dbt-bigquery)
└── README.md
```

---

## Camadas dbt

### Staging

Uma view por tabela raw, organizada por source (`models/staging/<source_name>/`) pra permitir múltiplas fontes no futuro sem refatoração. Responsabilidade restrita: rename de colunas pra convenção padrão, cast de tipos, limpeza mínima. Sem joins.

**Convenções aplicadas:**

- Timestamps de evento com sufixo `_at` (`purchased_at`, `approved_at`)
- Monetário como `NUMERIC` (evita imprecisão de float em agregações)
- CEPs como `STRING` (preserva zeros à esquerda)
- Texto livre com `LOWER` + `TRIM` antes de agregações

### Intermediate

Joins e cálculos de domínio reutilizáveis. Nenhum mart acessa staging diretamente.

| Modelo                      | Responsabilidade                                                            |
| --------------------------- | --------------------------------------------------------------------------- |
| `int_order_items__enriched` | order_items + products + sellers + category_translation                     |
| `int_orders__aggregated`    | agrega itens por pedido (receita, frete, contagens)                         |
| `int_orders__enriched`      | orders + customers + reviews + agregado de itens + flags e deltas temporais |

### Marts

Tabelas materializadas, prontas pro Looker. Organizadas por domínio: `operational/` para marts orientados a fluxo do pedido (entregas, status, prazos); `commercial/` para marts orientados a receita (categoria, seller, ticket).

| Mart                        | Granularidade                | Domínio     | Principais métricas                                |
| --------------------------- | ---------------------------- | ----------- | -------------------------------------------------- |
| `fct_orders`                | 1 linha por pedido           | operational | prazo real, atraso, review score, receita, flags   |
| `mart_category_performance` | 1 linha por (categoria, mês) | commercial  | receita, ticket médio, freight ratio, review score |
| `mart_seller_performance`   | 1 linha por seller           | commercial  | receita, prazo médio, % atraso, review score       |

---

## Testes

**71 testes automatizados** cobrindo staging e marts.

| Tipo                                      | Cobertura                                      |
| ----------------------------------------- | ---------------------------------------------- |
| `not_null`                                | PKs e FKs críticas em todas as camadas         |
| `unique`                                  | PKs de todas as tabelas                        |
| `accepted_values`                         | `order_status`, `payment_type`, `review_score` |
| `relationships`                           | integridade referencial entre staging models   |
| `dbt_utils.unique_combination_of_columns` | PKs compostas (`order_id + order_item_id`)     |

```bash
dbt test                       # todos os testes
dbt test --select staging      # só staging
dbt test --select marts        # só marts
```

---

## Decisões Técnicas

### dbt Core via CLI (e não dbt Cloud)

O projeto é pensado pra portfólio público — toda decisão de modelagem, profile e dependência precisa ser inspecionável no GitHub, não escondida atrás de uma UI proprietária. dbt Core no terminal preserva esse princípio e ainda facilita CI/CD futuro via GitHub Actions.

### `profiles.yml` versionado no projeto

Em vez do padrão `~/.dbt/profiles.yml` (que vive fora do repo), o profile mora em `dbt/profiles.yml` e usa `env_var()` pra tudo que é credencial. Isso torna o setup reprodutível em qualquer máquina sem mexer no home do usuário, e mantém o princípio de "código inspecionável" do portfólio.

### Staging organizada por source

A pasta `models/staging/` é subdividida por nome de source (`olist/` hoje, podendo ter `correios/`, `mercado_pago/` etc. no futuro). Adicionar uma nova fonte de dados não exige reorganização — só uma pasta nova ao lado.

### Service accounts separadas para ingestão e transformação

O pipeline Python usa uma SA com permissão de escrita restrita ao dataset `raw`. O dbt usa uma SA separada com leitura em `raw` e escrita nos datasets de transformação. Princípio de least privilege aplicado desde o início.

> Para simplificar o setup inicial, o README acima usa uma SA única com ambas as roles. Para produção/portfólio polido, separe as duas.

### Staging conservadora em testes de unicidade

Testes `unique` e `relationships` foram adicionados após exploração, não antes. Dois casos de inconsistência descobertos e documentados:

- `order_reviews`: `review_id` não é PK confiável — o mesmo ID aparece em pedidos distintos (bug de sistema na origem). PK garantida é `order_id` via deduplicação.
- `geolocation`: sem PK única por design — múltiplas coordenadas por prefixo de CEP.

### Deduplicação de reviews na staging

0.56% dos pedidos tinham múltiplas avaliações (551 casos). Tratado via `ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answered_at DESC)`, preservando a avaliação mais recente por pedido.

### Geolocation agregada na staging

A raw tem 1 milhão+ de linhas para ~19k CEPs únicos (média de 52 coordenadas por prefixo). A staging agrega via `AVG(lat/lng)` pra produzir 1 linha por CEP, reduzindo o volume em 98% antes de qualquer join downstream.

### Typos preservados na source, corrigidos na staging

O dataset Olist original tem `product_name_lenght` e `product_description_lenght` (typo em "length"). A source documenta o nome real da coluna. A staging corrige para `product_name_length` e `product_description_length`. Rastreabilidade total da decisão.

---

## Troubleshooting

### Erro: `Env var required but not provided: 'GCP_PROJECT_ID'`

→ O dbt não enxergou as variáveis do `.env`. Carregue-as na sessão antes de rodar comandos dbt (veja [seção 5](#5-configuração-dbt)). Confirme com `echo $env:GCP_PROJECT_ID` (PowerShell) ou `echo $GCP_PROJECT_ID` (Linux/Mac).

### Erro: `Could not find profile named 'olist_project'`

→ O dbt não encontrou o `profiles.yml` versionado. Garanta que `DBT_PROFILES_DIR=./dbt` está no `.env` e foi carregado na sessão.

### Mensagem confusa: "version X.X of the dbt Cloud CLI is now available"

→ Outra instalação de `dbt` está vencendo o `.venv` no PATH (provavelmente pyenv shims ou pacote `dbt` global). Diagnóstico:

```powershell
where.exe dbt           # Windows
# which -a dbt           # Linux/Mac
```

Se aparecer algo fora do `.venv\Scripts\`, desinstale com `pip uninstall dbt -y` no Python base e/ou remova os shims em `~/.pyenv/pyenv-win/shims/dbt*`. Sempre ative o `.venv` antes de rodar `dbt`.

### Erro: `ModuleNotFoundError: No module named 'kaggle.bigquery'`

→ Você rodou o script diretamente em vez de usar `-m`. Use `python -m kaggle.runner_get_upload` a partir da raiz do projeto.

### Erro: `Kaggle credentials not found`

→ Verifique se `~/.kaggle/kaggle.json` existe e tem permissões corretas (`chmod 600` no Linux/Mac), ou use download manual (Opção A da [seção 2](#2-dataset-kaggle)).

### Erro: `Could not find credentials` (BigQuery)

→ Verifique se `.env` está configurado, `GOOGLE_CREDENTIALS` aponta pro JSON correto, e as variáveis foram carregadas na sessão.

### Erro: `Dataset not found` no BigQuery

→ Crie o dataset `raw` manualmente no BigQuery (ver [seção 3](#3-credenciais-bigquery)). Os demais datasets o dbt cria sozinho.

### Erro: `403 Permission denied` em queries dbt

→ A service account precisa da role `BigQuery Job User` além de `BigQuery Data Editor`. Confira em IAM & Admin.

### Ambiente virtual corrompido

Recrie do zero:

```bash
deactivate
rm -rf .venv                                # Linux/Mac
# Remove-Item .venv -Recurse -Force         # Windows PowerShell
python -m venv .venv
source .venv/bin/activate                   # ou .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

---

## Roadmap

Evoluções técnicas planejadas:

- [ ] CI/CD via GitHub Actions (`dbt build` + testes a cada PR)
- [ ] Hospedagem da documentação dbt via GitHub Pages
- [ ] Modelo preditivo de atraso usando XGBoost (features: categoria, peso, distância, seller_state)
- [ ] Análise de cohort de retenção (% clientes que recompram por mês de primeira compra)
- [ ] Dashboard de anomalia: alertar quando métricas-chave saem do padrão histórico
- [ ] Integração com API Correios para benchmark custo real vs cobrado
- [ ] Pipeline incremental no dbt (atualizar apenas dados novos, não full refresh)

---

## Stack

| Camada        | Tecnologia                                            |
| ------------- | ----------------------------------------------------- |
| Ingestão      | Python 3.12, pandas, kagglehub, google-cloud-bigquery |
| Warehouse     | Google BigQuery                                       |
| Transformação | dbt Core (CLI), dbt-bigquery, dbt_utils               |
| Visualização  | Looker Studio                                         |
| Versionamento | Git + GitHub                                          |

---

## Licença

Este projeto utiliza dados públicos da Olist disponibilizados via Kaggle sob licença [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

---

## Contato

**Igor Trindade**  
[LinkedIn](https://www.linkedin.com/in/trindadeigu/) • [GitHub](https://github.com/trindata)
