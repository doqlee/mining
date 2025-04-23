********************************************************************************
* Location of Mines in our sample
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/figure2_`logdate'.txt", append text
set linesize 225
version 14 // 15

u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1, clear

sort mine_id year_quarter
tab state_fips, m
replace fips_st_cty_cd = "78010" if state_abbr=="VI"

bys mine_id: gen num_mines = (_n==1)
collapse (sum) num_mines, by(fips_st_cty_cd)
duplicates drop
cap drop county
destring fips_st_cty_cd, gen(county)

* Make sure the map files are installed before using the maptile package: 
*cap maptile_install using "http://files.michaelstepner.com/geo_state.zip"
*cap maptile_install using "http://files.michaelstepner.com/geo_county2014.zip"

maptile num_mines, geo(county2014) nq(5) rangecolor(gs12, black) ///
	ndfcolor(white) /// fcolor(Greys) /// ndfcolor(gs12) ///
	twopt(title("Number of Mines, by County", size(medium) color(black)) ///
	legend(title("# Mines", size(medium)) bmargin(l=100) ///
	order(6 "14 - 57" 5 "6 - 13" 4 "3 - 5" 3 "2" 2 "1" 1 "0")) ///
	graphregion(margin(medium))) stateoutline(medium)
graph export ../figures/figure2.eps, replace // mine_heatmap.pdf
graph close

cap log close
