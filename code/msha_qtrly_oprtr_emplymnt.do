********************************************************************************
* MSHA Quarterly Operator Employment Data
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_qtrly_oprtr_emplymnt_`logdate'.txt", append text
set linesize 225
version 14 // 15

* Quarterly Operator Employment
insheet using "../data/msha/msha_qtrly_oprtr_emplymnt.csv", comma clear

* Reshape all types of hours/emp wide, so can get unique at mine/quarter level
sort petreemine_id empl_prod_yr empl_prod_qtr
	
* Get the labels for each subunit in a local
levelsof subunit_cd, local(levels)
foreach cd in `levels' {
	di "`cd'"
	tab subunit_desc if subunit_cd==`cd'
}
local desc_1 "Underground"
local desc_2 "Surface at Underground"
local desc_3 "Strip, Quary, Open Pit"
local desc_4 "Auger"
local desc_5 "Culm Bank, Refuse Pile"
local desc_6 "Dredge"
local desc_12 "Other Mining"
local desc_17 "Independent Shops or Yards"
local desc_30 "Mill Operation, Prep Plant"
local desc_99 "Office Workers at Mine Site"

keep petreemine_id empl_prod_yr empl_prod_qtr subunit_cd avg_empl_cnt empl_hrs
reshape wide avg_empl_cnt empl_hrs ///
	, i(petreemine_id empl_prod_yr empl_prod_qtr) j(subunit_cd)
foreach cd in `levels' {
	lab var avg_empl_cnt`cd'  "Average emp, `desc_`cd''"
	lab var empl_hrs`cd' "Total hours, `desc_`cd''"
}

* Replace missing values to zero
foreach v of varlist avg_empl_cnt* empl_hrs* {
	replace `v' = 0 if `v'==.
}

* Generate various aggregations of employment/hours
* Total across all subunits
egen avg_empl_cnt_total = rowtotal(avg_empl_cnt*)
egen empl_hrs_total = rowtotal(empl_hrs*)
lab var avg_empl_cnt_total "Average employment"
lab var empl_hrs_total "Total working hours"

* Total minus office workers
gen empl_hrs_min_office = empl_hrs_total - empl_hrs99
gen avg_empl_cnt_min_office = avg_empl_cnt_total - avg_empl_cnt99
lab var empl_hrs_min_office "Total working hours, minus office workers"
lab var avg_empl_cnt_min_office "Average employment, minus office workers"

rename petreemine_id mine_id

compress
save "../data/msha/msha_qtrly_oprtr_emplymnt.dta", replace

cap log close
