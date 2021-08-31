/*
Created by: Peichen Li
Last Updated: 6/12/2021

This do file is for exercise 1 & 2 of the PRE Workshp Stata Exercise Session

The task is to analyze data from the Social Connectedness Index (SCI), a dataset built from an anonymized snapshot of Facebook users and their friendship networks. The data measure the intensity of social connections between counties.

Relevant data: “county_county_sci.tsv”,  “sf12010countydistancemiles.csv”

Our team has a presentation coming up to a set of policymakers in Washtenaw County, Michigan. Using the SCI and the county distance datasets, make a set of exploratory plots describing the social connections of Washtenaw County. Specifically:

Exercise 1
(a)	Summarize the distribution of Washtenaw’s Social Connectedness Index to other counties
(b)	Which counties are most strongly connected to Washtenaw?
(c)	Merge in the distance data and describe the relationship between distance to Washtenaw and connectedness to Washtenaw

Exercise 2
(a) Using the “county_county_sci.tsv” and “sf12010countydistancemiles.csv”, construct a county-level
measure of network concentration ~ number of facebook friends living nearby. Briefly justify your measure (there is no single “right” answer).
(b) Summarize the distribution of this measure. Where does Washtenaw County fall on the national and
relevant state distribution?
(c) Merge in the county_demographics dataset and describe relationships between network
concentration and 2-3 other county level measures. Suggest possible explanations of why these
relationships might exist. Discuss any ideas you have on how your explanations could be tested (perhaps using other data or in other contexts).
*/


*---------------------
* Set useful globals
*---------------------

global root "C:/Users/90596/Downloads/Practice Exercise"
global input_data "${root}/input"
global temp_data "${root}/intermediate"
global output "${root}/output"



**************************************************************************************************************************************************************************************
* Exercise 1


*---------------------
* Input Data
*---------------------

* Input data
import delimited "${input_data}/county_county_sci.tsv", clear

* Verify the level of the data -- county-pair level (no repetitions for these two variables)
isid user_loc fr_loc

* Merge in County names

	* Clean County Names Data
	preserve
	import delimited "{input_data}/county_description.csv", clear
	keep county_fips county_name state_name
	rename county_fips user_loc
	tempfile temp_county_name
	save `temp_county_name'
	restore
	
	* Merge to main file
	merge m:1 user_loc using `temp_county_name', keep(3) nogen

* Keep Washtenaw, MI
keep if county_name == "Washtenaw"
drop if fr_loc == 26161


*---------------------------------------------
* Part (a): Summarize SCI of Washtenaw County
*---------------------------------------------
summarize scaled_sci
summarize scaled_sci, detail

* Make histogram of scaled_sci
histogram scaled_sci, frequency

* Transform scaled_sci for interpretability
generate log_scaled_sci = log(scaled_sci) 

* Make histogram of log_scaled_sci
histogram log_scaled_sci, frequency xtitle("Social Connectedness") ytitle("Count") color(maroon) ylabel(,nogrid) xscale(range(0 13)) xlabel(0(1)13)
graph export "${output}/histogram log scaled sci.png", replace


*--------------------------------------------------------------
* Part (b): Which counties are the most connected to Washtenaw
*--------------------------------------------------------------

* Merge in County names

	* Clean County Names Data
	preserve
	import delimited "{input_data}/county_description.csv", clear
	keep county_fips county_name state_name
	rename (county_fips county_name state_name) (fr_loc fr_county_name fr_state_name)
	tempfile temp_county_name_fr
	save `temp_county_name_fr'
	restore
	
	* Merge to main file
	merge m:1 fr_loc using `temp_county_name_fr', keep(3) nogen
	
* Find top 10 counties that are connected to Washtenaw, MI

egen sci_rank = rank(-scaled_sci)
sort sci_rank

	* Make and export table
	preserve
	keep if sci_rank <= 10
	keep scaled_sci fr_county_name fr_state_name
	rename (scaled_sci fr_county_name fr_state_name) (SCI County State)
	order County State SCI
	export delimited "${output}/top 10 counties.csv", replace
	restore

* Save temporary dadtaset
save "${temp_data/temp.dta}", replace

*--------------------------------------------------------------
* Part (c): Describe the relationship between distance to Washtenaw and connectedness
* to Washtenaw
*--------------------------------------------------------------

* Use temporary dataset
use "${temp_data}/temp.dta", clear

* Merge in distance data
	
	preserve
	import delimited "${input_data}/sf12010countydistancemiles.csv", clear
	rename (county1 county2) (user_loc fr_loc)
	tempfile distance
	save `distance'
	restore
	
	* Merge into Washtenaw County data
	merge 1:1 user_loc fr_loc using `distance', keep(3) nogen

