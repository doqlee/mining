********************************************************************************
* Commodity Price Data
********************************************************************************

cap log close
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/price_`logdate'.txt", append text
set linesize 225
version 14 // 15

* Define Globals
*-------------------------------------------------------------------------------

* Number of lags and leads
global numL = 13

* Conversion factors for units of measurement 
* NIST Handbook 44 Specifications: Handbook 44 – 2013 
* Appendix C – General Tables of Units of Measurement
global mt_lb = 2204.623 // 1 MT = 2204.623 lbs
global mt_to = 32150.7 // 1 MT = 32150.7 troy ounce
global lb_to = 14.5833 // 1 lb = 14.5833 troy ounce

* IMF commodity price system data
*-------------------------------------------------------------------------------

insheet using "../data/price/imf_commodity_price_system.csv", comma clear nonames

ren v2 commodity
ren v4 datatype
drop if datatype=="Index"
d
forval i = 8(1)`r(k)' {
	loc vn = v`i'[1]
	ren v`i' price_imf`vn'
}
drop in 1

gen msha_commodity_name = ""
replace msha_commodity_name = "Aluminum Ore-Bauxite" if commodity=="PALUMUSD.Q"
replace msha_commodity_name = "Copper Ore NEC" if commodity=="PCOPPUSD.Q"
replace msha_commodity_name = "Gold Ore" if commodity=="PGOLDUSD.Q"
replace msha_commodity_name = "Lead-Zinc Ore" if commodity=="PLEADUSD.Q"
replace msha_commodity_name = "Nickel Ore" if commodity=="PNICKUSD.Q"
replace msha_commodity_name = "Tin Ore" if commodity=="PTINUSD.Q"
replace msha_commodity_name = "Uranium Ore" if commodity=="PURANUSD.Q"
replace msha_commodity_name = "Zinc" if commodity=="PZINCUSD.Q"

gen units_imf = "USD per metric ton"
replace units_imf = "USD per troy ounce" if commodity=="PGOLDUSD.Q"
replace units_imf = "USD per pound" if commodity=="PURANUSD.Q"
	tab units_imf, m
	
keep commodity msha_commodity_name units_imf price_imf*
reshape long price_imf, i(msha_commodity_name) j(date) string
	destring price_imf, replace
	gen year = substr(date, 1, 4)
	gen quarter = substr(date, 6, 1)
	destring year, replace
	destring quarter, replace
	drop date
	
keep if year>=1983 & year<=2016
keep if msha_commodity_name=="Gold Ore" 
tempfile imf_tmp
save `imf_tmp' // to be appended to COMMP_10...

* IMF Primary Commodity Prices Data
*-------------------------------------------------------------------------------

insheet using "../data/price/COMMP_10-06-2017 05-38-22-13_panel/COMMP_10-06-2017 05-38-22-13_panel.csv", comma clear

split timeperiod, p(M) gen(date)
destring date*, replace
	ren date1 year
	ren date2 month
keep year month *_usd
	ren *_usd price_imf*_usd
	
reshape long price_imf, i(year month) j(commodity) string

gen quarter = mod(month, 3)
replace quarter = 0 if quarter==2
bys commodity (year month): replace quarter = sum(quarter)
replace quarter = mod(quarter, 4)
replace quarter = 4 if quarter==0

collapse (mean) price_imf, by(commodity year quarter)

gen msha_commodity_name = ""
replace msha_commodity_name = "Aluminum Ore-Bauxite" if commodity=="aluminumpalum_usd"
replace msha_commodity_name = "Copper Ore NEC" if commodity=="copperpcopp_usd"
replace msha_commodity_name = "Iron Ore" if commodity=="ironorepiorecr_usd"
replace msha_commodity_name = "Lead-Zinc Ore" if commodity=="leadplead_usd"
replace msha_commodity_name = "Nickel Ore" if commodity=="nickelpnick_usd"
replace msha_commodity_name = "Tin Ore" if commodity=="tinptin_usd"
replace msha_commodity_name = "Uranium Ore" if commodity=="uraniumpuran_usd"
replace msha_commodity_name = "Zinc" if commodity=="zincpzinc_usd"

gen units_imf = "USD per metric ton"
replace units_imf = "USD per pound" if commodity=="uraniumpuran_usd"
lab var price_imf "Commodity last price this quarter [IMF]"

append using `imf_tmp'

