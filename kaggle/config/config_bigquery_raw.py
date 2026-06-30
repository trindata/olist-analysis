from kaggle.bigquery.modelo_bigquery import BigQueryConfig

# =============================================================================
# Raw tables
# =============================================================================
# project_id é resolvido via env var GCP_PROJECT_ID no BigQueryConfig (default).
# Pra apontar pra outro projeto, basta trocar a variável no .env — nenhuma
# alteração de código necessária.

RAW_TABLE_CUSTOMERS = BigQueryConfig(
    dataset="raw",
    table="customers"
)

RAW_TABLE_GEOLOCATION = BigQueryConfig(
    dataset="raw",
    table="geolocation"
)

RAW_TABLE_ORDER_ITEMS = BigQueryConfig(
    dataset="raw",
    table="order_items"
)

RAW_TABLE_ORDER_PAYMENTS = BigQueryConfig(
    dataset="raw",
    table="order_payments"
)

RAW_TABLE_ORDER_REVIEWS = BigQueryConfig(
    dataset="raw",
    table="order_reviews"
)

RAW_TABLE_ORDERS = BigQueryConfig(
    dataset="raw",
    table="orders"
)

RAW_TABLE_PRODUCTS = BigQueryConfig(
    dataset="raw",
    table="products"
)

RAW_TABLE_SELLERS = BigQueryConfig(
    dataset="raw",
    table="sellers"
)

RAW_TABLE_CATEGORY_NAME_TRANSLATION = BigQueryConfig(
    dataset="raw",
    table="category_name_translation"
)

# =============================================================================
# Mapeamento nome da tabela -> config BigQuery
# =============================================================================

BQ_TABLE_MAP = {
    "customers":            RAW_TABLE_CUSTOMERS,
    "geolocation":          RAW_TABLE_GEOLOCATION,
    "order_items":          RAW_TABLE_ORDER_ITEMS,
    "order_payments":       RAW_TABLE_ORDER_PAYMENTS,
    "order_reviews":        RAW_TABLE_ORDER_REVIEWS,
    "orders":               RAW_TABLE_ORDERS,
    "products":             RAW_TABLE_PRODUCTS,
    "sellers":              RAW_TABLE_SELLERS,
    "category_translation": RAW_TABLE_CATEGORY_NAME_TRANSLATION,
}