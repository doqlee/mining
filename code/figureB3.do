********************************************************************************
* Changes in Corporate Siblings Commodity Price on Mine Injury Rates: Multi Lags
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/figureB3_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_siblings_analysis.dta if commodity_group==commodity_group_gen, clear

keep if commodity_group==commodity_group_gen
sort mine_id year_quarter

gen ln_total_accidents_min_nn = ln(1+total_accidents_min_nn)
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

* Check the sibling effect at longer lags 
reghdfe ln_total_accidents_min_nn_dif ///
	l*_ln_std_price_mt_dif l*_avg_price_ctrl_oth_dif ///
	if l1_avg_price_ctrl_oth_dif!=. & sum_mine_ctrl_not > 0 ///
	, a(year quarter) vce(cluster firm_id) 

set scheme s2color
coefplot ///
	, keep(*_avg_price_ctrl_oth_dif) vertical level(95) yline(0) /// baselevels 
	title("Dependent variable = log injury rate", size(medium) color(black)) ///
	xtitle("Siblings' average price in quarter relative to this quarter") ///
	ytitle("Coefficient and confidence interval on siblings' price") ///
	coeflabels( ///
		l1_avg_price_ctrl_oth_dif = "t-1" ///
		l2_avg_price_ctrl_oth_dif = "t-2" ///
		l3_avg_price_ctrl_oth_dif = "t-3" ///
		l4_avg_price_ctrl_oth_dif = "t-4" ///
		) graphregion(fcolor(white)) 
graph export ../figures/figureB3.eps, replace // lags_sibling_price_on_inj_rate.pdf
graph close
