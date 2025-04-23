********************************************************************************
* MSHA Accidents Data (Injuries and Illnesses)
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_accident_`logdate'.txt", append text
set linesize 225
version 14 // 15

insheet using "../data/msha/msha_accident.csv", comma clear

* Date of accident
gen accident_date = date(ai_dt, "YMD"), after(ai_dt)
	format accident_date %td

* Clean data entry errors in no_injuries
* Impute with the number of documents registered in data per incident
su no_injuries, d
bys mine_id accident_date accident_time: gen _tmp = _N
replace no_injuries = _tmp if no_injuries!=_tmp
	tab no_injuries, m
	cap drop _tmp

* Incident-level identifier: Same mine/same date/same time/same no. injuries
* Note: Incident = n*Accidents. An incident may involve many people injured
duplicates tag mine_id accident_date accident_time, gen(dup0) // 
	tab dup0, m
	cap drop dup0
sort mine_id accident_date
egen incident_id = group(mine_id accident_date accident_time)
	order incident_id, first

* no_injuries only varies at the incident level!
* Before doing a collapse (sum), make sure we do not double count number of injuries
* Recall: we set no_injuries = # documents per incident
gen raw_no_injuries = no_injuries
bys incident_id (document_no): replace no_injuries = 1

* Injuries with unidentified degree
replace degree_injury_cd="11" if degree_injury_cd == "?"

* Actually, let's drop those with unidentified degree
drop if degree_injury_cd=="11"

* Dummy for each type of injury
levelsof degree_injury_cd, local(degrees)
local label_00 "Accident only"
local label_01 "Fatality"
local label_02 "Perm disability"
local label_03 "Days away from work only"
local label_04 "Days away and rstrcted act"
local label_05 "Days restricted act only"
local label_06 "No days away, no rstrctd act"
local label_07 "Occ illness"
local label_08 "Natural causes"
local label_09 "inj involving nonemployees"
local label_10 "All other cases"
local label_11 "No value found"
foreach type in `degrees' {
	gen byte inj_type_`type' = degree_injury_cd=="`type'"
}

* Dummies for workers with high/low experience at current mine
gen byte accidents_mine_exper1 = (exper_mine_calc>=.5 & exper_mine_calc!=.) // 6 month == 0.5 year
gen byte accidents_mine_exper2 = (exper_mine_calc<.5 & exper_mine_calc!=.)
gen byte accidents_mine_exper3 = (exper_mine_calc==.)

* Dummies for workers with high/low experience in the mining sector
gen byte accidents_tot_exper1 = (exper_tot_calc>=3 & exper_tot_calc!=.) // 3 years is ~25th percentile
gen byte accidents_tot_exper2 = (exper_tot_calc<3 & exper_tot_calc!=.)
gen byte accidents_tot_exper3 = (exper_tot_calc==.)

* Identify traumatic injuries using the approach in Morantz (2013) ILRR
gen byte traumatic_injury = 0
replace traumatic_injury = 1 if inj_type_01==1
replace traumatic_injury = 1 if regexm(nature_injury, "AMPUTAT")
replace traumatic_injury = 1 if regexm(nature_injury, "ENUC")
replace traumatic_injury = 1 if regexm(nature_injury, "FRACT")
replace traumatic_injury = 1 if regexm(nature_injury, "CHIP")
replace traumatic_injury = 1 if regexm(nature_injury, "DISLOC")
replace traumatic_injury = 1 if regexm(nature_injury, "EYE")
replace traumatic_injury = 1 if regexm(nature_injury, "LACER")
replace traumatic_injury = 1 if regexm(nature_injury, "PUNCT")
replace traumatic_injury = 1 if regexm(nature_injury, "BURN")
replace traumatic_injury = 1 if regexm(nature_injury, "SCALD")
replace traumatic_injury = 1 if regexm(nature_injury, "CRUSH")

* Identify injuries related to over-exertion
replace accident_type = upper(accident_type)
gen byte exertion_injury = regexm(accident_type, "EXERTION")
gen byte fall_injury = regexm(accident_type, "FALL ") // exclude "falling" by adding the space at end
gen byte struck_injury = regexm(accident_type, "STRUCK")
gen byte machinery_injury = (ai_class_desc=="MACHINERY")
gen byte electrical_injury = (ai_class_desc=="ELECTRICAL")

