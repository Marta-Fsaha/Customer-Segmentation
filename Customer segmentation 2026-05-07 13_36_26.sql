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

-----
CREATE OR REPLACE VIEW `rfm032026.sales..rfm_scores` 
AS
SELECT *, 
NTILE(10) OVER(order by r_rank DESC) AS r_score,
NTILE(10) OVER(order by f_rank DESC) AS f_score,
NTILE(10) OVER(order by m_rank DESC) AS m_score,
FROM `rfm032026.sales..rfm_metrics`; 

------

CREATE OR REPLACE VIEW `rfm032026.sales.rfm_total_scores` 
AS
SELECT 
customerId,
recency,
frequency,
monetary,
r_score,
f_score,
m_score,
(r_score+f_score+m_score) as rfm_total_score
FROM `rfm032026.sales..rfm_scores`
ORDER BY rfm_total_score DESC;

----BI ready rfm segments table
 CREATE OR REPLACE VIEW `rfm032026.sales.rfm_segments_final`
 AS
 SELECT 
 customerId,
 recency,
 frequency,
 monetary,
 r_score,
 f_score,
 m_score,
 rfm_total_score,
 CASE
 WHEN rfm_total_score>=28 THEN 'Champians'
 WHEN rfm_total_score>=24 THEN 'Loyal VIPs'
 WHEN rfm_total_score>=20 THEN 'Potential Loyalists'
 WHEN rfm_total_score>=16 THEN'Promising'
 WHEN rfm_total_score>=12 THEN'Engaged'
 WHEN rfm_total_score>=8 THEN'Requires Attenation'
 WHEN rfm_total_score>=4 THEN'At risk'
ELSE 'Inactive'
END AS rfm_segment
FROM `rfm032026.sales.rfm_total_scores`
Order By rfm_total_score DESC;


