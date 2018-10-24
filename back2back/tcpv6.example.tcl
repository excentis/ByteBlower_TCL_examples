# This tcl script contains the main script to execute a TCP test.
# Before you can use this script, you need to source following tcl scripts:
#  * tcp.conf.tcl

source [ file join [ file dirname [ info script ]] tcpv6.proc.tcl ]

# Test Setup 
set setup [ TCP.Setup ]
#->returns [ list $httpServerPort $httpClientPort $httpServer $httpClient $server]

# Test Run
set result [ TCP.Run [lindex $setup 2] [lindex $setup 3] $::requestSize ]
