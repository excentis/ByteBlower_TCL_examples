# This tcl script contains the main script to execute a TCP.time-based test.
# Before you can use this script, you need to source following tcl scripts:
#  * tcp.time-based.conf.tcl

source [ file join [ file dirname [ info script ]] time-based.proc.tcl ]

# Test Setup 
set setup [ TCP.time-based.Setup ]
#->returns [ list $httpServerPort $httpClientPort $httpServer $httpClient $server ]

#set httpServerPort [ lindex $setup 0 ] 
#set httpClientPort [ lindex $setup 1 ]
set httpServer [ lindex $setup 2 ]
set httpClient [ lindex $setup 3 ]
#set server [ lindex $setup 4 ]

# Test Run
set result [ TCP.time-based.Run $httpServer $httpClient $::requestDuration ]           