* Create a standardized price (mean 0 SD 1)
keep if year>=1983 & year<=2016
egen mean_price = mean(price), by(msha_commodity_name)
egen sd_price = sd(price), by(msha_commodity_name)
gen std_price_imf = (price_imf-mean_price)/sd_price
drop mean_price sd_price

* Create log(Price in U$/MT)
tab msha_commodity_name units_imf, m
gen price_mt_imf = price_imf
replace price_mt_imf = price_imf * $mt_lb if units_imf=="USD per pound"
replace price_mt_imf = price_imf * $mt_to if units_imf=="USD per troy ounce"
gen ln_price_mt_imf = ln(price_mt_imf)
lab var price_mt_imf "Commodity price in U$/MT [IMF]"
lab var ln_price_mt_imf "Log(commodity price in U$/MT) [IMF]"

compress
save "../data/price/imf.dta", replace

keep if year==2006 & quarter==1
keep msha_commodity_name price_mt_imf
ren price_mt_imf price_mt_imf_base

tempfile imf_base
save `imf_base'

* Datastream
*-------------------------------------------------------------------------------

insheet using "../data/price/datastream.csv", comma clear

destring price, ignore(",") replace
	tab series units
keep msha_name year quarter units price
	rename msha_name msha_commodity_name
	rename price price_datastream
	rename units units_datastream
lab var price_datastream "Commodity last price this quarter [Datastream]"

* Create a standardized price (mean 0 SD 1)
egen mean_price = mean(price), by(msha_commodity_name)
egen sd_price = sd(price), by(msha_commodity_name)
gen std_price_datastream = (price_datastream-mean_price)/sd_price
drop mean_price sd_price

* Create log(Price in U$/MT)
merge m:1 msha_commodity_name using `imf_base', nogen keep(1 3)
tab msha_commodity_name units_datastream, m
sort msha_commodity_name year quarter
	
gen price_datastream_base = price_datastream ///
	if year==2006 & quarter==1 & units_datastrea=="index"
	
bys msha_commodity_name: egen price_datastream_rescaled = min(price_datastream_base)
replace price_datastream_rescaled = price_datastream / price_datastream_rescaled ///
	if units_datastream=="index"
	
gen price_mt_datastream = price_datastream
replace price_mt_datastream = price_mt_datastream * price_mt_imf_base ///
	if units_datastream=="index"
replace price_mt_datastream = price_datastream * $mt_lb ///
	if regexm(units_datastream, "[$][/]lb")
replace price_mt_datastream = price_datastream * $mt_to ///
	if regexm(units_datastream, "[$][/]troy_ounce")
replace price_mt_datastream = price_datastream * $mt_to * 100 ///
	if regexm(units_datastream, "[$]cents[/]troy_ounce")

gen ln_price_mt_datastream = ln(price_mt_datastream)
lab var price_mt_datastream "Commodity price in U$/MT [Datastream]"
lab var ln_price_mt_datastream "Log(commodity price in U$/MT) [Datastream]"
	cap drop price_*_base *_rescaled

compress
save "../data/price/datastream.dta", replace

* LME
*-------------------------------------------------------------------------------

insheet using "../data/price/lme-price-data.csv", comma clear

keep msha_name year quarter units price
	rename msha_name msha_commodity_name
	rename price price_lme
	rename units units_lme
lab var price_lme "Commodity last price this quarter [LME]"

* Create a standardized price (mean 0 SD 1)
egen mean_price = mean(price), by(msha_commodity_name)
egen sd_price = sd(price), by(msha_commodity_name)
gen std_price_lme = (price_lme-mean_price)/sd_price
drop mean_price sd_price

* Create log(Price in U$/MT)
tab msha_commodity_name units_lme, m
gen price_mt_lme = price_lme
gen ln_price_mt_lme = ln(price_mt_lme)
lab var price_mt_lme "Commodity price in U$/MT [LME]"
lab var ln_price_mt_lme "Log(commodity price in U$/MT) [LME]"

compress
save "../data/price/lme.dta", replace

* Bloomberg
*-------------------------------------------------------------------------------

insheet using "../data/price/bloomberg.csv", comma clear

* We decided some commodities we pulled from bloomberg cannot in fact be matched to MSHA
drop if msha_name==""
keep msha_name year quarter units price_last
	rename msha_name msha_commodity_name
	rename price_last price_bloomberg
	rename units units_bloomberg
lab var price_bloomberg "Commodity last price this quarter [Bloomberg]"

* Create a standardized price (mean 0 SD 1)
egen mean_price = mean(price), by(msha_commodity_name)
egen sd_price = sd(price), by(msha_commodity_name)
gen std_price_bloomberg = (price_bloomberg-mean_price)/sd_price
drop mean_price sd_price

