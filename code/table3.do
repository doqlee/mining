********************************************************************************
* Global Production and Markets for Commodities in our Sample
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/table3_`logdate'.txt", append text
set linesize 225
version 14 // 15

* Crosswalk file to standardize commodity names to MSHA definitions
insheet using "../data/commodity_names.csv", comma names clear
tempfile commodity_names
save `commodity_names', replace

* Mining industry HHI data by commodity and country 
insheet using "../data/commodity_tomerge.csv", comma names clear
tempfile commodity_tomerge
save `commodity_tomerge', replace

* Production data. Rank of US production relative to rest of the world. 
local commodity_list Aluminium Bauxite Antimony Cobalt Copper Gold Iron Lead ///
	Molybdenum Nickel Platinum Silver Tin Uranium Vanadium Zinc
foreach c of local commodity_list {
	import excel using ///
		"../data/bmwfw/6.4.Production_of_Mineral_Raw_Materials_of_individual_Countries_by_Minerals.xlsx" ///
		, sheet(`c') case(lower) clear
	drop in 1/2 // table title
	compress
	ren A country
	ren B unit
	ren C y2011
	ren D y2012
	ren E y2013
	ren F y2014
	ren G y2015
	ren H source
	gen commodity = "`c'"
	replace country = "World" if country=="Total"
	forval i = 2011(1)2015 {
		destring y`i', replace
		replace y`i' = 0 if mi(y`i')
	}
	gen cum_u = y2011 + y2012 + y2013 + y2014 + y2015, before(source)
	gsort -cum_u
	egen cty_rank = rank(-cum_u)
	order cty_rank, after(country)
	keep if inlist(country, "United States", "World") | cty_rank==2
	drop source
	tempfile `c'
	save ``c'', replace
}

foreach c of local commodity_list {
    append using ``c''
}
duplicates drop commodity country, force
drop I

merge m:1 commodity country using `commodity_tomerge'
drop _merge

merge m:1 commodity using `commodity_names'
drop _merge

order commodity msha_commodity_name, before(country)
sort commodity cty_rank
bys commodity: replace unit = unit[_n-1] if unit==""

// US Share of cumulative production
gen cum_w = cum_u if country=="World"
bys msha_commodity_name (cty_rank): ///
    replace cum_w = cum_w[_n-1] if mi(cum_w)
gen shr_cum_u = cum_u / cum_w * 100

// Rank 1 country's Share of cumulative production
gen cum_r = cum_u if cty_rank==2
bys msha_commodity_name (cty_rank): ///
    replace cum_r = cum_r[_n-1] if mi(cum_r)
gen shr_cum_r = cum_r / cum_w * 100

// US Share of leading mine and 2014 production
gen w2014 = y2014 if country=="World"
bys msha_commodity_name (cty_rank): ///
    replace w2014 = w2014[_n-1] if mi(w2014)
gen shr_cap_u2014 = cap_u2014 / w2014 * 100
gen shr_u2014 = y2014 / w2014 * 100

// Rank 1 country's share of 2014 production
gen r2014 = y2014 if cty_rank==2
bys msha_commodity_name (cty_rank): ///
    replace r2014 = r2014[_n-1] if mi(r2014)
gen shr_r2014 = r2014 / w2014 * 100

// HHI index
gen hhi_w2014 = hhi_u2014 if country=="World"
bys msha_commodity_name (cty_rank): ///
    replace hhi_w2014 = hhi_w2014[_n-1] if mi(hhi_w2014)
gen hhi_r2014 = hhi_u2014 if cty_rank==2
bys msha_commodity_name (cty_rank): ///
    replace hhi_r2014 = hhi_r2014[_n-1] if mi(hhi_r2014)

// Name of rank 1 country
gen r_cty = country if cty_rank==2
bys msha_commodity_name (cty_rank): ///
    replace r_cty = r_cty[_n-1] if mi(r_cty)

sort commodity cty_rank
keep if country=="United States"

ren y2014 u2014
drop commodity country y2011 y2012 y2013 y2015 mine_u2014 operator_u2014 
order msha_commodity_name cty_rank r_cty unit ///
    u2014 r2014 w2014 shr_u2014 shr_r2014 ///
    cum_u cum_r cum_w shr_cum_u shr_cum_r ///
    hhi_u2014 hhi_r2014 hhi_w2014 ///
    cap_u2014 shr_cap_u2014 

lab var msha_commodity_name "Commodity"
lab var cty_rank "Rank of United States by production in 2014 (US)"
lab var r_cty "Country with highest production in 2014 (Rank 1)"
lab var unit "Unit of production"
lab var u2014 "Mine Production in 2014 (US)"
lab var r2014 "Mine Production in 2014 (Rank 1)"
lab var w2014 "Mine Production in 2014 (World)"
lab var shr_u2014 "u2014 / w2014 * 100"
lab var shr_r2014 "r2014 / w2014 * 100"
lab var cum_u "Cumulative production from 2011 to 2015 (US)"
lab var cum_r "Cumulative production from 2011 to 2015 (Rank 1)"
lab var cum_w "Cumulative production from 2011 to 2015 (World)"
lab var shr_cum_u "cum_u / cum_w (%)"
lab var shr_cum_r "cum_r / cum_w (%)"
lab var hhi_u2014 "Herfindahl-Hirschman Index (HHI) in 2014 (US)"
lab var hhi_r2014 "Herfindahl-Hirschman Index (HHI) in 2014 (Rank 1)"
lab var hhi_w2014 "Herfindahl-Hirschman Index (HHI) in 2014 (World)"
lab var cap_u2014 "Production capacity of leading mine in US"
lab var shr_cap_u2014 "cap_u2014 / w2014 * 100"
d

format shr* %9.2f
expand 2 in 1, gen(tag)
sort msha_commodity_name tag
drop tag
tostring shr* hhi*, replace force usedisplayformat
tostring _all, replace force
ds
loc vars = r(varlist)
foreach v of local vars {
    di `"`v'"'
	replace `v' = `"`: var label `v''"' in 1
}

compress
save "../tables/table3.dta", replace
outsheet _all using "../tables/table3.csv", comma replace

cap log close
