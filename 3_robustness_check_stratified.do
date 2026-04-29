* ==============================================================================
* Project: Impact of US-China Trade War on Sino-US Joint Venture Survival
* Task: Robustness Check - Outlier Trimming, Randomized A/B Split & Hierarchical Regression
* Author: [Your Name]
* ==============================================================================

clear all
set more off

* ------------------------------------------------------------------------------
* 1. Data Import
* ------------------------------------------------------------------------------
import delimited "sample_JV_data.csv", encoding(UTF-8) clear 

* ------------------------------------------------------------------------------
* 2. Variable Renaming & Interaction Terms
* ------------------------------------------------------------------------------
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

* Construct Interaction Terms
capture drop Post_X1 Post_X2
gen Post_X1 = Post * X1
gen Post_X2 = Post * X2

* ------------------------------------------------------------------------------
* 3. Data Cleaning: Trimming Extreme Outliers (1st & 99th Percentiles)
* ------------------------------------------------------------------------------
dis ""
dis "=========================================================="
dis " STEP 1: Detecting and Trimming Outliers"
dis "=========================================================="

local continuous_vars "C2 C4 C6 C8 ln_Parent_Patents"

foreach v of local continuous_vars {
    qui summarize `v', detail
    local p1 = r(p1)
    local p99 = r(p99)
    
    dis ">>> Identified outliers for variable 【`v'】:"
    list Deal_Name `v' if (`v' < `p1' | `v' > `p99') & !missing(`v')
    
    qui drop if (`v' < `p1' | `v' > `p99') & !missing(`v')
}
dis ">>> SUCCESS: Outlier cleaning completed."

* ------------------------------------------------------------------------------
* 4. Randomized A/B Split (Cross-Validation Approach)
* ------------------------------------------------------------------------------
dis ""
dis "=========================================================="
dis " STEP 2: Randomized A/B Split for Surviving JVs"
dis "=========================================================="

* Identify if the JV ever failed during its lifecycle (1=Failed, 0=Survived)
egen max_death = max(Death_Event), by(Deal_Name)

* Create a unique tag for each JV to avoid splitting the same company across groups
egen tag = tag(Deal_Name)

* Set random seed for reproducibility (Crucial for data science standards)
set seed 42

* Generate random numbers and broadcast to all years for a specific JV
gen rand_tmp = runiform() if max_death == 0 & tag == 1
egen jv_rand = max(rand_tmp), by(Deal_Name)
drop rand_tmp

* Find the median of the random distribution to split equally
qui sum jv_rand if max_death == 0 & tag == 1, detail
local median_rand = r(p50)

* Assign groups: All failed JVs are kept as the baseline, surviving JVs are split 50/50
gen sample_A = (max_death == 1) | (max_death == 0 & jv_rand <= `median_rand' & !missing(jv_rand))
gen sample_B = (max_death == 1) | (max_death == 0 & jv_rand > `median_rand' & !missing(jv_rand))

* Validate the split
count if tag == 1 & sample_A == 1
dis "Sample A - Unique JVs Count: " r(N)
count if tag == 1 & sample_B == 1
dis "Sample B - Unique JVs Count: " r(N)

* ------------------------------------------------------------------------------
* 5. Hierarchical Regression Modeling (Stepwise inclusion of Controls)
* ------------------------------------------------------------------------------
* Define macros for step-by-step model building to test coefficient stability
local core "X1 X2 Post Post_X1 Post_X2"
local m1 "`core'"
local m2 "`m1' C4"                      // + JV Duration
local m3 "`m2' C6"                      // + US Ownership Pct
local m4 "`m3' C8"                      // + Parent Firm Age
local m5 "`m4' ln_Parent_Patents"       // + Parent Patents (Log)
local m6 "`m5' C2"                      // + Parent Innovation Quality

foreach grp in A B {
    dis ""
    dis "========================================================="
    dis " LAUNCHING: Hierarchical Regression for Sample `grp'"
    dis "========================================================="
    
    dis ""
    dis ">>> Model 1: Baseline (No Controls)"
    logit Death_Event `m1' if sample_`grp' == 1, vce(cluster Deal_Name)

    dis ""
    dis ">>> Model 2: Adding JV Duration"
    logit Death_Event `m2' if sample_`grp' == 1, vce(cluster Deal_Name)

    dis ""
    dis ">>> Model 3: Adding US Ownership Pct"
    logit Death_Event `m3' if sample_`grp' == 1, vce(cluster Deal_Name)

    dis ""
    dis ">>> Model 4: Adding Parent Firm Age"
    logit Death_Event `m4' if sample_`grp' == 1, vce(cluster Deal_Name)

    dis ""
    dis ">>> Model 5: Adding Log of Parent Patents"
    logit Death_Event `m5' if sample_`grp' == 1, vce(cluster Deal_Name)

    dis ""
    dis ">>> Model 6: Adding Parent Innovation Quality (Full Model)"
    logit Death_Event `m6' if sample_`grp' == 1, vce(cluster Deal_Name)
}

dis "========================================================="
dis "🎉 SUCCESS: All data processing and regression models completed!"
dis "========================================================="
