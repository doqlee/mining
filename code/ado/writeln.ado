// Author: Johannes F. Schmieder
// Version: July 2007
// Department of Economics, Columbia University
// Comments and suggestions welcome: jfs2106 {at} columbia.edu

capture program drop writeln
program define writeln
	gettoken file line : 0
	tempname f
	local append append
	capture confirm file `file'
	if _rc!=0 {
		confirm new file `file'
		local append " "
	}
	file open `f' using `file', `append' write
	file write `f' `line' _n
	file close `f'
end

