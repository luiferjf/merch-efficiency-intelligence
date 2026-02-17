-- ======================================================================
-- PROJECT: Merchandising Performance & SKU Optimization (Multi-Store)
-- SCRIPT: 02_merch_efficiency_pipeline.sql
-- DESCRIPTION: Core SQL Logic for Efficiency Metrics (ABC, Dead-Weight, Pareto)
-- TARGET: Tableau Dashboard (SKU Action Playbook)
-- ======================================================================

-- 1. STAGING: Create a Base Table for 'Styles' (Design Level) 
--    Groups variants (Color/Size) under a single Style ID.
CREATE OR REPLACE TABLE dim_merch_styles AS
SELECT 
    store_code,
    product_id,
    sku,
    product_name,
    std_category,
    std_audience,
    std_theme,
    regular_price,
    sale_price,
    -- Construct a 'Style ID' = Theme + Category for aggregation
    CONCAT(store_code, '-Theme:', COALESCE(NULLIF(std_theme,''),'Gen'), '-Cat:', COALESCE(NULLIF(std_category,''),'Gen')) as style_id
FROM stg_merch_enriched_data; -- Full catalog, including unsold items

-- 2. AGGREGATION: Calculate Sales at Variant Level
CREATE OR REPLACE TABLE fact_sales_agg AS
SELECT 
    sku, 
    store_code, 
    SUM(line_total) as net_rev, 
    SUM(quantity) as sold_units
FROM fact_order_items 
GROUP BY sku, store_code;

-- 3. ANALYSIS: The "Brain" of the Project (Efficiency Calculation)
--    Strategies: Dead Weight Detection, Pareto Principle, Efficiency Matrix
CREATE OR REPLACE TABLE tableau_merch_optimization AS
WITH style_metrics AS (
    SELECT 
        s.store_code, 
        s.style_id, 
        -- Count TOTAL existing variants (from catalog)
        COUNT(DISTINCT s.sku) as total_vars, 
        -- Count ACTIVE variants (matched to sales)
        COUNT(DISTINCT CASE WHEN f.sold_units > 0 THEN s.sku END) as active_vars, 
        -- Sum Revenue
        SUM(COALESCE(f.net_rev, 0)) as style_rev
    FROM dim_merch_styles s
    LEFT JOIN fact_sales_agg f ON s.sku = f.sku AND s.store_code = f.store_code
    GROUP BY s.store_code, s.style_id
),
pareto_calc AS (
    SELECT 
        *,
        -- Window Function for Pareto Chart (Red Line)
        SUM(style_rev) OVER (PARTITION BY store_code ORDER BY style_rev DESC) as running_total_revenue,
        SUM(style_rev) OVER (PARTITION BY store_code) as total_store_revenue
    FROM style_metrics
)
SELECT 
    p.store_code, 
    p.style_id, 
    p.total_vars,
    p.active_vars,
    p.style_rev,
    
    -- METRIC: Pareto % (Running Total / Total Store Revenue)
    ROUND(p.running_total_revenue / NULLIF(p.total_store_revenue, 0), 4) as pareto_pct,

    -- METRIC: Dead Variant Ratio (Key Optimization KPI)
    -- If 3 variants exist but only 1 sold, DVR = 66% (Bad)
    ROUND(1 - (p.active_vars / NULLIF(p.total_vars, 0)), 2) as dead_variant_ratio, 
    
    -- PLAYBOOK: Automated Keep/Kill Decisions (Matches Visual Reference Lines)
    CASE 
        -- The "Oriente Paradox" Fix: High Rev but High Inefficiency
        WHEN p.style_rev > 2000 AND (1 - (p.active_vars / NULLIF(p.total_vars, 0))) > 0.5 THEN 'Fix (Inefficient)'
        
        -- The "Hidden 20k": Zero Sales or Negligible
        WHEN p.style_rev = 0 OR p.style_rev IS NULL THEN 'Kill (Dead Weight)'
        
        -- The Winners
        WHEN p.style_rev > 5000 THEN 'Invest (Winner)'
        
        ELSE 'Maintain' 
    END as action_tag
FROM pareto_calc p;
