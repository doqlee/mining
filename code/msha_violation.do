********************************************************************************
* MSHA Violations Data
********************************************************************************

cap log close 
local logdate = string(d(`c(current_date)'), "%dNDCY")
log using "./log/msha_violation_`logdate'.txt", append text
set linesize 225
version 14 // 15

insheet using "../data/msha/msha_violation.csv", comma clear

* Part Section specifies the MSHA regulation that the violation pertains to
* Extract part/section only and take out everything after the terms in parentheses
gen first2 = substr(part_section, 1, 2)
replace first2 = subinstr(first2, ".", "", .)
gen section_num = part_section, after(part_section) // part_substr(part_section,1,4)
replace section_num = regexr(section_num, "[\(].*", "")

* Dummies for violations of each part of the MSHA regulations
levelsof first2, local(parts)
local label_37 "SUBCHAPTER C-F [Reserved]"
local label_40 "REPRESENTATIVE OF MINERS"
local label_41 "NOTIFICATION OF LEGAL IDENTITY"
local label_44 "RULES OF PRACTICE FOR PETITIONS FOR MODIFICATION OF MANDATORY SAFETY STANDARDS"
local label_45 "INDEPENDENT CONTRACTORS"
local label_46 "TRAINING AND RETRAINING OF MINERS ENGAGED IN SHELL DREDGING"
local label_47 "HAZARD COMMUNICATION (HazCom)"
local label_48 "TRAINING AND RETRAINING OF MINERS"
local label_49 "MINE RESCUE TEAMS"
local label_50 "REPORTS OF ACCIDENTS, INJURIES, ILLNESSES, EMPLOYMENT, AND COAL PRODUCTION"
local label_55 "SUBCHAPTER J [Reserved]"
local label_56 "SAFETY AND HEALTH STANDARDS-SURFACE METAL AND NONMETAL MINES"
local label_57 "SAFETY AND HEALTH STANDARDS-UNDERGROUND METAL AND NONMETAL MINES"
local label_58 "HEALTH STANDARDS FOR METAL AND NONMETAL MINES"
local label_62 "OCCUPATIONAL NOISE EXPOSURE"
local label_7 "TESTING BY APPLICANT OR THIRD PARTY"
local label_70 "MANDATORY HEALTH STANDARDS-UNDERGROUND COAL MINES"
local label_71 "MANDATORY HEALTH STANDARDS-SURFACE COAL MINES AND SURFACE WORK AREAS"
local label_72 "HEALTH STANDARDS FOR COAL MINES"
local label_75 "COAL MINE DUST SAMPLING DEVICES"
local label_77 "MANDATORY SAFETY STANDARDS-UNDERGROUND COAL MINES"
local label_81 "MANDATORY SAFETY STANDARDS-SURFACE COAL MINES AND SURFACE WORK AREAS"
local label_90 "MANDATORY HEALTH STANDARDS-COAL MINERS WITH EVIDENCE OF PNEUMOCONIOSIS"
foreach part in `parts' {
	gen byte part`part'_viol = (first2=="`part'")
}

* Lockout / Tagout violations
gen loto_viol = 0
replace loto_viol = 1 if section_num=="56.12006"
replace loto_viol = 1 if section_num=="56.12016"
replace loto_viol = 1 if section_num=="56.12017"
replace loto_viol = 1 if section_num=="56.14105"
replace loto_viol = 1 if section_num=="57.12006"
replace loto_viol = 1 if section_num=="57.12016"
replace loto_viol = 1 if section_num=="57.12017"
replace loto_viol = 1 if section_num=="57.14105"

* Violations having to do with repairs, maintenance, housekeeping, examination
tab section_num if first2=="57", sort
gen rep_maint_exam_viol = 0
replace rep_maint_exam_viol = 1 if section_num=="57.14100"
replace rep_maint_exam_viol = 1 if section_num=="57.20003"

* Categorize violations by various measures of severity
gen high_negligence_viol = negligence=="HighNegligence"
gen reckless_viol = negligence=="Reckless"
gen sig_sub_viol = sig_sub=="Y"

* event_no is the identifier for each inspection - collapse to the inspection level
collapse (sum) *_viol, by(event_no)
tab high_negligence_viol
su part*viol

* Part 55 viol is always zero, so delete it
drop part55_viol

* Total number of violations by mine-quarter
egen total_viol = rowtotal(part*viol)

compress
save "../data/msha/msha_violation.dta", replace

cap log close
