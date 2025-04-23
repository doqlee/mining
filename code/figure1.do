********************************************************************************
* Standardized Commodity Prices 1983-2015
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/figure1_`logdate'.txt", append text
set linesize 225
version 14 // 15

use "../data/price/std_price.dta", clear

cap drop MSHA_COMMODITY_NAME
encode msha_commodity_name, gen(MSHA_COMMODITY_NAME)

cap drop year_quarter
gen year_quarter = yq(year, quarter), before(year)
	format year_quarter %tq
keep if year>=1983
keep if year<=2015
xtset MSHA_COMMODITY_NAME year_quarter

merge m:1 msha_commodity_name using "../tables/table3.dta", nogen keep(1 3)
destring w2014, replace
sort w2014

* Plot standardized commodity prices: precious metals
twoway ///
	(line std_price year_quarter if regexm(msha, "Gold") ///
		, sort lw(medthick) lp(solid) lc(gs8)) ///
	(line std_price year_quarter if regexm(msha, "Silver") ///
		, sort lw(medthick) lp(longdash) lc(gs4)) ///
	(line std_price year_quarter if regexm(msha, "Platinum") ///
		, sort lw(medthick) lp(shortdash) lc(gs0)) ///
	, legend( ///
		label(1 "Gold") label(2 "Silver") label(3 "Platinum") ///
		col(3) size(large)) title("") graphregion(fcolor(white)) ///
		xtitle("") ytitle("Standardized commodity price", size(large)) ///
		xlabel(, labsize(large)) ylabel(, labsize(large)) ///
		title("Precious Metals", size(large) color(black))
graph export ../figures/figure1a.eps, replace 
	cap graph close

* Plot standardized commodity prices: industrial metals part 1
twoway ///
	(line std_price year_quarter if regexm(msha, "Iron") ///
		, sort lw(medthick) lp(solid) lc(gs8)) ///
	(line std_price year_quarter if regexm(msha, "Aluminum") ///
		, sort lw(medthick) lp(longdash) lc(gs4)) ///
	(line std_price year_quarter if regexm(msha, "Copper") ///
		, sort lw(medthick) lp(shortdash) lc(gs0)) ///
	, legend( ///
		label(1 "Iron") label(2 "Aluminum") label(3 "Copper") ///
		col(3) size(large)) title("") graphregion(fcolor(white)) ///
		xtitle("") ytitle("Standardized commodity price", size(large)) ///
		xlabel(, labsize(large)) ylabel(, labsize(large)) ///
		title("Industrial Metals 1", size(large) color(black))
graph export ../figures/figure1b.eps, replace 
	cap graph close

* Plot standardized commodity prices: industrial metals part 2
twoway ///
	(line std_price year_quarter if msha=="Zinc" ///
		, sort lw(medthick) lp(solid) lc(gs8)) ///
	(line std_price year_quarter if regexm(msha, "Lead-Zinc") ///
		, sort lw(medthick) lp(longdash) lc(gs4)) ///
	(line std_price year_quarter if regexm(msha, "Nickel") ///
		, sort lw(medthick) lp(shortdash) lc(gs0)) ///
	, legend( ///
		label(1 "Zinc") label(2 "Lead-Zinc") label(3 "Nickel") ///
		col(3) size(large)) title("") graphregion(fcolor(white)) ///
		xtitle("") ytitle("Standardized commodity price", size(large)) ///
		xlabel(, labsize(large)) ylabel(, labsize(large)) ///
		title("Industrial Metals 2", size(large) color(black))
graph export ../figures/figure1c.eps, replace 
	cap graph close

* Plot standardized commodity prices: industrial metals part 3
twoway ///
	(line std_price year_quarter if regexm(msha, "Tin") ///
		, sort lw(medthick) lp(solid) lc(gs8)) ///
	(line std_price year_quarter if regexm(msha, "Molybdenum") ///
		, sort lw(medthick) lp(longdash) lc(gs4)) ///
	(line std_price year_quarter if regexm(msha, "Antimony") ///
		, sort lw(medthick) lp(shortdash) lc(gs0)) ///
	, legend( ///
		label(1 "Tin") label(2 "Molybdenum") label(3 "Antimony") ///
		col(3) size(large)) title("") graphregion(fcolor(white)) ///
		xtitle("") ytitle("Standardized commodity price", size(large)) ///
		xlabel(, labsize(large)) ylabel(, labsize(large)) ///
		title("Industrial Metals 3", size(large) color(black))
graph export ../figures/figure1d.eps, replace 
	cap graph close

* Plot standardized commodity prices: industrial metals part 3
twoway ///
	(line std_price year_quarter if regexm(msha, "Alumina") ///
		, sort lw(medthick) lp(solid) lc(gs8)) ///
	(line std_price year_quarter if regexm(msha, "Cobalt") ///
		, sort lw(medthick) lp(longdash) lc(gs4)) ///
	(line std_price year_quarter if regexm(msha, "Uranium Ore") ///
		, sort lw(medthick) lp(shortdash) lc(gs0)) ///
	, legend( ///
		label(1 "Alumina") label(2 "Cobalt") label(3 "Uranium") ///
		col(3) size(large)) title("") graphregion(fcolor(white)) ///
		xtitle("") ytitle("Standardized commodity price", size(large)) ///
		xlabel(, labsize(large)) ylabel(, labsize(large)) ///
		title("Industrial Metals 4", size(large) color(black))
graph export ../figures/figure1e.eps, replace 
	cap graph close

/** Plot standardized commodity prices
twoway ///
(line std_price year_quarter if regexm(msha, "Alumina"), sort) ///
(line std_price year_quarter if regexm(msha, "Aluminum"), sort) ///
(line std_price year_quarter if regexm(msha, "Antimony"), sort) ///
(line std_price year_quarter if regexm(msha, "Cobalt"), sort) ///
(line std_price year_quarter if regexm(msha, "Copper"), sort) ///
(line std_price year_quarter if regexm(msha, "Gold"), sort) ///
(line std_price year_quarter if regexm(msha, "Iron"), sort) ///
(line std_price year_quarter if regexm(msha, "Lead-Zinc"), sort) ///
(line std_price year_quarter if regexm(msha, "Molybdenum"), sort) ///
(line std_price year_quarter if regexm(msha, "Nickel"), sort) ///
(line std_price year_quarter if regexm(msha, "Platinum"), sort) ///
(line std_price year_quarter if regexm(msha, "Silver"), sort) ///
(line std_price year_quarter if regexm(msha, "Tin"), sort) ///
(line std_price year_quarter if trim(msha)=="Uranium Ore", sort) ///
(line std_price year_quarter if trim(msha)=="Zinc", sort) ///
(line std_price year_quarter if trim(msha)=="Uranium-Vanadium Ore", sort)  ///
, legend( ///
	label(1 "Alumina") label(2 "Aluminum") label(3 "Antimony") ///
	label(4 "Cobalt") label(5 "Copper") label(6 "Gold") label(7 "Iron") ///
	label(8 "Lead-Zinc")  label(9 "Molybdenum")  label(10 "Nickel") ///
	label(11 "Platinum") label(12 "Silver") label(13 "Tin") ///
	label(14 "Uranium") label(15 "Zinc")  label(16 "Uranium-Vanadium") ///
	col(3)) title("") graphregion(fcolor(white)) ///
	xtitle("") ytitle("Standardized commodity price")
graph export ../figures/figure1.eps, replace 
	cap graph close */

cap log close
