********************************************************************************
* Do Changes in Worker Composition Explain the Effect on Injuries?
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/table6_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1, clear
sort mine_id year_quarter
egen commodity_group = group(msha_commodity_name)

cap ren ln_std_commodity_price_mt ln_std_price_mt

foreach v of varlist total_accidents_min_nn accidents*exper* ///
	exertion_injury *machinery* *struck* *fall* *incident_*cntctr* {
	qui sum `v' if `v'>0, d
	gen ln_`v' = ln(`r(p1)'+`v')
}

foreach v of varlist *total_accidents_min_nn* *accidents*exper* *machinery* *exertion* *fall* *struck* *incident_*cntctr* { 
	gen `v'_dif1 = `v'-l1.`v'
	gen `v'_dif = `v'-l4.`v'
}
lab var ln_total_accidents_min_nn_dif "$ \shortstack{Injuries \\ Total}$"
lab var ln_accidents_mine_exper2_dif "$ \shortstack{Injuries \\ Experience \\ $<$ .5 year}$"
lab var ln_accidents_mine_exper1_dif "$ \shortstack{Injuries \\ Experience \\ $\geq$ .5 year}$"
lab var ln_accidents_mine_exper3_dif "$ \shortstack{Injuries \\ Experience \\ Missing}$"
lab var ln_exertion_injury_dif "$ \shortstack{Injuries \\ Over \\ Exertion}$"
lab var ln_machinery_injury_dif "$ \shortstack{Injuries \\ Due To \\ Machinery}$"
lab var ln_struck_injury_dif "$ \shortstack{Injuries \\ Struck\\ By}$"
lab var ln_fall_injury_dif "$ \shortstack{Injuries \\ Due to \\ Fall}$"

eststo clear

* Overall
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

* 3 categories of tenure at MINE
* exper2 = <=0.5 years experience w/ current mine
eststo: reghdfe ln_accidents_mine_exper2_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
*exper1 = >0.5 years experience w/ current mine
eststo: reghdfe ln_accidents_mine_exper1_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

*exper3 = missing experience
eststo: reghdfe ln_accidents_mine_exper3_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* 3 categories of EXPERIENCE in mining INDUSTRY
*tot_exper2 = <=3 years experience w/ current mine
eststo: reghdfe ln_accidents_tot_exper2_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
*tot_exper1 = >3 years experience w/ current mine
eststo: reghdfe ln_accidents_tot_exper1_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
*tot_exper3 = missing INDUSTRY experience
eststo: reghdfe ln_accidents_tot_exper3_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* Involves Contractor
eststo: reghdfe ln_incident_cntctr_tc_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

* Does not involve contractor
eststo: reghdfe ln_incident_excntctr_tc_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

esttab * using "../tables/table6.txt" ///
	, tab se replace fragment substitute(\_ _) ///
	nocon nonotes label b(%9.3f) order(*ln_std_price_mt_*) star /// 
	mtitles( ///
		"Total" ///
		"\shortstack{Workers\\ $<6$ months \\ at mine}" ///
		"\shortstack{Workers\\ $\ge{6}$ months \\ at mine}" ///
		"\shortstack{Mine \\ Tenure\\ missing}" ///
		"\shortstack{Workers\\ $<3$ years in \\ industry}" ///
		"\shortstack{Workers\\ $\ge{3}$ years in \\ industry}" ///
		"\shortstack{Industry \\ Experience \\ missing}" ///
		"\shortstack{Involves\\Contractor}" ///
		"\shortstack{Does not\\Involve\\Contractor}" ///
		) ///
	stats(N r2 spec num_metal mean_dv, ///
		fmt(%9.0fc %9.3fc %9s %9.0fc %9.3fc) ///
		labels("Observations" "$ R^{2}$" "Specification" ///
			"Commodities" "Mean of Dep Var")) /// 
	addnotes("*** p<0.01, ** p<0.05, * p<0.1") star(* .10 ** 0.05 *** 0.01) 

cap log close