* Create log(Price in U$/MT)
tab msha_commodity_name units_bloomberg, m
gen price_mt_bloomberg = price_bloomberg
replace price_mt_bloomberg = price_bloomberg * $mt_lb ///
	if regexm(units_bloomberg, "[$][/]lb")
replace price_mt_bloomberg = price_bloomberg * $mt_lb * 100 ///
	if regexm(units_bloomberg, "[$]cents[/]lb")
	
gen ln_price_mt_bloomberg = ln(price_mt_bloomberg)
lab var price_mt_bloomberg "Commodity price in U$/MT [Bloomberg]"
lab var ln_price_mt_bloomberg "Log(commodity price in U$/MT) [Bloomberg]"

compress
save "../data/price/bloomberg.dta", replace

* Extra Datastream prices for antimony and cobalt (CIF NWE)
*-------------------------------------------------------------------------------

import excel using "../data/price/datastream_antimony_cobalt.xlsx", clear

cap ren A date
cap ren B ds_Cobalt_Ore
cap ren C ds_Antimony_Ore
drop in 1/6

drop if trim(date)==""
replace date = trim(date)
split date, parse(" ") gen(d)
cap drop quarter
gen quarter = substr(trim(d1), 2, 1)
cap drop year
gen year = trim(d2)
destring, replace ignore("NA")

cap drop year_quarter
gen year_quarter = yq(year, quarter)
	format year_quarter %tq
keep year_quarter year quarter ds_*
order year_quarter year quarter ds_*

reshape long ds_, i(year_quarter year quarter) j(msha_commodity_name) string

replace msha_commodity_name = subinstr(msha_commodity_name, "_", " ", .)
	ren ds_ price_datastream_extra

gen units_datastream_extra = ""
replace units_datastream_extra = "U$/MT" if msha_commodity_name=="Antimony Ore"
replace units_datastream_extra = "U$/lb" if msha_commodity_name=="Cobalt Ore"
	
* Create a standardized price (mean 0 SD 1)
egen mean_price = mean(price_datastream_extra), by(msha_commodity_name)
egen sd_price = sd(price_datastream_extra), by(msha_commodity_name)
gen std_price_datastream_extra = (price_datastream_extra-mean_price)/sd_price
	drop mean_price sd_price

* Create log(Price in U$/MT)
tab msha_commodity_name units_datastream_extra, m
gen price_mt_datastream_extra = price_datastream_extra
replace price_mt_datastream_extra = price_datastream_extra * $mt_lb ///
	if regexm(units_datastream_extra, "[$][/]lb")
replace price_mt_datastream_extra = price_datastream_extra * $mt_lb * 100 ///
	if regexm(units_datastream_extra, "[$]cents[/]lb")

gen ln_price_mt_datastream_extra = ln(price_mt_datastream_extra)
lab var price_mt_datastream_extra "Commodity price in U$/MT [Datastream]"
lab var ln_price_mt_datastream_extra "Log(commodity price in U$/MT) [Datastream]"
	cap drop year_quarter
	order msha_commodity_name year quarter units_* *price*

compress
save "../data/price/datastream_extra.dta", replace

* Combine all sources into a single file
*-------------------------------------------------------------------------------

use "../data/price/lme.dta", clear

merge m:1 msha_commodity_name year quarter using ///
	"../data/price/bloomberg.dta", gen(merge_bloomberg)
merge m:1 msha_commodity_name year quarter using ///
	"../data/price/datastream.dta", gen(merge_datastream)
merge m:1 msha_commodity_name year quarter using ///
	"../data/price/imf.dta", gen(merge_imf)
merge m:1 msha_commodity_name year quarter using ///
	"../data/price/datastream_extra.dta", gen(merge_datastream_extra)

* Create an authoritative price - label the data sources
gen source = "London Metal Exchange (LME)"
replace source = "IMF Primary Commodity Prices Database" ///
	if std_price_lme==. & std_price_imf!=.
replace source = "Datastream" ///
	if std_price_lme==. & std_price_imf==. & std_price_datastream!=.
replace source = "Bloomberg" ///
	if std_price_lme==. & std_price_imf==. & std_price_datastream==. & std_price_bloomberg!=.
replace source = "Datastream" ///
	if inlist(trim(msha_commodity_name), "Cobalt Ore")
replace source = "Datastream" ///
	if inlist(trim(msha_commodity_name), "Antimony Ore")
	
