********************************************************************************
* Put everything together into a mine-level panel
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/mine_panel_for_analysis_`logdate'.txt", append text
set linesize 225
version 14 // 15

* Prepare FIPS codes
*-------------------------------------------------------------------------------

import excel "../data/state_fips_codes.xlsx", sheet("Sheet1") firstrow clear		
rename state_code state_abbr
drop state_name
compress
save "../data/state_fips_codes.dta", replace
			
* Bring in MSHA data
*-------------------------------------------------------------------------------

* Bring in the time-invariant mine characteristics
insheet using "../data/msha/msha_mine.csv", comma clear

keep avg_mine_height cong_dist_cd controller_id ///
	curr_stat_cd curr_stat_dt state_abbr fips_cnty_cd latitude longitude ///
	mine_id mine_miles_ofc mine_type_cd miners_rep_ind office_cd oper_id ///
	full_sic_cd primary_sic* sic_desc secondary_sic_desc

* Merge in the FIPS state code so can get FIPS county codes
merge m:1 state_abbr using "../data/state_fips_codes.dta" ///
	, keep(master match) nogen

tostring fips_cnty_cd, replace
replace fips_cnty_cd = "0" + fips_cnty_cd if length(fips_cnty_cd)==2
replace fips_cnty_cd = "00" + fips_cnty_cd if length(fips_cnty_cd)==1

tostring state_fips, replace
replace state_fips = "0"+state_fips if length(state_fips)==1
gen fips_st_cty_cd = state_fips + fips_cnty_cd
lab var fips_st_cty_cd "FIPS state and county code"

* Merge in quarterly employment data
merge 1:m mine_id using "../data/msha/msha_qtrly_oprtr_emplymnt.dta" ///
	, keep(master match) gen(operator_emp_merge)
	
* 1.44% of mines don't match - these are overwhelmingly abandoned mines
tab curr_stat_cd if operator_emp_merge==1

* Moreover, mostly abandoned before 1980, which is before the employment series begin
codebook curr_stat_dt if operator_emp_merge==1

* Just drop these guys 
drop if operator_emp_merge==1
drop operator_emp_merge

rename sic_desc msha_commodity_name
rename empl_prod_yr year
rename empl_prod_qtr quarter

* Repeat for contractor quarterly employment data
merge m:1 mine_id year quarter using "../data/msha/msha_qtrly_cntrctr_emplymnt2.dta" ///
	, keep(master match) gen(contractor_emp_merge)

tab curr_stat_cd if contractor_emp_merge==1
codebook curr_stat_dt if contractor_emp_merge==1
drop if contractor_emp_merge==2
drop contractor_emp_merge

* Accidents
merge 1:1 mine_id year quarter using "../data/msha/msha_accident.dta" ///
	, keep(master match) gen(merge_accidents)

* Recode # injuries = 0 if observation did not match 
* (didn't have accidents in that mine-quarter)
ds inj_type_* accidents*_exper* *_injury ///
	no_injuries_*cntctr incident_*cntctr ///
	no_injuries no_incidents total_accidents* total_incidents* 
foreach v in `r(varlist)' {
	replace `v' = 0 if merge_accidents!=3
}

* Violations
merge 1:1 mine_id year quarter using "../data/msha/msha_inspection.dta" ///
	, keep(master match) gen(merge_insp)
replace insp_type_regular = 0 if merge_insp==1

cap drop year_quarter 
gen year_quarter = yq(year, quarter)
	format year_quarter %tq
	tsset mine_id year_quarter

* Note when a mine begins operating, and when it is abandoned
* Date a mine begins operating
preserve
	insheet using "../data/msha/msha_operator_history.csv", comma clear
	
	gen oper_begin_date2 = date(oper_start_dt, "YMD")
	gen oper_begin_quarter= qofd(oper_begin_date2 )
		format oper_begin_quarter %tq
	
	egen mine_begin_quarter = min(oper_begin_quarter), by(mine_id)
		format mine_begin_quarter %tq
	
	keep mine_id mine_begin_quarter
	duplicates drop
	tempfile mine_begin_dates
	save `mine_begin_dates', replace
