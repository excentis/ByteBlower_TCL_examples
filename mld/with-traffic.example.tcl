# This tcl script contains the main script to execute a MLD with traffic test.
# Before you can use this script, you need to source following tcl scripts:
#  * mld_with_traffic.conf.tcl
#  * general.proc.tcl
#  * mld_with_traffic.proc.tcl

source [ file join [ file dirname [ info script ]] with-traffic.proc.tcl ]

# Test Setup 
set setup [ MLD_with_traffic.Setup ]

# Test Run
set result [ MLD_with_traffic.Run ]

# Test Cleanup Server and Port List
#Cleanup $::server [ list $::sourcePort $::port1 $::port2 ]

            
