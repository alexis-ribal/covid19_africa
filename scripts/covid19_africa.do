/*==================================================
Project:       	Reported COVID-19 cases in Africa

Output:			Figures showing the evolution of the pandemic in the Africa region 
				(with a focus on sub-Saharan African countries)
				
Author:        	Alexis Rivera Ballesteros
E-email:       	ariveraballester@worldbank.org

----------------------------------------------------
Creation Date:	Mar 1, 2020
Latest update: Sep 8, 2020           
==================================================*/


/*==================================================
						SUMMARY
==================================================*/

/*
		Cleaning:
		
		0: Global set up
		1: Import and clean latest update from Johns Hopkins Github repository
		2: Extract population data and region classification from WB Open Data API
		3: Merge JHU data with World Bank population and regions
		
		
		Charts:
		
		Chart 1: Reported COVID-19 cases by region
		Chart 2: Reported COVID-19 cases per million people by region
		Chart 3: Cumulative reported cases map
		Chart 4: Bar chart of COVID-19 cases by country
		Chart 5: Reported cases line chart by country
		Chart 6: Chart showing daily COVID-19 cases in South Africa and the rest of Africa

*/


/*==================================================
              0: Global set up
==================================================*/


	global projectfolder = "/Users/alexis_pro/Documents/GitHub/covid19_africa"
	*global projectfolder = 
	

