# This tcl script contains the main script to execute a TCP ACK suppression test
# Before you can use this script, you need to source following tcl scripts:
#  * tcp-ack-suppression.conf.tcl

source [ file join [ file dirname [ info script ]] ack-suppression.proc.tcl ]

# Test Setup 
set setup [ TAS.Setup ]

# Test Run
set result [ TAS.Run [lindex $setup 1] [lindex $setup 2] [lindex $setup 3] ]

# Test Cleanup Server and Port List
#Cleanup [lindex $setup 0] [ lrange $setup 1 3 ]	

            
