********************************************************************************
* Range of Price Data and Number of Mines for Each Commodity in our Sample
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/table1_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1, clear
merge m:1 msha_commodity_name year quarter using ///
	"../data/price/std_price.dta", keep(master match) keepusing(source) nogen

cap drop start end num_mines psource
gen start = ""
gen end = ""
gen num_mines = .
gen psource = ""
levelsof msha_commodity_name if std_price!=., local(commodities) 
foreach com in `commodities' {

	* Start and end date of price series
	qui sum year_quarter if msha_commodity_name=="`com'" & std_price!=.
	local start: di %tq `r(min)'
	local end: di %tq `r(max)'
	di "Commodity: `com', Start: `start', End: `end'"
	qui replace start = "`start'" if msha_commodity_name=="`com'" 
	qui replace end = "`end'" if msha_commodity_name=="`com'" 

	* Source of price data
	loc psource
	levelsof source if msha_commodity_name=="`com'" & std_price!=., local(slist)
	foreach ss in `slist' {
		loc psource `ss', 
	}
	loc psource = regexr("`psource'", "\,\s?$", "")
	di "Commodity: `com', Source(s): `psource'"
	qui replace psource = "`psource'" if msha_commodity_name=="`com'" 

	* Number of mines
	cap drop z
	qui gen z = msha_commodity_name=="`com'"
	cap noi unique mine_id if z==1 & std_price!=. & mine_opened==1 & mine_abandoned!=1
	local num_mines = `r(unique)' // `r(sum)' 
	di "Commodity: `com', # Mines: `num_mines'"
	qui replace num_mines = `num_mines' if z==1 
}
keep msha_commodity_name start end num_mines psource
duplicates drop
compress
lab var msha_commodity_name ""
lab var start "First year"
lab var end "Last year"
lab var num_mines "No. mines"
lab var psource "Source of price data"
texsave using "../tables/table1.tex", replace varlabels nofix /// 
	width(>{\raggedright}p{0.25\linewidth}>{\centering}p{0.08\linewidth}>{\centering}p{0.08\linewidth}>{\centering}p{0.08\linewidth}>{\centering\arraybackslash}p{0.4\linewidth}) ///
	headerlines(" & (1) & (2) & (3) & (4) " ///
		"& \multicolumn{2}{c}{Price Series Range} & & " ///
		"\cmidrule(r){2-3}")

cap log close
