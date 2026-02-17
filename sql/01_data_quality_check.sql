-- ======================================================================
-- PROJECT: Merchandising Performance & SKU Optimization
-- SCRIPT: 01_data_quality_check.sql
-- DESCRIPTION: Pre-Analysis Audit. Ensures "Garbage In, Garbage Out" protection.
-- FOCUS: Validating Taxonomy Integrity (Category vs. Attribute Logic)
-- ======================================================================

-- 1. AUDIT: Identify "Orphaned" SKUs (Products missing core taxonomy)
--    Business Rule: Every active product must have a 'Category' and 'Theme'.
SELECT 
    store_code,
    COUNT(*) as orphaned_skus,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg_merch_enriched_data), 2) as pct_orphaned
FROM stg_merch_enriched_data
WHERE 
    (std_category IS NULL OR std_category = '')
    OR (std_theme IS NULL OR std_theme = '')
GROUP BY store_code
HAVING orphaned_skus > 0;

-- 2. AUDIT: The "Double-Confirmation" Logic (Attribute vs. Category Mismatch)
--    Business Rule: If a product is categorized as 'Soccer', it implies it must have
--    specific attributes. If not, it's a data entry error.
SELECT 
    product_id,
    sku,
    product_name,
    std_category as assigned_category,
    detected_keywords
FROM stg_merch_enriched_data
WHERE 
    std_category = 'Soccer' 
    AND detected_keywords NOT LIKE '%jersey%' 
    AND detected_keywords NOT LIKE '%training%'
LIMIT 100;

-- 3. AUDIT: Duplicate SKU Check (System Integrity)
--    Business Rule: SKU must be unique per Store.
SELECT 
    sku, 
    store_code, 
    COUNT(*) as occurrence_count
FROM stg_merch_enriched_data
GROUP BY sku, store_code
HAVING COUNT(*) > 1;

-- 4. SUMMARY TABLE: Quality Scorecard
--    Used to report "Data Health" to stakeholders before analysis begins.
CREATE OR REPLACE TABLE audit_quality_scorecard AS
SELECT 
    store_code,
    COUNT(*) as total_records,
    SUM(CASE WHEN sale_price IS NULL THEN 1 ELSE 0 END) as missing_price_count,
    SUM(CASE WHEN std_category IS NULL THEN 1 ELSE 0 END) as missing_taxonomy_count
FROM stg_merch_enriched_data
GROUP BY store_code;
