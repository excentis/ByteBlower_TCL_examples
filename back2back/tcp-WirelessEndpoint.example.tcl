# This tcl script contains the main script to execute a TCP test.
# Before you can use this script, you need to source following tcl scripts:
#  * tcp.conf.tcl

source [ file join [ file dirname [ info script ]] tcp-WirelessEndpoint.proc.tcl ]

# Test Setup 
set setup [ TCP.Setup ]
# indices:            0               1                2          3          4        5
# ->returns [ list $httpServerPort $httpClientPort $httpServer $httpClient $server $meetingpoint]

set httpServerPort [ lindex $setup 0 ]
set wirelessEndpoint [ lindex $setup 1 ]
set httpServer [ lindex $setup 2 ]
set httpClient [ lindex $setup 3 ]
set byteblowerServer [ lindex $setup 4 ]
set meetingpoint [ lindex $setup 5 ]

# Test Run
set result [ TCP.Run $wirelessEndpoint $httpServer $httpClient $::requestDuration ]

catch { $wirelessEndpoint Destructor }
catch { $meetingpoint Destructor }
catch { $byteblowerServer Destructor }

puts "Result: $result"
