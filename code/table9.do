********************************************************************************
* Heterogeneous Effects of Price Shocks by Mine Type
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/table9_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1, clear
	sort mine_id year_quarter
	egen commodity_group = group(msha_commodity_name)

foreach v of varlist ln_avg_empl_cnt_min_office ln_empl_hrs_min_office ///
	ln_avg_empl_cnt_total ln_empl_hrs_total { // ln_std_price_mt
	gen `v'_dif1 = `v'-l1.`v'
	gen `v'_dif = `v'-l4.`v'
}

lab var ln_avg_empl_cnt_min_office_dif "$ \log(\textit{Employment})$"
lab var ln_empl_hrs_min_office_dif "$ \log(\textit{Total Hours})$"

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

cap ren high_negligence_viol high_neg_viol
cap ren high_negligence_viol_tc high_neg_viol_tc

* # of violations that are either training or haz comm
	gen part4748_viol = part46_viol + part47_viol + part48_viol
	gen part474849_viol = part46_viol + part47_viol + part48_viol + part49_viol
	
* # violations per FTE
	gen total_viol_fte = total_viol / (avg_empl_cnt_total + 1)		
	
* # violations averaged 3, 4 and 5 quarters ago and take this difference
foreach v of varlist total_viol part57_viol high_neg_viol sig_sub_viol ///
	part4748_viol total_viol_fte part474849_viol {
	qui sum `v' if `v'>0, d
	gen ln_`v' = ln(`r(p1)'+`v')
}
foreach v of varlist ln_total_viol* ln_part57_viol ln_high_neg_viol ///
	ln_sig_sub_viol total_viol_tc part57_viol_tc high_neg_viol_tc ///
	sig_sub_viol part4748_viol ln_part4748_viol {
	
	* Average of 3-4-5 lags
	forvalues i = 3/5 {
		gen l`i'_`v' = l`i'.`v'
	}
	egen avg_`v'_345 = rowmean(l3_`v' l4_`v' l5_`v')
	
	* Average of 1 lag, today, 1 lead
	gen l1_`v' = l1.`v'
	gen f1_`v' = f1.`v'
	egen avg_`v'_101 = rowmean(l1_`v' `v' f1_`v')
		
	* Difference
	gen `v'_dif_101_345 = avg_`v'_101 - avg_`v'_345 
}

eststo clear

* Employment
eststo: reghdfe ln_avg_empl_cnt_total_dif ///
	l1_ln_std_price_mt_dif c.l1_ln_std_price_mt_dif#1.underground ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
* Hours
eststo: reghdfe ln_empl_hrs_total_dif ///
	l1_ln_std_price_mt_dif c.l1_ln_std_price_mt_dif#1.underground ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
* Accidents
eststo: reghdfe ln_total_accidents_min_nn_dif ///
	l1_ln_std_price_mt_dif c.l1_ln_std_price_mt_dif#1.underground ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
* Violations
eststo: reghdfe ln_total_viol_dif_101_345 ///
	l1_ln_std_price_mt_dif c.l1_ln_std_price_mt_dif#1.underground ///
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
esttab * using "../tables/table9.txt" ///
	, tab se replace fragment substitute(\_ _) ///
	nocon nonotes label b(%9.3f) order(*ln_std_price_mt_*) star /// 
	stats(est se N r2 spec num_metal mean_dv, ///
		fmt(%9s %9.3fc %9.0fc %9.3fc %9s %9.0fc %9.3fc) ///
		labels("Sum of Lags" "Std. Err." "Observations" "$ R^{2}$" ///
			"Specification" "Commodities" "Mean of Dep Var")) /// 
	addnotes("*** p<0.01, ** p<0.05, * p<0.1") star(* .10 ** 0.05 *** 0.01) 

cap log close
