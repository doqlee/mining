********************************************************************************
* Price Shocks and Mine Production at the Extensive and Intensive Margin
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/table4_`logdate'.txt", append text
set linesize 225
version 14 // 15

* Table 4 columns (1) and (2). Dependent variable: # Employees
*-------------------------------------------------------------------------------

* See if price shocks affect the number of active mines each quarter, 
* separately for underground and surface mines
u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1, clear
	sort mine_id year_quarter

* Create an indicator for whether a mine is active
cap drop active
gen active =  mine_opened==1 & mine_abandoned!=1 & avg_empl_cnt_total > 0
gen active_ug = active==1 & underground==1
gen active_surface = active==1 & underground!=1

gen avg_empl_cnt_total_ug  = avg_empl_cnt_total if underground==1
gen avg_empl_cnt_total_surf = avg_empl_cnt_total if underground!=1

gen empl_hrs_min_office_ug = empl_hrs_min_office if underground==1
gen empl_hrs_min_office_surf = empl_hrs_min_office if underground!=1
collapse (sum) active* ///
	avg_empl_cnt_total avg_empl_cnt_total_ug avg_empl_cnt_total_surf ///
	empl_hrs_min_office_surf empl_hrs_min_office_ug empl_hrs_min_office ///
	, by(msha_commodity_name year_quarter)

* Quarters with zero active mines per commodity in the MSHA database, 
* won't be present in this dataset as is, so need to expand to include all quarters
egen commodity_group = group(msha_commodity_name)
tsset commodity_group year_quarter
tsfill, full
foreach v of varlist active* *empl* {
	replace `v' = 0 if `v'==.
}
gen year = year(dofq(year_quarter))
gen quarter = quarter(dofq(year_quarter))

* The Commodity name needs to be filled in to the expanded rows
preserve
	keep if msha_commodity_name!=""
	keep msha_commodity_name commodity_group
	duplicates drop
	tempfile names
	save `names', replace
restore
drop msha_commodity_name
merge m:1 commodity_group using `names'
	
* Merge in the price data. Need to do again so that the quarters with 0 active mines get data
merge m:1 msha_commodity_name year quarter using ///
	"../data/price/lme.dta", keep(master match) gen(merge_lme)
merge m:1 msha_commodity_name year quarter using ///
	"../data/price/bloomberg.dta", keep(master match) gen(merge_bloomberg)
merge m:1 msha_commodity_name year quarter using ///
	"../data/price/datastream.dta", keep(master match) gen(merge_datastream)

* Create an authoritative price
gen commodity_price_mt = price_mt_lme
	replace commodity_price_mt = price_mt_datastream ///
		if price_mt_lme==. & price_mt_datastream!=.
	replace commodity_price_mt = price_mt_bloomberg ///
		if  price_mt_lme==. & price_mt_datastream==. & price_mt_bloomberg!=.
	lab var commodity_price_mt "Commodity price this quarter"
gen ln_commodity_price_mt = ln(commodity_price_mt)
	lab var ln_commodity_price_mt "log (price) this quarter"

* Create lagged prices
sort commodity_group year_quarter
local l: variable label ln_commodity_price 
forvalues i = 1/4 {
	gen l`i'_ln_commodity_price  = l`i'.ln_commodity_price 
		lab var l`i'_ln_commodity_price "`l', lagged `i' quarter"
	gen f`i'_ln_commodity_price  = f`i'.ln_commodity_price 
		lab var f`i'_ln_commodity_price "`l', lead `i' quarter"
}

* total log employment/horus
foreach v of varlist *empl* {
	qui sum `v' if `v'>0, d
	gen ln_`v' = ln(`v'+`r(p1)')
}

* log active mines
foreach v of varlist active active_ug active_surface {
	qui sum `v' if `v'>0, d
	gen ln_`v' = ln(`v'+`r(p1)')
}

*---------- First Differences ----------*

sort commodity_group year_quarter
tsset commodity_group year_quarter
foreach v of varlist active* ln_active* ln_avg_empl_cnt_total* l*_ln_commodity_price {
	gen `v'_dif = `v'-l4.`v'
	gen `v'_diff1 = `v'-l1.`v'
	local l: variable label `v' 
	lab var `v'_diff "`l', First Differenced"
}

* Labels for tex formatting
forvalues i = 1/4 {
	lab var l`i'_ln_commodity_price_dif "$ \Delta \textit{Price}_{jt-`i'}$"
}
lab var active_dif "$ \shortstack{Active Mines\\Total}$"
lab var active_surface_dif "$ \shortstack{Active Mines\\Surface}$"
lab var active_ug_dif "$ \shortstack{Active Mines\\Underground}$"

* Weight observations by the # of mines actively producing 4 quarters prior
gen l4_active = l4.active 

estimates clear
eststo clear

