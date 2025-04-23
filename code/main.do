*===============================================================================
* DEMAND CONDITIONS AND WORKPLACE SAFETY: EVIDENCE FROM PRICE SHOCKS IN MINING
* Kerwin Kofi Charles, Matthew S. Johnson, Melvin Stephens, Jr., Do Q Lee
* January 30, 2021
*===============================================================================

********************************************************************************
* 0 Master Do-file
********************************************************************************

* 1. Set Paths and Settings
*-------------------------------------------------------------------------------

pwd
adopath + "./ado/"

set more off
clear all
timer clear
set matsize 11000
set seed 12345

* 2. Create folder structure
*-------------------------------------------------------------------------------

cap mkdir ./log/
cap mkdir ../data/
cap mkdir ../tables/
cap mkdir ../figures/

* 3. Run do-files
*-------------------------------------------------------------------------------

* 3.1 Data Prep
do msha_qtrly_oprtr_emplymnt.do
do msha_qtrly_cntrctr_emplymnt.do
do msha_accident.do
do msha_violation.do
do msha_inspection.do
do msha_operator_history.do
do msha_controller_history.do
do msha_contractor_history.do
do price.do
do datastream_production.do
do mine_panel_for_analysis.do
do mine_panel_for_siblings_analysis.do

* 3.2 Tables
do table1.do
do table2.do
do table3.do
do table4.do
do table5.do
do table6.do
do table7.do
do table8.do
do table9.do
do table10.do
do tableB1.do
do tableB2.do
do tableB3.do

* 3.3 Figures
do figure1.do
do figure2.do
do figure3.do
do figureB1.do
do figureB2.do
do figureB3.do

