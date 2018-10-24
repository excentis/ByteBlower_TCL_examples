# This tcl script contains the main script to execute a MLD test.
# Before you can use this script, you need to source following tcl scripts:
#  * mld.conf.tcl
#  * general.proc.tcl
#  * mld.proc.tcl

source [ file join [ file dirname [ info script ]] mld.proc.tcl ]

# Test Setup 
set setup [ MLD.Setup ]

# Test Run
set result [ MLD.Run ]

# Test Cleanup Server and Port List
#Cleanup $::server [ list $::port1 $::port2 ]

            