/*====================================================================================
              1: Import and clean latest update from Johns Hopkins Github repository
==================================================================================*/	
	
	
	import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv", clear varnames(nonames)
	drop v1 v3 v4
	rename v2 country
	drop if _n==1

	foreach var of varlist v*{
		destring `var', replace
	}

	collapse (sum) v*, by(country)

	reshape long v, i(country) j(time)

	gen date = date("22jan2020", "DMY") if time == 5
	replace date = date[_n-1]+1 if missing(date)

	format date %td
	
	rename v confirmed
	drop time
		

	replace country = "Brunei Darussalam" if country == "Brunei"
	replace country = "Myanmar" if country == "Burma"
	replace country = "Congo, Rep" if country == "Congo (Brazzaville)"
	replace country = "Congo, Dem Rep" if country == "Congo (Kinshasa)"
	replace country = "Czech Republic" if country == "Czechia"
	replace country = "Egypt, Arab Rep" if country == "Egypt"
	replace country = "Gambia, The" if country == "Gambia"
	replace country = "Iran, Islamic Rep" if country == "Iran"
	replace country = "Korea, Rep" if country == "Korea, South"
	replace country = "Kyrgyz Republic" if country == "Kyrgyzstan"
	replace country = "Lao PDR" if country == "Laos"
	replace country = "Russian Federation" if country == "Russia"
	replace country = "Slovak Republic" if country == "Slovakia"
	replace country = "Syrian Arab Republic" if country == "Syria"
	replace country = "United States" if country == "US"
	replace country = "Venezuela, RB" if country == "Venezuela"
	replace country = "Yemen, Rep" if country == "Yemen"
	replace country = "Bahamas, The" if country == "Bahamas"
	
	save "$projectfolder/data/coronavirus_jhu_reported_raw.dta", replace
	
	
	
/*====================================================================================
              2: Extract population data and region classification from WB Open Data API
==================================================================================*/

	wbopendata, indicator(SP.POP.TOTL) long latest clear
	
	rename countrycode iso3
	rename countryname country
	
	drop year
	rename sp_pop_totl pop
	
	save "$projectfolder/data/regions_panel.dta", replace
	

	
/*====================================================================================
              3: Merge JHU data with World Bank population and regions
==================================================================================*/	
	
	use "$projectfolder/data/coronavirus_jhu_reported_raw.dta", clear
	
	merge m:1 country using "$projectfolder/data/regions_panel.dta"
	
	drop if _merge==1 | _merge==2
	
	drop _merge
	
	sort iso3 date
	
	gen first_case = 1 if confirmed>0 & confirmed[_n-1] == 0
	replace first_case=first_case[_n-1] if first_case==. & iso3==iso3[_n-1]
	
	
	foreach var of varlist region-lendingtypename{
		replace `var' = `var'[_n-1] if missing(`var') & iso3 == "ZWE"
	}
	
	replace first_case = 1 if iso3 == "CHN" | iso3 == "USA" | iso3 == "KOR"

	bysort iso3 (date): gen confirmed_days=sum(first_case)
		

	save "$projectfolder/data/coronavirus_jhu_reported.dta", replace
	
	


/*====================================================================================
              Chart 1: Reported COVID-19 cases by region
==================================================================================*/


	use "$projectfolder/data/coronavirus_jhu_reported.dta", clear


	collapse (sum) confirmed, by(regionname date)
	
	drop if date == .

	gen latest = regionname != regionname[_n+1]

	gen ln_confirmed_cumu = asinh(confirmed)


	gen first_case = 1 if confirmed>0 & confirmed[_n-1] == 0
	replace first_case=first_case[_n-1] if first_case==. & regionname==regionname[_n-1]

	replace first_case = 1 if regionname == "East Asia and Pacific" | regionname == "North America"

	bysort regionname (date): gen confirmed_days=sum(first_case)
	
	gen ln_confirmed = ln(confirmed)
	
	
	tw lowess ln_confirmed confirmed_days if regionname == "Sub-Saharan Africa", bwidth(.2) lcolor("222 110 75") lwidth(1) || ///
	lowess ln_confirmed confirmed_days if regionname == "North America", bwidth(.2) lcolor("47 131 150") || ///
	lowess ln_confirmed confirmed_days if regionname == "Europe and Central Asia", bwidth(.2) lcolor("202 202 170") || ///
	lowess ln_confirmed confirmed_days if regionname == "East Asia and Pacific", bwidth(.2) lcolor("127 209 186") || ///
	lowess ln_confirmed confirmed_days if regionname == "South Asia", bwidth(.2) lcolor("122 101 99") || ///
	lowess ln_confirmed confirmed_days if regionname == "Middle East and North Africa", bwidth(.2) lcolor("33 69 91") || ///
	lowess ln_confirmed confirmed_days if regionname == "Latin America and Caribbean", bwidth(.2) lcolor("180 130 130") || ///
	scatter ln_confirmed confirmed_days if regionname == "Sub-Saharan Africa" & latest==1, mlab(regionname) mcolor("222 110 75") mlabcolor("222 110 75") mlabsize(vsmall) mlabpos(6) || ///
	scatter ln_confirmed confirmed_days if regionname == "North America" & latest==1, mlab(regionname) mcolor("47 131 150") mlabcolor("47 131 150") mlabsize(vsmall) mlabpos(2) || ///
	scatter ln_confirmed confirmed_days if regionname == "Europe and Central Asia" & latest==1, mlab(regionname) mcolor("202 202 170") mlabcolor("202 202 170") mlabsize(vsmall) mlabpos(4) || ///
	scatter ln_confirmed confirmed_days if regionname == "East Asia and Pacific" & latest==1, mlab(regionname) mcolor("127 209 186") mlabcolor("127 209 186") mlabsize(vsmall) || ///
	scatter ln_confirmed confirmed_days if regionname == "South Asia" & latest==1, mlab(regionname) mcolor("122 101 99") mlabcolor("122 101 99") mlabsize(vsmall) mlabpos(3)  || ///
	scatter ln_confirmed confirmed_days if regionname == "Middle East and North Africa" & latest==1, mlab(regionname) mcolor("33 69 91") mlabcolor("33 69 91") mlabsize(vsmall) mlabpos(3) || ///
	scatter ln_confirmed confirmed_days if regionname == "Latin America and Caribbean" & latest==1, mlab(regionname) mcolor("180 130 130") mlabcolor("180 130 130") mlabsize(vsmall) mlabpos(12) ///
	tlab(0(10)280, labsize(vsmall)) legend(off) graphregion(color(white)) bgcolor(white) ylab(2.3 "10" 4.6 "100" 6.9 "1K" 9.2 "10K" 11.51 "100K" 13.82 "1M" 16.12 "10M", labsize(vsmall)) ///
	ttitle("Days since first case reported in each region --->", size(small)) ytitle("Total reported cases (log scale)" " ", size(small)) ///
	title("Reported cases of COVID-19 in sub-Saharan Africa is following" "a similar trajectory to other regions, but with a delayed start." " ", size(medium) position(11) span) ///
	note("{bf:Note}: Groups of countries by World Bank geographical region: sub-Saharan Africa (48), North America (2), Europe & Central Asia (49)," ///
	"East Asia & Pacific (29), South Asia (8), Middle East & North Africa (21) and Latin America (26)." "The chart shows reported numbers. Limited testing in sub-Saharan African countries could result in underreporting." ///
	"{bf:Source}: own elaboration using CSSE at Johns Hopkins University data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall) span)	

	
	
	graph export "$projectfolder/charts/regions_cumu.png", replace	
	
	


	
	
/*====================================================================================
              Chart 2: Reported COVID-19 cases per million people by region
==================================================================================*/


	use "$projectfolder/data/coronavirus_jhu_reported.dta", clear


	collapse (sum) confirmed (sum) pop, by(regionname date)
	
	gen confirmed_pc = confirmed/(pop/1000000)
	
	drop if date == .

	gen latest = regionname != regionname[_n+1]


	gen first_case = 1 if confirmed>0 & confirmed[_n-1] == 0
	replace first_case=first_case[_n-1] if first_case==. & regionname==regionname[_n-1]

	replace first_case = 1 if regionname == "East Asia and Pacific" | regionname == "North America"

	bysort regionname (date): gen confirmed_days=sum(first_case)
	
	gen ln_confirmedpc = ln(confirmed_pc)
	
	
	tw lowess ln_confirmedpc confirmed_days if regionname == "Sub-Saharan Africa", bwidth(.2) lcolor("222 110 75") lwidth(1) || ///
	lowess ln_confirmedpc confirmed_days if regionname == "North America", bwidth(.2) lcolor("47 131 150") || ///
	lowess ln_confirmedpc confirmed_days if regionname == "Europe and Central Asia", bwidth(.2) lcolor("202 202 170") || ///
	lowess ln_confirmedpc confirmed_days if regionname == "East Asia and Pacific", bwidth(.2) lcolor("127 209 186") || ///
	lowess ln_confirmedpc confirmed_days if regionname == "South Asia", bwidth(.2) lcolor("122 101 99") || ///
	lowess ln_confirmedpc confirmed_days if regionname == "Middle East and North Africa", bwidth(.2) lcolor("33 69 91") || ///
	lowess ln_confirmedpc confirmed_days if regionname == "Latin America and Caribbean", bwidth(.2) lcolor("180 130 130") || ///
	scatter ln_confirmedpc confirmed_days if regionname == "Sub-Saharan Africa" & latest==1, mlab(regionname) mcolor("222 110 75") mlabcolor("222 110 75") mlabsize(vsmall) || ///
	scatter ln_confirmedpc confirmed_days if regionname == "North America" & latest==1, mlab(regionname) mcolor("47 131 150") mlabcolor("47 131 150") mlabsize(vsmall) mlabpos(3) || ///
	scatter ln_confirmedpc confirmed_days if regionname == "Europe and Central Asia" & latest==1, mlab(regionname) mcolor("202 202 170") mlabcolor("202 202 170") mlabsize(vsmall) mlabpos(2) || ///
	scatter ln_confirmedpc confirmed_days if regionname == "East Asia and Pacific" & latest==1, mlab(regionname) mcolor("127 209 186") mlabcolor("127 209 186") mlabsize(vsmall) || ///
	scatter ln_confirmedpc confirmed_days if regionname == "South Asia" & latest==1, mlab(regionname) mcolor("122 101 99") mlabcolor("122 101 99") mlabsize(vsmall) mlabpos(3)  || ///
	scatter ln_confirmedpc confirmed_days if regionname == "Middle East and North Africa" & latest==1, mlab(regionname) mcolor("33 69 91") mlabcolor("33 69 91") mlabsize(vsmall) mlabpos(3) || ///
	scatter ln_confirmedpc confirmed_days if regionname == "Latin America and Caribbean" & latest==1, mlab(regionname) mcolor("180 130 130") mlabcolor("180 130 130") mlabsize(vsmall) mlabpos(12) ///
	tlab(0(10)280, labsize(vsmall)) legend(off) graphregion(color(white)) bgcolor(white) ylab(-6.9 "0.001" -4.6 "0.01" -2.3 "0.1" 0 "1" 2.3 "10" 4.6 "100" 6.9 "1K" 9.2 "10K", labsize(vsmall)) ///
	ttitle("Days since first case reported in each region --->", size(small)) ytitle("Total reported cases per million people (log scale)" " ", size(small)) ///
	title("Reported COVID-19 cases per million people in sub-Saharan Africa are higher" "than East Asia & Pacific and increasing more rapidly." " ", size(medium) position(11) span) ///
	note("{bf:Note}: Groups of countries by World Bank geographical region: sub-Saharan Africa (48), North America (2), Europe & Central Asia (49)," ///
	"East Asia & Pacific (29), South Asia (8), Middle East & North Africa (21) and Latin America (26)." "The chart shows reported numbers. Limited testing in sub-Saharan African countries could result in underreporting." ///
	"{bf:Source}: own elaboration using CSSE at Johns Hopkins University and World Bank data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall) span)	

	
	
	graph export "$projectfolder/charts/regions_pc_cumu.png", replace	
	
		
	
/*====================================================================================
              Chart 3: Cumulative reported cases map
==================================================================================*/

* cumulative reported cases africa map


	use "$projectfolder/data/coronavirus_jhu_reported.dta", clear

	sort iso3 date

	gen latest = iso3 != iso3[_n+1]

	keep if latest==1

	merge 1:1 iso3 using "$projectfolder/data/world.dta"

	drop _merge

	keep if regionname=="Sub-Saharan Africa" | iso3 == "ESH" | iso3 == "MAR" | iso3 == "DZA" | iso3 == "LBY" | iso3 == "TUN" | iso3 == "EGY" | iso3 == "LSO" | iso3 == "MWI" | iso3 == "SSD" | iso3 == "STP" | iso3 == "DJI"

	gen ln_cum_conf = asinh(confirmed)

	gen africa_map = 1 if ln_cum_conf > 12.2 & ln_cum_conf !=.
	replace africa_map = 2 if ln_cum_conf > 9.9 & ln_cum_conf <= 12.2
	replace africa_map = 3 if ln_cum_conf > 7.6 & ln_cum_conf <=9.9
	replace africa_map = 4 if ln_cum_conf > 5.3 & ln_cum_conf <=7.6
	replace africa_map = 5 if ln_cum_conf== . | ln_cum_conf <= 5.3


	label define map 1 "More than 100,000" 2 "10,000-100,000" 3 "1,000-10,000" 4 "101-1,000" 5 "No data" 

	label values africa_map map
	

	spmap africa_map using "$projectfolder/data/worldcoord.dta", ///
	id(id) fcolor ("222 110 75*1.4" "222 110 75*1" "222 110 75*0.6" "222 110 75*0.2" gs13) clmethod(unique) legend(size(medium)) title("Reported cases of COVID-19 in Africa.", size(medium) position(11)) ///
	subtitle("After five months since the first case was reported in the region," "only South Africa and Egypt have crossed the 100,000 reported COVID-19 cases.", size(small) position(11) span) ///
	note("{bf:Note}: Limited testing in sub-Saharan African countries could result in underreporting." ///
	"{bf:Source}: own elaboration using CSSE at Johns Hopkins University data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall))	///
	legend(size(small))

	graph export "$projectfolder/maps/africa_cumu_map.png", replace
	

	
	
/*====================================================================================
              Chart 4: Bar chart of COVID-19 cases by country
==================================================================================*/	
	

	use "$projectfolder/data/coronavirus_jhu_reported.dta", clear
	
	gen latest = iso3 != iso3[_n+1]
	

	keep if latest==1

	keep if regionname == "Sub-Saharan Africa"
	
	format confirmed %12.0fc
	
	count if confirmed >=1000
	count if confirmed >=5000
	
	graph hbar confirmed if confirmed!= . & confirmed >= 1000 & iso3 != "ZAF", over(country, sort(confirmed) descending label(labsize(tiny))) blabel(total, size(tiny) format(%12.0fc)) bar(1, fcolor("33 69 91"))  ///
	graphregion(color(white)) bgcolor(white) ytitle("Total reported cases") ylab(,labsize(small)) ylab(0 "0" 10e3 "10K" 20e3 "20K" 30e3 "30K" 40e3 "40K" 50e3 "50K" 60e3 "60K") ///
	title("According to the latest reports, 41 sub-Saharan African countries already" "reported more than 1,000 people with COVID-19." " ", size(medium) position(11) span) ///
	note("{bf:Note}: Only displaying countries with more than 1,000 reported excluding South Africa. The chart shows reported numbers." "Limited testing in sub-Saharan African countries could result in underreporting." "{bf:Source}: own elaboration using CSSE at Johns Hopkins University data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall) span)	
	
	
	graph export "$projectfolder/charts/confirmed_bar.png", replace

	
	
/*====================================================================================
              Chart 5: Reported cases line chart by country
==================================================================================*/												


	use "$projectfolder/data/coronavirus_jhu_reported.dta", clear

	keep if regionname == "Sub-Saharan Africa" | iso3 == "USA" | iso3 == "KOR" | iso3 == "CHN" | iso3 == "ITA" | iso3 == "BRA" | iso3 == "IND"
	
	replace country = "DRC" if iso3 == "COD"
	
	gen latest = iso3 != iso3[_n+1]

	gen ln_confirmed_cumu = ln(confirmed)

	tab country if latest==1, sum(confirmed)											
	
	format confirmed %12.0fc

	
	
	tw lowess ln_confirmed_cumu confirmed_days if iso3 == "USA", bwidth(.4) lcolor(gs12) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "KOR", bwidth(.4) lcolor(gs12) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "ITA", bwidth(.4) lcolor(gs12) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "BRA", bwidth(.4) lcolor(gs12) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "CHN", bwidth(.4) lcolor(gs12) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "IND", bwidth(.4) lcolor(gs12) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "GIN", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "NER", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "BFA", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "MUS", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "SOM", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "MLI", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "TZA", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "COG", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "SDN", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "GAB", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "RWA", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "MDG", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "LBR", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "TGO", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "GNQ", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "CPV", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "ZMB", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "UGA", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "SLE", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "BEN", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "GNB", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "MOZ", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "ERI", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "MWI", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "TCD", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "SWZ", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "ZWE", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "BWA", bwidth(.1) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "NAM", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "CAF", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "SYC", bwidth(.1) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "BDI", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "GMB", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "MRT", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "SSD", bwidth(.4) lcolor(gs14) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "STP", bwidth(.4) lcolor(gs14) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "GIN" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "NER" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "BFA" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "MUS" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "SOM" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "MLI" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "TZA" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "COG" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "SDN" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "GAB" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "RWA" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "MDG" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "LBR" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "TGO" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "GNQ" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "CPV" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "ZMB" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "UGA" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "SLE" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "BEN" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "GNB" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "MOZ" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "ERI" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "MWI" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "TCD" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "SWZ" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "ZWE" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "BWA" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "NAM" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "CAF" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "SYC" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "BDI" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "GMB" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "MRT" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "SSD" & latest==1, mcolor(gs14) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "STP" & latest==1, mcolor(gs14) msize(vsmall) || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "CIV", bwidth(.2) lcolor("222 110 75") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "ZAF", bwidth(.2) lcolor("122 101 99") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "GHA", bwidth(.2) lcolor("47 131 150") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "CMR", bwidth(.2) lcolor("33 69 91") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "NGA", bwidth(.2) lcolor("108 145 150") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "AGO", bwidth(.2) lcolor("180 130 130") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "COD", bwidth(.2) lcolor("144 201 120") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "ETH", bwidth(.2) lcolor("254 107 100") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "KEN", bwidth(.2) lcolor("149 125 173") || ///
	lowess ln_confirmed_cumu confirmed_days if iso3 == "SEN", bwidth(.2) lcolor("246 146 188") legend(off) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "CIV" & latest==1, mlab(country) mcolor("222 110 75") mlabcolor("222 110 75") mlabpos(8) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "ZAF" & latest==1, mlab(country) mcolor("122 101 99") mlabcolor("122 101 99")  mlabpos(12) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "GHA" & latest==1, mlab(country) mcolor("47 131 150") mlabcolor("47 131 150") mlabpos(3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "CMR" & latest==1, mlab(country) mcolor("33 69 91") mlabcolor("33 69 91")  mlabpos(3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "NGA" & latest==1, mlab(country) mcolor("108 145 150") mlabcolor("108 145 150")  mlabpos(3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "AGO" & latest==1, mlab(country) mcolor("180 130 130") mlabcolor("180 130 130") mlabpos(3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "COD" & latest==1, mlab(country) mcolor("144 201 120") mlabcolor("144 201 120")  mlabpos(3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "ETH" & latest==1, mlab(country) mcolor("254 107 100") mlabcolor("254 107 100") mlabpos(1) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "KEN" & latest==1, mlab(country) mcolor("149 125 173") mlabcolor("149 125 173")  mlabpos(3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "SEN" & latest==1, mlab(country) mcolor("246 146 188") mlabcolor("246 146 188")  mlabpos(3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "USA" & latest==1, mlab(country) mcolor(gs12) mlabcolor(gs10) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "KOR" & latest==1, mlab(country) mcolor(gs12) mlabcolor(gs10) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "ITA" & latest==1, mlab(country) mlabpos(4) mcolor(gs12) mlabcolor(gs10) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "CHN" & latest==1, mlab(country) mcolor(gs12) mlabcolor(gs10) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "BRA" & latest==1, mlab(country) mcolor(gs12) mlabcolor(gs10) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "IND" & latest==1, mlab(country) mcolor(gs12) mlabcolor(gs10) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "CIV" & latest==1, mlab(confirmed) mcolor("222 110 75") mlabcolor("222 110 75") mlabpos(8) mlabsize(tiny) mlabgap(*8) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "ZAF" & latest==1, mlab(confirmed) mcolor("122 101 99") mlabcolor("122 101 99")  mlabpos(12) mlabgap(*3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "GHA" & latest==1, mlab(confirmed) mcolor("47 131 150") mlabcolor("47 131 150") mlabpos(3) mlabgap(*8) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "CMR" & latest==1, mlab(confirmed) mcolor("33 69 91") mlabcolor("33 69 91")  mlabpos(3) mlabgap(*11) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "NGA" & latest==1, mlab(confirmed) mcolor("108 145 150") mlabcolor("108 145 150")  mlabpos(3) mlabgap(*8) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "AGO" & latest==1, mlab(confirmed) mcolor("180 130 130") mlabcolor("180 130 130") mlabpos(3) mlabgap(*8) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "COD" & latest==1, mlab(confirmed) mcolor("144 201 120") mlabcolor("144 201 120") mlabpos(3) mlabgap(*8) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "ETH" & latest==1, mlab(confirmed) mcolor("254 107 100") mlabcolor("254 107 100") mlabpos(1) mlabgap(*3) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "KEN" & latest==1, mlab(confirmed) mcolor("149 125 173") mlabcolor("149 125 173") mlabpos(3) mlabgap(*9) mlabsize(tiny) msize(vsmall) || ///
	scatter ln_confirmed_cumu confirmed_days if iso3 == "SEN" & latest==1, mlab(confirmed) mcolor("246 146 188") mlabcolor("246 146 188") mlabpos(3) mlabgap(*11) mlabsize(tiny) msize(vsmall) ///
	ttitle("Days since first case reported by country --->", size(small)) ytitle("Total reported cases (log scale)", size(small)) ylab(2.3 "10" 4.6 "100" 6.9 "1K" 9.21 "10K" 11.51 "100K" 13.81 "1M" 16.8 "10M", labsize(vsmall)) ///
	graphregion(color(white)) bgcolor(white) title("Sub-Saharan African countries vary significantly in the current number" "of confirmed cases, but numbers continue rising steeply.", position(11) span size(medium)) tlab(0(10)250, labsize(vsmall)) ///
	subtitle("Some have quickly crossed 1,000 cases, while others lag behind possibly due to limited testing capacity." " ", position(11) span size(small) color("33 69 91")) ///
	note("{bf:Note}: Ten selected large sub-Saharan African countries are indicated by name. All remaining sub-Saharan African countries shown in grey." ///
	"The chart shows reported numbers.  Limited testing in sub-Saharan African countries could result in underreporting." ///
	"{bf:Source}: own elaboration using CSSE at Johns Hopkins University data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall) span)	

		
	
	
	graph export "$projectfolder/charts/countries_cumu_allssa.png", replace	
		

		
		
		
/*====================================================================================
              Chart 6: Chart showing daily COVID-19 cases in South Africa and the rest of Africca
==================================================================================*/
	

	
	use "$projectfolder/data/coronavirus_jhu_reported.dta", clear

	gen group = 1 if regionname == "Sub-Saharan Africa" & iso3 != "ZAF"
	replace group = 2 if iso3 == "ZAF"	
	
	collapse (sum) confirmed, by(group date)
	
	
	drop if date == .

	gen latest = group != group[_n+1]
	
	gen new_confirmed = confirmed - confirmed[_n-1] if group == group[_n-1]
	
	gen new_confirmed_pct = (new_confirmed/confirmed[_n-1])*100 if  group == group[_n-1] 
	
	
	gen label = string(date, "%tdd-m") 
	labmask date, values(label) 
	
	bysort group : gen daycount = _n
	
	gen threemonths = daycount-90 if latest==1
	bysort group(threemonths) : replace threemonths = threemonths[_n-1] if missing(threemonths)
	
	gsort group date
	
	keep if daycount>=threemonths
	
	keep date group label new_confirmed
	
	reshape wide new_confirmed, i(date label) j(group)
	
	gen new_confirmed_total = new_confirmed1+new_confirmed2
	
	gen new_confirmed_zaf = new_confirmed2/new_confirmed_total
	
	graph bar new_confirmed2 new_confirmed1,  over(date, label(labsize(tiny) angle(90))) stack ///
	ytitle("Total reported cases") graphregion(color(white)) bgcolor(white) ///
	title("Daily new COVID-19 reported cases in sub-Saharan Africa (last 3 months)", size(medium)) ///
	legend(cols(2) order(1 "South Africa" 2 "Rest of sub-Saharan Africa")) bar(1, color("222 110 75")) bar(2, color("108 145 150")) ///
	note("{bf:Note}: Limited testing in sub-Saharan African countries could result in underreporting." "{bf:Source}: own elaboration using CSSE at Johns Hopkins University data.  Accessed on $S_DATE {bf:CC BY}", size(vsmall) span)	

	graph export "$projectfolder/charts/new_daily_cases.png", replace	

	
	
*** end of do-file		
	
		
