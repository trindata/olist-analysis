from bigquery.modelo_bigquery import BigQueryConfig

# =============================================================================
# Raw tables
# =============================================================================

RAW_TABLE_CUSTOMERS = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
    dataset="raw",
    table="customers"
)

RAW_TABLE_GEOLOCATION = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
    dataset="raw",
    table="geolocation"
)

RAW_TABLE_ORDER_ITEMS = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
    dataset="raw",
    table="order_items"
)

RAW_TABLE_ORDER_PAYMENTS = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
    dataset="raw",
    table="order_payments"
)

RAW_TABLE_ORDER_REVIEWS = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
    dataset="raw",
    table="order_reviews"
)

RAW_TABLE_ORDERS = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
    dataset="raw",
    table="orders"
)

RAW_TABLE_PRODUCTS = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
    dataset="raw",
    table="products"
)

RAW_TABLE_SELLERS = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
    dataset="raw",
    table="sellers"
)

RAW_TABLE_CATEGORY_NAME_TRANSLATION = BigQueryConfig(
    project_id="olist-funnel-analysis-494020",
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