/*	"Market structure, oligopsony, and productivity"
			(Michael Rubens, UCLA)
 
=================================================================================*/

global station = "D:\文章发表\欣昊\input markdown\IJIO\学习材料\rubens AER\186041-V1"		// change to your own directory
cd "$station"
set more off
 
 timer clear
timer on 1		

 

global B =  200      	// set # bootstrap iterations"

* 1. load data and reduced-form results

do  ./main/china_tobacco_data				// compiles dataset & cleans the data
 
do  ./main/china_tobacco_reducedform		// generates Figure 2, Figure 3, Figure A1, Table A3, Table A12
  
* 2. model in the main text
 
do  ./main/china_tobacco_baseline			// generates   Table 1,  Table 2, Table 3, Figure 4, Table A11, Figure A2

* 3. models in the appendices

do  ./appendix/china_tobacco_ap_nestedlogit	// generates Table A1

do  ./appendix/china_tobacco_ap_nestedlogit_bis // generates Table A2
 
do  ./appendix/china_tobacco_ap_acf			// generates Table A4 

do  ./appendix/china_tobacco_ap_substit		// generates Table A5, Table A6
 
do  ./appendix/china_tobacco_ap_robchecks		// generates Table A7, Table A8, Table A9, Table A10

* 4. maps

do  ./main/china_tobacco_maps				// generates the maps in Figure 1

timer off 1
 timer list 1
 di `"program has ended"'


 exit

  