restore
merge m:1 mine_id using `mine_begin_dates', keep(master match) nogen
	
* Date abandoned
gen mine_opened = year_quarter>=mine_begin_quarter
gen current_stat_date = date(curr_stat_dt, "YMD")
	format current_stat_date %td 
	
* Make a quarter version
gen current_stat_qt = qofd(current_stat_date )
	format current_stat_qt %tq
gen byte mine_abandoned = curr_stat_cd=="Abandoned" & year_quarter>current_stat_qt
sort mine_id year_quarter

* Merge in controller and operator history
ren oper_id curr_oper_id // current operator id
ren controller_id curr_ctrlr_id // current controller id
merge m:1 mine_id year_quarter using "../data/msha/msha_operator_history.dta" ///
	, gen(_merge_oper_history)
	drop if _merge_oper_history==2
	drop _merge_oper_history
merge m:1 oper_id year_quarter using "../data/msha/msha_controller_history.dta" ///
	, gen(_merge_ctrlr_history)
	drop if _merge_ctrlr_history==2
	drop _merge_ctrlr_history

* Indicator for whether a mine is currently active
gen byte active = mine_opened==1 & mine_abandoned!=1 & avg_empl_cnt_total > 0
lab var active "Mine is active this quarter"

* Log hours and employment
foreach v of varlist *empl* {
	cap drop ln_`v'
	local l: variable label `v'
	cap noi sum `v' if `v' > 0, d
	cap noi gen ln_`v' = ln(`v' + `r(p1)')
	cap lab var ln_`v' "log `l'"
}

* Injury rates per FTE (full-time worker
*qui sum empl_hrs_total if empl_hrs_total > 0, d
* add 20 to the denominator, the equivalent of one person working a half week 
* (the first percentile is 3 hours, which seems too low)
gen inj_rate_hrs = total_accidents / (20 + empl_hrs_total) * 50000
gen inj_rate_min_nn_hrs = total_accidents_min_nn / (20 + empl_hrs_total) * 50000
gen inc_rate_hrs = total_incidents / (20 + empl_hrs_total) * 50000
gen inc_rate_min_nn_hrs = total_incidents_min_nn / (20 + empl_hrs_total) * 50000
ds inj_rate_hrs inj_rate_min_nn_hrs ///
	inc_rate_hrs inc_rate_min_nn_hrs 
foreach v in `r(varlist)' {
	gen `v'_tc = `v' // topcode
	qui sum `v' if `v' > 0, d
	replace `v'_tc = `r(p99)' if `v'>`r(p99)' & `v'!=.
	qui sum `v' if `v' > 0, d // Log injury rate
	gen ln_`v' = ln(`r(p1)' + `v')
}

* Dummy for underground mines
gen byte underground = .
replace underground = 1 if mine_type_cd=="Underground"
replace underground = 0 if mine_type_cd=="Surface" | mine_type_cd=="Facility"

* Topcode
ds *_viol total_accident* total_incident* *_injury /// 
	avg_empl_cnt_total empl_hrs_total empl_hrs_min_office avg_empl_cnt_min_office /// 
	accidents_*exper* no_injuries_*cntctr incident_*cntctr 
foreach v in `r(varlist)' {
	local l: variable label `v'
	gen `v'_tc = `v'
	qui sum `v' if `v'>0, d
	replace `v'_tc = `r(p99)' if `v'>`r(p99)' & `v'!=.
	lab var `v'_tc "`l'"
}

* Merge in price data
*-------------------------------------------------------------------------------

* primary commodity
merge m:1 msha_commodity_name year quarter using "../data/price/std_price.dta" ///
	, keep(master match) gen(merge_lme)
cap noi drop source
d std_price std_price_mt ln_std_price_mt

* secondary commodity
ren msha_commodity_name msha_commodity_name_1st
ren secondary_sic_desc msha_commodity_name
ren *std_price* *std_1st_price*
merge m:1 msha_commodity_name year quarter using "../data/price/std_price.dta" ///
	, keep(master match) gen(merge_2nd) ///
	keepusing(*std_price*)

cap noi drop source
ren *std_price* *std_2nd_price*
ren *std_1st_price* *std_price*
ren msha_commodity_name msha_commodity_name_2nd
ren msha_commodity_name_1st msha_commodity_name
d std_2nd_price std_2nd_price_mt ln_std_2nd_price_mt
	
* Indicator for whether commodity ever has a price
gen byte has_price = std_price!=.
egen byte ever_has_price = max(has_price), by(msha_commodity_name)
lab var ever_has_price "Commodity has price data at any point"
drop has_price
			
* Merge production data
merge m:1 msha_commodity_name year quarter using ///
	"../data/production/datastream_production.dta" ///
	, keep(master match) gen(merge_production_datastream)

xtset mine_id year_quarter
compress
save "../data/mine_panel_for_analysis.dta", replace

cap log close
