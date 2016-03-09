#!/usr/bin/tclsh

#Written by           - Ashay Maheshwari
#Called From          - health.sh
#Scripting Language   -   Tcl/Expect
#Version              -   8.1


set path "/usr/local/software"

set systemTime [clock seconds]
set date [clock format $systemTime -format %Y%m%d]
set file_name "SAMPLE_HC_$date.txt"

set fh [open $path/$file_name w]
set fp [open "$path/clean_health.txt" r]
set data [read $fp]
set file_data [split $data "\n"]
foreach line $file_data { 
	#puts $line
	puts $fh "[string map {" [m" ""} $line]"
}
close $fp
close $fh
	
