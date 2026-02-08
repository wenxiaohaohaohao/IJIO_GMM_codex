/*	Market Structure, Oligopsony Power, and Productivity
					(Michael Rubens, UCLA)

	- MAPS - */
 
cd "$station"
set more off
 	
use ./data/china_tobacco_data, clear

gen nf = emp>0
drop if nf==0 | nf==. | _y==. | _x==.
bys _x _y yr: egen nfco=sum(nf)

tab nfco if yr==1999
tab nfco if yr==2006

collapse nfco province_id , by(_y _x yr)

tab nfco if yr==1999
tab nfco if yr==2006

forvalues y = 1999(7)2006 {
preserve
keep if yr==`y'
rename (_y _x) (_Y _X)
save ./tempfiles/china_tobacco_maps`y', replace
restore
}
* Shapefiles province level 

*shp2dta using .\shapefiles\CHN_adm2.shp, database(.\shapefiles\CHN_adm2) coord(.\shapefiles\cncoord_zip2)
*use .\shapefiles\cndb, clear

ssc install spmap	

*shp2dta using .\shapefiles\chn_admbnda_adm1_ocha_2020.shp, database(.\shapefiles\chn_admbnda_adm1_ocha_2020) coord(.\shapefiles\cncoord_zip1_taiwan)

* use .\shapefiles\CHN_adm1, clear		
use ./data/shapefiles/chn_admbnda_adm1_ocha_2020, clear
  
spmap using ./data/shapefiles/cncoord_zip1_taiwan, id(_ID) ocolor(black) osize(vthin) point(data(./tempfiles/china_tobacco_maps1999)   x(_X) y(_Y)   fcolor(red red) size(small small)  shape(diamond)  ocolor(black black)  legenda(off) leglabel("Manufacturing location" )   )  ndocolor(ebg) legend(size(large)) 
*spmap using .\shapefiles\cncoord_zip1, id(id) ocolor(black) osize(vthin) point(data(.\china_tobacco_maps1999)   x(_X) y(_Y)   fcolor(red red) size(small small)  shape(diamond)  ocolor(black black)  legenda(off) leglabel("County with cigarette firm(s)" )   )  ndocolor(ebg) legend(size(large)) 
graph export "/Users/MichaelRubens/Dropbox/China tobacco/paper/aer_2021_0383/figures/Figure1b.pdf", replace
 
spmap using ./data/shapefiles/cncoord_zip1_taiwan, id(_ID) ocolor(black) osize(vthin) point(data(./tempfiles/china_tobacco_maps2006)   x(_X) y(_Y)    fcolor(red red) size(small small)  shape(diamond)  ocolor(black black)  legenda(on) leglabel("Manufacturing location" )   )  legend(size(large)) 
graph export "/Users/MichaelRubens/Dropbox/China tobacco/paper/aer_2021_0383/figures/Figure1c.pdf", replace
  
exit
 