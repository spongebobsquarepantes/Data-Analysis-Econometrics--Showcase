* ==============================================================================
* Project: Impact of US-China Trade War on Sino-US Joint Venture Survival
* Task: Robustness Check (Handling Extreme Outliers via Trimming)
* ==============================================================================

clear all
set more off

* 1. Data Import
import delimited "sample_JV_data.csv", encoding(UTF-8) clear 

* 2. Variable Renaming (Consistent with Baseline)
rename x1tech* X1
rename x2strategic* X2
rename post_trade* Post
rename c2_parentfirm* C2
rename c4_jv* C4
rename c6_us* C6
rename c8_parent* C8
rename death_event Death_Event
rename deal_name Deal_Name
rename ln_parent_pat* ln_Parent_Patents

* 3. Constructing Interaction Terms
gen Post_X1 = Post * X1
gen Post_X2 = Post * X2

* ------------------------------------------------------------------------------
* 4. Data Cleaning: Outlier Detection & Trimming (Top 1% & Bottom 1%)
* ------------------------------------------------------------------------------
dis "=========================================================="
dis "IN PROGRESS: Detecting and Trimming Outliers (1st/99th Percentiles)"
dis "=========================================================="

local continuous_vars "C2 C4 C6 C8 ln_Parent_Patents"

foreach v of local continuous_vars {
    * Calculate 1st and 99th percentiles
    qui summarize `v', detail
    local p1 = r(p1)
    local p99 = r(p99)
    
    * Log identified outliers for transparency
    dis ""
    dis ">>> Identified outliers for variable 【`v'】 (Below `p1' or Above `p99'):"
    list Deal_Name `v' if (`v' < `p1' | `v' > `p99') & !missing(`v')
    
    * Drop extreme observations (Trimming)
    qui drop if (`v' < `p1' | `v' > `p99') & !missing(`v')
    dis "Result: Extreme samples for 【`v'】 have been dropped."
}

dis "=========================================================="
dis "Outlier handling complete. Proceeding to Model Estimation..."
dis "=========================================================="

* ------------------------------------------------------------------------------
* 5. Model Estimation: Logit Regression (Trimmed Sample)
* ------------------------------------------------------------------------------
logit Death_Event X1 X2 Post Post_X1 Post_X2 C2 C4 C6 C8 ln_Parent_Patents, vce(cluster Deal_Name)

* ------------------------------------------------------------------------------
* 6. Exporting Results
* ------------------------------------------------------------------------------
* outreg2 using "Robustness_Trimmed_Results.doc", replace word dec(3) title("Logit Analysis (Trimmed Sample)")

dis "SUCCESS: Robustness check with trimmed sample completed."
