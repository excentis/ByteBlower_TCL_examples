# This tcl script contains the main script to execute a tcp multisession test.
# Before you can use this script, you need to source following tcl scripts:
#  * tcp.multisession.conf.tcl

source [ file join [ file dirname [ info script ]] multisession.proc.tcl ]

# Test Setup 
set setup [ TCP.multisession.Setup ]
#returns  [ list $httpServer $httpClientPort ]

set httpServer [ lindex $setup 0 ]
set httpClientPort [ lindex $setup 1 ]

# Test Run
set result [ TCP.multisession.Run $httpServer $httpClientPort ]

# Test Cleanup
# -- Clean up
#Cleanup $::server [ list $::httpClientPort $::httpServerPort ]
