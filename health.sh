#!/bin/sh

#Written by        - Ashay Maheshwari

#DATE in YYYYMMDD format 
DATE=`date +%Y%m%d`
customer_name="SAMPLE"

#path containning all required files
path="/usr/local/software/pmecs_install/HC_autogen"

#executing tcl script to get health check and redirecting it to a text file
tclsh $path/login_device.tcl devices.txt > $path/health_Check.txt

#Removing all the control characters
tr -cd '\11\12\15\40-\176' < $path/health_Check.txt > $path/clean_health.txt

#executing tcl file to replce unwanted string and clear health check text file 
tclsh $path/replace.tcl 

#removing junk files of no use
rm -rf $path/health_Check.txt $path/clean_health.txt $path/_*

#executing script to send mail
sh $path/send_mail.sh

#removing mail parameters from directory $path
rm -rf $path/mailpack*

#renaming Healthlth check file to  a standard name 
mv $path/SAMPLE_HC_$DATE.txt $path/SAMPLE_HC_logs.txt 

#Copying the health check file to /home/master
cp $path/SAMPLE_HC_logs.txt /home/master/SAMPLE_HC_logs.txt