* Transform distance variable and visualize distribution
gen log_distance = log(mi_to_county)
histogram log_distance, frequency

* Make scatterplot
twoway (scatter log_sci ml_to_county) (lfit log_scaled_sci log_distance)
twoway (scatter log_sci ml_to_county) (qfit log_scaled_sci log_distance)

* Make binscatter
ssc install binscatter
binscatter log_scaled_sci log_distance, nquantiles(20) linetype(qfit) ytitle("Log SCI") xtitle("Log Distance") ylabel(,nogrid)
graph export "${output}/binscatter log sci to log distance.png", replace

* Make a map of SCI to Washtenaw, MI
ssc install maptile
ssc install spmap
rename fr_loc county
maptile log_scaled_sci, geo(county2014) nquantiles(9) rangecolor(White blue*1.2) proptwopt(legend(title("Log SCI")))
graph export "${output}/map of sci Washtenaw.png", replace


**************************************************************************************************************************************************************************************
* Exercise 2


*---------------
* Input Data
*---------------

* Input data
import delimited "${input_data}/county_county_sci.tsv", clear 

* Verify the level of the data -- county-pair level 
isid user_loc fr_loc

* Get county names

		* Clean County Names Data
		preserve
		import delimited "${input_data}/county_description.csv", clear
		keep county_fips county_name state_name
		rename county_fips user_loc
		tempfile temp_county_name
		save `temp_county_name'
		restore 
		
		* Merge to main file
		merge m:1 user_loc using `temp_county_name', keep(3) nogen
		
		
		* Clean County Names Data
		preserve
		import delimited "${input_data}/county_description.csv", clear
		keep county_fips county_name state_name
		rename (county_fips county_name state_name) (fr_loc fr_county_name fr_state_name)
		tempfile temp_county_name_fr
		save `temp_county_name_fr'
		restore 
		
		* Merge to main file
		merge m:1 fr_loc using `temp_county_name_fr', keep(3) nogen

* Get county populations

	* Save population tempfile
	preserve
	import delimited "${input_data}/county_demographics.csv",clear
	keep if measure == "total_population"
	destring value, replace
	rename value user_population
	rename county_fips user_loc 
	drop measure 
	tempfile user_loc_pop
	save `user_loc_pop'
	restore
	
	* Merge in user_loc population
	merge m:1 user_loc using `user_loc_pop', keep(3) nogen 
	
	* Save population tempfile
	preserve
	import delimited "${input_data}/county_demographics.csv",clear
	keep if measure == "total_population"
	destring value, replace
	rename value fr_population
	rename county_fips fr_loc 
	drop measure 
	tempfile fr_loc_pop
	save `fr_loc_pop'
	restore
	
	* Merge in user_loc population
	merge m:1 fr_loc using `fr_loc_pop', keep(3) nogen 
	
* Get county distance

	* Get distance data
	preserve
	import delimited "${input_data}/sf12010countydistancemiles.csv", clear 
	rename (county1 county2) (user_loc fr_loc)
	tempfile distance
	save `distance'
	restore

	* Merge into Washtenaw County data
	merge 1:1 user_loc fr_loc using `distance', keep(3) nogen
	
