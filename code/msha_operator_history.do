********************************************************************************
* MSHA Operator History Data
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_operator_history_`logdate'.txt", append text
set linesize 225
version 14 // 15

insheet using "../data/msha/msha_operator_history.csv", comma clear names

* Controller starting and ending dates into numeric format
foreach pp in start end {
	cap drop oper_`pp'_daten // numeric dates1
	gen int oper_`pp'_daten = date(oper_`pp'_dt, "YMD")
	format oper_`pp'_daten %td
	cap drop oper_`pp'_dt
	
	cap drop oper_`pp'_year // numeric years
	gen int oper_`pp'_year = year(oper_`pp'_daten)
	
	cap drop oper_`pp'_quarter // numeric quarters
	gen byte oper_`pp'_quarter = quarter(oper_`pp'_daten)
}

gen int year_quarter = yq(oper_start_year, oper_start_quarter)
format year_quarter %tq

* Count the number of quarters for which a controller was active
* If controller has an end date, take the # quarters between starting/ending dates
* Otherwise count the number of quarters since start date up to 2017Q4. 
cap drop oper_active_quarters
gen int oper_active_quarters = ///
	yq(oper_end_year, oper_end_quarter) - yq(oper_start_year, oper_start_quarter) + 1
replace oper_active_quarters = ///
	yq(2017, 4) - yq(oper_start_year, oper_start_quarter) + 1 if mi(oper_end_daten)

* Expand the mine-operator observations into a panel of mine-quarter observations.
expand oper_active_quarters, gen(dup)
bys mine_id dup oper_start_daten: replace year_quarter = year_quarter + _n if dup > 0
sort mine_id oper_id oper_start_daten year_quarter

* There are duplicates coming from the mine changing its operator in middle of a given quarter. 
* Keep the latest value so that each observation links a mine with its operator at end of quarter. 
duplicates tag mine_id year_quarter, gen(tag)
tab tag, m
sort mine_id year_quarter oper_start_daten
bys mine_id year_quarter tag (oper_start_daten): keep if _n==_N

* Check for duplicates, xtset, and save
duplicates report mine_id year_quarter
cap drop dup
cap drop tag
xtset mine_id year_quarter
keep mine_id oper_id year_quarter *_nm *_daten

compress
save "../data/msha/msha_operator_history.dta", replace
