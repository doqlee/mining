********************************************************************************
* Price Shocks and Compliance with Safety Regulations
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/table8_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1, clear
sort mine_id year_quarter
egen commodity_group = group(msha_commodity_name)

cap ren ln_std_commodity_price_mt ln_std_price_mt
foreach v of varlist insp_type_regular { 
	gen `v'_dif1 = `v'-l1.`v'
	gen `v'_dif = `v'-l4.`v'
}
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

* Total violations
eststo: reghdfe ln_total_viol_dif_101_345 l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year#quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace
	
* High negligence violations
eststo: reghdfe ln_high_neg_viol_dif_101_345 l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year#quarter) 
		local dv = "`e(depvar)'"
		local dv = substr("`dv'", 1, length("`dv'")-4)
		sum `dv' if e(sample)
	estadd scalar mean_dv = `r(mean)'
	unique commodity_group if e(sample)
	estadd local num_metal = `r(unique)' //`r(sum)'
	estadd local spec "OLS", replace
	estadd local fd "Y", replace

esttab * using "../tables/table8.txt" ///
	, tab se replace fragment substitute(\_ _) ///
	nocon nonotes label b(%9.3f) star /// 
	stats(N r2 spec num_metal mean_dv, ///
		fmt(%9.0fc %9.3fc %9s %9.0fc %9.3fc) ///
		labels("Observations" "$ R^{2}$" "Specification" ///
			"Commodities" "Mean of Dep Var")) /// 
	addnotes("*** p<0.01, ** p<0.05, * p<0.1") star(* .10 ** 0.05 *** 0.01) 

cap log close
