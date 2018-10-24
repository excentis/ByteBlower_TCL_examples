# This tcl script contains the main script to execute a TCP with MTU test.
# Before you can use this script, you need to source following tcl scripts:
#  * tcp-with-mtu.conf.tcl

source [ file join [ file dirname [ info script ]] with-mtu.proc.tcl ]

# Test Setup 
set setup [ TCP_with_MTU.Setup ]

set httpServer [lindex $setup 2]
set httpClient [lindex $setup 3]

# Test Run
set result [ TCP_with_MTU.Run $httpServer $httpClient $::requestSize ]

# Test Cleanup Server and Port List
#Cleanup [lindex $setup 4] [ lrange $setup 0 1 ]	

            
