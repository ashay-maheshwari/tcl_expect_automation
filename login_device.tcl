#!/usr/bin/tclsh

#Written by           - Ashay Maheshwari
#Called From 	      - health.sh
#Scripting Language   -   Tcl/Expect
#Version 	      -   8.1


package require Expect

#Variable stores the path of all the files like net_device file , cli file 
#Set the value of this variable to the path containing this file file device.txt

global path 
set path "/usr/local/software/"

#proc to login inside LanEnforcer and fire CLI commands 
proc login { ip user_name passwd cli_prompt cp_prompt dp_propmt cli_cmd_file} {
		


        global file_name
	global path
	
	#Trying to open CLI commands file 
	if { [catch {set fh [open "$cli_cmd_file" r]} errmsg ]} {

		puts "\n[info script]:CLI command file not found"
		puts "\n$errmsg"
		puts "\nPlease locate the CLI command file"

		#send mail , if CLI command file not found
		#if { [catch {[exec echo "The CLI command list is missing.\nPlease figure out the issue.\n\nRegards,\nXYZ\n" | mail -s "Critical-Don't Ignore "  -r "Ashay Maheshwari<ashay.maheshwari@gmail.com>" ashay.maheshwari@gmail.com]} errmsg ] } {

        		#puts $errmsg

		#};#end inner-if 
		exit 1

	};#end if 
	
	#Variable to skip connection for illegal ip address to other devices which fail to connect
	global skip
 	set skip ""	


	#Trying to open log file to save the output of executed commands
        if {[catch {set fp [open $path/$file_name a+]} errmsg]} {
		puts $errmsg
		puts "[info script]: Cannot Append or Create File\n"
		exit 1
	};#end if 


	
        spawn ssh $user_name@$ip
	set confirmation_string "Are you sure you want to continue connecting (yes/no)?"

	expect {
                "assword:"  { sleep 5; send "$passwd\r" }
                 "$confirmation_string" {
                        puts "Adding host to known list of hosts\n"
                        send "yes\r"
                        expect {
                                "assword:" {
                                        sleep 5;
                                        send "$passwd/r"
                                        } timeout {
                                               	puts " connection timed out:\n"
						global skip 
						set skip 1
                                       	} eof {
                                                puts "Connection Failed\n"
                                               	#break
                                        }
                                };#end inner expect

                 } "Access Denied" {
                                puts "login incorrect\n"
                                #continue; 
                 } timeout {
                                puts "connection timed out"
				global skip
				set skip 1
				#exit 1
                                #continue
                 } eof {

                                puts "Connection Failed\n"
  	                        #break;
				global skip
				set skip 1

                        }

                };#end outer expect
		

	#Will return from function if somethihng oges wrong with LE
	if {$skip == 1 } {
		
		puts "Skipping connection to $ip\n"
		return

	};#end if 	

	
        

	while { [gets $fh line] >= 0 } {

			expect {
				"$cli_prompt" { send "$line\r" }
						
				"$cp_prompt" { send "$line\r" }

				"#" { send "$line\r" } 

				timeout { puts "Timed out" }

			 
			};#end expect

			set data "$expect_out(buffer)"
			#puts $fp $data
				
								
		};#end while 	


	if { [catch {close $fp} errmsg]} {
		puts $errmsg
		puts "Unable to Close file"
	};#end if  

	if { [catch {close $fh} errmsg] } {

		puts $errmsg
		puts "Unable to close file"

	};#end if 

	return

};#end proc login


set systemTime [clock seconds]
set date [clock format $systemTime -format %Y%m%d]
set time [clock format $systemTime -format %H%M]


#will contain the file name of file containing net_device credentials
global net_device_file
set net_device_file ""


#Checking the no of Command Line Arguments 
if { $argc == 1 } {
	
	#Will store file name containing net_device parameters information 
	global net_device_file
	set net_device_file [lindex $argv 0]

} else {
	puts "\n\nPlease Follow the following pattern to execute----"
	
	puts "tclsh $argv0 <file_name_containing_device_credentials.txt>\n\n"

};#end if else


#Checks whether the command line arguments are blank. If found blank, prints message and exits
if {$net_device_file == "" } {
	puts "[info script]: File name cannot be blank. EXITING........."
	exit 1
};#end if   


#Varible stores the file name which gets created  and stores the output of cli commands 
global file_name
set file_name "_$date.txt"

#puts $file_name

#Creating a file to store logs

if { [catch {set fp [open $path/$file_name w]} errmsg]} {
	puts "Cant create file\n"
	puts $errmsg
	exit 1
};#end if

#Closing the file after creating 

if { [catch {close $fp} errmsg ]} {
	puts $errmsg 
	exit 1
};#end if  



#Trying to open net_device file

if { [catch {set fh [open "$path/$net_device_file" r]} errmsg] } {
	puts "Cannot find file\n"
	puts "[info script]: File does not exist"
	exit 1	
};#end if 

#Loop read net_device file line by line

while { [gets $fh line] > 0 } {

	#if starting with # , then ignonre line
	if {[string index $line 0] eq "#" } {
		#Do nothing . Ignore
	} else {

		#set a list storing the splitted line read from net_device
		set lines [split $line " "]

		#set the variables storing individual paramaters obtained from line  
		set ip [lindex $lines 0]
		set user [lindex $lines 1]
		set passwd [lindex $lines 2]
		set cli_prompt [lindex $lines 3]
		set cp_prompt1 [lindex $lines 4]
		set cp_prompt2 [lindex $lines 5]
		set dp_propmt [lindex $lines 6]
		set cli_cmd_file [lindex $lines 7]
		set cp_prompt "$cp_prompt1 $cp_prompt2"


		#calls the loginf proc with suitable parameters
		login $ip $user $passwd $cli_prompt $cp_prompt $dp_propmt $cli_cmd_file

	};#end if-else
};#end while 

if {[catch {close $fh} errmsg]} {
	puts $errmsg
};#end if 



#Removes CTRL Characters from text file
puts [exec tr -d '$\r' < $path/$file_name > $path/SAMPLE_HC$file_name]


	


set fp [open "$path/mailpack2.txt" w]
puts $fp "attach:/usr/local/software/pmecs_install/HC_autogen/SAMPLE_HC$file_name"
puts $fp "subject:Health Status - SAMPLE, $date"
puts $fp "Hello team, \n Please find the attached file.\n\n Thanks and Regards,\nsomeone@something.com
close $fp

set fp [open "$path/mailpack.txt" w]
puts $fp "version:1"
puts $fp "mailserver:smpt_your_mail_server"
puts $fp "port:25"
puts $fp "enabletls:0"
puts $fp "from:your_mail@address"
puts $fp "user:recivers_mail@address"
puts $fp "password:somepassword"
puts $fp "to:ashay.maheshwari@someodomain.com"
puts $fp "reply-to:your_mail@address"
puts $fp "/usr/local/software"
close $fp

#exec sh send_mail.sh

#deletes the junk file containing CNTRL characters 
puts [exec rm -rf $path/$file_name]






