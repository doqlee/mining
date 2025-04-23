********************************************************************************
* MSHA Controller History Data
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_controller_history_`logdate'.txt", append text
set linesize 225
version 14 // 15

insheet using "../data/msha/msha_controller_history.csv", comma clear names

* Converting controller starting and ending dates to numeric format
foreach pp in start end {
	cap drop ctrlr_`pp'_daten // numeric dates
	gen int ctrlr_`pp'_daten = date(ctrlr_`pp'_dt, "YMD")
	format ctrlr_`pp'_daten %td
	cap drop ctrlr_`pp'_dt
	
	cap drop ctrlr_`pp'_year // numeric years
	gen int ctrlr_`pp'_year = year(ctrlr_`pp'_daten)
	
	cap drop ctrlr_`pp'_quarter // numeric quarters
	gen byte ctrlr_`pp'_quarter = quarter(ctrlr_`pp'_daten)
}

gen int year_quarter = yq(ctrlr_start_year, ctrlr_start_quarter)
format year_quarter %tq

* Count the number of quarters for which a controller was active.
* If a controller has an end date, then take the number of quarters between starting and ending dates. 
* Otherwise count the number of quarters since start date up to 2017Q4. 
cap drop ctrlr_active_quarters
gen int ctrlr_active_quarters = ///
	yq(ctrlr_end_year, ctrlr_end_quarter) - yq(ctrlr_start_year, ctrlr_start_quarter) + 1
replace ctrlr_active_quarters = ///
	yq(2017, 4) - yq(ctrlr_start_year, ctrlr_start_quarter) + 1 if mi(ctrlr_end_daten)

* Drop duplicate records. These duplicates differ only in the controller name. 
duplicates tag oper_id ctrlr_id ctrlr_start_daten, gen(tmp)
	tab tmp, m
drop if tmp > 0 & _n > 1
	cap drop tmp

* Expand the operator-controller observations into a panel of operator-quarter observations.
expand ctrlr_active_quarters, gen(dup)
bys oper_id dup ctrlr_start_daten: replace year_quarter = year_quarter + _n if dup > 0
	sort oper_id ctrlr_id ctrlr_start_daten ctrlr_end_daten ctrlr_nm year_quarter

* There are duplicates coming from the operator changing its controller in middle of a given quarter. 
* Keep the latest value so that each observation links an operator with its controller at end of quarter. 
duplicates tag oper_id year_quarter, gen(tag)
	tab tag, m
sort oper_id year_quarter ctrlr_start_daten
bys oper_id year_quarter tag (ctrlr_start_daten): keep if _n==_N

duplicates report oper_id year_quarter // should be 0
	cap drop dup
	cap drop tag
keep oper_id ctrlr_id year_quarter *_nm *_daten

compress
save "../data/msha/msha_controller_history.dta", replace