* Incident that involved a contractor, # injuries involving contractor
gen byte incident_cntctr = (trim(cntctr_id)!=""), after(cntctr_id)
gen int no_injuries_cntctr = no_injuries if incident_cntctr==1, after(no_injuries) 
gen byte incident_excntctr = (trim(cntctr_id)==""), after(cntctr_id)
gen int no_injuries_excntctr = no_injuries if incident_excntctr==1, after(no_injuries) 
ds incident_*cntctr no_injuries_*cntctr // 
foreach vv in `r(varlist)' {
	replace `vv' = 0 if no_injuries==0
}

* Redefine variables at incident level
ds inj_type_* *exper* no_injuries no_injuries_*cntctr incident_*cntctr /// 
	traumatic_injury exertion_injury fall_injury struck_injury ///
	machinery_injury electrical_injury
global vlist_accid "`r(varlist)'" // accident-level variables
cap drop ic_*
foreach vv in `r(varlist)' {
	gen ic_`vv' = `vv'
	bys incident_id (ic_`vv'): replace ic_`vv' = . if _n!=_N // 
}
ds ic_*
global vlist_ic "`r(varlist)'" // incident-level variables

* Number of accidents by mine
keep mine_id cal_yr cal_qtr $vlist_accid $vlist_ic
compress
collapse (sum) $vlist_accid $vlist_ic, /// 
	by(mine_id cal_yr cal_qtr)
	rename cal_yr year
	rename cal_qtr quarter

* Number of serious injuries
gen serious_injury = inj_type_01 + inj_type_02 + inj_type_03 + inj_type_04
gen ic_serious_injury = ic_inj_type_01 + ic_inj_type_02 + ic_inj_type_03 + ic_inj_type_04
	
* Total number of accidents by mine-quarter
egen total_accidents = rowtotal(inj_type_00-inj_type_10)
egen total_incidents = rowtotal(ic_inj_type_00-ic_inj_type_10)
gen total_accidents_min_nn = (total_accidents - inj_type_08 - inj_type_09)
gen total_incidents_min_nn = (total_incidents - ic_inj_type_08 - ic_inj_type_09)

* Label variables
foreach type in `degrees' {
	lab var inj_type_`type' "`label_`type''"
}
lab var exper_tot_calc "Experience in the job title of the injured worker(s) this quarter"
lab var exper_mine_calc "Total experience at a specific mine of the injured worker(s) this quarter"
lab var exper_job_calc "Total mining experience of the injured worker(s) this quarter"
lab var accidents_mine_exper1 "# injuries involving workers with >=6 months experience at the mine"
lab var accidents_mine_exper2 "# injuries involving workers with <6 months experience at the mine"
lab var accidents_mine_exper3 "# injuries with experience at this mine of worker missing"
lab var accidents_tot_exper1 "# injuries involving workers with >=1 year experience in mining industry"
lab var accidents_tot_exper2 "# injuries involving workers with <1 year experience in mining industry"
lab var accidents_tot_exper3 "# injuries with total experience of worker missing"
lab var traumatic_injury "Number of traumatic injuries"
lab var exertion_injury "Number of injuries caused by over-exertion"
lab var fall_injury "Number of injuries caused by worker falling"
lab var struck_injury "Number of injuries caused by striking object"
lab var machinery_injury "Number of injuries caused by machinery"
lab var electrical_injury "Number of injuries caused by electrical"
lab var serious_inj "Number of fatalities, permanent disabilities, or DAFW injuries"
lab var no_injuries_cntctr "Number of injuires from incidents involving a contractor"
lab var incident_cntctr "Number of incidents involving a contractor"
lab var no_injuries_excntctr "Number of injuires from incidents that do not involve a contractor"
lab var incident_excntctr "Number of incidents that do not involve a contractor"
lab var total_accidents "Total number of accidents this quarter"
lab var total_accidents_min_nn "Total number of accidents this quarter, less natural and non-emp"
lab var total_incidents "Total number of incidents this quarter"
lab var total_incidents_min_nn "Total number of incidents this quarter, less natural and non-emp"
	
* Check for differences between accident-level vs incident-level variables
ds mine_id year quarter ic_*, not
foreach vv in `r(varlist)' {
	di "count if `vv'!=ic_`vv'"
	cap count if `vv'!=ic_`vv'
	qui cap loc lbl: variable label `vv'
	qui cap lab var ic_`vv' "Incident level: `lbl'"
}
ren ic_no_injuries no_incidents
lab var no_injuries "Number of injuries this quarter"
lab var no_incidents "Number of incidents this quarter"

d
compress
save "../data/msha/msha_accident.dta", replace

cap log close
