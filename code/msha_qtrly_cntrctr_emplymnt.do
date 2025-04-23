********************************************************************************
* MSHA Quarterly Contractor Employment Data
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_qtrly_cntrctr_emplymnt_`logdate'.txt", append text
set linesize 225
version 14 // 15

* Contractor employment
insheet using "../data/msha/msha_qtrly_cntrctr_emplymnt.csv", comma clear

* Reshape all types of hours/emp wide, so can get unique at mine/quarter level
sort cntctr_id empl_prod_yr empl_prod_qtr
	
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

* Contractor/quarter/subunit/commodity level
keep cntctr_id empl_prod_yr empl_prod_qtr subunit_cd avg_empl_cnt empl_hrs cmdty_type
cap drop tag
duplicates report cntctr_id empl_prod_yr empl_prod_qtr subunit_cd cmdty_type
collapse (sum) avg_empl_cnt empl_hrs, ///
	by(cntctr_id empl_prod_yr empl_prod_qtr subunit_cd cmdty_type)

ren avg_empl_cnt cntctr_avg_empl_cnt_ 
ren empl_hrs cntctr_empl_hrs_

reshape wide cntctr_avg_empl_cnt_ cntctr_empl_hrs_ /// 
	, i(cntctr_id empl_prod_yr empl_prod_qtr subunit_cd) j(cmdty_type) string

reshape wide cntctr_avg_empl_cnt_M cntctr_avg_empl_cnt_C ///
	cntctr_empl_hrs_M cntctr_empl_hrs_C ///
	, i(cntctr_id empl_prod_yr empl_prod_qtr) j(subunit_cd)

foreach cd in `levels' {
	lab var cntctr_avg_empl_cnt_M`cd'  "Average emp (Metal), contractor, `desc_`cd''"
	lab var cntctr_avg_empl_cnt_C`cd'  "Average emp (Coal), contractor, `desc_`cd''"
	lab var cntctr_empl_hrs_M`cd' "Total hours (Metal), contractor, `desc_`cd''"
	lab var cntctr_empl_hrs_C`cd' "Total hours (Coal), contractor, `desc_`cd''"
}

* Replace missing values to zero
foreach v of varlist cntctr_avg_empl_cnt* cntctr_empl_hrs* {
	replace `v' = 0 if `v'==.
}
drop *_C* // drop employment in coal mining
d

* Generate various aggregations of employment/hours
* Total across all subunits
egen cntctr_avg_empl_cnt_total = rowtotal(cntctr_avg_empl_cnt*)
egen cntctr_empl_hrs_total = rowtotal(cntctr_empl_hrs*)
lab var cntctr_avg_empl_cnt_total "Average contractor employment"
lab var cntctr_empl_hrs_total "Total contractor working hours"

* Total minus office workers
gen cntctr_empl_hrs_min_office = cntctr_empl_hrs_total - cntctr_empl_hrs_M99
gen cntctr_avg_empl_cnt_min_office = cntctr_avg_empl_cnt_total - cntctr_avg_empl_cnt_M99
lab var cntctr_empl_hrs_min_office "Total contractor working hours, minus office workers"
lab var cntctr_avg_empl_cnt_min_office "Average contractor employment, minus office workers"

ren empl_prod_yr year
ren empl_prod_qtr quarter

compress
save "../data/msha/msha_qtrly_cntrctr_emplymnt.dta", replace

cap log close
