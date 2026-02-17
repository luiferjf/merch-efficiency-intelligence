# Dashboard Wireframe: Merchandising Performance & SKU Optimization

This dashboard is designed to be the "Operational Brain" for catalog rationalization. It transforms historical sales into a "SKU Action Playbook" (Keep / Invest / Kill).

## 🏛️ Layout Structure

### Sheet 1: Design Pareto (Concentration Analysis)
*   **Business Question:** Which designs (Styles) sustain 80% of our revenue?
*   **Visual:** Pareto Chart (Bar + Cumulative Line).
*   **Dimensions:** `style_id` (Sorted by `total_style_revenue`).
*   **Action:** Identify and protect the core assets. Proves that a bulk of the catalog is "noise".

### Sheet 2: The Efficiency Matrix (Portfolio Maturity)
*   **Business Question:** Which products justify their existence based on complexity vs. return?
*   **Visual:** Scatter Plot (Quadrants).
*   **X-Axis:** `dead_variant_ratio` (Complexity - lower is better).
*   **Y-Axis:** `total_style_revenue` (Scale).
*   **Bubble Size:** `style_variant_count` (Total complexity cost).
*   **Colors:** `action_tag` (Invest, Maintain, Review, Kill).
*   **Action:** Immediate visualization of the "Kill List" (Bottom-Left) vs. "Winners" (Top-Right).

### Sheet 3: Dead Weight Audit (Inventory Hygiene)
*   **Business Question:** How much operational "fat" (unsold variants) exists in each Niche/Theme?
*   **Visual:** Stacked Bar Chart (100%).
*   **Dimension:** `std_theme`.
*   **Color Segments:** % Sold Variants vs. % Dead Variants (Never Sold).
*   **Action:** Identify themes with high catalog bloat to cut future production.

### Sheet 4: Attribute Performance (Variant Precision)
*   **Business Question:** Are we producing colors or sizes that the market doesn't want?
*   **Visual:** Heatmap or Bar Chart.
*   **Metrics:** `% of Sales Share` vs. `% of Catalog Variety`.
*   **Dimensions:** `std_color` and `std_size_list`.
*   **Action:** Discontinue underperforming attributes (e.g., colors that represent 20% of catalog but <1% of sales).

---

## 🛠️ Data Implementation Note
To build this in Tableau:
1.  **DataSource:** Connect to the final table `tableau_merch_optimization`.
2.  **Why:** This table already contains the pre-calculated ratios (`dead_variant_ratio`, `rev_per_variant`) and the `action_tag` logic, making the Tableau build a simple drag-and-drop process.
