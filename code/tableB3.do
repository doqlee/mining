********************************************************************************
* Heterogeneity in Own- and Sibling-Price Effects on Worker Safety, by Firm Size
* Use mines with corporate siblings that produce a different commodity
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/tableB3_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_siblings_analysis.dta if commodity_group==commodity_group_gen, clear

keep if commodity_group==commodity_group_gen
sort mine_id year_quarter

gen ln_total_accidents_min_nn = ln(1 + total_accidents_min_nn)
foreach v of varlist ln_total_accidents_min_nn ln_inj_rate_min_nn_hrs ///
	avg_price_ctrl_oth* price_rand_not_ctrl {
	gen `v'_dif = `v'-l4.`v'
}
lab var ln_inj_rate_min_nn_hrs_dif "$ \log(\textit{Injury Rate})$"
lab var ln_std_price_mt "Log(price)"
lab var avg_price_ctrl_oth "Average log(price), corporate siblings"
lab var avg_price_ctrl_oth2 "Average log(price), corporate siblings in other counties"
lab var price_rand_not_ctrl "log(price) of random commodity not produced by firm"

foreach pc in avg_price_ctrl_oth avg_price_ctrl_oth2 price_rand_not_ctrl {
	local l: variable label `pc'
	forvalues i = 1/4 {
		gen l`i'_`pc'_dif = l`i'.`pc'_dif
		lab var l`i'_`pc'_dif "$ \Delta \textit{`l'}_{jt-`i'}$"
	}
}
egen firm_id = group(curr_ctrlr_id)

* Own and sibling price: whether or not have LOTS of siblings 
cap drop few_siblings 
cap drop lots_siblings
gen few_siblings = num_mine_ctrl>1 & num_mine_ctrl<6
gen lots_siblings = num_mine_ctrl>=6
lab var lots_siblings "Has at least 6 corporate siblings"

eststo clear

* Baseline
reghdfe ln_total_accidents_min_nn_dif ///
	l1_ln_std_price_mt_dif l1_avg_price_ctrl_oth_dif ///
		if l1_avg_price_ctrl_oth_dif!=. & sum_mine_ctrl_not>0 ///
		, a(year quarter) vce(cluster firm_id) 
		est sto r1
			local dv = "`e(depvar)'"
			local dv = substr("`dv'", 1, length("`dv'")-4)
			sum `dv' if e(sample)
		estadd scalar mean_dv = `r(mean)'
		unique commodity_group if e(sample)
		estadd local num_metal = `r(unique)' //`r(sum)'
		unique mine_id if e(sample)
		estadd local num_mine = `r(unique)' //`r(sum)'
		unique firm_id if e(sample)
		estadd local num_firm = `r(unique)' //`r(sum)'
		estadd local spec "OLS", replace
		estadd local fd "Y", replace

* Heterogeneity by size 
reghdfe ln_total_accidents_min_nn_dif ///
	l1_ln_std_price_mt_dif c.l1_ln_std_price_mt_dif#i1.lots_siblings ///
	l1_avg_price_ctrl_oth_dif c.l1_avg_price_ctrl_oth_dif#i1.lots_siblings  ///
		if l1_avg_price_ctrl_oth_dif!=. & sum_mine_ctrl_not>0 ///
		, a(year quarter) vce(cluster firm_id) 
		est sto r2
			local dv = "`e(depvar)'"
			local dv = substr("`dv'", 1, length("`dv'")-4)
			sum `dv' if e(sample)
		estadd scalar mean_dv = `r(mean)'
		unique commodity_group if e(sample)
		estadd local num_metal = `r(unique)' //`r(sum)'
		unique mine_id if e(sample)
		estadd local num_mine = `r(unique)' //`r(sum)'
		unique firm_id if e(sample)
		estadd local num_firm = `r(unique)' //`r(sum)'
		estadd local spec "OLS", replace
		estadd local fd "Y", replace

esttab * using "../tables/tableB3.txt" ///
	, tab se replace fragment substitute(\_ _) depvars star /// 
	nocon nonotes label b(%9.3f) keep(*ln_std_price_mt* *price* *siblings*) /// 
	stats(est se N r2 num_metal num_mine num_firm mean_dv, ///
		fmt(%9s %9.3fc %9.0fc %9.3fc %9s %9.0fc %9.3fc) /// 
		labels("Std. Err." "Observations" "$ R^{2}$" ///
			 "Commodities" "Mines" "Firms" "Mean of Dep Var")) /// 
	addnotes("*** p<0.01, ** p<0.05, * p<0.1") star(* .10 ** 0.05 *** 0.01) 

cap log close
