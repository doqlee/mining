********************************************************************************
* MSHA Contractor History Data
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_contractor_history_`logdate'.txt", append text
set linesize 225
version 14 // 15

insheet using "../data/msha/msha_mine_contractor.csv", comma clear names

* Converting controller starting and ending dates to numeric format
foreach pp in start end {
	cap drop cntctr_`pp'_daten // numeric dates1
	gen int cntctr_`pp'_daten = date(cntctr_`pp'_dt, "YMD")
	format cntctr_`pp'_daten %td
	cap drop cntctr_`pp'_dt
	
	cap drop cntctr_`pp'_year // numeric years
	gen int cntctr_`pp'_year = year(cntctr_`pp'_daten)
	
	cap drop cntctr_`pp'_quarter // numeric quarters
	gen byte cntctr_`pp'_quarter = quarter(cntctr_`pp'_daten)
}
replace cntctr_start_quarter = 1 if cntctr_start_year < 1980 // to avoid consuming RAM when expanding
replace cntctr_start_year = max(cntctr_start_year, 1980) // to avoid consuming RAM when expanding

gen int year_quarter = yq(cntctr_start_year, cntctr_start_quarter)
format year_quarter %tq

* Count the number of quarters for which a controller was active.
* If a controller has an end date, then take the number of quarters between starting and ending dates. 
* Otherwise count the number of quarters since start date up to 2017Q4. 
cap drop cntctr_active_quarters
gen int cntctr_active_quarters = ///
	yq(cntctr_end_year, cntctr_end_quarter) - yq(cntctr_start_year, cntctr_start_quarter) + 1
replace cntctr_active_quarters = ///
	yq(2017, 4) - yq(cntctr_start_year, cntctr_start_quarter) + 1 if mi(cntctr_end_daten)

* Expand the mine-operator observations into a panel of mine-quarter observations.
expand cntctr_active_quarters, gen(dup)
bys mine_id dup cntctr_start_daten: replace year_quarter = year_quarter + _n if dup > 0
	sort mine_id cntctr_id cntctr_start_daten year_quarter

* There are duplicates coming from the mine changing its operator in middle of a given quarter. 
* Keep the latest value so that each observation links a mine with its operator at end of quarter. 
duplicates tag mine_id year_quarter, gen(tag)
	tab tag, m
sort mine_id year_quarter cntctr_start_daten
bys mine_id year_quarter tag (cntctr_start_daten): keep if _n==_N

duplicates report mine_id year_quarter
	cap drop dup
	cap drop tag
xtset mine_id year_quarter
keep mine_id cntctr_id year_quarter *_nm *_daten
cap drop year quarter
gen year = yofd(dofq(year_quarter))
gen quarter = quarter(dofq(year_quarter))

compress
save "../data/msha/msha_contractor_history.dta", replace

* Merge with contractor employment data
merge m:1 cntctr_id year quarter using "../data/msha/msha_qtrly_cntrctr_emplymnt.dta"
	drop if _merge==2
	drop _merge
fcollapse (sum) *empl*, by(mine_id year_quarter year quarter)
xtset mine_id year_quarter

compress
save "../data/msha/msha_qtrly_cntrctr_emplymnt2.dta", replace