* Total
eststo: reghdfe ln_active_dif  l1_ln_commodity_price_dif [aw = l4_active] ///
	, a(i.year i.quarter) vce(cluster commodity_group#year_quarter) 
	local dv = "`e(depvar)'"
	local dv = substr("`dv'", 1, length("`dv'")-4)
	sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	estadd local yq_fe "Y", replace

* 4 lags - total
eststo: reghdfe ln_active_dif  l*_ln_commodity_price_dif [aw = l4_active] ///
	, a(i.year i.quarter) vce(cluster commodity_group#year_quarter) 
	test l1_ln_commodity_price_dif + l2_ln_commodity_price_dif + ///
		l3_ln_commodity_price_dif + l4_ln_commodity_price_dif = 0
		if r(p)<0.01 loc stars = "***"
		else if r(p)<0.05 loc stars = "**"
		else if r(p)<0.10 loc stars = "*"
		else loc stars = ""
	lincom l1_ln_commodity_price_dif + l2_ln_commodity_price_dif + ///
		l3_ln_commodity_price_dif + l4_ln_commodity_price_dif 
	loc est_tmp: di %9.3fc r(estimate)
	loc est_tmp = trim("`est_tmp'")
	loc se_tmp: di %9.3fc r(se)
	loc se_tmp = trim("`se_tmp'")
	estadd local est = "`est_tmp'`stars'"
	estadd local se = "(`se_tmp')"
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* Table 4 columns (3) through (6). Dependent variable: # Employees
*-------------------------------------------------------------------------------

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1 , clear
sort mine_id year_quarter
egen commodity_group = group(msha_commodity_name)
	
*---------- First Differences ----------*
foreach v of varlist ln_avg_empl_cnt_min_office ln_empl_hrs_min_office ///
	ln_avg_empl_cnt_total ln_empl_hrs_total { // ln_std_price_mt
	gen `v'_dif1 = `v'-l1.`v'
	gen `v'_dif = `v'-l4.`v'
}

lab var ln_avg_empl_cnt_min_office_dif "$ \log(\textit{Employment})$"
lab var ln_empl_hrs_min_office_dif "$ \log(\textit{Total Hours})$"

* Total employment, minus office workers	
eststo: reghdfe ln_avg_empl_cnt_total_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
	local dv = "`e(depvar)'"
	local dv = substr("`dv'", 1, length("`dv'")-4)
	sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* 4 lags
* Total employment, minus office workers	
eststo: reghdfe ln_avg_empl_cnt_total_dif l1_ln_std_price_mt_dif ///
	l2_ln_std_price_mt_dif l3_ln_std_price_mt_dif l4_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter)
	test l1_ln_std_price_mt_dif + l2_ln_std_price_mt_dif ///
		+ l3_ln_std_price_mt_dif + l4_ln_std_price_mt_dif = 0
		if r(p)<0.01 loc stars = "***"
		else if r(p)<0.05 loc stars = "**"
		else if r(p)<0.10 loc stars = "*"
		else loc stars = ""
	lincom l1_ln_std_price_mt_dif + l2_ln_std_price_mt_dif ///
		+ l3_ln_std_price_mt_dif + l4_ln_std_price_mt_dif 
	loc est_tmp: di %9.3fc r(estimate)
	loc est_tmp = trim("`est_tmp'")
	loc se_tmp: di %9.3fc r(se)
	loc se_tmp = trim("`se_tmp'")
	estadd local est = "`est_tmp'`stars'"
	estadd local se = "(`se_tmp')"
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace


* Total hours, minus office workers	
eststo: reghdfe ln_empl_hrs_total_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
	local dv = "`e(depvar)'"
	local dv = substr("`dv'", 1, length("`dv'")-4)
	sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
* 4 lags
* Total hours, minus office workers	
eststo: reghdfe ln_empl_hrs_total_dif l1_ln_std_price_mt_dif ///
	l2_ln_std_price_mt_dif l3_ln_std_price_mt_dif l4_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter)
	test l1_ln_std_price_mt_dif + l2_ln_std_price_mt_dif + ///
		l3_ln_std_price_mt_dif + l4_ln_std_price_mt_dif = 0
		if r(p)<0.01 loc stars = "***"
		else if r(p)<0.05 loc stars = "**"
		else if r(p)<0.10 loc stars = "*"
		else loc stars = ""
	lincom l1_ln_std_price_mt_dif + l2_ln_std_price_mt_dif + ///
		l3_ln_std_price_mt_dif + l4_ln_std_price_mt_dif 
	loc est_tmp: di %9.3fc r(estimate)
	loc est_tmp = trim("`est_tmp'")
	loc se_tmp: di %9.3fc r(se)
	loc se_tmp = trim("`se_tmp'")
	estadd local est = "`est_tmp'`stars'"
	estadd local se = "(`se_tmp')"
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* Export table to txt file	
esttab * using "../tables/table4.txt" ///
	, tab se replace fragment substitute(\_ _) ///
	nocon nonotes label b(%9.3f) ///
	order(*ln_std_price_mt_*) depvars star /// 
	stats(est se N r2 spec num_metal mean_dv, ///
		fmt(%9s %9.3fc %9.0fc %9.3fc %9s %9.0fc %9.3fc) ///
		labels("Sum of Lags" "Std. Err." "Observations" "$ R^{2}$" ///
			"Specification" "Commodities" "Mean of Dep Var")) /// 
	addnotes("*** p<0.01, ** p<0.05, * p<0.1") star(* .10 ** 0.05 *** 0.01) 

cap log close
