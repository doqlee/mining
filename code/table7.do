********************************************************************************
* Robustness Tests on Effects of Price Shocks on Worker Safety
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/table7_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1, clear
sort mine_id year_quarter
egen commodity_group = group(msha_commodity_name)

cap ren ln_std_commodity_price_mt ln_std_price_mt

foreach v of varlist total_accidents_min_nn accidents*exper* *incident_*cntctr* {
	qui sum `v' if `v'>0, d
	gen ln_`v' = ln(`r(p1)'+`v')
}

* Inverse hyperbolic sine
gen ihs_total_accidents_min_nn = asinh(total_accidents_min_nn)

foreach v of varlist *total_accidents_min_nn* { 
	gen `v'_dif1 = `v'-l1.`v'
	gen `v'_dif = `v'-l4.`v'
}

eststo clear

* Baseline
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
	
* Cluster by commodity using wild bootstrap ./ado/clustse.ado
* Note: Covariance matrix e(V) is 'fake'. Should not use for inference.
* Report the bootstrap confidence interval instead
eststo: xi: clustse regress ln_total_accidents_min_nn_dif ///
	l1_ln_std_price_mt_dif i.year i.quarter ///
	, cluster(commodity_group) method(wild) reps(5000) seed(3834)
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
*Drop mines that produce >1 commodity 
eststo: reghdfe ln_total_accidents_min_nn_dif l1_ln_std_price_mt_dif ///
	if trim(msha_commodity_name_2nd)=="" ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
* Year-quarter FE, instead of year and quarter FE separately
eststo: reghdfe ln_total_accidents_min_nn_dif l1_ln_std_price_mt_dif ///
	, a(i.year#i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
* Inverse Hyperbolic Sine of injuries as DV
eststo: reghdfe ihs_total_accidents_min_nn_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* Fixed effects rather than first-difference
eststo: reghdfe ln_total_accidents_min_nn l1_ln_std_price_mt ///
	, a(mine_id i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "N", replace

* Fixed effects Poisson for # injuries
eststo: xtpoisson total_accidents_min_nn_tc ///
	l1_ln_std_price_mt i.year i.quarter ///
	, fe vce(robust) 
		local dv = "`e(depvar)'"
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "Poisson", replace
	estadd local fd "N", replace

* Export table to txt file	
esttab * using "../tables/table7.txt" ///
	, tab se replace fragment substitute(\_ _) ///
	nocon nonotes label b(%9.3f) keep(*ln_std_price_mt*) star /// 
	mtitles( ///
		"Baseline" "\shortstack{Cluster\\ commodity}" ///
		"\shortstack{Drop if >1 \\ commodity}" ///
		"\shortstack{Year-quarter \\ FE}" ///
		"\shortstackInverse \\ Hyperbolic Sine}" ///
		"\shortstack{Fixed-\\ Effects OLS}" ///
		"\shortstack{Fixed-\\ Effects Poisson}" ///
		) ///
	stats(N r2 spec num_metal mean_dv, ///
		fmt(%9.0fc %9.3fc %9s %9.0fc %9.3fc) ///
		labels("Observations" "$ R^{2}$" "Specification" ///
			"Commodities" "Mean of Dep Var")) /// 
	addnotes("*** p<0.01, ** p<0.05, * p<0.1") star(* .10 ** 0.05 *** 0.01) 

cap log close