* The authoritative (standardized) price 
gen std_price = std_price_lme
replace std_price = std_price_imf ///
	if std_price_lme==. & std_price_imf!=.
replace std_price = std_price_datastream ///
	if std_price_lme==. & std_price_imf==. & std_price_datastream!=.
replace std_price = std_price_bloomberg ///
	if std_price_lme==. & std_price_imf==. & std_price_datastream==. & std_price_bloomberg!=.
replace std_price = std_price_datastream_extra ///
	if inlist(trim(msha_commodity_name), "Cobalt Ore")
replace std_price = std_price_datastream_extra ///
	if inlist(trim(msha_commodity_name), "Antimony Ore")
lab var std_price "Standardized commodity price this quarter"

* Repeat for log(U$/MT) version 
cap drop *std_price_mt
gen std_price_mt = price_mt_lme // all U$/MT
replace std_price_mt = price_mt_imf ///
	if price_mt_lme==. & price_mt_imf!=.
replace std_price_mt = price_mt_datastream ///
	if price_mt_lme==. & price_mt_imf==. & price_mt_datastream!=.
replace std_price_mt = price_mt_bloomberg ///
	if price_mt_lme==. & price_mt_imf==. & price_mt_datastream==. & price_mt_bloomberg!=.
replace std_price_mt = price_mt_datastream_extra ///
	if inlist(trim(msha_commodity_name), "Cobalt Ore")
replace std_price_mt = price_mt_datastream_extra ///
	if inlist(trim(msha_commodity_name), "Antimony Ore")
gen ln_std_price_mt = ln(std_price_mt)
	tab msha_commodity_name if !mi(ln_std_price_mt), m
lab var std_price_mt "Standardized price in U$/MT this quarter"
lab var ln_std_price_mt "Standardized Log(price in U$/MT) this quarter"	

cap drop MSHA_COMMODITY_NAME
encode msha_commodity_name, gen(MSHA_COMMODITY_NAME)
cap drop year_quarter
gen year_quarter = yq(year, quarter), before(year)
	format year_quarter %tq

* lagged prices
xtset MSHA_COMMODITY_NAME year_quarter
foreach vv in std_price std_price_mt ln_std_price_mt {
	local l: variable label `vv' 
	forval i = 1(1)$numL {
		cap drop l`i'_`vv'
		gen l`i'_`vv'  = l`i'.`vv' 
		lab var l`i'_`vv' "`l', lagged `i' quarter(s)"
	}
	forval i = 1(1)$numL {
		cap drop f`i'_`vv'
		gen f`i'_`vv'  = f`i'.`vv' 
		lab var f`i'_`vv' "`l', lead `i' quarter(s)"
	}
}

* lagged first differences (1-quarter or year-on-year diffs)
foreach v of varlist std_price std_price_mt ln_std_price_mt {
	gen `v'_dif1 = `v'-l1.`v'
	gen `v'_dif = `v'-l4.`v'
	local l: variable label `v'
	forvalues i = 1/4 {
		gen l`i'_`v'_dif1 = l`i'.`v'_dif1
			lab var l`i'_`v'_dif1 "`l' 1-quarter difference, lagged `i' quarter"
		gen l`i'_`v'_dif = l`i'.`v'_dif
			lab var l`i'_`v'_dif "`l' 4-quarter difference, lagged `i' quarter"
		gen f`i'_`v'_dif1 = f`i'.`v'_dif1
			lab var f`i'_`v'_dif1 "`l' 1-quarter difference, lead `i' quarter"
		gen f`i'_`v'_dif = f`i'.`v'_dif
			lab var f`i'_`v'_dif "`l' 4-quarter difference, lead `i' quarter"
		if `v'==ln_std_price_mt | `v'==ln_price_mt_imf {
			lab var l`i'_`v'_dif "$ \Delta \ln(\textit{Price}_{jt-`i'})$"
		}
		else lab var l`i'_`v'_dif "$ \Delta \textit{Price}_{jt-`i'}$"
	}
}
cap drop MSHA_COMMODITY_NAME
cap drop year_quarter
sort msha_commodity_name year quarter
compress
save "../data/price/std_price.dta", replace

* Precious metal dummy
*-------------------------------------------------------------------------------

use "../data/price/std_price.dta", clear

keep if year>=1983 & year<=2015

collapse (mean) std_price_mt, by(msha_commodity_name)

gen byte precious = (std_price_mt > 10^6)
	tab msha_commodity_name precious, m
	
compress
save "../data/price/precious.dta", replace

cap log close
