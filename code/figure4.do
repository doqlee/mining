********************************************************************************
* Effects of Leading and Lagged Commodity Prices on Injury Rates
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/figure4_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1, clear
sort mine_id year_quarter
egen commodity_group = group(msha_commodity_name)

local pc ln_std_price_mt 
reghdfe ln_inj_rate_min_nn_hrs ///
	l9.`pc' l5.`pc' l1.`pc' f1.`pc' f5.`pc' f9.`pc' ///
	, a(mine_id year quarter) vce(cluster mine_id) 

coefplot, keep(*`pc'*)  vertical level(95) yline(0) /// baselevels 
	xlabel(1 "t-9" 2 "t-5" 3 "t-1" 4 "t+1" 5 "t+5" 6 "t+9") ///
	title("Lead and lag price" "Dependent variable = log injury rate" ///
		, size(medium) color(black)) graphregion(fcolor(white)) ///
	xtitle("Price in quarter relative to this quarter") ///
	ytitle("Coefficient and confidence interval on price") 
graph export ../figures/figure4.eps, replace // lead_and_lag_price_on_inj_rate.pdf
graph close

cap log close
