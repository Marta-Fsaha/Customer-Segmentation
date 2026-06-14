SELECT * FROM `rfm032026.sales.online retail` LIMIT 1000
CREATE OR REPLACE VIEW `rfm032026.sales.rfm_metrics` 
AS
WITH current_date AS (
  SELECT DATE('2026-05-07') AS analysis_date
),
rfm AS (
  SELECT 
    customerId,
    MAX(InvoiceDate) AS last_order_date,
    DATE_DIFF(
      (SELECT analysis_date FROM current_date),
      DATE(MAX(InvoiceDate)),
      DAY
    ) AS recency,
    COUNT(*) AS frequency, 
    SUM(Quantity * UnitPrice) AS monetary
  FROM `rfm032026.sales.online retail`
  GROUP BY customerId
)

SELECT 
  rfm.*,
  ROW_NUMBER() OVER (ORDER BY recency ASC) AS r_rank,
  ROW_NUMBER() OVER (ORDER BY frequency DESC) AS f_rank,
  ROW_NUMBER() OVER (ORDER BY monetary DESC) AS m_rank
FROM rfm;