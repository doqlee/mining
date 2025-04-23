********************************************************************************
* Summary Statistics on All Other Dependent Variables
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/tableB1_`logdate'.txt", append text
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

* Baseline sample
reghdfe ln_total_accidents_min_nn_dif l1_ln_std_price_mt_dif ///
	, a(i.year i.quarter) vce(cluster mine_id commodity_group#year_quarter) 
keep if e(sample)
	
ds accidents_mine_exper1 accidents_mine_exper2 accidents_mine_exper3 ///
	incident_cntctr_tc incident_excntctr_tc ///
	exertion_injury struck_injury machinery_injury fall_injury
local summ_vars `r(varlist)'

* Basic summary stats table
foreach stat in sum mean p50 p25 p75 count sd iqr var min max {
	loc `stat'
	loc `stat'_var
	foreach y in `summ_vars' {
		loc `stat' ``stat'' `stat'_`y'=`y'
	}
	di `"``stat''"'
}
keep `summ_vars'
collapse ///
	(count) `count' (mean) `mean' (sd) `sd' /// 
	(p50) `p50' (min) `min' (max) `max' 
compress
gen byte constant = 1
reshape long count_ mean_ sd_ p50_ min_ max_, i(constant) j(variables) string
	drop constant
	ren *_ *
	compress
gen byte nrow = .
loc ii = 0
foreach vv in `summ_vars' {
	replace nrow = `ii++' if variables=="`vv'"
}
sort nrow
drop nrow
outsheet _all using "../tables/tableB1.csv", comma replace

cap log close
