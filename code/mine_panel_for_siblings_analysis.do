********************************************************************************
* Put together mine-level panel with info on corporate siblings
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/mine_panel_for_siblings_analysis_`logdate'.txt", append text
set linesize 225
version 14 // 15

set seed 1234
u ../data/mine_panel_for_analysis.dta if year>=1983 & mine_opened==1, clear

sort mine_id year_quarter
egen commodity_group = group(msha_commodity_name)

* Controller ID is like the firm ID
drop if curr_ctrlr_id==""

* Drop firms without a single commodity with prices
egen ever_has_price_ctrl = max(ever_has_price), by(curr_ctrlr_id)
drop if ever_has_price_ctrl!=1
drop ever_has_price_ctrl 

* First: a file with quarterly prices at commodity level
preserve
	keep if ln_std_price_mt!=.
	keep year_quarter commodity_group ln_std_price_mt
	
	duplicates drop 
	duplicates report commodity_group year_quarter 
	
	rename commodity_group commodity_group_gen
	rename ln_std_price_mt ln_std_price_mt_gen
	tempfile comm
	save `comm', replace
restore

* Total firm employment and # mines each quarter
egen num_mine_ctrl = count(mine_id), by(curr_ctrlr_id year_quarter)
egen total_emp_ctrl = sum(avg_empl_cnt_total_tc), by(curr_ctrlr_id year_quarter)

* Collapse to firm-commodity-quarter level 
* Gives us the # mines and total employment at each level
preserve
	keep if ln_std_price_mt!=.
	
	collapse (count) num_mine_ctrl_comm = mine_id ///
		(sum) total_emp_ctrl_comm = avg_empl_cnt_total_tc ///
		, by(curr_ctrlr_id commodity_group year_quarter)
		
	rename commodity_group commodity_group_gen
	tempfile ctrl_comm
	save `ctrl_comm', replace
restore

* Collapse to firm-commodity-COUNTY-quarter level 
* Gives us the # mines and total employment at each level
preserve
	keep if ln_std_price_mt!=.
	
	collapse (sum) total_emp_ctrl_comm_state = avg_empl_cnt_total_tc ///
		, by(curr_ctrlr_id commodity_group fips_st_cty_cd year_quarter)
	
	rename commodity_group commodity_group_gen
	tempfile ctrl_comm_state
	save `ctrl_comm_state', replace
restore

* First, for each observation, merge in all commodity prices
joinby year_quarter using `comm', unmatched(none) _merge(merge_yq)

* Merge in controller file to identiy which commodities a firm does NOT produce
merge m:1 curr_ctrlr_id commodity_group_gen year_quarter ///
	using `ctrl_comm', gen(merge_comm_ctrl)
merge m:1 curr_ctrlr_id commodity_group_gen fips_st_cty_cd year_quarter ///
	using `ctrl_comm_state', gen(merge_comm_ctrl_state)
* Merge = 1 means firm did not produce that commodity this quarter

* Missing to zero
foreach v of varlist num_mine_ctrl_comm total_emp_ctrl_comm total_emp_ctrl_comm_state {
	replace `v' = 0 if merge_comm_ctrl==1
	replace `v' = 0 if missing(`v')
}

* Total employment in my firm in other commodities for mines located in OTHER states
gen total_emp_ctrl_commm_oth_state = total_emp_ctrl_comm - total_emp_ctrl_comm_state
replace total_emp_ctrl_commm_oth_state = 0 if total_emp_ctrl_commm_oth_state ==.
	
* The weights for each commodity is firm's emp in that commodity / total firm emp
gen comm_wgt = total_emp_ctrl_comm / total_emp_ctrl

* Multiply the weight by the commodity's price
gen price_wgt = ln_std_price_mt_gen * comm_wgt

* Average price for the firm's other commodities
* Weighted by their share of firm's employment
gen price_wgt_oth = price_wgt
replace price_wgt_oth = . if commodity_group==commodity_group_gen
egen avg_price_ctrl_oth = sum(price_wgt_oth), by(mine_id year_quarter)

* Also do one where we only use mines' siblings that are located in OTHER states
gen comm_wgt2 = total_emp_ctrl_commm_oth_state / total_emp_ctrl

* Multiply the weight by the commodity's price
gen price_wgt2 = ln_std_price_mt_gen*comm_wgt2

* Average price for the firm's other commodities
* Weighted by their share of firm's employment
gen price_wgt2_oth = price_wgt2
replace price_wgt2_oth = . if commodity_group==commodity_group_gen
egen avg_price_ctrl_oth2 = sum(price_wgt2_oth), by(mine_id year_quarter)

* Note which mines are part of firms that have other commodities with price data
gen not_me_ctrl = commodity_group!=commodity_group_gen & merge_comm_ctrl==3
gen num_mine_ctrl_comm_not = num_mine_ctrl_comm if not_me_ctrl==1
egen sum_mine_ctrl_not = sum(num_mine_ctrl_comm_not), by(mine_id year_quarter)	
lab var sum_mine_ctrl_not "# other mines in my firm in other commodities with prices"
	drop num_mine_ctrl_comm_not 
	
* Among those commodities the firm does NOT produce: 
* For a given mine, pick one at random
gen double unif = runiform() if merge_comm_ctrl==1
egen rank_unif = rank(unif) if unif!=., by(mine_id year_quarter)
gen price_rand = ln_std_price_mt_gen if rank_unif==1
egen price_rand_not_ctrl = max(price_rand), by(mine_id year_quarter) 
	drop unif rank_unif price_rand

* Want to check own-price effect based on whether mine is part of multiunit firm
keep if commodity_group==commodity_group_gen
preserve 
	u ../data/mine_panel_for_analysis.dta if year>=1983 & ever_has_price==1 & mine_opened==1, clear
	
	egen num_mine_ctrl = count(mine_id), by(ctrlr_id year quarter)
	sum num_mine_ctrl if num_mine_ctrl>1, d
	gen siblings = num_mine_ctrl>1
	lab var siblings "In multi-unit firm"
	
	keep mine_id year quarter num_mine_ctrl siblings 
	tempfile siblings 
	save `siblings' , replace 
restore
merge 1:1 mine_id year quarter using `siblings', keep(master match) nogen

compress
save ../data/mine_panel_for_siblings_analysis.dta, replace

cap log close
