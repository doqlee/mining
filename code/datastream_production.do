********************************************************************************
* Production Data from Datastream
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_accident_`logdate'.txt", append text
set linesize 225
version 14 // 15

insheet using "../data/production/production data - datastream.csv", comma clear

keep msha_name year quarter units production
rename msha_name msha_commodity_name
rename production production_datastream
rename units units_production_datastream

* Create a standardized production index with mean=0 and sd=1
egen mean_production = mean(production_datastream), by(msha_commodity_name)
egen sd_production = sd(production_datastream), by(msha_commodity_name)
gen std_production_datastream = (production_datastream-mean_production)/sd_production
drop mean_production sd_production

* Label variables
lab var production_datastream "Commodity production this quarter [Datastream]"
lab var units_production_datastream "Units of measurement, Datastream production data"
lab var std_production_datastream "Standardized commodity production this quarter [Datastream]"	

* Create log production in MT
gen production_mt = production_datastream
replace production_mt = 4830 * 1000 * production_mt if msha_commodity_name=="Aluminum Ore-Bauxite" // Index=100 in 2012. US production was 4,830 thousand MT for 2012. 
replace production_mt = production_mt / 1000 if msha_commodity_name=="Iron Ore"
gen ln_production_mt = ln(production_mt)
lab var production_mt "Commodity production this quarter, metric tons [Datastream]"
lab var ln_production_mt "Log(Commodity production this quarter, metric tons) [Datastream]"
	
compress
save "../data/production/datastream_production.dta", replace

cap log close
