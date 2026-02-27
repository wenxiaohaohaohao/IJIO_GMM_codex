** Weather station matching

// this do-file matches each tobacco firm observation to the nearest weather station.

 
cd "$station"

use ./data/climate/weatherdata, clear
keep station_id station_num station_long station_lat
gen _xs  = substr(station_lat, 1,5)
gen _ys  = substr(station_long, 1,4)


foreach var of varlist _xs _ys {
destring `var', replace
replace `var' = `var'/100
}

save ./data/climate/stationcoord, replace
	
*	use "C:\Users\u0104241\Dropbox\China\data\shapefiles\cncoord_zip3", clear
	use ./data/shapefiles/cncoord_zip3, clear

	collapse _X _Y, by(_ID)

/*	* Map of locations
	spmap using ./data/shapefiles/cncoord_zip3, id(_ID) ocolor(black)  osize(vthin) point(data("stationcoord")   x(_xs) y(_ys) fcolor(blue) ocolor(black) shape(diamond) size(small)  /*by(dnmach)  fcolor(blue red)  shape(circle circle)  ocolor(black black) legtitle("Machines:") legenda(on) proportional(nmach)*/  leglabel(0)) legend(size(large)) title("", size(huge)) name(stationmap,replace)		
	graph export "C:\Users\MichaelRubens\Dropbox\China tobacco\paper\map_weatherstations.png", replace */

use ./data/climate/stationcoord, clear	
gen cons = 1

collapse _xs _ys cons, by(station_num)

reshape wide _x _y, i(cons) j(station_num)

save ./data/climate/stationcoord_long, replace
	
use ./data/coordinates/county_coords, clear
keep zip4 _x _y		// 4 digit zipcode identifies county

*rename (_x _y)(_y _x)

gen cons = 1

merge m:1 cons using  ./data/climate/stationcoord_long, nogen

// 

forvalues n = 1/173 {
gen dist`n' = sqrt((_xs`n'-_x)^2+(_ys`n'-_y)^2)
}

egen mindist = rowmin(dist*)

encode zip4, gen(zip4id)
reshape long _xs _ys dist , i(zip4id) j(station_num)


keep if mindist==dist & mindist~=. & dist~= .

keep zip4id zip4 station_num
save ./data/climate/county_station_matching, replace


