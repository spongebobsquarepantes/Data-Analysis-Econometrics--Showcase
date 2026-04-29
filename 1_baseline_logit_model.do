* ==============================================================================
* Project: Impact of US-China Trade War on Sino-US Joint Venture Survival
* Task: Baseline Logit Regression Analysis
* Author: [Your Name]
* ==============================================================================

clear all              
set more off           

* 1. Data Import
* Note: Replace the path below with your local path or relative path
import delimited "sample_JV_data.csv", encoding(UTF-8) clear 

* ------------------------------------------------------------------------------
* 2. Variable Renaming & Standardization
* ------------------------------------------------------------------------------
* Core Independent Variables (IVs)
rename x1tech* X1               // Tech Sensitivity
rename x2strategic* X2          // Strategic Decoupling
rename post_trade* Post         // Post Trade War Dummy

* Control Variables (CVs)
rename c2_parentfirm* C2        // Parent Firm Innovation Quality
rename c4_jv* C4                // JV Duration (Age)
rename c6_us* C6                // US Ownership Pct
rename c8_parent* C8            // Parent Firm Age

* Dependent Variable (DV) & Identifiers
rename death_event Death_Event  // 1 = Exit/Dissolution, 0 = Survival
rename deal_name Deal_Name
rename ln_parent_pat* ln_Parent_Patents

* ------------------------------------------------------------------------------
* 3. Constructing Interaction Terms
* ------------------------------------------------------------------------------
capture drop Post_X1 Post_X2

gen Post_X1 = Post * X1
label var Post_X1 "Policy Shock * Tech Sensitivity"

gen Post_X2 = Post * X2
label var Post_X2 "Policy Shock * Strategic Decoupling"

* ------------------------------------------------------------------------------
* 4. Model Estimation: Logit Regression
* ------------------------------------------------------------------------------
* We use Clustered Robust Standard Errors at the JV (Deal_Name) level 
* to account for within-firm correlation over time.

logit Death_Event X1 X2 Post Post_X1 Post_X2 C2 C4 C6 C8 ln_Parent_Patents, vce(cluster Deal_Name)

* ------------------------------------------------------------------------------
* 5. Exporting Results (Optional)
* ------------------------------------------------------------------------------
* outreg2 using "Baseline_Results.doc", replace word dec(3) title("Baseline Logit Analysis")

dis "=========================================================="
dis "SUCCESS: Baseline regression completed."
dis "=========================================================="
