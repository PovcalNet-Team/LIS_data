/*==================================================
project:       Organize output from LISSY
Author:        R.Andres Castaneda Aguilar 
E-email:       acastanedaa@worldbank.org
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    11 Dec 2019 - 20:55:47
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
0: Program set up
==================================================*/
*##s
* version 14
discard
clear all

//------------modify this
*local dir "c:\Users\wb384996\OneDrive - WBG\temp\04.LIS\"

local dir "p:/01.PovcalNet/04.LIS"
local dir "c:/Users/wb384996/OneDrive - WBG/WorldBank/DECDG/PovcalNet Team/LIS_data"
cd "`dir'"

local files: dir "00.LIS_output/" files "LISSY_Jan2020_*.txt"
local files: dir "00.LIS_output/" files "test*.txt"
* local files = "test2.txt"
disp `"`files'"'

* local files = `"test3.txt"'

//------------do NOT modify this
mata: mata clear

* data with survey name
use "02.data/_aux/LIS_survname.dta", clear
tostring _all, force replace
putmata LIS = (*), replace


local f = 0
foreach file of local files {
	local ++f
	
	global fn = "`dir'/00.LIS_output/`file'"
	
	local A: word `f' of `c(ALPHA)'
	local l: word `f' of `c(alpha)'
	
	//========================================================
	// extrac vectors into Associative Array
	//========================================================
	
	qui do "01.programs/lis_functions.mata"	
	mata: `l' = lis_set()
	mata: `A' = lis_iter(`l') 
	
	//========================================================
	// convert to dta and place in corresponding folder
	//========================================================
	
	local go = 1
	local i = 0
	qui while (`go' == 1) {
		local ++i
		
		//------------ convert to local from AA
		cap mata: st_local("id", `A'.get((`i',1)))
		if (_rc != 0 | wordcount("`id'") != 3) {
			continue, break
		} 
		
		//------------ get info 
		
		local ccode: word 1 of `id'
		local year:  word 2 of `id'
		local wave:  word 3 of `id'
		
		if (length("`wave'") == 1) {
			local wave = "0" + "`wave'"
		}
		
		mata: lis_metadata(LIS, "`ccode'", "`year'")
		
		//------------ create country/year folders
		
		qui disp _n "`ccode' ${ccode} `year' `sacronym' - `sname'" _n
		
		cap mkdir "02.data/`ccode'"
		local cy_dir "`ccode'_`year'_`sacronym'" // country year dir
		cap mkdir "02.data/`ccode'/`cy_dir'"
		
		
		//------------get matrix into dta and save
		drop _all
		mata: T = `A'.get((`i',2))
		getmata (weight welfare min max)=T
		
		char _dta[wave]         "`wave'" 
		char _dta[id]           "`id'"
		char _dta[author]       "`c(username)'"
		char _dta[orig_file]    "`file'"
		char _dta[survey_name]  "`sname'"
		
		
		//------------ check if file exists or if it has changed
		cap datasignature confirm using /* 
		*/ "02.data/`ccode'/`cy_dir'/`cy_dir'", strict
		
		if (_rc == 601) { // file not found
			nois disp in y "file `id' not found. Creating folder with version 01"
			local av = "01"  // alternative version
		} 
		else if (_rc == 9) {  // data have changed
			local vers: dir "02.data/`ccode'/`cy_dir'" dirs "*", respectcase
			
			local avs 0
			foreach ver of local vers {
				if regexm("`ver'", "_v([0-9]+)_A_LIS$") loca v = regexs(1)
				local avs = "`avs', `v'"
			}
			
			local av = max(`avs') + 1
			if (length("`av'") == 1) {
				local av = "0" + "`av'"
			}
		}
		else {
			noi disp in y "File `id' has not changed since last time"
			continue
		}
		
		datasignature set, reset saving("02.data/`ccode'/`cy_dir'/`cy_dir'", replace)
		
		//------------Create versions folders
		local svid "`cy_dir'_v01_M_v`av'_A_LIS"
		cap mkdir "02.data/`ccode'/`cy_dir'/`svid'"
		
		local ddir "02.data/`ccode'/`cy_dir'/`svid'/data" // data dir
		cap mkdir "`ddir'"
		
		
		save "`ddir'/`svid'.dta", replace
	} // end of while loop 
	
} // close loop  `n' = .txt files
*##e

exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:



// F = lis_svid(l)
//G = lis_bins(l)	



