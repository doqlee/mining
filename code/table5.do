********************************************************************************
* Price Shocks and Worker Safety
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/table5_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1, clear
	sort mine_id year_quarter
	egen commodity_group = group(msha_commodity_name)

foreach v of varlist total_accidents_min_nn traumatic_injury serious_injury {
	qui sum `v' if `v'>0, d
	gen ln_`v' = ln(`r(p1)'+`v')
}

foreach v of varlist *total_accidents_min_nn* ///
	ln_inj_rate_min_nn_hrs *traumatic_injury* *serious_injury* { 
	gen `v'_dif1 = `v'-l1.`v'
	gen `v'_dif = `v'-l4.`v'
}
lab var traumatic_injury_tc_dif "$ \shortstack{Injuries \\ Traumatic}$"
lab var serious_injury_tc_dif "$ \shortstack{Injuries \\ Most Serious}$"
eststo clear

* Total accidents
eststo: reghdfe ln_total_accidents_min_nn_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* Log injury rate
eststo: reghdfe ln_inj_rate_min_nn_hrs_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* Traumatic Injuries
eststo: reghdfe ln_traumatic_injury_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* Serious injuries
eststo: reghdfe ln_serious_injury_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
* Export table to txt file	
esttab * using "../tables/table5.txt" ///
	, tab se replace fragment substitute(\_ _) ///
	nocon nonotes label b(%9.3f) order(*ln_std_price_mt_*) star /// 
	mtitles("Injury Count" "Injury Rate" "Traumatic Injuries" "Serious Injuries") ///
	stats(est se N r2 spec num_metal mean_dv, ///
		fmt(%9s %9.3fc %9.0fc %9.3fc %9s %9.0fc %9.3fc) ///
		labels("Sum of Lags" "Std. Err." "Observations" "$ R^{2}$" ///
			"Specification" "Commodities" "Mean of Dep Var")) /// 
	addnotes("*** p<0.01, ** p<0.05, * p<0.1") star(* .10 ** 0.05 *** 0.01) 

cap log close
