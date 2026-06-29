-- =============================================================================
-- 02 — Prazo real vs prometido (gap de calibração logística)
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   A Olist está calibrando bem o prazo prometido ao cliente? Em média entrega
--   antes, depois ou bem em cima? Há padrão sazonal nessa calibração?
--
-- HIPÓTESE
--   A empresa tende a ser conservadora na promessa pra blindar reputação,
--   então a entrega real deve ser, em média, vários dias *antes* do prometido.
--   Se for próximo de zero ou negativo, indica problema operacional sério.
--
-- GRANULARIDADE
--   1 linha por (ano, mês) de compra. Permite ver evolução temporal.
--
-- COMO INTERPRETAR
--   avg_days_promised: média do prazo prometido (estimated_delivery - purchased).
--   avg_days_actual: média do prazo real (delivered_to_customer - purchased).
--   buffer_days: diferença. Positivo = entrega antes do prometido (folga).
--   Negativo = entrega depois (problema).
--
-- TABELAS USADAS
--   dbt_dev_marts.fct_orders
-- =============================================================================

select
    purchase_year,
    purchase_month_num,
    count(*)                                    as total_orders,
    round(avg(days_promised), 1)                as avg_days_promised,
    round(avg(days_to_deliver), 1)              as avg_days_actual,
    round(avg(days_promised - days_to_deliver), 1) as buffer_days,
    countif(is_late)                            as late_orders,
    round(countif(is_late) * 100.0 / count(*), 2) as pct_late

from `dbt_dev_marts.fct_orders`
where order_status = 'delivered'
  and days_to_deliver is not null
  and days_promised is not null

group by purchase_year, purchase_month_num
order by purchase_year, purchase_month_num

-- =============================================================================
-- FINDINGS 

-- Buffer médio histórico: ~12-13 dias (folga estrutural ampla)
-- Pior mês: Mar/2018 com 21.36% de atraso e buffer de 6 dias
-- Outros meses críticos: Fev/2018 (16%), Nov/2017 - Black Friday (14%), Ago/2018 (10%)
-- 
-- Tendência: três janelas de crise + mudança estrutural em Ago/2018 (prazos prometidos
-- caíram 33%, mas pct_late dobrou).
--
-- Insight pro README:
--   Atrasos são episódicos, não estruturais. 19 dos 23 meses ficam <9%.
--   Black Friday e Fev-Mar/2018 são as crises. Ago/2018 marca mudança de
--   política comercial (prometer mais rápido) com custo em confiabilidade.
-- =============================================================================