* Get estimate of number of Facebook friendships (in billions between every county-pair
gen friendships = (scaled_sci * user_population * fr_population) / 1000000000 

* Get the total number of Facebook friends for each user county
bysort user_loc: egen total_friendships = total(friendships)

* Create indicator variables for distance
gen within_50mi = mi_to_county <= 50
gen within_100mi = mi_to_county <= 100

* Get the number of friendships within 50 and 100 miles
gen friendships_within_50mi = friendships * within_50mi
gen friendships_within_100mi = friendships * within_100mi

* Collapse to the county-level
collapse (sum) friendships_within_*  (max) total_friendships (first) county_name state_name, by(user_loc)

* Sanity check: make sure there 50 mi < 100mi < total 
assert friendships_within_50mi <= friendships_within_100mi <= total_friendships

* Create share of friendships variables
foreach var in 50mi 100mi{
	gen share_connections_`var' = 100*(friendships_within_`var' / total_friendships)
}

* Save Temporary Dataset for Ease 
save "${temp_data}/exer2 temp", replace

*----------------------------------------
* Summarize Data on Social Connectedness
*----------------------------------------

* Use Temporary Dataset for Ease 
use "${temp_data}/exer2 temp", clear

* Summarize 
sum share_connections_*

* Get Washtenaw rank in within_100mi distribution nationally and within Michigan 

	* Create Rank variable
	egen rank_100mi = rank(-share_connections_100mi)
	egen rank_100mi_within_state = rank(-share_connections_100mi), by(state_name)
	
	* Save rank in locals
		
		* National rank 
		
			* Get Number of Counties Nationally
			unique user_loc
			local num_counties = `r(unique)'
			
			* Get Washtenaw rank
			su rank_100mi if user_loc == 26161
			local wt_nat_rank = `r(mean)'
			di in red "Washtenaw, MI friendship within 100mi rank in Natl distribution = " `wt_nat_rank' " out of " `num_counties' " counties nationally "
		


		* Within-State rank
		
			* Get Number of Counties Nationally
			unique user_loc if state_name == "Michigan"
			local num_counties_mi = `r(unique)'
			
			* Get Washtenaw rank
			su rank_100mi_within_state if user_loc == 26161
			local wt_st_rank = `r(mean)'
			di in red "Washtenaw, MI friendship within 100mi rank in Michigan distribution = " `wt_st_rank'	" out of " `num_counties_mi' " counties in Michigan "
			
* Get Washtenaw share 
su share_connections_100mi if user_loc == 26161
local wt_share = `r(mean)'

* Create Histograms for within 100mi (adding Washtenaw ranks as captions)

	* National histogram
	tw ///
	(histogram share_connections_100mi, frequency color(ltblue)) ///
	(scatteri 250 `wt_share' 0 `wt_share' , connect(direct) msymbol(i) lcolor(gs8) lpattern(dash)) ///
	, ///
	xtitle("Share Friendships Within 100 Miles") ///
	ytitle("Count") ///
	ylabel(,nogrid) ///
	caption("Wastenaw, MI Rank in Natl Distribution: `wt_nat_rank' of out `num_counties' counties") ///
	legend(off) ///
	text(260 `=`wt_share'' "Washtenaw County")
	graph export "${output}/histogram within 100 miles national.png", replace
	
	* National histogram
	tw ///
	(histogram share_connections_100mi if state_name == "Michigan", frequency color(ltblue)) ///
	(scatteri 20 `wt_share' 0 `wt_share' , connect(direct) msymbol(i) lcolor(gs8) lpattern(dash)) ///
	, ///
	xtitle("Share Friendships Within 100 Miles") ///
	ytitle("Count") ///
	ylabel(,nogrid) ///
	caption("Wastenaw, MI Rank in Michigan Distribution: `wt_st_rank' of out `num_counties_mi' counties") ///
	legend(off) ///
	text(21 `=`wt_share'' "Washtenaw County")
	graph export "${output}/histogram within 100 miles state.png", replace
	
*--------------------------------------------------------
* See relationship in friendships vs other variables
*--------------------------------------------------------

* Get other variables (lets grab median income, upward mobility, and life-expectancy of Q1 (poor) men)

	* Create covariates tempfile
	preserve
	import delimited "${input_data}/county_demographics.csv",clear
	keep if inlist(measure, "median_hh_income", "e_rank_b", "le_agg_q1_m")
	replace value = "" if value == "NA"
	destring value, replace
	rename value val_ 
		* Reshape (data is currently long -- we want wide)
		reshape wide val_, i(county_fips) j(measure) string
		rename (val_median_hh_income val_e_rank_b val_le_agg_q1_m) (med_inc mobility life_exp)
		rename county_fips user_loc
	tempfile covariates
	save `covariates'
	restore
	
	* Merge
	merge 1:1 user_loc using `covariates', nogen keep(1 3)
	
* Make Binscatters
foreach var in med_inc mobility life_exp { //mobility life_exp
	
	* Regressions (with and without fixed-effects)
	reg `var' share_connections_100mi
	local coef = round(_b[share_connections_100mi],0.0001)
	local coef: di %4.3f `coef'
	reg `var' share_connections_100mi, absorb(state_name)
	local coef_fe = round(_b[share_connections_100mi],0.0001)
	local coef_fe: di %4.3f `coef_fe'
	
	* Useful locals for titles
	if "`var'" == "med_inc" local title "Median HH Income"
	if "`var'" == "mobility" local title "Upward Mobility"
	if "`var'" == "life_exp" local title "Q1 Men Life Expectancy"
	
	* Figure
	binscatter `var' share_connections_100mi ///
	, ///
	nquantiles(30) ///
	linetype(qfit) ///
	ytitle(`title') ///
	xtitle("Share of Friends within 100 miles") ///
	ylabel(,nogrid) ///
	caption("Coef. = `coef'" "Coef. (State FEs) = `coef_fe'")
	graph export "${output}/binscatter friendships 100mi to `var'.png", replace

}






