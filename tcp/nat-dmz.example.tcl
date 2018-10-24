# This tcl script contains the main script to execute a TCP NAT DMZ test.
# Before you can use this script, you need to source following tcl scripts:
#  * tcp.NAT.DMZ.conf.tcl

source [ file join [ file dirname [ info script ]] nat-dmz.proc.tcl ]

# Test Setup 
set setup [ tcp-nat-dmz.Setup ]
#->returns [ list $dmzHttpServerPort $httpClientPort $dmzHttpServer $httpClient $server ]

#set httpServerPort [ lindex $setup 0 ] 
#set httpClientPort [ lindex $setup 1 ]
set dmzHttpServer [ lindex $setup 2 ]
set httpClient [ lindex $setup 3 ]
set server [ lindex $setup 4 ]

# Test Run
set result [ tcp-nat-dmz.Run $dmzHttpServer $httpClient $::requestSize ]

# Cleanup of all objects...
$server Destructor
