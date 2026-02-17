-- ======================================================================
-- PROJECT: Merchandising Performance & SKU Optimization
-- SCRIPT: 03_future_optimization.sql
-- DESCRIPTION: Phase 3 Monitoring - Validating the impact of our actions.
-- FOCUS: Safety Checks (Did we lose money?) & Protocol Enforcement (One-In, One-Out)
-- ======================================================================

-- 1. MONITOR: Post-Deprecation Revenue Impact (Safety Check)
--    Business Question: "Did killing the 20,000 SKUs hurt our total sales?"
--    Logic: Compare Store Revenue YOY focusing on the 'Kill List' cohort.
SELECT 
    DATE_TRUNC('month', order_date) as sales_month,
    store_code,
    SUM(line_total) as total_revenue,
    -- We expect this column to be near ZERO after execution
    SUM(CASE WHEN p.action_tag = 'Kill (Dead Weight)' THEN line_total ELSE 0 END) as revenue_from_killed_products,
    COUNT(DISTINCT order_id) as transaction_count
FROM fact_order_items oi
JOIN tableau_merch_optimization p ON oi.sku = p.sku
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
GROUP BY 1, 2
ORDER BY 1 DESC;

-- 2. MONITOR: "One-In, One-Out" Protocol Compliance (New Launches)
--    Business Question: "Are buyers following the new efficiency rules?"
--    Logic: Flag new style creations that exceed the allowed color variant limit (Max 2).
SELECT 
    s.store_code,
    s.style_id,
    COUNT(DISTINCT s.sku) as variant_count_at_launch,
    MIN(s.created_at) as launch_date,
    CASE 
        WHEN COUNT(DISTINCT s.sku) > 2 THEN 'VIOLATION: Too Many Colors'
        ELSE 'Compliant'
    END as protocol_status
FROM dim_merch_styles s
WHERE s.created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH) -- New launches only
GROUP BY s.store_code, s.style_id
HAVING variant_count_at_launch > 2;

-- 3. MONITOR: Efficiency Trend (Quarterly KPI)
--    Business Question: "Is our catalog getting leaner?"
--    Target: Revenue per Active SKU should INCREASE over time.
SELECT 
    QUARTER(order_date) as qtr,
    YEAR(order_date) as yr,
    SUM(line_total) as total_revenue,
    COUNT(DISTINCT sku) as active_skus_sold,
    ROUND(SUM(line_total) / COUNT(DISTINCT sku), 2) as revenue_per_active_sku
FROM fact_order_items
GROUP BY 2, 1
ORDER BY 2 DESC, 1 DESC;
