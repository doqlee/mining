********************************************************************************
* The Time-Series Relationship Between 
* Commodity Prices and U.S. Production of Silver and Gold
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/figureB1_`logdate'.txt", append text
set linesize 225
version 14 // 15

* Conversion factors for units of production
*-------------------------------------------------------------------------------

* NIST Handbook 44 Specifications: Handbook 44 – 2013 
* Appendix C – General Tables of Units of Measurement
global mt_lb = 2204.623 // 1 MT = 2204.623 lbs
global mt_to = 32150.7 // 1 MT = 32150.7 troy ounce
global lb_to = 14.5833 // 1 lb = 14.5833 troy ounce

* Hand-inputted annual production data from USGS Yearbooks 
*-------------------------------------------------------------------------------

* Gold production
import excel using "../data/production/production_usgs_yearbook.xlsx", ///
	sheet("gold_production") first case(lower) clear

drop if trim(vintage)==""
keep vintage*
ren vintage year
drop in 1/2
destring, replace

ds vintage1986 vintage1982 vintage1979 vintage1975
foreach vvvv in `r(varlist)' { // factor conversion from thousand troy ounces to kilograms
	replace `vvvv' = (`vvvv' / $mt_to) * 10^6
}

gen production_usgs_gold = .
order vintage*, alpha // note: we are going to data from the latest vintage if there were any revisions
order year, first
ds year production_usgs_gold, not
foreach vvvv in `r(varlist)' { // combine vintages together
	replace production_usgs_gold = `vvvv' if mi(production_usgs_gold) & !mi(`vvvv')
}

keep year production_usgs_gold
format production_usgs_gold %9.2g
tsset year
compress
tempfile _gold_production
save `_gold_production'

* Gold price
import excel using "../data/production/production_usgs_yearbook.xlsx", ///
	sheet("gold_price") first case(lower) clear

drop if trim(vintage)==""
keep vintage*
ren vintage year
drop in 1/2
destring, replace

gen price_usgs_gold = .
order vintage*, alpha // note: we are going to data from the latest vintage if there were any revisions
order year, first
ds year price_usgs_gold, not
foreach vvvv in `r(varlist)' { // combine vintages together
	replace price_usgs_gold = `vvvv' if mi(price_usgs_gold) & !mi(`vvvv')
}

keep year price_usgs_gold
format price_usgs_gold %9.2g
tsset year
compress
tempfile _gold_price
save `_gold_price'

* Silver production
import excel using "../data/production/production_usgs_yearbook.xlsx", ///
	sheet("silver_production") first case(lower) clear

drop if trim(vintage)==""
keep vintage*
ren vintage year
drop in 1/2
destring, replace

ds vintage1986 vintage1982 vintage1979 vintage1975
foreach vvvv in `r(varlist)' { // factor conversion from thousand troy ounces to kilograms
	replace `vvvv' = (`vvvv' / $mt_to) * 10^3
}

gen production_usgs_silver = .
order vintage*, alpha // note: we are going to data from the latest vintage if there were any revisions
order year, first
ds year production_usgs_silver, not
foreach vvvv in `r(varlist)' { // combine vintages together
	replace production_usgs_silver = `vvvv' if mi(production_usgs_silver) & !mi(`vvvv')
}

keep year production_usgs_silver
format production_usgs_silver %9.2g
tsset year
compress
tempfile _silver_production
save `_silver_production'

* Silver price
import excel using "../data/production/production_usgs_yearbook.xlsx", ///
	sheet("silver_price") first case(lower) clear

drop if trim(vintage)==""
keep vintage*
ren vintage year
drop in 1/2
destring, replace

gen price_usgs_silver = .
order vintage*, alpha // note: we are going to data from the latest vintage if there were any revisions
order year, first
ds year price_usgs_silver, not
foreach vvvv in `r(varlist)' { // combine vintages together
	replace price_usgs_silver = `vvvv' if mi(price_usgs_silver) & !mi(`vvvv')
}

keep year price_usgs_silver
format price_usgs_silver %9.2g
tsset year
compress
tempfile _silver_price
save `_silver_price'

* Combine all sheets
use `_gold_production', clear
merge 1:1 year using `_gold_price', nogen
merge 1:1 year using `_silver_production', nogen
merge 1:1 year using `_silver_price', nogen

tsset year
ds year, not
foreach vv in `r(varlist)' {
	gen D1_`vv' = (`vv' - L1.`vv')
	gen LD1_`vv' = L1.D1_`vv'
	gen logD1_`vv' = (log(`vv') - log(L1.`vv'))
	gen LlogD1_`vv' = L1.logD1_`vv'
}
compress
save "../data/production/production_usgs_yearbook.dta", replace

********************************************************************************
* Restricting to pre 2005 and using price lagged two years
********************************************************************************

use "../data/production/production_usgs_yearbook.dta", clear

keep if year>=1983
keep if year<=2015
tsset year 

*** log changes ***

twoway ///
	(tsline logD1_production_usgs_silver if year<=2005 & year>=1983 ///
		, yaxis(1) lpattern(solid) lcolor(navy)) ///
	(tsline l1.logD1_price_usgs_silver if year<=2005 & year>=1983 ///
		, yaxis(2) lpattern(dash) lcolor(dkgreen)) ///
	, graphregion(color(white)) title("Silver", color(black) size(medium)) ///
		ytitle("log change in production (YoY, metric tons)", axis(1)) ///
		ytitle("log change in price (YoY)", axis(2)) ///
		ylabel(, axis(2)) xlabel(1985(5)2005) xtitle("") ///
		legend(order(1 "log change in production" ///
			2 "log change in price, lag 1 year") row(1) symxsize(*0.4)) 
	graph export "../figures/figureB1a.eps", replace 
	graph close
		
twoway ///
	(tsline logD1_production_usgs_gold if year<=2005 & year>=1983 ///
		, yaxis(1) lpattern(solid) lcolor(navy)) ///
	(tsline l1.logD1_price_usgs_gold if year<=2005 & year>=1983 ///
		, yaxis(2) lpattern(dash) lcolor(maroon)) /// 
	, graphregion(color(white)) title("Gold", color(black) size(medium)) ///
		ytitle("log change in production (YoY, metric tons)", axis(1)) ///
		ytitle("log change in price (YoY)", axis(2)) ///
		ylabel(, axis(2)) xlabel(1985(5)2005) xtitle("") ///
		legend(order(1 "log change in production" ///
			2 "log change in price, lag 1 year") row(1) symxsize(*0.4)) 
	graph export "../figures/figureB1b.eps", replace 
	graph close
	
cap log close
