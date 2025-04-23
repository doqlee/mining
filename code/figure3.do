********************************************************************************
* The Time-Series Relationship Between Commodity Prices and the 
* Number of Workplace Injuries in Mines that Produce Them
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/figure3_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1, clear

sort mine_id year_quarter
egen commodity_group = group(msha_commodity_name)

* A few cases that are outliers
keep if avg_empl_cnt_total>=total_accidents

reg std_price i.year i.quarter
predict price_resid, resid

reg total_accidents_tc i.year i.quarter
predict accident_resid, resid

reg inj_rate_min_nn_hrs_tc i.year i.quarter
predict accident_rate_resid, resid

gen ihs_inj_rate_min_nn_hrs = log(inj_rate_min_nn_hrs + sqrt(inj_rate_min_nn_hrs^2+1))

reg ihs_inj_rate_min_nn_hrs   i.year i.quarter
predict ihs_accident_resid, resid

collapse (mean) price_resid accident_resid std_price_mt ///
	total_accidents_tc ihs_inj_rate_min_nn_hrs ihs_accident_resid ///
	inj_rate_min_nn_hrs_tc accident_rate_resid ///
	, by(msha_commodity_name year_quarter)

egen commodity_group = group(msha_commodity_name)
xtset commodity_group  year_quarter

* Uranium
twoway (line accident_resid year_quarter ///
		if year_quarter<=tq(2005q1) & trim(msha)=="Uranium Ore" ///
		, yaxis(1) ytitle("# Accidents, de-trended", axis(1) size(large)) lp(solid) lc(black)) ///
	(line price_resid  year_quarter ///
		if year_quarter<=tq(2005q1) & trim(msha)=="Uranium Ore" ///
		, yaxis(2) ytitle("Price, de-trended", axis(2) size(large)) lp(dash) lc(black)) ///
	, title("Uranium", size(large) color(black)) graphregion(fcolor(white)) xtitle("") ///
	legend(label(1 "# Accidents") label(2 "Price") size(large)) ///
	ylabel(, axis(1) labsize(large)) ylabel(, axis(2) labsize(large)) xlabel(, labsize(large))
graph export ../figures/figure3a.eps, replace // price_accident_uranium.pdf
graph close

* Copper
twoway (line accident_resid year_quarter ///
		if year_quarter<=tq(2005q1) & regexm(msha_commodity_name, "Copper") ///
		, yaxis(1) ytitle("# Accidents, de-trended", axis(1) size(large)) lp(solid) lc(black)) ///
	(line price_resid  year_quarter ///
		if year_quarter<=tq(2005q1) & regexm(msha_commodity_name, "Copper") ///
		, yaxis(2) ytitle("Price, de-trended", axis(2) size(large)) lp(dash) lc(black)) ///
	, title("Copper", size(large) color(black)) graphregion(fcolor(white)) xtitle("") ///
	legend(label(1 "# Accidents") label(2 "Price") size(large)) ///
	ylabel(, axis(1) labsize(large)) ylabel(, axis(2) labsize(large)) xlabel(, labsize(large))
graph export ../figures/figure3b.eps, replace // price_accident_copper.pdf
graph close

* Gold
twoway (line accident_resid year_quarter ///
		if year_quarter<=tq(2005q1) & regexm(msha_commodity_name, "Gold") ///
		, yaxis(1) ytitle("# Accidents, de-trended", axis(1) size(large)) lp(solid) lc(black)) ///
	(line price_resid  year_quarter ///
		if year_quarter<=tq(2005q1) & regexm(msha_commodity_name, "Gold") ///
		, yaxis(2) ytitle("Price, de-trended", axis(2) size(large)) lp(dash) lc(black)) ///
	, title("Gold", size(large) color(black)) graphregion(fcolor(white)) xtitle("") ///
	legend(label(1 "# Accidents") label(2 "Price") size(large)) ///
	ylabel(, axis(1) labsize(large)) ylabel(, axis(2) labsize(large)) xlabel(, labsize(large))
graph export ../figures/figure3c.eps, replace // price_accident_gold.pdf
graph close

* Silver
twoway (line accident_resid year_quarter ///
		if year_quarter<=tq(2005q1) & regexm(msha_commodity_name, "Silver") ///
		, yaxis(1) ytitle("# Accidents, de-trended", axis(1) size(large)) lp(solid) lc(black)) ///
	(line price_resid  year_quarter ///
		if year_quarter<=tq(2005q1) & regexm(msha_commodity_name, "Silver") ///
		, yaxis(2) ytitle("Price, de-trended", axis(2) size(large)) lp(dash) lc(black)) ///
	, title("Silver", size(large) color(black)) graphregion(fcolor(white)) xtitle("") ///
	legend(label(1 "# Accidents") label(2 "Price") size(large)) ///
	ylabel(, axis(1) labsize(large)) ylabel(, axis(2) labsize(large)) xlabel(, labsize(large))
graph export ../figures/figure3d.eps, replace // price_accident_silver.pdf
graph close

cap log close
