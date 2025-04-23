# Demand Conditions and Worker Safety: Evidence from Price Shocks in Mining

**Kerwin Kofi Charles**, **Matthew S. Johnson**, **Melvin Stephens, Jr.**, **Do Q. Lee**  
February 3, 2021

This repository contains the replication materials for the paper *“Demand Conditions and Worker Safety: Evidence from Price Shocks in Mining”*. It includes data (where permissible), Stata code, and output files for tables and figures.

---

## Directory Structure

### `./data/`
- `msha/`: Raw mine-level data from the Mine Safety and Health Administration (MSHA)
- `price/`: Commodity price data from LME, IMF, Datastream, and Bloomberg
- `production/`: Commodity-level production data
- `bmwfw/`: Herfindahl-Hirschman Index (HHI) data from World Mining Data

**Note**: Some data sources (Datastream, Bloomberg) are proprietary and require a subscription.

---

### `./code/`
Contains all scripts needed to replicate the analysis. Written for **Stata 14 or later**.

- `main.do`: Master script that runs the entire replication process
- `ado/`: Additional Stata packages used by `main.do`
- `log/`: Output logs in `.txt` format

#### Data Preparation Scripts:
- `msha_qtrly_oprtr_emplymnt.do`: Prepares MSHA operator employment data
- `msha_qtrly_cntrctr_emplymnt.do`: Prepares MSHA contractor employment data
- `msha_accident.do`: Prepares accident (injuries and illnesses) data
- `msha_violation.do`: Prepares violations data
- `msha_inspection.do`: Prepares inspections data
- `msha_operator_history.do`: Prepares operator history data
- `msha_controller_history.do`: Prepares controller history data
- `msha_contractor_history.do`: Prepares contractor history data
- `price.do`: Prepares commodity price data
- `datastream_production.do`: Prepares production data from Datastream
- `mine_panel_for_analysis.do`: Builds the main analysis dataset
- `mine_panel_for_siblings_analysis.do`: Builds a dataset including corporate siblings

#### Output Scripts:
- `table#.do`: Generates the corresponding table in the paper (replace # with the table number)
- `figure#.do`: Generates the corresponding figure in the paper (replace # with the figure number)

---

### `./tables/`
- Contains LaTeX-formatted tables for the paper

### `./figures/`
- Contains figures in EPS format

---

## Data Sources

### 1. Mine Safety and Health Administration (MSHA)
- Mine-level panel data on employment, injuries, inspections, violations, and ownership
- Accessed via: [MSHA Data Portal](https://enforcedata.dol.gov/views/data_summary.php)
- Downloaded in September 2015

### 2. Commodity Price Data
- London Metal Exchange (LME): Primary source
- IMF Primary Commodity Prices
- Datastream: Cash prices for metals (1983–2015)
- Bloomberg: Supplemental commodity prices

### 3. Additional Datasets
- **World Mining Data (2014)**: Herfindahl-Hirschman Index (HHI) for market concentration
- **USGS Production Data**: Long-run production series for gold and silver
- **Datastream Production Data**: Commodity-level production panel used in supplementary analyses

---

## Replication Instructions

1. Install **Stata 14** or later and ensure access to any required proprietary datasets.
2. Install additional Stata packages found in the `ado/` folder.
3. Run `main.do` located in the `code/` folder. This script will:
   - Prepare datasets
   - Generate the final tables and figures
4. Outputs will be saved in the `tables/` and `figures/` folders.

---

## Contact

For questions about this repository or the paper, please contact:

- Kerwin Kofi Charles: [kerwin.charles@yale.edu](mailto:kerwin.charles@yale.edu)
- Matthew S. Johnson: [matthew.johnson@duke.edu](mailto:matthew.johnson@duke.edu)
- Melvin Stephens, Jr.: [mstep@umich.edu](mailto:mstep@umich.edu)
- Do Q. Lee: [dql204@nyu.edu](mailto:dql204@nyu.edu)

---

**Note**: Proprietary datasets such as those from Datastream and Bloomberg are not included in this repository. Researchers must obtain the necessary subscriptions independently.
