********************************************************************************
* Commodity Prices and Mining Companies' Exploration Budgets
* Source: S&P Global Marker Intelligence
* Corporate Exploration Strategies (CES) Survey, Oct. 29, 2018. 
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/figureB2_`logdate'.txt", append text
set linesize 225
version 14 // 15

clear
set obs 24
gen year = _n + 1992
replace year = 2000 + _n - 8 + 00 if year > 99

gen budget = .
replace budget = 3.0 if year==1993
replace budget = 3.3 if year==1994
replace budget = 3.8 if year==1995
replace budget = 4.2 if year==1996
replace budget = 5.0 if year==1997
replace budget = 4.0 if year==1998
replace budget = 3.7 if year==1999
replace budget = 3.3 if year==2000
replace budget = 2.8 if year==2001
replace budget = 2.0 if year==2002
replace budget = 3.0 if year==2003
replace budget = 4.0 if year==2004
replace budget = 5.5 if year==2005
replace budget = 8.0 if year==2006
replace budget = 11.8 if year==2007
replace budget = 14.0 if year==2008
replace budget = 8.5 if year==2009
replace budget = 12.0 if year==2010
replace budget = 18.0 if year==2011
replace budget = 21.5 if year==2012
replace budget = 14.5 if year==2013
replace budget = 11.7 if year==2014
replace budget = 9.0 if year==2015
replace budget = 7.0 if year==2016

gen priceIndex = .
replace priceIndex = 1.01 if year==1993
replace priceIndex = 1.05 if year==1994
replace priceIndex = 1.09 if year==1995
replace priceIndex = 1.05 if year==1996
replace priceIndex = 0.98 if year==1997
replace priceIndex = 0.87 if year==1998
replace priceIndex = 0.9 if year==1999
replace priceIndex = 0.95 if year==2000
replace priceIndex = 0.85 if year==2001
replace priceIndex = 0.9 if year==2002
replace priceIndex = 1.0 if year==2003
replace priceIndex = 1.3 if year==2004
replace priceIndex = 1.5 if year==2005
replace priceIndex = 2.5 if year==2006
replace priceIndex = 3.1 if year==2007
replace priceIndex = 3.0 if year==2008
replace priceIndex = 2.8 if year==2009
replace priceIndex = 3.5 if year==2010
replace priceIndex = 4.2 if year==2011
replace priceIndex = 4.18 if year==2012
replace priceIndex = 3.7 if year==2013
replace priceIndex = 3.3 if year==2014
replace priceIndex = 2.95 if year==2015
replace priceIndex = 3.0 if year==2016

tsset year
twoway ///
	(bar budget year, lcolor(black) fcolor(none)) ///
	(line priceIndex year, lcolor(black) lw(medthick) yaxis(2)) ///
	, graphregion(color(white)) xtitle("") xlabel(, labsize(medsmall)) ///
	title("Total Nonferrous Exploration Budgets Fell to an 11-Year Low in 2016" ///
		, size(medium) color(black)) ///
	ytitle("") ylabel(0(4)24, labsize(medsmall)) ///
	ytitle("", axis(2)) ylabel(0(1)5, axis(2) labsize(medsmall)) ///
	legend(order(1 "Exploration Budget in Billions USD (Left Axis)" ///
		2 "Indexed Metals Prices (1993 = 1) (Right Axis)") row(2) size(medsmall))
graph export ../figures/figureB2.eps, replace
graph close

cap log close 
