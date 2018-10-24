# This tcl script contains the main script to execute a Telnet test.
# Before you can use this script, you need to source following tcl scripts:
#  * telnet.conf.tcl
#  * general.proc.tcl
#  * telnet.proc.tcl

source [ file join [ file dirname [ info script ]] telnet.proc.tcl ]

# Test Setup 
set setup [ Telnet.Setup ]

# Test Run
set result [ Telnet.Run [ lindex $setup 0 ] [ lindex $setup 1 ]  [ lindex $setup 2 ] ]
           
