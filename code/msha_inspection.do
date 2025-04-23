********************************************************************************
* MSHA Inspections Data
********************************************************************************

cap log close
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_inspection_`logdate'.txt", append text
set linesize 225
version 14 // 15

insheet using "../data/msha/msha_inspection.csv", comma clear

* There is weirdly one duplicate inspection - drop it
duplicates drop event_no, force
keep mine_id event_no acty_* beg_dt end_dt cal_*

* Merge in the violations found in an inspection
merge 1:1 event_no using "../data/msha/msha_violation.dta", keep(master match)
foreach v of varlist *viol {
	replace `v' = 0 if _merge==1
}

* Classify inspection types
replace acty_desc = upper(acty_desc)
gen insp_type_regular = regexm(acty_desc, "REGULAR")
gen insp_type_spot = regexm(acty_desc, "SPOT")
gen insp_type_compliance = regexm(acty_desc, "COMPLIANCE")
gen insp_type_tech = regexm(acty_desc, "TECHNICAL")

* For now, only keep regular inspections for measures of compliance
keep if insp_type_regular==1

* Collapse to the mine/quarter level
collapse (sum) insp_type_regular *viol, by(mine_id cal_yr cal_qtr)

* Label variables
foreach part in `parts' { // excluding part55
	cap lab var part`part'_viol "`label_`part''"
}
lab var total_viol "Total number of violations this quarter"
lab var sig_sub_viol "Number of S and S violations this quarter"
lab var high_negligence_viol "Number of high neglgence violations this quarter"
rename cal_yr year
rename cal_qtr quarter

compress
save "../data/msha/msha_inspection.dta", replace

cap log close
